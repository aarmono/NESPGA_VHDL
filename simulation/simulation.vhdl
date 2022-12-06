library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.apu_bus_types.all;
use work.file_bus_types.all;
use work.nes_types.all;
use work.nes_audio_mixer.all;

package simulation is

    component apu_bus_record is
    generic
    (
        FILEPATH : string
    );
    port
    (
        apu_bus     : in apu_bus_t;
        apu_data_in : in data_t
    );
    end component apu_bus_record;
    
    component apu_bus_playback is
    generic
    (
        FILEPATH : string
    );
    port
    (
        apu_bus      : out apu_bus_t;
        apu_data_out : out data_t;
        done         : out boolean
    );
    end component apu_bus_playback;
    
    component apu_audio_record is
    generic
    (
        FILEPATH : string
    );
    port
    (
        clk    : in std_logic;
        clk_en : in boolean;
        audio  : in mixed_audio_t;
        ready  : in boolean;
        done   : in boolean
    );
    end component apu_audio_record;

    component ppu_video_record is
    generic
    (
        FILE_PREFIX : string
    );
    port
    (
        clk       : in std_logic;
        clk_en    : in boolean;
        pixel_bus : in pixel_bus_t;
        ready     : in boolean;
        done      : in boolean
    );
    end component ppu_video_record;

    component fm2_joystick is
    generic
    (
        FILEPATH     : string;
        INPUT_OFFSET : integer := 0
    );
    port
    (
        frame_valid : in boolean;

        joy_strobe : in std_logic;

        shift_joy_1 : in std_logic;
        joy_1_val   : out std_logic;

        shift_joy_2 : in std_logic;
        joy_2_val   : out std_logic
    );
    end component fm2_joystick;
    
    component file_memory is
    generic
    (
        FILEPATH    : string;
        MEM_BYTES   : integer := 131072;
        READ_DELAY  : time := 0 ns;
        WRITE_DELAY : time := 0 ns
    );
    port
    (
        file_bus_1       : in file_bus_t;
        data_to_file_1   : in data_t := (others => '-');
        data_from_file_1 : out data_t;
        
        file_bus_2       : in file_bus_t := FILE_BUS_IDLE;
        data_to_file_2   : in data_t := (others => '-');
        data_from_file_2 : out data_t
    );
    end component file_memory;
    
    component clock is
    generic
    (
        PERIOD : time;
        OFFSET : time := 0 ns;
        DUTY   : real range 0.0 to 1.0 := 0.5
    );
    port
    (
        done  : in boolean;
        clk   : out std_logic;
        reset : out boolean
    );
    end component clock;

    component sram IS
    generic
    (
        -- if TRUE, RAM is initialized with zeroes at start of simulation
        -- Clearing of RAM is carried out before download takes place
        clear_on_power_up: boolean := FALSE;
        -- if TRUE, RAM is downloaded at start of simulation
        download_on_power_up: boolean := TRUE;
        -- Echoes the data downloaded to the RAM on the screen
        -- (included for debugging purposes)
        trace_ram_load: boolean := TRUE;
        -- Read-/write access controlled by nWE only
        -- nOE may be kept active all the time
        enable_nWE_only_control: boolean := TRUE;

        -- Configuring RAM size
        size:      INTEGER :=  8;  -- number of memory words
        adr_width: INTEGER :=  3;  -- number of address bits
        width:     INTEGER :=  8;  -- number of bits per memory word

        -- READ-cycle timing parameters
        tAA_max:    TIME := 10 NS; -- Address Access Time
        tOHA_min:   TIME :=  2 NS; -- Output Hold Time
        tACE_max:   TIME := 10 NS; -- nCE/CE2 Access Time
        tDOE_max:   TIME :=  5 NS; -- nOE Access Time
        tLZOE_min:  TIME :=  0 NS; -- nOE to Low-Z Output
        tHZOE_max:  TIME :=  8 NS; --  OE to High-Z Output
        tLZCE_min:  TIME :=  3 NS; -- nCE/CE2 to Low-Z Output
        tHZCE_max:  TIME :=  4 NS; --  CE/nCE2 to High Z Output

        -- WRITE-cycle timing parameters
        tWC_min:    TIME := 10 NS; -- Write Cycle Time
        tSCE_min:   TIME :=  8 NS; -- nCE/CE2 to Write End
        tAW_min:    TIME :=  8 NS; -- tAW Address Set-up Time to Write End
        tHA_min:    TIME :=  0 NS; -- tHA Address Hold from Write End
        tSA_min:    TIME :=  0 NS; -- Address Set-up Time
        tPWE_min:   TIME :=  8 NS; -- nWE Pulse Width
        tSD_min:    TIME :=  6 NS; -- Data Set-up to Write End
        tHD_min:    TIME :=  0 NS; -- Data Hold from Write End
        tHZWE_max:  TIME :=  5 NS; -- nWE Low to High-Z Output
        tLZWE_min:  TIME :=  2 NS  -- nWE High to Low-Z Output
    );
    port
    (
        -- low-active Chip-Enable of the SRAM device; defaults to '1' (inactive)
        nCE: IN std_logic := '1';
        -- low-active Output-Enable of the SRAM device; defaults to '1' (inactive)
        nOE: IN std_logic := '1';
        -- low-active Write-Enable of the SRAM device; defaults to '1' (inactive)
        nWE: IN std_logic := '1';

        -- address bus of the SRAM device
        A:   IN std_logic_vector(adr_width-1 downto 0);
        -- bidirectional data bus to/from the SRAM device
        D:   INOUT std_logic_vector(width-1 downto 0);

        -- high-active Chip-Enable of the SRAM device; defaults to '1'  (active)
        CE2: IN std_logic := '1';

        -- A FALSE-to-TRUE transition on this signal downloads the data
        -- in file specified by download_filename to the RAM
        download: IN boolean := FALSE;

        -- name of the download source file
        --            Passing the filename via a port of type
        -- ********** string may cause a problem with some
        -- WATCH OUT! simulators. The string signal assigned
        -- ********** to the port at least should have the
        --            same length as the default value.
        download_filename: IN string := "sram_load.dat";

        -- A FALSE-to-TRUE transition on this signal dumps
        -- the current content of the memory to the file
        -- specified by dump_filename.
        dump: IN boolean := FALSE;
        -- Written to the dump-file are the memory words from memory address 
        dump_start: IN natural := 0;
        -- dump_start to address dump_end (default: all addresses)
        dump_end: IN natural := size-1;

        -- name of the dump destination file
        -- (See note at port  download_filename)
        dump_filename: IN string := "sram_dump.dat"
    );
    end component sram;

end simulation;

package body simulation is

end package body;