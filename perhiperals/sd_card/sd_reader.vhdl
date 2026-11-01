library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utilities.all;
use work.perhipheral_types.all;

-- Reads runs of consecutive blocks from an SD card over SPI, and writes
-- single blocks.
--
-- After reset the card is initialized (CMD0, CMD8, ACMD41, CMD58, CMD16) at
-- INIT_SCK_FREQ, and blocks are then read one 512 byte block at a time with
-- CMD17, and written with CMD24, at SCK_FREQ. Both standard capacity (byte
-- addressed) and high capacity (block addressed) cards are supported.
--
-- The first run, from START_BLOCK, starts as soon as the card is
-- initialized. Without REQUESTS it does not end until stop. With REQUESTS
-- it is sd_count_t'high blocks long. Once a run is over the card is
-- deselected and req_ready is true, and with REQUESTS a run of req_count
-- blocks from req_block is started on a clock where req_valid is also true.
-- req_count must be at least 1. If req_write is true as well, block
-- req_block is written instead.
--
-- Each received byte is presented on data with valid true until it is taken
-- by a clock where ready is also true, and offset is its offset in the
-- block. The card clock is paused until then, so the consumer may take as
-- long as it likes. stop ends a read run: from the first clock where it is
-- true, valid is false, the rest of the current block is read and
-- discarded, and the run ends with the card deselected, so that it is left
-- in a state where it can be initialized again after a reset. stop only
-- has to be true for one clock, and is ignored while no read is running.
--
-- A write sends the byte at offset to the card, so write_data must be the
-- byte at offset from the clock after offset changes. offset is 0 before
-- the first byte. stop is ignored. req_ready becomes true again once the
-- card has accepted the block and finished programming it.
--
-- If the card does not respond as expected, or rejects a write, failed
-- becomes true and the reader stops until the next reset.
--
-- MISO is registered and sampled on the clock before the falling edge of
-- SCK, so there is at least SCK_FREQ / 2 periods minus one clock between
-- the card changing MISO and it being sampled. SCK_FREQ must be no more than
-- CLK_FREQ / 4 so that this is at least one clock.
entity sd_reader is
generic
(
    CLK_FREQ      : positive := 50_000_000;
    INIT_SCK_FREQ : positive := 400_000;
    SCK_FREQ      : positive := 12_500_000;

    START_BLOCK : natural := 0;
    -- Take runs and writes from the req ports. Without it the first run
    -- never ends, and the logic for the req ports is not built
    REQUESTS    : boolean := false;

    -- Time to wait after reset before talking to the card
    POWER_UP_US : natural := 1000;
    -- Time allowed for the card to finish initializing, and for each block
    -- read to start
    TIMEOUT_MS  : positive := 1000;
    -- CMD0 is retried, which lets a card that was left part way through a
    -- block read finish sending it and then be reset
    CMD0_TRIES  : positive := 64
);
port
(
    clk   : in std_logic;
    reset : in boolean;

    failed : out boolean;

    req_valid : in boolean := false;
    req_write : in boolean := false;
    req_block : in sd_block_t := (others => '0');
    req_count : in sd_count_t := 1;
    req_ready : out boolean;

    write_data : in std_logic_vector(7 downto 0) := (others => '1');

    stop   : in boolean;
    data   : out std_logic_vector(7 downto 0);
    offset : out sd_offset_t;
    valid  : out boolean;
    ready  : in boolean;

    sd_clk  : out std_logic;
    sd_cs_n : out std_logic;
    sd_mosi : out std_logic;
    sd_miso : in std_logic
);
end sd_reader;

