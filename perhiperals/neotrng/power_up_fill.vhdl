library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.perhipheral_types.all;

-- Makes the random bytes the RAMs of the console power up with, as the RAMs
-- of a real NES contain whatever they powered up with. Bytes from a neoTRNG
-- are mixed into a LFSR, which makes the data.
--
-- The TRNG runs while enable is true, which is while the console is held in
-- reset to load the ROM, and until enough bytes are mixed in to fill the
-- LFSR. The ring oscillators of the TRNG start in the same state every time,
-- so the bytes they make soon after they start are close to the same in
-- every power up, and the longer they run the more random they get.
--
-- ready is true once enough bytes are mixed in. The LFSR steps when step is
-- true, which is when the console is filling its RAMs. It holds its state
-- otherwise, so a later fill gets other bytes, mixed with more from the TRNG.
--
-- With POWER_UP_ZERO the data is zero and ready is always true
entity power_up_fill is
generic
(
    MODE : power_up_mode_t;
    -- What the LFSR holds before the TRNG bytes are mixed in. With
    -- POWER_UP_DETERMINISTIC the bytes are the same every time, so this is
    -- how simulations power up in other ways
    SEED : natural := 0
);
port
(
    clk : in std_logic;

    enable : in boolean;
    step   : in boolean;
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

    constant SEED_BYTES : positive := power_up_data_t'length / 8;

    -- x^56 + x^55 + x^35 + x^34 + 1
    constant LFSR_TAPS : power_up_data_t := x"C0000600000000";

    -- Steps the LFSR once for each of its bits, so that none of them is
    -- still in the state. Each RAM takes its own byte of the state, and
    -- with fewer steps a byte would be another byte of an earlier state
    -- shifted down: stepping 8, CPU RAM powered up a copy of OAM
    function lfsr_step(lfsr : power_up_data_t) return power_up_data_t
    is
        variable ret : power_up_data_t := lfsr;
    begin
        for i in power_up_data_t'range
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

    signal lfsr     : power_up_data_t :=
        std_logic_vector(to_unsigned(SEED, power_up_data_t'length));
    signal absorbed : natural range 0 to SEED_BYTES := 0;

    -- The ports of the TRNG are std_ulogic, which Quartus does not
    -- associate with std_logic signals
    signal trng_enable : std_ulogic;
    signal trng_valid  : std_ulogic;
    signal trng_data   : std_ulogic_vector(7 downto 0);

begin

    ready <= absorbed = SEED_BYTES;
    data <= lfsr;

    trng_enable <= '1' when enable or absorbed /= SEED_BYTES else '0';

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

    process(clk)
        variable next_lfsr : power_up_data_t;
    begin
    if rising_edge(clk)
    then
        por <= por(0) & '1';

        -- Bytes are only mixed in while the TRNG is enabled, which is before
        -- the RAMs are filled, so that the data only changes on step during
        -- a fill. The TRNG can still make a byte in the clock after it is
        -- disabled, which is dropped
        if trng_valid = '1' and trng_enable = '1'
        then
            -- Stepping before mixing in spreads every byte over the whole
            -- state. The step can be undone, so no byte takes away what
            -- earlier bytes put in
            next_lfsr := lfsr_step(lfsr);
            next_lfsr(trng_data'range) := next_lfsr(trng_data'range) xor
                                          std_logic_vector(trng_data);
            lfsr <= next_lfsr;
            if absorbed /= SEED_BYTES
            then
                absorbed <= absorbed + 1;
            end if;
        elsif step
        then
            lfsr <= lfsr_step(lfsr);
        end if;
    end if;
    end process;

end generate;

end behavioral;
