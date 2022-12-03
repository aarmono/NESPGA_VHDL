--
-- Copyright (C) 1988-2004 Altera Corporation
--
-- Any megafunction design, and related net list (encrypted or decrypted),
-- support information, device programming or simulation file, and any
-- other associated documentation or information provided by Altera or a
-- partner under Altera's Megafunction Partnership Program may be used only
-- to program PLD devices (but not masked PLD devices) from Altera.  Any
-- other use of such megafunction design, net list, support information,
-- device programming or simulation file, or any other related
-- documentation or information is prohibited for any other purpose,
-- including, but not limited to modification, reverse engineering, de-
-- compiling, or use with any other silicon devices, unless such use is
-- explicitly licensed under a separate agreement with Altera or a
-- megafunction partner.  Title to the intellectual property, including
-- patents, copyrights, trademarks, trade secrets, or maskworks, embodied
-- in any such megafunction design, net list, support information, device
-- programming or simulation file, or any other related documentation or
-- information provided by Altera or a megafunction partner, remains with
-- Altera, the megafunction partner, or their respective licensors.  No
-- other licenses, including any licenses needed under any third party's
-- intellectual property, are provided herein.
----------------------------------------------------------------------------
-- ALtera Megafunction Component Declaration File
----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

package altera_mf_components is
type altera_mf_logic_2D is array (NATURAL RANGE <>, NATURAL RANGE <>) of STD_LOGIC;

component lcell
    port (
        a_in : in std_logic;
        a_out : out std_logic);
end component;

component parallel_add 

   generic (
      width                   :  natural := 4;    
      size                    :  natural := 2;    
      widthr                  :  natural := 4;    
      shift                   :  natural := 0;    
      msw_subtract            :  string  := "NO";    
      representation          :  string  := "UNSIGNED";    
      pipeline                :  natural := 0;    
      result_alignment        :  string  := "LSB";
      lpm_hint		      :  string  := "UNUSED";    
      lpm_type                :  string  := "parallel_add"
      );

   port (
      data                    : in altera_mf_logic_2D(size - 1 downto 0, width- 1 downto 0);   
      clock                   : in std_logic := '1';
      aclr                    : in std_logic := '0';
      clken                   : in std_logic := '1';
      result                  : out std_logic_vector(widthr - 1 downto 0));   
end component;

--clearbox auto-generated components begin
--Dont add any component declarations after this section

