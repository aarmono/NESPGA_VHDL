library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.nes_types.all;

-- The serial EEPROMs of the Bandai FCG boards: the 128-byte X24C01 and the
-- 256-byte X24C02, on an I2C bus whose SCL and SDA lines the mapper drives
-- from register bits. The EEPROM steps on each change of the lines: a fall
-- of SDA while SCL is high starts a transfer, a rise stops it, and the rise
-- and fall of SCL clock the bits.
--
-- The X24C02 takes a device address (1010 and the address pins, which the
-- boards ground), then a byte address to write at, or reads at its current
-- address, and shifts bits MSB first. The X24C01 responds to any start and
-- takes a 7-bit byte address and a read bit with no device address. Bandai
-- took it to shift bits LSB first, and the games do, so it is emulated that
-- way. Both follow Mesen and Nestopia, which agree, apart from the device
-- address, which they only compare in bits 7 and 5.
--
-- The contents are kept outside the EEPROM, in the chip RAM. A step that
-- loads a byte reads it at the address before the step, and one that stores
-- a byte writes the data before the step there
package lib_bandai_eeprom is

    type eeprom_chip_t is
    (
        X24C01,
        X24C02
    );

    type eeprom_mode_t is
    (
        EEPROM_IDLE,
        -- The X24C02 takes the device address
        EEPROM_DEVICE,
        EEPROM_ADDR,
        EEPROM_READ,
        EEPROM_WRITE,
        -- The EEPROM pulls SDA low for one clock, then goes to next_mode
        EEPROM_SEND_ACK,
        -- The EEPROM waits for the master to acknowledge a byte it read
        EEPROM_WAIT_ACK
    );

    subtype eeprom_count_t is natural range 0 to 8;

    type eeprom_t is record
        mode      : eeprom_mode_t;
        next_mode : eeprom_mode_t;
        device    : data_t;
        addr      : data_t;
        data      : data_t;
        -- The bits of the byte shifted so far
        count     : eeprom_count_t;
        -- SDA as the EEPROM drives it: low only to acknowledge or for a 0
        -- bit it reads out
        output    : std_logic;
        -- The lines as of the last step
        scl       : std_logic;
        sda       : std_logic;
    end record;

    constant RESET_EEPROM : eeprom_t :=
    (
        mode => EEPROM_IDLE,
        next_mode => EEPROM_IDLE,
        device => (others => '0'),
        addr => (others => '0'),
        data => (others => '0'),
        count => 0,
        output => '1',
        scl => '0',
        sda => '0'
    );

    type eeprom_step_t is record
        eeprom : eeprom_t;
        -- The step loads data from addr of the EEPROM before the step
        read   : boolean;
        -- The step stores data of the EEPROM before the step at its addr
        write  : boolean;
    end record;

    -- Steps the EEPROM on the lines scl and sda. ram_data is the byte at
    -- the address of the EEPROM before the step, used if the step reads
    function step_eeprom
    (
        eeprom   : eeprom_t;
        chip     : eeprom_chip_t;
        scl      : std_logic;
        sda      : std_logic;
        ram_data : data_t
    )
    return eeprom_step_t;

end package lib_bandai_eeprom;


