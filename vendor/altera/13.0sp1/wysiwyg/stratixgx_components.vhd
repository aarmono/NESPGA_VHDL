--
-- Copyright (C) 1988-2002 Altera Corporation
-- Any megafunction design, and related net list (encrypted or decrypted),
-- support information, device programming or simulation file, and any other
-- associated documentation or information provided by Altera or a partner
-- under  Altera's   Megafunction   Partnership   Program  may  be  used  only
-- to program  PLD  devices (but not masked  PLD  devices) from  Altera.   Any
-- other  use  of such  megafunction  design,  netlist,  support  information,
-- device programming or simulation file,  or any other  related documentation
-- or information  is prohibited  for  any  other purpose,  including, but not
-- limited to modification, reverse engineering, de-compiling, or use with
-- any other silicon devices, unless such use is explicitly licensed under
-- a separate agreement with  Altera  or a megafunction partner.  Title to the
-- intellectual property,  including patents,  copyrights,  trademarks,  trade
-- secrets,  or maskworks,  embodied in any such megafunction design, netlist,
-- support  information,  device programming or simulation file,  or any other
-- related documentation or information provided by  Altera  or a megafunction
-- partner, remains with Altera, the megafunction partner, or their respective
-- licensors. No other licenses, including any licenses needed under any third
-- party's intellectual property, are provided herein.




library IEEE, stratixgx;
use IEEE.STD_LOGIC_1164.all;

package STRATIXGX_COMPONENTS is


component stratixgx_hssi_receiver 
	generic (
				channel_num					: integer := 1;
				channel_width				: integer := 20;
				run_length					: integer := 4;
				run_length_enable			: String  := "false";
				use_8b_10b_mode			    : String  := "false";
				use_double_data_mode		: String  := "false";
				use_rate_match_fifo		    : String  := "false";
				rate_matching_fifo_mode	    : String  := "none";
				use_channel_align			: String  := "false";
				use_symbol_align			: String  := "true";
				use_auto_bit_slip			: String  := "false";
				synchronization_mode		: String  := "none";
				align_pattern				: std_logic_vector := "0000000000000000";
				align_pattern_length		: integer  := 10;
				infiniband_invalid_code	    : integer  := 0;
				disparity_mode				: String  := "false";
				clk_out_mode_reference	    : String  := "false";
				cruclk_period				: integer := 5000;
				cruclk_multiplier 		    : integer := 4;
				use_cruclk_divider          : String := "false";
				use_self_test_mode          : String := "false";
 			    self_test_mode              : integer := 0;
				use_parallel_feedback       : String := "false";
                use_post8b10b_feedback      : String := "false";
				use_equalizer_ctrl_signal   : String := "false";
				equalizer_ctrl_setting      : integer := 20;
				signal_threshhold_select    : integer := 2;
				bandwidth_type              : String := "low";
				enable_dc_coupling          : String := "false";
				vco_bypass                  : String := "false";
				force_signal_detect         : String := "false";
				for_engineering_sample_device : String := "true"
;
		lpm_type : string := "stratixgx_hssi_receiver"			);

	port (
				datain				: in std_logic := '0';
				cruclk				: in std_logic := '0';
				pllclk				: in std_logic := '0';
				masterclk			: in std_logic := '0';
				coreclk				: in std_logic := '0';
				softreset			: in std_logic := '0';
				serialfdbk			: in std_logic := '0';
				parallelfdbk		: in std_logic_vector(9 downto 0) := "0000000000";
				post8b10b			: in std_logic_vector(7 downto 0) := "00000000";
				slpbk				: in std_logic := '0';
				bitslip				: in std_logic := '0';
				enacdet				: in std_logic := '0';
				we					: in std_logic := '0';
				re					: in std_logic := '0';
				alignstatus			: in std_logic := '0';
				disablefifordin	    : in std_logic := '0';
				disablefifowrin	    : in std_logic := '0';
				fifordin			: in std_logic := '0';
				enabledeskew		: in std_logic := '0';
				fiforesetrd			: in std_logic := '0';
				xgmdatain			: in std_logic_vector(7 downto 0) := "00000000";
				xgmctrlin			: in std_logic := '0';
                a1a2size            : in std_logic := '0';
				equalizerctrl       : in std_logic_vector(2 downto 0) := "000";
				locktorefclk        : in std_logic := '0';
                locktodata          : in std_logic := '0';
				syncstatus			: out std_logic_vector(1 downto 0);
				patterndetect		: out std_logic_vector(1 downto 0);
				ctrldetect			: out std_logic_vector(1 downto 0);
				errdetect			: out std_logic_vector(1 downto 0);
				disperr				: out std_logic_vector(1 downto 0);
				syncstatusdeskew	: out std_logic;
				adetectdeskew		: out std_logic;
				rdalign				: out std_logic;
				dataout				: out std_logic_vector(19 downto 0);
				xgmdataout			: out std_logic_vector(7 downto 0);
				xgmctrldet			: out std_logic;
				xgmrunningdisp		: out std_logic;
				xgmdatavalid		: out std_logic;
				fifofull			: out std_logic;
				fifoalmostfull		: out std_logic;
				fifoempty			: out std_logic;
				fifoalmostempty	    : out std_logic;
				disablefifordout	: out std_logic;
				disablefifowrout	: out std_logic;
				fifordout			: out std_logic;
				signaldetect		: out std_logic;
				lock				: out std_logic;
				freqlock			: out std_logic;
				rlv					: out std_logic;
				clkout				: out std_logic;
				recovclkout			: out std_logic;
				bistdone            : out std_logic;
				bisterr             : out std_logic;
				a1a2sizeout         : out std_logic_vector(1 downto 0)
		);
