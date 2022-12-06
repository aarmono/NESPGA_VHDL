library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.perhipheral_types.all;

package lib_wm8731 is
    
    subtype wm_addr_t is std_logic_vector(6 downto 0);
    subtype wm_data_t is std_logic_vector(8 downto 0);
    
    type serial_bus_t is record
        sdin : std_logic;
        sclk : std_logic;
    end record;
    
    subtype wm_dat_count_t is unsigned(6 downto 0);

    type wm8731_dat_t is record
        fifo  : std_logic_vector(23 downto 0);
        count : wm_dat_count_t;
    end record;
    
    constant RESET_DAT : wm8731_dat_t :=
    (
        fifo => (others => '0'),
        count => (others => '0')
    );
    
    function sdat_out(val : wm8731_dat_t) return std_logic;
    function sclk_out(val : wm8731_dat_t) return std_logic;
    function start_write(addr : wm_addr_t; data : wm_data_t) return wm8731_dat_t;
    function is_idle(val : wm8731_dat_t) return boolean;
    function reset_val(val : wm8731_dat_t) return wm8731_dat_t;
    function next_dat(cur_val : wm8731_dat_t) return wm8731_dat_t;
    
    type audio_bus_t is record
        bclk    : std_logic;
        daclrck : std_logic;
        dacdat  : std_logic;
    end record;
    
    type wm8731_aud_t is record
        fifo  : wm_audio_t;
        count : unsigned(5 downto 0);
    end record;
    
    constant RESET_AUD : wm8731_aud_t :=
    (
        fifo => (others => '0'),
        count => (others => '0')
    );
    
    function bus_out(val : wm8731_aud_t) return audio_bus_t;
    function start_sample(audio : wm_audio_t) return wm8731_aud_t;
    function is_idle(val : wm8731_aud_t) return boolean;
    function reset_val(val : wm8731_aud_t) return wm8731_aud_t;
    function next_aud(cur_val : wm8731_aud_t) return wm8731_aud_t;
    
end lib_wm8731;

package body lib_wm8731 is
    
    -- wm8731_dat_t {
    constant START_HIGH   : wm_dat_count_t := to_unsigned(111, wm_dat_count_t'length);
    constant START_LOW    : wm_dat_count_t := to_unsigned(110, wm_dat_count_t'length);
    constant END_LOW      : wm_dat_count_t := to_unsigned(1, wm_dat_count_t'length);
    constant END_HIGH     : wm_dat_count_t := to_unsigned(0, wm_dat_count_t'length);
    constant ACK_ADDR_S   : wm_dat_count_t := to_unsigned(76, wm_dat_count_t'length);
    constant ACK_ADDR_H   : wm_dat_count_t := to_unsigned(75, wm_dat_count_t'length);
    constant ACK_DATA_L_S : wm_dat_count_t := to_unsigned(40, wm_dat_count_t'length);
    constant ACK_DATA_L_H : wm_dat_count_t := to_unsigned(39, wm_dat_count_t'length);
    constant ACK_DATA_H_S : wm_dat_count_t := to_unsigned(4, wm_dat_count_t'length);
    constant ACK_DATA_H_H : wm_dat_count_t := to_unsigned(3, wm_dat_count_t'length);
    
    function is_idle(val : wm8731_dat_t) return boolean
    is
    begin
        return val.count = ZERO(val.count);
    end;
    
    function reset_val(val : wm8731_dat_t) return wm8731_dat_t
    is
        variable ret : wm8731_dat_t;
    begin
        ret.count := ZERO(val.count);
        ret.fifo := (others => '-');
        
        return ret;
    end;
    
    function start_write(addr : wm_addr_t; data : wm_data_t) return wm8731_dat_t
    is
        variable ret : wm8731_dat_t;
    begin
        ret.fifo := x"34" & addr & data;
        ret.count := START_HIGH;
        
        return ret;
    end;
    
    function sclk_out(val : wm8731_dat_t) return std_logic
    is
        variable ret : std_logic;
    begin
        if val.count = START_HIGH or
           val.count = END_LOW or
           val.count = END_HIGH
        then
            ret := '1';
        else
            ret := val.count(1);
        end if;
        
        return ret;
    end;
    
    function sdat_out(val : wm8731_dat_t) return std_logic
    is
        variable ret : std_logic;
    begin
        if val.count = START_HIGH or
           val.count = END_LOW
        then
            ret := '0';
        elsif val.count = END_HIGH
        then
            ret := '1';
        elsif val.count = ACK_ADDR_S or
              val.count = ACK_ADDR_H or
              val.count = ACK_DATA_L_S or
              val.count = ACK_DATA_L_H or
              val.count = ACK_DATA_H_S or
              val.count = ACK_DATA_H_H
        then
            ret := 'Z';
        else
            ret := val.fifo(val.fifo'high);
        end if;
        
        return ret;
    end;
    
    function next_dat(cur_val : wm8731_dat_t) return wm8731_dat_t
    is
        variable next_val : wm8731_dat_t;

        constant COUNT_LEN : positive := wm_dat_count_t'length;
        constant COUNT_HIGH : integer := wm_dat_count_t'high;

        constant CYCLE_LEN : positive := COUNT_LEN - 2;
        constant CYCLE_HIGH : integer := CYCLE_LEN - 1;
        
        variable cur_cycle : unsigned(CYCLE_HIGH downto 0);
    begin
        next_val := cur_val;
        cur_cycle := cur_val.count(COUNT_HIGH downto 2);

        if cur_val.count(1 downto 0) = "01" and
           cur_cycle /= START_HIGH(COUNT_HIGH downto 2) and
           cur_cycle /= ACK_ADDR_S(COUNT_HIGH downto 2) and
           cur_cycle /= ACK_DATA_L_S(COUNT_HIGH downto 2) and
           cur_cycle /= ACK_DATA_H_S(COUNT_HIGH downto 2)
        then
            next_val.fifo := cur_val.fifo(cur_val.fifo'high-1 downto 0) & '0';
        end if;
        
        if cur_val.count > ZERO(cur_val.count)
        then
            next_val.count := cur_val.count - "1";
        end if;
        
        return next_val;
    end;
    -- }
    
    function bus_out(val : wm8731_aud_t) return audio_bus_t
    is
        variable ret : audio_bus_t;
        variable idx : natural;
    begin
        idx := natural(to_integer(val.count(4 downto 1)));
        
        ret.daclrck := val.count(5);
        ret.bclk := not val.count(0);
        ret.dacdat := val.fifo(idx);
        
        return ret;
    end;
    
    function start_sample(audio : wm_audio_t) return wm8731_aud_t
    is
        variable ret : wm8731_aud_t;
    begin
        ret.fifo := audio;
        ret.count := (others => '1');
        
        return ret;
    end;
    
    function is_idle(val : wm8731_aud_t) return boolean
    is
    begin
        return val.count = ZERO(val.count);
    end;
    
    function reset_val(val : wm8731_aud_t) return wm8731_aud_t
    is
        variable ret : wm8731_aud_t;
    begin
        ret.count := ZERO(ret.count);
        ret.fifo := (others => '-');
        
        return ret;
    end;
    
    function next_aud(cur_val : wm8731_aud_t) return wm8731_aud_t
    is
        variable next_val : wm8731_aud_t;
    begin
        next_val := cur_val;
        if cur_val.count > ZERO(cur_val.count)
        then
            next_val.count := cur_val.count - "1";
        end if;
        
        return next_val;
    end;
    
end package body;