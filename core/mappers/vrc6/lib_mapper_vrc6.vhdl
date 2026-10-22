library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.chr_bus_types.all;
use work.cart_types.all;
use work.lib_vrc_irq.all;
use work.lib_vrc6_audio.all;

-- Boards built around the Konami VRC6 (24, 26): a 16KB PRG ROM bank at
-- 0x8000, an 8KB bank at 0xC000, eight CHR registers that map the pattern
-- tables in 1KB or 2KB banks and the nametables to CIRAM or CHR ROM, the
-- VRC IRQ counter and three channels of audio. VRC6b (26) has the A0 and A1
-- inputs of the chip wired to CPU A1 and A0 rather than A0 and A1
package lib_mapper_vrc6 is

    -- The mapper number is that of a board built around the VRC6
    function is_vrc6_mapper(mapper_num : mapper_num_t) return boolean;

    subtype prg_bank_16kb_t is unsigned(3 downto 0);
    subtype prg_bank_t is unsigned(4 downto 0);

    -- R0-R7, at 0xD000-0xD003 and 0xE000-0xE003
    subtype chr_reg_t is unsigned(7 downto 0);
    type chr_reg_arr_t is array(0 to 7) of chr_reg_t;
    subtype chr_reg_idx_t is natural range 0 to 7;

    -- The PPU banking style of 0xB003, decoded when it is written. Bits 1-0
    -- select how R0-R7 map the pattern tables
    type chr_layout_t is
    (
        -- R0-R7 each map 1KB
        CHR_1KB,
        -- R0-R3 each map 2KB
        CHR_2KB,
        -- R0-R3 each map 1KB at 0x0000 and R4-R5 2KB at 0x1000
        CHR_1KB_2KB
    );

    -- The registers that map the four nametables
    type nt_regs_t is
    (
        -- R6 at 0x2000 and 0x2400, R7 at 0x2800 and 0x2C00
        NT_R6_R7_A11,
        -- R6 at 0x2000 and 0x2800, R7 at 0x2400 and 0x2C00
        NT_R6_R7_A10,
        -- R4-R7
        NT_R4_R7
    );

    -- Where the low bit of the bank of a nametable comes from. It is also
    -- CIRAM A10 when the nametables are in CIRAM
    type nt_lsb_t is
    (
        NT_LSB_REG,
        NT_LSB_A10,
        NT_LSB_A11,
        NT_LSB_0,
        NT_LSB_1
    );

    type mapper_vrc6_reg_t is record
        prg_bank_16kb : prg_bank_16kb_t;
        prg_bank_8kb  : prg_bank_t;

        chr_regs      : chr_reg_arr_t;

        -- 0xB003
        chr_layout    : chr_layout_t;
        -- The low bit of a 2KB pattern table bank is PPU A10 rather than
        -- that of its register
        chr_a10       : boolean;
        nt_regs       : nt_regs_t;
        nt_lsb        : nt_lsb_t;
        -- The nametables are in CHR ROM rather than CIRAM
        nt_chr        : boolean;
        prg_ram       : boolean;

        irq           : vrc_irq_t;

        audio         : vrc6_audio_t;
    end record;

    type mapper_vrc6_out_t is record
        reg  : mapper_vrc6_reg_t;
        cart : cart_out_t;
    end record;

    -- The registers as they are at reset, which is as though 0 had been
    -- written to every register
    function get_reset_vrc6_reg return mapper_vrc6_reg_t;

    function cycle_mapper_vrc6
    (
        reg      : mapper_vrc6_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_vrc6_out_t;

end package lib_mapper_vrc6;


package body lib_mapper_vrc6 is

    function is_vrc6_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        case mapper_num is
            when x"018" | x"01A" => return true;
            when others => return false;
        end case;
    end;

    -- Decodes a write to 0xB003: W.PN MMDD. W enables PRG RAM, P passes PPU
    -- A10 to 2KB banks and overrides the low bit of the nametable banks
    -- with the mirroring in MM in modes (DD) 0 and 3, and N puts the
    -- nametables in CHR ROM. The tables are those on nesdev, which agree
    -- with Mesen
    function write_banking_style
    (
        reg  : mapper_vrc6_reg_t;
        data : data_t
    )
    return mapper_vrc6_reg_t
    is
        variable ret : mapper_vrc6_reg_t;
        variable mirror : std_logic_vector(1 downto 0);
    begin
        ret := reg;

        case data(1 downto 0) is
            when "00" => ret.chr_layout := CHR_1KB;
            when "01" => ret.chr_layout := CHR_2KB;
            when others => ret.chr_layout := CHR_1KB_2KB;
        end case;

        ret.chr_a10 := data(5) = '1';
        ret.nt_chr := data(4) = '1';
        ret.prg_ram := data(7) = '1';

        if data(5) = '1' and (data(1 downto 0) = "00" or
                              data(1 downto 0) = "11")
        then
            -- Mode 3 has the mirroring of mode 0 with bit 2 inverted
            mirror := data(3 downto 2);
            if data(1 downto 0) = "11"
            then
                mirror(0) := not mirror(0);
            end if;

            -- Vertical, horizontal, one screen A and one screen B, from
            -- R6 and R7
            case mirror is
                when "00" =>
                    ret.nt_regs := NT_R6_R7_A11;
                    ret.nt_lsb := NT_LSB_A10;
                when "01" =>
                    ret.nt_regs := NT_R6_R7_A10;
                    ret.nt_lsb := NT_LSB_A11;
                when "10" =>
                    ret.nt_regs := NT_R6_R7_A11;
                    ret.nt_lsb := NT_LSB_0;
                when others =>
                    ret.nt_regs := NT_R6_R7_A10;
                    ret.nt_lsb := NT_LSB_1;
            end case;
        else
            ret.nt_lsb := NT_LSB_REG;
            case data(2 downto 0) is
                when "001" | "101" =>
                    ret.nt_regs := NT_R4_R7;
                when "010" | "011" | "100" =>
                    ret.nt_regs := NT_R6_R7_A10;
                when others =>
                    ret.nt_regs := NT_R6_R7_A11;
            end case;
        end if;

        return ret;
    end;

    function get_reset_vrc6_reg return mapper_vrc6_reg_t
    is
        variable ret : mapper_vrc6_reg_t;
    begin
        ret.prg_bank_16kb := (others => '0');
        ret.prg_bank_8kb := (others => '0');
        ret.chr_regs := (others => (others => '0'));
        ret.irq := RESET_VRC_IRQ;
        ret.audio := RESET_VRC6_AUDIO;

        return write_banking_style(ret, (others => '0'));
    end;

    function cycle_write
    (
        reg      : mapper_vrc6_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_vrc6_reg_t
    is
        variable ret : mapper_vrc6_reg_t;
        variable data : data_t;
        -- The A1 and A0 inputs of the chip
        variable lines : std_logic_vector(1 downto 0);
        variable reg_idx : natural range 0 to 3;
    begin
        ret := reg;
        data := cart_in.cpu.data;

        lines := cart_in.cpu.prg_bus.address(1 downto 0);
        if config.mapper_num = x"01A"
        then
            lines := lines(0) & lines(1);
        end if;
        reg_idx := to_integer(lines);

        if is_rom_write(cart_in.cpu, clk_sync)
        then
            case cart_in.cpu.prg_bus.address(14 downto 12) is
                when "000" =>
                    ret.prg_bank_16kb := unsigned(data(prg_bank_16kb_t'range));
                when "001" =>
                    if reg_idx = 3
                    then
                        ret.audio :=
                            write_vrc6_frequency_control(reg.audio, data);
                    else
                        ret.audio := write_vrc6_channel(reg.audio,
                                                        VRC6_PULSE_1,
                                                        reg_idx,
                                                        data);
                    end if;
                when "010" =>
                    if reg_idx /= 3
                    then
                        ret.audio := write_vrc6_channel(reg.audio,
                                                        VRC6_PULSE_2,
                                                        reg_idx,
                                                        data);
                    end if;
                when "011" =>
                    if reg_idx = 3
                    then
                        ret := write_banking_style(reg, data);
                    else
                        ret.audio := write_vrc6_channel(reg.audio,
                                                        VRC6_SAW,
                                                        reg_idx,
                                                        data);
                    end if;
                when "100" =>
                    ret.prg_bank_8kb := unsigned(data(prg_bank_t'range));
                when "101" =>
                    ret.chr_regs(reg_idx) := unsigned(data);
                when "110" =>
                    ret.chr_regs(4 + reg_idx) := unsigned(data);
                when others =>
                    case reg_idx is
                        when 0 =>
                            ret.irq := write_vrc_irq_latch(reg.irq, data);
                        when 1 =>
                            ret.irq := write_vrc_irq_control(reg.irq, data);
                        when 2 =>
                            ret.irq := acknowledge_vrc_irq(reg.irq);
                        when 3 =>
                            null;
                    end case;
            end case;
        end if;

        return ret;
    end;

    -- The 8KB PRG ROM bank in the window of the CPU address
    function get_prg_bank
    (
        reg    : mapper_vrc6_reg_t;
        window : prg_window_t
    )
    return prg_bank_8kb_t
    is
    begin
        case window is
            when "00" | "01" =>
                return resize(reg.prg_bank_16kb & window(0),
                              prg_bank_8kb_t'length);
            when "10" =>
                return resize(reg.prg_bank_8kb, prg_bank_8kb_t'length);
            when others =>
                return (others => '1');
        end case;
    end;

    -- The 1KB bank of a register that maps 2KB: the even bank of the pair
    -- and PPU A10 when chr_a10 is set, else the register itself
    function get_2kb_half
    (
        reg  : mapper_vrc6_reg_t;
        bank : chr_reg_t;
        a10  : std_logic
    )
    return chr_reg_t
    is
        variable ret : chr_reg_t;
    begin
        ret := bank;
        if reg.chr_a10
        then
            ret(0) := a10;
        end if;

        return ret;
    end;

    -- The 1KB CHR bank of a pattern table access, in the window of the PPU
    -- address
    function get_pattern_bank
    (
        reg    : mapper_vrc6_reg_t;
        window : chr_window_t
    )
    return chr_reg_t
    is
        variable idx : chr_reg_idx_t;
    begin
        idx := to_integer(window);

        case reg.chr_layout is
            when CHR_1KB =>
                return reg.chr_regs(idx);
            when CHR_2KB =>
                return get_2kb_half(reg, reg.chr_regs(idx / 2), window(0));
            when CHR_1KB_2KB =>
                if window(2) = '0'
                then
                    return reg.chr_regs(idx);
                else
                    return get_2kb_half(reg,
                                        reg.chr_regs(2 + idx / 2),
                                        window(0));
                end if;
        end case;
    end;

    -- The 1KB bank of a nametable access, in CHR ROM, or whose low bit is
    -- CIRAM A10
    function get_nt_bank
    (
        reg  : mapper_vrc6_reg_t;
        addr : chr_addr_t
    )
    return chr_reg_t
    is
        variable idx : chr_reg_idx_t;
        variable ret : chr_reg_t;
    begin
        case reg.nt_regs is
            when NT_R6_R7_A11 =>
                idx := 6 + to_integer(addr(11 downto 11));
            when NT_R6_R7_A10 =>
                idx := 6 + to_integer(addr(10 downto 10));
            when NT_R4_R7 =>
                idx := 4 + to_integer(addr(11 downto 10));
        end case;

        ret := reg.chr_regs(idx);

        case reg.nt_lsb is
            when NT_LSB_REG => null;
            when NT_LSB_A10 => ret(0) := addr(10);
            when NT_LSB_A11 => ret(0) := addr(11);
            when NT_LSB_0 => ret(0) := '0';
            when NT_LSB_1 => ret(0) := '1';
        end case;

        return ret;
    end;

    function cycle_mapper_vrc6
    (
        reg      : mapper_vrc6_reg_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_vrc6_out_t
    is
        variable ret : mapper_vrc6_out_t;
        variable banks : cart_banks_t;
        variable chr_bank : chr_reg_t;
    begin
        ret.reg := reg;

        -- The IRQ counter and the audio are clocked before the write of the
        -- CPU cycle, so a write is not undone by the clock
        ret.reg.irq := cycle_vrc_irq(reg.irq, clk_sync);
        ret.reg.audio := cycle_vrc6_audio(reg.audio, clk_sync);
        ret.reg := cycle_write(ret.reg, config, clk_sync, cart_in);

        -- The PPU sees the registers written by the CPU this cycle
        banks := default_banks(config);
        banks.prg_ram := ret.reg.prg_ram;
        banks.prg := get_prg_bank(ret.reg, get_prg_window(cart_in.cpu));

        if cart_in.ppu.chr_bus.address(13) = '0'
        then
            chr_bank := get_pattern_bank(ret.reg,
                                         get_chr_window(cart_in.ppu));
        else
            chr_bank := get_nt_bank(ret.reg, cart_in.ppu.chr_bus.address);
            banks.nt_chr := ret.reg.nt_chr;
            banks.mirror := get_single_screen_mirror(chr_bank(0));
        end if;
        banks.chr := resize(chr_bank, chr_bank_1kb_t'length);

        ret.cart := map_cart(config, cart_in, banks);

        ret.cart.cpu.irq := reg.irq.irq;
        ret.cart.audio := get_vrc6_audio_level(reg.audio);

        return ret;
    end;

end package body;
