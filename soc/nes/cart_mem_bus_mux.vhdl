library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.cart_mem_bus_types.all;
use work.nes_types.all;

entity cart_mem_bus_mux is
port
(
    clk     : in std_logic;
    clk_en  : in boolean;
    clk_sync : in boolean;
    reset   : in boolean;

    cart_mem_bus_chr  : in cart_mem_bus_t;
    data_from_chr_bus : in data_t;
    data_to_chr_bus   : out data_t;

    cart_mem_bus_prg  : in cart_mem_bus_t;
    data_from_prg_bus : in data_t;
    data_to_prg_bus   : out data_t;

    cart_mem_bus_out   : out cart_mem_bus_t;
    data_to_cart_mem   : out data_t;
    data_from_cart_mem : in data_t
);
end entity;

architecture behavioral of cart_mem_bus_mux
is

    type cache_entry_t is record
        address : cart_mem_addr_t;
        data    : data_t;
    end record;

    constant RESET_CACHE_ENTRY : cache_entry_t :=
    (
        address => (others => '1'),
        data => (others => '1')
    );

    type cache_result_t is record
        update_cache : boolean;
        cache_miss   : boolean;
        data         : data_t;
    end record;

    constant RESULT_INIT : cache_result_t :=
    (
        update_cache => false,
        cache_miss => false,
        data => (others => '-')
    );

    type cache_t is array(integer range <>) of cache_entry_t;

    subtype prg_cache_t is cache_t(0 to 0);
    subtype chr_cache_t is cache_t(0 to 0);

    signal prg_cache : prg_cache_t := (others => RESET_CACHE_ENTRY);
    signal chr_cache : chr_cache_t := (others => RESET_CACHE_ENTRY);

    signal next_prg_cache : prg_cache_t;
    signal next_chr_cache : chr_cache_t;

    signal sig_data_to_chr_bus : data_t;
    signal sig_data_to_prg_bus : data_t;

    function update_cache
    (
        cache_in : cache_t;
        address  : cart_mem_addr_t;
        data     : data_t
    )
    return cache_t
    is
        variable cache_out : cache_t(cache_in'range);
        variable idx : integer;

        constant IDX_ONE : integer := cache_in'low + 1;
    begin
        cache_out := cache_in;

        if cache_in'length > 1
        then
            -- If address not already in cache, eject least recently accessed
            -- element
            idx := cache_in'high;

            for i in cache_in'reverse_range
            loop
                if cache_in(i).address = address
                then
                    idx := i;
                end if;
            end loop;

            for i in cache_in'high downto IDX_ONE
            loop
                -- If address already in cache, move it to the front
                if i <= idx
                then
                    -- Shift elements ahead of it back to make room
                    cache_out(i) := cache_in(i-1);
                end if;
            end loop;
        end if;

        cache_out(cache_in'low).address := address;
        cache_out(cache_in'low).data := data;

        return cache_out;
    end;

    -- The cache holds what memory holds at each cached address, so a write
    -- only hits if memory already holds the data being written. A write that
    -- misses is passed on to memory, which makes the cache write-through
    function cache_lookup
    (
        cache_in     : in cache_t;
        cart_mem_bus : in cart_mem_bus_t;
        write_data   : in data_t
    )
    return cache_result_t
    is
        variable ret : cache_result_t := RESULT_INIT;
    begin
        if is_bus_active(cart_mem_bus)
        then
            ret.cache_miss := true;

            for i in cache_in'reverse_range
            loop
                if cache_in(i).address = cart_mem_bus.address and
                   (is_bus_read(cart_mem_bus) or cache_in(i).data = write_data)
                then
                    ret.cache_miss := false;
                    ret.update_cache := true;
                    ret.data := cache_in(i).data;
                end if;
            end loop;
        end if;

        return ret;
    end;

    -- The data memory holds at the address of an access once it is served
    function served_data
    (
        cart_mem_bus : cart_mem_bus_t;
        write_data   : data_t;
        read_data    : data_t
    )
    return data_t
    is
    begin
        if is_bus_write(cart_mem_bus)
        then
            return write_data;
        else
            return read_data;
        end if;
    end;

begin

    data_to_chr_bus <= sig_data_to_chr_bus;
    data_to_prg_bus <= sig_data_to_prg_bus;

    process(all)
        variable chr_result : cache_result_t := RESULT_INIT;
        variable prg_result : cache_result_t := RESULT_INIT;
    begin

        cart_mem_bus_out <= CART_MEM_BUS_IDLE;
        data_to_cart_mem <= (others => '-');

        next_chr_cache <= chr_cache;
        next_prg_cache <= prg_cache;

        chr_result := cache_lookup(chr_cache,
                                   cart_mem_bus_chr,
                                   data_from_chr_bus);

        prg_result := cache_lookup(prg_cache,
                                   cart_mem_bus_prg,
                                   data_from_prg_bus);

        -- If this is the sync cycle and there is a cache miss, prioritize
        -- PRG because this is the last chance for the CPU to receive data
        -- this cycle, and under normal circumstances PPU memory accesses
        -- take 2 PPU cycles; so next PPU cycle the PPU should be requesting
        -- data at the same address
        if prg_result.cache_miss and (clk_sync or not chr_result.cache_miss)
        then
            prg_result.update_cache := true;

            prg_result.data := served_data(cart_mem_bus_prg,
                                           data_from_prg_bus,
                                           data_from_cart_mem);

            cart_mem_bus_out <= cart_mem_bus_prg;
            data_to_cart_mem <= data_from_prg_bus;
        -- Otherwise prioritize CHR because we usually have several PPU
        -- cycles to retrieve PRG data
        elsif chr_result.cache_miss
        then
            chr_result.update_cache := true;

            chr_result.data := served_data(cart_mem_bus_chr,
                                           data_from_chr_bus,
                                           data_from_cart_mem);

            cart_mem_bus_out <= cart_mem_bus_chr;
            data_to_cart_mem <= data_from_chr_bus;
        end if;

        sig_data_to_chr_bus <= chr_result.data;
        sig_data_to_prg_bus <= prg_result.data;

        if chr_result.update_cache
        then
            next_chr_cache <= update_cache(chr_cache,
                                           cart_mem_bus_chr.address,
                                           chr_result.data);
        end if;

        if prg_result.update_cache
        then
            next_prg_cache <= update_cache(prg_cache,
                                           cart_mem_bus_prg.address,
                                           prg_result.data);
        end if;

    end process;

    process(clk)
    begin
    if rising_edge(clk) then
    if clk_en then
        if reset
        then
            chr_cache <= (others => RESET_CACHE_ENTRY);
            prg_cache <= (others => RESET_CACHE_ENTRY);
        else
            chr_cache <= next_chr_cache;
            prg_cache <= next_prg_cache;

            -- pragma translate_off
            -- The PPU presents a CHR write for only one PPU cycle, so it must
            -- be served in that cycle. If it was, the cache now holds it
            assert not (is_bus_write(cart_mem_bus_chr) and
                        cache_lookup(next_chr_cache,
                                     cart_mem_bus_chr,
                                     data_from_chr_bus).cache_miss)
                report "cart_mem_bus_mux: CHR write dropped"
                severity failure;
            -- pragma translate_on
        end if;
    end if;
    end if;
    end process;

end behavioral;