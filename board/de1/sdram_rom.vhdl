library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_mem_bus_types.all;

-- Serves the cartridge memory bus out of SDRAM.
--
-- After reset the ROM file is copied into SDRAM from a byte stream, during
-- which loading is true and the NES must be held in reset. A byte is taken
-- from the stream on each clock where load_valid and load_ready are both
-- true. If the file starts with an iNES header, only as many bytes as the
-- header says the file holds are copied, otherwise MAX_BYTES are. Once
-- loading is complete each PPU cycle gets one SDRAM slot, started
-- START_DELAY clocks after ppu_clk_en, which serves a read or a write of the
-- cartridge memory bus. The address and write data are sampled when the
-- slot starts, so they must be stable from then until the next ppu_clk_en,
-- and the read data is ready well before that.
entity sdram_rom is
generic
(
    CLK_FREQ    : positive := 50_000_000;
    -- Clocks after ppu_clk_en until the cartridge memory bus address is sampled
    START_DELAY : positive := 2
);
port
(
    clk   : in std_logic;
    reset : in boolean;

    loading : out boolean;

    load_valid : in boolean;
    load_data  : in data_t;
    load_ready : out boolean;

    ppu_clk_en         : in boolean;
    cart_mem_bus       : in cart_mem_bus_t;
    data_to_cart_mem   : in data_t;
    data_from_cart_mem : out data_t;

    dram_addr  : out std_logic_vector(11 downto 0);
    dram_ba    : out std_logic_vector(1 downto 0);
    dram_cs_n  : out std_logic;
    dram_ras_n : out std_logic;
    dram_cas_n : out std_logic;
    dram_we_n  : out std_logic;
    dram_cke   : out std_logic;
    dram_ldqm  : out std_logic;
    dram_udqm  : out std_logic;
    dram_dq    : inout std_logic_vector(15 downto 0)
);
end sdram_rom;

