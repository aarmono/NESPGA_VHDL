--------------------------------------------------------------------------
--                                                                      --
-- Copyright (c) 1994-97 by Altera Corporation.  All rights reserved.   --
--                                                                      --
--                                                                      --
--  Package name: maxplus2                                              --
--                                                                      --
--  Description:  This package contains 74 series Macrofunctions and    --
--                Altera primitives.                                    --
--                                                                      --
--                                                                      --
--                                                                      --
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

PACKAGE maxplus2 is

component a_161MUX
	port (	gn: in STD_LOGIC;
		sel3: in STD_LOGIC;
		sel2: in STD_LOGIC;
		sel1: in STD_LOGIC;
		sel0: in STD_LOGIC;
		in15: in STD_LOGIC;
		in14: in STD_LOGIC;
		in13: in STD_LOGIC;
		in12: in STD_LOGIC;
		in11: in STD_LOGIC;
		in10: in STD_LOGIC;
		in9: in STD_LOGIC;
		in8: in STD_LOGIC;
		in7: in STD_LOGIC;
		in6: in STD_LOGIC;
		in5: in STD_LOGIC;
		in4: in STD_LOGIC;
		in3: in STD_LOGIC;
		in2: in STD_LOGIC;
		in1: in STD_LOGIC;
		in0: in STD_LOGIC;
		a_out: out STD_LOGIC);
end component;


component a_16cudslb
	port (	clrn: in STD_LOGIC;
		setn: in STD_LOGIC;
		data: in STD_LOGIC;
		stct: in STD_LOGIC;
		dnup: in STD_LOGIC;
		ltrt: in STD_LOGIC;
		q: out STD_LOGIC_VECTOR (16 downto 1));
end component;


component a_16cudslr
	port (	clk: in STD_LOGIC;
		clrn: in STD_LOGIC;
		setn: in STD_LOGIC;
		data: in STD_LOGIC;
		stct: in STD_LOGIC;
		dnup: in STD_LOGIC;
		ltrt: in STD_LOGIC;
		q: out STD_LOGIC_VECTOR (16 downto 1));
end component;


component a_16cudsrb
	port (	clk: in STD_LOGIC;
		clrn: in STD_LOGIC;
		setn: in STD_LOGIC;
		data: in STD_LOGIC;
		stct: in STD_LOGIC;
		dnup: in STD_LOGIC;
		ltrt: in STD_LOGIC;
		q: out STD_LOGIC_VECTOR (16 downto 1));
end component;


component a_16dmux
	port (	d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		q: out STD_LOGIC_VECTOR (15 downto 0));
end component;


component a_16ndmuX
	port (	d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		qn: out STD_LOGIC_VECTOR (15 downto 0));
end component;


component a_21mux
	port (	s: in STD_LOGIC;
		a: in STD_LOGIC;
		b: in STD_LOGIC;
		y: out STD_LOGIC);
end component;


component a_2x8mux
	port (	sel: in STD_LOGIC;
		a: in STD_LOGIC_VECTOR (7 downto 0);
		b: in STD_LOGIC_VECTOR (7 downto 0);
		y: out STD_LOGIC_VECTOR (7 downto 0));
end component;


component a_4count
	port (	clk: in STD_LOGIC;
		clrn: in STD_LOGIC;
		setn: in STD_LOGIC;
		ldn: in STD_LOGIC;
		cin: in STD_LOGIC;
		dnup: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC;
		cout: out STD_LOGIC);
end component;


component a_7400
	port (	a_2: in STD_LOGIC;
		a_3: in STD_LOGIC;
		a_1: out STD_LOGIC);
end component;


component a_7402
	port (	a_2: in STD_LOGIC;
		a_3: in STD_LOGIC;
		a_1: out STD_LOGIC);
end component;


component a_7404
	port (	a_2: in STD_LOGIC;
		a_1: out STD_LOGIC);
end component;


component a_7408
	port (	a_2: in STD_LOGIC;
		a_3: in STD_LOGIC;
		a_1: out STD_LOGIC);
end component;


component a_7410
	port (	a_2: in STD_LOGIC;
		a_3: in STD_LOGIC;
		a_4: in STD_LOGIC;
		a_1: out STD_LOGIC);
end component;


component a_74107
	port (	a_1j: in STD_LOGIC;
		a_1k: in STD_LOGIC;
		a_1clrn: in STD_LOGIC;
		a_1clk: in STD_LOGIC;
		a_2j: in STD_LOGIC;
		a_2k: in STD_LOGIC;
		a_2clrn: in STD_LOGIC;
		a_2clk: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_1qn: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_2qn: out STD_LOGIC);
end component;


component a_74107a
	port (	a_1j: in STD_LOGIC;
		a_1clkn: in STD_LOGIC;
		a_1k: in STD_LOGIC;
		a_1clrn: in STD_LOGIC;
		a_2j: in STD_LOGIC;
		a_2clkn: in STD_LOGIC;
		a_2k: in STD_LOGIC;
		a_2clrn: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_1qn: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_2qn: out STD_LOGIC);
end component;


component a_74109
	port (	a_1prn: in STD_LOGIC;
		a_1j: in STD_LOGIC;
		a_1kn: in STD_LOGIC;
		a_1clrn: in STD_LOGIC;
		a_1clk: in STD_LOGIC;
		a_2prn: in STD_LOGIC;
		a_2j: in STD_LOGIC;
		a_2kn: in STD_LOGIC;
		a_2clrn: in STD_LOGIC;
		a_2clk: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_1qn: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_2qn: out STD_LOGIC);
end component;


component a_7411
	port (	a_2: in STD_LOGIC;
		a_3: in STD_LOGIC;
		a_4: in STD_LOGIC;
		a_1: out STD_LOGIC);
end component;


component a_74112
	port (	a_1prn: in STD_LOGIC;
		a_1j: in STD_LOGIC;
		a_1k: in STD_LOGIC;
		a_1clrn: in STD_LOGIC;
		a_1clk: in STD_LOGIC;
		a_2prn: in STD_LOGIC;
		a_2j: in STD_LOGIC;
		a_2k: in STD_LOGIC;
		a_2clrn: in STD_LOGIC;
		a_2clk: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_1qn: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_2qn: out STD_LOGIC);
end component;


component a_74113
	port (	a_1prn: in STD_LOGIC;
		a_1j: in STD_LOGIC;
		a_1k: in STD_LOGIC;
		a_1clk: in STD_LOGIC;
		a_2prn: in STD_LOGIC;
		a_2j: in STD_LOGIC;
		a_2k: in STD_LOGIC;
		a_2clk: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_1qn: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_2qn: out STD_LOGIC);
end component;


component a_74114
	port (	a_1prn: in STD_LOGIC;
		a_1j: in STD_LOGIC;
		a_1k: in STD_LOGIC;
		a_2prn: in STD_LOGIC;
		a_2j: in STD_LOGIC;
		a_2k: in STD_LOGIC;
		clrn: in STD_LOGIC;
		clk: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_1qn: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_2qn: out STD_LOGIC);
end component;


component a_74116
	port (	a_1clrn: in STD_LOGIC;
		a_2clrn: in STD_LOGIC;
		a_1g1n: in STD_LOGIC;
		a_1g2n: in STD_LOGIC;
		a_2g1n: in STD_LOGIC;
		a_2g2n: in STD_LOGIC;
		a_1d: in STD_LOGIC_VECTOR (4 downto 1);
		a_2d: in STD_LOGIC_VECTOR (4 downto 1);
		a_1q: out STD_LOGIC_VECTOR (4 downto 1);
		a_2q: out STD_LOGIC_VECTOR (4 downto 1));
end component;


component a_74133
	port (	a_2: in STD_LOGIC;
		a_3: in STD_LOGIC;
		a_4: in STD_LOGIC;
		a_5: in STD_LOGIC;
		a_6: in STD_LOGIC;
		a_7: in STD_LOGIC;
		a_8: in STD_LOGIC;
		a_9: in STD_LOGIC;
		a_10: in STD_LOGIC;
		a_11: in STD_LOGIC;
		a_12: in STD_LOGIC;
		a_13: in STD_LOGIC;
		a_14: in STD_LOGIC;
		a_1: out STD_LOGIC);
end component;


component a_74134
	port (	a_2: in STD_LOGIC;
		a_3: in STD_LOGIC;
		a_4: in STD_LOGIC;
		a_5: in STD_LOGIC;
		a_6: in STD_LOGIC;
		a_7: in STD_LOGIC;
		a_8: in STD_LOGIC;
		a_9: in STD_LOGIC;
		a_10: in STD_LOGIC;
		a_11: in STD_LOGIC;
		a_12: in STD_LOGIC;
		a_13: in STD_LOGIC;
		oen: in STD_LOGIC;
		a_1: out STD_LOGIC);
end component;


component a_74135
	port (	a_1a: in STD_LOGIC;
		a_1b: in STD_LOGIC;
		a_12c: in STD_LOGIC;
		a_2a: in STD_LOGIC;
		a_2b: in STD_LOGIC;
		a_3a: in STD_LOGIC;
		a_3b: in STD_LOGIC;
		a_34c: in STD_LOGIC;
		a_4a: in STD_LOGIC;
		a_4b: in STD_LOGIC;
		a_1y: out STD_LOGIC;
		a_2y: out STD_LOGIC;
		a_3y: out STD_LOGIC;
		a_4y: out STD_LOGIC);
end component;


component a_74137
	port (	gln: in STD_LOGIC;
		g1: in STD_LOGIC;
		g2n: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		y: out STD_LOGIC_VECTOR (0 to 7));
end component;


component a_74138
	port (	g1: in STD_LOGIC;
		g2an: in STD_LOGIC;
		g2bn: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		y0n: out STD_LOGIC;
		y1n: out STD_LOGIC;
		y2n: out STD_LOGIC;
		y3n: out STD_LOGIC;
		y4n: out STD_LOGIC;
		y5n: out STD_LOGIC;
		y6n: out STD_LOGIC;
		y7n: out STD_LOGIC);
end component;


component a_74139
	port (	g1n: in STD_LOGIC;
		b1: in STD_LOGIC;
		a1: in STD_LOGIC;
		g2n: in STD_LOGIC;
		b2: in STD_LOGIC;
		a2: in STD_LOGIC;
		y10n: out STD_LOGIC;
		y11n: out STD_LOGIC;
		y12n: out STD_LOGIC;
		y13n: out STD_LOGIC;
		y20n: out STD_LOGIC;
		y21n: out STD_LOGIC;
		y22n: out STD_LOGIC;
		y23n: out STD_LOGIC);
end component;


component a_74143
	port (	clk: in STD_LOGIC;
		clrn: in STD_LOGIC;
		strbn: in STD_LOGIC;
		pcein: in STD_LOGIC;
		scein: in STD_LOGIC;
		bin: in STD_LOGIC;
		rbin: in STD_LOGIC;
		dpi: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC;
		max: out STD_LOGIC;
		a: out STD_LOGIC;
		b: out STD_LOGIC;
		c: out STD_LOGIC;
		d: out STD_LOGIC;
		e: out STD_LOGIC;
		f: out STD_LOGIC;
		g: out STD_LOGIC;
		dpo: out STD_LOGIC;
		rbon: out STD_LOGIC);
end component;


component a_74145
	port (	d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		o0n: out STD_LOGIC;
		o1n: out STD_LOGIC;
		o2n: out STD_LOGIC;
		o3n: out STD_LOGIC;
		o4n: out STD_LOGIC;
		o5n: out STD_LOGIC;
		o6n: out STD_LOGIC;
		o7n: out STD_LOGIC;
		o8n: out STD_LOGIC;
		o9n: out STD_LOGIC);
end component;


component a_74147
	port (	a_1n: in STD_LOGIC;
		a_2n: in STD_LOGIC;
		a_3n: in STD_LOGIC;
		a_4n: in STD_LOGIC;
		a_5n: in STD_LOGIC;
		a_6n: in STD_LOGIC;
		a_7n: in STD_LOGIC;
		a_8n: in STD_LOGIC;
		a_9n: in STD_LOGIC;
		dn: out STD_LOGIC;
		cn: out STD_LOGIC;
		bn: out STD_LOGIC;
		an: out STD_LOGIC);
end component;


component a_74148
	port (	ein: in STD_LOGIC;
		a_0n: in STD_LOGIC;
		a_1n: in STD_LOGIC;
		a_2n: in STD_LOGIC;
		a_3n: in STD_LOGIC;
		a_4n: in STD_LOGIC;
		a_5n: in STD_LOGIC;
		a_6n: in STD_LOGIC;
		a_7n: in STD_LOGIC;
		a2n: out STD_LOGIC;
		a1n: out STD_LOGIC;
		a0n: out STD_LOGIC;
		gsn: out STD_LOGIC;
		eon: out STD_LOGIC);
end component;


component a_74151
	port (	c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		d7: in STD_LOGIC;
		d6: in STD_LOGIC;
		d5: in STD_LOGIC;
		d4: in STD_LOGIC;
		d3: in STD_LOGIC;
		d2: in STD_LOGIC;
		d1: in STD_LOGIC;
		d0: in STD_LOGIC;
		gn: in STD_LOGIC;
		y: out STD_LOGIC;
		wn: out STD_LOGIC);
