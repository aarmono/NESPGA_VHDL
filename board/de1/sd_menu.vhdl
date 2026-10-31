library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.prg_bus_types.all;
use work.cart_types.all;
use work.cart_mem_bus_types.all;
use work.perhipherals.all;
use work.perhipheral_types.all;
use work.sd_menu_stub.all;

-- The SD card side of ROM_SD_MENU. It loads ROM files from the card into
-- sdram_rom, and gives the menu, which runs on the NES, access to the card.
--
-- After reset the card is streamed into sdram_rom from block 0, as with
-- ROM_SD_TO_SDRAM. If the card holds a filesystem rather than an iNES file,
-- sdram_rom stops the stream (rom_no_header). The boot stub (see
-- sd_menu/stub.s) is then streamed into sdram_rom instead, as an NROM image
-- whose PRG ROM is padded below the stub, and the loader enters menu mode
-- once it is loaded. The stub launches MENU.NES from the card.
--
-- In menu mode the CPU sees these registers on the CPU side of the
-- cartridge connector. Only A9 and A2-A0 are decoded in 0x5000-0x5FFF, so
-- the registers are mirrored through it:
--
--   0x5000-0x51FF  R/W  The block buffer
--   0x5200         W    Shifts a byte into the top of the 32 bit block
--                       number. Write its 4 bytes, lowest first
--   0x5201         W    Bits 1-0: the flags, which only reset clears
--   0x5204         W    Read the block into the buffer
--   0x5205         W    Launch. Bit 0: stay in menu mode. Bit 1: keep PRG
--                       RAM
--   0x5206         W    Write the buffer to the block
--   0x5207         W    Bits 4-0: the bank of cartridge RAM at 0x6000
--   0x5200-0x53FF  R    Status. Bit 7: a read or write is running. Bit 6:
--                       the card failed. Bits 1-0: the flags
--
-- Other bits of the values written to commands are ignored. The buffer must
-- not be accessed while a block is read into it or written from it, and
-- commands are ignored until that is over.
--
-- Launch loads the file whose extents are in the buffer and leaves menu
-- mode, unless bit 0 is set, as when the stub launches the menu. Each of the
-- 64 entries of 8 bytes holds the first block of an extent (4 bytes, lowest
-- first), its number of blocks (2 bytes, lowest first) and 2 unused bytes.
-- A count of 0 ends the list. sdram_rom restarts, so the NES is held in
-- reset until the file is loaded and then powers up into it. If the extents
-- end before the file is loaded, or the file has no iNES header,
-- launch_failed becomes true. Bit 1 makes the power up leave PRG RAM alone
-- (keep_prg_ram), as when the menu has loaded a save into it. The stub and
-- the menu always keep it, so that a game's PRG RAM survives until the menu
-- has written it back.
--
-- In menu mode, CPU accesses to PRG RAM, which the menu has 8 KB of at
-- 0x6000-0x7FFF, go to the selected 8 KB bank of the 256 KB of cartridge
-- RAM instead (see lib_nes): 0-7 are PRG RAM, 8-15 CHR RAM, 16 ExRAM, and
-- the rest are not used by games, so the menu keeps its own data there.
--
-- Holding Start and Select on controller 1 for RETURN_HOLD_MS, while a game
-- that the menu launched runs, returns to the menu: the stub is loaded
-- again, as at power up, and launches the menu, which finds what it left in
-- cartridge RAM and in the flags. buttons are those the game last read.
entity sd_menu is
generic
(
    -- See syncram_sp
    VENDOR : vendor_t := VENDOR_ALTERA;

    CLK_FREQ       : positive := 50_000_000;
    RETURN_HOLD_MS : positive := 2000
);
port
(
    clk   : in std_logic;
    reset : in boolean;

    -- The cartridge connector. See nes_soc
    cpu_clk_en    : in boolean;
    board_cpu_in  : in cart_cpu_in_t;
    board_cpu_out : out cart_cpu_out_t;

    -- Controller 1, low while pressed, with A in bit 0. See joy_port
    buttons : in std_logic_vector(7 downto 0);

    -- See nes_soc
    keep_prg_ram : out boolean;

    -- The cartridge memory bus, from nes_soc to sdram_rom. The menu's PRG
    -- RAM bank is applied here
    cart_mem_bus_in  : in cart_mem_bus_t;
    cart_mem_bus_out : out cart_mem_bus_t;

    -- See sdram_rom
    rom_loading   : in boolean;
    rom_no_header : in boolean;
    rom_restart   : out boolean;

    load_valid : out boolean;
    load_data  : out data_t;
    load_ready : in boolean;

    sd_failed     : out boolean;
    launch_failed : out boolean;

    sd_clk  : out std_logic;
    sd_cs_n : out std_logic;
    sd_mosi : out std_logic;
    sd_miso : in std_logic
);
end sd_menu;