package body lib_bandai_eeprom is

    -- The position in a byte of bit count, in the order the chip shifts
    function bit_pos(chip : eeprom_chip_t; count : eeprom_count_t)
    return natural
    is
    begin
        if chip = X24C02
        then
            return 7 - count;
        else
            return count;
        end if;
    end;

    function shift_in
    (
        val   : data_t;
        chip  : eeprom_chip_t;
        count : eeprom_count_t;
        sda   : std_logic
    )
    return data_t
    is
        variable ret : data_t;
    begin
        ret := val;
        ret(bit_pos(chip, count)) := sda;

        return ret;
    end;

    function next_addr(eeprom : eeprom_t; chip : eeprom_chip_t) return data_t
    is
        variable ret : unsigned(data_t'range);
    begin
        ret := unsigned(eeprom.addr) + 1;
        if chip = X24C01
        then
            ret(7) := '0';
        end if;

        return std_logic_vector(ret);
    end;

    -- SCL rises: the master puts out a bit, or reads one
    function rise
    (
        step     : eeprom_step_t;
        chip     : eeprom_chip_t;
        sda      : std_logic;
        ram_data : data_t
    )
    return eeprom_step_t
    is
        variable ret : eeprom_step_t;
        variable e : eeprom_t;
    begin
        ret := step;
        e := step.eeprom;

        case e.mode is
            when EEPROM_DEVICE =>
                if e.count < 8
                then
                    ret.eeprom.device := shift_in(e.device, chip, e.count, sda);
                    ret.eeprom.count := e.count + 1;
                end if;
            when EEPROM_ADDR =>
                if chip = X24C02
                then
                    if e.count < 8
                    then
                        ret.eeprom.addr := shift_in(e.addr, chip, e.count, sda);
                        ret.eeprom.count := e.count + 1;
                    end if;
                -- The X24C01 takes 7 address bits, then the read bit
                elsif e.count < 7
                then
                    ret.eeprom.addr := shift_in(e.addr, chip, e.count, sda);
                    ret.eeprom.count := e.count + 1;
                elsif e.count = 7
                then
                    ret.eeprom.count := 8;
                    if sda = '1'
                    then
                        ret.eeprom.next_mode := EEPROM_READ;
                        ret.eeprom.data := ram_data;
                        ret.read := true;
                    else
                        ret.eeprom.next_mode := EEPROM_WRITE;
                    end if;
                end if;
            when EEPROM_READ =>
                if e.count < 8
                then
                    ret.eeprom.output := e.data(bit_pos(chip, e.count));
                    ret.eeprom.count := e.count + 1;
                end if;
            when EEPROM_WRITE =>
                if e.count < 8
                then
                    ret.eeprom.data := shift_in(e.data, chip, e.count, sda);
                    ret.eeprom.count := e.count + 1;
                end if;
            when EEPROM_SEND_ACK =>
                ret.eeprom.output := '0';
            when EEPROM_WAIT_ACK =>
                -- The master acknowledges with SDA low. The X24C02 then reads
                -- out the next byte and the X24C01 stops
                if sda = '0'
                then
                    if chip = X24C02
                    then
                        ret.eeprom.next_mode := EEPROM_READ;
                        ret.eeprom.data := ram_data;
                        ret.read := true;
                    else
                        ret.eeprom.next_mode := EEPROM_IDLE;
                    end if;
                end if;
            when EEPROM_IDLE =>
                null;
        end case;

        return ret;
    end;

    -- SCL falls: the EEPROM acts on a whole byte and puts out its next bit
    function fall
    (
        step     : eeprom_step_t;
        chip     : eeprom_chip_t;
        ram_data : data_t
    )
    return eeprom_step_t
    is
        variable ret : eeprom_step_t;
        variable e : eeprom_t;
    begin
        ret := step;
        e := step.eeprom;

        case e.mode is
            when EEPROM_DEVICE =>
                if e.count = 8
                then
                    ret.eeprom.count := 0;
                    ret.eeprom.output := '1';
                    if e.device(7 downto 1) = "1010000"
                    then
                        ret.eeprom.mode := EEPROM_SEND_ACK;
                        -- Bit 0 set reads at the current address
                        if e.device(0) = '1'
                        then
                            ret.eeprom.next_mode := EEPROM_READ;
                            ret.eeprom.data := ram_data;
                            ret.read := true;
                        else
                            ret.eeprom.next_mode := EEPROM_ADDR;
                        end if;
                    else
                        ret.eeprom.mode := EEPROM_IDLE;
                    end if;
                end if;
            when EEPROM_ADDR =>
                if e.count = 8
                then
                    ret.eeprom.mode := EEPROM_SEND_ACK;
                    ret.eeprom.output := '1';
                    if chip = X24C02
                    then
                        ret.eeprom.count := 0;
                        ret.eeprom.next_mode := EEPROM_WRITE;
                    end if;
                end if;
            when EEPROM_READ =>
                if e.count = 8
                then
                    ret.eeprom.mode := EEPROM_WAIT_ACK;
                    ret.eeprom.addr := next_addr(e, chip);
                end if;
            when EEPROM_WRITE =>
                if e.count = 8
                then
                    ret.eeprom.mode := EEPROM_SEND_ACK;
                    ret.eeprom.addr := next_addr(e, chip);
                    ret.write := true;
                    -- The X24C02 takes the next byte at the next address,
                    -- the X24C01 one byte per transfer
                    if chip = X24C02
                    then
                        ret.eeprom.count := 0;
                        ret.eeprom.next_mode := EEPROM_WRITE;
                    else
                        ret.eeprom.next_mode := EEPROM_IDLE;
                    end if;
                end if;
            when EEPROM_SEND_ACK =>
                ret.eeprom.mode := e.next_mode;
                ret.eeprom.count := 0;
                ret.eeprom.output := '1';
            when EEPROM_WAIT_ACK =>
                -- The X24C01 waits here for a start or stop
                if chip = X24C02
                then
                    ret.eeprom.mode := e.next_mode;
                    ret.eeprom.count := 0;
                    ret.eeprom.output := '1';
                end if;
            when EEPROM_IDLE =>
                null;
        end case;

        return ret;
    end;

    function step_eeprom
    (
        eeprom   : eeprom_t;
        chip     : eeprom_chip_t;
        scl      : std_logic;
        sda      : std_logic;
        ram_data : data_t
    )
    return eeprom_step_t
    is
        variable ret : eeprom_step_t;
    begin
        ret.eeprom := eeprom;
        ret.read := false;
        ret.write := false;

        if eeprom.scl = '1' and scl = '1' and eeprom.sda /= sda
        then
            ret.eeprom.output := '1';
            -- Start
            if sda = '0'
            then
                ret.eeprom.count := 0;
                if chip = X24C02
                then
                    ret.eeprom.mode := EEPROM_DEVICE;
                else
                    ret.eeprom.mode := EEPROM_ADDR;
                    ret.eeprom.addr := (others => '0');
                end if;
            -- Stop
            else
                ret.eeprom.mode := EEPROM_IDLE;
            end if;
        elsif eeprom.scl = '0' and scl = '1'
        then
            ret := rise(ret, chip, sda, ram_data);
        elsif eeprom.scl = '1' and scl = '0'
        then
            ret := fall(ret, chip, ram_data);
        end if;

        ret.eeprom.scl := scl;
        ret.eeprom.sda := sda;

        return ret;
    end;

end package body;
