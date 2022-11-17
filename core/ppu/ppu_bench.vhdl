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
    BMP_FILE_PREFIX  : string := "C:\\GitHub\\NESPGA_VHDL\\board\\sim\vsim\\nes_dump\\frame";
    PPU_MEM_FILEPATH : string := "C:\\GitHub\\NESPGA_VHDL\\board\\sim\vsim\\nes_dump\\ppu.dmp";
    OAM_MEM_FILEPATH : string := "C:\\GitHub\\NESPGA_VHDL\\board\\sim\vsim\\nes_dump\\oam.dmp";
    SEC_OAM_MEM_FILEPATH : string := "C:\\GitHub\\NESPGA_VHDL\\board\\sim\vsim\\nes_dump\\sec_oam.dmp";

    -- These values are 1:1 with the PPU Status display in Mesen debugger
    BG_EN         : boolean := true;
    SPR_EN        : boolean := true;
    DRAW_LEFT_BG  : boolean := true;
    DRAW_LEFT_SPR : boolean := true;
    VERT_WRITE    : boolean := false;
    NMI_ON        : boolean := true;
    LARGE_SPRITE  : boolean := false;
    GRAYSCALE     : boolean := false;
    INTENSE_R     : boolean := false;
    INTENSE_G     : boolean := false;
    INTENSE_B     : boolean := false;

    T_REG         : integer := 16#0000#;
    X_SCROLL      : integer := 0;
    BG_ADDR       : integer := 16#1000#;
    SPR_ADDR      : integer := 16#0000#
);
end ppu_bench;

architecture behavioral of ppu_bench is

    constant T_REG_US    : unsigned(15 downto 0) := to_unsigned(T_REG, 16);
    constant X_SCROLL_US : unsigned( 2 downto 0) := to_unsigned(X_SCROLL, 3);
    constant BG_ADDR_US  : unsigned(15 downto 0) := to_unsigned(BG_ADDR, 16);
    constant SPR_ADDR_US : unsigned(15 downto 0) := to_unsigned(SPR_ADDR, 16);

    constant PPUMASK_VAL : data_t := to_std_logic(INTENSE_B)     &
                                     to_std_logic(INTENSE_G)     &
                                     to_std_logic(INTENSE_R)     &
                                     to_std_logic(SPR_EN)        &
                                     to_std_logic(BG_EN)         &
                                     to_std_logic(DRAW_LEFT_SPR) &
                                     to_std_logic(DRAW_LEFT_BG)  &
                                     to_std_logic(GRAYSCALE);
    
    constant PPUCTRL_VAL : data_t := to_std_logic(NMI_ON)       &
                                     '0'                        &
                                     to_std_logic(LARGE_SPRITE) &
                                     BG_ADDR_US(12)             &
                                     SPR_ADDR_US(12)            &
                                     to_std_logic(VERT_WRITE)   &
                                     std_logic_vector(T_REG_US(11 downto 10));

    constant PPUSCROLL_X : data_t := std_logic_vector(T_REG_US(4 downto 0)) &
                                     std_logic_vector(X_SCROLL_US);

    constant PPUSCROLL_Y : data_t := std_logic_vector(T_REG_US(9 downto 5)) &
                                     std_logic_vector(T_REG_US(14 downto 12));

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
        prg_data_to_ppu => prg_data_to_ppu,

        pixel_bus => pixel_bus
    );

    process
    is
        constant PPUCTRL   : ppu_addr_t := "000";
        constant PPUMASK   : ppu_addr_t := "001";
        constant PPUADDR   : ppu_addr_t := "110";
        constant PPUSCROLL : ppu_addr_t := "101";
    begin

        clk <= '0';
        reset <= true;
        wait for 10 ns;
        clk <= '1';
        
        wait for 10 ns;
        clk <= '0';
        wait for 10 ns;

        reset <= false;
        cpu_bus <= bus_write(PPUCTRL);
        prg_data_to_ppu <= PPUCTRL_VAL;
        clk <= '1';

        wait for 10 ns;
        clk <= '0';
        wait for 10 ns;
        
        cpu_bus <= bus_write(PPUADDR);
        prg_data_to_ppu <= x"00";
        clk <= '1';
        
        wait for 10 ns;
        clk <= '0';
        wait for 10 ns;
        
        prg_data_to_ppu <= x"00";
        clk <= '1';
        
        wait for 10 ns;
        clk <= '0';
        wait for 10 ns;

        cpu_bus <= bus_write(PPUMASK);
        prg_data_to_ppu <= PPUMASK_VAL;
        clk <= '1';

        wait for 10 ns;
        clk <= '0';
        wait for 10 ns;

        cpu_bus <= bus_write(PPUSCROLL);
        prg_data_to_ppu <= PPUSCROLL_X;
        clk <= '1';
        
        wait for 10 ns;
        clk <= '0';
        wait for 10 ns;
        
        prg_data_to_ppu <= PPUSCROLL_Y;
        clk <= '1';
        
        wait for 10 ns;
        clk <= '0';
        wait for 10 ns;
        
        cpu_bus <= PPU_BUS_IDLE;

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

        stop;
    end process;

end behavioral;
