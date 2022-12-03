library IEEE, cycloneiii;
use IEEE.STD_LOGIC_1164.all;

package cycloneiii_components is

--clearbox auto-generated components begin
--Dont add any component declarations after this section

------------------------------------------------------------------
-- cycloneiii_ram_block parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component cycloneiii_ram_block
	generic (
		clk0_core_clock_enable	:	string := "none";
		clk0_input_clock_enable	:	string := "none";
		clk0_output_clock_enable	:	string := "none";
		clk1_core_clock_enable	:	string := "none";
		clk1_input_clock_enable	:	string := "none";
		clk1_output_clock_enable	:	string := "none";
		connectivity_checking	:	string := "OFF";
		data_interleave_offset_in_bits	:	natural := 1;
		data_interleave_width_in_bits	:	natural := 1;
		init_file	:	string := "UNUSED";
		init_file_layout	:	string := "UNUSED";
		init_file_restructured	:	string := "UNUSED";
		logical_ram_name	:	string;
		mem_init0	:	std_logic_vector(2047 downto 0) := "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
		mem_init1	:	std_logic_vector(2047 downto 0) := "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
		mem_init2	:	std_logic_vector(2047 downto 0) := "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
		mem_init3	:	std_logic_vector(2047 downto 0) := "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
		mem_init4	:	std_logic_vector(2047 downto 0) := "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
		mixed_port_feed_through_mode	:	string := "UNUSED";
		operation_mode	:	string;
		port_a_address_clear	:	string := "UNUSED";
		port_a_address_width	:	natural := 1;
		port_a_byte_enable_mask_width	:	natural := 1;
		port_a_byte_size	:	natural := 8;
		port_a_data_out_clear	:	string := "UNUSED";
		port_a_data_out_clock	:	string := "none";
		port_a_data_width	:	natural := 1;
		port_a_first_address	:	natural;
		port_a_first_bit_number	:	natural;
		port_a_last_address	:	natural;
		port_a_logical_ram_depth	:	natural := 0;
		port_a_logical_ram_width	:	natural := 0;
		port_a_read_during_write_mode	:	string := "new_data_no_nbe_read";
		port_b_address_clear	:	string := "UNUSED";
		port_b_address_clock	:	string := "UNUSED";
		port_b_address_width	:	natural := 1;
		port_b_byte_enable_clock	:	string := "UNUSED";
		port_b_byte_enable_mask_width	:	natural := 1;
		port_b_byte_size	:	natural := 8;
		port_b_data_in_clock	:	string := "UNUSED";
		port_b_data_out_clear	:	string := "UNUSED";
		port_b_data_out_clock	:	string := "none";
		port_b_data_width	:	natural := 1;
		port_b_first_address	:	natural := 0;
		port_b_first_bit_number	:	natural := 0;
		port_b_last_address	:	natural := 0;
		port_b_logical_ram_depth	:	natural := 0;
		port_b_logical_ram_width	:	natural := 0;
		port_b_read_during_write_mode	:	string := "new_data_no_nbe_read";
		port_b_read_enable_clock	:	string := "UNUSED";
		port_b_write_enable_clock	:	string := "UNUSED";
		power_up_uninitialized	:	string := "false";
		ram_block_type	:	string;
		safe_write	:	string := "ERR_ON_2CLK";
		width_eccstatus	:	natural := 3;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneiii_ram_block"
	);
	port(
		clk0	:	in std_logic;
		clk1	:	in std_logic := '0';
		clr0	:	in std_logic := '0';
		clr1	:	in std_logic := '0';
		ena0	:	in std_logic := '1';
		ena1	:	in std_logic := '1';
		ena2	:	in std_logic := '1';
		ena3	:	in std_logic := '1';
		portaaddr	:	in std_logic_vector(port_a_address_width-1 downto 0) := (others => '0');
		portaaddrstall	:	in std_logic := '0';
		portabyteenamasks	:	in std_logic_vector(port_a_byte_enable_mask_width-1 downto 0) := (others => '1');
		portadatain	:	in std_logic_vector(port_a_data_width-1 downto 0) := (others => '0');
		portadataout	:	out std_logic_vector(port_a_data_width-1 downto 0);
		portare	:	in std_logic := '1';
		portawe	:	in std_logic := '0';
		portbaddr	:	in std_logic_vector(port_b_address_width-1 downto 0) := (others => '0');
		portbaddrstall	:	in std_logic := '0';
		portbbyteenamasks	:	in std_logic_vector(port_b_byte_enable_mask_width-1 downto 0) := (others => '1');
		portbdatain	:	in std_logic_vector(port_b_data_width-1 downto 0) := (others => '0');
		portbdataout	:	out std_logic_vector(port_b_data_width-1 downto 0);
		portbre	:	in std_logic := '1';
		portbwe	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cycloneiii_io_ibuf parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneiii_io_ibuf
	generic (
		bus_hold	:	string := "false";
		differential_mode	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneiii_io_ibuf";
		simulate_z_as	:	string := "Z"	);
	port(
		i	:	in std_logic := '0';
		ibar	:	in std_logic := '0';
		o	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cycloneiii_apfcontroller parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneiii_apfcontroller
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneiii_apfcontroller"	);
	port(
		nceout	:	out std_logic;
		usermode	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cycloneiii_pll parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneiii_pll
	generic (
		auto_settings	:	string := "true";
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
		charge_pump_current	:	natural := 10;
		charge_pump_current_bits	:	natural := 9999;
		clk0_counter	:	string := "c0";
		clk0_divide_by	:	natural := 1;
		clk0_duty_cycle	:	natural := 50;
		clk0_multiply_by	:	natural := 0;
		clk0_output_frequency	:	natural := 0;
		clk0_phase_shift	:	string := "UNUSED";
		clk0_use_even_counter_mode	:	string := "off";
		clk0_use_even_counter_value	:	string := "off";
		clk1_counter	:	string := "c1";
		clk1_divide_by	:	natural := 1;
		clk1_duty_cycle	:	natural := 50;
		clk1_multiply_by	:	natural := 0;
		clk1_output_frequency	:	natural := 0;
		clk1_phase_shift	:	string := "UNUSED";
		clk1_use_even_counter_mode	:	string := "off";
		clk1_use_even_counter_value	:	string := "off";
		clk2_counter	:	string := "c2";
		clk2_divide_by	:	natural := 1;
		clk2_duty_cycle	:	natural := 50;
		clk2_multiply_by	:	natural := 0;
		clk2_output_frequency	:	natural := 0;
		clk2_phase_shift	:	string := "UNUSED";
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
		compensate_clock	:	string := "clk0";
		enable_switch_over_counter	:	string := "off";
		family_name	:	string := "Cyclone III";
		inclk0_input_frequency	:	natural := 0;
		inclk1_input_frequency	:	natural := 0;
		init_block_reset_a_count	:	natural := 1;
		init_block_reset_b_count	:	natural := 1;
		lock_c	:	natural := 4;
		lock_high	:	natural := 0;
		lock_low	:	natural := 0;
		lock_window	:	natural := 0;
		lock_window_ui	:	string := "0.05";
		lock_window_ui_bits	:	string := "UNUSED";
		loop_filter_c	:	natural := 1;
		loop_filter_c_bits	:	natural := 9999;
		loop_filter_r	:	string := "UNUSED";
		loop_filter_r_bits	:	natural := 9999;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneiii_pll";
		m	:	natural := 0;
		m_initial	:	natural := 1;
		m_ph	:	natural := 0;
		m_test_source	:	natural := 5;
		n	:	natural := 1;
		operation_mode	:	string := "normal";
		pfd_max	:	natural := 0;
		pfd_min	:	natural := 0;
		pll_compensation_delay	:	natural := 0;
		pll_type	:	string := "auto";
		scan_chain_mif_file	:	string := "UNUSED";
		self_reset_on_loss_lock	:	string := "off";
		sim_gate_lock_device_behavior	:	string := "off";
		simulation_type	:	string := "functional";
		switch_over_counter	:	natural := 1;
		switch_over_type	:	string := "auto";
		test_bypass_lock_detect	:	string := "OFF";
		test_counter_c0_delay_chain_bits	:	natural := 0;
		test_counter_c1_delay_chain_bits	:	natural := 0;
		test_counter_c2_delay_chain_bits	:	natural := 0;
		test_counter_c3_delay_chain_bits	:	natural := 0;
		test_counter_c4_delay_chain_bits	:	natural := 0;
		test_counter_c5_delay_chain_bits	:	natural := 0;
		test_counter_m_delay_chain_bits	:	natural := 0;
		test_counter_n_delay_chain_bits	:	natural := 0;
		test_feedback_comp_delay_chain_bits	:	natural := 0;
		test_input_comp_delay_chain_bits	:	natural := 0;
		test_volt_reg_output_mode_bits	:	natural := 0;
		test_volt_reg_output_voltage_bits	:	natural := 0;
		test_volt_reg_test_mode	:	string := "false";
		use_dc_coupling	:	string := "false";
		use_vco_bypass	:	string := "false";
		vco_center	:	natural := 0;
		vco_divide_by	:	natural := 0;
		vco_frequency_control	:	string := "auto";
		vco_max	:	natural := 0;
		vco_min	:	natural := 0;
		vco_multiply_by	:	natural := 0;
		vco_phase_shift_step	:	natural := 0;
		vco_post_scale	:	natural := 1;
		vco_range_detector_high_bits	:	string := "UNUSED";
		vco_range_detector_low_bits	:	string := "UNUSED"	);
	port(
		activeclock	:	out std_logic;
		areset	:	in std_logic := '0';
		clk	:	out std_logic_vector(4 downto 0);
		clkbad	:	out std_logic_vector(1 downto 0);
		clkswitch	:	in std_logic := '0';
		configupdate	:	in std_logic := '0';
		fbin	:	in std_logic := '0';
		fbout	:	out std_logic;
		inclk	:	in std_logic_vector(1 downto 0) := (others => '0');
		locked	:	out std_logic;
		pfdena	:	in std_logic := '1';
		phasecounterselect	:	in std_logic_vector(2 downto 0) := (others => '0');
		phasedone	:	out std_logic;
		phasestep	:	in std_logic := '0';
		phaseupdown	:	in std_logic := '0';
		scanclk	:	in std_logic := '0';
		scanclkena	:	in std_logic := '1';
		scandata	:	in std_logic := '0';
		scandataout	:	out std_logic;
		scandone	:	out std_logic;
		vcooverrange	:	out std_logic;
		vcounderrange	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cycloneiii_pseudo_diff_out parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneiii_pseudo_diff_out
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneiii_pseudo_diff_out"	);
	port(
		i	:	in std_logic := '0';
		o	:	out std_logic;
		obar	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cycloneiii_clkctrl parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneiii_clkctrl
	generic (
		clock_type	:	string;
		ena_register_mode	:	string := "falling edge";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneiii_clkctrl"	);
	port(
		clkselect	:	in std_logic_vector(1 downto 0);
		ena	:	in std_logic;
		inclk	:	in std_logic_vector(3 downto 0);
		outclk	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cycloneiii_ddio_out parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneiii_ddio_out
	generic (
		async_mode	:	string := "none";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneiii_ddio_out";
		power_up	:	string := "low";
		sync_mode	:	string := "none";
		use_new_clocking_model	:	string := "false"	);
	port(
		areset	:	in std_logic := '0';
		clk	:	in std_logic := '0';
		clkhi	:	in std_logic := '0';
		clklo	:	in std_logic := '0';
		datainhi	:	in std_logic := '0';
		datainlo	:	in std_logic := '0';
		dataout	:	out std_logic;
		ena	:	in std_logic := '1';
		muxsel	:	in std_logic := '0';
		sreset	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cycloneiii_ff parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneiii_ff
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneiii_ff";
		power_up	:	string := "low";
		x_on_violation	:	string := "on"	);
	port(
		aload	:	in std_logic := '0';
		asdata	:	in std_logic := '0';
		clk	:	in std_logic := '0';
		clrn	:	in std_logic := '0';
		d	:	in std_logic := '0';
		ena	:	in std_logic := '1';
		q	:	out std_logic;
		sclr	:	in std_logic := '0';
		sload	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cycloneiii_mac_mult parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneiii_mac_mult
	generic (
		dataa_clock	:	string := "none";
		dataa_width	:	natural;
		datab_clock	:	string := "none";
		datab_width	:	natural;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneiii_mac_mult";
		signa_clock	:	string := "none";
		signb_clock	:	string := "none"	);
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
-- cycloneiii_rublock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneiii_rublock
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneiii_rublock";
		sim_init_config	:	string := "factory";
		sim_init_status	:	natural := 0;
		sim_init_watchdog_value	:	natural := 0	);
	port(
		captnupdt	:	in std_logic := '0';
		clk	:	in std_logic := '0';
		rconfig	:	in std_logic := '0';
		regin	:	in std_logic := '0';
		regout	:	out std_logic;
		rsttimer	:	in std_logic := '0';
		shiftnld	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cycloneiii_io_obuf parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneiii_io_obuf
	generic (
		bus_hold	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneiii_io_obuf";
		open_drain_output	:	string := "false"	);
	port(
		i	:	in std_logic := '0';
		o	:	out std_logic;
		obar	:	out std_logic;
		oe	:	in std_logic := '1';
		seriesterminationcontrol	:	in std_logic_vector(15 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- cycloneiii_jtag parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneiii_jtag
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneiii_jtag"	);
	port(
		clkdruser	:	out std_logic;
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
-- cycloneiii_termination parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneiii_termination
	generic (
		clock_divide_by	:	natural := 32;
		left_shift_termination_code	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneiii_termination";
		power_down	:	string := "true";
		pulldown_adder	:	natural := 0;
		pullup_adder	:	natural := 0;
		pullup_control_to_core	:	string := "false";
		runtime_control	:	string := "false";
		shift_vref_rdn	:	string := "true";
		shift_vref_rup	:	string := "true";
		shifted_vref_control	:	string := "true";
		test_mode	:	string := "false"	);
	port(
		calibrationdone	:	out std_logic;
		comparatorprobe	:	out std_logic;
		rdn	:	in std_logic := '0';
		rup	:	in std_logic := '0';
		terminationclear	:	in std_logic := '0';
		terminationclock	:	in std_logic := '0';
		terminationcontrol	:	out std_logic_vector(15 downto 0);
		terminationcontrolprobe	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cycloneiii_io_pad parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneiii_io_pad
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneiii_io_pad"	);
	port(
		padin	:	in std_logic := '0';
		padout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cycloneiii_oscillator parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneiii_oscillator
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneiii_oscillator"	);
	port(
		clkout	:	out std_logic;
		oscena	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cycloneiii_lcell_comb parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneiii_lcell_comb
	generic (
		dont_touch	:	string := "off";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneiii_lcell_comb";
		lut_mask	:	std_logic_vector(15 downto 0) := "0000000000000000";
		sum_lutc_input	:	string := "datac"	);
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
-- cycloneiii_crcblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneiii_crcblock
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneiii_crcblock";
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
-- cycloneiii_mac_out parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneiii_mac_out
	generic (
		dataa_width	:	natural := 0;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneiii_mac_out";
		output_clock	:	string := "none"	);
	port(
		aclr	:	in std_logic := '0';
		clk	:	in std_logic := '1';
		dataa	:	in std_logic_vector(dataa_width-1 downto 0) := (others => '0');
		dataout	:	out std_logic_vector(dataa_width-1 downto 0);
		ena	:	in std_logic := '1'
	);
end component;

------------------------------------------------------------------
-- cycloneiii_ddio_oe parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cycloneiii_ddio_oe
	generic (
		async_mode	:	string := "none";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cycloneiii_ddio_oe";
		power_up	:	string := "low";
		sync_mode	:	string := "none"	);
	port(
		areset	:	in std_logic := '0';
		clk	:	in std_logic := '0';
		dataout	:	out std_logic;
		ena	:	in std_logic := '1';
		oe	:	in std_logic := '1';
		sreset	:	in std_logic := '0'
	);
end component;

--clearbox auto-generated components end
end cycloneiii_components;