end component;

component stratixgx_hssi_transmitter 
	generic (
				channel_num					: integer := 1;
				channel_width				: integer := 20;
				use_double_data_mode		: String  := "false";
				use_8b_10b_mode			    : String  := "false";
				use_fifo_mode				: String  := "false";
				force_disparity_mode		: String  := "false";
				transmit_protocol			: String  := "none";
                use_vod_ctrl_signal         : String  := "false";
                vod_ctrl_setting            : integer := 4;
				use_preemphasis_ctrl_signal : String  := "false";
				preemphasis_ctrl_setting    : integer := 5;
				use_self_test_mode          : String := "false";
				self_test_mode              : integer := 0;
				use_reverse_parallel_feedback : String := "false";
				termination                 : integer := 0
;
		lpm_type : string := "stratixgx_hssi_transmitter"			);
	port (
				datain				: in std_logic_vector(19 downto 0) := "00000000000000000000";
				pllclk				: in std_logic := '0';
				fastpllclk			: in std_logic := '0';
				coreclk				: in std_logic := '0';
				softreset			: in std_logic := '0';
				analogreset			: in std_logic := '0'; 
				ctrlenable			: in std_logic_vector(1 downto 0) := "00";
				forcedisparity		: in std_logic_vector(1 downto 0) := "00";
				serialdatain		: in std_logic := '0';
				xgmdatain			: in std_logic_vector(7 downto 0) := "00000000";
				xgmctrl				: in std_logic := '0';
				srlpbk				: in std_logic := '0';
                vodctrl             : in std_logic_vector(2 downto 0) := "000";
                preemphasisctrl     : in std_logic_vector(2 downto 0) := "000";
				dataout				: out std_logic;
				xgmdataout			: out std_logic_vector(7 downto 0);
				xgmctrlenable		: out std_logic;
				rdenablesync		: out std_logic;
				parallelfdbkdata	: out std_logic_vector(9 downto 0);
				pre8b10bdata		: out std_logic_vector(9 downto 0)
		);
end component;