end component;


component a_74151b
	port (	c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (7 downto 0);
		gn: in STD_LOGIC;
		y: out STD_LOGIC;
		wn: out STD_LOGIC);
end component;


component a_74153
	port (	b: in STD_LOGIC;
		a: in STD_LOGIC;
		a_1gn: in STD_LOGIC;
		a_1c: in STD_LOGIC_VECTOR (3 downto 0);
		a_2gn: in STD_LOGIC;
		a_2c: in STD_LOGIC_VECTOR (3 downto 0);
		a_1y: out STD_LOGIC;
		a_2y: out STD_LOGIC);
end component;


component a_74154
	port (	g1n: in STD_LOGIC;
		g2n: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		o0n: out STD_LOGIC;
		o1n: out STD_LOGIC;
		o2n: out STD_LOGIC;
		o3n: out STD_LOGIC;
		o4n: out STD_LOGIC;
		o5n: out STD_LOGIC;
		o6n: out STD_LOGIC;
		o7n: out STD_LOGIC;
		o8n: out STD_LOGIC;
		o9n: out STD_LOGIC;
		o10n: out STD_LOGIC;
		o11n: out STD_LOGIC;
		o12n: out STD_LOGIC;
		o13n: out STD_LOGIC;
		o14n: out STD_LOGIC;
		o15n: out STD_LOGIC);
end component;


component a_74155
	port (	a_2cn: in STD_LOGIC;
		a_1c: in STD_LOGIC;
		selb: in STD_LOGIC;
		sela: in STD_LOGIC;
		a_2gn: in STD_LOGIC;
		a_1gn: in STD_LOGIC;
		a_2y0n: out STD_LOGIC;
		a_2y1n: out STD_LOGIC;
		a_2y2n: out STD_LOGIC;
		a_2y3n: out STD_LOGIC;
		a_1y0n: out STD_LOGIC;
		a_1y1n: out STD_LOGIC;
		a_1y2n: out STD_LOGIC;
		a_1y3n: out STD_LOGIC);
end component;


component a_74156
	port (	a_2cn: in STD_LOGIC;
		a_1c: in STD_LOGIC;
		selb: in STD_LOGIC;
		sela: in STD_LOGIC;
		a_2gn: in STD_LOGIC;
		a_1gn: in STD_LOGIC;
		a_2y0n: out STD_LOGIC;
		a_2y1n: out STD_LOGIC;
		a_2y2n: out STD_LOGIC;
		a_2y3n: out STD_LOGIC;
		a_1y0n: out STD_LOGIC;
		a_1y1n: out STD_LOGIC;
		a_1y2n: out STD_LOGIC;
		a_1y3n: out STD_LOGIC);
end component;


component a_74157
	port (	gn: in STD_LOGIC;
		sel: in STD_LOGIC;
		a: in STD_LOGIC_VECTOR (4 downto 1);
		b: in STD_LOGIC_VECTOR (4 downto 1);
		y: out STD_LOGIC_VECTOR (4 downto 1));
end component;


component a_74158
	port (	gn: in STD_LOGIC;
		sel: in STD_LOGIC;
		a_1a: in STD_LOGIC;
		a_2a: in STD_LOGIC;
		a_3a: in STD_LOGIC;
		a_4a: in STD_LOGIC;
		a_1b: in STD_LOGIC;
		a_2b: in STD_LOGIC;
		a_3b: in STD_LOGIC;
		a_4b: in STD_LOGIC;
		a_1yn: out STD_LOGIC;
		a_2yn: out STD_LOGIC;
		a_3yn: out STD_LOGIC;
		a_4yn: out STD_LOGIC);
end component;


component a_74160
	port (	clk: in STD_LOGIC;
		ldn: in STD_LOGIC;
		clrn: in STD_LOGIC;
		enp: in STD_LOGIC;
		ent: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC;
		rco: out STD_LOGIC);
end component;


component a_74161
	port (	clk: in STD_LOGIC;
		ldn: in STD_LOGIC;
		clrn: in STD_LOGIC;
		enp: in STD_LOGIC;
		ent: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC;
		rco: out STD_LOGIC);
end component;


component a_74162
	port (	clk: in STD_LOGIC;
		ldn: in STD_LOGIC;
		clrn: in STD_LOGIC;
		enp: in STD_LOGIC;
		ent: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC;
		rco: out STD_LOGIC);
end component;


component a_74163
	port (	clk: in STD_LOGIC;
		ldn: in STD_LOGIC;
		clrn: in STD_LOGIC;
		enp: in STD_LOGIC;
		ent: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC;
		rco: out STD_LOGIC);
end component;


component a_74164
	port (	clk: in STD_LOGIC;
		clrn: in STD_LOGIC;
		a: in STD_LOGIC;
		b: in STD_LOGIC;
		qa: out STD_LOGIC;
		qb: out STD_LOGIC;
		qc: out STD_LOGIC;
		qd: out STD_LOGIC;
		qe: out STD_LOGIC;
		qf: out STD_LOGIC;
		qg: out STD_LOGIC;
		qh: out STD_LOGIC);
end component;


component a_74164b
	port (	clk: in STD_LOGIC;
		clrn: in STD_LOGIC;
		a: in STD_LOGIC;
		b: in STD_LOGIC;
		q: out STD_LOGIC_VECTOR (7 downto 0));
end component;


component a_74165
	port (	clk: in STD_LOGIC;
		clkih: in STD_LOGIC;
		stld: in STD_LOGIC;
		ser: in STD_LOGIC;
		a: in STD_LOGIC;
		b: in STD_LOGIC;
		c: in STD_LOGIC;
		d: in STD_LOGIC;
		e: in STD_LOGIC;
		f: in STD_LOGIC;
		g: in STD_LOGIC;
		h: in STD_LOGIC;
		qh: out STD_LOGIC;
		qhn: out STD_LOGIC);
end component;


component a_74165b
	port (	clk: in STD_LOGIC;
		clkih: in STD_LOGIC;
		stld: in STD_LOGIC;
		ser: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (7 downto 0);
		q7: out STD_LOGIC;
		q7n: out STD_LOGIC);
end component;


component a_74166
	port (	clrn: in STD_LOGIC;
		stld: in STD_LOGIC;
		clkih: in STD_LOGIC;
		clk: in STD_LOGIC;
		ser: in STD_LOGIC;
		a: in STD_LOGIC;
		b: in STD_LOGIC;
		c: in STD_LOGIC;
		d: in STD_LOGIC;
		e: in STD_LOGIC;
		f: in STD_LOGIC;
		g: in STD_LOGIC;
		h: in STD_LOGIC;
		qh: out STD_LOGIC);
end component;


component a_74171
	port (	clrn: in STD_LOGIC;
		clk: in STD_LOGIC;
		d1: in STD_LOGIC;
		d2: in STD_LOGIC;
		d3: in STD_LOGIC;
		d4: in STD_LOGIC;
		q1: out STD_LOGIC;
		qn1: out STD_LOGIC;
		q2: out STD_LOGIC;
		qn2: out STD_LOGIC;
		q3: out STD_LOGIC;
		qn3: out STD_LOGIC;
		q4: out STD_LOGIC;
		qn4: out STD_LOGIC);
end component;


component a_74173
	port (	clr: in STD_LOGIC;
		clk: in STD_LOGIC;
		mn: in STD_LOGIC;
		nn: in STD_LOGIC;
		g1n: in STD_LOGIC;
		g2n: in STD_LOGIC;
		a_1d: in STD_LOGIC;
		a_2d: in STD_LOGIC;
		a_3d: in STD_LOGIC;
		a_4d: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_3q: out STD_LOGIC;
		a_4q: out STD_LOGIC);
end component;


component a_74174
	port (	clrn: in STD_LOGIC;
		clk: in STD_LOGIC;
		a_1d: in STD_LOGIC;
		a_2d: in STD_LOGIC;
		a_3d: in STD_LOGIC;
		a_4d: in STD_LOGIC;
		a_5d: in STD_LOGIC;
		a_6d: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_3q: out STD_LOGIC;
		a_4q: out STD_LOGIC;
		a_5q: out STD_LOGIC;
		a_6q: out STD_LOGIC);
end component;


component a_74174b
	port (	clrn: in STD_LOGIC;
		clk: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (6 downto 1);
		q: out STD_LOGIC_VECTOR (6 downto 1));
end component;


component a_74175
	port (	clrn: in STD_LOGIC;
		clk: in STD_LOGIC;
		a_1d: in STD_LOGIC;
		a_2d: in STD_LOGIC;
		a_3d: in STD_LOGIC;
		a_4d: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_1qn: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_2qn: out STD_LOGIC;
		a_3q: out STD_LOGIC;
		a_3qn: out STD_LOGIC;
		a_4q: out STD_LOGIC;
		a_4qn: out STD_LOGIC);
end component;


component a_74176
	port (	clrn: in STD_LOGIC;
		ldn: in STD_LOGIC;
		clk1: in STD_LOGIC;
		clk2: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC);
end component;


component a_74177
	port (	clrn: in STD_LOGIC;
		ldn: in STD_LOGIC;
		clk1: in STD_LOGIC;
		clk2: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC);
end component;


component a_74178
	port (	st: in STD_LOGIC;
		ld: in STD_LOGIC;
		ser: in STD_LOGIC;
		clk: in STD_LOGIC;
		a: in STD_LOGIC;
		b: in STD_LOGIC;
		c: in STD_LOGIC;
		d: in STD_LOGIC;
		qa: out STD_LOGIC;
		qb: out STD_LOGIC;
		qc: out STD_LOGIC;
		qd: out STD_LOGIC);
end component;


component a_74179
	port (	clrn: in STD_LOGIC;
		st: in STD_LOGIC;
		ld: in STD_LOGIC;
		clk: in STD_LOGIC;
		ser: in STD_LOGIC;
		a: in STD_LOGIC;
		b: in STD_LOGIC;
		c: in STD_LOGIC;
		d: in STD_LOGIC;
		qa: out STD_LOGIC;
		qb: out STD_LOGIC;
		qc: out STD_LOGIC;
		qd: out STD_LOGIC;
		qdn: out STD_LOGIC);
end component;


component a_74180
	port (	a: in STD_LOGIC;
		b: in STD_LOGIC;
		c: in STD_LOGIC;
		d: in STD_LOGIC;
		e: in STD_LOGIC;
		f: in STD_LOGIC;
		g: in STD_LOGIC;
		h: in STD_LOGIC;
		evni: in STD_LOGIC;
		oddi: in STD_LOGIC;
		evns: out STD_LOGIC;
		odds: out STD_LOGIC);
end component;


component a_74180b
	port (	d: in STD_LOGIC_VECTOR (7 downto 0);
		evni: in STD_LOGIC;
		oddi: in STD_LOGIC;
		evns: out STD_LOGIC;
		odds: out STD_LOGIC);
end component;


component a_74181
	port (	s: in STD_LOGIC_VECTOR (3 downto 0);
		m: in STD_LOGIC;
		cn: in STD_LOGIC;
		a3n: in STD_LOGIC;
		a2n: in STD_LOGIC;
		a1n: in STD_LOGIC;
		a0n: in STD_LOGIC;
		b3n: in STD_LOGIC;
		b2n: in STD_LOGIC;
		b1n: in STD_LOGIC;
		b0n: in STD_LOGIC;
		gn: out STD_LOGIC;
		pn: out STD_LOGIC;
		f3n: out STD_LOGIC;
		f2n: out STD_LOGIC;
		f1n: out STD_LOGIC;
		f0n: out STD_LOGIC;
		aeqb: out STD_LOGIC;
		cn4: out STD_LOGIC);
end component;


component a_74182
	port (	pn3: in STD_LOGIC;
		pn2: in STD_LOGIC;
		pn1: in STD_LOGIC;
		pn0: in STD_LOGIC;
		gn3: in STD_LOGIC;
		gn2: in STD_LOGIC;
		gn1: in STD_LOGIC;
		gn0: in STD_LOGIC;
		ci: in STD_LOGIC;
		pn: out STD_LOGIC;
		gn: out STD_LOGIC;
		cz: out STD_LOGIC;
		cy: out STD_LOGIC;
		cx: out STD_LOGIC);
end component;


component a_74183
	port (	a_1cn0: in STD_LOGIC;
		a_1b: in STD_LOGIC;
		a_1a: in STD_LOGIC;
		a_2cn0: in STD_LOGIC;
		a_2b: in STD_LOGIC;
		a_2a: in STD_LOGIC;
		a_1sum: out STD_LOGIC;
		a_1cn1: out STD_LOGIC;
		a_2sum: out STD_LOGIC;
		a_2cn1: out STD_LOGIC);
end component;


component a_74184
	port (	e: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		gn: in STD_LOGIC;
		y: out STD_LOGIC_VECTOR (8 downto 1));
end component;


component a_74185
	port (	e: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		gn: in STD_LOGIC;
		y: out STD_LOGIC_VECTOR (8 downto 1));
end component;


component a_74190
	port (	clk: in STD_LOGIC;
		gn: in STD_LOGIC;
		ldn: in STD_LOGIC;
		dnup: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC;
		mxmn: out STD_LOGIC;
		rcon: out STD_LOGIC);
end component;


