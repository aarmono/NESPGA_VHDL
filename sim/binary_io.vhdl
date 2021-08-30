library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;

package binary_io is
    type byte_file_t is file of character;
    subtype byte is std_logic_vector(7 downto 0);
    
    procedure byte_fopen
    (
        file byte_file : byte_file_t;
        filename : string;
        open_kind : file_open_kind := read_mode
    );
    
    procedure byte_fclose(file file_in : byte_file_t);
    procedure byte_fwrite(file file_in : byte_file_t; val : byte);
    impure function  byte_fread(file file_in : byte_file_t) return byte;
    impure function  byte_feof(file file_in : byte_file_t) return boolean;
    
end binary_io;

package body binary_io is

    procedure byte_fopen
    (
        file byte_file : byte_file_t;
        filename : string;
        open_kind : file_open_kind := read_mode
    )
    is
        variable stat : file_open_status;
    begin
        file_open(stat, byte_file, filename, open_kind);
    end;
    
    procedure byte_fclose(file file_in : byte_file_t)
    is
    begin
        file_close(file_in);
    end;
    
    procedure byte_fwrite(file file_in : byte_file_t; val : byte)
    is
        variable char : character;
    begin
        char := character'val(to_integer(val));
        write(file_in, char);
    end;
    
    impure function byte_fread(file file_in : byte_file_t) return byte
    is
        variable ret : byte;
        variable val : character;
    begin
        assert not endfile(file_in) report "Attempt to read past end of file";
        read(file_in, val);
        ret := to_std_logic_vector(val);
        
        return ret;
    end;
    
    impure function byte_feof(file file_in : byte_file_t) return boolean
    is
    begin
        return endfile(file_in);
    end;

end package body;