architecture behavioral of sd_reader is

    constant INIT_HALF_CLKS : positive :=
        (CLK_FREQ + 2 * INIT_SCK_FREQ - 1) / (2 * INIT_SCK_FREQ);
    constant HALF_CLKS : positive :=
        (CLK_FREQ + 2 * SCK_FREQ - 1) / (2 * SCK_FREQ);

    constant POWER_UP_CLKS : natural := POWER_UP_US * (CLK_FREQ / 1_000_000);
    constant TIMEOUT_CLKS  : positive := TIMEOUT_MS * (CLK_FREQ / 1_000);

    -- Bytes of 0xFF clocked with CS high before the first command. At least
    -- 74 clocks are required
    constant WAKE_BYTES : positive := 10;
    -- Bytes polled for a command response. The card responds within 8
    constant NCR_BYTES  : positive := 16;
    constant BLOCK_BYTES : positive := 512;

    subtype div_t is natural range 0 to INIT_HALF_CLKS - 1;
    subtype timer_t is natural range 0 to max(POWER_UP_CLKS, TIMEOUT_CLKS);
    subtype count_t is natural range 0 to BLOCK_BYTES - 1;
    subtype byte_t is std_logic_vector(7 downto 0);
    subtype frame_t is std_logic_vector(47 downto 0);
    -- The bytes of a command frame
    subtype frame_byte_t is natural range 0 to 5;

    type state_t is
    (
        ST_POWER_UP,
        -- Clock WAKE_BYTES with CS high
        ST_WAKE,
        -- Send the command in frame
        ST_CMD,
        -- Poll for the R1 response
        ST_RESP,
        -- Read the 4 bytes after R1 in an R3 or R7 response
        ST_RESP_EXTRA,
        -- Poll for the data token
        ST_TOKEN,
        ST_DATA,
        ST_CRC,
        -- Send the data token of a write, after a byte of 0xFF
        ST_WRITE_TOKEN,
        ST_WRITE_DATA,
        ST_WRITE_CRC,
        -- Poll for the data response token
        ST_WRITE_RESP,
        -- Poll until the card stops holding MISO low while it programs
        ST_WRITE_BUSY,
        -- Clock one byte with CS high, then send cmd, unless it is the read
        -- of a block after the end of the run, or a write
        ST_DESELECT,
        -- Waiting for a run to read
        ST_IDLE,
        ST_ERROR
    );

    type cmd_t is
    (
        CMD_GO_IDLE,
        CMD_SEND_IF_COND,
        CMD_APP,
        CMD_APP_SEND_OP_COND,
        CMD_READ_OCR,
        CMD_SET_BLOCKLEN,
        CMD_READ_BLOCK,
        CMD_WRITE_BLOCK
    );

    -- The R1 responses that are checked for
    type r1_t is
    (
        R1_READY,
        R1_IDLE,
        -- Idle, with an illegal command
        R1_ILLEGAL,
        R1_OTHER
    );

    type reg_t is record
        state : state_t;
        cmd   : cmd_t;
        count : count_t;
        tries : natural range 0 to CMD0_TRIES;
        timer : timer_t;

        -- Card is version 2.00 or later and accepted CMD8
        v2         : boolean;
        -- Card is high capacity and is addressed in blocks
        block_addr : boolean;
        blk        : sd_block_t;
        -- Blocks left in the run, including blk
        left       : sd_count_t;
        -- stop ended the read run
        stopped    : boolean;

        r1    : r1_t;
        -- Bits 11-8 of the R7 response of CMD8 are 0x1: 2.7-3.6V. The
        -- check pattern is in its last byte
        volts_ok : boolean;

        -- Byte transfer
        busy  : boolean;
        div   : div_t;
        bits  : natural range 0 to 7;
        shift : byte_t;

        -- SPI pins
        sck  : std_logic;
        cs_n : std_logic;
        mosi : std_logic;
        miso : std_logic;
    end record;

    constant RESET_REG : reg_t :=
    (
        state => ST_POWER_UP,
        cmd => CMD_GO_IDLE,
        count => 0,
        tries => 0,
        timer => POWER_UP_CLKS,

        v2 => false,
        block_addr => false,
        blk => to_std_logic_vector(START_BLOCK, sd_block_t'length),
        left => sd_count_t'high,
        stopped => false,

        r1 => R1_OTHER,
        volts_ok => false,

        busy => false,
        div => 0,
        bits => 0,
        shift => (others => '1'),

        sck => '0',
        cs_n => '1',
        mosi => '1',
        miso => '1'
    );

    -- Blocks are read and written at SCK_FREQ, once the card is initialized
    function is_fast(cmd : cmd_t) return boolean
    is
    begin
        return cmd = CMD_READ_BLOCK or cmd = CMD_WRITE_BLOCK;
    end;

    function get_r1(resp : byte_t) return r1_t
    is
    begin
        case resp is
            when x"00" =>
                return R1_READY;
            when x"01" =>
                return R1_IDLE;
            when x"05" =>
                return R1_ILLEGAL;
            when others =>
                return R1_OTHER;
        end case;
    end;

    -- Start clocking a byte out on MOSI and in from MISO. The received byte
    -- is in shift once busy is false again
    procedure start_byte(v : inout reg_t; tx : in byte_t)
    is
    begin
        v.busy := true;
        v.bits := 0;
        v.shift := tx;
        v.mosi := tx(7);
        if is_fast(v.cmd)
        then
            v.div := HALF_CLKS - 1;
        else
            v.div := INIT_HALF_CLKS - 1;
        end if;
    end;

    -- The command frame of the command in reg. It is sent a byte at a time
    -- rather than held in a shift register, as it only depends on registers
    -- that do not change while it is sent
    function get_frame(reg : reg_t) return frame_t
    is
        variable index : natural range 0 to 63;
        variable arg   : std_logic_vector(31 downto 0);
        -- Only CMD0 and CMD8 are checked before the CRC is disabled
        variable crc   : std_logic_vector(6 downto 0);
    begin
        arg := (others => '0');
        crc := (others => '1');
        case reg.cmd is
            when CMD_GO_IDLE =>
                index := 0;
                crc := "1001010";
            when CMD_SEND_IF_COND =>
                -- 2.7-3.6V and check pattern 0xAA
                index := 8;
                arg := x"000001AA";
                crc := "1000011";
            when CMD_APP =>
                index := 55;
            when CMD_APP_SEND_OP_COND =>
                index := 41;
                -- HCS: the host supports high capacity cards
                if reg.v2
                then
                    arg(30) := '1';
                end if;
            when CMD_READ_OCR =>
                index := 58;
            when CMD_SET_BLOCKLEN =>
                index := 16;
                arg := to_std_logic_vector(BLOCK_BYTES, 32);
            when CMD_READ_BLOCK | CMD_WRITE_BLOCK =>
                if reg.cmd = CMD_READ_BLOCK
                then
                    index := 17;
                else
                    index := 24;
                end if;
                if reg.block_addr
                then
                    arg := reg.blk;
                else
                    arg := reg.blk(22 downto 0) & "000000000";
                end if;
        end case;

        return "01" & to_std_logic_vector(index, 6) & arg & crc & "1";
    end;

    -- Byte n of the command frame of the command in reg
    function get_frame_byte(reg : reg_t; n : frame_byte_t) return byte_t
    is
        constant FRAME : frame_t := get_frame(reg);
    begin
        case n is
            when 0 => return FRAME(47 downto 40);
            when 1 => return FRAME(39 downto 32);
            when 2 => return FRAME(31 downto 24);
            when 3 => return FRAME(23 downto 16);
            when 4 => return FRAME(15 downto 8);
            when 5 => return FRAME(7 downto 0);
        end case;
    end;

    -- Select the card and start sending cmd, preceded by one byte of 0xFF
    procedure start_cmd(v : inout reg_t; cmd : in cmd_t)
    is
    begin
        v.cmd := cmd;
        v.count := 0;
        v.cs_n := '0';
        v.state := ST_CMD;
        start_byte(v, x"FF");
    end;

    -- Deselect the card for one byte and then send cmd
    procedure deselect(v : inout reg_t; cmd : in cmd_t)
    is
    begin
        v.cmd := cmd;
        v.cs_n := '1';
        v.state := ST_DESELECT;
        start_byte(v, x"FF");
    end;

    procedure fail(v : inout reg_t)
    is
    begin
        v.cs_n := '1';
        v.mosi := '1';
        v.state := ST_ERROR;
    end;

    -- The entity's inputs, other than clk and reset
    type reader_in_t is record
        stop       : boolean;
        ready      : boolean;
        write_data : byte_t;
        req_valid  : boolean;
        req_write  : boolean;
        req_block  : sd_block_t;
        req_count  : sd_count_t;
        miso       : std_logic;
    end record;

    function cycle_reader(reg : reg_t; reader_in : reader_in_t) return reg_t
    is
        variable ret : reg_t;
        variable v_resp_done : boolean;
    begin
        ret := reg;
        v_resp_done := false;

        if reader_in.stop and reg.cmd = CMD_READ_BLOCK and
           reg.state /= ST_IDLE
        then
            ret.stopped := true;
        end if;

        ret.miso := to_x01(reader_in.miso);

        if reg.timer /= 0
        then
            ret.timer := reg.timer - 1;
        end if;

        -- Byte transfer, SPI mode 0. MOSI changes on the falling edge of
        -- SCK and MISO is sampled just before it
        if reg.busy
        then
            if reg.div /= 0
            then
                ret.div := reg.div - 1;
            else
                if is_fast(reg.cmd)
                then
                    ret.div := HALF_CLKS - 1;
                else
                    ret.div := INIT_HALF_CLKS - 1;
                end if;

                if reg.sck = '0'
                then
                    ret.sck := '1';
                else
                    ret.sck := '0';
                    ret.shift := reg.shift(6 downto 0) & reg.miso;
                    if reg.bits = 7
                    then
                        ret.busy := false;
                        ret.mosi := '1';
                    else
                        ret.bits := reg.bits + 1;
                        ret.mosi := reg.shift(6);
                    end if;
                end if;
            end if;
        else
            case reg.state is
                when ST_POWER_UP =>
                    if reg.timer = 0
                    then
                        ret.count := 0;
                        ret.state := ST_WAKE;
                        start_byte(ret, x"FF");
                    end if;
                when ST_WAKE =>
                    if reg.count = WAKE_BYTES - 1
                    then
                        start_cmd(ret, CMD_GO_IDLE);
                    else
                        ret.count := reg.count + 1;
                        start_byte(ret, x"FF");
                    end if;
                when ST_CMD =>
                    if reg.count = 6
                    then
                        ret.count := 0;
                        ret.state := ST_RESP;
                        start_byte(ret, x"FF");
                    else
                        ret.count := reg.count + 1;
                        start_byte(ret, get_frame_byte(reg, reg.count));
                    end if;
                when ST_RESP =>
                    if reg.shift(7) = '0' or reg.count = NCR_BYTES - 1
                    then
                        -- A timeout leaves r1 as R1_OTHER, which every
                        -- command treats as a failure
                        ret.r1 := get_r1(reg.shift);
                        if reg.cmd = CMD_SEND_IF_COND or reg.cmd = CMD_READ_OCR
                        then
                            ret.count := 0;
                            ret.state := ST_RESP_EXTRA;
                            start_byte(ret, x"FF");
                        else
                            v_resp_done := true;
                        end if;
                    else
                        ret.count := reg.count + 1;
                        start_byte(ret, x"FF");
                    end if;
                when ST_RESP_EXTRA =>
                    -- Only the bits that are checked are kept. The last byte
                    -- is checked from shift
                    if reg.count = 0 and reg.cmd = CMD_READ_OCR
                    then
                        -- CCS. A failed command leaves it unused
                        ret.block_addr := reg.shift(6) = '1';
                    end if;
                    if reg.count = 2
                    then
                        ret.volts_ok := reg.shift(3 downto 0) = x"1";
                    end if;
                    if reg.count = 3
                    then
                        v_resp_done := true;
                    else
                        ret.count := reg.count + 1;
                        start_byte(ret, x"FF");
                    end if;
                when ST_TOKEN =>
                    if reg.shift = x"FE"
                    then
                        ret.count := 0;
                        ret.state := ST_DATA;
                        start_byte(ret, x"FF");
                    elsif reg.shift /= x"FF" or reg.timer = 0
                    then
                        -- Data error token, or no response
                        fail(ret);
                    else
                        start_byte(ret, x"FF");
                    end if;
                when ST_DATA =>
                    if reader_in.ready or ret.stopped
                    then
                        if reg.count = BLOCK_BYTES - 1
                        then
                            ret.count := 0;
                            ret.state := ST_CRC;
                        else
                            ret.count := reg.count + 1;
                        end if;
                        start_byte(ret, x"FF");
                    end if;
                when ST_CRC =>
                    if reg.count = 1
                    then
                        -- left is at least 1. Once it is 0 the run is
                        -- over and the next run sets blk
                        ret.blk := std_logic_vector(unsigned(reg.blk) + 1);
                        ret.left := reg.left - 1;
                        deselect(ret, CMD_READ_BLOCK);
                    else
                        ret.count := reg.count + 1;
                        start_byte(ret, x"FF");
                    end if;
                when ST_WRITE_TOKEN =>
                    if reg.count = 0
                    then
                        ret.count := 1;
                        start_byte(ret, x"FF");
                    else
                        -- offset is 0 for the first byte from here
                        ret.count := 0;
                        ret.state := ST_WRITE_DATA;
                        start_byte(ret, x"FE");
                    end if;
                when ST_WRITE_DATA =>
                    if reg.count = BLOCK_BYTES - 1
                    then
                        ret.count := 0;
                        ret.state := ST_WRITE_CRC;
                    else
                        ret.count := reg.count + 1;
                    end if;
                    start_byte(ret, reader_in.write_data);
                when ST_WRITE_CRC =>
                    -- The CRC is not checked in SPI mode. The byte after it
                    -- is the first byte polled for the response
                    if reg.count = 2
                    then
                        ret.count := 0;
                        ret.state := ST_WRITE_RESP;
                    else
                        ret.count := reg.count + 1;
                    end if;
                    start_byte(ret, x"FF");
                when ST_WRITE_RESP =>
                    -- xxx0sss1, where sss = 010 means the data was accepted
                    if reg.shift(4) = '0' and reg.shift(0) = '1'
                    then
                        if reg.shift(3 downto 1) = "010"
                        then
                            ret.timer := TIMEOUT_CLKS;
                            ret.state := ST_WRITE_BUSY;
                            start_byte(ret, x"FF");
                        else
                            fail(ret);
                        end if;
                    elsif reg.count = NCR_BYTES - 1
                    then
                        fail(ret);
                    else
                        ret.count := reg.count + 1;
                        start_byte(ret, x"FF");
                    end if;
                when ST_WRITE_BUSY =>
                    if reg.shift = x"FF"
                    then
                        deselect(ret, CMD_WRITE_BLOCK);
                    elsif reg.timer = 0
                    then
                        fail(ret);
                    else
                        start_byte(ret, x"FF");
                    end if;
                when ST_DESELECT =>
                    if (reg.cmd = CMD_READ_BLOCK and
                        (ret.stopped or (REQUESTS and reg.left = 0))) or
                       reg.cmd = CMD_WRITE_BLOCK
                    then
                        ret.stopped := false;
                        ret.state := ST_IDLE;
                    else
                        start_cmd(ret, reg.cmd);
                    end if;
                when ST_IDLE =>
                    if REQUESTS and reader_in.req_valid
                    then
                        ret.blk := reader_in.req_block;
                        ret.left := reader_in.req_count;
                        if reader_in.req_write
                        then
                            start_cmd(ret, CMD_WRITE_BLOCK);
                        else
                            start_cmd(ret, CMD_READ_BLOCK);
                        end if;
                    end if;
                when ST_ERROR =>
                    null;
            end case;
        end if;

        if v_resp_done
        then
            case reg.cmd is
                when CMD_GO_IDLE =>
                    if ret.r1 = R1_IDLE
                    then
                        deselect(ret, CMD_SEND_IF_COND);
                    elsif reg.tries = CMD0_TRIES - 1
                    then
                        fail(ret);
                    else
                        ret.tries := reg.tries + 1;
                        deselect(ret, CMD_GO_IDLE);
                    end if;
                when CMD_SEND_IF_COND =>
                    -- Version 1 cards reject CMD8 as an illegal command
                    ret.timer := TIMEOUT_CLKS;
                    if ret.r1 = R1_IDLE and reg.volts_ok and reg.shift = x"AA"
                    then
                        ret.v2 := true;
                        deselect(ret, CMD_APP);
                    elsif ret.r1 = R1_ILLEGAL
                    then
                        ret.v2 := false;
                        deselect(ret, CMD_APP);
                    else
                        fail(ret);
                    end if;
                when CMD_APP =>
                    if ret.r1 = R1_READY or ret.r1 = R1_IDLE
                    then
                        deselect(ret, CMD_APP_SEND_OP_COND);
                    else
                        fail(ret);
                    end if;
                when CMD_APP_SEND_OP_COND =>
                    if ret.r1 = R1_READY
                    then
                        if reg.v2
                        then
                            deselect(ret, CMD_READ_OCR);
                        else
                            deselect(ret, CMD_SET_BLOCKLEN);
                        end if;
                    elsif ret.r1 = R1_IDLE and reg.timer /= 0
                    then
                        -- Still initializing
                        deselect(ret, CMD_APP);
                    else
                        fail(ret);
                    end if;
                when CMD_READ_OCR =>
                    if ret.r1 = R1_READY
                    then
                        if ret.block_addr
                        then
                            deselect(ret, CMD_READ_BLOCK);
                        else
                            deselect(ret, CMD_SET_BLOCKLEN);
                        end if;
                    else
                        fail(ret);
                    end if;
                when CMD_SET_BLOCKLEN =>
                    if ret.r1 = R1_READY
                    then
                        deselect(ret, CMD_READ_BLOCK);
                    else
                        fail(ret);
                    end if;
                when CMD_READ_BLOCK =>
                    if ret.r1 = R1_READY
                    then
                        -- Keep the card selected and wait for the data
                        ret.timer := TIMEOUT_CLKS;
                        ret.state := ST_TOKEN;
                        start_byte(ret, x"FF");
                    else
                        fail(ret);
                    end if;
                when CMD_WRITE_BLOCK =>
                    -- Only reachable with REQUESTS. Saying so lets the
                    -- write states be removed without it
                    if REQUESTS and ret.r1 = R1_READY
                    then
                        ret.count := 0;
                        ret.state := ST_WRITE_TOKEN;
                    else
                        fail(ret);
                    end if;
            end case;
        end if;

        return ret;
    end;

    signal reg : reg_t := RESET_REG;

begin

    sd_clk  <= reg.sck;
    sd_cs_n <= reg.cs_n;
    sd_mosi <= reg.mosi;

    failed <= reg.state = ST_ERROR;
    req_ready <= reg.state = ST_IDLE;

    data   <= reg.shift;
    offset <= reg.count;
    valid  <= reg.state = ST_DATA and not reg.busy and not stop and
              not reg.stopped;

    process(clk)
    begin
    if rising_edge(clk)
    then
        if reset
        then
            reg <= RESET_REG;
        else
            reg <= cycle_reader(reg, (stop => stop,
                                      ready => ready,
                                      write_data => write_data,
                                      req_valid => req_valid,
                                      req_write => req_write,
                                      req_block => req_block,
                                      req_count => req_count,
                                      miso => sd_miso));
        end if;
    end if;
    end process;

end behavioral;