component a_74191
	port (	clk: in STD_LOGIC;
		gn: in STD_LOGIC;
		ldn: in STD_LOGIC;
		dnup: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC;
		mxmn: out STD_LOGIC;
		rcon: out STD_LOGIC);
end component;


component a_74192
	port (	clr: in STD_LOGIC;
		up: in STD_LOGIC;
		dn: in STD_LOGIC;
		ldn: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC;
		con: out STD_LOGIC;
		bon: out STD_LOGIC);
end component;


component a_74193
	port (	clr: in STD_LOGIC;
		up: in STD_LOGIC;
		dn: in STD_LOGIC;
		ldn: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC;
		con: out STD_LOGIC;
		bon: out STD_LOGIC);
end component;


component a_74194
	port (	clrn: in STD_LOGIC;
		s1: in STD_LOGIC;
		s0: in STD_LOGIC;
		clk: in STD_LOGIC;
		slsi: in STD_LOGIC;
		srsi: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC);
end component;


component a_74196
	port (	clrn: in STD_LOGIC;
		ldn: in STD_LOGIC;
		clk1: in STD_LOGIC;
		clk2: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC);
end component;


component a_74197
	port (	clrn: in STD_LOGIC;
		ldn: in STD_LOGIC;
		clk1: in STD_LOGIC;
		clk2: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC);
end component;


component a_74198
	port (	clrn: in STD_LOGIC;
		s1: in STD_LOGIC;
		s0: in STD_LOGIC;
		clk: in STD_LOGIC;
		slsi: in STD_LOGIC;
		srsi: in STD_LOGIC;
		a: in STD_LOGIC;
		b: in STD_LOGIC;
		c: in STD_LOGIC;
		d: in STD_LOGIC;
		e: in STD_LOGIC;
		f: in STD_LOGIC;
		g: in STD_LOGIC;
		h: in STD_LOGIC;
		qa: out STD_LOGIC;
		qb: out STD_LOGIC;
		qc: out STD_LOGIC;
		qd: out STD_LOGIC;
		qe: out STD_LOGIC;
		qf: out STD_LOGIC;
		qg: out STD_LOGIC;
		qh: out STD_LOGIC);
end component;


component a_7420
	port (	a_2: in STD_LOGIC;
		a_3: in STD_LOGIC;
		a_4: in STD_LOGIC;
		a_5: in STD_LOGIC;
		a_1: out STD_LOGIC);
end component;


component a_7421
	port (	a_2: in STD_LOGIC;
		a_3: in STD_LOGIC;
		a_4: in STD_LOGIC;
		a_5: in STD_LOGIC;
		a_1: out STD_LOGIC);
end component;


component a_7423
	port (	a_1a: in STD_LOGIC;
		a_1b: in STD_LOGIC;
		a_1c: in STD_LOGIC;
		a_1d: in STD_LOGIC;
		a_1g: in STD_LOGIC;
		a_2a: in STD_LOGIC;
		a_2b: in STD_LOGIC;
		a_2c: in STD_LOGIC;
		a_2d: in STD_LOGIC;
		a_2g: in STD_LOGIC;
		a_1y: out STD_LOGIC;
		a_2y: out STD_LOGIC);
end component;


component a_74240
	port (	a_1gn: in STD_LOGIC;
		a_1a: in STD_LOGIC_VECTOR (1 to 4);
		a_2gn: in STD_LOGIC;
		a_2a: in STD_LOGIC_VECTOR (1 to 4);
		a_1y: out STD_LOGIC_VECTOR (1 to 4);
		a_2y: out STD_LOGIC_VECTOR (1 to 4));
end component;


component a_74240b
	port (	a: in STD_LOGIC_VECTOR (4 downto 1);
		b: in STD_LOGIC_VECTOR (4 downto 1);
		agn: in STD_LOGIC;
		bgn: in STD_LOGIC;
		ay: out STD_LOGIC_VECTOR (4 downto 1);
		by: out STD_LOGIC_VECTOR (4 downto 1));
end component;


component a_74241
	port (	a_1gn: in STD_LOGIC;
		a_1a: in STD_LOGIC_VECTOR (1 to 4);
		a_2g: in STD_LOGIC;
		a_2a: in STD_LOGIC_VECTOR (1 to 4);
		a_1y: out STD_LOGIC_VECTOR (1 to 4);
		a_2y: out STD_LOGIC_VECTOR (1 to 4));
end component;


component a_74241b
	port (	a: in STD_LOGIC_VECTOR (4 downto 1);
		b: in STD_LOGIC_VECTOR (4 downto 1);
		agn: in STD_LOGIC;
		bg: in STD_LOGIC;
		ay: out STD_LOGIC_VECTOR (4 downto 1);
		by: out STD_LOGIC_VECTOR (4 downto 1));
end component;


component a_74244
	port (	a_1gn: in STD_LOGIC;
		a_1a: in STD_LOGIC_VECTOR (1 to 4);
		a_2gn: in STD_LOGIC;
		a_2a: in STD_LOGIC_VECTOR (1 to 4);
		a_1y: out STD_LOGIC_VECTOR (1 to 4);
		a_2y: out STD_LOGIC_VECTOR (1 to 4));
end component;


component a_74244b
	port (	a: in STD_LOGIC_VECTOR (4 downto 1);
		b: in STD_LOGIC_VECTOR (4 downto 1);
		agn: in STD_LOGIC;
		bgn: in STD_LOGIC;
		ay: out STD_LOGIC_VECTOR (4 downto 1);
		by: out STD_LOGIC_VECTOR (4 downto 1));
end component;


component a_74246
	port (	ltn: in STD_LOGIC;
		rbin: in STD_LOGIC;
		bin: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		oa: out STD_LOGIC;
		ob: out STD_LOGIC;
		oc: out STD_LOGIC;
		od: out STD_LOGIC;
		oe: out STD_LOGIC;
		a_of: out STD_LOGIC;
		og: out STD_LOGIC;
		rbon: out STD_LOGIC);
end component;


component a_74247
	port (	ltn: in STD_LOGIC;
		rbin: in STD_LOGIC;
		bin: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		oa: out STD_LOGIC;
		ob: out STD_LOGIC;
		oc: out STD_LOGIC;
		od: out STD_LOGIC;
		oe: out STD_LOGIC;
		a_of: out STD_LOGIC;
		og: out STD_LOGIC;
		rbon: out STD_LOGIC);
end component;


component a_74248
	port (	ltn: in STD_LOGIC;
		rbin: in STD_LOGIC;
		bin: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		oa: out STD_LOGIC;
		ob: out STD_LOGIC;
		oc: out STD_LOGIC;
		od: out STD_LOGIC;
		oe: out STD_LOGIC;
		a_of: out STD_LOGIC;
		og: out STD_LOGIC;
		rbon: out STD_LOGIC);
end component;


component a_7425
	port (	a_1a: in STD_LOGIC;
		a_1b: in STD_LOGIC;
		a_1c: in STD_LOGIC;
		a_1d: in STD_LOGIC;
		a_1g: in STD_LOGIC;
		a_2a: in STD_LOGIC;
		a_2b: in STD_LOGIC;
		a_2c: in STD_LOGIC;
		a_2d: in STD_LOGIC;
		a_2g: in STD_LOGIC;
		a_1y: out STD_LOGIC;
		a_2y: out STD_LOGIC);
end component;


component a_74251
	port (	c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (7 downto 0);
		gn: in STD_LOGIC;
		y: out STD_LOGIC;
		wn: out STD_LOGIC);
end component;


component a_74253
	port (	b: in STD_LOGIC;
		a: in STD_LOGIC;
		a_1gn: in STD_LOGIC;
		a_1c: in STD_LOGIC_VECTOR (0 to 3);
		a_2gn: in STD_LOGIC;
		a_2c: in STD_LOGIC_VECTOR (0 to 3);
		a_1y: out STD_LOGIC;
		a_2y: out STD_LOGIC);
end component;


component a_74257
	port (	gn: in STD_LOGIC;
		sel: in STD_LOGIC;
		a: in STD_LOGIC_VECTOR (4 downto 1);
		b: in STD_LOGIC_VECTOR (4 downto 1);
		y: out STD_LOGIC_VECTOR (4 downto 1));
end component;


component a_74258
	port (	gn: in STD_LOGIC;
		sel: in STD_LOGIC;
		a: in STD_LOGIC_VECTOR (4 downto 1);
		b: in STD_LOGIC_VECTOR (4 downto 1);
		yn: out STD_LOGIC_VECTOR (4 downto 1));
end component;


component a_74259
	port (	clrn: in STD_LOGIC;
		gn: in STD_LOGIC;
		s: in STD_LOGIC_VECTOR (2 downto 0);
		data: in STD_LOGIC;
		q: out STD_LOGIC_VECTOR (7 downto 0));
end component;


component a_74260
	port (	a: in STD_LOGIC_VECTOR (0 to 4);
		b: in STD_LOGIC_VECTOR (0 to 4);
		ayn: out STD_LOGIC;
		byn: out STD_LOGIC);
end component;


component a_74261
	port (	b: in STD_LOGIC_VECTOR (4 downto 0);
		m: in STD_LOGIC_VECTOR (2 downto 0);
		g: in STD_LOGIC;
		q4n: out STD_LOGIC;
		q: out STD_LOGIC_VECTOR (3 downto 0));
end component;


component a_74265
	port (	a_1a: in STD_LOGIC;
		a_2a: in STD_LOGIC;
		a_2b: in STD_LOGIC;
		a_3a: in STD_LOGIC;
		a_3b: in STD_LOGIC;
		a_4a: in STD_LOGIC;
		a_1w: out STD_LOGIC;
		a_1yn: out STD_LOGIC;
		a_2w: out STD_LOGIC;
		a_2yn: out STD_LOGIC;
		a_3w: out STD_LOGIC;
		a_3yn: out STD_LOGIC;
		a_4w: out STD_LOGIC;
		a_4yn: out STD_LOGIC);
end component;


component a_7427
	port (	a_2: in STD_LOGIC;
		a_3: in STD_LOGIC;
		a_4: in STD_LOGIC;
		a_1: out STD_LOGIC);
end component;


component a_74273
	port (	clrn: in STD_LOGIC;
		clk: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (8 downto 1);
		q: out STD_LOGIC_VECTOR (8 downto 1));
end component;


component a_74273b
	port (	clrn: in STD_LOGIC;
		clk: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (8 downto 1);
		q: out STD_LOGIC_VECTOR (8 downto 1));
end component;


component a_74276
	port (	prn: in STD_LOGIC;
		clrn: in STD_LOGIC;
		a_1j: in STD_LOGIC;
		a_1kn: in STD_LOGIC;
		a_1clk: in STD_LOGIC;
		a_2j: in STD_LOGIC;
		a_2kn: in STD_LOGIC;
		a_2clk: in STD_LOGIC;
		a_3j: in STD_LOGIC;
		a_3kn: in STD_LOGIC;
		a_3clk: in STD_LOGIC;
		a_4j: in STD_LOGIC;
		a_4kn: in STD_LOGIC;
		a_4clk: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_1qn: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_2qn: out STD_LOGIC;
		a_3q: out STD_LOGIC;
		a_3qn: out STD_LOGIC;
		a_4q: out STD_LOGIC;
		a_4qn: out STD_LOGIC);
end component;


component a_74278
	port (	p0: in STD_LOGIC;
		g: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (4 downto 1);
		y: out STD_LOGIC_VECTOR (4 downto 1);
		p1: out STD_LOGIC);
end component;


component a_74279
	port (	s11n: in STD_LOGIC;
		s12n: in STD_LOGIC;
		r1n: in STD_LOGIC;
		s2n: in STD_LOGIC;
		r2n: in STD_LOGIC;
		s31n: in STD_LOGIC;
		s32n: in STD_LOGIC;
		r3n: in STD_LOGIC;
		s4n: in STD_LOGIC;
		r4n: in STD_LOGIC;
		q: out STD_LOGIC_VECTOR (4 downto 1));
end component;


component a_7428
	port (	a1: in STD_LOGIC;
		b1: in STD_LOGIC;
		a2: in STD_LOGIC;
		b2: in STD_LOGIC;
		a3: in STD_LOGIC;
		b3: in STD_LOGIC;
		a4: in STD_LOGIC;
		b4: in STD_LOGIC;
		y1: out STD_LOGIC;
		y2: out STD_LOGIC;
		y3: out STD_LOGIC;
		y4: out STD_LOGIC);
end component;


component a_74280
	port (	a: in STD_LOGIC;
		b: in STD_LOGIC;
		c: in STD_LOGIC;
		d: in STD_LOGIC;
		e: in STD_LOGIC;
		f: in STD_LOGIC;
		g: in STD_LOGIC;
		h: in STD_LOGIC;
		i: in STD_LOGIC;
		even: out STD_LOGIC;
		odd: out STD_LOGIC);
end component;


component a_74280b
	port (	d: in STD_LOGIC_VECTOR (8 downto 0);
		even: out STD_LOGIC;
		odd: out STD_LOGIC);
end component;


component a_74283
	port (	a: in STD_LOGIC_VECTOR (4 downto 1);
		b: in STD_LOGIC_VECTOR (4 downto 1);
		cin: in STD_LOGIC;
		cout: out STD_LOGIC;
		sum: out STD_LOGIC_VECTOR (4 downto 1));
