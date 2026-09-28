-- Copyright (C) 2025  Altera Corporation. All rights reserved.
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and any partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, the Altera Quartus Prime License Agreement,
-- the Altera IP License Agreement, or other applicable license
-- agreement, including, without limitation, that your use is for
-- the sole purpose of programming logic devices manufactured by
-- Altera and sold by Altera or its authorized distributors.  Please
-- refer to the Altera Software License Subscription Agreements 
-- on the Quartus Prime software download page.

-- VENDOR "Altera"
-- PROGRAM "Quartus Prime"
-- VERSION "Version 25.1std.0 Build 1129 10/21/2025 SC Lite Edition"

-- DATE "09/28/2026 18:43:51"

-- 
-- Device: Altera 5CGXFC5C6F27C7 Package FBGA672
-- 

-- 
-- This VHDL file should be used for Questa Altera FPGA (VHDL) only
-- 

LIBRARY ALTERA;
LIBRARY ALTERA_LNSIM;
LIBRARY CYCLONEV;
LIBRARY IEEE;
USE ALTERA.ALTERA_PRIMITIVES_COMPONENTS.ALL;
USE ALTERA_LNSIM.ALTERA_LNSIM_COMPONENTS.ALL;
USE CYCLONEV.CYCLONEV_COMPONENTS.ALL;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY 	hft_nn_top IS
    PORT (
	CLOCK_50_B5B : IN std_logic;
	KEY0 : IN std_logic;
	KEY1 : IN std_logic;
	LEDG0 : OUT std_logic;
	LEDR0 : OUT std_logic;
	LEDR1 : OUT std_logic;
	LEDR2 : OUT std_logic;
	LEDR3 : OUT std_logic
	);
END hft_nn_top;

-- Design Ports Information
-- LEDG0	=>  Location: PIN_L7,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- LEDR0	=>  Location: PIN_F7,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- LEDR1	=>  Location: PIN_F6,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- LEDR2	=>  Location: PIN_G6,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- LEDR3	=>  Location: PIN_G7,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- KEY0	=>  Location: PIN_P11,	 I/O Standard: 1.2 V,	 Current Strength: Default
-- CLOCK_50_B5B	=>  Location: PIN_R20,	 I/O Standard: 3.3-V LVTTL,	 Current Strength: Default
-- KEY1	=>  Location: PIN_P12,	 I/O Standard: 1.2 V,	 Current Strength: Default


ARCHITECTURE structure OF hft_nn_top IS
SIGNAL gnd : std_logic := '0';
SIGNAL vcc : std_logic := '1';
SIGNAL unknown : std_logic := 'X';
SIGNAL devoe : std_logic := '1';
SIGNAL devclrn : std_logic := '1';
SIGNAL devpor : std_logic := '1';
SIGNAL ww_devoe : std_logic;
SIGNAL ww_devclrn : std_logic;
SIGNAL ww_devpor : std_logic;
SIGNAL ww_CLOCK_50_B5B : std_logic;
SIGNAL ww_KEY0 : std_logic;
SIGNAL ww_KEY1 : std_logic;
SIGNAL ww_LEDG0 : std_logic;
SIGNAL ww_LEDR0 : std_logic;
SIGNAL ww_LEDR1 : std_logic;
SIGNAL ww_LEDR2 : std_logic;
SIGNAL ww_LEDR3 : std_logic;
SIGNAL \~QUARTUS_CREATED_GND~I_combout\ : std_logic;
SIGNAL \CLOCK_50_B5B~input_o\ : std_logic;
SIGNAL \CLOCK_50_B5B~inputCLKENA0_outclk\ : std_logic;
SIGNAL \KEY0~input_o\ : std_logic;
SIGNAL \KEY1~input_o\ : std_logic;
SIGNAL \input_valid~1_combout\ : std_logic;
SIGNAL \key1_d~q\ : std_logic;
SIGNAL \input_valid~0_combout\ : std_logic;
SIGNAL \input_valid~q\ : std_logic;
SIGNAL \u_nn_core|valid_stage0~0_combout\ : std_logic;
SIGNAL \u_nn_core|valid_stage0~q\ : std_logic;
SIGNAL \u_nn_core|valid_stage1~0_combout\ : std_logic;
SIGNAL \u_nn_core|valid_stage1~q\ : std_logic;
SIGNAL \u_nn_core|output_valid~0_combout\ : std_logic;
SIGNAL \u_nn_core|output_valid~q\ : std_logic;
SIGNAL \done_latched~0_combout\ : std_logic;
SIGNAL \done_latched~q\ : std_logic;
SIGNAL \u_nn_core|latency_cycles~0_combout\ : std_logic;
SIGNAL \u_nn_core|latency_cycles\ : std_logic_vector(31 DOWNTO 0);
SIGNAL \ALT_INV_KEY1~input_o\ : std_logic;
SIGNAL \ALT_INV_KEY0~input_o\ : std_logic;
SIGNAL \ALT_INV_key1_d~q\ : std_logic;
SIGNAL \ALT_INV_input_valid~q\ : std_logic;
SIGNAL \u_nn_core|ALT_INV_valid_stage0~q\ : std_logic;
SIGNAL \u_nn_core|ALT_INV_valid_stage1~q\ : std_logic;
SIGNAL \u_nn_core|ALT_INV_output_valid~q\ : std_logic;
SIGNAL \u_nn_core|ALT_INV_latency_cycles\ : std_logic_vector(1 DOWNTO 1);
SIGNAL \ALT_INV_done_latched~q\ : std_logic;

