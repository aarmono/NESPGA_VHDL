library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.binary_io.all;

-- Behavioral model of an SD card in SPI mode, holding the contents of
-- FILEPATH starting at block START_BLOCK. Every other block reads as zero.
--
-- Only the commands sd_reader uses are modeled: CMD0, CMD8, CMD16, CMD17,
-- CMD55, ACMD41 and CMD58. HIGH_CAPACITY selects between a block addressed
-- SDHC card and a byte addressed SDSC card, and VERSION_1 makes the card
-- reject CMD8 like a version 1 card. Protocol violations are reported with
-- severity error.
entity sd_card is
generic
(
    FILEPATH   : string;
    FILE_BYTES : positive;
    START_BLOCK : natural := 0;

    HIGH_CAPACITY : boolean := true;
    VERSION_1     : boolean := false;

    -- ACMD41 responses with the idle bit still set before the card is ready
    INIT_BUSY_RESPONSES : natural := 3;
    -- Bytes of 0xFF before a command response (Ncr, 1 to 8)
    RESPONSE_DELAY : positive := 2;
    -- Bytes of 0xFF before the data token of a read (Nac)
    READ_DELAY     : natural := 20;
    -- Clock to output delay after the falling edge of SCK
    T_ODLY : time := 14 ns
);
port
(
    sck  : in std_logic;
    cs_n : in std_logic;
    mosi : in std_logic;
    miso : out std_logic
);
end sd_card;

architecture behavioral of sd_card is

    constant BLOCK_BYTES : positive := 512;

    subtype byte_t is std_logic_vector(7 downto 0);
    type mem_t is array(0 to FILE_BYTES - 1) of byte_t;
    type mem_ptr_t is access mem_t;

    -- Output queue. Large enough for a data block and its response
    constant QUEUE_LEN : positive := 1024;
    type queue_t is array(0 to QUEUE_LEN - 1) of byte_t;
    type cmd_bytes_t is array(0 to 5) of byte_t;