end component;


component a_74284
	port (	gan: in STD_LOGIC;
		gbn: in STD_LOGIC;
		a: in STD_LOGIC_VECTOR (4 downto 1);
		b: in STD_LOGIC_VECTOR (4 downto 1);
		y: out STD_LOGIC_VECTOR (8 downto 5));
end component;


component a_74285
	port (	gan: in STD_LOGIC;
		gbn: in STD_LOGIC;
		a: in STD_LOGIC_VECTOR (4 downto 1);
		b: in STD_LOGIC_VECTOR (4 downto 1);
		y: out STD_LOGIC_VECTOR (4 downto 1));
end component;


component a_74290
	port (	clka: in STD_LOGIC;
		clkb: in STD_LOGIC;
		clra: in STD_LOGIC;
		clrb: in STD_LOGIC;
		set9a: in STD_LOGIC;
		set9b: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC);
end component;


component a_74292
	port (	clk1: in STD_LOGIC;
		clk2: in STD_LOGIC;
		clrn: in STD_LOGIC;
		e: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		q: out STD_LOGIC;
		tp1: out STD_LOGIC;
		tp2: out STD_LOGIC;
		tp3: out STD_LOGIC);
end component;


component a_74293
	port (	clka: in STD_LOGIC;
		clkb: in STD_LOGIC;
		clra: in STD_LOGIC;
		clrb: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC);
end component;


component a_74294
	port (	clk1: in STD_LOGIC;
		clk2: in STD_LOGIC;
		clrn: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		q: out STD_LOGIC;
		tp: out STD_LOGIC);
end component;


component a_74298
	port (	wrsl: in STD_LOGIC;
		clkn: in STD_LOGIC;
		a1: in STD_LOGIC;
		b1: in STD_LOGIC;
		c1: in STD_LOGIC;
		d1: in STD_LOGIC;
		a2: in STD_LOGIC;
		b2: in STD_LOGIC;
		c2: in STD_LOGIC;
		d2: in STD_LOGIC;
		qa: out STD_LOGIC;
		qb: out STD_LOGIC;
		qc: out STD_LOGIC;
		qd: out STD_LOGIC);
end component;


component a_7430
	port (	a_2: in STD_LOGIC;
		a_3: in STD_LOGIC;
		a_4: in STD_LOGIC;
		a_5: in STD_LOGIC;
		a_6: in STD_LOGIC;
		a_7: in STD_LOGIC;
		a_8: in STD_LOGIC;
		a_9: in STD_LOGIC;
		a_1: out STD_LOGIC);
end component;


component a_7432
	port (	a_2: in STD_LOGIC;
		a_3: in STD_LOGIC;
		a_1: out STD_LOGIC);
end component;


component a_74348
	port (	ei: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (0 to 7);
		eo: out STD_LOGIC;
		gs: out STD_LOGIC;
		a: out STD_LOGIC_VECTOR (2 downto 0));
end component;


component a_74352
	port (	b: in STD_LOGIC;
		a: in STD_LOGIC;
		a_1gn: in STD_LOGIC;
		a_1c: in STD_LOGIC_VECTOR (0 to 3);
		a_2gn: in STD_LOGIC;
		a_2c: in STD_LOGIC_VECTOR (0 to 3);
		a_1yn: out STD_LOGIC;
		a_2yn: out STD_LOGIC);
end component;


component a_74353
	port (	b: in STD_LOGIC;
		a: in STD_LOGIC;
		a_1gn: in STD_LOGIC;
		a_1c: in STD_LOGIC_VECTOR (0 to 3);
		a_2gn: in STD_LOGIC;
		a_2c: in STD_LOGIC_VECTOR (0 to 3);
		a_1yn: out STD_LOGIC;
		a_2yn: out STD_LOGIC);
end component;


component a_74354
	port (	gn1: in STD_LOGIC;
		gn2: in STD_LOGIC;
		g3: in STD_LOGIC;
		s: in STD_LOGIC_VECTOR (2 downto 0);
		scn: in STD_LOGIC;
		dcn: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (7 downto 0);
		y: out STD_LOGIC;
		wn: out STD_LOGIC);
end component;


component a_74356
	port (	gn1: in STD_LOGIC;
		gn2: in STD_LOGIC;
		g3: in STD_LOGIC;
		s: in STD_LOGIC_VECTOR (2 downto 0);
		scn: in STD_LOGIC;
		clk: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (7 downto 0);
		y: out STD_LOGIC;
		wn: out STD_LOGIC);
end component;


component a_74365
	port (	gn1: in STD_LOGIC;
		gn2: in STD_LOGIC;
		a: in STD_LOGIC_VECTOR (1 to 6);
		y: out STD_LOGIC_VECTOR (1 to 6));
end component;


component a_74366
	port (	gn1: in STD_LOGIC;
		gn2: in STD_LOGIC;
		a: in STD_LOGIC_VECTOR (1 to 6);
		yn: out STD_LOGIC_VECTOR (1 to 6));
end component;


component a_74367
	port (	a_1gn: in STD_LOGIC;
		a_1a: in STD_LOGIC_VECTOR (1 to 4);
		a_2gn: in STD_LOGIC;
		a_2a: in STD_LOGIC_VECTOR (1 to 2);
		a_1y: out STD_LOGIC_VECTOR (1 to 4);
		a_2y: out STD_LOGIC_VECTOR (1 to 2));
end component;


component a_74368
	port (	a_1gn: in STD_LOGIC;
		a_1a: in STD_LOGIC_VECTOR (1 to 4);
		a_2gn: in STD_LOGIC;
		a_2a: in STD_LOGIC_VECTOR (1 to 2);
		a_1yn: out STD_LOGIC_VECTOR (1 to 4);
		a_2yn: out STD_LOGIC_VECTOR (1 to 2));
end component;


component a_7437
	port (	a_1a: in STD_LOGIC;
		a_1b: in STD_LOGIC;
		a_2a: in STD_LOGIC;
		a_2b: in STD_LOGIC;
		a_3a: in STD_LOGIC;
		a_3b: in STD_LOGIC;
		a_4a: in STD_LOGIC;
		a_4b: in STD_LOGIC;
		a_1y: out STD_LOGIC;
		a_2y: out STD_LOGIC;
		a_3y: out STD_LOGIC;
		a_4y: out STD_LOGIC);
end component;


component a_74373
	port (	oen: in STD_LOGIC;
		g: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (8 downto 1);
		q: out STD_LOGIC_VECTOR (8 downto 1));
end component;


component a_74373b
	port (	oen: in STD_LOGIC;
		g: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (8 downto 1);
		q: out STD_LOGIC_VECTOR (8 downto 1));
end component;


component a_74374
	port (	clk: in STD_LOGIC;
		oen: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (8 downto 1);
		q: out STD_LOGIC_VECTOR (8 downto 1));
end component;


component a_74374b
	port (	clk: in STD_LOGIC;
		oen: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (8 downto 1);
		q: out STD_LOGIC_VECTOR (8 downto 1));
end component;


component a_74374NT
	port (	clk: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (8 downto 1);
		q: out STD_LOGIC_VECTOR (8 downto 1));
end component;


component a_74375
	port (	a_1d: in STD_LOGIC;
		a_2d: in STD_LOGIC;
		a_3d: in STD_LOGIC;
		a_4d: in STD_LOGIC;
		e12: in STD_LOGIC;
		e34: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_1qn: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_2qn: out STD_LOGIC;
		a_3q: out STD_LOGIC;
		a_3qn: out STD_LOGIC;
		a_4q: out STD_LOGIC;
		a_4qn: out STD_LOGIC);
end component;


component a_74376
	port (	clk: in STD_LOGIC;
		clrn: in STD_LOGIC;
		a_1j: in STD_LOGIC;
		a_1kn: in STD_LOGIC;
		a_2j: in STD_LOGIC;
		a_2kn: in STD_LOGIC;
		a_3j: in STD_LOGIC;
		a_3kn: in STD_LOGIC;
		a_4j: in STD_LOGIC;
		a_4kn: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_3q: out STD_LOGIC;
		a_4q: out STD_LOGIC);
end component;


component a_74377
	port (	en: in STD_LOGIC;
		clk: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (8 downto 1);
		q: out STD_LOGIC_VECTOR (8 downto 1));
end component;


component a_74377b
	port (	d1: in STD_LOGIC;
		clk: in STD_LOGIC;
		en: in STD_LOGIC;
		d2: in STD_LOGIC;
		d3: in STD_LOGIC;
		d4: in STD_LOGIC;
		d5: in STD_LOGIC;
		d6: in STD_LOGIC;
		d7: in STD_LOGIC;
		d8: in STD_LOGIC;
		q1: out STD_LOGIC;
		q2: out STD_LOGIC;
		q3: out STD_LOGIC;
		q4: out STD_LOGIC;
		q5: out STD_LOGIC;
		q6: out STD_LOGIC;
		q7: out STD_LOGIC;
		q8: out STD_LOGIC);
end component;


component a_74378
	port (	en: in STD_LOGIC;
		clk: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (6 downto 1);
		q: out STD_LOGIC_VECTOR (6 downto 1));
end component;


component a_74379
	port (	en: in STD_LOGIC;
		clk: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (4 downto 1);
		q: out STD_LOGIC_VECTOR (4 downto 1);
		qn: out STD_LOGIC_VECTOR (4 downto 1));
end component;


component a_74381
	port (	s: in STD_LOGIC_VECTOR (2 downto 0);
		a: in STD_LOGIC_VECTOR (3 downto 0);
		b: in STD_LOGIC_VECTOR (3 downto 0);
		cin: in STD_LOGIC;
		pn: out STD_LOGIC;
		gn: out STD_LOGIC;
		f: out STD_LOGIC_VECTOR (3 downto 0));
end component;


component a_74382
	port (	s: in STD_LOGIC_VECTOR (2 downto 0);
		a: in STD_LOGIC_VECTOR (3 downto 0);
		b: in STD_LOGIC_VECTOR (3 downto 0);
		cin: in STD_LOGIC;
		ovr: out STD_LOGIC;
		cn4: out STD_LOGIC;
		f: out STD_LOGIC_VECTOR (3 downto 0));
end component;


component a_74386
	port (	a: in STD_LOGIC_VECTOR (1 to 4);
		b: in STD_LOGIC_VECTOR (1 to 4);
		y: out STD_LOGIC_VECTOR (1 to 4));
end component;


component a_74390
	port (	a_1clr: in STD_LOGIC;
		a_1clka: in STD_LOGIC;
		a_1clkb: in STD_LOGIC;
		a_2clr: in STD_LOGIC;
		a_2clka: in STD_LOGIC;
		a_2clkb: in STD_LOGIC;
		a_1qd: out STD_LOGIC;
		a_1qc: out STD_LOGIC;
		a_1qb: out STD_LOGIC;
		a_1qa: out STD_LOGIC;
		a_2qd: out STD_LOGIC;
		a_2qc: out STD_LOGIC;
		a_2qb: out STD_LOGIC;
		a_2qa: out STD_LOGIC);
end component;


component a_74393
	port (	a1: in STD_LOGIC;
		clr1: in STD_LOGIC;
		a2: in STD_LOGIC;
		clr2: in STD_LOGIC;
		q1a: out STD_LOGIC;
		q1b: out STD_LOGIC;
		q1c: out STD_LOGIC;
		q1d: out STD_LOGIC;
		q2a: out STD_LOGIC;
		q2b: out STD_LOGIC;
		q2c: out STD_LOGIC;
		q2d: out STD_LOGIC);
end component;


component a_74396
	port (	strbn: in STD_LOGIC;
		clk: in STD_LOGIC;
		d1: in STD_LOGIC;
		d2: in STD_LOGIC;
		d3: in STD_LOGIC;
		d4: in STD_LOGIC;
		a_1q1: out STD_LOGIC;
		a_1q2: out STD_LOGIC;
		a_1q3: out STD_LOGIC;
		a_1q4: out STD_LOGIC;
		a_2q1: out STD_LOGIC;
		a_2q2: out STD_LOGIC;
		a_2q3: out STD_LOGIC;
		a_2q4: out STD_LOGIC);
end component;


component a_74398
	port (	sel: in STD_LOGIC;
		a1: in STD_LOGIC;
		b1: in STD_LOGIC;
		c1: in STD_LOGIC;
		d1: in STD_LOGIC;
		a2: in STD_LOGIC;
		b2: in STD_LOGIC;
		c2: in STD_LOGIC;
		d2: in STD_LOGIC;
		clk: in STD_LOGIC;
		qa: out STD_LOGIC;
		qan: out STD_LOGIC;
		qb: out STD_LOGIC;
		qbn: out STD_LOGIC;
		qc: out STD_LOGIC;
		qcn: out STD_LOGIC;
		qd: out STD_LOGIC;
		qdn: out STD_LOGIC);
end component;


component a_74399
	port (	sel: in STD_LOGIC;
		a1: in STD_LOGIC;
		b1: in STD_LOGIC;
		c1: in STD_LOGIC;
		d1: in STD_LOGIC;
		a2: in STD_LOGIC;
		b2: in STD_LOGIC;
		c2: in STD_LOGIC;
		d2: in STD_LOGIC;
		clk: in STD_LOGIC;
		qa: out STD_LOGIC;
		qb: out STD_LOGIC;
		qc: out STD_LOGIC;
		qd: out STD_LOGIC);
