library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.file_bus_types.all;
use work.binary_io.all;
use work.au_file.all;
use work.utilities.all;
use work.de1_types.all;
use work.perhipheral_types.all;
use work.simulation.all;

entity nes_de1_bench is
generic
(
    AU_FILEPATH     : string;
    BMP_FILE_PREFIX : string;
    NES_FILEPATH    : string;
    NES_FILE_BYTES  : integer := 196608;
    ROM_CONFIG      : rom_config_t := ROM_SD_TO_SDRAM;
    -- A on the controller in port 1 is held from JOY_A_FROM_MS until
    -- JOY_A_UNTIL_MS, as when choosing the first entry of the SD menu, and
    -- again from JOY_A2_FROM_MS until JOY_A2_UNTIL_MS. Start and Select are
    -- held from JOY_RETURN_FROM_MS until JOY_RETURN_UNTIL_MS, as when
    -- returning to the menu after RETURN_HOLD_MS. Natural, not time, since
    -- ghdl cannot override time generics
    JOY_A_FROM_MS   : natural := 0;
    JOY_A_UNTIL_MS  : natural := 0;
    JOY_A2_FROM_MS  : natural := 0;
    JOY_A2_UNTIL_MS : natural := 0;
    JOY_RETURN_FROM_MS  : natural := 0;
    JOY_RETURN_UNTIL_MS : natural := 0;
    RETURN_HOLD_MS  : positive := 2000
);
end nes_de1_bench;

architecture behavioral of nes_de1_bench is
    signal clk_50  : std_logic := '0';
    signal clk_vga : std_logic := '0';
    signal clk_aud : std_logic := '0';
    signal clk_we  : std_logic := '0';
    
    signal i2c_sdat : std_logic;
    signal i2c_sclk : std_logic;
    
    signal fl_dq   : std_logic_vector(7 downto 0);
    signal fl_addr : std_logic_vector(21 downto 0);
    signal fl_oe_n : std_logic;

    signal flash_bus : file_bus_t;

    signal dram_addr  : std_logic_vector(11 downto 0);
    signal dram_ba_0  : std_logic;
    signal dram_ba_1  : std_logic;
    signal dram_cas_n : std_logic;
    signal dram_cke   : std_logic;
    signal dram_clk   : std_logic;
    signal dram_cs_n  : std_logic;
    signal dram_dq    : std_logic_vector(15 downto 0);
    signal dram_ldqm  : std_logic;
    signal dram_udqm  : std_logic;
    signal dram_ras_n : std_logic;
    signal dram_we_n  : std_logic;

    signal sd_dat  : std_logic;
    signal sd_dat3 : std_logic;
    signal sd_cmd  : std_logic;
    signal sd_clk  : std_logic;

    signal ps2_clk : std_logic;
    signal ps2_dat : std_logic;

    signal joy_1_latch : std_logic;
    signal joy_1_clk   : std_logic;
    signal joy_1_data  : joy_data_t := JOY_DATA_IDLE;

    signal sram_dq   : std_logic_vector(15 downto 0);
    signal sram_addr : std_logic_vector(17 downto 0);
    signal sram_oe_n : std_logic;
    signal sram_we_n : std_logic;
    signal sram_ce_n : std_logic;
    
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
    
    file audio_file : byte_file_t;
    signal aud_initialized : boolean := false;
    signal aud_shift : std_logic_vector(15 downto 0) := x"0000";
    signal aud_count : natural range 0 to 2**4-1 := 2**4-1;
