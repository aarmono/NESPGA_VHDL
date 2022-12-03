library IEEE, twentynm;
use IEEE.STD_LOGIC_1164.all;

package twentynm_components is

--clearbox auto-generated components begin
--Dont add any component declarations after this section

------------------------------------------------------------------
-- twentynm_crcblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_crcblock
	generic (
		crc_deld_disable	:	string := "false";
		error_delay	:	natural := 0;
		error_dra_dl_bypass	:	string := "false";
		lpm_type	:	string := "twentynm_crcblock";
		oscillator_divider	:	natural := 256;
		quad_adj_err_correction	:	string := "false";
		triple_adj_err_correction	:	string := "false"	);
	port(
		clk	:	in std_logic := '0';
		crcerror	:	out std_logic;
		endofedfullchip	:	out std_logic;
		regout	:	out std_logic;
		shiftnld	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- twentynm_lvds_clock_tree parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_lvds_clock_tree
	generic (
		clock_export_compatible	:	string := "true";
		lpm_type	:	string := "twentynm_lvds_clock_tree"	);
	port(
		loaden_bot_out	:	out std_logic;
		loaden_in	:	in std_logic := '0';
		loaden_out	:	out std_logic;
		loaden_top_out	:	out std_logic;
		lvdsfclk_bot_out	:	out std_logic;
		lvdsfclk_in	:	in std_logic := '0';
		lvdsfclk_out	:	out std_logic;
		lvdsfclk_top_out	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- twentynm_opregblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_opregblock
	generic (
		lpm_type	:	string := "twentynm_opregblock"	);
	port(
		clk	:	in std_logic := '0';
		regout	:	out std_logic;
		shiftnld	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- twentynm_clkena parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_clkena
	generic (
		clock_type	:	string := "Auto";
		disable_mode	:	string := "low";
		ena_register_mode	:	string := "always enabled";
		ena_register_power_up	:	string := "high";
		lpm_type	:	string := "twentynm_clkena";
		test_syn	:	string := "high"	);
	port(
		ena	:	in std_logic := '1';
		enaout	:	out std_logic;
		inclk	:	in std_logic := '1';
		observableena	:	out std_logic_vector(1 downto 0);
		outclk	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- twentynm_lcell_comb parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_lcell_comb
	generic (
		extended_lut	:	string := "off";
		lpm_type	:	string := "twentynm_lcell_comb";
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
		propagatein	:	in std_logic := '0';
		propagateout	:	out std_logic;
		sharein	:	in std_logic := '0';
		shareout	:	out std_logic;
		sumout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- twentynm_io_aux parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_io_aux
	generic (
		cal_clk_div	:	string := "cal_divide_by_6";
		contents	:	string := "UNUSED";
		debug_mode	:	string := "mode_normal";
		engineering_mode	:	string := "false";
		lpm_type	:	string := "twentynm_io_aux";
		sys_clk_div	:	string := "nios_divide_by_2";
		sys_clk_source	:	string := "int_osc_clk";
		tile0_contents	:	string := "UNUSED";
		tile10_contents	:	string := "UNUSED";
		tile11_contents	:	string := "UNUSED";
		tile1_contents	:	string := "UNUSED";
		tile2_contents	:	string := "UNUSED";
		tile3_contents	:	string := "UNUSED";
		tile4_contents	:	string := "UNUSED";
		tile5_contents	:	string := "UNUSED";
		tile6_contents	:	string := "UNUSED";
		tile7_contents	:	string := "UNUSED";
		tile8_contents	:	string := "UNUSED";
		tile9_contents	:	string := "UNUSED"	);
	port(
		core_avl_clk	:	in std_logic := '0';
		core_nios_clk	:	in std_logic := '0';
		core_prog_done	:	in std_logic := '0';
		debug_clk	:	in std_logic := '0';
		debug_out	:	out std_logic_vector(31 downto 0);
		debug_select	:	in std_logic_vector(15 downto 0) := (others => '0');
		mcu_en	:	in std_logic := '0';
		mode	:	in std_logic := '0';
		soft_nios_addr	:	in std_logic_vector(18 downto 0) := (others => '0');
		soft_nios_clk	:	in std_logic := '0';
		soft_nios_ctl_sig_bidir_in	:	in std_logic_vector(8 downto 0) := (others => '0');
		soft_nios_ctl_sig_bidir_out	:	out std_logic_vector(8 downto 0);
		soft_nios_read	:	in std_logic := '0';
		soft_nios_read_data	:	out std_logic_vector(31 downto 0);
		soft_nios_write	:	in std_logic := '0';
		soft_nios_write_data	:	in std_logic_vector(31 downto 0) := (others => '0');
		soft_ram_addr	:	out std_logic_vector(18 downto 0);
		soft_ram_ctl_sig	:	out std_logic_vector(8 downto 0);
		soft_ram_read	:	out std_logic;
		soft_ram_read_data	:	in std_logic_vector(31 downto 0) := (others => '0');
		soft_ram_rst_n	:	out std_logic;
		soft_ram_write	:	out std_logic;
		soft_ram_write_data	:	out std_logic_vector(31 downto 0);
		system_clk	:	in std_logic := '0';
		uc_address	:	out std_logic_vector(18 downto 0);
		uc_av_bus_clk	:	out std_logic;
		uc_read	:	out std_logic;
		uc_read_data	:	in std_logic_vector(31 downto 0) := (others => '0');
		uc_read_data_valid	:	in std_logic := '0';
		uc_write	:	out std_logic;
		uc_write_data	:	out std_logic_vector(31 downto 0);
		usrmode	:	in std_logic := '0';
		vji_cdr_to_the_hard_nios	:	in std_logic := '0';
		vji_ir_in_to_the_hard_nios	:	in std_logic_vector(1 downto 0) := (others => '0');
		vji_ir_out_from_the_hard_nios	:	out std_logic;
		vji_rti_to_the_hard_nios	:	in std_logic := '0';
		vji_sdr_to_the_hard_nios	:	in std_logic := '0';
		vji_tck_to_the_hard_nios	:	in std_logic := '0';
		vji_tdi_to_the_hard_nios	:	in std_logic := '0';
		vji_tdo_from_the_hard_nios	:	out std_logic;
		vji_udr_to_the_hard_nios	:	in std_logic := '0';
		vji_uir_to_the_hard_nios	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- twentynm_cmu_fpll parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_cmu_fpll
	generic (
		bw_sel	:	string := "auto";
		cgb_div	:	natural := 1;
		compensation_mode	:	string := "direct";
		duty_cycle_0	:	natural := 50;
		duty_cycle_1	:	natural := 50;
		duty_cycle_2	:	natural := 50;
		duty_cycle_3	:	natural := 50;
		hssi_output_clock_frequency	:	string := "0 ps";
		is_cascaded_pll	:	string := "false";
		lpm_type	:	string := "twentynm_cmu_fpll";
		output_clock_frequency_0	:	string := "0 ps";
		output_clock_frequency_1	:	string := "0 ps";
		output_clock_frequency_2	:	string := "0 ps";
		output_clock_frequency_3	:	string := "0 ps";
		phase_shift_0	:	string := "0 ps";
		phase_shift_1	:	string := "0 ps";
		phase_shift_2	:	string := "0 ps";
		phase_shift_3	:	string := "0 ps";
		pll_atb	:	string := "atb_selectdisable";
		pll_c_counter_0	:	natural := 1;
		pll_c_counter_0_coarse_dly	:	string := "0 ps";
		pll_c_counter_0_fine_dly	:	string := "0 ps";
		pll_c_counter_0_in_src	:	string := "m_cnt_in_src_test_clk";
		pll_c_counter_0_ph_mux_prst	:	natural := 0;
		pll_c_counter_0_ph_mux_tclk	:	string := "phmux_vco_phase";
		pll_c_counter_0_prst	:	natural := 1;
		pll_c_counter_1	:	natural := 1;
		pll_c_counter_1_coarse_dly	:	string := "0 ps";
		pll_c_counter_1_fine_dly	:	string := "0 ps";
		pll_c_counter_1_in_src	:	string := "m_cnt_in_src_test_clk";
		pll_c_counter_1_ph_mux_prst	:	natural := 0;
		pll_c_counter_1_ph_mux_tclk	:	string := "phmux_vco_phase";
		pll_c_counter_1_prst	:	natural := 1;
		pll_c_counter_2	:	natural := 1;
		pll_c_counter_2_coarse_dly	:	string := "0 ps";
		pll_c_counter_2_fine_dly	:	string := "0 ps";
		pll_c_counter_2_in_src	:	string := "m_cnt_in_src_test_clk";
		pll_c_counter_2_ph_mux_prst	:	natural := 0;
		pll_c_counter_2_ph_mux_tclk	:	string := "phmux_vco_phase";
		pll_c_counter_2_prst	:	natural := 1;
		pll_c_counter_3	:	natural := 1;
		pll_c_counter_3_coarse_dly	:	string := "0 ps";
		pll_c_counter_3_fine_dly	:	string := "0 ps";
		pll_c_counter_3_in_src	:	string := "m_cnt_in_src_test_clk";
		pll_c_counter_3_ph_mux_prst	:	natural := 0;
		pll_c_counter_3_ph_mux_tclk	:	string := "phmux_vco_phase";
		pll_c_counter_3_prst	:	natural := 1;
		pll_cal_status	:	string := "true";
		pll_calibration	:	string := "false";
		pll_cmp_buf_dly	:	string := "0 ps";
		pll_cmu_rstn_value	:	string := "true";
		pll_cp_compensation	:	string := "true";
		pll_cp_current_setting	:	string := "cp_current_setting0";
		pll_cp_lf_3rd_pole_freq	:	string := "lf_3rd_pole_setting0";
		pll_cp_lf_4th_pole_freq	:	string := "lf_4th_pole_setting0";
		pll_cp_lf_order	:	string := "lf_2nd_order";
		pll_cp_testmode	:	string := "cp_normal";
		pll_ctrl_override_setting	:	string := "true";
		pll_ctrl_plniotri_override	:	string := "false";
		pll_dsm_ecn_bypass	:	string := "false";
		pll_dsm_ecn_test_en	:	string := "false";
		pll_dsm_fractional_division	:	natural := 1;
		pll_dsm_fractional_value_ready	:	string := "pll_k_ready";
		pll_dsm_mode	:	string := "dsm_mode_integer";
		pll_dsm_out_sel	:	string := "pll_dsm_disable";
		pll_enable	:	string := "false";
		pll_fbclk_mux_1	:	string := "pll_fbclk_mux_1_glb";
		pll_fbclk_mux_2	:	string := "pll_fbclk_mux_2_fb_1";
		pll_iqclk_mux_sel	:	string := "power_down";
		pll_l_counter	:	natural := 1;
		pll_l_counter_bypass	:	string := "false";
		pll_l_counter_enable	:	string := "true";
		pll_lf_resistance	:	string := "lf_res_setting0";
		pll_lf_ripplecap	:	string := "lf_ripple_enabled";
		pll_lock_fltr_cfg	:	natural := 1;
		pll_lock_fltr_test	:	string := "pll_lock_fltr_nrm";
		pll_lpf_rstn_value	:	string := "true";
		pll_m_counter	:	natural := 1;
		pll_m_counter_coarse_dly	:	string := "0 ps";
		pll_m_counter_fine_dly	:	string := "0 ps";
		pll_m_counter_in_src	:	string := "m_cnt_in_src_test_clk";
		pll_m_counter_ph_mux_prst	:	natural := 0;
		pll_m_counter_ph_mux_tclk	:	string := "phmux_vco_phase";
		pll_m_counter_prst	:	natural := 1;
		pll_n_counter	:	natural := 1;
		pll_n_counter_coarse_dly	:	string := "0 ps";
		pll_n_counter_fine_dly	:	string := "0 ps";
		pll_nreset_invert	:	string := "false";
		pll_op_mode	:	string := "false";
		pll_overrange_level	:	string := "level0";
		pll_ppm_clk0_src	:	string := "ppm_clk0_vss";
		pll_ppm_clk1_src	:	string := "ppm_clk1_vss";
		pll_proc_mode	:	string := "pcie1_2";
		pll_ref_buf_dly	:	string := "0 ps";
		pll_refclk	:	string := "freq_100";
		pll_rstn_override	:	string := "false";
		pll_self_reset	:	string := "false";
		pll_tclk_mux_en	:	string := "false";
		pll_tclk_sel	:	string := "pll_tclk_m_src";
		pll_test_enable	:	string := "false";
		pll_underrange_level	:	string := "level0";
		pll_unlock_fltr_cfg	:	natural := 0;
		pll_vccr_pd_en	:	string := "true";
		pll_vco_freq_band	:	string := "pll_freq_band0";
		pll_vco_ph0_en	:	string := "false";
		pll_vco_ph0_value	:	string := "pll_vco_ph0_vss";
		pll_vco_ph1_en	:	string := "false";
		pll_vco_ph1_value	:	string := "pll_vco_ph1_vss";
		pll_vco_ph2_en	:	string := "false";
		pll_vco_ph2_value	:	string := "pll_vco_ph2_vss";
		pll_vco_ph3_en	:	string := "false";
		pll_vco_ph3_value	:	string := "pll_vco_ph3_vss";
		pll_vreg0_output	:	string := "vccdreg_nominal";
		pll_vreg1_output	:	string := "vccdreg_nominal";
		pma_width	:	natural := 8;
		prot_mode	:	string := "basic";
		reference_clock_frequency	:	string := "0 ps";
		silicon_rev	:	string := "reve";
		speed_grade	:	string := "2";
		use_default_base_address	:	string := "true";
		user_base_address	:	natural := 0;
		vco_frequency	:	string := "0 ps"	);
	port(
		avmmaddress	:	in std_logic_vector(8 downto 0) := (others => '0');
		avmmclk	:	in std_logic := '0';
		avmmread	:	in std_logic := '0';
		avmmreaddata	:	out std_logic_vector(7 downto 0);
		avmmrstn	:	in std_logic := '0';
		avmmwrite	:	in std_logic := '1';
		avmmwritedata	:	in std_logic_vector(7 downto 0) := (others => '0');
		block_select	:	out std_logic;
		clk0	:	out std_logic;
		clk180	:	out std_logic;
		clklow	:	out std_logic;
		cnt_sel	:	in std_logic_vector(3 downto 0) := (others => '0');
		csr_bufin	:	in std_logic := '0';
		csr_bufout	:	out std_logic;
		csr_clk	:	in std_logic := '1';
		csr_en	:	in std_logic := '1';
		csr_in	:	in std_logic := '1';
		csr_out	:	out std_logic;
		csr_test_mode	:	in std_logic := '1';
		dps_rst_n	:	in std_logic := '1';
		extswitch_buf	:	in std_logic := '0';
		fbclk_in	:	in std_logic := '0';
		fbclk_out	:	out std_logic;
		fpll_ppm_clk	:	in std_logic_vector(1 downto 0) := (others => '0');
		fref	:	out std_logic;
		hclk_out	:	out std_logic;
		iqtxrxclk	:	in std_logic_vector(5 downto 0) := (others => '0');
		iqtxrxclk_out	:	out std_logic;
		lock	:	out std_logic;
		mdio_dis	:	in std_logic := '1';
		nfrzdrv	:	in std_logic := '1';
		nrpi_freeze	:	in std_logic := '1';
		num_phase_shifts	:	in std_logic_vector(2 downto 0) := (others => '0');
		outclk	:	out std_logic_vector(3 downto 0);
		overrange	:	out std_logic;
		pfden	:	in std_logic := '1';
		phase_done	:	out std_logic;
		phase_en	:	in std_logic := '0';
		pll_cascade_out	:	out std_logic;
		pma_atpg_los_en_n	:	in std_logic := '0';
		pma_csr_test_dis	:	in std_logic := '1';
		ppm_clk	:	out std_logic_vector(1 downto 0);
		refclk	:	in std_logic := '0';
		rst_n	:	in std_logic := '1';
		scan_mode_n	:	in std_logic := '1';
		scan_shift_n	:	in std_logic := '1';
		underrange	:	out std_logic;
		up_dn	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- twentynm_uib_wdrc_cell parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_uib_wdrc_cell
	generic (
		clock_enable	:	string := "None";
		external_clock_source	:	string := "EXT_CLK";
		external_dataout_strength	:	string := "LOW_STRENGTH";
		logical_function	:	string := "None";
		logical_name	:	string := "UNUSED";
		loopback_mode	:	string := "false";
		lpm_type	:	string := "twentynm_uib_wdrc_cell";
		port_bit_index	:	natural := -1;
		user_port_name	:	string := "UNUSED";
		user_port_type	:	string := "GENERIC";
		write_mode	:	string := "QDR"	);
	port(
		clk0	:	in std_logic := '0';
		clk1	:	in std_logic := '0';
		clr	:	in std_logic := '0';
		datain	:	in std_logic_vector(3 downto 0) := (others => '0');
		ena0	:	in std_logic := '1';
		ext_clk	:	in std_logic := '0';
		extclkout	:	out std_logic;
		extdataout	:	out std_logic;
		nextclkout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- twentynm_uib_rdrc_cell parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_uib_rdrc_cell
	generic (
		clock_enable	:	string := "None";
		logical_function	:	string := "None";
		logical_name	:	string := "UNUSED";
		loopback_mode	:	string := "false";
		lpm_type	:	string := "twentynm_uib_rdrc_cell";
		port_bit_index	:	natural := -1;
		read_mode	:	string := "QDR_RF";
		user_port_name	:	string := "UNUSED";
		user_port_type	:	string := "GENERIC"	);
	port(
		clk0	:	in std_logic := '0';
		clk1	:	in std_logic := '0';
		clr	:	in std_logic := '0';
		dataout	:	out std_logic_vector(3 downto 0);
		ena0	:	in std_logic := '1';
		extdatain	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- twentynm_delay_chain parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_delay_chain
	generic (
		lpm_type	:	string := "twentynm_delay_chain";
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
-- twentynm_iopll parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_iopll
	generic (
		bw_sel	:	string := "auto";
		compensation_mode	:	string := "direct";
		duty_cycle_0	:	natural := 50;
		duty_cycle_1	:	natural := 50;
		duty_cycle_2	:	natural := 50;
		duty_cycle_3	:	natural := 50;
		duty_cycle_4	:	natural := 50;
		duty_cycle_5	:	natural := 50;
		duty_cycle_6	:	natural := 50;
		duty_cycle_7	:	natural := 50;
		duty_cycle_8	:	natural := 50;
		is_cascaded_pll	:	string := "false";
		lpm_type	:	string := "twentynm_iopll";
		output_clock_frequency_0	:	string := "0 ps";
		output_clock_frequency_1	:	string := "0 ps";
		output_clock_frequency_2	:	string := "0 ps";
		output_clock_frequency_3	:	string := "0 ps";
		output_clock_frequency_4	:	string := "0 ps";
		output_clock_frequency_5	:	string := "0 ps";
		output_clock_frequency_6	:	string := "0 ps";
		output_clock_frequency_7	:	string := "0 ps";
		output_clock_frequency_8	:	string := "0 ps";
		phase_shift_0	:	string := "0 ps";
		phase_shift_1	:	string := "0 ps";
		phase_shift_2	:	string := "0 ps";
		phase_shift_3	:	string := "0 ps";
		phase_shift_4	:	string := "0 ps";
		phase_shift_5	:	string := "0 ps";
		phase_shift_6	:	string := "0 ps";
		phase_shift_7	:	string := "0 ps";
		phase_shift_8	:	string := "0 ps";
		pll_atb	:	string := "atb_selectdisable";
		pll_auto_clk_sw_en	:	string := "false";
		pll_bwctrl	:	string := "pll_bw_res_setting4";
		pll_c0_extclk_dllout_en	:	string := "false";
		pll_c0_out_en	:	string := "false";
		pll_c1_extclk_dllout_en	:	string := "false";
		pll_c1_out_en	:	string := "false";
		pll_c2_extclk_dllout_en	:	string := "false";
		pll_c2_out_en	:	string := "false";
		pll_c3_extclk_dllout_en	:	string := "false";
		pll_c3_out_en	:	string := "false";
		pll_c4_out_en	:	string := "false";
		pll_c5_out_en	:	string := "false";
		pll_c6_out_en	:	string := "false";
		pll_c7_out_en	:	string := "false";
		pll_c8_out_en	:	string := "false";
		pll_c_counter_0_bypass_en	:	string := "false";
		pll_c_counter_0_coarse_dly	:	string := "0 ps";
		pll_c_counter_0_even_duty_en	:	string := "false";
		pll_c_counter_0_fine_dly	:	string := "0 ps";
		pll_c_counter_0_high	:	natural := 1;
		pll_c_counter_0_in_src	:	string := "c_m_cnt_in_src_test_clk";
		pll_c_counter_0_low	:	natural := 1;
		pll_c_counter_0_ph_mux_prst	:	natural := 0;
		pll_c_counter_0_prst	:	natural := 1;
		pll_c_counter_1_bypass_en	:	string := "false";
		pll_c_counter_1_coarse_dly	:	string := "0 ps";
		pll_c_counter_1_even_duty_en	:	string := "false";
		pll_c_counter_1_fine_dly	:	string := "0 ps";
		pll_c_counter_1_high	:	natural := 1;
		pll_c_counter_1_in_src	:	string := "c_m_cnt_in_src_test_clk";
		pll_c_counter_1_low	:	natural := 1;
		pll_c_counter_1_ph_mux_prst	:	natural := 0;
		pll_c_counter_1_prst	:	natural := 1;
		pll_c_counter_2_bypass_en	:	string := "false";
		pll_c_counter_2_coarse_dly	:	string := "0 ps";
		pll_c_counter_2_even_duty_en	:	string := "false";
		pll_c_counter_2_fine_dly	:	string := "0 ps";
		pll_c_counter_2_high	:	natural := 1;
		pll_c_counter_2_in_src	:	string := "c_m_cnt_in_src_test_clk";
		pll_c_counter_2_low	:	natural := 1;
		pll_c_counter_2_ph_mux_prst	:	natural := 0;
		pll_c_counter_2_prst	:	natural := 1;
		pll_c_counter_3_bypass_en	:	string := "false";
		pll_c_counter_3_coarse_dly	:	string := "0 ps";
		pll_c_counter_3_even_duty_en	:	string := "false";
		pll_c_counter_3_fine_dly	:	string := "0 ps";
		pll_c_counter_3_high	:	natural := 1;
		pll_c_counter_3_in_src	:	string := "c_m_cnt_in_src_test_clk";
		pll_c_counter_3_low	:	natural := 1;
		pll_c_counter_3_ph_mux_prst	:	natural := 0;
		pll_c_counter_3_prst	:	natural := 1;
		pll_c_counter_4_bypass_en	:	string := "false";
		pll_c_counter_4_coarse_dly	:	string := "0 ps";
		pll_c_counter_4_even_duty_en	:	string := "false";
		pll_c_counter_4_fine_dly	:	string := "0 ps";
		pll_c_counter_4_high	:	natural := 1;
		pll_c_counter_4_in_src	:	string := "c_m_cnt_in_src_test_clk";
		pll_c_counter_4_low	:	natural := 1;
		pll_c_counter_4_ph_mux_prst	:	natural := 0;
		pll_c_counter_4_prst	:	natural := 1;
		pll_c_counter_5_bypass_en	:	string := "false";
		pll_c_counter_5_coarse_dly	:	string := "0 ps";
		pll_c_counter_5_even_duty_en	:	string := "false";
		pll_c_counter_5_fine_dly	:	string := "0 ps";
		pll_c_counter_5_high	:	natural := 1;
		pll_c_counter_5_in_src	:	string := "c_m_cnt_in_src_test_clk";
		pll_c_counter_5_low	:	natural := 1;
		pll_c_counter_5_ph_mux_prst	:	natural := 0;
		pll_c_counter_5_prst	:	natural := 1;
		pll_c_counter_6_bypass_en	:	string := "false";
		pll_c_counter_6_coarse_dly	:	string := "0 ps";
		pll_c_counter_6_even_duty_en	:	string := "false";
		pll_c_counter_6_fine_dly	:	string := "0 ps";
		pll_c_counter_6_high	:	natural := 1;
		pll_c_counter_6_in_src	:	string := "c_m_cnt_in_src_test_clk";
		pll_c_counter_6_low	:	natural := 1;
		pll_c_counter_6_ph_mux_prst	:	natural := 0;
		pll_c_counter_6_prst	:	natural := 1;
		pll_c_counter_7_bypass_en	:	string := "false";
		pll_c_counter_7_coarse_dly	:	string := "0 ps";
		pll_c_counter_7_even_duty_en	:	string := "false";
		pll_c_counter_7_fine_dly	:	string := "0 ps";
		pll_c_counter_7_high	:	natural := 1;
		pll_c_counter_7_in_src	:	string := "c_m_cnt_in_src_test_clk";
		pll_c_counter_7_low	:	natural := 1;
		pll_c_counter_7_ph_mux_prst	:	natural := 0;
		pll_c_counter_7_prst	:	natural := 1;
		pll_c_counter_8_bypass_en	:	string := "false";
		pll_c_counter_8_coarse_dly	:	string := "0 ps";
		pll_c_counter_8_even_duty_en	:	string := "false";
		pll_c_counter_8_fine_dly	:	string := "0 ps";
		pll_c_counter_8_high	:	natural := 1;
		pll_c_counter_8_in_src	:	string := "c_m_cnt_in_src_test_clk";
		pll_c_counter_8_low	:	natural := 1;
		pll_c_counter_8_ph_mux_prst	:	natural := 0;
		pll_c_counter_8_prst	:	natural := 1;
		pll_clk_loss_edge	:	string := "pll_clk_loss_both_edges";
		pll_clk_loss_sw_en	:	string := "false";
		pll_clk_sw_dly	:	natural := 0;
		pll_clkin_0_src	:	string := "pll_clkin_0_src_refclkin";
		pll_clkin_1_src	:	string := "pll_clkin_1_src_refclkin";
		pll_cmp_buf_dly	:	string := "0 ps";
		pll_coarse_dly_0	:	string := "0 ps";
		pll_coarse_dly_1	:	string := "0 ps";
		pll_coarse_dly_2	:	string := "0 ps";
		pll_coarse_dly_3	:	string := "0 ps";
		pll_cp_compensation	:	string := "true";
		pll_cp_current_setting	:	string := "pll_cp_setting2";
		pll_ctrl_override_setting	:	string := "true";
		pll_dft_plniotri_override	:	string := "false";
		pll_dft_ppmclk	:	string := "c_cnt_out";
		pll_dft_vco_ph0_en	:	string := "false";
		pll_dft_vco_ph1_en	:	string := "false";
		pll_dft_vco_ph2_en	:	string := "false";
		pll_dft_vco_ph3_en	:	string := "false";
		pll_dft_vco_ph4_en	:	string := "false";
		pll_dft_vco_ph5_en	:	string := "false";
		pll_dft_vco_ph6_en	:	string := "false";
		pll_dft_vco_ph7_en	:	string := "false";
		pll_dll_src	:	string := "pll_dll_src_vss";
		pll_dly_0_enable	:	string := "false";
		pll_dly_1_enable	:	string := "false";
		pll_dly_2_enable	:	string := "false";
		pll_dly_3_enable	:	string := "false";
		pll_enable	:	string := "false";
		pll_extclk_0_cnt_src	:	string := "pll_extclk_cnt_src_vss";
		pll_extclk_0_enable	:	string := "false";
		pll_extclk_0_invert	:	string := "false";
		pll_extclk_1_cnt_src	:	string := "pll_extclk_cnt_src_vss";
		pll_extclk_1_enable	:	string := "false";
		pll_extclk_1_invert	:	string := "false";
		pll_fbclk_mux_1	:	string := "pll_fbclk_mux_1_glb";
		pll_fbclk_mux_2	:	string := "pll_fbclk_mux_2_fb_1";
		pll_fine_dly_0	:	string := "0 ps";
		pll_fine_dly_1	:	string := "0 ps";
		pll_fine_dly_2	:	string := "0 ps";
		pll_fine_dly_3	:	string := "0 ps";
		pll_lock_fltr_cfg	:	natural := 1;
		pll_lock_fltr_test	:	string := "pll_lock_fltr_nrm";
		pll_m_counter_bypass_en	:	string := "false";
		pll_m_counter_coarse_dly	:	string := "0 ps";
		pll_m_counter_even_duty_en	:	string := "false";
		pll_m_counter_fine_dly	:	string := "0 ps";
		pll_m_counter_high	:	natural := 1;
		pll_m_counter_in_src	:	string := "c_m_cnt_in_src_test_clk";
		pll_m_counter_low	:	natural := 1;
		pll_m_counter_ph_mux_prst	:	natural := 0;
		pll_m_counter_prst	:	natural := 1;
		pll_manu_clk_sw_en	:	string := "false";
		pll_mode	:	string := "false";
		pll_n_counter_bypass_en	:	string := "false";
		pll_n_counter_coarse_dly	:	string := "0 ps";
		pll_n_counter_fine_dly	:	string := "0 ps";
		pll_n_counter_high	:	natural := 1;
		pll_n_counter_low	:	natural := 1;
		pll_n_counter_odd_div_duty_en	:	string := "false";
		pll_nreset_invert	:	string := "false";
		pll_phyfb_mux	:	string := "m_cnt_phmux_out";
		pll_ref_buf_dly	:	string := "0 ps";
		pll_ripplecap_ctrl	:	string := "pll_ripplecap_setting0";
		pll_self_reset	:	string := "false";
		pll_sw_refclk_src	:	string := "pll_sw_refclk_src_clk_0";
		pll_tclk_mux_en	:	string := "false";
		pll_tclk_sel	:	string := "pll_tclk_m_src";
		pll_test_enable	:	string := "false";
		pll_testdn_enable	:	string := "false";
		pll_testup_enable	:	string := "false";
		pll_unlock_fltr_cfg	:	natural := 0;
		pll_vccr_pd_en	:	string := "true";
		pll_vco_ph0_en	:	string := "false";
		pll_vco_ph1_en	:	string := "false";
		pll_vco_ph2_en	:	string := "false";
		pll_vco_ph3_en	:	string := "false";
		pll_vco_ph4_en	:	string := "false";
		pll_vco_ph5_en	:	string := "false";
		pll_vco_ph6_en	:	string := "false";
		pll_vco_ph7_en	:	string := "false";
		reference_clock_frequency	:	string := "0 ps";
		silicon_rev	:	string := "reve";
		speed_grade	:	string := "2";
		use_default_base_address	:	string := "true";
		user_base_address	:	natural := 0;
		vco_frequency	:	string := "0 ps"	);
	port(
		block_select	:	out std_logic;
		clk0_bad	:	out std_logic;
		clk1_bad	:	out std_logic;
		clken	:	in std_logic_vector(1 downto 0) := (others => '0');
		clksel	:	out std_logic;
		cnt_sel	:	in std_logic_vector(3 downto 0) := (others => '0');
		core_refclk	:	in std_logic := '0';
		csr_clk	:	in std_logic := '0';
		csr_en	:	in std_logic := '0';
		csr_in	:	in std_logic := '0';
		csr_out	:	out std_logic;
		csr_test_mode	:	in std_logic := '0';
		dll_output	:	out std_logic;
		dprio_address	:	in std_logic_vector(8 downto 0) := (others => '0');
		dprio_clk	:	in std_logic := '0';
		dprio_rst_n	:	in std_logic := '0';
		dps_rst_n	:	in std_logic := '0';
		extclk_dft	:	out std_logic_vector(1 downto 0);
		extclk_output	:	out std_logic_vector(1 downto 0);
		extswitch	:	in std_logic := '0';
		fbclk_in	:	in std_logic := '0';
		fbclk_out	:	out std_logic;
		fblvds_in	:	in std_logic := '0';
		fblvds_out	:	out std_logic;
		lf_reset	:	out std_logic;
		loaden	:	out std_logic_vector(1 downto 0);
		lock	:	out std_logic;
		lvds_clk	:	out std_logic_vector(1 downto 0);
		mdio_dis	:	in std_logic := '0';
		num_phase_shifts	:	in std_logic_vector(2 downto 0) := (others => '0');
		outclk	:	out std_logic_vector(8 downto 0);
		pfden	:	in std_logic := '0';
		phase_done	:	out std_logic;
		phase_en	:	in std_logic := '0';
		pipeline_global_en_n	:	in std_logic := '0';
		pll_cascade_in	:	in std_logic := '0';
		pll_cascade_out	:	out std_logic;
		pll_pd	:	out std_logic;
		pma_csr_test_dis	:	in std_logic := '0';
		read	:	in std_logic := '0';
		readdata	:	out std_logic_vector(7 downto 0);
		refclk	:	in std_logic_vector(3 downto 0) := (others => '0');
		rst_n	:	in std_logic := '0';
		scan_mode_n	:	in std_logic := '0';
		scan_shift_n	:	in std_logic := '0';
		up_dn	:	in std_logic := '0';
		vcop_en	:	out std_logic;
		vcoph	:	out std_logic_vector(7 downto 0);
		write	:	in std_logic := '0';
		writedata	:	in std_logic_vector(7 downto 0) := (others => '0');
		zdb_in	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- twentynm_ff parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_ff
	generic (
		lpm_type	:	string := "twentynm_ff"	);
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
-- twentynm_refclk_input parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_refclk_input
	generic (
		clkpin2_select	:	string := "select_clkpin_0";
		lpm_type	:	string := "twentynm_refclk_input";
		pllin_msel	:	string := "refclk0_ftop";
		ref2to3_en	:	string := "disable_2to3";
		ref3to2_en	:	string := "disable_3to2";
		ref_clk_mode	:	string := "current_clk_pin0";
		refclk0in_msel	:	string := "refclk1_0";
		refclk1_btm_dwnen	:	string := "disable_bt_dn_1";
		refclk1_btm_upen	:	string := "disable_bt_up_1";
		refclk1_muxin_en	:	string := "disable_muxin_1";
		refclk1_tp_dwnen	:	string := "disable_tp_dn_1";
		refclk1_tp_upen	:	string := "disable_tp_up_1";
		refclk1in_msel	:	string := "refclk2_1";
		refclk2_btm_dwnen	:	string := "disable_bt_dn_2";
		refclk2_btm_upen	:	string := "disable_bt_up_2";
		refclk2_muxin_en	:	string := "disable_muxin_2";
		refclk2_tp_dwnen	:	string := "disable_tp_dn_2";
		refclk2_tp_upen	:	string := "disable_tp_up_2";
		refclk2in_msel	:	string := "pll_output_2";
		refclk3_btm_dwnen	:	string := "disable_bt_dn_3";
		refclk3_btm_upen	:	string := "disable_bt_up_3";
		refclk3_muxin_en	:	string := "disable_muxin_3";
		refclk3_tp_dwnen	:	string := "disable_tp_dn_3";
		refclk3_tp_upen	:	string := "disable_tp_up_3";
		refclk3in_msel	:	string := "pll_output_3"	);
	port(
		clk_out	:	out std_logic;
		down_in	:	in std_logic_vector(3 downto 0) := (others => '0');
		down_out	:	out std_logic_vector(3 downto 0);
		pll_cascade_in	:	in std_logic := '0';
		ref_clk_in	:	in std_logic_vector(3 downto 0) := (others => '0');
		up_in	:	in std_logic_vector(3 downto 0) := (others => '0');
		up_out	:	out std_logic_vector(3 downto 0)
	);
end component;

------------------------------------------------------------------
-- twentynm_rublock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_rublock
	generic (
		lpm_type	:	string := "twentynm_rublock";
		sim_init_config_is_application	:	string := "false";
		sim_init_status	:	natural := 0;
		sim_init_watchdog_enabled	:	string := "false";
		sim_init_watchdog_value	:	natural := 0	);
	port(
		clk	:	in std_logic := '0';
		ctl	:	in std_logic_vector(1 downto 0) := (others => '0');
		rconfig	:	in std_logic := '0';
		regin	:	in std_logic := '0';
		regout	:	out std_logic;
		rsttimer	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- twentynm_termination parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_termination
	generic (
		a_oct_cal_ddr4	:	string := "a_oct_cal_ddr4_dis";
		a_oct_cal_mode	:	string := "a_oct_cal_mode_disable";
		a_oct_cal_x2	:	string := "a_oct_cal_x2_dis";
		a_oct_calclr	:	string := "a_oct_calclr_off";
		a_oct_pwrdn	:	string := "a_oct_pwrdn_on";
		a_oct_rshft_rdn	:	string := "a_oct_rshft_rdn_enable";
		a_oct_rshft_rup	:	string := "a_oct_rshft_rup_enable";
		a_oct_user_oct	:	string := "a_oct_user_oct_off";
		lpm_type	:	string := "twentynm_termination"	);
	port(
		clkenusr	:	in std_logic := '0';
		clkusr	:	in std_logic := '0';
		clkusr_dft_out	:	out std_logic;
		compout_rdn	:	out std_logic;
		compout_rup	:	out std_logic;
		enserout	:	out std_logic;
		enserusr	:	in std_logic := '0';
		nclrusr	:	in std_logic := '0';
		oct_scanclk	:	in std_logic := '0';
		oct_scanen	:	in std_logic := '0';
		oct_scanin	:	in std_logic := '0';
		oct_scanout	:	out std_logic;
		other_enser	:	in std_logic_vector(10 downto 0) := (others => '0');
		rzqin	:	in std_logic := '0';
		ser_data_ca_from_core	:	in std_logic := '0';
		ser_data_ca_out	:	out std_logic;
		ser_data_ca_to_core	:	out std_logic;
		ser_data_dq_from_core	:	in std_logic := '0';
		ser_data_dq_out	:	out std_logic;
		ser_data_dq_to_core	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- twentynm_ddio_out parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_ddio_out
	generic (
		async_mode	:	string := "none";
		half_rate_mode	:	string := "false";
		lpm_type	:	string := "twentynm_ddio_out";
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
-- twentynm_oscillator parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_oscillator
	generic (
		lpm_type	:	string := "twentynm_oscillator"	);
	port(
		clkout	:	out std_logic;
		clkout1	:	out std_logic;
		observableoutputport	:	out std_logic;
		oscena	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- twentynm_fp_mac parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_fp_mac
	generic (
		accum_adder_clock	:	string := "NONE";
		accum_pipeline_clock	:	string := "NONE";
		accumulate_clock	:	string := "NONE";
		adder_input_clock	:	string := "NONE";
		adder_subtract	:	string := "false";
		ax_chainin_pl_clock	:	string := "NONE";
		ax_clock	:	string := "NONE";
		ay_clock	:	string := "NONE";
		az_clock	:	string := "NONE";
		lpm_type	:	string := "twentynm_fp_mac";
		mult_pipeline_clock	:	string := "NONE";
		operation_mode	:	string := "SP_MULT_ADD";
		output_clock	:	string := "NONE";
		use_chainin	:	string := "false"	);
	port(
		accumulate	:	in std_logic := '0';
		aclr	:	in std_logic_vector(1 downto 0) := (others => '0');
		ax	:	in std_logic_vector(31 downto 0) := (others => '0');
		ay	:	in std_logic_vector(31 downto 0) := (others => '0');
		az	:	in std_logic_vector(31 downto 0) := (others => '0');
		chainin	:	in std_logic_vector(31 downto 0) := (others => '0');
		chainin_inexact	:	in std_logic := '0';
		chainin_invalid	:	in std_logic := '0';
		chainin_overflow	:	in std_logic := '0';
		chainin_underflow	:	in std_logic := '0';
		chainout	:	out std_logic_vector(31 downto 0);
		chainout_inexact	:	out std_logic;
		chainout_invalid	:	out std_logic;
		chainout_overflow	:	out std_logic;
		chainout_underflow	:	out std_logic;
		clk	:	in std_logic_vector(2 downto 0) := (others => '0');
		dftout	:	out std_logic;
		ena	:	in std_logic_vector(2 downto 0) := (others => '1');
		inexact	:	out std_logic;
		invalid	:	out std_logic;
		overflow	:	out std_logic;
		resulta	:	out std_logic_vector(31 downto 0);
		underflow	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- twentynm_ddio_oe parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_ddio_oe
	generic (
		async_mode	:	string := "none";
		disable_second_level_register	:	string := "false";
		lpm_type	:	string := "twentynm_ddio_oe";
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
-- twentynm_clkselect parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_clkselect
	generic (
		lpm_type	:	string := "twentynm_clkselect";
		test_cff	:	string := "low"	);
	port(
		clkselect	:	in std_logic_vector(1 downto 0) := (others => '0');
		inclk	:	in std_logic_vector(3 downto 0) := (others => '0');
		outclk	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- twentynm_io_ibuf parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_io_ibuf
	generic (
		bus_hold	:	string := "false";
		differential_mode	:	string := "false";
		lpm_type	:	string := "twentynm_io_ibuf";
		simulate_z_as	:	string := "z"	);
	port(
		dynamicterminationcontrol	:	in std_logic := '0';
		i	:	in std_logic := '0';
		ibar	:	in std_logic := '0';
		o	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- twentynm_prblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_prblock
	generic (
		en_pr_decomp	:	string := "false";
		en_pr_decrypt	:	string := "false";
		lpm_type	:	string := "twentynm_prblock";
		pr_enable	:	string := "false";
		pr_read_adden_cnt	:	string := "false";
		pr_read_adden_low_cnt	:	string := "false";
		pr_read_pre_prechg_cnt	:	string := "false";
		pr_read_prechg_adden_cnt	:	string := "false";
		pr_read_prechg_dl_cnt	:	string := "false";
		pr_write_adden_cnt	:	string := "false";
		pr_write_adden_low_cnt	:	string := "false";
		pr_write_dl_hv_low_cnt	:	string := "false";
		pr_write_dl_hv_wb_cnt	:	string := "false";
		pr_write_dl_lv_drbce_cnt	:	string := "false";
		pr_write_drbce_dl_hv_cnt	:	string := "false";
		pr_write_wb_adden_cnt	:	string := "false";
		user_pr_read_adden_cnt_val	:	natural := 44;
		user_pr_read_adden_low_cnt_val	:	natural := 7;
		user_pr_read_pre_prechg_cnt_val	:	natural := 13;
		user_pr_read_prechg_adden_cnt_val	:	natural := 7;
		user_pr_read_prechg_dl_cnt_val	:	natural := 22;
		user_pr_write_adden_cnt_val	:	natural := 19;
		user_pr_write_adden_low_cnt_val	:	natural := 13;
		user_pr_write_dl_hv_low_cnt_val	:	natural := 7;
		user_pr_write_dl_hv_wb_cnt_val	:	natural := 7;
		user_pr_write_dl_lv_drbce_cnt_val	:	natural := 7;
		user_pr_write_drbce_dl_hv_cnt_val	:	natural := 16;
		user_pr_write_wb_adden_cnt_val	:	natural := 13	);
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
-- twentynm_termination_logic parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_termination_logic
	generic (
		a_iob_oct_block	:	string := "a_iob_oct_block_none";
		a_iob_oct_serdata	:	string := "a_iob_oct_ser_data_ca";
		a_iob_oct_test	:	string := "a_iob_oct_test_off";
		lpm_type	:	string := "twentynm_termination_logic"	);
	port(
		enser	:	in std_logic_vector(11 downto 0) := (others => '0');
		parallelterminationcontrol	:	out std_logic_vector(15 downto 0);
		s2pload	:	in std_logic := '0';
		scan_out	:	out std_logic;
		scan_shift_n	:	in std_logic := '0';
		scanclk	:	in std_logic := '0';
		scanin	:	in std_logic := '0';
		ser_data_ca	:	in std_logic := '0';
		ser_data_dq	:	in std_logic := '0';
		seriesterminationcontrol	:	out std_logic_vector(15 downto 0)
	);
end component;

------------------------------------------------------------------
-- twentynm_jtag parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_jtag
	generic (
		lpm_type	:	string := "twentynm_jtag"	);
	port(
		clkdruser	:	out std_logic;
		corectl	:	in std_logic := '1';
		ntdopinena	:	in std_logic := '1';
		ntrst	:	in std_logic := '0';
		runidleuser	:	out std_logic;
		shiftuser	:	out std_logic;
		tck	:	in std_logic := '0';
		tckcore	:	in std_logic := '0';
		tckutap	:	out std_logic;
		tdi	:	in std_logic := '0';
		tdicore	:	in std_logic := '0';
		tdiutap	:	out std_logic;
		tdo	:	out std_logic;
		tdocore	:	out std_logic;
		tdouser	:	in std_logic := '0';
		tdoutap	:	in std_logic := '0';
		tms	:	in std_logic := '0';
		tmscore	:	in std_logic := '0';
		tmsutap	:	out std_logic;
		updateuser	:	out std_logic;
		usr1user	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- twentynm_io_obuf parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_io_obuf
	generic (
		bus_hold	:	string := "false";
		lpm_type	:	string := "twentynm_io_obuf";
		open_drain_output	:	string := "false";
		shift_series_termination_control	:	string := "false"	);
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
-- twentynm_mac parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_mac
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
		input_pipeline_clock	:	string := "none";
		load_const_clock	:	string := "none";
		load_const_value	:	natural := 0;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "twentynm_mac";
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
-- twentynm_ddio_in parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_ddio_in
	generic (
		async_mode	:	string := "none";
		lpm_type	:	string := "twentynm_ddio_in";
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
-- twentynm_tile_ctrl parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_tile_ctrl
	generic (
		dll_ctl_static	:	std_logic_vector(8 downto 0) := "000000000";
		dll_ctlsel	:	string := "ctl_dynamic";
		dll_ctlsel_core	:	string := "ctl_core";
		dll_en	:	string := "dll_dis";
		dll_exponent_0	:	std_logic_vector(2 downto 0) := "000";
		dll_exponent_1	:	std_logic_vector(2 downto 0) := "000";
		dll_mantissa_0	:	std_logic_vector(4 downto 0) := "00000";
		dll_mantissa_1	:	std_logic_vector(4 downto 0) := "00000";
		dll_mode	:	string := "ddr_mode";
		dll_phase_offset_0	:	std_logic_vector(6 downto 0) := "0000000";
		dll_phase_offset_1	:	std_logic_vector(6 downto 0) := "0000000";
		hmc_add_lat	:	std_logic_vector(6 downto 0) := "0000000";
		hmc_addr_order	:	string := "chip_bank_row_col";
		hmc_auto_pd_cycles	:	std_logic_vector(17 downto 0) := "000000000000000000";
		hmc_ca_pos	:	string := "lane0to2";
		hmc_cas_wr_lat	:	std_logic_vector(5 downto 0) := "000101";
		hmc_cfg_pinpong_mode	:	string := "pingpong_off";
		hmc_clr_intr	:	string := "disable";
		hmc_crc_en	:	string := "disable";
		hmc_ctl_usr_refresh	:	string := "zero";
		hmc_ctrl2dbc_switch0	:	string := "local_tile_dbc0";
		hmc_ctrl2dbc_switch1	:	string := "local_tile_dbc1";
		hmc_ctrl_ac_pos	:	string := "use_0_1_2_lane";
		hmc_ctrl_burst_length	:	string := "bl_8_ctrl";
		hmc_ctrl_cmd_rate	:	string := "half_rate";
		hmc_ctrl_dimm_type	:	string := "component";
		hmc_ctrl_dualport_en	:	string := "disable";
		hmc_ctrl_enable_ecc	:	string := "disable";
		hmc_ctrl_in_protocol	:	string := "ast_in";
		hmc_ctrl_mem_type	:	string := "ddr3";
		hmc_ctrl_output_regd	:	string := "disable";
		hmc_ctrl_reorder_data	:	string := "disable";
		hmc_dbc0_burst_length	:	string := "bl_8_dbc0";
		hmc_dbc0_cmd_rate	:	string := "half_rate_dbc0";
		hmc_dbc0_ctrl_sel	:	string := "upper_mux_dbc0";
		hmc_dbc0_dualport_en	:	string := "disable";
		hmc_dbc0_enable_ecc	:	string := "disable";
		hmc_dbc0_in_protocol	:	string := "ast_dbc0";
		hmc_dbc0_output_regd	:	string := "disable";
		hmc_dbc0_pipe_lat	:	std_logic_vector(2 downto 0) := "000";
		hmc_dbc0_reorder_data	:	string := "disable";
		hmc_dbc1_burst_length	:	string := "bl_8_dbc1";
		hmc_dbc1_cmd_rate	:	string := "half_rate_dbc1";
		hmc_dbc1_ctrl_sel	:	string := "upper_mux_dbc1";
		hmc_dbc1_dualport_en	:	string := "disable";
		hmc_dbc1_enable_ecc	:	string := "disable";
		hmc_dbc1_in_protocol	:	string := "ast_dbc1";
		hmc_dbc1_output_regd	:	string := "disable";
		hmc_dbc1_pipe_lat	:	std_logic_vector(2 downto 0) := "000";
		hmc_dbc1_reorder_data	:	string := "disable";
		hmc_dbc2_burst_length	:	string := "bl_8_dbc2";
		hmc_dbc2_cmd_rate	:	string := "half_rate_dbc2";
		hmc_dbc2_ctrl_sel	:	string := "upper_mux_dbc2";
		hmc_dbc2_dualport_en	:	string := "disable";
		hmc_dbc2_enable_ecc	:	string := "disable";
		hmc_dbc2_in_protocol	:	string := "ast_dbc2";
		hmc_dbc2_output_regd	:	string := "disable";
		hmc_dbc2_pipe_lat	:	std_logic_vector(2 downto 0) := "000";
		hmc_dbc2_reorder_data	:	string := "disable";
		hmc_dbc2ctrl_sel	:	string := "dbc0_to_local";
		hmc_dbc3_burst_length	:	string := "bl_8_dbc3";
		hmc_dbc3_cmd_rate	:	string := "half_rate_dbc3";
		hmc_dbc3_ctrl_sel	:	string := "upper_mux_dbc3";
		hmc_dbc3_dualport_en	:	string := "disable";
		hmc_dbc3_enable_ecc	:	string := "disable";
		hmc_dbc3_in_protocol	:	string := "ast_dbc3";
		hmc_dbc3_output_regd	:	string := "disable";
		hmc_dbc3_pipe_lat	:	std_logic_vector(2 downto 0) := "000";
		hmc_dbc3_reorder_data	:	string := "disable";
		hmc_dbi_en	:	string := "disable";
		hmc_device_width	:	string := "device_x8";
		hmc_enable_auto_corr	:	string := "disable";
		hmc_enable_dm	:	string := "enable";
		hmc_enable_dqs_tracking	:	string := "enable";
		hmc_enable_ecc_code_overwrites	:	string := "disable";
		hmc_enable_intr	:	string := "disable";
		hmc_fgr_en	:	string := "disable";
		hmc_geardn_en	:	string := "disable";
		hmc_gen_dbe	:	string := "disable";
		hmc_gen_sbe	:	string := "disable";
		hmc_interface_width	:	string := "dwidth_8";
		hmc_local_if_cs_width	:	string := "cs_width_2";
		hmc_lpasr_en	:	string := "disable";
		hmc_mask_corr_dropped_intr	:	string := "disable";
		hmc_mask_dbe_intr	:	string := "disable";
		hmc_mask_sbe_intr	:	string := "disable";
		hmc_mem_clk_disable_entry_cycles	:	std_logic_vector(5 downto 0) := "001010";
		hmc_mem_if_bankaddr_width	:	string := "bank_width_3";
		hmc_mem_if_coladdr_width	:	string := "col_width_12";
		hmc_mem_if_rowaddr_width	:	string := "row_width_16";
		hmc_open_page_en	:	string := "disable";
		hmc_parity_en	:	string := "disable";
		hmc_pasr_en	:	string := "disable";
		hmc_pdn_exit_cycles	:	string := "slow_exit";
		hmc_power_saving_exit_cycles	:	std_logic_vector(5 downto 0) := "000101";
		hmc_read_odt_chip	:	std_logic_vector(15 downto 0) := "0000000000000000";
		hmc_reorder_cmd	:	string := "disable";
		hmc_reserve0	:	std_logic_vector(15 downto 0) := "0000000000000000";
		hmc_self_rfsh_exit_cycles	:	string := "self_rfsh_exit_cycles_512";
		hmc_starve_limit	:	std_logic_vector(5 downto 0) := "111111";
		hmc_tccd	:	std_logic_vector(5 downto 0) := "000100";
		hmc_tcl	:	std_logic_vector(6 downto 0) := "0000110";
		hmc_tfaw	:	std_logic_vector(7 downto 0) := "00010000";
		hmc_tile_id	:	std_logic_vector(4 downto 0) := "00000";
		hmc_tmrd	:	std_logic_vector(5 downto 0) := "000010";
		hmc_tras	:	std_logic_vector(5 downto 0) := "010000";
		hmc_trc	:	std_logic_vector(7 downto 0) := "00010110";
		hmc_trcd	:	std_logic_vector(5 downto 0) := "000110";
		hmc_trefi	:	std_logic_vector(14 downto 0) := "000110000110000";
		hmc_trfc	:	std_logic_vector(9 downto 0) := "0000100010";
		hmc_trp	:	std_logic_vector(5 downto 0) := "000110";
		hmc_trrd	:	std_logic_vector(5 downto 0) := "000100";
		hmc_trtp	:	std_logic_vector(5 downto 0) := "000100";
		hmc_tsaw	:	std_logic_vector(7 downto 0) := "00010000";
		hmc_twr	:	std_logic_vector(5 downto 0) := "000110";
		hmc_twtr	:	std_logic_vector(5 downto 0) := "000100";
		hmc_write_odt_chip	:	std_logic_vector(15 downto 0) := "0000000000000000";
		lpm_type	:	string := "twentynm_tile_ctrl";
		mode	:	string := "tile_ddr";
		physeq_avl_ena	:	string := "avl_disable";
		physeq_bc_id_ena	:	string := "bc_disable";
		physeq_hmc_id	:	std_logic_vector(8 downto 0) := "000000000";
		physeq_hmc_or_core	:	string := "core";
		physeq_phy_clk_sel	:	string := "phy_clk0";
		physeq_tile_id	:	std_logic_vector(8 downto 0) := "000000000";
		physeq_trk_mgr_mrnk_mode	:	string := "one_rank";
		physeq_trk_mgr_read_monitor_ena	:	string := "disable"	);
	port(
		afi_cmd_bus	:	out std_logic_vector(383 downto 0);
		afi_core2ctl	:	in std_logic_vector(16 downto 0) := (others => '0');
		afi_ctl2core	:	out std_logic_vector(25 downto 0);
		afi_lane0_to_ctl	:	in std_logic_vector(15 downto 0) := (others => '0');
		afi_lane1_to_ctl	:	in std_logic_vector(15 downto 0) := (others => '0');
		afi_lane2_to_ctl	:	in std_logic_vector(15 downto 0) := (others => '0');
		afi_lane3_to_ctl	:	in std_logic_vector(15 downto 0) := (others => '0');
		cal_avl_in	:	in std_logic_vector(54 downto 0) := (others => '0');
		cal_avl_in_from_lane0	:	in std_logic_vector(32 downto 0) := (others => '0');
		cal_avl_in_from_lane1	:	in std_logic_vector(32 downto 0) := (others => '0');
		cal_avl_in_from_lane2	:	in std_logic_vector(32 downto 0) := (others => '0');
		cal_avl_in_from_lane3	:	in std_logic_vector(32 downto 0) := (others => '0');
		cal_avl_out_to_lanes	:	out std_logic_vector(53 downto 0);
		cal_avl_rdata_in	:	in std_logic_vector(31 downto 0) := (others => '0');
		cal_avl_rdata_out	:	out std_logic_vector(31 downto 0);
		cfg_core2ctl	:	in std_logic_vector(42 downto 0) := (others => '0');
		cfg_ctl2core	:	out std_logic_vector(15 downto 0);
		cfg_dbc0	:	in std_logic_vector(11 downto 0) := (others => '0');
		cfg_dbc1	:	in std_logic_vector(11 downto 0) := (others => '0');
		cfg_dbc2	:	in std_logic_vector(11 downto 0) := (others => '0');
		cfg_dbc3	:	in std_logic_vector(11 downto 0) := (others => '0');
		core2ctl_avl0	:	in std_logic_vector(60 downto 0) := (others => '0');
		core2ctl_avl1	:	in std_logic_vector(60 downto 0) := (others => '0');
		core_clk_fb_in	:	in std_logic_vector(1 downto 0) := (others => '0');
		core_clk_out	:	out std_logic_vector(1 downto 0);
		core_dll	:	in std_logic_vector(11 downto 0) := (others => '0');
		ctl2core_avl0	:	out std_logic_vector(13 downto 0);
		ctl2core_avl1	:	out std_logic_vector(13 downto 0);
		ctl2core_soc_out	:	out std_logic_vector(13 downto 0);
		ctl2dbc0	:	out std_logic_vector(42 downto 0);
		ctl2dbc1	:	out std_logic_vector(42 downto 0);
		ctl2dbc_in_down	:	in std_logic_vector(42 downto 0) := (others => '0');
		ctl2dbc_in_up	:	in std_logic_vector(42 downto 0) := (others => '0');
		ctl_mem_clk_disable	:	out std_logic_vector(1 downto 0);
		dbc2ctl0	:	in std_logic_vector(20 downto 0) := (others => '0');
		dbc2ctl1	:	in std_logic_vector(20 downto 0) := (others => '0');
		dbc2ctl2	:	in std_logic_vector(20 downto 0) := (others => '0');
		dbc2ctl3	:	in std_logic_vector(20 downto 0) := (others => '0');
		dll_clk_in	:	in std_logic := '0';
		dqs_in0	:	in std_logic_vector(1 downto 0) := (others => '0');
		dqs_in1	:	in std_logic_vector(1 downto 0) := (others => '0');
		dqs_in2	:	in std_logic_vector(1 downto 0) := (others => '0');
		dqs_in3	:	in std_logic_vector(1 downto 0) := (others => '0');
		dqs_out0	:	out std_logic_vector(1 downto 0);
		dqs_out1	:	out std_logic_vector(1 downto 0);
		dqs_out2	:	out std_logic_vector(1 downto 0);
		dqs_out3	:	out std_logic_vector(1 downto 0);
		global_reset_n	:	in std_logic := '0';
		hmc_core_clk_in	:	in std_logic := '0';
		mmr_in	:	in std_logic_vector(50 downto 0) := (others => '0');
		mmr_out	:	out std_logic_vector(33 downto 0);
		mrnk_read_core	:	in std_logic_vector(3 downto 0) := (others => '0');
		phy_clk_out0	:	out std_logic_vector(9 downto 0);
		phy_clk_out1	:	out std_logic_vector(9 downto 0);
		phy_clk_out2	:	out std_logic_vector(9 downto 0);
		phy_clk_out3	:	out std_logic_vector(9 downto 0);
		ping_pong_alert_n_in	:	in std_logic := '0';
		ping_pong_alert_n_out	:	out std_logic;
		ping_pong_in	:	in std_logic_vector(43 downto 0) := (others => '0');
		ping_pong_out	:	out std_logic_vector(43 downto 0);
		pll_clk_in	:	in std_logic_vector(1 downto 0) := (others => '0');
		pll_locked_in	:	in std_logic := '0';
		pll_vco_in	:	in std_logic_vector(7 downto 0) := (others => '0');
		pvt_ref_gry	:	out std_logic_vector(8 downto 0);
		rdata_en_full_core	:	in std_logic_vector(3 downto 0) := (others => '0');
		seq2core_reset_n	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- twentynm_cmu_fpll_refclk_select parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_cmu_fpll_refclk_select
	generic (
		lpm_type	:	string := "twentynm_cmu_fpll_refclk_select";
		mux0_inclk0_logical_to_physical_mapping	:	string := "ref_iqclk0";
		mux0_inclk1_logical_to_physical_mapping	:	string := "ref_iqclk0";
		mux0_inclk2_logical_to_physical_mapping	:	string := "ref_iqclk0";
		mux0_inclk3_logical_to_physical_mapping	:	string := "ref_iqclk0";
		mux0_inclk4_logical_to_physical_mapping	:	string := "ref_iqclk0";
		mux1_inclk0_logical_to_physical_mapping	:	string := "ref_iqclk0";
		mux1_inclk1_logical_to_physical_mapping	:	string := "ref_iqclk0";
		mux1_inclk2_logical_to_physical_mapping	:	string := "ref_iqclk0";
		mux1_inclk3_logical_to_physical_mapping	:	string := "ref_iqclk0";
		mux1_inclk4_logical_to_physical_mapping	:	string := "ref_iqclk0";
		pll_auto_clk_sw_en	:	string := "false";
		pll_clk_loss_edge	:	string := "pll_clk_loss_both_edges";
		pll_clk_loss_sw_en	:	string := "false";
		pll_clk_sw_dly	:	natural := 0;
		pll_clkin_0_src	:	string := "pll_clkin_0_src_vss";
		pll_clkin_1_src	:	string := "pll_clkin_1_src_vss";
		pll_manu_clk_sw_en	:	string := "false";
		pll_sw_refclk_src	:	string := "pll_sw_refclk_src_clk_0";
		refclk_select0	:	string := "ref_iqclk0";
		refclk_select1	:	string := "ref_iqclk0";
		silicon_rev	:	string := "reve";
		xpm_iqref_mux0_iqclk_sel	:	string := "power_down";
		xpm_iqref_mux0_scratch0_src	:	string := "scratch0_refclk";
		xpm_iqref_mux0_scratch1_src	:	string := "scratch1_refclk";
		xpm_iqref_mux0_scratch2_src	:	string := "scratch2_refclk";
		xpm_iqref_mux0_scratch3_src	:	string := "scratch3_refclk";
		xpm_iqref_mux0_scratch4_src	:	string := "scratch4_refclk";
		xpm_iqref_mux1_iqclk_sel	:	string := "power_down";
		xpm_iqref_mux1_scratch0_src	:	string := "scratch0_refclk";
		xpm_iqref_mux1_scratch1_src	:	string := "scratch1_refclk";
		xpm_iqref_mux1_scratch2_src	:	string := "scratch2_refclk";
		xpm_iqref_mux1_scratch3_src	:	string := "scratch3_refclk";
		xpm_iqref_mux1_scratch4_src	:	string := "scratch4_refclk"	);
	port(
		avmmaddress	:	in std_logic_vector(8 downto 0) := (others => '0');
		avmmclk	:	in std_logic := '0';
		avmmread	:	in std_logic := '0';
		avmmreaddata	:	out std_logic_vector(7 downto 0);
		avmmrstn	:	in std_logic := '1';
		avmmwrite	:	in std_logic := '0';
		avmmwritedata	:	in std_logic_vector(7 downto 0) := (others => '0');
		blockselect	:	out std_logic;
		clk0bad	:	out std_logic;
		clk1bad	:	out std_logic;
		clk_src	:	out std_logic_vector(1 downto 0);
		core_refclk	:	in std_logic := '0';
		extswitch	:	in std_logic := '0';
		extswitch_buf	:	out std_logic;
		iqtxrxclk	:	in std_logic_vector(5 downto 0) := (others => '0');
		outclk	:	out std_logic;
		pll_cascade_in	:	in std_logic := '0';
		pllclksel	:	out std_logic;
		ref_iqclk	:	in std_logic_vector(11 downto 0) := (others => '0');
		refclk	:	in std_logic := '0';
		tx_rx_core_refclk	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- twentynm_io_pad parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_io_pad
	generic (
		lpm_type	:	string := "twentynm_io_pad"	);
	port(
		padin	:	in std_logic := '0';
		padout	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- twentynm_clkburst parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_clkburst
	generic (
		burstcnt_ctrl	:	string := "static";
		lpm_type	:	string := "twentynm_clkburst";
		static_burstcnt	:	string := "cnt0"	);
	port(
		burstcnt	:	in std_logic_vector(2 downto 0) := (others => '0');
		ena	:	in std_logic := '0';
		enaout	:	out std_logic;
		inclk	:	in std_logic := '0'
	);
end component;

------------------------------------------------------------------
-- twentynm_io_12_lane parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_io_12_lane
	generic (
		avl_base_addr	:	std_logic_vector(8 downto 0) := "000000000";
		avl_bc_id_ena	:	string := "false";
		avl_ena	:	string := "false";
		db_crc_dq0	:	string := "crc_dq0_pin0";
		db_crc_dq1	:	string := "crc_dq1_pin0";
		db_crc_dq2	:	string := "crc_dq2_pin0";
		db_crc_dq3	:	string := "crc_dq3_pin0";
		db_crc_dq4	:	string := "crc_dq4_pin0";
		db_crc_dq5	:	string := "crc_dq5_pin0";
		db_crc_dq6	:	string := "crc_dq6_pin0";
		db_crc_dq7	:	string := "crc_dq7_pin0";
		db_crc_dq8	:	string := "crc_dq8_pin0";
		db_crc_en	:	string := "crc_disable";
		db_crc_x4_or_x8_or_x9	:	string := "x8_mode";
		db_dbi_en	:	string := "dbi_disable";
		db_dbi_sel	:	string := "dbi_dq0";
		db_pin_0_bypass	:	string := "true";
		db_pin_0_mode	:	string := "dq_mode";
		db_pin_0_oe_invert	:	string := "false";
		db_pin_0_wr_invert	:	string := "false";
		db_pin_10_bypass	:	string := "true";
		db_pin_10_mode	:	string := "dq_mode";
		db_pin_10_oe_invert	:	string := "false";
		db_pin_10_wr_invert	:	string := "false";
		db_pin_11_bypass	:	string := "true";
		db_pin_11_mode	:	string := "dq_mode";
		db_pin_11_oe_invert	:	string := "false";
		db_pin_11_wr_invert	:	string := "false";
		db_pin_1_bypass	:	string := "true";
		db_pin_1_mode	:	string := "dq_mode";
		db_pin_1_oe_invert	:	string := "false";
		db_pin_1_wr_invert	:	string := "false";
		db_pin_2_bypass	:	string := "true";
		db_pin_2_mode	:	string := "dq_mode";
		db_pin_2_oe_invert	:	string := "false";
		db_pin_2_wr_invert	:	string := "false";
		db_pin_3_bypass	:	string := "true";
		db_pin_3_mode	:	string := "dq_mode";
		db_pin_3_oe_invert	:	string := "false";
		db_pin_3_wr_invert	:	string := "false";
		db_pin_4_bypass	:	string := "true";
		db_pin_4_mode	:	string := "dq_mode";
		db_pin_4_oe_invert	:	string := "false";
		db_pin_4_wr_invert	:	string := "false";
		db_pin_5_bypass	:	string := "true";
		db_pin_5_mode	:	string := "dq_mode";
		db_pin_5_oe_invert	:	string := "false";
		db_pin_5_wr_invert	:	string := "false";
		db_pin_6_bypass	:	string := "true";
		db_pin_6_mode	:	string := "dq_mode";
		db_pin_6_oe_invert	:	string := "false";
		db_pin_6_wr_invert	:	string := "false";
		db_pin_7_bypass	:	string := "true";
		db_pin_7_mode	:	string := "dq_mode";
		db_pin_7_oe_invert	:	string := "false";
		db_pin_7_wr_invert	:	string := "false";
		db_pin_8_bypass	:	string := "true";
		db_pin_8_mode	:	string := "dq_mode";
		db_pin_8_oe_invert	:	string := "false";
		db_pin_8_wr_invert	:	string := "false";
		db_pin_9_bypass	:	string := "true";
		db_pin_9_mode	:	string := "dq_mode";
		db_pin_9_oe_invert	:	string := "false";
		db_pin_9_wr_invert	:	string := "false";
		dqs_lgc_burst_length	:	string := "burst_length_2";
		dqs_lgc_count_threshold	:	std_logic_vector(6 downto 0) := "0000000";
		dqs_lgc_phase_shift	:	std_logic_vector(11 downto 0) := "000000000000";
		dqs_lgc_pst_ddr4_preamble_en	:	string := "false";
		dqs_lgc_pst_en_shrink	:	std_logic_vector(1 downto 0) := "00";
		lpm_type	:	string := "twentynm_io_12_lane";
		mode_rate_in	:	string := "in_rate_1_4";
		mode_rate_out	:	string := "out_rate_full";
		phy_clk_phs_freq	:	natural := 1000;
		pin_0_alignment_mode	:	string := "data";
		pin_0_mode_ddr	:	string := "mode_ddr";
		pin_10_alignment_mode	:	string := "data";
		pin_10_mode_ddr	:	string := "mode_ddr";
		pin_11_alignment_mode	:	string := "data";
		pin_11_mode_ddr	:	string := "mode_ddr";
		pin_1_alignment_mode	:	string := "data";
		pin_1_mode_ddr	:	string := "mode_ddr";
		pin_2_alignment_mode	:	string := "data";
		pin_2_mode_ddr	:	string := "mode_ddr";
		pin_3_alignment_mode	:	string := "data";
		pin_3_mode_ddr	:	string := "mode_ddr";
		pin_4_alignment_mode	:	string := "data";
		pin_4_mode_ddr	:	string := "mode_ddr";
		pin_5_alignment_mode	:	string := "data";
		pin_5_mode_ddr	:	string := "mode_ddr";
		pin_6_alignment_mode	:	string := "data";
		pin_6_mode_ddr	:	string := "mode_ddr";
		pin_7_alignment_mode	:	string := "data";
		pin_7_mode_ddr	:	string := "mode_ddr";
		pin_8_alignment_mode	:	string := "data";
		pin_8_mode_ddr	:	string := "mode_ddr";
		pin_9_alignment_mode	:	string := "data";
		pin_9_mode_ddr	:	string := "mode_ddr";
		read_latency	:	std_logic_vector(7 downto 0) := "00000000";
		vref_mode	:	string := "vref_ext";
		vref_no_cal_val	:	string := "vccn_0_45";
		write_latency	:	std_logic_vector(9 downto 0) := "0000000000"	);
	port(
		ac_hmc	:	in std_logic_vector(95 downto 0) := (others => '0');
		avl_address	:	in std_logic_vector(19 downto 0) := (others => '0');
		avl_base_hit	:	out std_logic;
		avl_clk	:	in std_logic := '0';
		avl_read	:	in std_logic := '0';
		avl_readdata	:	out std_logic_vector(31 downto 0);
		avl_write	:	in std_logic := '0';
		avl_writedata	:	in std_logic_vector(31 downto 0) := (others => '0');
		cfg_cmd_rate	:	in std_logic_vector(2 downto 0) := (others => '0');
		cfg_dbc_ctrl_sel	:	in std_logic := '0';
		cfg_dbc_dualport_en	:	in std_logic := '0';
		cfg_dbc_in_protocol	:	in std_logic := '0';
		cfg_dbc_pipe_lat	:	in std_logic_vector(2 downto 0) := (others => '0');
		cfg_enable_ecc	:	in std_logic := '0';
		cfg_output_regd	:	in std_logic := '0';
		cfg_reorder_data	:	in std_logic := '0';
		ctl2dbc_mask_entry0	:	in std_logic := '0';
		ctl2dbc_mask_entry1	:	in std_logic := '0';
		ctl2dbc_mrnk_read0	:	in std_logic_vector(7 downto 0) := (others => '0');
		ctl2dbc_mrnk_read1	:	in std_logic_vector(7 downto 0) := (others => '0');
		ctl2dbc_rb_rdptr0	:	in std_logic_vector(11 downto 0) := (others => '0');
		ctl2dbc_rb_rdptr1	:	in std_logic_vector(11 downto 0) := (others => '0');
		ctl2dbc_rb_rdptr_vld0	:	in std_logic_vector(1 downto 0) := (others => '0');
		ctl2dbc_rb_rdptr_vld1	:	in std_logic_vector(1 downto 0) := (others => '0');
		ctl2dbc_rb_wrptr0	:	in std_logic_vector(5 downto 0) := (others => '0');
		ctl2dbc_rb_wrptr1	:	in std_logic_vector(5 downto 0) := (others => '0');
		ctl2dbc_rb_wrptr_vld0	:	in std_logic := '0';
		ctl2dbc_rb_wrptr_vld1	:	in std_logic := '0';
		ctl2dbc_rdata_en_full0	:	in std_logic_vector(3 downto 0) := (others => '0');
		ctl2dbc_rdata_en_full1	:	in std_logic_vector(3 downto 0) := (others => '0');
		ctl2dbc_seq_en0	:	in std_logic := '0';
		ctl2dbc_seq_en1	:	in std_logic := '0';
		ctl2dbc_wb_rdptr0	:	in std_logic_vector(5 downto 0) := (others => '0');
		ctl2dbc_wb_rdptr1	:	in std_logic_vector(5 downto 0) := (others => '0');
		ctl2dbc_wb_rdptr_vld0	:	in std_logic := '0';
		ctl2dbc_wb_rdptr_vld1	:	in std_logic := '0';
		ctl2dbc_wrdata_vld0	:	in std_logic := '0';
		ctl2dbc_wrdata_vld1	:	in std_logic := '0';
		data_from_core	:	in std_logic_vector(95 downto 0) := (others => '0');
		data_in	:	in std_logic_vector(11 downto 0) := (others => '0');
		data_oe	:	out std_logic_vector(11 downto 0);
		data_out	:	out std_logic_vector(11 downto 0);
		data_to_core	:	out std_logic_vector(95 downto 0);
		dbc2ctl_rb_retire_ptr	:	out std_logic_vector(5 downto 0);
		dbc2ctl_rb_retire_ptr_vld	:	out std_logic;
		dbc2ctl_wb_retire_ptr	:	out std_logic_vector(5 downto 0);
		dbc2ctl_wb_retire_ptr_vld	:	out std_logic;
		dbc2db_wb_wrptr	:	out std_logic_vector(5 downto 0);
		dbc2db_wb_wrptr_vld	:	out std_logic;
		dll_value	:	in std_logic_vector(8 downto 0) := (others => '0');
		dqs_burst_core	:	in std_logic_vector(3 downto 0) := (others => '0');
		dqs_in_a	:	in std_logic := '0';
		dqs_in_b	:	in std_logic := '0';
		mrnk_read_core	:	in std_logic_vector(1 downto 0) := (others => '0');
		mrnk_write_core	:	in std_logic_vector(1 downto 0) := (others => '0');
		oeb_from_core	:	in std_logic_vector(47 downto 0) := (others => '0');
		phy_clk	:	in std_logic := '0';
		phy_clk_phs	:	in std_logic_vector(7 downto 0) := (others => '0');
		rdata_en_full_core	:	in std_logic_vector(3 downto 0) := (others => '0');
		rdata_valid_core	:	out std_logic_vector(3 downto 0);
		reset_n	:	in std_logic := '0';
		wdata_valid_core	:	in std_logic_vector(3 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- twentynm_asmiblock parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_asmiblock
	generic (
		lpm_type	:	string := "twentynm_asmiblock"	);
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
		sce	:	in std_logic_vector(2 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- twentynm_io_serdes_dpa parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_io_serdes_dpa
	generic (
		align_to_rising_edge_only	:	string := "false";
		bitslip_rollover	:	natural := 10;
		data_width	:	natural := 10;
		enable_clock_pin_mode	:	string := "false";
		is_negative_ppm_drift	:	string := "false";
		loopback_mode	:	natural := 0;
		lose_lock_on_one_change	:	string := "false";
		lpm_type	:	string := "twentynm_io_serdes_dpa";
		mode	:	string := "off_mode";
		net_ppm_variation	:	natural := 0;
		reset_fifo_at_first_lock	:	string := "false"	);
	port(
		bitslipcntl	:	in std_logic := '0';
		bitslipmax	:	out std_logic;
		bitslipreset	:	in std_logic := '0';
		dpaclk	:	in std_logic_vector(7 downto 0) := (others => '0');
		dpafiforeset	:	in std_logic := '0';
		dpahold	:	in std_logic := '0';
		dpalock	:	out std_logic;
		dpareset	:	in std_logic := '0';
		dpaswitch	:	in std_logic := '0';
		fclk	:	in std_logic := '0';
		fclkcorein	:	in std_logic := '0';
		loaden	:	in std_logic := '0';
		loadencorein	:	in std_logic := '0';
		loopbackin	:	in std_logic := '0';
		loopbackout	:	out std_logic;
		lvdsin	:	in std_logic := '0';
		lvdsout	:	out std_logic;
		pclk	:	out std_logic;
		pclkcorein	:	in std_logic := '0';
		pclkioin	:	in std_logic := '0';
		rxdata	:	out std_logic_vector(9 downto 0);
		txdata	:	in std_logic_vector(9 downto 0) := (others => '0')
	);
end component;

------------------------------------------------------------------
-- twentynm_mlab_cell parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_mlab_cell
	generic (
		address_width	:	natural := 1;
		byte_enable_mask_width	:	natural := 2;
		data_width	:	natural := 1;
		first_address	:	natural;
		first_bit_number	:	natural;
		init_file	:	string := "UNUSED";
		last_address	:	natural;
		logical_ram_depth	:	natural := 0;
		logical_ram_name	:	string := "UNUSED";
		logical_ram_width	:	natural := 0;
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "twentynm_mlab_cell";
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
-- twentynm_ram_block parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_ram_block
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
		ecc_pipeline_stage_enabled	:	string := "false";
		enable_ecc	:	string := "false";
		init_file	:	string := "UNUSED";
		init_file_layout	:	string := "UNUSED";
		logical_ram_name	:	string := "UNUSED";
		lpm_hint	:	string := "UNUSED";
		lpm_type	:	string := "twentynm_ram_block";
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
-- twentynm_atx_pll parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_atx_pll
	generic (
		bw_sel	:	string := "auto";
		caliberation_mode	:	string := "cal_off";
		cascadeclk_test	:	string := "cascadetest_off";
		cgb_div	:	natural := 1;
		cp_compensation_enable	:	string := "true";
		cp_current_setting	:	string := "cp_current_setting0";
		cp_lf_3rd_pole_freq	:	string := "lf_3rd_pole_setting0";
		cp_lf_4th_pole_freq	:	string := "lf_4th_pole_setting0";
		cp_lf_order	:	string := "lf_2nd_order";
		cp_testmode	:	string := "cp_normal";
		d2a_voltage	:	string := "d2a_disable";
		dsm_ecn_bypass	:	string := "false";
		dsm_ecn_test_en	:	string := "false";
		dsm_fractional_division	:	natural := 1;
		dsm_fractional_value_ready	:	string := "pll_k_ready";
		dsm_mode	:	string := "dsm_mode_integer";
		dsm_out_sel	:	string := "pll_dsm_disable";
		fb_select	:	string := "direct_fb";
		hclk_divide	:	natural := 1;
		iqclk_mux_sel	:	string := "power_down";
		is_cascaded_pll	:	string := "false";
		l_counter	:	natural := 1;
		l_counter_enable	:	string := "false";
		lc_atb	:	string := "atb_selectdisable";
		lc_mode	:	string := "lccmu_pd";
		lf_resistance	:	string := "lf_setting0";
		lf_ripplecap	:	string := "lf_ripple_cap";
		lpm_type	:	string := "twentynm_atx_pll";
		m_counter	:	natural := 1;
		output_clock_frequency	:	string := "0 ps";
		output_regulator_supply	:	string := "vreg1v_setting1";
		overrange_voltage	:	string := "over_setting3";
		pma_width	:	natural := 8;
		prot_mode	:	string := "basic";
		ref_clk_div	:	natural := 1;
		reference_clock_frequency	:	string := "0 ps";
		silicon_rev	:	string := "reve";
		speed_grade	:	string := "2";
		tank_band	:	string := "lc_band0";
		tank_sel	:	string := "lctank0";
		tank_voltage_coarse	:	string := "vreg_setting_coarse1";
		tank_voltage_fine	:	string := "vreg_setting3";
		underrange_voltage	:	string := "under_setting3";
		use_default_base_address	:	string := "true";
		user_base_address	:	natural := 0;
		vco_bypass_enable	:	string := "false";
		vreg0_output	:	string := "vccdreg_nominal";
		vreg1_output	:	string := "vccdreg_nominal"	);
	port(
		avmmaddress	:	in std_logic_vector(8 downto 0) := (others => '0');
		avmmclk	:	in std_logic := '0';
		avmmread	:	in std_logic := '0';
		avmmreaddata	:	out std_logic_vector(7 downto 0);
		avmmrstn	:	in std_logic := '1';
		avmmwrite	:	in std_logic := '0';
		avmmwritedata	:	in std_logic_vector(7 downto 0) := (others => '0');
		blockselect	:	out std_logic;
		clk0_16g	:	out std_logic;
		clk0_8g	:	out std_logic;
		clk180_16g	:	out std_logic;
		clk180_8g	:	out std_logic;
		clklow	:	out std_logic;
		fref	:	out std_logic;
		hclk_out	:	out std_logic;
		iqtxrxclk	:	in std_logic_vector(5 downto 0) := (others => '0');
		iqtxrxclk_out	:	out std_logic;
		lf_rst_n	:	in std_logic := '1';
		lock	:	out std_logic;
		overrange	:	out std_logic;
		refclk	:	in std_logic := '0';
		rst_n	:	in std_logic := '1';
		underrange	:	out std_logic
	);
end component;

------------------------------------------------------------------
-- twentynm_uib_cell parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_uib_cell
	generic (
		external_clock_source	:	string := "CLK3";
		external_datain_strength	:	string := "LOW_STRENGTH";
		logical_function	:	string := "None";
		logical_name	:	string := "UNUSED";
		loopback_mode	:	string := "false";
		lpm_type	:	string := "twentynm_uib_cell";
		read_clock_enable	:	string := "None";
		read_mode	:	string := "MUX_BYPASS";
		read_port_bit_index	:	natural := -1;
		read_port_name	:	string := "UNUSED";
		write_clock_enable	:	string := "None";
		write_mode	:	string := "MUX_BYPASS";
		write_port_bit_index	:	natural := -1;
		write_port_name	:	string := "UNUSED"	);
	port(
		clk0	:	in std_logic := '0';
		clk1	:	in std_logic := '0';
		clk2	:	in std_logic := '0';
		clk3	:	in std_logic := '0';
		clr	:	in std_logic := '0';
		datain0	:	in std_logic_vector(9 downto 0) := (others => '0');
		datain1	:	in std_logic_vector(9 downto 0) := (others => '0');
		datain2	:	in std_logic_vector(9 downto 0) := (others => '0');
		datain3	:	in std_logic_vector(9 downto 0) := (others => '0');
		dataout0	:	out std_logic_vector(9 downto 0);
		dataout1	:	out std_logic_vector(9 downto 0);
		dataout2	:	out std_logic_vector(9 downto 0);
		dataout3	:	out std_logic_vector(9 downto 0);
		ena0	:	in std_logic := '1';
		ena1	:	in std_logic := '1';
		extclkout	:	out std_logic;
		extdatain	:	in std_logic_vector(9 downto 0) := (others => '0');
		extdataout	:	out std_logic_vector(9 downto 0)
	);
end component;

------------------------------------------------------------------
-- twentynm_te_test_atom parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_te_test_atom
	generic (
		config_fname	:	string := "UNUSED";
		ip_type	:	string := "UNUSED";
		lpm_type	:	string := "twentynm_te_test_atom";
		silicon_rev	:	string := "reve"	);
	port(
		te_test_atom_inp	:	in std_logic_vector(8191 downto 0) := (others => '0');
		te_test_atom_out	:	out std_logic_vector(8191 downto 0)
	);
end component;

------------------------------------------------------------------
-- twentynm_pseudo_diff_out parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_pseudo_diff_out
	generic (
		lpm_type	:	string := "twentynm_pseudo_diff_out"	);
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
-- twentynm_phb parameterized megafunction component declaration
-- Generated with 'mega_defn_creator' loader - do not edit
------------------------------------------------------------------
component twentynm_phb
	generic (
		lpm_type	:	string := "twentynm_phb"	);
	port(
		phbinp	:	in std_logic_vector(63 downto 0) := (others => '0');
		phbout	:	out std_logic_vector(63 downto 0)
	);
end component;

--clearbox auto-generated components end
end twentynm_components;