component stratixgx_xgm_interface 
 generic (
		lpm_type : string := "stratixgx_xgm_interface"
		);
	port (
				txdatain				: in std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
				txctrl				: in std_logic_vector(3 downto 0) := "0000";
				rdenablesync		: in std_logic := '0';
				txclk					: in std_logic := '0';
				rxdatain				: in std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
				rxctrl				: in std_logic_vector(3 downto 0) := "0000";
				rxrunningdisp		: in std_logic_vector(3 downto 0) := "0000";
				rxdatavalid			: in std_logic_vector(3 downto 0) := "0000";
				rxclk					: in std_logic := '0';
				resetall				: in std_logic := '0';
				adet					: in std_logic_vector(3 downto 0) := "0000";
				syncstatus			: in std_logic_vector(3 downto 0) := "0000";
				rdalign				: in std_logic_vector(3 downto 0) := "0000";
				recovclk				: in std_logic := '0';
				txdataout			: out std_logic_vector(31 downto 0);
				txctrlout			: out std_logic_vector(3 downto 0);
				rxdataout			: out std_logic_vector(31 downto 0);
				rxctrlout			: out std_logic_vector(3 downto 0);
				resetout				: out std_logic;
				alignstatus			: out std_logic;
				enabledeskew		: out std_logic;
				fiforesetrd			: out std_logic
		);
end component;


--clearbox auto-generated components begin
--Dont add any component declarations after this section

------------------------------------------------------------------
-- stratixgx_lvds_receiver parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component stratixgx_lvds_receiver
	generic (
		channel_width	:	natural;
		dpll_lockcnt	:	natural := 1;
		dpll_lockwin	:	natural := 100;
		dpll_rawperror	:	string := "off";
		enable_dpa	:	string := "off";
		enable_fifo	:	string := "on";
		use_enable1	:	string := "false";
		lpm_type	:	string := "stratixgx_lvds_receiver"
	);
	port(
		bitslip	:	in std_logic := '0';
		clk0	:	in std_logic;
		coreclk	:	in std_logic := '0';
		datain	:	in std_logic;
		dataout	:	out std_logic_vector(channel_width-1 downto 0);
		dpalock	:	out std_logic;
		dpareset	:	in std_logic := '0';
		dpllreset	:	in std_logic := '0';
		enable0	:	in std_logic;
		enable1	:	in std_logic := '0'
	);
end component;

--clearbox auto-generated components end
--clearbox copy auto-generated components begin
--Dont add any component declarations after this section

component stratixgx_crcblock
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixgx_crcblock";
		oscillator_divider	:	natural := 1	);
	port(
		clk	:	in std_logic := '0';
		crcerror	:	out std_logic;
		ldsrc	:	in std_logic := '0';
		regout	:	out std_logic;
		shiftnld	:	in std_logic := '0'
	);
end component;
component stratixgx_dll
	generic (
		input_frequency	:	string;
		phase_shift	:	string := "0";
		sim_invalid_lock	:	natural := 5;
		sim_valid_lock	:	natural := 1;
		lpm_type	:	string := "stratixgx_dll"
	);
	port(
		clk	:	in std_logic;
		delayctrlout	:	out std_logic
	);
end component;
component stratixgx_mac_out
	generic (
		addnsub0_clear	:	string := "none";
		addnsub0_clock	:	string := "none";
		addnsub0_pipeline_clear	:	string := "none";
		addnsub0_pipeline_clock	:	string := "none";
		addnsub1_clear	:	string := "none";
		addnsub1_clock	:	string := "none";
		addnsub1_pipeline_clear	:	string := "none";
		addnsub1_pipeline_clock	:	string := "none";
		data_out_programmable_invert	:	std_logic_vector(71 downto 0) := "000000000000000000000000000000000000000000000000000000000000000000000000";
		dataa_width	:	natural := 1;
		datab_width	:	natural := 1;
		datac_width	:	natural := 1;
		datad_width	:	natural := 1;
		dataout_width	:	natural := 72;
		operation_mode	:	string;
		output_clear	:	string := "none";
		output_clock	:	string := "none";
		signa_clear	:	string := "none";
		signa_clock	:	string := "none";
		signa_pipeline_clear	:	string := "none";
		signa_pipeline_clock	:	string := "none";
		signb_clear	:	string := "none";
		signb_clock	:	string := "none";
		signb_pipeline_clear	:	string := "none";
		signb_pipeline_clock	:	string := "none";
		zeroacc_clear	:	string := "none";
		zeroacc_clock	:	string := "none";
		zeroacc_pipeline_clear	:	string := "none";
		zeroacc_pipeline_clock	:	string := "none";
		lpm_type	:	string := "stratixgx_mac_out"
	);
	port(
		accoverflow	:	out std_logic;
		aclr	:	in std_logic_vector(3 downto 0) := (others => '0');
		addnsub0	:	in std_logic := '1';
		addnsub1	:	in std_logic := '1';
		clk	:	in std_logic_vector(3 downto 0) := (others => '1');
		dataa	:	in std_logic_vector(dataa_width-1 downto 0) := (others => '0');
		datab	:	in std_logic_vector(datab_width-1 downto 0) := (others => '0');
		datac	:	in std_logic_vector(datac_width-1 downto 0) := (others => '0');
		datad	:	in std_logic_vector(datad_width-1 downto 0) := (others => '0');
		dataout	:	out std_logic_vector(dataout_width-1 downto 0);
		ena	:	in std_logic_vector(3 downto 0) := (others => '1');
		signa	:	in std_logic := '1';
		signb	:	in std_logic := '1';
		zeroacc	:	in std_logic := '0'
	);
