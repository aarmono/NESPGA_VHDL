library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.file_bus_types.all;
use work.nes_types.all;

entity file_bus_mux is
port
(
    clk     : in std_logic;
    clk_en  : in boolean;
    clk_sync : in boolean;
    reset   : in boolean;

    file_bus_chr    : in file_bus_t;
    data_to_chr_bus : out data_t;

    file_bus_prg    : in file_bus_t;
    data_to_prg_bus : out data_t;

    file_bus_out    : out file_bus_t;
    data_from_file  : in data_t
);
end entity;

architecture behavioral of file_bus_mux
is

    type cache_entry_t is record
        address : file_addr_t;
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

    subtype prg_cache_t is cache_t(0 to 7);
    subtype chr_cache_t is cache_t(0 to 3);

    signal prg_cache : prg_cache_t := (others => RESET_CACHE_ENTRY);
    signal chr_cache : chr_cache_t := (others => RESET_CACHE_ENTRY);

    signal next_prg_cache : prg_cache_t;
    signal next_chr_cache : chr_cache_t;

    signal sig_data_to_chr_bus : data_t;
    signal sig_data_to_prg_bus : data_t;

    function update_cache
    (
        cache_in : cache_t;
        address  : file_addr_t;
        data     : data_t
    )
    return cache_t
    is
        variable cache_out : cache_t(cache_in'range);
        variable idx : integer;
    begin
        cache_out := cache_in;
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

        for i in cache_in'high downto 1
        loop
            -- If address already in cache, move it to the front
            if i <= idx
            then
                -- Shift elements ahead of it back to make room
                cache_out(i) := cache_in(i-1);
            end if;
        end loop;

        cache_out(0).address := address;
        cache_out(0).data := data;

        return cache_out;
    end;

    function cache_lookup
    (
        cache_in : in cache_t;
        file_bus : in file_bus_t
    )
    return cache_result_t
    is
        variable ret : cache_result_t := RESULT_INIT;
    begin
        if is_bus_active(file_bus)
        then
            ret.cache_miss := true;

            for i in cache_in'reverse_range
            loop
                if cache_in(i).address = file_bus.address
                then
                    ret.cache_miss := false;
                    ret.update_cache := true;
                    ret.data := cache_in(i).data;
                end if;
            end loop;
        end if;

        return ret;
    end;

begin

    data_to_chr_bus <= sig_data_to_chr_bus;
    data_to_prg_bus <= sig_data_to_prg_bus;

    process(all)
        variable chr_result : cache_result_t := RESULT_INIT;
        variable prg_result : cache_result_t := RESULT_INIT;
    begin

        file_bus_out <= FILE_BUS_IDLE;

        next_chr_cache <= chr_cache;
        next_prg_cache <= prg_cache;

        chr_result := cache_lookup(chr_cache, file_bus_chr);
        sig_data_to_chr_bus <= chr_result.data;

        prg_result := cache_lookup(prg_cache, file_bus_prg);
        sig_data_to_prg_bus <= prg_result.data;

        -- If this is the sync cycle and there is a cache miss, prioritize
        -- PRG because this is the last chance for the CPU to receive data
        -- this cycle, and most PPU memory accesses take 2 PPU cycles
        if prg_result.cache_miss and (clk_sync or not chr_result.cache_miss)
        then
            prg_result.update_cache := true;

            file_bus_out <= file_bus_prg;
            sig_data_to_prg_bus <= data_from_file;
        -- Otherwise prioritize CHR because we usually have several PPU
        -- cycles to retrieve PRG data
        elsif chr_result.cache_miss
        then
            chr_result.update_cache := true;

            file_bus_out <= file_bus_chr;
            sig_data_to_chr_bus <= data_from_file;
        end if;

        if chr_result.update_cache
        then
            next_chr_cache <= update_cache(chr_cache,
                                           file_bus_chr.address,
                                           sig_data_to_chr_bus);
        end if;

        if prg_result.update_cache
        then
            next_prg_cache <= update_cache(prg_cache,
                                           file_bus_prg.address,
                                           sig_data_to_prg_bus);
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
        end if;
    end if;
    end if;
    end process;

end behavioral;