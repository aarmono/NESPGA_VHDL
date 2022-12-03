--
-- Copyright (C) 1988-2000 Altera Corporation
-- Any megafunction design, and related net list (encrypted or decrypted),
-- support information, device programming or simulation file, and any other
-- associated documentation or information provided by Altera or a partner
-- under Altera's Megafunction Partnership Program may be used only to
-- program PLD devices (but not masked PLD devices) from Altera.  Any other
-- use of such megafunction design, net list, support information, device
-- programming or simulation file, or any other related documentation or
-- information is prohibited for any other purpose, including, but not
-- limited to modification, reverse engineering, de-compiling, or use with
-- any other silicon devices, unless such use is explicitly licensed under
-- a separate agreement with Altera or a megafunction partner.  Title to
-- the intellectual property, including patents, copyrights, trademarks,
-- trade secrets, or maskworks, embodied in any such megafunction design,
-- net list, support information, device programming or simulation file, or
-- any other related documentation or information provided by Altera or a
-- megafunction partner, remains with Altera, the megafunction partner, or
-- their respective licensors.  No other licenses, including any licenses
-- needed under any third party's intellectual property, are provided herein.
--
-- FILENAME     :    max_components.vhd
-- FILE CONTENTS:    MAX VITAL Component Package (3.0)
-- DATE CREATED :    Tue Oct 17 17:43:50 PST 2000
--
-- LIBRARY      :    max
-- REVISION     :    QII 1.2
-- LOGIC SYSTEM :    IEEE-1164
-- NOTES        :
-- HISTORY      :
--
----------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package MAX_COMPONENTS is

component max_mcell 
  generic (	operation_mode : string := "normal";
      		output_mode : string := "comb";
      		register_mode : string := "dff";
		pexp_mode : string := "off";
		lpm_type : string := "max_mcell";
      		power_up : string := "low");

  port (	pterm0  : in std_logic_vector(35 downto 0) := (OTHERS => '1');
        	pterm1  : in std_logic_vector(35 downto 0) := (OTHERS => '1');
        	pterm2  : in std_logic_vector(35 downto 0) := (OTHERS => '1');
       	 	pterm3  : in std_logic_vector(35 downto 0) := (OTHERS => '1');
        	pterm4  : in std_logic_vector(35 downto 0) := (OTHERS => '1');
        	pterm5  : in std_logic_vector(35 downto 0) := (OTHERS => '1');
        	pclk    : in std_logic_vector(35 downto 0) := (OTHERS => '1');
        	pena    : in std_logic_vector(35 downto 0) := (OTHERS => '1');
        	paclr   : in std_logic_vector(35 downto 0) := (OTHERS => '1');
        	papre   : in std_logic_vector(35 downto 0) := (OTHERS => '1');
        	pxor    : in std_logic_vector(35 downto 0) := (OTHERS => '1');
        	pexpin  : in std_logic := '0';
        	clk     : in std_logic := '0';
        	fpin    : in std_logic := '1';
        	aclr    : in std_logic := '0';
        	dataout : out std_logic;
        	pexpout : out std_logic );
end component;

component max_io
  generic (	operation_mode : string := "input";
		open_drain_output :string := "false";
		bus_hold : string := "false";
		lpm_type : string := "max_io";
		weak_pull_up : string := "false");

  port (	datain          : in std_logic := '0';
		oe              : in std_logic := '1';
		dataout         : out std_logic;
		padio           : inout std_logic);

end component;

component max_sexp
 generic (
		lpm_type : string := "max_sexp"
		);
  port (	datain          : in std_logic_vector(35 downto 0) := (OTHERS => '1');
		dataout         : out std_logic);

end component;

end max_components;
