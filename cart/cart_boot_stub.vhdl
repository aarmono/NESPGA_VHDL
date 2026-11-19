library IEEE;
use IEEE.std_logic_1164.all;
use work.nes_types.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.cart_connector_types.all;

-- What a cartridge in a real console answers until its game is ready. The
-- CPU fetches the reset vector a few cycles after reset, long before the ROM
-- file is loaded, and the connector has no reset to hold it with. So the
-- console is given a stub that loops without writing anything or changing a
-- register or flag, and the game then starts as from reset.
--
-- The stub answers again whenever the cartridge stops being ready, as when
-- it loads another game. That game also starts as from reset, but the
-- console's PPU and APU are as the last program left them.
entity cart_boot_stub is
port
(
    clk   : in std_logic;
    reset : in boolean;

    cpu_en : in boolean;
    -- The cartridge can answer the console
    ready  : in boolean;
    -- The stub is answering in place of the cartridge
    active : out boolean;

    -- The console's side of the connector
    cpu_in : in cart_cpu_in_t;
    ppu_in : in cart_ppu_in_t;

    -- The cartridge's side of the connector
    cart_cpu_out : in cart_cpu_out_t;
    cart_ppu_out : in cart_ppu_out_t;

    -- What the console is answered
    cpu_out : out cart_cpu_out_t;
    ppu_out : out cart_ppu_out_t
);
end entity;

architecture behavioral of cart_boot_stub
is

    type stub_reg_t is record
        active : boolean;
        -- The cartridge was ready as this CPU cycle started
        armed  : boolean;
    end record;

    constant RESET_STUB_REG : stub_reg_t :=
    (
        active => true,
        armed => false
    );

    -- The low byte of the reset vector, less /ROMSEL's A15
    constant RESET_VECTOR_ADDR : prg_addr_t := "111111111111100";

    subtype stub_idx_t is std_logic_vector(1 downto 0);

    -- Four bytes, repeated through 0x8000-0xFFFF. The reset vector reads
    -- 0xFC6C, where JMP (0xFFFC) jumps to itself. From anywhere else in
    -- 0x8000-0xFFFF the CPU reaches the JMP within three instructions: the
    -- other bytes read as NOP abs,X or ISC abs,X, each of which ends a byte
    -- short of where it started in the four, and the NMI and IRQ vectors
    -- read 0xFCFF. The ISC writes to 0x6C00-0x6DFF, which a cartridge that
    -- isn't ready ignores. A CPU running code outside 0x8000-0xFFFF is not
    -- caught until an interrupt takes it there
    function get_stub_data(addr : prg_addr_t) return data_t
    is
    begin
        case stub_idx_t'(addr(1 downto 0)) is
            -- JMP (0xFFFC)
            when "00" => return x"6C";
            when "01" => return x"FC";
            when "10" => return x"FF";
            when others => return x"FC";
        end case;
    end;

    -- The stub answers this cycle. The game takes over on a read of 0xFFFC
    -- once the cartridge is ready. The stub reads 0xFFFC as the fourth cycle
    -- of each JMP, so the same instruction fetches the game's reset vector.
    -- The CPU's reset sequence reads it too, so a console that is reset
    -- after the cartridge is ready never sees the stub
    function is_active
    (
        cur        : stub_reg_t;
        cpu        : cart_cpu_in_t;
        cart_ready : boolean
    )
    return boolean
    is
    begin
        return (cur.active or not cart_ready) and
               not (cur.armed and cart_ready and cpu.romsel and
                    cpu.prg_bus.read and
                    cpu.prg_bus.address = RESET_VECTOR_ADDR);
    end;

    function get_stub_cpu_out(cpu : cart_cpu_in_t) return cart_cpu_out_t
    is
    begin
        return
        (
            data => get_stub_data(cpu.prg_bus.address),
            data_oe => cpu.romsel and cpu.prg_bus.read,
            data_float => (others => '0'),
            irq => false
        );
    end;

    -- The console's own nametables, mirrored vertically, and nothing at
    -- 0x0000-0x1FFF
    function get_stub_ppu_out(ppu : cart_ppu_in_t) return cart_ppu_out_t
    is
    begin
        return
        (
            data => (others => '-'),
            data_oe => false,
            ciram_ce => ppu.chr_bus.address(13) = '1',
            ciram_a10 => ppu.chr_bus.address(10)
        );
    end;

    signal reg : stub_reg_t := RESET_STUB_REG;

begin

    active <= is_active(reg, cpu_in, ready);

    cpu_out <= get_stub_cpu_out(cpu_in) when is_active(reg, cpu_in, ready) else
               cart_cpu_out;
    ppu_out <= get_stub_ppu_out(ppu_in) when is_active(reg, cpu_in, ready) else
               cart_ppu_out;

    process(clk)
    begin
    if rising_edge(clk)
    then
        if reset
        then
            reg <= RESET_STUB_REG;
        else
            reg.active <= is_active(reg, cpu_in, ready);
            if cpu_en
            then
                reg.armed <= ready;
            end if;
        end if;
    end if;
    end process;

end behavioral;
