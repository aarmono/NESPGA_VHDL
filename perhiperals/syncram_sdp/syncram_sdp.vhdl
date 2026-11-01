library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.perhipheral_types.all;
use work.utilities.all;

-- A simple dual port RAM with a clock for each port: one port writes, the
-- other reads. A read of an address being written at the same time returns
-- either value
entity syncram_sdp is
generic
(
    MEM_TYPE  : memory_type_t := MEMORY_INFERRED;
    VENDOR    : vendor_t := VENDOR_ALTERA;
    ADDR_BITS : positive;
    DATA_BITS : positive := 8
);
port
(
    write_clk     : in std_logic;
    write         : in boolean;
    write_address : in std_logic_vector(ADDR_BITS-1 downto 0);
    data_in       : in std_logic_vector(DATA_BITS-1 downto 0);

    -- data_out is the data at read_address as of the last read_clk edge
    read_clk      : in std_logic;
    read_address  : in std_logic_vector(ADDR_BITS-1 downto 0);
    data_out      : out std_logic_vector(DATA_BITS-1 downto 0)
);
end syncram_sdp;

architecture behavioral of syncram_sdp is
    constant RAM_SIZE : positive := 2**ADDR_BITS;

    subtype ram_elem_t is std_logic_vector(data_in'range);
    subtype ram_addr_t is unsigned(read_address'range);

begin

vendor_gen : case VENDOR generate
    when VENDOR_ALTERA =>

        type ram_t is array(0 to RAM_SIZE-1) of ram_elem_t;

        signal ram : ram_t;
        signal reg_address : ram_addr_t := (others => '0');

        attribute ramstyle : string;
        attribute ramstyle of ram : signal is ramtype_attr_str(VENDOR,
                                                               MEM_TYPE,
                                                               "no_rw_check");

    begin

        process(write_clk)
        begin
        if rising_edge(write_clk)
        then
            if write
            then
                ram(to_integer(write_address)) <= data_in;
            end if;
        end if;
        end process;

        process(read_clk)
        begin
        if rising_edge(read_clk)
        then
            reg_address <= unsigned(read_address);
        end if;
        end process;

        data_out <=
            -- pragma translate_off
            (others => '-') when is_x(std_logic_vector(reg_address)) else
            -- pragma translate_on
            ram(to_integer(reg_address));
    end;

    when VENDOR_SIM =>

        -- ghdl keeps a signal array of vectors as a signal per bit, which
        -- takes hundreds of bytes each, so the memory holds integers. A
        -- variable can't be shared between the two clocks' processes
        subtype ram_int_t is natural range 0 to 2**DATA_BITS-1;
        type ram_t is array(0 to RAM_SIZE-1) of ram_int_t;

        signal ram : ram_t := (others => 0);

    begin

        process(write_clk)
        begin
        if rising_edge(write_clk)
        then
            if write
            then
                ram(to_integer(write_address)) <= to_integer(data_in);
            end if;
        end if;
        end process;

        process(read_clk)
        begin
        if rising_edge(read_clk)
        then
            if is_x(read_address)
            then
                data_out <= (others => '-');
            else
                data_out <= to_std_logic_vector(
                    ram(to_integer(read_address)), DATA_BITS);
            end if;
        end if;
        end process;
    end;

end generate;

end behavioral;