end component;
component stratixgx_jtag
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixgx_jtag"	);
	port(
		clkdruser	:	out std_logic;
		ntrst	:	in std_logic := '0';
		runidleuser	:	out std_logic;
		shiftuser	:	out std_logic;
		tck	:	in std_logic := '0';
		tckutap	:	out std_logic;
		tdi	:	in std_logic := '0';
		tdiutap	:	out std_logic;
		tdo	:	out std_logic;
		tdouser	:	in std_logic := '0';
		tdoutap	:	in std_logic := '0';
		tms	:	in std_logic := '0';
		tmsutap	:	out std_logic;
		updateuser	:	out std_logic;
		usr1user	:	out std_logic
	);
end component;
component stratixgx_pll
	generic (
		bandwidth	:	natural := 0;
		bandwidth_type	:	string := "auto";
		charge_pump_current	:	natural := 0;
		clk0_counter	:	string := "g0";
		clk0_divide_by	:	natural := 1;
		clk0_duty_cycle	:	natural := 50;
		clk0_multiply_by	:	natural := 1;
		clk0_phase_shift	:	string := "UNUSED";
		clk0_phase_shift_num	:	natural := 0;
		clk0_time_delay	:	string := "UNUSED";
		clk0_use_even_counter_mode	:	string := "off";
		clk0_use_even_counter_value	:	string := "off";
		clk1_counter	:	string := "g1";
		clk1_divide_by	:	natural := 1;
		clk1_duty_cycle	:	natural := 50;
		clk1_multiply_by	:	natural := 1;
		clk1_phase_shift	:	string := "UNUSED";
		clk1_phase_shift_num	:	natural := 0;
		clk1_time_delay	:	string := "UNUSED";
		clk1_use_even_counter_mode	:	string := "off";
		clk1_use_even_counter_value	:	string := "off";
		clk2_counter	:	string := "g2";
		clk2_divide_by	:	natural := 1;
		clk2_duty_cycle	:	natural := 50;
		clk2_multiply_by	:	natural := 1;
		clk2_phase_shift	:	string := "UNUSED";
		clk2_phase_shift_num	:	natural := 0;
		clk2_time_delay	:	string := "UNUSED";
		clk2_use_even_counter_mode	:	string := "off";
		clk2_use_even_counter_value	:	string := "off";
		clk3_counter	:	string := "g3";
		clk3_divide_by	:	natural := 1;
		clk3_duty_cycle	:	natural := 50;
		clk3_multiply_by	:	natural := 1;
		clk3_phase_shift	:	string := "UNUSED";
		clk3_time_delay	:	string := "UNUSED";
		clk3_use_even_counter_mode	:	string := "off";
		clk3_use_even_counter_value	:	string := "off";
		clk4_counter	:	string := "l0";
		clk4_divide_by	:	natural := 1;
		clk4_duty_cycle	:	natural := 50;
		clk4_multiply_by	:	natural := 1;
		clk4_phase_shift	:	string := "UNUSED";
		clk4_time_delay	:	string := "UNUSED";
		clk4_use_even_counter_mode	:	string := "off";
		clk4_use_even_counter_value	:	string := "off";
		clk5_counter	:	string := "l1";
		clk5_divide_by	:	natural := 1;
		clk5_duty_cycle	:	natural := 50;
		clk5_multiply_by	:	natural := 1;
		clk5_phase_shift	:	string := "UNUSED";
		clk5_time_delay	:	string := "UNUSED";
		clk5_use_even_counter_mode	:	string := "off";
		clk5_use_even_counter_value	:	string := "off";
		common_rx_tx	:	string := "off";
		compensate_clock	:	string := "clk0";
		down_spread	:	string := "UNUSED";
		e0_high	:	natural := 1;
		e0_initial	:	natural := 1;
		e0_low	:	natural := 1;
		e0_mode	:	string := "bypass";
		e0_ph	:	natural := 0;
		e0_time_delay	:	natural := 0;
		e1_high	:	natural := 1;
		e1_initial	:	natural := 1;
		e1_low	:	natural := 1;
		e1_mode	:	string := "bypass";
		e1_ph	:	natural := 0;
		e1_time_delay	:	natural := 0;
		e2_high	:	natural := 1;
		e2_initial	:	natural := 1;
		e2_low	:	natural := 1;
		e2_mode	:	string := "bypass";
		e2_ph	:	natural := 0;
		e2_time_delay	:	natural := 0;
		e3_high	:	natural := 1;
		e3_initial	:	natural := 1;
		e3_low	:	natural := 1;
		e3_mode	:	string := "bypass";
		e3_ph	:	natural := 0;
		e3_time_delay	:	natural := 0;
		enable0_counter	:	string := "l0";
		enable1_counter	:	string := "l0";
		enable_switch_over_counter	:	string := "off";
		extclk0_counter	:	string := "e0";
		extclk0_divide_by	:	natural := 1;
		extclk0_duty_cycle	:	natural := 50;
		extclk0_multiply_by	:	natural := 1;
		extclk0_phase_shift	:	string := "UNUSED";
		extclk0_time_delay	:	string := "UNUSED";
		extclk0_use_even_counter_mode	:	string := "off";
		extclk0_use_even_counter_value	:	string := "off";
		extclk1_counter	:	string := "e1";
		extclk1_divide_by	:	natural := 1;
		extclk1_duty_cycle	:	natural := 50;
		extclk1_multiply_by	:	natural := 1;
		extclk1_phase_shift	:	string := "UNUSED";
		extclk1_time_delay	:	string := "UNUSED";
		extclk1_use_even_counter_mode	:	string := "off";
		extclk1_use_even_counter_value	:	string := "off";
		extclk2_counter	:	string := "e2";
		extclk2_divide_by	:	natural := 1;
		extclk2_duty_cycle	:	natural := 50;
		extclk2_multiply_by	:	natural := 1;
		extclk2_phase_shift	:	string := "UNUSED";
		extclk2_time_delay	:	string := "UNUSED";
		extclk2_use_even_counter_mode	:	string := "off";
		extclk2_use_even_counter_value	:	string := "off";
		extclk3_counter	:	string := "e3";
		extclk3_divide_by	:	natural := 1;
		extclk3_duty_cycle	:	natural := 50;
		extclk3_multiply_by	:	natural := 1;
		extclk3_phase_shift	:	string := "UNUSED";
		extclk3_time_delay	:	string := "UNUSED";
		extclk3_use_even_counter_mode	:	string := "off";
		extclk3_use_even_counter_value	:	string := "off";
		feedback_source	:	string := "extclk0";
		g0_high	:	natural := 1;
		g0_initial	:	natural := 1;
		g0_low	:	natural := 1;
		g0_mode	:	string := "bypass";
		g0_ph	:	natural := 0;
		g0_time_delay	:	natural := 0;
		g1_high	:	natural := 1;
		g1_initial	:	natural := 1;
		g1_low	:	natural := 1;
		g1_mode	:	string := "bypass";
		g1_ph	:	natural := 0;
		g1_time_delay	:	natural := 0;
		g2_high	:	natural := 1;
		g2_initial	:	natural := 1;
		g2_low	:	natural := 1;
		g2_mode	:	string := "bypass";
		g2_ph	:	natural := 0;
		g2_time_delay	:	natural := 0;
		g3_high	:	natural := 1;
		g3_initial	:	natural := 1;
		g3_low	:	natural := 1;
		g3_mode	:	string := "bypass";
		g3_ph	:	natural := 0;
		g3_time_delay	:	natural := 0;
		gate_lock_counter	:	natural := 1;
		gate_lock_signal	:	string := "no";
		inclk0_input_frequency	:	natural := 0;
		inclk1_input_frequency	:	natural := 0;
		invalid_lock_multiplier	:	natural := 5;
		l0_high	:	natural := 1;
		l0_initial	:	natural := 1;
		l0_low	:	natural := 1;
		l0_mode	:	string := "bypass";
		l0_ph	:	natural := 0;
		l0_time_delay	:	natural := 0;
		l1_high	:	natural := 1;
		l1_initial	:	natural := 1;
		l1_low	:	natural := 1;
		l1_mode	:	string := "bypass";
		l1_ph	:	natural := 0;
		l1_time_delay	:	natural := 0;
		loop_filter_c	:	natural := 1;
		loop_filter_r	:	string := "UNUSED";
		m	:	natural := 0;
		m2	:	natural := 1;
		m_initial	:	natural := 1;
		m_ph	:	natural := 0;
		m_time_delay	:	natural := 0;
		n	:	natural := 1;
		n2	:	natural := 1;
		n_time_delay	:	natural := 0;
		operation_mode	:	string := "normal";
		pfd_max	:	natural := 0;
		pfd_min	:	natural := 0;
		pll_compensation_delay	:	natural := 0;
		pll_type	:	string := "Auto";
		primary_clock	:	string := "inclk0";
		qualify_conf_done	:	string := "OFF";
		rx_outclock_resource	:	string := "auto";
		scan_chain	:	string := "long";
		scan_chain_mif_file	:	string;
		simulation_type	:	string := "timing";
		skip_vco	:	string := "off";
		source_is_pll	:	string := "off";
		spread_frequency	:	natural := 0;
		ss	:	natural := 0;
		switch_over_counter	:	natural := 1;
		switch_over_on_gated_lock	:	string := "off";
		switch_over_on_lossclk	:	string := "off";
		use_dc_coupling	:	string := "false";
		use_vco_bypass	:	string := "false";
		valid_lock_multiplier	:	natural := 5;
		vco_center	:	natural := 0;
		vco_max	:	natural := 0;
		vco_min	:	natural := 0;
		lpm_type	:	string := "stratixgx_pll"
	);
	port(
		activeclock	:	out std_logic;
		areset	:	in std_logic := '0';
		clk	:	out std_logic_vector(5 downto 0);
		clkbad	:	out std_logic_vector(1 downto 0);
		clkena	:	in std_logic_vector(5 downto 0) := (others => '1');
		clkloss	:	out std_logic;
		clkswitch	:	in std_logic := '0';
		comparator	:	in std_logic := '0';
		ena	:	in std_logic := '1';
		enable0	:	out std_logic;
		enable1	:	out std_logic;
		extclk	:	out std_logic_vector(3 downto 0);
		extclkena	:	in std_logic_vector(3 downto 0) := (others => '1');
		fbin	:	in std_logic := '0';
		inclk	:	in std_logic_vector(1 downto 0);
		locked	:	out std_logic;
		pfdena	:	in std_logic := '1';
		scanaclr	:	in std_logic := '0';
		scanclk	:	in std_logic := '0';
		scandata	:	in std_logic := '0';
		scandataout	:	out std_logic
	);