BEGIN

ww_CLOCK_50_B5B <= CLOCK_50_B5B;
ww_KEY0 <= KEY0;
ww_KEY1 <= KEY1;
LEDG0 <= ww_LEDG0;
LEDR0 <= ww_LEDR0;
LEDR1 <= ww_LEDR1;
LEDR2 <= ww_LEDR2;
LEDR3 <= ww_LEDR3;
ww_devoe <= devoe;
ww_devclrn <= devclrn;
ww_devpor <= devpor;
\ALT_INV_KEY1~input_o\ <= NOT \KEY1~input_o\;
\ALT_INV_KEY0~input_o\ <= NOT \KEY0~input_o\;
\ALT_INV_key1_d~q\ <= NOT \key1_d~q\;
\ALT_INV_input_valid~q\ <= NOT \input_valid~q\;
\u_nn_core|ALT_INV_valid_stage0~q\ <= NOT \u_nn_core|valid_stage0~q\;
\u_nn_core|ALT_INV_valid_stage1~q\ <= NOT \u_nn_core|valid_stage1~q\;
\u_nn_core|ALT_INV_output_valid~q\ <= NOT \u_nn_core|output_valid~q\;
\u_nn_core|ALT_INV_latency_cycles\(1) <= NOT \u_nn_core|latency_cycles\(1);
\ALT_INV_done_latched~q\ <= NOT \done_latched~q\;

-- Location: IOOBUF_X10_Y61_N42
\LEDG0~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \done_latched~q\,
	devoe => ww_devoe,
	o => ww_LEDG0);

-- Location: IOOBUF_X14_Y61_N53
\LEDR0~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => GND,
	devoe => ww_devoe,
	o => ww_LEDR0);

-- Location: IOOBUF_X15_Y61_N36
\LEDR1~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \u_nn_core|latency_cycles\(1),
	devoe => ww_devoe,
	o => ww_LEDR1);

-- Location: IOOBUF_X15_Y61_N53
\LEDR2~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => GND,
	devoe => ww_devoe,
	o => ww_LEDR2);

-- Location: IOOBUF_X14_Y61_N36
\LEDR3~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => GND,
	devoe => ww_devoe,
	o => ww_LEDR3);

-- Location: IOIBUF_X68_Y22_N44
\CLOCK_50_B5B~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_CLOCK_50_B5B,
	o => \CLOCK_50_B5B~input_o\);

-- Location: CLKCTRL_G10
\CLOCK_50_B5B~inputCLKENA0\ : cyclonev_clkena
-- pragma translate_off
GENERIC MAP (
	clock_type => "global clock",
	disable_mode => "low",
	ena_register_mode => "always enabled",
	ena_register_power_up => "high",
	test_syn => "high")