architecture behavioral of sd_menu is

    -- 8 byte entries in the 512 byte buffer
    constant EXTENTS : positive := 64;

    subtype extent_t is natural range 0 to EXTENTS - 1;
    -- Clocks to read an extent from the buffer: the address of each of its
    -- 6 bytes, and the read data of the last
    subtype fetch_t is natural range 0 to 6;
    subtype buf_addr_t is std_logic_vector(8 downto 0);
    subtype count_t is std_logic_vector(15 downto 0);
    subtype flags_t is std_logic_vector(1 downto 0);
    -- 8 KB banks of the cartridge RAM region
    subtype bank_t is std_logic_vector(4 downto 0);

    constant HOLD_CLKS : positive := RETURN_HOLD_MS * (CLK_FREQ / 1000);
    subtype hold_t is natural range 0 to HOLD_CLKS;

    constant BUTTON_SELECT : natural := 2;
    constant BUTTON_START  : natural := 3;

    constant HEADER_BYTES : positive := stub_header_t'length;
    -- The stub's iNES image is the header, then the PRG ROM, with the stub
    -- at its top. The position in the image is counted from
    -- STUB_POS_START, so that the parts of the image and the stub ROM
    -- address are bits of it: the header is below STUB_BYTES, then the
    -- padding below STUB_PRG_BYTES, then the stub, at STUB_PRG_BYTES plus
    -- its address. sdram_rom stops the stream at the end of the image
    constant STUB_POS_START : positive := STUB_BYTES - HEADER_BYTES;
    subtype stub_pos_t is natural range 0 to 2 * STUB_PRG_BYTES - 1;
    subtype stub_addr_t is natural range 0 to STUB_BYTES - 1;

    type state_t is
    (
        -- Streaming the card from block 0 into sdram_rom
        ST_BOOT,
        -- Restarting sdram_rom for the stub
        ST_STUB_START,
        -- Streaming the stub into sdram_rom
        ST_STUB,
        -- Menu mode, waiting for a command
        ST_MENU,
        -- Menu mode, reading a block into the buffer
        ST_READ,
        -- Menu mode, writing the buffer to a block
        ST_WRITE,
        -- Restarting sdram_rom
        ST_LAUNCH,
        -- Reading an extent from the buffer
        ST_FETCH,
        -- Reading an extent into sdram_rom
        ST_RUN,
        -- The ROM file the menu launched is loaded, and runs
        ST_GAME,
        -- The ROM file at block 0 is loaded
        ST_LOADED,
        ST_FAILED
    );

    type reg_t is record
        state  : state_t;
        -- A run is waiting for sd_reader to take it
        req    : boolean;
        blk    : sd_block_t;
        count  : count_t;
        extent : extent_t;
        fetch  : fetch_t;
        -- The byte of the stub's image to stream, and whether it has been
        -- read from the stub ROM
        stub_pos   : stub_pos_t;
        stub_ready : boolean;
        -- Enter menu mode once the launched file is loaded
        keep_menu  : boolean;
        keep_ram   : boolean;
        flags      : flags_t;
        bank       : bank_t;
        -- How long Start and Select have been held
        hold       : hold_t;
    end record;

    constant RESET_REG : reg_t :=
    (
        state => ST_BOOT,
        req => false,
        blk => (others => '0'),
        count => (others => '0'),
        extent => 0,
        fetch => 0,
        stub_pos => 0,
        stub_ready => false,
        keep_menu => false,
        keep_ram => false,
        flags => (others => '0'),
        bank => (others => '0'),
        hold => 0
    );

    type menu_in_t is record
        cpu_clk_en    : boolean;
        cpu_bus       : cart_cpu_in_t;
        rom_loading   : boolean;
        rom_no_header : boolean;
        load_ready    : boolean;
        -- sd_reader is idle
        sd_idle       : boolean;
        buf_data      : data_t;
        buttons       : std_logic_vector(7 downto 0);
    end record;

    -- An access to 0x5000-0x5FFF
    function is_window(cpu_bus : cart_cpu_in_t) return boolean
    is
    begin
        return not cpu_bus.romsel and
               cpu_bus.prg_bus.address(14 downto 12) = "101";
    end;

    function is_buf_write(cpu_bus : cart_cpu_in_t) return boolean
    is
    begin
        return is_bus_write(cpu_bus.prg_bus) and is_window(cpu_bus) and
               cpu_bus.prg_bus.address(9) = '0';
    end;

    function is_reg_write(cpu_bus : cart_cpu_in_t) return boolean
    is
    begin
        return is_bus_write(cpu_bus.prg_bus) and is_window(cpu_bus) and
               cpu_bus.prg_bus.address(9) = '1';
    end;

    -- The cartridge memory bus with the menu's PRG RAM bank applied to
    -- accesses to the 64 KB PRG RAM window, the first of the cartridge RAM
    -- region. The menu's 8 KB of PRG RAM is at its start
    function get_menu_cart_mem_bus
    (
        cart_mem_bus : cart_mem_bus_t;
        bank         : bank_t
    )
    return cart_mem_bus_t
    is
        variable ret : cart_mem_bus_t;
    begin
        ret := cart_mem_bus;
        if is_in_window(cart_mem_bus.address, PRG_RAM_WINDOW)
        then
            ret.address(17 downto 13) := bank;
        end if;
        return ret;
    end;

    function cycle_menu(reg : reg_t; menu_in : menu_in_t) return reg_t
    is
        variable ret : reg_t;
        -- The run that was requested is over
        variable v_run_done : boolean;
    begin
        ret := reg;
        v_run_done := not reg.req and menu_in.sd_idle;

        if menu_in.sd_idle
        then
            ret.req := false;
        end if;

        case reg.state is
            when ST_BOOT =>
                if not menu_in.rom_loading
                then
                    ret.state := ST_LOADED;
                elsif menu_in.rom_no_header and menu_in.sd_idle
                then
                    ret.state := ST_STUB_START;
                end if;
            when ST_STUB_START =>
                ret.stub_pos := STUB_POS_START;
                ret.stub_ready := false;
                ret.keep_ram := true;
                ret.state := ST_STUB;
            when ST_STUB =>
                -- The stub ROM's data is for the address of the clock before
                if not menu_in.rom_loading
                then
                    ret.state := ST_MENU;
                elsif not reg.stub_ready
                then
                    ret.stub_ready := true;
                elsif menu_in.load_ready
                then
                    ret.stub_pos := reg.stub_pos + 1;
                    ret.stub_ready := false;
                end if;
            when ST_MENU =>
                if menu_in.cpu_clk_en and is_reg_write(menu_in.cpu_bus)
                then
                    case menu_in.cpu_bus.prg_bus.address(2 downto 0) is
                        when "000" =>
                            ret.blk := menu_in.cpu_bus.data &
                                       reg.blk(31 downto 8);
                        when "001" =>
                            ret.flags := menu_in.cpu_bus.data(flags_t'range);
                        when "100" =>
                            ret.count := x"0001";
                            ret.req := true;
                            ret.state := ST_READ;
                        when "101" =>
                            ret.keep_menu := menu_in.cpu_bus.data(0) = '1';
                            ret.keep_ram := menu_in.cpu_bus.data(0) = '1' or
                                            menu_in.cpu_bus.data(1) = '1';
                            ret.state := ST_LAUNCH;
                        when "110" =>
                            ret.count := x"0001";
                            ret.req := true;
                            ret.state := ST_WRITE;
                        when "111" =>
                            ret.bank := menu_in.cpu_bus.data(bank_t'range);
                        when others =>
                            null;
                    end case;
                end if;
            when ST_READ | ST_WRITE =>
                if v_run_done
                then
                    ret.state := ST_MENU;
                end if;
            when ST_LAUNCH =>
                ret.extent := 0;
                ret.fetch := 0;
                ret.state := ST_FETCH;
            when ST_FETCH =>
                -- The buffer data is the byte addressed on the clock before
                if reg.fetch >= 1 and reg.fetch <= 4
                then
                    ret.blk := menu_in.buf_data & reg.blk(31 downto 8);
                elsif reg.fetch >= 5
                then
                    ret.count := menu_in.buf_data & reg.count(15 downto 8);
                end if;

                if reg.fetch = fetch_t'high
                then
                    if ret.count = x"0000"
                    then
                        ret.state := ST_FAILED;
                    else
                        ret.req := true;
                        ret.state := ST_RUN;
                    end if;
                else
                    ret.fetch := reg.fetch + 1;
                end if;
            when ST_RUN =>
                -- The NES leaves reset once the file is loaded, so menu
                -- mode starts then, while sd_reader discards the rest of the
                -- block. A read waits for it
                if not menu_in.rom_loading
                then
                    ret.hold := 0;
                    if reg.keep_menu
                    then
                        ret.state := ST_MENU;
                    else
                        ret.state := ST_GAME;
                    end if;
                elsif v_run_done
                then
                    if menu_in.rom_no_header or reg.extent = extent_t'high
                    then
                        ret.state := ST_FAILED;
                    else
                        ret.extent := reg.extent + 1;
                        ret.fetch := 0;
                        ret.state := ST_FETCH;
                    end if;
                end if;
            when ST_GAME =>
                if menu_in.buttons(BUTTON_START) = '1' or
                   menu_in.buttons(BUTTON_SELECT) = '1'
                then
                    ret.hold := 0;
                elsif reg.hold = HOLD_CLKS
                then
                    ret.state := ST_STUB_START;
                else
                    ret.hold := reg.hold + 1;
                end if;
            when ST_LOADED | ST_FAILED =>
                null;
        end case;

        return ret;
    end;

    signal reg : reg_t := RESET_REG;

    signal menu_mode : boolean;
    -- The data read from the card goes to sdram_rom, not the buffer
    signal to_sdram  : boolean;

    signal stub_addr : stub_addr_t;
    signal stub_data : data_t;

    signal req_count : sd_count_t;
    signal req_ready : boolean;
    signal sd_stop   : boolean;
    signal sd_data   : data_t;
    signal sd_offset : sd_offset_t;
    signal sd_valid  : boolean;
    signal sd_ready  : boolean;
    signal sd_error  : boolean;

    signal buf_addr     : buf_addr_t;
    signal buf_write    : boolean;
    signal data_to_buf  : data_t;
    signal data_from_buf : data_t;

begin

    menu_mode <= reg.state = ST_MENU or reg.state = ST_READ or
                 reg.state = ST_WRITE;
    to_sdram <= reg.state /= ST_READ and reg.state /= ST_STUB;

    rom_restart <= reg.state = ST_STUB_START or reg.state = ST_LAUNCH;
    launch_failed <= reg.state = ST_FAILED;
    sd_failed <= sd_error;
    keep_prg_ram <= reg.keep_ram;

    cart_mem_bus_out <= get_menu_cart_mem_bus(cart_mem_bus_in, reg.bank)
                            when menu_mode else
                        cart_mem_bus_in;

    req_count <= to_integer(reg.count);

    -- A run is only wanted while it reads a block into the buffer, or a
    -- file that sdram_rom still takes. Otherwise sd_reader ends it, once
    -- sdram_rom has the whole file or has refused it. A new run waits for
    -- that. Writes ignore it
    sd_stop <= not (reg.state = ST_READ or
                    ((reg.state = ST_BOOT or reg.state = ST_RUN) and
                     rom_loading and not rom_no_header));

    load_valid <= reg.stub_ready when reg.state = ST_STUB else
                  sd_valid and to_sdram;
    -- STUB_POS_START is a multiple of HEADER_BYTES
    load_data <=
        sd_data when reg.state /= ST_STUB else
        STUB_HEADER(reg.stub_pos mod HEADER_BYTES)
            when reg.stub_pos < STUB_BYTES else
        x"FF" when reg.stub_pos < STUB_PRG_BYTES else
        stub_data;
    sd_ready <= load_ready or not to_sdram;

    stub_addr <= reg.stub_pos mod STUB_BYTES;

    -- In a process of its own, so that it is built as a ROM
    process(clk)
    begin
    if rising_edge(clk)
    then
        stub_data <= STUB_ROM(stub_addr);
    end if;
    end process;

    -- The buffer has one port. A block read into it or written from it has
    -- it to itself, so the CPU only has it in menu mode while no block is
    -- read or written, and the extents are read from it while the NES is
    -- held in reset. The address is otherwise held, so that the read data
    -- does not change outside menu mode
    buf_addr <=
        to_std_logic_vector(sd_offset, buf_addr_t'length)
            when reg.state = ST_READ or reg.state = ST_WRITE else
        board_cpu_in.prg_bus.address(buf_addr_t'range)
            when reg.state = ST_MENU else
        to_std_logic_vector(reg.extent, 6) &
        to_std_logic_vector(reg.fetch, 3);

    buf_write <= (reg.state = ST_READ and sd_valid) or
                 (reg.state = ST_MENU and cpu_clk_en and
                  is_buf_write(board_cpu_in));

    data_to_buf <= sd_data when reg.state = ST_READ else board_cpu_in.data;

    board_cpu_out.data_oe <= menu_mode and
                             is_bus_read(board_cpu_in.prg_bus) and
                             is_window(board_cpu_in);
    board_cpu_out.data_float <= (others => '0');
    board_cpu_out.irq <= false;

    board_cpu_out.data <=
        (others => '0') when not menu_mode else
        data_from_buf when board_cpu_in.prg_bus.address(9) = '0' else
        to_std_logic((reg.state = ST_READ or reg.state = ST_WRITE) and
                     not sd_error) &
        to_std_logic(sd_error) & "0000" & reg.flags;

    buf : syncram_sp
    generic map
    (
        VENDOR => VENDOR,
        ADDR_BITS => buf_addr_t'length
    )
    port map
    (
        clk => clk,
        clk_en => true,

        address => buf_addr,
        read => true,
        write => buf_write,

        data_in => data_to_buf,
        data_out => data_from_buf
    );

    reader : entity work.sd_reader(behavioral)
    generic map
    (
        REQUESTS => true
    )
    port map
    (
        clk => clk,
        reset => reset,

        failed => sd_error,

        req_valid => reg.req,
        req_write => reg.state = ST_WRITE,
        req_block => reg.blk,
        req_count => req_count,
        req_ready => req_ready,

        write_data => data_from_buf,

        stop => sd_stop,
        data => sd_data,
        offset => sd_offset,
        valid => sd_valid,
        ready => sd_ready,

        sd_clk => sd_clk,
        sd_cs_n => sd_cs_n,
        sd_mosi => sd_mosi,
        sd_miso => sd_miso
    );

    process(clk)
    begin
    if rising_edge(clk)
    then
        if reset
        then
            reg <= RESET_REG;
        else
            reg <= cycle_menu(reg, (cpu_clk_en => cpu_clk_en,
                                    cpu_bus => board_cpu_in,
                                    rom_loading => rom_loading,
                                    rom_no_header => rom_no_header,
                                    load_ready => load_ready,
                                    sd_idle => req_ready,
                                    buf_data => data_from_buf,
                                    buttons => buttons));
        end if;
    end if;
    end process;

end behavioral;
