library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.joy_bus_types.all;
use work.ram_bus_types.all;
use work.ppu_bus_types.all;
use work.prg_bus_types.all;
use work.chr_bus_types.all;
use work.ciram_bus_types.all;
use work.nes_types.all;
use work.utilities.all;
use work.cart_types.all;

-- The memory maps of the console. Anything the console does not decode
-- itself is on the cartridge
package lib_nes_mmap is

    type cpu_mmap_reg_t is record
        -- Last value driven on the CPU data bus
        open_bus     : data_t;
        -- Last value on the data bus internal to the CPU. It is not
        -- updated by DMA reads
        internal_bus : data_t;
    end record;

    constant RESET_CPU_MMAP_REG : cpu_mmap_reg_t :=
    (
        open_bus => (others => '0'),
        internal_bus => (others => '0')
    );

    -- The complete set of bus inputs for
    -- NES CPU memory mapping
    type cpu_mmap_bus_in_t is record
        cpu_bus : cpu_bus_t;

        clk_sync : boolean;
        -- A DMA unit, not the CPU, is driving the bus
        dma_cycle : boolean;
        -- The CPU's own address bus is in 0x4000-0x401F. The APU and joypad
        -- registers are selected by the low 5 bits of the bus address only
        -- when this is true, even during a DMA
        apu_regs_active : boolean;
        
        data_from_cpu  : data_t;
        data_from_apu  : data_t;
        data_from_joy  : data_t;
        data_from_ram  : data_t;
        data_from_ppu  : data_t;
    end record;
    
    -- The complete set of bus outputs for
    -- NES CPU memory mapping
    type cpu_mmap_bus_out_t is record
        apu_bus       : apu_bus_t;
        joy_bus       : joy_bus_t;
        ram_bus       : ram_bus_t;
        ppu_bus       : ppu_bus_t;
        oam_dma_write : boolean;
        
        data_to_cpu     : data_t;
        data_to_apu     : data_t;
        data_to_joy     : data_t;
        data_to_ram     : data_t;
        data_to_ppu     : data_t;
    end record;
    
    constant CPU_MMAP_BUS_IDLE : cpu_mmap_bus_out_t :=
    (
        apu_bus => APU_BUS_IDLE,
        joy_bus => JOY_BUS_IDLE,
        ram_bus => RAM_BUS_IDLE,
        ppu_bus => PPU_BUS_IDLE,
        oam_dma_write => false,
        
        data_to_cpu => (others => '-'),
        data_to_apu => (others => '-'),
        data_to_joy => (others => '-'),
        data_to_ram => (others => '-'),
        data_to_ppu => (others => '-')
    );

    type cpu_mmap_in_t is record
        reg    : cpu_mmap_reg_t;
        bus_in : cpu_mmap_bus_in_t;
        cart   : cart_cpu_out_t;
    end record;
    
    type cpu_mmap_out_t is record
        reg     : cpu_mmap_reg_t;
        bus_out : cpu_mmap_bus_out_t;
    end record;
    
    function mmap_cpu_memory(map_in : cpu_mmap_in_t) return cpu_mmap_out_t;

    -- The complete set of bus inputs for
    -- NES PPU memory mapping
    type ppu_mmap_bus_in_t is record
        chr_bus : chr_bus_t;
        
        data_from_ppu   : data_t;
        data_from_ciram : data_t;
    end record;
    
    -- The complete set of bus outputs for
    -- NES PPU memory mapping
    type ppu_mmap_bus_out_t is record
        ciram_bus : ciram_bus_t;
        
        data_to_ppu   : data_t;
        data_to_ciram : data_t;
    end record;
    
    constant PPU_MMAP_BUS_IDLE : ppu_mmap_bus_out_t :=
    (
        ciram_bus => CIRAM_BUS_IDLE,
        
        data_to_ppu => (others => '-'),
        data_to_ciram => (others => '-')
    );
    
    function mmap_ppu_memory
    (
        bus_in : ppu_mmap_bus_in_t;
        cart   : cart_ppu_out_t
    )
    return ppu_mmap_bus_out_t;

    -- The CPU side of the cartridge connector for an access on the CPU bus
    function get_cart_cpu_in
    (
        cpu_bus : cpu_bus_t;
        data    : data_t
    )
    return cart_cpu_in_t;

    function get_ram_addr(addr : cpu_addr_t) return ram_addr_t;
    
    function get_ppu_addr(addr : cpu_addr_t) return ppu_addr_t;
    
    function get_apu_addr(addr : cpu_addr_t) return apu_addr_t;

    function get_joy_addr(addr : cpu_addr_t) return joy_addr_t;