------------------------------------------------------------------
-- altufm_spi parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altufm_spi
	generic (
		access_mode	:	string;
		byte_of_page_write	:	natural := 8;
		config_mode	:	string;
		intended_device_family	:	string := "unused";
		erase_time	:	natural := 500000000;
		lpm_file	:	string := "UNUSED";
		osc_frequency	:	natural := 180000;
		program_time	:	natural := 1600000;
		width_ufm_address	:	natural := 9;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altufm_spi"
	);
	port(
		ncs	:	in std_logic;
		osc	:	out std_logic;
		oscena	:	in std_logic := '1';
		sck	:	in std_logic;
		si	:	in std_logic;
		so	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- altfp_log parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altfp_log
	generic (
		intended_device_family	:	string := "unused";
		pipeline	:	natural := 21;
		width_exp	:	natural := 8;
		width_man	:	natural := 23;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altfp_log"
	);
	port(
		aclr	:	in std_logic := '0';
		clk_en	:	in std_logic := '1';
		clock	:	in std_logic;
		data	:	in std_logic_vector(width_exp+width_man+1-1 downto 0);
		nan	:	out std_logic;
		result	:	out std_logic_vector(width_exp+width_man+1-1 downto 0);
		zero	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- altfp_exp parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altfp_exp
	generic (
		intended_device_family	:	string := "unused";
		pipeline	:	natural := 17;
		rounding	:	string := "TO_NEAREST";
		width_exp	:	natural := 8;
		width_man	:	natural := 23;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altfp_exp"
	);
	port(
		aclr	:	in std_logic := '0';
		clk_en	:	in std_logic := '1';
		clock	:	in std_logic;
		data	:	in std_logic_vector(width_exp+width_man+1-1 downto 0);
		nan	:	out std_logic;
		overflow	:	out std_logic;
		result	:	out std_logic_vector(width_exp+width_man+1-1 downto 0);
		underflow	:	out std_logic;
		zero	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- altfp_div parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altfp_div
	generic (
		decoder_support	:	string := "NO";
		denormal_support	:	string := "YES";
		intended_device_family	:	string := "unused";
		exception_handling	:	string := "YES";
		optimize	:	string := "SPEED";
		pipeline	:	natural := 32;
		reduced_functionality	:	string := "NO";
		rounding	:	string := "TO_NEAREST";
		width_exp	:	natural := 8;
		width_man	:	natural := 23;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altfp_div"
	);
	port(
		aclr	:	in std_logic := '0';
		clk_en	:	in std_logic := '1';
		clock	:	in std_logic;
		dataa	:	in std_logic_vector(width_exp+width_man+1-1 downto 0);
		datab	:	in std_logic_vector(width_exp+width_man+1-1 downto 0);
		denormal	:	out std_logic;
		division_by_zero	:	out std_logic;
		indefinite	:	out std_logic;
		nan	:	out std_logic;
		overflow	:	out std_logic;
		result	:	out std_logic_vector(width_exp+width_man+1-1 downto 0);
		underflow	:	out std_logic;
		zero	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- altfp_compare parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altfp_compare
	generic (
		intended_device_family	:	string := "unused";
		pipeline	:	natural := 3;
		width_exp	:	natural := 8;
		width_man	:	natural := 23;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altfp_compare"
	);
	port(
		aclr	:	in std_logic := '0';
		aeb	:	out std_logic;
		agb	:	out std_logic;
		ageb	:	out std_logic;
		alb	:	out std_logic;
		aleb	:	out std_logic;
		aneb	:	out std_logic;
		clk_en	:	in std_logic := '1';
		clock	:	in std_logic;
		dataa	:	in std_logic_vector(width_exp+width_man+1-1 downto 0);
		datab	:	in std_logic_vector(width_exp+width_man+1-1 downto 0);
		unordered	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- alt_oct parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component alt_oct
	generic (
		allow_serial_data_from_core	:	string := "FALSE";
		intended_device_family	:	string := "unused";
		enable_parallel_termination	:	string := "FALSE";
		oct_block_number	:	natural := 0;
		power_down	:	string := "TRUE";
		test_mode	:	string := "FALSE";
		width_ptc	:	natural := 14;
		width_stc	:	natural := 14;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "alt_oct"
	);
	port(
		aclr	:	in std_logic := '0';
		cal_shift_busy	:	out std_logic_vector(oct_block_number-1 downto 0);
		calibration_busy	:	out std_logic_vector(oct_block_number-1 downto 0);
		calibration_done	:	out std_logic_vector(oct_block_number-1 downto 0);
		calibration_only_req	:	in std_logic_vector(oct_block_number-1 downto 0) := (others => '0');
		calibration_request	:	in std_logic_vector(oct_block_number-1 downto 0) := (others => '0');
		calibration_wait	:	in std_logic_vector(oct_block_number-1 downto 0) := (others => '0');
		clken	:	in std_logic := '1';
		clock	:	in std_logic := '0';
		incrdn	:	out std_logic;
		incrup	:	out std_logic;
		parallelterminationcontrol	:	out std_logic_vector(oct_block_number * width_ptc-1 downto 0);
		rdn	:	in std_logic_vector(oct_block_number-1 downto 0) := (others => '0');
		rup	:	in std_logic_vector(oct_block_number-1 downto 0) := (others => '0');
		rzqin	:	in std_logic_vector(oct_block_number-1 downto 0) := (others => '0');
		s2pload	:	in std_logic_vector(oct_block_number-1 downto 0) := (others => '0');
		scanout	:	out std_logic;
		seriesterminationcontrol	:	out std_logic_vector(oct_block_number * width_stc-1 downto 0);
		shift_busy	:	out std_logic_vector(oct_block_number-1 downto 0);
		shift_only_req	:	in std_logic_vector(oct_block_number-1 downto 0) := (others => '0');
		shiftregisterprobe	:	out std_logic;
		termination_control	:	out std_logic_vector(16 * oct_block_number-1 downto 0);
		terminationcontrolprobe	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- dcfifo parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component dcfifo
	generic (
		add_ram_output_register	:	string := "OFF";
		add_usedw_msb_bit	:	string := "OFF";
		clocks_are_synchronized	:	string := "FALSE";
		delay_rdusedw	:	natural := 1;
		delay_wrusedw	:	natural := 1;
		intended_device_family	:	string := "unused";
		lpm_numwords	:	natural;
		lpm_showahead	:	string := "OFF";
		lpm_width	:	natural;
		lpm_widthu	:	natural := 1;
		overflow_checking	:	string := "ON";
		rdsync_delaypipe	:	natural := 0;
		read_aclr_synch	:	string := "OFF";
		underflow_checking	:	string := "ON";
		use_eab	:	string := "ON";
		write_aclr_synch	:	string := "OFF";
		wrsync_delaypipe	:	natural := 0;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "dcfifo"
	);
	port(
		aclr	:	in std_logic := '0';
		data	:	in std_logic_vector(lpm_width-1 downto 0);
		q	:	out std_logic_vector(lpm_width-1 downto 0);
		rdclk	:	in std_logic;
		rdempty	:	out std_logic;
		rdfull	:	out std_logic;
		rdreq	:	in std_logic;
		rdusedw	:	out std_logic_vector(lpm_widthu-1 downto 0);
		wrclk	:	in std_logic;
		wrempty	:	out std_logic;
		wrfull	:	out std_logic;
		wrreq	:	in std_logic;
		wrusedw	:	out std_logic_vector(lpm_widthu-1 downto 0)
	);
end component;

------------------------------------------------------------------
-- sld_virtual_jtag parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component sld_virtual_jtag
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "sld_virtual_jtag";
		sld_auto_instance_index	:	string := "NO";
		sld_instance_index	:	natural := 0;
		sld_ir_width	:	natural := 1;
		sld_sim_action	:	string := "UNUSED";
		sld_sim_n_scan	:	natural := 0;
		sld_sim_total_length	:	natural := 0	);
	port(
		ir_in	:	out std_logic_vector(sld_ir_width-1 downto 0);
		ir_out	:	in std_logic_vector(sld_ir_width-1 downto 0);
		jtag_state_cdr	:	out std_logic;
		jtag_state_cir	:	out std_logic;
		jtag_state_e1dr	:	out std_logic;
		jtag_state_e1ir	:	out std_logic;
		jtag_state_e2dr	:	out std_logic;
		jtag_state_e2ir	:	out std_logic;
		jtag_state_pdr	:	out std_logic;
		jtag_state_pir	:	out std_logic;
		jtag_state_rti	:	out std_logic;
		jtag_state_sdr	:	out std_logic;
		jtag_state_sdrs	:	out std_logic;
		jtag_state_sir	:	out std_logic;
		jtag_state_sirs	:	out std_logic;
		jtag_state_tlr	:	out std_logic;
		jtag_state_udr	:	out std_logic;
		jtag_state_uir	:	out std_logic;
		tck	:	out std_logic;
		tdi	:	out std_logic;
		tdo	:	in std_logic;
		tms	:	out std_logic;
		virtual_state_cdr	:	out std_logic;
		virtual_state_cir	:	out std_logic;
		virtual_state_e1dr	:	out std_logic;
		virtual_state_e2dr	:	out std_logic;
		virtual_state_pdr	:	out std_logic;
		virtual_state_sdr	:	out std_logic;
		virtual_state_udr	:	out std_logic;
		virtual_state_uir	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- alt2gxb_reconfig parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component alt2gxb_reconfig
	generic (
		aeq_fromgxb_width	:	natural := 6;
		aeq_mode	:	string := "RUN";
		aeq_togxb_width	:	natural := 4;
		aeq_translate_eqs	:	string := "YES";
		avmm_slave_addr_width	:	natural := 16;
		avmm_slave_rdata_width	:	natural := 16;
		avmm_slave_wdata_width	:	natural := 16;
		base_port_width	:	natural := 1;
		channel_address_width	:	natural := 1;
		data_latency	:	natural := 0;
		intended_device_family	:	string := "unused";
		enable_aeq	:	string := "OFF";
		enable_arriaii_ext_eq	:	string := "false";
		enable_arriaii_ext_preemp	:	string := "false";
		enable_buf_cal	:	string := "FALSE";
		enable_buf_cal_func_sim	:	string := "FALSE";
		enable_chl_addr_for_analog_ctrl	:	string := "FALSE";
		enable_dfe	:	string := "OFF";
		enable_eye_monitor	:	string := "OFF";
		enable_full_write	:	string := "FALSE";
		enable_illegal_mode_check	:	string := "FALSE";
		enable_rx_tx_duplex_sel	:	string := "FALSE";
		enable_self_recovery	:	string := "FALSE";
		enable_stratixiv_rx_equalization	:	string := "FALSE";
		logical_pll_sel_width	:	natural := 1;
		mif_address_width	:	natural := 5;
		number_of_channels	:	natural;
		number_of_reconfig_ports	:	natural;
		read_base_port_width	:	natural := 1;
		reconfig_fromgxb_width	:	natural := 1;
		reconfig_mode_sel_width	:	natural := 3;
		reconfig_togxb_width	:	natural := 3;
		rx_eqdcgain_port_width	:	natural := 2;
		tx_preemp_port_width	:	natural := 4;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "alt2gxb_reconfig"
	);
	port(
		adce_cal_busy	:	out std_logic;
		aeq_fromgxb	:	in std_logic_vector(aeq_fromgxb_width-1 downto 0) := (others => '0');
		aeq_togxb	:	out std_logic_vector(aeq_togxb_width-1 downto 0);
		busy	:	out std_logic;
		channel_reconfig_done	:	out std_logic;
		conv_error	:	out std_logic_vector(number_of_channels-1 downto 0);
		ctrl_address	:	in std_logic_vector(avmm_slave_addr_width-1 downto 0) := (others => '0');
		ctrl_read	:	in std_logic := '0';
		ctrl_readdata	:	out std_logic_vector(avmm_slave_rdata_width-1 downto 0);
		ctrl_waitrequest	:	out std_logic;
		ctrl_write	:	in std_logic := '0';
		ctrl_writedata	:	in std_logic_vector(avmm_slave_wdata_width-1 downto 0) := (others => '0');
		data_valid	:	out std_logic;
		eqout	:	out std_logic_vector(3 downto 0);
		error	:	out std_logic;
		gxb_address	:	in std_logic_vector(3-1 downto 0) := (others => '0');
		logical_channel_address	:	in std_logic_vector(channel_address_width-1 downto 0) := (others => '0');
		logical_tx_pll_sel	:	in std_logic_vector(logical_pll_sel_width-1 downto 0) := (others => '0');
		logical_tx_pll_sel_en	:	in std_logic := '1';
		offset_cancellation_reset	:	in std_logic := '0';
		rate_switch_ctrl	:	in std_logic_vector(2-1 downto 0) := (others => '0');
		rate_switch_out	:	out std_logic_vector(2-1 downto 0);
		read	:	in std_logic := '0';
		reconfig_address	:	in std_logic_vector(mif_address_width-1 downto 0) := (others => '0');
		reconfig_address_en	:	out std_logic;
		reconfig_address_out	:	out std_logic_vector(mif_address_width-1 downto 0);
		reconfig_clk	:	in std_logic;
		reconfig_data	:	in std_logic_vector(16-1 downto 0) := (others => '0');
		reconfig_data_mask	:	in std_logic_vector(16-1 downto 0) := (others => '0');
		reconfig_data_out	:	out std_logic_vector(16-1 downto 0);
		reconfig_fromgxb	:	in std_logic_vector(reconfig_fromgxb_width-1 downto 0);
		reconfig_mode_sel	:	in std_logic_vector(reconfig_mode_sel_width-1 downto 0) := (others => '0');
		reconfig_reset	:	in std_logic := '0';
		reconfig_togxb	:	out std_logic_vector(reconfig_togxb_width-1 downto 0);
		reset_reconfig_address	:	in std_logic := '0';
		rx_eqctrl	:	in std_logic_vector(base_port_width*4-1 downto 0) := (others => '0');
		rx_eqctrl_out	:	out std_logic_vector(read_base_port_width*4-1 downto 0);
		rx_eqdcgain	:	in std_logic_vector(base_port_width*rx_eqdcgain_port_width-1 downto 0) := (others => '0');
		rx_eqdcgain_out	:	out std_logic_vector(read_base_port_width*rx_eqdcgain_port_width-1 downto 0);
		rx_tx_duplex_sel	:	in std_logic_vector(2-1 downto 0) := (others => '0');
		start	:	in std_logic := '0';
		timeout	:	out std_logic;
		transceiver_init	:	in std_logic := '0';
		tx_preemp_0t	:	in std_logic_vector(base_port_width*tx_preemp_port_width-1 downto 0) := (others => '0');
		tx_preemp_0t_out	:	out std_logic_vector(read_base_port_width*tx_preemp_port_width-1 downto 0);
		tx_preemp_1t	:	in std_logic_vector(base_port_width*tx_preemp_port_width-1 downto 0) := (others => '0');
		tx_preemp_1t_out	:	out std_logic_vector(read_base_port_width*tx_preemp_port_width-1 downto 0);
		tx_preemp_1ta	:	in std_logic_vector(base_port_width*tx_preemp_port_width-1 downto 0) := (others => '0');
		tx_preemp_1ta_out	:	out std_logic_vector(read_base_port_width*tx_preemp_port_width-1 downto 0);
		tx_preemp_1tb	:	in std_logic_vector(base_port_width*tx_preemp_port_width-1 downto 0) := (others => '0');
		tx_preemp_1tb_out	:	out std_logic_vector(read_base_port_width*tx_preemp_port_width-1 downto 0);
		tx_preemp_2t	:	in std_logic_vector(base_port_width*tx_preemp_port_width-1 downto 0) := (others => '0');
		tx_preemp_2t_out	:	out std_logic_vector(read_base_port_width*tx_preemp_port_width-1 downto 0);
		tx_vodctrl	:	in std_logic_vector(base_port_width*3-1 downto 0) := (others => '0');
		tx_vodctrl_out	:	out std_logic_vector(read_base_port_width*3-1 downto 0);
		tx_vodctrla	:	in std_logic_vector(base_port_width*3-1 downto 0) := (others => '0');
		tx_vodctrla_out	:	out std_logic_vector(read_base_port_width*3-1 downto 0);
		write_all	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- altmemmult parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altmemmult
	generic (
		coeff_representation	:	string := "SIGNED";
		coefficient0	:	string := "UNUSED";
		data_representation	:	string := "SIGNED";
		intended_device_family	:	string := "unused";
		max_clock_cycles_per_result	:	natural := 1;
		number_of_coefficients	:	natural := 1;
		ram_block_type	:	string := "AUTO";
		total_latency	:	natural;
		width_c	:	natural;
		width_d	:	natural;
		width_r	:	natural;
		width_s	:	natural := 1;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altmemmult"
	);
	port(
		clock	:	in std_logic;
		coeff_in	:	in std_logic_vector(width_c-1 downto 0) := (others => '0');
		data_in	:	in std_logic_vector(width_d-1 downto 0);
		load_done	:	out std_logic;
		result	:	out std_logic_vector(width_r-1 downto 0);
		result_valid	:	out std_logic;
		sclr	:	in std_logic := '0';
		sel	:	in std_logic_vector(width_s-1 downto 0) := (others => '0');
		sload_coeff	:	in std_logic := '0';
		sload_data	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- altshift_taps parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altshift_taps
	generic (
		intended_device_family	:	string := "unused";
		number_of_taps	:	natural;
		power_up_state	:	string := "CLEARED";
		tap_distance	:	natural;
		width	:	natural;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altshift_taps"
	);
	port(
		aclr	:	in std_logic := '0';
		clken	:	in std_logic := '1';
		clock	:	in std_logic;
		shiftin	:	in std_logic_vector(width-1 downto 0);
		shiftout	:	out std_logic_vector(width-1 downto 0);
		taps	:	out std_logic_vector(width*number_of_taps-1 downto 0)
	);
end component;

------------------------------------------------------------------
-- altpll_reconfig parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altpll_reconfig
	generic (
		intended_device_family	:	string := "unused";
		init_from_rom	:	string := "NO";
		pll_type	:	string := "UNUSED";
		scan_chain	:	string := "UNUSED";
		scan_init_file	:	string := "UNUSED";
		use_scanclk_sync_register	:	string := "NO";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altpll_reconfig"
	);
	port(
		busy	:	out std_logic;
		clock	:	in std_logic;
		counter_param	:	in std_logic_vector(2 downto 0) := (others => '0');
		counter_type	:	in std_logic_vector(3 downto 0) := (others => '0');
		data_in	:	in std_logic_vector(8 downto 0) := (others => '0');
		data_out	:	out std_logic_vector(8 downto 0);
		pll_areset	:	out std_logic;
		pll_areset_in	:	in std_logic := '0';
		pll_configupdate	:	out std_logic;
		pll_scanaclr	:	out std_logic;
		pll_scanclk	:	out std_logic;
		pll_scanclkena	:	out std_logic;
		pll_scandata	:	out std_logic;
		pll_scandataout	:	in std_logic := '0';
		pll_scandone	:	in std_logic := '0';
		pll_scanread	:	out std_logic;
		pll_scanwrite	:	out std_logic;
		read_param	:	in std_logic := '0';
		reconfig	:	in std_logic := '0';
		reset	:	in std_logic;
		reset_rom_address	:	in std_logic := '0';
		rom_address_out	:	out std_logic_vector(7 downto 0);
		rom_data_in	:	in std_logic := '0';
		write_from_rom	:	in std_logic := '0';
		write_param	:	in std_logic := '0';
		write_rom_ena	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- altcal_dpa_pll parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altcal_dpa_pll
	generic (
		calibrate_for_all_channels	:	string := "OFF";
		calibration_start_threshold	:	natural := 256;
		calibration_wait_timer	:	natural := 1024;
		number_of_channels	:	natural;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altcal_dpa_pll"
	);
	port(
		calibration_busy	:	out std_logic;
		clock	:	in std_logic;
		dpa_fifo_reset	:	out std_logic_vector(number_of_channels-1 downto 0);
		dpa_lock_out	:	out std_logic_vector(number_of_channels-1 downto 0);
		dpa_lock_reset	:	out std_logic_vector(number_of_channels-1 downto 0);
		dpa_locked	:	in std_logic_vector(number_of_channels-1 downto 0);
		dpa_reset	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		pll_locked	:	in std_logic;
		pll_phasecounterselect	:	out std_logic_vector(3 downto 0);
		pll_phasedone	:	in std_logic;
		pll_phasestep	:	out std_logic;
		pll_phaseupdown	:	out std_logic;
		pll_scanclk	:	in std_logic;
		recalibrate	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- altbarrel_shift parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altbarrel_shift
	generic (
		intended_device_family	:	string := "unused";
		padding	:	string := "0";
		pipeline	:	natural := 0;
		register_output	:	string := "YES";
		shiftdir	:	string := "LEFT";
		shifttype	:	string := "LOGICAL";
		width	:	natural := 8;
		widthdist	:	natural := 3;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altbarrel_shift"
	);
	port(
		aclr	:	in std_logic := '0';
		clk_en	:	in std_logic := '1';
		clock	:	in std_logic := '0';
		data	:	in std_logic_vector(width-1 downto 0);
		direction	:	in std_logic := '0';
		distance	:	in std_logic_vector(widthdist-1 downto 0);
		overflow	:	out std_logic;
		result	:	out std_logic_vector(width-1 downto 0);
		underflow	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- alt4gxb parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component alt4gxb
	generic (
		advanced_calibration_clocking	:	string := "false";
		base_data_rate	:	string := "UNUSED";
		clk_div_use_vco_bypass	:	string := "false";
		cmu_clk_div_use_coreclk_out_post_divider	:	string := "false";
		cmu_offset_all_errors_align	:	string := "false";
		cmu_pll1_inclk_log_index	:	natural := 0;
		cmu_pll1_log_index	:	natural := 0;
		cmu_pll2_inclk_log_index	:	natural := 0;
		cmu_pll2_log_index	:	natural := 0;
		cmu_pll3_inclk_log_index	:	natural := 0;
		cmu_pll3_log_index	:	natural := 0;
		cmu_pll_inclk_log_index	:	natural := 0;
		cmu_pll_log_index	:	natural := 0;
		cmu_pll_reconfig_inclk_log_index	:	natural := 0;
		cmu_pll_reconfig_log_index	:	natural := 0;
		coreclkout_control_width	:	natural := 1;
		intended_device_family	:	string := "unused";
		effective_data_rate	:	string := "UNUSED";
		elec_idle_infer_enable	:	string := "false";
		enable_0ppm	:	string := "false";
		enable_lc_tx_pll	:	string := "false";
		enable_pcie_gen2_reset	:	string := "false";
		enable_pcie_gen2_x8_es	:	string := "false";
		enable_pll_cascade	:	string := "false";
		enable_pll_inclk_drive_rx_cru	:	string := "false";
		enable_pma_direct	:	string := "false";
		enable_pma_xn_bonding	:	string := "false";
		enable_stratixiv_rx_equalization	:	string := "false";
		equalizer_ctrl_a_setting	:	natural := 7;
		equalizer_ctrl_b_setting	:	natural := 7;
		equalizer_ctrl_c_setting	:	natural := 7;
		equalizer_ctrl_d_setting	:	natural := 7;
		equalizer_ctrl_v_setting	:	natural := 7;
		equalizer_dcgain_setting	:	natural := 0;
		gen_reconfig_pll	:	string := "false";
		gx_channel_type	:	string := "auto";
		gxb_analog_power	:	string := "AUTO";
		gxb_powerdown_width	:	natural := 1;
		hip_enable	:	string := "false";
		input_clock_frequency	:	string := "UNUSED";
		intended_device_speed_grade	:	string := "UNUSED";
		intended_device_variant	:	string := "UNUSED";
		loopback_mode	:	string := "none";
		number_of_channels	:	natural := 1;
		number_of_quads	:	natural := 1;
		operation_mode	:	string := "duplex";
		pcie_sw_width	:	natural := 1;
		pll1_control_width	:	natural := 1;
		pll2_control_width	:	natural := 1;
		pll3_control_width	:	natural := 1;
		pll_control_width	:	natural := 1;
		pll_pfd_fb_mode	:	string := "internal";
		preemphasis_ctrl_1stposttap_setting	:	natural := 0;
		preemphasis_ctrl_2ndposttap_inv_setting	:	string := "false";
		preemphasis_ctrl_2ndposttap_setting	:	natural := 0;
		preemphasis_ctrl_pretap_inv_setting	:	string := "false";
		preemphasis_ctrl_pretap_setting	:	natural := 0;
		protocol	:	string := "basic";
		rateswitch_control_width	:	natural := 1;
		receiver_termination	:	string := "OCT_100_OHMS";
		reconfig_base_data_rate	:	string := "UNUSED";
		reconfig_calibration	:	string := "false";
		reconfig_dprio_mode	:	natural := 0;
		reconfig_fromgxb_port_width	:	natural := 1;
		reconfig_input_clock_frequency	:	string := "UNUSED";
		reconfig_pll_inclk_width	:	natural := 1;
		reconfig_protocol	:	string := "basic";
		reconfig_togxb_port_width	:	natural := 3;
		rx_0ppm_core_clock	:	string := "false";
		rx_8b_10b_compatibility_mode	:	string := "true";
		rx_8b_10b_mode	:	string := "none";
		rx_adaptive_equalization_mode	:	string := "none";
		rx_align_loss_sync_error_num	:	natural := 1;
		rx_align_pattern	:	string := "0000000000";
		rx_align_pattern_length	:	natural := 10;
		rx_align_to_deskew_pattern_pos_disp_only	:	string := "false";
		rx_allow_align_polarity_inversion	:	string := "false";
		rx_allow_pipe_polarity_inversion	:	string := "false";
		rx_bitslip_enable	:	string := "false";
		rx_byte_order_pad_pattern	:	string := "0";
		rx_byte_order_pattern	:	string := "0";
		rx_byte_order_pld_ctrl_enable	:	string := "false";
		rx_byte_ordering_mode	:	string := "none";
		rx_cdrctrl_enable	:	string := "false";
		rx_channel_bonding	:	string := "indv";
		rx_channel_width	:	natural := 8;
		rx_common_mode	:	string := "0.82v";
		rx_cru_bandwidth_type	:	string := "auto";
		rx_cru_inclk_log_index	:	natural := 0;
		rx_cru_inclock0_period	:	natural := 5000;
		rx_cru_inclock1_period	:	natural := 5000;
		rx_cru_inclock2_period	:	natural := 5000;
		rx_cru_inclock3_period	:	natural := 5000;
		rx_cru_inclock4_period	:	natural := 5000;
		rx_cru_inclock5_period	:	natural := 5000;
		rx_cru_inclock6_period	:	natural := 5000;
		rx_cru_inclock7_period	:	natural := 5000;
		rx_cru_inclock8_period	:	natural := 5000;
		rx_cru_inclock9_period	:	natural := 5000;
		rx_cru_m_divider	:	natural := 0;
		rx_cru_n_divider	:	natural := 1;
		rx_cru_refclk_divide_by	:	natural := 0;
		rx_cru_refclk_divider	:	natural := 0;
		rx_cru_refclk_multiply_by	:	natural := 0;
		rx_cru_use_refclk_pin	:	string := "false";
		rx_cru_vco_post_scale_divider	:	natural := 1;
		rx_custom_deskew_pattern	:	string := "false";
		rx_data_rate	:	natural := 1000;
		rx_data_rate_remainder	:	natural := 0;
		rx_dataoutfull_width	:	natural := 64;
		rx_datapath_low_latency_mode	:	string := "false";
		rx_datapath_protocol	:	string := "basic";
		rx_deskew_pattern	:	string := "0";
		rx_digitalreset_port_width	:	natural := 1;
		rx_disable_auto_idle_insertion	:	string := "false";
		rx_disable_running_disp_in_word_align	:	string := "false";
		rx_dprio_mode	:	string := "none";
		rx_dwidth_factor	:	natural := 2;
		rx_enable_bit_reversal	:	string := "false";
		rx_enable_dc_coupling	:	string := "false";
		rx_enable_deep_align_byte_swap	:	string := "false";
		rx_enable_lock_to_data_sig	:	string := "false";
		rx_enable_lock_to_refclk_sig	:	string := "false";
		rx_enable_self_test_mode	:	string := "false";
		rx_enable_true_complement_match_in_word_align	:	string := "false";
		rx_eyemonitor_bandwidth	:	natural := 0;
		rx_flip_rx_out	:	string := "false";
		rx_force_freq_det_high	:	string := "false";
		rx_force_freq_det_low	:	string := "false";
		rx_force_signal_detect	:	string := "false";
		rx_force_signal_detect_dig	:	string := "true";
		rx_ignore_lock_detect	:	string := "false";
		rx_infiniband_invalid_code	:	natural := 0;
		rx_insert_pad_on_underflow	:	string := "false";
		rx_num_align_code_groups_in_ordered_set	:	natural := 0;
		rx_num_align_cons_good_data	:	natural := 1;
		rx_num_align_cons_pat	:	natural := 1;
		rx_phfiforegmode	:	string := "false";
		rx_pll_fast_lock_control	:	string := "false";
		rx_pll_sim_clkout_phase_shift	:	natural := 0;
		rx_ppmselect	:	natural := 32;
		rx_rate_match_almost_empty_threshold	:	natural := 11;
		rx_rate_match_almost_full_threshold	:	natural := 13;
		rx_rate_match_back_to_back	:	string := "false";
		rx_rate_match_delete_threshold	:	natural := 0;
		rx_rate_match_empty_threshold	:	natural := 0;
		rx_rate_match_fifo_mode	:	string := "none";
		rx_rate_match_fifo_mode_manual_control	:	string := "normal";
		rx_rate_match_full_threshold	:	natural := 0;
		rx_rate_match_insert_threshold	:	natural := 0;
		rx_rate_match_ordered_set_based	:	string := "false";
		rx_rate_match_pattern1	:	string := "0";
		rx_rate_match_pattern2	:	string := "0";
		rx_rate_match_pattern_size	:	natural := 10;
		rx_rate_match_reset_enable	:	string := "false";
		rx_rate_match_skip_set_based	:	string := "false";
		rx_rate_match_start_threshold	:	natural := 0;
		rx_reconfig_clk_scheme	:	string := "tx_clk_to_rx";
		rx_run_length	:	natural := 40;
		rx_run_length_enable	:	string := "true";
		rx_self_test_mode	:	string := "incremental";
		rx_signal_detect_loss_threshold	:	natural := 0;
		rx_signal_detect_threshold	:	natural := 0;
		rx_signal_detect_valid_threshold	:	natural := 0;
		rx_use_align_state_machine	:	string := "false";
		rx_use_clkout	:	string := "true";
		rx_use_coreclk	:	string := "false";
		rx_use_cruclk	:	string := "false";
		rx_use_deserializer_double_data_mode	:	string := "false";
		rx_use_deskew_fifo	:	string := "false";
		rx_use_double_data_mode	:	string := "false";
		rx_use_external_termination	:	string := "false";
		rx_use_pipe8b10binvpolarity	:	string := "false";
		rx_use_rate_match_pattern1_only	:	string := "false";
		rx_use_rising_edge_triggered_pattern_align	:	string := "false";
		rx_word_aligner_num_byte	:	natural := 1;
		sim_dump_dprio_internal_reg_at_time	:	natural := 0;
		sim_dump_filename	:	string := "sim_dprio_dump.txt";
		starting_channel_number	:	natural := 0;
		transmitter_termination	:	string := "OCT_100_OHMS";
		tx_0ppm_core_clock	:	string := "false";
		tx_8b_10b_compatibility_mode	:	string := "true";
		tx_8b_10b_mode	:	string := "none";
		tx_allow_polarity_inversion	:	string := "false";
		tx_analog_power	:	string := "auto";
		tx_bitslip_enable	:	string := "false";
		tx_channel_bonding	:	string := "indv";
		tx_channel_width	:	natural := 8;
		tx_clkout_width	:	natural := 1;
		tx_common_mode	:	string := "0.65v";
		tx_data_rate	:	natural := 1000;
		tx_data_rate_remainder	:	natural := 0;
		tx_datainfull_width	:	natural := 44;
		tx_datapath_low_latency_mode	:	string := "false";
		tx_digitalreset_port_width	:	natural := 1;
		tx_dprio_mode	:	string := "none";
		tx_dwidth_factor	:	natural := 2;
		tx_elec_idle_delay	:	natural := 3;
		tx_enable_bit_reversal	:	string := "false";
		tx_enable_idle_selection	:	string := "false";
		tx_enable_self_test_mode	:	string := "false";
		tx_enable_symbol_swap	:	string := "false";
		tx_flip_tx_in	:	string := "false";
		tx_force_disparity_mode	:	string := "false";
		tx_force_echar	:	string := "false";
		tx_force_kchar	:	string := "false";
		tx_low_speed_test_select	:	natural := 0;
		tx_phfiforegmode	:	string := "false";
		tx_pll1_bandwidth_type	:	string := "auto";
		tx_pll1_base_data_rate	:	string := "UNUSED";
		tx_pll1_input_clock_frequency	:	string := "UNUSED";
		tx_pll1_m_divider	:	natural := 1;
		tx_pll1_n_divider	:	natural := 1;
		tx_pll1_protocol	:	string := "basic";
		tx_pll1_type	:	string := "CMU";
		tx_pll1_vco_post_scale_divider	:	natural := 1;
		tx_pll2_bandwidth_type	:	string := "auto";
		tx_pll2_base_data_rate	:	string := "UNUSED";
		tx_pll2_input_clock_frequency	:	string := "UNUSED";
		tx_pll2_m_divider	:	natural := 1;
		tx_pll2_n_divider	:	natural := 1;
		tx_pll2_protocol	:	string := "basic";
		tx_pll2_type	:	string := "CMU";
		tx_pll2_vco_post_scale_divider	:	natural := 1;
		tx_pll3_bandwidth_type	:	string := "auto";
		tx_pll3_base_data_rate	:	string := "UNUSED";
		tx_pll3_input_clock_frequency	:	string := "UNUSED";
		tx_pll3_m_divider	:	natural := 1;
		tx_pll3_n_divider	:	natural := 1;
		tx_pll3_protocol	:	string := "basic";
		tx_pll3_type	:	string := "CMU";
		tx_pll3_vco_post_scale_divider	:	natural := 1;
		tx_pll_bandwidth_type	:	string := "auto";
		tx_pll_clock_post_divider	:	natural := 1;
		tx_pll_count	:	natural := 0;
		tx_pll_inclk0_period	:	natural := 5000;
		tx_pll_inclk1_period	:	natural := 5000;
		tx_pll_inclk2_period	:	natural := 5000;
		tx_pll_inclk3_period	:	natural := 5000;
		tx_pll_inclk4_period	:	natural := 5000;
		tx_pll_inclk5_period	:	natural := 5000;
		tx_pll_inclk6_period	:	natural := 5000;
		tx_pll_inclk7_period	:	natural := 5000;
		tx_pll_inclk8_period	:	natural := 5000;
		tx_pll_inclk9_period	:	natural := 5000;
		tx_pll_m_divider	:	natural := 0;
		tx_pll_n_divider	:	natural := 1;
		tx_pll_pfd_clk_select	:	natural := 1;
		tx_pll_refclk_divide_by	:	natural := 0;
		tx_pll_refclk_divider	:	natural := 0;
		tx_pll_refclk_multiply_by	:	natural := 0;
		tx_pll_sim_clkout_phase_shift	:	natural := 0;
		tx_pll_type	:	string := "CMU";
		tx_pll_use_refclk_pin	:	string := "false";
		tx_pll_vco_post_scale_divider	:	natural := 1;
		tx_reconfig_clk_scheme	:	string := "tx_ch0_clk_source";
		tx_reconfig_data_rate	:	natural := 1000;
		tx_reconfig_data_rate_remainder	:	natural := 0;
		tx_reconfig_pll_bandwidth_type	:	string := "auto";
		tx_reconfig_pll_m_divider	:	natural := 1;
		tx_reconfig_pll_n_divider	:	natural := 1;
		tx_reconfig_pll_vco_post_scale_divider	:	natural := 1;
		tx_refclk_divide_by	:	natural := 1;
		tx_self_test_mode	:	string := "incremental";
		tx_slew_rate	:	string := "off";
		tx_transmit_protocol	:	string := "basic";
		tx_use_coreclk	:	string := "false";
		tx_use_double_data_mode	:	string := "false";
		tx_use_external_termination	:	string := "false";
		tx_use_serializer_double_data_mode	:	string := "false";
		use_calibration_block	:	string := "true";
		use_global_clk_divider	:	string := "auto";
		vod_ctrl_setting	:	natural := 0;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "alt4gxb"
	);
	port(
		aeq_fromgxb	:	out std_logic_vector(number_of_quads*4*8-1 downto 0);
		aeq_togxb	:	in std_logic_vector(number_of_quads*4*6-1 downto 0) := (others => '0');
		cal_blk_calibrationstatus	:	out std_logic_vector(4 downto 0);
		cal_blk_clk	:	in std_logic := '0';
		cal_blk_powerdown	:	in std_logic := '0';
		cmu_rateswitchin	:	in std_logic_vector(number_of_quads-1 downto 0) := (others => '0');
		coreclkout	:	out std_logic_vector(coreclkout_control_width-1 downto 0);
		fixedclk	:	in std_logic := '0';
		fixedclk_fast	:	in std_logic_vector(6*number_of_quads-1 downto 0) := (others => '1');
		gxb_powerdown	:	in std_logic_vector(gxb_powerdown_width-1 downto 0) := (others => '0');
		hip_tx_clkout	:	out std_logic_vector(number_of_channels-1 downto 0);
		pcie_sw	:	out std_logic_vector(pcie_sw_width-1 downto 0);
		pipe8b10binvpolarity	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		pipedatavalid	:	out std_logic_vector(number_of_channels-1 downto 0);
		pipeelecidle	:	out std_logic_vector(number_of_channels-1 downto 0);
		pipephydonestatus	:	out std_logic_vector(number_of_channels-1 downto 0);
		pipestatus	:	out std_logic_vector(number_of_channels*3-1 downto 0);
		pll1_locked	:	out std_logic_vector(pll1_control_width-1 downto 0);
		pll1_powerdown	:	in std_logic_vector(pll1_control_width-1 downto 0) := (others => '0');
		pll2_locked	:	out std_logic_vector(pll2_control_width-1 downto 0);
		pll2_powerdown	:	in std_logic_vector(pll2_control_width-1 downto 0) := (others => '0');
		pll3_locked	:	out std_logic_vector(pll3_control_width-1 downto 0);
		pll3_powerdown	:	in std_logic_vector(pll3_control_width-1 downto 0) := (others => '0');
		pll_inclk	:	in std_logic := '0';
		pll_inclk_rx_cruclk	:	in std_logic_vector(reconfig_pll_inclk_width-1 downto 0) := (others => '0');
		pll_inclk_slave	:	in std_logic := '0';
		pll_locked	:	out std_logic_vector(pll_control_width-1 downto 0);
		pll_locked_alt	:	out std_logic_vector(pll_control_width-1 downto 0);
		pll_powerdown	:	in std_logic_vector(pll_control_width-1 downto 0) := (others => '0');
		pll_powerdown_alt	:	in std_logic_vector(pll_control_width-1 downto 0) := (others => '0');
		powerdn	:	in std_logic_vector(number_of_channels*2-1 downto 0) := (others => '0');
		rateswitch	:	in std_logic_vector(rateswitch_control_width-1 downto 0) := (others => '0');
		rateswitchbaseclock	:	out std_logic_vector(number_of_quads-1 downto 0);
		reconfig_clk	:	in std_logic := '0';
		reconfig_fromgxb	:	out std_logic_vector(reconfig_fromgxb_port_width-1 downto 0);
		reconfig_fromgxb_oe	:	out std_logic_vector(number_of_quads-1 downto 0);
		reconfig_togxb	:	in std_logic_vector(reconfig_togxb_port_width-1 downto 0) := (others => '0');
		rx_a1a2size	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_a1a2sizeout	:	out std_logic_vector(number_of_channels*rx_dwidth_factor-1 downto 0);
		rx_a1detect	:	out std_logic_vector(number_of_channels*rx_word_aligner_num_byte-1 downto 0);
		rx_a2detect	:	out std_logic_vector(number_of_channels*rx_word_aligner_num_byte-1 downto 0);
		rx_analogreset	:	in std_logic_vector(rx_digitalreset_port_width-1 downto 0) := (others => '0');
		rx_bistdone	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_bisterr	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_bitslip	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_bitslipboundaryselectout	:	out std_logic_vector(number_of_channels*5-1 downto 0);
		rx_byteorderalignstatus	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_channelaligned	:	out std_logic_vector(number_of_quads-1 downto 0);
		rx_clkout	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_coreclk	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_cruclk	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_ctrldetect	:	out std_logic_vector(number_of_channels*rx_dwidth_factor-1 downto 0);
		rx_datain	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_dataout	:	out std_logic_vector(rx_channel_width*number_of_channels-1 downto 0);
		rx_dataoutfull	:	out std_logic_vector(rx_dataoutfull_width*number_of_channels-1 downto 0);
		rx_digitalreset	:	in std_logic_vector(rx_digitalreset_port_width-1 downto 0) := (others => '0');
		rx_disperr	:	out std_logic_vector(number_of_channels*rx_dwidth_factor-1 downto 0);
		rx_elecidleinfersel	:	in std_logic_vector(number_of_channels*3-1 downto 0) := (others => '0');
		rx_enabyteord	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_enapatternalign	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_errdetect	:	out std_logic_vector(number_of_channels*rx_dwidth_factor-1 downto 0);
		rx_freqlocked	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_invpolarity	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_k1detect	:	out std_logic_vector(number_of_channels*rx_word_aligner_num_byte-1 downto 0);
		rx_k2detect	:	out std_logic_vector(number_of_channels*2-1 downto 0);
		rx_locktodata	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_locktorefclk	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_patterndetect	:	out std_logic_vector(number_of_channels*rx_dwidth_factor-1 downto 0);
		rx_phase_comp_fifo_error	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_phfifooverflow	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_phfifordenable	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '1');
		rx_phfiforeset	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_phfifounderflow	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_phfifowrdisable	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_pipebufferstat	:	out std_logic_vector(number_of_channels*4-1 downto 0);
		rx_pll_locked	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_powerdown	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_prbscidenable	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_recovclkout	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_revbitorderwa	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_revbyteorderwa	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_revseriallpbkout	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_rlv	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_rmfifoalmostempty	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_rmfifoalmostfull	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_rmfifodatadeleted	:	out std_logic_vector(number_of_channels*rx_dwidth_factor-1 downto 0);
		rx_rmfifodatainserted	:	out std_logic_vector(number_of_channels*rx_dwidth_factor-1 downto 0);
		rx_rmfifoempty	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_rmfifofull	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_rmfifordena	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_rmfiforeset	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_rmfifowrena	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_runningdisp	:	out std_logic_vector(number_of_channels*rx_dwidth_factor-1 downto 0);
		rx_seriallpbken	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_seriallpbkin	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_signaldetect	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_syncstatus	:	out std_logic_vector(number_of_channels*rx_dwidth_factor-1 downto 0);
		scanclk	:	in std_logic := '0';
		scanin	:	in std_logic_vector(22 downto 0) := (others => '0');
		scanmode	:	in std_logic := '0';
		scanshift	:	in std_logic := '0';
		testin	:	in std_logic_vector(999 downto 0) := (others => '0');
		tx_bitslipboundaryselect	:	in std_logic_vector(number_of_channels*5-1 downto 0) := (others => '0');
		tx_clkout	:	out std_logic_vector(tx_clkout_width-1 downto 0);
		tx_coreclk	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		tx_ctrlenable	:	in std_logic_vector(number_of_channels*tx_dwidth_factor-1 downto 0) := (others => '0');
		tx_datain	:	in std_logic_vector(tx_channel_width*number_of_channels-1 downto 0) := (others => '0');
		tx_datainfull	:	in std_logic_vector(tx_datainfull_width*number_of_channels-1 downto 0) := (others => '0');
		tx_dataout	:	out std_logic_vector(number_of_channels-1 downto 0);
		tx_detectrxloop	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		tx_digitalreset	:	in std_logic_vector(tx_digitalreset_port_width-1 downto 0) := (others => '0');
		tx_dispval	:	in std_logic_vector(number_of_channels*tx_dwidth_factor-1 downto 0) := (others => '0');
		tx_forcedisp	:	in std_logic_vector(number_of_channels*tx_dwidth_factor-1 downto 0) := (others => '0');
		tx_forcedispcompliance	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		tx_forceelecidle	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		tx_invpolarity	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		tx_phase_comp_fifo_error	:	out std_logic_vector(number_of_channels-1 downto 0);
		tx_phfifooverflow	:	out std_logic_vector(number_of_channels-1 downto 0);
		tx_phfiforeset	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		tx_phfifounderflow	:	out std_logic_vector(number_of_channels-1 downto 0);
		tx_pipedeemph	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		tx_pipemargin	:	in std_logic_vector(number_of_channels*3-1 downto 0) := (others => '0');
		tx_pipeswing	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		tx_pllreset	:	in std_logic := '0';
		tx_revparallellpbken	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		tx_revseriallpbkin	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		tx_seriallpbkout	:	out std_logic_vector(number_of_channels-1 downto 0)
	);
end component;

------------------------------------------------------------------
-- altremote_update parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altremote_update
	generic (
		check_app_pof	:	string := "false";
		intended_device_family	:	string := "unused";
		in_data_width	:	natural := 12;
		operation_mode	:	string := "remote";
		out_data_width	:	natural := 12;
		sim_init_config	:	string := "factory";
		sim_init_page_select	:	natural := 0;
		sim_init_status	:	natural := 0;
		sim_init_watchdog_value	:	natural := 0;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altremote_update"
	);
	port(
		asmi_addr	:	out std_logic_vector(23 downto 0);
		asmi_busy	:	in std_logic := '0';
		asmi_data_valid	:	in std_logic := '0';
		asmi_dataout	:	in std_logic_vector(7 downto 0) := (others => '0');
		asmi_rden	:	out std_logic;
		asmi_read	:	out std_logic;
		busy	:	out std_logic;
		clock	:	in std_logic;
		data_in	:	in std_logic_vector(in_data_width-1 downto 0) := (others => '0');
		data_out	:	out std_logic_vector(out_data_width-1 downto 0);
		param	:	in std_logic_vector(2 downto 0) := (others => '0');
		pgmout	:	out std_logic_vector(2 downto 0);
		pof_error	:	out std_logic;
		read_param	:	in std_logic := '0';
		read_source	:	in std_logic_vector(1 downto 0) := (others => '0');
		reconfig	:	in std_logic := '0';
		reset	:	in std_logic;
		reset_timer	:	in std_logic := '0';
		write_param	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- altecc_decoder parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altecc_decoder
	generic (
		intended_device_family	:	string := "unused";
		lpm_pipeline	:	natural := 0;
		width_codeword	:	natural := 8;
		width_dataword	:	natural := 8;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altecc_decoder"
	);
	port(
		aclr	:	in std_logic := '0';
		clock	:	in std_logic := '0';
		clocken	:	in std_logic := '1';
		data	:	in std_logic_vector(width_codeword-1 downto 0);
		err_corrected	:	out std_logic;
		err_detected	:	out std_logic;
		err_fatal	:	out std_logic;
		q	:	out std_logic_vector(width_dataword-1 downto 0);
		syn_e	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- altotp parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altotp
	generic (
		intended_device_family	:	string := "unused";
		init_data	:	string;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altotp"
	);
	port(
		otp_clk	:	in std_logic;
		otp_clken	:	in std_logic := '1';
		otp_dout	:	out std_logic;
		otp_shiftnld	:	in std_logic
	);
end component;

------------------------------------------------------------------
-- altfp_add_sub parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altfp_add_sub
	generic (
		denormal_support	:	string := "YES";
		intended_device_family	:	string := "unused";
		direction	:	string := "ADD";
		exception_handling	:	string := "YES";
		optimize	:	string := "SPEED";
		pipeline	:	natural := 11;
		reduced_functionality	:	string := "NO";
		rounding	:	string := "TO_NEAREST";
		speed_optimized	:	string := "STRATIX_ONLY";
		width_exp	:	natural := 8;
		width_man	:	natural := 23;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altfp_add_sub"
	);
	port(
		aclr	:	in std_logic := '0';
		add_sub	:	in std_logic := '1';
		clk_en	:	in std_logic := '1';
		clock	:	in std_logic;
		dataa	:	in std_logic_vector(width_exp+width_man+1-1 downto 0);
		datab	:	in std_logic_vector(width_exp+width_man+1-1 downto 0);
		denormal	:	out std_logic;
		indefinite	:	out std_logic;
		nan	:	out std_logic;
		overflow	:	out std_logic;
		result	:	out std_logic_vector(width_exp+width_man+1-1 downto 0);
		underflow	:	out std_logic;
		zero	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- altfp_atan parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altfp_atan
	generic (
		intended_device_family	:	string := "unused";
		pipeline	:	natural := 34;
		rounding	:	string := "TO_NEAREST";
		width_exp	:	natural := 8;
		width_man	:	natural := 23;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altfp_atan"
	);
	port(
		aclr	:	in std_logic := '0';
		clk_en	:	in std_logic := '1';
		clock	:	in std_logic := '0';
		data	:	in std_logic_vector(width_exp+width_man+1-1 downto 0) := (others => '0');
		result	:	out std_logic_vector(width_exp+width_man+1-1 downto 0)
	);
end component;

------------------------------------------------------------------
-- altddio_out parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altddio_out
	generic (
		intended_device_family	:	string := "unused";
		extend_oe_disable	:	string := "OFF";
		invert_output	:	string := "OFF";
		oe_reg	:	string := "UNREGISTERED";
		power_up_high	:	string := "OFF";
		width	:	natural;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altddio_out"
	);
	port(
		aclr	:	in std_logic := '0';
		aset	:	in std_logic := '0';
		datain_h	:	in std_logic_vector(width-1 downto 0);
		datain_l	:	in std_logic_vector(width-1 downto 0);
		dataout	:	out std_logic_vector(width-1 downto 0);
		oe	:	in std_logic := '1';
		oe_out	:	out std_logic_vector(width-1 downto 0);
		outclock	:	in std_logic;
		outclocken	:	in std_logic := '1';
		sclr	:	in std_logic := '0';
		sset	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- a_graycounter parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component a_graycounter
	generic (
		intended_device_family	:	string := "unused";
		pvalue	:	natural := 0;
		width	:	natural := 8;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "a_graycounter"
	);
	port(
		aclr	:	in std_logic := '0';
		clk_en	:	in std_logic := '1';
		clock	:	in std_logic;
		cnt_en	:	in std_logic := '1';
		q	:	out std_logic_vector(width-1 downto 0);
		qbin	:	out std_logic_vector(width-1 downto 0);
		sclr	:	in std_logic := '0';
		updown	:	in std_logic := '1'
	);
end component;

------------------------------------------------------------------
-- altasmi_parallel parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altasmi_parallel
	generic (
		data_width	:	string := "STANDARD";
		intended_device_family	:	string := "unused";
		epcs_type	:	string := "EPCS4";
		page_size	:	natural := 1;
		port_bulk_erase	:	string := "PORT_UNUSED";
		port_die_erase	:	string := "PORT_UNUSED";
		port_en4b_addr	:	string := "PORT_UNUSED";
		port_fast_read	:	string := "PORT_UNUSED";
		port_illegal_erase	:	string := "PORT_UNUSED";
		port_illegal_write	:	string := "PORT_UNUSED";
		port_rdid_out	:	string := "PORT_UNUSED";
		port_read_address	:	string := "PORT_UNUSED";
		port_read_dummyclk	:	string := "PORT_UNUSED";
		port_read_rdid	:	string := "PORT_UNUSED";
		port_read_sid	:	string := "PORT_UNUSED";
		port_read_status	:	string := "PORT_UNUSED";
		port_sector_erase	:	string := "PORT_UNUSED";
		port_sector_protect	:	string := "PORT_UNUSED";
		port_shift_bytes	:	string := "PORT_UNUSED";
		port_wren	:	string := "PORT_UNUSED";
		port_write	:	string := "PORT_UNUSED";
		use_asmiblock	:	string := "ON";
		use_eab	:	string := "ON";
		write_dummy_clk	:	natural := 0;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altasmi_parallel"
	);
	port(
		addr	:	in std_logic_vector(23 downto 0);
		asmi_dataoe	:	out std_logic_vector(3 downto 0);
		asmi_dataout	:	in std_logic_vector(3 downto 0) := (others => '0');
		asmi_dclk	:	out std_logic;
		asmi_scein	:	out std_logic;
		asmi_sdoin	:	out std_logic_vector(3 downto 0);
		bulk_erase	:	in std_logic := '0';
		busy	:	out std_logic;
		clkin	:	in std_logic;
		data_valid	:	out std_logic;
		datain	:	in std_logic_vector(7 downto 0) := (others => '0');
		dataout	:	out std_logic_vector(7 downto 0);
		die_erase	:	in std_logic := '0';
		en4b_addr	:	in std_logic := '0';
		epcs_id	:	out std_logic_vector(7 downto 0);
		fast_read	:	in std_logic := '0';
		illegal_erase	:	out std_logic;
		illegal_write	:	out std_logic;
		rden	:	in std_logic;
		rdid_out	:	out std_logic_vector(7 downto 0);
		read	:	in std_logic := '0';
		read_address	:	out std_logic_vector(23 downto 0);
		read_dummyclk	:	in std_logic := '0';
		read_rdid	:	in std_logic := '0';
		read_sid	:	in std_logic := '0';
		read_status	:	in std_logic := '0';
		reset	:	in std_logic := '0';
		sector_erase	:	in std_logic := '0';
		sector_protect	:	in std_logic := '0';
		shift_bytes	:	in std_logic := '0';
		status_out	:	out std_logic_vector(7 downto 0);
		wren	:	in std_logic := '1';
		write	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- altmult_complex parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altmult_complex
	generic (
		intended_device_family	:	string := "unused";
		implementation_style	:	string := "AUTO";
		pipeline	:	natural := 4;
		representation_a	:	string := "SIGNED";
		representation_b	:	string := "SIGNED";
		width_a	:	natural;
		width_b	:	natural;
		width_result	:	natural;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altmult_complex"
	);
	port(
		aclr	:	in std_logic := '0';
		clock	:	in std_logic := '0';
		complex	:	in std_logic := '1';
		dataa_imag	:	in std_logic_vector(width_a-1 downto 0);
		dataa_real	:	in std_logic_vector(width_a-1 downto 0);
		datab_imag	:	in std_logic_vector(width_b-1 downto 0);
		datab_real	:	in std_logic_vector(width_b-1 downto 0);
		ena	:	in std_logic := '1';
		result_imag	:	out std_logic_vector(width_result-1 downto 0);
		result_real	:	out std_logic_vector(width_result-1 downto 0)
	);
end component;

------------------------------------------------------------------
-- altserial_flash_loader parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component altserial_flash_loader
	generic (
		enable_quad_spi_support	:	natural := 0;
		enable_shared_access	:	string := "OFF";
		enhanced_mode	:	natural := 0;
		intended_device_family	:	string := "Cyclone";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altserial_flash_loader"	);
	port(
		asmi_access_granted	:	in std_logic := '1';
		asmi_access_request	:	out std_logic;
		data0out	:	out std_logic;
		data_in	:	in std_logic_vector(3 downto 0) := (others => '0');
		data_oe	:	in std_logic_vector(3 downto 0) := (others => '0');
		data_out	:	out std_logic_vector(3 downto 0);
		dclkin	:	in std_logic := '0';
		noe	:	in std_logic := '0';
		scein	:	in std_logic := '0';
		sdoin	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- altfp_matrix_mult parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altfp_matrix_mult
	generic (
		blocks	:	natural := 0;
		cluster	:	natural := 16;
		columnsaa	:	natural := 0;
		columnsbb	:	natural := 0;
		intended_device_family	:	string := "unused";
		rowsaa	:	natural := 0;
		vectorsize	:	natural := 0;
		width_exp	:	natural := 8;
		width_man	:	natural := 23;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altfp_matrix_mult"
	);
	port(
		calcmatrix	:	in std_logic := '0';
		done	:	out std_logic;
		enable	:	in std_logic := '1';
		loadaa	:	in std_logic := '0';
		loadbb	:	in std_logic := '0';
		loaddata	:	in std_logic_vector(width_exp+width_man+1-1 downto 0) := (others => '0');
		loaddataimag	:	in std_logic_vector(width_exp+width_man+1-1 downto 0) := (others => '0');
		loaddatareal	:	in std_logic_vector(width_exp+width_man+1-1 downto 0) := (others => '0');
		outdata	:	out std_logic_vector(width_exp+width_man+1-1 downto 0);
		outdataimag	:	out std_logic_vector(width_exp+width_man+1-1 downto 0);
		outdatareal	:	out std_logic_vector(width_exp+width_man+1-1 downto 0);
		outvalid	:	out std_logic;
		ready	:	out std_logic;
		reset	:	in std_logic := '0';
		result	:	out std_logic_vector(width_exp+width_man+1-1 downto 0);
		selbus	:	in std_logic := '0';
		sysclk	:	in std_logic;
		vector_l_data	:	in std_logic_vector(255 downto 0) := (others => '0');
		vector_m_data	:	in std_logic_vector(255 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- altstratixii_oct parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component altstratixii_oct
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altstratixii_oct"	);
	port(
		rdn	:	in std_logic;
		rup	:	in std_logic;
		terminationclock	:	in std_logic;
		terminationenable	:	in std_logic
	);
end component;

------------------------------------------------------------------
-- altpriority_encoder parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altpriority_encoder
	generic (
		lsb_priority	:	string := "NO";
		pipeline	:	natural := 0;
		width	:	natural;
		widthad	:	natural;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altpriority_encoder"
	);
	port(
		aclr	:	in std_logic := '0';
		clk_en	:	in std_logic := '1';
		clock	:	in std_logic := '0';
		data	:	in std_logic_vector(width-1 downto 0);
		q	:	out std_logic_vector(widthad-1 downto 0);
		zero	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- altdll parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altdll
	generic (
		delay_buffer_mode	:	string := "low";
		delay_chain_length	:	natural := 8;
		delayctrlout_width	:	natural := 6;
		intended_device_family	:	string := "unused";
		dll_offset_ctrl_a_static_offset	:	string := "unused";
		dll_offset_ctrl_a_use_offset	:	string := "false";
		dll_offset_ctrl_b_static_offset	:	string := "unused";
		dll_offset_ctrl_b_use_offset	:	string := "false";
		input_frequency	:	string := "unused";
		jitter_reduction	:	string := "false";
		use_dll_offset_ctrl_a	:	string := "false";
		use_dll_offset_ctrl_b	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altdll"
	);
	port(
		dll_aload	:	in std_logic := '0';
		dll_clk	:	in std_logic_vector(0 downto 0);
		dll_delayctrlout	:	out std_logic_vector(delayctrlout_width-1 downto 0);
		dll_dqsupdate	:	out std_logic;
		dll_offset_ctrl_a_addnsub	:	in std_logic := '1';
		dll_offset_ctrl_a_offset	:	in std_logic_vector(delayctrlout_width-1 downto 0) := (others => '0');
		dll_offset_ctrl_a_offsetctrlout	:	out std_logic_vector(delayctrlout_width-1 downto 0);
		dll_offset_ctrl_b_addnsub	:	in std_logic := '1';
		dll_offset_ctrl_b_offset	:	in std_logic_vector(delayctrlout_width-1 downto 0) := (others => '0');
		dll_offset_ctrl_b_offsetctrlout	:	out std_logic_vector(delayctrlout_width-1 downto 0)
	);
end component;

------------------------------------------------------------------
-- altiobuf_out parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altiobuf_out
	generic (
		intended_device_family	:	string := "unused";
		enable_bus_hold	:	string := "FALSE";
		left_shift_series_termination_control	:	string := "FALSE";
		number_of_channels	:	natural;
		open_drain_output	:	string := "FALSE";
		pseudo_differential_mode	:	string := "FALSE";
		use_differential_mode	:	string := "FALSE";
		use_oe	:	string := "FALSE";
		use_out_dynamic_delay_chain1	:	string := "FALSE";
		use_out_dynamic_delay_chain2	:	string := "FALSE";
		use_termination_control	:	string := "FALSE";
		width_ptc	:	natural := 14;
		width_stc	:	natural := 14;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altiobuf_out"
	);
	port(
		datain	:	in std_logic_vector(number_of_channels-1 downto 0);
		dataout	:	out std_logic_vector(number_of_channels-1 downto 0);
		dataout_b	:	out std_logic_vector(number_of_channels-1 downto 0);
		io_config_clk	:	in std_logic := '0';
		io_config_clkena	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		io_config_datain	:	in std_logic := '0';
		io_config_update	:	in std_logic := '0';
		oe	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '1');
		oe_b	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '1');
		parallelterminationcontrol	:	in std_logic_vector(width_ptc * number_of_channels-1 downto 0) := (others => '0');
		parallelterminationcontrol_b	:	in std_logic_vector(width_ptc * number_of_channels-1 downto 0) := (others => '0');
		seriesterminationcontrol	:	in std_logic_vector(width_stc * number_of_channels-1 downto 0) := (others => '0');
		seriesterminationcontrol_b	:	in std_logic_vector(width_stc * number_of_channels-1 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- altera_std_synchronizer_bundle parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component altera_std_synchronizer_bundle
	generic (
		depth	:	natural := 3;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altera_std_synchronizer_bundle";
		width	:	natural := 1	);
	port(
		clk	:	in std_logic;
		din	:	in std_logic_vector(width-1 downto 0);
		dout	:	out std_logic_vector(width-1 downto 0);
		reset_n	:	in std_logic
	);
end component;

------------------------------------------------------------------
-- altddio_bidir parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altddio_bidir
	generic (
		intended_device_family	:	string := "unused";
		extend_oe_disable	:	string := "OFF";
		implement_input_in_lcell	:	string := "OFF";
		invert_output	:	string := "OFF";
		oe_reg	:	string := "UNREGISTERED";
		power_up_high	:	string := "OFF";
		width	:	natural;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altddio_bidir"
	);
	port(
		aclr	:	in std_logic := '0';
		aset	:	in std_logic := '0';
		combout	:	out std_logic_vector(width-1 downto 0);
		datain_h	:	in std_logic_vector(width-1 downto 0);
		datain_l	:	in std_logic_vector(width-1 downto 0);
		dataout_h	:	out std_logic_vector(width-1 downto 0);
		dataout_l	:	out std_logic_vector(width-1 downto 0);
		dqsundelayedout	:	out std_logic_vector(width-1 downto 0);
		inclock	:	in std_logic := '0';
		inclocken	:	in std_logic := '1';
		oe	:	in std_logic := '1';
		oe_out	:	out std_logic_vector(width-1 downto 0);
		outclock	:	in std_logic := '0';
		outclocken	:	in std_logic := '1';
		padio	:	inout std_logic_vector(width-1 downto 0);
		sclr	:	in std_logic := '0';
		sset	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- altmult_add parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altmult_add
	generic (
		accum_direction	:	string := "ADD";
		accum_sload_aclr	:	string := "ACLR0";
		accum_sload_pipeline_aclr	:	string := "ACLR0";
		accum_sload_pipeline_register	:	string := "CLOCK0";
		accum_sload_register	:	string := "CLOCK0";
		accumulator	:	string := "NO";
		adder1_rounding	:	string := "NO";
		adder3_rounding	:	string := "NO";
		addnsub1_round_aclr	:	string := "ACLR0";
		addnsub1_round_pipeline_aclr	:	string := "ACLR0";
		addnsub1_round_pipeline_register	:	string := "CLOCK0";
		addnsub1_round_register	:	string := "CLOCK0";
		addnsub3_round_aclr	:	string := "ACLR0";
		addnsub3_round_pipeline_aclr	:	string := "ACLR0";
		addnsub3_round_pipeline_register	:	string := "CLOCK0";
		addnsub3_round_register	:	string := "CLOCK0";
		addnsub_multiplier_aclr1	:	string := "ACLR0";
		addnsub_multiplier_aclr3	:	string := "ACLR0";
		addnsub_multiplier_pipeline_aclr1	:	string := "ACLR0";
		addnsub_multiplier_pipeline_aclr3	:	string := "ACLR0";
		addnsub_multiplier_pipeline_register1	:	string := "CLOCK0";
		addnsub_multiplier_pipeline_register3	:	string := "CLOCK0";
		addnsub_multiplier_register1	:	string := "CLOCK0";
		addnsub_multiplier_register3	:	string := "CLOCK0";
		chainout_aclr	:	string := "ACLR0";
		chainout_adder	:	string := "NO";
		chainout_register	:	string := "CLOCK0";
		chainout_round_aclr	:	string := "ACLR0";
		chainout_round_output_aclr	:	string := "ACLR0";
		chainout_round_output_register	:	string := "CLOCK0";
		chainout_round_pipeline_aclr	:	string := "ACLR0";
		chainout_round_pipeline_register	:	string := "CLOCK0";
		chainout_round_register	:	string := "CLOCK0";
		chainout_rounding	:	string := "NO";
		chainout_saturate_aclr	:	string := "ACLR0";
		chainout_saturate_output_aclr	:	string := "ACLR0";
		chainout_saturate_output_register	:	string := "CLOCK0";
		chainout_saturate_pipeline_aclr	:	string := "ACLR0";
		chainout_saturate_pipeline_register	:	string := "CLOCK0";
		chainout_saturate_register	:	string := "CLOCK0";
		chainout_saturation	:	string := "NO";
		coef0_0	:	natural := 0;
		coef0_1	:	natural := 0;
		coef0_2	:	natural := 0;
		coef0_3	:	natural := 0;
		coef0_4	:	natural := 0;
		coef0_5	:	natural := 0;
		coef0_6	:	natural := 0;
		coef0_7	:	natural := 0;
		coef1_0	:	natural := 0;
		coef1_1	:	natural := 0;
		coef1_2	:	natural := 0;
		coef1_3	:	natural := 0;
		coef1_4	:	natural := 0;
		coef1_5	:	natural := 0;
		coef1_6	:	natural := 0;
		coef1_7	:	natural := 0;
		coef2_0	:	natural := 0;
		coef2_1	:	natural := 0;
		coef2_2	:	natural := 0;
		coef2_3	:	natural := 0;
		coef2_4	:	natural := 0;
		coef2_5	:	natural := 0;
		coef2_6	:	natural := 0;
		coef2_7	:	natural := 0;
		coef3_0	:	natural := 0;
		coef3_1	:	natural := 0;
		coef3_2	:	natural := 0;
		coef3_3	:	natural := 0;
		coef3_4	:	natural := 0;
		coef3_5	:	natural := 0;
		coef3_6	:	natural := 0;
		coef3_7	:	natural := 0;
		coefsel0_aclr	:	string := "ACLR0";
		coefsel0_register	:	string := "CLOCK0";
		coefsel1_aclr	:	string := "ACLR0";
		coefsel1_register	:	string := "CLOCK0";
		coefsel2_aclr	:	string := "ACLR0";
		coefsel2_register	:	string := "CLOCK0";
		coefsel3_aclr	:	string := "ACLR0";
		coefsel3_register	:	string := "CLOCK0";
		dedicated_multiplier_circuitry	:	string := "AUTO";
		intended_device_family	:	string := "unused";
		double_accum	:	string := "NO";
		dsp_block_balancing	:	string := "Auto";
		extra_latency	:	natural := 0;
		input_aclr_a0	:	string := "ACLR0";
		input_aclr_a1	:	string := "ACLR0";
		input_aclr_a2	:	string := "ACLR0";
		input_aclr_a3	:	string := "ACLR0";
		input_aclr_b0	:	string := "ACLR0";
		input_aclr_b1	:	string := "ACLR0";
		input_aclr_b2	:	string := "ACLR0";
		input_aclr_b3	:	string := "ACLR0";
		input_aclr_c0	:	string := "ACLR0";
		input_aclr_c1	:	string := "ACLR0";
		input_aclr_c2	:	string := "ACLR0";
		input_aclr_c3	:	string := "ACLR0";
		input_register_a0	:	string := "CLOCK0";
		input_register_a1	:	string := "CLOCK0";
		input_register_a2	:	string := "CLOCK0";
		input_register_a3	:	string := "CLOCK0";
		input_register_b0	:	string := "CLOCK0";
		input_register_b1	:	string := "CLOCK0";
		input_register_b2	:	string := "CLOCK0";
		input_register_b3	:	string := "CLOCK0";
		input_register_c0	:	string := "CLOCK0";
		input_register_c1	:	string := "CLOCK0";
		input_register_c2	:	string := "CLOCK0";
		input_register_c3	:	string := "CLOCK0";
		input_source_a0	:	string := "DATAA";
		input_source_a1	:	string := "DATAA";
		input_source_a2	:	string := "DATAA";
		input_source_a3	:	string := "DATAA";
		input_source_b0	:	string := "DATAB";
		input_source_b1	:	string := "DATAB";
		input_source_b2	:	string := "DATAB";
		input_source_b3	:	string := "DATAB";
		loadconst_control_aclr	:	string := "ACLR0";
		loadconst_control_register	:	string := "CLOCK0";
		loadconst_value	:	natural := 64;
		mult01_round_aclr	:	string := "ACLR0";
		mult01_round_register	:	string := "CLOCK0";
		mult01_saturation_aclr	:	string := "ACLR1";
		mult01_saturation_register	:	string := "CLOCK0";
		mult23_round_aclr	:	string := "ACLR0";
		mult23_round_register	:	string := "CLOCK0";
		mult23_saturation_aclr	:	string := "ACLR0";
		mult23_saturation_register	:	string := "CLOCK0";
		multiplier01_rounding	:	string := "NO";
		multiplier01_saturation	:	string := "NO";
		multiplier1_direction	:	string := "ADD";
		multiplier23_rounding	:	string := "NO";
		multiplier23_saturation	:	string := "NO";
		multiplier3_direction	:	string := "ADD";
		multiplier_aclr0	:	string := "ACLR0";
		multiplier_aclr1	:	string := "ACLR0";
		multiplier_aclr2	:	string := "ACLR0";
		multiplier_aclr3	:	string := "ACLR0";
		multiplier_register0	:	string := "CLOCK0";
		multiplier_register1	:	string := "CLOCK0";
		multiplier_register2	:	string := "CLOCK0";
		multiplier_register3	:	string := "CLOCK0";
		number_of_multipliers	:	natural;
		output_aclr	:	string := "ACLR0";
		output_register	:	string := "CLOCK0";
		output_round_aclr	:	string := "ACLR0";
		output_round_pipeline_aclr	:	string := "ACLR0";
		output_round_pipeline_register	:	string := "CLOCK0";
		output_round_register	:	string := "CLOCK0";
		output_round_type	:	string := "NEAREST_INTEGER";
		output_rounding	:	string := "NO";
		output_saturate_aclr	:	string := "ACLR0";
		output_saturate_pipeline_aclr	:	string := "ACLR0";
		output_saturate_pipeline_register	:	string := "CLOCK0";
		output_saturate_register	:	string := "CLOCK0";
		output_saturate_type	:	string := "ASYMMETRIC";
		output_saturation	:	string := "NO";
		port_addnsub1	:	string := "PORT_CONNECTIVITY";
		port_addnsub3	:	string := "PORT_CONNECTIVITY";
		port_chainout_sat_is_overflow	:	string := "PORT_UNUSED";
		port_mult0_is_saturated	:	string := "UNUSED";
		port_mult1_is_saturated	:	string := "UNUSED";
		port_mult2_is_saturated	:	string := "UNUSED";
		port_mult3_is_saturated	:	string := "UNUSED";
		port_output_is_overflow	:	string := "PORT_UNUSED";
		port_signa	:	string := "PORT_CONNECTIVITY";
		port_signb	:	string := "PORT_CONNECTIVITY";
		preadder_direction_0	:	string := "ADD";
		preadder_direction_1	:	string := "ADD";
		preadder_direction_2	:	string := "ADD";
		preadder_direction_3	:	string := "ADD";
		preadder_mode	:	string := "SIMPLE";
		representation_a	:	string := "UNSIGNED";
		representation_b	:	string := "UNSIGNED";
		rotate_aclr	:	string := "ACLR0";
		rotate_output_aclr	:	string := "ACLR0";
		rotate_output_register	:	string := "CLOCK0";
		rotate_pipeline_aclr	:	string := "ACLR0";
		rotate_pipeline_register	:	string := "CLOCK0";
		rotate_register	:	string := "CLOCK0";
		scanouta_aclr	:	string := "ACLR0";
		scanouta_register	:	string := "UNREGISTERED";
		shift_mode	:	string := "NO";
		shift_right_aclr	:	string := "ACLR0";
		shift_right_output_aclr	:	string := "ACLR0";
		shift_right_output_register	:	string := "CLOCK0";
		shift_right_pipeline_aclr	:	string := "ACLR0";
		shift_right_pipeline_register	:	string := "CLOCK0";
		shift_right_register	:	string := "CLOCK0";
		signed_aclr_a	:	string := "ACLR0";
		signed_aclr_b	:	string := "ACLR0";
		signed_pipeline_aclr_a	:	string := "ACLR0";
		signed_pipeline_aclr_b	:	string := "ACLR0";
		signed_pipeline_register_a	:	string := "CLOCK0";
		signed_pipeline_register_b	:	string := "CLOCK0";
		signed_register_a	:	string := "CLOCK0";
		signed_register_b	:	string := "CLOCK0";
		systolic_aclr1	:	string := "ACLR0";
		systolic_aclr3	:	string := "ACLR0";
		systolic_delay1	:	string := "UNREGISTERED";
		systolic_delay3	:	string := "UNREGISTERED";
		width_a	:	natural;
		width_b	:	natural;
		width_c	:	natural := 22;
		width_chainin	:	natural := 1;
		width_coef	:	natural := 18;
		width_msb	:	natural := 17;
		width_result	:	natural;
		width_saturate_sign	:	natural := 1;
		zero_chainout_output_aclr	:	string := "ACLR0";
		zero_chainout_output_register	:	string := "CLOCK0";
		zero_loopback_aclr	:	string := "ACLR0";
		zero_loopback_output_aclr	:	string := "ACLR0";
		zero_loopback_output_register	:	string := "CLOCK0";
		zero_loopback_pipeline_aclr	:	string := "ACLR0";
		zero_loopback_pipeline_register	:	string := "CLOCK0";
		zero_loopback_register	:	string := "CLOCK0";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altmult_add"
	);
	port(
		accum_sload	:	in std_logic := '0';
		aclr0	:	in std_logic := '0';
		aclr1	:	in std_logic := '0';
		aclr2	:	in std_logic := '0';
		aclr3	:	in std_logic := '0';
		addnsub1	:	in std_logic := '1';
		addnsub1_round	:	in std_logic := '0';
		addnsub3	:	in std_logic := '1';
		addnsub3_round	:	in std_logic := '0';
		chainin	:	in std_logic_vector(width_chainin-1 downto 0) := (others => '0');
		chainout_round	:	in std_logic := '0';
		chainout_sat_overflow	:	out std_logic;
		chainout_saturate	:	in std_logic := '0';
		clock0	:	in std_logic := '1';
		clock1	:	in std_logic := '1';
		clock2	:	in std_logic := '1';
		clock3	:	in std_logic := '1';
		coefsel0	:	in std_logic_vector(2 downto 0) := (others => '0');
		coefsel1	:	in std_logic_vector(2 downto 0) := (others => '0');
		coefsel2	:	in std_logic_vector(2 downto 0) := (others => '0');
		coefsel3	:	in std_logic_vector(2 downto 0) := (others => '0');
		dataa	:	in std_logic_vector(width_a*number_of_multipliers-1 downto 0) := (others => '0');
		datab	:	in std_logic_vector(width_b*number_of_multipliers-1 downto 0) := (others => '0');
		datac	:	in std_logic_vector(width_c*number_of_multipliers-1 downto 0) := (others => '0');
		ena0	:	in std_logic := '1';
		ena1	:	in std_logic := '1';
		ena2	:	in std_logic := '1';
		ena3	:	in std_logic := '1';
		mult01_round	:	in std_logic := '0';
		mult01_saturation	:	in std_logic := '0';
		mult0_is_saturated	:	out std_logic;
		mult1_is_saturated	:	out std_logic;
		mult23_round	:	in std_logic := '0';
		mult23_saturation	:	in std_logic := '0';
		mult2_is_saturated	:	out std_logic;
		mult3_is_saturated	:	out std_logic;
		output_round	:	in std_logic := '0';
		output_saturate	:	in std_logic := '0';
		overflow	:	out std_logic;
		result	:	out std_logic_vector(width_result-1 downto 0);
		rotate	:	in std_logic := '0';
		scanina	:	in std_logic_vector(width_a-1 downto 0) := (others => '0');
		scaninb	:	in std_logic_vector(width_b-1 downto 0) := (others => '0');
		scanouta	:	out std_logic_vector(width_a-1 downto 0);
		scanoutb	:	out std_logic_vector(width_b-1 downto 0);
		shift_right	:	in std_logic := '0';
		signa	:	in std_logic := '0';
		signb	:	in std_logic := '0';
		sourcea	:	in std_logic_vector(number_of_multipliers-1 downto 0) := (others => '0');
		sourceb	:	in std_logic_vector(number_of_multipliers-1 downto 0) := (others => '0');
		zero_chainout	:	in std_logic := '0';
		zero_loopback	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- altecc_encoder parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altecc_encoder
	generic (
		intended_device_family	:	string := "unused";
		lpm_pipeline	:	natural := 0;
		width_codeword	:	natural := 8;
		width_dataword	:	natural := 8;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altecc_encoder"
	);
	port(
		aclr	:	in std_logic := '0';
		clock	:	in std_logic := '0';
		clocken	:	in std_logic := '1';
		data	:	in std_logic_vector(width_dataword-1 downto 0);
		q	:	out std_logic_vector(width_codeword-1 downto 0)
	);
end component;

------------------------------------------------------------------
-- altdq parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altdq
	generic (
		ddioinclk_input	:	string := "NEGATED_INCLK";
		intended_device_family	:	string := "unused";
		extend_oe_disable	:	string := "OFF";
		invert_input_clocks	:	string := "ON";
		number_of_dq	:	natural;
		oe_reg	:	string := "UNREGISTERED";
		power_up_high	:	string := "OFF";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altdq"
	);
	port(
		aclr	:	in std_logic := '0';
		aset	:	in std_logic := '0';
		datain_h	:	in std_logic_vector(number_of_dq-1 downto 0);
		datain_l	:	in std_logic_vector(number_of_dq-1 downto 0);
		dataout_h	:	out std_logic_vector(number_of_dq-1 downto 0);
		dataout_l	:	out std_logic_vector(number_of_dq-1 downto 0);
		ddioinclk	:	in std_logic := '0';
		inclock	:	in std_logic;
		inclocken	:	in std_logic := '1';
		oe	:	in std_logic := '1';
		outclock	:	in std_logic;
		outclocken	:	in std_logic := '1';
		padio	:	inout std_logic_vector(number_of_dq-1 downto 0)
	);
end component;

------------------------------------------------------------------
-- altera_mult_add parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altera_mult_add
	generic (
		accum_direction	:	string := "ADD";
		accum_sload_aclr	:	string := "NONE";
		accum_sload_pipeline_aclr	:	string := "NONE";
		accum_sload_pipeline_register	:	string := "UNREGISTERED";
		accum_sload_register	:	string := "UNREGISTERED";
		accumulator	:	string := "NO";
		adder1_rounding	:	string := "NO";
		adder3_rounding	:	string := "NO";
		addnsub1_round_aclr	:	string := "NONE";
		addnsub1_round_pipeline_aclr	:	string := "NONE";
		addnsub1_round_pipeline_register	:	string := "UNREGISTERED";
		addnsub1_round_register	:	string := "UNREGISTERED";
		addnsub3_round_aclr	:	string := "NONE";
		addnsub3_round_pipeline_aclr	:	string := "NONE";
		addnsub3_round_pipeline_register	:	string := "UNREGISTERED";
		addnsub3_round_register	:	string := "UNREGISTERED";
		addnsub_multiplier_aclr1	:	string := "NONE";
		addnsub_multiplier_aclr3	:	string := "NONE";
		addnsub_multiplier_pipeline_aclr1	:	string := "NONE";
		addnsub_multiplier_pipeline_aclr3	:	string := "NONE";
		addnsub_multiplier_pipeline_register1	:	string := "UNREGISTERED";
		addnsub_multiplier_pipeline_register3	:	string := "UNREGISTERED";
		addnsub_multiplier_register1	:	string := "UNREGISTERED";
		addnsub_multiplier_register3	:	string := "UNREGISTERED";
		chainout_aclr	:	string := "NONE";
		chainout_adder	:	string := "NO";
		chainout_register	:	string := "UNREGISTERED";
		chainout_round_aclr	:	string := "NONE";
		chainout_round_output_aclr	:	string := "NONE";
		chainout_round_output_register	:	string := "UNREGISTERED";
		chainout_round_pipeline_aclr	:	string := "NONE";
		chainout_round_pipeline_register	:	string := "UNREGISTERED";
		chainout_round_register	:	string := "UNREGISTERED";
		chainout_rounding	:	string := "NO";
		chainout_saturate_aclr	:	string := "NONE";
		chainout_saturate_output_aclr	:	string := "NONE";
		chainout_saturate_output_register	:	string := "UNREGISTERED";
		chainout_saturate_pipeline_aclr	:	string := "NONE";
		chainout_saturate_pipeline_register	:	string := "UNREGISTERED";
		chainout_saturate_register	:	string := "UNREGISTERED";
		chainout_saturation	:	string := "NO";
		coef0_0	:	natural := 0;
		coef0_1	:	natural := 0;
		coef0_2	:	natural := 0;
		coef0_3	:	natural := 0;
		coef0_4	:	natural := 0;
		coef0_5	:	natural := 0;
		coef0_6	:	natural := 0;
		coef0_7	:	natural := 0;
		coef1_0	:	natural := 0;
		coef1_1	:	natural := 0;
		coef1_2	:	natural := 0;
		coef1_3	:	natural := 0;
		coef1_4	:	natural := 0;
		coef1_5	:	natural := 0;
		coef1_6	:	natural := 0;
		coef1_7	:	natural := 0;
		coef2_0	:	natural := 0;
		coef2_1	:	natural := 0;
		coef2_2	:	natural := 0;
		coef2_3	:	natural := 0;
		coef2_4	:	natural := 0;
		coef2_5	:	natural := 0;
		coef2_6	:	natural := 0;
		coef2_7	:	natural := 0;
		coef3_0	:	natural := 0;
		coef3_1	:	natural := 0;
		coef3_2	:	natural := 0;
		coef3_3	:	natural := 0;
		coef3_4	:	natural := 0;
		coef3_5	:	natural := 0;
		coef3_6	:	natural := 0;
		coef3_7	:	natural := 0;
		coefsel0_aclr	:	string := "NONE";
		coefsel0_register	:	string := "UNREGISTERED";
		coefsel1_aclr	:	string := "NONE";
		coefsel1_register	:	string := "UNREGISTERED";
		coefsel2_aclr	:	string := "NONE";
		coefsel2_register	:	string := "UNREGISTERED";
		coefsel3_aclr	:	string := "NONE";
		coefsel3_register	:	string := "UNREGISTERED";
		dedicated_multiplier_circuitry	:	string := "AUTO";
		intended_device_family	:	string := "unused";
		double_accum	:	string := "NO";
		dsp_block_balancing	:	string := "Auto";
		extra_latency	:	natural := 0;
		input_aclr_a0	:	string := "NONE";
		input_aclr_a1	:	string := "NONE";
		input_aclr_a2	:	string := "NONE";
		input_aclr_a3	:	string := "NONE";
		input_aclr_b0	:	string := "NONE";
		input_aclr_b1	:	string := "NONE";
		input_aclr_b2	:	string := "NONE";
		input_aclr_b3	:	string := "NONE";
		input_aclr_c0	:	string := "NONE";
		input_aclr_c1	:	string := "NONE";
		input_aclr_c2	:	string := "NONE";
		input_aclr_c3	:	string := "NONE";
		input_register_a0	:	string := "UNREGISTERED";
		input_register_a1	:	string := "UNREGISTERED";
		input_register_a2	:	string := "UNREGISTERED";
		input_register_a3	:	string := "UNREGISTERED";
		input_register_b0	:	string := "UNREGISTERED";
		input_register_b1	:	string := "UNREGISTERED";
		input_register_b2	:	string := "UNREGISTERED";
		input_register_b3	:	string := "UNREGISTERED";
		input_register_c0	:	string := "UNREGISTERED";
		input_register_c1	:	string := "UNREGISTERED";
		input_register_c2	:	string := "UNREGISTERED";
		input_register_c3	:	string := "UNREGISTERED";
		input_source_a0	:	string := "DATAA";
		input_source_a1	:	string := "DATAA";
		input_source_a2	:	string := "DATAA";
		input_source_a3	:	string := "DATAA";
		input_source_b0	:	string := "DATAB";
		input_source_b1	:	string := "DATAB";
		input_source_b2	:	string := "DATAB";
		input_source_b3	:	string := "DATAB";
		loadconst_control_aclr	:	string := "NONE";
		loadconst_control_register	:	string := "UNREGISTERED";
		loadconst_value	:	natural := 64;
		mult01_round_aclr	:	string := "NONE";
		mult01_round_register	:	string := "UNREGISTERED";
		mult01_saturation_aclr	:	string := "ACLR0";
		mult01_saturation_register	:	string := "UNREGISTERED";
		mult23_round_aclr	:	string := "NONE";
		mult23_round_register	:	string := "UNREGISTERED";
		mult23_saturation_aclr	:	string := "NONE";
		mult23_saturation_register	:	string := "UNREGISTERED";
		multiplier01_rounding	:	string := "NO";
		multiplier01_saturation	:	string := "NO";
		multiplier1_direction	:	string := "ADD";
		multiplier23_rounding	:	string := "NO";
		multiplier23_saturation	:	string := "NO";
		multiplier3_direction	:	string := "ADD";
		multiplier_aclr0	:	string := "NONE";
		multiplier_aclr1	:	string := "NONE";
		multiplier_aclr2	:	string := "NONE";
		multiplier_aclr3	:	string := "NONE";
		multiplier_register0	:	string := "UNREGISTERED";
		multiplier_register1	:	string := "UNREGISTERED";
		multiplier_register2	:	string := "UNREGISTERED";
		multiplier_register3	:	string := "UNREGISTERED";
		number_of_multipliers	:	natural;
		output_aclr	:	string := "NONE";
		output_register	:	string := "UNREGISTERED";
		output_round_aclr	:	string := "NONE";
		output_round_pipeline_aclr	:	string := "NONE";
		output_round_pipeline_register	:	string := "UNREGISTERED";
		output_round_register	:	string := "UNREGISTERED";
		output_round_type	:	string := "NEAREST_INTEGER";
		output_rounding	:	string := "NO";
		output_saturate_aclr	:	string := "NONE";
		output_saturate_pipeline_aclr	:	string := "NONE";
		output_saturate_pipeline_register	:	string := "UNREGISTERED";
		output_saturate_register	:	string := "UNREGISTERED";
		output_saturate_type	:	string := "ASYMMETRIC";
		output_saturation	:	string := "NO";
		port_addnsub1	:	string := "PORT_UNUSED";
		port_addnsub3	:	string := "PORT_UNUSED";
		port_chainout_sat_is_overflow	:	string := "PORT_UNUSED";
		port_mult0_is_saturated	:	string := "UNUSED";
		port_mult1_is_saturated	:	string := "UNUSED";
		port_mult2_is_saturated	:	string := "UNUSED";
		port_mult3_is_saturated	:	string := "UNUSED";
		port_output_is_overflow	:	string := "PORT_UNUSED";
		port_signa	:	string := "PORT_UNUSED";
		port_signb	:	string := "PORT_UNUSED";
		preadder_direction_0	:	string := "ADD";
		preadder_direction_1	:	string := "ADD";
		preadder_direction_2	:	string := "ADD";
		preadder_direction_3	:	string := "ADD";
		preadder_mode	:	string := "SIMPLE";
		representation_a	:	string := "UNSIGNED";
		representation_b	:	string := "UNSIGNED";
		rotate_aclr	:	string := "NONE";
		rotate_output_aclr	:	string := "NONE";
		rotate_output_register	:	string := "UNREGISTERED";
		rotate_pipeline_aclr	:	string := "NONE";
		rotate_pipeline_register	:	string := "UNREGISTERED";
		rotate_register	:	string := "UNREGISTERED";
		scanouta_aclr	:	string := "NONE";
		scanouta_register	:	string := "UNREGISTERED";
		selected_device_family	:	string;
		shift_mode	:	string := "NO";
		shift_right_aclr	:	string := "NONE";
		shift_right_output_aclr	:	string := "NONE";
		shift_right_output_register	:	string := "UNREGISTERED";
		shift_right_pipeline_aclr	:	string := "NONE";
		shift_right_pipeline_register	:	string := "UNREGISTERED";
		shift_right_register	:	string := "UNREGISTERED";
		signed_aclr_a	:	string := "NONE";
		signed_aclr_b	:	string := "NONE";
		signed_pipeline_aclr_a	:	string := "NONE";
		signed_pipeline_aclr_b	:	string := "NONE";
		signed_pipeline_register_a	:	string := "UNREGISTERED";
		signed_pipeline_register_b	:	string := "UNREGISTERED";
		signed_register_a	:	string := "UNREGISTERED";
		signed_register_b	:	string := "UNREGISTERED";
		systolic_aclr1	:	string := "NONE";
		systolic_aclr3	:	string := "NONE";
		systolic_delay1	:	string := "UNREGISTERED";
		systolic_delay3	:	string := "UNREGISTERED";
		use_sload_accum_port	:	string := "NO";
		width_a	:	natural;
		width_b	:	natural;
		width_c	:	natural := 22;
		width_chainin	:	natural := 1;
		width_coef	:	natural := 18;
		width_msb	:	natural := 17;
		width_result	:	natural;
		width_saturate_sign	:	natural := 1;
		zero_chainout_output_aclr	:	string := "NONE";
		zero_chainout_output_register	:	string := "UNREGISTERED";
		zero_loopback_aclr	:	string := "NONE";
		zero_loopback_output_aclr	:	string := "NONE";
		zero_loopback_output_register	:	string := "UNREGISTERED";
		zero_loopback_pipeline_aclr	:	string := "NONE";
		zero_loopback_pipeline_register	:	string := "UNREGISTERED";
		zero_loopback_register	:	string := "UNREGISTERED";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altera_mult_add"
	);
	port(
		accum_sload	:	in std_logic := '0';
		aclr0	:	in std_logic := '0';
		aclr1	:	in std_logic := '0';
		aclr2	:	in std_logic := '0';
		aclr3	:	in std_logic := '0';
		addnsub1	:	in std_logic := '1';
		addnsub1_round	:	in std_logic := '0';
		addnsub3	:	in std_logic := '1';
		addnsub3_round	:	in std_logic := '0';
		chainin	:	in std_logic_vector(width_chainin-1 downto 0) := (others => '0');
		chainout_round	:	in std_logic := '0';
		chainout_sat_overflow	:	out std_logic;
		chainout_saturate	:	in std_logic := '0';
		clock0	:	in std_logic := '1';
		clock1	:	in std_logic := '1';
		clock2	:	in std_logic := '1';
		clock3	:	in std_logic := '1';
		coefsel0	:	in std_logic_vector(2 downto 0) := (others => '0');
		coefsel1	:	in std_logic_vector(2 downto 0) := (others => '0');
		coefsel2	:	in std_logic_vector(2 downto 0) := (others => '0');
		coefsel3	:	in std_logic_vector(2 downto 0) := (others => '0');
		dataa	:	in std_logic_vector(width_a*number_of_multipliers-1 downto 0) := (others => '0');
		datab	:	in std_logic_vector(width_b*number_of_multipliers-1 downto 0) := (others => '0');
		datac	:	in std_logic_vector(width_c*number_of_multipliers-1 downto 0) := (others => '0');
		ena0	:	in std_logic := '1';
		ena1	:	in std_logic := '1';
		ena2	:	in std_logic := '1';
		ena3	:	in std_logic := '1';
		mult01_round	:	in std_logic := '0';
		mult01_saturation	:	in std_logic := '0';
		mult0_is_saturated	:	out std_logic;
		mult1_is_saturated	:	out std_logic;
		mult23_round	:	in std_logic := '0';
		mult23_saturation	:	in std_logic := '0';
		mult2_is_saturated	:	out std_logic;
		mult3_is_saturated	:	out std_logic;
		output_round	:	in std_logic := '0';
		output_saturate	:	in std_logic := '0';
		overflow	:	out std_logic;
		result	:	out std_logic_vector(width_result-1 downto 0);
		rotate	:	in std_logic := '0';
		scanina	:	in std_logic_vector(width_a-1 downto 0) := (others => '0');
		scaninb	:	in std_logic_vector(width_b-1 downto 0) := (others => '0');
		scanouta	:	out std_logic_vector(width_a-1 downto 0);
		scanoutb	:	out std_logic_vector(width_b-1 downto 0);
		shift_right	:	in std_logic := '0';
		signa	:	in std_logic := '0';
		signb	:	in std_logic := '0';
		sload_accum	:	in std_logic := '0';
		sourcea	:	in std_logic_vector(number_of_multipliers-1 downto 0) := (others => '0');
		sourceb	:	in std_logic_vector(number_of_multipliers-1 downto 0) := (others => '0');
		zero_chainout	:	in std_logic := '0';
		zero_loopback	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- dcfifo_mixed_widths parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component dcfifo_mixed_widths
	generic (
		add_ram_output_register	:	string := "OFF";
		add_usedw_msb_bit	:	string := "OFF";
		clocks_are_synchronized	:	string := "FALSE";
		delay_rdusedw	:	natural := 1;
		delay_wrusedw	:	natural := 1;
		intended_device_family	:	string := "unused";
		lpm_numwords	:	natural;
		lpm_showahead	:	string := "OFF";
		lpm_width	:	natural;
		lpm_width_r	:	natural := 0;
		lpm_widthu	:	natural := 1;
		lpm_widthu_r	:	natural := 1;
		overflow_checking	:	string := "ON";
		rdsync_delaypipe	:	natural := 0;
		read_aclr_synch	:	string := "OFF";
		underflow_checking	:	string := "ON";
		use_eab	:	string := "ON";
		write_aclr_synch	:	string := "OFF";
		wrsync_delaypipe	:	natural := 0;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "dcfifo_mixed_widths"
	);
	port(
		aclr	:	in std_logic := '0';
		data	:	in std_logic_vector(lpm_width-1 downto 0);
		q	:	out std_logic_vector(lpm_width_r-1 downto 0);
		rdclk	:	in std_logic;
		rdempty	:	out std_logic;
		rdfull	:	out std_logic;
		rdreq	:	in std_logic;
		rdusedw	:	out std_logic_vector(lpm_widthu_r-1 downto 0);
		wrclk	:	in std_logic;
		wrempty	:	out std_logic;
		wrfull	:	out std_logic;
		wrreq	:	in std_logic;
		wrusedw	:	out std_logic_vector(lpm_widthu-1 downto 0)
	);
end component;

------------------------------------------------------------------
-- altufm_i2c parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altufm_i2c
	generic (
		access_mode	:	string := "READ_WRITE";
		intended_device_family	:	string := "unused";
		erase_method	:	string := "MEM_ADD";
		erase_time	:	natural := 500000000;
		fixed_device_add	:	string := "UNUSED";
		lpm_file	:	string := "UNUSED";
		mem_add_erase0	:	string := "UNUSED";
		mem_add_erase1	:	string := "UNUSED";
		mem_protect	:	string := "FULL";
		memory_size	:	string := "4K";
		osc_frequency	:	natural := 180000;
		page_write_size	:	natural := 16;
		port_global_reset	:	string := "PORT_UNUSED";
		program_time	:	natural := 1600000;
		write_mode	:	string := "SINGLE_BYTE";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altufm_i2c"
	);
	port(
		a0	:	in std_logic := '0';
		a1	:	in std_logic := '0';
		a2	:	in std_logic := '0';
		global_reset	:	in std_logic := '0';
		osc	:	out std_logic;
		oscena	:	in std_logic := '1';
		scl	:	inout std_logic;
		sda	:	inout std_logic;
		wp	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- altfp_sincos parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altfp_sincos
	generic (
		cordic_depth	:	natural := 0;
		cordic_width	:	natural := 0;
		intended_device_family	:	string := "unused";
		indexpoint	:	natural := 0;
		operation	:	string;
		pipeline	:	natural := 20;
		rounding	:	string := "TO_NEAREST";
		width_exp	:	natural := 8;
		width_man	:	natural := 23;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altfp_sincos"
	);
	port(
		aclr	:	in std_logic := '0';
		clk_en	:	in std_logic := '1';
		clock	:	in std_logic;
		data	:	in std_logic_vector(width_exp+width_man+1-1 downto 0);
		nan	:	out std_logic;
		result	:	out std_logic_vector(width_exp+width_man+1-1 downto 0);
		zero	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- altera_std_synchronizer parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component altera_std_synchronizer
	generic (
		depth	:	natural := 3;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altera_std_synchronizer"	);
	port(
		clk	:	in std_logic;
		din	:	in std_logic;
		dout	:	out std_logic;
		reset_n	:	in std_logic
	);
end component;

------------------------------------------------------------------
-- altpll parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component altpll
	generic (
		bandwidth	:	natural := 0;
		bandwidth_type	:	string := "AUTO";
		c0_high	:	natural := 0;
		c0_initial	:	natural := 0;
		c0_low	:	natural := 0;
		c0_mode	:	string := "BYPASS";
		c0_ph	:	natural := 0;
		c0_test_source	:	natural := 5;
		c1_high	:	natural := 0;
		c1_initial	:	natural := 0;
		c1_low	:	natural := 0;
		c1_mode	:	string := "BYPASS";
		c1_ph	:	natural := 0;
		c1_test_source	:	natural := 5;
		c1_use_casc_in	:	string := "OFF";
		c2_high	:	natural := 0;
		c2_initial	:	natural := 0;
		c2_low	:	natural := 0;
		c2_mode	:	string := "BYPASS";
		c2_ph	:	natural := 0;
		c2_test_source	:	natural := 5;
		c2_use_casc_in	:	string := "OFF";
		c3_high	:	natural := 0;
		c3_initial	:	natural := 0;
		c3_low	:	natural := 0;
		c3_mode	:	string := "BYPASS";
		c3_ph	:	natural := 0;
		c3_test_source	:	natural := 5;
		c3_use_casc_in	:	string := "OFF";
		c4_high	:	natural := 0;
		c4_initial	:	natural := 0;
		c4_low	:	natural := 0;
		c4_mode	:	string := "BYPASS";
		c4_ph	:	natural := 0;
		c4_test_source	:	natural := 5;
		c4_use_casc_in	:	string := "OFF";
		c5_high	:	natural := 0;
		c5_initial	:	natural := 0;
		c5_low	:	natural := 0;
		c5_mode	:	string := "BYPASS";
		c5_ph	:	natural := 0;
		c5_test_source	:	natural := 5;
		c5_use_casc_in	:	string := "OFF";
		c6_high	:	natural := 0;
		c6_initial	:	natural := 0;
		c6_low	:	natural := 0;
		c6_mode	:	string := "BYPASS";
		c6_ph	:	natural := 0;
		c6_test_source	:	natural := 5;
		c6_use_casc_in	:	string := "OFF";
		c7_high	:	natural := 0;
		c7_initial	:	natural := 0;
		c7_low	:	natural := 0;
		c7_mode	:	string := "BYPASS";
		c7_ph	:	natural := 0;
		c7_test_source	:	natural := 5;
		c7_use_casc_in	:	string := "OFF";
		c8_high	:	natural := 0;
		c8_initial	:	natural := 0;
		c8_low	:	natural := 0;
		c8_mode	:	string := "BYPASS";
		c8_ph	:	natural := 0;
		c8_test_source	:	natural := 5;
		c8_use_casc_in	:	string := "OFF";
		c9_high	:	natural := 0;
		c9_initial	:	natural := 0;
		c9_low	:	natural := 0;
		c9_mode	:	string := "BYPASS";
		c9_ph	:	natural := 0;
		c9_test_source	:	natural := 5;
		c9_use_casc_in	:	string := "OFF";
		charge_pump_current	:	natural := 2;
		charge_pump_current_bits	:	natural := 9999;
		clk0_counter	:	string := "G0";
		clk0_divide_by	:	natural := 1;
		clk0_duty_cycle	:	natural := 50;
		clk0_multiply_by	:	natural := 1;
		clk0_output_frequency	:	natural := 0;
		clk0_phase_shift	:	string := "0";
		clk0_time_delay	:	string := "0";
		clk0_use_even_counter_mode	:	string := "OFF";
		clk0_use_even_counter_value	:	string := "OFF";
		clk1_counter	:	string := "G0";
		clk1_divide_by	:	natural := 1;
		clk1_duty_cycle	:	natural := 50;
		clk1_multiply_by	:	natural := 1;
		clk1_output_frequency	:	natural := 0;
		clk1_phase_shift	:	string := "0";
		clk1_time_delay	:	string := "0";
		clk1_use_even_counter_mode	:	string := "OFF";
		clk1_use_even_counter_value	:	string := "OFF";
		clk2_counter	:	string := "G0";
		clk2_divide_by	:	natural := 1;
		clk2_duty_cycle	:	natural := 50;
		clk2_multiply_by	:	natural := 1;
		clk2_output_frequency	:	natural := 0;
		clk2_phase_shift	:	string := "0";
		clk2_time_delay	:	string := "0";
		clk2_use_even_counter_mode	:	string := "OFF";
		clk2_use_even_counter_value	:	string := "OFF";
		clk3_counter	:	string := "G0";
		clk3_divide_by	:	natural := 1;
		clk3_duty_cycle	:	natural := 50;
		clk3_multiply_by	:	natural := 1;
		clk3_phase_shift	:	string := "0";
		clk3_time_delay	:	string := "0";
		clk3_use_even_counter_mode	:	string := "OFF";
		clk3_use_even_counter_value	:	string := "OFF";
		clk4_counter	:	string := "G0";
		clk4_divide_by	:	natural := 1;
		clk4_duty_cycle	:	natural := 50;
		clk4_multiply_by	:	natural := 1;
		clk4_phase_shift	:	string := "0";
		clk4_time_delay	:	string := "0";
		clk4_use_even_counter_mode	:	string := "OFF";
		clk4_use_even_counter_value	:	string := "OFF";
		clk5_counter	:	string := "G0";
		clk5_divide_by	:	natural := 1;
		clk5_duty_cycle	:	natural := 50;
		clk5_multiply_by	:	natural := 1;
		clk5_phase_shift	:	string := "0";
		clk5_time_delay	:	string := "0";
		clk5_use_even_counter_mode	:	string := "OFF";
		clk5_use_even_counter_value	:	string := "OFF";
		clk6_counter	:	string := "E0";
		clk6_divide_by	:	natural := 0;
		clk6_duty_cycle	:	natural := 50;
		clk6_multiply_by	:	natural := 0;
		clk6_phase_shift	:	string := "0";
		clk6_use_even_counter_mode	:	string := "OFF";
		clk6_use_even_counter_value	:	string := "OFF";
		clk7_counter	:	string := "E1";
		clk7_divide_by	:	natural := 0;
		clk7_duty_cycle	:	natural := 50;
		clk7_multiply_by	:	natural := 0;
		clk7_phase_shift	:	string := "0";
		clk7_use_even_counter_mode	:	string := "OFF";
		clk7_use_even_counter_value	:	string := "OFF";
		clk8_counter	:	string := "E2";
		clk8_divide_by	:	natural := 0;
		clk8_duty_cycle	:	natural := 50;
		clk8_multiply_by	:	natural := 0;
		clk8_phase_shift	:	string := "0";
		clk8_use_even_counter_mode	:	string := "OFF";
		clk8_use_even_counter_value	:	string := "OFF";
		clk9_counter	:	string := "E3";
		clk9_divide_by	:	natural := 0;
		clk9_duty_cycle	:	natural := 50;
		clk9_multiply_by	:	natural := 0;
		clk9_phase_shift	:	string := "0";
		clk9_use_even_counter_mode	:	string := "OFF";
		clk9_use_even_counter_value	:	string := "OFF";
		compensate_clock	:	string := "CLK0";
		down_spread	:	string := "0";
		dpa_divide_by	:	natural := 1;
		dpa_divider	:	natural := 0;
		dpa_multiply_by	:	natural := 0;
		e0_high	:	natural := 1;
		e0_initial	:	natural := 1;
		e0_low	:	natural := 1;
		e0_mode	:	string := "BYPASS";
		e0_ph	:	natural := 0;
		e0_time_delay	:	natural := 0;
		e1_high	:	natural := 1;
		e1_initial	:	natural := 1;
		e1_low	:	natural := 1;
		e1_mode	:	string := "BYPASS";
		e1_ph	:	natural := 0;
		e1_time_delay	:	natural := 0;
		e2_high	:	natural := 1;
		e2_initial	:	natural := 1;
		e2_low	:	natural := 1;
		e2_mode	:	string := "BYPASS";
		e2_ph	:	natural := 0;
		e2_time_delay	:	natural := 0;
		e3_high	:	natural := 1;
		e3_initial	:	natural := 1;
		e3_low	:	natural := 1;
		e3_mode	:	string := "BYPASS";
		e3_ph	:	natural := 0;
		e3_time_delay	:	natural := 0;
		enable0_counter	:	string := "L0";
		enable1_counter	:	string := "L0";
		enable_switch_over_counter	:	string := "OFF";
		extclk0_counter	:	string := "E0";
		extclk0_divide_by	:	natural := 1;
		extclk0_duty_cycle	:	natural := 50;
		extclk0_multiply_by	:	natural := 1;
		extclk0_phase_shift	:	string := "0";
		extclk0_time_delay	:	string := "0";
		extclk1_counter	:	string := "E1";
		extclk1_divide_by	:	natural := 1;
		extclk1_duty_cycle	:	natural := 50;
		extclk1_multiply_by	:	natural := 1;
		extclk1_phase_shift	:	string := "0";
		extclk1_time_delay	:	string := "0";
		extclk2_counter	:	string := "E2";
		extclk2_divide_by	:	natural := 1;
		extclk2_duty_cycle	:	natural := 50;
		extclk2_multiply_by	:	natural := 1;
		extclk2_phase_shift	:	string := "0";
		extclk2_time_delay	:	string := "0";
		extclk3_counter	:	string := "E3";
		extclk3_divide_by	:	natural := 1;
		extclk3_duty_cycle	:	natural := 50;
		extclk3_multiply_by	:	natural := 1;
		extclk3_phase_shift	:	string := "0";
		extclk3_time_delay	:	string := "0";
		feedback_source	:	string := "EXTCLK0";
		g0_high	:	natural := 1;
		g0_initial	:	natural := 1;
		g0_low	:	natural := 1;
		g0_mode	:	string := "BYPASS";
		g0_ph	:	natural := 0;
		g0_time_delay	:	natural := 0;
		g1_high	:	natural := 1;
		g1_initial	:	natural := 1;
		g1_low	:	natural := 1;
		g1_mode	:	string := "BYPASS";
		g1_ph	:	natural := 0;
		g1_time_delay	:	natural := 0;
		g2_high	:	natural := 1;
		g2_initial	:	natural := 1;
		g2_low	:	natural := 1;
		g2_mode	:	string := "BYPASS";
		g2_ph	:	natural := 0;
		g2_time_delay	:	natural := 0;
		g3_high	:	natural := 1;
		g3_initial	:	natural := 1;
		g3_low	:	natural := 1;
		g3_mode	:	string := "BYPASS";
		g3_ph	:	natural := 0;
		g3_time_delay	:	natural := 0;
		gate_lock_counter	:	natural := 0;
		gate_lock_signal	:	string := "NO";
		inclk0_input_frequency	:	natural;
		inclk1_input_frequency	:	natural := 0;
		intended_device_family	:	string := "NONE";
		invalid_lock_multiplier	:	natural := 5;
		l0_high	:	natural := 1;
		l0_initial	:	natural := 1;
		l0_low	:	natural := 1;
		l0_mode	:	string := "BYPASS";
		l0_ph	:	natural := 0;
		l0_time_delay	:	natural := 0;
		l1_high	:	natural := 1;
		l1_initial	:	natural := 1;
		l1_low	:	natural := 1;
		l1_mode	:	string := "BYPASS";
		l1_ph	:	natural := 0;
		l1_time_delay	:	natural := 0;
		lock_high	:	natural := 1;
		lock_low	:	natural := 1;
		lock_window_ui	:	string := " 0.05";
		lock_window_ui_bits	:	string := "UNUSED";
		loop_filter_c	:	natural := 5;
		loop_filter_c_bits	:	natural := 9999;
		loop_filter_r	:	string := " 1.000000";
		loop_filter_r_bits	:	natural := 9999;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altpll";
		m	:	natural := 0;
		m2	:	natural := 1;
		m_initial	:	natural := 0;
		m_ph	:	natural := 0;
		m_test_source	:	natural := 5;
		m_time_delay	:	natural := 0;
		n	:	natural := 1;
		n2	:	natural := 1;
		n_time_delay	:	natural := 0;
		operation_mode	:	string;
		pfd_max	:	natural := 0;
		pfd_min	:	natural := 0;
		pll_type	:	string := "AUTO";
		port_activeclock	:	string := "PORT_CONNECTIVITY";
		port_areset	:	string := "PORT_CONNECTIVITY";
		port_clk0	:	string := "PORT_CONNECTIVITY";
		port_clk1	:	string := "PORT_CONNECTIVITY";
		port_clk2	:	string := "PORT_CONNECTIVITY";
		port_clk3	:	string := "PORT_CONNECTIVITY";
		port_clk4	:	string := "PORT_CONNECTIVITY";
		port_clk5	:	string := "PORT_CONNECTIVITY";
		port_clk6	:	string := "PORT_UNUSED";
		port_clk7	:	string := "PORT_UNUSED";
		port_clk8	:	string := "PORT_UNUSED";
		port_clk9	:	string := "PORT_UNUSED";
		port_clkbad0	:	string := "PORT_CONNECTIVITY";
		port_clkbad1	:	string := "PORT_CONNECTIVITY";
		port_clkena0	:	string := "PORT_CONNECTIVITY";
		port_clkena1	:	string := "PORT_CONNECTIVITY";
		port_clkena2	:	string := "PORT_CONNECTIVITY";
		port_clkena3	:	string := "PORT_CONNECTIVITY";
		port_clkena4	:	string := "PORT_CONNECTIVITY";
		port_clkena5	:	string := "PORT_CONNECTIVITY";
		port_clkloss	:	string := "PORT_CONNECTIVITY";
		port_clkswitch	:	string := "PORT_CONNECTIVITY";
		port_configupdate	:	string := "PORT_CONNECTIVITY";
		port_enable0	:	string := "PORT_CONNECTIVITY";
		port_enable1	:	string := "PORT_CONNECTIVITY";
		port_extclk0	:	string := "PORT_CONNECTIVITY";
		port_extclk1	:	string := "PORT_CONNECTIVITY";
		port_extclk2	:	string := "PORT_CONNECTIVITY";
		port_extclk3	:	string := "PORT_CONNECTIVITY";
		port_extclkena0	:	string := "PORT_CONNECTIVITY";
		port_extclkena1	:	string := "PORT_CONNECTIVITY";
		port_extclkena2	:	string := "PORT_CONNECTIVITY";
		port_extclkena3	:	string := "PORT_CONNECTIVITY";
		port_fbin	:	string := "PORT_CONNECTIVITY";
		port_fbout	:	string := "PORT_CONNECTIVITY";
		port_inclk0	:	string := "PORT_CONNECTIVITY";
		port_inclk1	:	string := "PORT_CONNECTIVITY";
		port_locked	:	string := "PORT_CONNECTIVITY";
		port_pfdena	:	string := "PORT_CONNECTIVITY";
		port_phasecounterselect	:	string := "PORT_CONNECTIVITY";
		port_phasedone	:	string := "PORT_CONNECTIVITY";
		port_phasestep	:	string := "PORT_CONNECTIVITY";
		port_phaseupdown	:	string := "PORT_CONNECTIVITY";
		port_pllena	:	string := "PORT_CONNECTIVITY";
		port_scanaclr	:	string := "PORT_CONNECTIVITY";
		port_scanclk	:	string := "PORT_CONNECTIVITY";
		port_scanclkena	:	string := "PORT_CONNECTIVITY";
		port_scandata	:	string := "PORT_CONNECTIVITY";
		port_scandataout	:	string := "PORT_CONNECTIVITY";
		port_scandone	:	string := "PORT_CONNECTIVITY";
		port_scanread	:	string := "PORT_CONNECTIVITY";
		port_scanwrite	:	string := "PORT_CONNECTIVITY";
		port_sclkout0	:	string := "PORT_CONNECTIVITY";
		port_sclkout1	:	string := "PORT_CONNECTIVITY";
		port_vcooverrange	:	string := "PORT_CONNECTIVITY";
		port_vcounderrange	:	string := "PORT_CONNECTIVITY";
		primary_clock	:	string := "INCLK0";
		qualify_conf_done	:	string := "OFF";
		scan_chain	:	string := "LONG";
		scan_chain_mif_file	:	string := "UNUSED";
		sclkout0_phase_shift	:	string := "0";
		sclkout1_phase_shift	:	string := "0";
		self_reset_on_gated_loss_lock	:	string := "OFF";
		self_reset_on_loss_lock	:	string := "OFF";
		sim_gate_lock_device_behavior	:	string := "OFF";
		skip_vco	:	string := "OFF";
		spread_frequency	:	natural := 0;
		ss	:	natural := 1;
		switch_over_counter	:	natural := 0;
		switch_over_on_gated_lock	:	string := "OFF";
		switch_over_on_lossclk	:	string := "OFF";
		switch_over_type	:	string := "AUTO";
		using_fbmimicbidir_port	:	string := "OFF";
		valid_lock_multiplier	:	natural := 1;
		vco_center	:	natural := 0;
		vco_divide_by	:	natural := 0;
		vco_frequency_control	:	string := "AUTO";
		vco_max	:	natural := 0;
		vco_min	:	natural := 0;
		vco_multiply_by	:	natural := 0;
		vco_phase_shift_step	:	natural := 0;
		vco_post_scale	:	natural := 0;
		vco_range_detector_high_bits	:	string := "UNUSED";
		vco_range_detector_low_bits	:	string := "UNUSED";
		width_clock	:	natural := 6;
		width_phasecounterselect	:	natural := 4	);
	port(
		activeclock	:	out std_logic;
		areset	:	in std_logic := '0';
		clk	:	out std_logic_vector(WIDTH_CLOCK-1 downto 0);
		clkbad	:	out std_logic_vector(1 downto 0);
		clkena	:	in std_logic_vector(5 downto 0) := (others => '1');
		clkloss	:	out std_logic;
		clkswitch	:	in std_logic := '0';
		configupdate	:	in std_logic := '0';
		enable0	:	out std_logic;
		enable1	:	out std_logic;
		extclk	:	out std_logic_vector(3 downto 0);
		extclkena	:	in std_logic_vector(3 downto 0) := (others => '1');
		fbin	:	in std_logic := '1';
		fbmimicbidir	:	inout std_logic;
		fbout	:	out std_logic;
		fref	:	out std_logic;
		icdrclk	:	out std_logic;
		inclk	:	in std_logic_vector(1 downto 0) := (others => '0');
		locked	:	out std_logic;
		pfdena	:	in std_logic := '1';
		phasecounterselect	:	in std_logic_vector(WIDTH_PHASECOUNTERSELECT-1 downto 0) := (others => '1');
		phasedone	:	out std_logic;
		phasestep	:	in std_logic := '1';
		phaseupdown	:	in std_logic := '1';
		pllena	:	in std_logic := '1';
		scanaclr	:	in std_logic := '0';
		scanclk	:	in std_logic := '0';
		scanclkena	:	in std_logic := '1';
		scandata	:	in std_logic := '0';
		scandataout	:	out std_logic;
		scandone	:	out std_logic;
		scanread	:	in std_logic := '0';
		scanwrite	:	in std_logic := '0';
		sclkout0	:	out std_logic;
		sclkout1	:	out std_logic;
		vcooverrange	:	out std_logic;
		vcounderrange	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- altufm_none parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altufm_none
	generic (
		intended_device_family	:	string := "unused";
		erase_time	:	natural := 500000000;
		lpm_file	:	string := "UNUSED";
		osc_frequency	:	natural := 180000;
		port_arclkena	:	string := "PORT_UNUSED";
		port_drclkena	:	string := "PORT_UNUSED";
		program_time	:	natural := 1600000;
		width_ufm_address	:	natural := 9;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altufm_none"
	);
	port(
		arclk	:	in std_logic;
		arclkena	:	in std_logic := '1';
		ardin	:	in std_logic;
		arshft	:	in std_logic;
		busy	:	out std_logic;
		drclk	:	in std_logic;
		drclkena	:	in std_logic := '1';
		drdin	:	in std_logic;
		drdout	:	out std_logic;
		drshft	:	in std_logic;
		erase	:	in std_logic;
		osc	:	out std_logic;
		oscena	:	in std_logic;
		program	:	in std_logic;
		rtpbusy	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- scfifo parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component scfifo
	generic (
		add_ram_output_register	:	string := "OFF";
		allow_rwcycle_when_full	:	string := "OFF";
		almost_empty_value	:	natural := 0;
		almost_full_value	:	natural := 0;
		intended_device_family	:	string := "unused";
		lpm_numwords	:	natural;
		lpm_showahead	:	string := "OFF";
		lpm_width	:	natural;
		lpm_widthu	:	natural := 1;
		overflow_checking	:	string := "ON";
		underflow_checking	:	string := "ON";
		use_eab	:	string := "ON";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "scfifo"
	);
	port(
		aclr	:	in std_logic := '0';
		almost_empty	:	out std_logic;
		almost_full	:	out std_logic;
		clock	:	in std_logic;
		data	:	in std_logic_vector(lpm_width-1 downto 0);
		empty	:	out std_logic;
		full	:	out std_logic;
		q	:	out std_logic_vector(lpm_width-1 downto 0);
		rdreq	:	in std_logic;
		sclr	:	in std_logic := '0';
		usedw	:	out std_logic_vector(lpm_widthu-1 downto 0);
		wrreq	:	in std_logic
	);
end component;

------------------------------------------------------------------
-- altsquare parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altsquare
	generic (
		data_width	:	natural;
		intended_device_family	:	string := "unused";
		pipeline	:	natural;
		representation	:	string := "UNSIGNED";
		result_alignment	:	string := "LSB";
		result_width	:	natural;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altsquare"
	);
	port(
		aclr	:	in std_logic := '0';
		clock	:	in std_logic := '1';
		data	:	in std_logic_vector(data_width-1 downto 0);
		ena	:	in std_logic := '1';
		result	:	out std_logic_vector(result_width-1 downto 0)
	);
end component;

------------------------------------------------------------------
-- sld_virtual_jtag_basic parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component sld_virtual_jtag_basic
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "sld_virtual_jtag_basic";
		sld_auto_instance_index	:	string := "NO";
		sld_instance_index	:	natural := 0;
		sld_ir_width	:	natural := 1;
		sld_mfg_id	:	natural := 0;
		sld_sim_action	:	string := "UNUSED";
		sld_sim_n_scan	:	natural := 0;
		sld_sim_total_length	:	natural := 0;
		sld_type_id	:	natural := 0;
		sld_version	:	natural := 0	);
	port(
		ir_in	:	out std_logic_vector(sld_ir_width-1 downto 0);
		ir_out	:	in std_logic_vector(sld_ir_width-1 downto 0);
		jtag_state_cdr	:	out std_logic;
		jtag_state_cir	:	out std_logic;
		jtag_state_e1dr	:	out std_logic;
		jtag_state_e1ir	:	out std_logic;
		jtag_state_e2dr	:	out std_logic;
		jtag_state_e2ir	:	out std_logic;
		jtag_state_pdr	:	out std_logic;
		jtag_state_pir	:	out std_logic;
		jtag_state_rti	:	out std_logic;
		jtag_state_sdr	:	out std_logic;
		jtag_state_sdrs	:	out std_logic;
		jtag_state_sir	:	out std_logic;
		jtag_state_sirs	:	out std_logic;
		jtag_state_tlr	:	out std_logic;
		jtag_state_udr	:	out std_logic;
		jtag_state_uir	:	out std_logic;
		tck	:	out std_logic;
		tdi	:	out std_logic;
		tdo	:	in std_logic;
		tms	:	out std_logic;
		virtual_state_cdr	:	out std_logic;
		virtual_state_cir	:	out std_logic;
		virtual_state_e1dr	:	out std_logic;
		virtual_state_e2dr	:	out std_logic;
		virtual_state_pdr	:	out std_logic;
		virtual_state_sdr	:	out std_logic;
		virtual_state_udr	:	out std_logic;
		virtual_state_uir	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- alt_adv_seu_detection parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
	constant	mem_data_width	:	NATURAL	:=	32;
component alt_adv_seu_detection
	generic (
		cache_depth	:	natural := 10;
		clock_frequency	:	natural := 50;
		emr_data_width	:	natural := 35;
		enable_virtual_jtag	:	natural := 1;
		error_clock_divisor	:	natural := 256;
		error_delay_cycles	:	natural := 0;
		intended_device_family	:	string := "UNUSED";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "alt_adv_seu_detection";
		mem_addr_width	:	natural := 32;
		start_address	:	natural := 0;
		use_memory_interface	:	natural := 1	);
	port(
		cache_comparison_off	:	in std_logic;
		cache_fill_level	:	out std_logic_vector(3 downto 0);
		cache_full	:	out std_logic;
		clk	:	in std_logic;
		crcerror_core	:	out std_logic;
		crcerror_pin	:	out std_logic;
		critical_error	:	out std_logic;
		emr_cache_ack	:	in std_logic;
		emr_cache_int	:	out std_logic;
		emr_data	:	out std_logic_vector(emr_data_width-1 downto 0);
		mem_addr	:	out std_logic_vector(mem_addr_width-1 downto 0);
		mem_bytesel	:	out std_logic_vector(3 downto 0);
		mem_critical	:	in std_logic;
		mem_data	:	in std_logic_vector(mem_data_width-1 downto 0);
		mem_rd	:	out std_logic;
		mem_wait	:	in std_logic;
		noncritical_error	:	out std_logic;
		nreset	:	in std_logic
	);
end component;

------------------------------------------------------------------
-- altmem_init parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altmem_init
	generic (
		intended_device_family	:	string := "unused";
		init_file	:	string := "UNUSED";
		init_to_zero	:	string := "YES";
		numwords	:	natural := 16;
		port_rom_data_ready	:	string := "PORT_UNUSED";
		rom_read_latency	:	natural := 1;
		width	:	natural;
		widthad	:	natural;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altmem_init"
	);
	port(
		clken	:	in std_logic := '1';
		clock	:	in std_logic;
		datain	:	in std_logic_vector(width-1 downto 0) := (others => '0');
		dataout	:	out std_logic_vector(width-1 downto 0);
		init	:	in std_logic;
		init_busy	:	out std_logic;
		ram_address	:	out std_logic_vector(widthad-1 downto 0);
		ram_wren	:	out std_logic;
		rom_address	:	out std_logic_vector(widthad-1 downto 0);
		rom_data_ready	:	in std_logic := '0';
		rom_rden	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- altlvds_tx parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altlvds_tx
	generic (
		center_align_msb	:	string := "UNUSED";
		common_rx_tx_pll	:	string := "ON";
		coreclock_divide_by	:	natural := 2;
		data_rate	:	string := "UNUSED";
		deserialization_factor	:	natural := 4;
		intended_device_family	:	string := "unused";
		differential_drive	:	natural := 0;
		enable_clock_pin_mode	:	string := "UNUSED";
		implement_in_les	:	string := "OFF";
		inclock_boost	:	natural := 0;
		inclock_data_alignment	:	string := "EDGE_ALIGNED";
		inclock_period	:	natural := 0;
		inclock_phase_shift	:	natural := 0;
		multi_clock	:	string := "OFF";
		number_of_channels	:	natural;
		outclock_alignment	:	string := "EDGE_ALIGNED";
		outclock_divide_by	:	natural := 1;
		outclock_duty_cycle	:	natural := 50;
		outclock_multiply_by	:	natural := 1;
		outclock_phase_shift	:	natural := 0;
		outclock_resource	:	string := "AUTO";
		output_data_rate	:	natural := 0;
		pll_compensation_mode	:	string := "AUTO";
		pll_self_reset_on_loss_lock	:	string := "OFF";
		preemphasis_setting	:	natural := 0;
		refclk_frequency	:	string := "UNUSED";
		registered_input	:	string := "ON";
		use_external_pll	:	string := "OFF";
		use_no_phase_shift	:	string := "ON";
		vod_setting	:	natural := 0;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altlvds_tx"
	);
	port(
		pll_areset	:	in std_logic := '0';
		sync_inclock	:	in std_logic := '0';
		tx_coreclock	:	out std_logic;
		tx_data_reset	:	in std_logic := '0';
		tx_enable	:	in std_logic := '1';
		tx_in	:	in std_logic_vector(deserialization_factor*number_of_channels-1 downto 0);
		tx_inclock	:	in std_logic;
		tx_locked	:	out std_logic;
		tx_out	:	out std_logic_vector(number_of_channels-1 downto 0);
		tx_outclock	:	out std_logic;
		tx_pll_enable	:	in std_logic := '1';
		tx_syncclock	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- altfp_inv parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altfp_inv
	generic (
		intended_device_family	:	string := "unused";
		pipeline	:	natural := 20;
		rounding	:	string := "TO_NEAREST";
		width_exp	:	natural := 8;
		width_man	:	natural := 23;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altfp_inv"
	);
	port(
		aclr	:	in std_logic := '0';
		clk_en	:	in std_logic := '1';
		clock	:	in std_logic;
		data	:	in std_logic_vector(width_exp+width_man+1-1 downto 0);
		division_by_zero	:	out std_logic;
		nan	:	out std_logic;
		result	:	out std_logic_vector(width_exp+width_man+1-1 downto 0);
		underflow	:	out std_logic;
		zero	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- altufm_osc parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altufm_osc
	generic (
		osc_frequency	:	natural := 180000;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altufm_osc"
	);
	port(
		osc	:	out std_logic;
		oscena	:	in std_logic
	);
end component;

------------------------------------------------------------------
-- alt3pram parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component alt3pram
	generic (
		indata_aclr	:	string := "ON";
		indata_reg	:	string := "INCLOCK";
		intended_device_family	:	string := "unused";
		lpm_file	:	string := "UNUSED";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "alt3pram";
		maximum_depth	:	natural := 0;
		numwords	:	natural := 0;
		outdata_aclr_a	:	string := "ON";
		outdata_aclr_b	:	string := "ON";
		outdata_reg_a	:	string := "OUTCLOCK";
		outdata_reg_b	:	string := "OUTCLOCK";
		ram_block_type	:	string := "AUTO";
		rdaddress_aclr_a	:	string := "ON";
		rdaddress_aclr_b	:	string := "ON";
		rdaddress_reg_a	:	string := "INCLOCK";
		rdaddress_reg_b	:	string := "INCLOCK";
		rdcontrol_aclr_a	:	string := "ON";
		rdcontrol_aclr_b	:	string := "ON";
		rdcontrol_reg_a	:	string := "INCLOCK";
		rdcontrol_reg_b	:	string := "INCLOCK";
		use_eab	:	string := "ON";
		width	:	natural;
		widthad	:	natural;
		write_aclr	:	string := "ON";
		write_reg	:	string := "INCLOCK"	);
	port(
		aclr	:	in std_logic := '0';
		data	:	in std_logic_vector(WIDTH-1 downto 0);
		inclock	:	in std_logic := '1';
		inclocken	:	in std_logic := '1';
		outclock	:	in std_logic := '1';
		outclocken	:	in std_logic := '1';
		qa	:	out std_logic_vector(WIDTH-1 downto 0);
		qb	:	out std_logic_vector(WIDTH-1 downto 0);
		rdaddress_a	:	in std_logic_vector(WIDTHAD-1 downto 0);
		rdaddress_b	:	in std_logic_vector(WIDTHAD-1 downto 0);
		rden_a	:	in std_logic := '1';
		rden_b	:	in std_logic := '1';
		wraddress	:	in std_logic_vector(WIDTHAD-1 downto 0);
		wren	:	in std_logic
	);
end component;

------------------------------------------------------------------
-- altfp_inv_sqrt parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altfp_inv_sqrt
	generic (
		intended_device_family	:	string := "unused";
		pipeline	:	natural := 26;
		rounding	:	string := "TO_NEAREST";
		width_exp	:	natural := 8;
		width_man	:	natural := 23;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altfp_inv_sqrt"
	);
	port(
		aclr	:	in std_logic := '0';
		clk_en	:	in std_logic := '1';
		clock	:	in std_logic;
		data	:	in std_logic_vector(width_exp+width_man+1-1 downto 0);
		division_by_zero	:	out std_logic;
		nan	:	out std_logic;
		result	:	out std_logic_vector(width_exp+width_man+1-1 downto 0);
		zero	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- alt_zaccum parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component alt_zaccum
	generic (
		intended_device_family	:	string := "unused";
		extra_latency	:	natural := 0;
		lpm_representation	:	string := "UNSIGNED";
		round_fraction_width	:	natural := 15;
		rounding	:	string := "NO";
		saturation	:	string := "NO";
		saturation_fraction_width	:	natural := 31;
		width_fraction	:	natural := 15;
		width_in	:	natural;
		width_out	:	natural;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "alt_zaccum"
	);
	port(
		aclr	:	in std_logic := '0';
		add_sub	:	in std_logic := '1';
		cin	:	in std_logic := '0';
		clken	:	in std_logic := '1';
		clock	:	in std_logic;
		cout	:	out std_logic;
		data	:	in std_logic_vector(width_in-1 downto 0);
		load_data	:	in std_logic_vector(width_out-1 downto 0) := (others => '0');
		overflow	:	out std_logic;
		result	:	out std_logic_vector(width_out-1 downto 0);
		round	:	in std_logic := '0';
		saturate	:	in std_logic := '0';
		saturate_overflow	:	out std_logic;
		sign_data	:	in std_logic := '0';
		zero_accum	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- altdpram parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altdpram
	generic (
		byte_size	:	natural := 0;
		intended_device_family	:	string := "unused";
		indata_aclr	:	string := "ON";
		indata_reg	:	string := "INCLOCK";
		lpm_file	:	string := "UNUSED";
		maximum_depth	:	natural := 0;
		numwords	:	natural := 0;
		outdata_aclr	:	string := "ON";
		outdata_reg	:	string := "UNREGISTERED";
		ram_block_type	:	string := "AUTO";
		rdaddress_aclr	:	string := "ON";
		rdaddress_reg	:	string := "OUTCLOCK";
		rdcontrol_aclr	:	string := "ON";
		rdcontrol_reg	:	string := "OUTCLOCK";
		read_during_write_mode_mixed_ports	:	string := "DONT_CARE";
		use_eab	:	string := "ON";
		width	:	natural;
		width_byteena	:	natural := 1;
		widthad	:	natural;
		wraddress_aclr	:	string := "ON";
		wraddress_reg	:	string := "INCLOCK";
		wrcontrol_aclr	:	string := "ON";
		wrcontrol_reg	:	string := "INCLOCK";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altdpram"
	);
	port(
		aclr	:	in std_logic := '0';
		byteena	:	in std_logic_vector(width_byteena-1 downto 0) := (others => '1');
		data	:	in std_logic_vector(width-1 downto 0);
		inclock	:	in std_logic := '1';
		inclocken	:	in std_logic := '1';
		outclock	:	in std_logic := '1';
		outclocken	:	in std_logic := '1';
		q	:	out std_logic_vector(width-1 downto 0);
		rdaddress	:	in std_logic_vector(widthad-1 downto 0);
		rdaddressstall	:	in std_logic := '0';
		rden	:	in std_logic := '1';
		wraddress	:	in std_logic_vector(widthad-1 downto 0);
		wraddressstall	:	in std_logic := '0';
		wren	:	in std_logic
	);
end component;

------------------------------------------------------------------
-- altmult_accum parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altmult_accum
	generic (
		accum_direction	:	string := "ADD";
		accum_round_aclr	:	string := "ACLR0";
		accum_round_pipeline_aclr	:	string := "ACLR0";
		accum_round_pipeline_reg	:	string := "CLOCK0";
		accum_round_reg	:	string := "CLOCK0";
		accum_saturation_aclr	:	string := "ACLR0";
		accum_saturation_pipeline_aclr	:	string := "ACLR0";
		accum_saturation_pipeline_reg	:	string := "CLOCK0";
		accum_saturation_reg	:	string := "CLOCK0";
		accum_sload_aclr	:	string := "ACLR0";
		accum_sload_pipeline_aclr	:	string := "ACLR0";
		accum_sload_pipeline_reg	:	string := "CLOCK0";
		accum_sload_reg	:	string := "CLOCK0";
		accum_sload_upper_data_aclr	:	string := "ACLR0";
		accum_sload_upper_data_pipeline_aclr	:	string := "ACLR0";
		accum_sload_upper_data_pipeline_reg	:	string := "CLOCK0";
		accum_sload_upper_data_reg	:	string := "CLOCK0";
		accumulator_rounding	:	string := "NO";
		accumulator_saturation	:	string := "NO";
		addnsub_aclr	:	string := "ACLR0";
		addnsub_pipeline_aclr	:	string := "ACLR0";
		addnsub_pipeline_reg	:	string := "CLOCK0";
		addnsub_reg	:	string := "CLOCK0";
		coef0_0	:	natural := 0;
		coef0_1	:	natural := 0;
		coef0_2	:	natural := 0;
		coef0_3	:	natural := 0;
		coef0_4	:	natural := 0;
		coef0_5	:	natural := 0;
		coef0_6	:	natural := 0;
		coef0_7	:	natural := 0;
		coef1_0	:	natural := 0;
		coef1_1	:	natural := 0;
		coef1_2	:	natural := 0;
		coef1_3	:	natural := 0;
		coef1_4	:	natural := 0;
		coef1_5	:	natural := 0;
		coef1_6	:	natural := 0;
		coef1_7	:	natural := 0;
		coef2_0	:	natural := 0;
		coef2_1	:	natural := 0;
		coef2_2	:	natural := 0;
		coef2_3	:	natural := 0;
		coef2_4	:	natural := 0;
		coef2_5	:	natural := 0;
		coef2_6	:	natural := 0;
		coef2_7	:	natural := 0;
		coef3_0	:	natural := 0;
		coef3_1	:	natural := 0;
		coef3_2	:	natural := 0;
		coef3_3	:	natural := 0;
		coef3_4	:	natural := 0;
		coef3_5	:	natural := 0;
		coef3_6	:	natural := 0;
		coef3_7	:	natural := 0;
		coefsel0_aclr	:	string := "ACLR0";
		coefsel0_register	:	string := "CLOCK0";
		coefsel1_aclr	:	string := "ACLR0";
		coefsel1_register	:	string := "CLOCK0";
		coefsel2_aclr	:	string := "ACLR0";
		coefsel2_register	:	string := "CLOCK0";
		coefsel3_aclr	:	string := "ACLR0";
		coefsel3_register	:	string := "CLOCK0";
		dedicated_multiplier_circuitry	:	string := "AUTO";
		intended_device_family	:	string := "unused";
		double_accum	:	string := "NO";
		dsp_block_balancing	:	string := "Auto";
		extra_accumulator_latency	:	natural := 0;
		extra_multiplier_latency	:	natural := 0;
		input_aclr_a	:	string := "ACLR0";
		input_aclr_b	:	string := "ACLR0";
		input_aclr_c0	:	string := "ACLR0";
		input_aclr_c1	:	string := "ACLR0";
		input_aclr_c2	:	string := "ACLR0";
		input_aclr_c3	:	string := "ACLR0";
		input_reg_a	:	string := "CLOCK0";
		input_reg_b	:	string := "CLOCK0";
		input_register_c0	:	string := "CLOCK0";
		input_register_c1	:	string := "CLOCK0";
		input_register_c2	:	string := "CLOCK0";
		input_register_c3	:	string := "CLOCK0";
		input_source_a	:	string := "DATAA";
		input_source_b	:	string := "DATAB";
		loadconst_control_aclr	:	string := "ACLR0";
		loadconst_control_register	:	string := "CLOCK0";
		loadconst_value	:	natural := 64;
		mult_round_aclr	:	string := "ACLR0";
		mult_round_reg	:	string := "CLOCK0";
		mult_saturation_aclr	:	string := "ACLR0";
		mult_saturation_reg	:	string := "CLOCK0";
		multiplier1_direction	:	string := "ADD";
		multiplier3_direction	:	string := "ADD";
		multiplier_aclr	:	string := "ACLR0";
		multiplier_reg	:	string := "CLOCK0";
		multiplier_rounding	:	string := "NO";
		multiplier_saturation	:	string := "NO";
		number_of_multipliers	:	natural := 1;
		output_aclr	:	string := "ACLR0";
		output_reg	:	string := "CLOCK0";
		port_accum_is_saturated	:	string := "UNUSED";
		port_addnsub	:	string := "PORT_CONNECTIVITY";
		port_mult_is_saturated	:	string := "UNUSED";
		port_signa	:	string := "PORT_CONNECTIVITY";
		port_signb	:	string := "PORT_CONNECTIVITY";
		preadder_direction_0	:	string := "ADD";
		preadder_direction_1	:	string := "ADD";
		preadder_direction_2	:	string := "ADD";
		preadder_direction_3	:	string := "ADD";
		preadder_mode	:	string := "SIMPLE";
		representation_a	:	string := "UNSIGNED";
		representation_b	:	string := "UNSIGNED";
		sign_aclr_a	:	string := "ACLR0";
		sign_aclr_b	:	string := "ACLR0";
		sign_pipeline_aclr_a	:	string := "ACLR0";
		sign_pipeline_aclr_b	:	string := "ACLR0";
		sign_pipeline_reg_a	:	string := "CLOCK0";
		sign_pipeline_reg_b	:	string := "CLOCK0";
		sign_reg_a	:	string := "CLOCK0";
		sign_reg_b	:	string := "CLOCK0";
		systolic_aclr1	:	string := "ACLR0";
		systolic_aclr3	:	string := "ACLR0";
		systolic_delay1	:	string := "UNREGISTERED";
		systolic_delay3	:	string := "UNREGISTERED";
		width_a	:	natural;
		width_b	:	natural;
		width_c	:	natural := 22;
		width_coef	:	natural := 18;
		width_result	:	natural;
		width_upper_data	:	natural := 1;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altmult_accum"
	);
	port(
		accum_is_saturated	:	out std_logic;
		accum_round	:	in std_logic := '0';
		accum_saturation	:	in std_logic := '0';
		accum_sload	:	in std_logic := '0';
		accum_sload_upper_data	:	in std_logic_vector(width_upper_data-1 downto 0) := (others => '0');
		aclr0	:	in std_logic := '0';
		aclr1	:	in std_logic := '0';
		aclr2	:	in std_logic := '0';
		aclr3	:	in std_logic := '0';
		addnsub	:	in std_logic := '1';
		clock0	:	in std_logic := '1';
		clock1	:	in std_logic := '1';
		clock2	:	in std_logic := '1';
		clock3	:	in std_logic := '1';
		coefsel0	:	in std_logic_vector(2 downto 0);
		coefsel1	:	in std_logic_vector(2 downto 0);
		coefsel2	:	in std_logic_vector(2 downto 0);
		coefsel3	:	in std_logic_vector(2 downto 0);
		dataa	:	in std_logic_vector(width_a-1 downto 0) := (others => '0');
		datab	:	in std_logic_vector(width_b-1 downto 0) := (others => '0');
		datac	:	in std_logic_vector(width_c-1 downto 0);
		ena0	:	in std_logic := '1';
		ena1	:	in std_logic := '1';
		ena2	:	in std_logic := '1';
		ena3	:	in std_logic := '1';
		mult_is_saturated	:	out std_logic;
		mult_round	:	in std_logic := '0';
		mult_saturation	:	in std_logic := '0';
		overflow	:	out std_logic;
		result	:	out std_logic_vector(width_result-1 downto 0);
		scanina	:	in std_logic_vector(width_a-1 downto 0) := (others => '0');
		scaninb	:	in std_logic_vector(width_b-1 downto 0) := (others => '0');
		scanouta	:	out std_logic_vector(width_a-1 downto 0);
		scanoutb	:	out std_logic_vector(width_b-1 downto 0);
		signa	:	in std_logic := '0';
		signb	:	in std_logic := '0';
		sourcea	:	in std_logic := '0';
		sourceb	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- altfp_convert parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altfp_convert
	generic (
		intended_device_family	:	string := "unused";
		operation	:	string := "INT2FLOAT";
		rounding	:	string := "TO_NEAREST";
		width_data	:	natural := 32;
		width_exp_input	:	natural := 8;
		width_exp_output	:	natural := 8;
		width_int	:	natural := 32;
		width_man_input	:	natural := 23;
		width_man_output	:	natural := 23;
		width_result	:	natural := 32;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altfp_convert"
	);
	port(
		aclr	:	in std_logic := '0';
		clk_en	:	in std_logic := '1';
		clock	:	in std_logic;
		dataa	:	in std_logic_vector(width_data-1 downto 0);
		nan	:	out std_logic;
		overflow	:	out std_logic;
		result	:	out std_logic_vector(width_result-1 downto 0);
		underflow	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- alt_oct_power parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component alt_oct_power
	generic (
		intended_device_family	:	string := "unused";
		width_ptc	:	natural := 14;
		width_stc	:	natural := 14;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "alt_oct_power"
	);
	port(
		parallelterminationcontrol	:	out std_logic_vector(width_ptc-1 downto 0);
		rdn	:	in std_logic_vector(0 downto 0) := (others => '0');
		rup	:	in std_logic_vector(0 downto 0) := (others => '0');
		rzqin	:	in std_logic_vector(0 downto 0) := (others => '0');
		serdata	:	out std_logic;
		seriesterminationcontrol	:	out std_logic_vector(width_stc-1 downto 0);
		termination_control	:	out std_logic_vector(16-1 downto 0);
		terminationclock	:	out std_logic;
		terminationdata	:	out std_logic;
		terminationselect	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- altfp_matrix_inv parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altfp_matrix_inv
	generic (
		blocks	:	natural := 2;
		cluster	:	natural := 16;
		intended_device_family	:	string := "unused";
		dimension	:	natural := 4;
		width_exp	:	natural := 8;
		width_man	:	natural := 23;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altfp_matrix_inv"
	);
	port(
		busy	:	out std_logic;
		datain	:	in std_logic_vector(width_exp+width_man+1-1 downto 0) := (others => '0');
		dataout	:	out std_logic_vector(width_exp+width_man+1-1 downto 0);
		done	:	out std_logic;
		enable	:	in std_logic := '1';
		load	:	in std_logic := '0';
		outvalid	:	out std_logic;
		reset	:	in std_logic := '0';
		sysclk	:	in std_logic
	);
end component;

------------------------------------------------------------------
-- altaccumulate parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altaccumulate
	generic (
		carry_chain	:	string := "MANUAL";
		carry_chain_length	:	natural := 32;
		intended_device_family	:	string := "unused";
		extra_latency	:	natural := 0;
		lpm_representation	:	string := "UNSIGNED";
		right_shift_distance	:	natural := 0;
		use_wys	:	string := "ON";
		width_in	:	natural;
		width_out	:	natural;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altaccumulate"
	);
	port(
		aclr	:	in std_logic := '0';
		add_sub	:	in std_logic := '1';
		cin	:	in std_logic := '0';
		clken	:	in std_logic := '1';
		clock	:	in std_logic;
		cout	:	out std_logic;
		data	:	in std_logic_vector(width_in-1 downto 0);
		overflow	:	out std_logic;
		result	:	out std_logic_vector(width_out-1 downto 0);
		sign_data	:	in std_logic := '0';
		sload	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- altiobuf_in parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altiobuf_in
	generic (
		intended_device_family	:	string := "unused";
		enable_bus_hold	:	string := "FALSE";
		number_of_channels	:	natural;
		use_differential_mode	:	string := "FALSE";
		use_dynamic_termination_control	:	string := "FALSE";
		use_in_dynamic_delay_chain	:	string := "FALSE";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altiobuf_in"
	);
	port(
		datain	:	in std_logic_vector(number_of_channels-1 downto 0);
		datain_b	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		dataout	:	out std_logic_vector(number_of_channels-1 downto 0);
		dynamicterminationcontrol	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		io_config_clk	:	in std_logic := '0';
		io_config_clkena	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		io_config_datain	:	in std_logic := '0';
		io_config_update	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- alt_c3gxb parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component alt_c3gxb
	generic (
		intended_device_family	:	string := "unused";
		effective_data_rate	:	string := "UNUSED";
		elec_idle_infer_enable	:	string := "false";
		enable_0ppm	:	string := "false";
		equalization_setting	:	natural := 1;
		equalizer_dcgain_setting	:	natural := 0;
		gxb_powerdown_width	:	natural := 1;
		hip_enable	:	string := "false";
		loopback_mode	:	string := "none";
		number_of_channels	:	natural := 1;
		number_of_quads	:	natural := 1;
		number_of_rx_pll	:	natural := 1;
		number_of_tx_pll	:	natural := 1;
		operation_mode	:	string := "duplex";
		pll_bandwidth_type	:	string := "auto";
		pll_control_width	:	natural := 1;
		pll_divide_by	:	string := "UNUSED";
		pll_en_switchover	:	string := "false";
		pll_inclk1_period	:	natural := 5000;
		pll_inclk_period	:	natural := 5000;
		pll_multiply_by	:	string := "UNUSED";
		pll_pfd_fb_mode	:	string := "internal";
		preemphasis_ctrl_1stposttap_setting	:	natural := 0;
		protocol	:	string := "gige";
		receiver_termination	:	string := "OCT_100_OHMS";
		reconfig_calibration	:	string := "false";
		reconfig_dprio_mode	:	natural := 0;
		reconfig_pll_control_width	:	natural := 1;
		rx_0ppm_core_clock	:	string := "false";
		rx_8b_10b_mode	:	string := "none";
		rx_align_loss_sync_error_num	:	natural := 1;
		rx_align_pattern	:	string := "0000000";
		rx_align_pattern_length	:	natural := 7;
		rx_allow_align_polarity_inversion	:	string := "false";
		rx_allow_pipe_polarity_inversion	:	string := "false";
		rx_bitslip_enable	:	string := "false";
		rx_byte_order_pad_pattern	:	string := "0";
		rx_byte_order_pattern	:	string := "0";
		rx_byte_order_pld_ctrl_enable	:	string := "false";
		rx_byte_ordering_mode	:	string := "none";
		rx_cdrctrl_enable	:	string := "false";
		rx_channel_bonding	:	string := "indv";
		rx_channel_width	:	natural := 8;
		rx_common_mode	:	string := "0.82v";
		rx_dataoutfull_width	:	natural := 32;
		rx_datapath_low_latency_mode	:	string := "false";
		rx_datapath_protocol	:	string := "basic";
		rx_deskew_pattern	:	string := "0";
		rx_digitalreset_port_width	:	natural := 1;
		rx_disable_running_disp_in_word_align	:	string := "false";
		rx_dwidth_factor	:	natural := 2;
		rx_enable_bit_reversal	:	string := "false";
		rx_enable_local_divider	:	string := "false";
		rx_enable_lock_to_data_sig	:	string := "false";
		rx_enable_lock_to_refclk_sig	:	string := "false";
		rx_enable_second_order_loop	:	string := "false";
		rx_enable_self_test_mode	:	string := "false";
		rx_flip_rx_out	:	string := "false";
		rx_force_signal_detect	:	string := "false";
		rx_force_signal_detect_dig	:	string := "true";
		rx_infiniband_invalid_code	:	natural := 0;
		rx_insert_pad_on_underflow	:	string := "false";
		rx_loop_1_digital_filter	:	natural := 8;
		rx_num_align_code_groups_in_ordered_set	:	natural := 0;
		rx_num_align_cons_good_data	:	natural := 1;
		rx_num_align_cons_pat	:	natural := 1;
		rx_phfiforegmode	:	string := "false";
		rx_ppmselect	:	natural := 8;
		rx_rate_match_back_to_back	:	string := "false";
		rx_rate_match_fifo_mode	:	string := "none";
		rx_rate_match_fifo_mode_manual_control	:	string := "normal";
		rx_rate_match_pattern1	:	string := "0";
		rx_rate_match_pattern2	:	string := "0";
		rx_rate_match_pattern_size	:	natural := 10;
		rx_rate_match_reset_enable	:	string := "false";
		rx_reconfig_clk_scheme	:	string := "tx_clk_to_rx";
		rx_run_length	:	natural := 4;
		rx_run_length_enable	:	string := "true";
		rx_self_test_mode	:	string := "incremental";
		rx_signal_detect_loss_threshold	:	natural := 3;
		rx_signal_detect_threshold	:	natural := 3;
		rx_signal_detect_valid_threshold	:	natural := 2;
		rx_use_align_state_machine	:	string := "false";
		rx_use_clkout	:	string := "true";
		rx_use_coreclk	:	string := "false";
		rx_use_deskew_fifo	:	string := "false";
		rx_use_double_data_mode	:	string := "false";
		rx_use_external_termination	:	string := "false";
		rx_use_pipe8b10binvpolarity	:	string := "false";
		rx_word_aligner_num_byte	:	natural := 1;
		sim_en_pll_fs_res	:	string := "false";
		starting_channel_number	:	natural := 0;
		top_module_name	:	string := "DPRIO_ONLY";
		transmitter_termination	:	string := "OCT_100_OHMS";
		tx_0ppm_core_clock	:	string := "false";
		tx_8b_10b_mode	:	string := "none";
		tx_allow_polarity_inversion	:	string := "false";
		tx_bitslip_enable	:	string := "false";
		tx_channel_bonding	:	string := "indv";
		tx_channel_width	:	natural := 8;
		tx_clkout_width	:	natural := 1;
		tx_common_mode	:	string := "0.65v";
		tx_datainfull_width	:	natural := 22;
		tx_datapath_low_latency_mode	:	string := "false";
		tx_digitalreset_port_width	:	natural := 1;
		tx_dwidth_factor	:	natural := 2;
		tx_elec_idle_delay	:	natural := 3;
		tx_enable_bit_reversal	:	string := "false";
		tx_enable_idle_selection	:	string := "false";
		tx_enable_self_test_mode	:	string := "false";
		tx_flip_tx_in	:	string := "false";
		tx_force_disparity_mode	:	string := "false";
		tx_phfiforegmode	:	string := "false";
		tx_reconfig_clk_scheme	:	string := "tx_ch0_clk_source";
		tx_self_test_mode	:	string := "incremental";
		tx_slew_rate	:	string := "low";
		tx_transmit_protocol	:	string := "basic";
		tx_use_coreclk	:	string := "false";
		tx_use_double_data_mode	:	string := "false";
		tx_use_external_termination	:	string := "false";
		use_calibration_block	:	string := "true";
		vod_ctrl_setting	:	natural := 0;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "alt_c3gxb"
	);
	port(
		cal_blk_clk	:	in std_logic := '0';
		cal_blk_powerdown	:	in std_logic := '0';
		coreclkout	:	out std_logic_vector(number_of_quads-1 downto 0);
		fixedclk	:	in std_logic := '0';
		fixedclk_fast	:	in std_logic_vector(4*number_of_quads-1 downto 0) := (others => '1');
		gxb_powerdown	:	in std_logic_vector(gxb_powerdown_width-1 downto 0) := (others => '0');
		hip_tx_clkout	:	out std_logic_vector(number_of_channels-1 downto 0);
		pipe8b10binvpolarity	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		pipedatavalid	:	out std_logic_vector(number_of_channels-1 downto 0);
		pipeelecidle	:	out std_logic_vector(number_of_channels-1 downto 0);
		pipephydonestatus	:	out std_logic_vector(number_of_channels-1 downto 0);
		pipestatus	:	out std_logic_vector(number_of_channels*3-1 downto 0);
		pll_areset	:	in std_logic_vector(pll_control_width-1 downto 0) := (others => '0');
		pll_clkswitch	:	in std_logic_vector(number_of_rx_pll-1 downto 0) := (others => '0');
		pll_configupdate	:	in std_logic_vector(reconfig_pll_control_width-1 downto 0) := (others => '0');
		pll_inclk	:	in std_logic_vector(pll_control_width-1 downto 0);
		pll_inclk1	:	in std_logic_vector(number_of_rx_pll-1 downto 0) := (others => '0');
		pll_locked	:	out std_logic_vector(pll_control_width-1 downto 0);
		pll_powerdown	:	in std_logic_vector(pll_control_width-1 downto 0) := (others => '0');
		pll_reconfig_done	:	out std_logic_vector(reconfig_pll_control_width-1 downto 0);
		pll_scanclk	:	in std_logic_vector(reconfig_pll_control_width-1 downto 0) := (others => '0');
		pll_scanclkena	:	in std_logic_vector(reconfig_pll_control_width-1 downto 0) := (others => '0');
		pll_scandata	:	in std_logic_vector(reconfig_pll_control_width-1 downto 0) := (others => '0');
		pll_scandataout	:	out std_logic_vector(reconfig_pll_control_width-1 downto 0);
		powerdn	:	in std_logic_vector(number_of_channels*2-1 downto 0) := (others => '0');
		reconfig_clk	:	in std_logic := '0';
		reconfig_fromgxb	:	out std_logic_vector(5*number_of_quads-1 downto 0);
		reconfig_togxb	:	in std_logic_vector(3 downto 0) := (others => '0');
		rx_a1a2size	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_a1a2sizeout	:	out std_logic_vector(number_of_channels*rx_dwidth_factor-1 downto 0);
		rx_a1detect	:	out std_logic_vector(number_of_channels*rx_word_aligner_num_byte-1 downto 0);
		rx_a2detect	:	out std_logic_vector(number_of_channels*rx_word_aligner_num_byte-1 downto 0);
		rx_analogreset	:	in std_logic_vector(rx_digitalreset_port_width-1 downto 0) := (others => '0');
		rx_bistdone	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_bisterr	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_bitslip	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_bitslipboundaryselectout	:	out std_logic_vector(number_of_channels*5-1 downto 0);
		rx_byteorderalignstatus	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_channelaligned	:	out std_logic_vector(number_of_quads-1 downto 0);
		rx_clkout	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_coreclk	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_ctrldetect	:	out std_logic_vector(number_of_channels*rx_dwidth_factor-1 downto 0);
		rx_datain	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_dataout	:	out std_logic_vector(rx_channel_width*number_of_channels-1 downto 0);
		rx_dataoutfull	:	out std_logic_vector(rx_dataoutfull_width*number_of_channels-1 downto 0);
		rx_digitalreset	:	in std_logic_vector(rx_digitalreset_port_width-1 downto 0) := (others => '0');
		rx_disperr	:	out std_logic_vector(number_of_channels*rx_dwidth_factor-1 downto 0);
		rx_elecidleinfersel	:	in std_logic_vector(number_of_channels*3-1 downto 0) := (others => '0');
		rx_enabyteord	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_enapatternalign	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_errdetect	:	out std_logic_vector(number_of_channels*rx_dwidth_factor-1 downto 0);
		rx_freqlocked	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_invpolarity	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_k1detect	:	out std_logic_vector(number_of_channels*rx_word_aligner_num_byte-1 downto 0);
		rx_k2detect	:	out std_logic_vector(number_of_channels*2-1 downto 0);
		rx_locktodata	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_locktorefclk	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_patterndetect	:	out std_logic_vector(number_of_channels*rx_dwidth_factor-1 downto 0);
		rx_phase_comp_fifo_error	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_phfifooverflow	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_phfifordenable	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '1');
		rx_phfiforeset	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_phfifounderflow	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_phfifowrdisable	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_pipebufferstat	:	out std_logic_vector(number_of_channels*4-1 downto 0);
		rx_powerdown	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_prbscidenable	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_recovclkout	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_revbitorderwa	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_revseriallpbkout	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_rlv	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_rmfifodatadeleted	:	out std_logic_vector(number_of_channels*rx_dwidth_factor-1 downto 0);
		rx_rmfifodatainserted	:	out std_logic_vector(number_of_channels*rx_dwidth_factor-1 downto 0);
		rx_rmfifoempty	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_rmfifofull	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_rmfifordena	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_rmfiforeset	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_rmfifowrena	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_runningdisp	:	out std_logic_vector(number_of_channels*rx_dwidth_factor-1 downto 0);
		rx_seriallpbkin	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_signaldetect	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_syncstatus	:	out std_logic_vector(number_of_channels*rx_dwidth_factor-1 downto 0);
		tx_bitslipboundaryselect	:	in std_logic_vector(number_of_channels*5-1 downto 0) := (others => '0');
		tx_clkout	:	out std_logic_vector(tx_clkout_width-1 downto 0);
		tx_coreclk	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		tx_ctrlenable	:	in std_logic_vector(number_of_channels*tx_dwidth_factor-1 downto 0) := (others => '0');
		tx_datain	:	in std_logic_vector(tx_channel_width*number_of_channels-1 downto 0) := (others => '0');
		tx_datainfull	:	in std_logic_vector(tx_datainfull_width*number_of_channels-1 downto 0) := (others => '0');
		tx_dataout	:	out std_logic_vector(number_of_channels-1 downto 0);
		tx_detectrxloop	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		tx_digitalreset	:	in std_logic_vector(tx_digitalreset_port_width-1 downto 0) := (others => '0');
		tx_dispval	:	in std_logic_vector(number_of_channels*tx_dwidth_factor-1 downto 0) := (others => '0');
		tx_forcedisp	:	in std_logic_vector(number_of_channels*tx_dwidth_factor-1 downto 0) := (others => '0');
		tx_forcedispcompliance	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		tx_forceelecidle	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		tx_invpolarity	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		tx_phase_comp_fifo_error	:	out std_logic_vector(number_of_channels-1 downto 0);
		tx_phfifooverflow	:	out std_logic_vector(number_of_channels-1 downto 0);
		tx_phfiforeset	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		tx_phfifounderflow	:	out std_logic_vector(number_of_channels-1 downto 0);
		tx_pll_clkswitch	:	in std_logic_vector(number_of_tx_pll-1 downto 0) := (others => '0');
		tx_pll_inclk1	:	in std_logic_vector(number_of_tx_pll-1 downto 0) := (others => '0');
		tx_revparallellpbken	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		tx_revseriallpbkin	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		tx_seriallpbkout	:	out std_logic_vector(number_of_channels-1 downto 0)
	);
end component;

------------------------------------------------------------------
-- altufm_parallel parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altufm_parallel
	generic (
		access_mode	:	string;
		intended_device_family	:	string := "unused";
		erase_time	:	natural := 500000000;
		lpm_file	:	string := "UNUSED";
		osc_frequency	:	natural := 180000;
		program_time	:	natural := 1600000;
		width_address	:	natural := 9;
		width_data	:	natural := 16;
		width_ufm_address	:	natural := 9;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altufm_parallel"
	);
	port(
		addr	:	in std_logic_vector(width_address-1 downto 0);
		data_valid	:	out std_logic;
		datain	:	in std_logic_vector(width_data-1 downto 0) := (others => '0');
		dataout	:	out std_logic_vector(width_data-1 downto 0);
		nbusy	:	out std_logic;
		nerase	:	in std_logic := '1';
		nread	:	in std_logic;
		nwrite	:	in std_logic := '1';
		osc	:	out std_logic;
		oscena	:	in std_logic := '1'
	);
end component;

------------------------------------------------------------------
-- alttemp_sense parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component alttemp_sense
	generic (
		clk_frequency	:	string;
		clock_divider_enable	:	string := "off";
		clock_divider_value	:	natural := 40;
		intended_device_family	:	string := "unused";
		number_of_samples	:	natural := 128;
		poi_cal_temperature	:	natural := 85;
		sim_tsdcalo	:	natural := 0;
		use_wys	:	string := "on";
		user_offset_enable	:	string := "off";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "alttemp_sense"
	);
	port(
		aclr	:	in std_logic := '0';
		ce	:	in std_logic := '1';
		clk	:	in std_logic;
		clr	:	in std_logic := '0';
		compouttest	:	in std_logic := '0';
		fdbkctrlfromcore	:	in std_logic := '0';
		offset	:	in std_logic_vector(5 downto 0) := (others => '0');
		offsetout	:	out std_logic_vector(5 downto 0);
		testin	:	in std_logic_vector(7 downto 0) := (others => '0');
		tsd_avg	:	out std_logic_vector(7 downto 0);
		tsd_busy	:	out std_logic;
		tsd_trig	:	in std_logic := '0';
		tsdcaldone	:	out std_logic;
		tsdcalo	:	out std_logic_vector(7 downto 0);
		tsdcompout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- altiobuf_bidir parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altiobuf_bidir
	generic (
		intended_device_family	:	string := "unused";
		enable_bus_hold	:	string := "FALSE";
		number_of_channels	:	natural;
		open_drain_output	:	string := "FALSE";
		use_differential_mode	:	string := "FALSE";
		use_dynamic_termination_control	:	string := "FALSE";
		use_in_dynamic_delay_chain	:	string := "FALSE";
		use_out_dynamic_delay_chain1	:	string := "FALSE";
		use_out_dynamic_delay_chain2	:	string := "FALSE";
		use_termination_control	:	string := "FALSE";
		width_ptc	:	natural := 14;
		width_stc	:	natural := 14;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altiobuf_bidir"
	);
	port(
		datain	:	in std_logic_vector(number_of_channels-1 downto 0);
		dataio	:	inout std_logic_vector(number_of_channels-1 downto 0);
		dataio_b	:	inout std_logic_vector(number_of_channels-1 downto 0);
		dataout	:	out std_logic_vector(number_of_channels-1 downto 0);
		dynamicterminationcontrol	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		dynamicterminationcontrol_b	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		io_config_clk	:	in std_logic := '0';
		io_config_clkena	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		io_config_datain	:	in std_logic := '0';
		io_config_update	:	in std_logic := '0';
		oe	:	in std_logic_vector(number_of_channels-1 downto 0);
		oe_b	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '1');
		parallelterminationcontrol	:	in std_logic_vector(width_ptc * number_of_channels-1 downto 0) := (others => '0');
		parallelterminationcontrol_b	:	in std_logic_vector(width_ptc * number_of_channels-1 downto 0) := (others => '0');
		seriesterminationcontrol	:	in std_logic_vector(width_stc * number_of_channels-1 downto 0) := (others => '0');
		seriesterminationcontrol_b	:	in std_logic_vector(width_stc * number_of_channels-1 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- altclkctrl parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altclkctrl
	generic (
		clock_type	:	string := "AUTO";
		intended_device_family	:	string := "unused";
		ena_register_mode	:	string := "falling edge";
		implement_in_les	:	string := "OFF";
		number_of_clocks	:	natural := 4;
		use_glitch_free_switch_over_implementation	:	string := "OFF";
		width_clkselect	:	natural := 2;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altclkctrl"
	);
	port(
		clkselect	:	in std_logic_vector(width_clkselect-1 downto 0) := (others => '0');
		ena	:	in std_logic := '1';
		inclk	:	in std_logic_vector(number_of_clocks-1 downto 0) := (others => '0');
		outclk	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- altfp_abs parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altfp_abs
	generic (
		intended_device_family	:	string := "unused";
		pipeline	:	natural := 0;
		width_exp	:	natural := 8;
		width_man	:	natural := 23;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altfp_abs"
	);
	port(
		aclr	:	in std_logic := '0';
		clk_en	:	in std_logic := '1';
		clock	:	in std_logic := '0';
		data	:	in std_logic_vector(width_exp+width_man+1-1 downto 0);
		division_by_zero	:	out std_logic;
		division_by_zero_in	:	in std_logic := '0';
		nan	:	out std_logic;
		nan_in	:	in std_logic := '0';
		overflow	:	out std_logic;
		overflow_in	:	in std_logic := '0';
		result	:	out std_logic_vector(width_exp+width_man+1-1 downto 0);
		underflow	:	out std_logic;
		underflow_in	:	in std_logic := '0';
		zero	:	out std_logic;
		zero_in	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- alt_oct_aii parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component alt_oct_aii
	generic (
		intended_device_family	:	string := "unused";
		divide_intosc_by	:	natural := 1;
		left_shift_termination_code	:	string := "FALSE";
		power_down	:	string := "TRUE";
		pulldown_adder	:	natural := 0;
		pullup_adder	:	natural := 0;
		pullup_control_to_core	:	string := "FALSE";
		runtime_control	:	string := "FALSE";
		shift_vref_rdn	:	string := "TRUE";
		shift_vref_rup	:	string := "TRUE";
		shifted_vref_control	:	string := "TRUE";
		test_mode	:	string := "FALSE";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "alt_oct_aii"
	);
	port(
		cal_shift_busy	:	out std_logic_vector(0 downto 0);
		calibration_request	:	in std_logic_vector(0 downto 0) := (others => '0');
		clock	:	in std_logic := '0';
		comparatorprobe	:	out std_logic;
		rdn	:	in std_logic_vector(0 downto 0);
		rup	:	in std_logic_vector(0 downto 0);
		scanclock	:	in std_logic := '0';
		scanin	:	in std_logic := '0';
		scaninmux	:	in std_logic := '0';
		scanout	:	out std_logic;
		scanshiftmux	:	in std_logic := '0';
		termination_control	:	out std_logic_vector(16-1 downto 0);
		terminationcontrolprobe	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- altdqs parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altdqs
	generic (
		delay_buffer_mode	:	string := "low";
		delay_chain_mode	:	string := "static";
		intended_device_family	:	string := "unused";
		dll_delay_chain_length	:	natural := 12;
		dll_delayctrl_mode	:	string := "normal";
		dll_jitter_reduction	:	string := "true";
		dll_offsetctrl_mode	:	string := "none";
		dll_phase_shift	:	string := "unused";
		dll_static_offset	:	string := "0";
		dll_use_reset	:	string := "false";
		dll_use_upndnin	:	string := "false";
		dll_use_upndninclkena	:	string := "false";
		dqs_ctrl_latches_enable	:	string := "true";
		dqs_delay_chain_length	:	natural := 3;
		dqs_delay_chain_setting	:	string := "0";
		dqs_delay_requirement	:	string := "unused";
		dqs_edge_detect_enable	:	string := "false";
		dqs_oe_async_reset	:	string := "none";
		dqs_oe_power_up	:	string := "low";
		dqs_oe_register_mode	:	string := "register";
		dqs_oe_sync_reset	:	string := "none";
		dqs_open_drain_output	:	string := "false";
		dqs_output_async_reset	:	string := "none";
		dqs_output_power_up	:	string := "low";
		dqs_output_sync_reset	:	string := "none";
		dqs_use_dedicated_delayctrlin	:	string := "true";
		dqsn_mode	:	string := "none";
		extend_oe_disable	:	string := "true";
		gated_dqs	:	string := "false";
		has_dqs_delay_requirement	:	string := "true";
		input_frequency	:	string;
		invert_output	:	string := "false";
		number_of_dqs	:	natural;
		number_of_dqs_controls	:	natural := 1;
		sim_invalid_lock	:	natural := 100000;
		sim_valid_lock	:	natural := 1;
		tie_off_dqs_oe_clock_enable	:	string := "false";
		tie_off_dqs_output_clock_enable	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altdqs"
	);
	port(
		dll_addnsub	:	in std_logic := '0';
		dll_delayctrlout	:	out std_logic_vector(5 downto 0);
		dll_offset	:	in std_logic_vector(5 downto 0) := (others => '0');
		dll_reset	:	in std_logic := '0';
		dll_upndnin	:	in std_logic := '0';
		dll_upndninclkena	:	in std_logic := '1';
		dll_upndnout	:	out std_logic;
		dqddioinclk	:	out std_logic_vector(number_of_dqs-1 downto 0);
		dqinclk	:	out std_logic_vector(number_of_dqs-1 downto 0);
		dqs_areset	:	in std_logic_vector(number_of_dqs_controls-1 downto 0) := (others => '0');
		dqs_datain_h	:	in std_logic_vector(number_of_dqs-1 downto 0);
		dqs_datain_l	:	in std_logic_vector(number_of_dqs-1 downto 0);
		dqs_delayctrlin	:	in std_logic_vector(5 downto 0) := (others => '0');
		dqs_padio	:	inout std_logic_vector(number_of_dqs-1 downto 0);
		dqs_sreset	:	in std_logic_vector(number_of_dqs_controls-1 downto 0) := (others => '0');
		dqsn_padio	:	inout std_logic_vector(number_of_dqs-1 downto 0);
		dqsundelayedout	:	out std_logic_vector(number_of_dqs-1 downto 0);
		enable_dqs	:	in std_logic_vector(number_of_dqs-1 downto 0) := (others => '1');
		inclk	:	in std_logic := '0';
		oe	:	in std_logic_vector(number_of_dqs_controls-1 downto 0) := (others => '1');
		outclk	:	in std_logic_vector(number_of_dqs_controls-1 downto 0);
		outclkena	:	in std_logic_vector(number_of_dqs_controls-1 downto 0) := (others => '1')
	);
end component;

------------------------------------------------------------------
-- alt_c3gxb_reconfig parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component alt_c3gxb_reconfig
	generic (
		base_port_width	:	natural := 1;
		channel_address_width	:	natural := 1;
		data_latency	:	natural := 0;
		intended_device_family	:	string := "unused";
		enable_buf_cal	:	string := "FALSE";
		enable_buf_cal_func_sim	:	string := "FALSE";
		enable_chl_addr_for_analog_ctrl	:	string := "FALSE";
		enable_full_write	:	string := "FALSE";
		enable_illegal_mode_check	:	string := "FALSE";
		enable_rx_equalization	:	string := "TRUE";
		enable_rx_tx_duplex_sel	:	string := "FALSE";
		enable_self_recovery	:	string := "FALSE";
		mif_address_width	:	natural := 5;
		number_of_channels	:	natural;
		number_of_reconfig_ports	:	natural;
		read_base_port_width	:	natural := 1;
		reconfig_fromgxb_width	:	natural := 5;
		reconfig_mode_sel_width	:	natural := 3;
		reconfig_togxb_width	:	natural := 4;
		rx_eqdcgain_port_width	:	natural := 2;
		tx_preemp_port_width	:	natural := 4;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "alt_c3gxb_reconfig"
	);
	port(
		busy	:	out std_logic;
		channel_reconfig_done	:	out std_logic;
		data_valid	:	out std_logic;
		error	:	out std_logic;
		gxb_address	:	in std_logic_vector(3-1 downto 0) := (others => '0');
		logical_channel_address	:	in std_logic_vector(channel_address_width-1 downto 0) := (others => '0');
		offset_cancellation_reset	:	in std_logic := '0';
		read	:	in std_logic := '0';
		reconfig_address	:	in std_logic_vector(mif_address_width-1 downto 0) := (others => '0');
		reconfig_address_en	:	out std_logic;
		reconfig_address_out	:	out std_logic_vector(mif_address_width-1 downto 0);
		reconfig_clk	:	in std_logic;
		reconfig_data	:	in std_logic_vector(16-1 downto 0) := (others => '0');
		reconfig_data_mask	:	in std_logic_vector(16-1 downto 0) := (others => '0');
		reconfig_data_out	:	out std_logic_vector(16-1 downto 0);
		reconfig_fromgxb	:	in std_logic_vector(reconfig_fromgxb_width-1 downto 0);
		reconfig_mode_sel	:	in std_logic_vector(reconfig_mode_sel_width-1 downto 0) := (others => '0');
		reconfig_reset	:	in std_logic := '0';
		reconfig_togxb	:	out std_logic_vector(reconfig_togxb_width-1 downto 0);
		reset_reconfig_address	:	in std_logic := '0';
		rx_eqctrl	:	in std_logic_vector(base_port_width*4-1 downto 0) := (others => '0');
		rx_eqctrl_out	:	out std_logic_vector(read_base_port_width*4-1 downto 0);
		rx_eqdcgain	:	in std_logic_vector(base_port_width*rx_eqdcgain_port_width-1 downto 0) := (others => '0');
		rx_eqdcgain_out	:	out std_logic_vector(read_base_port_width*rx_eqdcgain_port_width-1 downto 0);
		rx_tx_duplex_sel	:	in std_logic_vector(2-1 downto 0) := (others => '0');
		tx_preemp	:	in std_logic_vector(base_port_width*tx_preemp_port_width-1 downto 0) := (others => '0');
		tx_preemp_out	:	out std_logic_vector(read_base_port_width*tx_preemp_port_width-1 downto 0);
		tx_vodctrl	:	in std_logic_vector(base_port_width*3-1 downto 0) := (others => '0');
		tx_vodctrl_out	:	out std_logic_vector(read_base_port_width*3-1 downto 0);
		write_all	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- alt_cal parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component alt_cal
	generic (
		cal_bbpd_first	:	string := "FALSE";
		channel_address_width	:	natural := 1;
		error_signals	:	string := "FALSE";
		number_of_channels	:	natural;
		sim_model_mode	:	string := "FALSE";
		watch_length	:	natural := 100;
		lpm_type	:	string := "alt_cal"
	);
	port(
		busy	:	out std_logic;
		cal_error	:	out std_logic_vector(number_of_channels-1 downto 0);
		clock	:	in std_logic;
		dprio_addr	:	out std_logic_vector(15 downto 0);
		dprio_busy	:	in std_logic;
		dprio_datain	:	in std_logic_vector(15 downto 0);
		dprio_dataout	:	out std_logic_vector(15 downto 0);
		dprio_rden	:	out std_logic;
		dprio_wren	:	out std_logic;
		quad_addr	:	out std_logic_vector(8 downto 0);
		remap_addr	:	in std_logic_vector(11 downto 0) := (others => '0');
		reset	:	in std_logic := '0';
		retain_addr	:	out std_logic;
		start	:	in std_logic := '0';
		testbuses	:	in std_logic_vector(number_of_channels*4-1 downto 0) := (others => '0');
		transceiver_init	:	in std_logic
	);
end component;

------------------------------------------------------------------
-- altdq_dqs parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altdq_dqs
	generic (
		add_mem_fitter_group_assignments	:	string := "TRUE";
		delay_buffer_mode	:	string := "LOW";
		delay_dqs_enable_by_half_cycle	:	string := "FALSE";
		intended_device_family	:	string := "unused";
		dm_loc	:	string := "NONE";
		dq_half_rate_use_dataoutbypass	:	string := "FALSE";
		dq_input_reg_async_mode	:	string := "NONE";
		dq_input_reg_clk_source	:	string := "DQS_BUS";
		dq_input_reg_mode	:	string := "NONE";
		dq_input_reg_power_up	:	string := "LOW";
		dq_input_reg_sync_mode	:	string := "NONE";
		dq_input_reg_use_clkn	:	string := "FALSE";
		dq_ipa_add_input_cycle_delay	:	string := "FALSE";
		dq_ipa_add_phase_transfer_reg	:	string := "FALSE";
		dq_ipa_bypass_output_register	:	string := "FALSE";
		dq_ipa_invert_phase	:	string := "FALSE";
		dq_ipa_phase_setting	:	natural := 0;
		dq_oe_reg_async_mode	:	string := "NONE";
		dq_oe_reg_mode	:	string := "NONE";
		dq_oe_reg_power_up	:	string := "LOW";
		dq_oe_reg_sync_mode	:	string := "NONE";
		dq_output_reg_async_mode	:	string := "NONE";
		dq_output_reg_mode	:	string := "NONE";
		dq_output_reg_power_up	:	string := "LOW";
		dq_output_reg_sync_mode	:	string := "NONE";
		dq_resync_reg_mode	:	string := "NONE";
		dqs_ctrl_latches_enable	:	string := "FALSE";
		dqs_delay_chain_delayctrlin_source	:	string := "CORE";
		dqs_delay_chain_phase_setting	:	natural := 0;
		dqs_dqsn_mode	:	string := "NONE";
		dqs_enable_ctrl_add_phase_transfer_reg	:	string := "FALSE";
		dqs_enable_ctrl_invert_phase	:	string := "FALSE";
		dqs_enable_ctrl_phase_setting	:	natural := 0;
		dqs_input_frequency	:	string := "UNUSED";
		dqs_oe_reg_async_mode	:	string := "NONE";
		dqs_oe_reg_mode	:	string := "NONE";
		dqs_oe_reg_power_up	:	string := "LOW";
		dqs_oe_reg_sync_mode	:	string := "NONE";
		dqs_offsetctrl_enable	:	string := "FALSE";
		dqs_output_reg_async_mode	:	string := "NONE";
		dqs_output_reg_mode	:	string := "NONE";
		dqs_output_reg_power_up	:	string := "LOW";
		dqs_output_reg_sync_mode	:	string := "NONE";
		dqs_phase_shift	:	natural := 0;
		io_clock_divider_clk_source	:	string := "CORE";
		io_clock_divider_invert_phase	:	string := "FALSE";
		io_clock_divider_phase_setting	:	natural := 0;
		level_dqs_enable	:	string := "FALSE";
		number_of_bidir_dq	:	natural := 0;
		number_of_clk_divider	:	natural := 0;
		number_of_dk	:	natural := 0;
		number_of_dqs	:	natural := 1;
		number_of_input_dq	:	natural := 0;
		number_of_output_dq	:	natural := 0;
		oct_reg_mode	:	string := "NONE";
		qvld_loc	:	string := "NONE";
		rldramii_mode	:	string := "NONE";
		use_dm	:	string := "FALSE";
		use_dq_input_delay_chain	:	string := "FALSE";
		use_dq_ipa	:	string := "FALSE";
		use_dq_ipa_phasectrlin	:	string := "TRUE";
		use_dq_oe_delay_chain1	:	string := "FALSE";
		use_dq_oe_delay_chain2	:	string := "FALSE";
		use_dq_oe_path	:	string := "FALSE";
		use_dq_output_delay_chain1	:	string := "FALSE";
		use_dq_output_delay_chain2	:	string := "FALSE";
		use_dqs	:	string := "FALSE";
		use_dqs_delay_chain	:	string := "FALSE";
		use_dqs_delay_chain_phasectrlin	:	string := "FALSE";
		use_dqs_enable	:	string := "FALSE";
		use_dqs_enable_ctrl	:	string := "FALSE";
		use_dqs_enable_ctrl_phasectrlin	:	string := "TRUE";
		use_dqs_input_delay_chain	:	string := "FALSE";
		use_dqs_input_path	:	string := "FALSE";
		use_dqs_oe_delay_chain1	:	string := "FALSE";
		use_dqs_oe_delay_chain2	:	string := "FALSE";
		use_dqs_oe_path	:	string := "FALSE";
		use_dqs_output_delay_chain1	:	string := "FALSE";
		use_dqs_output_delay_chain2	:	string := "FALSE";
		use_dqs_output_path	:	string := "FALSE";
		use_dqsbusout_delay_chain	:	string := "FALSE";
		use_dqsenable_delay_chain	:	string := "FALSE";
		use_dynamic_oct	:	string := "FALSE";
		use_half_rate	:	string := "FALSE";
		use_half_rate_on_input	:	string := "FALSE";
		use_half_rate_on_output	:	string := "FALSE";
		use_io_clock_divider_masterin	:	string := "FALSE";
		use_io_clock_divider_phasectrlin	:	string := "FALSE";
		use_io_clock_divider_slaveout	:	string := "FALSE";
		use_oct_delay_chain1	:	string := "FALSE";
		use_oct_delay_chain2	:	string := "FALSE";
		use_qvld	:	string := "FALSE";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altdq_dqs"
	);
	port(
		bidir_dq_areset	:	in std_logic_vector(number_of_bidir_dq-1 downto 0) := (others => '0');
		bidir_dq_hr_input_data_out	:	out std_logic_vector(number_of_bidir_dq * 4-1 downto 0);
		bidir_dq_hr_oe_in	:	in std_logic_vector(number_of_bidir_dq * 2-1 downto 0) := (others => '0');
		bidir_dq_hr_output_data_in	:	in std_logic_vector(number_of_bidir_dq * 4-1 downto 0) := (others => '0');
		bidir_dq_input_data_in	:	in std_logic_vector(number_of_bidir_dq-1 downto 0) := (others => '0');
		bidir_dq_input_data_out	:	out std_logic_vector(number_of_bidir_dq-1 downto 0);
		bidir_dq_input_data_out_high	:	out std_logic_vector(number_of_bidir_dq-1 downto 0);
		bidir_dq_input_data_out_low	:	out std_logic_vector(number_of_bidir_dq-1 downto 0);
		bidir_dq_io_config_ena	:	in std_logic_vector(number_of_bidir_dq-1 downto 0) := (others => '1');
		bidir_dq_oct_out	:	out std_logic_vector(number_of_bidir_dq-1 downto 0);
		bidir_dq_oe_in	:	in std_logic_vector(number_of_bidir_dq-1 downto 0) := (others => '0');
		bidir_dq_oe_out	:	out std_logic_vector(number_of_bidir_dq-1 downto 0);
		bidir_dq_output_data_in	:	in std_logic_vector(number_of_bidir_dq-1 downto 0) := (others => '0');
		bidir_dq_output_data_in_high	:	in std_logic_vector(number_of_bidir_dq-1 downto 0) := (others => '0');
		bidir_dq_output_data_in_low	:	in std_logic_vector(number_of_bidir_dq-1 downto 0) := (others => '0');
		bidir_dq_output_data_out	:	out std_logic_vector(number_of_bidir_dq-1 downto 0);
		bidir_dq_sreset	:	in std_logic_vector(number_of_bidir_dq-1 downto 0) := (others => '0');
		config_clk	:	in std_logic := '0';
		config_datain	:	in std_logic := '0';
		config_update	:	in std_logic := '0';
		core_delayctrlin	:	in std_logic_vector(5 downto 0) := (others => '0');
		dk_areset	:	in std_logic_vector(number_of_dk-1 downto 0) := (others => '0');
		dk_hr_oe_in	:	in std_logic_vector(number_of_dk * 2-1 downto 0) := (others => '0');
		dk_hr_output_data_in	:	in std_logic_vector(number_of_dk * 4-1 downto 0) := (others => '0');
		dk_io_config_ena	:	in std_logic_vector(number_of_dk-1 downto 0) := (others => '1');
		dk_oe_in	:	in std_logic_vector(number_of_dk-1 downto 0) := (others => '0');
		dk_oe_out	:	out std_logic_vector(number_of_dk-1 downto 0);
		dk_output_data_in	:	in std_logic_vector(number_of_dk-1 downto 0) := (others => '0');
		dk_output_data_in_high	:	in std_logic_vector(number_of_dk-1 downto 0) := (others => '0');
		dk_output_data_in_low	:	in std_logic_vector(number_of_dk-1 downto 0) := (others => '0');
		dk_output_data_out	:	out std_logic_vector(number_of_dk-1 downto 0);
		dk_sreset	:	in std_logic_vector(number_of_dk-1 downto 0) := (others => '0');
		dkn_areset	:	in std_logic_vector(number_of_dk-1 downto 0) := (others => '0');
		dkn_hr_oe_in	:	in std_logic_vector(number_of_dk * 2-1 downto 0) := (others => '0');
		dkn_hr_output_data_in	:	in std_logic_vector(number_of_dk * 4-1 downto 0) := (others => '0');
		dkn_io_config_ena	:	in std_logic_vector(number_of_dk-1 downto 0) := (others => '1');
		dkn_oe_in	:	in std_logic_vector(number_of_dk-1 downto 0) := (others => '0');
		dkn_oe_out	:	out std_logic_vector(number_of_dk-1 downto 0);
		dkn_output_data_in	:	in std_logic_vector(number_of_dk-1 downto 0) := (others => '0');
		dkn_output_data_in_high	:	in std_logic_vector(number_of_dk-1 downto 0) := (others => '0');
		dkn_output_data_in_low	:	in std_logic_vector(number_of_dk-1 downto 0) := (others => '0');
		dkn_output_data_out	:	out std_logic_vector(number_of_dk-1 downto 0);
		dkn_sreset	:	in std_logic_vector(number_of_dk-1 downto 0) := (others => '0');
		dll_delayctrlin	:	in std_logic_vector(5 downto 0) := (others => '0');
		dm_areset	:	in std_logic := '0';
		dm_hr_oe_in	:	in std_logic_vector(1 downto 0) := (others => '0');
		dm_hr_output_data_in	:	in std_logic_vector(3 downto 0) := (others => '0');
		dm_io_config_ena	:	in std_logic := '1';
		dm_oe_in	:	in std_logic := '0';
		dm_oe_out	:	out std_logic;
		dm_output_data_in	:	in std_logic := '0';
		dm_output_data_in_high	:	in std_logic := '0';
		dm_output_data_in_low	:	in std_logic := '0';
		dm_output_data_out	:	out std_logic;
		dm_sreset	:	in std_logic := '0';
		dq_hr_output_reg_clk	:	in std_logic := '0';
		dq_input_reg_clk	:	in std_logic := '0';
		dq_input_reg_clkena	:	in std_logic := '1';
		dq_ipa_clk	:	in std_logic := '0';
		dq_output_reg_clk	:	in std_logic := '0';
		dq_output_reg_clkena	:	in std_logic := '1';
		dq_resync_reg_clk	:	in std_logic := '0';
		dqs_areset	:	in std_logic_vector(number_of_dqs-1 downto 0) := (others => '0');
		dqs_bus_out	:	out std_logic_vector(number_of_dqs-1 downto 0);
		dqs_config_ena	:	in std_logic := '1';
		dqs_enable_ctrl_clk	:	in std_logic := '1';
		dqs_enable_ctrl_hr_datainhi	:	in std_logic := '0';
		dqs_enable_ctrl_hr_datainlo	:	in std_logic := '0';
		dqs_enable_ctrl_in	:	in std_logic := '1';
		dqs_enable_in	:	in std_logic := '1';
		dqs_hr_oe_in	:	in std_logic_vector(number_of_dqs * 2-1 downto 0) := (others => '0');
		dqs_hr_output_data_in	:	in std_logic_vector(number_of_dqs * 4-1 downto 0) := (others => '0');
		dqs_hr_output_reg_clk	:	in std_logic := '0';
		dqs_input_data_in	:	in std_logic_vector(number_of_dqs-1 downto 0) := (others => '0');
		dqs_input_data_out	:	out std_logic_vector(number_of_dqs-1 downto 0);
		dqs_io_config_ena	:	in std_logic_vector(number_of_dqs-1 downto 0) := (others => '1');
		dqs_oct_out	:	out std_logic;
		dqs_oe_in	:	in std_logic_vector(number_of_dqs-1 downto 0) := (others => '0');
		dqs_oe_out	:	out std_logic_vector(number_of_dqs-1 downto 0);
		dqs_output_data_in	:	in std_logic_vector(number_of_dqs-1 downto 0) := (others => '0');
		dqs_output_data_in_high	:	in std_logic_vector(number_of_dqs-1 downto 0) := (others => '0');
		dqs_output_data_in_low	:	in std_logic_vector(number_of_dqs-1 downto 0) := (others => '0');
		dqs_output_data_out	:	out std_logic_vector(number_of_dqs-1 downto 0);
		dqs_output_reg_clk	:	in std_logic := '0';
		dqs_output_reg_clkena	:	in std_logic := '1';
		dqs_sreset	:	in std_logic_vector(number_of_dqs-1 downto 0) := (others => '0');
		dqsn_areset	:	in std_logic_vector(number_of_dqs-1 downto 0) := (others => '0');
		dqsn_bus_out	:	out std_logic_vector(number_of_dqs-1 downto 0);
		dqsn_hr_oe_in	:	in std_logic_vector(number_of_dqs * 2-1 downto 0) := (others => '0');
		dqsn_hr_output_data_in	:	in std_logic_vector(number_of_dqs * 4-1 downto 0) := (others => '0');
		dqsn_input_data_in	:	in std_logic_vector(number_of_dqs-1 downto 0) := (others => '0');
		dqsn_input_data_out	:	out std_logic_vector(number_of_dqs-1 downto 0);
		dqsn_io_config_ena	:	in std_logic_vector(number_of_dqs-1 downto 0) := (others => '1');
		dqsn_oct_out	:	out std_logic;
		dqsn_oe_in	:	in std_logic_vector(number_of_dqs-1 downto 0) := (others => '0');
		dqsn_oe_out	:	out std_logic_vector(number_of_dqs-1 downto 0);
		dqsn_output_data_in	:	in std_logic_vector(number_of_dqs-1 downto 0) := (others => '0');
		dqsn_output_data_in_high	:	in std_logic_vector(number_of_dqs-1 downto 0) := (others => '0');
		dqsn_output_data_in_low	:	in std_logic_vector(number_of_dqs-1 downto 0) := (others => '0');
		dqsn_output_data_out	:	out std_logic_vector(number_of_dqs-1 downto 0);
		dqsn_sreset	:	in std_logic_vector(number_of_dqs-1 downto 0) := (others => '0');
		dqsupdateen	:	in std_logic := '0';
		hr_oct_in	:	in std_logic_vector(1 downto 0) := (others => '0');
		hr_oct_reg_clk	:	in std_logic := '0';
		input_dq_areset	:	in std_logic_vector(number_of_input_dq-1 downto 0) := (others => '0');
		input_dq_hr_input_data_out	:	out std_logic_vector(number_of_input_dq * 4-1 downto 0);
		input_dq_input_data_in	:	in std_logic_vector(number_of_input_dq-1 downto 0) := (others => '0');
		input_dq_input_data_out	:	out std_logic_vector(number_of_input_dq-1 downto 0);
		input_dq_input_data_out_high	:	out std_logic_vector(number_of_input_dq-1 downto 0);
		input_dq_input_data_out_low	:	out std_logic_vector(number_of_input_dq-1 downto 0);
		input_dq_io_config_ena	:	in std_logic_vector(number_of_input_dq-1 downto 0) := (others => '1');
		input_dq_oct_out	:	out std_logic_vector(number_of_input_dq-1 downto 0);
		input_dq_sreset	:	in std_logic_vector(number_of_input_dq-1 downto 0) := (others => '0');
		io_clock_divider_clk	:	in std_logic := '0';
		io_clock_divider_clkout	:	out std_logic_vector(number_of_clk_divider-1 downto 0);
		io_clock_divider_masterin	:	in std_logic := '0';
		io_clock_divider_slaveout	:	out std_logic;
		oct_in	:	in std_logic := '0';
		oct_reg_clk	:	in std_logic := '0';
		offsetctrlin	:	in std_logic_vector(5 downto 0) := (others => '0');
		output_dq_areset	:	in std_logic_vector(number_of_output_dq-1 downto 0) := (others => '0');
		output_dq_hr_oe_in	:	in std_logic_vector(number_of_output_dq * 2-1 downto 0) := (others => '0');
		output_dq_hr_output_data_in	:	in std_logic_vector(number_of_output_dq * 4-1 downto 0) := (others => '0');
		output_dq_io_config_ena	:	in std_logic_vector(number_of_output_dq-1 downto 0) := (others => '1');
		output_dq_oe_in	:	in std_logic_vector(number_of_output_dq-1 downto 0) := (others => '0');
		output_dq_oe_out	:	out std_logic_vector(number_of_output_dq-1 downto 0);
		output_dq_output_data_in	:	in std_logic_vector(number_of_output_dq-1 downto 0) := (others => '0');
		output_dq_output_data_in_high	:	in std_logic_vector(number_of_output_dq-1 downto 0) := (others => '0');
		output_dq_output_data_in_low	:	in std_logic_vector(number_of_output_dq-1 downto 0) := (others => '0');
		output_dq_output_data_out	:	out std_logic_vector(number_of_output_dq-1 downto 0);
		output_dq_sreset	:	in std_logic_vector(number_of_output_dq-1 downto 0) := (others => '0');
		qvld_areset	:	in std_logic := '0';
		qvld_hr_input_data_out	:	out std_logic_vector(3 downto 0);
		qvld_input_data_in	:	in std_logic := '0';
		qvld_input_data_out	:	out std_logic;
		qvld_input_data_out_high	:	out std_logic;
		qvld_input_data_out_low	:	out std_logic;
		qvld_io_config_ena	:	in std_logic := '1';
		qvld_oct_out	:	out std_logic;
		qvld_sreset	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- altfp_sqrt parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altfp_sqrt
	generic (
		intended_device_family	:	string := "unused";
		exception_handling	:	string := "YES";
		pipeline	:	natural := 28;
		rounding	:	string := "TO_NEAREST";
		width_exp	:	natural := 8;
		width_man	:	natural := 23;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altfp_sqrt"
	);
	port(
		aclr	:	in std_logic := '0';
		clk_en	:	in std_logic := '1';
		clock	:	in std_logic;
		data	:	in std_logic_vector(width_exp+width_man+1-1 downto 0);
		nan	:	out std_logic;
		overflow	:	out std_logic;
		result	:	out std_logic_vector(width_exp+width_man+1-1 downto 0);
		zero	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- altsqrt parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component altsqrt
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altsqrt";
		pipeline	:	natural := 0;
		q_port_width	:	natural := 1;
		r_port_width	:	natural := 1;
		width	:	natural	);
	port(
		aclr	:	in std_logic := '0';
		clk	:	in std_logic := '1';
		ena	:	in std_logic := '1';
		q	:	out std_logic_vector(Q_PORT_WIDTH-1 downto 0);
		radical	:	in std_logic_vector(WIDTH-1 downto 0);
		remainder	:	out std_logic_vector(R_PORT_WIDTH-1 downto 0)
	);
end component;

------------------------------------------------------------------
-- altsource_probe parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component altsource_probe
	generic (
		enable_metastability	:	string := "NO";
		instance_id	:	string := "UNUSED";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altsource_probe";
		probe_width	:	natural := 1;
		sld_auto_instance_index	:	string := "YES";
		sld_instance_index	:	natural := 0;
		sld_ir_width	:	natural := 4;
		sld_node_info	:	natural := 4746752;
		source_initial_value	:	string := "0";
		source_width	:	natural := 1	);
	port(
		clrn	:	in std_logic;
		ena	:	in std_logic;
		ir_in	:	in std_logic_vector(sld_ir_width-1 downto 0);
		ir_out	:	out std_logic_vector(sld_ir_width-1 downto 0);
		jtag_state_cdr	:	in std_logic;
		jtag_state_cir	:	in std_logic;
		jtag_state_e1dr	:	in std_logic;
		jtag_state_sdr	:	in std_logic;
		jtag_state_tlr	:	in std_logic;
		jtag_state_udr	:	in std_logic;
		jtag_state_uir	:	in std_logic;
		probe	:	in std_logic_vector(probe_width-1 downto 0);
		raw_tck	:	in std_logic;
		source	:	out std_logic_vector(source_width-1 downto 0);
		source_clk	:	in std_logic;
		source_ena	:	in std_logic;
		tdi	:	in std_logic;
		tdo	:	out std_logic;
		usr1	:	in std_logic
	);
end component;

------------------------------------------------------------------
-- altclklock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component altclklock
	generic (
		clock0_boost	:	natural := 1;
		clock0_divide	:	natural := 1;
		clock0_settings	:	string := "UNUSED";
		clock0_time_delay	:	natural := 0;
		clock1_boost	:	natural := 1;
		clock1_divide	:	natural := 1;
		clock1_settings	:	string := "UNUSED";
		clock1_time_delay	:	natural := 0;
		clock2_boost	:	natural := 1;
		clock2_divide	:	natural := 1;
		clock2_settings	:	string := "UNUSED";
		clock2_time_delay	:	natural := 0;
		clock_ext_boost	:	natural := 1;
		clock_ext_divide	:	natural := 1;
		clock_ext_settings	:	string := "UNUSED";
		clock_ext_time_delay	:	natural := 0;
		inclock_period	:	natural := 10000;
		inclock_settings	:	string := "UNUSED";
		intended_device_family	:	string := "UNUSED";
		invalid_lock_cycles	:	natural := 5;
		invalid_lock_multiplier	:	natural := 5;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altclklock";
		operation_mode	:	string := "UNUSED";
		outclock_phase_shift	:	natural := 0;
		valid_lock_cycles	:	natural := 5;
		valid_lock_multiplier	:	natural := 5	);
	port(
		clock0	:	out std_logic;
		clock1	:	out std_logic;
		clock2	:	out std_logic;
		clock_ext	:	out std_logic;
		fbin	:	in std_logic := '1';
		inclock	:	in std_logic;
		inclocken	:	in std_logic := '1';
		locked	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- altddio_in parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altddio_in
	generic (
		intended_device_family	:	string := "unused";
		implement_input_in_lcell	:	string := "ON";
		invert_input_clocks	:	string := "OFF";
		power_up_high	:	string := "OFF";
		width	:	natural;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altddio_in"
	);
	port(
		aclr	:	in std_logic := '0';
		aset	:	in std_logic := '0';
		datain	:	in std_logic_vector(width-1 downto 0);
		dataout_h	:	out std_logic_vector(width-1 downto 0);
		dataout_l	:	out std_logic_vector(width-1 downto 0);
		inclock	:	in std_logic;
		inclocken	:	in std_logic := '1';
		sclr	:	in std_logic := '0';
		sset	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- altlvds_rx parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altlvds_rx
	generic (
		buffer_implementation	:	string := "RAM";
		cds_mode	:	string := "UNUSED";
		common_rx_tx_pll	:	string := "ON";
		data_align_rollover	:	natural := 4;
		data_rate	:	string := "UNUSED";
		deserialization_factor	:	natural := 4;
		intended_device_family	:	string := "unused";
		dpa_initial_phase_value	:	natural := 0;
		dpll_lock_count	:	natural := 0;
		dpll_lock_window	:	natural := 0;
		enable_clock_pin_mode	:	string := "UNUSED";
		enable_dpa_align_to_rising_edge_only	:	string := "OFF";
		enable_dpa_calibration	:	string := "ON";
		enable_dpa_fifo	:	string := "OFF";
		enable_dpa_initial_phase_selection	:	string := "OFF";
		enable_dpa_mode	:	string := "OFF";
		enable_dpa_pll_calibration	:	string := "OFF";
		enable_soft_cdr_mode	:	string := "OFF";
		implement_in_les	:	string := "OFF";
		inclock_boost	:	natural := 0;
		inclock_data_alignment	:	string := "EDGE_ALIGNED";
		inclock_period	:	natural := 0;
		inclock_phase_shift	:	natural := 0;
		input_data_rate	:	natural := 0;
		lose_lock_on_one_change	:	string := "OFF";
		number_of_channels	:	natural;
		outclock_resource	:	string := "AUTO";
		pll_operation_mode	:	string := "NORMAL";
		pll_self_reset_on_loss_lock	:	string := "OFF";
		port_rx_channel_data_align	:	string := "PORT_CONNECTIVITY";
		port_rx_data_align	:	string := "PORT_CONNECTIVITY";
		refclk_frequency	:	string := "UNUSED";
		registered_data_align_input	:	string := "ON";
		registered_output	:	string := "ON";
		reset_fifo_at_first_lock	:	string := "ON";
		rx_align_data_reg	:	string := "RISING_EDGE";
		sim_dpa_is_negative_ppm_drift	:	string := "OFF";
		sim_dpa_net_ppm_variation	:	natural := 0;
		sim_dpa_output_clock_phase_shift	:	natural := 0;
		use_coreclock_input	:	string := "OFF";
		use_dpll_rawperror	:	string := "OFF";
		use_external_pll	:	string := "OFF";
		use_no_phase_shift	:	string := "ON";
		x_on_bitslip	:	string := "ON";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altlvds_rx"
	);
	port(
		dpa_pll_cal_busy	:	out std_logic;
		dpa_pll_recal	:	in std_logic := '0';
		pll_areset	:	in std_logic := '0';
		pll_phasecounterselect	:	out std_logic_vector(3 downto 0);
		pll_phasedone	:	in std_logic := '1';
		pll_phasestep	:	out std_logic;
		pll_phaseupdown	:	out std_logic;
		pll_scanclk	:	out std_logic;
		rx_cda_max	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_cda_reset	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_channel_data_align	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_coreclk	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '1');
		rx_data_align	:	in std_logic := '0';
		rx_data_align_reset	:	in std_logic := '0';
		rx_data_reset	:	in std_logic := '0';
		rx_deskew	:	in std_logic := '0';
		rx_divfwdclk	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_dpa_lock_reset	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_dpa_locked	:	out std_logic_vector(number_of_channels-1 downto 0);
		rx_dpaclock	:	in std_logic := '0';
		rx_dpll_enable	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '1');
		rx_dpll_hold	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_dpll_reset	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_enable	:	in std_logic := '1';
		rx_fifo_reset	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_in	:	in std_logic_vector(number_of_channels-1 downto 0);
		rx_inclock	:	in std_logic;
		rx_locked	:	out std_logic;
		rx_out	:	out std_logic_vector(deserialization_factor*number_of_channels-1 downto 0);
		rx_outclock	:	out std_logic;
		rx_pll_enable	:	in std_logic := '1';
		rx_readclock	:	in std_logic := '0';
		rx_reset	:	in std_logic_vector(number_of_channels-1 downto 0) := (others => '0');
		rx_syncclock	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- altfp_mult parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altfp_mult
	generic (
		dedicated_multiplier_circuitry	:	string := "YES";
		denormal_support	:	string := "YES";
		intended_device_family	:	string := "unused";
		exception_handling	:	string := "NO";
		pipeline	:	natural := 5;
		reduced_functionality	:	string := "NO";
		rounding	:	string := "TO_NEAREST";
		width_exp	:	natural := 8;
		width_man	:	natural := 23;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altfp_mult"
	);
	port(
		aclr	:	in std_logic := '0';
		clk_en	:	in std_logic := '1';
		clock	:	in std_logic;
		dataa	:	in std_logic_vector(width_exp+width_man+1-1 downto 0);
		datab	:	in std_logic_vector(width_exp+width_man+1-1 downto 0);
		denormal	:	out std_logic;
		indefinite	:	out std_logic;
		nan	:	out std_logic;
		overflow	:	out std_logic;
		result	:	out std_logic_vector(width_exp+width_man+1-1 downto 0);
		underflow	:	out std_logic;
		zero	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- altsyncram parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component altsyncram
	generic (
		address_aclr_a	:	string := "UNUSED";
		address_aclr_b	:	string := "NONE";
		address_reg_b	:	string := "CLOCK1";
		byte_size	:	natural := 8;
		byteena_aclr_a	:	string := "UNUSED";
		byteena_aclr_b	:	string := "NONE";
		byteena_reg_b	:	string := "CLOCK1";
		clock_enable_core_a	:	string := "USE_INPUT_CLKEN";
		clock_enable_core_b	:	string := "USE_INPUT_CLKEN";
		clock_enable_input_a	:	string := "NORMAL";
		clock_enable_input_b	:	string := "NORMAL";
		clock_enable_output_a	:	string := "NORMAL";
		clock_enable_output_b	:	string := "NORMAL";
		intended_device_family	:	string := "unused";
		ecc_pipeline_stage_enabled	:	string := "FALSE";
		enable_ecc	:	string := "FALSE";
		implement_in_les	:	string := "OFF";
		indata_aclr_a	:	string := "UNUSED";
		indata_aclr_b	:	string := "NONE";
		indata_reg_b	:	string := "CLOCK1";
		init_file	:	string := "UNUSED";
		init_file_layout	:	string := "PORT_A";
		maximum_depth	:	natural := 0;
		numwords_a	:	natural := 0;
		numwords_b	:	natural := 0;
		operation_mode	:	string := "BIDIR_DUAL_PORT";
		outdata_aclr_a	:	string := "NONE";
		outdata_aclr_b	:	string := "NONE";
		outdata_reg_a	:	string := "UNREGISTERED";
		outdata_reg_b	:	string := "UNREGISTERED";
		power_up_uninitialized	:	string := "FALSE";
		ram_block_type	:	string := "AUTO";
		rdcontrol_aclr_b	:	string := "NONE";
		rdcontrol_reg_b	:	string := "CLOCK1";
		read_during_write_mode_mixed_ports	:	string := "DONT_CARE";
		read_during_write_mode_port_a	:	string := "NEW_DATA_NO_NBE_READ";
		read_during_write_mode_port_b	:	string := "NEW_DATA_NO_NBE_READ";
		stratixiv_m144k_allow_dual_clocks	:	string := "ON";
		width_a	:	natural;
		width_b	:	natural := 1;
		width_byteena_a	:	natural := 1;
		width_byteena_b	:	natural := 1;
		width_eccstatus	:	natural := 3;
		widthad_a	:	natural;
		widthad_b	:	natural := 1;
		wrcontrol_aclr_a	:	string := "UNUSED";
		wrcontrol_aclr_b	:	string := "NONE";
		wrcontrol_wraddress_reg_b	:	string := "CLOCK1";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altsyncram"
	);
	port(
		aclr0	:	in std_logic := '0';
		aclr1	:	in std_logic := '0';
		address_a	:	in std_logic_vector(widthad_a-1 downto 0);
		address_b	:	in std_logic_vector(widthad_b-1 downto 0) := (others => '1');
		addressstall_a	:	in std_logic := '0';
		addressstall_b	:	in std_logic := '0';
		byteena_a	:	in std_logic_vector(width_byteena_a-1 downto 0) := (others => '1');
		byteena_b	:	in std_logic_vector(width_byteena_b-1 downto 0) := (others => '1');
		clock0	:	in std_logic := '1';
		clock1	:	in std_logic := '1';
		clocken0	:	in std_logic := '1';
		clocken1	:	in std_logic := '1';
		clocken2	:	in std_logic := '1';
		clocken3	:	in std_logic := '1';
		data_a	:	in std_logic_vector(width_a-1 downto 0) := (others => '1');
		data_b	:	in std_logic_vector(width_b-1 downto 0) := (others => '1');
		eccstatus	:	out std_logic_vector(width_eccstatus-1 downto 0);
		q_a	:	out std_logic_vector(width_a-1 downto 0);
		q_b	:	out std_logic_vector(width_b-1 downto 0);
		rden_a	:	in std_logic := '1';
		rden_b	:	in std_logic := '1';
		wren_a	:	in std_logic := '0';
		wren_b	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- altparallel_flash_loader parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component altparallel_flash_loader
	generic (
		addr_width	:	natural := 20;
		auto_restart	:	string := "OFF";
		burst_mode	:	natural := 0;
		burst_mode_intel	:	natural := 0;
		burst_mode_latency_count	:	natural := 4;
		burst_mode_numonyx	:	natural := 0;
		burst_mode_spansion	:	natural := 0;
		clk_divisor	:	natural := 1;
		conf_data_width	:	natural := 1;
		conf_wait_timer_width	:	natural := 16;
		dclk_create_delay	:	natural := 0;
		dclk_divisor	:	natural := 1;
		decompressor_mode	:	string := "NONE";
		disable_crc_checkbox	:	natural := 0;
		enhanced_flash_programming	:	natural := 0;
		extra_addr_byte	:	natural := 0;
		features_cfg	:	natural := 1;
		features_pgm	:	natural := 1;
		fifo_size	:	natural := 16;
		flash_burst_extra_cycle	:	natural := 0;
		flash_data_width	:	natural := 16;
		flash_ecc_checkbox	:	natural := 0;
		flash_nreset_checkbox	:	natural := 0;
		flash_nreset_counter	:	natural := 1;
		flash_static_wait_width	:	natural := 15;
		flash_type	:	string := "CFI_FLASH";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "altparallel_flash_loader";
		n_flash	:	natural := 1;
		nand_size	:	natural := 67108864;
		nflash_mfc	:	string := "NUMONYX";
		normal_mode	:	natural := 1;
		nrb_addr	:	natural := 65667072;
		option_bits_start_address	:	natural := 0;
		page_clk_divisor	:	natural := 1;
		page_mode	:	natural := 0;
		pfl_rsu_watchdog_enabled	:	natural := 0;
		qflash_fast_speed	:	natural := 0;
		qflash_mfc	:	string := "ALTERA";
		qspi_data_delay	:	natural := 0;
		qspi_data_delay_count	:	natural := 1;
		rsu_watchdog_counter	:	natural := 100000000;
		safe_mode_halt	:	natural := 0;
		safe_mode_retry	:	natural := 1;
		safe_mode_revert	:	natural := 0;
		safe_mode_revert_addr	:	natural := 0;
		tristate_checkbox	:	natural := 0;
		us_unit_counter	:	natural := 1	);
	port(
		flash_addr	:	out std_logic_vector(addr_width-1 downto 0);
		flash_ale	:	out std_logic;
		flash_cle	:	out std_logic;
		flash_clk	:	out std_logic;
		flash_data	:	inout std_logic_vector(flash_data_width-1 downto 0);
		flash_io	:	inout std_logic_vector(7 downto 0);
		flash_io0	:	inout std_logic_vector(n_flash-1 downto 0);
		flash_io1	:	inout std_logic_vector(n_flash-1 downto 0);
		flash_io2	:	inout std_logic_vector(n_flash-1 downto 0);
		flash_io3	:	inout std_logic_vector(n_flash-1 downto 0);
		flash_nadv	:	out std_logic;
		flash_nce	:	out std_logic_vector(n_flash-1 downto 0);
		flash_ncs	:	out std_logic_vector(n_flash-1 downto 0);
		flash_noe	:	out std_logic;
		flash_nreset	:	out std_logic;
		flash_nwe	:	out std_logic;
		flash_rdy	:	in std_logic := '1';
		flash_sck	:	out std_logic_vector(n_flash-1 downto 0);
		fpga_conf_done	:	in std_logic := '0';
		fpga_data	:	out std_logic_vector(conf_data_width-1 downto 0);
		fpga_dclk	:	out std_logic;
		fpga_nconfig	:	out std_logic;
		fpga_nstatus	:	in std_logic := '0';
		fpga_pgm	:	in std_logic_vector(2 downto 0) := (others => '0');
		pfl_clk	:	in std_logic := '0';
		pfl_flash_access_granted	:	in std_logic := '0';
		pfl_flash_access_request	:	out std_logic;
		pfl_nreconfigure	:	in std_logic := '1';
		pfl_nreset	:	in std_logic := '0';
		pfl_reset_watchdog	:	in std_logic := '0';
		pfl_watchdog_error	:	out std_logic
	);
end component;

--clearbox auto-generated components begin
end altera_mf_components;