end component;
component stratixgx_ram_block
	generic (
		connectivity_checking	:	string := "OFF";
		data_interleave_offset_in_bits	:	natural := 1;
		data_interleave_width_in_bits	:	natural := 1;
		init_file	:	string := "UNUSED";
		init_file_layout	:	string := "UNUSED";
		logical_ram_name	:	string;
		mem_init0	:	std_logic_vector(2047 downto 0) := "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
		mem_init1	:	std_logic_vector(2559 downto 0) := "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
		mixed_port_feed_through_mode	:	string := "UNUSED";
		operation_mode	:	string;
		port_a_address_clear	:	string := "UNUSED";
		port_a_address_width	:	natural := 1;
		port_a_byte_enable_clear	:	string := "UNUSED";
		port_a_byte_enable_mask_width	:	natural := 1;
		port_a_data_in_clear	:	string := "UNUSED";
		port_a_data_out_clear	:	string := "UNUSED";
		port_a_data_out_clock	:	string := "none";
		port_a_data_width	:	natural := 1;
		port_a_first_address	:	natural;
		port_a_first_bit_number	:	natural;
		port_a_last_address	:	natural;
		port_a_logical_ram_depth	:	natural := 0;
		port_a_logical_ram_width	:	natural := 0;
		port_a_write_enable_clear	:	string := "UNUSED";
		port_b_address_clear	:	string := "UNUSED";
		port_b_address_clock	:	string := "UNUSED";
		port_b_address_width	:	natural := 1;
		port_b_byte_enable_clear	:	string := "UNUSED";
		port_b_byte_enable_clock	:	string := "UNUSED";
		port_b_byte_enable_mask_width	:	natural := 1;
		port_b_data_in_clear	:	string := "UNUSED";
		port_b_data_in_clock	:	string := "UNUSED";
		port_b_data_out_clear	:	string := "UNUSED";
		port_b_data_out_clock	:	string := "none";
		port_b_data_width	:	natural := 1;
		port_b_first_address	:	natural := 0;
		port_b_first_bit_number	:	natural := 0;
		port_b_last_address	:	natural := 0;
		port_b_logical_ram_depth	:	natural := 0;
		port_b_logical_ram_width	:	natural := 0;
		port_b_read_enable_write_enable_clear	:	string := "UNUSED";
		port_b_read_enable_write_enable_clock	:	string := "UNUSED";
		power_up_uninitialized	:	string := "false";
		ram_block_type	:	string;
		width_eccstatus	:	natural := 3;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixgx_ram_block"
	);
	port(
		clk0	:	in std_logic;
		clk1	:	in std_logic := '0';
		clr0	:	in std_logic := '0';
		clr1	:	in std_logic := '0';
		ena0	:	in std_logic := '1';
		ena1	:	in std_logic := '1';
		portaaddr	:	in std_logic_vector(port_a_address_width-1 downto 0) := (others => '0');
		portabyteenamasks	:	in std_logic_vector(port_a_byte_enable_mask_width-1 downto 0) := (others => '1');
		portadatain	:	in std_logic_vector(port_a_data_width-1 downto 0) := (others => '0');
		portadataout	:	out std_logic_vector(port_a_data_width-1 downto 0);
		portawe	:	in std_logic := '0';
		portbaddr	:	in std_logic_vector(port_b_address_width-1 downto 0) := (others => '0');
		portbbyteenamasks	:	in std_logic_vector(port_b_byte_enable_mask_width-1 downto 0) := (others => '1');
		portbdatain	:	in std_logic_vector(port_b_data_width-1 downto 0) := (others => '0');
		portbdataout	:	out std_logic_vector(port_b_data_width-1 downto 0);
		portbrewe	:	in std_logic := '0'
	);
