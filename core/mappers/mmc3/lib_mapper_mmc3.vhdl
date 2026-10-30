library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.prg_ram_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_types.all;

-- Boards built around the MMC3, the MMC6, the Namco 108, which came before
-- the MMC3, or the Tengen RAMBO-1, which extends it. They differ in how the
-- outputs of the chip are wired, so the board is chosen by the mapper number
-- at run time.
--
-- The Namco 108 has only the bank select and bank data registers of the
-- MMC3, at 0x8000-0x9FFF. Its PRG and CHR modes are always 0, and it has no
-- mirroring control, PRG RAM or IRQ. Its CHR banks are 6 bits wide
--
-- An iNES header cannot tell the MMC6 from the MMC3, so a TxROM board with
-- an iNES header becomes an MMC6 once the CPU sets bit 5 of 0x8000, which
-- enables the PRG RAM of the MMC6 and does nothing on the MMC3
--
-- The RAMBO-1 adds R8 and R9, which with bit 5 of 0x8000 set split the 2KB
-- CHR banks of R0 and R1 into 1KB banks, and RF, which selects the PRG ROM
-- bank the MMC3 fixes to the second last. It has no PRG RAM. Its IRQ
-- counter is clocked either by PPU A12, filtered on M2 rather than on PPU
-- clocks, or every 4 CPU cycles, and follows the rules nesdev gives as
-- demonstrated on hardware rather than those of Mesen
--
-- The multicart boards add outer bank registers, which select the part of
-- PRG ROM and CHR ROM the MMC3 banks within. Those written at 0x6000-0x7FFF
-- in place of PRG RAM are written only while 0xA001 enables PRG RAM without
-- write protection, unless the board says otherwise
--
-- To add a board, add it to mmc3_board_t, get_mmc3_board and the case of
-- cycle_mapper_mmc3 and its mapper number to is_mmc3_mapper. A multicart
-- board also goes in is_multicart, write_outer and the get_multicart_*
-- functions. A Namco 108
-- board also goes in is_namco_108, a RAMBO-1 board in is_rambo1, and a board
-- that wires its own CIRAM A10 in get_mirror
package lib_mapper_mmc3 is

    type mmc3_board_t is
    (
        -- TxROM (4)
        MMC3_TXROM,
        -- TxROM with an NEC MMC3 (4, NES 2.0 submapper 4), which raises the
        -- IRQ only when the counter reaches 0 from 1, or is reloaded after
        -- 0xC001 was written. A reload value of 0 then gives a single IRQ
        -- rather than one every scanline
        MMC3_NEC,
        -- HKROM (4, NES 2.0 submapper 1): the MMC6, which has 1KB of PRG
        -- RAM at 0x7000-0x7FFF, enabled in 512 byte halves
        MMC3_MMC6,
        -- NES-QJ (47): two 128KB PRG ROM and CHR ROM sets, selected by a
        -- latch at 0x6000-0x7FFF in place of PRG RAM
        MMC3_QJ,
        -- PAL-ZZ (37): a latch at 0x6000-0x7FFF in place of PRG RAM, whose
        -- bits Q2-Q0 drive PRG A17 and CHR A17 (Q2) and PRG A16 (Q0 and
        -- Q1, or Q2 and the A16 of the MMC3)
        MMC3_ZZ,
        -- Super Big 7-in-1 (44): bits 2-0 of 0xA001 select a block of
        -- 128KB of PRG ROM and CHR ROM, or of 256KB for blocks 6 and 7
        MMC3_SUPER_BIG_7,
        -- GA23C (45): four outer registers, written in turn at 0x6000
        -- whatever 0xA001 holds, give the bits of the PRG and CHR banks
        -- that are set (OR) and those that the MMC3 gives (AND). See
        -- write_outer
        MMC3_GA23C,
        -- Super HiK 4-in-1 (49): a register at 0x6000-0x7FFF in place of
        -- PRG RAM selects a block of 128KB of PRG ROM and CHR ROM and
        -- either a 32KB PRG bank or the PRG banks of the MMC3
        MMC3_SUPER_HIK_4,
        -- Realtec 8213 (52): a register at 0x6000-0x7FFF, over the PRG RAM,
        -- selects blocks of 128KB or 256KB of PRG ROM and CHR ROM, and can
        -- lock itself until reset
        MMC3_REALTEC_8213,
        -- TxSROM (118): bit 7 of the CHR bank drives CIRAM A10
        MMC3_TXSROM,
        -- TQROM (119): bit 6 of the CHR bank selects CHR RAM
        MMC3_TQROM,
        -- Namco 108 boards with hardwired mirroring: DxROM (206) and
        -- NAMCOT-3433/3443 (88), which wires PPU A12 to CHR A16 for 128KB of
        -- CHR. DxROM has at most 64KB of CHR, so it can be wired the same way
        NAMCO_108,
        -- NAMCOT-3425 (95): bit 5 of the CHR bank drives CIRAM A10
        NAMCO_3425,
        -- NAMCOT-3446 (76): 128KB of CHR in four 2KB banks, selected by the
        -- registers of the 1KB banks
        NAMCO_3446,
        -- NAMCOT-3453 (154): NAMCOT-3433 with single screen mirroring,
        -- selected by bit 6 of every write to 0x8000-0xFFFF
        NAMCO_3453,
        -- Tengen 800032 (64)
        RAMBO1,
        -- Tengen 800037 (158): bit 7 of the CHR bank drives CIRAM A10, as on
        -- TxSROM, in place of 0xA000
        RAMBO1_158
    );

    -- The mapper number is that of a board built around the MMC3, the MMC6,
    -- the Namco 108 or the RAMBO-1
    function is_mmc3_mapper(mapper_num : mapper_num_t) return boolean;

    function get_mmc3_board(config : cart_config_t) return mmc3_board_t;

    -- Bit 3 selects R8, R9 and RF on the RAMBO-1
    subtype bank_idx_t is unsigned(3 downto 0);

    subtype bank_t is unsigned(7 downto 0);
    type bank_arr_t is array(0 to 7) of bank_t;

    -- R8, R9 and RF of the RAMBO-1
    type rambo1_bank_arr_t is array(0 to 2) of bank_t;
    constant RAMBO1_R8 : natural := 0;
    constant RAMBO1_R9 : natural := 1;
    constant RAMBO1_RF : natural := 2;

    subtype irq_count_t is natural range 0 to 2**8-1;

    subtype irq_delay_t is boolean_array(1 downto 0);

    -- The MMC3 counts PPU clocks with A12 low, and clocks the IRQ counter
    -- when A12 rises after A12_MAX of them
    constant A12_MAX : natural := 10;
    -- The RAMBO-1 counts falls of M2 with A12 low, and clocks the IRQ
    -- counter on a fall of M2 with A12 high after RAMBO1_A12_MAX of them.
    -- Writing 0xC001 sets the count to RAMBO1_A12_RELOAD, which is never
    -- reached by counting, so the next rise of A12 does not clock it
    constant RAMBO1_A12_MAX : natural := 16;
    constant RAMBO1_A12_RELOAD : natural := 17;
    subtype a12_count_t is natural range 0 to RAMBO1_A12_RELOAD;

    -- The RAMBO-1 in CPU cycle mode clocks the IRQ counter every 4 CPU
    -- cycles
    subtype irq_prescaler_t is natural range 0 to 3;

    -- Bits 7-4 of 0xA001
    subtype prg_ram_bits_t is std_logic_vector(7 downto 4);

    -- The four registers of the GA23C. The other multicart boards have one,
    -- outer(0). On reset the GA23C takes all 8 bits of the CHR bank from
    -- the MMC3
    type outer_regs_t is array(0 to 3) of data_t;
    subtype outer_idx_t is natural range outer_regs_t'range;
    constant RESET_OUTER_REGS : outer_regs_t :=
    (
        2 => x"0F",
        others => x"00"
    );

    type mapper_mmc3_reg_t is record
        bank_idx : bank_idx_t;

        banks : bank_arr_t;
        rambo1_banks : rambo1_bank_arr_t;

        chr_mode : std_logic;
        prg_mode : std_logic;
        -- Bit 5 of 0x8000 on the RAMBO-1: R8 and R9 select the odd 1KB
        -- halves of the 2KB banks of R0 and R1
        chr_1kb : boolean;

        mirroring : std_logic;

        -- Bits 7-4 of 0xA001. On the MMC3, bit 7 enables PRG RAM and bit 6
        -- protects it from writes. On the MMC6, bits 7 and 6 enable reads
        -- and writes of the upper 512 bytes, and bits 5 and 4 of the lower
        prg_ram_bits : prg_ram_bits_t;
        -- Bit 5 of 0x8000, which enables the PRG RAM of the MMC6
        mmc6_ram_enable : boolean;
        -- The chip is an MMC6, found from the writes to 0x8000
        mmc6 : boolean;

        irq_count  : irq_count_t;
        irq_reload : irq_count_t;
        -- 0xC001 was written since the counter was last clocked
        irq_clear  : boolean;
        irq_enable : boolean;
        irq        : boolean;
        irq_delay  : irq_delay_t;

        -- The RAMBO-1 clocks its IRQ counter every 4 CPU cycles rather than
        -- on PPU A12
        irq_cpu_mode  : boolean;
        irq_prescaler : irq_prescaler_t;
        -- The RAMBO-1 raises the IRQ one CPU cycle after the clock that
        -- triggers it
        irq_pending   : boolean;

        a12_count : a12_count_t;

        -- The outer bank registers of the multicart boards, and the next
        -- one the GA23C writes
        outer     : outer_regs_t;
        outer_idx : outer_idx_t;
    end record;

    -- The bank registers power on with no set value. These are those of
    -- Mesen, FCEUX and Nestopia, which map 8KB of CHR RAM in order and which
    -- Famicom Yarou Vol. 1 (45) needs, since it writes CHR RAM before it
    -- sets them
    constant RESET_MAPPER_MMC3_REG : mapper_mmc3_reg_t :=
    (
        bank_idx => (others => '0'),

        banks => (x"00", x"02", x"04", x"05", x"06", x"07", x"00", x"01"),
        rambo1_banks => (others => (others => '0')),

        chr_mode => '0',
        prg_mode => '0',
        chr_1kb => false,

        mirroring => '0',

        prg_ram_bits => (others => '0'),
        mmc6_ram_enable => false,
        mmc6 => false,

        irq_count => 0,
        irq_reload => 0,
        irq_clear => false,
        irq_enable => false,
        irq => false,
        irq_delay => (others => false),

        irq_cpu_mode => false,
        irq_prescaler => 0,
        irq_pending => false,

        a12_count => 0,

        outer => RESET_OUTER_REGS,
        outer_idx => 0
    );

    type mapper_mmc3_out_t is record
        reg  : mapper_mmc3_reg_t;
        cart : cart_out_t;
    end record;

    function cycle_mapper_mmc3
    (
        reg      : mapper_mmc3_reg_t;
        board    : mmc3_board_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_mmc3_out_t;

end package lib_mapper_mmc3;


package body lib_mapper_mmc3 is

    function is_mmc3_mapper(mapper_num : mapper_num_t) return boolean
    is
    begin
        case mapper_num is
            when x"004" | x"025" | x"02C" | x"02D" | x"02F" | x"031" |
                 x"034" | x"04C" | x"058" | x"05F" | x"076" | x"077" |
                 x"09A" | x"0CE" | x"040" | x"09E" => return true;
            when others => return false;
        end case;
    end;

    function get_mmc3_board(config : cart_config_t) return mmc3_board_t
    is
    begin
        case config.mapper_num is
            when x"004" =>
                if config.submapper_num = x"1"
                then
                    return MMC3_MMC6;
                elsif config.submapper_num = x"4"
                then
                    return MMC3_NEC;
                else
                    return MMC3_TXROM;
                end if;
            when x"02F" => return MMC3_QJ;
            when x"025" => return MMC3_ZZ;
            when x"02C" => return MMC3_SUPER_BIG_7;
            when x"02D" => return MMC3_GA23C;
            when x"031" => return MMC3_SUPER_HIK_4;
            when x"034" => return MMC3_REALTEC_8213;
            when x"076" => return MMC3_TXSROM;
            when x"077" => return MMC3_TQROM;
            when x"0CE" | x"058" => return NAMCO_108;
            when x"05F" => return NAMCO_3425;
            when x"04C" => return NAMCO_3446;
            when x"09A" => return NAMCO_3453;
            when x"040" => return RAMBO1;
            when x"09E" => return RAMBO1_158;
            when others => return MMC3_TXROM;
        end case;
    end;

    function is_mmc6
    (
        reg   : mapper_mmc3_reg_t;
        board : mmc3_board_t
    )
    return boolean
    is
    begin
        return board = MMC3_MMC6 or reg.mmc6;
    end;

    function is_namco_108(board : mmc3_board_t) return boolean
    is
    begin
        return board = NAMCO_108 or
               board = NAMCO_3425 or
               board = NAMCO_3446 or
               board = NAMCO_3453;
    end;

    function is_rambo1(board : mmc3_board_t) return boolean
    is
    begin
        return board = RAMBO1 or board = RAMBO1_158;
    end;

    function is_multicart(board : mmc3_board_t) return boolean
    is
    begin
        return board = MMC3_QJ or
               board = MMC3_ZZ or
               board = MMC3_SUPER_BIG_7 or
               board = MMC3_GA23C or
               board = MMC3_SUPER_HIK_4 or
               board = MMC3_REALTEC_8213;
    end;

    -- The outer bank registers with the CPU write of this cycle
    function write_outer
    (
        reg      : mapper_mmc3_reg_t;
        board    : mmc3_board_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_mmc3_reg_t
    is
        variable ret : mapper_mmc3_reg_t;
        variable addr : prg_addr_t;
        variable data : data_t;
        variable prg_ram_write : boolean;
    begin
        ret := reg;
        addr := cart_in.cpu.prg_bus.address;
        data := cart_in.cpu.data;

        if not is_bus_write(cart_in.cpu.prg_bus) or not clk_sync
        then
            return ret;
        end if;

        -- A write to PRG RAM, as the MMC3 sees it
        prg_ram_write := is_prg_ram_window(cart_in.cpu) and
                         reg.prg_ram_bits(7 downto 6) = "10";

        case board is
            when MMC3_QJ | MMC3_ZZ | MMC3_SUPER_HIK_4 =>
                if prg_ram_write
                then
                    ret.outer(0) := data;
                end if;
            -- Until bit 7 locks it
            when MMC3_REALTEC_8213 =>
                if prg_ram_write and reg.outer(0)(7) = '0'
                then
                    ret.outer(0) := data;
                end if;
            -- The block is written with 0xA001, and block 7 is block 6
            when MMC3_SUPER_BIG_7 =>
                if cart_in.cpu.romsel and
                   addr(14 downto 13) = "01" and
                   addr(0) = '1'
                then
                    ret.outer(0) := "00000" & data(2 downto 0);
                    if data(2 downto 0) = "111"
                    then
                        ret.outer(0)(0) := '0';
                    end if;
                end if;
            -- The registers are at 0x6000-0x6FFF with A0 clear, until bit 6
            -- of register 3 locks them. A write with A0 set resets them and
            -- releases the lock
            when MMC3_GA23C =>
                if is_prg_ram_window(cart_in.cpu) and addr(12) = '0'
                then
                    if addr(0) = '1'
                    then
                        ret.outer := RESET_OUTER_REGS;
                        ret.outer_idx := 0;
                    elsif reg.outer(3)(6) = '0'
                    then
                        ret.outer(reg.outer_idx) := data;
                        if reg.outer_idx = outer_idx_t'high
                        then
                            ret.outer_idx := 0;
                        else
                            ret.outer_idx := reg.outer_idx + 1;
                        end if;
                    end if;
                end if;
            when others =>
        end case;

        return ret;
    end;

    -- The PRG ROM bank of a multicart board, from the bank the MMC3 selects
    function get_multicart_prg_bank
    (
        reg    : mapper_mmc3_reg_t;
        board  : mmc3_board_t;
        inner  : bank_t;
        window : prg_window_t
    )
    return prg_bank_8kb_t
    is
        variable outer : data_t;
        variable ret : prg_bank_8kb_t;
    begin
        outer := reg.outer(0);
        ret := inner;

        case board is
            when MMC3_QJ =>
                ret := "000" & outer(0) & inner(3 downto 0);
            when MMC3_ZZ =>
                ret := "000" & outer(2) &
                       ((outer(0) and outer(1)) or (outer(2) and inner(3))) &
                       inner(2 downto 0);
            -- Block 6 takes PRG A17 from the MMC3 as well
            when MMC3_SUPER_BIG_7 =>
                ret := "0" & unsigned(outer(2 downto 1)) &
                       (outer(0) or (outer(2) and outer(1) and inner(4))) &
                       inner(3 downto 0);
            -- PRG A21 and A22 are beyond the 2MB of PRG ROM banks
            when MMC3_GA23C =>
                outer := reg.outer(1);
                ret(5 downto 0) := (inner(5 downto 0) and
                                    not unsigned(reg.outer(3)(5 downto 0))) or
                                   unsigned(outer(5 downto 0));
                ret(7 downto 6) := unsigned(outer(7 downto 6));
            -- Bit 0 clear selects the 32KB bank of bits 5-4, from the
            -- first 128KB whatever the block
            when MMC3_SUPER_HIK_4 =>
                if outer(0) = '0'
                then
                    ret := "0000" & unsigned(outer(5 downto 4)) & window;
                else
                    ret := "00" & unsigned(outer(7 downto 6)) &
                           inner(3 downto 0);
                end if;
            -- Bit 3 set takes PRG A17 from bit 0 rather than the MMC3
            when MMC3_REALTEC_8213 =>
                ret := "0" & unsigned(outer(2 downto 1)) & inner(4 downto 0);
                if outer(3) = '1'
                then
                    ret(4) := outer(0);
                end if;
            when others =>
        end case;

        return ret;
    end;

    -- The 1KB CHR bank of a multicart board, from the bank the MMC3 selects
    function get_multicart_chr_bank
    (
        reg    : mapper_mmc3_reg_t;
        board  : mmc3_board_t;
        config : cart_config_t;
        inner  : bank_t
    )
    return chr_bank_1kb_t
    is
        variable outer : data_t;
        variable mask_bits : natural range 0 to 15;
        variable ret : chr_bank_1kb_t;
    begin
        outer := reg.outer(0);
        ret := resize(inner, ret'length);

        case board is
            when MMC3_QJ =>
                ret(7) := outer(0);
            when MMC3_ZZ =>
                ret(7) := outer(2);
            when MMC3_SUPER_BIG_7 =>
                ret(9 downto 7) := unsigned(outer(2 downto 0));
                ret(7) := outer(0) or (outer(2) and outer(1) and inner(7));
            -- Register 2 gives the number of bits taken from the MMC3, from
            -- 8 ($F) down to none ($7 and below), and CHR A18-A20. CHR A21
            -- is beyond the 2MB of CHR ROM banks. A board with CHR RAM
            -- takes its banks from the MMC3 alone, as in Mesen
            when MMC3_GA23C =>
                if not has_chr_ram(config)
                then
                    mask_bits := to_integer(reg.outer(2)(3 downto 0));
                    for i in inner'range
                    loop
                        ret(i) := (inner(i) and to_std_logic(i + 8 <= mask_bits))
                                  or reg.outer(0)(i);
                    end loop;
                    ret(10 downto 8) := unsigned(reg.outer(2)(6 downto 4));
                end if;
            when MMC3_SUPER_HIK_4 =>
                ret(8 downto 7) := unsigned(outer(7 downto 6));
            -- Bit 6 set takes CHR A17 from bit 4 rather than the MMC3
            when MMC3_REALTEC_8213 =>
                ret(9) := outer(2);
                ret(8) := outer(5);
                if outer(6) = '1'
                then
                    ret(7) := outer(4);
                end if;
            when others =>
        end case;

        return ret;
    end;

    -- The 8KB PRG ROM bank in the window of the CPU address
    function get_prg_bank
    (
        reg    : mapper_mmc3_reg_t;
        board  : mmc3_board_t;
        window : prg_window_t
    )
    return bank_t
    is
        variable bank : bank_t;
    begin
        case window is
            -- 0xA000-0xBFFF
            when "01" =>
                bank := reg.banks(7);
            -- 0xE000-0xFFFF is the last bank
            when "11" =>
                bank := x"FF";
            -- PRG mode 1 swaps 0x8000-0x9FFF and 0xC000-0xDFFF. The second
            -- last bank is RF on the RAMBO-1
            when others =>
                if (window(1) xor reg.prg_mode) = '0'
                then
                    bank := reg.banks(6);
                elsif is_rambo1(board)
                then
                    bank := reg.rambo1_banks(RAMBO1_RF);
                else
                    bank := x"FE";
                end if;
        end case;

        return bank;
    end;

    -- The 1KB CHR bank in the window of the PPU address
    function get_chr_bank
    (
        reg    : mapper_mmc3_reg_t;
        window : chr_window_t
    )
    return bank_t
    is
        variable bank : bank_t;
        variable swapped : chr_window_t;
    begin
        -- CHR mode 1 swaps the 2KB and 1KB banks between 0x0000 and 0x1000
        swapped := window;
        swapped(2) := window(2) xor reg.chr_mode;

        case swapped is
            when "000" | "001" =>
                bank := reg.banks(0);
            when "010" | "011" =>
                bank := reg.banks(1);
            when "100" =>
                bank := reg.banks(2);
            when "101" =>
                bank := reg.banks(3);
            when "110" =>
                bank := reg.banks(4);
            when others =>
                bank := reg.banks(5);
        end case;

        -- R0 and R1 select 2KB banks, unless the RAMBO-1 has R8 and R9
        -- select their odd 1KB halves
        if swapped(2) = '0'
        then
            if not reg.chr_1kb
            then
                bank(0) := swapped(0);
            elsif swapped(0) = '1'
            then
                if swapped(1) = '0'
                then
                    bank := reg.rambo1_banks(RAMBO1_R8);
                else
                    bank := reg.rambo1_banks(RAMBO1_R9);
                end if;
            end if;
        end if;

        return bank;
    end;

    function cycle_write
    (
        reg      : mapper_mmc3_reg_t;
        board    : mmc3_board_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_mmc3_reg_t
    is
        variable ret : mapper_mmc3_reg_t;
    begin
        ret := reg;

        -- The single screen mirroring of NAMCOT-3453
        if board = NAMCO_3453 and is_rom_write(cart_in.cpu, clk_sync)
        then
            ret.mirroring := cart_in.cpu.data(6);
        end if;

        -- The Namco 108 has only the registers at 0x8000-0x9FFF
        if is_rom_write(cart_in.cpu, clk_sync) and
           (not is_namco_108(board) or
            cart_in.cpu.prg_bus.address(14 downto 13) = "00")
        then
            case cart_in.cpu.prg_bus.address(14 downto 13) is
                -- 0x8000-0x9FFF
                when "00" =>
                    if cart_in.cpu.prg_bus.address(0) = '0'
                    then
                        ret.bank_idx := unsigned(cart_in.cpu.data(3 downto 0));

                        if not is_namco_108(board)
                        then
                            ret.chr_mode := cart_in.cpu.data(7);
                            ret.prg_mode := cart_in.cpu.data(6);
                            ret.mmc6_ram_enable := cart_in.cpu.data(5) = '1';
                        end if;

                        if is_rambo1(board)
                        then
                            ret.chr_1kb := cart_in.cpu.data(5) = '1';
                        end if;

                        if board = MMC3_TXROM and
                           not config.nes2 and
                           cart_in.cpu.data(5) = '1'
                        then
                            ret.mmc6 := true;
                        end if;

                        -- The MMC6 holds 0xA001 at 0 while its PRG RAM is
                        -- disabled
                        if is_mmc6(ret, board) and
                           (not reg.mmc6_ram_enable or
                            cart_in.cpu.data(5) = '0')
                        then
                            ret.prg_ram_bits := (others => '0');
                        end if;
                    -- Bit 3 of the index is only decoded by the RAMBO-1, which
                    -- has no register at 0xA-0xE
                    elsif reg.bank_idx(3) = '0' or not is_rambo1(board)
                    then
                        ret.banks(to_integer(reg.bank_idx(2 downto 0))) :=
                            unsigned(cart_in.cpu.data);
                    else
                        case reg.bank_idx(2 downto 0) is
                            when "000" =>
                                ret.rambo1_banks(RAMBO1_R8) :=
                                    unsigned(cart_in.cpu.data);
                            when "001" =>
                                ret.rambo1_banks(RAMBO1_R9) :=
                                    unsigned(cart_in.cpu.data);
                            when "111" =>
                                ret.rambo1_banks(RAMBO1_RF) :=
                                    unsigned(cart_in.cpu.data);
                            when others =>
                        end case;
                    end if;
                -- 0xA000-0xBFFF
                when "01" =>
                    if cart_in.cpu.prg_bus.address(0) = '0'
                    then
                        ret.mirroring := cart_in.cpu.data(0);
                    -- The MMC6 ignores this while its PRG RAM is disabled
                    elsif not is_mmc6(reg, board) or reg.mmc6_ram_enable
                    then
                        ret.prg_ram_bits := cart_in.cpu.data(7 downto 4);
                    end if;
                -- 0xC000-0xDFFF
                when "10" =>
                    if cart_in.cpu.prg_bus.address(0) = '0'
                    then
                        ret.irq_reload :=
                            to_integer(cart_in.cpu.data);
                    -- The RAMBO-1 reloads the counter at once, selects the
                    -- source of its clock and restarts the prescaler and
                    -- the A12 filter
                    elsif is_rambo1(board)
                    then
                        ret.irq_count := reg.irq_reload;
                        ret.irq_cpu_mode := cart_in.cpu.data(0) = '1';
                        ret.irq_prescaler := 0;
                        ret.a12_count := RAMBO1_A12_RELOAD;
                    else
                        ret.irq_count := 0;
                        ret.irq_clear := true;
                    end if;
                -- 0xE000-0xFFFF
                when others =>
                    ret.irq_enable := cart_in.cpu.prg_bus.address(0) = '1';
                    ret.irq := reg.irq and ret.irq_enable;
                    ret.irq_pending := reg.irq_pending and ret.irq_enable;
            end case;
        end if;

        if is_multicart(board)
        then
            ret := write_outer(ret, board, clk_sync, cart_in);
        end if;

        return ret;
    end;

    -- The IRQ counter is clocked when PPU A12 rises after being low for
    -- A12_MAX PPU clocks
    function cycle_irq
    (
        reg     : mapper_mmc3_reg_t;
        board   : mmc3_board_t;
        cart_in : cart_in_t
    )
    return mapper_mmc3_reg_t
    is
        variable ret : mapper_mmc3_reg_t;
    begin
        ret := reg;

        if not is_bus_active(cart_in.ppu.chr_bus) or
           cart_in.ppu.chr_bus.address(12) = '0'
        then
            if reg.a12_count < A12_MAX
            then
                ret.a12_count := reg.a12_count + 1;
            end if;
        else
            ret.a12_count := 0;
            if reg.a12_count = A12_MAX
            then
                if reg.irq_count = 0
                then
                    ret.irq_count := reg.irq_reload;
                else
                    ret.irq_count := reg.irq_count - 1;
                end if;
                ret.irq_clear := false;

                if ret.irq_count = 0 and
                   (board /= MMC3_NEC or reg.irq_count /= 0 or reg.irq_clear)
                then
                    ret.irq := reg.irq_enable;
                end if;
            end if;
        end if;

        -- IRQ needs to be delayed, but acknowledging it clears it immediately
        if ret.irq
        then
            ret.irq_delay := shift_left(reg.irq_delay, true);
        else
            ret.irq_delay := (others => false);
        end if;

        return ret;
    end;

    -- The IRQ counter of the RAMBO-1 is clocked on the falls of M2, which
    -- are at clk_sync. On a clock, a counter of 0 is reloaded and raises the
    -- IRQ a CPU cycle later, if IRQs are enabled. Any other count is
    -- decremented
    function cycle_rambo1_irq
    (
        reg      : mapper_mmc3_reg_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_mmc3_reg_t
    is
        variable ret : mapper_mmc3_reg_t;
        variable clock : boolean;
    begin
        ret := reg;

        if clk_sync
        then
            ret.irq := reg.irq or reg.irq_pending;
            ret.irq_pending := false;

            clock := false;
            if reg.irq_cpu_mode
            then
                if reg.irq_prescaler = irq_prescaler_t'high
                then
                    ret.irq_prescaler := 0;
                    clock := true;
                else
                    ret.irq_prescaler := reg.irq_prescaler + 1;
                end if;
            elsif is_bus_active(cart_in.ppu.chr_bus) and
                  cart_in.ppu.chr_bus.address(12) = '1'
            then
                ret.a12_count := 0;
                clock := reg.a12_count = RAMBO1_A12_MAX;
            elsif reg.a12_count < RAMBO1_A12_MAX
            then
                ret.a12_count := reg.a12_count + 1;
            end if;

            if clock
            then
                if reg.irq_count = 0
                then
                    ret.irq_count := reg.irq_reload;
                    ret.irq_pending := reg.irq_enable;
                else
                    ret.irq_count := reg.irq_count - 1;
                end if;
            end if;
        end if;

        return ret;
    end;

    -- The CPU accesses PRG RAM at 0x6000-0x7FFF
    function is_prg_ram_enabled
    (
        reg     : mapper_mmc3_reg_t;
        board   : mmc3_board_t;
        cart_in : cart_in_t
    )
    return boolean
    is
    begin
        if board = MMC3_QJ or board = MMC3_ZZ or board = MMC3_SUPER_HIK_4 or
           is_namco_108(board) or is_rambo1(board)
        then
            return false;
        elsif is_mmc6(reg, board)
        then
            -- 0x7000-0x7FFF, when either half can be read
            return reg.mmc6_ram_enable and
                   cart_in.cpu.prg_bus.address(12) = '1' and
                   (reg.prg_ram_bits(7) = '1' or reg.prg_ram_bits(5) = '1');
        else
            return reg.prg_ram_bits(7) = '1';
        end if;
    end;

    -- Applies the write protection of the PRG RAM, and on the MMC6 the
    -- 1KB size of the PRG RAM and the enables of its halves
    function protect_prg_ram
    (
        reg      : mapper_mmc3_reg_t;
        board    : mmc3_board_t;
        cart_in  : cart_in_t;
        cart_out : cart_out_t
    )
    return cart_out_t
    is
        variable ret : cart_out_t;
        variable bits : std_logic_vector(1 downto 0);
    begin
        ret := cart_out;

        if is_mmc6(reg, board)
        then
            ret.mem.prg_ram_bus.address(12 downto 10) := "000";

            -- The read and write enables of the half selected by bit 9 of
            -- the address
            if cart_in.cpu.prg_bus.address(9) = '1'
            then
                bits := reg.prg_ram_bits(7 downto 6);
            else
                bits := reg.prg_ram_bits(5 downto 4);
            end if;

            -- A half that cannot be read reads 0 when the other half can be
            -- read. A half can only be written when it can be read
            if bits(1) = '0'
            then
                ret.cpu.data := x"00";
            end if;

            if bits /= "11"
            then
                ret.mem.prg_ram_bus.write := false;
            end if;
        elsif reg.prg_ram_bits(6) = '1'
        then
            ret.mem.prg_ram_bus.write := false;
        end if;

        return ret;
    end;

    function get_mirror
    (
        reg      : mapper_mmc3_reg_t;
        board    : mmc3_board_t;
        config   : cart_config_t;
        chr_bank : bank_t
    )
    return mirror_t
    is
    begin
        -- The CHR bank is computed for nametable addresses as well, so on
        -- the boards that wire a bit of it to CIRAM A10, each 1KB nametable
        -- window has its own CIRAM A10
        case board is
            when MMC3_TXSROM | RAMBO1_158 =>
                return get_single_screen_mirror(chr_bank(7));
            when NAMCO_3425 =>
                return get_single_screen_mirror(chr_bank(5));
            when NAMCO_3453 =>
                return get_single_screen_mirror(reg.mirroring);
            when NAMCO_108 | NAMCO_3446 =>
                return config.mirror;
            when others =>
                if config.mirror = MIRROR_FOUR
                then
                    return config.mirror;
                else
                    return get_hv_mirror(reg.mirroring);
                end if;
        end case;
    end;

    function cycle_mapper_mmc3
    (
        reg      : mapper_mmc3_reg_t;
        board    : mmc3_board_t;
        config   : cart_config_t;
        clk_sync : boolean;
        cart_in  : cart_in_t
    )
    return mapper_mmc3_out_t
    is
        variable ret : mapper_mmc3_out_t;
        variable written : mapper_mmc3_reg_t;
        variable banks : cart_banks_t;
        variable prg_bank : bank_t;
        variable chr_window : chr_window_t;
        variable bank_window : chr_window_t;
        variable chr_bank : bank_t;
    begin
        -- The PPU sees the registers written by the CPU this cycle. The
        -- RAMBO-1 clocks its IRQ counter before the write of the CPU cycle,
        -- so a write to 0xC001 restarts the prescaler and the A12 filter;
        -- the MMC3 after it
        if is_rambo1(board)
        then
            written := cycle_rambo1_irq(reg, clk_sync, cart_in);
        else
            written := reg;
        end if;
        written := cycle_write(written, board, config, clk_sync, cart_in);
        if is_rambo1(board)
        then
            ret.reg := written;
        else
            ret.reg := cycle_irq(written, board, cart_in);
        end if;

        chr_window := get_chr_window(cart_in.ppu);

        -- NAMCOT-3446 maps the 2KB banks of the 1KB bank registers, at
        -- 0x1000-0x1FFF in CHR mode 0, to 0x0000-0x1FFF
        bank_window := chr_window;
        if board = NAMCO_3446
        then
            bank_window := "1" & chr_window(2 downto 1);
        end if;

        prg_bank := get_prg_bank(written,
                                 board,
                                 get_prg_window(cart_in.cpu));
        chr_bank := get_chr_bank(written, bank_window);

        banks := default_banks(config);
        banks.prg_ram := is_prg_ram_enabled(written, board, cart_in);
        banks.mirror := get_mirror(written, board, config, chr_bank);

        case board is
            when MMC3_TXROM | MMC3_NEC | MMC3_MMC6 | MMC3_TXSROM |
                 RAMBO1 | RAMBO1_158 =>
            when MMC3_QJ | MMC3_ZZ | MMC3_SUPER_BIG_7 | MMC3_GA23C |
                 MMC3_SUPER_HIK_4 | MMC3_REALTEC_8213 =>
            when MMC3_TQROM =>
                banks.chr_ram := chr_bank(6) = '1';
            when NAMCO_108 | NAMCO_3425 | NAMCO_3453 =>
                -- PPU A12 drives CHR A16 on NAMCOT-3433 and NAMCOT-3453.
                -- The other boards have at most 64KB of CHR, which drops it
                chr_bank := "0" & cart_in.ppu.chr_bus.address(12) &
                            chr_bank(5 downto 0);
            when NAMCO_3446 =>
                chr_bank := "0" & chr_bank(5 downto 0) & chr_window(0);
        end case;

        if is_multicart(board)
        then
            banks.prg := get_multicart_prg_bank(written, board, prg_bank,
                                                get_prg_window(cart_in.cpu));
            banks.chr := get_multicart_chr_bank(written, board, config,
                                                chr_bank);
        else
            banks.prg := prg_bank;
            banks.chr := resize(chr_bank, chr_bank_1kb_t'length);
        end if;

        ret.cart := map_cart(config, cart_in, banks);
        if is_bus_active(ret.cart.mem.prg_ram_bus)
        then
            ret.cart := protect_prg_ram(written, board, cart_in, ret.cart);
        end if;
        -- The IRQ of the MMC3 is set by the PPU in the middle of a CPU
        -- cycle, which the CPU sees about 2 PPU clocks later. That of the
        -- RAMBO-1 is set on M2
        if is_rambo1(board)
        then
            ret.cart.cpu.irq := reg.irq;
        else
            ret.cart.cpu.irq := ret.reg.irq and
                                reg.irq_delay(reg.irq_delay'high);
        end if;

        return ret;
    end;

end package body;
