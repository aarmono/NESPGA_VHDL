library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.utilities.all;
use work.de1_types.all;

entity ppu_video_ram_mux is
port
(
    clk_50mhz : in std_logic;
    reset     : in boolean;

    sram_dq   : inout std_logic_vector(15 downto 0);
    sram_addr : out std_logic_vector(17 downto 0);
    sram_lb_n : out std_logic;
    sram_ub_n : out std_logic;
    sram_oe_n : out std_logic;
    sram_we_n : out std_logic;

    ppu_clk_en  : in boolean;
    pixel_bus   : in pixel_bus_t;

    data_to_vga    : out std_logic_vector(15 downto 0);
    vga_sram_addr  : in std_logic_vector(17 downto 0);
    vga_sram_oe_n  : in std_logic;

    vga_line_valid : in boolean
);
end ppu_video_ram_mux;

architecture behavioral of ppu_video_ram_mux
is
    subtype sram_data_t is std_logic_vector(sram_dq'range);

    type ppu_pixel_buf_t is array(0 to 255) of pixel_t;
    signal ppu_pixel_buf : ppu_pixel_buf_t;

    constant MAX_ROW : unsigned(7 downto 0) := to_unsigned(239, 8);

    type palette_t is array(0 to 63) of sram_data_t;
    constant PALETTE : palette_t :=
    (
        x"0666",
        x"0028",
        x"0119",
        x"0309",
        x"0507",
        x"0603",
        x"0600",
        x"0510",
        x"0330",
        x"0040",
        x"0040",
        x"0040",
        x"0034",
        x"0000",
        x"0000",
        x"0000",
        x"0AAA",
        x"015C",
        x"033F",
        x"062E",
        x"091C",
        x"0A17",
        x"0A21",
        x"0940",
        x"0660",
        x"0370",
        x"0080",
        x"0082",
        x"0078",
        x"0000",
        x"0000",
        x"0000",
        x"0FEF",
        x"05AF",
        x"088F",
        x"0B6F",
        x"0E6F",
        x"0E6C",
        x"0E76",
        x"0D92",
        x"0BB0",
        x"08C0",
        x"05D2",
        x"04D7",
        x"04CD",
        x"0444",
        x"0000",
        x"0000",
        x"0FEF",
        x"0BDF",
        x"0CCF",
        x"0DBF",
        x"0EBF",
        x"0EBD",
        x"0ECB",
        x"0EC9",
        x"0DD8",
        x"0CE8",
        x"0BEA",
        x"0AEC",
        x"0ADE",
        x"0AAA",
        x"0000",
        x"0000"
    );

    type reg_t is record
        ppu_pixel_addr : pixel_addr_t;

        sram_we_n : std_logic;
        sram_data : std_logic_vector(sram_dq'range);
        sram_addr : std_logic_vector(sram_addr'range);

        buffer_empty : boolean;
        buffer_initialized : boolean;
    end record;

    constant RESET_REG : reg_t :=
    (
        ppu_pixel_addr => (others => '0'),
        sram_we_n => '1',
        sram_data => (others => '0'),
        sram_addr => (others => '0'),
        buffer_empty => true,
        buffer_initialized => false
    );

    signal reg : reg_t := RESET_REG;

begin

    sram_lb_n <= '0';
    sram_ub_n <= '0';

    process(clk_50mhz)
        alias pixel_row : unsigned(7 downto 0) is reg.ppu_pixel_addr(15 downto 8);
        alias pixel_col : unsigned(7 downto 0) is reg.ppu_pixel_addr(7 downto 0);

        variable v_pixel : pixel_t;
    begin
    if rising_edge(clk_50mhz)
    then
        if reset
        then
            reg <= RESET_REG;
        elsif not reg.buffer_initialized
        then
            ppu_pixel_buf(to_integer(pixel_col)) <= (others => '0');
            if is_max_val(pixel_col)
            then
                reg.buffer_initialized <= true;
            end if;

            pixel_col <= pixel_col + "1";
        elsif pixel_bus.line_valid
        then
            reg.sram_we_n <= '1';
            if ppu_clk_en
            then
                ppu_pixel_buf(to_integer(pixel_col)) <= pixel_bus.pixel;
                pixel_col <= pixel_col + "1";

                reg.buffer_empty <= false;
            end if;
        elsif not vga_line_valid and not reg.buffer_empty
        then
            reg.sram_addr <= std_logic_vector(resize(reg.ppu_pixel_addr,
                                                     sram_addr'length));
            v_pixel := ppu_pixel_buf(to_integer(pixel_col));
            reg.sram_data <= PALETTE(to_integer(v_pixel));
            reg.sram_we_n <= '0';

            if is_max_val(pixel_col)
            then
                reg.buffer_empty <= true;
                if pixel_row = MAX_ROW
                then
                    reg.ppu_pixel_addr <= (others => '0');
                else
                    reg.ppu_pixel_addr <= reg.ppu_pixel_addr + "1";
                end if;
            else
                pixel_col <= pixel_col + "1";
            end if;
        else
            reg.sram_we_n <= '1';
        end if;
    end if;
    end process;

    process(all)
    begin
        if reg.sram_we_n = '1'
        then
            sram_addr <= vga_sram_addr;
            sram_oe_n <= vga_sram_oe_n;
            sram_we_n <= '1';
            sram_dq <= (others => 'Z');
            data_to_vga <= sram_dq;
        else
            sram_addr <= reg.sram_addr;
            sram_oe_n <= '1';
            sram_we_n <= reg.sram_we_n;
            sram_dq <= reg.sram_data;

            data_to_vga <= x"0F00";
        end if;
    end process;

end behavioral;