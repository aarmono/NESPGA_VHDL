library IEEE;
use std.textio.all;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.binary_io.all;
use work.cart_pin_types.all;

-- A real NROM cartridge at its pins, built from an iNES file, for testing
-- cart_slot: PRG ROM at 0x8000-0xFFFF (16 KB mirrored, or 32 KB), 8 KB of PRG
-- RAM at 0x6000-0x7FFF (as the emulated NROM has, for Family BASIC), CHR ROM,
-- or 8 KB of CHR RAM when the file has none, and fixed mirroring.
--
-- The memories answer with access times, and drive X until their data is
-- valid. The model reports a timing violation as an error starting with
-- "nrom_cart:":
--   * read data not valid CPU_SAMPLE_LEAD before M2 falls, or
--     PPU_SAMPLE_LEAD before /RD rises (when the console samples it). See
--     PPU_DOT
--   * the CPU address or R/W changing while M2 is high, or within HOLD after
--     it falls
--   * the PPU address changing while /RD or /WR is low, or within HOLD after
--     /WR rises
--   * write data not stable WRITE_SETUP before the end of a write
entity nrom_cart is
generic
(
    NES_FILEPATH    : string;
    NES_FILE_BYTES  : positive;
    -- Address or chip enable to data
    PRG_ACCESS      : time := 150 ns;
    CHR_ACCESS      : time := 150 ns;
    RAM_ACCESS      : time := 100 ns;
    -- /OE (/RD) to data
    OE_ACCESS       : time := 50 ns;
    -- Deselect to the outputs floating
    OUTPUT_DISABLE  : time := 30 ns;
    -- PPU A10 or A11 and /A13 to CIRAM A10 and /CE, through the level
    -- shifters both ways
    CIRAM_DELAY     : time := 30 ns;
    -- How long before M2 falls, or /RD rises, the console samples read data
    CPU_SAMPLE_LEAD : time;
    PPU_SAMPLE_LEAD : time;
    -- A PPU dot. After a $2007 access the PPU reads the new address for one
    -- dot without using the data, and the bus goes idle after it. So a read
    -- of less than a dot whose address doesn't change when /RD rises isn't
    -- checked
    PPU_DOT         : time;
    HOLD            : time := 5 ns;
    WRITE_SETUP     : time := 20 ns
);
port
(
    pins        : in  cart_console_pins_t;

    cpu_data    : out data_t;
    cpu_data_oe : out boolean;
    irq_n       : out std_logic;

    ppu_data    : out data_t;
    ppu_data_oe : out boolean;
    ciram_ce_n  : out std_logic;
    ciram_a10   : out std_logic
);
end entity;

architecture behavioral of nrom_cart
is

    type mem_t is array(natural range <>) of data_t;

    -- iNES header fields, read once
    type header_t is record
        prg_bytes : natural;
        chr_bytes : natural;
        vertical  : boolean;
        trainer   : boolean;
    end record;

    procedure violation(msg : string)
    is
    begin
        report "nrom_cart: " & msg severity error;
    end;

    function max(a : time; b : time) return time
    is
    begin
        if a > b
        then
            return a;
        else
            return b;
        end if;
    end;