-- pragma translate_on
PORT MAP (
	inclk => \CLOCK_50_B5B~input_o\,
	outclk => \CLOCK_50_B5B~inputCLKENA0_outclk\);

-- Location: IOIBUF_X21_Y0_N1
\KEY0~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_KEY0,
	o => \KEY0~input_o\);

-- Location: IOIBUF_X21_Y0_N18
\KEY1~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_KEY1,
	o => \KEY1~input_o\);

-- Location: LABCELL_X15_Y16_N18
\input_valid~1\ : cyclonev_lcell_comb
-- Equation(s):
-- \input_valid~1_combout\ = ( \KEY0~input_o\ & ( !\KEY1~input_o\ ) )

-- pragma translate_off
GENERIC MAP (
	extended_lut => "off",
	lut_mask => "0000000000000000111100001111000000000000000000001111000011110000",
	shared_arith => "off")
-- pragma translate_on
PORT MAP (
	datac => \ALT_INV_KEY1~input_o\,
	datae => \ALT_INV_KEY0~input_o\,
	combout => \input_valid~1_combout\);

-- Location: FF_X15_Y16_N19
key1_d : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \CLOCK_50_B5B~inputCLKENA0_outclk\,
	d => \input_valid~1_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \key1_d~q\);

-- Location: LABCELL_X15_Y16_N33
\input_valid~0\ : cyclonev_lcell_comb
-- Equation(s):
-- \input_valid~0_combout\ = ( !\key1_d~q\ & ( (\KEY0~input_o\ & !\KEY1~input_o\) ) )

-- pragma translate_off
GENERIC MAP (
	extended_lut => "off",
	lut_mask => "0101010100000000010101010000000000000000000000000000000000000000",
	shared_arith => "off")
-- pragma translate_on
PORT MAP (
	dataa => \ALT_INV_KEY0~input_o\,
	datad => \ALT_INV_KEY1~input_o\,
	dataf => \ALT_INV_key1_d~q\,
	combout => \input_valid~0_combout\);

-- Location: FF_X15_Y16_N34
input_valid : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \CLOCK_50_B5B~inputCLKENA0_outclk\,
	d => \input_valid~0_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \input_valid~q\);

-- Location: LABCELL_X15_Y16_N42
\u_nn_core|valid_stage0~0\ : cyclonev_lcell_comb
-- Equation(s):
-- \u_nn_core|valid_stage0~0_combout\ = ( \input_valid~q\ & ( \KEY0~input_o\ ) )

-- pragma translate_off
GENERIC MAP (
	extended_lut => "off",
	lut_mask => "0000000000000000000000000000000001010101010101010101010101010101",
	shared_arith => "off")
-- pragma translate_on
PORT MAP (
	dataa => \ALT_INV_KEY0~input_o\,
	dataf => \ALT_INV_input_valid~q\,
	combout => \u_nn_core|valid_stage0~0_combout\);

-- Location: FF_X15_Y16_N43
\u_nn_core|valid_stage0\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \CLOCK_50_B5B~inputCLKENA0_outclk\,
	d => \u_nn_core|valid_stage0~0_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_nn_core|valid_stage0~q\);

-- Location: LABCELL_X15_Y16_N45
\u_nn_core|valid_stage1~0\ : cyclonev_lcell_comb
-- Equation(s):
-- \u_nn_core|valid_stage1~0_combout\ = ( \u_nn_core|valid_stage0~q\ & ( \KEY0~input_o\ ) )

-- pragma translate_off
GENERIC MAP (
	extended_lut => "off",
	lut_mask => "0000000000000000000000000000000001010101010101010101010101010101",
	shared_arith => "off")
-- pragma translate_on
PORT MAP (
	dataa => \ALT_INV_KEY0~input_o\,
	dataf => \u_nn_core|ALT_INV_valid_stage0~q\,
	combout => \u_nn_core|valid_stage1~0_combout\);

