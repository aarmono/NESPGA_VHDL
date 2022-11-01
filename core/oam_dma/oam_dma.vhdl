library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_bus_types.all;
use work.nes_types.all;
use work.utilities.all;

entity oam_dma is
port
(
    clk            : in std_logic;
    clk_en         : in boolean := true;
    reset          : in boolean;
    
    write_from_cpu : in boolean;
    data_to_dma    : in data_t;
    
    dma_bus         : out cpu_bus_t;
    data_from_dma   : out data_t;
    
    ready           : out boolean
);
end entity;

architecture behavioral of oam_dma
is

    type state_t is
    (
        IDLE,
        WAITING,
        READING,
        WRITING
    );
    
    type reg_t is record
        state   : state_t;
        address : unsigned(cpu_addr_t'range);
        data    : data_t;
    end record;
    
    constant RESET_REG : reg_t :=
    (
        state => IDLE,
        address => (others => '0'),
        data => (others => '0')
    );
    
    type dma_out_t is record
        reg           : reg_t;
        dma_bus       : cpu_bus_t;
        data_from_dma : data_t;
        ready         : boolean;
    end record;
    
    type dma_in_t is record
        reg            : reg_t;
        write_from_cpu : boolean;
        data_to_dma    : data_t;
    end record;

    function cycle_dma(dma_in : dma_in_t) return dma_out_t
    is
        -- OAMDATA
        constant WRITE_ADDR : cpu_addr_t := x"2004";
        variable dma_out : dma_out_t;
    begin
        dma_out.reg := dma_in.reg;
        dma_out.dma_bus := CPU_BUS_IDLE;
        dma_out.data_from_dma := (others => '-');
        
        case dma_in.reg.state is
            when IDLE =>
                dma_out.ready := true;
                
                if dma_in.write_from_cpu
                then
                    dma_out.reg.state := WAITING;
                    dma_out.reg.address := unsigned(dma_in.data_to_dma) & x"00";
                end if;
            when WAITING =>
                dma_out.ready := false;
                
                dma_out.reg.state := READING;
            when READING =>
                dma_out.ready := false;
                
                dma_out.dma_bus := bus_read(dma_in.reg.address);
                dma_out.reg.data := dma_in.data_to_dma;
                
                dma_out.reg.state := WRITING;
            when WRITING =>
                dma_out.ready := false;
                
                dma_out.dma_bus := bus_write(WRITE_ADDR);
                dma_out.data_from_dma := dma_in.reg.data;
                
                if dma_in.reg.address(7 downto 0) = x"FF"
                then
                    dma_out.reg.state := IDLE;
                else
                    dma_out.reg.state := READING;
                end if;
                
                dma_out.reg.address := dma_in.reg.address + "1";
        end case;
        
        return dma_out;
    end;
    
    signal reg : reg_t := RESET_REG;
    signal reg_next : reg_t;

begin


    process(all)
    is
        variable dma_in : dma_in_t;
        variable dma_out : dma_out_t;
    begin
        dma_in.reg := reg;
        dma_in.write_from_cpu := write_from_cpu;
        dma_in.data_to_dma := data_to_dma;
        
        dma_out := cycle_dma(dma_in);
        
        reg_next <= dma_out.reg;
        dma_bus <= dma_out.dma_bus;
        data_from_dma <= dma_out.data_from_dma;
        ready <= dma_out.ready;
    end process;
    
    process(clk)
    is
    begin
    if rising_edge(clk) and clk_en
    then
        if reset
        then
            reg <= RESET_REG;
        else
            reg <= reg_next;
        end if;
    end if;
    end process;

end behavioral;