end component;


component a_7440
	port (	a_1a: in STD_LOGIC;
		a_1b: in STD_LOGIC;
		a_1c: in STD_LOGIC;
		a_1d: in STD_LOGIC;
		a_2a: in STD_LOGIC;
		a_2b: in STD_LOGIC;
		a_2c: in STD_LOGIC;
		a_2d: in STD_LOGIC;
		a_1y: out STD_LOGIC;
		a_2y: out STD_LOGIC);
end component;


component a_7442
	port (	d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		o0n: out STD_LOGIC;
		o1n: out STD_LOGIC;
		o2n: out STD_LOGIC;
		o3n: out STD_LOGIC;
		o4n: out STD_LOGIC;
		o5n: out STD_LOGIC;
		o6n: out STD_LOGIC;
		o7n: out STD_LOGIC;
		o8n: out STD_LOGIC;
		o9n: out STD_LOGIC);
end component;


component a_7443
	port (	d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		o0n: out STD_LOGIC;
		o1n: out STD_LOGIC;
		o2n: out STD_LOGIC;
		o3n: out STD_LOGIC;
		o4n: out STD_LOGIC;
		o5n: out STD_LOGIC;
		o6n: out STD_LOGIC;
		o7n: out STD_LOGIC;
		o8n: out STD_LOGIC;
		o9n: out STD_LOGIC);
end component;


component a_7444
	port (	d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		o0n: out STD_LOGIC;
		o1n: out STD_LOGIC;
		o2n: out STD_LOGIC;
		o3n: out STD_LOGIC;
		o4n: out STD_LOGIC;
		o5n: out STD_LOGIC;
		o6n: out STD_LOGIC;
		o7n: out STD_LOGIC;
		o8n: out STD_LOGIC;
		o9n: out STD_LOGIC);
end component;


component a_74445
	port (	d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		o0n: out STD_LOGIC;
		o1n: out STD_LOGIC;
		o2n: out STD_LOGIC;
		o3n: out STD_LOGIC;
		o4n: out STD_LOGIC;
		o5n: out STD_LOGIC;
		o6n: out STD_LOGIC;
		o7n: out STD_LOGIC;
		o8n: out STD_LOGIC;
		o9n: out STD_LOGIC);
end component;


component a_7445
	port (	d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		o0n: out STD_LOGIC;
		o1n: out STD_LOGIC;
		o2n: out STD_LOGIC;
		o3n: out STD_LOGIC;
		o4n: out STD_LOGIC;
		o5n: out STD_LOGIC;
		o6n: out STD_LOGIC;
		o7n: out STD_LOGIC;
		o8n: out STD_LOGIC;
		o9n: out STD_LOGIC);
end component;


component a_7446
	port (	ltn: in STD_LOGIC;
		rbin: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		bin: in STD_LOGIC;
		oa: out STD_LOGIC;
		ob: out STD_LOGIC;
		oc: out STD_LOGIC;
		od: out STD_LOGIC;
		oe: out STD_LOGIC;
		a_of: out STD_LOGIC;
		og: out STD_LOGIC;
		rbon: out STD_LOGIC);
end component;


component a_74465
	port (	gn: in STD_LOGIC_VECTOR (1 to 2);
		a: in STD_LOGIC_VECTOR (1 to 8);
		y: out STD_LOGIC_VECTOR (1 to 8));
end component;


component a_74466
	port (	gn: in STD_LOGIC_VECTOR (1 to 2);
		a: in STD_LOGIC_VECTOR (1 to 8);
		yn: out STD_LOGIC_VECTOR (1 to 8));
end component;


component a_74467
	port (	a_1gn: in STD_LOGIC;
		a_1a: in STD_LOGIC_VECTOR (1 to 4);
		a_2gn: in STD_LOGIC;
		a_2a: in STD_LOGIC_VECTOR (1 to 4);
		a_1y: out STD_LOGIC_VECTOR (1 to 4);
		a_2y: out STD_LOGIC_VECTOR (1 to 4));
end component;


component a_74468
	port (	a_1gn: in STD_LOGIC;
		a_1a: in STD_LOGIC_VECTOR (1 to 4);
		a_2gn: in STD_LOGIC;
		a_2a: in STD_LOGIC_VECTOR (1 to 4);
		a_1yn: out STD_LOGIC_VECTOR (1 to 4);
		a_2yn: out STD_LOGIC_VECTOR (1 to 4));
end component;


component a_7447
	port (	ltn: in STD_LOGIC;
		rbin: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		bin: in STD_LOGIC;
		oa: out STD_LOGIC;
		ob: out STD_LOGIC;
		oc: out STD_LOGIC;
		od: out STD_LOGIC;
		oe: out STD_LOGIC;
		a_of: out STD_LOGIC;
		og: out STD_LOGIC;
		rbon: out STD_LOGIC);
end component;


component a_7448
	port (	ltn: in STD_LOGIC;
		rbin: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		bin: in STD_LOGIC;
		oa: out STD_LOGIC;
		ob: out STD_LOGIC;
		oc: out STD_LOGIC;
		od: out STD_LOGIC;
		oe: out STD_LOGIC;
		a_of: out STD_LOGIC;
		og: out STD_LOGIC;
		rbon: out STD_LOGIC);
end component;


component a_7449
	port (	d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		bin: in STD_LOGIC;
		oa: out STD_LOGIC;
		ob: out STD_LOGIC;
		oc: out STD_LOGIC;
		od: out STD_LOGIC;
		oe: out STD_LOGIC;
		a_of: out STD_LOGIC;
		og: out STD_LOGIC);
end component;


component a_74490
	port (	a_1set9: in STD_LOGIC;
		a_1clr: in STD_LOGIC;
		a_1clk: in STD_LOGIC;
		a_2set9: in STD_LOGIC;
		a_2clr: in STD_LOGIC;
		a_2clk: in STD_LOGIC;
		a_1qd: out STD_LOGIC;
		a_1qc: out STD_LOGIC;
		a_1qb: out STD_LOGIC;
		a_1qa: out STD_LOGIC;
		a_2qd: out STD_LOGIC;
		a_2qc: out STD_LOGIC;
		a_2qb: out STD_LOGIC;
		a_2qa: out STD_LOGIC);
end component;


component a_7450
	port (	a_1x: in STD_LOGIC;
		a_1xn: in STD_LOGIC;
		a_1a: in STD_LOGIC;
		a_1b: in STD_LOGIC;
		a_1c: in STD_LOGIC;
		a_1d: in STD_LOGIC;
		a_2a: in STD_LOGIC;
		a_2b: in STD_LOGIC;
		a_2c: in STD_LOGIC;
		a_2d: in STD_LOGIC;
		a_1yn: out STD_LOGIC;
		a_2yn: out STD_LOGIC);
end component;


component a_7451
	port (	a_1a: in STD_LOGIC;
		a_1b: in STD_LOGIC;
		a_1c: in STD_LOGIC;
		a_1d: in STD_LOGIC;
		a_1e: in STD_LOGIC;
		a_1f: in STD_LOGIC;
		a_2a: in STD_LOGIC;
		a_2b: in STD_LOGIC;
		a_2c: in STD_LOGIC;
		a_2d: in STD_LOGIC;
		a_1yn: out STD_LOGIC;
		a_2yn: out STD_LOGIC);
end component;


component a_74518
	port (	p: in STD_LOGIC_VECTOR (7 downto 0);
		q: in STD_LOGIC_VECTOR (7 downto 0);
		gn: in STD_LOGIC;
		pq: out STD_LOGIC);
end component;


component a_74518b
	port (	p: in STD_LOGIC_VECTOR (7 downto 0);
		q: in STD_LOGIC_VECTOR (7 downto 0);
		gn: in STD_LOGIC;
		pq: out STD_LOGIC);
end component;


component a_7452
	port (	x: in STD_LOGIC;
		a: in STD_LOGIC;
		b: in STD_LOGIC;
		c: in STD_LOGIC;
		d: in STD_LOGIC;
		e: in STD_LOGIC;
		f: in STD_LOGIC;
		g: in STD_LOGIC;
		h: in STD_LOGIC;
		i: in STD_LOGIC;
		y: out STD_LOGIC);
end component;


component a_7453
	port (	xn: in STD_LOGIC;
		x: in STD_LOGIC;
		a: in STD_LOGIC;
		b: in STD_LOGIC;
		c: in STD_LOGIC;
		d: in STD_LOGIC;
		e: in STD_LOGIC;
		f: in STD_LOGIC;
		g: in STD_LOGIC;
		h: in STD_LOGIC;
		yn: out STD_LOGIC);
end component;


component a_7454
	port (	a: in STD_LOGIC;
		b: in STD_LOGIC;
		c: in STD_LOGIC;
		d: in STD_LOGIC;
		e: in STD_LOGIC;
		f: in STD_LOGIC;
		g: in STD_LOGIC;
		h: in STD_LOGIC;
		i: in STD_LOGIC;
		j: in STD_LOGIC;
		yn: out STD_LOGIC);
end component;


component a_74540
	port (	gn: in STD_LOGIC_VECTOR (1 to 2);
		a: in STD_LOGIC_VECTOR (1 to 8);
		yn: out STD_LOGIC_VECTOR (1 to 8));
end component;


component a_74541
	port (	gn: in STD_LOGIC_VECTOR (1 to 2);
		a: in STD_LOGIC_VECTOR (1 to 8);
		y: out STD_LOGIC_VECTOR (1 to 8));
end component;


component a_74548
	port (	clk: in STD_LOGIC;
		clkenn1: in STD_LOGIC;
		clkenn2: in STD_LOGIC;
		insel: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (7 downto 0);
		outsel: in STD_LOGIC;
		oen: in STD_LOGIC;
		y: out STD_LOGIC_VECTOR (7 downto 0));
end component;


component a_74549
	port (	g: in STD_LOGIC;
		g1n: in STD_LOGIC;
		g2n: in STD_LOGIC;
		insel: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (7 downto 0);
		outsel: in STD_LOGIC;
		oen: in STD_LOGIC;
		y: out STD_LOGIC_VECTOR (7 downto 0));
end component;


component a_7455
	port (	a: in STD_LOGIC;
		b: in STD_LOGIC;
		c: in STD_LOGIC;
		d: in STD_LOGIC;
		e: in STD_LOGIC;
		f: in STD_LOGIC;
		g: in STD_LOGIC;
		h: in STD_LOGIC;
		yn: out STD_LOGIC);
end component;


component a_7456
	port (	clr: in STD_LOGIC;
		clkb: in STD_LOGIC;
		clka: in STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC);
end component;


component a_7457
	port (	clr: in STD_LOGIC;
		clkb: in STD_LOGIC;
		clka: in STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC);
end component;


component a_74589
	port (	oen: in STD_LOGIC;
		srclk: in STD_LOGIC;
		ser: in STD_LOGIC;
		srldn: in STD_LOGIC;
		rclk: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (0 to 7);
		qhn: out STD_LOGIC);
end component;


component a_74590
	port (	gn: in STD_LOGIC;
		cclrn: in STD_LOGIC;
		ccken: in STD_LOGIC;
		cclk: in STD_LOGIC;
		rclk: in STD_LOGIC;
		qh: out STD_LOGIC;
		qg: out STD_LOGIC;
		qf: out STD_LOGIC;
		qe: out STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC;
		rcon: out STD_LOGIC);
end component;


component a_74592
	port (	cclrn: in STD_LOGIC;
		cloadn: in STD_LOGIC;
		rclk: in STD_LOGIC;
		ccken: in STD_LOGIC;
		cclk: in STD_LOGIC;
		h: in STD_LOGIC;
		g: in STD_LOGIC;
		f: in STD_LOGIC;
		e: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		rcon: out STD_LOGIC);
end component;


component a_74594
	port (	srclrn: in STD_LOGIC;
		rclrn: in STD_LOGIC;
		srclk: in STD_LOGIC;
		rclk: in STD_LOGIC;
		ser: in STD_LOGIC;
		qa: out STD_LOGIC;
		qb: out STD_LOGIC;
		qc: out STD_LOGIC;
		qd: out STD_LOGIC;
		qe: out STD_LOGIC;
		qf: out STD_LOGIC;
		qg: out STD_LOGIC;
		qh: out STD_LOGIC;
		qhn: out STD_LOGIC);
end component;


component a_74595
	port (	gn: in STD_LOGIC;
		srclrn: in STD_LOGIC;
		srclk: in STD_LOGIC;
		rclk: in STD_LOGIC;
		ser: in STD_LOGIC;
		qa: out STD_LOGIC;
		qb: out STD_LOGIC;
		qc: out STD_LOGIC;
		qd: out STD_LOGIC;
		qe: out STD_LOGIC;
		qf: out STD_LOGIC;
		qg: out STD_LOGIC;
		qh: out STD_LOGIC;
		qhn: out STD_LOGIC);
end component;


component a_74597
	port (	srclrn: in STD_LOGIC;
		srldn: in STD_LOGIC;
		rclk: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (7 downto 0);
		srclk: in STD_LOGIC;
		ser: in STD_LOGIC;
		qhn: out STD_LOGIC);