end component;
component stratixgx_mac_mult
	generic (
		dataa_clear	:	string := "none";
		dataa_clock	:	string := "none";
		dataa_width	:	natural;
		datab_clear	:	string := "none";
		datab_clock	:	string := "none";
		datab_width	:	natural;
		output_clear	:	string := "none";
		output_clock	:	string := "none";
		signa_clear	:	string := "none";
		signa_clock	:	string := "none";
		signa_internally_grounded	:	string := "false";
		signb_clear	:	string := "none";
		signb_clock	:	string := "none";
		signb_internally_grounded	:	string := "false";
		lpm_type	:	string := "stratixgx_mac_mult"
	);
	port(
		aclr	:	in std_logic_vector(3 downto 0) := (others => '0');
		clk	:	in std_logic_vector(3 downto 0) := (others => '1');
		dataa	:	in std_logic_vector(dataa_width-1 downto 0) := (others => '1');
		datab	:	in std_logic_vector(datab_width-1 downto 0) := (others => '1');
		dataout	:	out std_logic_vector(dataa_width+datab_width-1 downto 0);
		ena	:	in std_logic_vector(3 downto 0) := (others => '1');
		scanouta	:	out std_logic_vector(dataa_width-1 downto 0);
		scanoutb	:	out std_logic_vector(datab_width-1 downto 0);
		signa	:	in std_logic := '1';
		signb	:	in std_logic := '1'
	);
