library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_mem_bus_types.all;

-- Serves the two channels of a split cartridge memory bus (see cart_system
-- SPLIT_MEM_BUS) out of the DE1's asynchronous SRAM, each access as it is
-- asked for, where sdram_rom serves one access per PPU cycle. For a
-- cartridge in a real console, whose accesses come when the console makes
-- them and must be answered within the access.
--
-- After reset the ROM file is copied into the SRAM from a byte stream, as
-- sdram_rom does it, during which loading is true and the cartridge must be
-- held in reset. The ROM file is in the lower half of the SRAM and the
-- 64 KB windows of the cartridge RAMs in the upper half, so the DE1's
-- 512 KB hold a ROM file of up to 256 KB. A larger iNES file is not copied:
-- too_large becomes true and loading stays true. With REQUIRE_INES, a stream
-- that does not start with an iNES header is not copied either: no_header
-- becomes true after its first 4 bytes, and loading stays true.
--
-- restart starts a new copy, of a new stream, from the start. loading is
-- true from the next clock, and an access in progress is completed first,
-- so that a write to a cartridge RAM is not cut short. The copy only writes
-- the lower half of the SRAM, so the cartridge RAMs keep their contents.
--
-- Once loading is complete, an access on a channel is started on the first
-- clock the SRAM is free, and a channel that has just been served waits for
-- the other one. A read takes READ_CLOCKS and a write 3, so with both
-- channels asking at once the second read is answered READ_CLOCKS + 1
-- clocks after the first. The read data of a channel holds until its next
-- read is answered, so the board sees the data of the address it asked for
-- last, late by the time the access takes.
--
-- The address and data of an access are taken when it starts. A channel
-- whose access changes is served again, and a write is made again whenever
-- its address or data changes. So a channel may show an access before it
-- has settled, as long as only the data of a write is wrong then: the
-- settled access overwrites it.
--
-- A write through one channel is seen by a read through the other, which
-- only ExRAM and the VRAM of a four-screen board use.
entity sram_rom is
generic
(
    -- The address bits of the SRAM, which has 16-bit words: 18 on the DE1,
    -- and up to 22, which holds all of the cartridge memory bus
    ADDR_BITS   : positive := 18;
    -- Clocks from the address to the data of a read: 2, or 1 if the SRAM's
    -- access time and the pin delays both ways fit in a clock
    READ_CLOCKS : positive := 2;
    -- Stop at a stream that does not start with an iNES header
    REQUIRE_INES : boolean := false
);
port
(
    clk   : in std_logic;
    reset : in boolean;

    restart : in boolean := false;

    loading   : out boolean;
    too_large : out boolean;
    no_header : out boolean;

    load_valid : in boolean;
    load_data  : in data_t;
    load_ready : out boolean;

    prg_mem_bus       : in cart_mem_bus_t;
    data_to_prg_mem   : in data_t;
    data_from_prg_mem : out data_t;

    chr_mem_bus       : in cart_mem_bus_t;
    data_to_chr_mem   : in data_t;
    data_from_chr_mem : out data_t;

    sram_addr : out std_logic_vector(ADDR_BITS - 1 downto 0);
    sram_dq   : inout std_logic_vector(15 downto 0);
    sram_ce_n : out std_logic;
    sram_oe_n : out std_logic;
    sram_we_n : out std_logic;
    sram_lb_n : out std_logic;
    sram_ub_n : out std_logic
);
end sram_rom;

