library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;

entity clk_en is
generic
(
    -- Frequency of clk in Hz
    CLK_FREQ : positive := 50_000_000;
    -- CPU clock frequency in Hz as the fraction CPU_FREQ_NUM / CPU_FREQ_DEN.
    -- The default is the NTSC rate, 39.375MHz / 22 = 1.7897727MHz.
    --
    -- CPU cycles are floor(CLK_FREQ / CPU_FREQ) clocks long, with one clock
    -- added to enough of them that the average rate is exact. When CLK_FREQ
    -- is a whole multiple of the CPU frequency every cycle is the same
    -- length. At 50MHz, 59 of every 63 cycles are 28 clocks long and the
    -- other 4 are 27. CPU cycles must be 6 to 31 clocks long.
    CPU_FREQ_NUM : positive := 39_375_000;
    CPU_FREQ_DEN : positive := 22
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
    subtype cpu_count_t is natural range 0 to 31;
    subtype nsf_count_t is natural range 0 to 63;

    -- Clocks per CPU cycle as the reduced fraction
    -- CPU_DIV_NUM / CPU_DIV_DEN = CLK_FREQ * CPU_FREQ_DEN / CPU_FREQ_NUM
    constant FREQ_GCD : positive := gcd(CLK_FREQ, CPU_FREQ_NUM);
    constant DIV_GCD : positive :=
        gcd((CLK_FREQ / FREQ_GCD) * CPU_FREQ_DEN, CPU_FREQ_NUM / FREQ_GCD);

    constant CPU_DIV_NUM : positive :=
        (CLK_FREQ / FREQ_GCD) * CPU_FREQ_DEN / DIV_GCD;
    constant CPU_DIV_DEN : positive := (CPU_FREQ_NUM / FREQ_GCD) / DIV_GCD;

    -- Clocks in a short CPU cycle. Long cycles have one more
    constant CPU_DIV : integer := CPU_DIV_NUM / CPU_DIV_DEN;
    -- Long cycles in every CPU_DIV_DEN cycles
    constant LONG_CYCLES : natural := CPU_DIV_NUM mod CPU_DIV_DEN;

    constant MAX_CPU_DIV : integer :=
        (CPU_DIV_NUM + CPU_DIV_DEN - 1) / CPU_DIV_DEN;

    -- Each CPU cycle adds LONG_CYCLES to an accumulator modulo CPU_DIV_DEN,
    -- and the cycles where it wraps are long
    subtype cpu_frac_t is natural range 0 to CPU_DIV_DEN - 1;
    constant LONG_CPU_FRAC : natural := CPU_DIV_DEN - LONG_CYCLES;

    -- The NSF clock is a 1MHz tick
    constant NSF_DIV : integer := (CLK_FREQ + 500_000) / 1_000_000;

    constant MAX_CPU_COUNT : cpu_count_t := CPU_DIV - 1;
    constant MAX_NSF_COUNT : nsf_count_t := NSF_DIV - 1;

    -- Input clocks between PPU enables. Any remainder, and the extra clock of
    -- a long cycle, is absorbed by the interval which wraps around the end
    -- of the count
    constant PPU_DIV : integer := CPU_DIV / 3;

    -- Input clocks between a PPU enable and the following RAM enable
    constant RAM_OFFSET : integer := max(1, (4 * MAX_CPU_DIV) / 28);

    type ppu_en_arr_t is array(0 to 2) of cpu_count_t;
    -- Maintain a 3:1 ratio between CPU and PPU cycles
    constant PPU_EN_COUNT_ARR : ppu_en_arr_t :=
    (
        0,
        PPU_DIV,
        2 * PPU_DIV
    );

    -- The RAM enable after the PPU enable at count 0 follows the wrap, so it
    -- also absorbs the remainder
    constant PPU_RAM_EN_COUNT_ARR : ppu_en_arr_t :=
    (
        3 * PPU_DIV - RAM_OFFSET,
        PPU_DIV - RAM_OFFSET,
        2 * PPU_DIV - RAM_OFFSET
    );

    constant CPU_EN_COUNT : cpu_count_t := PPU_EN_COUNT_ARR(2);

    constant CPU_RAM_EN_COUNT : cpu_count_t := PPU_RAM_EN_COUNT_ARR(2);

    -- CPU/PPU sync period is the cycle when both ppu_en and cpu_en are high.
    -- It starts at the beginning of the CPU cycle, just after the previous
    -- ppu_en event
    constant PPU_SYNC_END_COUNT : cpu_count_t := CPU_EN_COUNT - 1;

    -- Reset to the start of a short cycle, as though it was chosen with an
    -- accumulator of 0
    constant RESET_CPU_COUNT : cpu_count_t := MAX_CPU_COUNT;
    constant RESET_CPU_FRAC : cpu_frac_t := LONG_CYCLES;
    constant RESET_NSF_COUNT : nsf_count_t := MAX_NSF_COUNT;

    signal cpu_count : cpu_count_t := RESET_CPU_COUNT;
    signal cpu_frac : cpu_frac_t := RESET_CPU_FRAC;
    signal nsf_count : nsf_count_t := RESET_NSF_COUNT;

    -- True on the first clock of a CPU cycle. Long and short cycles start at
    -- different counts
    signal cpu_cycle_start : boolean := true;

    signal reg_odd_cpu_cycle : boolean := false;

begin

    assert CPU_DIV >= 6 and MAX_CPU_DIV <= 31
        report "clk_en: CPU cycles must be 6 to 31 clocks long"
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
            cpu_frac <= RESET_CPU_FRAC;
            nsf_count <= RESET_NSF_COUNT;

            cpu_en <= false;
            ppu_en <= false;
            nsf_en <= false;

            cpu_ram_en <= false;
            ppu_ram_en <= false;

            ppu_sync <= false;
            cpu_cycle_start <= true;
            reg_odd_cpu_cycle <= true;
        else
            if cpu_cycle_start
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

            if cpu_cycle_start
            then
                ppu_sync <= true;
            elsif cpu_count = PPU_SYNC_END_COUNT
            then
                ppu_sync <= false;
            end if;

            cpu_cycle_start <= cpu_count = 0;

            if cpu_count = 0
            then
                if cpu_frac >= LONG_CPU_FRAC
                then
                    cpu_count <= MAX_CPU_COUNT + 1;
                    cpu_frac <= cpu_frac - LONG_CPU_FRAC;
                else
                    cpu_count <= MAX_CPU_COUNT;
                    cpu_frac <= cpu_frac + LONG_CYCLES;
                end if;
            else
                cpu_count <= cpu_count - 1;
            end if;

            if nsf_count = 0
            then
                nsf_count <= MAX_NSF_COUNT;
                nsf_en <= true;
            else
                nsf_count <= nsf_count - 1;
                nsf_en <= false;
            end if;
        end if;
    end if;
    end process;

end behavioral;
