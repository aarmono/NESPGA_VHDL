library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package perhipheral_types is

    subtype wm_audio_t is std_logic_vector(15 downto 0);

    type vendor_t is
    (
        VENDOR_ALTERA
    );
    
    type memory_type_t is
    (
        MEMORY_INFERRED,
        MEMORY_MEMORY,
        MEMORY_REGISTER
    );
    
    function ramtype_attr_str
    (
        vendor      : vendor_t;
        mem_type    : memory_type_t;
        default_val : string
    )
    return string;

end perhipheral_types;

package body perhipheral_types is

    function ramtype_attr_str
    (
        vendor      : vendor_t;
        mem_type    : memory_type_t;
        default_val : string
    )
    return string
    is
    begin
        case vendor is
            when VENDOR_ALTERA =>
                case mem_type is
                    when MEMORY_REGISTER =>
                        return "logic";
                    when others =>
                        return default_val;
                end case;
        end case;
    end;

end package body;