end component;


component a_74604
	port (	clk: in STD_LOGIC;
		sel: in STD_LOGIC;
		a: in STD_LOGIC_VECTOR (1 to 8);
		b: in STD_LOGIC_VECTOR (1 to 8);
		y: out STD_LOGIC_VECTOR (1 to 8));
end component;


component a_74630
	port (	s1: in STD_LOGIC;
		s0: in STD_LOGIC;
		db: in STD_LOGIC_VECTOR (15 downto 0);
		cb: in STD_LOGIC_VECTOR (5 downto 0);
		dbo: out STD_LOGIC_VECTOR (15 downto 0);
		cbo: out STD_LOGIC_VECTOR (5 downto 0);
		sef: out STD_LOGIC;
		def: out STD_LOGIC);
end component;


component a_74636
	port (	s1: in STD_LOGIC;
		s0: in STD_LOGIC;
		db: in STD_LOGIC_VECTOR (7 downto 0);
		cb: in STD_LOGIC_VECTOR (4 downto 0);
		dbo: out STD_LOGIC_VECTOR (7 downto 0);
		cbo: out STD_LOGIC_VECTOR (4 downto 0);
		sef: out STD_LOGIC;
		def: out STD_LOGIC);
end component;


component a_7464
	port (	a: in STD_LOGIC;
		b: in STD_LOGIC;
		c: in STD_LOGIC;
		d: in STD_LOGIC;
		e: in STD_LOGIC;
		f: in STD_LOGIC;
		g: in STD_LOGIC;
		h: in STD_LOGIC;
		i: in STD_LOGIC;
		j: in STD_LOGIC;
		k: in STD_LOGIC;
		y: out STD_LOGIC);
end component;


component a_74670
	port (	wb: in STD_LOGIC;
		wa: in STD_LOGIC;
		gwn: in STD_LOGIC;
		rb: in STD_LOGIC;
		ra: in STD_LOGIC;
		grn: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (1 to 4);
		q: out STD_LOGIC_VECTOR (1 to 4));
end component;


component a_7468
	port (	a_1clk1: in STD_LOGIC;
		a_1clk2: in STD_LOGIC;
		a_1clrn: in STD_LOGIC;
		a_2clk: in STD_LOGIC;
		a_2clrn: in STD_LOGIC;
		a_1qd: out STD_LOGIC;
		a_1qc: out STD_LOGIC;
		a_1qb: out STD_LOGIC;
		a_1qa: out STD_LOGIC;
		a_2qd: out STD_LOGIC;
		a_2qc: out STD_LOGIC;
		a_2qb: out STD_LOGIC;
		a_2qa: out STD_LOGIC);
end component;


component a_74684
	port (	p: in STD_LOGIC_VECTOR (7 downto 0);
		q: in STD_LOGIC_VECTOR (7 downto 0);
		equaln: out STD_LOGIC;
		p_gr_qn: out STD_LOGIC);
end component;


component a_74686
	port (	g1n: in STD_LOGIC;
		g2n: in STD_LOGIC;
		p: in STD_LOGIC_VECTOR (7 downto 0);
		q: in STD_LOGIC_VECTOR (7 downto 0);
		equaln: out STD_LOGIC;
		p_gr_qn: out STD_LOGIC);
end component;


component a_74688
	port (	gn: in STD_LOGIC;
		p: in STD_LOGIC_VECTOR (7 downto 0);
		q: in STD_LOGIC_VECTOR (7 downto 0);
		equaln: out STD_LOGIC);
end component;


component a_7469
	port (	a_1clk1: in STD_LOGIC;
		a_1clk2: in STD_LOGIC;
		a_1clrn: in STD_LOGIC;
		a_2clk: in STD_LOGIC;
		a_2clrn: in STD_LOGIC;
		a_1qd: out STD_LOGIC;
		a_1qc: out STD_LOGIC;
		a_1qb: out STD_LOGIC;
		a_1qa: out STD_LOGIC;
		a_2qd: out STD_LOGIC;
		a_2qc: out STD_LOGIC;
		a_2qb: out STD_LOGIC;
		a_2qa: out STD_LOGIC);
end component;


component a_7470
	port (	prn: in STD_LOGIC;
		clrn: in STD_LOGIC;
		clk: in STD_LOGIC;
		j1: in STD_LOGIC;
		j2: in STD_LOGIC;
		jn: in STD_LOGIC;
		k1: in STD_LOGIC;
		k2: in STD_LOGIC;
		kn: in STD_LOGIC;
		q: out STD_LOGIC;
		qn: out STD_LOGIC);
end component;


component a_7471
	port (	prn: in STD_LOGIC;
		clk: in STD_LOGIC;
		j1a: in STD_LOGIC;
		j1b: in STD_LOGIC;
		j2a: in STD_LOGIC;
		j2b: in STD_LOGIC;
		k1a: in STD_LOGIC;
		k1b: in STD_LOGIC;
		k2a: in STD_LOGIC;
		k2b: in STD_LOGIC;
		q: out STD_LOGIC;
		qn: out STD_LOGIC);
end component;


component a_7472
	port (	prn: in STD_LOGIC;
		clrn: in STD_LOGIC;
		clk: in STD_LOGIC;
		j1: in STD_LOGIC;
		j2: in STD_LOGIC;
		j3: in STD_LOGIC;
		k1: in STD_LOGIC;
		k2: in STD_LOGIC;
		k3: in STD_LOGIC;
		q: out STD_LOGIC;
		qn: out STD_LOGIC);
end component;


component a_7473
	port (	a_1clrn: in STD_LOGIC;
		a_1clk: in STD_LOGIC;
		a_1j: in STD_LOGIC;
		a_1k: in STD_LOGIC;
		a_2clrn: in STD_LOGIC;
		a_2clk: in STD_LOGIC;
		a_2j: in STD_LOGIC;
		a_2k: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_1qn: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_2qn: out STD_LOGIC);
end component;


component a_7473a
	port (	a_1j: in STD_LOGIC;
		a_1clkn: in STD_LOGIC;
		a_1k: in STD_LOGIC;
		a_1clrn: in STD_LOGIC;
		a_2j: in STD_LOGIC;
		a_2clkn: in STD_LOGIC;
		a_2k: in STD_LOGIC;
		a_2clrn: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_1qn: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_2qn: out STD_LOGIC);
end component;


component a_7474
	port (	a_1prn: in STD_LOGIC;
		a_1clrn: in STD_LOGIC;
		a_1clk: in STD_LOGIC;
		a_1d: in STD_LOGIC;
		a_2prn: in STD_LOGIC;
		a_2clrn: in STD_LOGIC;
		a_2clk: in STD_LOGIC;
		a_2d: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_1qn: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_2qn: out STD_LOGIC);
end component;


component a_7475
	port (	a_1d: in STD_LOGIC;
		a_2d: in STD_LOGIC;
		a_3d: in STD_LOGIC;
		a_4d: in STD_LOGIC;
		e12: in STD_LOGIC;
		e34: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_1qn: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_2qn: out STD_LOGIC;
		a_3q: out STD_LOGIC;
		a_3qn: out STD_LOGIC;
		a_4q: out STD_LOGIC;
		a_4qn: out STD_LOGIC);
end component;


component a_7476
	port (	a_1prn: in STD_LOGIC;
		a_1clrn: in STD_LOGIC;
		a_1clk: in STD_LOGIC;
		a_1j: in STD_LOGIC;
		a_1k: in STD_LOGIC;
		a_2prn: in STD_LOGIC;
		a_2clrn: in STD_LOGIC;
		a_2clk: in STD_LOGIC;
		a_2j: in STD_LOGIC;
		a_2k: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_1qn: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_2qn: out STD_LOGIC);
end component;


component a_7476a
	port (	a_1prn: in STD_LOGIC;
		a_1j: in STD_LOGIC;
		a_1k: in STD_LOGIC;
		a_1clrn: in STD_LOGIC;
		a_1clkn: in STD_LOGIC;
		a_2prn: in STD_LOGIC;
		a_2j: in STD_LOGIC;
		a_2k: in STD_LOGIC;
		a_2clrn: in STD_LOGIC;
		a_2clkn: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_1qn: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_2qn: out STD_LOGIC);
end component;


component a_7477
	port (	a_1d: in STD_LOGIC;
		a_2d: in STD_LOGIC;
		a_3d: in STD_LOGIC;
		a_4d: in STD_LOGIC;
		e12: in STD_LOGIC;
		e34: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_3q: out STD_LOGIC;
		a_4q: out STD_LOGIC);
end component;


component a_7478
	port (	clrn: in STD_LOGIC;
		a_1prn: in STD_LOGIC;
		a_1j: in STD_LOGIC;
		a_1k: in STD_LOGIC;
		a_2prn: in STD_LOGIC;
		a_2j: in STD_LOGIC;
		a_2k: in STD_LOGIC;
		clk: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_1qn: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_2qn: out STD_LOGIC);
end component;


component a_7478a
	port (	a_1prn: in STD_LOGIC;
		a_1j: in STD_LOGIC;
		a_1k: in STD_LOGIC;
		a_2prn: in STD_LOGIC;
		a_2j: in STD_LOGIC;
		a_2k: in STD_LOGIC;
		clkn: in STD_LOGIC;
		clrn: in STD_LOGIC;
		a_1q: out STD_LOGIC;
		a_1qn: out STD_LOGIC;
		a_2q: out STD_LOGIC;
		a_2qn: out STD_LOGIC);
end component;


component a_7480
	port (	cn0: in STD_LOGIC;
		a1: in STD_LOGIC;
		a2: in STD_LOGIC;
		as: in STD_LOGIC;
		ac: in STD_LOGIC;
		b1: in STD_LOGIC;
		b2: in STD_LOGIC;
		bs: in STD_LOGIC;
		bc: in STD_LOGIC;
		cn1n: out STD_LOGIC;
		sum: out STD_LOGIC;
		sumn: out STD_LOGIC);
end component;


component a_7482
	port (	a: in STD_LOGIC_VECTOR (2 downto 1);
		b: in STD_LOGIC_VECTOR (2 downto 1);
		c0: in STD_LOGIC;
		sum: out STD_LOGIC_VECTOR (2 downto 1);
		c2: out STD_LOGIC);
end component;


component a_74821
	port (	oen: in STD_LOGIC;
		clk: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (1 to 10);
		q: out STD_LOGIC_VECTOR (1 to 10));
end component;


component a_74821b
	port (	d: in STD_LOGIC_VECTOR (10 downto 1);
		oen: in STD_LOGIC;
		clk: in STD_LOGIC;
		q: out STD_LOGIC_VECTOR (10 downto 1));
end component;


component a_74822
	port (	oen: in STD_LOGIC;
		clk: in STD_LOGIC;
		dn: in STD_LOGIC_VECTOR (1 to 10);
		q: out STD_LOGIC_VECTOR (1 to 10));
end component;


component a_74822b
	port (	dn: in STD_LOGIC_VECTOR (10 downto 1);
		oen: in STD_LOGIC;
		clk: in STD_LOGIC;
		q: out STD_LOGIC_VECTOR (10 downto 1));
end component;


component a_74823
	port (	oen: in STD_LOGIC;
		clrn: in STD_LOGIC;
		clkenn: in STD_LOGIC;
		clk: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (1 to 9);
		q: out STD_LOGIC_VECTOR (1 to 9));
end component;


component a_74823b
	port (	d: in STD_LOGIC_VECTOR (9 downto 1);
		oen: in STD_LOGIC;
		clk: in STD_LOGIC;
		clrn: in STD_LOGIC;
		clkenn: in STD_LOGIC;
		q: out STD_LOGIC_VECTOR (9 downto 1));
end component;


component a_74824
	port (	oen: in STD_LOGIC;
		clrn: in STD_LOGIC;
		clkenn: in STD_LOGIC;
		clk: in STD_LOGIC;
		dn: in STD_LOGIC_VECTOR (1 to 9);
		q: out STD_LOGIC_VECTOR (1 to 9));
end component;


component a_74824b
	port (	dn: in STD_LOGIC_VECTOR (9 downto 1);
		oen: in STD_LOGIC;
		clk: in STD_LOGIC;
		clrn: in STD_LOGIC;
		clkenn: in STD_LOGIC;
		q: out STD_LOGIC_VECTOR (9 downto 1));
end component;


component a_74825
	port (	oe1n: in STD_LOGIC;
		oe2n: in STD_LOGIC;
		oe3n: in STD_LOGIC;
		clrn: in STD_LOGIC;
		clkenn: in STD_LOGIC;
		clk: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (1 to 8);
		q: out STD_LOGIC_VECTOR (1 to 8));
end component;


component a_74825b
	port (	d: in STD_LOGIC_VECTOR (8 downto 1);
		oe1n: in STD_LOGIC;
		oe2n: in STD_LOGIC;
		oe3n: in STD_LOGIC;
		clk: in STD_LOGIC;
		clrn: in STD_LOGIC;
		clkenn: in STD_LOGIC;
		q: out STD_LOGIC_VECTOR (8 downto 1));
end component;