end package lib_nes_mmap;


package body lib_nes_mmap is

    -- A DMA read also reads the register mirrored at its address when the
    -- registers are enabled. The register's bits replace those of the value
    -- read from the DMA address
    function cycle_dma_reg_conflict
    (
        map_in  : cpu_mmap_in_t;
        bus_out : cpu_mmap_bus_out_t
    )
    return cpu_mmap_bus_out_t
    is
        variable ret : cpu_mmap_bus_out_t;
    begin
        ret := bus_out;

        case map_in.bus_in.cpu_bus.address(4 downto 0) is
            -- 0x4015 is internal to the CPU, so the DMA reads its value but
            -- it does not drive the external data bus. Bit 5 is not driven
            -- so it comes from the value read from the DMA address
            when "10101" =>
                ret.apu_bus.address :=
                    get_apu_addr(map_in.bus_in.cpu_bus.address);
                ret.apu_bus.read := map_in.bus_in.cpu_bus.read;

                ret.data_to_cpu := map_in.bus_in.data_from_apu;
                ret.data_to_cpu(5) := bus_out.data_to_cpu(5);
            -- The joypads drive bits 0-4, unless the DMA is reading internal
            -- RAM, which wins the bus conflict
            when "10110" | "10111" =>
                ret.joy_bus.address :=
                    get_joy_addr(map_in.bus_in.cpu_bus.address);
                ret.joy_bus.read := map_in.bus_in.cpu_bus.read;

                if map_in.bus_in.cpu_bus.address(15 downto 13) /= "000"
                then
                    ret.data_to_cpu(4 downto 0) :=
                        map_in.bus_in.data_from_joy(4 downto 0);
                end if;
            when others =>
                null;
        end case;

        return ret;
    end;
    
    function mmap_cpu_memory(map_in : cpu_mmap_in_t) return cpu_mmap_out_t
    is
        variable map_out : cpu_mmap_out_t;
        variable address : natural range 0 to 16#FFFF#;
        variable v_regs_enabled : boolean;
        variable v_reg_range    : boolean;
        variable v_reg_conflict : boolean;
        -- Value on the external data bus
        variable v_ext_data     : data_t;
    begin
        map_out.reg := map_in.reg;
        map_out.bus_out := CPU_MMAP_BUS_IDLE;
        v_reg_conflict := false;
        v_ext_data := (others => '-');
        
        -- The APU and joypad registers are selected by the low 5 bits of the
        -- bus address and enabled by the CPU's own address bus, which still
        -- holds the address of its halted read during a DMA
        v_regs_enabled := not map_in.bus_in.dma_cycle or
                          map_in.bus_in.apu_regs_active;

        if is_bus_active(map_in.bus_in.cpu_bus)
        then
            address := to_integer(map_in.bus_in.cpu_bus.address);
            v_reg_range := address >= 16#4000# and address <= 16#401F#;
            if v_reg_range and not v_regs_enabled
            then
                -- Nothing else responds to these addresses, so they read
                -- open bus like the unused registers at 0x4018-0x401F
                address := 16#4018#;
            end if;

            case address is
                -- RAM
                when 16#0000# to 16#1FFF# =>
                    map_out.bus_out.ram_bus.address :=
                        get_ram_addr(map_in.bus_in.cpu_bus.address);
                    map_out.bus_out.ram_bus.read := map_in.bus_in.cpu_bus.read;
                    map_out.bus_out.ram_bus.write := map_in.bus_in.cpu_bus.write;
                    
                    map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_ram;
                    map_out.bus_out.data_to_ram := map_in.bus_in.data_from_cpu;
                -- PPU
                when 16#2000# to 16#3FFF# =>
                    map_out.bus_out.ppu_bus.address :=
                        get_ppu_addr(map_in.bus_in.cpu_bus.address);
                    map_out.bus_out.ppu_bus.read := map_in.bus_in.cpu_bus.read;
                    map_out.bus_out.ppu_bus.write := map_in.bus_in.cpu_bus.write;
                    
                    map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_ppu;
                    map_out.bus_out.data_to_ppu := map_in.bus_in.data_from_cpu;
                -- APU
                when 16#4000# to 16#4013# =>
                    map_out.bus_out.apu_bus.address :=
                        get_apu_addr(map_in.bus_in.cpu_bus.address);
                    map_out.bus_out.apu_bus.read := map_in.bus_in.cpu_bus.read;
                    map_out.bus_out.apu_bus.write := map_in.bus_in.cpu_bus.write;
                    
                    -- Write-only registers
                    map_out.bus_out.data_to_cpu := map_in.reg.open_bus;
                    map_out.bus_out.data_to_apu := map_in.bus_in.data_from_cpu;
                when 16#4015# =>
                    map_out.bus_out.apu_bus.address :=
                        get_apu_addr(map_in.bus_in.cpu_bus.address);
                    map_out.bus_out.apu_bus.read := map_in.bus_in.cpu_bus.read;
                    map_out.bus_out.apu_bus.write := map_in.bus_in.cpu_bus.write;
                    
                    -- Bit 5 is not driven, so it holds the value of the
                    -- CPU's internal data bus
                    map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_apu;
                    map_out.bus_out.data_to_cpu(5) := map_in.reg.internal_bus(5);
                    map_out.bus_out.data_to_apu := map_in.bus_in.data_from_cpu;
                when 16#4014# =>
                    if is_bus_write(map_in.bus_in.cpu_bus)
                    then
                        map_out.bus_out.oam_dma_write := true;
                        -- HACK since DMA and CPU data busses are shared
                        map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_cpu;
                    else
                        -- Write-only register
                        map_out.bus_out.data_to_cpu := map_in.reg.open_bus;
                    end if;
                when 16#4016# =>
                    map_out.bus_out.joy_bus.address :=
                        get_joy_addr(map_in.bus_in.cpu_bus.address);
                    map_out.bus_out.joy_bus.read := map_in.bus_in.cpu_bus.read;
                    map_out.bus_out.joy_bus.write := map_in.bus_in.cpu_bus.write;

                    map_out.bus_out.data_to_cpu :=
                        map_in.reg.open_bus(7 downto 5) &
                        map_in.bus_in.data_from_joy(4 downto 0);
                    map_out.bus_out.data_to_joy := map_in.bus_in.data_from_cpu;
                when 16#4017# =>
                    if is_bus_read(map_in.bus_in.cpu_bus)
                    then
                        map_out.bus_out.joy_bus.address :=
                            get_joy_addr(map_in.bus_in.cpu_bus.address);
                        map_out.bus_out.joy_bus.read := map_in.bus_in.cpu_bus.read;
                        map_out.bus_out.joy_bus.write := map_in.bus_in.cpu_bus.write;

                        map_out.bus_out.data_to_cpu :=
                            map_in.reg.open_bus(7 downto 5) &
                            map_in.bus_in.data_from_joy(4 downto 0);
                        map_out.bus_out.data_to_joy := map_in.bus_in.data_from_cpu;
                    elsif is_bus_write(map_in.bus_in.cpu_bus)
                    then
                        map_out.bus_out.apu_bus.address :=
                            get_apu_addr(map_in.bus_in.cpu_bus.address);
                        map_out.bus_out.apu_bus.read := map_in.bus_in.cpu_bus.read;
                        map_out.bus_out.apu_bus.write := map_in.bus_in.cpu_bus.write;
                        
                        map_out.bus_out.data_to_cpu := map_in.bus_in.data_from_apu;
                        map_out.bus_out.data_to_apu := map_in.bus_in.data_from_cpu;
                    end if;
                -- CPU test mode registers
                when 16#4018# to 16#401F# =>
                    map_out.bus_out.data_to_cpu := map_in.reg.open_bus;
                -- Cartridge
                when others =>
                    if map_in.cart.data_oe
                    then
                        map_out.bus_out.data_to_cpu := map_in.cart.data;
                    else
                        map_out.bus_out.data_to_cpu := map_in.reg.open_bus;
                    end if;
            end case;

            v_ext_data := map_out.bus_out.data_to_cpu;

            -- A DMA read outside of 0x4000-0x401F while the registers are
            -- enabled also reads the register mirrored at its address
            v_reg_conflict := map_in.bus_in.dma_cycle and
                              map_in.bus_in.apu_regs_active and
                              is_bus_read(map_in.bus_in.cpu_bus) and
                              not v_reg_range;
            if v_reg_conflict
            then
                map_out.bus_out := cycle_dma_reg_conflict(map_in, map_out.bus_out);
            end if;
        end if;
        
        if map_in.bus_in.clk_sync
        then
            if not map_in.bus_in.dma_cycle
            then
                if is_bus_write(map_in.bus_in.cpu_bus)
                then
                    map_out.reg.internal_bus := map_in.bus_in.data_from_cpu;
                elsif is_bus_read(map_in.bus_in.cpu_bus)
                then
                    map_out.reg.internal_bus := map_out.bus_out.data_to_cpu;
                end if;
            end if;

            if is_bus_write(map_in.bus_in.cpu_bus)
            then
                map_out.reg.open_bus := map_in.bus_in.data_from_cpu;
            -- 0x4015 is internal to the CPU, so it does not drive the
            -- external data bus
            elsif v_reg_conflict and
                  map_in.bus_in.cpu_bus.address(4 downto 0) = "10101"
            then
                map_out.reg.open_bus := v_ext_data;
            elsif is_bus_read(map_in.bus_in.cpu_bus) and
                  address /= 16#4015#
            then
                map_out.reg.open_bus := map_out.bus_out.data_to_cpu;
            end if;
        end if;

        return map_out;
    end;
    
    function mmap_ppu_memory
    (
        bus_in : ppu_mmap_bus_in_t;
        cart   : cart_ppu_out_t
    )
    return ppu_mmap_bus_out_t
    is
        variable ret : ppu_mmap_bus_out_t;
    begin
        ret := PPU_MMAP_BUS_IDLE;

        if cart.ciram_ce
        then
            ret.ciram_bus.address :=
                cart.ciram_a11 &
                cart.ciram_a10 &
                bus_in.chr_bus.address(9 downto 0);
            ret.ciram_bus.read := bus_in.chr_bus.read;
            ret.ciram_bus.write := bus_in.chr_bus.write;

            ret.data_to_ppu := bus_in.data_from_ciram;
            ret.data_to_ciram := bus_in.data_from_ppu;
        elsif cart.data_oe
        then
            ret.data_to_ppu := cart.data;
        end if;
        
        return ret;
    end;

    function get_cart_cpu_in
    (
        cpu_bus : cpu_bus_t;
        data    : data_t
    )
    return cart_cpu_in_t
    is
        variable ret : cart_cpu_in_t;
    begin
        ret.prg_bus.address := cpu_bus.address(prg_addr_t'range);
        ret.prg_bus.read := cpu_bus.read;
        ret.prg_bus.write := cpu_bus.write;
        -- M2 is high for all of an access here, so /ROMSEL is just A15
        ret.romsel := is_bus_active(cpu_bus) and cpu_bus.address(15) = '1';
        ret.data := data;

        return ret;
    end;

    function get_ram_addr(addr : cpu_addr_t) return ram_addr_t
    is
    begin
        return addr(ram_addr_t'RANGE);
    end;
    
    function get_ppu_addr(addr : cpu_addr_t) return ppu_addr_t
    is
    begin
        return addr(ppu_addr_t'RANGE);
    end;
    
    function get_apu_addr(addr : cpu_addr_t) return apu_addr_t
    is
    begin
        return addr(apu_addr_t'RANGE);
    end;

    function get_joy_addr(addr : cpu_addr_t) return joy_addr_t
    is
    begin
        return addr(joy_addr_t'RANGE);
    end;

end package body;
