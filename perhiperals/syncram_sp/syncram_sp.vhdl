library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.perhipheral_types.all;

entity syncram_sp is
generic
(
    MEM_TYPE  : memory_type_t := MEMORY_ALTERA;
    ADDR_BITS : positive;
    DATA_BITS : positive := 8
);
port
(
    clk      : in std_logic;
    clk_en   : in boolean;

    address  : in std_logic_vector(ADDR_BITS-1 downto 0);
    read     : in boolean;
    write    : in boolean;

    data_in  : in std_logic_vector(DATA_BITS-1 downto 0);
    data_out : out std_logic_vector(DATA_BITS-1 downto 0)
);
end syncram_sp;

architecture behavioral of syncram_sp is
    constant RAM_SIZE : positive := 2**ADDR_BITS;

    subtype ram_elem_t is std_logic_vector(data_in'range);
    subtype ram_addr_t is unsigned(address'range);

    type ram_t is array(0 to RAM_SIZE-1) of ram_elem_t;

begin

syncram_gen : case MEM_TYPE generate
    when MEMORY_ALTERA =>

        signal ram : ram_t;
        signal reg_address : ram_addr_t := (others => '0');

        attribute ramstyle : string;
        attribute ramstyle of ram : signal is "no_rw_check";

    begin

        process(clk)
        begin
        if rising_edge(clk)
        then
            -- Infers the Altera Cyclone II Single port RAM. Successfully
            -- inferring this is tricky, so be very careful when changing this
            -- logic
            if write and clk_en
            then
                ram(to_integer(unsigned(address))) <= data_in;
            end if;
            
            -- Can't use clock enable signal here since Quartus
            -- infers a dual-port RAM if we do. This shouldn't be
            -- and issue for this application since the main concern
            -- is overwriting memory we don't want to due to the
            -- address/data lines not being stable
            reg_address <= unsigned(address);
        end if;
        end process;
        
        data_out <=
            -- pragma translate_off
            (others => '-') when is_x(std_logic_vector(reg_address)) else
            -- pragma translate_on
            ram(to_integer(reg_address));
    end;
    
    when MEMORY_REGISTER =>
    
        signal ram : ram_t;
        
    begin
    
        process(clk)
        begin
        if rising_edge(clk) then
        if write and clk_en
        then
            ram(to_integer(unsigned(address))) <= data_in;
        end if;
        end if;
        end process;
        
        -- Asynchronous access should prevent RAM from being inferred
        data_out <=
            -- pragma translate_off
            (others => '-') when is_x(std_logic_vector(address)) else
            -- pragma translate_on
            ram(to_integer(unsigned(address)));
    end;

end generate;

end behavioral;