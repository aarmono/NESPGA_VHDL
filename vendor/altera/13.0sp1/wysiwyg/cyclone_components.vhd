library IEEE, cyclone;
use IEEE.STD_LOGIC_1164.all;

package cyclone_components is

--clearbox auto-generated components begin
--Dont add any component declarations after this section

------------------------------------------------------------------
-- cyclone_io parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component cyclone_io
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
		lpm_type	:	string := "cyclone_io"
	);
	port(
		areset	:	in std_logic := '0';
		combout	:	out std_logic;
		datain	:	in std_logic := '0';
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

------------------------------------------------------------------
-- cyclone_ram_block parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component cyclone_ram_block
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
		lpm_type	:	string := "cyclone_ram_block"
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

------------------------------------------------------------------
-- cyclone_pll parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component cyclone_pll
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
		lpm_type	:	string := "cyclone_pll"
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

------------------------------------------------------------------
-- cyclone_lcell parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component cyclone_lcell
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
		lpm_type	:	string := "cyclone_lcell"
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

------------------------------------------------------------------
-- cyclone_asmiblock parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component cyclone_asmiblock
	generic (
		lpm_type	:	string := "cyclone_asmiblock"
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
-- cyclone_crcblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclone_crcblock
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclone_crcblock";
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
-- cyclone_jtag parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclone_jtag
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclone_jtag"	);
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

--clearbox auto-generated components end
end cyclone_components;
