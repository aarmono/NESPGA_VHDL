-----------------------------------------------------------------------------
--                                                                         --
-- Copyright (c) 1996 by Altera Corp.  All rights reserved.                --
--                                                                         --
--                                                                         --
--  Description:  Package file for Altera mega functions.                  --
--                                                                         --
--                                                                         --
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package megacore is
	component a16450 
	port (
		mr : IN std_logic;
		clk : IN std_logic;
		a : IN std_logic_vector(2 downto 0);
		din : IN std_logic_vector(7 downto 0);
		cs0 : IN std_logic;
		cs1 : IN std_logic;
		ncs2 : IN std_logic;
		nads : IN std_logic;
		rd : IN std_logic;
    		nrd : IN std_logic;
		wr : IN std_logic;
		nwr : IN std_logic;
		sin : IN std_logic;
		rclk : IN std_logic;
		ncts : IN std_logic;
		ndsr : IN std_logic;
		ndcd : IN std_logic;
		nri : IN std_logic;
		dout : OUT std_logic_vector(7 downto 0);
		ddis : OUT std_logic;
		csout : OUT std_logic;
		sout : OUT std_logic;
		nbaudout : OUT std_logic;
		nrts : OUT std_logic;
		ndtr : OUT std_logic;
		nout1 : OUT std_logic;
		nout2 : OUT std_logic;
		intr : OUT std_logic
	     );
	end component;
 
	component a6402 
	port (
		cls1 : IN std_logic;
		cls2 : IN std_logic;
		crl : IN std_logic;
		ndrr : IN std_logic;
		epe : IN std_logic;
		mr : IN std_logic;
		pi : IN std_logic;
		rrc : IN std_logic;
		rri : IN std_logic;
		sbs : IN std_logic;
		tbr : IN std_logic_vector(7 downto 0);
		ntbrl : IN std_logic;
		trc : IN std_logic;
		dr : OUT std_logic;
		fe : OUT std_logic;
		oe : OUT std_logic;
		pe : OUT std_logic;
		rbr : OUT std_logic_vector(7 downto 0);
		tbre : OUT std_logic;
		tro : OUT std_logic;
		tre : OUT std_logic
	     );
	end component;
 
	component a6850 
	port (
		nreset : IN std_logic;
		di : IN std_logic_vector(7 downto 0);
		e : IN std_logic;
		rnw : IN std_logic;
		cs : IN std_logic_vector(2 downto 0);
		rs : IN std_logic;
		txclk : IN std_logic;
		rxclk : IN std_logic;
		rxdata : IN std_logic;
		ncts : IN std_logic;
		ndcd : IN std_logic;
		do : OUT std_logic_vector(7 downto 0);
		nirq : OUT std_logic;
		txdata : OUT std_logic;
		nrts : OUT std_logic
	     );
	end component;
 
	component a8237 
	port (
		reset : IN std_logic;
		clk : IN std_logic;
		ncs : IN std_logic;
		niorin : IN std_logic;
		niowin : IN std_logic;
		ready : IN std_logic;
		hlda : IN std_logic;
		neopin : IN std_logic;
		ain : IN std_logic_vector(3 downto 0);
		dreq : IN std_logic_vector(3 downto 0);
		dbin : IN std_logic_vector(7 downto 0);
		dbout : OUT std_logic_vector(7 downto 0);
		dben : OUT std_logic;
		aout : OUT std_logic_vector(7 downto 0);
		hrq : OUT std_logic;
		dack : OUT std_logic_vector(3 downto 0);
		aen : OUT std_logic;
		adstb : OUT std_logic;
		niorout : OUT std_logic;
		niowout : OUT std_logic;
		nmemr : OUT std_logic;
		nmemw : OUT std_logic;
		neopout : OUT std_logic;
		dmaenable : OUT std_logic
	     );
	end component;
 
	component a8251 
	port (
		clk : IN std_logic;
		nreset : IN std_logic;
		nwr : IN std_logic;
		nrd : IN std_logic;
		ncs : IN std_logic;
		cnd : IN std_logic;
		ndsr : IN std_logic;
		ncts : IN std_logic;
		extsyncd : IN std_logic;
		ntxc : IN std_logic;
		nrxc : IN std_logic;
		rxd : IN std_logic;
		din : IN std_logic_vector(7 downto 0);
		txd : OUT std_logic;
		txrdy : OUT std_logic;
		txempty : OUT std_logic;
		rxrdy : OUT std_logic;
		ndtr : OUT std_logic;
		nrts : OUT std_logic;
		syn_brk : OUT std_logic;
		nen : OUT std_logic;
		dout : OUT std_logic_vector(7 downto 0)
	     );
	end component;
 
	component a8255 
	port (
		reset : IN std_logic;
		clk : IN std_logic;
		ncs : IN std_logic;
		nrd : IN std_logic;
		nwr : IN std_logic;
		a : IN std_logic_vector(1 downto 0);
		din : IN std_logic_vector(7 downto 0);
		pain : IN std_logic_vector(7 downto 0);
		pbin  : IN std_logic_vector(7 downto 0);
		pcin : IN std_logic_vector(7 downto 0);
		dout : OUT std_logic_vector(7 downto 0);
		paout : OUT std_logic_vector(7 downto 0);
		paen : OUT std_logic;
		pbout : OUT std_logic_vector(7 downto 0);
		pben : OUT std_logic;
		pcout : OUT std_logic_vector(7 downto 0);
		pcen : OUT std_logic_vector(7 downto 0)
	     );
	end component;

	component rgb2ycrcb
	port (
		R : IN std_logic_vector(7 downto 0);
        G : IN std_logic_vector(7 downto 0);
        B : IN std_logic_vector(7 downto 0);
        CLOCK : IN std_logic := '0';
        ACLR  : IN std_logic := '0';
     	Y : OUT std_logic_vector(15 downto 0);
     	Cr: OUT std_logic_vector(14 downto 0);
     	Cb: OUT std_logic_vector(14 downto 0)
     	 );
	end component;

	component ycrcb2rgb
    port (
    	Y : IN std_logic_vector(7 downto 0);
        CR : IN std_logic_vector(7 downto 0);
        CB : IN std_logic_vector(7 downto 0);
        CLOCK : IN std_logic := '0';
        ACLR  : IN std_logic := '0';
     	R : OUT std_logic_vector(16 downto 0);
     	G: OUT std_logic_vector(16 downto 0);
     	B: OUT std_logic_vector(16 downto 0)
      	 );
	end component;

	component a8259
	port (
		nmrst, clk, ncs, nwr, nrd, a0, nsp, ninta : IN std_logic;
		casin : IN std_logic_vector(2 downto 0);
		din, ir : IN std_logic_vector(7 downto 0);
		nen, cas_en, int : OUT std_logic;
		dout : OUT std_logic_vector(7 downto 0);
		casout : OUT std_logic_vector(7 downto 0)
		 );
	end component;

	component fft
	generic (
		WIDTH_DATA               : POSITIVE;
        WIDTH_TWIDDLE            : POSITIVE;
        PIPE_DATA                : INTEGER;
        PIPE_TWIDDLE             : INTEGER;
        WIDTH_EXPONENT           : POSITIVE;
        WIDTH_ADD                : POSITIVE;
        EXPONENT_INITIAL_VALUE   : INTEGER
            );
	port (
		clock            : IN std_logic := '0';
		start_fft        : IN std_logic;
		data_left_in_re  : IN std_logic_vector(WIDTH_DATA-1 downto 0);
		data_left_in_im  : IN std_logic_vector(WIDTH_DATA-1 downto 0);
		data_right_in_re : IN std_logic_vector(WIDTH_DATA-1 downto 0);
		data_right_in_im : IN std_logic_vector(WIDTH_DATA-1 downto 0);
		twiddle_re       : IN std_logic_vector(WIDTH_TWIDDLE-1 downto 0);
		twiddle_im       : IN std_logic_vector(WIDTH_TWIDDLE-1 downto 0);
		done             : OUT std_logic;
		data_direction   : OUT std_logic;
		we_left          : OUT std_logic;
		add_left         : OUT std_logic_vector(WIDTH_ADD-1 downto 0); 
		we_right         : OUT std_logic;
		add_right        : OUT std_logic_vector(WIDTH_ADD-1 downto 0); 
		add_twiddle      : OUT std_logic_vector(WIDTH_ADD-2 downto 0); 
		data_out_re      : OUT std_logic_vector(WIDTH_DATA-1 downto 0); 
		data_out_im      : OUT std_logic_vector(WIDTH_DATA-1 downto 0); 
		exponent         : OUT std_logic_vector(WIDTH_EXPONENT-1 downto 0)
		 );
	end component;



end megacore;