architecture behavioral of sdram_rom is

    -- Largest ROM file that is loaded. The ROM file image is in the lower
    -- half of the cartridge memory bus, from address 0, and the cartridge
    -- RAMs are in the upper half
    constant MAX_BYTES : positive := 2**(cart_mem_addr_t'length - 1);

    subtype sdram_addr_t is std_logic_vector(22 downto 0);
    subtype load_addr_t is natural range 0 to MAX_BYTES - 1;
    subtype banks_t is natural range 0 to 255;

    -- Bytes in an iNES file, limited to MAX_BYTES
    function ines_bytes
    (
        prg_banks : banks_t;
        chr_banks : banks_t;
        trainer   : boolean
    )
    return positive
    is
        variable ret : positive;
    begin
        ret := 16 + prg_banks * 16384 + chr_banks * 8192;
        if trainer
        then
            ret := ret + 512;
        end if;

        if ret > MAX_BYTES
        then
            return MAX_BYTES;
        else
            return ret;
        end if;
    end;

    type state_t is
    (
        STATE_INIT,
        STATE_COPY,
        STATE_RUN
    );

    type reg_t is record
        state      : state_t;
        load_addr  : load_addr_t;
        load_last  : load_addr_t;
        ppu_delay  : boolean_array(START_DELAY - 1 downto 0);

        -- iNES header fields
        ines      : boolean;
        nes2      : boolean;
        trainer   : boolean;
        prg_banks : banks_t;
        chr_banks : banks_t;
    end record;

    constant RESET_REG : reg_t :=
    (
        state => STATE_INIT,
        load_addr => 0,
        load_last => load_addr_t'high,
        ppu_delay => (others => false),

        ines => false,
        nes2 => false,
        trainer => false,
        prg_banks => 0,
        chr_banks => 0
    );

    signal reg    : reg_t := RESET_REG;
    signal reg_in : reg_t;

    signal sdram_ready : boolean;
    signal sdram_idle  : boolean;
    signal start       : boolean;
    signal read        : boolean;
    signal write       : boolean;
    signal address     : sdram_addr_t;
    signal write_data  : data_t;

begin

    loading <= reg.state /= STATE_RUN;

    ctrl : entity work.sdram_ctrl(behavioral)
    generic map
    (
        CLK_FREQ => CLK_FREQ
    )
    port map
    (
        clk => clk,
        reset => reset,

        ready => sdram_ready,
        idle => sdram_idle,

        start => start,
        read => read,
        write => write,
        address => address,
        data_in => write_data,
        data_out => data_from_cart_mem,

        dram_addr => dram_addr,
        dram_ba => dram_ba,
        dram_cs_n => dram_cs_n,
        dram_ras_n => dram_ras_n,
        dram_cas_n => dram_cas_n,
        dram_we_n => dram_we_n,
        dram_cke => dram_cke,
        dram_ldqm => dram_ldqm,
        dram_udqm => dram_udqm,
        dram_dq => dram_dq
    );

    process(all)
        variable v_reg : reg_t;
    begin
        v_reg := reg;

        v_reg.ppu_delay := shift_left(reg.ppu_delay, ppu_clk_en);

        load_ready <= false;
        start <= false;
        read <= false;
        write <= false;
        address <= (others => '-');
        write_data <= (others => '-');

        case reg.state is
            when STATE_INIT =>
                if sdram_ready
                then
                    v_reg.state := STATE_COPY;
                end if;
            when STATE_COPY =>
                address <= to_std_logic_vector(
                    reg.load_addr, sdram_addr_t'length);

                -- Keep starting slots while waiting for data so that the
                -- SDRAM is refreshed
                load_ready <= sdram_idle;
                start <= sdram_idle;
                write <= load_valid;
                write_data <= load_data;

                if load_valid and sdram_idle
                then
                    case reg.load_addr is
                        when 0 =>
                            v_reg.ines := load_data = x"4E";
                        when 1 =>
                            v_reg.ines := reg.ines and load_data = x"45";
                        when 2 =>
                            v_reg.ines := reg.ines and load_data = x"53";
                        when 3 =>
                            v_reg.ines := reg.ines and load_data = x"1A";
                        when 4 =>
                            v_reg.prg_banks := to_integer(load_data);
                        when 5 =>
                            v_reg.chr_banks := to_integer(load_data);
                        when 6 =>
                            v_reg.trainer := load_data(2) = '1';
                        when 7 =>
                            v_reg.nes2 := load_data(3 downto 2) = "10";
                        when 9 =>
                            -- NES 2.0 keeps the high bits of the bank counts
                            -- here. Files that use them are larger than
                            -- MAX_BYTES anyway
                            if reg.ines and
                               not (reg.nes2 and load_data /= x"00")
                            then
                                v_reg.load_last := ines_bytes(reg.prg_banks,
                                                              reg.chr_banks,
                                                              reg.trainer) - 1;
                            end if;
                        when others =>
                            null;
                    end case;

                    if reg.load_addr = reg.load_last
                    then
                        v_reg.state := STATE_RUN;
                    else
                        v_reg.load_addr := reg.load_addr + 1;
                    end if;
                end if;
            when STATE_RUN =>
                start <= reg.ppu_delay(reg.ppu_delay'high);
                read <= is_bus_read(cart_mem_bus);
                write <= is_bus_write(cart_mem_bus);
                address <= resize(cart_mem_bus.address, sdram_addr_t'length);
                write_data <= data_to_cart_mem;
        end case;

        reg_in <= v_reg;
    end process;

    process(clk)
    begin
    if rising_edge(clk)
    then
        if reset
        then
            reg <= RESET_REG;
        else
            reg <= reg_in;
        end if;
    end if;
    end process;

    -- pragma translate_off
    -- Check the assumptions that make one fixed slot per PPU cycle work: the
    -- slot is never started while the previous one is still running, and
    -- the cartridge memory bus, and the data of a write, do not change
    -- between the start of the slot and the PPU clock enable at which the
    -- access is complete. The requester takes the access as served at that
    -- PPU clock enable, so a change would make it disagree with the SDRAM
    process(clk)
        variable slot_bus  : cart_mem_bus_t := CART_MEM_BUS_IDLE;
        variable slot_data : data_t;
    begin
    if rising_edge(clk)
    then
        if reg.state = STATE_RUN and not reset
        then
            if start
            then
                assert sdram_idle
                    report "sdram_rom: slot started while SDRAM busy"
                    severity error;
                slot_bus := cart_mem_bus;
                slot_data := data_to_cart_mem;
            elsif is_bus_active(slot_bus)
            then
                assert cart_mem_bus = slot_bus
                    report "sdram_rom: cartridge memory bus changed during " &
                           "SDRAM access"
                    severity error;
                assert not is_bus_write(slot_bus) or
                       data_to_cart_mem = slot_data
                    report "sdram_rom: write data changed during SDRAM write"
                    severity error;
            end if;

            if ppu_clk_en
            then
                slot_bus := CART_MEM_BUS_IDLE;
            end if;
        end if;
    end if;
    end process;
    -- pragma translate_on

end behavioral;
