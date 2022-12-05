library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.lib_wm8731.all;
use work.perhipheral_types.all;

entity wm8731 is
port
(
    clk      : in std_logic;
    reset    : in boolean;
    
    audio    : in wm_audio_t;
    
    sclk     : out std_logic;
    sdat     : out std_logic;
    bclk     : out std_logic;
    dac_dat  : out std_logic;
    dac_lrck : out std_logic
);
end wm8731;

architecture behavioral of wm8731 is

    constant CLOCK_RATE : unsigned(27 downto 0) := x"1194000";
    constant SAMPLE_RATE : unsigned(16 downto 0) := to_unsigned(96000, 17);
    constant SAMPLE_SIZE : unsigned(4 downto 0) := to_unsigned(16, 5);
    constant CLOCK_DIV : unsigned(27 downto 0) := 
        CLOCK_RATE / (SAMPLE_RATE * SAMPLE_SIZE * 4);
    constant AUD_PERIOD : unsigned(1 downto 0) := resize(CLOCK_DIV - "1", 2);
    constant DAT_FREQ : unsigned(14 downto 0) := to_unsigned(20000, 15);
    constant DAT_PERIOD : unsigned(9 downto 0) :=
        resize((CLOCK_RATE / DAT_FREQ) -  "1", 10);
        
    type reg_t is record
        data    : wm8731_dat_t;
        audio   : wm8731_aud_t;
        count   : unsigned(wm_addr_t'RANGE);
        aud_div : unsigned(1 downto 0);
        dat_div : unsigned(9 downto 0);
    end record;
    
    constant RESET_REG : reg_t :=
    (
        data => RESET_DAT,
        audio => RESET_AUD,
        count => (others => '0'),
        aud_div => AUD_PERIOD,
        dat_div => DAT_PERIOD
    );  
    
    signal reg    : reg_t := RESET_REG;
    signal reg_in : reg_t;
    
begin
    
    process(reg, audio, reset)
        variable v_reg    : reg_t;
        variable v_sdat   : std_logic;
        variable v_sclk   : std_logic;
        variable v_audio  : audio_bus_t;
    begin
        v_audio := bus_out(reg.audio);
        v_reg := reg;
        
        v_sdat := sdat_out(reg.data);
        
        if reset
        then
            v_reg.data := reset_val(reg.data);
            v_reg.count := ZERO(reg.count);
            v_reg.dat_div := DAT_PERIOD;
        elsif reg.dat_div = ZERO(reg.dat_div)
        then
            v_reg.dat_div := DAT_PERIOD;
            if is_idle(reg.data)
            then
                case reg.count is
                    -- Mute input and assign value to both L and R channels
                    when "0000000" => 
                        v_reg.data := start_write(wm_addr_t(reg.count), b"1_1000_0000");
                    -- 0dB gain, enable zero-cross circuit (to update volume when
                    -- output near zero), and assign to both L and R channels
                    when "0000010" =>
                        v_reg.data := start_write(wm_addr_t(reg.count), b"1_1_0110000");
                    -- Route DAC to Lineout, disable others
                    when "0000100" =>
                        v_reg.data := start_write(wm_addr_t(reg.count), b"0_11_0_1_0_0_1_0");
                    -- Enable high-pass filter, disable soft mute and de-emphasis
                    when "0000101" =>
                        v_reg.data := start_write(wm_addr_t(reg.count), b"0000_1_0_10_1");
                    -- Power control
                    when "0000110" =>
                        v_reg.data := start_write(wm_addr_t(reg.count), b"0_0_1_1_0_0_1_1_1");
                    -- Data mode: left-justified, 16-bit, right on DACLRCK low,
                    -- no swap, slave mode, no clock invert
                    when "0000111" =>
                        v_reg.data := start_write(wm_addr_t(reg.count), b"0_0_0_0_0_00_01");
                    -- Sample mode: no clock divider/multiplier, 96KHz, normal mode
                    when "0001000" =>
                        v_reg.data := start_write(wm_addr_t(reg.count), b"0_0_0_0111_1_0");
                    -- Activate interface
                    when "0001001" =>
                        v_reg.data := start_write(wm_addr_t(reg.count), b"00000000_1");
                    when others =>
                        v_reg.data := reset_val(reg.data);
                end case;
                v_reg.count := reg.count + "1";
            else
                v_reg.data := next_dat(reg.data);
            end if;
        else
            v_reg.dat_div := reg.dat_div - "1";
        end if;
        
        if reset
        then
            v_reg.audio := reset_val(reg.audio);
            v_reg.aud_div := AUD_PERIOD;
        elsif reg.aud_div = ZERO(reg.aud_div)
        then
            if is_idle(reg.audio)
            then
                v_reg.audio := start_sample(audio);
            else
                v_reg.audio := next_aud(reg.audio);
            end if;
            v_reg.aud_div := AUD_PERIOD;
        else
            v_reg.aud_div := reg.aud_div - "1";
        end if;
    
        v_sclk := sclk_out(v_reg.data);
        sclk <= v_sclk;
        sdat <= v_sdat;
        
        bclk <= v_audio.bclk;
        dac_dat <= v_audio.dacdat;
        dac_lrck <= v_audio.daclrck;
        reg_in <= v_reg;
    
    end process;
    
    process(clk)
    begin
    if rising_edge(clk) then
        reg <= reg_in;
    end if;
    end process;
    
end behavioral;