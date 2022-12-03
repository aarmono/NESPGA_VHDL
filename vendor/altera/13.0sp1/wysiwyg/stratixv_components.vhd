library IEEE, stratixv;
use IEEE.STD_LOGIC_1164.all;

package stratixv_components is

--clearbox auto-generated components begin
--Dont add any component declarations after this section

------------------------------------------------------------------
-- stratixv_cvpcieblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_cvpcieblock
	generic (
		aux_cvp_opbit	:	string := "false";
		cvp_dbg	:	string := "false";
		cvp_dfx	:	string := "false";
		cvp_opbit	:	string := "false";
		dft_opbits	:	string := "false";
		en_cvp_confdone	:	string := "false";
		iocsr_ready_from_csrdone	:	string := "false";
		lpm_type	:	string := "stratixv_cvpcieblock";
		test_cvp_dbg_val	:	natural := 15;
		test_dft_opbits_val	:	natural := 0	);
	port(
		clk	:	in std_logic := '0';
		confdone	:	out std_logic;
		configerror	:	out std_logic;
		configready	:	out std_logic;
		cvpconfig	:	in std_logic := '0';
		data	:	in std_logic_vector(31 downto 0) := (others => '0');
		en	:	out std_logic;
		fullconfig	:	in std_logic := '0';
		iocsrready	:	out std_logic;
		iocsrreadydly	:	out std_logic;
		startxfer	:	in std_logic := '0';
		usermode	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- stratixv_crcblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_crcblock
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_crcblock";
		oscillator_divider	:	natural := 256	);
	port(
		clk	:	in std_logic := '0';
		crcerror	:	out std_logic;
		regout	:	out std_logic;
		shiftnld	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_io_clock_divider parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_io_clock_divider
	generic (
		invert_phase	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_io_clock_divider";
		power_up	:	string := "low";
		use_masterin	:	string := "false"	);
	port(
		clk	:	in std_logic := '0';
		clkout	:	out std_logic;
		masterin	:	in std_logic := '0';
		phaseinvertctrl	:	in std_logic := '0';
		slaveout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- stratixv_jtag parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_jtag
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_jtag"	);
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
-- stratixv_dll parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_dll
	generic (
		delay_chain_length	:	natural := 8;
		delayctrlout_mode	:	string := "normal";
		dual_phase_comparators	:	string := "true";
		input_frequency	:	string := "0";
		jitter_reduction	:	string := "false";
		lpm_hint	:	string := "unused";
		lpm_type	:	string := "stratixv_dll";
		sim_buffer_delay_increment	:	natural := 10;
		sim_buffer_intrinsic_delay	:	natural := 175;
		sim_valid_lock	:	natural := 16;
		sim_valid_lockcount	:	natural := 0;
		static_delay_ctrl	:	natural := 0;
		use_upndnin	:	string := "false";
		use_upndninclkena	:	string := "false"	);
	port(
		aload	:	in std_logic := '0';
		clk	:	in std_logic := '0';
		delayctrlout	:	out std_logic_vector(6 downto 0);
		dffin	:	out std_logic;
		dqsupdate	:	out std_logic;
		locked	:	out std_logic;
		offsetdelayctrlclkout	:	out std_logic;
		offsetdelayctrlout	:	out std_logic_vector(6 downto 0);
		upndnin	:	in std_logic := '0';
		upndninclkena	:	in std_logic := '0';
		upndnout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- stratixv_pll_output_counter parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_pll_output_counter
	generic (
		c_cnt_coarse_dly	:	string := "0 ps";
		c_cnt_fine_dly	:	string := "0 ps";
		c_cnt_in_src	:	string := "test_clk0";
		c_cnt_ph_mux_prst	:	natural := 0;
		c_cnt_prst	:	natural := 1;
		cnt_fpll_src	:	string := "fpll_0";
		dprio0_cnt_bypass_en	:	string := "false";
		dprio0_cnt_hi_div	:	natural := 1;
		dprio0_cnt_lo_div	:	natural := 1;
		dprio0_cnt_odd_div_even_duty_en	:	string := "false";
		dprio1_cnt_bypass_en	:	string := "false";
		dprio1_cnt_hi_div	:	natural := 1;
		dprio1_cnt_lo_div	:	natural := 1;
		dprio1_cnt_odd_div_even_duty_en	:	string := "false";
		duty_cycle	:	natural := 50;
		fractional_pll_index	:	natural := 1;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_pll_output_counter";
		output_clock_frequency	:	string := "0 ps";
		output_counter_index	:	natural := 1;
		phase_shift	:	string := "0 ps"	);
	port(
		cascadein	:	in std_logic := '0';
		cascadeout	:	out std_logic;
		divclk	:	out std_logic;
		nen0	:	in std_logic := '0';
		nen1	:	in std_logic := '0';
		shift0	:	in std_logic := '0';
		shift1	:	in std_logic := '0';
		shiftdone0i	:	in std_logic := '0';
		shiftdone0o	:	out std_logic;
		shiftdone1i	:	in std_logic := '0';
		shiftdone1o	:	out std_logic;
		shiften	:	in std_logic := '0';
		tclk0	:	in std_logic := '0';
		tclk1	:	in std_logic := '0';
		up0	:	in std_logic := '0';
		up1	:	in std_logic := '0';
		vco0ph	:	in std_logic_vector(7 downto 0) := (others => '0');
		vco1ph	:	in std_logic_vector(7 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- stratixv_oscillator parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_oscillator
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_oscillator"	);
	port(
		clkout	:	out std_logic;
		clkout1	:	out std_logic;
		oscena	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_bias_block parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_bias_block
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_bias_block"	);
	port(
		captnupdt	:	in std_logic := '0';
		clk	:	in std_logic := '0';
		din	:	in std_logic := '0';
		dout	:	out std_logic;
		shiftnld	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_channel_pll parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_channel_pll
	generic (
		avmm_group_channel_index	:	natural := 0;
		bbpd_salatch_offset_ctrl_clk0	:	string := "offset_0mv";
		bbpd_salatch_offset_ctrl_clk180	:	string := "offset_0mv";
		bbpd_salatch_offset_ctrl_clk270	:	string := "offset_0mv";
		bbpd_salatch_offset_ctrl_clk90	:	string := "offset_0mv";
		bbpd_salatch_sel	:	string := "normal";
		bypass_cp_rgla	:	string := "false";
		cdr_atb_select	:	string := "atb_disable";
		cgb_clk_enable	:	string := "false";
		charge_pump_current_test	:	string := "enable_ch_pump_normal";
		clklow_fref_to_ppm_div_sel	:	natural := 1;
		clock_monitor	:	string := "lpbk_data";
		cvp_en_iocsr	:	string := "false";
		diag_rev_lpbk	:	string := "false";
		enable_debug_info	:	string := "false";
		enabled_for_reconfig	:	string := "false";
		eye_monitor_bbpd_data_ctrl	:	string := "cdr_data";
		fast_lock_mode	:	string := "false";
		fb_sel	:	string := "vcoclk";
		gpon_lock2ref_ctrl	:	string := "lck2ref";
		hs_levshift_power_supply_setting	:	natural := 1;
		ignore_phslock	:	string := "false";
		l_counter_pd_clock_disable	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_channel_pll";
		m_counter	:	natural := 0;
		output_clock_frequency	:	string := "0 ps";
		pcie_freq_control	:	string := "pcie_100mhz";
		pd_charge_pump_current_ctrl	:	natural := 0;
		pd_l_counter	:	natural := 0;
		pfd_charge_pump_current_ctrl	:	natural := 0;
		pfd_l_counter	:	natural := 0;
		powerdown	:	string := "false";
		ref_clk_div	:	natural := 0;
		reference_clock_frequency	:	string := "0 ps";
		regulator_volt_inc	:	string := "0";
		replica_bias_ctrl	:	string := "false";
		reverse_serial_lpbk	:	string := "false";
		ripple_cap_ctrl	:	string := "none";
		rxpll_pd_bw_ctrl	:	natural := 0;
		rxpll_pfd_bw_ctrl	:	natural := 0;
		silicon_rev	:	string := "reve";
		sim_use_fast_model	:	string := "true";
		txpll_hclk_driver_enable	:	string := "false";
		use_default_base_address	:	string := "true";
		user_base_address	:	natural := 0;
		vco_overange_ref	:	string := "off";
		vco_range_ctrl_en	:	string := "false"	);
	port(
		avmmaddress	:	in std_logic_vector(10 downto 0) := (others => '0');
		avmmbyteen	:	in std_logic_vector(1 downto 0) := (others => '0');
		avmmclk	:	in std_logic := '0';
		avmmread	:	in std_logic := '0';
		avmmreaddata	:	out std_logic_vector(15 downto 0);
		avmmrstn	:	in std_logic := '1';
		avmmwrite	:	in std_logic := '0';
		avmmwritedata	:	in std_logic_vector(15 downto 0) := (others => '0');
		blockselect	:	out std_logic;
		ck0pd	:	out std_logic;
		ck180pd	:	out std_logic;
		ck270pd	:	out std_logic;
		ck90pd	:	out std_logic;
		clk270bcdr	:	out std_logic;
		clk270bdes	:	out std_logic;
		clk270beyerm	:	in std_logic := '0';
		clk270eye	:	in std_logic := '0';
		clk90bcdr	:	out std_logic;
		clk90bdes	:	out std_logic;
		clk90beyerm	:	in std_logic := '0';
		clk90eye	:	in std_logic := '0';
		clkcdr	:	out std_logic;
		clkindeser	:	in std_logic := '0';
		clklow	:	out std_logic;
		crurstb	:	in std_logic := '1';
		decdr	:	out std_logic;
		deeye	:	in std_logic := '0';
		deeyerm	:	in std_logic := '0';
		deven	:	out std_logic;
		docdr	:	out std_logic;
		dodd	:	out std_logic;
		doeye	:	in std_logic := '0';
		doeyerm	:	in std_logic := '0';
		earlyeios	:	in std_logic := '0';
		extclk	:	in std_logic := '0';
		extfbctrla	:	in std_logic := '0';
		extfbctrlb	:	in std_logic := '0';
		fref	:	out std_logic;
		gpblck2refb	:	in std_logic := '0';
		lpbkpreen	:	in std_logic := '0';
		ltd	:	in std_logic := '0';
		ltr	:	in std_logic := '0';
		occalen	:	in std_logic := '0';
		pciel	:	in std_logic := '0';
		pciem	:	in std_logic := '0';
		pciesw	:	in std_logic_vector(1 downto 0) := (others => '0');
		pdof	:	out std_logic_vector(3 downto 0);
		pfdmodelock	:	out std_logic;
		ppmlock	:	in std_logic := '0';
		refclk	:	in std_logic := '0';
		rstn	:	in std_logic := '1';
		rxlpbdp	:	out std_logic;
		rxlpbp	:	out std_logic;
		rxp	:	in std_logic := '0';
		rxplllock	:	out std_logic;
		sd	:	in std_logic := '0';
		txpllhclk	:	out std_logic;
		txrlpbk	:	out std_logic;
		vctrloverrange	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- stratixv_ram_block parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_ram_block
	generic (
		bist_ena	:	string := "false";
		clk0_core_clock_enable	:	string := "none";
		clk0_input_clock_enable	:	string := "none";
		clk0_output_clock_enable	:	string := "none";
		clk1_core_clock_enable	:	string := "none";
		clk1_input_clock_enable	:	string := "none";
		clk1_output_clock_enable	:	string := "none";
		connectivity_checking	:	string := "OFF";
		data_interleave_offset_in_bits	:	natural := 1;
		data_interleave_width_in_bits	:	natural := 1;
		ecc_pipeline_stage_enabled	:	string := "false";
		enable_ecc	:	string := "false";
		init_file	:	string := "UNUSED";
		init_file_layout	:	string := "UNUSED";
		logical_ram_name	:	string := "UNUSED";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_ram_block";
		mem_init0	:	string;
		mem_init1	:	string;
		mem_init2	:	string;
		mem_init3	:	string;
		mem_init4	:	string;
		mem_init5	:	string;
		mem_init6	:	string;
		mem_init7	:	string;
		mem_init8	:	string;
		mem_init9	:	string;
		mixed_port_feed_through_mode	:	string := "dont_care";
		operation_mode	:	string := "single_port";
		port_a_address_clear	:	string := "none";
		port_a_address_clock	:	string := "clock0";
		port_a_address_width	:	natural := 1;
		port_a_byte_enable_clock	:	string := "clock0";
		port_a_byte_enable_mask_width	:	natural := 1;
		port_a_byte_size	:	natural := 0;
		port_a_data_in_clock	:	string := "clock0";
		port_a_data_out_clear	:	string := "none";
		port_a_data_out_clock	:	string := "none";
		port_a_data_width	:	natural := 1;
		port_a_first_address	:	natural := 0;
		port_a_first_bit_number	:	natural := 0;
		port_a_last_address	:	natural := 0;
		port_a_logical_ram_depth	:	natural := 0;
		port_a_logical_ram_width	:	natural := 0;
		port_a_read_during_write_mode	:	string := "new_data_no_nbe_read";
		port_a_read_enable_clock	:	string := "clock0";
		port_a_write_enable_clock	:	string := "clock0";
		port_b_address_clear	:	string := "none";
		port_b_address_clock	:	string := "clock1";
		port_b_address_width	:	natural := 1;
		port_b_byte_enable_clock	:	string := "clock1";
		port_b_byte_enable_mask_width	:	natural := 1;
		port_b_byte_size	:	natural := 0;
		port_b_data_in_clock	:	string := "clock1";
		port_b_data_out_clear	:	string := "none";
		port_b_data_out_clock	:	string := "none";
		port_b_data_width	:	natural := 1;
		port_b_first_address	:	natural := 0;
		port_b_first_bit_number	:	natural := 0;
		port_b_last_address	:	natural := 0;
		port_b_logical_ram_depth	:	natural := 0;
		port_b_logical_ram_width	:	natural := 0;
		port_b_read_during_write_mode	:	string := "new_data_no_nbe_read";
		port_b_read_enable_clock	:	string := "clock1";
		port_b_write_enable_clock	:	string := "clock1";
		power_up_uninitialized	:	string := "false";
		ram_block_type	:	string := "AUTO";
		width_eccstatus	:	natural := 2	);
	port(
		clk0	:	in std_logic;
		clk1	:	in std_logic := '0';
		clr0	:	in std_logic := '0';
		clr1	:	in std_logic := '0';
		dftout	:	out std_logic_vector(8 downto 0);
		eccstatus	:	out std_logic_vector(WIDTH_ECCSTATUS-1 downto 0);
		ena0	:	in std_logic := '1';
		ena1	:	in std_logic := '1';
		ena2	:	in std_logic := '1';
		ena3	:	in std_logic := '1';
		portaaddr	:	in std_logic_vector(PORT_A_ADDRESS_WIDTH-1 downto 0) := (others => '0');
		portaaddrstall	:	in std_logic := '0';
		portabyteenamasks	:	in std_logic_vector(PORT_A_BYTE_ENABLE_MASK_WIDTH-1 downto 0) := (others => '1');
		portadatain	:	in std_logic_vector(PORT_A_DATA_WIDTH-1 downto 0) := (others => '0');
		portadataout	:	out std_logic_vector(PORT_A_DATA_WIDTH-1 downto 0);
		portare	:	in std_logic := '1';
		portawe	:	in std_logic := '0';
		portbaddr	:	in std_logic_vector(PORT_B_ADDRESS_WIDTH-1 downto 0) := (others => '0');
		portbaddrstall	:	in std_logic := '0';
		portbbyteenamasks	:	in std_logic_vector(PORT_B_BYTE_ENABLE_MASK_WIDTH-1 downto 0) := (others => '1');
		portbdatain	:	in std_logic_vector(PORT_B_DATA_WIDTH-1 downto 0) := (others => '0');
		portbdataout	:	out std_logic_vector(PORT_B_DATA_WIDTH-1 downto 0);
		portbre	:	in std_logic := '1';
		portbwe	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_opregblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_opregblock
	generic (
		lpm_type	:	string := "stratixv_opregblock"	);
	port(
		clk	:	in std_logic := '0';
		regout	:	out std_logic;
		shiftnld	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_controller parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_controller
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_controller"	);
end component;

------------------------------------------------------------------
-- stratixv_input_phase_alignment parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_input_phase_alignment
	generic (
		add_input_cycle_delay	:	string := "false";
		add_phase_transfer_reg	:	string := "false";
		async_mode	:	string := "none";
		bypass_output_register	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_input_phase_alignment";
		power_up	:	string := "low"	);
	port(
		areset	:	in std_logic := '0';
		datain	:	in std_logic := '1';
		dataout	:	out std_logic;
		dff1t	:	out std_logic;
		dffin	:	out std_logic;
		dffphasetransfer	:	out std_logic;
		enainputcycledelay	:	in std_logic := '0';
		enaphasetransferreg	:	in std_logic := '0';
		levelingclk	:	in std_logic := '0';
		zerophaseclk	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_asmiblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_asmiblock
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_asmiblock"	);
	port(
		data0in	:	out std_logic;
		data0oe	:	in std_logic := '0';
		data0out	:	in std_logic := '0';
		data1in	:	out std_logic;
		data1oe	:	in std_logic := '0';
		data1out	:	in std_logic := '0';
		data2in	:	out std_logic;
		data2oe	:	in std_logic := '0';
		data2out	:	in std_logic := '0';
		data3in	:	out std_logic;
		data3oe	:	in std_logic := '0';
		data3out	:	in std_logic := '0';
		dclk	:	in std_logic := '0';
		oe	:	in std_logic := '0';
		sce	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_leveling_delay_chain parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_leveling_delay_chain
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_leveling_delay_chain";
		physical_clock_source	:	string := "dqs";
		sim_buffer_delay_increment	:	natural := 10;
		sim_buffer_intrinsic_delay	:	natural := 175;
		test_mode	:	string := "false";
		use_duty_cycle_correction	:	string := "false"	);
	port(
		clkin	:	in std_logic := '0';
		clkout	:	out std_logic_vector(3 downto 0);
		delayctrlin	:	in std_logic_vector(6 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- stratixv_prblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_prblock
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_prblock"	);
	port(
		clk	:	in std_logic := '0';
		corectl	:	in std_logic := '0';
		data	:	in std_logic_vector(15 downto 0) := (others => '0');
		done	:	out std_logic;
		error	:	out std_logic;
		externalrequest	:	out std_logic;
		prrequest	:	in std_logic := '0';
		ready	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- stratixv_io_obuf parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_io_obuf
	generic (
		bus_hold	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_io_obuf";
		open_drain_output	:	string := "false";
		shift_series_termination_control	:	string := "false";
		sim_dynamic_termination_control_is_connected	:	string := "false"	);
	port(
		dynamicterminationcontrol	:	in std_logic := '0';
		i	:	in std_logic := '0';
		o	:	out std_logic;
		obar	:	out std_logic;
		oe	:	in std_logic := '1';
		parallelterminationcontrol	:	in std_logic_vector(15 downto 0) := (others => '0');
		seriesterminationcontrol	:	in std_logic_vector(15 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- stratixv_att_cdr_pll parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_att_cdr_pll
	generic (
		bbpd_salatch_offset_ctrl_clk0	:	string := "offset_0mv";
		bbpd_salatch_offset_ctrl_clk180	:	string := "offset_0mv";
		bbpd_salatch_offset_ctrl_clk270	:	string := "offset_0mv";
		bbpd_salatch_offset_ctrl_clk90	:	string := "offset_0mv";
		bbpd_salatch_sel	:	string := "normal";
		bypass_cp_rgla	:	string := "false";
		charge_pump_current_test	:	string := "disable_ch_pump_curr_test";
		clk_mon_jitter	:	string := "false";
		clk_sel	:	string := "pcs0";
		clklow_fref_to_ppm_div_sel	:	natural := 1;
		fast_lock_mode	:	string := "false";
		fb_sel	:	string := "vcoclk";
		ignore_phslock	:	string := "false";
		l_counter_buffer	:	string := "enable_l_count_buff";
		lpm_type	:	string := "stratixv_att_cdr_pll";
		m_counter	:	natural := 20;
		output_clock_frequency	:	string := "0 ps";
		pd_charge_pump_current_ctrl	:	natural := 5;
		pd_l_counter	:	natural := 1;
		pfd_charge_pump_current_ctrl	:	natural := 10;
		pfd_l_counter	:	natural := 1;
		powerdown	:	string := "normal_cdr_on";
		ref_clk_div	:	natural := 1;
		reference_clock_frequeny	:	string := "0 ps";
		regulator_volt_inc	:	string := "0";
		replica_bias_ctrl	:	string := "disable_replica_bias_ctrl";
		ripple_cap_ctrl	:	string := "none";
		rxpll_pd_bw_ctrl	:	natural := 300;
		rxpll_pfd_bw_ctrl	:	natural := 3200;
		sd_sel	:	string := "sd_analog"	);
	port(
		clk	:	in std_logic := '0';
		clkout	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_rublock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_rublock
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_rublock";
		sim_init_config_is_application	:	string := "false";
		sim_init_status	:	natural := 0;
		sim_init_watchdog_enabled	:	string := "false";
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
-- stratixv_atx_pll parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_atx_pll
	generic (
		ac_cap	:	string := "disable_ac_cap";
		avmm_group_channel_index	:	natural := 0;
		cp_current_ctrl	:	natural := 0;
		cp_current_test	:	string := "enable_ch_pump_normal";
		cp_hs_levshift_power_supply_setting	:	natural := 1;
		cp_replica_bias_ctrl	:	string := "disable_replica_bias_ctrl";
		cp_rgla_bypass	:	string := "false";
		cp_rgla_volt_inc	:	string := "boost_30pct";
		enabled_for_reconfig	:	string := "false";
		fbclk_sel	:	string := "internal_fb";
		l_counter	:	natural := 0;
		lc_cmu_pdb	:	string := "false";
		lc_div33_pdb	:	string := "false";
		lcpll_atb_select	:	string := "atb_disable";
		lcpll_d2a_sel	:	string := "volt_1p02v";
		lcpll_hclk_driver_enable	:	string := "driver_off";
		lcvco_gear_sel	:	string := "high_gear";
		lcvco_sel	:	string := "high_freq_14g";
		lpf_ripple_cap_ctrl	:	string := "none";
		lpf_rxpll_pfd_bw_ctrl	:	natural := 0;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_atx_pll";
		m_counter	:	natural := 0;
		output_clock_frequency	:	string := "0 ps";
		ref_clk_div	:	natural := 0;
		refclk_sel	:	string := "refclk";
		reference_clock_frequency	:	string := "0 ps";
		sel_buf14g	:	string := "disable_buf14g";
		sel_buf8g	:	string := "disable_buf8g";
		silicon_rev	:	string := "reve";
		sim_use_fast_model	:	string := "true";
		use_default_base_address	:	string := "true";
		user_base_address0	:	natural := 0;
		user_base_address1	:	natural := 0;
		user_base_address2	:	natural := 0;
		vco_over_range_ref	:	string := "auto";
		vco_under_range_ref	:	string := "auto";
		vreg1_lcvco_volt_inc	:	string := "auto";
		vreg1_vccehlow	:	string := "normal_operation";
		vreg2_lcpll_volt_sel	:	string := "auto";
		vreg3_lcpll_volt_sel	:	string := "auto"	);
	port(
		avmmaddress	:	in std_logic_vector(10 downto 0) := (others => '0');
		avmmbyteen	:	in std_logic_vector(1 downto 0) := (others => '0');
		avmmclk	:	in std_logic := '0';
		avmmread	:	in std_logic := '0';
		avmmreaddata	:	out std_logic_vector(15 downto 0);
		avmmrstn	:	in std_logic := '1';
		avmmwrite	:	in std_logic := '0';
		avmmwritedata	:	in std_logic_vector(15 downto 0) := (others => '0');
		blockselect	:	out std_logic;
		ch0lctestout	:	out std_logic_vector(1 downto 0);
		ch0rcsrlc	:	in std_logic_vector(31 downto 0) := (others => '0');
		ch1lctestout	:	out std_logic_vector(1 downto 0);
		ch1rcsrlc	:	in std_logic_vector(31 downto 0) := (others => '0');
		ch2lctestout	:	out std_logic_vector(1 downto 0);
		ch2rcsrlc	:	in std_logic_vector(31 downto 0) := (others => '0');
		clk010g	:	out std_logic;
		clk025g	:	out std_logic;
		clk18010g	:	out std_logic;
		clk18025g	:	out std_logic;
		clk33cmu	:	out std_logic;
		clklowcmu	:	out std_logic;
		cmurstn	:	in std_logic := '1';
		cmurstnlpf	:	in std_logic := '1';
		extfbclk	:	in std_logic := '0';
		fixedclklc	:	in std_logic := '0';
		frefcmu	:	out std_logic;
		iqclkatt	:	out std_logic;
		iqclklc	:	in std_logic := '0';
		pfdmodelockcmu	:	out std_logic;
		pldclkatt	:	out std_logic;
		pldclklc	:	in std_logic := '0';
		pllfbswblc	:	in std_logic := '0';
		pllfbswtlc	:	in std_logic := '0';
		refclkatt	:	out std_logic;
		refclklc	:	in std_logic := '0';
		txpllhclk	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- stratixv_read_fifo parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_read_fifo
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_read_fifo";
		sim_wclk_pre_delay	:	natural := 0;
		use_half_rate_read	:	string := "false"	);
	port(
		areset	:	in std_logic := '0';
		datain	:	in std_logic_vector(1 downto 0) := (others => '0');
		dataout	:	out std_logic_vector(3 downto 0);
		plus2	:	in std_logic := '0';
		rclk	:	in std_logic := '0';
		re	:	in std_logic := '0';
		wclk	:	in std_logic := '0';
		we	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_phy_clkbuf parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_phy_clkbuf
	generic (
		level1_mux	:	string := "VALUE_FAST";
		level2_mux	:	string := "VALUE_FAST";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_phy_clkbuf"	);
	port(
		inclk	:	in std_logic_vector(3 downto 0) := (others => '1');
		outclk	:	out std_logic_vector(3 downto 0)
	);
end component;

------------------------------------------------------------------
-- stratixv_mlab_cell parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_mlab_cell
	generic (
		address_width	:	natural := 1;
		byte_enable_mask_width	:	natural := 2;
		byte_size	:	natural := 1;
		data_width	:	natural := 1;
		first_address	:	natural;
		first_bit_number	:	natural;
		init_file	:	string := "UNUSED";
		last_address	:	natural;
		logical_ram_depth	:	natural := 0;
		logical_ram_name	:	string := "UNUSED";
		logical_ram_width	:	natural := 0;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_mlab_cell";
		mem_init0	:	std_logic_vector(639 downto 0) := "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
		mixed_port_feed_through_mode	:	string := "dont_care";
		port_b_data_out_clear	:	string := "none";
		port_b_data_out_clock	:	string := "none"	);
	port(
		clk0	:	in std_logic := '0';
		clk1	:	in std_logic := '0';
		clr	:	in std_logic := '0';
		ena0	:	in std_logic := '1';
		ena1	:	in std_logic := '1';
		ena2	:	in std_logic := '1';
		portaaddr	:	in std_logic_vector(address_width-1 downto 0) := (others => '0');
		portabyteenamasks	:	in std_logic_vector(byte_enable_mask_width-1 downto 0) := (others => '1');
		portadatain	:	in std_logic_vector(data_width-1 downto 0) := (others => '0');
		portbaddr	:	in std_logic_vector(address_width-1 downto 0) := (others => '0');
		portbdataout	:	out std_logic_vector(data_width-1 downto 0)
	);
end component;

------------------------------------------------------------------
-- stratixv_io_pad parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_io_pad
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_io_pad"	);
	port(
		padin	:	in std_logic := '0';
		padout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- stratixv_pll_refclk_select parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_pll_refclk_select
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_pll_refclk_select";
		pll_auto_clk_sw_en	:	string := "false";
		pll_clk_loss_edge	:	string := "both_edges";
		pll_clk_loss_sw_en	:	string := "false";
		pll_clk_sw_dly	:	natural := 0;
		pll_clkin_0_src	:	string := "ref_clk0";
		pll_clkin_1_src	:	string := "ref_clk1";
		pll_manu_clk_sw_en	:	string := "false";
		pll_sw_refclk_src	:	string := "clk_0"	);
	port(
		adjpllin	:	in std_logic := '0';
		cclk	:	in std_logic := '0';
		clk0bad	:	out std_logic;
		clk1bad	:	out std_logic;
		clkin	:	in std_logic_vector(3 downto 0) := (others => '0');
		clkout	:	out std_logic;
		coreclkin	:	in std_logic := '0';
		extswitch	:	in std_logic := '0';
		extswitchbuf	:	out std_logic;
		iqtxrxclkin	:	in std_logic := '0';
		pllclksel	:	out std_logic;
		plliqclkin	:	in std_logic := '0';
		refiqclk	:	in std_logic_vector(1 downto 0) := (others => '0');
		rxiqclkin	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_delay_chain parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_delay_chain
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_delay_chain";
		sim_falling_delay_increment	:	natural := 10;
		sim_intrinsic_falling_delay	:	natural := 200;
		sim_intrinsic_rising_delay	:	natural := 200;
		sim_rising_delay_increment	:	natural := 10;
		use_pvt_compensation	:	string := "false"	);
	port(
		datain	:	in std_logic := '0';
		dataout	:	out std_logic;
		delayctrlin	:	in std_logic_vector(7 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- stratixv_ddio_in parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_ddio_in
	generic (
		async_mode	:	string := "none";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_ddio_in";
		power_up	:	string := "low";
		sync_mode	:	string := "none";
		use_clkn	:	string := "false"	);
	port(
		areset	:	in std_logic := '0';
		clk	:	in std_logic := '0';
		clkn	:	in std_logic := '0';
		datain	:	in std_logic := '0';
		dfflo	:	out std_logic;
		ena	:	in std_logic := '1';
		regouthi	:	out std_logic;
		regoutlo	:	out std_logic;
		sreset	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_clkena parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_clkena
	generic (
		clock_type	:	string := "Auto";
		disable_mode	:	string := "low";
		ena_register_mode	:	string := "always enabled";
		ena_register_power_up	:	string := "high";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_clkena";
		test_syn	:	string := "high"	);
	port(
		ena	:	in std_logic := '1';
		enaout	:	out std_logic;
		inclk	:	in std_logic := '1';
		outclk	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- stratixv_half_rate_input parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_half_rate_input
	generic (
		async_mode	:	string := "none";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_half_rate_input";
		power_up	:	string := "low";
		use_dataoutbypass	:	string := "false"	);
	port(
		areset	:	in std_logic := '0';
		clk	:	in std_logic := '0';
		datain	:	in std_logic_vector(1 downto 0) := (others => '0');
		dataout	:	out std_logic_vector(3 downto 0);
		dataoutbypass	:	in std_logic := '0';
		dffin	:	out std_logic_vector(1 downto 0);
		directin	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_mac parameterized megafunction component declaration
-- Generated with 'clearbox' loader - do not edit
------------------------------------------------------------------
component stratixv_mac
	generic (
		accumulate_clock	:	string := "none";
		ax_clock	:	string := "none";
		ax_width	:	natural := 16;
		ay_scan_in_clock	:	string := "none";
		ay_scan_in_width	:	natural := 16;
		ay_use_scan_in	:	string := "false";
		az_clock	:	string := "none";
		az_width	:	natural := 1;
		bx_clock	:	string := "none";
		bx_width	:	natural := 16;
		by_clock	:	string := "none";
		by_use_scan_in	:	string := "false";
		by_width	:	natural := 16;
		coef_a_0	:	natural := 0;
		coef_a_1	:	natural := 0;
		coef_a_2	:	natural := 0;
		coef_a_3	:	natural := 0;
		coef_a_4	:	natural := 0;
		coef_a_5	:	natural := 0;
		coef_a_6	:	natural := 0;
		coef_a_7	:	natural := 0;
		coef_b_0	:	natural := 0;
		coef_b_1	:	natural := 0;
		coef_b_2	:	natural := 0;
		coef_b_3	:	natural := 0;
		coef_b_4	:	natural := 0;
		coef_b_5	:	natural := 0;
		coef_b_6	:	natural := 0;
		coef_b_7	:	natural := 0;
		coef_sel_a_clock	:	string := "none";
		coef_sel_b_clock	:	string := "none";
		complex_clock	:	string := "none";
		delay_scan_out_ay	:	string := "false";
		delay_scan_out_by	:	string := "false";
		load_const_clock	:	string := "none";
		load_const_value	:	natural := 0;
		mode_sub_location	:	natural := 0;
		negate_clock	:	string := "none";
		operand_source_max	:	string := "input";
		operand_source_may	:	string := "input";
		operand_source_mbx	:	string := "input";
		operand_source_mby	:	string := "input";
		operation_mode	:	string := "m18x18_sumof2";
		output_clock	:	string := "none";
		preadder_subtract_a	:	string := "false";
		preadder_subtract_b	:	string := "false";
		result_a_width	:	natural := 64;
		result_b_width	:	natural := 1;
		scan_out_width	:	natural := 1;
		signed_max	:	string := "false";
		signed_may	:	string := "false";
		signed_mbx	:	string := "false";
		signed_mby	:	string := "false";
		sub_clock	:	string := "none";
		use_chainadder	:	string := "false";
		lpm_type	:	string := "stratixv_mac"
	);
	port(
		accumulate	:	in std_logic := '0';
		aclr	:	in std_logic_vector(1 downto 0) := (others => '0');
		ax	:	in std_logic_vector(ax_width-1 downto 0) := (others => '0');
		ay	:	in std_logic_vector(ay_scan_in_width-1 downto 0) := (others => '0');
		az	:	in std_logic_vector(az_width-1 downto 0) := (others => '0');
		bx	:	in std_logic_vector(bx_width-1 downto 0) := (others => '0');
		by	:	in std_logic_vector(by_width-1 downto 0) := (others => '0');
		chainin	:	in std_logic_vector(63 downto 0) := (others => '0');
		chainout	:	out std_logic_vector(63 downto 0);
		cin	:	in std_logic := '0';
		clk	:	in std_logic_vector(2 downto 0) := (others => '0');
		coefsela	:	in std_logic_vector(2 downto 0) := (others => '0');
		coefselb	:	in std_logic_vector(2 downto 0) := (others => '0');
		complex	:	in std_logic := '0';
		cout	:	out std_logic;
		dftout	:	out std_logic;
		ena	:	in std_logic_vector(2 downto 0) := (others => '1');
		loadconst	:	in std_logic := '0';
		negate	:	in std_logic := '0';
		resulta	:	out std_logic_vector(result_a_width-1 downto 0);
		resultb	:	out std_logic_vector(result_b_width-1 downto 0);
		scanin	:	in std_logic_vector(ay_scan_in_width-1 downto 0) := (others => '0');
		scanout	:	out std_logic_vector(scan_out_width-1 downto 0);
		sub	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_ddio_oe parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_ddio_oe
	generic (
		async_mode	:	string := "none";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_ddio_oe";
		power_up	:	string := "low";
		sync_mode	:	string := "none"	);
	port(
		areset	:	in std_logic := '0';
		clk	:	in std_logic := '0';
		dataout	:	out std_logic;
		dffhi	:	out std_logic;
		dfflo	:	out std_logic;
		ena	:	in std_logic := '1';
		oe	:	in std_logic := '1';
		sreset	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_io_config parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_io_config
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_io_config";
		use_pvt_compensation	:	string := "false";
		use_read_vt_tracking	:	string := "false"	);
	port(
		calibrationdone	:	in std_logic := '0';
		clk	:	in std_logic := '0';
		datain	:	in std_logic := '0';
		dataout	:	out std_logic;
		delayctrlin	:	in std_logic_vector(6 downto 0) := (others => '0');
		dutycycledelaymode	:	out std_logic;
		dutycycledelaysetting	:	out std_logic_vector(3 downto 0);
		ena	:	in std_logic := '0';
		inputclkdelaysetting	:	out std_logic_vector(1 downto 0);
		inputclkndelaysetting	:	out std_logic_vector(1 downto 0);
		outputdelaysetting1	:	out std_logic_vector(5 downto 0);
		outputdelaysetting2	:	out std_logic_vector(5 downto 0);
		padtoinputregisterdelaysetting	:	out std_logic_vector(5 downto 0);
		padtoinputregisterrisefalldelaysetting	:	out std_logic_vector(5 downto 0);
		rankselectread	:	in std_logic := '0';
		rankselectwrite	:	in std_logic := '0';
		update	:	in std_logic := '0';
		vtreadstatus	:	out std_logic_vector(1 downto 0)
	);
end component;

------------------------------------------------------------------
-- stratixv_clkburst parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_clkburst
	generic (
		burstcnt_ctrl	:	string := "static";
		lpm_type	:	string := "stratixv_clkburst";
		static_burstcnt	:	string := "cnt0"	);
	port(
		burstcnt	:	in std_logic_vector(2 downto 0) := (others => '0');
		ena	:	in std_logic := '0';
		enaout	:	out std_logic;
		inclk	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_read_fifo_read_enable parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_read_fifo_read_enable
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_read_fifo_read_enable";
		use_stalled_read_enable	:	string := "false"	);
	port(
		areset	:	in std_logic := '0';
		plus2	:	in std_logic := '0';
		plus2out	:	out std_logic;
		rclk	:	in std_logic := '0';
		re	:	in std_logic := '1';
		reout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- stratixv_pll_dll_output parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_pll_dll_output
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_pll_dll_output";
		pll_dll_src	:	string := "vss"	);
	port(
		cclk	:	in std_logic_vector(17 downto 0) := (others => '0');
		clkin	:	in std_logic_vector(3 downto 0) := (others => '0');
		clkout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- stratixv_duty_cycle_adjustment parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_duty_cycle_adjustment
	generic (
		dca_config_mode	:	natural := 0;
		dca_config_static_delayctrl_setting	:	natural := 0;
		duty_cycle_delay_mode	:	string := "none";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_duty_cycle_adjustment"	);
	port(
		clkin	:	in std_logic := '0';
		clkout	:	out std_logic;
		delayctrlin	:	in std_logic_vector(3 downto 0) := (others => '0');
		delaymode	:	in std_logic_vector(1 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- stratixv_lvds_rx parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_lvds_rx
	generic (
		align_to_rising_edge_only	:	string := "false";
		data_align_rollover	:	natural := 0;
		data_width	:	natural := 10;
		dpa_clock_output_phase_shift	:	natural := 0;
		dpa_config	:	natural := 0;
		dpa_debug	:	string := "false";
		dpa_initial_phase_value	:	natural := 0;
		enable_clock_pin_mode	:	string := "false";
		enable_dpa	:	string := "false";
		enable_dpa_align_to_rising_edge_only	:	string := "false";
		enable_dpa_initial_phase_selection	:	string := "false";
		enable_soft_cdr	:	string := "false";
		is_negative_ppm_drift	:	string := "false";
		lose_lock_on_one_change	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_lvds_rx";
		net_ppm_variation	:	natural := 0;
		reset_fifo_at_first_lock	:	string := "false";
		rx_input_path_delay_engineering_bits	:	natural := 0;
		use_serial_feedback_input	:	string := "off";
		x_on_bitslip	:	string := "false"	);
	port(
		bitslip	:	in std_logic := '0';
		bitslipmax	:	out std_logic;
		bitslipreset	:	in std_logic := '0';
		clock0	:	in std_logic := '0';
		datain	:	in std_logic := '0';
		dataout	:	out std_logic_vector(9 downto 0);
		divfwdclk	:	out std_logic;
		dpaclkin	:	in std_logic_vector(7 downto 0) := (others => '0');
		dpaclkout	:	out std_logic;
		dpahold	:	in std_logic := '0';
		dpalock	:	out std_logic;
		dpareset	:	in std_logic := '0';
		dpaswitch	:	in std_logic := '1';
		enable0	:	in std_logic := '0';
		fiforeset	:	in std_logic := '0';
		observableout	:	out std_logic_vector(3 downto 0);
		postdpaserialdataout	:	out std_logic;
		serialdataout	:	out std_logic;
		serialfbk	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_output_alignment parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_output_alignment
	generic (
		add_output_cycle_delay	:	string := "false";
		add_phase_transfer_reg	:	string := "false";
		async_mode	:	string := "none";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_output_alignment";
		power_up	:	string := "low";
		sync_mode	:	string := "none"	);
	port(
		areset	:	in std_logic := '0';
		clk	:	in std_logic := '0';
		datain	:	in std_logic := '1';
		dataout	:	out std_logic;
		dff1t	:	out std_logic;
		dff2t	:	out std_logic;
		dffin	:	out std_logic;
		dffphasetransfer	:	out std_logic;
		enaoutputcycledelay	:	in std_logic_vector(2 downto 0) := (others => '0');
		enaphasetransferreg	:	in std_logic := '0';
		sreset	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_dqs_enable_ctrl parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_dqs_enable_ctrl
	generic (
		add_phase_transfer_reg	:	string := "false";
		bypass_output_register	:	string := "false";
		delay_dqs_enable_by_half_cycle	:	string := "false";
		ext_delay_chain_setting	:	natural := 0;
		int_delay_chain_setting	:	natural := 0;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_dqs_enable_ctrl";
		sim_dqsenablein_pre_delay	:	natural := 0;
		use_enable_tracking	:	string := "false";
		use_on_die_variation_tracking	:	string := "false";
		use_pvt_compensation	:	string := "false"	);
	port(
		coredqsdisablendelayctrlin	:	in std_logic_vector(7 downto 0) := (others => '0');
		coredqsdisablendelayctrlout	:	out std_logic_vector(7 downto 0);
		coredqsenabledelayctrlin	:	in std_logic_vector(7 downto 0) := (others => '0');
		coredqsenabledelayctrlout	:	out std_logic_vector(7 downto 0);
		dffextenddqsenable	:	out std_logic;
		dffin	:	out std_logic;
		dffphasetransfer	:	out std_logic;
		dqsenablein	:	in std_logic := '0';
		dqsenableout	:	out std_logic;
		enaphasetransferreg	:	in std_logic := '0';
		enatrackingevent	:	out std_logic;
		enatrackingreset	:	in std_logic := '0';
		enatrackingupdwn	:	out std_logic;
		levelingclk	:	in std_logic := '0';
		nextphasealign	:	out std_logic;
		prevphasealign	:	out std_logic;
		prevphasedelaysetting	:	out std_logic_vector(5 downto 0);
		prevphasevalid	:	out std_logic;
		rankclkout	:	out std_logic;
		zerophaseclk	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_ff parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_ff
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_ff";
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
-- stratixv_fractional_pll parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_fractional_pll
	generic (
		dsm_accumulator_reset_value	:	natural := 0;
		forcelock	:	string := "false";
		fractional_pll_index	:	natural := 1;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_fractional_pll";
		mimic_fbclk_type	:	string := "gclk";
		nreset_invert	:	string := "false";
		output_clock_frequency	:	string := "0 ps";
		pll_atb	:	natural := 0;
		pll_bwctrl	:	natural := 10000;
		pll_cmp_buf_dly	:	string := "0 ps";
		pll_cp_comp	:	string := "true";
		pll_cp_current	:	natural := 20;
		pll_ctrl_override_setting	:	string := "false";
		pll_dsm_dither	:	string := "disable";
		pll_dsm_out_sel	:	string := "disable";
		pll_dsm_reset	:	string := "false";
		pll_ecn_bypass	:	string := "false";
		pll_ecn_test_en	:	string := "false";
		pll_enable	:	string := "true";
		pll_fbclk_mux_1	:	string := "glb";
		pll_fbclk_mux_2	:	string := "fb_1";
		pll_fractional_carry_out	:	natural := 24;
		pll_fractional_division	:	natural := 1;
		pll_fractional_division_string	:	string := "'0'";
		pll_fractional_value_ready	:	string := "true";
		pll_lf_testen	:	string := "false";
		pll_lock_fltr_cfg	:	natural := 0;
		pll_lock_fltr_test	:	string := "false";
		pll_m_cnt_bypass_en	:	string := "false";
		pll_m_cnt_coarse_dly	:	string := "0 ps";
		pll_m_cnt_fine_dly	:	string := "0 ps";
		pll_m_cnt_hi_div	:	natural := 1;
		pll_m_cnt_in_src	:	string := "ph_mux_clk";
		pll_m_cnt_lo_div	:	natural := 1;
		pll_m_cnt_odd_div_duty_en	:	string := "false";
		pll_m_cnt_ph_mux_prst	:	natural := 0;
		pll_m_cnt_prst	:	natural := 1;
		pll_n_cnt_bypass_en	:	string := "false";
		pll_n_cnt_coarse_dly	:	string := "0 ps";
		pll_n_cnt_fine_dly	:	string := "0 ps";
		pll_n_cnt_hi_div	:	natural := 1;
		pll_n_cnt_lo_div	:	natural := 1;
		pll_n_cnt_odd_div_duty_en	:	string := "false";
		pll_ref_buf_dly	:	string := "0 ps";
		pll_reg_boost	:	natural := 0;
		pll_regulator_bypass	:	string := "false";
		pll_ripplecap_ctrl	:	natural := 0;
		pll_slf_rst	:	string := "false";
		pll_tclk_mux_en	:	string := "false";
		pll_tclk_sel	:	string := "m_src";
		pll_test_enable	:	string := "false";
		pll_testdn_enable	:	string := "false";
		pll_testup_enable	:	string := "false";
		pll_unlock_fltr_cfg	:	natural := 0;
		pll_vco_div	:	natural := 2;
		pll_vco_ph0_en	:	string := "false";
		pll_vco_ph1_en	:	string := "false";
		pll_vco_ph2_en	:	string := "false";
		pll_vco_ph3_en	:	string := "false";
		pll_vco_ph4_en	:	string := "false";
		pll_vco_ph5_en	:	string := "false";
		pll_vco_ph6_en	:	string := "false";
		pll_vco_ph7_en	:	string := "false";
		pll_vctrl_test_voltage	:	natural := 750;
		reference_clock_frequency	:	string := "0 ps";
		vccd0g_atb	:	string := "disable";
		vccd0g_output	:	natural := 0;
		vccd1g_atb	:	string := "disable";
		vccd1g_output	:	natural := 0;
		vccm1g_tap	:	natural := 2;
		vccr_pd	:	string := "false";
		vcodiv_override	:	string := "false"	);
	port(
		cntnen	:	out std_logic;
		coreclkfb	:	in std_logic := '0';
		ecnc1test	:	in std_logic := '0';
		ecnc2test	:	in std_logic := '0';
		fbclk	:	out std_logic;
		fbclkfpll	:	in std_logic := '0';
		fblvdsout	:	out std_logic;
		lock	:	out std_logic;
		lvdsfbin	:	in std_logic := '0';
		mcntout	:	out std_logic;
		mhi	:	out std_logic_vector(7 downto 0);
		nresync	:	in std_logic := '1';
		pfden	:	in std_logic := '0';
		plniotribuf	:	out std_logic;
		refclkin	:	in std_logic := '0';
		shift	:	in std_logic := '0';
		shiftdonein	:	in std_logic := '0';
		shiftdoneout	:	out std_logic;
		shiften	:	in std_logic := '0';
		tclk	:	out std_logic;
		up	:	in std_logic := '0';
		vcoph	:	out std_logic_vector(7 downto 0);
		zdb	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_io_ibuf parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_io_ibuf
	generic (
		bus_hold	:	string := "false";
		differential_mode	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_io_ibuf";
		simulate_z_as	:	string := "z"	);
	port(
		dynamicterminationcontrol	:	in std_logic := '0';
		i	:	in std_logic := '0';
		ibar	:	in std_logic := '0';
		o	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- stratixv_pll_extclk_output parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_pll_extclk_output
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_pll_extclk_output";
		pll_extclk_cnt_src	:	string := "vss";
		pll_extclk_enable	:	string := "true";
		pll_extclk_invert	:	string := "false"	);
	port(
		cclk	:	in std_logic_vector(17 downto 0) := (others => '0');
		clken	:	in std_logic := '0';
		extclk	:	out std_logic;
		mcnt0	:	in std_logic := '0';
		mcnt1	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_dftblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_dftblock
	generic (
		lpm_type	:	string := "stratixv_dftblock"	);
	port(
		dftin	:	in std_logic_vector(5 downto 0) := (others => '0');
		dftout	:	out std_logic_vector(24 downto 0)
	);
end component;

------------------------------------------------------------------
-- stratixv_lcell_comb parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_lcell_comb
	generic (
		dont_touch	:	string := "off";
		extended_lut	:	string := "off";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_lcell_comb";
		lut_mask	:	std_logic_vector(63 downto 0) := "1111111111111111111111111111111111111111111111111111111111111111";
		shared_arith	:	string := "off"	);
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
-- stratixv_dll_offset_ctrl parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_dll_offset_ctrl
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_dll_offset_ctrl";
		static_offset	:	natural := 0;
		use_offset	:	string := "false";
		use_pvt_compensation	:	string := "false"	);
	port(
		addnsub	:	in std_logic := '0';
		aload	:	in std_logic := '0';
		clk	:	in std_logic := '0';
		offset	:	in std_logic_vector(6 downto 0) := (others => '0');
		offsetctrlout	:	out std_logic_vector(6 downto 0);
		offsetdelayctrlin	:	in std_logic_vector(6 downto 0) := (others => '0');
		offsettestout	:	out std_logic_vector(6 downto 0)
	);
end component;

------------------------------------------------------------------
-- stratixv_dqs_config parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_dqs_config
	generic (
		dca_calibration_block_input_select	:	natural := 0;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_dqs_config";
		use_pvt_compensation	:	string := "false"	);
	port(
		addrphaseinvert	:	out std_logic;
		addrphasesetting	:	out std_logic_vector(1 downto 0);
		addrpowerdown	:	out std_logic;
		calibrationdone	:	in std_logic := '0';
		ck2xoutputphaseinvert	:	out std_logic;
		ck2xoutputphasesetting	:	out std_logic_vector(1 downto 0);
		ck2xoutputpowerdown	:	out std_logic;
		clk	:	in std_logic := '0';
		coremultirankdelayctrlin	:	in std_logic_vector(7 downto 0) := (others => '0');
		coremultirankdelayctrlout	:	out std_logic_vector(7 downto 0);
		corerankselectreadin	:	in std_logic := '0';
		datain	:	in std_logic := '0';
		dataout	:	out std_logic;
		delayctrlin	:	in std_logic_vector(6 downto 0) := (others => '0');
		dftin	:	in std_logic_vector(20 downto 0) := (others => '0');
		dftout	:	out std_logic_vector(6 downto 0);
		dividerioehratephaseinvert	:	out std_logic;
		dividerphaseinvert	:	out std_logic;
		dq2xoutputphaseinvert	:	out std_logic;
		dq2xoutputphasesetting	:	out std_logic_vector(1 downto 0);
		dq2xoutputpowerdown	:	out std_logic;
		dqoutputphaseinvert	:	out std_logic;
		dqoutputphasesetting	:	out std_logic_vector(1 downto 0);
		dqoutputpowerdown	:	out std_logic;
		dqoutputzerophasesetting	:	out std_logic_vector(1 downto 0);
		dqs2xoutputphaseinvert	:	out std_logic;
		dqs2xoutputphasesetting	:	out std_logic_vector(1 downto 0);
		dqs2xoutputpowerdown	:	out std_logic;
		dqsbusoutdelaysetting	:	out std_logic_vector(5 downto 0);
		dqsbusoutdelaysetting2	:	out std_logic_vector(5 downto 0);
		dqsdisablendelaysetting	:	out std_logic_vector(7 downto 0);
		dqsenabledelaysetting	:	out std_logic_vector(7 downto 0);
		dqsinputphasesetting	:	out std_logic_vector(1 downto 0);
		dqsoutputphaseinvert	:	out std_logic;
		dqsoutputphasesetting	:	out std_logic_vector(1 downto 0);
		dqsoutputpowerdown	:	out std_logic;
		dutycycledelaysetting	:	out std_logic_vector(3 downto 0);
		ena	:	in std_logic := '0';
		enadqscycledelaysetting	:	out std_logic_vector(2 downto 0);
		enadqsenablephasetransferreg	:	out std_logic;
		enadqsphasetransferreg	:	out std_logic;
		enainputcycledelaysetting	:	out std_logic;
		enainputphasetransferreg	:	out std_logic;
		enaoctcycledelaysetting	:	out std_logic_vector(2 downto 0);
		enaoctphasetransferreg	:	out std_logic;
		enaoutputcycledelaysetting	:	out std_logic_vector(2 downto 0);
		enaoutputphasetransferreg	:	out std_logic;
		octdelaysetting1	:	out std_logic_vector(5 downto 0);
		octdelaysetting2	:	out std_logic_vector(5 downto 0);
		postamblephaseinvert	:	out std_logic;
		postamblephasesetting	:	out std_logic_vector(1 downto 0);
		postamblepowerdown	:	out std_logic;
		postamblezerophasesetting	:	out std_logic_vector(1 downto 0);
		postamblezeropowerdown	:	out std_logic;
		rankclkin	:	in std_logic := '0';
		rankselectread	:	in std_logic := '0';
		rankselectreadout	:	out std_logic;
		rankselectwrite	:	in std_logic := '0';
		resyncinputphaseinvert	:	out std_logic;
		resyncinputphasesetting	:	out std_logic_vector(1 downto 0);
		resyncinputpowerdown	:	out std_logic;
		resyncinputzerophaseinvert	:	out std_logic;
		update	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_pll_lvds_output parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_pll_lvds_output
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_pll_lvds_output";
		pll_loaden_coarse_dly	:	string := "0 ps";
		pll_loaden_enable_disable	:	string := "false";
		pll_loaden_fine_dly	:	string := "0 ps";
		pll_lvdsclk_coarse_dly	:	string := "0 ps";
		pll_lvdsclk_enable_disable	:	string := "false";
		pll_lvdsclk_fine_dly	:	string := "0 ps"	);
	port(
		ccout	:	in std_logic_vector(1 downto 0) := (others => '0');
		loaden	:	out std_logic;
		lvdsclk	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- stratixv_termination_logic parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_termination_logic
	generic (
		a_iob_oct_test	:	string := "a_iob_oct_test_off";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_termination_logic"	);
	port(
		enser	:	in std_logic_vector(10 downto 0) := (others => '0');
		parallelterminationcontrol	:	out std_logic_vector(15 downto 0);
		s2pload	:	in std_logic := '0';
		scanclk	:	in std_logic := '0';
		scanenable	:	in std_logic := '0';
		serdata	:	in std_logic := '0';
		seriesterminationcontrol	:	out std_logic_vector(15 downto 0)
	);
end component;

------------------------------------------------------------------
-- stratixv_phb parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_phb
	generic (
		lpm_type	:	string := "stratixv_phb"	);
	port(
		phbinp	:	in std_logic_vector(63 downto 0) := (others => '0');
		phbout	:	out std_logic_vector(63 downto 0)
	);
end component;

------------------------------------------------------------------
-- stratixv_chipidblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_chipidblock
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_chipidblock"	);
	port(
		clk	:	in std_logic := '0';
		regout	:	out std_logic;
		shiftnld	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_termination parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_termination
	generic (
		a_oct_cal_mode	:	string := "a_oct_cal_mode_none";
		a_oct_calclr	:	string := "a_oct_calclr_off";
		a_oct_clkenusr_inv	:	string := "a_oct_clkenusr_inv_off";
		a_oct_enserusr_inv	:	string := "a_oct_enserusr_inv_off";
		a_oct_intosc	:	string := "a_oct_intosc_none";
		a_oct_nclrusr_inv	:	string := "a_oct_nclrusr_inv_off";
		a_oct_pllbiasen	:	string := "a_oct_pllbiasen_dis";
		a_oct_pwrdn	:	string := "true";
		a_oct_rsadjust	:	string := "a_oct_rsadjust_none";
		a_oct_rshft_rdn	:	string := "a_oct_rshft_rdn_enable";
		a_oct_rshft_rup	:	string := "a_oct_rshft_rup_enable";
		a_oct_rsmult	:	string := "a_oct_rsmult_1";
		a_oct_scanen_inv	:	string := "a_oct_scanen_inv_off";
		a_oct_test_0	:	string := "a_oct_test_0_off";
		a_oct_test_1	:	string := "a_oct_test_1_off";
		a_oct_test_4	:	string := "a_oct_test_4_off";
		a_oct_test_5	:	string := "a_oct_test_5_off";
		a_oct_user_oct	:	string := "a_oct_user_oct_off";
		a_oct_usermode	:	string := "false";
		a_oct_vrefh	:	string := "a_oct_vrefh_m";
		a_oct_vrefl	:	string := "a_oct_vrefl_m";
		lpm_hint	:	string := "unused";
		lpm_type	:	string := "stratixv_termination"	);
	port(
		clkenusr	:	in std_logic := '0';
		clkusr	:	in std_logic := '0';
		clkusrdftout	:	out std_logic;
		compoutrdn	:	out std_logic;
		compoutrup	:	out std_logic;
		enserout	:	out std_logic;
		enserusr	:	in std_logic := '0';
		nclrusr	:	in std_logic := '0';
		otherenser	:	in std_logic_vector(9 downto 0) := (others => '0');
		rzqin	:	in std_logic := '0';
		scanclk	:	in std_logic := '0';
		scanen	:	in std_logic := '0';
		scanin	:	in std_logic := '0';
		scanout	:	out std_logic;
		serdatafromcore	:	in std_logic := '0';
		serdatain	:	in std_logic := '0';
		serdataout	:	out std_logic;
		serdatatocore	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- stratixv_ddio_out parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_ddio_out
	generic (
		async_mode	:	string := "none";
		half_rate_mode	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_ddio_out";
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
		dffhi	:	out std_logic_vector(1 downto 0);
		dfflo	:	out std_logic;
		ena	:	in std_logic := '1';
		muxsel	:	in std_logic := '0';
		sreset	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_dqs_delay_chain parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_dqs_delay_chain
	generic (
		dqs_ctrl_latches_enable	:	string := "false";
		dqs_input_frequency	:	string := "0";
		dqs_offsetctrl_enable	:	string := "false";
		dqs_period	:	string := "unused";
		dqs_phase_shift	:	natural := 0;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_dqs_delay_chain";
		phase_setting	:	natural := 0;
		sim_buffer_delay_increment	:	natural := 10;
		sim_buffer_intrinsic_delay	:	natural := 175;
		test_enable	:	string := "false";
		use_alternate_input_for_first_stage_delayctrl	:	string := "false";
		use_phasectrlin	:	string := "false"	);
	port(
		delayctrlin	:	in std_logic_vector(6 downto 0) := (others => '0');
		dffin	:	out std_logic;
		dqsbusout	:	out std_logic;
		dqsdisablen	:	in std_logic := '1';
		dqsenable	:	in std_logic := '0';
		dqsin	:	in std_logic := '0';
		dqsupdateen	:	in std_logic := '0';
		offsetctrlin	:	in std_logic_vector(6 downto 0) := (others => '0');
		phasectrlin	:	in std_logic_vector(1 downto 0) := (others => '0');
		testin	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_pll_dpa_output parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_pll_dpa_output
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_pll_dpa_output";
		output_clock_frequency	:	string := "0 ps";
		pll_vcoph_div	:	natural := 1	);
	port(
		pd	:	in std_logic := '0';
		phin	:	in std_logic_vector(7 downto 0) := (others => '0');
		phout	:	out std_logic_vector(7 downto 0)
	);
end component;

------------------------------------------------------------------
-- stratixv_clk_phase_select parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_clk_phase_select
	generic (
		invert_phase	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_clk_phase_select";
		phase_setting	:	natural := 0;
		physical_clock_source	:	string := "auto";
		use_phasectrlin	:	string := "true"	);
	port(
		clkin	:	in std_logic_vector(3 downto 0) := (others => '0');
		clkout	:	out std_logic;
		phasectrlin	:	in std_logic_vector(1 downto 0) := (others => '0');
		phaseinvertctrl	:	in std_logic := '0';
		powerdown	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_pll_reconfig parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_pll_reconfig
	generic (
		fractional_pll_index	:	natural := 1;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_pll_reconfig"	);
	port(
		addr	:	in std_logic_vector(5 downto 0) := (others => '0');
		atpgmode	:	in std_logic := '0';
		blockselect	:	out std_logic;
		byteen	:	in std_logic_vector(1 downto 0) := (others => '0');
		clk	:	in std_logic := '0';
		cntnen	:	in std_logic := '0';
		cntsel	:	in std_logic_vector(4 downto 0) := (others => '0');
		din	:	in std_logic_vector(15 downto 0) := (others => '0');
		dout	:	out std_logic_vector(15 downto 0);
		dprioout	:	out std_logic_vector(815 downto 0);
		fpllcsrtest	:	in std_logic := '0';
		iocsrclkin	:	in std_logic := '0';
		iocsrdatain	:	in std_logic := '0';
		iocsrdataout	:	out std_logic;
		iocsren	:	in std_logic := '0';
		iocsrenbuf	:	out std_logic;
		iocsrrstn	:	in std_logic := '0';
		iocsrrstnbuf	:	out std_logic;
		mdiodis	:	in std_logic := '0';
		mhi	:	in std_logic_vector(7 downto 0) := (others => '0');
		phasedone	:	out std_logic;
		phaseen	:	in std_logic := '0';
		read	:	in std_logic := '0';
		rstn	:	in std_logic := '0';
		scanen	:	in std_logic := '0';
		sershiftload	:	in std_logic := '0';
		shift	:	out std_logic;
		shiftdonei	:	in std_logic := '0';
		shiften	:	out std_logic_vector(17 downto 0);
		shiftenm	:	out std_logic;
		up	:	out std_logic;
		updn	:	in std_logic := '0';
		write	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- stratixv_pseudo_diff_out parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_pseudo_diff_out
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_pseudo_diff_out"	);
	port(
		dtc	:	out std_logic;
		dtcbar	:	out std_logic;
		dtcin	:	in std_logic := '0';
		i	:	in std_logic := '0';
		o	:	out std_logic;
		obar	:	out std_logic;
		oebout	:	out std_logic;
		oein	:	in std_logic := '0';
		oeout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- stratixv_tsdblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_tsdblock
	generic (
		clock_divider_enable	:	string := "false";
		clock_divider_value	:	natural := 40;
		lpm_hint	:	string := "unused";
		lpm_type	:	string := "stratixv_tsdblock";
		sim_tsdcalo	:	natural := 0	);
	port(
		ce	:	in std_logic := '1';
		clk	:	in std_logic := '0';
		clr	:	in std_logic := '0';
		tsdcaldone	:	out std_logic;
		tsdcalo	:	out std_logic_vector(7 downto 0)
	);
end component;

------------------------------------------------------------------
-- stratixv_clkselect parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_clkselect
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_clkselect";
		test_cff	:	string := "low"	);
	port(
		clkselect	:	in std_logic_vector(1 downto 0) := (others => '0');
		inclk	:	in std_logic_vector(3 downto 0) := (others => '0');
		outclk	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- stratixv_lvds_tx parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component stratixv_lvds_tx
	generic (
		bypass_serializer	:	string := "false";
		data_width	:	natural := 10;
		enable_clock_pin_mode	:	string := "false";
		enable_dpaclk_to_lvdsout	:	string := "false";
		invert_clock	:	string := "false";
		is_used_as_outclk	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "stratixv_lvds_tx";
		tx_output_path_delay_engineering_bits	:	natural := 0;
		use_falling_clock_edge	:	string := "false";
		use_post_dpa_serial_data_input	:	string := "false";
		use_serial_data_input	:	string := "false"	);
	port(
		clock0	:	in std_logic := '0';
		datain	:	in std_logic_vector(9 downto 0) := (others => '0');
		dataout	:	out std_logic;
		dpaclkin	:	in std_logic := '0';
		enable0	:	in std_logic := '0';
		observableout	:	out std_logic_vector(2 downto 0);
		postdpaserialdatain	:	in std_logic := '0';
		serialdatain	:	in std_logic := '0';
		serialfdbkout	:	out std_logic
	);
end component;

--clearbox auto-generated components end
end stratixv_components;
