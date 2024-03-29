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
    nsf_en : out boolean;

    cpu_ram_en : out boolean;
    ppu_ram_en : out boolean;

    ppu_sync      : out boolean;
    odd_cpu_cycle : out boolean
);
end clk_en;

architecture behavioral of clk_en is
    subtype cpu_count_t is unsigned(4 downto 0);
    subtype nsf_count_t is unsigned(5 downto 0);
    
    -- Divide 50MHz clock by 28 to approximate NES CPU clock speed
    constant MAX_CPU_COUNT : cpu_count_t := to_unsigned(27, cpu_count_t'length);
    constant MAX_NSF_COUNT : nsf_count_t := to_unsigned(49, nsf_count_t'length);

    type ppu_en_arr_t is array(0 to 2) of cpu_count_t;
    -- Maintain a 3:1 ratio between CPU and PPU cycles
    constant PPU_EN_COUNT_ARR : ppu_en_arr_t :=
    (
        (others => '0'),
        to_unsigned(9, cpu_count_t'length),
        to_unsigned(18, cpu_count_t'length)
    );

    constant PPU_RAM_EN_COUNT_ARR : ppu_en_arr_t :=
    (
        to_unsigned(5, cpu_count_t'length),
        to_unsigned(14, cpu_count_t'length),
        to_unsigned(23, cpu_count_t'length)
    );

    constant CPU_EN_COUNT : cpu_count_t := PPU_EN_COUNT_ARR(2);

    constant CPU_RAM_EN_COUNT : cpu_count_t := PPU_RAM_EN_COUNT_ARR(2);

    -- CPU/PPU sync period is the cycle when both ppu_en and cpu_en are high.
    -- It starts just after the previous ppu_en event
    constant PPU_SYNC_START_COUNT : cpu_count_t := MAX_CPU_COUNT;
    constant PPU_SYNC_END_COUNT : cpu_count_t := CPU_EN_COUNT - "1";

    constant RESET_CPU_COUNT : cpu_count_t := PPU_SYNC_START_COUNT;
    constant RESET_NSF_COUNT : nsf_count_t := MAX_NSF_COUNT;

    signal cpu_count : cpu_count_t := RESET_CPU_COUNT;
    signal nsf_count : nsf_count_t := RESET_NSF_COUNT;
    
    signal reg_odd_cpu_cycle : boolean := false;
    
begin

    odd_cpu_cycle <= reg_odd_cpu_cycle;

    process(clk_50mhz)
        variable is_ppu_en : boolean;
        variable is_ppu_ram_en : boolean;
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

            cpu_ram_en <= false;
            ppu_ram_en <= false;

            ppu_sync <= false;
            reg_odd_cpu_cycle <= true;
        else
            if is_zero(cpu_count)
            then
                cpu_count <= MAX_CPU_COUNT;
            else
                cpu_count <= cpu_count - "1";
            end if;

            if cpu_count = MAX_CPU_COUNT
            then
                reg_odd_cpu_cycle <= not reg_odd_cpu_cycle;
            end if;

            cpu_en <= cpu_count = CPU_EN_COUNT;
            cpu_ram_en <= cpu_count = CPU_RAM_EN_COUNT;

            is_ppu_en := false;
            is_ppu_ram_en := false;
            for i in ppu_en_arr_t'range
            loop
                if cpu_count = PPU_EN_COUNT_ARR(i)
                then
                    is_ppu_en := true;
                end if;

                if cpu_count = PPU_RAM_EN_COUNT_ARR(i)
                then
                    is_ppu_ram_en := true;
                end if;
            end loop;

            ppu_en <= is_ppu_en;
            ppu_ram_en <= is_ppu_ram_en;

            if cpu_count = PPU_SYNC_START_COUNT
            then
                ppu_sync <= true;
            elsif cpu_count = PPU_SYNC_END_COUNT
            then
                ppu_sync <= false;
            end if;

            if is_zero(nsf_count)
            then
                nsf_count <= MAX_NSF_COUNT;
                nsf_en <= true;
            else
                nsf_count <= nsf_count - "1";
                nsf_en <= false;
            end if;
        end if;
    end if;
    end process;
    
end behavioral;
