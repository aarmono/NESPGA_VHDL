library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;

package lib_wm8731 is
    
    subtype wm_addr_t is std_logic_vector(6 downto 0);
    subtype wm_data_t is std_logic_vector(8 downto 0);
    
    type serial_bus_t is record
        sdin : std_logic;
        sclk : std_logic;
    end record;
    
    type wm8731_dat_t is record
        fifo  : std_logic_vector(23 downto 0);
        count : unsigned(5 downto 0);
    end record;
    
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
    
    subtype wm_audio_t is std_logic_vector(15 downto 0);
    
    type wm8731_aud_t is record
        fifo  : wm_audio_t;
        count : unsigned(5 downto 0);
    end record;
    
    function bus_out(val : wm8731_aud_t) return audio_bus_t;
    function start_sample(audio : wm_audio_t) return wm8731_aud_t;
    function is_idle(val : wm8731_aud_t) return boolean;
    function reset_val(val : wm8731_aud_t) return wm8731_aud_t;
    function next_aud(cur_val : wm8731_aud_t) return wm8731_aud_t;
    
    component wm8731 is
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
    end component wm8731;
    
end lib_wm8731;

package body lib_wm8731 is
    
    -- wm8731_dat_t {
    constant START_HIGH : unsigned(5 downto 0) := to_unsigned(57, 6);
    constant START_LOW  : unsigned(5 downto 0) := to_unsigned(56, 6);
    constant END_LOW    : unsigned(5 downto 0) := to_unsigned(1, 6);
    constant END_HIGH   : unsigned(5 downto 0) := to_unsigned(0, 6);
    constant ACK_ADDR   : unsigned(5 downto 0) := to_unsigned(39, 6);
    constant ACK_DATA_L : unsigned(5 downto 0) := to_unsigned(21, 6);
    constant ACK_DATA_H : unsigned(5 downto 0) := to_unsigned(3, 6);
    
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
        ret.fifo := reverse_vector(x"34" & addr & data);
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
            ret := val.count(0);
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
        elsif val.count = END_HIGH or
              val.count = ACK_ADDR or
              val.count = ACK_DATA_L or
              val.count = ACK_DATA_H
        then
            ret := '1';
        else
            ret := val.fifo(0);
        end if;
        
        return ret;
    end;
    
    function bus_out(val : wm8731_dat_t) return serial_bus_t
    is
        variable ret : serial_bus_t;
    begin
        if val.count = START_HIGH or
           val.count = END_LOW
        then
            ret.sclk := '1';
            ret.sdin := '0';
        elsif val.count = END_HIGH
        then
            ret.sclk := '1';
            ret.sdin := '1';
        elsif val.count = ACK_ADDR or
              val.count = ACK_DATA_L or
              val.count = ACK_DATA_H
        then
            ret.sclk := val.count(0);
            ret.sdin := '1';
        else
            ret.sclk := val.count(0);
            ret.sdin := val.fifo(0);
        end if;
        
        return ret;
    end;
    
    function next_dat(cur_val : wm8731_dat_t) return wm8731_dat_t
    is
        variable next_val : wm8731_dat_t;
    begin
        next_val := cur_val;
        if cur_val.count(0) = '1' and 
           cur_val.count /= START_HIGH and
           cur_val.count /= ACK_ADDR and
           cur_val.count /= ACK_DATA_L and
           cur_val.count /= ACK_DATA_H
        then
            next_val.fifo := '0' & cur_val.fifo(cur_val.fifo'HIGH downto 1);
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