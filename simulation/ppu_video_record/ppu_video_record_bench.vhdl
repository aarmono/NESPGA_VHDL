library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.binary_io.all;
use work.bmp_file.all;
use work.nes_types.all;
use work.simulation.all;
use std.env.all;

entity ppu_video_record_bench is
generic
(
    FILE_PREFIX : string := "C:\\GitHub\\NESPGA_VHDL\\board\\sim\\out"
);
end ppu_video_record_bench;

architecture behavioral of ppu_video_record_bench is

    signal pixel_bus : pixel_bus_t;
    signal clk : std_logic;

begin

    recorder : ppu_video_record
    generic map
    (
        FILE_PREFIX => FILE_PREFIX
    )
    port map
    (
        clk => clk,
        clk_en => true,
        pixel_bus => pixel_bus,
        ready => true,
        done => false
    );


    process
    is
        variable pixel_val : unsigned(8 downto 0);
    begin

        pixel_bus.pixel <= (others => '0');
        pixel_bus.line_valid <= false;
        pixel_bus.frame_valid <= false;
        clk <= '0';

        wait for 10 ns;

        for y in 0 to 260
        loop
            if y = 0
            then
                pixel_bus.frame_valid <= true;
            elsif y = 240
            then
                pixel_bus.frame_valid <= false;
            end if;

            for x in 0 to 340
            loop
                if x = 1
                then
                    pixel_bus.line_valid <= true;
                elsif x = 257
                then
                    pixel_bus.line_valid <= false;
                end if;

                pixel_val := to_unsigned(x, pixel_val'length);
                pixel_bus.pixel <= std_logic_vector(pixel_val(pixel_t'range));
                
                clk <= '1';
                wait for 10 ns;
                clk <= '0';
                wait for 10 ns;
            end loop;
        end loop;
        finish;
    end process;

end behavioral;
