library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ppu is
generic
(
    CLK_FREQUENCY : frequency_t
)
port
(
    clk   : in std_logic;
    reset : in boolean := false;

    address : out ppu_addr_t;
    valid   : out boolean;
    data    : in ppu_data_t;

    pixel  : out pixel_t;
    h_sync : out std_logic;
    v_sync : out std_logic
);
end entity;

architecture simulation of ppu
is

    constant GTF_PARMS : gtf_parms_t := calc_gtf_settings(640,
                                                          480,
                                                          CLK_FREQUENCY);

begin

    process
    begin
        for y in 1 to GTF_PARMS.vert.fporch
        loop
            v_sync <= '0';
            for x in 1 to GTF_PARMS.horz.total
            loop
                wait until rising_edge(clk);
                h_sync <= '1';
            end loop;
        end loop;
        for y in 1 to GTF_PARMS.vert.sync
        loop
            v_sync <= '1';
            for x in 1 to GTF_PARMS.horz.total
            loop
                wait until rising_edge(clk);
                h_sync <= '1';
            end loop;
        end loop;
        for y in 1 to GTF_PARMS.vert.bporch
        loop
            v_sync <= '0';
            for x in 1 to GTF_PARMS.horz.total
            loop
                wait until rising_edge(clk);
                h_sync <= '1';
            end loop;
        end loop;
        for y in 1 to GTF_PARMS.vert.addr
        loop
            v_sync <= '0';
            for x in 1 to GTF_PARMS.horz.fporch
            loop
                wait until rising_edge(clk);
                h_sync <= '1';
            end loop;
            for x in 1 to GTF_PARMS.horz.sync
            loop
                wait until rising_edge(clk);
                h_sync <= '0';
            end loop;
            for x in 1 to GTF_PARMS.horz.bporch
            loop
                wait until rising_edge(clk);
                h_sync <= '1';
            end loop;
            for x in 1 to GTF_PARMS.horz.addr
            loop
                wait until rising_edge(clk);
                address <= tile_idx_addr(y, x);
                wait until rising_edge(clk);
                tile_idx <= data;


end simulation;