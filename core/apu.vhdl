library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;
use work.lib_apu.all;
use work.apu_bus_types.all;
use work.utilities.all;

entity apu is
port
(
    clk          : in  std_logic;
    reset        : in  boolean;
    
    cpu_bus      : in  apu_bus_t;
    cpu_data_in  : in  data_t;
    cpu_data_out : out data_t;
    
    audio        : out apu_out_t;
    irq          : out boolean
);
end apu;

architecture behavioral of apu is
    
    type reg_t is record
        frame_seq : frame_seq_t;
        square_1  : square_t;
        square_2  : square_t;
        triangle  : triangle_t;
        noise     : noise_t;
        irq       : boolean;
    end record;
    
    signal reg, reg_in : reg_t;
    
begin
    
    process(reset, cpu_bus, cpu_data_in, reg)
        variable v_audio           : apu_out_t;
        variable v_update_envelope : boolean;
        variable v_update_length   : boolean;
        variable v_reg             : reg_t;
        variable v_cpu_data_out    : data_t;
    begin
        
        v_cpu_data_out   := (others => '-');
        v_reg            := reg;
        v_audio.square_1 := work.lib_apu.audio(reg.square_1, "0");
        v_audio.square_2 := work.lib_apu.audio(reg.square_2, "1");
        v_audio.triangle := work.lib_apu.audio(reg.triangle);
        v_audio.noise    := work.lib_apu.audio(reg.noise);
        
        if work.lib_apu.irq(reg.frame_seq)
        then
            v_reg.irq := true;
        end if;
        
        v_update_envelope := update_envelope(reg.frame_seq);
        v_update_length := update_length(reg.frame_seq);
        
        v_reg.triangle := next_triangle(reg.triangle,
                                        v_update_envelope,
                                        v_update_length);
        v_reg.square_1 := next_square(reg.square_1,
                                      v_update_envelope,
                                      v_update_length,
                                      "0");
        v_reg.square_2 := next_square(reg.square_2,
                                      v_update_envelope,
                                      v_update_length,
                                      "1");
        v_reg.noise := next_noise(reg.noise,
                                  v_update_envelope,
                                  v_update_length);
        v_reg.frame_seq := next_sequence(reg.frame_seq);
        
        -- Memory map {
        if is_bus_write(cpu_bus)
        then
            case cpu_bus.address is
                -- Square Channel 1
                when "00000" =>
                    v_reg.square_1 := write_reg_0(v_reg.square_1, cpu_data_in);
                when "00001" =>
                    v_reg.square_1 := write_reg_1(v_reg.square_1, cpu_data_in);
                when "00010" =>
                    v_reg.square_1 := write_reg_2(v_reg.square_1, cpu_data_in);
                when "00011" =>
                    v_reg.square_1 := write_reg_3(v_reg.square_1, cpu_data_in);

                -- Square Channel 2
                when "00100" =>
                    v_reg.square_2 := write_reg_0(v_reg.square_2, cpu_data_in);
                when "00101" =>
                    v_reg.square_2 := write_reg_1(v_reg.square_2, cpu_data_in);
                when "00110" =>
                    v_reg.square_2 := write_reg_2(v_reg.square_2, cpu_data_in);
                when "00111" =>
                    v_reg.square_2 := write_reg_3(v_reg.square_2, cpu_data_in);

                -- Triangle Channel
                -- Linear Counter registers
                when "01000" =>
                    v_reg.triangle := write_reg_0(v_reg.triangle, cpu_data_in);
                -- Timer period low
                when "01010" =>
                    v_reg.triangle := write_reg_1(v_reg.triangle, cpu_data_in);
                -- Timer period high and length counter reload
                when "01011" =>
                    v_reg.triangle := write_reg_2(v_reg.triangle, cpu_data_in);

                -- Noise Channel
                when "01100" =>
                    v_reg.noise := write_reg_0(v_reg.noise, cpu_data_in);
                when "01110" =>
                    v_reg.noise := write_reg_1(v_reg.noise, cpu_data_in);
                when "01111" =>
                    v_reg.noise := write_reg_2(v_reg.noise, cpu_data_in);
                -- DMC Channel
                when "10000" =>
                when "10001" =>
                when "10010" =>
                when "10011" =>
                -- Common
                when "10101" =>
                    v_reg.square_1 := write_reg_4(reg.square_1, cpu_data_in(0));
                    v_reg.square_2 := write_reg_4(reg.square_2, cpu_data_in(1));
                    v_reg.triangle := write_reg_3(reg.triangle, cpu_data_in(2));
                    v_reg.noise := write_reg_3(reg.noise, cpu_data_in(3));
                when "10111" =>
                    v_reg.frame_seq := write_reg(v_reg.frame_seq, 
                                                 cpu_data_in(7 downto 6));
                when others =>
            end case;
        elsif is_bus_read(cpu_bus) and
              cpu_bus.address = "10101"
        then
            v_cpu_data_out := 
            (
                6 => to_std_logic(reg.irq),
                3 => get_status(reg.noise),
                2 => get_status(reg.triangle),
                1 => get_status(reg.square_2),
                0 => get_status(reg.square_1),
                others => '0'
            );
            v_reg.irq := false;
        end if;
        -- }
        
        if reset then
            v_reg.frame_seq := RESET_FRAME_SEQ;
            v_reg.square_1 := RESET_SQUARE;
            v_reg.square_2 := RESET_SQUARE;
            v_reg.triangle := RESET_TRIANGLE;
            v_reg.noise := RESET_NOISE;
            v_reg.irq := false;
        end if;
        
        reg_in <= v_reg;
        audio <= v_audio;
        cpu_data_out <= v_cpu_data_out;
        irq <= reg.irq;
        
    end process;
    
    process(clk)
    begin
    if rising_edge(clk)
    then
        reg <= reg_in;
    end if;
    end process;

end behavioral;