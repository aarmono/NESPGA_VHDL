library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity syncram_sp is
generic
(
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

    constant DATA_IGNORE : ram_elem_t := (others => '-');

    type ram_t is array(0 to RAM_SIZE-1) of ram_elem_t;
    signal ram : ram_t;
    
    signal reg_address : ram_addr_t := (others => '0');
begin

    process(clk)
    begin
    if rising_edge(clk)
    then
        -- Infers the Altera Cyclone II Single port RAM. Successfully inferring
        -- this is tricky, so be very careful when changing this logic
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
    
    data_out <= ram(to_integer(reg_address));

end behavioral;