architecture behavioral of sram_rom is

    -- A byte of the SRAM: the word, and bit 0 selects the byte of it
    subtype byte_addr_t is std_logic_vector(ADDR_BITS downto 0);

    -- The ROM file is in the lower half of the SRAM
    constant ROM_BYTES : positive := 2**(byte_addr_t'length - 1);

    subtype load_addr_t is natural range 0 to ROM_BYTES - 1;
    subtype banks_t is natural range 0 to 255;
    -- A file can be far larger than the SRAM
    subtype file_bytes_t is natural range 0 to 16 + 512 + 255 * (16384 + 8192);

    function ines_bytes
    (
        prg_banks : banks_t;
        chr_banks : banks_t;
        trainer   : boolean
    )
    return file_bytes_t
    is
        variable ret : file_bytes_t;
    begin
        ret := 16 + prg_banks * 16384 + chr_banks * 8192;
        if trainer
        then
            ret := ret + 512;
        end if;

        return ret;
    end;

    -- The lower half of the cartridge memory bus is the ROM file, and the
    -- cartridge RAMs have their windows at the start of the upper half
    function to_byte_addr(address : cart_mem_addr_t) return byte_addr_t
    is
    begin
        return address(address'high) & address(ADDR_BITS - 1 downto 0);
    end;

    type state_t is
    (
        STATE_COPY,
        -- The ROM file doesn't fit
        STATE_TOO_LARGE,
        -- The stream has no iNES header and REQUIRE_INES is set
        STATE_NO_HEADER,
        STATE_RUN
    );

    type channel_t is (CHANNEL_PRG, CHANNEL_CHR);

    -- What the SRAM holds at the address a channel last accessed
    type served_t is record
        valid   : boolean;
        address : byte_addr_t;
        data    : data_t;
    end record;

    constant RESET_SERVED : served_t :=
    (
        valid => false,
        address => (others => '0'),
        data => (others => '0')
    );

    -- A write takes 3 clocks, and a read no more
    subtype access_count_t is natural range 0 to 2;

    type reg_t is record
        state      : state_t;
        -- A restart waits for the access in progress
        restart    : boolean;
        load_addr  : load_addr_t;
        load_last  : load_addr_t;

        -- iNES header fields
        ines      : boolean;
        nes2      : boolean;
        trainer   : boolean;
        prg_banks : banks_t;
        chr_banks : banks_t;

        -- An access is in progress, for this channel, and it is a write.
        -- The clocks since it started
        busy    : boolean;
        channel : channel_t;
        write   : boolean;
        count   : access_count_t;
        -- The address and write data of the access
        address : byte_addr_t;
        data    : data_t;

        prg : served_t;
        chr : served_t;

        -- The pins
        dq_oe : boolean;
        oe_n  : std_logic;
        we_n  : std_logic;
    end record;

    constant RESET_REG : reg_t :=
    (
        state => STATE_COPY,
        restart => false,
        load_addr => 0,
        load_last => load_addr_t'high,

        ines => false,
        nes2 => false,
        trainer => false,
        prg_banks => 0,
        chr_banks => 0,

        busy => false,
        channel => CHANNEL_PRG,
        write => false,
        count => 0,
        address => (others => '0'),
        data => (others => '0'),

        prg => RESET_SERVED,
        chr => RESET_SERVED,

        dq_oe => false,
        oe_n => '1',
        we_n => '1'
    );

    type sram_rom_in_t is record
        reg        : reg_t;
        restart    : boolean;
        load_valid : boolean;
        load_data  : data_t;
        prg_bus    : cart_mem_bus_t;
        prg_data   : data_t;
        chr_bus    : cart_mem_bus_t;
        chr_data   : data_t;
        -- The byte of DQ the access reads
        read_data  : data_t;
    end record;

    -- The channel's access is not what it was last served
    function is_pending
    (
        bus_in : cart_mem_bus_t;
        data   : data_t;
        served : served_t
    )
    return boolean
    is
    begin
        if not is_bus_active(bus_in)
        then
            return false;
        end if;

        return not served.valid or
               served.address /= to_byte_addr(bus_in.address) or
               (bus_in.write and served.data /= data);
    end;

    -- Starts an access
    function start_access
    (
        reg     : reg_t;
        channel : channel_t;
        address : byte_addr_t;
        write   : boolean;
        data    : data_t
    )
    return reg_t
    is
        variable ret : reg_t;
    begin
        ret := reg;
        ret.busy := true;
        ret.channel := channel;
        ret.write := write;
        ret.count := 0;
        ret.address := address;
        ret.data := data;
        -- The SRAM lets go of the data bus a clock before a write drives it
        if write
        then
            ret.oe_n := '1';
        else
            ret.oe_n := '0';
        end if;

        return ret;
    end;

    function cycle_sram_rom(rom_in : sram_rom_in_t) return reg_t
    is
        variable reg  : reg_t;
        variable done : boolean;
        variable served : served_t;
        variable prg_pending : boolean;
        variable chr_pending : boolean;
    begin
        reg := rom_in.reg;

        -- A write: the address in the first clock, /WE low and the data
        -- in the second, and both held with /WE high in the third
        done := false;
        if reg.busy
        then
            if reg.write
            then
                case reg.count is
                    when 0 =>
                        reg.dq_oe := true;
                        reg.we_n := '0';
                    when 1 =>
                        reg.we_n := '1';
                    when others =>
                        reg.dq_oe := false;
                        done := true;
                end case;
            else
                done := reg.count = READ_CLOCKS - 1;
            end if;

            if not done
            then
                reg.count := reg.count + 1;
            end if;
        end if;

        if done
        then
            reg.busy := false;

            served.valid := true;
            served.address := reg.address;
            if reg.write
            then
                served.data := reg.data;
            else
                served.data := rom_in.read_data;
            end if;

            -- The other channel keeps holding what the SRAM holds
            case reg.channel is
                when CHANNEL_PRG =>
                    reg.prg := served;
                    if reg.write and reg.chr.address = reg.address
                    then
                        reg.chr.data := reg.data;
                    end if;
                when CHANNEL_CHR =>
                    reg.chr := served;
                    if reg.write and reg.prg.address = reg.address
                    then
                        reg.prg.data := reg.data;
                    end if;
            end case;
        end if;

        if rom_in.restart
        then
            reg.restart := true;
        end if;

        if reg.restart
        then
            if not reg.busy
            then
                reg := RESET_REG;
            end if;

            return reg;
        end if;

        case rom_in.reg.state is
            when STATE_COPY =>
                if rom_in.load_valid and not reg.busy
                then
                    reg := start_access(
                        reg,
                        CHANNEL_PRG,
                        to_std_logic_vector(reg.load_addr, byte_addr_t'length),
                        true,
                        rom_in.load_data);

                    case reg.load_addr is
                        when 0 =>
                            reg.ines := rom_in.load_data = x"4E";
                        when 1 =>
                            reg.ines := reg.ines and rom_in.load_data = x"45";
                        when 2 =>
                            reg.ines := reg.ines and rom_in.load_data = x"53";
                        when 3 =>
                            reg.ines := reg.ines and rom_in.load_data = x"1A";
                            if REQUIRE_INES and not reg.ines
                            then
                                reg.state := STATE_NO_HEADER;
                            end if;
                        when 4 =>
                            reg.prg_banks := to_integer(rom_in.load_data);
                        when 5 =>
                            reg.chr_banks := to_integer(rom_in.load_data);
                        when 6 =>
                            reg.trainer := rom_in.load_data(2) = '1';
                        when 7 =>
                            reg.nes2 := rom_in.load_data(3 downto 2) = "10";
                        when 9 =>
                            -- NES 2.0 keeps the high bits of the bank counts
                            -- here. Files that use them don't fit
                            if reg.ines
                            then
                                if (reg.nes2 and rom_in.load_data /= x"00") or
                                   ines_bytes(reg.prg_banks,
                                              reg.chr_banks,
                                              reg.trainer) > ROM_BYTES
                                then
                                    reg.state := STATE_TOO_LARGE;
                                else
                                    reg.load_last :=
                                        ines_bytes(reg.prg_banks,
                                                   reg.chr_banks,
                                                   reg.trainer) - 1;
                                end if;
                            end if;
                        when others =>
                            null;
                    end case;

                    if reg.state = STATE_COPY
                    then
                        if reg.load_addr = reg.load_last
                        then
                            reg.state := STATE_RUN;
                            -- The channels read what was copied, not what
                            -- the copy last wrote
                            reg.prg.valid := false;
                            reg.chr.valid := false;
                        else
                            reg.load_addr := reg.load_addr + 1;
                        end if;
                    end if;
                end if;

            when STATE_TOO_LARGE | STATE_NO_HEADER =>
                null;

            when STATE_RUN =>
                if not reg.busy
                then
                    prg_pending := is_pending(rom_in.prg_bus,
                                              rom_in.prg_data,
                                              reg.prg);
                    chr_pending := is_pending(rom_in.chr_bus,
                                              rom_in.chr_data,
                                              reg.chr);

                    -- The channel that wasn't served last goes first
                    if prg_pending and
                       (not chr_pending or reg.channel = CHANNEL_CHR)
                    then
                        reg := start_access(
                            reg,
                            CHANNEL_PRG,
                            to_byte_addr(rom_in.prg_bus.address),
                            rom_in.prg_bus.write,
                            rom_in.prg_data);
                    elsif chr_pending
                    then
                        reg := start_access(
                            reg,
                            CHANNEL_CHR,
                            to_byte_addr(rom_in.chr_bus.address),
                            rom_in.chr_bus.write,
                            rom_in.chr_data);
                    end if;
                end if;
        end case;

        return reg;
    end;

    signal reg : reg_t := RESET_REG;

    signal read_data : data_t;

begin

    assert ADDR_BITS >= 18 and ADDR_BITS <= cart_mem_addr_t'length - 1
        report "sram_rom: ADDR_BITS must be 18 to 22"
        severity failure;

    assert READ_CLOCKS <= 3
        report "sram_rom: READ_CLOCKS must be at most 3"
        severity failure;

    loading <= reg.state /= STATE_RUN or reg.restart;
    too_large <= reg.state = STATE_TOO_LARGE;
    no_header <= reg.state = STATE_NO_HEADER;

    data_from_prg_mem <= reg.prg.data;
    data_from_chr_mem <= reg.chr.data;

    sram_ce_n <= '0';
    sram_oe_n <= reg.oe_n;
    sram_we_n <= reg.we_n;
    sram_addr <= reg.address(ADDR_BITS downto 1);
    sram_lb_n <= reg.address(0);
    sram_ub_n <= not reg.address(0);
    sram_dq <= reg.data & reg.data when reg.dq_oe else (others => 'Z');

    read_data <= sram_dq(15 downto 8) when reg.address(0) = '1' else
                 sram_dq(7 downto 0);

    process(clk)
    is
        variable rom_in : sram_rom_in_t;
    begin
    if rising_edge(clk)
    then
        if reset
        then
            reg <= RESET_REG;
        else
            rom_in.reg := reg;
            rom_in.restart := restart;
            rom_in.load_valid := load_valid;
            rom_in.load_data := load_data;
            rom_in.prg_bus := prg_mem_bus;
            rom_in.prg_data := data_to_prg_mem;
            rom_in.chr_bus := chr_mem_bus;
            rom_in.chr_data := data_to_chr_mem;
            rom_in.read_data := read_data;

            reg <= cycle_sram_rom(rom_in);
        end if;
    end if;
    end process;

    -- A byte is taken from the stream on the clock an access can start
    load_ready <= reg.state = STATE_COPY and not reg.restart and
                  (not reg.busy or
                   (reg.write and reg.count = 2) or
                   (not reg.write and reg.count = READ_CLOCKS - 1));

end behavioral;
