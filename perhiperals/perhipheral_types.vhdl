library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package perhipheral_types is

    subtype wm_audio_t is std_logic_vector(15 downto 0);

    type vendor_t is
    (
        VENDOR_ALTERA
    );

end perhipheral_types;

package body perhipheral_types is

end package body;