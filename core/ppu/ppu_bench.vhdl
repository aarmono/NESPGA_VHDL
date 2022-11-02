library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.nes_types.all;
use work.nes_core.all;

use work.chr_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.palette_bus_types.all;
use work.file_bus_types.all;
use work.ppu_bus_types.all;

use work.simulation.all;
use std.env.all;

entity ppu_bench is
generic
(
    BMP_FILE_PREFIX  : string := "C:\\GitHub\\NESPGA_VHDL\\board\\sim\\out";
    PPU_MEM_FILEPATH : string := "C:\\GitHub\\NESPGA_VHDL\\board\\sim\\ppu.dmp";
    OAM_MEM_FILEPATH : string := "C:\\GitHub\\NESPGA_VHDL\\board\\sim\\oam.dmp";
    SEC_OAM_MEM_FILEPATH : string := "C:\\GitHub\\NESPGA_VHDL\\board\\sim\\sec_oam.dmp"
);
end ppu_bench;

architecture behavioral of ppu_bench is

    signal pixel_bus : pixel_bus_t;

    signal clk             : std_logic := '0';
    signal reset           : boolean := true;
    signal prg_data_to_ppu : data_t;
    signal cpu_bus         : ppu_bus_t;

    signal chr_bus           : chr_bus_t;
    signal chr_data_from_ppu : data_t;
    signal chr_data_to_ppu   : data_t;

    signal palette_bus       : palette_bus_t;
    signal data_to_palette   : data_t;
    signal data_from_palette : data_t;

    signal oam_bus       : oam_bus_t;
    signal data_to_oam   : data_t;
    signal data_from_oam : data_t;

    signal sec_oam_bus       : sec_oam_bus_t;
    signal data_to_sec_oam   : data_t;
    signal data_from_sec_oam : data_t;

    function chr_to_mem(bus_in : chr_bus_t) return file_bus_t
    is
        variable ret : file_bus_t;
    begin
        ret.address := resize(bus_in.address, file_addr_t'length);
        ret.read := bus_in.read;
        ret.write := bus_in.write;

        return ret;
    end;
    
    function palette_to_mem(bus_in : palette_bus_t) return file_bus_t
    is
        variable ret : file_bus_t;
        variable address : unsigned(file_addr_t'range);
    begin
        address :=
            resize(unsigned(bus_in.address), file_addr_t'length) + x"03F00";
        ret.address := std_logic_vector(address);
        ret.read := bus_in.read;
        ret.write := bus_in.write;

        return ret;
    end;

    function oam_to_mem(bus_in : oam_bus_t) return file_bus_t
    is
        variable ret : file_bus_t;
    begin
        ret.address := resize(bus_in.address, file_addr_t'length);
        ret.read := bus_in.read;
        ret.write := bus_in.write;

        return ret;
    end;

    function sec_oam_to_mem(bus_in : sec_oam_bus_t) return file_bus_t
    is
        variable ret : file_bus_t;
    begin
        ret.address := resize(bus_in.address, file_addr_t'length);
        ret.read := bus_in.read;
        ret.write := bus_in.write;

        return ret;
    end;

begin

    recorder : ppu_video_record
    generic map
    (
        FILE_PREFIX => BMP_FILE_PREFIX
    )
    port map
    (
        clk => clk,
        clk_en => true,
        pixel_bus => pixel_bus,
        ready => true,
        done => false
    );

    ppu_mem : file_memory
    generic map
    (
        FILEPATH => PPU_MEM_FILEPATH,
        MEM_BYTES => 16#4000#
    )
    port map
    (
        file_bus_1 => chr_to_mem(chr_bus),
        data_to_file_1 => chr_data_from_ppu,
        data_from_file_1 => chr_data_to_ppu,

        file_bus_2 => palette_to_mem(palette_bus),
        data_to_file_2 => data_to_palette,
        data_from_file_2 => data_from_palette
    );

    oam_mem : file_memory
    generic map
    (
        FILEPATH => OAM_MEM_FILEPATH,
        MEM_BYTES => 16#100#
    )
    port map
    (
        file_bus_1 => oam_to_mem(oam_bus),
        data_to_file_1 => data_to_oam,
        data_from_file_1 => data_from_oam
    );

    sec_oam_mem : file_memory
    generic map
    (
        FILEPATH => SEC_OAM_MEM_FILEPATH,
        MEM_BYTES => 16#20#
    )
    port map
    (
        file_bus_1 => sec_oam_to_mem(sec_oam_bus),
        data_to_file_1 => data_to_sec_oam,
        data_from_file_1 => data_from_sec_oam
    );

    dut : ppu
    port map
    (
        clk => clk,
        clk_en => true,
        reset => reset,

        chr_bus => chr_bus,
        chr_data_from_ppu => chr_data_from_ppu,
        chr_data_to_ppu => chr_data_to_ppu,

        oam_bus => oam_bus,
        data_to_oam => data_to_oam,
        data_from_oam => data_from_oam,

        sec_oam_bus => sec_oam_bus,
        data_to_sec_oam => data_to_sec_oam,
        data_from_sec_oam => data_from_sec_oam,

        palette_bus => palette_bus,
        data_to_palette => data_to_palette,
        data_from_palette => data_from_palette,

        cpu_bus => cpu_bus,
        cpu_bus_clk_en => true,
        prg_data_to_ppu => prg_data_to_ppu,

        pixel_bus => pixel_bus
    );

    process
    is
        constant PPUCTRL : ppu_addr_t := "000";
        constant PPUMASK : ppu_addr_t := "001";
    begin

        clk <= '0';
        reset <= true;
        wait for 10 ns;
        clk <= '1';
        
        wait for 10 ns;
        clk <= '0';
        wait for 10 ns;

        reset <= false;
        cpu_bus <= bus_read(PPUCTRL);
        prg_data_to_ppu <= "11010100";
        clk <= '1';

        wait for 10 ns;
        clk <= '0';
        wait for 10 ns;

        cpu_bus <= bus_read(PPUMASK);
        prg_data_to_ppu <= "00011110";
        clk <= '1';

        wait for 10 ns;
        clk <= '0';
        wait for 10 ns;

        for y in 0 to 260
        loop
            for x in 0 to 340
            loop
                clk <= '1';
                wait for 10 ns;
                clk <= '0';
                wait for 10 ns;
            end loop;
        end loop;

        finish;
    end process;

end behavioral;
