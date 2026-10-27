library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cart_types.all;
use work.opll_bus_types.all;
use work.lib_cartridge.all;
use work.lib_vrc7_audio.all;

-- The cartridge, built as the board given by the mapper number of the ROM
-- file. The boards are cycled by lib_cartridge
entity cartridge is
generic
(
    -- The boards to build. See board_set_t
    CART_BOARDS : board_set_t := ALL_BOARDS
);
port
(
    clk      : in std_logic;
    clk_en   : in boolean;
    clk_sync : in boolean;
    reset    : in boolean;

    config   : in cart_config_t;

    cart_in  : in cart_in_t;
    cart_out : out cart_out_t;

    -- The memories of the VRC7 audio
    opll_mem_out       : out opll_mem_out_t;
    data_from_opll_ram : in opll_ram_data_t
);
    -- Quartus builds the small multipliers of the boards' audio (volume
    -- and level scaling) from LEs unless told otherwise, and there are
    -- plenty of multiplier blocks to spare
    attribute multstyle : string;
    attribute multstyle of cartridge : entity is "dsp";
end cartridge;

architecture behavioral of cartridge is

    signal boards : cart_boards_t;

    signal reg : cart_reg_t := RESET_CART_REG;

    signal opll_tables : vrc7_tables_t;

begin

    boards <= get_cart_boards(config);

    assert reset or CART_BOARDS(boards.board)
        report "Mapper not supported: " &
               integer'image(to_integer(unsigned(config.mapper_num)))
        severity failure;

    -- Only the registers of the board in use are written, since writing
    -- those of every board is slow to simulate
    process(clk)
        variable v_out : cart_cycle_out_t;
    begin
    -- double-IF is required for synthesis
    if rising_edge(clk) then
    if clk_en then
        if reset
        then
            reg <= get_reset_cart_reg(boards);
        else
            v_out := cycle_cartridge(reg,
                                     boards,
                                     CART_BOARDS,
                                     config,
                                     clk_sync,
                                     cart_in,
                                     data_from_opll_ram,
                                     opll_tables);

            case boards.board is
                when BOARD_LATCH => reg.latch <= v_out.reg.latch;
                when BOARD_MMC1 => reg.mmc1 <= v_out.reg.mmc1;
                when BOARD_MMC2 => reg.mmc2 <= v_out.reg.mmc2;
                when BOARD_MMC3 => reg.mmc3 <= v_out.reg.mmc3;
                when BOARD_FME7 =>
                    reg.fme7 <= v_out.reg.fme7;
                    reg.irq_counter <= v_out.reg.irq_counter;
                when BOARD_VRC4 =>
                    reg.vrc4 <= v_out.reg.vrc4;
                    reg.vrc_irq <= v_out.reg.vrc_irq;
                when BOARD_VRC6 =>
                    reg.vrc6 <= v_out.reg.vrc6;
                    reg.vrc_irq <= v_out.reg.vrc_irq;
                when BOARD_VRC7 =>
                    reg.vrc7 <= v_out.reg.vrc7;
                    reg.vrc_irq <= v_out.reg.vrc_irq;
                when BOARD_MMC5 => reg.mmc5 <= v_out.reg.mmc5;
                when BOARD_N163 =>
                    reg.n163 <= v_out.reg.n163;
                    reg.irq_counter <= v_out.reg.irq_counter;
                when BOARD_ACTION53 => reg.action53 <= v_out.reg.action53;
                when BOARD_BANDAI =>
                    reg.bandai <= v_out.reg.bandai;
                    reg.irq_counter <= v_out.reg.irq_counter;
                when BOARD_SS88006 => reg.ss88006 <= v_out.reg.ss88006;
                when BOARD_TAITO => reg.taito <= v_out.reg.taito;
                when BOARD_SUNSOFT =>
                    reg.sunsoft <= v_out.reg.sunsoft;
                    reg.irq_counter <= v_out.reg.irq_counter;
                when BOARD_IREM =>
                    reg.irem <= v_out.reg.irem;
                    reg.irq_counter <= v_out.reg.irq_counter;
                when BOARD_NSF => reg.nsf <= v_out.reg.nsf;
                when BOARD_NONE | BOARD_SUNSOFT_5B | BOARD_MMC5_AUDIO |
                     BOARD_VRC7_AUDIO =>
            end case;
        end if;
    end if;
    end if;
    end process;

    process(all)
        variable v_out : cart_cycle_out_t;
    begin
        -- cart_out does not depend on the reads of the VRC7 audio's
        -- memories, so they are left out of this process's inputs
        v_out := cycle_cartridge(reg,
                                 boards,
                                 CART_BOARDS,
                                 config,
                                 clk_sync,
                                 cart_in,
                                 (others => '-'),
                                 VRC7_TABLES_UNUSED);

        cart_out <= v_out.cart;
    end process;

    opll_mem_out <= get_opll_mem_out(reg, boards, CART_BOARDS, clk_sync);

    -- The tables of the VRC7 audio. Quartus builds them as ROMs in the
    -- on-chip memory when they are looked up in a process of their own, but
    -- not within cycle_cartridge
    gen_opll_tables : if CART_BOARDS(BOARD_VRC7_AUDIO) generate
        process(clk)
        begin
        if rising_edge(clk) then
        if clk_en then
            opll_tables <= get_opll_tables(reg);
        end if;
        end if;
        end process;
    end generate;

end behavioral;
