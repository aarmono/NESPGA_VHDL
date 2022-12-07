library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.de1_types.all;
use work.perhipheral_types.all;

entity ppu_video_ram_mux is
generic
(
    MEM_TYPE : memory_type_t := MEMORY_INFERRED
);
port
(
    clk_50mhz : in std_logic;
    clk_we    : in std_logic;
    reset     : in boolean;

    sram_dq   : inout std_logic_vector(15 downto 0);
    sram_addr : out std_logic_vector(17 downto 0);
    sram_lb_n : out std_logic;
    sram_ub_n : out std_logic;
    sram_oe_n : out std_logic;
    sram_we_n : out std_logic;
    sram_ce_n : out std_logic;

    ppu_clk_en  : in boolean;
    pixel_bus   : in pixel_bus_t;

    data_to_vga    : out std_logic_vector(15 downto 0);
    vga_sram_addr  : in std_logic_vector(17 downto 0);
    vga_sram_oe_n  : in std_logic;
    vga_sram_ce_n  : in std_logic
);
end ppu_video_ram_mux;

architecture behavioral of ppu_video_ram_mux
is
    subtype sram_data_t is std_logic_vector(sram_dq'range);

    subtype buffer_addr_t is unsigned(7 downto 0);
    constant BUFFER_SIZE : positive := 2 ** buffer_addr_t'length;

    type ppu_pixel_buf_t is array(0 to BUFFER_SIZE-1) of pixel_t;
    signal ppu_pixel_buf : ppu_pixel_buf_t;
    
    attribute ramstyle : string;
    attribute ramstyle of ppu_pixel_buf : signal is ramtype_attr_str(VENDOR_ALTERA,
                                                                     MEM_TYPE,
                                                                     "");

    type palette_t is array(0 to 63) of sram_data_t;
    constant PALETTE : palette_t :=
    (
        x"0666",
        x"0028",
        x"011A",
        x"030A",
        x"0507",
        x"0604",
        x"0600",
        x"0520",
        x"0330",
        x"0140",
        x"0050",
        x"0050",
        x"0045",
        x"0000",
        x"0000",
        x"0000",
        x"0AAA",
        x"016D",
        x"044F",
        x"072F",
        x"092C",
        x"0B27",
        x"0B32",
        x"0950",
        x"0660",
        x"0380",
        x"0190",
        x"0083",
        x"0078",
        x"0000",
        x"0000",
        x"0000",
        x"0FFF",
        x"06AF",
        x"098F",
        x"0C7F",
        x"0E6F",
        x"0F6C",
        x"0F87",
        x"0E92",
        x"0BB0",
        x"08D0",
        x"05D3",
        x"04D8",
        x"04CD",
        x"0555",
        x"0000",
        x"0000",
        x"0FFF",
        x"0BDF",
        x"0CCF",
        x"0ECF",
        x"0FBF",
        x"0FCE",
        x"0FCC",
        x"0FDA",
        x"0DD9",
        x"0CE9",
        x"0BEA",
        x"0BEC",
        x"0BEE",
        x"0BBB",
        x"0000",
        x"0000"
    );

    function incr_pixel_addr(pixel_addr : pixel_addr_t) return pixel_addr_t
    is
        variable ret : pixel_addr_t;
    begin
        if pixel_addr = PIXEL_ADDR_MAX
        then
            ret := (others => '0');
        else
            ret := pixel_addr + "1";
        end if;

        return ret;
    end;

    type reg_t is record
        write_pixel_addr  : pixel_addr_t;
        read_pixel_addr   : pixel_addr_t;

        sram_we_n : std_logic;
        sram_data : std_logic_vector(sram_dq'range);
        sram_addr : std_logic_vector(sram_addr'range);

        vga_sram_ce_n : std_logic_vector(1 downto 0);

        frame_overflow : boolean;
    end record;

    constant RESET_REG : reg_t :=
    (
        write_pixel_addr => (others => '0'),
        read_pixel_addr => (others => '0'),

        sram_we_n => '1',
        sram_data => (others => '0'),
        sram_addr => (others => '0'),
        
        vga_sram_ce_n => (others => '1'),
        
        frame_overflow => false
    );

    signal reg : reg_t := RESET_REG;

begin

    sram_lb_n <= '0';
    sram_ub_n <= '0';

    process(clk_50mhz)
        alias write_buffer_addr : buffer_addr_t is
            reg.write_pixel_addr(buffer_addr_t'range);
        alias read_buffer_addr : buffer_addr_t is
            reg.read_pixel_addr(buffer_addr_t'range);

        variable v_pixel : pixel_t;
        variable next_write_pixel_addr : pixel_addr_t;
        variable next_read_pixel_addr : pixel_addr_t;
    begin
    if rising_edge(clk_50mhz)
    then
        if pixel_bus.line_valid and ppu_clk_en
        then
            ppu_pixel_buf(to_integer(write_buffer_addr)) <= pixel_bus.pixel;
            
            next_write_pixel_addr := incr_pixel_addr(reg.write_pixel_addr);

            if next_write_pixel_addr(pixel_addr_t'high) = '0' and
               reg.write_pixel_addr(pixel_addr_t'high) = '1'
            then
                reg.frame_overflow <= true;
            end if;

            reg.write_pixel_addr <= next_write_pixel_addr;
        end if;

        if reg.vga_sram_ce_n(reg.vga_sram_ce_n'high) = '1' and
           ((reg.write_pixel_addr > reg.read_pixel_addr) or reg.frame_overflow)
        then
            reg.sram_addr <=
                std_logic_vector(resize(reg.read_pixel_addr, sram_addr'length));
            
            v_pixel := ppu_pixel_buf(to_integer(read_buffer_addr));
            reg.sram_data <= PALETTE(to_integer(v_pixel));
            reg.sram_we_n <= '0';

            next_read_pixel_addr := incr_pixel_addr(reg.read_pixel_addr);

            if next_read_pixel_addr(pixel_addr_t'high) = '0' and
               reg.read_pixel_addr(pixel_addr_t'high) = '1'
            then
                reg.frame_overflow <= false;
            end if;

            reg.read_pixel_addr <= next_read_pixel_addr;
        else
            reg.sram_we_n <= '1';
        end if;
        
        for i in reg.vga_sram_ce_n'high downto 1
        loop
            reg.vga_sram_ce_n(i) <= reg.vga_sram_ce_n(i-1);
        end loop;
        reg.vga_sram_ce_n(0) <= vga_sram_ce_n;
        
        if reset
        then
            reg <= RESET_REG;
        end if;
    end if;
    end process;

    process(all)
    begin
        if reg.sram_we_n = '1'
        then
            sram_addr <= vga_sram_addr;
            sram_oe_n <= vga_sram_oe_n;
            sram_ce_n <= vga_sram_ce_n;
            sram_we_n <= '1';
            sram_dq <= (others => 'Z');
            data_to_vga <= sram_dq;
        else
            sram_addr <= reg.sram_addr;
            sram_oe_n <= '1';
            -- The write enable clock is a derived
            -- clock from the main 50MHz clock shifted
            -- forward a few ns to ensure the data written
            -- to the sram is stable when the WE signal
            -- goes high
            sram_we_n <= reg.sram_we_n or clk_we;
            sram_ce_n <= reg.sram_we_n or clk_we;
            sram_dq <= reg.sram_data;

            -- Deliberately output red so that glitches
            -- are easy to spot during test
            data_to_vga <= x"0F00";
        end if;
    end process;

end behavioral;