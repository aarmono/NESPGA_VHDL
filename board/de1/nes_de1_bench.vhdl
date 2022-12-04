library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.file_bus_types.all;
use work.binary_io.all;
use work.au_file.all;
use work.utilities.all;
use work.de1_types.all;
use work.simulation.all;

entity nes_de1_bench is
generic
(
    AU_FILEPATH     : string;
    BMP_FILE_PREFIX : string;
    NES_FILEPATH    : string;
    NES_FILE_BYTES  : integer := 196608
);
end nes_de1_bench;

architecture behavioral of nes_de1_bench is
    signal clk_50 : std_logic := '0';
    signal clk_24 : std_logic := '0';
    signal clk_aud : std_logic := '0';
    
    signal i2c_sdat : std_logic;
    signal i2c_sclk : std_logic;
    
    signal fl_dq   : std_logic_vector(7 downto 0);
    signal fl_addr : std_logic_vector(21 downto 0);
    signal fl_oe_n : std_logic;

    signal flash_bus : file_bus_t;

    signal sram_dq   : std_logic_vector(15 downto 0);
    signal sram_addr : std_logic_vector(17 downto 0);
    signal sram_oe_n : std_logic;
    signal sram_we_n : std_logic;
    
    signal bclk    : std_logic;
    signal dacdat  : std_logic;
    signal daclrck : std_logic;

    signal vga_r    : std_logic_vector(3 downto 0);
    signal vga_g    : std_logic_vector(3 downto 0);
    signal vga_b    : std_logic_vector(3 downto 0);
    signal vga_hs   : std_logic;
    signal vga_vs   : std_logic;
    signal vga_lval : std_logic;
    signal vga_fval : std_logic;

    signal vga_out : vga_out_t;

    subtype sram_data_t is std_logic_vector(15 downto 0);
    type sram_t is array(0 to (2**sram_addr'length)-1) of sram_data_t;
    signal sram : sram_t := (others => (others => '0'));
    
    file audio_file : byte_file_t;
    signal aud_initialized : boolean := false;
    signal aud_shift : std_logic_vector(15 downto 0) := x"0000";
    signal aud_count : unsigned(3 downto 0) := x"F";
begin

    nes : entity work.nes_de1(behavioral)
    port map
    (
        CLOCK_50 => clk_50,
        CLOCK_24 => clk_24,
        CLOCK_AUD => clk_aud,
        
        I2C_SDAT => i2c_sdat,
        I2C_SCLK => i2c_sclk,
        
        FL_DQ => fl_dq,
        FL_ADDR => fl_addr,
        FL_OE_N => fl_oe_n,

        SRAM_DQ => sram_dq,
        SRAM_ADDR => sram_addr,
        SRAM_OE_N => sram_oe_n,
        SRAM_WE_N => sram_we_n,

        VGA_R => vga_r,
        VGA_G => vga_g,
        VGA_B => vga_b,
        VGA_HS => vga_hs,
        VGA_VS => vga_vs,
        VGA_LVAL => vga_lval,
        VGA_FVAL => vga_fval,
        
        AUD_BCLK => bclk,
        AUD_DACDAT => dacdat,
        AUD_DACLRCK => daclrck
    );

    vga_out.color.red <= VGA_R;
    vga_out.color.green <= VGA_G;
    vga_out.color.blue <= VGA_B;
    vga_out.h_sync <= VGA_HS;
    vga_out.v_sync <= VGA_VS;
    vga_out.lval <= VGA_LVAL = '1';
    vga_out.fval <= VGA_FVAL = '1';

    process(bclk)
        variable aud_out : std_logic_vector(15 downto 0);
    begin
    if rising_edge(bclk) then
        if not aud_initialized
        then
            au_fopen_16(audio_file, AU_FILEPATH, x"00017700");
            aud_initialized <= true;
        end if;
        
        aud_out := aud_shift;
        if daclrck = '1'
        then
            aud_out(to_integer(aud_count)) := dacdat;
            if aud_count = x"0"
            then
                au_fwrite_16(audio_file, aud_out);
                --flush(audio_file);
            end if;
            
            aud_shift <= aud_out;
            aud_count <= aud_count - "1";
        end if;
    end if;
    end process;
    
    process(all)
    begin
        if sram_oe_n = '1'
        then
            sram_dq <= (others => 'Z');
            if sram_we_n = '0'
            then
                sram(to_integer(unsigned(sram_addr))) <= sram_dq;
            end if;
        else
            sram_dq <= sram(to_integer(unsigned(sram_addr)));
        end if;
    end process;
    

    flash_bus.read <= fl_oe_n = '0';
    flash_bus.write <= false;
    flash_bus.address <= fl_addr(file_addr_t'range);

    nes_file : file_memory
    generic map
    (
       FILEPATH => NES_FILEPATH,
       MEM_BYTES => NES_FILE_BYTES,
       READ_DELAY => 110 ns
    )
    port map
    (
       file_bus_1 => flash_bus,
       data_from_file_1 => fl_dq
    );

    vga_recorder : entity work.vga_video_record(behavioral)
    generic map
    (
        FILE_PREFIX => BMP_FILE_PREFIX
    )
    port map
    (
        clk => clk_24,

        vga_out => vga_out
    );

    clk_50mhz_gen : clock
    generic map
    (
        PERIOD => 20 ns
    )
    port map
    (
        clk => clk_50,
        done => false
    );

    clk_24mhz_gen : clock
    generic map
    (
        PERIOD => 42 ns
    )
    port map
    (
        clk => clk_24,
        done => false
    );

    clk_aud_gen : clock
    generic map
    (
        PERIOD => 54 ns
    )
    port map
    (
        clk => clk_aud,
        done => false
    );

end behavioral;