component a_74826
	port (	oe1n: in STD_LOGIC;
		oe2n: in STD_LOGIC;
		oe3n: in STD_LOGIC;
		clrn: in STD_LOGIC;
		clkenn: in STD_LOGIC;
		clk: in STD_LOGIC;
		dn: in STD_LOGIC_VECTOR (1 to 8);
		q: out STD_LOGIC_VECTOR (1 to 8));
end component;


component a_74826b
	port (	dn: in STD_LOGIC_VECTOR (8 downto 1);
		oe1n: in STD_LOGIC;
		oe2n: in STD_LOGIC;
		oe3n: in STD_LOGIC;
		clk: in STD_LOGIC;
		clrn: in STD_LOGIC;
		clkenn: in STD_LOGIC;
		q: out STD_LOGIC_VECTOR (8 downto 1));
end component;


component a_7483
	port (	a: in STD_LOGIC_VECTOR (4 downto 1);
		b: in STD_LOGIC_VECTOR (4 downto 1);
		c0: in STD_LOGIC;
		s: out STD_LOGIC_VECTOR (4 downto 1);
		c4: out STD_LOGIC);
end component;


component a_74841
	port (	oen: in STD_LOGIC;
		c: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (1 to 10);
		q: out STD_LOGIC_VECTOR (1 to 10));
end component;


component a_74841b
	port (	d: in STD_LOGIC_VECTOR (10 downto 1);
		oen: in STD_LOGIC;
		c: in STD_LOGIC;
		q: out STD_LOGIC_VECTOR (10 downto 1));
end component;


component a_74842
	port (	oen: in STD_LOGIC;
		c: in STD_LOGIC;
		dn: in STD_LOGIC_VECTOR (1 to 10);
		q: out STD_LOGIC_VECTOR (1 to 10));
end component;


component a_74842b
	port (	dn: in STD_LOGIC_VECTOR (10 downto 1);
		oen: in STD_LOGIC;
		c: in STD_LOGIC;
		q: out STD_LOGIC_VECTOR (10 downto 1));
end component;


component a_74843
	port (	oen: in STD_LOGIC;
		clrn: in STD_LOGIC;
		pren: in STD_LOGIC;
		ena: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (1 to 9);
		q: out STD_LOGIC_VECTOR (1 to 9));
end component;


component a_74844
	port (	oen: in STD_LOGIC;
		clrn: in STD_LOGIC;
		pren: in STD_LOGIC;
		ena: in STD_LOGIC;
		dn: in STD_LOGIC_VECTOR (1 to 9);
		q: out STD_LOGIC_VECTOR (1 to 9));
end component;


component a_74845
	port (	oen1: in STD_LOGIC;
		oen2: in STD_LOGIC;
		oen3: in STD_LOGIC;
		clrn: in STD_LOGIC;
		pren: in STD_LOGIC;
		ena: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (1 to 8);
		q: out STD_LOGIC_VECTOR (1 to 8));
end component;


component a_74846
	port (	oen1: in STD_LOGIC;
		oen2: in STD_LOGIC;
		oen3: in STD_LOGIC;
		clrn: in STD_LOGIC;
		pren: in STD_LOGIC;
		ena: in STD_LOGIC;
		dn: in STD_LOGIC_VECTOR (1 to 8);
		q: out STD_LOGIC_VECTOR (1 to 8));
end component;


component a_7485
	port (	a: in STD_LOGIC_VECTOR (3 downto 0);
		b: in STD_LOGIC_VECTOR (3 downto 0);
		agbi: in STD_LOGIC;
		albi: in STD_LOGIC;
		aebi: in STD_LOGIC;
		agbo: out STD_LOGIC;
		albo: out STD_LOGIC;
		aebo: out STD_LOGIC);
end component;


component a_7486
	port (	a_2: in STD_LOGIC;
		a_3: in STD_LOGIC;
		a_1: out STD_LOGIC);
end component;


component a_7487
	port (	a: in STD_LOGIC_VECTOR (4 downto 1);
		b: in STD_LOGIC;
		c: in STD_LOGIC;
		y: out STD_LOGIC_VECTOR (4 downto 1));
end component;


component a_7490
	port (	set9a: in STD_LOGIC;
		set9b: in STD_LOGIC;
		clra: in STD_LOGIC;
		clrb: in STD_LOGIC;
		clka: in STD_LOGIC;
		clkb: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC);
end component;


component a_7491
	port (	clk: in STD_LOGIC;
		a: in STD_LOGIC;
		b: in STD_LOGIC;
		qh: out STD_LOGIC;
		qhn: out STD_LOGIC);
end component;


component a_7492
	port (	clra: in STD_LOGIC;
		clrb: in STD_LOGIC;
		clka: in STD_LOGIC;
		clkb: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC);
end component;


component a_7493
	port (	clka: in STD_LOGIC;
		clkb: in STD_LOGIC;
		ro1: in STD_LOGIC;
		ro2: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC);
end component;


component a_7494
	port (	p1a: in STD_LOGIC;
		p2a: in STD_LOGIC;
		p1b: in STD_LOGIC;
		p2b: in STD_LOGIC;
		p1c: in STD_LOGIC;
		p2c: in STD_LOGIC;
		p1d: in STD_LOGIC;
		p2d: in STD_LOGIC;
		pe1: in STD_LOGIC;
		pe2: in STD_LOGIC;
		clr: in STD_LOGIC;
		clk: in STD_LOGIC;
		ser: in STD_LOGIC;
		a_out: out STD_LOGIC);
end component;


component a_7495
	port (	mode: in STD_LOGIC;
		clkl: in STD_LOGIC;
		clkr: in STD_LOGIC;
		ser: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (0 to 3);
		q: out STD_LOGIC_VECTOR (0 to 3));
end component;


component a_7496
	port (	clrn: in STD_LOGIC;
		pe: in STD_LOGIC;
		a: in STD_LOGIC;
		b: in STD_LOGIC;
		c: in STD_LOGIC;
		d: in STD_LOGIC;
		e: in STD_LOGIC;
		clk: in STD_LOGIC;
		ser: in STD_LOGIC;
		qa: out STD_LOGIC;
		qb: out STD_LOGIC;
		qc: out STD_LOGIC;
		qd: out STD_LOGIC;
		qe: out STD_LOGIC);
end component;


component a_7498
	port (	clkn: in STD_LOGIC;
		wrdsl: in STD_LOGIC;
		a1: in STD_LOGIC;
		b1: in STD_LOGIC;
		c1: in STD_LOGIC;
		d1: in STD_LOGIC;
		a2: in STD_LOGIC;
		b2: in STD_LOGIC;
		c2: in STD_LOGIC;
		d2: in STD_LOGIC;
		qa: out STD_LOGIC;
		qb: out STD_LOGIC;
		qc: out STD_LOGIC;
		qd: out STD_LOGIC);
end component;


component a_7499
	port (	mode: in STD_LOGIC;
		clk2: in STD_LOGIC;
		clk1: in STD_LOGIC;
		j: in STD_LOGIC;
		kn: in STD_LOGIC;
		a: in STD_LOGIC;
		b: in STD_LOGIC;
		c: in STD_LOGIC;
		d: in STD_LOGIC;
		qa: out STD_LOGIC;
		qb: out STD_LOGIC;
		qc: out STD_LOGIC;
		qd: out STD_LOGIC;
		qdn: out STD_LOGIC);
end component;


component a_74990
	port (	oerb: in STD_LOGIC;
		c: in STD_LOGIC;
		d: out STD_LOGIC_VECTOR (8 downto 1);
		q: out STD_LOGIC_VECTOR (8 downto 1));
end component;


component a_8count
	port (	clk: in STD_LOGIC;
		clrn: in STD_LOGIC;
		setn: in STD_LOGIC;
		ldn: in STD_LOGIC;
		dnup: in STD_LOGIC;
		gn: in STD_LOGIC;
		h: in STD_LOGIC;
		g: in STD_LOGIC;
		f: in STD_LOGIC;
		e: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		qh: out STD_LOGIC;
		qg: out STD_LOGIC;
		qf: out STD_LOGIC;
		qe: out STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC;
		cout: out STD_LOGIC);
end component;


component a_8DFF
	port (	clk: in STD_LOGIC;
		clrn: in STD_LOGIC;
		prn: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (8 downto 1);
		q: out STD_LOGIC_VECTOR (8 downto 1));
end component;


component a_8DFFE
	port (	clk: in STD_LOGIC;
		ena: in STD_LOGIC;
		clrn: in STD_LOGIC;
		prn: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (8 downto 1);
		q: out STD_LOGIC_VECTOR (8 downto 1));
end component;


component a_8fadd
	port (	cin: in STD_LOGIC;
		a8: in STD_LOGIC;
		a7: in STD_LOGIC;
		a6: in STD_LOGIC;
		a5: in STD_LOGIC;
		a4: in STD_LOGIC;
		a3: in STD_LOGIC;
		a2: in STD_LOGIC;
		a1: in STD_LOGIC;
		b8: in STD_LOGIC;
		b7: in STD_LOGIC;
		b6: in STD_LOGIC;
		b5: in STD_LOGIC;
		b4: in STD_LOGIC;
		b3: in STD_LOGIC;
		b2: in STD_LOGIC;
		b1: in STD_LOGIC;
		cout: out STD_LOGIC;
		sum8: out STD_LOGIC;
		sum7: out STD_LOGIC;
		sum6: out STD_LOGIC;
		sum5: out STD_LOGIC;
		sum4: out STD_LOGIC;
		sum3: out STD_LOGIC;
		sum2: out STD_LOGIC;
		sum1: out STD_LOGIC);
end component;


component a_8faddb
	port (	cin: in STD_LOGIC;
		a: in STD_LOGIC_VECTOR (8 downto 1);
		b: in STD_LOGIC_VECTOR (8 downto 1);
		cout: out STD_LOGIC;
		sum: out STD_LOGIC_VECTOR (8 downto 1));
end component;


component a_8mcomp
	port (	a7: in STD_LOGIC;
	      	a6: in STD_LOGIC;
	      	a5: in STD_LOGIC;
	      	a4: in STD_LOGIC;
	      	a3: in STD_LOGIC;
	      	a2: in STD_LOGIC;
	      	a1: in STD_LOGIC;
	      	a0: in STD_LOGIC;
		b7: in STD_LOGIC;
		b6: in STD_LOGIC;
		b5: in STD_LOGIC;
		b4: in STD_LOGIC;
		b3: in STD_LOGIC;
		b2: in STD_LOGIC;
		b1: in STD_LOGIC;
		b0: in STD_LOGIC;
		altb: out STD_LOGIC;
		aeqb: out STD_LOGIC;
		agtb: out STD_LOGIC;
		aeb7: out STD_LOGIC;
		aeb6: out STD_LOGIC;
		aeb5: out STD_LOGIC;
		aeb4: out STD_LOGIC;
		aeb3: out STD_LOGIC;
		aeb2: out STD_LOGIC;
		aeb1: out STD_LOGIC;
		aeb0: out STD_LOGIC);
end component;


component a_8mcompb
	port (	a: in STD_LOGIC_VECTOR (7 downto 0);
		b: in STD_LOGIC_VECTOR (7 downto 0);
		altb: out STD_LOGIC;
		aeqb: out STD_LOGIC;
		agtb: out STD_LOGIC;
		aeb: out STD_LOGIC_VECTOR (7 downto 0));
end component;


component barrelst
	port (	s: in STD_LOGIC_VECTOR (2 downto 0);
		ldst: in STD_LOGIC;
		a: in STD_LOGIC;
		b: in STD_LOGIC;
		c: in STD_LOGIC;
		d: in STD_LOGIC;
		e: in STD_LOGIC;
		f: in STD_LOGIC;
		g: in STD_LOGIC;
		h: in STD_LOGIC;
		clk: in STD_LOGIC;
		qa: out STD_LOGIC;
		qb: out STD_LOGIC;
		qc: out STD_LOGIC;
		qd: out STD_LOGIC;
		qe: out STD_LOGIC;
		qf: out STD_LOGIC;
		qg: out STD_LOGIC;
		qh: out STD_LOGIC);
end component;


component barrlstb
	port (	s: in STD_LOGIC_VECTOR (2 downto 0);
		ldst: in STD_LOGIC;
		d: in STD_LOGIC_VECTOR (7 downto 0);
		clk: in STD_LOGIC;
		q: out STD_LOGIC_VECTOR (7 downto 0));
end component;


component btri
	port (	oen: in STD_LOGIC;
		a_in: in STD_LOGIC;
		a_out: out STD_LOGIC);
end component;


component cbuf
	port (	a_1: in STD_LOGIC;
		a_2: out STD_LOGIC;
		a_3: out STD_LOGIC);
end component;


component enadff
	port (	d: in STD_LOGIC;
		clk: in STD_LOGIC;
		clrn: in STD_LOGIC;
		prn: in STD_LOGIC;
		ena: in STD_LOGIC;
		q: out STD_LOGIC);
end component;


component explatch
	port (	d: in STD_LOGIC;
		ena: in STD_LOGIC;
		q: out STD_LOGIC);
end component;


component freqdiv
	port (	clr: in STD_LOGIC;
		clk: in STD_LOGIC;
		g: in STD_LOGIC;
		dv2: out STD_LOGIC;
		dv4: out STD_LOGIC;
		dv8: out STD_LOGIC;
		dv16: out STD_LOGIC);
