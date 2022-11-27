library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.ram_bus_types.all;
use work.sram_bus_types.all;
use work.chr_bus_types.all;
use work.cpu_bus_types.all;
use work.file_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.palette_bus_types.all;
use work.utilities.all;
use work.soc.all;
use work.simulation.all;

entity nes_bench is
generic
(
    AU_FILEPATH     : string;
    BMP_FILE_PREFIX : string;
    NES_FILEPATH    : string;
    FM2_FILEPATH    : string := "";
    NES_FILE_BYTES  : integer := 196608
);
end nes_bench;

architecture behavioral of nes_bench is
    type ram_t is array(0 to 16#7FF#) of data_t;
    type vram_t is array(0 to 16#3FFF#) of data_t;
    type sram_t is array(0 to 16#1FFF#) of data_t;
    type oam_t is array(0 to 16#FF#) of data_t;
    type sec_oam_t is array(0 to 16#1F#) of data_t;
    type palette_t is array(0 to 16#1F#) of data_t;
    
    signal prg_ram : ram_t;
    signal sram    : sram_t;
    signal oam     : oam_t;
    signal sec_oam : sec_oam_t;
    signal palette : palette_t;
    signal ciram   : vram_t;
    
    signal prg_ram_bus  : ram_bus_t;
    signal sram_bus     : sram_bus_t;
    signal oam_bus      : oam_bus_t;
    signal sec_oam_bus  : sec_oam_bus_t;
    signal palette_bus  : palette_bus_t;
    signal ciram_bus    : chr_bus_t;
    signal file_bus_prg : file_bus_t;
    signal file_bus_chr : file_bus_t;
    
    signal data_to_sram       : data_t;
    signal data_from_sram     : data_t;
    signal data_to_prg_ram    : data_t;
    signal data_from_prg_ram  : data_t;
    signal data_to_oam        : data_t;
    signal data_from_oam      : data_t;
    signal data_to_sec_oam    : data_t;
    signal data_from_sec_oam  : data_t;
    signal data_to_palette    : data_t;
    signal data_from_palette  : data_t;
    signal data_from_ciram    : data_t;
    signal data_to_ciram      : data_t;
    signal data_from_file_prg : data_t;
    signal data_from_file_chr : data_t;
    
    signal audio_out : mixed_audio_t;
    signal pixel_bus : pixel_bus_t;

    signal joy_strobe : std_logic;

    signal shift_joy_1 : std_logic;
    signal joy_1_val   : std_logic;

    signal shift_joy_2 : std_logic;
    signal joy_2_val   : std_logic;

    signal ppu_clk_en : boolean;
    signal cpu_clk_en : boolean;
    
    signal reset : boolean;
    
    signal clk_50mhz : std_logic := '0';

    signal output_ready : boolean;
    
begin

    soc : nes_soc
    port map
    (
        clk_50mhz => clk_50mhz,
        reset => false,

        nes_running => output_ready,

        ppu_clk_en => ppu_clk_en,
        cpu_clk_en => cpu_clk_en,
        
        file_bus_prg => file_bus_prg,
        data_from_file_prg => data_from_file_prg,
        
        file_bus_chr => file_bus_chr,
        data_from_file_chr => data_from_file_chr,
        
        sram_bus => sram_bus,
        data_to_sram => data_to_sram,
        data_from_sram => data_from_sram,
        
        prg_ram_bus => prg_ram_bus,
        data_to_prg_ram => data_to_prg_ram,
        data_from_prg_ram => data_from_prg_ram,
        
        oam_bus => oam_bus,
        data_to_oam => data_to_oam,
        data_from_oam => data_from_oam,
        
        sec_oam_bus => sec_oam_bus,
        data_to_sec_oam => data_to_sec_oam,
        data_from_sec_oam => data_from_sec_oam,
        
        palette_bus => palette_bus,
        data_to_palette => data_to_palette,
        data_from_palette => data_from_palette,
        
        ciram_bus => ciram_bus,
        data_to_ciram => data_to_ciram,
        data_from_ciram => data_from_ciram,
        
        pixel_bus => pixel_bus,
        audio => audio_out,

        joy_strobe => joy_strobe,

        shift_joy_1 => shift_joy_1,
        joy_1_val => joy_1_val,

        shift_joy_2 => shift_joy_2,
        joy_2_val => joy_2_val
    );
    
    ppu_recorder : ppu_video_record
    generic map
    (
        FILE_PREFIX => BMP_FILE_PREFIX
    )
    port map
    (
        clk => clk_50mhz,
        clk_en => ppu_clk_en,
        pixel_bus => pixel_bus,
        ready => output_ready,
        done => false
    );

    apu_recorder : apu_audio_record
    generic map
    (
        FILEPATH => AU_FILEPATH
    )
    port map
    (
        clk => clk_50mhz,
        clk_en => cpu_clk_en,
        audio => audio_out,
        ready => output_ready,
        done => false
    );

    fm2_controller : fm2_joystick
    generic map
    (
        FILEPATH => FM2_FILEPATH
    )
    port map
    (
        frame_valid => pixel_bus.frame_valid,

        joy_strobe => joy_strobe,

        shift_joy_1 => shift_joy_1,
        joy_1_val => joy_1_val,

        shift_joy_2 => shift_joy_2,
        joy_2_val => joy_2_val
    );
    
    nes_file : file_memory
    generic map
    (
       FILEPATH => NES_FILEPATH,
       MEM_BYTES => NES_FILE_BYTES
    )
    port map
    (
       file_bus_1 => file_bus_prg,
       data_from_file_1 => data_from_file_prg,
       
       file_bus_2 => file_bus_chr,
       data_from_file_2 => data_from_file_chr
    );
    
    process(all)
    begin
        if is_bus_write(sram_bus)
        then
            sram(to_integer(sram_bus.address)) <= data_to_sram;
        elsif is_bus_read(sram_bus)
        then
            data_from_sram <= sram(to_integer(sram_bus.address));
        end if;
    end process;
    
    process(all)
    begin
        if is_bus_write(prg_ram_bus)
        then
            prg_ram(to_integer(prg_ram_bus.address)) <= data_to_prg_ram;
        elsif is_bus_read(prg_ram_bus)
        then
            data_from_prg_ram <= prg_ram(to_integer(prg_ram_bus.address));
        end if;
    end process;
    
    process(all)
    begin
        if is_bus_write(ciram_bus)
        then
            ciram(to_integer(ciram_bus.address)) <= data_to_ciram;
        elsif is_bus_read(ciram_bus)
        then
            data_from_ciram <= ciram(to_integer(ciram_bus.address));
        end if;
    end process;
    
    process(all)
    begin
        if is_bus_write(oam_bus)
        then
            oam(to_integer(oam_bus.address)) <= data_to_oam;
        elsif is_bus_read(oam_bus)
        then
            data_from_oam <= oam(to_integer(oam_bus.address));
        end if;
    end process;
    
    process(all)
    begin
        if is_bus_write(sec_oam_bus)
        then
            sec_oam(to_integer(sec_oam_bus.address)) <= data_to_sec_oam;
        elsif is_bus_read(sec_oam_bus)
        then
            data_from_sec_oam <= sec_oam(to_integer(sec_oam_bus.address));
        end if;
    end process;
    
    process(all)
    begin
        if is_bus_write(palette_bus)
        then
            palette(to_integer(palette_bus.address)) <= data_to_palette;
        elsif is_bus_read(palette_bus)
        then
            data_from_palette <= palette(to_integer(palette_bus.address));
        end if;
    end process;
    
    clk_50mhz_gen : clock
    generic map
    (
        PERIOD => 20 ns
    )
    port map
    (
        clk => clk_50mhz,
        done => false
    );

end behavioral;