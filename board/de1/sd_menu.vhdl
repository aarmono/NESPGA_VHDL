library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.prg_bus_types.all;
use work.cart_types.all;
use work.perhipherals.all;
use work.perhipheral_types.all;

-- The SD card side of ROM_SD_MENU. It loads ROM files from the card into
-- sdram_rom, and gives the menu, which runs on the NES, access to the card.
--
-- After reset the card is streamed into sdram_rom from block 0, as with
-- ROM_SD_TO_SDRAM. If the card holds a filesystem rather than an iNES file,
-- sdram_rom stops the stream (rom_no_header), and the loader enters menu
-- mode.
--
-- In menu mode the CPU sees these registers on the CPU side of the
-- cartridge connector. Only A9 and A2-A0 are decoded in 0x5000-0x5FFF, so
-- the registers are mirrored through it:
--
--   0x5000-0x51FF  R/W  The block buffer
--   0x5200         W    Shifts a byte into the top of the 32 bit block
--                       number. Write its 4 bytes, lowest first
--   0x5204         W    Read the block into the buffer
--   0x5205         W    Launch
--   0x5200-0x53FF  R    Status. Bit 7: a read is running. Bit 6: the card
--                       failed
--
-- The value written to a command is ignored. The buffer must not be
-- accessed while a block is read into it, and commands are ignored until the
-- read is over.
--
-- Launch loads the file whose extents are in the buffer and leaves menu
-- mode. Each of the 64 entries of 8 bytes holds the first block of an
-- extent (4 bytes, lowest first), its number of blocks (2 bytes, lowest
-- first) and 2 unused bytes. A count of 0 ends the list. sdram_rom restarts,
-- so the NES is held in reset until the file is loaded and then powers up
-- into it. If the extents end before the file is loaded, or the file has no
-- iNES header, launch_failed becomes true.
entity sd_menu is
generic
(
    -- See syncram_sp
    VENDOR : vendor_t := VENDOR_ALTERA
);
port
(
    clk   : in std_logic;
    reset : in boolean;

    -- The cartridge connector. See nes_soc
    cpu_clk_en    : in boolean;
    board_cpu_in  : in cart_cpu_in_t;
    board_cpu_out : out cart_cpu_out_t;

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

    type state_t is
    (
        -- Streaming the card from block 0 into sdram_rom
        ST_BOOT,
        -- Menu mode, waiting for a command
        ST_MENU,
        -- Menu mode, reading a block into the buffer
        ST_READ,
        -- Restarting sdram_rom
        ST_LAUNCH,
        -- Reading an extent from the buffer
        ST_FETCH,
        -- Reading an extent into sdram_rom
        ST_RUN,
        -- The ROM file is loaded
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
    end record;

    constant RESET_REG : reg_t :=
    (
        state => ST_BOOT,
        req => false,
        blk => (others => '0'),
        count => (others => '0'),
        extent => 0,
        fetch => 0
    );

    type menu_in_t is record
        cpu_clk_en    : boolean;
        cpu_bus       : cart_cpu_in_t;
        rom_loading   : boolean;
        rom_no_header : boolean;
        -- sd_reader is idle
        sd_idle       : boolean;
        buf_data      : data_t;
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
                    ret.state := ST_MENU;
                end if;
            when ST_MENU =>
                if menu_in.cpu_clk_en and is_reg_write(menu_in.cpu_bus)
                then
                    case menu_in.cpu_bus.prg_bus.address(2 downto 0) is
                        when "000" =>
                            ret.blk := menu_in.cpu_bus.data &
                                       reg.blk(31 downto 8);
                        when "100" =>
                            ret.count := x"0001";
                            ret.req := true;
                            ret.state := ST_READ;
                        when "101" =>
                            ret.state := ST_LAUNCH;
                        when others =>
                            null;
                    end case;
                end if;
            when ST_READ =>
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
                if v_run_done
                then
                    if not menu_in.rom_loading
                    then
                        ret.state := ST_LOADED;
                    elsif menu_in.rom_no_header or reg.extent = extent_t'high
                    then
                        ret.state := ST_FAILED;
                    else
                        ret.extent := reg.extent + 1;
                        ret.fetch := 0;
                        ret.state := ST_FETCH;
                    end if;
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

    menu_mode <= reg.state = ST_MENU or reg.state = ST_READ;
    to_sdram <= reg.state /= ST_READ;

    rom_restart <= reg.state = ST_LAUNCH;
    launch_failed <= reg.state = ST_FAILED;
    sd_failed <= sd_error;

    req_count <= to_integer(reg.count);

    -- Once sdram_rom has the whole file, or has refused it, the rest of the
    -- block is discarded and the run ends
    sd_stop <= to_sdram and (not rom_loading or rom_no_header);

    load_valid <= sd_valid and to_sdram;
    load_data <= sd_data;
    sd_ready <= load_ready or not to_sdram;

    -- The buffer has one port. A block read into it has it to itself, so
    -- the CPU only has it in menu mode while no block is read, and the
    -- extents are read from it while the NES is held in reset. The address
    -- is otherwise held, so that the read data does not change outside menu
    -- mode
    buf_addr <=
        to_std_logic_vector(sd_offset, buf_addr_t'length)
            when reg.state = ST_READ else
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
        to_std_logic(reg.state = ST_READ and not sd_error) &
        to_std_logic(sd_error) & "000000";

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
    port map
    (
        clk => clk,
        reset => reset,

        failed => sd_error,

        req_valid => reg.req,
        req_block => reg.blk,
        req_count => req_count,
        req_ready => req_ready,

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
                                    sd_idle => req_ready,
                                    buf_data => data_from_buf));
        end if;
    end if;
    end process;

end behavioral;
