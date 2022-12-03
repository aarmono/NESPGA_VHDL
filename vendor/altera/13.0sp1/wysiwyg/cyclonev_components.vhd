library IEEE, cyclonev;
use IEEE.STD_LOGIC_1164.all;

package cyclonev_components is

--clearbox auto-generated components begin
--Dont add any component declarations after this section

------------------------------------------------------------------
-- cyclonev_fractional_pll parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_fractional_pll
	generic (
		dsm_accumulator_reset_value	:	natural := 0;
		forcelock	:	string := "false";
		fractional_pll_index	:	natural := 1;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_fractional_pll";
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
		pll_vco_div	:	natural := 1;
		pll_vco_ph0_en	:	string := "false";
		pll_vco_ph1_en	:	string := "false";
		pll_vco_ph2_en	:	string := "false";
		pll_vco_ph3_en	:	string := "false";
		pll_vco_ph4_en	:	string := "false";
		pll_vco_ph5_en	:	string := "false";
		pll_vco_ph6_en	:	string := "false";
		pll_vco_ph7_en	:	string := "false";
		pll_vctrl_test_voltage	:	natural := 0;
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
		nresync	:	in std_logic := '0';
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
-- cyclonev_termination_logic parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_termination_logic
	generic (
		a_iob_oct_test	:	string := "a_iob_oct_test_off";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_termination_logic"	);
	port(
		parallelterminationcontrol	:	out std_logic_vector(15 downto 0);
		s2pload	:	in std_logic := '0';
		scanclk	:	in std_logic := '0';
		scanenable	:	in std_logic := '0';
		serdata	:	in std_logic := '0';
		seriesterminationcontrol	:	out std_logic_vector(15 downto 0)
	);
end component;

------------------------------------------------------------------
-- cyclonev_pll_dll_output parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_pll_dll_output
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_pll_dll_output";
		pll_dll_src	:	string := "c_0_cnt"	);
	port(
		cclk	:	in std_logic_vector(17 downto 0) := (others => '0');
		clkin	:	in std_logic_vector(3 downto 0) := (others => '0');
		clkout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_termination parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_termination
	generic (
		a_oct_clkdiv	:	string := "a_oct_clkdiv_20";
		a_oct_intosc	:	string := "a_oct_intosc_none";
		a_oct_nclrusr_inv	:	string := "a_oct_nclrusr_inv_off";
		a_oct_pllbiasen	:	string := "a_oct_pllbiasen_low";
		a_oct_pwrdn	:	string := "true";
		a_oct_test_0	:	string := "a_oct_test_0_off";
		a_oct_test_1	:	string := "a_oct_test_1_off";
		a_oct_test_2	:	string := "a_oct_test_2_off";
		a_oct_test_3	:	string := "a_oct_test_3_off";
		a_oct_test_4	:	string := "a_oct_test_4_off";
		a_oct_test_5	:	string := "a_oct_test_5_off";
		a_oct_usermode	:	string := "false";
		a_oct_vref	:	string := "a_oct_vref_rupm_rdnm";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_termination"	);
	port(
		clkenusr	:	in std_logic := '0';
		clkusr	:	in std_logic := '0';
		compoutrdn	:	out std_logic;
		compoutrup	:	out std_logic;
		enserout	:	out std_logic;
		enserusr	:	in std_logic := '0';
		nclrusr	:	in std_logic := '0';
		otherenser	:	in std_logic_vector(9 downto 0) := (others => '0');
		rzqin	:	in std_logic := '0';
		scanclk	:	in std_logic := '0';
		scanin	:	in std_logic := '0';
		scanout	:	out std_logic;
		serdatafromcore	:	in std_logic := '0';
		serdataout	:	out std_logic;
		serdatatocore	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_pll_reconfig parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_pll_reconfig
	generic (
		fractional_pll_index	:	natural := 1;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_pll_reconfig"	);
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
		shiften	:	out std_logic_vector(8 downto 0);
		shiftenm	:	out std_logic;
		up	:	out std_logic;
		updn	:	in std_logic := '0';
		write	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_pll_output_counter parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_pll_output_counter
	generic (
		c_cnt_coarse_dly	:	string := "0 ps";
		c_cnt_fine_dly	:	string := "0 ps";
		c_cnt_in_src	:	string := "ph_mux_clk";
		c_cnt_ph_mux_prst	:	natural := 0;
		c_cnt_prst	:	natural := 1;
		cnt_fpll_src	:	string := "fpll_0";
		dprio0_cnt_bypass_en	:	string := "false";
		dprio0_cnt_hi_div	:	natural := 1;
		dprio0_cnt_lo_div	:	natural := 1;
		dprio0_cnt_odd_div_even_duty_en	:	string := "false";
		duty_cycle	:	natural := 50;
		fractional_pll_index	:	natural := 1;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_pll_output_counter";
		output_clock_frequency	:	string := "0 ps";
		output_counter_index	:	natural := 1;
		phase_shift	:	string := "0 ps"	);
	port(
		cascadein	:	in std_logic := '0';
		cascadeout	:	out std_logic;
		divclk	:	out std_logic;
		nen0	:	in std_logic := '0';
		shift0	:	in std_logic := '0';
		shiftdone0i	:	in std_logic := '0';
		shiftdone0o	:	out std_logic;
		shiften	:	in std_logic := '0';
		tclk0	:	in std_logic := '0';
		up0	:	in std_logic := '0';
		vco0ph	:	in std_logic_vector(7 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- cyclonev_pll_dpa_output parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_pll_dpa_output
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_pll_dpa_output";
		output_clock_frequency	:	string := "0 ps";
		pll_vcoph_div	:	natural := 1	);
	port(
		pd	:	in std_logic := '0';
		phin	:	in std_logic_vector(7 downto 0) := (others => '0');
		phout	:	out std_logic_vector(7 downto 0)
	);
end component;

------------------------------------------------------------------
-- cyclonev_pll_refclk_select parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_pll_refclk_select
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_pll_refclk_select";
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
-- cyclonev_pll_extclk_output parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_pll_extclk_output
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_pll_extclk_output";
		pll_extclk_cnt_src	:	string := "m0_cnt";
		pll_extclk_enable	:	string := "true";
		pll_extclk_invert	:	string := "false"	);
	port(
		cclk	:	in std_logic_vector(8 downto 0) := (others => '0');
		clken	:	in std_logic := '0';
		extclk	:	out std_logic;
		mcnt0	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_pll_lvds_output parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_pll_lvds_output
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_pll_lvds_output";
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
-- cyclonev_hmc parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hmc
	generic (
		attr_counter_one_mask	:	std_logic_vector(63 downto 0) := "0000000000000000000000000000000000000000000000000000000000000000";
		attr_counter_one_match	:	std_logic_vector(63 downto 0) := "0000000000000000000000000000000000000000000000000000000000000000";
		attr_counter_one_reset	:	string := "disabled";
		attr_counter_zero_mask	:	std_logic_vector(63 downto 0) := "0000000000000000000000000000000000000000000000000000000000000000";
		attr_counter_zero_match	:	std_logic_vector(63 downto 0) := "0000000000000000000000000000000000000000000000000000000000000000";
		attr_counter_zero_reset	:	string := "disabled";
		attr_debug_select_byte	:	std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
		attr_static_config_valid	:	string := "disabled";
		auto_pch_enable_0	:	string := "disabled";
		auto_pch_enable_1	:	string := "disabled";
		auto_pch_enable_2	:	string := "disabled";
		auto_pch_enable_3	:	string := "disabled";
		auto_pch_enable_4	:	string := "disabled";
		auto_pch_enable_5	:	string := "disabled";
		cal_req	:	string := "disabled";
		cfg_burst_length	:	string := "bl_8";
		cfg_interface_width	:	string := "dwidth_32";
		cfg_self_rfsh_exit_cycles	:	string := "self_rfsh_exit_cycles_512";
		cfg_starve_limit	:	string := "starve_limit_32";
		cfg_type	:	string := "ddr3";
		clr_intr	:	string := "no_clr_intr";
		cmd_port_in_use_0	:	string := "false";
		cmd_port_in_use_1	:	string := "false";
		cmd_port_in_use_2	:	string := "false";
		cmd_port_in_use_3	:	string := "false";
		cmd_port_in_use_4	:	string := "false";
		cmd_port_in_use_5	:	string := "false";
		cport0_rdy_almost_full	:	string := "not_full";
		cport0_rfifo_map	:	string := "fifo_0";
		cport0_type	:	string := "disable";
		cport0_wfifo_map	:	string := "fifo_0";
		cport1_rdy_almost_full	:	string := "not_full";
		cport1_rfifo_map	:	string := "fifo_0";
		cport1_type	:	string := "disable";
		cport1_wfifo_map	:	string := "fifo_0";
		cport2_rdy_almost_full	:	string := "not_full";
		cport2_rfifo_map	:	string := "fifo_0";
		cport2_type	:	string := "disable";
		cport2_wfifo_map	:	string := "fifo_0";
		cport3_rdy_almost_full	:	string := "not_full";
		cport3_rfifo_map	:	string := "fifo_0";
		cport3_type	:	string := "disable";
		cport3_wfifo_map	:	string := "fifo_0";
		cport4_rdy_almost_full	:	string := "not_full";
		cport4_rfifo_map	:	string := "fifo_0";
		cport4_type	:	string := "disable";
		cport4_wfifo_map	:	string := "fifo_0";
		cport5_rdy_almost_full	:	string := "not_full";
		cport5_rfifo_map	:	string := "fifo_0";
		cport5_type	:	string := "disable";
		cport5_wfifo_map	:	string := "fifo_0";
		ctl_addr_order	:	string := "chip_bank_row_col";
		ctl_ecc_enabled	:	string := "ctl_ecc_disabled";
		ctl_ecc_rmw_enabled	:	string := "ctl_ecc_rmw_disabled";
		ctl_regdimm_enabled	:	string := "regdimm_disabled";
		ctl_usr_refresh	:	string := "ctl_usr_refresh_disabled";
		ctrl_width	:	string := "data_width_64_bit";
		cyc_to_rld_jars_0	:	natural := 128;
		cyc_to_rld_jars_1	:	natural := 128;
		cyc_to_rld_jars_2	:	natural := 128;
		cyc_to_rld_jars_3	:	natural := 128;
		cyc_to_rld_jars_4	:	natural := 128;
		cyc_to_rld_jars_5	:	natural := 128;
		delay_bonding	:	string := "bonding_latency_0";
		dfx_bypass_enable	:	string := "dfx_bypass_disabled";
		disable_merging	:	string := "merging_enabled";
		ecc_dq_width	:	string := "ecc_dq_width_0";
		enable_atpg	:	string := "disabled";
		enable_bonding_0	:	string := "disabled";
		enable_bonding_1	:	string := "disabled";
		enable_bonding_2	:	string := "disabled";
		enable_bonding_3	:	string := "disabled";
		enable_bonding_4	:	string := "disabled";
		enable_bonding_5	:	string := "disabled";
		enable_bonding_wrapback	:	string := "disabled";
		enable_burst_interrupt	:	string := "disabled";
		enable_burst_terminate	:	string := "disabled";
		enable_dqs_tracking	:	string := "disabled";
		enable_ecc_code_overwrites	:	string := "disabled";
		enable_fast_exit_ppd	:	string := "disabled";
		enable_intr	:	string := "disabled";
		enable_no_dm	:	string := "disabled";
		enable_pipelineglobal	:	string := "disabled";
		extra_ctl_clk_act_to_act	:	natural := 0;
		extra_ctl_clk_act_to_act_diff_bank	:	natural := 0;
		extra_ctl_clk_act_to_pch	:	natural := 0;
		extra_ctl_clk_act_to_rdwr	:	natural := 0;
		extra_ctl_clk_arf_period	:	natural := 0;
		extra_ctl_clk_arf_to_valid	:	natural := 0;
		extra_ctl_clk_four_act_to_act	:	natural := 0;
		extra_ctl_clk_pch_all_to_valid	:	natural := 0;
		extra_ctl_clk_pch_to_valid	:	natural := 0;
		extra_ctl_clk_pdn_period	:	natural := 0;
		extra_ctl_clk_pdn_to_valid	:	natural := 0;
		extra_ctl_clk_rd_ap_to_valid	:	natural := 0;
		extra_ctl_clk_rd_to_pch	:	natural := 0;
		extra_ctl_clk_rd_to_rd	:	natural := 0;
		extra_ctl_clk_rd_to_rd_diff_chip	:	natural := 0;
		extra_ctl_clk_rd_to_wr	:	natural := 0;
		extra_ctl_clk_rd_to_wr_bc	:	natural := 0;
		extra_ctl_clk_rd_to_wr_diff_chip	:	natural := 0;
		extra_ctl_clk_srf_to_valid	:	natural := 0;
		extra_ctl_clk_srf_to_zq_cal	:	natural := 0;
		extra_ctl_clk_wr_ap_to_valid	:	natural := 0;
		extra_ctl_clk_wr_to_pch	:	natural := 0;
		extra_ctl_clk_wr_to_rd	:	natural := 0;
		extra_ctl_clk_wr_to_rd_bc	:	natural := 0;
		extra_ctl_clk_wr_to_rd_diff_chip	:	natural := 0;
		extra_ctl_clk_wr_to_wr	:	natural := 0;
		extra_ctl_clk_wr_to_wr_diff_chip	:	natural := 0;
		gen_dbe	:	string := "gen_dbe_disabled";
		gen_sbe	:	string := "gen_sbe_disabled";
		inc_sync	:	string := "fifo_set_2";
		local_if_cs_width	:	string := "addr_width_2";
		lpm_type	:	string := "cyclonev_hmc";
		mask_corr_dropped_intr	:	string := "disabled";
		mask_dbe_intr	:	string := "disabled";
		mask_sbe_intr	:	string := "disabled";
		mem_auto_pd_cycles	:	natural := 0;
		mem_clk_entry_cycles	:	natural := 10;
		mem_if_al	:	string := "al_0";
		mem_if_bankaddr_width	:	string := "addr_width_3";
		mem_if_burstlength	:	string := "mem_if_burstlength_8";
		mem_if_coladdr_width	:	string := "addr_width_12";
		mem_if_cs_per_rank	:	string := "mem_if_cs_per_rank_1";
		mem_if_cs_width	:	string := "mem_if_cs_width_1";
		mem_if_dq_per_chip	:	string := "mem_if_dq_per_chip_8";
		mem_if_dqs_width	:	string := "dqs_width_4";
		mem_if_dwidth	:	string := "mem_if_dwidth_32";
		mem_if_memtype	:	string := "ddr3_sdram";
		mem_if_rowaddr_width	:	string := "addr_width_16";
		mem_if_speedbin	:	string := "ddr3_1066_6_6_6";
		mem_if_tccd	:	string := "tccd_4";
		mem_if_tcl	:	string := "tcl_6";
		mem_if_tcwl	:	string := "tcwl_5";
		mem_if_tfaw	:	string := "tfaw_16";
		mem_if_tmrd	:	string := "tmrd_4";
		mem_if_tras	:	string := "tras_16";
		mem_if_trc	:	string := "trc_22";
		mem_if_trcd	:	string := "trcd_6";
		mem_if_trefi	:	natural := 3120;
		mem_if_trfc	:	natural := 34;
		mem_if_trp	:	string := "trp_6";
		mem_if_trrd	:	string := "trrd_4";
		mem_if_trtp	:	string := "trtp_4";
		mem_if_twr	:	string := "twr_6";
		mem_if_twtr	:	string := "twtr_4";
		mmr_cfg_mem_bl	:	string := "mp_bl_8";
		output_regd	:	string := "disabled";
		pdn_exit_cycles	:	string := "slow_exit";
		port0_width	:	string := "port_64_bit";
		port1_width	:	string := "port_64_bit";
		port2_width	:	string := "port_64_bit";
		port3_width	:	string := "port_64_bit";
		port4_width	:	string := "port_64_bit";
		port5_width	:	string := "port_64_bit";
		power_saving_exit_cycles	:	natural := 5;
		priority_0_0	:	string := "weight_0";
		priority_0_1	:	string := "weight_0";
		priority_0_2	:	string := "weight_0";
		priority_0_3	:	string := "weight_0";
		priority_0_4	:	string := "weight_0";
		priority_0_5	:	string := "weight_0";
		priority_1_0	:	string := "weight_0";
		priority_1_1	:	string := "weight_0";
		priority_1_2	:	string := "weight_0";
		priority_1_3	:	string := "weight_0";
		priority_1_4	:	string := "weight_0";
		priority_1_5	:	string := "weight_0";
		priority_2_0	:	string := "weight_0";
		priority_2_1	:	string := "weight_0";
		priority_2_2	:	string := "weight_0";
		priority_2_3	:	string := "weight_0";
		priority_2_4	:	string := "weight_0";
		priority_2_5	:	string := "weight_0";
		priority_3_0	:	string := "weight_0";
		priority_3_1	:	string := "weight_0";
		priority_3_2	:	string := "weight_0";
		priority_3_3	:	string := "weight_0";
		priority_3_4	:	string := "weight_0";
		priority_3_5	:	string := "weight_0";
		priority_4_0	:	string := "weight_0";
		priority_4_1	:	string := "weight_0";
		priority_4_2	:	string := "weight_0";
		priority_4_3	:	string := "weight_0";
		priority_4_4	:	string := "weight_0";
		priority_4_5	:	string := "weight_0";
		priority_5_0	:	string := "weight_0";
		priority_5_1	:	string := "weight_0";
		priority_5_2	:	string := "weight_0";
		priority_5_3	:	string := "weight_0";
		priority_5_4	:	string := "weight_0";
		priority_5_5	:	string := "weight_0";
		priority_6_0	:	string := "weight_0";
		priority_6_1	:	string := "weight_0";
		priority_6_2	:	string := "weight_0";
		priority_6_3	:	string := "weight_0";
		priority_6_4	:	string := "weight_0";
		priority_6_5	:	string := "weight_0";
		priority_7_0	:	string := "weight_0";
		priority_7_1	:	string := "weight_0";
		priority_7_2	:	string := "weight_0";
		priority_7_3	:	string := "weight_0";
		priority_7_4	:	string := "weight_0";
		priority_7_5	:	string := "weight_0";
		priority_remap	:	natural := 0;
		rcfg_static_weight_0	:	string := "weight_0";
		rcfg_static_weight_1	:	string := "weight_0";
		rcfg_static_weight_2	:	string := "weight_0";
		rcfg_static_weight_3	:	string := "weight_0";
		rcfg_static_weight_4	:	string := "weight_0";
		rcfg_static_weight_5	:	string := "weight_0";
		rcfg_sum_wt_priority_0	:	natural := 0;
		rcfg_sum_wt_priority_1	:	natural := 0;
		rcfg_sum_wt_priority_2	:	natural := 0;
		rcfg_sum_wt_priority_3	:	natural := 0;
		rcfg_sum_wt_priority_4	:	natural := 0;
		rcfg_sum_wt_priority_5	:	natural := 0;
		rcfg_sum_wt_priority_6	:	natural := 0;
		rcfg_sum_wt_priority_7	:	natural := 0;
		rcfg_user_priority_0	:	string := "priority_0";
		rcfg_user_priority_1	:	string := "priority_0";
		rcfg_user_priority_2	:	string := "priority_0";
		rcfg_user_priority_3	:	string := "priority_0";
		rcfg_user_priority_4	:	string := "priority_0";
		rcfg_user_priority_5	:	string := "priority_0";
		rd_dwidth_0	:	string := "dwidth_0";
		rd_dwidth_1	:	string := "dwidth_0";
		rd_dwidth_2	:	string := "dwidth_0";
		rd_dwidth_3	:	string := "dwidth_0";
		rd_dwidth_4	:	string := "dwidth_0";
		rd_dwidth_5	:	string := "dwidth_0";
		rd_fifo_in_use_0	:	string := "false";
		rd_fifo_in_use_1	:	string := "false";
		rd_fifo_in_use_2	:	string := "false";
		rd_fifo_in_use_3	:	string := "false";
		rd_port_info_0	:	string := "use_no";
		rd_port_info_1	:	string := "use_no";
		rd_port_info_2	:	string := "use_no";
		rd_port_info_3	:	string := "use_no";
		rd_port_info_4	:	string := "use_no";
		rd_port_info_5	:	string := "use_no";
		read_odt_chip	:	string := "odt_disabled";
		reorder_data	:	string := "data_reordering";
		rfifo0_cport_map	:	string := "cmd_port_0";
		rfifo1_cport_map	:	string := "cmd_port_0";
		rfifo2_cport_map	:	string := "cmd_port_0";
		rfifo3_cport_map	:	string := "cmd_port_0";
		single_ready_0	:	string := "concatenate_rdy";
		single_ready_1	:	string := "concatenate_rdy";
		single_ready_2	:	string := "concatenate_rdy";
		single_ready_3	:	string := "concatenate_rdy";
		static_weight_0	:	string := "weight_0";
		static_weight_1	:	string := "weight_0";
		static_weight_2	:	string := "weight_0";
		static_weight_3	:	string := "weight_0";
		static_weight_4	:	string := "weight_0";
		static_weight_5	:	string := "weight_0";
		sum_wt_priority_0	:	natural := 0;
		sum_wt_priority_1	:	natural := 0;
		sum_wt_priority_2	:	natural := 0;
		sum_wt_priority_3	:	natural := 0;
		sum_wt_priority_4	:	natural := 0;
		sum_wt_priority_5	:	natural := 0;
		sum_wt_priority_6	:	natural := 0;
		sum_wt_priority_7	:	natural := 0;
		sync_mode_0	:	string := "asynchronous";
		sync_mode_1	:	string := "asynchronous";
		sync_mode_2	:	string := "asynchronous";
		sync_mode_3	:	string := "asynchronous";
		sync_mode_4	:	string := "asynchronous";
		sync_mode_5	:	string := "asynchronous";
		test_mode	:	string := "normal_mode";
		thld_jar1_0	:	string := "threshold_32";
		thld_jar1_1	:	string := "threshold_32";
		thld_jar1_2	:	string := "threshold_32";
		thld_jar1_3	:	string := "threshold_32";
		thld_jar1_4	:	string := "threshold_32";
		thld_jar1_5	:	string := "threshold_32";
		thld_jar2_0	:	string := "threshold_16";
		thld_jar2_1	:	string := "threshold_16";
		thld_jar2_2	:	string := "threshold_16";
		thld_jar2_3	:	string := "threshold_16";
		thld_jar2_4	:	string := "threshold_16";
		thld_jar2_5	:	string := "threshold_16";
		use_almost_empty_0	:	string := "empty";
		use_almost_empty_1	:	string := "empty";
		use_almost_empty_2	:	string := "empty";
		use_almost_empty_3	:	string := "empty";
		user_ecc_en	:	string := "disable";
		user_priority_0	:	string := "priority_0";
		user_priority_1	:	string := "priority_0";
		user_priority_2	:	string := "priority_0";
		user_priority_3	:	string := "priority_0";
		user_priority_4	:	string := "priority_0";
		user_priority_5	:	string := "priority_0";
		wfifo0_cport_map	:	string := "cmd_port_0";
		wfifo0_rdy_almost_full	:	string := "not_full";
		wfifo1_cport_map	:	string := "cmd_port_0";
		wfifo1_rdy_almost_full	:	string := "not_full";
		wfifo2_cport_map	:	string := "cmd_port_0";
		wfifo2_rdy_almost_full	:	string := "not_full";
		wfifo3_cport_map	:	string := "cmd_port_0";
		wfifo3_rdy_almost_full	:	string := "not_full";
		wr_dwidth_0	:	string := "dwidth_0";
		wr_dwidth_1	:	string := "dwidth_0";
		wr_dwidth_2	:	string := "dwidth_0";
		wr_dwidth_3	:	string := "dwidth_0";
		wr_dwidth_4	:	string := "dwidth_0";
		wr_dwidth_5	:	string := "dwidth_0";
		wr_fifo_in_use_0	:	string := "false";
		wr_fifo_in_use_1	:	string := "false";
		wr_fifo_in_use_2	:	string := "false";
		wr_fifo_in_use_3	:	string := "false";
		wr_port_info_0	:	string := "use_no";
		wr_port_info_1	:	string := "use_no";
		wr_port_info_2	:	string := "use_no";
		wr_port_info_3	:	string := "use_no";
		wr_port_info_4	:	string := "use_no";
		wr_port_info_5	:	string := "use_no";
		write_odt_chip	:	string := "odt_disabled"	);
	port(
		afiaddr	:	out std_logic_vector(19 downto 0);
		afiba	:	out std_logic_vector(2 downto 0);
		aficasn	:	out std_logic;
		aficke	:	out std_logic_vector(1 downto 0);
		aficsn	:	out std_logic_vector(1 downto 0);
		afictllongidle	:	out std_logic_vector(1 downto 0);
		afictlrefreshdone	:	out std_logic_vector(1 downto 0);
		afidm	:	out std_logic_vector(9 downto 0);
		afidqsburst	:	out std_logic_vector(4 downto 0);
		afiodt	:	out std_logic_vector(1 downto 0);
		afirasn	:	out std_logic;
		afirdata	:	in std_logic_vector(79 downto 0) := (others => '0');
		afirdataen	:	out std_logic_vector(4 downto 0);
		afirdataenfull	:	out std_logic_vector(4 downto 0);
		afirdatavalid	:	in std_logic := '0';
		afirstn	:	out std_logic;
		afiseqbusy	:	in std_logic_vector(1 downto 0) := (others => '0');
		afiwdata	:	out std_logic_vector(79 downto 0);
		afiwdatavalid	:	out std_logic_vector(4 downto 0);
		afiwen	:	out std_logic;
		afiwlat	:	in std_logic_vector(3 downto 0) := (others => '0');
		bondingin1	:	in std_logic_vector(3 downto 0) := (others => '0');
		bondingin2	:	in std_logic_vector(5 downto 0) := (others => '0');
		bondingin3	:	in std_logic_vector(5 downto 0) := (others => '0');
		bondingout1	:	out std_logic_vector(3 downto 0);
		bondingout2	:	out std_logic_vector(5 downto 0);
		bondingout3	:	out std_logic_vector(5 downto 0);
		cfgaddlat	:	out std_logic_vector(4 downto 0);
		cfgbankaddrwidth	:	out std_logic_vector(2 downto 0);
		cfgcaswrlat	:	out std_logic_vector(3 downto 0);
		cfgcoladdrwidth	:	out std_logic_vector(4 downto 0);
		cfgcsaddrwidth	:	out std_logic_vector(2 downto 0);
		cfgdevicewidth	:	out std_logic_vector(3 downto 0);
		cfginterfacewidth	:	out std_logic_vector(7 downto 0);
		cfgrowaddrwidth	:	out std_logic_vector(4 downto 0);
		cfgtcl	:	out std_logic_vector(4 downto 0);
		cfgtmrd	:	out std_logic_vector(3 downto 0);
		cfgtrefi	:	out std_logic_vector(12 downto 0);
		cfgtrfc	:	out std_logic_vector(7 downto 0);
		cfgtwr	:	out std_logic_vector(3 downto 0);
		csrclk	:	in std_logic := '0';
		csrdin	:	in std_logic := '0';
		csrdout	:	out std_logic;
		csren	:	in std_logic := '0';
		ctlcalbytelaneseln	:	out std_logic_vector(4 downto 0);
		ctlcalfail	:	in std_logic := '0';
		ctlcalreq	:	out std_logic;
		ctlcalsuccess	:	in std_logic := '0';
		ctlclk	:	in std_logic := '0';
		ctlinitreq	:	out std_logic;
		ctlmemclkdisable	:	out std_logic_vector(1 downto 0);
		ctlresetn	:	in std_logic := '0';
		dramconfig	:	out std_logic_vector(20 downto 0);
		globalresetn	:	in std_logic := '0';
		iavstcmddata0	:	in std_logic_vector(41 downto 0) := (others => '0');
		iavstcmddata1	:	in std_logic_vector(41 downto 0) := (others => '0');
		iavstcmddata2	:	in std_logic_vector(41 downto 0) := (others => '0');
		iavstcmddata3	:	in std_logic_vector(41 downto 0) := (others => '0');
		iavstcmddata4	:	in std_logic_vector(41 downto 0) := (others => '0');
		iavstcmddata5	:	in std_logic_vector(41 downto 0) := (others => '0');
		iavstcmdresetn0	:	in std_logic := '0';
		iavstcmdresetn1	:	in std_logic := '0';
		iavstcmdresetn2	:	in std_logic := '0';
		iavstcmdresetn3	:	in std_logic := '0';
		iavstcmdresetn4	:	in std_logic := '0';
		iavstcmdresetn5	:	in std_logic := '0';
		iavstrdclk0	:	in std_logic := '0';
		iavstrdclk1	:	in std_logic := '0';
		iavstrdclk2	:	in std_logic := '0';
		iavstrdclk3	:	in std_logic := '0';
		iavstrdready0	:	in std_logic := '0';
		iavstrdready1	:	in std_logic := '0';
		iavstrdready2	:	in std_logic := '0';
		iavstrdready3	:	in std_logic := '0';
		iavstrdresetn0	:	in std_logic := '0';
		iavstrdresetn1	:	in std_logic := '0';
		iavstrdresetn2	:	in std_logic := '0';
		iavstrdresetn3	:	in std_logic := '0';
		iavstwrackready0	:	in std_logic := '0';
		iavstwrackready1	:	in std_logic := '0';
		iavstwrackready2	:	in std_logic := '0';
		iavstwrackready3	:	in std_logic := '0';
		iavstwrackready4	:	in std_logic := '0';
		iavstwrackready5	:	in std_logic := '0';
		iavstwrclk0	:	in std_logic := '0';
		iavstwrclk1	:	in std_logic := '0';
		iavstwrclk2	:	in std_logic := '0';
		iavstwrclk3	:	in std_logic := '0';
		iavstwrdata0	:	in std_logic_vector(89 downto 0) := (others => '0');
		iavstwrdata1	:	in std_logic_vector(89 downto 0) := (others => '0');
		iavstwrdata2	:	in std_logic_vector(89 downto 0) := (others => '0');
		iavstwrdata3	:	in std_logic_vector(89 downto 0) := (others => '0');
		iavstwrresetn0	:	in std_logic := '0';
		iavstwrresetn1	:	in std_logic := '0';
		iavstwrresetn2	:	in std_logic := '0';
		iavstwrresetn3	:	in std_logic := '0';
		localdeeppowerdnack	:	out std_logic;
		localdeeppowerdnchip	:	in std_logic_vector(1 downto 0) := (others => '0');
		localdeeppowerdnreq	:	in std_logic := '0';
		localinitdone	:	out std_logic;
		localpowerdownack	:	out std_logic;
		localrefreshack	:	out std_logic;
		localrefreshchip	:	in std_logic_vector(1 downto 0) := (others => '0');
		localrefreshreq	:	in std_logic := '0';
		localselfrfshack	:	out std_logic;
		localselfrfshchip	:	in std_logic_vector(1 downto 0) := (others => '0');
		localselfrfshreq	:	in std_logic := '0';
		localstsctlempty	:	out std_logic;
		mmraddr	:	in std_logic_vector(9 downto 0) := (others => '0');
		mmrbe	:	in std_logic := '0';
		mmrburstbegin	:	in std_logic := '0';
		mmrburstcount	:	in std_logic_vector(1 downto 0) := (others => '0');
		mmrclk	:	in std_logic := '0';
		mmrrdata	:	out std_logic_vector(7 downto 0);
		mmrrdatavalid	:	out std_logic;
		mmrreadreq	:	in std_logic := '0';
		mmrresetn	:	in std_logic := '0';
		mmrwaitrequest	:	out std_logic;
		mmrwdata	:	in std_logic_vector(7 downto 0) := (others => '0');
		mmrwritereq	:	in std_logic := '0';
		oammready0	:	out std_logic;
		oammready1	:	out std_logic;
		oammready2	:	out std_logic;
		oammready3	:	out std_logic;
		oammready4	:	out std_logic;
		oammready5	:	out std_logic;
		ordavstdata0	:	out std_logic_vector(79 downto 0);
		ordavstdata1	:	out std_logic_vector(79 downto 0);
		ordavstdata2	:	out std_logic_vector(79 downto 0);
		ordavstdata3	:	out std_logic_vector(79 downto 0);
		ordavstvalid0	:	out std_logic;
		ordavstvalid1	:	out std_logic;
		ordavstvalid2	:	out std_logic;
		ordavstvalid3	:	out std_logic;
		owrackavstdata0	:	out std_logic;
		owrackavstdata1	:	out std_logic;
		owrackavstdata2	:	out std_logic;
		owrackavstdata3	:	out std_logic;
		owrackavstdata4	:	out std_logic;
		owrackavstdata5	:	out std_logic;
		owrackavstvalid0	:	out std_logic;
		owrackavstvalid1	:	out std_logic;
		owrackavstvalid2	:	out std_logic;
		owrackavstvalid3	:	out std_logic;
		owrackavstvalid4	:	out std_logic;
		owrackavstvalid5	:	out std_logic;
		portclk0	:	in std_logic := '0';
		portclk1	:	in std_logic := '0';
		portclk2	:	in std_logic := '0';
		portclk3	:	in std_logic := '0';
		portclk4	:	in std_logic := '0';
		portclk5	:	in std_logic := '0';
		scaddr	:	in std_logic_vector(9 downto 0) := (others => '0');
		scanenable	:	in std_logic := '0';
		scbe	:	in std_logic := '0';
		scburstbegin	:	in std_logic := '0';
		scburstcount	:	in std_logic_vector(1 downto 0) := (others => '0');
		scclk	:	in std_logic := '0';
		scrdata	:	out std_logic_vector(7 downto 0);
		scrdatavalid	:	out std_logic;
		screadreq	:	in std_logic := '0';
		scresetn	:	in std_logic := '0';
		scwaitrequest	:	out std_logic;
		scwdata	:	in std_logic_vector(7 downto 0) := (others => '0');
		scwritereq	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_ddio_out parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_ddio_out
	generic (
		async_mode	:	string := "none";
		half_rate_mode	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_ddio_out";
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
		hrbypass	:	in std_logic := '0';
		muxsel	:	in std_logic := '0';
		sreset	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_dma parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_dma
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_dma"	);
	port(
		channel0_req	:	in std_logic := '0';
		channel0_single	:	in std_logic := '0';
		channel0_xx_ack	:	out std_logic;
		channel1_req	:	in std_logic := '0';
		channel1_single	:	in std_logic := '0';
		channel1_xx_ack	:	out std_logic;
		channel2_req	:	in std_logic := '0';
		channel2_single	:	in std_logic := '0';
		channel2_xx_ack	:	out std_logic;
		channel3_req	:	in std_logic := '0';
		channel3_single	:	in std_logic := '0';
		channel3_xx_ack	:	out std_logic;
		channel4_req	:	in std_logic := '0';
		channel4_single	:	in std_logic := '0';
		channel4_xx_ack	:	out std_logic;
		channel5_req	:	in std_logic := '0';
		channel5_single	:	in std_logic := '0';
		channel5_xx_ack	:	out std_logic;
		channel6_req	:	in std_logic := '0';
		channel6_single	:	in std_logic := '0';
		channel6_xx_ack	:	out std_logic;
		channel7_req	:	in std_logic := '0';
		channel7_single	:	in std_logic := '0';
		channel7_xx_ack	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_ddio_in parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_ddio_in
	generic (
		async_mode	:	string := "none";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_ddio_in";
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
-- cyclonev_soc_interface_peripheral_qspi parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_peripheral_qspi
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_peripheral_qspi"	);
	port(
		adqin	:	in std_logic_vector(3 downto 0) := (others => '0');
		adqout	:	out std_logic_vector(3 downto 0);
		cs	:	out std_logic;
		sclkout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_ff parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_ff
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_ff";
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
-- cyclonev_dqs_delay_chain parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_dqs_delay_chain
	generic (
		dqs_ctrl_latches_enable	:	string := "false";
		dqs_input_frequency	:	string := "0";
		dqs_offsetctrl_enable	:	string := "false";
		dqs_phase_shift	:	natural := 0;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_dqs_delay_chain";
		phase_setting	:	natural := 0;
		sim_buffer_delay_increment	:	natural := 10;
		sim_buffer_intrinsic_delay	:	natural := 175;
		test_enable	:	string := "false";
		use_alternate_input_for_first_stage_delayctrl	:	string := "false";
		use_alternate_input_for_multi_stage_delayctrl	:	string := "false";
		use_phasectrlin	:	string := "false"	);
	port(
		delayctrlin	:	in std_logic_vector(6 downto 0) := (others => '0');
		dffin	:	out std_logic;
		dqsbusout	:	out std_logic;
		dqsenable	:	in std_logic := '1';
		dqsin	:	in std_logic := '0';
		dqsupdateen	:	in std_logic := '0';
		testin	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_peripheral_usb parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_peripheral_usb
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_peripheral_usb"	);
	port(
		clk	:	in std_logic := '0';
		data_out_en	:	out std_logic_vector(7 downto 0);
		datain	:	in std_logic_vector(7 downto 0) := (others => '0');
		dataout	:	out std_logic_vector(7 downto 0);
		dir	:	in std_logic := '0';
		nxt	:	in std_logic := '0';
		stp	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_peripheral_emac parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_peripheral_emac
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_peripheral_emac"	);
	port(
		clk_rx_i	:	in std_logic := '0';
		clk_tx_i	:	in std_logic := '0';
		gmii_mdc_o	:	out std_logic;
		gmii_mdi_i	:	in std_logic := '0';
		gmii_mdo_o	:	out std_logic;
		gmii_mdo_o_e	:	out std_logic;
		phy_col_i	:	in std_logic := '0';
		phy_crs_i	:	in std_logic := '0';
		phy_rxd_i	:	in std_logic_vector(7 downto 0) := (others => '0');
		phy_rxdv_i	:	in std_logic := '0';
		phy_rxer_i	:	in std_logic := '0';
		phy_txclk_o	:	out std_logic;
		phy_txd_o	:	out std_logic_vector(7 downto 0);
		phy_txen_o	:	out std_logic;
		phy_txer_o	:	out std_logic;
		ptp_aux_ts_trig_i	:	in std_logic := '0';
		ptp_pps_o	:	out std_logic;
		rst_clk_rx_n_o	:	out std_logic;
		rst_clk_tx_n_o	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_mem_phy parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_mem_phy
	generic (
		hphy_ac_ddr_disable	:	string := "true";
		hphy_atpg_en	:	string := "false";
		hphy_csr_pipelineglobalenable	:	string := "false";
		hphy_datapath_delay	:	string := "zero_cycles";
		hphy_hhp_hps	:	string := "false";
		hphy_reset_delay_en	:	string := "false";
		hphy_use_hphy	:	string := "true";
		hphy_wrap_back_en	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_mem_phy";
		m_hphy_ac_rom_content	:	std_logic_vector(1199 downto 0) := "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
		m_hphy_ac_rom_init_file	:	string := "UNUSED";
		m_hphy_inst_rom_content	:	std_logic_vector(2559 downto 0) := "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
		m_hphy_inst_rom_init_file	:	string := "UNUSED"	);
	port(
		afiaddr	:	in std_logic_vector(19 downto 0) := (others => '0');
		afiba	:	in std_logic_vector(2 downto 0) := (others => '0');
		aficalfail	:	out std_logic;
		aficalsuccess	:	out std_logic;
		aficasn	:	in std_logic := '0';
		aficke	:	in std_logic_vector(1 downto 0) := (others => '0');
		aficsn	:	in std_logic_vector(1 downto 0) := (others => '0');
		afidm	:	in std_logic_vector(9 downto 0) := (others => '0');
		afidqsburst	:	in std_logic_vector(4 downto 0) := (others => '0');
		afimemclkdisable	:	in std_logic := '0';
		afiodt	:	in std_logic_vector(1 downto 0) := (others => '0');
		afirasn	:	in std_logic := '0';
		afirdata	:	out std_logic_vector(79 downto 0);
		afirdataen	:	in std_logic_vector(4 downto 0) := (others => '0');
		afirdataenfull	:	in std_logic_vector(4 downto 0) := (others => '0');
		afirdatavalid	:	out std_logic;
		afirlat	:	out std_logic_vector(4 downto 0);
		afirstn	:	in std_logic := '0';
		afiwdata	:	in std_logic_vector(79 downto 0) := (others => '0');
		afiwdatavalid	:	in std_logic_vector(4 downto 0) := (others => '0');
		afiwen	:	in std_logic := '0';
		afiwlat	:	out std_logic_vector(3 downto 0);
		avladdress	:	in std_logic_vector(15 downto 0) := (others => '0');
		avlread	:	in std_logic := '0';
		avlreaddata	:	out std_logic_vector(31 downto 0);
		avlresetn	:	in std_logic := '0';
		avlwaitrequest	:	out std_logic;
		avlwrite	:	in std_logic := '0';
		avlwritedata	:	in std_logic_vector(31 downto 0) := (others => '0');
		cfgaddlat	:	in std_logic_vector(7 downto 0) := (others => '0');
		cfgbankaddrwidth	:	in std_logic_vector(7 downto 0) := (others => '0');
		cfgcaswrlat	:	in std_logic_vector(7 downto 0) := (others => '0');
		cfgcoladdrwidth	:	in std_logic_vector(7 downto 0) := (others => '0');
		cfgcsaddrwidth	:	in std_logic_vector(7 downto 0) := (others => '0');
		cfgdevicewidth	:	in std_logic_vector(7 downto 0) := (others => '0');
		cfgdramconfig	:	in std_logic_vector(23 downto 0) := (others => '0');
		cfginterfacewidth	:	in std_logic_vector(7 downto 0) := (others => '0');
		cfgrowaddrwidth	:	in std_logic_vector(7 downto 0) := (others => '0');
		cfgtcl	:	in std_logic_vector(7 downto 0) := (others => '0');
		cfgtmrd	:	in std_logic_vector(7 downto 0) := (others => '0');
		cfgtrefi	:	in std_logic_vector(15 downto 0) := (others => '0');
		cfgtrfc	:	in std_logic_vector(7 downto 0) := (others => '0');
		cfgtwr	:	in std_logic_vector(7 downto 0) := (others => '0');
		ctlresetn	:	out std_logic;
		ddiophydqdin	:	in std_logic_vector(179 downto 0) := (others => '0');
		ddiophydqslogicrdatavalid	:	in std_logic_vector(4 downto 0) := (others => '0');
		globalresetn	:	in std_logic := '0';
		iointaddrdout	:	in std_logic_vector(63 downto 0) := (others => '0');
		iointaficalfail	:	out std_logic;
		iointaficalsuccess	:	out std_logic;
		iointafirlat	:	out std_logic_vector(4 downto 0);
		iointafiwlat	:	out std_logic_vector(3 downto 0);
		iointbadout	:	in std_logic_vector(11 downto 0) := (others => '0');
		iointcasndout	:	in std_logic_vector(3 downto 0) := (others => '0');
		iointckdout	:	in std_logic_vector(3 downto 0) := (others => '0');
		iointckedout	:	in std_logic_vector(7 downto 0) := (others => '0');
		iointckndout	:	in std_logic_vector(3 downto 0) := (others => '0');
		iointcsndout	:	in std_logic_vector(7 downto 0) := (others => '0');
		iointdmdout	:	in std_logic_vector(19 downto 0) := (others => '0');
		iointdqdin	:	out std_logic_vector(179 downto 0);
		iointdqdout	:	in std_logic_vector(179 downto 0) := (others => '0');
		iointdqoe	:	in std_logic_vector(89 downto 0) := (others => '0');
		iointdqsbdout	:	in std_logic_vector(19 downto 0) := (others => '0');
		iointdqsboe	:	in std_logic_vector(9 downto 0) := (others => '0');
		iointdqsdout	:	in std_logic_vector(19 downto 0) := (others => '0');
		iointdqslogicdqsena	:	in std_logic_vector(9 downto 0) := (others => '0');
		iointdqslogicfiforeset	:	in std_logic_vector(4 downto 0) := (others => '0');
		iointdqslogicincrdataen	:	in std_logic_vector(9 downto 0) := (others => '0');
		iointdqslogicincwrptr	:	in std_logic_vector(9 downto 0) := (others => '0');
		iointdqslogicoct	:	in std_logic_vector(9 downto 0) := (others => '0');
		iointdqslogicrdatavalid	:	out std_logic_vector(4 downto 0);
		iointdqslogicreadlatency	:	in std_logic_vector(24 downto 0) := (others => '0');
		iointdqsoe	:	in std_logic_vector(9 downto 0) := (others => '0');
		iointodtdout	:	in std_logic_vector(7 downto 0) := (others => '0');
		iointrasndout	:	in std_logic_vector(3 downto 0) := (others => '0');
		iointresetndout	:	in std_logic_vector(3 downto 0) := (others => '0');
		iointwendout	:	in std_logic_vector(3 downto 0) := (others => '0');
		phyddioaddrdout	:	out std_logic_vector(63 downto 0);
		phyddiobadout	:	out std_logic_vector(11 downto 0);
		phyddiocasndout	:	out std_logic_vector(3 downto 0);
		phyddiockdout	:	out std_logic_vector(3 downto 0);
		phyddiockedout	:	out std_logic_vector(7 downto 0);
		phyddiockndout	:	out std_logic_vector(3 downto 0);
		phyddiocsndout	:	out std_logic_vector(7 downto 0);
		phyddiodmdout	:	out std_logic_vector(19 downto 0);
		phyddiodqdout	:	out std_logic_vector(179 downto 0);
		phyddiodqoe	:	out std_logic_vector(89 downto 0);
		phyddiodqsbdout	:	out std_logic_vector(19 downto 0);
		phyddiodqsboe	:	out std_logic_vector(9 downto 0);
		phyddiodqsdout	:	out std_logic_vector(19 downto 0);
		phyddiodqslogicaclrfifoctrl	:	out std_logic_vector(4 downto 0);
		phyddiodqslogicaclrpstamble	:	out std_logic_vector(4 downto 0);
		phyddiodqslogicdqsena	:	out std_logic_vector(9 downto 0);
		phyddiodqslogicfiforeset	:	out std_logic_vector(4 downto 0);
		phyddiodqslogicincrdataen	:	out std_logic_vector(9 downto 0);
		phyddiodqslogicincwrptr	:	out std_logic_vector(9 downto 0);
		phyddiodqslogicoct	:	out std_logic_vector(9 downto 0);
		phyddiodqslogicreadlatency	:	out std_logic_vector(24 downto 0);
		phyddiodqsoe	:	out std_logic_vector(9 downto 0);
		phyddioodtdout	:	out std_logic_vector(7 downto 0);
		phyddiorasndout	:	out std_logic_vector(3 downto 0);
		phyddioresetndout	:	out std_logic_vector(3 downto 0);
		phyddiowendout	:	out std_logic_vector(3 downto 0);
		phyresetn	:	out std_logic;
		plladdrcmdclk	:	in std_logic := '0';
		pllaficlk	:	in std_logic := '0';
		pllavlclk	:	in std_logic := '0';
		plllocked	:	in std_logic := '0';
		scanen	:	in std_logic := '0';
		softresetn	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_clkselect parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_clkselect
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_clkselect";
		test_cff	:	string := "low"	);
	port(
		clkselect	:	in std_logic_vector(1 downto 0) := (others => '0');
		inclk	:	in std_logic_vector(3 downto 0) := (others => '0');
		outclk	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_clocks_resets parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_clocks_resets
	generic (
		h2f_user0_clk_freq	:	natural := 100;
		h2f_user1_clk_freq	:	natural := 100;
		h2f_user2_clk_freq	:	natural := 100;
		lpm_type	:	string := "cyclonev_hps_interface_clocks_resets"	);
	port(
		f2h_cold_rst_req_n	:	in std_logic := '0';
		f2h_dbg_rst_req_n	:	in std_logic := '0';
		f2h_pending_rst_ack	:	in std_logic := '0';
		f2h_periph_ref_clk	:	in std_logic := '0';
		f2h_sdram_ref_clk	:	in std_logic := '0';
		f2h_warm_rst_req_n	:	in std_logic := '0';
		h2f_cold_rst_n	:	out std_logic;
		h2f_pending_rst_req_n	:	out std_logic;
		h2f_rst_n	:	out std_logic;
		h2f_user0_clk	:	out std_logic;
		h2f_user1_clk	:	out std_logic;
		h2f_user2_clk	:	out std_logic;
		ptp_ref_clk	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_ram_block parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_ram_block
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
		lpm_type	:	string := "cyclonev_ram_block";
		mem_init0	:	string;
		mem_init1	:	string;
		mem_init2	:	string;
		mem_init3	:	string;
		mem_init4	:	string;
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
-- cyclonev_soc_interface_peripheral_i2c parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_peripheral_i2c
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_peripheral_i2c"	);
	port(
		icclkina	:	in std_logic := '0';
		icclkoe	:	out std_logic;
		iccurrentsrcen	:	out std_logic;
		icdataina	:	in std_logic := '0';
		icdataoe	:	out std_logic;
		icen	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_ddio_oe parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_ddio_oe
	generic (
		async_mode	:	string := "none";
		disable_second_level_register	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_ddio_oe";
		power_up	:	string := "low";
		sync_mode	:	string := "none"	);
	port(
		areset	:	in std_logic := '0';
		clk	:	in std_logic := '0';
		dataout	:	out std_logic;
		dffhi	:	out std_logic;
		dfflo	:	out std_logic;
		ena	:	in std_logic := '1';
		octreadcontrol	:	in std_logic := '1';
		oe	:	in std_logic := '1';
		sreset	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_soc_interface_peripheral_emac parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_peripheral_emac
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_peripheral_emac"	);
	port(
		col	:	in std_logic := '0';
		gtxclk	:	out std_logic;
		rxclk	:	in std_logic := '0';
		rxcrs	:	in std_logic := '0';
		rxd	:	in std_logic_vector(7 downto 0) := (others => '0');
		rxdv	:	in std_logic := '0';
		rxer	:	in std_logic := '0';
		txd	:	out std_logic_vector(7 downto 0);
		txen	:	out std_logic;
		txer	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_soc_interface_s2f_interrupts parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_s2f_interrupts
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_s2f_interrupts"	);
	port(
		fakedin	:	in std_logic := '0';
		intrdma	:	out std_logic;
		intremac0	:	out std_logic_vector(4 downto 0);
		intremac1	:	out std_logic_vector(4 downto 0);
		intrgpio	:	out std_logic;
		intri2c	:	out std_logic_vector(1 downto 0);
		intrmcan	:	out std_logic_vector(3 downto 0);
		intrnand	:	out std_logic;
		intrnor	:	out std_logic;
		intrqspi	:	out std_logic;
		intrsdio	:	out std_logic;
		intrspi	:	out std_logic;
		intrtimer	:	out std_logic_vector(4 downto 0);
		intrusbotg	:	out std_logic_vector(1 downto 0);
		intrwatchdog	:	out std_logic_vector(1 downto 0)
	);
end component;

------------------------------------------------------------------
-- cyclonev_dqs_config parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_dqs_config
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_dqs_config"	);
	port(
		clk	:	in std_logic := '0';
		datain	:	in std_logic := '0';
		dataout	:	out std_logic;
		dqsbusoutdelaysetting	:	out std_logic_vector(4 downto 0);
		ena	:	in std_logic := '0';
		enadqsenablephasetransferreg	:	out std_logic;
		postamblephaseinvert	:	out std_logic;
		postamblephasesetting	:	out std_logic_vector(1 downto 0);
		update	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_bias_block parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_bias_block
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_bias_block"	);
	port(
		captnupdt	:	in std_logic := '0';
		clk	:	in std_logic := '0';
		din	:	in std_logic := '0';
		dout	:	out std_logic;
		shiftnld	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_soc_interface_trace_fpga parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_trace_fpga
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_trace_fpga"	);
	port(
		fpgatraceclk	:	in std_logic := '0';
		fpgatracedata	:	in std_logic_vector(31 downto 0) := (others => '0');
		fpgatraceready	:	out std_logic;
		fpgatracevalid	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_phy_clkbuf parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_phy_clkbuf
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_phy_clkbuf"	);
	port(
		inclk	:	in std_logic_vector(3 downto 0) := (others => '1');
		outclk	:	out std_logic_vector(3 downto 0)
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_jtag parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_jtag
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_jtag"	);
	port(
		fake_din	:	in std_logic := '0';
		nenab_jtag	:	out std_logic;
		ntrst	:	out std_logic;
		tck	:	out std_logic;
		tdi	:	out std_logic;
		tms	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_sdram_pll parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_sdram_pll
	generic (
		clk0_frequency	:	string := "0";
		clk0_phase_shift	:	string := "0";
		clk1_frequency	:	string := "0";
		clk1_phase_shift	:	string := "0";
		clk2_frequency	:	string := "0";
		clk2_phase_shift	:	string := "0";
		clk3_frequency	:	string := "0";
		clk3_phase_shift	:	string := "0";
		lpm_type	:	string := "cyclonev_hps_sdram_pll";
		ref_clk_frequency	:	string := "0"	);
	port(
		clk_out	:	out std_logic_vector(3 downto 0);
		ref_clk	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_peripheral_nand parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_peripheral_nand
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_peripheral_nand"	);
	port(
		adq_in	:	in std_logic_vector(7 downto 0) := (others => '0');
		adq_oe	:	out std_logic;
		adq_out	:	out std_logic_vector(7 downto 0);
		ale	:	out std_logic;
		cebar	:	out std_logic_vector(3 downto 0);
		cle	:	out std_logic;
		rdy_busy	:	in std_logic_vector(3 downto 0) := (others => '0');
		rebar	:	out std_logic;
		webar	:	out std_logic;
		wpbar	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_boot_from_fpga parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_boot_from_fpga
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_boot_from_fpga"	);
	port(
		boot_from_fpga_on_failure	:	in std_logic := '0';
		boot_from_fpga_ready	:	in std_logic := '0';
		bsel	:	in std_logic_vector(2 downto 0) := (others => '0');
		bsel_en	:	in std_logic := '0';
		csel	:	in std_logic_vector(1 downto 0) := (others => '0');
		csel_en	:	in std_logic := '0';
		fake_dout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_vfifo parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_vfifo
	generic (
		lpm_type	:	string := "cyclonev_vfifo"	);
	port(
		incwrptr	:	in std_logic := '0';
		qvldin	:	in std_logic := '0';
		qvldreg	:	out std_logic;
		rdclk	:	in std_logic := '0';
		rstn	:	in std_logic := '0';
		wrclk	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_s2f_clk_r_mux parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_s2f_clk_r_mux
	generic (
		lpm_type	:	string := "cyclonev_s2f_clk_r_mux"	);
	port(
		emac0_tx_clk_o	:	in std_logic := '0';
		emac1_tx_clk_o	:	in std_logic := '0';
		hps_tck	:	in std_logic := '0';
		qspi_sck_out	:	in std_logic := '0';
		s2f_clk_r	:	out std_logic_vector(8 downto 0);
		s2f_cold_rst_n	:	in std_logic := '0';
		s2f_right_clk0_sel0	:	in std_logic := '0';
		s2f_right_clk0_sel1	:	in std_logic := '0';
		s2f_right_clk1_sel0	:	in std_logic := '0';
		s2f_right_clk1_sel1	:	in std_logic := '0';
		s2f_right_clk2_sel0	:	in std_logic := '0';
		s2f_right_clk2_sel1	:	in std_logic := '0';
		s2f_right_clk3_sel0	:	in std_logic := '0';
		s2f_right_clk3_sel1	:	in std_logic := '0';
		s2f_right_clk4_sel0	:	in std_logic := '0';
		s2f_right_clk4_sel1	:	in std_logic := '0';
		s2f_right_clk5_sel0	:	in std_logic := '0';
		s2f_right_clk5_sel1	:	in std_logic := '0';
		s2f_right_clk6_sel0	:	in std_logic := '0';
		s2f_right_clk6_sel1	:	in std_logic := '0';
		s2f_right_clk7_sel0	:	in std_logic := '0';
		s2f_right_clk7_sel1	:	in std_logic := '0';
		s2f_right_clk8_sel0	:	in std_logic := '0';
		s2f_right_clk8_sel1	:	in std_logic := '0';
		s2f_rst_n	:	in std_logic := '0';
		s2f_user0_clk	:	in std_logic := '0';
		s2f_user1_clk	:	in std_logic := '0';
		s2f_user2_clk	:	in std_logic := '0';
		spim0_sclk_out	:	in std_logic := '0';
		spim1_sclk_out	:	in std_logic := '0';
		tpiu_trace_clk	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_soc_interface_peripheral_sdio parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_peripheral_sdio
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_peripheral_sdio"	);
	port(
		carddetectn	:	in std_logic := '0';
		cardpoweren	:	out std_logic;
		cardvolta	:	out std_logic_vector(3 downto 0);
		cardvoltb	:	out std_logic_vector(3 downto 0);
		cardwriteprt	:	in std_logic := '0';
		cclkout	:	out std_logic;
		ccmdin	:	in std_logic := '0';
		ccmdodpullupenn	:	out std_logic;
		ccmdout	:	out std_logic;
		ccmdouten	:	out std_logic;
		cdatain	:	in std_logic_vector(7 downto 0) := (others => '0');
		cdataout	:	out std_logic_vector(7 downto 0);
		cdataouten	:	out std_logic_vector(7 downto 0)
	);
end component;

------------------------------------------------------------------
-- cyclonev_s2f_clk_t_mux parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_s2f_clk_t_mux
	generic (
		lpm_type	:	string := "cyclonev_s2f_clk_t_mux"	);
	port(
		emac0_tx_clk_o	:	in std_logic := '0';
		emac1_tx_clk_o	:	in std_logic := '0';
		hps_tck	:	in std_logic := '0';
		qspi_sck_out	:	in std_logic := '0';
		s2f_clk_t	:	out std_logic_vector(8 downto 0);
		s2f_cold_rst_n	:	in std_logic := '0';
		s2f_rst_n	:	in std_logic := '0';
		s2f_top_clk0_sel0	:	in std_logic := '0';
		s2f_top_clk0_sel1	:	in std_logic := '0';
		s2f_top_clk1_sel0	:	in std_logic := '0';
		s2f_top_clk1_sel1	:	in std_logic := '0';
		s2f_top_clk2_sel0	:	in std_logic := '0';
		s2f_top_clk2_sel1	:	in std_logic := '0';
		s2f_top_clk3_sel0	:	in std_logic := '0';
		s2f_top_clk3_sel1	:	in std_logic := '0';
		s2f_top_clk4_sel0	:	in std_logic := '0';
		s2f_top_clk4_sel1	:	in std_logic := '0';
		s2f_top_clk5_sel0	:	in std_logic := '0';
		s2f_top_clk5_sel1	:	in std_logic := '0';
		s2f_top_clk6_sel0	:	in std_logic := '0';
		s2f_top_clk6_sel1	:	in std_logic := '0';
		s2f_top_clk7_sel0	:	in std_logic := '0';
		s2f_top_clk7_sel1	:	in std_logic := '0';
		s2f_top_clk8_sel0	:	in std_logic := '0';
		s2f_top_clk8_sel1	:	in std_logic := '0';
		s2f_user0_clk	:	in std_logic := '0';
		s2f_user1_clk	:	in std_logic := '0';
		s2f_user2_clk	:	in std_logic := '0';
		spim0_sclk_out	:	in std_logic := '0';
		spim1_sclk_out	:	in std_logic := '0';
		tpiu_trace_clk	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_lfifo parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_lfifo
	generic (
		lpm_type	:	string := "cyclonev_lfifo";
		oct_lfifo_enable	:	natural := -1	);
	port(
		clk	:	in std_logic := '0';
		octlfifo	:	out std_logic;
		rdataen	:	in std_logic := '0';
		rdataenfull	:	in std_logic := '0';
		rdatavalid	:	out std_logic;
		rden	:	out std_logic;
		rdlatency	:	in std_logic_vector(4 downto 0) := (others => '0');
		rstn	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_clkena parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_clkena
	generic (
		clock_type	:	string := "Auto";
		disable_mode	:	string := "low";
		ena_register_mode	:	string := "always enabled";
		ena_register_power_up	:	string := "high";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_clkena";
		test_syn	:	string := "high"	);
	port(
		ena	:	in std_logic := '1';
		enaout	:	out std_logic;
		inclk	:	in std_logic := '1';
		outclk	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_peripheral_spi_master parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_peripheral_spi_master
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_peripheral_spi_master"	);
	port(
		rxd	:	in std_logic := '0';
		sclk_out	:	out std_logic;
		ss_0_n	:	out std_logic;
		ss_1_n	:	out std_logic;
		ss_2_n	:	out std_logic;
		ss_3_n	:	out std_logic;
		ss_in_n	:	in std_logic := '0';
		ssi_oe_n	:	out std_logic;
		txd	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_soc_interface_soc_loaned_io parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_soc_loaned_io
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_soc_loaned_io"	);
	port(
		fakedout	:	out std_logic;
		loanf2s	:	in std_logic_vector(31 downto 0) := (others => '0');
		loans2f	:	out std_logic_vector(31 downto 0);
		loantri	:	in std_logic_vector(31 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_cross_trigger parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_cross_trigger
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_cross_trigger"	);
	port(
		asicctl	:	out std_logic_vector(7 downto 0);
		clk	:	in std_logic := '0';
		clk_en	:	in std_logic := '0';
		fake_dout	:	out std_logic;
		trig_in	:	in std_logic_vector(7 downto 0) := (others => '0');
		trig_inack	:	out std_logic_vector(7 downto 0);
		trig_out	:	out std_logic_vector(7 downto 0);
		trig_outack	:	in std_logic_vector(7 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_fpga2hps parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_fpga2hps
	generic (
		data_width	:	natural := 32;
		lpm_type	:	string := "cyclonev_hps_interface_fpga2hps"	);
	port(
		araddr	:	in std_logic_vector(31 downto 0) := (others => '0');
		arburst	:	in std_logic_vector(1 downto 0) := (others => '0');
		arcache	:	in std_logic_vector(3 downto 0) := (others => '0');
		arid	:	in std_logic_vector(7 downto 0) := (others => '0');
		arlen	:	in std_logic_vector(3 downto 0) := (others => '0');
		arlock	:	in std_logic_vector(1 downto 0) := (others => '0');
		arprot	:	in std_logic_vector(2 downto 0) := (others => '0');
		arready	:	out std_logic;
		arsize	:	in std_logic_vector(2 downto 0) := (others => '0');
		aruser	:	in std_logic_vector(4 downto 0) := (others => '0');
		arvalid	:	in std_logic := '0';
		awaddr	:	in std_logic_vector(31 downto 0) := (others => '0');
		awburst	:	in std_logic_vector(1 downto 0) := (others => '0');
		awcache	:	in std_logic_vector(3 downto 0) := (others => '0');
		awid	:	in std_logic_vector(7 downto 0) := (others => '0');
		awlen	:	in std_logic_vector(3 downto 0) := (others => '0');
		awlock	:	in std_logic_vector(1 downto 0) := (others => '0');
		awprot	:	in std_logic_vector(2 downto 0) := (others => '0');
		awready	:	out std_logic;
		awsize	:	in std_logic_vector(2 downto 0) := (others => '0');
		awuser	:	in std_logic_vector(4 downto 0) := (others => '0');
		awvalid	:	in std_logic := '0';
		bid	:	out std_logic_vector(7 downto 0);
		bready	:	in std_logic := '0';
		bresp	:	out std_logic_vector(1 downto 0);
		bvalid	:	out std_logic;
		clk	:	in std_logic := '0';
		port_size_config	:	in std_logic_vector(1 downto 0) := (others => '0');
		rdata	:	out std_logic_vector(127 downto 0);
		rid	:	out std_logic_vector(7 downto 0);
		rlast	:	out std_logic;
		rready	:	in std_logic := '0';
		rresp	:	out std_logic_vector(1 downto 0);
		rvalid	:	out std_logic;
		wdata	:	in std_logic_vector(127 downto 0) := (others => '0');
		wid	:	in std_logic_vector(7 downto 0) := (others => '0');
		wlast	:	in std_logic := '0';
		wready	:	out std_logic;
		wstrb	:	in std_logic_vector(15 downto 0) := (others => '0');
		wvalid	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_io_config parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_io_config
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_io_config"	);
	port(
		clk	:	in std_logic := '0';
		datain	:	in std_logic := '0';
		dataout	:	out std_logic;
		ena	:	in std_logic := '0';
		padtoinputregisterdelaysetting	:	out std_logic_vector(4 downto 0);
		update	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_loan_io parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_loan_io
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_loan_io"	);
	port(
		fake_dout	:	out std_logic;
		input_only	:	out std_logic_vector(13 downto 0);
		loanio_in	:	out std_logic_vector(70 downto 0);
		loanio_oe	:	in std_logic_vector(70 downto 0) := (others => '0');
		loanio_out	:	in std_logic_vector(70 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- cyclonev_soc_interface_soc2fpga parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_soc2fpga
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_soc2fpga"	);
	port(
		fpga2socportsizeconfig	:	in std_logic_vector(1 downto 0) := (others => '0');
		soc2fpgaaxiar	:	out std_logic_vector(31 downto 0);
		soc2fpgaaxiarburst	:	out std_logic_vector(1 downto 0);
		soc2fpgaaxiarcache	:	out std_logic_vector(3 downto 0);
		soc2fpgaaxiarid	:	out std_logic_vector(7 downto 0);
		soc2fpgaaxiarlen	:	out std_logic_vector(3 downto 0);
		soc2fpgaaxiarlock	:	out std_logic_vector(1 downto 0);
		soc2fpgaaxiarprot	:	out std_logic_vector(2 downto 0);
		soc2fpgaaxiarready	:	in std_logic := '0';
		soc2fpgaaxiarsize	:	out std_logic_vector(3 downto 0);
		soc2fpgaaxiarvalid	:	out std_logic;
		soc2fpgaaxiaw	:	out std_logic_vector(31 downto 0);
		soc2fpgaaxiawburst	:	out std_logic_vector(1 downto 0);
		soc2fpgaaxiawcache	:	out std_logic_vector(3 downto 0);
		soc2fpgaaxiawid	:	out std_logic_vector(7 downto 0);
		soc2fpgaaxiawlen	:	out std_logic_vector(3 downto 0);
		soc2fpgaaxiawlock	:	out std_logic_vector(1 downto 0);
		soc2fpgaaxiawprot	:	out std_logic_vector(2 downto 0);
		soc2fpgaaxiawready	:	in std_logic := '0';
		soc2fpgaaxiawsize	:	out std_logic_vector(3 downto 0);
		soc2fpgaaxiawvalid	:	out std_logic;
		soc2fpgaaxiclk	:	in std_logic := '0';
		soc2fpgaaxirdata	:	in std_logic_vector(127 downto 0) := (others => '0');
		soc2fpgaaxirid	:	in std_logic_vector(7 downto 0) := (others => '0');
		soc2fpgaaxirlast	:	in std_logic := '0';
		soc2fpgaaxirready	:	out std_logic;
		soc2fpgaaxirresp	:	in std_logic_vector(1 downto 0) := (others => '0');
		soc2fpgaaxirvalid	:	in std_logic := '0';
		soc2fpgabid	:	in std_logic_vector(7 downto 0) := (others => '0');
		soc2fpgabready	:	out std_logic;
		soc2fpgabresp	:	in std_logic_vector(1 downto 0) := (others => '0');
		soc2fpgabvalid	:	in std_logic := '0';
		soc2fpgawdata	:	out std_logic_vector(127 downto 0);
		soc2fpgawid	:	out std_logic_vector(7 downto 0);
		soc2fpgawidth	:	in std_logic_vector(1 downto 0) := (others => '0');
		soc2fpgawlast	:	out std_logic;
		soc2fpgawready	:	in std_logic := '0';
		soc2fpgawstrb	:	out std_logic_vector(15 downto 0);
		soc2fpgawvalid	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_peripheral_sdmmc parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_peripheral_sdmmc
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_peripheral_sdmmc"	);
	port(
		card_intn_i	:	in std_logic := '0';
		cclk_out	:	out std_logic;
		cdn_i	:	in std_logic := '0';
		clk_in	:	in std_logic := '0';
		cmd_en	:	out std_logic;
		cmd_i	:	in std_logic := '0';
		cmd_o	:	out std_logic;
		data_en	:	out std_logic_vector(7 downto 0);
		data_i	:	in std_logic_vector(7 downto 0) := (others => '0');
		data_o	:	out std_logic_vector(7 downto 0);
		pwr_ena_o	:	out std_logic;
		rstn_o	:	out std_logic;
		vs_o	:	out std_logic;
		wp_i	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_asmiblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_asmiblock
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_asmiblock"	);
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
-- cyclonev_ir_fifo_userdes parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_ir_fifo_userdes
	generic (
		a_enable_soft_cdr	:	string := "false";
		a_rb_bslipcfg	:	natural := 1;
		a_rb_bypass_serializer	:	string := "false";
		a_rb_data_width	:	natural := 10;
		a_rb_fifo_mode	:	string := "hrate_mode";
		a_rb_tx_outclk	:	string := "false";
		a_sim_readenable_pre_delay	:	natural := 0;
		a_sim_wclk_pre_delay	:	natural := 0;
		a_use_dynamic_fifo_mode	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_ir_fifo_userdes"	);
	port(
		bslipctl	:	in std_logic := '0';
		bslipin	:	in std_logic := '0';
		bslipmax	:	out std_logic;
		bslipout	:	out std_logic;
		dinfiforx	:	in std_logic_vector(1 downto 0) := (others => '0');
		dout	:	out std_logic_vector(3 downto 0);
		dynfifomode	:	in std_logic_vector(2 downto 0) := (others => '0');
		loaden	:	in std_logic := '0';
		lvdsmodeen	:	out std_logic;
		lvdstxsel	:	out std_logic;
		observablefout1	:	out std_logic;
		observablefout2	:	out std_logic;
		observablefout3	:	out std_logic;
		observablefout4	:	out std_logic;
		observableout	:	out std_logic_vector(3 downto 0);
		observablewaddrcnt	:	out std_logic;
		readclk	:	in std_logic := '0';
		readenable	:	in std_logic := '0';
		regscan	:	in std_logic := '0';
		regscanovrd	:	in std_logic := '0';
		rstn	:	in std_logic := '0';
		rxout	:	out std_logic_vector(9 downto 0);
		scanin	:	in std_logic := '0';
		scanout	:	out std_logic;
		tstclk	:	in std_logic := '0';
		txin	:	in std_logic_vector(9 downto 0) := (others => '0');
		txout	:	out std_logic;
		writeclk	:	in std_logic := '0';
		writeenable	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_pll_aux parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_pll_aux
	generic (
		lpm_type	:	string := "cyclonev_pll_aux";
		pl_aux_atb_atben0_precomp	:	std_logic_vector(0 downto 0) := "1";
		pl_aux_atb_atben1_precomp	:	std_logic_vector(0 downto 0) := "1";
		pl_aux_atb_comp_minus	:	std_logic_vector(0 downto 0) := "0";
		pl_aux_atb_comp_plus	:	std_logic_vector(0 downto 0) := "0";
		pl_aux_comp_pwr_dn	:	std_logic_vector(0 downto 0) := "1"	);
	port(
		atb0out	:	in std_logic := '0';
		atb1out	:	in std_logic := '0';
		atbcompout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_oscillator parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_oscillator
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_oscillator"	);
	port(
		clkout	:	out std_logic;
		clkout1	:	out std_logic;
		oscena	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_channel_pll parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_channel_pll
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
		enable_gpon_detection	:	string := "false";
		enabled_for_reconfig	:	string := "false";
		fast_lock_mode	:	string := "true";
		fb_sel	:	string := "vcoclk";
		hs_levshift_power_supply_setting	:	natural := 1;
		ignore_phslock	:	string := "false";
		l_counter_pd_clock_disable	:	string := "false";
		lpm_type	:	string := "cyclonev_channel_pll";
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
		replica_bias_ctrl	:	string := "true";
		reverse_serial_lpbk	:	string := "false";
		ripple_cap_ctrl	:	string := "none";
		rxpll_pd_bw_ctrl	:	natural := 0;
		rxpll_pfd_bw_ctrl	:	natural := 0;
		txpll_hclk_driver_enable	:	string := "false";
		use_default_base_address	:	string := "true";
		user_base_address	:	natural := 0;
		vco_overange_ref	:	string := "ref_2";
		vco_range_ctrl_en	:	string := "true"	);
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
		clk270bdes	:	out std_logic;
		clk90bdes	:	out std_logic;
		clkcdr	:	out std_logic;
		clkindeser	:	in std_logic := '0';
		clklow	:	out std_logic;
		crurstb	:	in std_logic := '1';
		deven	:	out std_logic;
		dodd	:	out std_logic;
		earlyeios	:	in std_logic := '0';
		extclk	:	in std_logic := '0';
		fref	:	out std_logic;
		lpbkpreen	:	in std_logic := '0';
		ltd	:	in std_logic := '0';
		ltr	:	in std_logic := '0';
		occalen	:	in std_logic := '0';
		pciel	:	in std_logic := '0';
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
-- cyclonev_soc_interface_peripheral_uart parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_peripheral_uart
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_peripheral_uart"	);
	port(
		ctsn	:	in std_logic := '0';
		dcdn	:	in std_logic := '0';
		dsrn	:	in std_logic := '0';
		dtrn	:	out std_logic;
		outn0	:	out std_logic;
		outn1	:	out std_logic;
		rin	:	in std_logic := '0';
		rtsn	:	out std_logic;
		sin	:	in std_logic := '0';
		sout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_dftblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_dftblock
	generic (
		lpm_type	:	string := "cyclonev_dftblock"	);
	port(
		dftin	:	in std_logic_vector(5 downto 0) := (others => '0');
		dftout	:	out std_logic_vector(24 downto 0)
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_stm_event parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_stm_event
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_stm_event"	);
	port(
		fake_dout	:	out std_logic;
		stm_event	:	in std_logic_vector(27 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- cyclonev_controller parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_controller
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_controller"	);
end component;

------------------------------------------------------------------
-- cyclonev_soc_interface_peripheral_usb parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_peripheral_usb
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_peripheral_usb"	);
	port(
		devhirdrcvd	:	out std_logic_vector(3 downto 0);
		devhirdrcvdtgl	:	out std_logic;
		outmil1suspendn	:	out std_logic;
		outmisleepn	:	out std_logic;
		ulpidatain	:	in std_logic_vector(7 downto 0) := (others => '0');
		ulpidataout	:	out std_logic_vector(7 downto 0);
		ulpidir	:	in std_logic := '0';
		ulpinxt	:	in std_logic := '0';
		ulpistp	:	out std_logic;
		utmifsclk48	:	in std_logic := '0';
		utmifsrx	:	in std_logic_vector(7 downto 0) := (others => '0');
		utmifstx	:	out std_logic_vector(7 downto 0);
		utmifstxdm	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_hps2fpga parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_hps2fpga
	generic (
		data_width	:	natural := 32;
		lpm_type	:	string := "cyclonev_hps_interface_hps2fpga"	);
	port(
		araddr	:	out std_logic_vector(29 downto 0);
		arburst	:	out std_logic_vector(1 downto 0);
		arcache	:	out std_logic_vector(3 downto 0);
		arid	:	out std_logic_vector(11 downto 0);
		arlen	:	out std_logic_vector(3 downto 0);
		arlock	:	out std_logic_vector(1 downto 0);
		arprot	:	out std_logic_vector(2 downto 0);
		arready	:	in std_logic := '0';
		arsize	:	out std_logic_vector(2 downto 0);
		arvalid	:	out std_logic;
		awaddr	:	out std_logic_vector(29 downto 0);
		awburst	:	out std_logic_vector(1 downto 0);
		awcache	:	out std_logic_vector(3 downto 0);
		awid	:	out std_logic_vector(11 downto 0);
		awlen	:	out std_logic_vector(3 downto 0);
		awlock	:	out std_logic_vector(1 downto 0);
		awprot	:	out std_logic_vector(2 downto 0);
		awready	:	in std_logic := '0';
		awsize	:	out std_logic_vector(2 downto 0);
		awvalid	:	out std_logic;
		bid	:	in std_logic_vector(11 downto 0) := (others => '0');
		bready	:	out std_logic;
		bresp	:	in std_logic_vector(1 downto 0) := (others => '0');
		bvalid	:	in std_logic := '0';
		clk	:	in std_logic := '0';
		port_size_config	:	in std_logic_vector(1 downto 0) := (others => '0');
		rdata	:	in std_logic_vector(127 downto 0) := (others => '0');
		rid	:	in std_logic_vector(11 downto 0) := (others => '0');
		rlast	:	in std_logic := '0';
		rready	:	out std_logic;
		rresp	:	in std_logic_vector(1 downto 0) := (others => '0');
		rvalid	:	in std_logic := '0';
		wdata	:	out std_logic_vector(127 downto 0);
		wid	:	out std_logic_vector(11 downto 0);
		wlast	:	out std_logic;
		wready	:	in std_logic := '0';
		wstrb	:	out std_logic_vector(15 downto 0);
		wvalid	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_leveling_delay_chain parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_leveling_delay_chain
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_leveling_delay_chain";
		physical_clock_source	:	string := "auto";
		sim_buffer_delay_increment	:	natural := 10;
		sim_buffer_intrinsic_delay	:	natural := 175	);
	port(
		clkin	:	in std_logic := '0';
		clkout	:	out std_logic_vector(3 downto 0);
		delayctrlin	:	in std_logic_vector(6 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_interrupts parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_interrupts
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_interrupts"	);
	port(
		fake_dout	:	out std_logic;
		h2f_can0_irq	:	out std_logic;
		h2f_can1_irq	:	out std_logic;
		h2f_clkmgr_irq	:	out std_logic;
		h2f_cti_irq0_n	:	out std_logic;
		h2f_cti_irq1_n	:	out std_logic;
		h2f_dma_abort_irq	:	out std_logic;
		h2f_dma_irq0	:	out std_logic;
		h2f_dma_irq1	:	out std_logic;
		h2f_dma_irq2	:	out std_logic;
		h2f_dma_irq3	:	out std_logic;
		h2f_dma_irq4	:	out std_logic;
		h2f_dma_irq5	:	out std_logic;
		h2f_dma_irq6	:	out std_logic;
		h2f_dma_irq7	:	out std_logic;
		h2f_emac0_irq	:	out std_logic;
		h2f_emac1_irq	:	out std_logic;
		h2f_fpga_man_irq	:	out std_logic;
		h2f_gpio0_irq	:	out std_logic;
		h2f_gpio1_irq	:	out std_logic;
		h2f_gpio2_irq	:	out std_logic;
		h2f_i2c0_irq	:	out std_logic;
		h2f_i2c1_irq	:	out std_logic;
		h2f_i2c_emac0_irq	:	out std_logic;
		h2f_i2c_emac1_irq	:	out std_logic;
		h2f_l4sp0_irq	:	out std_logic;
		h2f_l4sp1_irq	:	out std_logic;
		h2f_mpuwakeup_irq	:	out std_logic;
		h2f_nand_irq	:	out std_logic;
		h2f_osc0_irq	:	out std_logic;
		h2f_osc1_irq	:	out std_logic;
		h2f_qspi_irq	:	out std_logic;
		h2f_sdmmc_irq	:	out std_logic;
		h2f_spi0_irq	:	out std_logic;
		h2f_spi1_irq	:	out std_logic;
		h2f_spi2_irq	:	out std_logic;
		h2f_spi3_irq	:	out std_logic;
		h2f_uart0_irq	:	out std_logic;
		h2f_uart1_irq	:	out std_logic;
		h2f_usb0_irq	:	out std_logic;
		h2f_usb1_irq	:	out std_logic;
		h2f_wdog0_irq	:	out std_logic;
		h2f_wdog1_irq	:	out std_logic;
		irq	:	in std_logic_vector(63 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- cyclonev_io_obuf parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_io_obuf
	generic (
		bus_hold	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_io_obuf";
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
-- cyclonev_soc_interface_f2s_interrupts parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_f2s_interrupts
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_f2s_interrupts"	);
	port(
		f2sintt	:	in std_logic_vector(63 downto 0) := (others => '0');
		fakedout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_soc_interface_fpga2soc parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_fpga2soc
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_fpga2soc"	);
	port(
		fpga2socarusers	:	in std_logic_vector(4 downto 0) := (others => '0');
		fpga2socawusers	:	in std_logic_vector(4 downto 0) := (others => '0');
		fpga2socaxiar	:	in std_logic_vector(31 downto 0) := (others => '0');
		fpga2socaxiarburst	:	in std_logic_vector(1 downto 0) := (others => '0');
		fpga2socaxiarcache	:	in std_logic_vector(3 downto 0) := (others => '0');
		fpga2socaxiarid	:	in std_logic_vector(7 downto 0) := (others => '0');
		fpga2socaxiarlen	:	in std_logic_vector(3 downto 0) := (others => '0');
		fpga2socaxiarlock	:	in std_logic_vector(1 downto 0) := (others => '0');
		fpga2socaxiarprot	:	in std_logic_vector(2 downto 0) := (others => '0');
		fpga2socaxiarready	:	out std_logic;
		fpga2socaxiarsize	:	in std_logic_vector(3 downto 0) := (others => '0');
		fpga2socaxiarvalid	:	in std_logic := '0';
		fpga2socaxiaw	:	in std_logic_vector(31 downto 0) := (others => '0');
		fpga2socaxiawburst	:	in std_logic_vector(1 downto 0) := (others => '0');
		fpga2socaxiawcache	:	in std_logic_vector(3 downto 0) := (others => '0');
		fpga2socaxiawid	:	in std_logic_vector(7 downto 0) := (others => '0');
		fpga2socaxiawlen	:	in std_logic_vector(3 downto 0) := (others => '0');
		fpga2socaxiawlock	:	in std_logic_vector(1 downto 0) := (others => '0');
		fpga2socaxiawprot	:	in std_logic_vector(2 downto 0) := (others => '0');
		fpga2socaxiawready	:	out std_logic;
		fpga2socaxiawsize	:	in std_logic_vector(3 downto 0) := (others => '0');
		fpga2socaxiawvalid	:	in std_logic := '0';
		fpga2socaxiclk	:	in std_logic := '0';
		fpga2socaxirdata	:	in std_logic_vector(127 downto 0) := (others => '0');
		fpga2socaxirid	:	in std_logic_vector(7 downto 0) := (others => '0');
		fpga2socaxirlast	:	in std_logic := '0';
		fpga2socaxirready	:	out std_logic;
		fpga2socaxirresp	:	in std_logic_vector(1 downto 0) := (others => '0');
		fpga2socaxirvalid	:	in std_logic := '0';
		fpga2socbid	:	in std_logic_vector(7 downto 0) := (others => '0');
		fpga2socbready	:	out std_logic;
		fpga2socbresp	:	in std_logic_vector(1 downto 0) := (others => '0');
		fpga2socbvalid	:	in std_logic := '0';
		fpga2soceventi	:	in std_logic := '0';
		fpga2socevento	:	out std_logic;
		fpga2socportsizeconfig	:	in std_logic_vector(1 downto 0) := (others => '0');
		fpga2socstandbywfe	:	out std_logic_vector(1 downto 0);
		fpga2socstandbywfi	:	out std_logic_vector(1 downto 0);
		fpga2socstandbywfi0	:	out std_logic;
		fpga2socwdata	:	out std_logic_vector(127 downto 0);
		fpga2socwid	:	out std_logic_vector(7 downto 0);
		fpga2socwlast	:	out std_logic;
		fpga2socwready	:	in std_logic := '0';
		fpga2socwstrb	:	out std_logic_vector(15 downto 0);
		fpga2socwvalid	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_crcblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_crcblock
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_crcblock";
		oscillator_divider	:	natural := 256	);
	port(
		clk	:	in std_logic := '0';
		crcerror	:	out std_logic;
		regout	:	out std_logic;
		shiftnld	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_opregblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_opregblock
	generic (
		lpm_type	:	string := "cyclonev_opregblock"	);
	port(
		clk	:	in std_logic := '0';
		regout	:	out std_logic;
		shiftnld	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_dll parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_dll
	generic (
		delay_chain_length	:	natural := 8;
		delayctrlout_mode	:	string := "normal";
		dual_phase_comparators	:	string := "true";
		input_frequency	:	string := "0";
		jitter_reduction	:	string := "false";
		lpm_hint	:	string := "unused";
		lpm_type	:	string := "cyclonev_dll";
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
		upndnin	:	in std_logic := '0';
		upndninclkena	:	in std_logic := '0';
		upndnout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_prblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_prblock
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_prblock"	);
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
-- cyclonev_soc_interface_peripheral_nand parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_peripheral_nand
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_peripheral_nand"	);
	port(
		ale	:	out std_logic;
		ce	:	out std_logic_vector(3 downto 0);
		cle	:	out std_logic;
		dqf2s	:	in std_logic_vector(15 downto 0) := (others => '0');
		dqs2f	:	out std_logic_vector(15 downto 0);
		dqsf2s	:	in std_logic := '0';
		dqss2f	:	out std_logic;
		dqstri	:	out std_logic;
		dqtri	:	out std_logic;
		f2sclk	:	in std_logic := '0';
		rb	:	in std_logic := '0';
		s2fclk	:	out std_logic;
		wp	:	out std_logic;
		writenread	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_mpu_general_purpose parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_mpu_general_purpose
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_mpu_general_purpose"	);
	port(
		fake_dout	:	out std_logic;
		gp_in	:	in std_logic_vector(31 downto 0) := (others => '0');
		gp_out	:	out std_logic_vector(31 downto 0)
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_peripheral_can parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_peripheral_can
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_peripheral_can"	);
	port(
		rxd	:	in std_logic := '0';
		txd	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_soc_interface_s2f_debug_apb parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_s2f_debug_apb
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_s2f_debug_apb"	);
	port(
		s2fpaddr	:	out std_logic_vector(9 downto 0);
		s2fpaddr31	:	out std_logic;
		s2fpclkdbg	:	in std_logic := '0';
		s2fpclkendbg	:	out std_logic;
		s2fpenabledbg	:	out std_logic;
		s2fprdata	:	in std_logic_vector(31 downto 0) := (others => '0');
		s2fpreadydbg	:	in std_logic := '0';
		s2fpseldbg	:	in std_logic := '0';
		s2fpwdata	:	out std_logic_vector(31 downto 0);
		s2fpwritedbg	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_tpiu_trace parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_tpiu_trace
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_tpiu_trace"	);
	port(
		trace_data	:	out std_logic_vector(31 downto 0);
		traceclk	:	out std_logic;
		traceclk_ctl	:	in std_logic := '0';
		traceclkin	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_io_pad parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_io_pad
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_io_pad"	);
	port(
		padin	:	in std_logic := '0';
		padout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_peripheral_qspi parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_peripheral_qspi
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_peripheral_qspi"	);
	port(
		mi0	:	in std_logic := '0';
		mi1	:	in std_logic := '0';
		mi2	:	in std_logic := '0';
		mi3	:	in std_logic := '0';
		mo0	:	out std_logic;
		mo1	:	out std_logic;
		mo2_wpn	:	out std_logic;
		mo3_hold	:	out std_logic;
		n_mo_en	:	out std_logic_vector(3 downto 0);
		n_ss_out	:	out std_logic_vector(3 downto 0);
		sclk_out	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_soc_interface_fpga2sdram parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_fpga2sdram
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_fpga2sdram"	);
	port(
		cfgaximmselect	:	in std_logic_vector(5 downto 0) := (others => '0');
		cfgcportrfifomap	:	in std_logic_vector(17 downto 0) := (others => '0');
		cfgcporttype	:	in std_logic_vector(11 downto 0) := (others => '0');
		cfgcportwfifomap	:	in std_logic_vector(17 downto 0) := (others => '0');
		cfgportwidth	:	in std_logic_vector(11 downto 0) := (others => '0');
		cfgrfifocportmap	:	in std_logic_vector(15 downto 0) := (others => '0');
		cfgwfifocportmap	:	in std_logic_vector(15 downto 0) := (others => '0');
		cmddata0	:	in std_logic_vector(59 downto 0) := (others => '0');
		cmddata1	:	in std_logic_vector(59 downto 0) := (others => '0');
		cmddata2	:	in std_logic_vector(59 downto 0) := (others => '0');
		cmddata3	:	in std_logic_vector(59 downto 0) := (others => '0');
		cmddata4	:	in std_logic_vector(59 downto 0) := (others => '0');
		cmddata5	:	in std_logic_vector(59 downto 0) := (others => '0');
		cmdportclk0	:	in std_logic := '0';
		cmdportclk1	:	in std_logic := '0';
		cmdportclk2	:	in std_logic := '0';
		cmdportclk3	:	in std_logic := '0';
		cmdportclk4	:	in std_logic := '0';
		cmdportclk5	:	in std_logic := '0';
		cmdready0	:	out std_logic;
		cmdready1	:	out std_logic;
		cmdready2	:	out std_logic;
		cmdready3	:	out std_logic;
		cmdready4	:	out std_logic;
		cmdready5	:	out std_logic;
		cmdvalid0	:	in std_logic := '0';
		cmdvalid1	:	in std_logic := '0';
		cmdvalid2	:	in std_logic := '0';
		cmdvalid3	:	in std_logic := '0';
		cmdvalid4	:	in std_logic := '0';
		cmdvalid5	:	in std_logic := '0';
		rdclk0	:	in std_logic := '0';
		rdclk1	:	in std_logic := '0';
		rdclk2	:	in std_logic := '0';
		rdclk3	:	in std_logic := '0';
		rddata0	:	out std_logic_vector(79 downto 0);
		rddata1	:	out std_logic_vector(79 downto 0);
		rddata2	:	out std_logic_vector(79 downto 0);
		rddata3	:	out std_logic_vector(79 downto 0);
		rdready0	:	in std_logic := '0';
		rdready1	:	in std_logic := '0';
		rdready2	:	in std_logic := '0';
		rdready3	:	in std_logic := '0';
		rdvalid0	:	out std_logic;
		rdvalid1	:	out std_logic;
		rdvalid2	:	out std_logic;
		rdvalid3	:	out std_logic;
		wrackdata0	:	out std_logic_vector(9 downto 0);
		wrackdata1	:	out std_logic_vector(9 downto 0);
		wrackdata2	:	out std_logic_vector(9 downto 0);
		wrackdata3	:	out std_logic_vector(9 downto 0);
		wrackdata4	:	out std_logic_vector(9 downto 0);
		wrackdata5	:	out std_logic_vector(9 downto 0);
		wrackready0	:	in std_logic := '0';
		wrackready1	:	in std_logic := '0';
		wrackready2	:	in std_logic := '0';
		wrackready3	:	in std_logic := '0';
		wrackready4	:	in std_logic := '0';
		wrackready5	:	in std_logic := '0';
		wrackvalid0	:	out std_logic;
		wrackvalid1	:	out std_logic;
		wrackvalid2	:	out std_logic;
		wrackvalid3	:	out std_logic;
		wrackvalid4	:	out std_logic;
		wrackvalid5	:	out std_logic;
		wrclk0	:	in std_logic := '0';
		wrclk1	:	in std_logic := '0';
		wrclk2	:	in std_logic := '0';
		wrclk3	:	in std_logic := '0';
		wrdata0	:	in std_logic_vector(89 downto 0) := (others => '0');
		wrdata1	:	in std_logic_vector(89 downto 0) := (others => '0');
		wrdata2	:	in std_logic_vector(89 downto 0) := (others => '0');
		wrdata3	:	in std_logic_vector(89 downto 0) := (others => '0');
		wrready0	:	out std_logic;
		wrready1	:	out std_logic;
		wrready2	:	out std_logic;
		wrready3	:	out std_logic;
		wrvalid0	:	in std_logic := '0';
		wrvalid1	:	in std_logic := '0';
		wrvalid2	:	in std_logic := '0';
		wrvalid3	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_clkburst parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_clkburst
	generic (
		burstcnt_ctrl	:	string := "static_setting";
		lpm_type	:	string := "cyclonev_clkburst";
		static_burstcnt	:	string := "cnt0"	);
	port(
		burstcnt	:	in std_logic_vector(2 downto 0) := (others => '0');
		ena	:	in std_logic := '0';
		enaout	:	out std_logic;
		inclk	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_soc_interface_gp parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_gp
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_gp"	);
	port(
		f2sgp	:	in std_logic_vector(31 downto 0) := (others => '0');
		fakedout	:	out std_logic;
		s2fgp	:	out std_logic_vector(31 downto 0)
	);
end component;

------------------------------------------------------------------
-- cyclonev_read_fifo_read_clock_select parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_read_fifo_read_clock_select
	generic (
		lpm_type	:	string := "cyclonev_read_fifo_read_clock_select"	);
	port(
		clkin	:	in std_logic_vector(2 downto 0) := (others => '0');
		clkout	:	out std_logic;
		clksel	:	in std_logic_vector(1 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- cyclonev_jtag parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_jtag
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_jtag"	);
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
-- cyclonev_rublock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_rublock
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_rublock";
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
-- cyclonev_soc_interface_f2s_debug_apb parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_f2s_debug_apb
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_f2s_debug_apb"	);
	port(
		f2spaddr	:	in std_logic_vector(9 downto 0) := (others => '0');
		f2spaddr31	:	in std_logic := '0';
		f2spclkdbg	:	in std_logic := '0';
		f2spclkendbg	:	in std_logic := '0';
		f2spenabledbg	:	in std_logic := '0';
		f2sprdata	:	out std_logic_vector(31 downto 0);
		f2spreadydbg	:	out std_logic;
		f2spseldbg	:	out std_logic;
		f2spwdata	:	in std_logic_vector(31 downto 0) := (others => '0');
		f2spwritedbg	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_soc_interface_dma parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_dma
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_dma"	);
	port(
		clk	:	in std_logic := '0';
		datype	:	out std_logic_vector(1 downto 0);
		davalid	:	out std_logic;
		drlast	:	in std_logic := '0';
		drready	:	in std_logic := '0';
		drtype	:	in std_logic_vector(1 downto 0) := (others => '0');
		drvalid	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_clk_phase_select parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_clk_phase_select
	generic (
		invert_phase	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_clk_phase_select";
		phase_setting	:	natural := 0;
		physical_clock_source	:	string := "auto";
		use_dqs_input	:	string := "false";
		use_phasectrlin	:	string := "true"	);
	port(
		clkin	:	in std_logic_vector(3 downto 0) := (others => '0');
		clkout	:	out std_logic;
		dqsin	:	in std_logic := '0';
		phasectrlin	:	in std_logic_vector(1 downto 0) := (others => '0');
		phaseinvertctrl	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_mpu_event_standby parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_mpu_event_standby
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_mpu_event_standby"	);
	port(
		eventi	:	in std_logic := '0';
		evento	:	out std_logic;
		standbywfe	:	out std_logic_vector(1 downto 0);
		standbywfi	:	out std_logic_vector(1 downto 0)
	);
end component;

------------------------------------------------------------------
-- cyclonev_hd_altpe2_hip_top parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hd_altpe2_hip_top
	generic (
		altpe2_hip_base_addr_1	:	std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
		altpe2_hip_base_addr_2	:	std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
		altpe2_hip_base_addr_3	:	std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
		altpe2_hip_base_addr_4	:	std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
		altpe2_hip_base_addr_5	:	std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
		altpe2_hip_base_addr_6	:	std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
		altpe2_hip_base_addr_user_1	:	std_logic_vector(9 downto 0) := "0000000000";
		altpe2_hip_base_addr_user_2	:	std_logic_vector(9 downto 0) := "0001000000";
		altpe2_hip_base_addr_user_3	:	std_logic_vector(9 downto 0) := "0010000000";
		altpe2_hip_base_addr_user_4	:	std_logic_vector(9 downto 0) := "0011000000";
		altpe2_hip_base_addr_user_5	:	std_logic_vector(9 downto 0) := "0100000000";
		altpe2_hip_base_addr_user_6	:	std_logic_vector(9 downto 0) := "0101000000";
		aspm_optionality_0	:	string := "true";
		aspm_optionality_1	:	string := "true";
		aspm_optionality_2	:	string := "true";
		aspm_optionality_3	:	string := "true";
		aspm_optionality_4	:	string := "true";
		aspm_optionality_5	:	string := "true";
		aspm_optionality_6	:	string := "true";
		aspm_optionality_7	:	string := "true";
		bar0_64bit_mem_space_0	:	string := "true";
		bar0_64bit_mem_space_1	:	string := "true";
		bar0_64bit_mem_space_2	:	string := "true";
		bar0_64bit_mem_space_3	:	string := "true";
		bar0_64bit_mem_space_4	:	string := "true";
		bar0_64bit_mem_space_5	:	string := "true";
		bar0_64bit_mem_space_6	:	string := "true";
		bar0_64bit_mem_space_7	:	string := "true";
		bar0_io_space_0	:	string := "false";
		bar0_io_space_1	:	string := "false";
		bar0_io_space_2	:	string := "false";
		bar0_io_space_3	:	string := "false";
		bar0_io_space_4	:	string := "false";
		bar0_io_space_5	:	string := "false";
		bar0_io_space_6	:	string := "false";
		bar0_io_space_7	:	string := "false";
		bar0_prefetchable_0	:	string := "true";
		bar0_prefetchable_1	:	string := "true";
		bar0_prefetchable_2	:	string := "true";
		bar0_prefetchable_3	:	string := "true";
		bar0_prefetchable_4	:	string := "true";
		bar0_prefetchable_5	:	string := "true";
		bar0_prefetchable_6	:	string := "true";
		bar0_prefetchable_7	:	string := "true";
		bar0_size_mask_0	:	string := "bar0_size_mask";
		bar0_size_mask_1	:	string := "bar0_size_mask";
		bar0_size_mask_2	:	string := "bar0_size_mask";
		bar0_size_mask_3	:	string := "bar0_size_mask";
		bar0_size_mask_4	:	string := "bar0_size_mask";
		bar0_size_mask_5	:	string := "bar0_size_mask";
		bar0_size_mask_6	:	string := "bar0_size_mask";
		bar0_size_mask_7	:	string := "bar0_size_mask";
		bar0_size_mask_data_0	:	std_logic_vector(27 downto 0) := "1111111111111111111111111111";
		bar0_size_mask_data_1	:	std_logic_vector(27 downto 0) := "1111111111111111111111111111";
		bar0_size_mask_data_2	:	std_logic_vector(27 downto 0) := "1111111111111111111111111111";
		bar0_size_mask_data_3	:	std_logic_vector(27 downto 0) := "1111111111111111111111111111";
		bar0_size_mask_data_4	:	std_logic_vector(27 downto 0) := "1111111111111111111111111111";
		bar0_size_mask_data_5	:	std_logic_vector(27 downto 0) := "1111111111111111111111111111";
		bar0_size_mask_data_6	:	std_logic_vector(27 downto 0) := "1111111111111111111111111111";
		bar0_size_mask_data_7	:	std_logic_vector(27 downto 0) := "1111111111111111111111111111";
		bar1_64bit_mem_space_0	:	string := "false";
		bar1_64bit_mem_space_1	:	string := "false";
		bar1_64bit_mem_space_2	:	string := "false";
		bar1_64bit_mem_space_3	:	string := "false";
		bar1_64bit_mem_space_4	:	string := "false";
		bar1_64bit_mem_space_5	:	string := "false";
		bar1_64bit_mem_space_6	:	string := "false";
		bar1_64bit_mem_space_7	:	string := "false";
		bar1_io_space_0	:	string := "false";
		bar1_io_space_1	:	string := "false";
		bar1_io_space_2	:	string := "false";
		bar1_io_space_3	:	string := "false";
		bar1_io_space_4	:	string := "false";
		bar1_io_space_5	:	string := "false";
		bar1_io_space_6	:	string := "false";
		bar1_io_space_7	:	string := "false";
		bar1_prefetchable_0	:	string := "false";
		bar1_prefetchable_1	:	string := "false";
		bar1_prefetchable_2	:	string := "false";
		bar1_prefetchable_3	:	string := "false";
		bar1_prefetchable_4	:	string := "false";
		bar1_prefetchable_5	:	string := "false";
		bar1_prefetchable_6	:	string := "false";
		bar1_prefetchable_7	:	string := "false";
		bar1_size_mask_0	:	string := "bar1_size_mask";
		bar1_size_mask_1	:	string := "bar1_size_mask";
		bar1_size_mask_2	:	string := "bar1_size_mask";
		bar1_size_mask_3	:	string := "bar1_size_mask";
		bar1_size_mask_4	:	string := "bar1_size_mask";
		bar1_size_mask_5	:	string := "bar1_size_mask";
		bar1_size_mask_6	:	string := "bar1_size_mask";
		bar1_size_mask_7	:	string := "bar1_size_mask";
		bar1_size_mask_data_0	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar1_size_mask_data_1	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar1_size_mask_data_2	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar1_size_mask_data_3	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar1_size_mask_data_4	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar1_size_mask_data_5	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar1_size_mask_data_6	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar1_size_mask_data_7	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar2_64bit_mem_space_0	:	string := "false";
		bar2_64bit_mem_space_1	:	string := "false";
		bar2_64bit_mem_space_2	:	string := "false";
		bar2_64bit_mem_space_3	:	string := "false";
		bar2_64bit_mem_space_4	:	string := "false";
		bar2_64bit_mem_space_5	:	string := "false";
		bar2_64bit_mem_space_6	:	string := "false";
		bar2_64bit_mem_space_7	:	string := "false";
		bar2_io_space_0	:	string := "false";
		bar2_io_space_1	:	string := "false";
		bar2_io_space_2	:	string := "false";
		bar2_io_space_3	:	string := "false";
		bar2_io_space_4	:	string := "false";
		bar2_io_space_5	:	string := "false";
		bar2_io_space_6	:	string := "false";
		bar2_io_space_7	:	string := "false";
		bar2_prefetchable_0	:	string := "false";
		bar2_prefetchable_1	:	string := "false";
		bar2_prefetchable_2	:	string := "false";
		bar2_prefetchable_3	:	string := "false";
		bar2_prefetchable_4	:	string := "false";
		bar2_prefetchable_5	:	string := "false";
		bar2_prefetchable_6	:	string := "false";
		bar2_prefetchable_7	:	string := "false";
		bar2_size_mask_0	:	string := "bar2_size_mask";
		bar2_size_mask_1	:	string := "bar2_size_mask";
		bar2_size_mask_2	:	string := "bar2_size_mask";
		bar2_size_mask_3	:	string := "bar2_size_mask";
		bar2_size_mask_4	:	string := "bar2_size_mask";
		bar2_size_mask_5	:	string := "bar2_size_mask";
		bar2_size_mask_6	:	string := "bar2_size_mask";
		bar2_size_mask_7	:	string := "bar2_size_mask";
		bar2_size_mask_data_0	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar2_size_mask_data_1	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar2_size_mask_data_2	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar2_size_mask_data_3	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar2_size_mask_data_4	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar2_size_mask_data_5	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar2_size_mask_data_6	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar2_size_mask_data_7	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar3_64bit_mem_space_0	:	string := "false";
		bar3_64bit_mem_space_1	:	string := "false";
		bar3_64bit_mem_space_2	:	string := "false";
		bar3_64bit_mem_space_3	:	string := "false";
		bar3_64bit_mem_space_4	:	string := "false";
		bar3_64bit_mem_space_5	:	string := "false";
		bar3_64bit_mem_space_6	:	string := "false";
		bar3_64bit_mem_space_7	:	string := "false";
		bar3_io_space_0	:	string := "false";
		bar3_io_space_1	:	string := "false";
		bar3_io_space_2	:	string := "false";
		bar3_io_space_3	:	string := "false";
		bar3_io_space_4	:	string := "false";
		bar3_io_space_5	:	string := "false";
		bar3_io_space_6	:	string := "false";
		bar3_io_space_7	:	string := "false";
		bar3_prefetchable_0	:	string := "false";
		bar3_prefetchable_1	:	string := "false";
		bar3_prefetchable_2	:	string := "false";
		bar3_prefetchable_3	:	string := "false";
		bar3_prefetchable_4	:	string := "false";
		bar3_prefetchable_5	:	string := "false";
		bar3_prefetchable_6	:	string := "false";
		bar3_prefetchable_7	:	string := "false";
		bar3_size_mask_0	:	string := "bar3_size_mask";
		bar3_size_mask_1	:	string := "bar3_size_mask";
		bar3_size_mask_2	:	string := "bar3_size_mask";
		bar3_size_mask_3	:	string := "bar3_size_mask";
		bar3_size_mask_4	:	string := "bar3_size_mask";
		bar3_size_mask_5	:	string := "bar3_size_mask";
		bar3_size_mask_6	:	string := "bar3_size_mask";
		bar3_size_mask_7	:	string := "bar3_size_mask";
		bar3_size_mask_data_0	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar3_size_mask_data_1	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar3_size_mask_data_2	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar3_size_mask_data_3	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar3_size_mask_data_4	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar3_size_mask_data_5	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar3_size_mask_data_6	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar3_size_mask_data_7	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar4_64bit_mem_space_0	:	string := "false";
		bar4_64bit_mem_space_1	:	string := "false";
		bar4_64bit_mem_space_2	:	string := "false";
		bar4_64bit_mem_space_3	:	string := "false";
		bar4_64bit_mem_space_4	:	string := "false";
		bar4_64bit_mem_space_5	:	string := "false";
		bar4_64bit_mem_space_6	:	string := "false";
		bar4_64bit_mem_space_7	:	string := "false";
		bar4_io_space_0	:	string := "false";
		bar4_io_space_1	:	string := "false";
		bar4_io_space_2	:	string := "false";
		bar4_io_space_3	:	string := "false";
		bar4_io_space_4	:	string := "false";
		bar4_io_space_5	:	string := "false";
		bar4_io_space_6	:	string := "false";
		bar4_io_space_7	:	string := "false";
		bar4_prefetchable_0	:	string := "false";
		bar4_prefetchable_1	:	string := "false";
		bar4_prefetchable_2	:	string := "false";
		bar4_prefetchable_3	:	string := "false";
		bar4_prefetchable_4	:	string := "false";
		bar4_prefetchable_5	:	string := "false";
		bar4_prefetchable_6	:	string := "false";
		bar4_prefetchable_7	:	string := "false";
		bar4_size_mask_0	:	string := "bar4_size_mask";
		bar4_size_mask_1	:	string := "bar4_size_mask";
		bar4_size_mask_2	:	string := "bar4_size_mask";
		bar4_size_mask_3	:	string := "bar4_size_mask";
		bar4_size_mask_4	:	string := "bar4_size_mask";
		bar4_size_mask_5	:	string := "bar4_size_mask";
		bar4_size_mask_6	:	string := "bar4_size_mask";
		bar4_size_mask_7	:	string := "bar4_size_mask";
		bar4_size_mask_data_0	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar4_size_mask_data_1	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar4_size_mask_data_2	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar4_size_mask_data_3	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar4_size_mask_data_4	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar4_size_mask_data_5	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar4_size_mask_data_6	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar4_size_mask_data_7	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar5_64bit_mem_space_0	:	string := "false";
		bar5_64bit_mem_space_1	:	string := "false";
		bar5_64bit_mem_space_2	:	string := "false";
		bar5_64bit_mem_space_3	:	string := "false";
		bar5_64bit_mem_space_4	:	string := "false";
		bar5_64bit_mem_space_5	:	string := "false";
		bar5_64bit_mem_space_6	:	string := "false";
		bar5_64bit_mem_space_7	:	string := "false";
		bar5_io_space_0	:	string := "false";
		bar5_io_space_1	:	string := "false";
		bar5_io_space_2	:	string := "false";
		bar5_io_space_3	:	string := "false";
		bar5_io_space_4	:	string := "false";
		bar5_io_space_5	:	string := "false";
		bar5_io_space_6	:	string := "false";
		bar5_io_space_7	:	string := "false";
		bar5_prefetchable_0	:	string := "false";
		bar5_prefetchable_1	:	string := "false";
		bar5_prefetchable_2	:	string := "false";
		bar5_prefetchable_3	:	string := "false";
		bar5_prefetchable_4	:	string := "false";
		bar5_prefetchable_5	:	string := "false";
		bar5_prefetchable_6	:	string := "false";
		bar5_prefetchable_7	:	string := "false";
		bar5_size_mask_0	:	string := "bar5_size_mask";
		bar5_size_mask_1	:	string := "bar5_size_mask";
		bar5_size_mask_2	:	string := "bar5_size_mask";
		bar5_size_mask_3	:	string := "bar5_size_mask";
		bar5_size_mask_4	:	string := "bar5_size_mask";
		bar5_size_mask_5	:	string := "bar5_size_mask";
		bar5_size_mask_6	:	string := "bar5_size_mask";
		bar5_size_mask_7	:	string := "bar5_size_mask";
		bar5_size_mask_data_0	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar5_size_mask_data_1	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar5_size_mask_data_2	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar5_size_mask_data_3	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar5_size_mask_data_4	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar5_size_mask_data_5	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar5_size_mask_data_6	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bar5_size_mask_data_7	:	std_logic_vector(27 downto 0) := "0000000000000000000000000000";
		bist_memory_settings	:	string := "bist_memory_settings";
		bist_memory_settings_data	:	std_logic_vector(74 downto 0) := "000000000000000000000000000000000000000000000000000000000000000000000000000";
		bonding_mode	:	string := "bond_disable";
		br_rcb	:	string := "ro";
		bridge_66mhzcap	:	string := "true";
		bridge_port_ssid_support_0	:	string := "false";
		bridge_port_ssid_support_1	:	string := "false";
		bridge_port_ssid_support_2	:	string := "false";
		bridge_port_ssid_support_3	:	string := "false";
		bridge_port_ssid_support_4	:	string := "false";
		bridge_port_ssid_support_5	:	string := "false";
		bridge_port_ssid_support_6	:	string := "false";
		bridge_port_ssid_support_7	:	string := "false";
		bridge_port_vga_enable_0	:	string := "false";
		bridge_port_vga_enable_1	:	string := "false";
		bridge_port_vga_enable_2	:	string := "false";
		bridge_port_vga_enable_3	:	string := "false";
		bridge_port_vga_enable_4	:	string := "false";
		bridge_port_vga_enable_5	:	string := "false";
		bridge_port_vga_enable_6	:	string := "false";
		bridge_port_vga_enable_7	:	string := "false";
		bypass_cdc	:	string := "false";
		bypass_clk_switch	:	string := "disable";
		bypass_tl	:	string := "false";
		cdc_clk_relation	:	string := "plesiochronous";
		cdc_dummy_insert_limit	:	string := "cdc_dummy_insert_limit";
		cdc_dummy_insert_limit_data	:	std_logic_vector(3 downto 0) := "1011";
		class_code_0	:	string := "class_code";
		class_code_1	:	string := "class_code";
		class_code_2	:	string := "class_code";
		class_code_3	:	string := "class_code";
		class_code_4	:	string := "class_code";
		class_code_5	:	string := "class_code";
		class_code_6	:	string := "class_code";
		class_code_7	:	string := "class_code";
		class_code_data_0	:	std_logic_vector(23 downto 0) := "111111110000000000000000";
		class_code_data_1	:	std_logic_vector(23 downto 0) := "111111110000000000000000";
		class_code_data_2	:	std_logic_vector(23 downto 0) := "111111110000000000000000";
		class_code_data_3	:	std_logic_vector(23 downto 0) := "111111110000000000000000";
		class_code_data_4	:	std_logic_vector(23 downto 0) := "111111110000000000000000";
		class_code_data_5	:	std_logic_vector(23 downto 0) := "111111110000000000000000";
		class_code_data_6	:	std_logic_vector(23 downto 0) := "111111110000000000000000";
		class_code_data_7	:	std_logic_vector(23 downto 0) := "111111110000000000000000";
		completion_timeout_0	:	string := "abcd";
		completion_timeout_1	:	string := "abcd";
		completion_timeout_2	:	string := "abcd";
		completion_timeout_3	:	string := "abcd";
		completion_timeout_4	:	string := "abcd";
		completion_timeout_5	:	string := "abcd";
		completion_timeout_6	:	string := "abcd";
		completion_timeout_7	:	string := "abcd";
		core_clk_disable_clk_switch	:	string := "pld_clk";
		core_clk_divider	:	string := "div_1";
		core_clk_out_sel	:	string := "div_1";
		core_clk_sel	:	string := "core_clk_out";
		core_clk_source	:	string := "pll_fixed_clk";
		credit_buffer_allocation_aux	:	string := "balanced";
		cvp_clk_reset	:	string := "false";
		cvp_data_compressed	:	string := "false";
		cvp_data_encrypted	:	string := "false";
		cvp_enable	:	string := "cvp_dis";
		cvp_isolation	:	string := "disable";
		cvp_mdio_dis_csr_ctrl_1	:	string := "mdio_dis_cvp_dis";
		cvp_mdio_dis_csr_ctrl_2	:	string := "mdio_dis_cvp_dis";
		cvp_mdio_dis_csr_ctrl_3	:	string := "mdio_dis_cvp_dis";
		cvp_mdio_dis_csr_ctrl_4	:	string := "mdio_dis_cvp_dis";
		cvp_mdio_dis_csr_ctrl_5	:	string := "mdio_dis_cvp_dis";
		cvp_mdio_dis_csr_ctrl_6	:	string := "mdio_dis_cvp_dis";
		cvp_mode_reset	:	string := "false";
		cvp_rate_sel	:	string := "full_rate";
		d0_pme_0	:	string := "false";
		d0_pme_1	:	string := "false";
		d0_pme_2	:	string := "false";
		d0_pme_3	:	string := "false";
		d0_pme_4	:	string := "false";
		d0_pme_5	:	string := "false";
		d0_pme_6	:	string := "false";
		d0_pme_7	:	string := "false";
		d1_pme_0	:	string := "false";
		d1_pme_1	:	string := "false";
		d1_pme_2	:	string := "false";
		d1_pme_3	:	string := "false";
		d1_pme_4	:	string := "false";
		d1_pme_5	:	string := "false";
		d1_pme_6	:	string := "false";
		d1_pme_7	:	string := "false";
		d1_support_0	:	string := "false";
		d1_support_1	:	string := "false";
		d1_support_2	:	string := "false";
		d1_support_3	:	string := "false";
		d1_support_4	:	string := "false";
		d1_support_5	:	string := "false";
		d1_support_6	:	string := "false";
		d1_support_7	:	string := "false";
		d2_pme_0	:	string := "false";
		d2_pme_1	:	string := "false";
		d2_pme_2	:	string := "false";
		d2_pme_3	:	string := "false";
		d2_pme_4	:	string := "false";
		d2_pme_5	:	string := "false";
		d2_pme_6	:	string := "false";
		d2_pme_7	:	string := "false";
		d2_support_0	:	string := "false";
		d2_support_1	:	string := "false";
		d2_support_2	:	string := "false";
		d2_support_3	:	string := "false";
		d2_support_4	:	string := "false";
		d2_support_5	:	string := "false";
		d2_support_6	:	string := "false";
		d2_support_7	:	string := "false";
		d3_cold_pme_0	:	string := "false";
		d3_cold_pme_1	:	string := "false";
		d3_cold_pme_2	:	string := "false";
		d3_cold_pme_3	:	string := "false";
		d3_cold_pme_4	:	string := "false";
		d3_cold_pme_5	:	string := "false";
		d3_cold_pme_6	:	string := "false";
		d3_cold_pme_7	:	string := "false";
		d3_hot_pme_0	:	string := "false";
		d3_hot_pme_1	:	string := "false";
		d3_hot_pme_2	:	string := "false";
		d3_hot_pme_3	:	string := "false";
		d3_hot_pme_4	:	string := "false";
		d3_hot_pme_5	:	string := "false";
		d3_hot_pme_6	:	string := "false";
		d3_hot_pme_7	:	string := "false";
		deemphasis_enable_0	:	string := "false";
		deemphasis_enable_1	:	string := "false";
		deemphasis_enable_2	:	string := "false";
		deemphasis_enable_3	:	string := "false";
		deemphasis_enable_4	:	string := "false";
		deemphasis_enable_5	:	string := "false";
		deemphasis_enable_6	:	string := "false";
		deemphasis_enable_7	:	string := "false";
		device_id_0	:	string := "device_id";
		device_id_1	:	string := "device_id";
		device_id_2	:	string := "device_id";
		device_id_3	:	string := "device_id";
		device_id_4	:	string := "device_id";
		device_id_5	:	string := "device_id";
		device_id_6	:	string := "device_id";
		device_id_7	:	string := "device_id";
		device_id_data_0	:	std_logic_vector(15 downto 0) := "0000000000000001";
		device_id_data_1	:	std_logic_vector(15 downto 0) := "0000000000000001";
		device_id_data_2	:	std_logic_vector(15 downto 0) := "0000000000000001";
		device_id_data_3	:	std_logic_vector(15 downto 0) := "0000000000000001";
		device_id_data_4	:	std_logic_vector(15 downto 0) := "0000000000000001";
		device_id_data_5	:	std_logic_vector(15 downto 0) := "0000000000000001";
		device_id_data_6	:	std_logic_vector(15 downto 0) := "0000000000000001";
		device_id_data_7	:	std_logic_vector(15 downto 0) := "0000000000000001";
		device_number	:	string := "device_number";
		device_number_data	:	std_logic_vector(4 downto 0) := "00000";
		device_specific_init_0	:	string := "false";
		device_specific_init_1	:	string := "false";
		device_specific_init_2	:	string := "false";
		device_specific_init_3	:	string := "false";
		device_specific_init_4	:	string := "false";
		device_specific_init_5	:	string := "false";
		device_specific_init_6	:	string := "false";
		device_specific_init_7	:	string := "false";
		devseltim	:	string := "fast_devsel_decoding";
		dft_broadcast_en_1	:	string := "broadcast_dis";
		dft_broadcast_en_2	:	string := "broadcast_dis";
		dft_broadcast_en_3	:	string := "broadcast_dis";
		dft_broadcast_en_4	:	string := "broadcast_dis";
		dft_broadcast_en_5	:	string := "broadcast_dis";
		dft_broadcast_en_6	:	string := "broadcast_dis";
		diffclock_nfts_count_0	:	string := "diffclock_nfts_count";
		diffclock_nfts_count_1	:	string := "diffclock_nfts_count";
		diffclock_nfts_count_2	:	string := "diffclock_nfts_count";
		diffclock_nfts_count_3	:	string := "diffclock_nfts_count";
		diffclock_nfts_count_4	:	string := "diffclock_nfts_count";
		diffclock_nfts_count_5	:	string := "diffclock_nfts_count";
		diffclock_nfts_count_6	:	string := "diffclock_nfts_count";
		diffclock_nfts_count_7	:	string := "diffclock_nfts_count";
		diffclock_nfts_count_data_0	:	std_logic_vector(7 downto 0) := "00000000";
		diffclock_nfts_count_data_1	:	std_logic_vector(7 downto 0) := "00000000";
		diffclock_nfts_count_data_2	:	std_logic_vector(7 downto 0) := "00000000";
		diffclock_nfts_count_data_3	:	std_logic_vector(7 downto 0) := "00000000";
		diffclock_nfts_count_data_4	:	std_logic_vector(7 downto 0) := "00000000";
		diffclock_nfts_count_data_5	:	std_logic_vector(7 downto 0) := "00000000";
		diffclock_nfts_count_data_6	:	std_logic_vector(7 downto 0) := "00000000";
		diffclock_nfts_count_data_7	:	std_logic_vector(7 downto 0) := "00000000";
		disable_auto_crs	:	string := "disable";
		disable_clk_switch	:	string := "disable";
		disable_link_x2_support	:	string := "false";
		disable_snoop_packet_0	:	string := "false";
		disable_snoop_packet_1	:	string := "false";
		disable_snoop_packet_2	:	string := "false";
		disable_snoop_packet_3	:	string := "false";
		disable_snoop_packet_4	:	string := "false";
		disable_snoop_packet_5	:	string := "false";
		disable_snoop_packet_6	:	string := "false";
		disable_snoop_packet_7	:	string := "false";
		disable_tag_check	:	string := "enable";
		dll_active_report_support_0	:	string := "false";
		dll_active_report_support_1	:	string := "false";
		dll_active_report_support_2	:	string := "false";
		dll_active_report_support_3	:	string := "false";
		dll_active_report_support_4	:	string := "false";
		dll_active_report_support_5	:	string := "false";
		dll_active_report_support_6	:	string := "false";
		dll_active_report_support_7	:	string := "false";
		ecrc_check_capable_0	:	string := "true";
		ecrc_check_capable_1	:	string := "true";
		ecrc_check_capable_2	:	string := "true";
		ecrc_check_capable_3	:	string := "true";
		ecrc_check_capable_4	:	string := "true";
		ecrc_check_capable_5	:	string := "true";
		ecrc_check_capable_6	:	string := "true";
		ecrc_check_capable_7	:	string := "true";
		ecrc_gen_capable_0	:	string := "true";
		ecrc_gen_capable_1	:	string := "true";
		ecrc_gen_capable_2	:	string := "true";
		ecrc_gen_capable_3	:	string := "true";
		ecrc_gen_capable_4	:	string := "true";
		ecrc_gen_capable_5	:	string := "true";
		ecrc_gen_capable_6	:	string := "true";
		ecrc_gen_capable_7	:	string := "true";
		ei_delay_powerdown_count	:	string := "ei_delay_powerdown_count";
		ei_delay_powerdown_count_data	:	std_logic_vector(7 downto 0) := "00001010";
		eie_before_nfts_count_0	:	string := "eie_before_nfts_count";
		eie_before_nfts_count_1	:	string := "eie_before_nfts_count";
		eie_before_nfts_count_2	:	string := "eie_before_nfts_count";
		eie_before_nfts_count_3	:	string := "eie_before_nfts_count";
		eie_before_nfts_count_4	:	string := "eie_before_nfts_count";
		eie_before_nfts_count_5	:	string := "eie_before_nfts_count";
		eie_before_nfts_count_6	:	string := "eie_before_nfts_count";
		eie_before_nfts_count_7	:	string := "eie_before_nfts_count";
		eie_before_nfts_count_data_0	:	std_logic_vector(3 downto 0) := "0100";
		eie_before_nfts_count_data_1	:	std_logic_vector(3 downto 0) := "0100";
		eie_before_nfts_count_data_2	:	std_logic_vector(3 downto 0) := "0100";
		eie_before_nfts_count_data_3	:	std_logic_vector(3 downto 0) := "0100";
		eie_before_nfts_count_data_4	:	std_logic_vector(3 downto 0) := "0100";
		eie_before_nfts_count_data_5	:	std_logic_vector(3 downto 0) := "0100";
		eie_before_nfts_count_data_6	:	std_logic_vector(3 downto 0) := "0100";
		eie_before_nfts_count_data_7	:	std_logic_vector(3 downto 0) := "0100";
		electromech_interlock_0	:	string := "false";
		electromech_interlock_1	:	string := "false";
		electromech_interlock_2	:	string := "false";
		electromech_interlock_3	:	string := "false";
		electromech_interlock_4	:	string := "false";
		electromech_interlock_5	:	string := "false";
		electromech_interlock_6	:	string := "false";
		electromech_interlock_7	:	string := "false";
		enable_adapter_half_rate_mode	:	string := "false";
		enable_ch01_pclk_out	:	string := "pclk_ch0";
		enable_ch0_pclk_out	:	string := "pclk_ch01";
		enable_completion_timeout_disable_0	:	string := "true";
		enable_completion_timeout_disable_1	:	string := "true";
		enable_completion_timeout_disable_2	:	string := "true";
		enable_completion_timeout_disable_3	:	string := "true";
		enable_completion_timeout_disable_4	:	string := "true";
		enable_completion_timeout_disable_5	:	string := "true";
		enable_completion_timeout_disable_6	:	string := "true";
		enable_completion_timeout_disable_7	:	string := "true";
		enable_function_msix_support_0	:	string := "true";
		enable_function_msix_support_1	:	string := "true";
		enable_function_msix_support_2	:	string := "true";
		enable_function_msix_support_3	:	string := "true";
		enable_function_msix_support_4	:	string := "true";
		enable_function_msix_support_5	:	string := "true";
		enable_function_msix_support_6	:	string := "true";
		enable_function_msix_support_7	:	string := "true";
		enable_l0s_aspm_0	:	string := "false";
		enable_l0s_aspm_1	:	string := "false";
		enable_l0s_aspm_2	:	string := "false";
		enable_l0s_aspm_3	:	string := "false";
		enable_l0s_aspm_4	:	string := "false";
		enable_l0s_aspm_5	:	string := "false";
		enable_l0s_aspm_6	:	string := "false";
		enable_l0s_aspm_7	:	string := "false";
		enable_l1_aspm_0	:	string := "false";
		enable_l1_aspm_1	:	string := "false";
		enable_l1_aspm_2	:	string := "false";
		enable_l1_aspm_3	:	string := "false";
		enable_l1_aspm_4	:	string := "false";
		enable_l1_aspm_5	:	string := "false";
		enable_l1_aspm_6	:	string := "false";
		enable_l1_aspm_7	:	string := "false";
		enable_rx_buffer_checking	:	string := "false";
		enable_rx_reordering	:	string := "true";
		enable_slot_register	:	string := "false";
		endpoint_l0_latency_0	:	string := "endpoint_l0_latency";
		endpoint_l0_latency_1	:	string := "endpoint_l0_latency";
		endpoint_l0_latency_2	:	string := "endpoint_l0_latency";
		endpoint_l0_latency_3	:	string := "endpoint_l0_latency";
		endpoint_l0_latency_4	:	string := "endpoint_l0_latency";
		endpoint_l0_latency_5	:	string := "endpoint_l0_latency";
		endpoint_l0_latency_6	:	string := "endpoint_l0_latency";
		endpoint_l0_latency_7	:	string := "endpoint_l0_latency";
		endpoint_l0_latency_data_0	:	std_logic_vector(2 downto 0) := "000";
		endpoint_l0_latency_data_1	:	std_logic_vector(2 downto 0) := "000";
		endpoint_l0_latency_data_2	:	std_logic_vector(2 downto 0) := "000";
		endpoint_l0_latency_data_3	:	std_logic_vector(2 downto 0) := "000";
		endpoint_l0_latency_data_4	:	std_logic_vector(2 downto 0) := "000";
		endpoint_l0_latency_data_5	:	std_logic_vector(2 downto 0) := "000";
		endpoint_l0_latency_data_6	:	std_logic_vector(2 downto 0) := "000";
		endpoint_l0_latency_data_7	:	std_logic_vector(2 downto 0) := "000";
		endpoint_l1_latency_0	:	string := "endpoint_l1_latency";
		endpoint_l1_latency_1	:	string := "endpoint_l1_latency";
		endpoint_l1_latency_2	:	string := "endpoint_l1_latency";
		endpoint_l1_latency_3	:	string := "endpoint_l1_latency";
		endpoint_l1_latency_4	:	string := "endpoint_l1_latency";
		endpoint_l1_latency_5	:	string := "endpoint_l1_latency";
		endpoint_l1_latency_6	:	string := "endpoint_l1_latency";
		endpoint_l1_latency_7	:	string := "endpoint_l1_latency";
		endpoint_l1_latency_data_0	:	std_logic_vector(2 downto 0) := "000";
		endpoint_l1_latency_data_1	:	std_logic_vector(2 downto 0) := "000";
		endpoint_l1_latency_data_2	:	std_logic_vector(2 downto 0) := "000";
		endpoint_l1_latency_data_3	:	std_logic_vector(2 downto 0) := "000";
		endpoint_l1_latency_data_4	:	std_logic_vector(2 downto 0) := "000";
		endpoint_l1_latency_data_5	:	std_logic_vector(2 downto 0) := "000";
		endpoint_l1_latency_data_6	:	std_logic_vector(2 downto 0) := "000";
		endpoint_l1_latency_data_7	:	std_logic_vector(2 downto 0) := "000";
		expansion_base_address_register_0	:	string := "expansion_base_address_register";
		expansion_base_address_register_1	:	string := "expansion_base_address_register";
		expansion_base_address_register_2	:	string := "expansion_base_address_register";
		expansion_base_address_register_3	:	string := "expansion_base_address_register";
		expansion_base_address_register_4	:	string := "expansion_base_address_register";
		expansion_base_address_register_5	:	string := "expansion_base_address_register";
		expansion_base_address_register_6	:	string := "expansion_base_address_register";
		expansion_base_address_register_7	:	string := "expansion_base_address_register";
		expansion_base_address_register_data_0	:	std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
		expansion_base_address_register_data_1	:	std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
		expansion_base_address_register_data_2	:	std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
		expansion_base_address_register_data_3	:	std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
		expansion_base_address_register_data_4	:	std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
		expansion_base_address_register_data_5	:	std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
		expansion_base_address_register_data_6	:	std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
		expansion_base_address_register_data_7	:	std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
		extend_tag_field_0	:	string := "false";
		extend_tag_field_1	:	string := "false";
		extend_tag_field_2	:	string := "false";
		extend_tag_field_3	:	string := "false";
		extend_tag_field_4	:	string := "false";
		extend_tag_field_5	:	string := "false";
		extend_tag_field_6	:	string := "false";
		extend_tag_field_7	:	string := "false";
		fastb2bcap	:	string := "true";
		fc_init_timer	:	string := "fc_init_timer";
		fc_init_timer_data	:	std_logic_vector(10 downto 0) := "10000000000";
		flow_control_timeout_count	:	string := "flow_control_timeout_count";
		flow_control_timeout_count_data	:	std_logic_vector(7 downto 0) := "11001000";
		flow_control_update_count	:	string := "flow_control_update_count";
		flow_control_update_count_data	:	std_logic_vector(4 downto 0) := "11110";
		flr_capability_0	:	string := "true";
		flr_capability_1	:	string := "true";
		flr_capability_2	:	string := "true";
		flr_capability_3	:	string := "true";
		flr_capability_4	:	string := "true";
		flr_capability_5	:	string := "true";
		flr_capability_6	:	string := "true";
		flr_capability_7	:	string := "true";
		force_mdio_dis_csr_ctrl_1	:	string := "mdio_dis_force_dis";
		force_mdio_dis_csr_ctrl_2	:	string := "mdio_dis_force_dis";
		force_mdio_dis_csr_ctrl_3	:	string := "mdio_dis_force_dis";
		force_mdio_dis_csr_ctrl_4	:	string := "mdio_dis_force_dis";
		force_mdio_dis_csr_ctrl_5	:	string := "mdio_dis_force_dis";
		force_mdio_dis_csr_ctrl_6	:	string := "mdio_dis_force_dis";
		func_mode	:	string := "enable";
		gen12_lane_rate_mode	:	string := "gen1";
		gen2_diffclock_nfts_count_0	:	string := "gen2_diffclock_nfts_count";
		gen2_diffclock_nfts_count_1	:	string := "gen2_diffclock_nfts_count";
		gen2_diffclock_nfts_count_2	:	string := "gen2_diffclock_nfts_count";
		gen2_diffclock_nfts_count_3	:	string := "gen2_diffclock_nfts_count";
		gen2_diffclock_nfts_count_4	:	string := "gen2_diffclock_nfts_count";
		gen2_diffclock_nfts_count_5	:	string := "gen2_diffclock_nfts_count";
		gen2_diffclock_nfts_count_6	:	string := "gen2_diffclock_nfts_count";
		gen2_diffclock_nfts_count_7	:	string := "gen2_diffclock_nfts_count";
		gen2_diffclock_nfts_count_data_0	:	std_logic_vector(7 downto 0) := "11111111";
		gen2_diffclock_nfts_count_data_1	:	std_logic_vector(7 downto 0) := "11111111";
		gen2_diffclock_nfts_count_data_2	:	std_logic_vector(7 downto 0) := "11111111";
		gen2_diffclock_nfts_count_data_3	:	std_logic_vector(7 downto 0) := "11111111";
		gen2_diffclock_nfts_count_data_4	:	std_logic_vector(7 downto 0) := "11111111";
		gen2_diffclock_nfts_count_data_5	:	std_logic_vector(7 downto 0) := "11111111";
		gen2_diffclock_nfts_count_data_6	:	std_logic_vector(7 downto 0) := "11111111";
		gen2_diffclock_nfts_count_data_7	:	std_logic_vector(7 downto 0) := "11111111";
		gen2_sameclock_nfts_count_0	:	string := "gen2_sameclock_nfts_count";
		gen2_sameclock_nfts_count_1	:	string := "gen2_sameclock_nfts_count";
		gen2_sameclock_nfts_count_2	:	string := "gen2_sameclock_nfts_count";
		gen2_sameclock_nfts_count_3	:	string := "gen2_sameclock_nfts_count";
		gen2_sameclock_nfts_count_4	:	string := "gen2_sameclock_nfts_count";
		gen2_sameclock_nfts_count_5	:	string := "gen2_sameclock_nfts_count";
		gen2_sameclock_nfts_count_6	:	string := "gen2_sameclock_nfts_count";
		gen2_sameclock_nfts_count_7	:	string := "gen2_sameclock_nfts_count";
		gen2_sameclock_nfts_count_data_0	:	std_logic_vector(7 downto 0) := "11111111";
		gen2_sameclock_nfts_count_data_1	:	std_logic_vector(7 downto 0) := "11111111";
		gen2_sameclock_nfts_count_data_2	:	std_logic_vector(7 downto 0) := "11111111";
		gen2_sameclock_nfts_count_data_3	:	std_logic_vector(7 downto 0) := "11111111";
		gen2_sameclock_nfts_count_data_4	:	std_logic_vector(7 downto 0) := "11111111";
		gen2_sameclock_nfts_count_data_5	:	std_logic_vector(7 downto 0) := "11111111";
		gen2_sameclock_nfts_count_data_6	:	std_logic_vector(7 downto 0) := "11111111";
		gen2_sameclock_nfts_count_data_7	:	std_logic_vector(7 downto 0) := "11111111";
		hard_reset_bypass	:	string := "false";
		hot_plug_support_0	:	string := "hot_plug_support";
		hot_plug_support_1	:	string := "hot_plug_support";
		hot_plug_support_2	:	string := "hot_plug_support";
		hot_plug_support_3	:	string := "hot_plug_support";
		hot_plug_support_4	:	string := "hot_plug_support";
		hot_plug_support_5	:	string := "hot_plug_support";
		hot_plug_support_6	:	string := "hot_plug_support";
		hot_plug_support_7	:	string := "hot_plug_support";
		hot_plug_support_data_0	:	std_logic_vector(6 downto 0) := "0000000";
		hot_plug_support_data_1	:	std_logic_vector(6 downto 0) := "0000000";
		hot_plug_support_data_2	:	std_logic_vector(6 downto 0) := "0000000";
		hot_plug_support_data_3	:	std_logic_vector(6 downto 0) := "0000000";
		hot_plug_support_data_4	:	std_logic_vector(6 downto 0) := "0000000";
		hot_plug_support_data_5	:	std_logic_vector(6 downto 0) := "0000000";
		hot_plug_support_data_6	:	std_logic_vector(6 downto 0) := "0000000";
		hot_plug_support_data_7	:	std_logic_vector(6 downto 0) := "0000000";
		hrdrstctrl_en	:	string := "hrdrstctrl_dis";
		iei_enable_settings	:	string := "gen2_infei_infsd_gen1_infei_sd";
		indicator_0	:	string := "indicator";
		indicator_1	:	string := "indicator";
		indicator_2	:	string := "indicator";
		indicator_3	:	string := "indicator";
		indicator_4	:	string := "indicator";
		indicator_5	:	string := "indicator";
		indicator_6	:	string := "indicator";
		indicator_7	:	string := "indicator";
		indicator_data_0	:	std_logic_vector(2 downto 0) := "111";
		indicator_data_1	:	std_logic_vector(2 downto 0) := "111";
		indicator_data_2	:	std_logic_vector(2 downto 0) := "111";
		indicator_data_3	:	std_logic_vector(2 downto 0) := "111";
		indicator_data_4	:	std_logic_vector(2 downto 0) := "111";
		indicator_data_5	:	std_logic_vector(2 downto 0) := "111";
		indicator_data_6	:	std_logic_vector(2 downto 0) := "111";
		indicator_data_7	:	std_logic_vector(2 downto 0) := "111";
		intel_id_access_0	:	string := "false";
		intel_id_access_1	:	string := "false";
		intel_id_access_2	:	string := "false";
		intel_id_access_3	:	string := "false";
		intel_id_access_4	:	string := "false";
		intel_id_access_5	:	string := "false";
		intel_id_access_6	:	string := "false";
		intel_id_access_7	:	string := "false";
		interrupt_pin_0	:	string := "inta";
		interrupt_pin_1	:	string := "inta";
		interrupt_pin_2	:	string := "inta";
		interrupt_pin_3	:	string := "inta";
		interrupt_pin_4	:	string := "inta";
		interrupt_pin_5	:	string := "inta";
		interrupt_pin_6	:	string := "inta";
		interrupt_pin_7	:	string := "inta";
		io_window_addr_width_0	:	string := "window_32_bit";
		io_window_addr_width_1	:	string := "window_32_bit";
		io_window_addr_width_2	:	string := "window_32_bit";
		io_window_addr_width_3	:	string := "window_32_bit";
		io_window_addr_width_4	:	string := "window_32_bit";
		io_window_addr_width_5	:	string := "window_32_bit";
		io_window_addr_width_6	:	string := "window_32_bit";
		io_window_addr_width_7	:	string := "window_32_bit";
		jtag_id	:	string := "jtag_id";
		jtag_id_data	:	std_logic_vector(127 downto 0) := "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
		l01_entry_latency	:	string := "l01_entry_latency";
		l01_entry_latency_data	:	std_logic_vector(4 downto 0) := "11111";
		l0_exit_latency_diffclock_0	:	string := "l0_exit_latency_diffclock";
		l0_exit_latency_diffclock_1	:	string := "l0_exit_latency_diffclock";
		l0_exit_latency_diffclock_2	:	string := "l0_exit_latency_diffclock";
		l0_exit_latency_diffclock_3	:	string := "l0_exit_latency_diffclock";
		l0_exit_latency_diffclock_4	:	string := "l0_exit_latency_diffclock";
		l0_exit_latency_diffclock_5	:	string := "l0_exit_latency_diffclock";
		l0_exit_latency_diffclock_6	:	string := "l0_exit_latency_diffclock";
		l0_exit_latency_diffclock_7	:	string := "l0_exit_latency_diffclock";
		l0_exit_latency_diffclock_data_0	:	std_logic_vector(2 downto 0) := "110";
		l0_exit_latency_diffclock_data_1	:	std_logic_vector(2 downto 0) := "110";
		l0_exit_latency_diffclock_data_2	:	std_logic_vector(2 downto 0) := "110";
		l0_exit_latency_diffclock_data_3	:	std_logic_vector(2 downto 0) := "110";
		l0_exit_latency_diffclock_data_4	:	std_logic_vector(2 downto 0) := "110";
		l0_exit_latency_diffclock_data_5	:	std_logic_vector(2 downto 0) := "110";
		l0_exit_latency_diffclock_data_6	:	std_logic_vector(2 downto 0) := "110";
		l0_exit_latency_diffclock_data_7	:	std_logic_vector(2 downto 0) := "110";
		l0_exit_latency_sameclock_0	:	string := "l0_exit_latency_sameclock";
		l0_exit_latency_sameclock_1	:	string := "l0_exit_latency_sameclock";
		l0_exit_latency_sameclock_2	:	string := "l0_exit_latency_sameclock";
		l0_exit_latency_sameclock_3	:	string := "l0_exit_latency_sameclock";
		l0_exit_latency_sameclock_4	:	string := "l0_exit_latency_sameclock";
		l0_exit_latency_sameclock_5	:	string := "l0_exit_latency_sameclock";
		l0_exit_latency_sameclock_6	:	string := "l0_exit_latency_sameclock";
		l0_exit_latency_sameclock_7	:	string := "l0_exit_latency_sameclock";
		l0_exit_latency_sameclock_data_0	:	std_logic_vector(2 downto 0) := "110";
		l0_exit_latency_sameclock_data_1	:	std_logic_vector(2 downto 0) := "110";
		l0_exit_latency_sameclock_data_2	:	std_logic_vector(2 downto 0) := "110";
		l0_exit_latency_sameclock_data_3	:	std_logic_vector(2 downto 0) := "110";
		l0_exit_latency_sameclock_data_4	:	std_logic_vector(2 downto 0) := "110";
		l0_exit_latency_sameclock_data_5	:	std_logic_vector(2 downto 0) := "110";
		l0_exit_latency_sameclock_data_6	:	std_logic_vector(2 downto 0) := "110";
		l0_exit_latency_sameclock_data_7	:	std_logic_vector(2 downto 0) := "110";
		l1_exit_latency_diffclock_0	:	string := "l1_exit_latency_diffclock";
		l1_exit_latency_diffclock_1	:	string := "l1_exit_latency_diffclock";
		l1_exit_latency_diffclock_2	:	string := "l1_exit_latency_diffclock";
		l1_exit_latency_diffclock_3	:	string := "l1_exit_latency_diffclock";
		l1_exit_latency_diffclock_4	:	string := "l1_exit_latency_diffclock";
		l1_exit_latency_diffclock_5	:	string := "l1_exit_latency_diffclock";
		l1_exit_latency_diffclock_6	:	string := "l1_exit_latency_diffclock";
		l1_exit_latency_diffclock_7	:	string := "l1_exit_latency_diffclock";
		l1_exit_latency_diffclock_data_0	:	std_logic_vector(2 downto 0) := "000";
		l1_exit_latency_diffclock_data_1	:	std_logic_vector(2 downto 0) := "000";
		l1_exit_latency_diffclock_data_2	:	std_logic_vector(2 downto 0) := "000";
		l1_exit_latency_diffclock_data_3	:	std_logic_vector(2 downto 0) := "000";
		l1_exit_latency_diffclock_data_4	:	std_logic_vector(2 downto 0) := "000";
		l1_exit_latency_diffclock_data_5	:	std_logic_vector(2 downto 0) := "000";
		l1_exit_latency_diffclock_data_6	:	std_logic_vector(2 downto 0) := "000";
		l1_exit_latency_diffclock_data_7	:	std_logic_vector(2 downto 0) := "000";
		l1_exit_latency_sameclock_0	:	string := "l1_exit_latency_sameclock";
		l1_exit_latency_sameclock_1	:	string := "l1_exit_latency_sameclock";
		l1_exit_latency_sameclock_2	:	string := "l1_exit_latency_sameclock";
		l1_exit_latency_sameclock_3	:	string := "l1_exit_latency_sameclock";
		l1_exit_latency_sameclock_4	:	string := "l1_exit_latency_sameclock";
		l1_exit_latency_sameclock_5	:	string := "l1_exit_latency_sameclock";
		l1_exit_latency_sameclock_6	:	string := "l1_exit_latency_sameclock";
		l1_exit_latency_sameclock_7	:	string := "l1_exit_latency_sameclock";
		l1_exit_latency_sameclock_data_0	:	std_logic_vector(2 downto 0) := "000";
		l1_exit_latency_sameclock_data_1	:	std_logic_vector(2 downto 0) := "000";
		l1_exit_latency_sameclock_data_2	:	std_logic_vector(2 downto 0) := "000";
		l1_exit_latency_sameclock_data_3	:	std_logic_vector(2 downto 0) := "000";
		l1_exit_latency_sameclock_data_4	:	std_logic_vector(2 downto 0) := "000";
		l1_exit_latency_sameclock_data_5	:	std_logic_vector(2 downto 0) := "000";
		l1_exit_latency_sameclock_data_6	:	std_logic_vector(2 downto 0) := "000";
		l1_exit_latency_sameclock_data_7	:	std_logic_vector(2 downto 0) := "000";
		l2_async_logic_0	:	string := "enable";
		l2_async_logic_1	:	string := "enable";
		l2_async_logic_2	:	string := "enable";
		l2_async_logic_3	:	string := "enable";
		l2_async_logic_4	:	string := "enable";
		l2_async_logic_5	:	string := "enable";
		l2_async_logic_6	:	string := "enable";
		l2_async_logic_7	:	string := "enable";
		lane_mask	:	string := "x4";
		lattim	:	string := "ro";
		lattim_ro_data	:	std_logic_vector(6 downto 0) := "0001000";
		low_priority_vc_0	:	string := "single_vc";
		low_priority_vc_1	:	string := "single_vc";
		low_priority_vc_2	:	string := "single_vc";
		low_priority_vc_3	:	string := "single_vc";
		low_priority_vc_4	:	string := "single_vc";
		low_priority_vc_5	:	string := "single_vc";
		low_priority_vc_6	:	string := "single_vc";
		low_priority_vc_7	:	string := "single_vc";
		lpm_type	:	string := "cyclonev_hd_altpe2_hip_top";
		max_link_width_0	:	string := "x4";
		max_link_width_1	:	string := "x4";
		max_link_width_2	:	string := "x4";
		max_link_width_3	:	string := "x4";
		max_link_width_4	:	string := "x4";
		max_link_width_5	:	string := "x4";
		max_link_width_6	:	string := "x4";
		max_link_width_7	:	string := "x4";
		max_payload_size_0	:	string := "payload_512";
		max_payload_size_1	:	string := "payload_512";
		max_payload_size_2	:	string := "payload_512";
		max_payload_size_3	:	string := "payload_512";
		max_payload_size_4	:	string := "payload_512";
		max_payload_size_5	:	string := "payload_512";
		max_payload_size_6	:	string := "payload_512";
		max_payload_size_7	:	string := "payload_512";
		maximum_current_0	:	string := "maximum_current";
		maximum_current_1	:	string := "maximum_current";
		maximum_current_2	:	string := "maximum_current";
		maximum_current_3	:	string := "maximum_current";
		maximum_current_4	:	string := "maximum_current";
		maximum_current_5	:	string := "maximum_current";
		maximum_current_6	:	string := "maximum_current";
		maximum_current_7	:	string := "maximum_current";
		maximum_current_data_0	:	std_logic_vector(2 downto 0) := "000";
		maximum_current_data_1	:	std_logic_vector(2 downto 0) := "000";
		maximum_current_data_2	:	std_logic_vector(2 downto 0) := "000";
		maximum_current_data_3	:	std_logic_vector(2 downto 0) := "000";
		maximum_current_data_4	:	std_logic_vector(2 downto 0) := "000";
		maximum_current_data_5	:	std_logic_vector(2 downto 0) := "000";
		maximum_current_data_6	:	std_logic_vector(2 downto 0) := "000";
		maximum_current_data_7	:	std_logic_vector(2 downto 0) := "000";
		mdio_cb_opbit_enable	:	string := "enable";
		memwrinv	:	string := "ro";
		millisecond_cycle_count	:	string := "millisecond_cycle_count";
		millisecond_cycle_count_data	:	std_logic_vector(19 downto 0) := "00111100101010110100";
		msi_64bit_addressing_capable_0	:	string := "true";
		msi_64bit_addressing_capable_1	:	string := "true";
		msi_64bit_addressing_capable_2	:	string := "true";
		msi_64bit_addressing_capable_3	:	string := "true";
		msi_64bit_addressing_capable_4	:	string := "true";
		msi_64bit_addressing_capable_5	:	string := "true";
		msi_64bit_addressing_capable_6	:	string := "true";
		msi_64bit_addressing_capable_7	:	string := "true";
		msi_masking_capable_0	:	string := "false";
		msi_masking_capable_1	:	string := "false";
		msi_masking_capable_2	:	string := "false";
		msi_masking_capable_3	:	string := "false";
		msi_masking_capable_4	:	string := "false";
		msi_masking_capable_5	:	string := "false";
		msi_masking_capable_6	:	string := "false";
		msi_masking_capable_7	:	string := "false";
		msi_multi_message_capable_0	:	string := "count_4";
		msi_multi_message_capable_1	:	string := "count_4";
		msi_multi_message_capable_2	:	string := "count_4";
		msi_multi_message_capable_3	:	string := "count_4";
		msi_multi_message_capable_4	:	string := "count_4";
		msi_multi_message_capable_5	:	string := "count_4";
		msi_multi_message_capable_6	:	string := "count_4";
		msi_multi_message_capable_7	:	string := "count_4";
		msi_support_0	:	string := "true";
		msi_support_1	:	string := "true";
		msi_support_2	:	string := "true";
		msi_support_3	:	string := "true";
		msi_support_4	:	string := "true";
		msi_support_5	:	string := "true";
		msi_support_6	:	string := "true";
		msi_support_7	:	string := "true";
		msix_pba_bir_0	:	string := "msix_pba_bir";
		msix_pba_bir_1	:	string := "msix_pba_bir";
		msix_pba_bir_2	:	string := "msix_pba_bir";
		msix_pba_bir_3	:	string := "msix_pba_bir";
		msix_pba_bir_4	:	string := "msix_pba_bir";
		msix_pba_bir_5	:	string := "msix_pba_bir";
		msix_pba_bir_6	:	string := "msix_pba_bir";
		msix_pba_bir_7	:	string := "msix_pba_bir";
		msix_pba_bir_data_0	:	std_logic_vector(2 downto 0) := "000";
		msix_pba_bir_data_1	:	std_logic_vector(2 downto 0) := "000";
		msix_pba_bir_data_2	:	std_logic_vector(2 downto 0) := "000";
		msix_pba_bir_data_3	:	std_logic_vector(2 downto 0) := "000";
		msix_pba_bir_data_4	:	std_logic_vector(2 downto 0) := "000";
		msix_pba_bir_data_5	:	std_logic_vector(2 downto 0) := "000";
		msix_pba_bir_data_6	:	std_logic_vector(2 downto 0) := "000";
		msix_pba_bir_data_7	:	std_logic_vector(2 downto 0) := "000";
		msix_pba_offset_0	:	string := "msix_pba_offset";
		msix_pba_offset_1	:	string := "msix_pba_offset";
		msix_pba_offset_2	:	string := "msix_pba_offset";
		msix_pba_offset_3	:	string := "msix_pba_offset";
		msix_pba_offset_4	:	string := "msix_pba_offset";
		msix_pba_offset_5	:	string := "msix_pba_offset";
		msix_pba_offset_6	:	string := "msix_pba_offset";
		msix_pba_offset_7	:	string := "msix_pba_offset";
		msix_pba_offset_data_0	:	std_logic_vector(28 downto 0) := "00000000000000000000000000000";
		msix_pba_offset_data_1	:	std_logic_vector(28 downto 0) := "00000000000000000000000000000";
		msix_pba_offset_data_2	:	std_logic_vector(28 downto 0) := "00000000000000000000000000000";
		msix_pba_offset_data_3	:	std_logic_vector(28 downto 0) := "00000000000000000000000000000";
		msix_pba_offset_data_4	:	std_logic_vector(28 downto 0) := "00000000000000000000000000000";
		msix_pba_offset_data_5	:	std_logic_vector(28 downto 0) := "00000000000000000000000000000";
		msix_pba_offset_data_6	:	std_logic_vector(28 downto 0) := "00000000000000000000000000000";
		msix_pba_offset_data_7	:	std_logic_vector(28 downto 0) := "00000000000000000000000000000";
		msix_table_bir_0	:	string := "msix_table_bir";
		msix_table_bir_1	:	string := "msix_table_bir";
		msix_table_bir_2	:	string := "msix_table_bir";
		msix_table_bir_3	:	string := "msix_table_bir";
		msix_table_bir_4	:	string := "msix_table_bir";
		msix_table_bir_5	:	string := "msix_table_bir";
		msix_table_bir_6	:	string := "msix_table_bir";
		msix_table_bir_7	:	string := "msix_table_bir";
		msix_table_bir_data_0	:	std_logic_vector(2 downto 0) := "000";
		msix_table_bir_data_1	:	std_logic_vector(2 downto 0) := "000";
		msix_table_bir_data_2	:	std_logic_vector(2 downto 0) := "000";
		msix_table_bir_data_3	:	std_logic_vector(2 downto 0) := "000";
		msix_table_bir_data_4	:	std_logic_vector(2 downto 0) := "000";
		msix_table_bir_data_5	:	std_logic_vector(2 downto 0) := "000";
		msix_table_bir_data_6	:	std_logic_vector(2 downto 0) := "000";
		msix_table_bir_data_7	:	std_logic_vector(2 downto 0) := "000";
		msix_table_offset_0	:	string := "msix_table_offset";
		msix_table_offset_1	:	string := "msix_table_offset";
		msix_table_offset_2	:	string := "msix_table_offset";
		msix_table_offset_3	:	string := "msix_table_offset";
		msix_table_offset_4	:	string := "msix_table_offset";
		msix_table_offset_5	:	string := "msix_table_offset";
		msix_table_offset_6	:	string := "msix_table_offset";
		msix_table_offset_7	:	string := "msix_table_offset";
		msix_table_offset_data_0	:	std_logic_vector(28 downto 0) := "00000000000000000000000000000";
		msix_table_offset_data_1	:	std_logic_vector(28 downto 0) := "00000000000000000000000000000";
		msix_table_offset_data_2	:	std_logic_vector(28 downto 0) := "00000000000000000000000000000";
		msix_table_offset_data_3	:	std_logic_vector(28 downto 0) := "00000000000000000000000000000";
		msix_table_offset_data_4	:	std_logic_vector(28 downto 0) := "00000000000000000000000000000";
		msix_table_offset_data_5	:	std_logic_vector(28 downto 0) := "00000000000000000000000000000";
		msix_table_offset_data_6	:	std_logic_vector(28 downto 0) := "00000000000000000000000000000";
		msix_table_offset_data_7	:	std_logic_vector(28 downto 0) := "00000000000000000000000000000";
		msix_table_size_0	:	string := "msix_table_size";
		msix_table_size_1	:	string := "msix_table_size";
		msix_table_size_2	:	string := "msix_table_size";
		msix_table_size_3	:	string := "msix_table_size";
		msix_table_size_4	:	string := "msix_table_size";
		msix_table_size_5	:	string := "msix_table_size";
		msix_table_size_6	:	string := "msix_table_size";
		msix_table_size_7	:	string := "msix_table_size";
		msix_table_size_data_0	:	std_logic_vector(10 downto 0) := "00000000000";
		msix_table_size_data_1	:	std_logic_vector(10 downto 0) := "00000000000";
		msix_table_size_data_2	:	std_logic_vector(10 downto 0) := "00000000000";
		msix_table_size_data_3	:	std_logic_vector(10 downto 0) := "00000000000";
		msix_table_size_data_4	:	std_logic_vector(10 downto 0) := "00000000000";
		msix_table_size_data_5	:	std_logic_vector(10 downto 0) := "00000000000";
		msix_table_size_data_6	:	std_logic_vector(10 downto 0) := "00000000000";
		msix_table_size_data_7	:	std_logic_vector(10 downto 0) := "00000000000";
		multi_function	:	string := "one_func";
		national_inst_thru_enhance	:	string := "true";
		no_command_completed_0	:	string := "true";
		no_command_completed_1	:	string := "true";
		no_command_completed_2	:	string := "true";
		no_command_completed_3	:	string := "true";
		no_command_completed_4	:	string := "true";
		no_command_completed_5	:	string := "true";
		no_command_completed_6	:	string := "true";
		no_command_completed_7	:	string := "true";
		no_soft_reset_0	:	string := "false";
		no_soft_reset_1	:	string := "false";
		no_soft_reset_2	:	string := "false";
		no_soft_reset_3	:	string := "false";
		no_soft_reset_4	:	string := "false";
		no_soft_reset_5	:	string := "false";
		no_soft_reset_6	:	string := "false";
		no_soft_reset_7	:	string := "false";
		pcie_mode	:	string := "shared_mode";
		pcie_spec_1p0_compliance	:	string := "spec_1p1";
		pcie_spec_version_0	:	string := "v2";
		pcie_spec_version_1	:	string := "v2";
		pcie_spec_version_2	:	string := "v2";
		pcie_spec_version_3	:	string := "v2";
		pcie_spec_version_4	:	string := "v2";
		pcie_spec_version_5	:	string := "v2";
		pcie_spec_version_6	:	string := "v2";
		pcie_spec_version_7	:	string := "v2";
		pclk_out_sel	:	string := "pclk";
		pipex1_debug_sel	:	string := "disable";
		plniotri_gate	:	string := "disable";
		port_link_number	:	string := "port_link_number";
		port_link_number_data	:	std_logic_vector(7 downto 0) := "00000001";
		porttype_func0	:	string := "shared_mode";
		porttype_func1	:	string := "shared_mode";
		porttype_func2	:	string := "shared_mode";
		porttype_func3	:	string := "shared_mode";
		porttype_func4	:	string := "shared_mode";
		porttype_func5	:	string := "shared_mode";
		porttype_func6	:	string := "shared_mode";
		porttype_func7	:	string := "shared_mode";
		power_isolation_en_1	:	string := "power_isolation_dis";
		power_isolation_en_1_data	:	std_logic_vector(0 downto 0) := "0";
		power_isolation_en_2	:	string := "power_isolation_dis";
		power_isolation_en_2_data	:	std_logic_vector(0 downto 0) := "0";
		power_isolation_en_3	:	string := "power_isolation_dis";
		power_isolation_en_3_data	:	std_logic_vector(0 downto 0) := "0";
		power_isolation_en_4	:	string := "power_isolation_dis";
		power_isolation_en_4_data	:	std_logic_vector(0 downto 0) := "0";
		power_isolation_en_5	:	string := "power_isolation_dis";
		power_isolation_en_5_data	:	std_logic_vector(0 downto 0) := "0";
		power_isolation_en_6	:	string := "power_isolation_dis";
		power_isolation_en_6_data	:	std_logic_vector(0 downto 0) := "0";
		prefetchable_mem_window_addr_width_0	:	string := "prefetch_32";
		prefetchable_mem_window_addr_width_1	:	string := "prefetch_32";
		prefetchable_mem_window_addr_width_2	:	string := "prefetch_32";
		prefetchable_mem_window_addr_width_3	:	string := "prefetch_32";
		prefetchable_mem_window_addr_width_4	:	string := "prefetch_32";
		prefetchable_mem_window_addr_width_5	:	string := "prefetch_32";
		prefetchable_mem_window_addr_width_6	:	string := "prefetch_32";
		prefetchable_mem_window_addr_width_7	:	string := "prefetch_32";
		prot_mode	:	string := "disabled_prot_mode";
		register_pipe_signals	:	string := "false";
		retry_buffer_last_active_address	:	string := "retry_buffer_last_active_address";
		retry_buffer_last_active_address_data	:	std_logic_vector(7 downto 0) := "11111111";
		retry_buffer_memory_settings	:	string := "retry_buffer_memory_settings";
		retry_buffer_memory_settings_data	:	std_logic_vector(15 downto 0) := "0000000000000110";
		revision_id_0	:	string := "revision_id";
		revision_id_1	:	string := "revision_id";
		revision_id_2	:	string := "revision_id";
		revision_id_3	:	string := "revision_id";
		revision_id_4	:	string := "revision_id";
		revision_id_5	:	string := "revision_id";
		revision_id_6	:	string := "revision_id";
		revision_id_7	:	string := "revision_id";
		revision_id_data_0	:	std_logic_vector(7 downto 0) := "00000001";
		revision_id_data_1	:	std_logic_vector(7 downto 0) := "00000001";
		revision_id_data_2	:	std_logic_vector(7 downto 0) := "00000001";
		revision_id_data_3	:	std_logic_vector(7 downto 0) := "00000001";
		revision_id_data_4	:	std_logic_vector(7 downto 0) := "00000001";
		revision_id_data_5	:	std_logic_vector(7 downto 0) := "00000001";
		revision_id_data_6	:	std_logic_vector(7 downto 0) := "00000001";
		revision_id_data_7	:	std_logic_vector(7 downto 0) := "00000001";
		role_based_error_reporting_0	:	string := "false";
		role_based_error_reporting_1	:	string := "false";
		role_based_error_reporting_2	:	string := "false";
		role_based_error_reporting_3	:	string := "false";
		role_based_error_reporting_4	:	string := "false";
		role_based_error_reporting_5	:	string := "false";
		role_based_error_reporting_6	:	string := "false";
		role_based_error_reporting_7	:	string := "false";
		rstctrl_1ms_count_fref_clk	:	string := "rstctrl_1ms_cnt";
		rstctrl_1ms_count_fref_clk_value	:	std_logic_vector(19 downto 0) := "00001111010000100100";
		rstctrl_1us_count_fref_clk	:	string := "rstctrl_1us_cnt";
		rstctrl_1us_count_fref_clk_value	:	std_logic_vector(19 downto 0) := "00000000000000111111";
		rstctrl_altpe2_crst_n_inv	:	string := "false";
		rstctrl_altpe2_rst_n_inv	:	string := "false";
		rstctrl_altpe2_srst_n_inv	:	string := "false";
		rstctrl_debug_en	:	string := "false";
		rstctrl_force_inactive_rst	:	string := "false";
		rstctrl_fref_clk_select	:	string := "ch0_sel";
		rstctrl_hard_block_enable	:	string := "hard_rst_ctl";
		rstctrl_hip_ep	:	string := "hip_ep";
		rstctrl_ltssm_disable	:	string := "disable";
		rstctrl_mask_tx_pll_lock_select	:	string := "not_active";
		rstctrl_off_cal_done_select	:	string := "not_active";
		rstctrl_off_cal_en_select	:	string := "not_active";
		rstctrl_perst_enable	:	string := "level";
		rstctrl_perstn_select	:	string := "perstn_pin";
		rstctrl_pld_clr	:	string := "false";
		rstctrl_rx_pcs_rst_n_inv	:	string := "false";
		rstctrl_rx_pcs_rst_n_select	:	string := "not_active";
		rstctrl_rx_pll_freq_lock_select	:	string := "not_active";
		rstctrl_rx_pll_lock_select	:	string := "not_active";
		rstctrl_rx_pma_rstb_cmu_select	:	string := "not_active";
		rstctrl_rx_pma_rstb_inv	:	string := "false";
		rstctrl_rx_pma_rstb_select	:	string := "not_active";
		rstctrl_timer_a	:	string := "rstctrl_timer_a";
		rstctrl_timer_a_type	:	string := "milli_secs";
		rstctrl_timer_a_value	:	std_logic_vector(7 downto 0) := "00000001";
		rstctrl_timer_b	:	string := "rstctrl_timer_b";
		rstctrl_timer_b_type	:	string := "milli_secs";
		rstctrl_timer_b_value	:	std_logic_vector(7 downto 0) := "00000001";
		rstctrl_timer_c	:	string := "rstctrl_timer_c";
		rstctrl_timer_c_type	:	string := "milli_secs";
		rstctrl_timer_c_value	:	std_logic_vector(7 downto 0) := "00000001";
		rstctrl_timer_d	:	string := "rstctrl_timer_d";
		rstctrl_timer_d_type	:	string := "milli_secs";
		rstctrl_timer_d_value	:	std_logic_vector(7 downto 0) := "00000001";
		rstctrl_timer_e	:	string := "rstctrl_timer_e";
		rstctrl_timer_e_type	:	string := "milli_secs";
		rstctrl_timer_e_value	:	std_logic_vector(7 downto 0) := "00000001";
		rstctrl_timer_f	:	string := "rstctrl_timer_f";
		rstctrl_timer_f_type	:	string := "milli_secs";
		rstctrl_timer_f_value	:	std_logic_vector(7 downto 0) := "00000001";
		rstctrl_timer_g	:	string := "rstctrl_timer_g";
		rstctrl_timer_g_type	:	string := "milli_secs";
		rstctrl_timer_g_value	:	std_logic_vector(7 downto 0) := "00000001";
		rstctrl_timer_h	:	string := "rstctrl_timer_h";
		rstctrl_timer_h_type	:	string := "milli_secs";
		rstctrl_timer_h_value	:	std_logic_vector(7 downto 0) := "00000001";
		rstctrl_timer_i	:	string := "rstctrl_timer_i";
		rstctrl_timer_i_type	:	string := "milli_secs";
		rstctrl_timer_i_value	:	std_logic_vector(7 downto 0) := "00000001";
		rstctrl_timer_j	:	string := "rstctrl_timer_j";
		rstctrl_timer_j_type	:	string := "milli_secs";
		rstctrl_timer_j_value	:	std_logic_vector(7 downto 0) := "00000001";
		rstctrl_tx_cmu_pll_lock_select	:	string := "not_active";
		rstctrl_tx_lc_pll_lock_select	:	string := "not_active";
		rstctrl_tx_lc_pll_rstb_select	:	string := "not_active";
		rstctrl_tx_pcs_rst_n_inv	:	string := "false";
		rstctrl_tx_pcs_rst_n_select	:	string := "not_active";
		rstctrl_tx_pma_rstb_inv	:	string := "false";
		rstctrl_tx_pma_syncp_inv	:	string := "false";
		rstctrl_tx_pma_syncp_select	:	string := "not_active";
		rx_cdc_almost_full	:	string := "rx_cdc_almost_full";
		rx_cdc_almost_full_data	:	std_logic_vector(3 downto 0) := "1100";
		rx_ei_l0s_0	:	string := "disable";
		rx_ei_l0s_1	:	string := "disable";
		rx_ei_l0s_2	:	string := "disable";
		rx_ei_l0s_3	:	string := "disable";
		rx_ei_l0s_4	:	string := "disable";
		rx_ei_l0s_5	:	string := "disable";
		rx_ei_l0s_6	:	string := "disable";
		rx_ei_l0s_7	:	string := "disable";
		rx_l0s_count_idl	:	string := "rx_l0s_count_idl";
		rx_l0s_count_idl_data	:	std_logic_vector(7 downto 0) := "00000000";
		rx_ptr0_nonposted_dpram_max	:	string := "rx_ptr0_nonposted_dpram_max";
		rx_ptr0_nonposted_dpram_max_data	:	std_logic_vector(9 downto 0) := "0000000000";
		rx_ptr0_nonposted_dpram_min	:	string := "rx_ptr0_nonposted_dpram_min";
		rx_ptr0_nonposted_dpram_min_data	:	std_logic_vector(9 downto 0) := "0000000000";
		rx_ptr0_posted_dpram_max	:	string := "rx_ptr0_posted_dpram_max";
		rx_ptr0_posted_dpram_max_data	:	std_logic_vector(9 downto 0) := "0000000000";
		rx_ptr0_posted_dpram_min	:	string := "rx_ptr0_posted_dpram_min";
		rx_ptr0_posted_dpram_min_data	:	std_logic_vector(9 downto 0) := "0000000000";
		rxfreqlk_cnt	:	string := "rxfreqlk_prog_cnt";
		rxfreqlk_cnt_data	:	std_logic_vector(19 downto 0) := "00000000000000000000";
		rxfreqlk_cnt_en	:	string := "true";
		sameclock_nfts_count_0	:	string := "sameclock_nfts_count";
		sameclock_nfts_count_1	:	string := "sameclock_nfts_count";
		sameclock_nfts_count_2	:	string := "sameclock_nfts_count";
		sameclock_nfts_count_3	:	string := "sameclock_nfts_count";
		sameclock_nfts_count_4	:	string := "sameclock_nfts_count";
		sameclock_nfts_count_5	:	string := "sameclock_nfts_count";
		sameclock_nfts_count_6	:	string := "sameclock_nfts_count";
		sameclock_nfts_count_7	:	string := "sameclock_nfts_count";
		sameclock_nfts_count_data_0	:	std_logic_vector(7 downto 0) := "00000000";
		sameclock_nfts_count_data_1	:	std_logic_vector(7 downto 0) := "00000000";
		sameclock_nfts_count_data_2	:	std_logic_vector(7 downto 0) := "00000000";
		sameclock_nfts_count_data_3	:	std_logic_vector(7 downto 0) := "00000000";
		sameclock_nfts_count_data_4	:	std_logic_vector(7 downto 0) := "00000000";
		sameclock_nfts_count_data_5	:	std_logic_vector(7 downto 0) := "00000000";
		sameclock_nfts_count_data_6	:	std_logic_vector(7 downto 0) := "00000000";
		sameclock_nfts_count_data_7	:	std_logic_vector(7 downto 0) := "00000000";
		single_rx_detect	:	string := "single_rx_detect";
		single_rx_detect_data	:	std_logic_vector(3 downto 0) := "0000";
		skp_insertion_control	:	string := "disable";
		skp_os_schedule_count	:	string := "skp_os_schedule_count";
		skp_os_schedule_count_data	:	std_logic_vector(10 downto 0) := "00000000000";
		slot_number_0	:	string := "slot_number";
		slot_number_1	:	string := "slot_number";
		slot_number_2	:	string := "slot_number";
		slot_number_3	:	string := "slot_number";
		slot_number_4	:	string := "slot_number";
		slot_number_5	:	string := "slot_number";
		slot_number_6	:	string := "slot_number";
		slot_number_7	:	string := "slot_number";
		slot_number_data_0	:	std_logic_vector(12 downto 0) := "0000000000000";
		slot_number_data_1	:	std_logic_vector(12 downto 0) := "0000000000000";
		slot_number_data_2	:	std_logic_vector(12 downto 0) := "0000000000000";
		slot_number_data_3	:	std_logic_vector(12 downto 0) := "0000000000000";
		slot_number_data_4	:	std_logic_vector(12 downto 0) := "0000000000000";
		slot_number_data_5	:	std_logic_vector(12 downto 0) := "0000000000000";
		slot_number_data_6	:	std_logic_vector(12 downto 0) := "0000000000000";
		slot_number_data_7	:	std_logic_vector(12 downto 0) := "0000000000000";
		slot_power_limit_0	:	string := "slot_power_limit";
		slot_power_limit_1	:	string := "slot_power_limit";
		slot_power_limit_2	:	string := "slot_power_limit";
		slot_power_limit_3	:	string := "slot_power_limit";
		slot_power_limit_4	:	string := "slot_power_limit";
		slot_power_limit_5	:	string := "slot_power_limit";
		slot_power_limit_6	:	string := "slot_power_limit";
		slot_power_limit_7	:	string := "slot_power_limit";
		slot_power_limit_data_0	:	std_logic_vector(7 downto 0) := "00000000";
		slot_power_limit_data_1	:	std_logic_vector(7 downto 0) := "00000000";
		slot_power_limit_data_2	:	std_logic_vector(7 downto 0) := "00000000";
		slot_power_limit_data_3	:	std_logic_vector(7 downto 0) := "00000000";
		slot_power_limit_data_4	:	std_logic_vector(7 downto 0) := "00000000";
		slot_power_limit_data_5	:	std_logic_vector(7 downto 0) := "00000000";
		slot_power_limit_data_6	:	std_logic_vector(7 downto 0) := "00000000";
		slot_power_limit_data_7	:	std_logic_vector(7 downto 0) := "00000000";
		slot_power_scale_0	:	string := "slot_power_scale";
		slot_power_scale_1	:	string := "slot_power_scale";
		slot_power_scale_2	:	string := "slot_power_scale";
		slot_power_scale_3	:	string := "slot_power_scale";
		slot_power_scale_4	:	string := "slot_power_scale";
		slot_power_scale_5	:	string := "slot_power_scale";
		slot_power_scale_6	:	string := "slot_power_scale";
		slot_power_scale_7	:	string := "slot_power_scale";
		slot_power_scale_data_0	:	std_logic_vector(1 downto 0) := "00";
		slot_power_scale_data_1	:	std_logic_vector(1 downto 0) := "00";
		slot_power_scale_data_2	:	std_logic_vector(1 downto 0) := "00";
		slot_power_scale_data_3	:	std_logic_vector(1 downto 0) := "00";
		slot_power_scale_data_4	:	std_logic_vector(1 downto 0) := "00";
		slot_power_scale_data_5	:	std_logic_vector(1 downto 0) := "00";
		slot_power_scale_data_6	:	std_logic_vector(1 downto 0) := "00";
		slot_power_scale_data_7	:	std_logic_vector(1 downto 0) := "00";
		slotclk_cfg	:	string := "dynamic_slotclkcfg";
		ssid_0	:	string := "ssid";
		ssid_1	:	string := "ssid";
		ssid_2	:	string := "ssid";
		ssid_3	:	string := "ssid";
		ssid_4	:	string := "ssid";
		ssid_5	:	string := "ssid";
		ssid_6	:	string := "ssid";
		ssid_7	:	string := "ssid";
		ssid_data_0	:	std_logic_vector(15 downto 0) := "0000000000000000";
		ssid_data_1	:	std_logic_vector(15 downto 0) := "0000000000000000";
		ssid_data_2	:	std_logic_vector(15 downto 0) := "0000000000000000";
		ssid_data_3	:	std_logic_vector(15 downto 0) := "0000000000000000";
		ssid_data_4	:	std_logic_vector(15 downto 0) := "0000000000000000";
		ssid_data_5	:	std_logic_vector(15 downto 0) := "0000000000000000";
		ssid_data_6	:	std_logic_vector(15 downto 0) := "0000000000000000";
		ssid_data_7	:	std_logic_vector(15 downto 0) := "0000000000000000";
		ssvid_0	:	string := "ssvid";
		ssvid_1	:	string := "ssvid";
		ssvid_2	:	string := "ssvid";
		ssvid_3	:	string := "ssvid";
		ssvid_4	:	string := "ssvid";
		ssvid_5	:	string := "ssvid";
		ssvid_6	:	string := "ssvid";
		ssvid_7	:	string := "ssvid";
		ssvid_data_0	:	std_logic_vector(15 downto 0) := "0000000000000000";
		ssvid_data_1	:	std_logic_vector(15 downto 0) := "0000000000000000";
		ssvid_data_2	:	std_logic_vector(15 downto 0) := "0000000000000000";
		ssvid_data_3	:	std_logic_vector(15 downto 0) := "0000000000000000";
		ssvid_data_4	:	std_logic_vector(15 downto 0) := "0000000000000000";
		ssvid_data_5	:	std_logic_vector(15 downto 0) := "0000000000000000";
		ssvid_data_6	:	std_logic_vector(15 downto 0) := "0000000000000000";
		ssvid_data_7	:	std_logic_vector(15 downto 0) := "0000000000000000";
		subsystem_device_id_0	:	string := "subsystem_device_id";
		subsystem_device_id_1	:	string := "subsystem_device_id";
		subsystem_device_id_2	:	string := "subsystem_device_id";
		subsystem_device_id_3	:	string := "subsystem_device_id";
		subsystem_device_id_4	:	string := "subsystem_device_id";
		subsystem_device_id_5	:	string := "subsystem_device_id";
		subsystem_device_id_6	:	string := "subsystem_device_id";
		subsystem_device_id_7	:	string := "subsystem_device_id";
		subsystem_device_id_data_0	:	std_logic_vector(15 downto 0) := "0000000000000001";
		subsystem_device_id_data_1	:	std_logic_vector(15 downto 0) := "0000000000000001";
		subsystem_device_id_data_2	:	std_logic_vector(15 downto 0) := "0000000000000001";
		subsystem_device_id_data_3	:	std_logic_vector(15 downto 0) := "0000000000000001";
		subsystem_device_id_data_4	:	std_logic_vector(15 downto 0) := "0000000000000001";
		subsystem_device_id_data_5	:	std_logic_vector(15 downto 0) := "0000000000000001";
		subsystem_device_id_data_6	:	std_logic_vector(15 downto 0) := "0000000000000001";
		subsystem_device_id_data_7	:	std_logic_vector(15 downto 0) := "0000000000000001";
		subsystem_vendor_id_0	:	string := "subsystem_vendor_id";
		subsystem_vendor_id_1	:	string := "subsystem_vendor_id";
		subsystem_vendor_id_2	:	string := "subsystem_vendor_id";
		subsystem_vendor_id_3	:	string := "subsystem_vendor_id";
		subsystem_vendor_id_4	:	string := "subsystem_vendor_id";
		subsystem_vendor_id_5	:	string := "subsystem_vendor_id";
		subsystem_vendor_id_6	:	string := "subsystem_vendor_id";
		subsystem_vendor_id_7	:	string := "subsystem_vendor_id";
		subsystem_vendor_id_data_0	:	std_logic_vector(15 downto 0) := "0001000101110010";
		subsystem_vendor_id_data_1	:	std_logic_vector(15 downto 0) := "0001000101110010";
		subsystem_vendor_id_data_2	:	std_logic_vector(15 downto 0) := "0001000101110010";
		subsystem_vendor_id_data_3	:	std_logic_vector(15 downto 0) := "0001000101110010";
		subsystem_vendor_id_data_4	:	std_logic_vector(15 downto 0) := "0001000101110010";
		subsystem_vendor_id_data_5	:	std_logic_vector(15 downto 0) := "0001000101110010";
		subsystem_vendor_id_data_6	:	std_logic_vector(15 downto 0) := "0001000101110010";
		subsystem_vendor_id_data_7	:	std_logic_vector(15 downto 0) := "0001000101110010";
		sup_mode	:	string := "user_mode";
		surprise_down_error_support_0	:	string := "false";
		surprise_down_error_support_1	:	string := "false";
		surprise_down_error_support_2	:	string := "false";
		surprise_down_error_support_3	:	string := "false";
		surprise_down_error_support_4	:	string := "false";
		surprise_down_error_support_5	:	string := "false";
		surprise_down_error_support_6	:	string := "false";
		surprise_down_error_support_7	:	string := "false";
		testmode_control	:	string := "disable";
		tx_cdc_almost_full	:	string := "tx_cdc_almost_full";
		tx_cdc_almost_full_data	:	std_logic_vector(3 downto 0) := "1100";
		tx_l0s_adjust	:	string := "disable";
		tx_swing	:	string := "tx_swing";
		tx_swing_data	:	std_logic_vector(7 downto 0) := "00000000";
		use_aer_0	:	string := "false";
		use_aer_1	:	string := "false";
		use_aer_2	:	string := "false";
		use_aer_3	:	string := "false";
		use_aer_4	:	string := "false";
		use_aer_5	:	string := "false";
		use_aer_6	:	string := "false";
		use_aer_7	:	string := "false";
		use_crc_forwarding	:	string := "false";
		user_id	:	string := "user_id";
		user_id_data	:	std_logic_vector(15 downto 0) := "0000000000000000";
		vc0_clk_enable	:	string := "true";
		vc0_rx_buffer_memory_settings	:	string := "vc0_rx_buffer_memory_settings";
		vc0_rx_buffer_memory_settings_data	:	std_logic_vector(15 downto 0) := "0000000000000110";
		vc0_rx_flow_ctrl_compl_data	:	string := "vc0_rx_flow_ctrl_compl_data";
		vc0_rx_flow_ctrl_compl_data_data	:	std_logic_vector(11 downto 0) := "000000000000";
		vc0_rx_flow_ctrl_compl_header	:	string := "vc0_rx_flow_ctrl_compl_header";
		vc0_rx_flow_ctrl_compl_header_data	:	std_logic_vector(7 downto 0) := "00000000";
		vc0_rx_flow_ctrl_nonposted_data	:	string := "vc0_rx_flow_ctrl_nonposted_data";
		vc0_rx_flow_ctrl_nonposted_data_data	:	std_logic_vector(7 downto 0) := "00000000";
		vc0_rx_flow_ctrl_nonposted_header	:	string := "vc0_rx_flow_ctrl_nonposted_header";
		vc0_rx_flow_ctrl_nonposted_header_data	:	std_logic_vector(7 downto 0) := "00100000";
		vc0_rx_flow_ctrl_posted_data	:	string := "vc0_rx_flow_ctrl_posted_data";
		vc0_rx_flow_ctrl_posted_data_data	:	std_logic_vector(11 downto 0) := "000001011110";
		vc0_rx_flow_ctrl_posted_header	:	string := "vc0_rx_flow_ctrl_posted_header";
		vc0_rx_flow_ctrl_posted_header_data	:	std_logic_vector(7 downto 0) := "00010010";
		vc1_clk_enable	:	string := "false";
		vc_arbitration_0	:	string := "single_vc";
		vc_arbitration_1	:	string := "single_vc";
		vc_arbitration_2	:	string := "single_vc";
		vc_arbitration_3	:	string := "single_vc";
		vc_arbitration_4	:	string := "single_vc";
		vc_arbitration_5	:	string := "single_vc";
		vc_arbitration_6	:	string := "single_vc";
		vc_arbitration_7	:	string := "single_vc";
		vc_enable	:	string := "single_vc";
		vendor_id_0	:	string := "vendor_id";
		vendor_id_1	:	string := "vendor_id";
		vendor_id_2	:	string := "vendor_id";
		vendor_id_3	:	string := "vendor_id";
		vendor_id_4	:	string := "vendor_id";
		vendor_id_5	:	string := "vendor_id";
		vendor_id_6	:	string := "vendor_id";
		vendor_id_7	:	string := "vendor_id";
		vendor_id_data_0	:	std_logic_vector(15 downto 0) := "0001000101110010";
		vendor_id_data_1	:	std_logic_vector(15 downto 0) := "0001000101110010";
		vendor_id_data_2	:	std_logic_vector(15 downto 0) := "0001000101110010";
		vendor_id_data_3	:	std_logic_vector(15 downto 0) := "0001000101110010";
		vendor_id_data_4	:	std_logic_vector(15 downto 0) := "0001000101110010";
		vendor_id_data_5	:	std_logic_vector(15 downto 0) := "0001000101110010";
		vendor_id_data_6	:	std_logic_vector(15 downto 0) := "0001000101110010";
		vendor_id_data_7	:	std_logic_vector(15 downto 0) := "0001000101110010";
		vsec_cap	:	string := "vsec_cap";
		vsec_cap_data	:	std_logic_vector(3 downto 0) := "0000";
		vsec_id	:	string := "vsec_id";
		vsec_id_data	:	std_logic_vector(15 downto 0) := "0001000101110010"	);
	port(
		avmmaddress	:	in std_logic_vector(9 downto 0) := (others => '0');
		avmmbyteen	:	in std_logic_vector(1 downto 0) := (others => '0');
		avmmclk	:	in std_logic := '0';
		avmmread	:	in std_logic := '0';
		avmmreaddata	:	out std_logic_vector(15 downto 0);
		avmmrstn	:	in std_logic := '0';
		avmmwrite	:	in std_logic := '0';
		avmmwritedata	:	in std_logic_vector(15 downto 0) := (others => '0');
		bistdonearcv0	:	out std_logic;
		bistdonearcv1	:	out std_logic;
		bistdonearpl	:	out std_logic;
		bistdonebrcv0	:	out std_logic;
		bistdonebrcv1	:	out std_logic;
		bistdonebrpl	:	out std_logic;
		bistenn	:	in std_logic := '0';
		bistpassrcv0	:	out std_logic;
		bistpassrcv1	:	out std_logic;
		bistpassrpl	:	out std_logic;
		bistscanenn	:	in std_logic := '0';
		bistscanin	:	in std_logic := '0';
		bistscanoutrcv0	:	out std_logic;
		bistscanoutrcv1	:	out std_logic;
		bistscanoutrpl	:	out std_logic;
		bisttestenn	:	in std_logic := '0';
		cbhipmdioen	:	in std_logic := '0';
		clrrxpath	:	out std_logic;
		coreclkin	:	in std_logic := '0';
		coreclkout	:	out std_logic;
		corecrst	:	in std_logic := '0';
		corepor	:	in std_logic := '0';
		corerst	:	in std_logic := '0';
		coresrst	:	in std_logic := '0';
		cplerr	:	in std_logic_vector(6 downto 0) := (others => '0');
		cplerrfunc	:	in std_logic_vector(2 downto 0) := (others => '0');
		cplpending	:	in std_logic_vector(7 downto 0) := (others => '0');
		csrcbdin	:	in std_logic := '0';
		csrclk	:	in std_logic := '0';
		csrdin	:	in std_logic := '0';
		csrdout	:	out std_logic;
		csren	:	in std_logic := '0';
		csrenscan	:	in std_logic := '0';
		csrin	:	in std_logic := '0';
		csrloadcsr	:	in std_logic := '0';
		csrout	:	out std_logic;
		csrpipein	:	in std_logic := '0';
		csrpipeout	:	out std_logic;
		csrseg	:	in std_logic := '0';
		csrtcsrin	:	in std_logic := '0';
		csrtverify	:	in std_logic := '0';
		cvpclk	:	out std_logic;
		cvpconfig	:	out std_logic;
		cvpconfigdone	:	in std_logic := '0';
		cvpconfigerror	:	in std_logic := '0';
		cvpconfigready	:	in std_logic := '0';
		cvpdata	:	out std_logic_vector(31 downto 0);
		cvpen	:	in std_logic := '0';
		cvpfullconfig	:	out std_logic;
		cvpstartxfer	:	out std_logic;
		dbgpipex1rx	:	in std_logic_vector(14 downto 0) := (others => '0');
		derrcorextrcv0	:	out std_logic;
		derrcorextrcv1	:	out std_logic;
		derrcorextrpl	:	out std_logic;
		derrrpl	:	out std_logic;
		dlcomclkreg	:	in std_logic := '0';
		dlctrllink2	:	in std_logic_vector(12 downto 0) := (others => '0');
		dlcurrentspeed	:	out std_logic_vector(1 downto 0);
		dlltssm	:	out std_logic_vector(4 downto 0);
		dlupexit	:	out std_logic;
		dlvcctrl	:	in std_logic_vector(7 downto 0) := (others => '0');
		dpriorefclkdig	:	in std_logic := '0';
		eidleinfersel0	:	out std_logic_vector(2 downto 0);
		eidleinfersel1	:	out std_logic_vector(2 downto 0);
		eidleinfersel2	:	out std_logic_vector(2 downto 0);
		eidleinfersel3	:	out std_logic_vector(2 downto 0);
		eidleinfersel4	:	out std_logic_vector(2 downto 0);
		eidleinfersel5	:	out std_logic_vector(2 downto 0);
		eidleinfersel6	:	out std_logic_vector(2 downto 0);
		eidleinfersel7	:	out std_logic_vector(2 downto 0);
		entest	:	in std_logic := '0';
		ev128ns	:	out std_logic;
		ev1us	:	out std_logic;
		flrreset	:	in std_logic_vector(7 downto 0) := (others => '0');
		flrsts	:	out std_logic_vector(7 downto 0);
		frefclk0	:	in std_logic := '0';
		frefclk1	:	in std_logic := '0';
		frefclk2	:	in std_logic := '0';
		frefclk3	:	in std_logic := '0';
		frefclk4	:	in std_logic := '0';
		frefclk5	:	in std_logic := '0';
		frefclk6	:	in std_logic := '0';
		frefclk7	:	in std_logic := '0';
		frefclk8	:	in std_logic := '0';
		frzlogic	:	in std_logic := '0';
		frzreg	:	in std_logic := '0';
		hipextraclkin	:	in std_logic_vector(1 downto 0) := (others => '0');
		hipextraclkout	:	out std_logic_vector(1 downto 0);
		hipextrain	:	in std_logic_vector(29 downto 0) := (others => '0');
		hipextraout	:	out std_logic_vector(29 downto 0);
		hippartialreconfign	:	in std_logic := '0';
		hotrstexit	:	out std_logic;
		interfacesel	:	in std_logic := '0';
		intstatus	:	out std_logic_vector(3 downto 0);
		iocsrrdydly	:	in std_logic := '0';
		l2exit	:	out std_logic;
		laneact	:	out std_logic_vector(3 downto 0);
		lmiack	:	out std_logic;
		lmiaddr	:	in std_logic_vector(14 downto 0) := (others => '0');
		lmidin	:	in std_logic_vector(31 downto 0) := (others => '0');
		lmidout	:	out std_logic_vector(31 downto 0);
		lmirden	:	in std_logic := '0';
		lmiwren	:	in std_logic := '0';
		ltssml0state	:	out std_logic;
		mdioclk	:	in std_logic := '0';
		mdiodevaddr	:	in std_logic_vector(1 downto 0) := (others => '0');
		mdioin	:	in std_logic := '0';
		mdiooenn	:	out std_logic;
		mdioout	:	out std_logic;
		mode	:	in std_logic_vector(1 downto 0) := (others => '0');
		nfrzdrv	:	in std_logic := '0';
		pcierr	:	in std_logic_vector(15 downto 0) := (others => '0');
		pclkcentral	:	in std_logic := '0';
		pclkch0	:	in std_logic := '0';
		pclkch1	:	in std_logic := '0';
		phyrst	:	in std_logic := '0';
		physrst	:	in std_logic := '0';
		phystatus0	:	in std_logic := '0';
		phystatus1	:	in std_logic := '0';
		phystatus2	:	in std_logic := '0';
		phystatus3	:	in std_logic := '0';
		phystatus4	:	in std_logic := '0';
		phystatus5	:	in std_logic := '0';
		phystatus6	:	in std_logic := '0';
		phystatus7	:	in std_logic := '0';
		pinperstn	:	in std_logic := '0';
		pldclk	:	in std_logic := '0';
		pldclkinuse	:	out std_logic;
		pldclrhipn	:	in std_logic := '0';
		pldclrpcshipn	:	in std_logic := '0';
		pldclrpmapcshipn	:	in std_logic := '0';
		pldcoreready	:	in std_logic := '0';
		pldperstn	:	in std_logic := '0';
		pldrst	:	in std_logic := '0';
		pldsrst	:	in std_logic := '0';
		pllfixedclkcentral	:	in std_logic := '0';
		pllfixedclkch0	:	in std_logic := '0';
		pllfixedclkch1	:	in std_logic := '0';
		plniotri	:	in std_logic := '0';
		por	:	in std_logic := '0';
		powerdown0	:	out std_logic_vector(1 downto 0);
		powerdown1	:	out std_logic_vector(1 downto 0);
		powerdown2	:	out std_logic_vector(1 downto 0);
		powerdown3	:	out std_logic_vector(1 downto 0);
		powerdown4	:	out std_logic_vector(1 downto 0);
		powerdown5	:	out std_logic_vector(1 downto 0);
		powerdown6	:	out std_logic_vector(1 downto 0);
		powerdown7	:	out std_logic_vector(1 downto 0);
		r2cerrext	:	out std_logic;
		rate0	:	out std_logic;
		rate1	:	out std_logic;
		rate2	:	out std_logic;
		rate3	:	out std_logic;
		rate4	:	out std_logic;
		rate5	:	out std_logic;
		rate6	:	out std_logic;
		rate7	:	out std_logic;
		rate8	:	out std_logic;
		resetstatus	:	out std_logic;
		rxbardecfuncnumvc0	:	out std_logic_vector(2 downto 0);
		rxbardecvc0	:	out std_logic_vector(7 downto 0);
		rxbevc00	:	out std_logic_vector(7 downto 0);
		rxbevc01	:	out std_logic_vector(7 downto 0);
		rxdata0	:	in std_logic_vector(7 downto 0) := (others => '0');
		rxdata1	:	in std_logic_vector(7 downto 0) := (others => '0');
		rxdata2	:	in std_logic_vector(7 downto 0) := (others => '0');
		rxdata3	:	in std_logic_vector(7 downto 0) := (others => '0');
		rxdata4	:	in std_logic_vector(7 downto 0) := (others => '0');
		rxdata5	:	in std_logic_vector(7 downto 0) := (others => '0');
		rxdata6	:	in std_logic_vector(7 downto 0) := (others => '0');
		rxdata7	:	in std_logic_vector(7 downto 0) := (others => '0');
		rxdatak0	:	in std_logic := '0';
		rxdatak1	:	in std_logic := '0';
		rxdatak2	:	in std_logic := '0';
		rxdatak3	:	in std_logic := '0';
		rxdatak4	:	in std_logic := '0';
		rxdatak5	:	in std_logic := '0';
		rxdatak6	:	in std_logic := '0';
		rxdatak7	:	in std_logic := '0';
		rxdatavc00	:	out std_logic_vector(63 downto 0);
		rxdatavc01	:	out std_logic_vector(63 downto 0);
		rxelecidle0	:	in std_logic := '0';
		rxelecidle1	:	in std_logic := '0';
		rxelecidle2	:	in std_logic := '0';
		rxelecidle3	:	in std_logic := '0';
		rxelecidle4	:	in std_logic := '0';
		rxelecidle5	:	in std_logic := '0';
		rxelecidle6	:	in std_logic := '0';
		rxelecidle7	:	in std_logic := '0';
		rxeopvc00	:	out std_logic;
		rxeopvc01	:	out std_logic;
		rxerrvc0	:	out std_logic;
		rxfifoemptyvc0	:	out std_logic;
		rxfifofullvc0	:	out std_logic;
		rxfifordpvc0	:	out std_logic_vector(3 downto 0);
		rxfifowrpvc0	:	out std_logic_vector(3 downto 0);
		rxfreqlocked0	:	in std_logic := '0';
		rxfreqlocked1	:	in std_logic := '0';
		rxfreqlocked2	:	in std_logic := '0';
		rxfreqlocked3	:	in std_logic := '0';
		rxfreqlocked4	:	in std_logic := '0';
		rxfreqlocked5	:	in std_logic := '0';
		rxfreqlocked6	:	in std_logic := '0';
		rxfreqlocked7	:	in std_logic := '0';
		rxfreqtxcmuplllock0	:	in std_logic := '0';
		rxfreqtxcmuplllock1	:	in std_logic := '0';
		rxfreqtxcmuplllock2	:	in std_logic := '0';
		rxfreqtxcmuplllock3	:	in std_logic := '0';
		rxfreqtxcmuplllock4	:	in std_logic := '0';
		rxfreqtxcmuplllock5	:	in std_logic := '0';
		rxfreqtxcmuplllock6	:	in std_logic := '0';
		rxfreqtxcmuplllock7	:	in std_logic := '0';
		rxfreqtxcmuplllock8	:	in std_logic := '0';
		rxmaskvc0	:	in std_logic := '0';
		rxpcsrstn0	:	out std_logic;
		rxpcsrstn1	:	out std_logic;
		rxpcsrstn2	:	out std_logic;
		rxpcsrstn3	:	out std_logic;
		rxpcsrstn4	:	out std_logic;
		rxpcsrstn5	:	out std_logic;
		rxpcsrstn6	:	out std_logic;
		rxpcsrstn7	:	out std_logic;
		rxpcsrstn8	:	out std_logic;
		rxpllphaselock0	:	in std_logic := '0';
		rxpllphaselock1	:	in std_logic := '0';
		rxpllphaselock2	:	in std_logic := '0';
		rxpllphaselock3	:	in std_logic := '0';
		rxpllphaselock4	:	in std_logic := '0';
		rxpllphaselock5	:	in std_logic := '0';
		rxpllphaselock6	:	in std_logic := '0';
		rxpllphaselock7	:	in std_logic := '0';
		rxpllphaselock8	:	in std_logic := '0';
		rxpmarstb0	:	out std_logic;
		rxpmarstb1	:	out std_logic;
		rxpmarstb2	:	out std_logic;
		rxpmarstb3	:	out std_logic;
		rxpmarstb4	:	out std_logic;
		rxpmarstb5	:	out std_logic;
		rxpmarstb6	:	out std_logic;
		rxpmarstb7	:	out std_logic;
		rxpmarstb8	:	out std_logic;
		rxpolarity0	:	out std_logic;
		rxpolarity1	:	out std_logic;
		rxpolarity2	:	out std_logic;
		rxpolarity3	:	out std_logic;
		rxpolarity4	:	out std_logic;
		rxpolarity5	:	out std_logic;
		rxpolarity6	:	out std_logic;
		rxpolarity7	:	out std_logic;
		rxreadyvc0	:	in std_logic := '0';
		rxsopvc00	:	out std_logic;
		rxsopvc01	:	out std_logic;
		rxstatus0	:	in std_logic_vector(2 downto 0) := (others => '0');
		rxstatus1	:	in std_logic_vector(2 downto 0) := (others => '0');
		rxstatus2	:	in std_logic_vector(2 downto 0) := (others => '0');
		rxstatus3	:	in std_logic_vector(2 downto 0) := (others => '0');
		rxstatus4	:	in std_logic_vector(2 downto 0) := (others => '0');
		rxstatus5	:	in std_logic_vector(2 downto 0) := (others => '0');
		rxstatus6	:	in std_logic_vector(2 downto 0) := (others => '0');
		rxstatus7	:	in std_logic_vector(2 downto 0) := (others => '0');
		rxvalid0	:	in std_logic := '0';
		rxvalid1	:	in std_logic := '0';
		rxvalid2	:	in std_logic := '0';
		rxvalid3	:	in std_logic := '0';
		rxvalid4	:	in std_logic := '0';
		rxvalid5	:	in std_logic := '0';
		rxvalid6	:	in std_logic := '0';
		rxvalid7	:	in std_logic := '0';
		rxvalidvc0	:	out std_logic;
		scanenn	:	in std_logic := '0';
		scanmoden	:	in std_logic := '0';
		serrout	:	out std_logic;
		sershiftload	:	in std_logic := '0';
		successfulspeednegotiationint	:	out std_logic;
		swdnin	:	in std_logic_vector(2 downto 0) := (others => '0');
		swdnwake	:	out std_logic;
		swuphotrst	:	out std_logic;
		swupin	:	in std_logic_vector(6 downto 0) := (others => '0');
		testinhip	:	in std_logic_vector(39 downto 0) := (others => '0');
		testouthip	:	out std_logic_vector(63 downto 0);
		tlaermsinum	:	in std_logic_vector(4 downto 0) := (others => '0');
		tlappintaack	:	out std_logic;
		tlappintafuncnum	:	in std_logic_vector(2 downto 0) := (others => '0');
		tlappintasts	:	in std_logic := '0';
		tlappintback	:	out std_logic;
		tlappintbfuncnum	:	in std_logic_vector(2 downto 0) := (others => '0');
		tlappintbsts	:	in std_logic := '0';
		tlappintcack	:	out std_logic;
		tlappintcfuncnum	:	in std_logic_vector(2 downto 0) := (others => '0');
		tlappintcsts	:	in std_logic := '0';
		tlappintdack	:	out std_logic;
		tlappintdfuncnum	:	in std_logic_vector(2 downto 0) := (others => '0');
		tlappintdsts	:	in std_logic := '0';
		tlappmsiack	:	out std_logic;
		tlappmsifunc	:	in std_logic_vector(2 downto 0) := (others => '0');
		tlappmsinum	:	in std_logic_vector(4 downto 0) := (others => '0');
		tlappmsireq	:	in std_logic := '0';
		tlappmsitc	:	in std_logic_vector(2 downto 0) := (others => '0');
		tlcfgadd	:	out std_logic_vector(6 downto 0);
		tlcfgctl	:	out std_logic_vector(31 downto 0);
		tlcfgctlwr	:	out std_logic;
		tlcfgsts	:	out std_logic_vector(122 downto 0);
		tlcfgstswr	:	out std_logic;
		tlhpgctrler	:	in std_logic_vector(4 downto 0) := (others => '0');
		tlpexmsinum	:	in std_logic_vector(4 downto 0) := (others => '0');
		tlpmauxpwr	:	in std_logic := '0';
		tlpmdata	:	in std_logic_vector(9 downto 0) := (others => '0');
		tlpmetocr	:	in std_logic := '0';
		tlpmetosr	:	out std_logic;
		tlpmevent	:	in std_logic := '0';
		tlpmeventfunc	:	in std_logic_vector(2 downto 0) := (others => '0');
		tlslotclkcfg	:	in std_logic := '0';
		txcompl0	:	out std_logic;
		txcompl1	:	out std_logic;
		txcompl2	:	out std_logic;
		txcompl3	:	out std_logic;
		txcompl4	:	out std_logic;
		txcompl5	:	out std_logic;
		txcompl6	:	out std_logic;
		txcompl7	:	out std_logic;
		txcreddatafccp	:	out std_logic_vector(11 downto 0);
		txcreddatafcnp	:	out std_logic_vector(11 downto 0);
		txcreddatafcp	:	out std_logic_vector(11 downto 0);
		txcredfchipcons	:	out std_logic_vector(5 downto 0);
		txcredfcinfinite	:	out std_logic_vector(5 downto 0);
		txcredhdrfccp	:	out std_logic_vector(7 downto 0);
		txcredhdrfcnp	:	out std_logic_vector(7 downto 0);
		txcredhdrfcp	:	out std_logic_vector(7 downto 0);
		txcredvc0	:	out std_logic_vector(35 downto 0);
		txdata0	:	out std_logic_vector(7 downto 0);
		txdata1	:	out std_logic_vector(7 downto 0);
		txdata2	:	out std_logic_vector(7 downto 0);
		txdata3	:	out std_logic_vector(7 downto 0);
		txdata4	:	out std_logic_vector(7 downto 0);
		txdata5	:	out std_logic_vector(7 downto 0);
		txdata6	:	out std_logic_vector(7 downto 0);
		txdata7	:	out std_logic_vector(7 downto 0);
		txdatak0	:	out std_logic;
		txdatak1	:	out std_logic;
		txdatak2	:	out std_logic;
		txdatak3	:	out std_logic;
		txdatak4	:	out std_logic;
		txdatak5	:	out std_logic;
		txdatak6	:	out std_logic;
		txdatak7	:	out std_logic;
		txdatavc00	:	in std_logic_vector(63 downto 0) := (others => '0');
		txdatavc01	:	in std_logic_vector(63 downto 0) := (others => '0');
		txdeemph0	:	out std_logic;
		txdeemph1	:	out std_logic;
		txdeemph2	:	out std_logic;
		txdeemph3	:	out std_logic;
		txdeemph4	:	out std_logic;
		txdeemph5	:	out std_logic;
		txdeemph6	:	out std_logic;
		txdeemph7	:	out std_logic;
		txdetectrx0	:	out std_logic;
		txdetectrx1	:	out std_logic;
		txdetectrx2	:	out std_logic;
		txdetectrx3	:	out std_logic;
		txdetectrx4	:	out std_logic;
		txdetectrx5	:	out std_logic;
		txdetectrx6	:	out std_logic;
		txdetectrx7	:	out std_logic;
		txelecidle0	:	out std_logic;
		txelecidle1	:	out std_logic;
		txelecidle2	:	out std_logic;
		txelecidle3	:	out std_logic;
		txelecidle4	:	out std_logic;
		txelecidle5	:	out std_logic;
		txelecidle6	:	out std_logic;
		txelecidle7	:	out std_logic;
		txeopvc00	:	in std_logic := '0';
		txeopvc01	:	in std_logic := '0';
		txerrvc0	:	in std_logic := '0';
		txfifoemptyvc0	:	out std_logic;
		txfifofullvc0	:	out std_logic;
		txfifordpvc0	:	out std_logic_vector(3 downto 0);
		txfifowrpvc0	:	out std_logic_vector(3 downto 0);
		txmargin0	:	out std_logic_vector(2 downto 0);
		txmargin1	:	out std_logic_vector(2 downto 0);
		txmargin2	:	out std_logic_vector(2 downto 0);
		txmargin3	:	out std_logic_vector(2 downto 0);
		txmargin4	:	out std_logic_vector(2 downto 0);
		txmargin5	:	out std_logic_vector(2 downto 0);
		txmargin6	:	out std_logic_vector(2 downto 0);
		txmargin7	:	out std_logic_vector(2 downto 0);
		txpcsrstn0	:	out std_logic;
		txpcsrstn1	:	out std_logic;
		txpcsrstn2	:	out std_logic;
		txpcsrstn3	:	out std_logic;
		txpcsrstn4	:	out std_logic;
		txpcsrstn5	:	out std_logic;
		txpcsrstn6	:	out std_logic;
		txpcsrstn7	:	out std_logic;
		txpcsrstn8	:	out std_logic;
		txpmasyncp0	:	out std_logic;
		txpmasyncp1	:	out std_logic;
		txpmasyncp2	:	out std_logic;
		txpmasyncp3	:	out std_logic;
		txpmasyncp4	:	out std_logic;
		txpmasyncp5	:	out std_logic;
		txpmasyncp6	:	out std_logic;
		txpmasyncp7	:	out std_logic;
		txpmasyncp8	:	out std_logic;
		txreadyvc0	:	out std_logic;
		txsopvc00	:	in std_logic := '0';
		txsopvc01	:	in std_logic := '0';
		txswing0	:	out std_logic;
		txswing1	:	out std_logic;
		txswing2	:	out std_logic;
		txswing3	:	out std_logic;
		txswing4	:	out std_logic;
		txswing5	:	out std_logic;
		txswing6	:	out std_logic;
		txswing7	:	out std_logic;
		txvalidvc0	:	in std_logic := '0';
		usermode	:	in std_logic := '0';
		vcc_hd	:	in std_logic := '0';
		vss_hd	:	in std_logic := '0';
		wakeoen	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_soc_interface_peripheral_spi parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_peripheral_spi
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_peripheral_spi"	);
	port(
		rxd	:	in std_logic := '0';
		sclkin	:	in std_logic := '0';
		sclkout	:	out std_logic;
		ssinn	:	in std_logic := '0';
		ssioen	:	out std_logic;
		ssoutn	:	out std_logic;
		txd	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_io_ibuf parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_io_ibuf
	generic (
		bus_hold	:	string := "false";
		differential_mode	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_io_ibuf";
		simulate_z_as	:	string := "z"	);
	port(
		dynamicterminationcontrol	:	in std_logic := '0';
		i	:	in std_logic := '0';
		ibar	:	in std_logic := '0';
		o	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_cvpcieblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_cvpcieblock
	generic (
		aux_cvp_opbit	:	string := "false";
		cvp_dbg	:	string := "false";
		cvp_dfx	:	string := "false";
		cvp_opbit	:	string := "false";
		dft_opbits	:	string := "false";
		en_cvp_confdone	:	string := "false";
		iocsr_ready_from_csrdone	:	string := "false";
		lpm_type	:	string := "cyclonev_cvpcieblock";
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
-- cyclonev_chipidblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_chipidblock
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_chipidblock"	);
	port(
		clk	:	in std_logic := '0';
		regout	:	out std_logic;
		shiftnld	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_peripheral_uart parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_peripheral_uart
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_peripheral_uart"	);
	port(
		cts	:	in std_logic := '0';
		dcd	:	in std_logic := '0';
		dsr	:	in std_logic := '0';
		dtr	:	out std_logic;
		out1_n	:	out std_logic;
		out2_n	:	out std_logic;
		ri	:	in std_logic := '0';
		rts	:	out std_logic;
		rxd	:	in std_logic := '0';
		txd	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_dqs_enable_ctrl parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_dqs_enable_ctrl
	generic (
		add_phase_transfer_reg	:	string := "false";
		delay_dqs_enable_by_half_cycle	:	string := "false";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_dqs_enable_ctrl"	);
	port(
		dffextenddqsenable	:	out std_logic;
		dffin	:	out std_logic;
		dffphasetransfer	:	out std_logic;
		dqsenablein	:	in std_logic := '0';
		dqsenableout	:	out std_logic;
		enaphasetransferreg	:	in std_logic := '0';
		levelingclk	:	in std_logic := '0';
		zerophaseclk	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- cyclonev_mac parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_mac
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
		bz_clock	:	string := "none";
		bz_width	:	natural := 1;
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
		delay_scan_out_ay	:	string := "false";
		delay_scan_out_by	:	string := "false";
		enable_double_accum	:	string := "false";
		load_const_clock	:	string := "none";
		load_const_value	:	natural := 0;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_mac";
		mode_sub_location	:	natural := 0;
		negate_clock	:	string := "none";
		operand_source_max	:	string := "input";
		operand_source_may	:	string := "input";
		operand_source_mbx	:	string := "input";
		operand_source_mby	:	string := "input";
		operation_mode	:	string := "m18x18_full";
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
		use_chainadder	:	string := "false"	);
	port(
		accumulate	:	in std_logic := '0';
		aclr	:	in std_logic_vector(1 downto 0) := (others => '0');
		ax	:	in std_logic_vector(ax_width-1 downto 0) := (others => '0');
		ay	:	in std_logic_vector(ay_scan_in_width-1 downto 0) := (others => '0');
		az	:	in std_logic_vector(az_width-1 downto 0) := (others => '0');
		bx	:	in std_logic_vector(bx_width-1 downto 0) := (others => '0');
		by	:	in std_logic_vector(by_width-1 downto 0) := (others => '0');
		bz	:	in std_logic_vector(bz_width-1 downto 0) := (others => '0');
		chainin	:	in std_logic_vector(63 downto 0) := (others => '0');
		chainout	:	out std_logic_vector(63 downto 0);
		clk	:	in std_logic_vector(2 downto 0) := (others => '0');
		coefsela	:	in std_logic_vector(2 downto 0) := (others => '0');
		coefselb	:	in std_logic_vector(2 downto 0) := (others => '0');
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
-- cyclonev_hps_interface_peripheral_spi_slave parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_peripheral_spi_slave
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_peripheral_spi_slave"	);
	port(
		rxd	:	in std_logic := '0';
		sclk_in	:	in std_logic := '0';
		ss_in_n	:	in std_logic := '0';
		ssi_oe_n	:	out std_logic;
		txd	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_fpga2sdram parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_fpga2sdram
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_fpga2sdram"	);
	port(
		bonding_out_1	:	out std_logic_vector(3 downto 0);
		bonding_out_2	:	out std_logic_vector(3 downto 0);
		cfg_axi_mm_select	:	in std_logic_vector(5 downto 0) := (others => '0');
		cfg_cport_rfifo_map	:	in std_logic_vector(17 downto 0) := (others => '0');
		cfg_cport_type	:	in std_logic_vector(11 downto 0) := (others => '0');
		cfg_cport_wfifo_map	:	in std_logic_vector(17 downto 0) := (others => '0');
		cfg_port_width	:	in std_logic_vector(11 downto 0) := (others => '0');
		cfg_rfifo_cport_map	:	in std_logic_vector(15 downto 0) := (others => '0');
		cfg_wfifo_cport_map	:	in std_logic_vector(15 downto 0) := (others => '0');
		cmd_data_0	:	in std_logic_vector(59 downto 0) := (others => '0');
		cmd_data_1	:	in std_logic_vector(59 downto 0) := (others => '0');
		cmd_data_2	:	in std_logic_vector(59 downto 0) := (others => '0');
		cmd_data_3	:	in std_logic_vector(59 downto 0) := (others => '0');
		cmd_data_4	:	in std_logic_vector(59 downto 0) := (others => '0');
		cmd_data_5	:	in std_logic_vector(59 downto 0) := (others => '0');
		cmd_port_clk_0	:	in std_logic := '0';
		cmd_port_clk_1	:	in std_logic := '0';
		cmd_port_clk_2	:	in std_logic := '0';
		cmd_port_clk_3	:	in std_logic := '0';
		cmd_port_clk_4	:	in std_logic := '0';
		cmd_port_clk_5	:	in std_logic := '0';
		cmd_ready_0	:	out std_logic;
		cmd_ready_1	:	out std_logic;
		cmd_ready_2	:	out std_logic;
		cmd_ready_3	:	out std_logic;
		cmd_ready_4	:	out std_logic;
		cmd_ready_5	:	out std_logic;
		cmd_valid_0	:	in std_logic := '0';
		cmd_valid_1	:	in std_logic := '0';
		cmd_valid_2	:	in std_logic := '0';
		cmd_valid_3	:	in std_logic := '0';
		cmd_valid_4	:	in std_logic := '0';
		cmd_valid_5	:	in std_logic := '0';
		rd_clk_0	:	in std_logic := '0';
		rd_clk_1	:	in std_logic := '0';
		rd_clk_2	:	in std_logic := '0';
		rd_clk_3	:	in std_logic := '0';
		rd_data_0	:	out std_logic_vector(79 downto 0);
		rd_data_1	:	out std_logic_vector(79 downto 0);
		rd_data_2	:	out std_logic_vector(79 downto 0);
		rd_data_3	:	out std_logic_vector(79 downto 0);
		rd_ready_0	:	in std_logic := '0';
		rd_ready_1	:	in std_logic := '0';
		rd_ready_2	:	in std_logic := '0';
		rd_ready_3	:	in std_logic := '0';
		rd_valid_0	:	out std_logic;
		rd_valid_1	:	out std_logic;
		rd_valid_2	:	out std_logic;
		rd_valid_3	:	out std_logic;
		wr_clk_0	:	in std_logic := '0';
		wr_clk_1	:	in std_logic := '0';
		wr_clk_2	:	in std_logic := '0';
		wr_clk_3	:	in std_logic := '0';
		wr_data_0	:	in std_logic_vector(89 downto 0) := (others => '0');
		wr_data_1	:	in std_logic_vector(89 downto 0) := (others => '0');
		wr_data_2	:	in std_logic_vector(89 downto 0) := (others => '0');
		wr_data_3	:	in std_logic_vector(89 downto 0) := (others => '0');
		wr_ready_0	:	out std_logic;
		wr_ready_1	:	out std_logic;
		wr_ready_2	:	out std_logic;
		wr_ready_3	:	out std_logic;
		wr_valid_0	:	in std_logic := '0';
		wr_valid_1	:	in std_logic := '0';
		wr_valid_2	:	in std_logic := '0';
		wr_valid_3	:	in std_logic := '0';
		wrack_data_0	:	out std_logic_vector(9 downto 0);
		wrack_data_1	:	out std_logic_vector(9 downto 0);
		wrack_data_2	:	out std_logic_vector(9 downto 0);
		wrack_data_3	:	out std_logic_vector(9 downto 0);
		wrack_data_4	:	out std_logic_vector(9 downto 0);
		wrack_data_5	:	out std_logic_vector(9 downto 0);
		wrack_ready_0	:	in std_logic := '0';
		wrack_ready_1	:	in std_logic := '0';
		wrack_ready_2	:	in std_logic := '0';
		wrack_ready_3	:	in std_logic := '0';
		wrack_ready_4	:	in std_logic := '0';
		wrack_ready_5	:	in std_logic := '0';
		wrack_valid_0	:	out std_logic;
		wrack_valid_1	:	out std_logic;
		wrack_valid_2	:	out std_logic;
		wrack_valid_3	:	out std_logic;
		wrack_valid_4	:	out std_logic;
		wrack_valid_5	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_soc_interface_trace_tpiu parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_soc_interface_trace_tpiu
	generic (
		lpm_type	:	string := "cyclonev_soc_interface_trace_tpiu"	);
	port(
		tpiutracectl	:	out std_logic;
		tpiutracedata	:	out std_logic_vector(31 downto 0)
	);
end component;

------------------------------------------------------------------
-- cyclonev_hps_interface_hps2fpga_light_weight parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_hps2fpga_light_weight
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_hps2fpga_light_weight"	);
	port(
		araddr	:	out std_logic_vector(20 downto 0);
		arburst	:	out std_logic_vector(1 downto 0);
		arcache	:	out std_logic_vector(3 downto 0);
		arid	:	out std_logic_vector(11 downto 0);
		arlen	:	out std_logic_vector(3 downto 0);
		arlock	:	out std_logic_vector(1 downto 0);
		arprot	:	out std_logic_vector(2 downto 0);
		arready	:	in std_logic := '0';
		arsize	:	out std_logic_vector(2 downto 0);
		arvalid	:	out std_logic;
		awaddr	:	out std_logic_vector(20 downto 0);
		awburst	:	out std_logic_vector(1 downto 0);
		awcache	:	out std_logic_vector(3 downto 0);
		awid	:	out std_logic_vector(11 downto 0);
		awlen	:	out std_logic_vector(3 downto 0);
		awlock	:	out std_logic_vector(1 downto 0);
		awprot	:	out std_logic_vector(2 downto 0);
		awready	:	in std_logic := '0';
		awsize	:	out std_logic_vector(2 downto 0);
		awvalid	:	out std_logic;
		bid	:	in std_logic_vector(11 downto 0) := (others => '0');
		bready	:	out std_logic;
		bresp	:	in std_logic_vector(1 downto 0) := (others => '0');
		bvalid	:	in std_logic := '0';
		clk	:	in std_logic := '0';
		rdata	:	in std_logic_vector(31 downto 0) := (others => '0');
		rid	:	in std_logic_vector(11 downto 0) := (others => '0');
		rlast	:	in std_logic := '0';
		rready	:	out std_logic;
		rresp	:	in std_logic_vector(1 downto 0) := (others => '0');
		rvalid	:	in std_logic := '0';
		wdata	:	out std_logic_vector(31 downto 0);
		wid	:	out std_logic_vector(11 downto 0);
		wlast	:	out std_logic;
		wready	:	in std_logic := '0';
		wstrb	:	out std_logic_vector(3 downto 0);
		wvalid	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- cyclonev_mlab_cell parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_mlab_cell
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
		lpm_type	:	string := "cyclonev_mlab_cell";
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
-- cyclonev_delay_chain parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_delay_chain
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_delay_chain";
		sim_falling_delay_increment	:	natural := 10;
		sim_intrinsic_falling_delay	:	natural := 200;
		sim_intrinsic_rising_delay	:	natural := 200;
		sim_rising_delay_increment	:	natural := 10	);
	port(
		datain	:	in std_logic := '0';
		dataout	:	out std_logic;
		delayctrlin	:	in std_logic_vector(4 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- cyclonev_lcell_comb parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_lcell_comb
	generic (
		dont_touch	:	string := "off";
		extended_lut	:	string := "off";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_lcell_comb";
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
-- cyclonev_pseudo_diff_out parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_pseudo_diff_out
	generic (
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "cyclonev_pseudo_diff_out"	);
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
-- cyclonev_hps_interface_peripheral_i2c parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component cyclonev_hps_interface_peripheral_i2c
	generic (
		lpm_type	:	string := "cyclonev_hps_interface_peripheral_i2c"	);
	port(
		out_clk	:	out std_logic;
		out_data	:	out std_logic;
		scl	:	in std_logic := '0';
		sda	:	in std_logic := '0'
	);
end component;

--clearbox auto-generated components end
end cyclonev_components;
