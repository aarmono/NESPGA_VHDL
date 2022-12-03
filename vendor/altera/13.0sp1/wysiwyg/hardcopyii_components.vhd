library IEEE, hardcopyii;
use IEEE.STD_LOGIC_1164.all;

package hardcopyii_components is

--clearbox auto-generated components begin
--Dont add any component declarations after this section

------------------------------------------------------------------
-- hardcopyii_termination parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component hardcopyii_termination
	generic (
		half_rate_clock	:	string := "false";
		left_shift	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "hardcopyii_termination";
		power_down	:	string := "true";
		pulldown_adder	:	natural := 0;
		pullup_adder	:	natural := 0;
		pullup_control_to_core	:	string := "true";
		runtime_control	:	string := "false";
		test_mode	:	string := "false";
		use_both_compares	:	string := "false";
		use_core_control	:	string := "false";
		use_high_voltage_compare	:	string := "true"	);
	port(
		incrdn	:	out std_logic;
		incrup	:	out std_logic;
		rdn	:	in std_logic := '0';
		rup	:	in std_logic := '0';
		terminationclear	:	in std_logic := '0';
		terminationclock	:	in std_logic := '0';
		terminationcontrol	:	out std_logic_vector(13 downto 0);
		terminationcontrolprobe	:	out std_logic_vector(6 downto 0);
		terminationenable	:	in std_logic := '1';
		terminationpulldown	:	in std_logic_vector(6 downto 0) := (others => '0');
		terminationpullup	:	in std_logic_vector(6 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- hardcopyii_jtag parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component hardcopyii_jtag
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "hardcopyii_jtag"	);
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

------------------------------------------------------------------
-- hardcopyii_ram_block parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component hardcopyii_ram_block
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
		port_a_address_width	:	natural := 1;
		port_a_byte_enable_mask_width	:	natural := 1;
		port_a_byte_size	:	natural := 8;
		port_a_data_out_clear	:	string := "UNUSED";
		port_a_data_out_clock	:	string := "none";
		port_a_data_width	:	natural := 1;
		port_a_disable_ce_on_input_registers	:	string := "off";
		port_a_disable_ce_on_output_registers	:	string := "off";
		port_a_first_address	:	natural;
		port_a_first_bit_number	:	natural;
		port_a_last_address	:	natural;
		port_a_logical_ram_depth	:	natural := 0;
		port_a_logical_ram_width	:	natural := 0;
		port_b_address_clock	:	string := "UNUSED";
		port_b_address_width	:	natural := 1;
		port_b_byte_enable_clock	:	string := "UNUSED";
		port_b_byte_enable_mask_width	:	natural := 1;
		port_b_byte_size	:	natural := 8;
		port_b_data_in_clock	:	string := "UNUSED";
		port_b_data_out_clear	:	string := "UNUSED";
		port_b_data_out_clock	:	string := "none";
		port_b_data_width	:	natural := 1;
		port_b_disable_ce_on_input_registers	:	string := "off";
		port_b_disable_ce_on_output_registers	:	string := "off";
		port_b_first_address	:	natural := 0;
		port_b_first_bit_number	:	natural := 0;
		port_b_last_address	:	natural := 0;
		port_b_logical_ram_depth	:	natural := 0;
		port_b_logical_ram_width	:	natural := 0;
		port_b_read_enable_write_enable_clock	:	string := "UNUSED";
		power_up_uninitialized	:	string := "false";
		ram_block_type	:	string;
		width_eccstatus	:	natural := 3;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "hardcopyii_ram_block"
	);
	port(
		clk0	:	in std_logic;
		clk1	:	in std_logic := '0';
		clr0	:	in std_logic := '0';
		clr1	:	in std_logic := '0';
		ena0	:	in std_logic := '1';
		ena1	:	in std_logic := '1';
		portaaddr	:	in std_logic_vector(port_a_address_width-1 downto 0) := (others => '0');
		portaaddrstall	:	in std_logic := '0';
		portabyteenamasks	:	in std_logic_vector(port_a_byte_enable_mask_width-1 downto 0) := (others => '1');
		portadatain	:	in std_logic_vector(port_a_data_width-1 downto 0) := (others => '0');
		portadataout	:	out std_logic_vector(port_a_data_width-1 downto 0);
		portawe	:	in std_logic := '0';
		portbaddr	:	in std_logic_vector(port_b_address_width-1 downto 0) := (others => '0');
		portbaddrstall	:	in std_logic := '0';
		portbbyteenamasks	:	in std_logic_vector(port_b_byte_enable_mask_width-1 downto 0) := (others => '1');
		portbdatain	:	in std_logic_vector(port_b_data_width-1 downto 0) := (others => '0');
		portbdataout	:	out std_logic_vector(port_b_data_width-1 downto 0);
		portbrewe	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- hardcopyii_mac_mult parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component hardcopyii_mac_mult
	generic (
		bypass_multiplier	:	string := "no";
		dataa_clear	:	string := "none";
		dataa_clock	:	string := "none";
		dataa_width	:	natural;
		datab_clear	:	string := "none";
		datab_clock	:	string := "none";
		datab_width	:	natural;
		output_clear	:	string := "none";
		output_clock	:	string := "none";
		round_clear	:	string := "none";
		round_clock	:	string := "none";
		saturate_clear	:	string := "none";
		saturate_clock	:	string := "none";
		signa_clear	:	string := "none";
		signa_clock	:	string := "none";
		signa_internally_grounded	:	string := "false";
		signb_clear	:	string := "none";
		signb_clock	:	string := "none";
		signb_internally_grounded	:	string := "false";
		lpm_type	:	string := "hardcopyii_mac_mult"
	);
	port(
		aclr	:	in std_logic_vector(3 downto 0) := (others => '0');
		clk	:	in std_logic_vector(3 downto 0) := (others => '1');
		dataa	:	in std_logic_vector(dataa_width-1 downto 0) := (others => '1');
		datab	:	in std_logic_vector(datab_width-1 downto 0) := (others => '1');
		dataout	:	out std_logic_vector(dataa_width+datab_width-1 downto 0);
		ena	:	in std_logic_vector(3 downto 0) := (others => '1');
		round	:	in std_logic := '0';
		saturate	:	in std_logic := '0';
		scanina	:	in std_logic_vector(dataa_width-1 downto 0) := (others => '0');
		scaninb	:	in std_logic_vector(datab_width-1 downto 0) := (others => '0');
		scanouta	:	out std_logic_vector(dataa_width-1 downto 0);
		scanoutb	:	out std_logic_vector(datab_width-1 downto 0);
		signa	:	in std_logic := '1';
		signb	:	in std_logic := '1';
		sourcea	:	in std_logic := '0';
		sourceb	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- hardcopyii_dll parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component hardcopyii_dll
	generic (
		delay_buffer_mode	:	string := "low";
		delay_chain_length	:	natural := 16;
		delayctrlout_mode	:	string := "normal";
		input_frequency	:	string;
		jitter_reduction	:	string := "false";
		offsetctrlout_mode	:	string := "static";
		sim_loop_delay_increment	:	natural := 100;
		sim_loop_intrinsic_delay	:	natural := 1000;
		sim_valid_lock	:	natural := 1;
		sim_valid_lockcount	:	natural := 90;
		static_delay_ctrl	:	natural := 0;
		static_offset	:	string;
		use_upndnin	:	string := "false";
		use_upndninclkena	:	string := "false";
		lpm_type	:	string := "hardcopyii_dll"
	);
	port(
		addnsub	:	in std_logic := '1';
		aload	:	in std_logic := '0';
		clk	:	in std_logic;
		delayctrlout	:	out std_logic_vector(5 downto 0);
		dqsupdate	:	out std_logic;
		offset	:	in std_logic_vector(5 downto 0) := (others => '0');
		offsetctrlout	:	out std_logic_vector(5 downto 0);
		upndnin	:	in std_logic := '0';
		upndninclkena	:	in std_logic := '1';
		upndnout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- hardcopyii_mac_out parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component hardcopyii_mac_out
	generic (
		addnsub0_clear	:	string := "none";
		addnsub0_clock	:	string := "none";
		addnsub0_pipeline_clear	:	string := "none";
		addnsub0_pipeline_clock	:	string := "none";
		addnsub1_clear	:	string := "none";
		addnsub1_clock	:	string := "none";
		addnsub1_pipeline_clear	:	string := "none";
		addnsub1_pipeline_clock	:	string := "none";
		dataa_width	:	natural := 1;
		datab_width	:	natural := 1;
		datac_width	:	natural := 1;
		datad_width	:	natural := 1;
		dataout_width	:	natural := 144;
		multabsaturate_clear	:	string := "none";
		multabsaturate_clock	:	string := "none";
		multabsaturate_pipeline_clear	:	string := "none";
		multabsaturate_pipeline_clock	:	string := "none";
		multcdsaturate_clear	:	string := "none";
		multcdsaturate_clock	:	string := "none";
		multcdsaturate_pipeline_clear	:	string := "none";
		multcdsaturate_pipeline_clock	:	string := "none";
		operation_mode	:	string;
		output_clear	:	string := "none";
		output_clock	:	string := "none";
		round0_clear	:	string := "none";
		round0_clock	:	string := "none";
		round0_pipeline_clear	:	string := "none";
		round0_pipeline_clock	:	string := "none";
		round1_clear	:	string := "none";
		round1_clock	:	string := "none";
		round1_pipeline_clear	:	string := "none";
		round1_pipeline_clock	:	string := "none";
		saturate_clear	:	string := "none";
		saturate_clock	:	string := "none";
		saturate_pipeline_clear	:	string := "none";
		saturate_pipeline_clock	:	string := "none";
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
		lpm_type	:	string := "hardcopyii_mac_out"
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
		multabsaturate	:	in std_logic := '0';
		multcdsaturate	:	in std_logic := '0';
		round0	:	in std_logic := '0';
		round1	:	in std_logic := '0';
		saturate	:	in std_logic := '0';
		signa	:	in std_logic := '1';
		signb	:	in std_logic := '1';
		zeroacc	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- hardcopyii_lvds_receiver parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component hardcopyii_lvds_receiver
	generic (
		align_to_rising_edge_only	:	string := "on";
		channel_width	:	natural;
		data_align_rollover	:	natural := 2;
		dpa_debug	:	string := "off";
		enable_dpa	:	string := "off";
		lose_lock_on_one_change	:	string := "off";
		reset_fifo_at_first_lock	:	string := "on";
		use_serial_feedback_input	:	string := "off";
		x_on_bitslip	:	string := "on";
		lpm_type	:	string := "hardcopyii_lvds_receiver"
	);
	port(
		bitslip	:	in std_logic := '0';
		bitslipmax	:	out std_logic;
		bitslipreset	:	in std_logic := '0';
		clk0	:	in std_logic := '0';
		datain	:	in std_logic;
		dataout	:	out std_logic_vector(channel_width-1 downto 0);
		dpahold	:	in std_logic := '0';
		dpalock	:	out std_logic;
		dpareset	:	in std_logic := '0';
		dpaswitch	:	in std_logic := '1';
		enable0	:	in std_logic := '0';
		fiforeset	:	in std_logic := '0';
		postdpaserialdataout	:	out std_logic;
		serialdataout	:	out std_logic;
		serialfbk	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- hardcopyii_lcell_ff parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component hardcopyii_lcell_ff
	generic (
		x_on_violation	:	string := "on";
		lpm_type	:	string := "hardcopyii_lcell_ff"
	);
	port(
		aclr	:	in std_logic := '0';
		adatasdata	:	in std_logic := '0';
		aload	:	in std_logic := '0';
		clk	:	in std_logic;
		datain	:	in std_logic;
		ena	:	in std_logic := '1';
		regout	:	out std_logic;
		sclr	:	in std_logic := '0';
		sload	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- hardcopyii_io parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component hardcopyii_io
	generic (
		bus_hold	:	string := "false";
		ddio_mode	:	string := "none";
		ddioinclk_input	:	string := "negated_inclk";
		dqs_ctrl_latches_enable	:	string := "false";
		dqs_delay_buffer_mode	:	string := "none";
		dqs_edge_detect_enable	:	string := "false";
		dqs_input_frequency	:	string := "unused";
		dqs_offsetctrl_enable	:	string := "false";
		dqs_out_mode	:	string := "none";
		dqs_phase_shift	:	natural := 0;
		extend_oe_disable	:	string := "false";
		gated_dqs	:	string := "false";
		inclk_input	:	string := "normal";
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
		sim_dqs_delay_increment	:	natural := 0;
		sim_dqs_intrinsic_delay	:	natural := 0;
		sim_dqs_offset_increment	:	natural := 0;
		tie_off_oe_clock_enable	:	string := "false";
		tie_off_output_clock_enable	:	string := "false";
		lpm_type	:	string := "hardcopyii_io"
	);
	port(
		areset	:	in std_logic := '0';
		combout	:	out std_logic;
		datain	:	in std_logic := '0';
		ddiodatain	:	in std_logic := '0';
		ddioinclk	:	in std_logic := '0';
		ddioregout	:	out std_logic;
		delayctrlin	:	in std_logic_vector(5 downto 0) := (others => '0');
		dqsbusout	:	out std_logic;
		dqsupdateen	:	in std_logic := '1';
		inclk	:	in std_logic := '0';
		inclkena	:	in std_logic := '1';
		linkin	:	in std_logic := '0';
		linkout	:	out std_logic;
		oe	:	in std_logic := '1';
		offsetctrlin	:	in std_logic_vector(5 downto 0) := (others => '0');
		outclk	:	in std_logic := '0';
		outclkena	:	in std_logic := '1';
		padio	:	inout std_logic;
		regout	:	out std_logic;
		sreset	:	in std_logic := '0';
		terminationcontrol	:	in std_logic_vector(13 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- hardcopyii_lvds_transmitter parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component hardcopyii_lvds_transmitter
	generic (
		bypass_serializer	:	string := "false";
		channel_width	:	natural;
		differential_drive	:	natural := 0;
		invert_clock	:	string := "false";
		preemphasis_setting	:	natural := 0;
		use_falling_clock_edge	:	string := "false";
		use_post_dpa_serial_data_input	:	string := "false";
		use_serial_data_input	:	string := "false";
		vod_setting	:	natural := 0;
		lpm_type	:	string := "hardcopyii_lvds_transmitter"
	);
	port(
		clk0	:	in std_logic := '0';
		datain	:	in std_logic_vector(channel_width-1 downto 0) := (others => '0');
		dataout	:	out std_logic;
		enable0	:	in std_logic;
		postdpaserialdatain	:	in std_logic := '0';
		serialdatain	:	in std_logic := '0';
		serialfdbkout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- hardcopyii_lcell_comb parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component hardcopyii_lcell_comb
	generic (
		extended_lut	:	string := "off";
		lut_mask	:	std_logic_vector(63 downto 0) := "0000000000000000000000000000000000000000000000000000000000000000";
		shared_arith	:	string := "off";
		lpm_type	:	string := "hardcopyii_lcell_comb"
	);
	port(
		cin	:	in std_logic := '0';
		combout	:	out std_logic;
		cout	:	out std_logic;
		dataa	:	in std_logic := '0';
		datab	:	in std_logic := '0';
		datac	:	in std_logic := '0';
		datad	:	in std_logic := '0';
		datae	:	in std_logic := '0';
		dataf	:	in std_logic := '0';
		datag	:	in std_logic := '0';
		sharein	:	in std_logic := '0';
		shareout	:	out std_logic;
		sumout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- hardcopyii_clkctrl parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component hardcopyii_clkctrl
	generic (
		clock_type	:	string;
		lpm_type	:	string := "hardcopyii_clkctrl"
	);
	port(
		clkselect	:	in std_logic_vector(1 downto 0);
		ena	:	in std_logic;
		inclk	:	in std_logic_vector(3 downto 0);
		outclk	:	out std_logic
	);
end component;

--clearbox auto-generated components end
end hardcopyii_components;