end component;
component stratixgx_rublock
	generic (
		operation_mode	:	string := "remote";
		sim_init_config	:	string := "factory";
		sim_init_page_select	:	natural := 0;
		sim_init_status	:	natural := 0;
		sim_init_watchdog_value	:	natural := 0;
		lpm_type	:	string := "stratixgx_rublock"
	);
	port(
		captnupdt	:	in std_logic;
		clk	:	in std_logic;
		pgmout	:	out std_logic_vector(2 downto 0);
		rconfig	:	in std_logic;
		regin	:	in std_logic;
		regout	:	out std_logic;
		rsttimer	:	in std_logic;
		shiftnld	:	in std_logic
	);
end component;
component stratixgx_lvds_transmitter
	generic (
		bypass_serializer	:	string := "false";
		channel_width	:	natural;
		invert_clock	:	string := "false";
		use_falling_clock_edge	:	string := "false";
		lpm_type	:	string := "stratixgx_lvds_transmitter"
	);
	port(
		clk0	:	in std_logic;
		datain	:	in std_logic_vector(channel_width-1 downto 0);
		dataout	:	out std_logic;
		enable0	:	in std_logic
	);
end component;
component stratixgx_lcell
	generic (
		cin0_used	:	string := "false";
		cin1_used	:	string := "false";
		cin_used	:	string := "false";
		lut_mask	:	string;
		operation_mode	:	string := "normal";
		output_mode	:	string := "reg_and_comb";
		power_up	:	string := "low";
		register_cascade_mode	:	string := "off";
		sum_lutc_input	:	string := "datac";
		synch_mode	:	string := "off";
		x_on_violation	:	string := "on";
		lpm_type	:	string := "stratixgx_lcell"
	);
	port(
		aclr	:	in std_logic := '0';
		aload	:	in std_logic := '0';
		cin	:	in std_logic := '0';
		clk	:	in std_logic := '0';
		combout	:	out std_logic;
		cout	:	out std_logic;
		dataa	:	in std_logic := '1';
		datab	:	in std_logic := '1';
		datac	:	in std_logic := '1';
		datad	:	in std_logic := '1';
		ena	:	in std_logic := '1';
		inverta	:	in std_logic := '0';
		regcascin	:	in std_logic := '0';
		regout	:	out std_logic;
		sclr	:	in std_logic := '0';
		sload	:	in std_logic := '0'
	);
