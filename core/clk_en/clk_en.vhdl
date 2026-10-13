library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;

entity clk_en is
generic
(
    -- Frequency of clk in Hz. The CPU clock is derived by dividing this by
    -- the nearest integer ratio to the NES CPU clock rate (1.789773MHz), so
    -- 50MHz gives a divisor of 28. The minimum supported clock is 6x the CPU
    -- clock.
    CLK_FREQ : positive := 50_000_000
);
port
(
    clk   : in std_logic;
    reset : in boolean;

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
    
    constant NES_CPU_HZ : integer := 1_789_773;

    -- Divide the input clock to approximate NES CPU clock speed
    constant CPU_DIV : integer := (CLK_FREQ + NES_CPU_HZ / 2) / NES_CPU_HZ;
    -- The NSF clock is a 1MHz tick
    constant NSF_DIV : integer := (CLK_FREQ + 500_000) / 1_000_000;

    constant MAX_CPU_COUNT : cpu_count_t := to_unsigned(CPU_DIV - 1, cpu_count_t'length);
    constant MAX_NSF_COUNT : nsf_count_t := to_unsigned(NSF_DIV - 1, nsf_count_t'length);

    -- Input clocks between PPU enables. Any remainder is absorbed by the
    -- interval which wraps around the end of the count
    constant PPU_DIV : integer := CPU_DIV / 3;
    constant PPU_DIV_REMAINDER : integer := CPU_DIV mod 3;

    -- Input clocks between a PPU enable and the following RAM enable
    constant RAM_OFFSET : integer := maximum(1, (4 * CPU_DIV) / 28);

    type ppu_en_arr_t is array(0 to 2) of cpu_count_t;
    -- Maintain a 3:1 ratio between CPU and PPU cycles
    constant PPU_EN_COUNT_ARR : ppu_en_arr_t :=
    (
        (others => '0'),
        to_unsigned(PPU_DIV, cpu_count_t'length),
        to_unsigned(2 * PPU_DIV, cpu_count_t'length)
    );

    constant PPU_RAM_EN_COUNT_ARR : ppu_en_arr_t :=
    (
        to_unsigned(CPU_DIV - RAM_OFFSET - PPU_DIV_REMAINDER, cpu_count_t'length),
        to_unsigned(PPU_DIV - RAM_OFFSET, cpu_count_t'length),
        to_unsigned(2 * PPU_DIV - RAM_OFFSET, cpu_count_t'length)
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

    assert CPU_DIV >= 6 and CPU_DIV <= 31
        and abs(CLK_FREQ - CPU_DIV * NES_CPU_HZ) * 50 <= CLK_FREQ
        report "clk_en: CLK_FREQ must be within 2% of 6 to 31 times the "
             & "NES CPU clock"
        severity failure;

    assert NSF_DIV >= 1 and NSF_DIV <= 64
        report "clk_en: CLK_FREQ out of range for NSF clock"
        severity failure;

    odd_cpu_cycle <= reg_odd_cpu_cycle;

    process(clk)
        variable is_ppu_en : boolean;
        variable is_ppu_ram_en : boolean;
    begin
    if rising_edge(clk)
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
