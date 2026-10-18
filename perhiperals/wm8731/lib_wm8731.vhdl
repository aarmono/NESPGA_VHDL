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
    
    subtype wm_dat_count_t is natural range 0 to 2**7-1;

    type wm8731_dat_t is record
        fifo  : std_logic_vector(23 downto 0);
        count : wm_dat_count_t;
    end record;
    
    constant RESET_DAT : wm8731_dat_t :=
    (
        fifo => (others => '0'),
        count => 0
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
    
    subtype wm_aud_count_t is natural range 0 to 2**6-1;

    type wm8731_aud_t is record
        fifo  : wm_audio_t;
        count : wm_aud_count_t;
    end record;
    
    constant RESET_AUD : wm8731_aud_t :=
    (
        fifo => (others => '0'),
        count => 0
    );
    
    function bus_out(val : wm8731_aud_t) return audio_bus_t;
    function start_sample(audio : wm_audio_t) return wm8731_aud_t;
    function is_idle(val : wm8731_aud_t) return boolean;
    function reset_val(val : wm8731_aud_t) return wm8731_aud_t;
    function next_aud(cur_val : wm8731_aud_t) return wm8731_aud_t;
    
end lib_wm8731;

package body lib_wm8731 is
    
    -- wm8731_dat_t {
    constant START_HIGH   : wm_dat_count_t := 111;
    constant START_LOW    : wm_dat_count_t := 110;
    constant END_LOW      : wm_dat_count_t := 1;
    constant END_HIGH     : wm_dat_count_t := 0;
    constant ACK_ADDR_S   : wm_dat_count_t := 76;
    constant ACK_ADDR_H   : wm_dat_count_t := 75;
    constant ACK_DATA_L_S : wm_dat_count_t := 40;
    constant ACK_DATA_L_H : wm_dat_count_t := 39;
    constant ACK_DATA_H_S : wm_dat_count_t := 4;
    constant ACK_DATA_H_H : wm_dat_count_t := 3;
    
    function is_idle(val : wm8731_dat_t) return boolean
    is
    begin
        return val.count = 0;
    end;
    
    function reset_val(val : wm8731_dat_t) return wm8731_dat_t
    is
        variable ret : wm8731_dat_t;
    begin
        ret.count := 0;
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
            ret := to_std_logic(get_bits(val.count, 1, 1) = 1);
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

        -- Each bit takes 4 counts
        variable cur_cycle : natural;
    begin
        next_val := cur_val;
        cur_cycle := cur_val.count / 4;

        if cur_val.count mod 4 = 1 and
           cur_cycle /= START_HIGH / 4 and
           cur_cycle /= ACK_ADDR_S / 4 and
           cur_cycle /= ACK_DATA_L_S / 4 and
           cur_cycle /= ACK_DATA_H_S / 4
        then
            next_val.fifo := cur_val.fifo(cur_val.fifo'high-1 downto 0) & '0';
        end if;
        
        if cur_val.count > 0
        then
            next_val.count := cur_val.count - 1;
        end if;
        
        return next_val;
    end;
    -- }
    
    function bus_out(val : wm8731_aud_t) return audio_bus_t
    is
        variable ret : audio_bus_t;
        variable idx : natural;
    begin
        idx := get_bits(val.count, 4, 1);
        
        ret.daclrck := to_std_logic(get_bits(val.count, 5, 5) = 1);
        ret.bclk := to_std_logic(get_bits(val.count, 0, 0) = 0);
        ret.dacdat := val.fifo(idx);
        
        return ret;
    end;
    
    function start_sample(audio : wm_audio_t) return wm8731_aud_t
    is
        variable ret : wm8731_aud_t;
    begin
        ret.fifo := audio;
        ret.count := wm_aud_count_t'high;
        
        return ret;
    end;
    
    function is_idle(val : wm8731_aud_t) return boolean
    is
    begin
        return val.count = 0;
    end;
    
    function reset_val(val : wm8731_aud_t) return wm8731_aud_t
    is
        variable ret : wm8731_aud_t;
    begin
        ret.count := 0;
        ret.fifo := (others => '-');
        
        return ret;
    end;
    
    function next_aud(cur_val : wm8731_aud_t) return wm8731_aud_t
    is
        variable next_val : wm8731_aud_t;
    begin
        next_val := cur_val;
        if cur_val.count > 0
        then
            next_val.count := cur_val.count - 1;
        end if;
        
        return next_val;
    end;
    
end package body;