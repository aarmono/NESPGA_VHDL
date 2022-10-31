library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;

entity clk_en is
port
(
    clk_50mhz : in std_logic;
    reset     : in boolean;

    cpu_en : out boolean;
    ppu_en : out boolean;
    nsf_en : out boolean
);
end clk_en;

architecture behavioral of clk_en is
    subtype cpu_count_t is unsigned(4 downto 0);
    subtype nsf_count_t is unsigned(5 downto 0);
    
    -- Divide 50MHz clock by 28 to approximate NES CPU clock speed
    constant RESET_CPU_COUNT : cpu_count_t := to_unsigned(27, cpu_count_t'length);
    constant RESET_NSF_COUNT : nsf_count_t := to_unsigned(49, nsf_count_t'length);
    
    signal cpu_count : cpu_count_t := RESET_CPU_COUNT;
    signal nsf_count : nsf_count_t := RESET_NSF_COUNT;
    
begin

    process(clk_50mhz)
    begin
    if rising_edge(clk_50mhz)
    then
        if reset
        then
            cpu_count <= RESET_CPU_COUNT;
            nsf_count <= RESET_NSF_COUNT;
            cpu_en <= false;
            ppu_en <= false;
            nsf_en <= false;
        else
            if is_zero(cpu_count)
            then
                cpu_count <= RESET_CPU_COUNT;
                cpu_en <= true;
                ppu_en <= true;
            else
                cpu_count <= cpu_count - "1";
                cpu_en <= false;
                -- Maintain a 3:1 ratio between CPU and PPU cycles
                ppu_en <= cpu_count = to_unsigned(9, cpu_count_t'length) or
                          cpu_count = to_unsigned(18, cpu_count_t'length);
            end if;
            
            if is_zero(nsf_count)
            then
                nsf_count <= RESET_NSF_COUNT;
                nsf_en <= true;
            else
                nsf_count <= nsf_count - "1";
                nsf_en <= false;
            end if;
        end if;
    end if;
    end process;
    
end behavioral;
