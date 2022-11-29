library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.lib_ppu.all;
use work.ppu_bus_types.all;
use work.chr_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.palette_bus_types.all;
use work.nes_types.all;
use work.utilities.all;

entity ppu is
port
(
    clk               : in std_logic;
    clk_en            : in boolean := true;
    clk_sync          : in boolean := true;
    reset             : in boolean;

    chr_bus           : out chr_bus_t;
    chr_data_from_ppu : out data_t;
    chr_data_to_ppu   : in  data_t;
    
    oam_bus           : out oam_bus_t;
    data_to_oam       : out data_t;
    data_from_oam     : in data_t;
    
    sec_oam_bus       : out sec_oam_bus_t;
    data_to_sec_oam   : out data_t;
    data_from_sec_oam : in data_t;
    
    palette_bus       : out palette_bus_t;
    data_to_palette   : out pixel_t;
    data_from_palette : in pixel_t;
    
    cpu_bus           : in  ppu_bus_t;
    prg_data_from_ppu : out data_t;
    prg_data_to_ppu   : in  data_t;

    pixel_bus         : out pixel_bus_t;
    vint              : out boolean
);
end ppu;

architecture behavioral of ppu is

    signal reg      : ppu_reg_t := RESET_PPU_REG;
    signal reg_next : ppu_reg_t;

    signal vint_next : boolean;
begin

    process(clk)
    begin
    if rising_edge(clk) and clk_en
    then
        if reset
        then
            reg <= RESET_PPU_REG;
            vint <= false;
        else
            reg <= reg_next;

            if clk_sync
            then
                vint <= vint_next;
            end if;
        end if;
    end if;
    end process;
    
    process(all)
        variable render_in : ppu_render_in_t;
        variable render_out : ppu_render_out_t;
    begin
        render_in.reg := reg;
        
        render_in.cpu_bus := cpu_bus;
        -- Only perform CPU bus actions during the "sync" cycle when both
        -- the CPU and PPU will be clocked
        render_in.cpu_bus.write := render_in.cpu_bus.write and clk_sync;
        render_in.cpu_bus.read := render_in.cpu_bus.read and clk_sync;
        render_in.data_from_cpu := prg_data_to_ppu;
        
        render_in.data_from_oam := data_from_oam;
        render_in.data_from_sec_oam := data_from_sec_oam;
        render_in.data_from_chr := chr_data_to_ppu;
        render_in.data_from_palette := data_from_palette;
        
        render_out := cycle_ppu(render_in);
        
        reg_next <= render_out.reg;
        
        chr_bus <= render_out.chr_bus;
        chr_data_from_ppu <= render_out.data_to_chr;
        
        oam_bus <= render_out.oam_bus;
        data_to_oam <= render_out.data_to_oam;
        
        sec_oam_bus <= render_out.sec_oam_bus;
        data_to_sec_oam <= render_out.data_to_sec_oam;
        
        palette_bus <= render_out.palette_bus;
        data_to_palette <= render_out.data_to_palette;
        
        prg_data_from_ppu <= render_out.data_to_cpu;
        
        vint_next <= render_out.vint;
        pixel_bus <= render_out.pixel_bus;
    end process;

end behavioral;
