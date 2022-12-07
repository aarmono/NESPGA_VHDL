library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package perhipheral_types is

    subtype wm_audio_t is std_logic_vector(15 downto 0);

    type memory_type_t is
    (
        MEMORY_ALTERA,
        MEMORY_REGISTER
    );

end perhipheral_types;

package body perhipheral_types is

end package body;