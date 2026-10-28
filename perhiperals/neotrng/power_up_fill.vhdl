library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.perhipheral_types.all;

-- Makes the random bytes the RAMs of the console power up with, as the RAMs
-- of a real NES contain whatever they powered up with. A seed taken from a
-- neoTRNG initializes a LFSR, so that the oscillators only run for the few
-- hundred microseconds it takes to get the seed.
--
-- ready is true once there is a seed. The LFSR steps in every clock enable is
-- true, which is when the console is filling its RAMs. It holds its state
-- otherwise, so a later fill gets other bytes without reading the TRNG again.
--
-- With POWER_UP_ZERO the data is zero and ready is always true
entity power_up_fill is
generic
(
    MODE : power_up_mode_t
);
port
(
    clk : in std_logic;

    enable : in boolean;
    ready  : out boolean;
    data   : out power_up_data_t
);
end power_up_fill;

architecture behavioral of power_up_fill is
begin

mode_gen : if MODE = POWER_UP_ZERO generate
begin

    ready <= true;
    data <= (others => '0');

else generate

    subtype lfsr_t is power_up_data_t;

    type state_t is (STATE_SEED, STATE_READY);

    constant SEED_BYTES : positive := lfsr_t'length / 8;

    -- x^48 + x^47 + x^21 + x^20 + 1
    constant LFSR_TAPS : lfsr_t := x"C00000180000";

    -- Gives the bytes taken from the LFSR the 8 steps they need to not be
    -- shifted copies of each other
    function lfsr_step_byte(lfsr : lfsr_t) return lfsr_t
    is
        variable ret : lfsr_t := lfsr;
    begin
        for i in 1 to 8
        loop
            if ret(0) = '1'
            then
                ret := ('0' & ret(ret'left downto 1)) xor LFSR_TAPS;
            else
                ret := '0' & ret(ret'left downto 1);
            end if;
        end loop;

        return ret;
    end function;

    -- Reset for the TRNG, which the FPGA gives from its register power up
    -- values
    signal por : std_logic_vector(1 downto 0) := "00";

    signal state      : state_t := STATE_SEED;
    signal seed_count : natural range 0 to SEED_BYTES-1 := 0;
    signal lfsr       : lfsr_t := (others => '0');

    -- The ports of the TRNG are std_ulogic, which Quartus does not
    -- associate with std_logic signals
    signal trng_enable : std_ulogic;
    signal trng_valid  : std_ulogic;
    signal trng_data   : std_ulogic_vector(7 downto 0);

begin

    trng_enable <= '1' when state = STATE_SEED else '0';

    trng : entity work.neoTRNG
    generic map
    (
        NUM_CELLS => 3,
        NUM_INV_START => 5,
        NUM_RAW_BITS => 64,
        SIM_MODE => MODE = POWER_UP_DETERMINISTIC
    )
    port map
    (
        clk_i => clk,
        rstn_i => por(1),
        enable_i => trng_enable,
        valid_o => trng_valid,
        data_o => trng_data
    );

    ready <= state = STATE_READY;
    data <= lfsr;

    process(clk)
    begin
    if rising_edge(clk)
    then
        por <= por(0) & '1';

        case state is
        when STATE_SEED =>
            if trng_valid = '1'
            then
                if seed_count = SEED_BYTES-1
                then
                    -- An all zero seed would never leave zero
                    lfsr <= lfsr(lfsr'left-8 downto 0) &
                            std_logic_vector(trng_data(7 downto 1)) & '1';
                    state <= STATE_READY;
                else
                    lfsr <= lfsr(lfsr'left-8 downto 0) &
                            std_logic_vector(trng_data);
                    seed_count <= seed_count + 1;
                end if;
            end if;
        when STATE_READY =>
            if enable
            then
                lfsr <= lfsr_step_byte(lfsr);
            end if;
        end case;
    end if;
    end process;

end generate;

end behavioral;