end component;


component gray4
	port (	clk: in STD_LOGIC;
		ena: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC);
end component;


component inhb
	port (	a_2: in STD_LOGIC;
		a_3: in STD_LOGIC;
		a_1: out STD_LOGIC);
end component;


component inpltch
	port (	d: in STD_LOGIC;
		g: in STD_LOGIC;
		q: out STD_LOGIC);
end component;


component mult2
	port (	a: in STD_LOGIC_VECTOR (2 downto 0);
		b: in STD_LOGIC_VECTOR (2 downto 0);
		g: in STD_LOGIC;
		y: out STD_LOGIC_VECTOR (4 downto 0));
end component;


component mult24
	port (	a: in STD_LOGIC_VECTOR (5 downto 1);
		b: in STD_LOGIC_VECTOR (3 downto 1);
		g: in STD_LOGIC;
		y: out STD_LOGIC_VECTOR (7 downto 1));
end component;


component mult4
	port (	a: in STD_LOGIC_VECTOR (5 downto 1);
		b: in STD_LOGIC_VECTOR (5 downto 1);
		g: in STD_LOGIC;
		y: out STD_LOGIC_VECTOR (9 downto 1));
end component;


component mult4b
	port (	a: in STD_LOGIC_VECTOR (5 downto 1);
		b: in STD_LOGIC_VECTOR (5 downto 1);
		g: in STD_LOGIC;
		y: out STD_LOGIC_VECTOR (9 downto 1));
end component;


component nandltch
	port (	sn: in STD_LOGIC;
		rn: in STD_LOGIC;
		q: out STD_LOGIC;
		qn: out STD_LOGIC);
end component;


component norltch
	port (	s: in STD_LOGIC;
		r: in STD_LOGIC;
		q: out STD_LOGIC;
		qn: out STD_LOGIC);
end component;


component ntsc
	port (	clock: in STD_LOGIC;
		reset: in STD_LOGIC;
		csync: out STD_LOGIC;
		hd: out STD_LOGIC;
		vd: out STD_LOGIC;
		fld: out STD_LOGIC;
		blank: out STD_LOGIC;
		burst: out STD_LOGIC);
end component;


component tmult4
	port (	gan: in STD_LOGIC;
		gbn: in STD_LOGIC;
		a: in STD_LOGIC_VECTOR (5 downto 1);
		b: in STD_LOGIC_VECTOR (5 downto 1);
		y: out STD_LOGIC_VECTOR (9 downto 1));
end component;


component unicnt
	port (	clk: in STD_LOGIC;
		clr: in STD_LOGIC;
		set: in STD_LOGIC;
		load: in STD_LOGIC;
		ctst: in STD_LOGIC;
		dnup: in STD_LOGIC;
		rtlt: in STD_LOGIC;
		cin: in STD_LOGIC;
		data: in STD_LOGIC;
		d: in STD_LOGIC;
		c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		qd: out STD_LOGIC;
		qc: out STD_LOGIC;
		qb: out STD_LOGIC;
		qa: out STD_LOGIC;
		cout: out STD_LOGIC);
end component;


component carry
	port (  A_IN:  in STD_LOGIC;
		A_OUT: out STD_LOGIC);
end component;


component cascade
	port (  A_IN:  in STD_LOGIC;
		A_OUT: out STD_LOGIC);
end component;


component dff
	port (  D  :  in STD_LOGIC;
			CLK:  in STD_LOGIC;
	        CLRN: in STD_LOGIC;
	        PRN:  in STD_LOGIC;
		Q  :  out STD_LOGIC);
end component;


component dffe
	port (  D  :  in STD_LOGIC;
			CLK:  in STD_LOGIC;
	        CLRN: in STD_LOGIC;
	        PRN:  in STD_LOGIC;
	        ENA:  in STD_LOGIC;
		Q  :  out STD_LOGIC);
end component;


component exp
	port (  A_IN:  in STD_LOGIC;
		A_OUT: out STD_LOGIC);
end component;


component row_global
	port (  A_IN:  in STD_LOGIC;
		A_OUT: out STD_LOGIC);
end component;


component global
	port (  A_IN:  in STD_LOGIC;
		A_OUT: out STD_LOGIC);
end component;


component jkff
	port (	J  :  in STD_LOGIC;
	        K  :  in STD_LOGIC;
			CLK:  in STD_LOGIC;
	        CLRN: in STD_LOGIC;
	        PRN:  in STD_LOGIC;
		Q  :  out STD_LOGIC);
end component;


component jkffe
	port (	J  :  in STD_LOGIC;
	        K  :  in STD_LOGIC;
			CLK:  in STD_LOGIC;
	        CLRN: in STD_LOGIC;
	        PRN:  in STD_LOGIC;
	        ENA:  in STD_LOGIC;
		Q  :  out STD_LOGIC);
end component;


component latch
	port (  D :   in STD_LOGIC;
		ENA:  in STD_LOGIC;
		Q  :  out STD_LOGIC);
end component;


component lcell
	port (  A_IN:  in STD_LOGIC;
		A_OUT: out STD_LOGIC);
end component;


component soft
	port (  A_IN:  in STD_LOGIC;
		A_OUT: out STD_LOGIC);
end component;


component srff
	port (  S  :  in STD_LOGIC;
	        R  :  in STD_LOGIC;
			CLK:  in STD_LOGIC;
	        CLRN: in STD_LOGIC;
	        PRN:  in STD_LOGIC;
		Q  :  out STD_LOGIC);
end component;


component srffe
	port (  S  :  in STD_LOGIC;
	        R  :  in STD_LOGIC;
			CLK:  in STD_LOGIC;
	        CLRN: in STD_LOGIC;
	        PRN:  in STD_LOGIC;
	        ENA:  in STD_LOGIC;
		Q  :  out STD_LOGIC);
end component;


component tff
	port (  T  	:  in STD_LOGIC;
	        CLK	:  in STD_LOGIC;
	        CLRN:  in STD_LOGIC;
	        PRN	:  in STD_LOGIC;
		Q  :  out STD_LOGIC);
end component;


component tffe
	port (  T  	:  in STD_LOGIC;
	        CLK	:  in STD_LOGIC;
	        CLRN:  in STD_LOGIC;
	        PRN	:  in STD_LOGIC;
	        ENA	:  in STD_LOGIC;
		Q  :  out STD_LOGIC);
end component;


component tri
	port (  A_IN:  in STD_LOGIC;
		OE:  in STD_LOGIC;
		A_OUT: out STD_LOGIC);
end component;


component opndrn
	port (  A_IN:  in STD_LOGIC;
		A_OUT: out STD_LOGIC);
end component;


component a_81MUX
	port (	c: in STD_LOGIC;
		b: in STD_LOGIC;
		a: in STD_LOGIC;
		d7: in STD_LOGIC;
		d6: in STD_LOGIC;
		d5: in STD_LOGIC;
		d4: in STD_LOGIC;
		d3: in STD_LOGIC;
		d2: in STD_LOGIC;
		d1: in STD_LOGIC;
		d0: in STD_LOGIC;
		gn: in STD_LOGIC;
		y: out STD_LOGIC;
		wn: out STD_LOGIC);
end component;

component pll
    port (  A: in STD_LOGIC; 
            B: in STD_LOGIC; 
            nSET: in STD_LOGIC; 
            nDOWN: out STD_LOGIC;
            TRI_DOWN: out STD_LOGIC;
            nUP: out STD_LOGIC;
            TRI_UP: out STD_LOGIC
        );
end component;

component clklock
	generic ( input_frequency : STRING;
			  clockboost : INTEGER
			);
	port ( 	inclk: in STD_LOGIC; 
			outclk: out STD_LOGIC 
		);
end component;

component csfifo
	generic ( 	LPM_WIDTH: POSITIVE;
			LPM_NUMWORDS: POSITIVE
			);
	port (
				data: in STD_LOGIC_VECTOR(LPM_WIDTH-1 downto 0);
				wreq: in STD_LOGIC;
				rreq: in STD_LOGIC;
				clock: in STD_LOGIC;
				clockx2: in STD_LOGIC;
				clr: in STD_LOGIC;
				empty: out STD_LOGIC;
				full: out STD_LOGIC;
				q: out STD_LOGIC_VECTOR(LPM_WIDTH-1 downto 0)
		);
end component;

component csdpram
	generic ( 	LPM_WIDTH: POSITIVE;
 			LPM_WIDTHAD: POSITIVE;
 			LPM_NUMWORDS: POSITIVE 
			);
	port (
				dataa: in STD_LOGIC_VECTOR(LPM_WIDTH-1 downto 0);
				datab: in STD_LOGIC_VECTOR(LPM_WIDTH-1 downto 0);
				addressa: in STD_LOGIC_VECTOR(LPM_WIDTHAD-1 downto 0);
				addressb: in STD_LOGIC_VECTOR(LPM_WIDTHAD-1 downto 0);
				clock: in STD_LOGIC;
				clockx2: in STD_LOGIC;
				wea: in STD_LOGIC;
				web: in STD_LOGIC;
				qa: out STD_LOGIC_VECTOR(LPM_WIDTH-1 downto 0);
				qb: out STD_LOGIC_VECTOR(LPM_WIDTH-1 downto 0);
				busy: out STD_LOGIC
		);
end component;

component busmux
	generic ( WIDTH : POSITIVE
			);
	port ( 	dataa: in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
			datab: in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
			sel: in STD_LOGIC;
			result: out STD_LOGIC_VECTOR(WIDTH-1 downto 0)
		);
end component;

component mux
	generic ( WIDTH : POSITIVE;
			  WIDTHS : POSITIVE
			);
	port ( 	data: in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
			sel: in STD_LOGIC_VECTOR(WIDTHS-1 downto 0);
			result: out STD_LOGIC
		);
end component;

component divide
        generic (WIDTH_Q : POSITIVE;
                 WIDTH_N : POSITIVE;
                 WIDTH_D : POSITIVE;
                 WIDTH_R : POSITIVE;
                 WIDTH_D_MIN : POSITIVE;
                 PIPELINE_DELAY : INTEGER := 0;
                 LPM_PIPELINE : INTEGER := 0);
        port (numerator : in std_logic_vector(WIDTH_N-1 downto 0);
              denominator :in std_logic_vector(WIDTH_D-1 downto 0);
              clock : in std_logic := '1';
              quotient: out std_logic_vector(WIDTH_Q-1 downto 0);
              remainder : out std_logic_vector(WIDTH_R-1 downto 0));
end component;
    
component scfifo
	generic ( LPM_WIDTH : POSITIVE;
	 	  LPM_WIDTHU : POSITIVE;
	 	  LPM_NUMWORDS : POSITIVE;
		  LPM_SHOWAHEAD :  STRING := "OFF";
		  ALMOST_FULL_VALUE : NATURAL := 0;
		  ALMOST_EMPTY_VALUE : NATURAL := 0;
		  ALLOW_RWCYCLE_WHEN_FULL : STRING := "OFF";
		  MAXIMIZE_SPEED : POSITIVE := 5;
		  OVERFLOW_CHECKING :  STRING := "ON";
		  UNDERFLOW_CHECKING : STRING := "ON");
     port (  data  : in std_logic_vector(LPM_WIDTH-1 downto 0);
             clock : in std_logic;
             wrreq : in std_logic;
             rdreq : in std_logic;
             aclr : in std_logic;
             sclr : in std_logic;
             full : out std_logic;
             almost_full : out std_logic;
             empty : out std_logic;
             almost_empty : out std_logic;
             q : out std_logic_vector(LPM_WIDTH-1 downto 0);
             usedW : out std_logic_vector(LPM_WIDTHU-1 downto 0)
     );
end component;

component dcfifo
	generic ( LPM_WIDTH : POSITIVE;
	 	  LPM_WIDTHU : POSITIVE;
	 	  LPM_NUMWORDS : POSITIVE;
		  LPM_SHOWAHEAD :  STRING := "OFF";
		  ALMOST_FULL_VALUE : NATURAL := 0;
		  ALMOST_EMPTY_VALUE : NATURAL := 0;
		  ALLOW_RWCYCLE_WHEN_FULL : STRING := "OFF";
		  MAXIMIZE_SPEED : POSITIVE := 5;
		  OVERFLOW_CHECKING :  STRING := "ON";
		  UNDERFLOW_CHECKING : STRING := "ON";
		  DELAY_RDUSEDW : POSITIVE := 1;
		  DELAY_WRUSEDW : POSITIVE := 1;
		  RDSYNC_DELAYPIPE : POSITIVE := 3;
		  WRSYNC_DELAYPIPE : POSITIVE := 3);
     port (  data  : in std_logic_vector(LPM_WIDTH-1 downto 0);
             rdclk : in std_logic;
             wrclk : in std_logic;
             wrreq : in std_logic;
             rdreq : in std_logic;
             aclr : in std_logic;
             rdfull : out std_logic;
             wrfull : out std_logic;
             wrempty : out std_logic;
             rdempty : out std_logic;
             q : out std_logic_vector(LPM_WIDTH-1 downto 0);
             rdusedW : out std_logic_vector(LPM_WIDTHU-1 downto 0);
             wrusedW : out std_logic_vector(LPM_WIDTHU-1 downto 0));
end component;

end maxplus2;