begin

    irq_n <= 'H';

    -- The memories are variables, since ghdl keeps a signal array as a
    -- signal per bit
    process
        file nes_file : byte_file_t;

        variable file_data : mem_t(0 to NES_FILE_BYTES - 1);
        variable header    : header_t;
        variable prg_rom   : mem_t(0 to 32767);
        variable prg_ram   : mem_t(0 to 8191) := (others => x"00");
        variable chr       : mem_t(0 to 8191) := (others => x"00");
        variable chr_ram   : boolean;
        variable offset    : natural;

        variable prev      : cart_console_pins_t;
        variable started   : boolean := false;

        -- CPU side
        variable cpu_sel       : boolean := false;
        variable cpu_valid_at  : time := 0 ns;
        variable m2_fall_at    : time := 0 ns;
        variable cpu_data_at   : time := 0 ns;
        variable ram_write     : boolean := false;
        variable ram_addr      : natural;
        variable cpu_value     : data_t;
        variable cpu_access    : time;

        -- PPU side
        variable ppu_sel       : boolean := false;
        variable ppu_valid_at  : time := 0 ns;
        variable ppu_addr_at   : time := 0 ns;
        variable ppu_rd_at     : time := 0 ns;
        variable ppu_wr_at     : time := 0 ns;
        variable ppu_data_at   : time := 0 ns;
        variable ppu_wr_end_at : time := 0 ns;
        variable ppu_value     : data_t;

        variable addr          : natural;
        variable sel           : boolean;
    begin
        byte_fopen(nes_file, NES_FILEPATH, read_mode);
        for i in file_data'range
        loop
            if not byte_feof(nes_file)
            then
                file_data(i) := byte_fread(nes_file);
            else
                file_data(i) := x"00";
            end if;
        end loop;
        byte_fclose(nes_file);

        header.prg_bytes := to_integer(unsigned(file_data(4))) * 16384;
        header.chr_bytes := to_integer(unsigned(file_data(5))) * 8192;
        header.vertical := file_data(6)(0) = '1';
        header.trainer := file_data(6)(2) = '1';

        assert header.prg_bytes = 16384 or header.prg_bytes = 32768
            report "nrom_cart: PRG ROM must be 16 or 32 KB"
            severity failure;
        assert header.chr_bytes = 0 or header.chr_bytes = 8192
            report "nrom_cart: CHR ROM must be 0 or 8 KB"
            severity failure;

        offset := 16;
        if header.trainer
        then
            offset := offset + 512;
        end if;

        for i in prg_rom'range
        loop
            prg_rom(i) := file_data(offset + (i mod header.prg_bytes));
        end loop;
        offset := offset + header.prg_bytes;

        chr_ram := header.chr_bytes = 0;
        if not chr_ram
        then
            for i in chr'range
            loop
                chr(i) := file_data(offset + i);
            end loop;
        end if;

        cpu_data <= (others => 'X');
        cpu_data_oe <= false;
        ppu_data <= (others => 'X');
        ppu_data_oe <= false;

        loop
            wait on pins;

            if not started
            then
                prev := pins;
                started := true;
            end if;

            -- CPU side

            if pins.m2 = '0' and prev.m2 = '1'
            then
                m2_fall_at := now;

                if cpu_sel and pins.cpu_rw = '1' and
                   now - CPU_SAMPLE_LEAD < cpu_valid_at
                then
                    violation("CPU read data valid " &
                              time'image(cpu_valid_at - (now - CPU_SAMPLE_LEAD)) &
                              " late");
                end if;

                if ram_write
                then
                    if now - cpu_data_at < WRITE_SETUP or not pins.cpu_data_oe
                    then
                        violation("PRG RAM write data setup");
                    end if;
                    prg_ram(ram_addr) := pins.cpu_data;
                    ram_write := false;
                end if;
            end if;

            if pins.cpu_addr /= prev.cpu_addr or pins.cpu_rw /= prev.cpu_rw
            then
                if pins.m2 = '1'
                then
                    violation("CPU address or R/W changed while M2 high");
                elsif now - m2_fall_at < HOLD
                then
                    violation("CPU address or R/W hold");
                end if;
            end if;

            if pins.cpu_data /= prev.cpu_data or
               pins.cpu_data_oe /= prev.cpu_data_oe
            then
                cpu_data_at := now;
                if pins.cpu_data_oe and prev.cpu_data_oe and
                   pins.cpu_rw = '0' and pins.m2 = '0' and prev.m2 = '0' and
                   now - m2_fall_at < HOLD
                then
                    violation("CPU write data hold");
                end if;
            end if;

            addr := to_integer(unsigned(pins.cpu_addr));
            -- PRG ROM: /CE is /ROMSEL. Its /OE is taken as R/W here, so that
            -- writes to ROM, which an NROM game shouldn't make, don't fight
            -- the console
            if pins.romsel_n = '0'
            then
                sel := pins.cpu_rw = '1';
                cpu_value := prg_rom(addr);
                cpu_access := PRG_ACCESS;
            -- PRG RAM: /CE from M2, /ROMSEL, A14 and A13
            elsif pins.m2 = '1' and pins.cpu_addr(14 downto 13) = "11"
            then
                sel := pins.cpu_rw = '1';
                ram_addr := addr mod 8192;
                cpu_value := prg_ram(ram_addr);
                cpu_access := RAM_ACCESS;
                ram_write := pins.cpu_rw = '0';
            else
                sel := false;
            end if;

            if sel
            then
                if not cpu_sel or pins.cpu_addr /= prev.cpu_addr
                then
                    cpu_valid_at := now + cpu_access;
                    cpu_data <= (others => 'X'), cpu_value after cpu_access;
                end if;
                cpu_data_oe <= true;
            elsif cpu_sel
            then
                cpu_data_oe <= false after OUTPUT_DISABLE;
            end if;
            cpu_sel := sel;

            -- PPU side

            if pins.ppu_addr /= prev.ppu_addr
            then
                ppu_addr_at := now;
                if pins.ppu_rd_n = '0' or pins.ppu_wr_n = '0'
                then
                    violation("PPU address changed while /RD or /WR low");
                elsif now - ppu_wr_end_at < HOLD
                then
                    violation("PPU address hold after /WR");
                end if;
            end if;

            if pins.ppu_data /= prev.ppu_data or
               pins.ppu_data_oe /= prev.ppu_data_oe
            then
                ppu_data_at := now;
                if pins.ppu_wr_n = '0' and prev.ppu_wr_n = '0'
                then
                    violation("PPU write data changed while /WR low");
                elsif pins.ppu_data_oe and prev.ppu_data_oe and
                      now - ppu_wr_end_at < HOLD
                then
                    violation("PPU write data hold");
                end if;
            end if;

            if pins.ppu_rd_n = '0' and prev.ppu_rd_n = '1'
            then
                ppu_rd_at := now;
            end if;

            if pins.ppu_wr_n = '0' and prev.ppu_wr_n = '1'
            then
                ppu_wr_at := now;
            end if;

            if pins.ppu_rd_n = '1' and prev.ppu_rd_n = '0' and ppu_sel and
               now - PPU_SAMPLE_LEAD < ppu_valid_at and
               not (now - ppu_rd_at < PPU_DOT and
                    pins.ppu_addr = prev.ppu_addr)
            then
                violation("PPU read data valid " &
                          time'image(ppu_valid_at - (now - PPU_SAMPLE_LEAD)) &
                          " late, address " &
                          to_hstring(prev.ppu_addr));
            end if;

            addr := to_integer(unsigned(pins.ppu_addr(12 downto 0)));

            -- The end of a write to CHR RAM: /WE is /WR, /CE is PPU A13
            if pins.ppu_wr_n = '1' and prev.ppu_wr_n = '0'
            then
                ppu_wr_end_at := now;
                if prev.ppu_addr(13) = '0' and chr_ram
                then
                    if now - ppu_data_at < WRITE_SETUP or
                       not prev.ppu_data_oe
                    then
                        violation("CHR RAM write data setup");
                    end if;
                    chr(to_integer(unsigned(prev.ppu_addr(12 downto 0)))) :=
                        prev.ppu_data;
                end if;
            end if;

            -- CHR: /CE is PPU A13 and /OE is /RD
            sel := pins.ppu_rd_n = '0' and pins.ppu_addr(13) = '0';
            if sel
            then
                if not ppu_sel or pins.ppu_addr /= prev.ppu_addr
                then
                    if chr_ram
                    then
                        ppu_valid_at := max(ppu_addr_at + RAM_ACCESS,
                                            ppu_rd_at + OE_ACCESS);
                    else
                        ppu_valid_at := max(ppu_addr_at + CHR_ACCESS,
                                            ppu_rd_at + OE_ACCESS);
                    end if;
                    ppu_value := chr(addr);
                    if ppu_valid_at > now
                    then
                        ppu_data <= (others => 'X'),
                                    ppu_value after ppu_valid_at - now;
                    else
                        ppu_data <= ppu_value;
                    end if;
                end if;
                ppu_data_oe <= true;
            elsif ppu_sel
            then
                ppu_data_oe <= false after OUTPUT_DISABLE;
            end if;
            ppu_sel := sel;

            -- CIRAM: /CE is /A13, and A10 is PPU A10 (vertical mirroring)
            -- or A11 (horizontal)
            ciram_ce_n <= pins.ppu_a13_n after CIRAM_DELAY;
            if header.vertical
            then
                ciram_a10 <= pins.ppu_addr(10) after CIRAM_DELAY;
            else
                ciram_a10 <= pins.ppu_addr(11) after CIRAM_DELAY;
            end if;

            prev := pins;
        end loop;
    end process;

end behavioral;
