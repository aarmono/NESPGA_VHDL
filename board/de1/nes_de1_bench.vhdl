library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use work.nes_types.all;
use work.cart_pin_types.all;
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
    -- With ROM_CART_SLOT the cartridge runs on a DE1 of its own (cart_de1)
    -- in the cartridge slot of nes_de1. The ROM file is on the cartridge's
    -- SD card. Both sides driving a data bus is written to the output
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
    RETURN_HOLD_MS  : positive := 2000;
    -- Report the frame lock's phase error and stretch rate once a frame
    LOG_LOCK        : boolean := false;
    -- Hold the console's reset button until the cartridge is ready, as for
    -- a cartridge that is configured after the console's reset. Otherwise
    -- both power up together and the console runs the cartridge's boot stub
    -- until then
    CART_HOLD_RESET : boolean := false;
    -- The period of the cartridge's clock in ps, and how long after the
    -- console's it starts: the two boards have an oscillator each
    CART_CLK_PERIOD_PS : positive := 20000;
    CART_CLK_OFFSET_PS : natural := 7000;
    -- See cart_de1
    CART_SRAM_READ_CLOCKS : positive := 2;
    -- The address bits of the cartridge's SRAM. The DE1's 18 hold a ROM
    -- file of up to 256 KB; 22 hold any
    CART_SRAM_ADDR_BITS : positive := 18;
    -- The cartridge's card holds a filesystem, and its SD menu loads the
    -- ROM file (cart_de1's USE_SD_MENU). The controller generics above then
    -- work the menu, which reads the console's controller
    CART_SD_MENU : boolean := false;
    -- Write this many CPU cycles and this many PPU accesses of the
    -- cartridge pins to the output, from CART_TRACE_FROM_MS and once the
    -- cartridge is ready: the address, R/W and data as M2 falls, or as /RD
    -- or /WR rises
    CART_TRACE_CYCLES   : natural := 0;
    CART_TRACE_ACCESSES : natural := 0;
    CART_TRACE_FROM_MS  : natural := 0
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

    signal key : std_logic_vector(3 downto 0) := (others => '1');

    -- The cartridge connector between the two boards
    signal console_pins : cart_console_pins_t;
    signal board_pins   : cart_board_pins_t := CART_BOARD_PINS_IDLE;

    file audio_file : byte_file_t;
    signal aud_initialized : boolean := false;
    signal aud_shift : std_logic_vector(15 downto 0) := x"0000";
    signal aud_count : natural range 0 to 2**4-1 := 2**4-1;

    -- 27 MHz * 29/31, as vga_pll makes it, to the nearest ps
    constant VGA_PERIOD : time := 39591 ps;
begin

    nes : nes_de1
    generic map
    (
        ROM_CONFIG => ROM_CONFIG,
        -- The oscillators of the random number generator cannot be simulated
        POWER_UP_MODE => POWER_UP_DETERMINISTIC,
        RETURN_HOLD_MS => RETURN_HOLD_MS,
        -- The bench's VGA clock, which time's precision rounds from vga_pll's
        CLOCK_VGA_FREQ => 1.0e12 / real(VGA_PERIOD / 1 ps),
        LOG_LOCK => LOG_LOCK
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

        KEY => key,
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

        VGA_R => vga_r,
        VGA_G => vga_g,
        VGA_B => vga_b,
        VGA_HS => vga_hs,
        VGA_VS => vga_vs,
        VGA_LVAL => vga_lval,
        VGA_FVAL => vga_fval,
        
        AUD_BCLK => bclk,
        AUD_DACDAT => dacdat,
        AUD_DACLRCK => daclrck,

        CART_PINS_OUT => console_pins,
        CART_PINS_IN => board_pins
    );

    gen_cart : if ROM_CONFIG = ROM_CART_SLOT generate
        signal clk_cart    : std_logic := '0';

        signal board_drive : cart_board_drive_t;
        signal cart_ready  : std_logic;
        signal cart_loading   : std_logic;
        signal cart_load_failed : std_logic;

        signal cart_sram_addr :
            std_logic_vector(CART_SRAM_ADDR_BITS - 1 downto 0);
        signal cart_sram_dq   : std_logic_vector(15 downto 0);
        signal cart_sram_ce_n : std_logic;
        signal cart_sram_oe_n : std_logic;
        signal cart_sram_we_n : std_logic;
        signal cart_sram_lb_n : std_logic;
        signal cart_sram_ub_n : std_logic;

        signal cart_sd_dat  : std_logic;
        signal cart_sd_dat3 : std_logic;
        signal cart_sd_cmd  : std_logic;
        signal cart_sd_clk  : std_logic;

        constant CART_CLK_PERIOD : time := CART_CLK_PERIOD_PS * 1 ps;
        constant CART_CLK_OFFSET : time := CART_CLK_OFFSET_PS * 1 ps;
    begin
        -- The reset button
        key(0) <= '1' when cart_ready = '1' or not CART_HOLD_RESET else '0';

        cart : cart_de1
        generic map
        (
            POWER_UP_MODE => POWER_UP_DETERMINISTIC,
            DOT_CLOCKS => 186243 ps / CART_CLK_PERIOD,
            SRAM_ADDR_BITS => CART_SRAM_ADDR_BITS,
            SRAM_READ_CLOCKS => CART_SRAM_READ_CLOCKS,
            USE_SD_MENU => CART_SD_MENU,
            RETURN_HOLD_MS => RETURN_HOLD_MS
        )
        port map
        (
            CLOCK_50 => clk_cart,
            RESET_N => '1',

            READY => cart_ready,
            LOADING => cart_loading,
            LOAD_FAILED => cart_load_failed,

            SRAM_ADDR => cart_sram_addr,
            SRAM_DQ => cart_sram_dq,
            SRAM_CE_N => cart_sram_ce_n,
            SRAM_OE_N => cart_sram_oe_n,
            SRAM_WE_N => cart_sram_we_n,
            SRAM_LB_N => cart_sram_lb_n,
            SRAM_UB_N => cart_sram_ub_n,

            SD_DAT => cart_sd_dat,
            SD_DAT3 => cart_sd_dat3,
            SD_CMD => cart_sd_cmd,
            SD_CLK => cart_sd_clk,

            CART_PINS_IN => console_pins,
            CART_CPU_DATA => board_pins.cpu_data,
            CART_PPU_DATA => board_pins.ppu_data,
            CART_PINS_OUT => board_drive
        );

        -- The cartridge's status, as its LEDs would show it
        process(cart_ready, cart_loading, cart_load_failed)
        is
            variable l : line;
        begin
            write(l, string'("nes_de1_bench: "));
            write(l, now);
            write(l, string'(" cartridge loading "));
            write(l, cart_loading);
            write(l, string'(" ready "));
            write(l, cart_ready);
            write(l, string'(" failed "));
            write(l, cart_load_failed);
            writeline(output, l);
        end process;

        process(console_pins.m2, console_pins.romsel_n)
        is
            variable cycles : natural := 0;
            -- /ROMSEL was low in this cycle. It rises as M2 falls
            variable romsel : std_logic := '0';
            variable l      : line;
        begin
            if falling_edge(console_pins.romsel_n)
            then
                romsel := '1';
            end if;

            if falling_edge(console_pins.m2) and cart_ready = '1' and
               now >= CART_TRACE_FROM_MS * 1 ms and
               cycles < CART_TRACE_CYCLES
            then
                write(l, string'("nes_de1_bench: "));
                write(l, now);
                write(l, string'(" CPU "));
                write(l, to_hstring(romsel & console_pins.cpu_addr));
                if console_pins.cpu_rw = '1'
                then
                    write(l, string'(" R "));
                else
                    write(l, string'(" W "));
                end if;
                write(l, to_hstring(board_pins.cpu_data));
                writeline(output, l);
                cycles := cycles + 1;
            end if;

            if falling_edge(console_pins.m2)
            then
                romsel := '0';
            end if;
        end process;

        process(console_pins.ppu_rd_n, console_pins.ppu_wr_n)
        is
            variable accesses : natural := 0;
            variable l        : line;
        begin
            if (rising_edge(console_pins.ppu_rd_n) or
                rising_edge(console_pins.ppu_wr_n)) and cart_ready = '1' and
               now >= CART_TRACE_FROM_MS * 1 ms and
               accesses < CART_TRACE_ACCESSES
            then
                write(l, string'("nes_de1_bench: "));
                write(l, now);
                write(l, string'(" PPU "));
                write(l, to_hstring("00" & console_pins.ppu_addr));
                if rising_edge(console_pins.ppu_rd_n)
                then
                    write(l, string'(" R "));
                else
                    write(l, string'(" W "));
                end if;
                write(l, to_hstring(board_pins.ppu_data));
                write(l, string'(" CIRAM /CE "));
                write(l, board_pins.ciram_ce_n);
                write(l, string'(" A10 "));
                write(l, board_pins.ciram_a10);
                writeline(output, l);
                accesses := accesses + 1;
            end if;
        end process;

        -- The shared data buses. A bit nobody drives keeps its last value,
        -- which a board would do with bus hold
        process(console_pins, board_drive)
        is
            variable value : data_t := (others => '0');
        begin
            for i in value'range
            loop
                if console_pins.cpu_data_oe and board_drive.cpu_data_oe(i) = '1'
                then
                    value(i) := 'X';
                elsif console_pins.cpu_data_oe
                then
                    value(i) := console_pins.cpu_data(i);
                elsif board_drive.cpu_data_oe(i) = '1'
                then
                    value(i) := board_drive.cpu_data(i);
                end if;
            end loop;

            if console_pins.cpu_data_oe and board_drive.cpu_data_oe /= x"00"
            then
                report "nes_de1_bench: CPU data bus driven by both sides"
                    severity error;
            end if;

            board_pins.cpu_data <= value;
        end process;

        process(console_pins, board_drive)
        is
            variable value : data_t := (others => '0');
        begin
            if console_pins.ppu_data_oe and board_drive.ppu_data_oe
            then
                report "nes_de1_bench: PPU data bus driven by both sides"
                    severity error;
                value := (others => 'X');
            elsif console_pins.ppu_data_oe
            then
                value := console_pins.ppu_data;
            elsif board_drive.ppu_data_oe
            then
                value := board_drive.ppu_data;
            end if;
            board_pins.ppu_data <= value;
        end process;

        -- /IRQ is pulled up by the console
        board_pins.irq_n <= '0' when board_drive.irq_n = '0' else '1';
        board_pins.ciram_ce_n <= board_drive.ciram_ce_n;
        board_pins.ciram_a10 <= board_drive.ciram_a10;

        cart_ram : sram_16
        generic map
        (
            ADDR_BITS => CART_SRAM_ADDR_BITS
        )
        port map
        (
            addr => cart_sram_addr,
            dq => cart_sram_dq,
            ce_n => cart_sram_ce_n,
            oe_n => cart_sram_oe_n,
            we_n => cart_sram_we_n,
            lb_n => cart_sram_lb_n,
            ub_n => cart_sram_ub_n
        );

        cart_sd : entity work.sd_card(behavioral)
        generic map
        (
            FILEPATH => NES_FILEPATH,
            FILE_BYTES => NES_FILE_BYTES
        )
        port map
        (
            sck => cart_sd_clk,
            cs_n => cart_sd_dat3,
            mosi => cart_sd_cmd,
            miso => cart_sd_dat
        );

        cart_sd_dat <= 'H';

        clk_cart_gen : clock
        generic map
        (
            PERIOD => CART_CLK_PERIOD,
            OFFSET => CART_CLK_PERIOD + CART_CLK_OFFSET
        )
        port map
        (
            clk => clk_cart,
            done => false
        );
    end generate;

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
        PERIOD => VGA_PERIOD
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