library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_types.all;
use work.lib_vrc_irq.all;
use work.opll_bus_types.all;
use work.lib_vrc7_audio.all;

-- Boards built around the Konami VRC7 (85): three 8KB PRG ROM banks and the
-- last bank fixed at 0xE000, eight 1KB CHR banks, PRG RAM with an enable,
-- the VRC IRQ counter and six channels of FM audio. The registers are
-- selected by CPU A15-A12 and one more address line, which is A4 on VRC7a
-- (Lagrange Point, NES 2.0 submapper 2) and A3 on VRC7b (Tiny Toon
-- Adventures 2, submapper 1). An iNES header gives no submapper, so the
-- chip sees the OR of both lines, as in Mesen. CPU A5 selects between the
-- address and data registers of the audio.
--
-- VRC7b boards have no resonator, which the audio needs to run, so they
-- are silent. The audio is built when told to, since NES carts have no
-- audio pins; nothing of it can be read back by the CPU
--
-- To add a board, add its mapper number to is_vrc7_mapper and give it an
-- arm in get_vrc7_board
package lib_mapper_vrc7 is

    type vrc7_board_t is record
        -- The CPU address lines whose OR drives the register select input
        -- of the chip
        a3    : boolean;
        a4    : boolean;
        -- The board has the resonator of the audio
        audio : boolean;
    end record;

    -- The mapper number is that of a board built around the VRC7
    function is_vrc7_mapper(mapper_num : mapper_num_t) return boolean;

    function get_vrc7_board(config : cart_config_t) return vrc7_board_t;

    subtype prg_bank_t is unsigned(5 downto 0);
    type prg_bank_arr_t is array(0 to 2) of prg_bank_t;

    subtype chr_bank_t is unsigned(7 downto 0);
    type chr_bank_arr_t is array(0 to 7) of chr_bank_t;

    type mapper_vrc7_reg_t is record
        -- The banks at 0x8000, 0xA000 and 0xC000
        prg_banks   : prg_bank_arr_t;
        chr_banks   : chr_bank_arr_t;

        -- 0xE000
        mirror      : mirror_t;
        -- Bit 6 holds the audio in reset
        audio_reset : boolean;
        prg_ram     : boolean;

        irq         : vrc_irq_t;

        audio       : vrc7_audio_t;
    end record;

    -- The registers as they are at reset, as though 0 had been written to
    -- each, as in Mesen: PRG RAM is disabled
    constant RESET_MAPPER_VRC7_REG : mapper_vrc7_reg_t :=
    (
        prg_banks => (others => (others => '0')),
        chr_banks => (others => (others => '0')),

        mirror => MIRROR_VERT,
        audio_reset => false,
        prg_ram => false,

        irq => RESET_VRC_IRQ,

        audio => get_reset_vrc7_audio
    );

    type mapper_vrc7_out_t is record
        reg  : mapper_vrc7_reg_t;
        cart : cart_out_t;
    end record;

    -- audio builds the audio. ram_data is what the access of
    -- get_vrc7_mem_out reads, and tables what get_vrc7_tables looked up the
    -- PPU cycle before
    function cycle_mapper_vrc7
    (
        reg      : mapper_vrc7_reg_t;
        board    : vrc7_board_t;
        audio    : boolean;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t;
        ram_data : opll_ram_data_t;
        tables   : vrc7_tables_t
    )
    return mapper_vrc7_out_t;

    -- The accesses of the audio to its memories, which are not part of
    -- cart_out_t, since cart_out is assigned on every change of its inputs
    -- and wide vectors there are slow to simulate. run: the board in use is
    -- built with the audio
    function get_vrc7_mem_out
    (
        reg      : mapper_vrc7_reg_t;
        board    : vrc7_board_t;
        run      : boolean;
        clk_sync : boolean
    )
    return opll_mem_out_t;

end package lib_mapper_vrc7;