-- Location: FF_X15_Y16_N47
\u_nn_core|valid_stage1\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \CLOCK_50_B5B~inputCLKENA0_outclk\,
	d => \u_nn_core|valid_stage1~0_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_nn_core|valid_stage1~q\);

-- Location: LABCELL_X15_Y16_N39
\u_nn_core|output_valid~0\ : cyclonev_lcell_comb
-- Equation(s):
-- \u_nn_core|output_valid~0_combout\ = (\KEY0~input_o\ & \u_nn_core|valid_stage1~q\)

-- pragma translate_off
GENERIC MAP (
	extended_lut => "off",
	lut_mask => "0000000001010101000000000101010100000000010101010000000001010101",
	shared_arith => "off")
-- pragma translate_on
PORT MAP (
	dataa => \ALT_INV_KEY0~input_o\,
	datad => \u_nn_core|ALT_INV_valid_stage1~q\,
	combout => \u_nn_core|output_valid~0_combout\);

-- Location: FF_X15_Y16_N40
\u_nn_core|output_valid\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \CLOCK_50_B5B~inputCLKENA0_outclk\,
	d => \u_nn_core|output_valid~0_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_nn_core|output_valid~q\);

-- Location: LABCELL_X15_Y16_N30
\done_latched~0\ : cyclonev_lcell_comb
-- Equation(s):
-- \done_latched~0_combout\ = ( \u_nn_core|output_valid~q\ & ( \KEY0~input_o\ ) ) # ( !\u_nn_core|output_valid~q\ & ( (\KEY0~input_o\ & \done_latched~q\) ) )

-- pragma translate_off
GENERIC MAP (
	extended_lut => "off",
	lut_mask => "0000000001010101000000000101010101010101010101010101010101010101",
	shared_arith => "off")
-- pragma translate_on
PORT MAP (
	dataa => \ALT_INV_KEY0~input_o\,
	datad => \ALT_INV_done_latched~q\,
	dataf => \u_nn_core|ALT_INV_output_valid~q\,
	combout => \done_latched~0_combout\);

-- Location: FF_X15_Y16_N31
done_latched : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \CLOCK_50_B5B~inputCLKENA0_outclk\,
	d => \done_latched~0_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \done_latched~q\);

-- Location: LABCELL_X15_Y16_N36
\u_nn_core|latency_cycles~0\ : cyclonev_lcell_comb
-- Equation(s):
-- \u_nn_core|latency_cycles~0_combout\ = ( \u_nn_core|valid_stage1~q\ & ( \KEY0~input_o\ ) ) # ( !\u_nn_core|valid_stage1~q\ & ( (\KEY0~input_o\ & \u_nn_core|latency_cycles\(1)) ) )

-- pragma translate_off
GENERIC MAP (
	extended_lut => "off",
	lut_mask => "0000000001010101000000000101010101010101010101010101010101010101",
	shared_arith => "off")
-- pragma translate_on
PORT MAP (
	dataa => \ALT_INV_KEY0~input_o\,
	datad => \u_nn_core|ALT_INV_latency_cycles\(1),
	dataf => \u_nn_core|ALT_INV_valid_stage1~q\,
	combout => \u_nn_core|latency_cycles~0_combout\);

-- Location: FF_X15_Y16_N37
\u_nn_core|latency_cycles[1]\ : dffeas
-- pragma translate_off
GENERIC MAP (
	is_wysiwyg => "true",
	power_up => "low")
-- pragma translate_on
PORT MAP (
	clk => \CLOCK_50_B5B~inputCLKENA0_outclk\,
	d => \u_nn_core|latency_cycles~0_combout\,
	devclrn => ww_devclrn,
	devpor => ww_devpor,
	q => \u_nn_core|latency_cycles\(1));

-- Location: LABCELL_X43_Y52_N0
\~QUARTUS_CREATED_GND~I\ : cyclonev_lcell_comb
-- Equation(s):

-- pragma translate_off
GENERIC MAP (
	extended_lut => "off",
	lut_mask => "0000000000000000000000000000000000000000000000000000000000000000",
	shared_arith => "off")
-- pragma translate_on
;
END structure;


