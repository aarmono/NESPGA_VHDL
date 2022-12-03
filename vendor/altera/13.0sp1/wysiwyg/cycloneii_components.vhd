library IEEE, cycloneii;
use IEEE.STD_LOGIC_1164.all;

package cycloneii_components is

--clearbox auto-generated components begin
--Dont add any component declarations after this section

------------------------------------------------------------------
-- cycloneii_clkctrl parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component cycloneii_clkctrl
	generic (
		clock_type	:	string;
		ena_register_mode	:	string := "falling edge";
		lpm_type	:	string := "cycloneii_clkctrl"
	);
	port(
		clkselect	:	in std_logic_vector(1 downto 0);
		ena	:	in std_logic;
		inclk	:	in std_logic_vector(3 downto 0);
		outclk	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cycloneii_mac_mult parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component cycloneii_mac_mult
	generic (
		dataa_clock	:	string := "none";
		dataa_width	:	natural;
		datab_clock	:	string := "none";
		datab_width	:	natural;
		signa_clock	:	string := "none";
		signb_clock	:	string := "none";
		lpm_type	:	string := "cycloneii_mac_mult"
	);
	port(
		aclr	:	in std_logic := '0';
		clk	:	in std_logic := '1';
		dataa	:	in std_logic_vector(dataa_width-1 downto 0) := (others => '1');
		datab	:	in std_logic_vector(datab_width-1 downto 0) := (others => '1');
		dataout	:	out std_logic_vector(dataa_width+datab_width-1 downto 0);
		ena	:	in std_logic := '1';
		signa	:	in std_logic := '1';
		signb	:	in std_logic := '1'
	);
end component;

------------------------------------------------------------------
-- cycloneii_pll parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component cycloneii_pll
	generic (
		bandwidth	:	natural := 0;
		bandwidth_type	:	string := "auto";
		c0_high	:	natural := 1;
		c0_initial	:	natural := 1;
		c0_low	:	natural := 1;
		c0_mode	:	string := "bypass";
		c0_ph	:	natural := 0;
		c0_test_source	:	natural := 5;
		c1_high	:	natural := 1;
		c1_initial	:	natural := 1;
		c1_low	:	natural := 1;
		c1_mode	:	string := "bypass";
		c1_ph	:	natural := 0;
		c1_test_source	:	natural := 5;
		c1_use_casc_in	:	string := "off";
		c2_high	:	natural := 1;
		c2_initial	:	natural := 1;
		c2_low	:	natural := 1;
		c2_mode	:	string := "bypass";
		c2_ph	:	natural := 0;
		c2_test_source	:	natural := 5;
		c2_use_casc_in	:	string := "off";
		c3_high	:	natural := 1;
		c3_initial	:	natural := 1;
		c3_low	:	natural := 1;
		c3_mode	:	string := "bypass";
		c3_ph	:	natural := 0;
		c3_test_source	:	natural := 5;
		c3_use_casc_in	:	string := "off";
		c4_high	:	natural := 1;
		c4_initial	:	natural := 1;
		c4_low	:	natural := 1;
		c4_mode	:	string := "bypass";
		c4_ph	:	natural := 0;
		c4_test_source	:	natural := 5;
		c4_use_casc_in	:	string := "off";
		c5_high	:	natural := 1;
		c5_initial	:	natural := 1;
		c5_low	:	natural := 1;
		c5_mode	:	string := "bypass";
		c5_ph	:	natural := 0;
		c5_test_source	:	natural := 5;
		c5_use_casc_in	:	string := "off";
		charge_pump_current	:	natural := 10;
		clk0_counter	:	string := "c0";
		clk0_divide_by	:	natural := 1;
		clk0_duty_cycle	:	natural := 50;
		clk0_multiply_by	:	natural := 0;
		clk0_output_frequency	:	natural := 0;
		clk0_phase_shift	:	string := "UNUSED";
		clk0_phase_shift_num	:	natural := 0;
		clk0_use_even_counter_mode	:	string := "off";
		clk0_use_even_counter_value	:	string := "off";
		clk1_counter	:	string := "c1";
		clk1_divide_by	:	natural := 1;
		clk1_duty_cycle	:	natural := 50;
		clk1_multiply_by	:	natural := 0;
		clk1_output_frequency	:	natural := 0;
		clk1_phase_shift	:	string := "UNUSED";
		clk1_phase_shift_num	:	natural := 0;
		clk1_use_even_counter_mode	:	string := "off";
		clk1_use_even_counter_value	:	string := "off";
		clk2_counter	:	string := "c2";
		clk2_divide_by	:	natural := 1;
		clk2_duty_cycle	:	natural := 50;
		clk2_multiply_by	:	natural := 0;
		clk2_output_frequency	:	natural := 0;
		clk2_phase_shift	:	string := "UNUSED";
		clk2_phase_shift_num	:	natural := 0;
		clk2_use_even_counter_mode	:	string := "off";
		clk2_use_even_counter_value	:	string := "off";
		clk3_counter	:	string := "c3";
		clk3_divide_by	:	natural := 1;
		clk3_duty_cycle	:	natural := 50;
		clk3_multiply_by	:	natural := 0;
		clk3_output_frequency	:	natural := 0;
		clk3_phase_shift	:	string := "UNUSED";
		clk3_use_even_counter_mode	:	string := "off";
		clk3_use_even_counter_value	:	string := "off";
		clk4_counter	:	string := "c4";
		clk4_divide_by	:	natural := 1;
		clk4_duty_cycle	:	natural := 50;
		clk4_multiply_by	:	natural := 0;
		clk4_output_frequency	:	natural := 0;
		clk4_phase_shift	:	string := "UNUSED";
		clk4_use_even_counter_mode	:	string := "off";
		clk4_use_even_counter_value	:	string := "off";
		clk5_counter	:	string := "c5";
		clk5_divide_by	:	natural := 1;
		clk5_duty_cycle	:	natural := 50;
		clk5_multiply_by	:	natural := 0;
		clk5_output_frequency	:	natural := 0;
		clk5_phase_shift	:	string := "UNUSED";
		clk5_use_even_counter_mode	:	string := "off";
		clk5_use_even_counter_value	:	string := "off";
		common_rx_tx	:	string := "off";
		compensate_clock	:	string := "clk0";
		down_spread	:	string := "UNUSED";
		enable_switch_over_counter	:	string := "off";
		feedback_source	:	string := "clk0";
		gate_lock_counter	:	natural := 1;
		gate_lock_signal	:	string := "no";
		inclk0_input_frequency	:	natural := 0;
		inclk1_input_frequency	:	natural := 0;
		invalid_lock_multiplier	:	natural := 5;
		loop_filter_c	:	natural := 1;
		loop_filter_r	:	string := "UNUSED";
		m	:	natural := 0;
		m2	:	natural := 1;
		m_initial	:	natural := 1;
		m_ph	:	natural := 0;
		m_test_source	:	natural := 5;
		n	:	natural := 1;
		n2	:	natural := 1;
		operation_mode	:	string := "normal";
		pfd_max	:	natural := 0;
		pfd_min	:	natural := 0;
		pll_compensation_delay	:	natural := 0;
		pll_type	:	string := "auto";
		qualify_conf_done	:	string := "off";
		self_reset_on_gated_loss_lock	:	string := "off";
		sim_gate_lock_device_behavior	:	string := "OFF";
		simulation_type	:	string := "functional";
		spread_frequency	:	natural := 0;
		ss	:	natural := 0;
		switch_over_counter	:	natural := 1;
		switch_over_on_gated_lock	:	string := "off";
		switch_over_on_lossclk	:	string := "off";
		switch_over_type	:	string := "manual";
		test_feedback_comp_delay_chain_bits	:	natural := 0;
		test_input_comp_delay_chain_bits	:	natural := 0;
		use_dc_coupling	:	string := "false";
		valid_lock_multiplier	:	natural := 1;
		vco_center	:	natural := 0;
		vco_divide_by	:	natural := 0;
		vco_max	:	natural := 0;
		vco_min	:	natural := 0;
		vco_multiply_by	:	natural := 0;
		vco_post_scale	:	natural := 1;
		lpm_type	:	string := "cycloneii_pll"
	);
	port(
		areset	:	in std_logic := '0';
		clk	:	out std_logic_vector(2 downto 0);
		clkswitch	:	in std_logic := '0';
		ena	:	in std_logic := '1';
		inclk	:	in std_logic_vector(1 downto 0) := (others => '0');
		locked	:	out std_logic;
		pfdena	:	in std_logic := '1';
		testdownout	:	out std_logic;
		testupout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cycloneii_asmiblock parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component cycloneii_asmiblock
	generic (
		lpm_type	:	string := "cycloneii_asmiblock"
	);
	port(
		data0out	:	out std_logic;
		dclkin	:	in std_logic;
		oe	:	in std_logic := '1';
		scein	:	in std_logic;
		sdoin	:	in std_logic
	);
end component;

------------------------------------------------------------------
-- cycloneii_lcell_ff parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component cycloneii_lcell_ff
	generic (
		x_on_violation	:	string := "on";
		lpm_type	:	string := "cycloneii_lcell_ff"
	);
	port(
		aclr	:	in std_logic := '0';
		clk	:	in std_logic;
		datain	:	in std_logic;
		ena	:	in std_logic := '1';
		regout	:	out std_logic;
		sclr	:	in std_logic := '0';
		sdata	:	in std_logic := '0';
		sload	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cycloneii_crcblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneii_crcblock
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneii_crcblock";
		oscillator_divider	:	natural := 1	);
	port(
		clk	:	in std_logic := '0';
		crcerror	:	out std_logic;
		ldsrc	:	in std_logic := '0';
		regout	:	out std_logic;
		shiftnld	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cycloneii_ram_block parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component cycloneii_ram_block
	generic (
		connectivity_checking	:	string := "OFF";
		data_interleave_offset_in_bits	:	natural := 1;
		data_interleave_width_in_bits	:	natural := 1;
		init_file	:	string := "UNUSED";
		init_file_layout	:	string := "UNUSED";
		init_file_restructured	:	string := "UNUSED";
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
		safe_write	:	string := "ERR_ON_2CLK";
		width_eccstatus	:	natural := 3;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneii_ram_block"
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
-- cycloneii_lcell_comb parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component cycloneii_lcell_comb
	generic (
		lut_mask	:	std_logic_vector(15 downto 0) := "0000000000000000";
		sum_lutc_input	:	string := "datac";
		lpm_type	:	string := "cycloneii_lcell_comb"
	);
	port(
		cin	:	in std_logic := '0';
		combout	:	out std_logic;
		cout	:	out std_logic;
		dataa	:	in std_logic := '0';
		datab	:	in std_logic := '0';
		datac	:	in std_logic := '0';
		datad	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cycloneii_jtag parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneii_jtag
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneii_jtag"	);
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
-- cycloneii_mac_out parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component cycloneii_mac_out
	generic (
		dataa_width	:	natural := 0;
		output_clock	:	string := "none";
		lpm_type	:	string := "cycloneii_mac_out"
	);
	port(
		aclr	:	in std_logic := '0';
		clk	:	in std_logic := '1';
		dataa	:	in std_logic_vector(dataa_width-1 downto 0) := (others => '0');
		dataout	:	out std_logic_vector(dataa_width-1 downto 0);
		ena	:	in std_logic := '1'
	);
end component;

------------------------------------------------------------------
-- cycloneii_clk_delay_ctrl parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component cycloneii_clk_delay_ctrl
	generic (
		behavioral_sim_delay	:	natural := 0;
		delay_chain	:	string := "unused";
		delay_chain_mode	:	string := "none";
		delay_ctrl_sim_delay_15_0	:	std_logic_vector(511 downto 0) := "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
		delay_ctrl_sim_delay_31_16	:	std_logic_vector(511 downto 0) := "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
		delay_ctrl_sim_delay_47_32	:	std_logic_vector(511 downto 0) := "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
		delay_ctrl_sim_delay_63_48	:	std_logic_vector(511 downto 0) := "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
		tan_delay_under_delay_ctrl_signal	:	string := "unused";
		use_new_style_dq_detection	:	string := "true";
		uses_calibration	:	string := "false";
		lpm_type	:	string := "cycloneii_clk_delay_ctrl"
	);
	port(
		clk	:	in std_logic;
		clkout	:	out std_logic;
		delayctrlin	:	in std_logic_vector(5 downto 0) := (others => '0');
		disablecalibration	:	in std_logic := '1';
		pllcalibrateclkdelayedin	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cycloneii_io parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component cycloneii_io
	generic (
		bus_hold	:	string := "false";
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
		tie_off_oe_clock_enable	:	string := "false";
		tie_off_output_clock_enable	:	string := "false";
		use_differential_input	:	string := "false";
		lpm_type	:	string := "cycloneii_io"
	);
	port(
		areset	:	in std_logic := '0';
		combout	:	out std_logic;
		datain	:	in std_logic := '0';
		differentialin	:	in std_logic := '0';
		differentialout	:	out std_logic;
		inclk	:	in std_logic := '0';
		inclkena	:	in std_logic := '1';
		linkin	:	in std_logic := '0';
		linkout	:	out std_logic;
		oe	:	in std_logic := '1';
		outclk	:	in std_logic := '0';
		outclkena	:	in std_logic := '1';
		padio	:	inout std_logic;
		regout	:	out std_logic;
		sreset	:	in std_logic := '0'
	);
end component;

--clearbox auto-generated components end
end cycloneii_components;