begin

    process
        variable mem : mem_ptr_t := new mem_t;
        file nes_file : byte_file_t;

        variable queue : queue_t;
        variable head  : natural := 0;
        variable count : natural := 0;

        variable in_byte  : byte_t := x"FF";
        variable in_bits  : natural := 0;
        variable out_byte : byte_t := x"FF";
        variable out_bits : natural := 0;

        variable cmd       : cmd_bytes_t;
        variable cmd_bytes : natural := 0;

        variable wake_clks : natural := 0;
        variable spi_mode  : boolean := false;
        variable idle      : boolean := true;
        variable app_cmd   : boolean := false;
        variable hcs       : boolean := false;
        variable busy_left : natural := INIT_BUSY_RESPONSES;

        variable index : natural;
        variable arg   : unsigned(31 downto 0);
        variable r1    : byte_t;
        variable blk   : natural;
        variable offset : integer;

        procedure push(val : byte_t)
        is
        begin
            assert count < QUEUE_LEN
                report "sd_card: output queue overflow"
                severity failure;
            queue((head + count) mod QUEUE_LEN) := val;
            count := count + 1;
        end;

        impure function pop return byte_t
        is
            variable ret : byte_t;
        begin
            if count = 0
            then
                return x"FF";
            else
                ret := queue(head);
                head := (head + 1) mod QUEUE_LEN;
                count := count - 1;
                return ret;
            end if;
        end;

        procedure respond(val : byte_t)
        is
        begin
            for i in 1 to RESPONSE_DELAY
            loop
                push(x"FF");
            end loop;
            push(val);
        end;

        procedure push_word(val : unsigned(31 downto 0))
        is
        begin
            push(std_logic_vector(val(31 downto 24)));
            push(std_logic_vector(val(23 downto 16)));
            push(std_logic_vector(val(15 downto 8)));
            push(std_logic_vector(val(7 downto 0)));
        end;

        procedure execute
        is
        begin
            index := to_integer(cmd(0)(5 downto 0));
            arg := unsigned(std_logic_vector'(cmd(1) & cmd(2) &
                                              cmd(3) & cmd(4)));

            if not spi_mode
            then
                -- The card powers up in SD mode and only enters SPI mode
                -- on a CMD0 with CS low
                if index /= 0
                then
                    report "sd_card: CMD" & integer'image(index) &
                           " before CMD0"
                        severity error;
                    return;
                end if;
                assert wake_clks >= 74
                    report "sd_card: only " & integer'image(wake_clks) &
                           " clocks with CS high before CMD0"
                    severity error;
            end if;

            -- CRC is only checked for CMD0 and CMD8 in SPI mode
            if (index = 0 and cmd(5) /= x"95") or
               (index = 8 and arg = x"000001AA" and cmd(5) /= x"87")
            then
                report "sd_card: bad CRC for CMD" & integer'image(index)
                    severity error;
                respond(x"08");
                return;
            end if;

            if idle
            then
                r1 := x"01";
            else
                r1 := x"00";
            end if;

            if app_cmd
            then
                app_cmd := false;
                if index = 41
                then
                    hcs := arg(30) = '1';
                    -- A high capacity card never becomes ready for a host
                    -- that does not support it
                    if busy_left /= 0
                    then
                        busy_left := busy_left - 1;
                    elsif hcs or not HIGH_CAPACITY
                    then
                        idle := false;
                    end if;

                    if idle
                    then
                        respond(x"01");
                    else
                        respond(x"00");
                    end if;
                else
                    report "sd_card: unsupported ACMD" & integer'image(index)
                        severity error;
                    respond(r1 or x"04");
                end if;
                return;
            end if;

            case index is
                when 0 =>
                    spi_mode := true;
                    idle := true;
                    busy_left := INIT_BUSY_RESPONSES;
                    respond(x"01");
                when 8 =>
                    if VERSION_1
                    then
                        respond(r1 or x"04");
                    else
                        respond(r1);
                        push_word(x"00000" & arg(11 downto 0));
                    end if;
                when 55 =>
                    app_cmd := true;
                    respond(r1);
                when 58 =>
                    respond(r1);
                    if idle
                    then
                        push_word(x"00FF8000");
                    elsif HIGH_CAPACITY
                    then
                        push_word(x"C0FF8000");
                    else
                        push_word(x"80FF8000");
                    end if;
                when 16 =>
                    assert not idle
                        report "sd_card: CMD16 while idle"
                        severity error;
                    if HIGH_CAPACITY or arg = BLOCK_BYTES
                    then
                        respond(r1);
                    else
                        report "sd_card: unsupported block length"
                            severity error;
                        respond(r1 or x"40");
                    end if;
                when 17 =>
                    if idle
                    then
                        report "sd_card: CMD17 while idle"
                            severity error;
                        respond(r1 or x"04");
                        return;
                    end if;

                    if HIGH_CAPACITY
                    then
                        blk := to_integer(arg);
                    else
                        assert arg mod BLOCK_BYTES = 0
                            report "sd_card: unaligned read address"
                            severity error;
                        blk := to_integer(arg / BLOCK_BYTES);
                    end if;

                    respond(r1);
                    for i in 1 to READ_DELAY
                    loop
                        push(x"FF");
                    end loop;
                    push(x"FE");
                    for i in 0 to BLOCK_BYTES - 1
                    loop
                        offset := (blk - START_BLOCK) * BLOCK_BYTES + i;
                        if offset >= 0 and offset < FILE_BYTES
                        then
                            push(mem(offset));
                        else
                            push(x"00");
                        end if;
                    end loop;
                    -- CRC is not checked in SPI mode
                    push(x"00");
                    push(x"00");
                when others =>
                    report "sd_card: unsupported CMD" & integer'image(index)
                        severity error;
                    respond(r1 or x"04");
            end case;
        end;

        procedure receive(val : byte_t)
        is
        begin
            if count /= 0
            then
                -- The card does not accept commands while it is sending
                assert val = x"FF"
                    report "sd_card: byte " & to_hstring(val) &
                           " sent while card is responding"
                    severity error;
            elsif cmd_bytes = 0
            then
                if val(7 downto 6) = "01"
                then
                    cmd(0) := val;
                    cmd_bytes := 1;
                else
                    assert val = x"FF"
                        report "sd_card: unexpected byte " & to_hstring(val)
                        severity error;
                end if;
            else
                cmd(cmd_bytes) := val;
                if cmd_bytes = 5
                then
                    cmd_bytes := 0;
                    execute;
                else
                    cmd_bytes := cmd_bytes + 1;
                end if;
            end if;
        end;

    begin
        byte_fopen(nes_file, FILEPATH, read_mode);
        for i in mem'range
        loop
            if not byte_feof(nes_file)
            then
                mem(i) := byte_fread(nes_file);
            else
                mem(i) := x"00";
            end if;
        end loop;
        byte_fclose(nes_file);

        miso <= 'Z';

        loop
            wait on sck, cs_n;

            if cs_n'event
            then
                if cs_n = '0'
                then
                    -- Bytes are aligned to CS going low
                    in_bits := 0;
                    out_bits := 0;
                    out_byte := pop;
                    miso <= out_byte(7) after T_ODLY;
                else
                    miso <= 'Z' after T_ODLY;
                end if;
            elsif cs_n = '1'
            then
                if rising_edge(sck)
                then
                    wake_clks := wake_clks + 1;
                end if;
            elsif rising_edge(sck)
            then
                in_byte := in_byte(6 downto 0) & to_x01(mosi);
                in_bits := in_bits + 1;
                if in_bits = 8
                then
                    in_bits := 0;
                    receive(in_byte);
                end if;
            elsif falling_edge(sck)
            then
                out_bits := out_bits + 1;
                if out_bits = 8
                then
                    out_bits := 0;
                    out_byte := pop;
                end if;
                miso <= out_byte(7 - out_bits) after T_ODLY;
            end if;
        end loop;
    end process;

end behavioral;
