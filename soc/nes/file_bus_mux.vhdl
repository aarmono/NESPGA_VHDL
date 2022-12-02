library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.file_bus_types.all;
use work.nes_types.all;

entity file_bus_mux is
port
(
    clk    : in std_logic;
    clk_en : in boolean;
    reset  : in boolean;

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
    constant RESET_BUS_REG : file_bus_t :=
    (
        address => (others => '0'),
        read => false,
        write => false
    );

    type bus_sel_t is
    (
        BUS_CHR,
        BUS_PRG
    );

    signal reg_bus_sel : bus_sel_t := BUS_CHR;
    signal reg_file_bus_out : file_bus_t := RESET_BUS_REG;
begin

    file_bus_out <= reg_file_bus_out;

    process(clk)
    begin
    if rising_edge(clk) then
    if clk_en then
        if reset
        then
            reg_bus_sel <= BUS_CHR;
            reg_file_bus_out <= RESET_BUS_REG;
        else
            -- How muxing works:
            -- The clock enable line is tied to the PPU RAM enable line.
            --
            -- The PPU runs more quickly than the CPU, but all its memory
            -- accesses take two PPU clock cycles. That means that for a given
            -- CHR access the same address is on the line for two clock cycles.
            -- So we put the PPU address on the bus for that first cycle, then
            -- if the next PPU cycle is for the same memory address we store
            -- the data read during the first cycle in a register and return it,
            -- then put the CPU address on the bus for the second. Once that
            -- data is read, we store it in a register to return to the CPU
            -- and are ready to read data for the PPU again
            -- 
            -- The CPU reads memory once per CPU clock cycle, but since there
            -- are 3 PPU cycles per CPU cycle, this all works perfectly without
            -- depending on any tight timing constraints
            case reg_bus_sel is
                when BUS_CHR =>
                    if is_bus_active(reg_file_bus_out)
                    then
                        data_to_chr_bus <= data_from_file;
                    end if;

                    -- CHR bus has priority
                    if is_bus_active(file_bus_chr) and
                       (not is_bus_active(reg_file_bus_out) or
                        file_bus_chr.address /= reg_file_bus_out.address)
                    then
                        reg_bus_sel <= BUS_CHR;
                        reg_file_bus_out <= file_bus_chr;
                    -- If there's nothing new on the CHR bus and a request on
                    -- the PRG bus, service it
                    elsif is_bus_active(file_bus_prg)
                    then
                        reg_bus_sel <= BUS_PRG;
                        reg_file_bus_out <= file_bus_prg;
                    else
                        reg_file_bus_out.read <= false;
                        reg_file_bus_out.write <= false;
                    end if;
                when BUS_PRG =>
                    if is_bus_active(reg_file_bus_out)
                    then
                        data_to_prg_bus <= data_from_file;
                    end if;

                    -- CHR bus has priority
                    if is_bus_active(file_bus_chr)
                    then
                        reg_bus_sel <= BUS_CHR;
                        reg_file_bus_out <= file_bus_chr;
                    -- Otherwise continue servicing CPU requests
                    elsif is_bus_active(file_bus_prg)
                    then
                        reg_bus_sel <= BUS_PRG;
                        reg_file_bus_out <= file_bus_prg;
                    else
                        reg_file_bus_out.read <= false;
                        reg_file_bus_out.write <= false;
                    end if;
            end case;
        end if;
    end if;
    end if;
    end process;

end behavioral;