library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.apu_bus_types.all;
use work.ram_bus_types.all;
use work.chr_bus_types.all;
use work.ciram_bus_types.all;
use work.oam_bus_types.all;
use work.sec_oam_bus_types.all;
use work.prg_bus_types.all;
use work.palette_bus_types.all;
use work.nes_types.all;
use work.nes_audio_mixer.all;
use work.utilities.all;
use work.perhipheral_types.all;
use work.cart_connector_types.all;
use work.lib_nes_mmap.all;

package lib_nes is

    type state_t is
    (
        -- Waits for the power up data, and for the cartridge to load the
        -- header of the ROM file. The cartridge fills its RAMs on the same
        -- CPU cycles as the console, from the same power up data
        STATE_POWER_UP,
        -- The console's RAMs are filled
        STATE_RESET,
        -- The console's RAMs are ready, and the cartridge's are still being
        -- filled
        STATE_WAIT_CART,
        -- The RAMs are ready, and the NES waits in reset for the board to
        -- start it (nes_in_t.run)
        STATE_WAIT,
        STATE_RUN,
        -- The reset button is held. The NES runs as in STATE_RUN, with the
        -- CPU, APU and PPU held in reset. Like the other reset states, the
        -- state only changes on CPU cycles, so they all leave reset on the
        -- same clock
        STATE_SOFT_RESET
    );
    
    -- Clocked off the CPU timer
    type reg_t is record
        mmap_reg    : cpu_mmap_reg_t;
        cur_cycle   : unsigned(cpu_addr_t'RANGE);
        cur_state   : state_t;
    end record;

    constant RESET_REG : reg_t :=
    (
        mmap_reg => RESET_CPU_MMAP_REG,
        cur_cycle => x"0000",
        cur_state => STATE_POWER_UP
    );

    constant STARTUP_PALETTE : palette_t :=
    (
        resize(x"09", pixel_t'length),
        resize(x"01", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"01", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"02", pixel_t'length),
        resize(x"02", pixel_t'length),
        resize(x"0D", pixel_t'length),
        resize(x"08", pixel_t'length),
        resize(x"10", pixel_t'length),
        resize(x"08", pixel_t'length),
        resize(x"24", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"04", pixel_t'length),
        resize(x"2C", pixel_t'length),
        resize(x"09", pixel_t'length),
        resize(x"01", pixel_t'length),
        resize(x"34", pixel_t'length),
        resize(x"03", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"04", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"14", pixel_t'length),
        resize(x"08", pixel_t'length),
        resize(x"3A", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"02", pixel_t'length),
        resize(x"00", pixel_t'length),
        resize(x"20", pixel_t'length),
        resize(x"2C", pixel_t'length),
        resize(x"08", pixel_t'length)
    );
    
    type nes_out_t is record
        reg                  : reg_t;
        cpu_bus              : cpu_mmap_bus_out_t;
        ppu_bus              : ppu_mmap_bus_out_t;
        oam_bus             : oam_bus_t;
        data_to_oam          : data_t;
        sec_oam_bus          : sec_oam_bus_t;
        data_to_sec_oam      : data_t;
        palette_bus          : palette_bus_t;
        data_to_palette      : pixel_t;
        audio                : mixed_audio_t;
        reset                : boolean;
        -- The reset button, for the CPU, APU and PPU
        soft_reset           : boolean;
        irq                  : boolean;
        -- The RAMs are being filled, so the power up data changes
        power_up_enable      : boolean;
    end record;
    
    type nes_in_t is record
        reg                : reg_t;
        cpu_bus            : cpu_mmap_bus_in_t;
        ppu_bus            : ppu_mmap_bus_in_t;
        -- The cartridge's side of the connector
        cart_cpu           : cart_cpu_out_t;
        cart_ppu           : cart_ppu_out_t;
        cart_audio         : cart_audio_t;
        -- See cart_system: loaded and ready
        cart_loaded        : boolean;
        cart_ready         : boolean;
        oam_bus            : oam_bus_t;
        data_to_oam        : data_t;
        sec_oam_bus        : sec_oam_bus_t;
        data_to_sec_oam    : data_t;
        palette_bus        : palette_bus_t;
        data_to_palette    : pixel_t;
        audio              : apu_out_t;
        -- The power up data is valid
        power_up_ready     : boolean;
        power_up_data      : power_up_data_t;
        -- The reset button is held
        soft_reset         : boolean;
        -- Leave reset once the RAMs are ready. Otherwise wait in STATE_WAIT
        run                : boolean;
    end record;

    function cycle_nes(nes_in : nes_in_t) return nes_out_t;

end lib_nes;

package body lib_nes is

    -- The state after the RAMs are ready
    function run_state(run : boolean) return state_t
    is
    begin
        if run
        then
            return STATE_RUN;
        else
            return STATE_WAIT;
        end if;
    end;

    -- The state once the console's RAMs are ready
    function cart_wait_state(cart_ready : boolean; run : boolean) return state_t
    is
    begin
        if cart_ready
        then
            return run_state(run);
        else
            return STATE_WAIT_CART;
        end if;
    end;

    function cycle_nes(nes_in : nes_in_t) return nes_out_t
    is
        -- These have initial values because without one ghdl fills in every
        -- element on each call, which is slow to simulate. They are constants
        -- because Quartus 13 can fail to infer registers from a variable
        -- whose initial value isn't
        variable ret : nes_out_t :=
            (reg => RESET_REG,
             cpu_bus => CPU_MMAP_BUS_IDLE,
             ppu_bus => PPU_MMAP_BUS_IDLE,
             oam_bus => OAM_BUS_IDLE,
             data_to_oam => (others => '-'),
             sec_oam_bus => SEC_OAM_BUS_IDLE,
             data_to_sec_oam => (others => '-'),
             palette_bus => PALETTE_BUS_IDLE,
             data_to_palette => (others => '-'),
             audio => (others => '-'),
             reset => false,
             soft_reset => false,
             irq => false,
             power_up_enable => false);

        variable cpu_map_out : cpu_mmap_out_t :=
            (reg => RESET_CPU_MMAP_REG,
             bus_out => CPU_MMAP_BUS_IDLE);
    begin
        ret.reg := nes_in.reg;

        case nes_in.reg.cur_state is
            when STATE_POWER_UP =>
                ret.reset := true;

                -- The power up data only changes on a clock enable once the
                -- RAMs are being filled. The cartridge starts its fill on
                -- the same CPU cycle
                if nes_in.cart_loaded and nes_in.power_up_ready
                then
                    ret.reg.cur_cycle := x"0000";
                    ret.reg.cur_state := STATE_RESET;
                end if;

            when STATE_RESET =>
                ret.reset := true;
                ret.power_up_enable := true;
                
                ret.cpu_bus.ram_bus :=
                    bus_write(nes_in.reg.cur_cycle(ram_addr_t'range));
                
                ret.oam_bus :=
                    bus_write(nes_in.reg.cur_cycle(oam_addr_t'range));
                ret.sec_oam_bus :=
                    bus_write(nes_in.reg.cur_cycle(sec_oam_addr_t'range));
                ret.palette_bus :=
                    bus_write(nes_in.reg.cur_cycle(palette_addr_t'range));
                
                ret.ppu_bus.ciram_bus :=
                    bus_write(nes_in.reg.cur_cycle(ciram_addr_t'range));
                
                -- The RAMs of the console power up with random bytes, a
                -- different part of the power up data for each
                ret.cpu_bus.data_to_ram := nes_in.power_up_data(7 downto 0);
                
                ret.data_to_oam := nes_in.power_up_data(15 downto 8);
                ret.data_to_sec_oam := nes_in.power_up_data(23 downto 16);
                ret.data_to_palette :=
                    STARTUP_PALETTE
                    (
                        to_integer(nes_in.reg.cur_cycle(palette_addr_t'range))
                    );
                
                ret.ppu_bus.data_to_ciram := nes_in.power_up_data(31 downto 24);
                
                ret.reg.mmap_reg := RESET_CPU_MMAP_REG;

                if nes_in.reg.cur_cycle = x"3FFF"
                then
                    ret.reg.cur_state :=
                        cart_wait_state(nes_in.cart_ready, nes_in.run);
                else
                    ret.reg.cur_cycle := nes_in.reg.cur_cycle + "1";
                end if;

            when STATE_WAIT_CART =>
                ret.reset := true;
                ret.reg.cur_state :=
                    cart_wait_state(nes_in.cart_ready, nes_in.run);

            when STATE_WAIT =>
                ret.reset := true;
                ret.reg.cur_state := run_state(nes_in.run);
                
            when STATE_RUN | STATE_SOFT_RESET =>
                ret.soft_reset := nes_in.reg.cur_state = STATE_SOFT_RESET;
                if nes_in.soft_reset
                then
                    ret.reg.cur_state := STATE_SOFT_RESET;
                else
                    ret.reg.cur_state := STATE_RUN;
                end if;

                ret.audio := mix_audio(nes_in.audio, nes_in.cart_audio);
                
                ret.oam_bus := nes_in.oam_bus;
                ret.data_to_oam := nes_in.data_to_oam;
                
                ret.sec_oam_bus := nes_in.sec_oam_bus;
                ret.data_to_sec_oam := nes_in.data_to_sec_oam;
                
                ret.palette_bus := nes_in.palette_bus;
                ret.data_to_palette := nes_in.data_to_palette;
                
                cpu_map_out :=
                    mmap_cpu_memory((reg => nes_in.reg.mmap_reg,
                                     bus_in => nes_in.cpu_bus,
                                     cart => nes_in.cart_cpu));
                
                ret.reg.mmap_reg := cpu_map_out.reg;
                ret.cpu_bus := cpu_map_out.bus_out;
                ret.ppu_bus := mmap_ppu_memory(nes_in.ppu_bus, nes_in.cart_ppu);

                ret.irq := nes_in.cart_cpu.irq;
        end case;
        
        return ret;
    end;

end package body;