end component;
component stratixgx_io
	generic (
		bus_hold	:	string := "false";
		ddio_mode	:	string := "none";
		extend_oe_disable	:	string := "false";
		input_async_reset	:	string := "none";
		input_power_up	:	string := "low";
		input_register_mode	:	string := "none";
		input_sync_reset	:	string := "none";
		oe_async_reset	:	string := "none";
		oe_power_up	:	string := "low";
		oe_register_mode	:	string := "none";
		oe_sync_reset	:	string := "none";
		open_drain_output	:	string := "false";
		operation_mode	:	string;
		output_async_reset	:	string := "none";
		output_power_up	:	string := "low";
		output_register_mode	:	string := "none";
		output_sync_reset	:	string := "none";
		sim_dll_phase_shift	:	string := "unused";
		sim_dqs_input_frequency	:	string := "unused";
		tie_off_oe_clock_enable	:	string := "false";
		tie_off_output_clock_enable	:	string := "false";
		lpm_type	:	string := "stratixgx_io"
	);
	port(
		areset	:	in std_logic := '0';
		combout	:	out std_logic;
		datain	:	in std_logic := '0';
		ddiodatain	:	in std_logic := '0';
		ddioregout	:	out std_logic;
		delayctrlin	:	in std_logic := '0';
		dqsundelayedout	:	out std_logic;
		inclk	:	in std_logic := '0';
		inclkena	:	in std_logic := '1';
		oe	:	in std_logic := '1';
		outclk	:	in std_logic := '0';
		outclkena	:	in std_logic := '1';
		padio	:	inout std_logic;
		regout	:	out std_logic;
		sreset	:	in std_logic := '0'
	);
end component;
--clearbox copy auto-generated components end
end stratixgx_components;