begin

    nes : nes_de1
    generic map
    (
        ROM_CONFIG => ROM_CONFIG,
        -- The oscillators of the random number generator cannot be simulated
        POWER_UP_MODE => POWER_UP_DETERMINISTIC,
        RETURN_HOLD_MS => RETURN_HOLD_MS
    )
    port map
    (
        CLOCK_50 => clk_50,
        CLOCK_VGA => clk_vga,
        CLOCK_AUD => clk_aud,
        CLOCK_WE => clk_we,
        RESET_N => '1',
        
        I2C_SDAT => i2c_sdat,
        I2C_SCLK => i2c_sclk,

        PS2_CLK => ps2_clk,
        PS2_DAT => ps2_dat,

        JOY_1_LATCH => joy_1_latch,
        JOY_1_CLK => joy_1_clk,
        JOY_1_DATA => joy_1_data,
        JOY_2_LATCH => open,
        JOY_2_CLK => open,

        SW => (others => '0'),
        
        FL_DQ => fl_dq,
        FL_ADDR => fl_addr,
        FL_OE_N => fl_oe_n,

        DRAM_ADDR => dram_addr,
        DRAM_BA_0 => dram_ba_0,
        DRAM_BA_1 => dram_ba_1,
        DRAM_CAS_N => dram_cas_n,
        DRAM_CKE => dram_cke,
        DRAM_CLK => dram_clk,
        DRAM_CS_N => dram_cs_n,
        DRAM_DQ => dram_dq,
        DRAM_LDQM => dram_ldqm,
        DRAM_UDQM => dram_udqm,
        DRAM_RAS_N => dram_ras_n,
        DRAM_WE_N => dram_we_n,

        SD_DAT => sd_dat,
        SD_DAT3 => sd_dat3,
        SD_CMD => sd_cmd,
        SD_CLK => sd_clk,

        SRAM_DQ => sram_dq,
        SRAM_ADDR => sram_addr,
        SRAM_OE_N => sram_oe_n,
        SRAM_WE_N => sram_we_n,
        SRAM_CE_N => sram_ce_n,

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
            aud_out(aud_count) := dacdat;
            if aud_count = 0
            then
                au_fwrite_16(audio_file, aud_out);
                --flush(audio_file);
            end if;
            
            aud_shift <= aud_out;
            aud_count <= wrap(aud_count - 1, 2**4-1);
        end if;
    end if;
    end process;

    video_ram : component sram
    generic map
    (
        clear_on_power_up => true,
        download_on_power_up => false,
        trace_ram_load => false,

        size => 16#40000#,
        adr_width => 18,
        width => 16
    )
    port map
    (
        nCE => sram_ce_n,
        nOE => sram_oe_n,
        nWE => sram_we_n,

        A => sram_addr,
        D => sram_dq
    );
    

    rom_ram : entity work.sdram(behavioral)
    port map
    (
        clk => dram_clk,
        cke => dram_cke,
        cs_n => dram_cs_n,
        ras_n => dram_ras_n,
        cas_n => dram_cas_n,
        we_n => dram_we_n,
        ba(0) => dram_ba_0,
        ba(1) => dram_ba_1,
        addr => dram_addr,
        ldqm => dram_ldqm,
        udqm => dram_udqm,
        dq => dram_dq
    );

    sd : entity work.sd_card(behavioral)
    generic map
    (
        FILEPATH => NES_FILEPATH,
        FILE_BYTES => NES_FILE_BYTES
    )
    port map
    (
        sck => sd_clk,
        cs_n => sd_dat3,
        mosi => sd_cmd,
        miso => sd_dat
    );

    -- A standard controller: a 4021 shift register, which loads the
    -- buttons (low while pressed, A first) while the latch is high, and
    -- shifts when CLK rises
    joy_1 : process(joy_1_latch, joy_1_clk)
        variable shift : std_logic_vector(7 downto 0) := (others => '1');
    begin
        if joy_1_latch = '1'
        then
            shift := (others => '1');
            if (now >= JOY_A_FROM_MS * 1 ms and now < JOY_A_UNTIL_MS * 1 ms) or
               (now >= JOY_A2_FROM_MS * 1 ms and now < JOY_A2_UNTIL_MS * 1 ms)
            then
                shift(0) := '0';
            end if;
            if now >= JOY_RETURN_FROM_MS * 1 ms and
               now < JOY_RETURN_UNTIL_MS * 1 ms
            then
                shift(3 downto 2) := "00";
            end if;
        elsif rising_edge(joy_1_clk)
        then
            shift := '1' & shift(7 downto 1);
        end if;
        joy_1_data(0) <= shift(0);
    end process;

    -- Pull ups on the board
    sd_dat <= 'H';
    ps2_clk <= 'H';
    ps2_dat <= 'H';

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
        clk => clk_vga,

        vga_out => vga_out
    );

    clk_50mhz_gen : clock
    generic map
    (
        PERIOD => 20 ns,
        OFFSET => 20 ns
    )
    port map
    (
        clk => clk_50,
        done => false
    );

    clk_vga_gen : clock
    generic map
    (
        PERIOD => 39683 ps
    )
    port map
    (
        clk => clk_vga,
        done => false
    );

    clk_aud_gen : clock
    generic map
    (
        PERIOD => 54286 ps
    )
    port map
    (
        clk => clk_aud,
        done => false
    );

    clk_we_gen : clock
    generic map
    (
        PERIOD => 20 ns,
        OFFSET => 17857 ps
    )
    port map
    (
        clk => clk_we,
        done => false
    );

end behavioral;