package body lib_mapper_vrc7 is

    function is_vrc7_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        return mapper_num = x"055";
    end;

    function get_vrc7_board(config : cart_config_t) return vrc7_board_t
    is
    begin
        case config.submapper_num is
            -- VRC7b
            when x"1" => return (a3 => true, a4 => false, audio => false);
            -- VRC7a
            when x"2" => return (a3 => false, a4 => true, audio => true);
            when others => return (a3 => true, a4 => true, audio => true);
        end case;
    end;

    -- The register select input of the chip
    function get_select
    (
        board  : vrc7_board_t;
        cpu_in : cart_cpu_in_t
    )
    return natural
    is
    begin
        if (board.a3 and cpu_in.prg_bus.address(3) = '1') or
           (board.a4 and cpu_in.prg_bus.address(4) = '1')
        then
            return 1;
        end if;
        return 0;
    end;

    -- audio: the audio runs and is not held in reset
    function cycle_write
    (
        reg      : mapper_vrc7_reg_t;
        board    : vrc7_board_t;
        audio    : boolean;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_vrc7_reg_t
    is
        variable ret : mapper_vrc7_reg_t;
        variable data : data_t;
        variable sel : natural range 0 to 1;
        variable page : natural range 0 to 7;
    begin
        ret := reg;
        data := cart_in.cpu.data;

        if is_rom_write(cart_in.cpu, clk_sync)
        then
            sel := get_select(board, cart_in.cpu);
            page := to_integer(cart_in.cpu.prg_bus.address(14 downto 12));

            case page is
                when 0 =>
                    ret.prg_banks(sel) := unsigned(data(prg_bank_t'range));
                when 1 =>
                    if sel = 0
                    then
                        ret.prg_banks(2) := unsigned(data(prg_bank_t'range));
                    elsif audio
                    then
                        -- CPU A5 selects the data register
                        ret.audio := write_vrc7_audio(
                            reg.audio,
                            cart_in.cpu.prg_bus.address(5) = '1',
                            data);
                    end if;
                when 2 to 5 =>
                    ret.chr_banks((page - 2) * 2 + sel) := unsigned(data);
                when 6 =>
                    if sel = 0
                    then
                        ret.mirror :=
                            get_hv_single_screen_mirror(data(1 downto 0));
                        ret.audio_reset := data(6) = '1';
                        ret.prg_ram := data(7) = '1';
                    else
                        ret.irq := write_vrc_irq_latch(reg.irq, data);
                    end if;
                when 7 =>
                    if sel = 0
                    then
                        ret.irq := write_vrc_irq_control(reg.irq, data);
                    else
                        ret.irq := acknowledge_vrc_irq(reg.irq);
                    end if;
            end case;
        end if;

        return ret;
    end;

    -- The 8KB PRG ROM bank in the window of the CPU address
    function get_prg_bank
    (
        reg    : mapper_vrc7_reg_t;
        window : prg_window_t
    )
    return prg_bank_8kb_t
    is
    begin
        if window = "11"
        then
            return (others => '1');
        end if;
        return resize(reg.prg_banks(to_integer(window)),
                      prg_bank_8kb_t'length);
    end;

    -- The level of the audio in the units of the mixed audio, offset to be
    -- positive. Mesen mixes the output of emu2413, 8 times that of
    -- Nuked-OPLL, at 1, where the APU at its loudest is about 5000, so a
    -- step is 8 * 255 / 5000 = 0.408 here, or 209 / 2**9
    function get_audio_level(audio : vrc7_audio_t) return cart_audio_t
    is
        constant MID : natural := (cart_audio_t'high + 1) / 2;
        variable level : integer;
    begin
        level := MID + (get_vrc7_audio_sum(audio) * 209) / 2**9;
        return min_int(max(level, 0), cart_audio_t'high);
    end;

    function cycle_mapper_vrc7
    (
        reg      : mapper_vrc7_reg_t;
        board    : vrc7_board_t;
        audio    : boolean;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t;
        ram_data : opll_ram_data_t;
        tables   : vrc7_tables_t
    )
    return mapper_vrc7_out_t
    is
        variable ret : mapper_vrc7_out_t;
        variable banks : cart_banks_t;
        variable window : chr_window_t;
        variable run : boolean;
    begin
        ret.reg := reg;
        run := audio and board.audio;

        -- The IRQ counter and the audio are clocked before the write of the
        -- CPU cycle, so a write is not undone by the clock
        ret.reg.irq := cycle_vrc_irq(reg.irq, clk_sync);
        if run
        then
            if reg.audio_reset
            then
                ret.reg.audio := reset_vrc7_audio(reg.audio);
            else
                ret.reg.audio := cycle_vrc7_audio(reg.audio,
                                                  clk_sync,
                                                  ram_data,
                                                  tables);
            end if;
        end if;
        ret.reg := cycle_write(ret.reg,
                               board,
                               run and not reg.audio_reset,
                               clk_sync,
                               cart_in);

        -- The PPU sees the registers written by the CPU this cycle
        banks := default_banks(config);
        banks.prg_ram := ret.reg.prg_ram;
        banks.prg := get_prg_bank(ret.reg, get_prg_window(cart_in.cpu));
        window := get_chr_window(cart_in.ppu);
        banks.chr := resize(ret.reg.chr_banks(to_integer(window)),
                            chr_bank_1kb_t'length);
        banks.mirror := ret.reg.mirror;

        ret.cart := map_cart(config, cart_in, banks);

        ret.cart.cpu.irq := reg.irq.irq;

        if run
        then
            ret.cart.audio := get_audio_level(reg.audio);
        end if;

        return ret;
    end;

    function get_vrc7_mem_out
    (
        reg      : mapper_vrc7_reg_t;
        board    : vrc7_board_t;
        run      : boolean;
        clk_sync : boolean
    )
    return opll_mem_out_t
    is
    begin
        if not run or not board.audio or reg.audio_reset
        then
            return OPLL_MEM_OUT_IDLE;
        end if;

        return
        (
            ram_bus => get_vrc7_ram_bus(reg.audio, clk_sync),
            data_to_ram => get_vrc7_ram_data(reg.audio, clk_sync)
        );
    end;

end package body;
