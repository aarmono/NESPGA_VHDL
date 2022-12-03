                           --- QSIM Logic Package ---
--  Copyright (c) Mentor Graphics Corporation, 1982-1991, All Rights Reserved.
--                       UNPUBLISHED, LICENSED SOFTWARE.
--            CONFIDENTIAL AND PROPRIETARY INFORMATION WHICH IS THE
--          PROPERTY OF MENTOR GRAPHICS CORPORATION OR ITS LICENSORS.
--  License:  The QSim Logic Package (QLP), but not any accompanying or
--  jointly used software, may be used, reproduced or distributed so long as
--  (1)  the copyright and proprietary rights notice and this License are not
--  removed from the QLP or modified; (2)  the QLP is not modified or used in
--  preparing any derivative or other works; and (3)  the QLP is not
--  distributed in return for any monetary or other payment."

--The LOGIC package provides the basic support that a designer needs to
--interface efficiently with the QuickSim II simulator and Mentor's other
--modeling techniques.


PACKAGE QSIM_logic IS

  --  Predefined Mentor enumerated types that allow
  --  the designer to interface from a VHDL model to
  --  a Mentor Graphics model, or allow a VHDL model to be used
  --  in a non-VHDL design.

  --  The qsim_state type provides signal values that are
  --  typically found in most simulators with minimum worry
  --  about signal strengths.
  --  The signal is mapped as follows:
  --     Mentor  maps  to State
  --   -------------------------
  --     0S,  0r  =>     0
  --     1S,  1r  =>     1
  -- XS, Xr,  Xi  =>     X
  --     0i,  1i  =>     X
  -- 0Z, Xz,  1Z  =>     Z

  --     State   maps  to Mentor
  --    --------------------------
  --         0    =>     0S
  --         1    =>     1S
  --         X    =>     XS
  --         Z    =>     XZ


  -------------------------------------------------------------------
  -- Directive for Altera synthesis of logic types.
  -- Declare the type encoding attribute and set the value for qsim_state
  -- Declare the synthesis directive attributes for functions.
  -- Setting of these attributes for the resolution function and all other 
  -- functions are in the package body
  -------------------------------------------------------------------
  
  ATTRIBUTE logic_type_encoding : string ;
  
  TYPE qsim_state IS ('X', '0', '1', 'Z');
  -- Synthesis directive
  ATTRIBUTE logic_type_encoding of qsim_state:type is ('X','0','1','Z') ;

  TYPE qsim_state_vector IS ARRAY (natural RANGE <>) OF qsim_state;

  -- Resolution function and resolved subtype for qsim_state:
  FUNCTION qsim_wired_x (input : qsim_state_vector) RETURN qsim_state;
    -- A wired 'X' operation is performed on the inputs to determine the
    -- resolved value.
  FUNCTION qsim_wired_or (input : qsim_state_vector) RETURN qsim_state;
    -- A wired OR operation is performed on the inputs to determine the
    -- resolved value.
  FUNCTION qsim_wired_and (input : qsim_state_vector) RETURN qsim_state;
    -- A wired AND operation is performed on the inputs to determine the
    -- resolved value.

  SUBTYPE qsim_state_resolved_x IS qsim_wired_x qsim_state;
  TYPE qsim_state_resolved_x_vector IS ARRAY(NATURAL RANGE <>) 
      OF qsim_state_resolved_x;

  SUBTYPE qsim_state_resolved_or IS qsim_wired_or qsim_state;
  TYPE qsim_state_resolved_or_vector 
       IS ARRAY(natural RANGE <>) OF qsim_state_resolved_or;

  SUBTYPE qsim_state_resolved_and IS qsim_wired_and qsim_state;
  TYPE qsim_state_resolved_and_vector 
       IS ARRAY(natural RANGE <>) OF qsim_state_resolved_and;


  -- Mentor Graphics 12-state values and strengths map one-for-one
  -- with QuickSim II.  This has an implicit resolution function
  -- that matches QuickSim II.  Types qsim_12state and qsim_12state_vector
  -- are provided for accessing all state information and for interfacing to
  -- other Mentor Graphics  primitives.  Only conversion functions to and from are
  -- from are provided.

  TYPE qsim_12state IS ( SXR, SXZ, SXS, SXI,
                         S0R, S0Z, S0S, S0I,
                         S1R, S1Z, S1S, S1I );

  -- Now a vector for qsim_12state:

  TYPE qsim_12state_vector IS ARRAY (natural RANGE <>) OF qsim_12state;

  -- Resolution function and resolved subtype for type qsim_12state:
  FUNCTION qsim_12state_wired (input : qsim_12state_vector) RETURN qsim_12state;
    -- This resolution function implements QuickSim's resolution function.

  SUBTYPE qsim_12state_resolved IS qsim_12state_wired qsim_12state;
  TYPE qsim_12state_resolved_vector
       IS ARRAY(natural RANGE <>) OF qsim_12state_resolved;

  -- Other miscellaneous types related to type qsim_12state:

  SUBTYPE qsim_value IS qsim_state RANGE 'X' TO '1';

  TYPE qsim_value_vector IS ARRAY (natural RANGE <>) OF qsim_value;

  TYPE qsim_strength IS ('I',  'Z',  'R', 'S');

  TYPE qsim_strength_vector IS ARRAY (natural RANGE <>) OF qsim_strength;

  -- Other miscellaneous types:

  -- Resolution function and type for bit types
  FUNCTION bit_wired_or (input : bit_vector) RETURN bit;

  SUBTYPE bit_resolved_or IS bit_wired_or bit;
  TYPE bit_resolved_or_vector IS ARRAY (natural RANGE <>) OF bit_resolved_or;

  FUNCTION bit_wired_and (input : bit_vector) RETURN bit;

  SUBTYPE bit_resolved_and IS bit_wired_and bit;
  TYPE bit_resolved_and_vector IS ARRAY (natural RANGE <>) OF bit_resolved_and;

  -- Implementation / Host dependendt constant used in conversion and shift
  -- routines to and from Integer.

  CONSTANT        IntBitSize               : integer := 32;


  -- Conversions to and from types qsim_state, qsim_strength, and qsim_value:

  FUNCTION qsim_value_from (val : qsim_12state) RETURN qsim_value;
  --   conversion is
  --          State             Result
  --   S0S,  S0R,  S0Z,  S0I      0
  --   S1S,  S1R,  S1Z,  S1I      1
  --   SXS,  SXR,  SXZ,  SXI      X

  FUNCTION qsim_strength_from (val : qsim_12state) RETURN qsim_strength;
  --   conversion is
  --        State               Result
  --   S0Z,  S1Z,  SXZ            Z
  --   S0R,  S1R,  SXR            R
  --   S0S,  S1S,  SXS            S
  --   S0I,  S1I,  SXI            I

  FUNCTION qsim_state_from (val : qsim_12state) RETURN qsim_state;
  --   conversion is
  --      State                     Result
  --   S0S,  S0R                      0
  --   S1S,  S1R                      1
  --   SXS,  SXR,  SXI,  S0I,  S1I    X
  --   SXZ,  S0Z,  S1Z                Z


  -- Conversion for arrays is the same as for scalars, the result
  -- is the same size as the argument and the conversion is
  -- applied to each element.
  -- For those functions taking a vector argument and returning
  -- a vector, the range of the result is taken from the input
  -- vector.

  FUNCTION qsim_value_from (val : qsim_12state_vector) 
      RETURN qsim_value_vector;

  FUNCTION qsim_strength_from (val : qsim_12state_vector) 
      RETURN qsim_strength_vector;

  FUNCTION qsim_state_from (val : qsim_12state_vector) 
      RETURN qsim_state_vector;

  -- Define the 'to' qsim_state functions:

  FUNCTION to_qsim_12state (val : qsim_state;
                            str : qsim_strength := 'S') RETURN qsim_12state;

  FUNCTION to_qsim_12state (val : qsim_value_vector;
                            str : qsim_strength_vector) 
                                   RETURN qsim_12state_vector;

  FUNCTION to_qsim_12state (val : qsim_state_vector) 
                                   RETURN qsim_12state_vector;
  -- misc. conversion function from types bit to qsim_state, bit_vector
  -- to integer, state vector to integer, integer to bit,
  -- and integer to state vector.  For integer conversion, the 'left
  -- is the most significant bit (msb) and 'right the least significant 
  -- bit (lsb).  For those functions taking 
  -- a vector argument and returninga vector, the range of the result is taken from the input
  -- vector.  For those functions having a scalar argument and
  -- returning a vector, the range of the result has a 'left
  -- value of 0, a direction of TO, and a 'length value equal
  -- to the input argument 'size'.

  FUNCTION to_qsim_state (val: bit) RETURN qsim_state;
  FUNCTION to_qsim_state (val: bit_vector) RETURN qsim_state_vector;
  FUNCTION to_qsim_state (val : integer; size : integer := IntBitSize)
      RETURN qsim_state_vector;
   -- to_qsim_state produces a 2's complement representation.

  -- In these conversions, the qsim_state value 'X' and 'Z' is translated to 
  -- the bit value '0'.
  FUNCTION to_bit (val : qsim_state)        RETURN bit;
  FUNCTION to_bit (val : qsim_state_vector) RETURN bit_vector;
  FUNCTION to_bit (val : integer; size : integer := IntBitSize) RETURN bit_vector;
   -- to_bit produces a 2's complement representation.

  FUNCTION to_integer (val : bit_vector) RETURN integer;
   -- to_integer assumes a 2's complement representation.

  -- In this conversion function, the qsim_state value 'X' and 'Z' are
  -- translated to the integer value of the second parameter x.  
  -- By default the value is zero (0).

  FUNCTION to_integer (val : qsim_state_vector; 
                         x : integer := 0)     RETURN integer;
   -- to_integer assumes a 2's complement representation.


  -- Overloaded math and logic operations:

  FUNCTION "AND" (l, r: qsim_state) RETURN qsim_state;
  --
  -- AND L>>>  0  1   X  Z
  -- R>>>  0   0  0   0  0
  --       1   0  1   X  X
  --       X   0  X   X  X
  --       Z   0  X   X  X

  FUNCTION "OR" (l, r: qsim_state) RETURN qsim_state;
  --
  -- OR  L>>>  0  1   X  Z
  -- R>>>  0   0  1   X  X
  --       1   1  1   1  1
  --       X   X  1   X  X
  --       Z   X  1   X  X

  FUNCTION "NAND" (l, r: qsim_state) RETURN qsim_state;
  --
  -- NAND L>>>  0  1   X  Z
  -- R>>>   0   1  1   1  1
  --        1   1  0   X  X
  --        X   1  X   X  X
  --        Z   1  X   X  X

  FUNCTION "NOR" (l, r: qsim_state) RETURN qsim_state;
  --
  -- NOR L>>>  0  1   X  Z
  -- R>>>  0   1  0   X  X
  --       1   0  0   0  0
  --       X   X  0   X  X
  --       Z   X  0   X  X

  FUNCTION "XOR" (l, r: qsim_state) RETURN qsim_state;
  --
  -- XOR L>>>  0  1   X  Z
  -- R>>>  0   0  1   X  X
  --       1   1  0   X  X
  --       X   X  X   X  X
  --       Z   X  X   X  X

  FUNCTION "XNOR" (l, r: qsim_state) RETURN qsim_state;
  --
  -- XNOR L>>>  0  1   X  Z
  --  R>>>  0   1  0   X  X
  --        1   0  1   X  X
  --        X   X  X   X  X
  --        Z   X  X   X  X

  FUNCTION "NOT" (l : qsim_state) RETURN qsim_state;
  --
  --
  --        NOT
  --    0    1
  --    1    0
  --    X    X
  --    Z    X

  FUNCTION "=" (l, r : qsim_state) RETURN qsim_state;
  --
  -- "="     r\l 0  1  X  Z
  --         0   1  0  X  X
  --         1   0  1  X  X
  --         X   X  X  X  X
  --         Z   X  X  X  X

  FUNCTION "/=" (l, r : qsim_state) RETURN qsim_state;
  --
  -- "/="    r\l 0  1  X  Z
  --         0   0  1  X  X
  --         1   1  0  X  X
  --         X   X  X  X  X
  --         Z   X  X  X  X

  FUNCTION  "<" (l, r : qsim_state) RETURN qsim_state;
  --
  -- "<"     r\l 0  1  X  Z
  --         0   0  0  0  0
  --         1   1  0  X  X
  --         X   X  0  X  X
  --         Z   X  0  X  X

  FUNCTION  ">" ( l,  r: qsim_state)   RETURN qsim_state;
  --
  -- ">"     r\l 0  1  X  Z
  --         0   0  1  X  X
  --         1   0  0  0  0
  --         X   0  X  X  X
  --         Z   0  X  X  X

  FUNCTION  "<=" (l,  r : qsim_state)   RETURN qsim_state;
  --
  -- "<="    r\l 0  1  X  Z
  --         0   1  0  X  X
  --         1   1  1  1  1
  --         X   1  X  X  X
  --         Z   1  X  X  X

  FUNCTION  ">=" (l,  r : qsim_state)   RETURN qsim_state;
  --
  -- ">="    r\l 0  1  X  Z
  --         0   1  1  1  1
  --         1   0  1  X  X
  --         X   X  1  X  X
  --         Z   X  1  X  X

  FUNCTION  "+" ( l,  r : qsim_state)   RETURN qsim_state;
  --
  -- "+"     r\l 0  1  X  Z
  --         0   0  1  X  X
  --         1   1  0  X  X
  --         X   X  X  X  X
  --         Z   X  X  X  X

  FUNCTION  "-" ( l,  r : qsim_state)   RETURN qsim_state;
  --
  -- "-"     r\l 0  1  X  Z
  --         0   0  1  X  X
  --         1   1  0  X  X
  --         X   X  X  X  X
  --         Z   X  X  X  X

  --
  --  The  operators  of &, unary  +,  unary -,  *, /, mod,  rem
  --    **,  abs are not defined for type qsim_state;

  --  The overload functions for type qsim_state_vector assume the standard Mentor
  --  Graphics notation of the msb being the left most element.  All functions,
  --  unless otherwise stated work with arrays of unequal length.  The shorter
  --  array will be prepended with '0' to make them the same length.  This
  --  is true for the relational operators.  
  --  This prevents ("011" < "10") = TRUE.
  --  The result has the length of the longest operand and a 'left and
  --  direction equal to the 'left and direction of the left operand.  The
  --  relational operators and logical operators work as if the qsim_state
  --  operator was applied individually to each operand pair.  The relational
  --  operator rules for arrays apply for qsim_state_vectors.
  --  qsim_state_vectors are treated as unsigned integers in all arithmetic
  --  operations.
  --  If either operand contains 'X' or 'Z' an attempt is made to compute an
  --  answer as optimistically as possible.  In some cases a partial result
  --  will be produced, otherwise the result will be 'X' or an array of 'X's.

   -- bitwise operations
  FUNCTION "AND" (l, r : qsim_state_vector)   RETURN qsim_state_vector;
  FUNCTION "OR"  (l, r : qsim_state_vector)   RETURN qsim_state_vector;
  FUNCTION "NAND"(l, r : qsim_state_vector)   RETURN qsim_state_vector;
  FUNCTION "NOR" (l, r : qsim_state_vector)   RETURN qsim_state_vector;
  FUNCTION "XOR" (l, r : qsim_state_vector)   RETURN qsim_state_vector;
  FUNCTION "XNOR"(l, r : qsim_state_vector)   RETURN qsim_state_vector;
  FUNCTION "NOT" (l    : qsim_state_vector)   RETURN qsim_state_vector;


   -- For these relational operators an algorithm is employed to provide
   -- the most optimistic answer possible in the case where 'X's are present
   -- For example the result of ("011" >= "0X1") is '1'.
   -- In effect a comparison is done with the 'X' replaced with a '0' and then
   -- repeated with the 'X' replaced with a '1'.  If the results of both
   -- comparisons are the same, then that result is returned.  If the results
   -- don't match then an 'X' is returned.

  FUNCTION "<"  (l, r : qsim_state_vector)   RETURN qsim_state;
  FUNCTION ">"  (l, r : qsim_state_vector)   RETURN qsim_state;
  FUNCTION "="  (l, r : qsim_state_vector)   RETURN qsim_state;
  FUNCTION "/=" (l, r : qsim_state_vector)   RETURN qsim_state;
  FUNCTION ">=" (l, r : qsim_state_vector)   RETURN qsim_state;
  FUNCTION "<=" (l, r : qsim_state_vector)   RETURN qsim_state;

  -- Addition and subtraction of qsim_state_vectors use the table
  -- defined for qsim_state "+" and "-" operators.  The result vector is the
  -- size of the larger operand.  The range of the result array will have a 
  -- 'left and direction equal to the 'left and direction of the left operand.
  -- The result will be as optimistic as possible when 'X's are present.
  -- For example:  ("01X0" + "0100") = "10X0"
  --               ("01X0" + "0110") = "1XX0"

  FUNCTION "+" (l, r : qsim_state_vector)  RETURN qsim_state_vector;
  FUNCTION "-" (l, r : qsim_state_vector)  RETURN qsim_state_vector;

  -- For these multiplying operators, the result is the size of the larger
  -- operand with a 'left and direction of the left operand.
  -- "*", "/", "mod", "rem", and "**" will do the following:  convert
  -- the entry to a natural universal integer, perform the operation
  -- and truncate it to the size of the result array.  The size of the
  -- result is the same as for addition and subtraction; the size of the
  -- larger operand.  The size of the result for "*" is the sum of the lengths
  -- of the two operands.

  -- If any 'X's or 'Z's are present in either operand the complete result is
  -- all 'X's.

  FUNCTION  "*"   (l, r : qsim_state_vector) RETURN qsim_state_vector;
  FUNCTION  "/"   (l, r : qsim_state_vector) RETURN qsim_state_vector;
  FUNCTION  "MOD" (l, r : qsim_state_vector) RETURN qsim_state_vector;
  -- NOTE: since the operands are treated as unsigned integers REM returns the
  --       same result as MOD.
  FUNCTION  "REM" (l, r : qsim_state_vector) RETURN qsim_state_vector;
  FUNCTION  "**"  (l, r : qsim_state_vector) RETURN qsim_state_vector;

  -- The operators unary +, - and abs are not defined
  -- & has the normal meaning


  -- Define logic operators on bit vectors
  -- these differ from the standard in that they accept vectors of different
  -- lengths.

  FUNCTION  fn_AND  (l, r : bit_vector) RETURN bit_vector;
  FUNCTION  fn_OR   (l, r : bit_vector) RETURN bit_vector;
  FUNCTION  fn_NAND (l, r : bit_vector) RETURN bit_vector;
  FUNCTION  fn_NOR  (l, r : bit_vector) RETURN bit_vector;
  FUNCTION  fn_XOR  (l, r : bit_vector) RETURN bit_vector;
  FUNCTION  fn_XNOR (l, r : bit_vector) RETURN bit_vector;

  -- Define addition and subtraction for bit vectors.  'left is the
  -- most significant bit and 'right is the least significant bit.
  -- The result is the size of the larger operand.  Bit_vectors are treated
  -- as unsigned integers.

  FUNCTION  "+" (l, r : bit_vector) RETURN bit_vector;
  FUNCTION  "-" (l, r : bit_vector) RETURN bit_vector;

  -- "*", "/", "mod", "rem", and "**" are defined to be:  
  --   convert the entry to a natural universal integer, 
  --   perform the operation and truncate it to the size of the 
  --   resultant array.  The size of the result for "*" is the sum of the lengths
  --   of the two operands.


  FUNCTION  "*"   (l, r : bit_vector) RETURN bit_vector;
  FUNCTION  "/"   (l, r : bit_vector) RETURN bit_vector;
  FUNCTION  "MOD" (l, r : bit_vector) RETURN bit_vector;
  -- NOTE: since the operands are treated as unsigned integers REM returns the
  --       same result as MOD.
  FUNCTION  "REM" (l, r : bit_vector) RETURN bit_vector;
  FUNCTION  "**"  (l, r : bit_vector) RETURN bit_vector;

  -- The operators unary +, unary - and abs are not defined

  -- Functions for Boolean relational operations on qsim_state.  
  FUNCTION eq ( l, r : qsim_state) RETURN boolean;
  --
  -- "="     r\l 0  1  X  Z
  --         0   T  F  F  F
  --         1   F  T  F  F
  --         X   F  F  F  F
  --         Z   F  F  F  F

  FUNCTION ne (l, r : qsim_state) RETURN boolean;
  --
  -- "/="    r\l 0  1  X  Z
  --         0   F  T  F  F
  --         1   T  F  F  F
  --         X   F  F  F  F
  --         Z   F  F  F  F

  FUNCTION  lt (l, r : qsim_state) RETURN boolean;
  --
  -- "<"     r\l 0  1  X  Z
  --         0   F  F  F  F
  --         1   T  F  F  F
  --         X   F  F  F  F
  --         Z   F  F  F  F

  FUNCTION  gt (l, r: qsim_state) RETURN boolean;
  --
  -- ">"     r\l 0  1  X  Z
  --         0   F  T  F  F
  --         1   F  F  F  F
  --         X   F  F  F  F
  --         Z   F  F  F  F

  FUNCTION  le (l,  r : qsim_state)   RETURN boolean;
  --
  -- "<="    r\l 0  1  X  Z
  --         0   T  F  F  F
  --         1   T  T  T  T
  --         X   T  F  F  F
  --         Z   T  F  F  F

  FUNCTION  ge (l,  r : qsim_state)   RETURN boolean;
  --
  -- ">="    r\l 0  1  X  Z
  --         0   T  T  T  T
  --         1   F  T  F  F
  --         X   F  T  F  F
  --         Z   F  T  F  F

  FUNCTION same( l, r : qsim_state )   RETURN boolean;
   -- True equivalence

  FUNCTION lt  (l, r : qsim_state_vector)   RETURN boolean;
  FUNCTION gt  (l, r : qsim_state_vector)   RETURN boolean;
  FUNCTION eq  (l, r : qsim_state_vector)   RETURN boolean;
  FUNCTION ne  (l, r : qsim_state_vector)   RETURN boolean;
  FUNCTION ge  (l, r : qsim_state_vector)   RETURN boolean;
  FUNCTION le  (l, r : qsim_state_vector)   RETURN boolean;

  -- Only the relational operators for QSIM_STRENGTH are defined.
  -- All other operations on QSIM_STRENGTH are undefined.

  FUNCTION  eq (l, r : qsim_strength) RETURN boolean;
  --
  -- "="  r\l Z  R  S  I
  --      Z   T  F  F  F
  --      R   F  T  F  F
  --      S   F  F  T  F
  --      I   F  F  F  F

  FUNCTION  ne( l,  r : qsim_strength)   RETURN  boolean;
  --
  -- "/=" r\l Z  R  S  I
  --      Z   F  T  T  F
  --      R   T  F  T  F
  --      S   T  T  F  F
  --      I   F  F  F  F

  FUNCTION  lt( l,  r : qsim_strength)   RETURN  boolean;
  --
  -- "<"  r\l Z  R  S  I
  --      Z   F  F  F  F
  --      R   T  F  F  F
  --      S   T  T  F  F
  --      I   F  F  F  F

  FUNCTION  gt( l,  r : qsim_strength)   RETURN  boolean;
  --
  -- ">"  r\l  Z  R  S  I 
  --      Z    F  T  T  F
  --      R    F  F  T  F
  --      S    F  F  F  F
  --      I    F  F  F  F

  FUNCTION le (l,  r : qsim_strength)   RETURN  boolean;
  --
  -- "<=" r\l Z  R  S  I
  --      Z   T  F  F  F
  --      R   T  T  F  F
  --      S   T  T  T  T
  --      I   T  F  F  F

  FUNCTION ge (l,  r : qsim_strength)   RETURN  boolean;
  --
  -- ">=" r\l Z  R  S  I
  --      Z   T  T  T  T
  --      R   F  T  T  F
  --      S   F  F  T  F
  --      I   F  F  T  F

  FUNCTION same (l, r : qsim_strength )   RETURN boolean;
   -- True equivalence


  -- Define the basic comparison operators on bit vectors because 
  -- that which is defined in VHDL does text string comparisons.
  -- The standard defines comparisons of arrays to proceed from left to right.
  -- However, bit_vectors normally represent numbers and in this case
  -- comparisons should proceed from right to left.
  -- To illustrate the implications of this, take the bit string literals 
  -- B"011" and B"10".  The first bit string literal represents the number 3; 
  -- the second, 2.  Going by the standard, B"011" < B"10" is true,
  -- (i.e. 3 < 2 is true).  To fix this, the comparison operators are 
  -- overloaded for bit_vectors to perform a numeric comparison.

  FUNCTION  lt   (l, r : bit_vector) RETURN bit;
  FUNCTION  gt   (l, r : bit_vector) RETURN bit;
  FUNCTION  eq   (l, r : bit_vector) RETURN bit;
  FUNCTION  ne  (l, r : bit_vector) RETURN bit;
  FUNCTION  ge   (l, r : bit_vector) RETURN bit;
  FUNCTION  le   (l, r : bit_vector) RETURN bit;

  FUNCTION  lt   (l, r : bit_vector) RETURN boolean;
  FUNCTION  gt   (l, r : bit_vector) RETURN boolean;
  FUNCTION  eq   (l, r : bit_vector) RETURN boolean;
  FUNCTION  ne  (l, r : bit_vector) RETURN boolean;
  FUNCTION  ge   (l, r : bit_vector) RETURN boolean;
  FUNCTION  le   (l, r : bit_vector) RETURN boolean;

  -- Shift operators for all vector types defined above
  --  below are shift operations defined on the following
  --  types:
  --   qsim_state_vector
  --   qsim_state_resolved_x_vector
  --   qsim_state_resolved_or_vector
  --   qsim_state_resolved_and_vector
  --   qsim_12state_vector
  --   qsim_12state_resolved_vector
  --   bit_resolved_and_vector
  --   bit_resolved_or_vector
  --   integer

  FUNCTION  "sll" (l : qsim_state_vector; r : integer)
	return qsim_state_vector;
  FUNCTION  "srl" (l : qsim_state_vector; r : integer)
	return qsim_state_vector;
  FUNCTION  "sla" (l : qsim_state_vector; r : integer)
      return qsim_state_vector;
  FUNCTION  "sra" (l : qsim_state_vector; r : integer)
      return qsim_state_vector;
  FUNCTION  "rol" (l : qsim_state_vector; r : integer)
      return qsim_state_vector;
  FUNCTION  "ror" (l : qsim_state_vector; r : integer)
      return qsim_state_vector;

  FUNCTION  "sll" (l : qsim_state_resolved_x_vector; r : integer)
      return qsim_state_resolved_x_vector;
  FUNCTION  "srl" (l : qsim_state_resolved_x_vector; r : integer)
      return qsim_state_resolved_x_vector;
  FUNCTION  "sla" (l : qsim_state_resolved_x_vector; r : integer)
      return qsim_state_resolved_x_vector;
  FUNCTION  "sra" (l : qsim_state_resolved_x_vector; r : integer)
      return qsim_state_resolved_x_vector;
  FUNCTION  "rol" (l : qsim_state_resolved_x_vector; r : integer)
      return qsim_state_resolved_x_vector;
  FUNCTION  "ror" (l : qsim_state_resolved_x_vector; r : integer)
      return qsim_state_resolved_x_vector;

  FUNCTION  "sll" (l : qsim_state_resolved_and_vector; r : integer)
      return qsim_state_resolved_and_vector;
  FUNCTION  "srl" (l : qsim_state_resolved_and_vector; r : integer)
      return qsim_state_resolved_and_vector;
  FUNCTION  "sla" (l : qsim_state_resolved_and_vector; r : integer)
      return qsim_state_resolved_and_vector;
  FUNCTION  "sra" (l : qsim_state_resolved_and_vector; r : integer)
      return qsim_state_resolved_and_vector;
  FUNCTION  "rol" (l : qsim_state_resolved_and_vector; r : integer)
      return qsim_state_resolved_and_vector;
  FUNCTION  "ror" (l : qsim_state_resolved_and_vector; r : integer)
      return qsim_state_resolved_and_vector;

  FUNCTION  "sll" (l : qsim_state_resolved_or_vector; r : integer)
      return qsim_state_resolved_or_vector;
  FUNCTION  "srl" (l : qsim_state_resolved_or_vector; r : integer)
      return qsim_state_resolved_or_vector;
  FUNCTION  "sla" (l : qsim_state_resolved_or_vector; r : integer)
      return qsim_state_resolved_or_vector;
  FUNCTION  "sra" (l : qsim_state_resolved_or_vector; r : integer)
      return qsim_state_resolved_or_vector;
  FUNCTION  "rol" (l : qsim_state_resolved_or_vector; r : integer)
      return qsim_state_resolved_or_vector;
  FUNCTION  "ror" (l : qsim_state_resolved_or_vector; r : integer)
      return qsim_state_resolved_or_vector;

  FUNCTION  "sll" (l : qsim_12state_vector; r : integer)
      return qsim_12state_vector;
  FUNCTION  "srl" (l : qsim_12state_vector; r : integer)
      return qsim_12state_vector;
  FUNCTION  "sla" (l : qsim_12state_vector; r : integer)
      return qsim_12state_vector;
  FUNCTION  "sra" (l : qsim_12state_vector; r : integer)
      return qsim_12state_vector;
  FUNCTION  "rol" (l : qsim_12state_vector; r : integer)
      return qsim_12state_vector;
  FUNCTION  "ror" (l : qsim_12state_vector; r : integer)
      return qsim_12state_vector;

  FUNCTION  "sll" (l : qsim_12state_resolved_vector; r : integer)
      return qsim_12state_resolved_vector;
  FUNCTION  "srl" (l : qsim_12state_resolved_vector; r : integer)
      return qsim_12state_resolved_vector;
  FUNCTION  "sla" (l : qsim_12state_resolved_vector; r : integer)
      return qsim_12state_resolved_vector;
  FUNCTION  "sra" (l : qsim_12state_resolved_vector; r : integer)
      return qsim_12state_resolved_vector;
  FUNCTION  "rol" (l : qsim_12state_resolved_vector; r : integer)
      return qsim_12state_resolved_vector;
  FUNCTION  "ror" (l : qsim_12state_resolved_vector; r : integer)
      return qsim_12state_resolved_vector;

  FUNCTION  "sll" (l : bit_resolved_and_vector; r : integer)
      return bit_resolved_and_vector;
  FUNCTION  "srl" (l : bit_resolved_and_vector; r : integer)
      return bit_resolved_and_vector;
  FUNCTION  "sla" (l : bit_resolved_and_vector; r : integer)
      return bit_resolved_and_vector;
  FUNCTION  "sra" (l : bit_resolved_and_vector; r : integer)
      return bit_resolved_and_vector;
  FUNCTION  "rol" (l : bit_resolved_and_vector; r : integer)
      return bit_resolved_and_vector;
  FUNCTION  "ror" (l : bit_resolved_and_vector; r : integer)
      return bit_resolved_and_vector;

  FUNCTION  "sll" (l : bit_resolved_or_vector; r : integer)
      return bit_resolved_or_vector;
  FUNCTION  "srl" (l : bit_resolved_or_vector; r : integer)
      return bit_resolved_or_vector;
  FUNCTION  "sla" (l : bit_resolved_or_vector; r : integer)
      return bit_resolved_or_vector;
  FUNCTION  "sra" (l : bit_resolved_or_vector; r : integer)
      return bit_resolved_or_vector;
  FUNCTION  "rol" (l : bit_resolved_or_vector; r : integer)
      return bit_resolved_or_vector;
  FUNCTION  "ror" (l : bit_resolved_or_vector; r : integer)
      return bit_resolved_or_vector;

  FUNCTION  "sll" (l : integer; r : integer)
      return integer;
  FUNCTION  "srl" (l : integer; r : integer)
      return integer;
  FUNCTION  "sla" (l : integer; r : integer)
      return integer;
  FUNCTION  "sra" (l : integer; r : integer)
      return integer;
  FUNCTION  "rol" (l : integer; r : integer)
      return integer;
  FUNCTION  "ror" (l : integer; r : integer)
      return integer;


END QSIM_logic;


                         --- QSIM Logic Package Body ---
--  Copyright (c) Mentor Graphics Corporation, 1982-1991, All Rights Reserved.
--                       UNPUBLISHED, LICENSED SOFTWARE.
--            CONFIDENTIAL AND PROPRIETARY INFORMATION WHICH IS THE
--          PROPERTY OF MENTOR GRAPHICS CORPORATION OR ITS LICENSORS.
--  License:  The QSim Logic Package Body (QLPB), but not any accompanying or
--  jointly used software, may be used, reproduced or distributed so long as
--  (1)  the copyright and proprietary rights notice and this License are not
--  removed from the QLPB or modified; (2)  the QLPB is not modified or used in
--  preparing any derivative or other works; and (3)  the QLPB is not
--  distributed in return for any monetary or other payment."

-- Declarations of Altera synthesis attributes
library altera;
use altera.altera_internal_syn.all;
  
PACKAGE BODY qsim_logic IS

TYPE qsim_state_boolean_table IS 
      ARRAY (qsim_state RANGE 'X' TO 'Z', qsim_state RANGE 'X' to 'Z') OF boolean;

TYPE qsim_state_table IS 
      ARRAY (qsim_state RANGE 'X' TO 'Z', qsim_state RANGE 'X' to 'Z') OF qsim_state;

TYPE qsim_strength_boolean_table IS 
      ARRAY (qsim_strength RANGE 'I' TO 'S', qsim_strength RANGE 'I' TO 'S') 
      OF boolean;

TYPE qsim_strength_table IS 
      ARRAY (qsim_strength RANGE 'I' TO 'S', qsim_strength RANGE 'I' TO 'S') 
      OF qsim_strength;

TYPE qsim_12state_boolean_table IS 
      ARRAY (qsim_12state RANGE sxr TO s1i, qsim_12state RANGE sxr TO s1i) 
      OF boolean;

TYPE qsim_12state_table IS 
      ARRAY (qsim_12state RANGE sxr TO s1i, qsim_12state RANGE sxr TO s1i) 
      OF qsim_12state;

FUNCTION qsim_wired_x (input : qsim_state_vector) RETURN qsim_state IS
   VARIABLE prev : qsim_state := 'Z';
   CONSTANT resolve_state : qsim_state_table :=
         --    X   0   1   Z
            (('X','X','X','X'),  -- X
             ('X','0','X','0'),  -- 0
             ('X','X','1','1'),  -- 1
             ('X','0','1','Z')); -- Z
   -- Synthesis directive attribute for this resolution function return value
   ATTRIBUTE synthesis_return OF prev:VARIABLE IS "WIRED_THREE_STATE" ;
BEGIN 
   FOR i IN input'RANGE LOOP
      prev := resolve_state(prev,input(i));
   END LOOP;
   RETURN prev;
END qsim_wired_x;

FUNCTION qsim_wired_or (input : qsim_state_vector) RETURN qsim_state IS
   VARIABLE prev : qsim_state := 'Z';
   CONSTANT resolve_state : qsim_state_table :=
         --    X   0   1   Z
            (('X','X','1','X'),  -- X
             ('X','0','1','0'),  -- 0
             ('1','1','1','1'),  -- 1
             ('X','0','1','Z')); -- Z
   -- Synthesis directive attribute for this resolution function return value
   -- Wired-OR not yet supported for synthesis. Replace by reduce-or
   ATTRIBUTE synthesis_return OF prev:VARIABLE IS "REDUCE_OR" ;
BEGIN 
   FOR i IN input'RANGE LOOP
      prev := resolve_state(prev,input(i));
   END LOOP;
   RETURN prev;
END qsim_wired_or;

FUNCTION qsim_wired_and (input : qsim_state_vector) RETURN qsim_state IS
   VARIABLE prev : qsim_state := 'Z';
   CONSTANT resolve_state : qsim_state_table :=
         --    X   0   1   Z
            (('X','0','X','X'),  -- X
             ('0','0','0','0'),  -- 0
             ('X','0','1','1'),  -- 1
             ('X','0','1','Z')); -- Z
   -- Synthesis directive attribute for this resolution function return value
   -- Wired-OR not yet supported for synthesis. Replace by reduce-or
   ATTRIBUTE synthesis_return OF prev:VARIABLE IS "REDUCE_OR" ;
BEGIN 
   FOR i IN input'RANGE LOOP
      prev := resolve_state(prev,input(i));
   END LOOP;
   RETURN prev;
END qsim_wired_and;

FUNCTION qsim_12state_wired (input : qsim_12state_vector) RETURN qsim_12state IS
   VARIABLE prev : qsim_12state;
   CONSTANT resolve_12state : qsim_12state_table :=
       --   SXR  SXZ  SXS  SXI  S0R  S0Z  S0S  S0I  S1R  S1Z  S1S  S1I
          ((SXR, SXR, SXS, SXI, SXR, SXR, S0S, SXI, SXR, SXR, S1S, SXI), -- SXR
           (SXR, SXZ, SXS, SXI, S0R, SXZ, S0S, SXI, S1R, SXZ, S1S, SXI), -- SXZ
           (SXS, SXS, SXS, SXS, SXS, SXS, SXS, SXS, SXS, SXS, SXS, SXS), -- SXS
           (SXI, SXI, SXS, SXI, SXI, SXI, SXS, SXI, SXI, SXI, SXS, SXI), -- SXI
           (SXR, S0R, SXS, SXI, S0R, S0R, S0S, S0I, SXR, S0R, S1S, SXI), -- S0R
           (SXR, SXZ, SXS, SXI, S0R, S0Z, S0S, S0I, S1R, SXZ, S1S, SXI), -- S0Z
           (S0S, S0S, SXS, SXS, S0S, S0S, S0S, S0S, S0S, S0S, SXS, SXS), -- S0S
           (SXI, SXI, SXS, SXI, S0I, S0I, S0S, S0I, SXI, SXI, SXS, SXI), -- S0I
           (SXR, S1R, SXS, SXI, SXR, S1R, S0S, SXI, S1R, S1R, S1S, S1I), -- S1R
           (SXR, SXZ, SXS, SXI, S0R, SXZ, S0S, SXI, S1R, S1Z, S1S, S1I), -- S1Z
           (S1S, S1S, SXS, SXS, S1S, S1S, SXS, SXS, S1S, S1S, S1S, S1S), -- S1S
           (SXI, SXI, SXS, SXI, SXI, SXI, SXS, SXI, S1I, S1I, S1S, S1I));-- S1I
BEGIN
   IF input'LENGTH <= 0 THEN 
     RETURN SXZ; 
   END IF;
   prev := input(input'LEFT);
   FOR i IN input'RANGE LOOP
      prev := resolve_12state(prev,input(i));
   END LOOP;
   RETURN prev;
END qsim_12state_wired;

FUNCTION bit_wired_or (input : BIT_VECTOR) RETURN BIT IS
   VARIABLE prev : BIT;
BEGIN 
   IF input'LENGTH <= 0 THEN 
     RETURN '1';
   END IF;
   prev := input(input'LEFT);
   FOR i IN input'RANGE LOOP
      prev := prev or input(i);
   END LOOP;
   RETURN prev;
END bit_wired_or;

FUNCTION bit_wired_and (input : BIT_VECTOR) RETURN BIT IS
   VARIABLE prev : BIT;
BEGIN 
   IF input'LENGTH <= 0 THEN 
     RETURN '0';
   END IF;
   prev := input(input'LEFT);
   FOR i IN input'RANGE LOOP
      prev := prev and input(i);
   END LOOP;
   RETURN prev;
END bit_wired_and;

FUNCTION qsim_value_from (val : qsim_12state) RETURN qsim_value IS
BEGIN
   CASE val IS
      WHEN S0S | S0R | S0I | S0Z =>   RETURN '0';
      WHEN S1S | S1R | S1I | S1Z =>   RETURN '1';
      WHEN SXS | SXR | SXI | SXZ =>   RETURN 'X';
   END CASE;
END qsim_value_from;

FUNCTION qsim_strength_from (val : qsim_12state) RETURN qsim_strength IS
BEGIN
   CASE val IS
      WHEN S0S | S1S | SXS =>   RETURN 'S';
      WHEN S0R | S1R | SXR =>   RETURN 'R';
      WHEN S0Z | S1Z | SXZ =>   RETURN 'Z';
      WHEN S0I | S1I | SXI =>   RETURN 'I';
   END CASE;
END qsim_strength_from;

FUNCTION qsim_state_from (val : qsim_12state) RETURN qsim_state IS
BEGIN
   CASE val IS
      WHEN S0S | S0R =>                     RETURN '0';
      WHEN S1S | S1R =>                     RETURN '1';
      WHEN SXS | SXR | SXI | S0I | S1I =>   RETURN 'X';
      WHEN SXZ | S0Z | S1Z =>               RETURN 'Z';
   END CASE;
END qsim_state_from;

FUNCTION qsim_value_from (val : qsim_12state_vector) RETURN qsim_value_vector IS
  VARIABLE return_vector : qsim_value_vector(val'RANGE);
BEGIN
  IF val'LENGTH = 0 THEN
     RETURN return_vector;
  ELSE
     FOR i IN val'RANGE LOOP
        CASE val(i) IS
           WHEN S0S | S0R | S0I | S0Z =>   return_vector(i) := '0';
           WHEN S1S | S1R | S1I | S1Z =>   return_vector(i) := '1';
           WHEN SXS | SXR | SXI | SXZ =>   return_vector(i) := 'X';
        END CASE;
     END LOOP; 
     RETURN return_vector;
  END IF;
END qsim_value_from;

FUNCTION qsim_strength_from (val : qsim_12state_vector) 
           RETURN qsim_strength_vector IS  
  VARIABLE return_vector : qsim_strength_vector(val'RANGE);
BEGIN
   IF val'LENGTH = 0 THEN
      RETURN return_vector;
   ELSE
      FOR i IN val'RANGE LOOP
         CASE val(i) IS
            WHEN S0S | S1S | SXS =>   return_vector(i) := 'S';
            WHEN S0R | S1R | SXR =>   return_vector(i) := 'R';
            WHEN S0Z | S1Z | SXZ =>   return_vector(i) := 'Z';
            WHEN S0I | S1I | SXI =>   return_vector(i) := 'I';
         END CASE;
      END LOOP;               
      RETURN return_vector;
   END IF;
END qsim_strength_from;

FUNCTION qsim_state_from (val : qsim_12state_vector) RETURN qsim_state_vector IS  
  VARIABLE return_vector : qsim_state_vector(val'RANGE);
BEGIN
   IF val'LENGTH = 0 THEN
      RETURN return_vector;
   ELSE
      FOR i IN val'RANGE LOOP
         CASE val(i) IS
            WHEN S0S | S0R =>                     return_vector(i) := '0';
            WHEN S1S | S1R =>                     return_vector(i) := '1';
            WHEN SXS | SXR | SXI | S0I | S1I =>   return_vector(i) := 'X';
            WHEN SXZ | S0Z | S1Z =>               return_vector(i) := 'Z';
         END CASE;
      END LOOP;               
      RETURN return_vector;
   END IF;
END qsim_state_from;

FUNCTION to_qsim_12state (val : qsim_state;
                          str : qsim_strength := 'S') RETURN qsim_12state IS
BEGIN
   CASE val IS
      WHEN '0' =>
         CASE str IS
            WHEN 'S' =>   RETURN S0S;
            WHEN 'R' =>   RETURN S0R;
            WHEN 'Z' =>   RETURN S0Z;
            WHEN 'I' =>   RETURN S0I;
         END CASE;
      WHEN '1' =>
         CASE str IS
            WHEN 'S' =>   RETURN S1S;
            WHEN 'R' =>   RETURN S1R;
            WHEN 'Z' =>   RETURN S1Z;
            WHEN 'I' =>   RETURN S1I;
         END CASE;
      WHEN 'X' =>
         CASE str IS
            WHEN 'S' =>   RETURN SXS;
            WHEN 'R' =>   RETURN SXR;
            WHEN 'Z' =>   RETURN SXZ;
            WHEN 'I' =>   RETURN SXI;
         END CASE;
      WHEN 'Z' => RETURN SXZ;
   END CASE;
END to_qsim_12state;

FUNCTION to_qsim_12state (val : qsim_value_vector;
                          str : qsim_strength_vector) 
            RETURN qsim_12state_vector IS  
   VARIABLE return_vector : qsim_12state_vector(val'RANGE); 
   VARIABLE str_tmp : qsim_strength_vector(val'RANGE);
   VARIABLE cnt, dir : integer := 0;
BEGIN
   IF val'LENGTH < 1 THEN
      RETURN return_vector;
   ELSE 
      IF str'LEFT = str'LOW THEN
         dir := 1;
      ELSE 
         dir := -1;
      END IF;
      cnt := str'LEFT;
      FOR i IN val'RANGE LOOP
         IF (cnt <= str'HIGH) AND (cnt >= str'LOW) THEN
            str_tmp(i) := str(cnt);
         ELSE
            str_tmp(i) := 'I';
         END IF;
         cnt := cnt + dir;
      END LOOP;       
      ASSERT val'LENGTH >= str'LENGTH 
         REPORT "Strength vector smaller than value vector, using 'I' strength."
         SEVERITY NOTE;      
      FOR i IN val'RANGE LOOP
         CASE val(i) IS
            WHEN '0' =>
               CASE str_tmp(i) IS
                  WHEN 'S' =>   return_vector(i) := S0S;
                  WHEN 'R' =>   return_vector(i) := S0R;
                  WHEN 'Z' =>   return_vector(i) := S0Z;
                  WHEN 'I' =>   return_vector(i) := S0I;
               END CASE;
            WHEN '1' =>
               CASE str_tmp(i) IS
                  WHEN 'S' =>   return_vector(i) := S1S;
                  WHEN 'R' =>   return_vector(i) := S1R;
                  WHEN 'Z' =>   return_vector(i) := S1Z;
                  WHEN 'I' =>   return_vector(i) := S1I;
               END CASE;
            WHEN 'X' =>
               CASE str_tmp(i) IS
                  WHEN 'S' =>   return_vector(i) := SXS;
                  WHEN 'R' =>   return_vector(i) := SXR;
                  WHEN 'Z' =>   return_vector(i) := SXZ;
                  WHEN 'I' =>   return_vector(i) := SXI;
               END CASE;
         END CASE;
      END LOOP;               
      RETURN return_vector;
   END IF;
END to_qsim_12state;

FUNCTION to_qsim_12state (val : qsim_state_vector) RETURN qsim_12state_vector IS  
   VARIABLE return_vector : qsim_12state_vector(val'RANGE);
BEGIN 
   FOR i IN val'RANGE LOOP
      CASE val(i) IS
         WHEN '0' =>   return_vector(i) := S0S;
         WHEN '1' =>   return_vector(i) := S1S;
         WHEN 'X' =>   return_vector(i) := SXS;
         WHEN 'Z' =>   return_vector(i) := SXZ;
      END CASE;             
   END LOOP;
   RETURN return_vector;
END to_qsim_12state;
 
FUNCTION to_qsim_state (val : bit) RETURN qsim_state IS
   -- Logic Type conversion
   VARIABLE result : qsim_state ;
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "FEED_THROUGH" ;
BEGIN
   CASE val IS
      WHEN '0' =>   result := '0';
      WHEN '1' =>   result := '1';
   END CASE;
   RETURN result ;
END to_qsim_state;

FUNCTION to_qsim_state (val : bit_vector) RETURN qsim_state_vector IS
   VARIABLE return_vector : qsim_state_vector(val'RANGE);
   -- Logic Vector Type conversion
   ATTRIBUTE synthesis_return OF return_vector:VARIABLE IS "FEED_THROUGH" ;
BEGIN
   FOR i IN val'RANGE LOOP
      CASE val(i) IS
         WHEN '0' =>   return_vector(i) := '0';
         WHEN '1' =>   return_vector(i) := '1';
      END CASE;
   END LOOP;
   RETURN return_vector;
END to_qsim_state;

FUNCTION to_qsim_state (val : integer; size : integer := IntBitSize) RETURN qsim_state_vector IS
   VARIABLE vector  : qsim_state_vector(0 TO size-1);
   VARIABLE tmp_int : integer;
   VARIABLE carry   : qsim_state := '1';   -- setup to add 1 if needed
   VARIABLE carry2  : qsim_state;
   -- Integer to (signed) vector type conversion
   ATTRIBUTE synthesis_return OF vector:VARIABLE IS "FEED_THROUGH" ;
BEGIN    
   tmp_int := val;
   FOR i IN size-1 DOWNTO 0 LOOP
       IF tmp_int MOD 2 = 1 THEN
          vector(i) := '1';
       ELSE
          vector(i) := '0';
       END IF;
       tmp_int := tmp_int / 2;
   END LOOP; 

   IF val < 0 THEN
       FOR i IN size-1 DOWNTO 0 LOOP
	   carry2    := (NOT vector(i)) AND carry;
	   vector(i) := (NOT vector(i)) XOR carry;
	   carry     := carry2;
       END LOOP; 
   END IF;
   RETURN vector;
END to_qsim_state; 

FUNCTION to_bit (val : qsim_state) RETURN bit IS
   -- Logic type conversion
   VARIABLE result : bit ;
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "FEED_THROUGH" ;
BEGIN
   CASE val IS
      WHEN '1' =>    result := '1';
      WHEN OTHERS => result := '0';
   END CASE;
   RETURN result ;
END to_bit; 

FUNCTION to_bit (val : qsim_state_vector) RETURN bit_vector IS
   VARIABLE vector : bit_vector(val'RANGE);
   -- Logic Vector type conversion
   ATTRIBUTE synthesis_return OF vector:VARIABLE IS "FEED_THROUGH" ;
BEGIN
   FOR i IN val'RANGE LOOP
      CASE val(i) IS 
         WHEN '1' =>      vector(i) := '1';
         WHEN OTHERS =>   vector(i) := '0';
      END CASE;
   END LOOP;
   RETURN vector;
END to_bit;

FUNCTION to_bit (val : integer; size : integer := IntBitSize) RETURN bit_vector IS
   VARIABLE vector : bit_vector(0 TO size-1);
   VARIABLE tmp_int : integer;
   VARIABLE carry   : bit := '1';   -- setup to add 1 if needed
   VARIABLE carry2  : bit;
   -- Integer to (signed) vector conversion
   ATTRIBUTE synthesis_return OF vector:VARIABLE IS "FEED_THROUGH" ;
BEGIN    
   tmp_int := val;
   FOR i IN size-1 DOWNTO 0 LOOP
      IF tmp_int MOD 2 = 1 THEN
         vector(i) := '1';
      ELSE
         vector(i) := '0';
      END IF;
      tmp_int := tmp_int / 2;
   END LOOP; 

   IF val < 0 THEN
       FOR i IN size-1 DOWNTO 0 LOOP
	   carry2    := (NOT vector(i)) AND carry;
	   vector(i) := (NOT vector(i)) XOR carry;
	   carry     := carry2;
       END LOOP; 
   END IF;
   RETURN vector;
END to_bit; 

FUNCTION to_integer (val : bit_vector) RETURN integer IS  
   VARIABLE return_int : integer := 0;
   -- Signed vector to integer conversion
   ATTRIBUTE is_signed OF val:CONSTANT IS TRUE ;
   ATTRIBUTE synthesis_return OF return_int:VARIABLE IS "FEED_THROUGH" ;
BEGIN 
   ASSERT val'LENGTH > 0
      REPORT "NULL vector, returning 0"
      SEVERITY NOTE;
   ASSERT val'LENGTH <= IntBitSize     -- implementation dependent limit
      REPORT "vector too large, conversion may cause overflow"
      SEVERITY WARNING;
   IF val(val'LEFT) = '0' THEN  -- positive value
      FOR i IN val'RANGE LOOP
         return_int := return_int * 2;
         IF val(i) = '1' THEN
            return_int := return_int + 1;
         END IF;
      END LOOP; 
   ELSE                                 -- negative value
      FOR i IN val'RANGE LOOP
         return_int := return_int * 2;
         IF val(i) = '0' THEN
            return_int := return_int + 1;
         END IF;
      END LOOP; 
      return_int := -(return_int + 1);
   END IF;
   RETURN return_int;
END to_integer;

FUNCTION to_integer (val : qsim_state_vector; x : integer := 0) 
            RETURN integer IS  
   VARIABLE return_int,x_tmp : integer := 0;
   -- Signed vector to integer conversion
   ATTRIBUTE is_signed OF val:CONSTANT IS TRUE ;
   ATTRIBUTE synthesis_return OF return_int:VARIABLE IS "FEED_THROUGH" ;
BEGIN
   ASSERT val'LENGTH > 0
      REPORT "NULL vector, returning 0"
      SEVERITY NOTE;
   ASSERT val'LENGTH <= IntBitSize     -- implementation dependent limit
      REPORT "vector too large, conversion may cause overflow"
      SEVERITY WARNING;
   IF val(val'LEFT) = '0' OR (x = 0 AND val(val'LEFT) /= '1') THEN  -- positive value
      IF x /= 0 THEN 
         x_tmp := 1;
      END IF;
      FOR i IN val'RANGE LOOP
         return_int := return_int * 2;
         CASE val(i) IS
            WHEN '0' =>     NULL;
            WHEN '1' =>     return_int := return_int + 1;
            WHEN OTHERS =>  return_int := return_int + x_tmp;
         END CASE;
      END LOOP;
   ELSE                         -- negative value
      IF x = 0 THEN 
         x_tmp := 1;
      END IF;
      FOR i IN val'RANGE LOOP
         return_int := return_int * 2;
         CASE val(i) IS
            WHEN '1' =>     NULL;
            WHEN '0' =>     return_int := return_int + 1;
            WHEN OTHERS =>  return_int := return_int + x_tmp;
         END CASE;
      END LOOP;
      return_int := -(return_int + 1);
   END IF;
   RETURN return_int;
END to_integer;


--//////////Logic Operator Overloading////////////////////////
--
--  Function      : AND
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  left operand
--                  r - qsim_state -  right operand   
--  Return        : qsim_state
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 0  0  0  0
--       1 | 0  1  X  X
--       X | 0  X  X  X
--       Z | 0  X  X  X
--
CONSTANT and_table : qsim_state_table :=
           -- X    0    1    Z
           (('X', '0', 'X', 'X'), -- X
            ('0', '0', '0', '0'), -- 0
            ('X', '0', '1', 'X'), -- 1
            ('X', '0', 'X', 'X'));-- Z

FUNCTION "AND" (l, r: qsim_state) RETURN qsim_state IS
   -- Binary AND on logic type
   VARIABLE result : qsim_state ; 
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "AND" ;
BEGIN
  result := and_table(l,r);
  RETURN result ;
END "AND" ;

     

--  Function      : OR 
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  left operand
--                  r - qsim_state -  right operand   
--  Return        : qsim_state
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 0  1  X  X
--       1 | 1  1  1  1
--       X | X  1  X  X
--       Z | X  1  X  X
--
CONSTANT or_table : qsim_state_table :=
           -- X    0    1    Z
           (('X', 'X', '1', 'X'), -- X
            ('X', '0', '1', 'X'), -- 0
            ('1', '1', '1', '1'), -- 1
            ('X', 'X', '1', 'X'));-- Z

FUNCTION "OR" (l, r: qsim_state) RETURN qsim_state IS
   -- Binary OR on logic type
   VARIABLE result : qsim_state ; 
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "OR" ;
BEGIN
   IF (l = '0') AND (r = '0') THEN
      result := '0';
   ELSIF (l = '1') OR (r = '1') THEN
      result := '1';
   ELSE
      result := 'X';
   END IF;
   RETURN result ;
END "OR";



--  Function      : NAND
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  left operand
--                  r - qsim_state -  right operand   
--  Return        : qsim_state
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 1  1  1  1
--       1 | 1  0  X  X
--       X | 1  X  X  X
--       Z | 1  X  X  X
--
FUNCTION "NAND" (l, r: qsim_state) RETURN qsim_state IS
   -- Binary NAND on logic type
   VARIABLE result : qsim_state ; 
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "NAND" ;
BEGIN
   IF (l = '0') OR (r = '0') THEN
      result := '1';
   ELSIF (l = '1') AND (r = '1') THEN
      result := '0';
   ELSE
      result := 'X';
   END IF;
   RETURN result ;
END "NAND";



--  Function      : NOR
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  left operand
--                  r - qsim_state -  right operand   
--  Return        : qsim_state
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 1  0  X  X
--       1 | 0  0  0  0
--       X | X  0  X  X
--       Z | X  0  X  X
--
FUNCTION "NOR" (l, r: qsim_state) RETURN qsim_state IS
   -- Binary NOR on logic type
   VARIABLE result : qsim_state ; 
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "NOR" ;
BEGIN
   IF (l = '0') AND (r = '0') THEN
      result := '1';
   ELSIF (l = '1') OR (r = '1') THEN
      result := '0';
   ELSE
      result := 'X';
   END IF;
   RETURN result ;
END "NOR";




--  Function      : XOR
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  left operand
--                  r - qsim_state -  right operand   
--  Return        : qsim_state
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 0  1  X  X
--       1 | 1  0  X  X
--       X | X  X  X  X
--       Z | X  X  X  X
--
CONSTANT xor_table : qsim_state_table :=
        -- X    0    1    Z
        (('X', 'X', 'X', 'X'), -- X
         ('X', '0', '1', 'X'), -- 0
         ('X', '1', '0', 'X'), -- 1
         ('X', 'X', 'X', 'X'));-- Z

FUNCTION "XOR" (l, r: qsim_state) RETURN qsim_state IS
   -- Binary XOR on logic type
   VARIABLE result : qsim_state ; 
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "XOR" ;
BEGIN
   result := xor_table(l,r);
   RETURN result ;
END "XOR";

FUNCTION "XNOR" (l, r: qsim_state) RETURN qsim_state IS
   -- Binary XOR on logic type
   VARIABLE result : qsim_state ; 
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "XNOR" ;
BEGIN
  CASE xor_table(l,r) IS
    WHEN '0' =>    result := '1';
    WHEN '1' =>    result := '0';
    WHEN OTHERS => result := 'X';
  END CASE;                              --  xor_table(l,r)
  RETURN result;
END "XNOR";




--  Function      : NOT
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  operand
--  Return        : qsim_state
--
--  Truth Table:
--
--          NOT
--           
--       0 | 1 
--       1 | 0 
--       X | X 
--       Z | X 
--
FUNCTION "NOT" (l : qsim_state) RETURN qsim_state IS
   -- Binary NOT on logic type
   VARIABLE result : qsim_state ; 
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "NOT" ;
BEGIN
   CASE l IS
        WHEN '0' =>    result := '1';
        WHEN '1' =>    result := '0';
        WHEN OTHERS => result := 'X';
   END CASE;
   RETURN result ;
END "NOT";

--///////////Relational Operator Overloading////////////////////////
--


--  Function      : "=" (Equality)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  left operand
--                  r - qsim_state -  right operand   
--  Return        : qsim_state
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 1  0  X  X
--       1 | 0  1  X  X
--       X | X  X  X  X
--       Z | X  X  X  X
--
FUNCTION "=" (l, r: qsim_state) RETURN qsim_state IS
   -- Equal than on logic type. Return in logic type.
   VARIABLE result : qsim_state ; 
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "EQ" ;
BEGIN
   result := NOT xor_table(l,r); -- same table as exclusive or
   RETURN result ;
END "=";




--  Function      : "/=" (Inequality)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  left operand
--                  r - qsim_state -  right operand   
--  Return        : qsim_state
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 0  1  X  X
--       1 | 1  0  X  X
--       X | X  X  X  X
--       Z | X  X  X  X
--
FUNCTION "/=" (l, r: qsim_state) RETURN qsim_state IS
   -- NOT-Equal than on logic type. Return in logic type.
   VARIABLE result : qsim_state ; 
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "NEQ" ;
BEGIN
   result := xor_table(l,r);  -- same table as exclusive or
   RETURN result ;
END "/=";




--  Function      : "<" (Less Than)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  left operand
--                  r - qsim_state -  right operand   
--  Return        : qsim_state
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 0  0  0  0
--       1 | 1  0  X  X
--       X | X  0  X  X
--       Z | X  0  X  X
--
CONSTANT lt_table : qsim_state_table :=
        -- X    0    1    Z  <-r
        (('X', '0', 'X', 'X'), -- X  <-l
         ('X', '0', '1', 'X'), -- 0
         ('0', '0', '0', '0'), -- 1
         ('X', '0', 'X', 'X'));-- Z

FUNCTION "<" (l, r: qsim_state) RETURN qsim_state IS
   -- Less-than on logic type. Return in logic type.
   VARIABLE result : qsim_state ; 
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "LT" ;
BEGIN
   result := lt_table(l,r);
   RETURN result ;
END "<";




--  Function      : ">" (Greater Than)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  left operand
--                  r - qsim_state -  right operand   
--  Return        : qsim_state
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 0  1  X  X
--       1 | 0  0  0  0
--       X | 0  X  X  X
--       Z | 0  X  X  X
--
CONSTANT gt_table : qsim_state_table :=
        -- X    0    1    Z  <-r
        (('X', 'X', '0', 'X'), -- X  <-l
         ('0', '0', '0', '0'), -- 0
         ('X', '1', '0', 'X'), -- 1
         ('X', 'X', '0', 'X'));-- Z

FUNCTION ">" (l, r: qsim_state) RETURN qsim_state IS
   -- Greater than on logic type. Return in logic type.
   VARIABLE result : qsim_state ; 
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "GT" ;
BEGIN
   result := gt_table(l,r);
   RETURN result ;
END ">";




--  Function      : "<=" (Less Than Or Equals)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  left operand
--                  r - qsim_state -  right operand   
--  Return        : qsim_state
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 1  0  X  X
--       1 | 1  1  1  1
--       X | 1  X  X  X
--       Z | 1  X  X  X
--
FUNCTION "<=" (l, r: qsim_state) RETURN qsim_state IS
   -- Less-than-or-equal on logic type. Return in logic type.
   VARIABLE result : qsim_state ; 
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "LTE" ;
BEGIN
   IF (l = '0') OR (r = '1') THEN
      result := '1';
   ELSIF (l = '1') AND (r = '0') THEN
      result := '0';
   ELSE
      result := 'X';
   END IF;
   RETURN result ;
END "<=";




--  Function      : >= (Greater Than Or Equals)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  left operand
--                  r - qsim_state -  right operand   
--  Return        : qsim_state
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 1  1  1  1
--       1 | 0  1  X  X
--       X | X  1  X  X
--       Z | X  1  X  X
--
FUNCTION ">=" (l, r: qsim_state) RETURN qsim_state IS
   -- Greater-than-or-equal on logic type. Return in logic type.
   VARIABLE result : qsim_state ; 
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "GTE" ;
BEGIN
   IF (l = '1') OR (r = '0') THEN
      result := '1';
   ELSIF (l = '0') AND (r = '1') THEN
      result := '0';
   ELSE
      result := 'X';
   END IF;
   RETURN result ;
END ">=";




--  Function      : "+" (Plus)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  left operand
--                  r - qsim_state -  right operand   
--  Return        : qsim_state
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 0  1  X  X
--       1 | 1  0  X  X
--       X | X  X  X  X
--       Z | X  X  X  X
--
FUNCTION "+" (l, r: qsim_state) RETURN qsim_state IS
   -- Arithmetic addition of logic types. Resembles XOR
   VARIABLE result : qsim_state ;
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "XOR" ;
BEGIN
   result := xor_table(l,r);
   RETURN result ;
END "+";




--  Function      : "-" (Minus)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  left operand
--                  r - qsim_state -  right operand   
--  Return        : qsim_state
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 0  1  X  X
--       1 | 1  0  X  X
--       X | X  X  X  X
--       Z | X  X  X  X
--
FUNCTION "-" (l, r: qsim_state) RETURN qsim_state IS
   -- Arithmetic subtraction of logic types. Resembles XOR
   VARIABLE result : qsim_state ;
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "XOR" ;
BEGIN
   result := xor_table(l,r);
   RETURN result ;
END "-";




--///////////////////Vector Functions////////////////////

-- Some useful generic functions

--//// Zero Extend ////
--
-- Function zxt
--
FUNCTION zxt( q : qsim_state_vector; i : integer ) return qsim_state_vector IS
    VARIABLE qs : qsim_state_vector (1 to i);
    VARIABLE qt : qsim_state_vector (1 to q'length);
   -- Zero-extend an unsigned vector
   ATTRIBUTE synthesis_return OF qs:VARIABLE IS "FEED_THROUGH" ;
BEGIN
    qt := q;
    if i < q'length then
        qs := qt( (q'length-i+1) to qt'right);
    elsif i > q'length then
        qs := (others=>'0');
        qs := qs(1 to (i-q'length)) & qt;
    else
        qs := qt;
    end if;
    return qs;
END;

--//// Zero Extend ////
--
-- Function zxt
--
FUNCTION zxt( q : bit_vector; i : integer ) return bit_vector IS
    VARIABLE qs : bit_vector (1 to i);
    VARIABLE qt : bit_vector (1 to q'length);
   -- Zero-extend an unsigned vector
   ATTRIBUTE synthesis_return OF qs:VARIABLE IS "FEED_THROUGH" ;
BEGIN
    qt := q;
    if i < q'length then
        qs := qt( (q'length-i+1) to qt'right);
    elsif i > q'length then
        qs := (others=>'0');
        qs := qs(1 to (i-q'length)) & qt;
    else
        qs := qt;
    end if;
    return qs;
END;

FUNCTION max (l, r :integer) RETURN integer IS
 -- Synthesize from native source
BEGIN   
   IF l > r THEN 
      RETURN l;
   ELSE
      RETURN r;
   END IF;
END max;



--///////////Logical Operators - return qsim_state_vector//////////////////////

--  NOTE:
--  If unequal operands are used, the shorter is prepended with zeros.
--  The result has the length of the longest operand and a 'LEFT and direction
--  equal to the 'LEFT and direction of the left operand.


--  Function      : AND
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  left operand
--                  r - qsim_state_vector -  right operand   
--  Return        : qsim_state_vector ( l'LEFT l'DIRECTION max_length(l,r) )
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 0  0  0  0
--       1 | 0  1  X  X
--       X | 0  X  X  X
--       Z | 0  X  X  X
--    
--
--

FUNCTION "AND" (l, r :qsim_state_vector) RETURN qsim_state_vector IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : qsim_state_vector(1 TO ml);
  VARIABLE rt   : qsim_state_vector(1 TO ml);
  VARIABLE res  : qsim_state_vector(1 TO ml);

   -- Vector wide AND with zero-extend.
   ATTRIBUTE synthesis_return OF res:VARIABLE IS "AND" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN res'RANGE LOOP
    res(i) := lt(i) AND rt(i);
  END LOOP;

  RETURN res;

END "AND";                


--  Function      : OR
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  left operand
--                  r - qsim_state_vector -  right operand   
--  Return        : qsim_state_vector
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 0  1  X  X
--       1 | 1  1  1  1
--       X | X  1  X  X
--       Z | X  1  X  X
--    
FUNCTION "OR" (l, r : qsim_state_vector) RETURN qsim_state_vector IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : qsim_state_vector(1 TO ml);
  VARIABLE rt   : qsim_state_vector(1 TO ml);
  VARIABLE res  : qsim_state_vector(1 TO ml);

   -- Vector wide OR with zero-extend.
   ATTRIBUTE synthesis_return OF res:VARIABLE IS "OR" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN res'RANGE LOOP
    res(i) := lt(i) OR rt(i);
  END LOOP;

  RETURN res;

END "OR";


--  Function      : NAND
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  left operand
--                  r - qsim_state_vector -  right operand   
--  Return        : qsim_state_vector
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 1  1  1  1
--       1 | 1  0  X  X
--       X | 1  X  X  X
--       Z | 1  X  X  X
--    
FUNCTION "NAND" (l, r : qsim_state_vector) RETURN qsim_state_vector IS
           
  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : qsim_state_vector(1 TO ml);
  VARIABLE rt   : qsim_state_vector(1 TO ml);
  VARIABLE res  : qsim_state_vector(1 TO ml);

   -- Vector wide NAND with zero-extend.
   ATTRIBUTE synthesis_return OF res:VARIABLE IS "NAND" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN res'RANGE LOOP
    res(i) := lt(i) NAND rt(i);
  END LOOP;

  RETURN res;

END "NAND";


--  Function      : NOR
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  left operand
--                  r - qsim_state_vector -  right operand   
--  Return        : qsim_state_vector
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 1  0  X  X
--       1 | 0  0  0  0
--       X | X  0  X  X
--       Z | X  0  X  X
--    
FUNCTION "NOR" (l, r : qsim_state_vector) RETURN qsim_state_vector IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : qsim_state_vector(1 TO ml);
  VARIABLE rt   : qsim_state_vector(1 TO ml);
  VARIABLE res  : qsim_state_vector(1 TO ml);

   -- Vector wide NOR with zero-extend
   ATTRIBUTE synthesis_return OF res:VARIABLE IS "NOR" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN res'RANGE LOOP
    res(i) := lt(i) NOR rt(i);
  END LOOP;

  RETURN res;

END "NOR";


--  Function      : XOR
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  left operand
--                  r - qsim_state_vector -  right operand   
--  Return        : qsim_state_vector
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 0  1  X  X
--       1 | 1  0  X  X
--       X | X  X  X  X
--       Z | X  X  X  X
--    
FUNCTION "XOR" (l, r : qsim_state_vector) RETURN qsim_state_vector IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : qsim_state_vector(1 TO ml);
  VARIABLE rt   : qsim_state_vector(1 TO ml);
  VARIABLE res  : qsim_state_vector(1 TO ml);

   -- Vector wide XOR with zero-extend
   ATTRIBUTE synthesis_return OF res:VARIABLE IS "XOR" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN res'RANGE LOOP
    res(i) := lt(i) XOR rt(i);
  END LOOP;

  RETURN res;

END "XOR";                

FUNCTION "XNOR" (l, r : qsim_state_vector) RETURN qsim_state_vector IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : qsim_state_vector(1 TO ml);
  VARIABLE rt   : qsim_state_vector(1 TO ml);
  VARIABLE res  : qsim_state_vector(1 TO ml);

BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN res'RANGE LOOP
    res(i) := lt(i) XNOR rt(i);
  END LOOP;

  RETURN res;

END "XNOR";                


--  Function      : NOT
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  operand
--  Return        : qsim_state_vector
--
--  Truth Table:
--
--          NOT
--           
--       0 | 1 
--       1 | 0 
--       X | X 
--       Z | X 
--
FUNCTION "NOT" (l : qsim_state_vector) RETURN qsim_state_vector IS
                   
   VARIABLE   return_vector  : qsim_state_vector(l'RANGE);

   -- Vector wide NOT
   ATTRIBUTE synthesis_return OF return_vector:VARIABLE IS "NOT" ;
BEGIN       
   FOR i IN return_vector'RANGE LOOP
         return_vector(i) := NOT(l(i));
   END LOOP;           
   RETURN return_vector;
END "NOT";               


--///////////Relational Operators - return qsim_state////////////////////////

--
--  Function      : < (Less Than)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector - left operand
--                  r - qsim_state_vector - right operand   
--  Return        : qsim_state
--
--  This operator is more complicated then expected because it
--  attempts to be as optimistic as possible without being overly
--  optimistic.  When comparing an 'X' with a known value, the
--  reminder of the vector is checked to see if the result can
--  be truely determined or not.
--  Truth Table:
--
--
FUNCTION "<" (l, r :qsim_state_vector) RETURN qsim_state IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : qsim_state_vector(1 TO ml);
  VARIABLE rt   : qsim_state_vector(1 TO ml);
  VARIABLE result  : qsim_state;
  VARIABLE tmp  : qsim_state;

   -- Less-than on logic type. Return in logic type.
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "LT" ;
BEGIN

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  CASE lt(1) IS
     WHEN '0' => 
        CASE rt(1) IS
           WHEN '0' =>
              IF ml = 1 THEN
                 result := lt(1) < rt(1);
                 RETURN result;
              ELSE  -- return recursive call result
                 result := lt(2 to ml) < rt(2 to ml);
                 RETURN result;
              END IF;
           WHEN '1' =>
              result := lt(1) < rt(1);
              RETURN result;
           WHEN 'X'|'Z' =>
              IF ml = 1 THEN
                 result := lt(1) < rt(1);
                 RETURN result;
              ELSE  -- return recursive call result
                 tmp := lt(2 to ml) < rt(2 to ml);
                 IF tmp = '1' THEN
                    result := '1';
                    RETURN result;
                 ELSE
                    result := 'X';
                    RETURN result;
                 END IF;
              END IF;
        END CASE;
     WHEN '1' =>
        CASE rt(1) IS
           WHEN '0' =>
              result := lt(1) < rt(1);
              RETURN result;
           WHEN '1' =>
              IF ml = 1 THEN
                 result := lt(1) < rt(1);
                 RETURN result;
              ELSE  -- return recursive call result
                 result := lt(2 to ml) < rt(2 to ml);
                 RETURN result;
              END IF;
           WHEN 'X'|'Z' =>
              IF ml = 1 THEN
                 result := lt(1) < rt(1);
                 RETURN result;
              ELSE   -- return recursive call result
                 tmp := lt(2 to ml) < rt(2 to ml);
                 IF tmp = '0' THEN
                    result := '0';
                    RETURN result;
                 ELSE
                    result := 'X';
                    RETURN result;
                 END IF;
              END IF;
        END CASE;
     WHEN 'X'|'Z' =>
        CASE rt(1) IS
           WHEN '0' =>
              IF ml = 1 THEN 
                 result := lt(1) < rt(1);
                 RETURN result;
              ELSE   -- return recursive call result
                 tmp := lt(2 to ml) < rt(2 to ml);
                 IF tmp = '0' THEN
                    result := '0';
                    RETURN result;
                 ELSE
                    result := 'X';
                    RETURN result;
                 END IF;
              END IF;
           WHEN '1' =>
              IF ml = 1 THEN
                 result := lt(1) < rt(1);
                 RETURN result;
              ELSE   -- return recursive call result
                 tmp := lt(2 to ml) < lt(2 to ml);
                 IF tmp = '1' THEN
                    result := '1';
                    RETURN result;
                 ELSE
                    result := 'X';
                    RETURN result;
                 END IF;
              END IF;
           WHEN 'X'|'Z' =>
              result := lt(1) < rt(1);
              RETURN result;
        END CASE;
  END CASE;

END "<";



--  Function      : ">" (Greater Than)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  left operand
--                  r - qsim_state_vector -  right operand   
--  Return        : qsim_state
--
--  
--  This operator is more complicated then expected because it
--  attempts to be as optimistic as possible without being overly
--  optimistic.  When comparing an 'X' with a known value, the
--  reminder of the vector is checked to see if the result can
--  be truely determined or not.
--  
--  
--
FUNCTION ">" (l, r :qsim_state_vector) RETURN qsim_state IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : qsim_state_vector(1 TO ml);
  VARIABLE rt   : qsim_state_vector(1 TO ml);
  VARIABLE result  : qsim_state;
  VARIABLE tmp  : qsim_state;

   -- Greater than on logic type. Return in logic type.
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "GT" ;
BEGIN

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  CASE lt(1) IS
     WHEN '0' =>
        CASE rt(1) IS
           WHEN '0' =>
              IF ml = 1 THEN
                 result := lt(1) > rt(1); -- 0
                 RETURN result;
              ELSE  -- return recursive call result
                 result := lt(2 TO ml) > rt(2 TO ml);
                 RETURN result;
              END IF;
           WHEN '1' =>
              result := lt(1) > rt(1); -- 0
              RETURN result;
           WHEN 'X'|'Z' =>
              IF ml = 1 THEN
                 result := lt(1) > rt(1); -- 0
                 RETURN result;
              ELSE   -- return recursive call result
                 tmp := lt(2 TO ml) > rt(2 TO ml);
                 IF tmp = '0' THEN
                    result := '0';
                    RETURN result;
                 ELSE
                    result := 'X';
                    RETURN result;
                 END IF;
              END IF;
        END CASE;
     WHEN '1' =>
        CASE rt(1) IS
           WHEN '0' =>
              result := lt(1) > rt(1); -- 1
              RETURN result;
           WHEN '1' =>
              IF ml = 1 THEN
                 result := lt(1) > rt(1); -- 0
                 RETURN result;
              ELSE  -- return recursive call result
                 result := lt(2 TO ml) > rt(2 TO ml);
                 RETURN result;
              END IF;
           WHEN 'X'|'Z' =>
              IF ml = 1 THEN
                 result := lt(1) > rt(1); -- X
                 RETURN result;
              ELSE   -- return recursive call result
                 tmp := lt(2 TO ml) > rt(2 TO ml);
                 IF tmp = '1' THEN
                    result := '1';
                    RETURN result;
                 ELSE
                    result := 'X';
                    RETURN result;
                 END IF;
              END IF;
        END CASE;
     WHEN 'X'|'Z' =>
        CASE rt(1) IS
           WHEN '0' =>
              IF ml = 1 THEN
                 result := lt(1) > rt(1); -- X
                 RETURN result;
              ELSE   -- return recursive call result
                 tmp := lt(2 TO ml) > rt(2 TO ml);
                 IF tmp = '1' THEN
                    result := '1';
                    RETURN result;
                 ELSE
                    result := 'X';
                    RETURN result;
                 END IF;
              END IF;
           WHEN '1' =>
              IF ml = 1 THEN
                 result := lt(1) > rt(1); -- X
                 RETURN result;
              ELSE   -- return recursive call result
                 tmp := lt(2 TO ml) > rt(2 TO ml);
                 IF tmp = '0' THEN
                    result := '0';
                    RETURN result;
                 ELSE
                    result := 'X';
                    RETURN result;
                 END IF;
              END IF;
           WHEN 'X'|'Z' =>
              result := lt(1) > rt(1); -- X
              RETURN result;
        END CASE;
  END CASE;

END ">";   


--  Function      : "=" (Equality)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  left operand
--                  r - qsim_state_vector -  right operand   
--  Return        : qsim_state
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 1  0  X  X
--       1 | 0  1  X  X
--       X | X  X  X  X
--       Z | X  X  X  X
--
FUNCTION "=" (l, r: qsim_state_vector) RETURN qsim_state IS
                                     
  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : qsim_state_vector(1 TO ml);
  VARIABLE rt   : qsim_state_vector(1 TO ml);
 
   -- Arithmetic equal on two unsigned vectors.
   VARIABLE result : qsim_state ;
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "EQ" ;
BEGIN
 
  lt := zxt( l, ml );
  rt := zxt( r, ml );
 
  FOR i IN lt'RANGE LOOP
 
    IF (not (lt(i) = rt(i))) OR
       (lt(i) = 'X') OR (rt(i) = 'X') OR
       (lt(i) = 'Z') OR (rt(i) = 'Z')   THEN
 
      result := lt(i) = rt(i);
      RETURN result ;
    END IF;
 
  END LOOP;
 
  result := '1';
  RETURN result ;
 
END "=";   



--  Function      : "/=" (Inequality)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  left operand
--                  r - qsim_state_vector -  right operand   
--  Return        : qsim_state
--
--  Truth Table:   
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 0  1  X  X
--       1 | 1  0  X  X
--       X | X  X  X  X
--       Z | X  X  X  X
--
FUNCTION "/=" (l, r: qsim_state_vector) RETURN qsim_state IS
                                     
  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : qsim_state_vector(1 TO ml);
  VARIABLE rt   : qsim_state_vector(1 TO ml);
   -- Arithmetic not-equal on two unsigned vectors.
   VARIABLE result : qsim_state ;
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "NEQ" ;
BEGIN
 
  lt := zxt( l, ml );
  rt := zxt( r, ml );
 
  FOR i IN lt'RANGE LOOP
 
    IF (lt(i) /= rt(i)) /= qsim_state'('0') THEN
      result := lt(i) /= rt(i);
      RETURN result ;
    END IF;
 
  END LOOP;
 
  result := lt(lt'RIGHT) /= rt(rt'RIGHT);
  RETURN result ;
 
END "/=";   


--
--  Function      : <= (Less Than Or Equals)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector - left operand
--                  r - qsim_state_vector - right operand   
--  Return        : qsim_state
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 1  0  X  X
--       1 | 1  1  1  1
--       X | 1  X  X  X
--       Z | 1  X  X  X
--

--                     
--  The lookup table facilitates the fuzzy logic due to the X and Z states.
--  It determines if we should continue examining the next elements in the
--  vectors or if we should quit.  We assume row precedence.
--         
--  col =     X  0  1  Z
--          ------------
--  row = X | X  X  N  X
--        0 | N  N  T  N
--        1 | X  F  N  X
--        Z | X  X  N  X
--
TYPE qsim_fuzzy_state IS ('X','T','F','N');
TYPE qsim_fuzzy_state_table IS
       ARRAY( qsim_state RANGE 'X' TO 'Z', qsim_state RANGE 'X' TO 'Z' ) 
       OF qsim_fuzzy_state;

CONSTANT qsim_le_state_table : qsim_fuzzy_state_table :=
            --  X    0    1    Z
             (('X', 'X', 'N', 'X'),  -- X
              ('N', 'N', 'T', 'N'),  -- 0
              ('X', 'F', 'N', 'X'),  -- 1
              ('X', 'X', 'N', 'X')); -- Z

FUNCTION "<=" (l, r :qsim_state_vector) RETURN qsim_state IS
                                                  
  VARIABLE ml     : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt     : qsim_state_vector(1 TO ml);
  VARIABLE rt     : qsim_state_vector(1 TO ml);
  VARIABLE res    : qsim_fuzzy_state;
  VARIABLE result : qsim_state;

   -- Less-than-or-equal on logic type. Return in logic type.
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "LTE" ;
BEGIN

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN lt'RANGE LOOP
    res := qsim_le_state_table( lt(i), rt(i) ); 
    CASE res IS
      WHEN 'X'     =>   result := 'X'; RETURN result;
      WHEN 'T'     =>   result := '1'; RETURN result;
      WHEN 'F'     =>   result := '0'; RETURN result;
      WHEN OTHERS  =>   null;
    END CASE;
  END LOOP;           
  result := '1';
  RETURN result;
END "<=";         


--  Function      : >= (Greater Than Or Equals)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  left operand
--                  r - qsim_state_vector -  right operand   
--  Return        : qsim_state
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | 1  1  1  1
--       1 | 0  1  X  X
--       X | X  1  X  X
--       Z | X  1  X  X
--

--
--    The lookup table facilitates the fuzzy logic due to the X and Z states.
--    It determines if we should continue examining the next elements in the vectors 
--    or if we should quit.  We assume row precedence.
--   
--           
--    col =     X  0  1  Z
--            ------------
--    row = X | X  N  X  X
--          0 | X  N  F  X
--          1 | N  T  N  N
--          Z | X  N  X  X
--                           
 
CONSTANT
   qsim_ge_state_table : qsim_fuzzy_state_table :=
           (('X', 'N', 'X', 'X'),
            ('X', 'N', 'F', 'X'),
            ('N', 'T', 'N', 'N'),
            ('X', 'N', 'X', 'X'));

FUNCTION ">=" (l, r :qsim_state_vector) RETURN qsim_state IS

  VARIABLE ml     : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt     : qsim_state_vector(1 TO ml);
  VARIABLE rt     : qsim_state_vector(1 TO ml);
  VARIABLE res    : qsim_fuzzy_state;
  VARIABLE result : qsim_state ; 

   -- Greater-than-or-equal on logic type. Return in logic type.
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "GTE" ;
BEGIN

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN lt'RANGE LOOP
    res := qsim_ge_state_table( lt(i), rt(i) ); 
    CASE res IS
      WHEN 'X'     =>   result := 'X'; RETURN result;
      WHEN 'T'     =>   result := '1'; RETURN result;
      WHEN 'F'     =>   result := '0'; RETURN result;
      WHEN OTHERS  =>   null;
    END CASE;
  END LOOP;           
  result := '1';
  RETURN result;

END ">=";         


--///////////Logical Operators - return bit_vector//////////////////////////

--  NOTE:
--  If unequal operands are used, the shorter is prepended with zeros.
--  The result has the length of the longest operand and a 'LEFT and direction
--  equal to the 'LEFT and direction of the left operand.


--  Function      : AND
--  Function Type : Operator Overload
--  Inputs        : l - bit_vector -  left operand
--                  r - bit_vector -  right operand   
--  Return        : bit_vector
--
--  Truth Table:
--
--  l =      0  1
--         ------
--  r =  0 | 0  0
--       1 | 0  1
--    
--
--

FUNCTION fn_AND (l, r :bit_vector) RETURN bit_vector IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : bit_vector(1 TO ml);
  VARIABLE rt   : bit_vector(1 TO ml);
  VARIABLE res  : bit_vector(1 TO ml);

BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN res'RANGE LOOP
    res(i) := lt(i) AND rt(i);
  END LOOP;

  RETURN res;

END fn_AND;


--  Function      : OR
--  Function Type : Operator Overload
--  Inputs        : l - bit_vector -  left operand
--                  r - bit_vector -  right operand   
--  Return        : bit_vector
--
--  Truth Table:
--
--  l =      0  1
--         ------
--  r =  0 | 0  1
--       1 | 1  1
--    
FUNCTION fn_OR (l, r : bit_vector) RETURN bit_vector IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : bit_vector(1 TO ml);
  VARIABLE rt   : bit_vector(1 TO ml);
  VARIABLE res  : bit_vector(1 TO ml);

BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN res'RANGE LOOP
    res(i) := lt(i) OR rt(i);
  END LOOP;

  RETURN res;

END fn_OR;  


--  Function      : NAND
--  Function Type : Operator Overload
--  Inputs        : l - bit_vector -  left operand
--                  r - bit_vector -  right operand   
--  Return        : bit_vector
--
--  Truth Table:
--
--  l =      0  1
--         ------
--  r =  0 | 1  1
--       1 | 1  0
--    
FUNCTION fn_NAND (l, r : bit_vector) RETURN bit_vector IS
           
  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : bit_vector(1 TO ml);
  VARIABLE rt   : bit_vector(1 TO ml);
  VARIABLE res  : bit_vector(1 TO ml);

BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN res'RANGE LOOP
    res(i) := lt(i) NAND rt(i);
  END LOOP;

  RETURN res;

END fn_NAND;


--  Function      : NOR
--  Function Type : Operator Overload
--  Inputs        : l - bit_vector -  left operand
--                  r - bit_vector -  right operand   
--  Return        : bit_vector
--
--  Truth Table:
--
--  l =      0  1
--         ------
--  r =  0 | 1  0
--       1 | 0  0
--    
FUNCTION fn_NOR (l, r : bit_vector) RETURN bit_vector IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : bit_vector(1 TO ml);
  VARIABLE rt   : bit_vector(1 TO ml);
  VARIABLE res  : bit_vector(1 TO ml);

BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN res'RANGE LOOP
    res(i) := lt(i) NOR rt(i);
  END LOOP;

  RETURN res;

END fn_NOR;


--  Function      : XOR
--  Function Type : Operator Overload
--  Inputs        : l - bit_vector -  left operand
--                  r - bit_vector -  right operand   
--  Return        : bit_vector
--
--  Truth Table:
--
--  l =      0  1
--         ------
--  r =  0 | 0  1
--       1 | 1  0
--    
FUNCTION fn_XOR (l, r : bit_vector) RETURN bit_vector IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : bit_vector(1 TO ml);
  VARIABLE rt   : bit_vector(1 TO ml);
  VARIABLE res  : bit_vector(1 TO ml);

BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN res'RANGE LOOP
    res(i) := lt(i) XOR rt(i);
  END LOOP;

  RETURN res;

END fn_XOR;                

FUNCTION fn_XNOR (l, r : bit_vector) RETURN bit_vector IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : bit_vector(1 TO ml);
  VARIABLE rt   : bit_vector(1 TO ml);
  VARIABLE res  : bit_vector(1 TO ml);

BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN res'RANGE LOOP
    res(i) := NOT (lt(i) XOR rt(i));
  END LOOP;

  RETURN res;

END fn_XNOR;



--//////////////////Arithmetic Operations///////////////////////


--//////////////////////Operators////////////
       
--  Function      : "+"
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  left operand
--                  r - qsim_state_vector -  right operand   
--  Return        : qsim_state_vector
--
--
FUNCTION "+" (l, r :qsim_state_vector) RETURN qsim_state_vector IS

  VARIABLE ml     : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt     : qsim_state_vector(1 TO ml);
  VARIABLE rt     : qsim_state_vector(1 TO ml);
  VARIABLE res    : qsim_state_vector(1 TO ml);
  VARIABLE carry  : qsim_state := '0';
  VARIABLE a,b,s1 : qsim_state;

   -- Arithmetic addition of unsigned vectors
   ATTRIBUTE synthesis_return OF res:VARIABLE IS "ADD" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN res'REVERSE_RANGE LOOP
    a := lt(i);
    b := rt(i);
    s1 := a + b;
    res(i) := s1 + carry;
    carry := (a AND b) OR (s1 AND carry);
  END LOOP;           
  RETURN res;
END "+";  


--  Function      : "-"
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  left operand
--                  r - qsim_state_vector -  right operand   
--  Return        : qsim_state_vector
--
--
FUNCTION "-" (l, r :qsim_state_vector) RETURN qsim_state_vector IS

  VARIABLE ml     : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt     : qsim_state_vector(1 TO ml);
  VARIABLE rt     : qsim_state_vector(1 TO ml);
  VARIABLE res    : qsim_state_vector(1 TO ml);
  VARIABLE borrow : qsim_state := '1';
  VARIABLE a,b,s1 : qsim_state;

   -- Arithmetic subtraction of unsigned vectors
   ATTRIBUTE synthesis_return OF res:VARIABLE IS "SUB" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN res'REVERSE_RANGE LOOP
    a := lt(i);
    b := NOT rt(i);
    s1 := a + b;
    res(i) := s1 + borrow;
    borrow := (a AND b) OR (s1 AND borrow);
  END LOOP;           
  RETURN res;                
END "-";  

FUNCTION hasX( v : qsim_state_vector ) RETURN boolean IS
   -- Synthesizized as is. 
BEGIN
   FOR i IN v'RANGE LOOP
       IF v(i) = '0' OR v(i) = '1' THEN 
           NULL;
       ELSE
           RETURN TRUE;
       END IF;
   END LOOP;
   RETURN FALSE;
END hasX;



--  Function      : "*"
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  left operand
--                  r - qsim_state_vector -  right operand   
--  Return        : qsim_state_vector
--
--
FUNCTION shift( v : qsim_state_vector ) RETURN qsim_state_vector IS
   VARIABLE v1 : qsim_state_vector( v'RANGE );
   -- Hidden function for synthesis. Directives are set for its callers.
BEGIN
   FOR i IN (v'LEFT+1) TO v'RIGHT LOOP
       v1(i-1) := v(i);
   END LOOP;
   v1(v1'RIGHT) := '0';
   RETURN v1;
END shift;

PROCEDURE copy(a : IN qsim_state_vector; b : OUT qsim_state_vector) IS
   VARIABLE bi : integer := b'RIGHT;
BEGIN
   FOR i in a'REVERSE_RANGE LOOP
       b(bi) := a(i);
       bi := bi - 1;
   END LOOP;
END copy;

FUNCTION "*" (l, r :qsim_state_vector) RETURN qsim_state_vector IS

  VARIABLE ml     : integer := (l'LENGTH + r'LENGTH);
  VARIABLE lt     : qsim_state_vector(1 TO ml);
  VARIABLE rt     : qsim_state_vector(1 TO ml);
  VARIABLE prod   : qsim_state_vector(1 TO ml) := (others=>'0');

   -- Arithmetic multiplication of unsigned vectors
   ATTRIBUTE synthesis_return OF prod:VARIABLE IS "MULT" ;
BEGIN       

  IF hasX(l) OR hasX(r) THEN
    prod := (others=>'X');
  ELSE
    lt := zxt( l, ml );
    rt := zxt( r, ml );
    FOR i IN rt'REVERSE_RANGE LOOP
      IF rt(i) = '1' THEN 
        prod := prod + lt;
      END IF;
      lt := shift(lt);
    END LOOP;
  END IF;
  RETURN prod;
END "*";  


--  Function      : "*"
--  Function Type : Operator Overload
--  Inputs        : l - bit_vector -  left operand
--                  r - bit_vector -  right operand   
--  Return        : bit_vector
--
--
FUNCTION shift( v : bit_vector ) RETURN bit_vector IS
   VARIABLE v1 : bit_vector( v'RANGE );
   -- Hidden function for synthesis. Directives are set for its callers.
BEGIN
   FOR i IN (v'LEFT+1) TO v'RIGHT LOOP
       v1(i-1) := v(i);
   END LOOP;
   v1(v1'RIGHT) := '0';
   RETURN v1;
END shift;

PROCEDURE copy(a : IN bit_vector; b : OUT bit_vector) IS
   VARIABLE bi : integer := b'RIGHT;
   -- Hidden function for synthesis. Directives are set for its callers.
BEGIN
   FOR i in a'REVERSE_RANGE LOOP
       b(bi) := a(i);
       bi := bi - 1;
   END LOOP;
END copy;

FUNCTION "*" (l, r :bit_vector) RETURN bit_vector IS

  VARIABLE ml     : integer := (l'LENGTH + r'LENGTH);
  VARIABLE lt     : bit_vector(1 TO ml);
  VARIABLE rt     : bit_vector(1 TO ml);
  VARIABLE prod   : bit_vector(1 TO ml) := (others=>'0');

   -- Arithmetic multiplication of unsigned vectors
   ATTRIBUTE synthesis_return OF prod:VARIABLE IS "MULT" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );
  FOR i IN rt'REVERSE_RANGE LOOP
    IF rt(i) = '1' THEN 
      prod := prod + lt;
    END IF;
    lt := shift(lt);
  END LOOP;
  RETURN prod;
END "*";  


--  Function      : "/"
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  left operand
--                  r - qsim_state_vector -  right operand   
--  Return        : qsim_state_vector
--
--
FUNCTION rshift( v : qsim_state_vector ) RETURN qsim_state_vector IS
   VARIABLE v1 : qsim_state_vector( v'RANGE );
BEGIN
   FOR i IN v'LEFT TO v'RIGHT-1 LOOP
       v1(i+1) := v(i);
   END LOOP;
   v1(v1'LEFT) := '0';
   RETURN v1;
END rshift;

FUNCTION "/" (l, r :qsim_state_vector) RETURN qsim_state_vector IS

  VARIABLE ml     : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt     : qsim_state_vector(0 TO ml+1);
  VARIABLE rt     : qsim_state_vector(0 TO ml+1);
  VARIABLE rr     : qsim_state_vector(0 TO ml+1);
  VARIABLE quote  : qsim_state_vector(1 TO ml);
  VARIABLE tmp    : qsim_state_vector(0 TO ml+1) := (others=>'0');
  VARIABLE n      : qsim_state_vector(0 TO ml+1) := (others=>'0');

  -- Division of Unsigned vectors.
  ATTRIBUTE synthesis_return OF quote:VARIABLE IS "DIV" ; 
BEGIN
   ASSERT NOT (r = "0")
       REPORT "Attempted divide by ZERO"
       SEVERITY ERROR;
   IF hasX(l) OR hasX(r) THEN
     quote := (others=>'X');
   ELSE
     lt := zxt( l, ml+2 );
     rr := zxt( r, ml+2 );
     WHILE lt >= rr LOOP
       rt := rr;
       n := (OTHERS=>'0');
       n(n'RIGHT) := '1';
       WHILE rt <= lt LOOP
         rt := shift(rt);
         n  := shift(n);
       END LOOP;
       rt := rshift(rt);
       lt := lt - rt;
       n := rshift(n);
       tmp := tmp + n;
     END LOOP;
     quote := tmp(2 to ml+1);
   END IF;
   RETURN quote;
END "/";


--  Function      : "/"
--  Function Type : Operator Overload
--  Inputs        : l - bit_vector -  left operand
--                  r - bit_vector -  right operand   
--  Return        : bit_vector
--
--
FUNCTION rshift( v : bit_vector ) RETURN bit_vector IS
   VARIABLE v1 : bit_vector( v'RANGE );
BEGIN
   FOR i IN v'LEFT TO v'RIGHT-1 LOOP
       v1(i+1) := v(i);
   END LOOP;
   v1(v1'LEFT) := '0';
   RETURN v1;
END rshift;

FUNCTION "/" (l, r :bit_vector) RETURN bit_vector IS

  VARIABLE ml     : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt     : bit_vector(0 TO ml+1);
  VARIABLE rt     : bit_vector(0 TO ml+1);
  VARIABLE rr     : bit_vector(0 TO ml+1);
  VARIABLE quote  : bit_vector(1 TO ml);
  VARIABLE tmp    : bit_vector(0 TO ml+1) := (others=>'0');
  VARIABLE n      : bit_vector(0 TO ml+1) := (others=>'0');

  -- Division of Unsigned vectors.
  ATTRIBUTE synthesis_return OF quote:VARIABLE IS "DIV" ; 
BEGIN
   ASSERT NOT (r = "0")
       REPORT "Attempted divide by ZERO"
       SEVERITY ERROR;
   lt := zxt( l, ml+2 );
   rr := zxt( r, ml+2 );
   WHILE lt >= rr LOOP
     rt := rr;
     n := (OTHERS=>'0');
     n(n'RIGHT) := '1';
     WHILE rt <= lt LOOP
       rt := shift(rt);
       n  := shift(n);
     END LOOP;
     rt := rshift(rt);
     lt := lt - rt;
     n := rshift(n);
     tmp := tmp + n;
   END LOOP;
   quote := tmp(2 to ml+1);
   RETURN quote;
END "/";


--  Function      : "+"
--  Function Type : Operator Overload
--  Inputs        : l - bit_vector -  left operand
--                  r - bit_vector -  right operand   
--  Return        : bit_vector
--
FUNCTION "+" (l, r :bit_vector) RETURN bit_vector IS

  VARIABLE ml     : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt     : bit_vector(1 TO ml);
  VARIABLE rt     : bit_vector(1 TO ml);
  VARIABLE res    : bit_vector(1 TO ml);
  VARIABLE carry  : bit := '0';
  VARIABLE a,b,s1 : bit;

   -- Arithmetic addition of two unsigned vectors.
   ATTRIBUTE synthesis_return OF res:VARIABLE IS "ADD" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN res'REVERSE_RANGE LOOP
    a := lt(i);
    b := rt(i);
    s1 := a XOR b;
    res(i) := s1 XOR carry;
    carry := (a AND b) OR (s1 AND carry);
  END LOOP;           
  RETURN res;
END "+";  



--  Function      : "-"
--  Function Type : Operator Overload
--  Inputs        : l - bit_vector -  left operand
--                  r - bit_vector -  right operand   
--  Return        : bit_vector
--
--
FUNCTION "-" (l, r :bit_vector) RETURN bit_vector IS

  VARIABLE ml     : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt     : bit_vector(1 TO ml);
  VARIABLE rt     : bit_vector(1 TO ml);
  VARIABLE res    : bit_vector(1 TO ml);
  VARIABLE borrow : bit := '1';
  VARIABLE a,b,s1 : bit;

   -- Arithmetic subtraction of two unsigned vectors.
   ATTRIBUTE synthesis_return OF res:VARIABLE IS "SUB" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN res'REVERSE_RANGE LOOP
    a := lt(i);
    b := NOT rt(i);
    s1 := a XOR b;
    res(i) := s1 XOR borrow;
    borrow := (a AND b) OR (s1 AND borrow);
  END LOOP;           
  RETURN res;                
END "-";  



--  Function      : "MOD"
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  left operand
--                  r - qsim_state_vector -  right operand   
--  Return        : qsim_state_vector
--
--
FUNCTION "MOD" (l, r :qsim_state_vector) RETURN qsim_state_vector IS

  VARIABLE ml     : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt     : qsim_state_vector(0 TO ml+1);
  VARIABLE rt     : qsim_state_vector(0 TO ml+1);
  VARIABLE rr     : qsim_state_vector(0 TO ml+1);
  VARIABLE quote  : qsim_state_vector(1 TO ml);

  -- Modulo with unsigned vectors
  ATTRIBUTE synthesis_return OF quote:VARIABLE IS "MOD" ; 
BEGIN                              
  ASSERT NOT (r = "0")
    REPORT "Attempted divide by ZERO"
    SEVERITY ERROR;
  IF hasX(l) OR hasX(r) THEN
    FOR i IN lt'RANGE LOOP
      lt(i) := 'X';
    END LOOP;
  ELSE
    lt := zxt( l, ml+2 );
    rr := zxt( r, ml+2 );
    WHILE lt >= rr LOOP
      rt := rr;
      WHILE rt <= lt LOOP
        rt := shift(rt);
      END LOOP;
      rt := rshift(rt);
      lt := lt - rt;
    END LOOP;
  END IF;
  quote := lt(2 to ml+1);
  RETURN quote;
END "MOD";


--  Function      : "REM"
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  left operand
--                  r - qsim_state_vector -  right operand   
--  Return        : qsim_state_vector
--
--
FUNCTION "REM" (l, r :qsim_state_vector) RETURN qsim_state_vector IS

  VARIABLE ml     : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt     : qsim_state_vector(0 TO ml+1);
  VARIABLE rt     : qsim_state_vector(0 TO ml+1);
  VARIABLE rr     : qsim_state_vector(0 TO ml+1);
  VARIABLE quote  : qsim_state_vector(1 TO ml);

  -- Remainder with unsigned vectors
  ATTRIBUTE synthesis_return OF quote:VARIABLE IS "REM" ; 
BEGIN                              
  ASSERT NOT (r = "0")
    REPORT "Attempted divide by ZERO"
    SEVERITY ERROR;
  IF hasX(l) OR hasX(r) THEN
    FOR i IN lt'RANGE LOOP
      lt(i) := 'X';
    END LOOP;
  ELSE
    lt := zxt( l, ml+2 );
    rr := zxt( r, ml+2 );
    WHILE lt >= rr LOOP
      rt := rr;
      WHILE rt <= lt LOOP
        rt := shift(rt);
      END LOOP;
      rt := rshift(rt);
      lt := lt - rt;
    END LOOP;
  END IF;
  quote := lt(2 to ml+1);
  RETURN quote;
END "REM";




--  Function      : "MOD"
--  Function Type : Operator Overload
--  Inputs        : l - bit_vector -  left operand
--                  r - bit_vector -  right operand   
--  Return        : bit_vector
--
--
FUNCTION "MOD" (l, r :bit_vector) RETURN bit_vector IS

  VARIABLE ml     : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt     : bit_vector(0 TO ml+1);
  VARIABLE rt     : bit_vector(0 TO ml+1);
  VARIABLE rr     : bit_vector(0 TO ml+1);
  VARIABLE quote  : bit_vector(1 TO ml);

  -- Modulo with unsigned vectors
  ATTRIBUTE synthesis_return OF quote:VARIABLE IS "MOD" ; 
BEGIN                              
  ASSERT NOT (r = "0")
    REPORT "Attempted divide by ZERO"
    SEVERITY ERROR;
  lt := zxt( l, ml+2 );
  rr := zxt( r, ml+2 );
  WHILE lt >= rr LOOP
    rt := rr;
    WHILE rt <= lt LOOP
      rt := shift(rt);
    END LOOP;
    rt := rshift(rt);
    lt := lt - rt;
  END LOOP;
  quote := lt(2 to ml+1);
  RETURN quote;
END "MOD";


--  Function      : "REM"
--  Function Type : Operator Overload
--  Inputs        : l - bit_vector -  left operand
--                  r - bit_vector -  right operand   
--  Return        : bit_vector
--
--
FUNCTION "REM" (l, r :bit_vector) RETURN bit_vector IS

  VARIABLE ml     : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt     : bit_vector(0 TO ml+1);
  VARIABLE rt     : bit_vector(0 TO ml+1);
  VARIABLE rr     : bit_vector(0 TO ml+1);
  VARIABLE quote  : bit_vector(1 TO ml);

  -- Remainder with unsigned vectors
  ATTRIBUTE synthesis_return OF quote:VARIABLE IS "REM" ; 
BEGIN                              
  ASSERT NOT (r = "0")
    REPORT "Attempted divide by ZERO"
    SEVERITY ERROR;
  lt := zxt( l, ml+2 );
  rr := zxt( r, ml+2 );
  WHILE lt >= rr LOOP
    rt := rr;
    WHILE rt <= lt LOOP
      rt := shift(rt);
    END LOOP;
    rt := rshift(rt);
    lt := lt - rt;
  END LOOP;
  quote := lt(2 to ml+1);
  RETURN quote;
END "REM";



--  
--  Function      : "**"
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  base
--                  r - qsim_state_vector -  exponent   
--  Return        : qsim_state_vector
--
--
FUNCTION "**" (l, r :qsim_state_vector) RETURN qsim_state_vector IS

  VARIABLE return_vector : qsim_state_vector(l'RANGE) := (others=>'0');
  VARIABLE tmp           : qsim_state_vector(1 to (2 * l'LENGTH)) := (others=>'0');
  CONSTANT lsh_l         : integer := l'LENGTH+1;
  CONSTANT lsh_r         : integer := 2 * l'LENGTH;
  VARIABLE pow           : integer;

  -- Power with unsigned vectors
  ATTRIBUTE synthesis_return OF return_vector:VARIABLE IS "POWER" ; 
BEGIN                              
   IF (hasX(l) OR hasX(r)) THEN
       FOR i IN return_vector'RANGE LOOP
           return_vector(i) := 'X';
       END LOOP;
   ELSE
       pow := to_integer( r, 0 );
       tmp( tmp'right ) := '1';
       FOR i IN 1 TO pow LOOP
           tmp := tmp(lsh_l TO lsh_r) * l;
       END LOOP;
       return_vector := tmp(lsh_l TO lsh_r);
   END IF;
   RETURN return_vector;
END "**";  


--  
--  Function      : "**"
--  Function Type : Operator Overload
--  Inputs        : l - bit_vector -  base
--                  r - bit_vector -  exponent   
--  Return        : bit_vector
--
--
FUNCTION "**" (l, r :bit_vector) RETURN bit_vector IS

  VARIABLE return_vector : bit_vector(l'RANGE) := (others=>'0');
  VARIABLE tmp           : bit_vector(1 to (2 * l'LENGTH)) := (others=>'0');
  CONSTANT lsh_l         : integer := l'LENGTH+1;
  CONSTANT lsh_r         : integer := 2 * l'LENGTH;
  VARIABLE pow           : integer;

  -- Power with unsigned vectors
  ATTRIBUTE synthesis_return OF return_vector:VARIABLE IS "POWER" ; 
BEGIN                              
   pow := to_integer( r );
   tmp( tmp'right ) := '1';
   FOR i IN 1 TO pow LOOP
       tmp := tmp(lsh_l TO lsh_r) * l;
   END LOOP;
   return_vector := tmp(lsh_l TO lsh_r);
   RETURN return_vector;
END "**";  


-- This part is functionally equivalent to qsim_relations







--///////////////////Vector Functions////////////////////

--
--  Function      : = (Equality)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  left operand
--                  r - qsim_state -  right operand   
--  Return        : boolean
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | T  F  F  F
--       1 | F  T  F  F
--       X | F  F  F  F
--       Z | F  F  F  F
--
CONSTANT eq_table : qsim_state_boolean_table :=
           --  X      0      1      Z
           ((FALSE, FALSE, FALSE, FALSE), -- X
            (FALSE, TRUE , FALSE, FALSE), -- 0
            (FALSE, FALSE, TRUE , FALSE), -- 1
            (FALSE, FALSE, FALSE, FALSE));-- Z

FUNCTION eq (l, r: qsim_state) RETURN boolean IS
   -- Equal than on logic type. Return boolean.
   VARIABLE result : boolean ; 
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "EQ" ;
BEGIN
   result := eq_table(l,r);
   RETURN result ;
END eq;



--
--  Function      : /= (Inequality)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  left operand
--                  r - qsim_state -  right operand   
--  Return        : boolean
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | F  T  F  F
--       1 | T  F  F  F
--       X | F  F  F  F
--       Z | F  F  F  F
--
CONSTANT neq_table : qsim_state_boolean_table :=
           --  X      0      1      Z
           ((FALSE, FALSE, FALSE, FALSE), -- X
            (FALSE, FALSE, TRUE , FALSE), -- 0
            (FALSE, TRUE , FALSE, FALSE), -- 1
            (FALSE, FALSE, FALSE, FALSE));-- Z

FUNCTION ne (l, r: qsim_state) RETURN boolean IS
   -- NOT-Equal than on logic type. Return boolean.
   VARIABLE result : boolean ; 
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "NEQ" ;
BEGIN
   result := neq_table(l,r);
   RETURN result ;
END ne;




--
--  Function      : < (Less Than)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  left operand
--                  r - qsim_state -  right operand   
--  Return        : boolean
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | F  F  F  F
--       1 | T  F  F  F
--       X | F  F  F  F
--       Z | F  F  F  F
--
FUNCTION lt (l, r: qsim_state) RETURN boolean IS
   -- Less-than on logic type. Return boolean.
   VARIABLE result : boolean ; 
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "LT" ;
BEGIN
   IF (l = '0') AND (r = '1') THEN
      result := TRUE; 
   ELSE
      result := FALSE;
   END IF;
   RETURN result ;
END lt;




--  Function      : > (Greater Than)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  left operand
--                  r - qsim_state -  right operand   
--  Return        : boolean
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | F  T  F  F
--       1 | F  F  F  F
--       X | F  F  F  F
--       Z | F  F  F  F
--
FUNCTION gt (l, r: qsim_state) RETURN boolean IS
   -- Greater-than on logic type. Return boolean.
   VARIABLE result : boolean ; 
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "GT" ;
BEGIN
   IF (l = '1') AND (r = '0') THEN
      result := TRUE; 
   ELSE
      result := FALSE;
   END IF;
   RETURN result ;
END gt;




--  Function      : <= (Less Than Or Equals)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  left operand
--                  r - qsim_state -  right operand   
--  Return        : boolean
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | T  F  F  F
--       1 | T  T  T  T
--       X | T  F  F  F
--       Z | T  F  F  F
--
FUNCTION le (l, r: qsim_state) RETURN boolean IS
   -- Less-than-or-equal on logic type. Return boolean.
   VARIABLE result : boolean ; 
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "LTE" ;
BEGIN
   IF (l = '0') OR (r = '1') THEN
      result := TRUE; 
   ELSE
      result := FALSE;
   END IF;
   RETURN result ;
END le;




--  Function      : >= (Greater Than Or Equals)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state -  left operand
--                  r - qsim_state -  right operand   
--  Return        : boolean
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | T  T  T  T
--       1 | F  T  F  F
--       X | F  T  F  F
--       Z | F  T  F  F
--
FUNCTION ge (l, r: qsim_state) RETURN boolean IS
   -- Greater-than-or-equal on logic type. Return boolean.
   VARIABLE result : boolean ; 
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "GTE" ;
BEGIN
   IF (l = '1') OR (r = '0') THEN
      result := TRUE; 
   ELSE
      result := FALSE;
   END IF;
   RETURN result ;
END ge;




--/////////////////Drive Strength Overloading///////////////////////
--
--  Function      : eq (Equals)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_strength -  left operand
--                  r - qsim_strength -  right operand   
--  Return        : Boolean
--
--  Truth Table:
--
--  l =      z  r  s  i  
--         ------------
--  r =  z | T  F  F  F
--       r | F  T  F  F
--       s | F  F  T  F
--       i | F  F  F  F
--
CONSTANT eq_strength_table : qsim_strength_boolean_table :=
           --  I      Z      R      S
           ((FALSE, FALSE, FALSE, FALSE), -- I
            (FALSE, TRUE , FALSE, FALSE), -- Z
            (FALSE, FALSE, TRUE , FALSE), -- R
            (FALSE, FALSE, FALSE, TRUE ));-- S

FUNCTION eq (l, r: qsim_strength) RETURN boolean IS

BEGIN
   RETURN eq_strength_table(l,r);
END eq;




--  Function      : neq (Not Equals)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_strength -  left operand
--                  r - qsim_strength -  right operand   
--  Return        : Boolean
--
--  Truth Table:
--
--  l =      z  r  s  i  
--         ------------
--  r =  z | F  T  T  F
--       r | T  F  T  F
--       s | T  T  F  F
--       i | F  F  F  F
--
CONSTANT neq_strength_table : qsim_strength_boolean_table :=
           --  I      Z      R      S
           ((FALSE, FALSE, FALSE, FALSE), -- I
            (FALSE, FALSE, TRUE , TRUE ), -- Z
            (FALSE, TRUE , FALSE, TRUE ), -- R
            (FALSE, TRUE , TRUE , FALSE));-- S

FUNCTION ne (l, r: qsim_strength) RETURN boolean IS

BEGIN
   RETURN neq_strength_table(l,r);
END ne;




--  Function      : lt (Less Than)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_strength -  left operand
--                  r - qsim_strength -  right operand   
--  Return        : Boolean
--
--  Truth Table:
--
--  l =      z  r  s  i  
--         ------------
--  r =  z | F  F  F  F
--       r | T  F  F  F
--       s | T  T  F  F
--       i | F  F  F  F
--
CONSTANT lt_strength_table : qsim_strength_boolean_table :=
           --  I      Z      R      S  <-r
           ((FALSE, FALSE, FALSE, FALSE), -- I  <-l
            (FALSE, FALSE, TRUE , TRUE ), -- Z
            (FALSE, FALSE, FALSE, TRUE ), -- R
            (FALSE, FALSE, FALSE, FALSE));-- S

FUNCTION lt (l, r: qsim_strength) RETURN boolean IS

BEGIN
   RETURN lt_strength_table(l,r);
END lt;







--  Function      : gt (Greater Than)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_strength -  left operand
--                  r - qsim_strength -  right operand   
--  Return        : Boolean
--
--  Truth Table:
--
--  l =      z  r  s  i  
--         ------------
--  r =  z | F  T  T  F
--       r | F  F  T  F
--       s | F  F  F  F
--       i | F  F  F  F
--
CONSTANT gt_strength_table : qsim_strength_boolean_table :=
           --  I      Z      R      S  <-r
           ((FALSE, FALSE, FALSE, FALSE), -- I  <-l
            (FALSE, FALSE, FALSE, FALSE), -- Z
            (FALSE, TRUE , FALSE, FALSE), -- R
            (FALSE, TRUE , TRUE , FALSE));-- S

FUNCTION gt (l, r: qsim_strength) RETURN boolean IS

BEGIN
   RETURN gt_strength_table(l,r);
END gt;






--  Function      : le (Less Than Or Equal To)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_strength -  left operand
--                  r - qsim_strength -  right operand   
--  Return        : Boolean
--
--  Truth Table:
--
--  l =      z  r  s  i  
--         ------------
--  r =  z | T  F  F  F
--       r | T  T  F  F
--       s | T  T  T  T
--       i | T  F  F  F
--
CONSTANT le_strength_table : qsim_strength_boolean_table :=
           --  I      Z      R      S  <-r
           ((FALSE, FALSE, FALSE, TRUE ), -- I  <-l
            (TRUE , TRUE , TRUE , TRUE ), -- Z
            (FALSE, FALSE, TRUE , TRUE ), -- R
            (FALSE, FALSE, FALSE, TRUE ));-- S

FUNCTION le (l, r: qsim_strength) RETURN boolean IS

BEGIN
   RETURN le_strength_table(l,r);
END le;







--  Function      : ge (Greater Than Or Equal To)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_strength -  left operand
--                  r - qsim_strength -  right operand   
--  Return        : Boolean
--
--  Truth Table:
--
--  l =      z  r  s  i  
--         ------------
--  r =  z | T  T  T  T
--       r | F  T  T  F
--       s | F  F  T  F
--       i | F  F  T  F
--
CONSTANT ge_strength_table : qsim_strength_boolean_table :=
           --  I      Z      R      S  <-r
           ((FALSE, TRUE , FALSE, FALSE), -- I  <-l
            (FALSE, TRUE , FALSE, FALSE), -- Z
            (FALSE, TRUE , TRUE , FALSE), -- R
            (TRUE , TRUE , TRUE , TRUE ));-- S

FUNCTION ge (l, r: qsim_strength) RETURN boolean IS

BEGIN
   RETURN ge_strength_table(l,r);
END ge;

FUNCTION same (l, r : qsim_strength )   RETURN boolean IS
   -- True equivalence
BEGIN

   IF qsim_strength'POS(l) = qsim_strength'POS(r) THEN
       RETURN TRUE;
   ELSE
       RETURN FALSE;
   END IF;

END same;

--///////////Relational Operators - return boolean////////////////////////
                                           
--
--  Function      : < (Less Than)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector - left operand
--                  r - qsim_state_vector - right operand   
--  Return        : boolean
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | F  F  F  F
--       1 | T  F  F  F
--       X | F  F  F  F
--       Z | F  F  F  F
--
FUNCTION lt (l, r :qsim_state_vector) RETURN boolean IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE ltp   : qsim_state_vector(1 TO ml);
  VARIABLE rt   : qsim_state_vector(1 TO ml);

   -- Arithmetic Less-than on two unsigned vectors.
   VARIABLE result : boolean ;
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "LT" ;
BEGIN

  ltp := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN ltp'RANGE LOOP
     IF NOT eq(ltp(i), rt(i)) THEN
        RETURN lt(ltp(i), rt(i));
     END IF;
  END LOOP;           

  result := FALSE ;
  RETURN result;

END lt;         



--  Function      : gt (Greater Than)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  left operand
--                  r - qsim_state_vector -  right operand   
--  Return        : boolean
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | F  T  F  F
--       1 | F  F  F  F
--       X | F  F  F  F
--       Z | F  F  F  F  
--
FUNCTION gt (l, r :qsim_state_vector) RETURN boolean IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : qsim_state_vector(1 TO ml);
  VARIABLE rt   : qsim_state_vector(1 TO ml);

   -- Arithmetic Greater-than on two unsigned vectors.
   VARIABLE result : boolean ;
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "GT" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN lt'RANGE LOOP
     IF NOT eq(lt(i), rt(i)) THEN
        RETURN gt(lt(i), rt(i));
     END IF;
  END LOOP;           
  result := FALSE ;
  RETURN result;
END gt;   


--  Function      : eq (Equality)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  left operand
--                  r - qsim_state_vector -  right operand   
--  Return        : boolean
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | T  F  F  F
--       1 | F  T  F  F
--       X | F  F  F  F
--       Z | F  F  F  F
--
FUNCTION eq (l, r: qsim_state_vector) RETURN boolean IS
                                     
  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : qsim_state_vector(1 TO ml);
  VARIABLE rt   : qsim_state_vector(1 TO ml);

   -- Arithmetic equal on two unsigned vectors.
   VARIABLE result : boolean ;
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "EQ" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN lt'RANGE LOOP
     IF not eq(lt(i), rt(i)) THEN
        RETURN FALSE;                                                    
     END IF;
  END LOOP;           
  result := TRUE ;
  RETURN result;
END eq;   


--  Function      : neq (Inequality)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  left operand
--                  r - qsim_state_vector -  right operand   
--  Return        : boolean
--
--  Truth Table:   
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | F  T  F  F
--       1 | T  F  F  F
--       X | F  F  F  F
--       Z | F  F  F  F
--
FUNCTION ne (l, r: qsim_state_vector) RETURN boolean IS
                                     
  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : qsim_state_vector(1 TO ml);
  VARIABLE rt   : qsim_state_vector(1 TO ml);

   -- Arithmetic NOT-equal on two unsigned vectors.
   VARIABLE result : boolean ;
   ATTRIBUTE synthesis_return OF result:VARIABLE IS "NEQ" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN lt'RANGE LOOP
     IF ne(lt(i), rt(i)) THEN
        RETURN TRUE;                                                    
     END IF;
  END LOOP;           
  result := FALSE ;
  RETURN result;
END ne;   


--
--  Function      : <= (Less Than Or Equals)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector - left operand
--                  r - qsim_state_vector - right operand   
--  Return        : boolean
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | T  F  F  F
--       1 | T  T  T  T
--       X | T  F  F  F
--       Z | T  F  F  F
--







FUNCTION le (l, r :qsim_state_vector) RETURN boolean IS
                                                  
  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : qsim_state_vector(1 TO ml);
  VARIABLE rt   : qsim_state_vector(1 TO ml);
  VARIABLE result : qsim_fuzzy_state;

   -- Arithmetic Less-than-or-equal on two unsigned vectors.
  VARIABLE bresult : boolean ;
  ATTRIBUTE synthesis_return OF bresult:VARIABLE IS "LTE" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN lt'RANGE LOOP
     result := qsim_le_state_table( lt(i), rt(i) );
     CASE result IS
        WHEN 'X'     =>   RETURN FALSE;
        WHEN 'T'     =>   RETURN TRUE;
        WHEN 'F'     =>   RETURN FALSE;
        WHEN OTHERS  =>   NULL;
     END CASE;
  END LOOP;           
  bresult := TRUE ;
  RETURN bresult;
END le;         


--  Function      : >= (Greater Than Or Equals)
--  Function Type : Operator Overload
--  Inputs        : l - qsim_state_vector -  left operand
--                  r - qsim_state_vector -  right operand   
--  Return        : boolean
--
--  Truth Table:
--
--  l =      0  1  X  Z  
--         ------------
--  r =  0 | T  T  T  T
--       1 | F  T  F  F
--       X | F  T  F  F
--       Z | F  T  F  F
--







FUNCTION ge (l, r :qsim_state_vector) RETURN boolean IS                   

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : qsim_state_vector(1 TO ml);
  VARIABLE rt   : qsim_state_vector(1 TO ml);
  VARIABLE result : qsim_fuzzy_state;

   -- Arithmetic Greater-than-or-equal on two unsigned vectors.
  VARIABLE bresult : boolean ;
  ATTRIBUTE synthesis_return OF bresult:VARIABLE IS "GTE" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN lt'RANGE LOOP
     result := qsim_ge_state_table( lt(i), rt(i) );
     CASE result IS
        WHEN 'X'     =>   RETURN FALSE;
        WHEN 'T'     =>   RETURN TRUE;
        WHEN 'F'     =>   RETURN FALSE;
        WHEN OTHERS  =>   NULL;
     END CASE;
  END LOOP;           
  bresult := TRUE ;
  RETURN bresult;
END ge;         
      
FUNCTION same( l, r : qsim_state )   RETURN boolean IS
   -- true equivalence
BEGIN

  IF qsim_state'pos(l) = qsim_state'pos(r) THEN
     RETURN TRUE;
  ELSE
     RETURN FALSE;
  END IF;

END same;

  -- Redefine the basic comparison operators on bit vectors because 
  -- that which is defined in VHDL does text string comparisons.

FUNCTION  lt   (l, r : bit_vector) RETURN bit IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : bit_vector(1 TO ml);
  VARIABLE rt   : bit_vector(1 TO ml);

  -- Arithmetic Less-than on two unsigned vectors.
  VARIABLE result : bit ;
  ATTRIBUTE synthesis_return OF result:VARIABLE IS "LT" ;
BEGIN

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN lt'RANGE LOOP
     IF NOT (lt(i) = rt(i)) THEN
        IF lt(i) < rt(i) THEN RETURN '1';
        ELSE                  RETURN '0';
        END IF;
     END IF;
  END LOOP;           

  result := '0' ;
  RETURN result;

END lt;         

FUNCTION  gt   (l, r : bit_vector) RETURN bit IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : bit_vector(1 TO ml);
  VARIABLE rt   : bit_vector(1 TO ml);

  -- Arithmetic Greater-than on two unsigned vectors.
  VARIABLE result : bit ;
  ATTRIBUTE synthesis_return OF result:VARIABLE IS "GT" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN lt'RANGE LOOP
     IF NOT (lt(i) = rt(i)) THEN
        IF (lt(i) > rt(i)) THEN RETURN '1';
        ELSE                    RETURN '0';
        END IF;
     END IF;
  END LOOP;           
  result := '0';
  RETURN result;
END gt;   

FUNCTION  eq   (l, r : bit_vector) RETURN bit IS
                                     
  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : bit_vector(1 TO ml);
  VARIABLE rt   : bit_vector(1 TO ml);

  -- Arithmetic Equal on two unsigned vectors.
  VARIABLE result : bit ;
  ATTRIBUTE synthesis_return OF result:VARIABLE IS "EQ" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN lt'RANGE LOOP
     IF lt(i) /= rt(i) THEN
        RETURN '0';                                                    
     END IF;
  END LOOP;           
  result := '1';
  RETURN result;
END eq;

FUNCTION  ne  (l, r : bit_vector) RETURN bit IS
                                     
  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : bit_vector(1 TO ml);
  VARIABLE rt   : bit_vector(1 TO ml);

  -- Arithmetic NOT-Equal on two unsigned vectors.
  VARIABLE result : bit ;
  ATTRIBUTE synthesis_return OF result:VARIABLE IS "NEQ" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN lt'RANGE LOOP
     IF lt(i) /= rt(i) THEN
        RETURN '1';                                                    
     END IF;
  END LOOP;           
  result := '0';
  RETURN result;
END ne;   

FUNCTION  ge  (l, r : bit_vector) RETURN bit IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : bit_vector(1 TO ml);
  VARIABLE rt   : bit_vector(1 TO ml);

  -- Arithmetic Greater-than-or-Equal on two unsigned vectors.
  VARIABLE result : bit ;
  ATTRIBUTE synthesis_return OF result:VARIABLE IS "GTE" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN lt'RANGE LOOP
     IF lt(i) < rt(i) THEN
        RETURN '0';    -- less
     ELSIF lt(i) > rt(i) THEN
        RETURN '1';    -- greater
     END IF;
  END LOOP;           
  result := '1' ;      -- equal
  RETURN result; 
END ge;         

FUNCTION  le  (l, r : bit_vector) RETURN bit IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : bit_vector(1 TO ml);
  VARIABLE rt   : bit_vector(1 TO ml);

  -- Arithmetic Less-than-or-Equal on two unsigned vectors.
  VARIABLE result : bit ;
  ATTRIBUTE synthesis_return OF result:VARIABLE IS "LTE" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN lt'RANGE LOOP
     IF lt(i) > rt(i) THEN
        RETURN '0';    -- greater
     ELSIF lt(i) < rt(i) THEN
        RETURN '1';    -- less
     END IF;
  END LOOP;           
  result := '1';       -- equal
  RETURN result;
END le;         

FUNCTION  lt   (l, r : bit_vector) RETURN boolean IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : bit_vector(1 TO ml);
  VARIABLE rt   : bit_vector(1 TO ml);

  -- Arithmetic Less-than on two unsigned vectors.
  VARIABLE result : boolean ;
  ATTRIBUTE synthesis_return OF result:VARIABLE IS "LT" ;
BEGIN

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN lt'RANGE LOOP
     IF NOT (lt(i) = rt(i)) THEN
        RETURN lt(i) < rt(i);
     END IF;
  END LOOP;           

  result := FALSE;
  RETURN result;

END lt;         

FUNCTION  gt   (l, r : bit_vector) RETURN boolean IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : bit_vector(1 TO ml);
  VARIABLE rt   : bit_vector(1 TO ml);

  -- Arithmetic Greater-than on two unsigned vectors.
  VARIABLE result : boolean ;
  ATTRIBUTE synthesis_return OF result:VARIABLE IS "GT" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN lt'RANGE LOOP
     IF NOT (lt(i) = rt(i)) THEN
        RETURN (lt(i) > rt(i));
     END IF;
  END LOOP;           
  result := FALSE;
  RETURN result;

END gt;   

FUNCTION  eq   (l, r : bit_vector) RETURN boolean IS
                                     
  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : bit_vector(1 TO ml);
  VARIABLE rt   : bit_vector(1 TO ml);

  -- Arithmetic Equal on two unsigned vectors.
  VARIABLE result : boolean ;
  ATTRIBUTE synthesis_return OF result:VARIABLE IS "EQ" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN lt'RANGE LOOP
     IF lt(i) /= rt(i) THEN
        RETURN FALSE;
     END IF;
  END LOOP;           
  result := TRUE;
  RETURN result;
END eq;

FUNCTION  ne  (l, r : bit_vector) RETURN boolean IS
                                     
  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : bit_vector(1 TO ml);
  VARIABLE rt   : bit_vector(1 TO ml);

  -- Arithmetic Not-Equal on two unsigned vectors.
  VARIABLE result : boolean ;
  ATTRIBUTE synthesis_return OF result:VARIABLE IS "NEQ" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN lt'RANGE LOOP
     IF lt(i) /= rt(i) THEN
        RETURN TRUE;
     END IF;
  END LOOP;           
  result := FALSE;
  RETURN result;
END ne;   

FUNCTION  ge  (l, r : bit_vector) RETURN boolean IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : bit_vector(1 TO ml);
  VARIABLE rt   : bit_vector(1 TO ml);

  -- Arithmetic Greater-than-or-Equal on two unsigned vectors.
  VARIABLE result : boolean ;
  ATTRIBUTE synthesis_return OF result:VARIABLE IS "GTE" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN lt'RANGE LOOP
     IF lt(i) < rt(i) THEN
        RETURN FALSE;    -- less
     ELSIF lt(i) > rt(i) THEN
        RETURN TRUE;     -- greater
     END IF;
  END LOOP;           
  result := TRUE;        -- equal
  RETURN result; 
END ge;         

FUNCTION  le  (l, r : bit_vector) RETURN boolean IS

  VARIABLE ml   : integer := max(l'LENGTH,r'LENGTH);
  VARIABLE lt   : bit_vector(1 TO ml);
  VARIABLE rt   : bit_vector(1 TO ml);

  -- Arithmetic Less-than-or-Equal on two unsigned vectors.
  VARIABLE result : boolean ;
  ATTRIBUTE synthesis_return OF result:VARIABLE IS "LTE" ;
BEGIN       

  lt := zxt( l, ml );
  rt := zxt( r, ml );

  FOR i IN lt'RANGE LOOP
     IF lt(i) > rt(i) THEN
        RETURN FALSE;    -- greater
     ELSIF lt(i) < rt(i) THEN
        RETURN TRUE;    -- less
     END IF;
  END LOOP;           
  result := TRUE;       -- equal
  RETURN result; 
END le;         


-- Shift operators for all vector types defined above
--  below are shift operations defined on the following
--  types:
--   qsim_state_vector
--   qsim_state_resolved_x_vector
--   qsim_state_resolved_or_vector
--   qsim_state_resolved_and_vector
--   qsim_12state_vector
--   qsim_12state_resolved_vector
--   bit_resolved_and_vector
--   bit_resolved_or_vector
--   integer

 FUNCTION "sll" (l:qsim_state_vector; r:integer) 
        RETURN qsim_state_vector IS
        CONSTANT  len  : integer := l'length;
        alias     ls   : qsim_state_vector(1 to len) is l;
        CONSTANT  zero : qsim_state_vector(1 to len) := (others=>'0');
        -- VHDL 93 SLL 
        VARIABLE result : qsim_state_vector(1 to len);
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SLL" ; 
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (ls(r+1 to len) & zero(1 to r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SRL -r);
  END IF;
  RETURN result;
END "sll";
  

FUNCTION "srl" (l : qsim_state_vector; r : integer)
        return qsim_state_vector IS
        CONSTANT   len    : integer := l'length;
        alias      ls     : qsim_state_vector(1 to len) is l;
        CONSTANT   zero   : qsim_state_vector(1 to len) := (others=>'0');
        -- VHDL 93 SRL
        VARIABLE result : qsim_state_vector(1 to len);
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SRL" ; 
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (zero(1 to r) & ls(1 to len-r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SLL -r);
  END IF;
  RETURN result;
END "srl";


FUNCTION "sla" (l : qsim_state_vector; r : integer)
        return qsim_state_vector IS
        CONSTANT    len    : integer := l'length;
        alias       ls     : qsim_state_vector(1 to len) is l;
        CONSTANT    zero   : qsim_state_vector(1 to len) :=
          (others=>l(l'right));
        -- VHDL 93 SLA
        VARIABLE result : qsim_state_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SLA" ; 
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (ls(r+1 to len) & zero(1 to r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SRA -r);
  END IF;
  RETURN result;
END "sla";

FUNCTION "sra" (l : qsim_state_vector; r : integer)
	return qsim_state_vector IS
        CONSTANT    len   : integer := l'length;
        ALIAS       ls    : qsim_state_vector(1 to len) IS l;
        CONSTANT    sign  : qsim_state_vector(1 to len) :=
          (others=>l(l'left));
        -- VHDL 93 SRA
        VARIABLE result : qsim_state_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SRA" ; 
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (sign);
    ELSE
      result := (sign(1 to r) & ls(1 to len-r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SLA -r);
  END IF;
  RETURN result;
END "sra";

FUNCTION "rol" (l : qsim_state_vector; r : integer)
        return qsim_state_vector IS
        CONSTANT    len   : integer := l'length;
        ALIAS       ls    : qsim_state_vector(1 to len) IS l;
        CONSTANT    mr    : integer := r mod len;
        -- VHDL 93 ROL
        VARIABLE result : qsim_state_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "ROL" ; 
BEGIN
  IF (r>=0) THEN
    ASSERT r > len
      REPORT "rotate is further then array size."
      SEVERITY WARNING ;
    IF (mr = 0) THEN
      result := (l);
    ELSE
      result := (ls(mr+1 to len) & ls(1 to mr));
    END IF;
  ELSE
    ASSERT FALSE
      REPORT "rotate is negative."
      SEVERITY WARNING ;
    result := (l ROR -r);
  END IF;
  RETURN result;
END "rol";

FUNCTION "ror" (l : qsim_state_vector; r : integer)
        return qsim_state_vector IS
        CONSTANT    len   : integer := l'length;
        ALIAS       ls    : qsim_state_vector(1 to len) IS l;
        CONSTANT    mr    : integer := r mod len;
        -- VHDL 93 ROR
        VARIABLE result : qsim_state_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "ROR" ; 
BEGIN
  IF (r>=0) THEN
    ASSERT r > len
      REPORT "rotate is further then array size."
      SEVERITY WARNING ;
    IF (mr = 0) THEN
      result := (l);
    ELSE
      result := (ls(len-mr+1 to len) & ls(1 to len-mr));
    END IF;
  ELSE
    ASSERT FALSE
      REPORT "rotate is negative."
      SEVERITY WARNING ;
    result := (l ROL -r);
  END IF;
  RETURN result;
END "ror";


--   qsim_state_resolved_x_vector

FUNCTION "sll" (l:qsim_state_resolved_x_vector; r:integer) 
        RETURN qsim_state_resolved_x_vector IS
        CONSTANT   len    : integer := l'length;
        ALIAS      ls     : qsim_state_resolved_x_vector(1 to len) is l;
        CONSTANT   zero   : qsim_state_resolved_x_vector(1 to len) :=
          (others=>'0');
        -- VHDL 93 SLL
        VARIABLE result : qsim_state_resolved_x_vector(1 to len);
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SLL" ; 
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (ls(r+1 to len) & zero(1 to r));
    END IF;
  ELSIF (r=0) THEN
      result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SRL -r);
  END IF;
  RETURN result;
END "sll";
  

FUNCTION "srl" (l : qsim_state_resolved_x_vector; r : integer)
        return qsim_state_resolved_x_vector IS
        CONSTANT    len   : integer := l'length;
        ALIAS       ls    : qsim_state_resolved_x_vector(1 to len) is l;
        CONSTANT    zero  : qsim_state_resolved_x_vector(1 to len) :=
          (others=>'0');
        -- VHDL 93 SRL
        VARIABLE result : qsim_state_resolved_x_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SRL" ; 
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (zero(1 to r) & ls(1 to len-r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SLL -r);
  END IF;
  RETURN result;
END "srl";


FUNCTION "sla" (l : qsim_state_resolved_x_vector; r : integer)
        return qsim_state_resolved_x_vector IS
        CONSTANT    len   : integer := l'length;
        ALIAS       ls    : qsim_state_resolved_x_vector(1 to len) is l;
        CONSTANT    zero  : qsim_state_resolved_x_vector(1 to len) :=
          (others=>l(l'right));
        -- VHDL 93 SLA
        VARIABLE result : qsim_state_resolved_x_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SLA";
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (ls(r+1 to len) & zero(1 to r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SRA -r);
  END IF;
  RETURN result;
END "sla";

FUNCTION "sra" (l : qsim_state_resolved_x_vector; r : integer)
      return qsim_state_resolved_x_vector IS
      CONSTANT    len   : integer := l'length;
      ALIAS       ls    : qsim_state_resolved_x_vector(1 to len) IS l;
      CONSTANT    sign  : qsim_state_resolved_x_vector(1 to len) :=
        (others=>l(l'left));
        -- VHDL 93 SRA
        VARIABLE result : qsim_state_resolved_x_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SRA";
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (sign);
    ELSE
      result := (sign(1 to r) & ls(1 to len-r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SLA -r);
  END IF;
  RETURN result;
END "sra";

FUNCTION "rol" (l : qsim_state_resolved_x_vector; r : integer)
        return qsim_state_resolved_x_vector IS
        CONSTANT    len   : integer := l'length;
        ALIAS       ls    : qsim_state_resolved_x_vector(1 to len) IS l;
        CONSTANT    mr    : integer := r mod len;
        -- VHDL 93 ROL
        VARIABLE result : qsim_state_resolved_x_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "ROL";
BEGIN
  IF (r>=0) THEN
    ASSERT r > len
      REPORT "rotate is further then array size."
      SEVERITY WARNING ;
    IF (mr = 0) THEN
      result := (l);
    ELSE
      result := (ls(mr+1 to len) & ls(1 to mr));
    END IF;
  ELSE
    ASSERT FALSE
      REPORT "rotate is negative."
      SEVERITY WARNING ;
    result := (l ROR -r);
  END IF;
  RETURN result;
END "rol";

FUNCTION "ror" (l : qsim_state_resolved_x_vector; r : integer)
        return qsim_state_resolved_x_vector IS
        CONSTANT    len   : integer := l'length;
        ALIAS       ls    : qsim_state_resolved_x_vector(1 to len) IS l;
        CONSTANT    mr    : integer := r mod len;
        -- VHDL 93 ROR
        VARIABLE result : qsim_state_resolved_x_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "ROR";
BEGIN
  IF (r>=0) THEN
    ASSERT r > len
      REPORT "rotate is further then array size."
      SEVERITY WARNING ;
    IF (mr = 0) THEN
      result := (l);
    ELSE
      result := (ls(len-mr+1 to len) & ls(1 to len-mr));
    END IF;
  ELSE
    ASSERT FALSE
      REPORT "rotate is negative."
      SEVERITY WARNING ;
    result := (l ROL -r);
  END IF;
  RETURN result;
END "ror";


--   qsim_state_resolved_and_vector

FUNCTION "sll" (l:qsim_state_resolved_and_vector;
                r:integer) RETURN qsim_state_resolved_and_vector IS
                CONSTANT   len    : integer := l'length;
                ALIAS      ls     : qsim_state_resolved_and_vector(1 to len) is l;
                CONSTANT   zero   : qsim_state_resolved_and_vector(1 to len) :=
                  (others=>'0');
        -- VHDL 93 SLL
        VARIABLE result : qsim_state_resolved_and_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SLL";
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (ls(r+1 to len) & zero(1 to r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SRL -r);
  END IF;
  RETURN result;
END "sll";
  

FUNCTION "srl" (l : qsim_state_resolved_and_vector; r : integer)
        return qsim_state_resolved_and_vector IS
        CONSTANT    len   : integer := l'length;
        ALIAS       ls    : qsim_state_resolved_and_vector(1 to len) is l;
        CONSTANT    zero  : qsim_state_resolved_and_vector(1 to len) :=
          (others=>'0');
        -- VHDL 93 SRL
        VARIABLE result : qsim_state_resolved_and_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SRL";
BEGIN
  IF (r>0) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
    IF (r >= len) THEN
      result := (zero);
    ELSE
      result := (zero(1 to r) & ls(1 to len-r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SLL -r);
  END IF;
  RETURN result;
END "srl";


FUNCTION "sla" (l : qsim_state_resolved_and_vector; r : integer)
        return qsim_state_resolved_and_vector IS
        CONSTANT    len   : integer := l'length;
        alias       ls    : qsim_state_resolved_and_vector(1 to len) is l;
        CONSTANT    zero  : qsim_state_resolved_and_vector(1 to len) :=
          (others=>l(l'right));
        -- VHDL 93 SLA
        VARIABLE result : qsim_state_resolved_and_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SLA";
begin
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (ls(r+1 to len) & zero(1 to r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SRA -r);
  END IF;
  RETURN result;
END "sla";

FUNCTION "sra" (l : qsim_state_resolved_and_vector; r : integer)
      return qsim_state_resolved_and_vector IS
      CONSTANT    len   : integer := l'length;
      ALIAS       ls    : qsim_state_resolved_and_vector(1 to len) IS l;
      CONSTANT    sign  : qsim_state_resolved_and_vector(1 to len) :=
         (others=>l(l'left));
        -- VHDL 93 SRA
        VARIABLE result : qsim_state_resolved_and_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SRA";
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (sign);
    ELSE
      result := (sign(1 to r) & ls(1 to len-r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SLA -r);
  END IF;
  RETURN result;
END "sra";

FUNCTION "rol" (l : qsim_state_resolved_and_vector; r : integer)
        return qsim_state_resolved_and_vector IS
        CONSTANT    len   : integer := l'length;
        ALIAS       ls    : qsim_state_resolved_and_vector(1 to len) IS l;
        CONSTANT    mr    : integer := r mod len;
        -- VHDL 93 ROL
        VARIABLE result : qsim_state_resolved_and_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "ROL";
BEGIN
  IF (r>=0) THEN
    ASSERT r > len
      REPORT "rotate is further then array size."
      SEVERITY WARNING ;
    IF (mr = 0) THEN
      result := (l);
    ELSE
      result := (ls(mr+1 to len) & ls(1 to mr));
    END IF;
  ELSE
    ASSERT FALSE
      REPORT "rotate is negative."
      SEVERITY WARNING ;
    result := (l ROR -r);
  END IF;
  RETURN result;
END "rol";

FUNCTION "ror" (l : qsim_state_resolved_and_vector; r : integer)
        return qsim_state_resolved_and_vector IS
        CONSTANT    len   : integer := l'length;
        ALIAS       ls    : qsim_state_resolved_and_vector(1 to len) IS l;
        CONSTANT    mr    : integer := r mod len;
        -- VHDL 93 ROR
        VARIABLE result : qsim_state_resolved_and_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "ROR";
BEGIN
  IF (r>=0) THEN
    ASSERT r > len
      REPORT "rotate is further then array size."
      SEVERITY WARNING ;
    IF (mr = 0) THEN
      result := (l);
    ELSE
      result := (ls(len-mr+1 to len) & ls(1 to len-mr));
    END IF;
  ELSE
    ASSERT FALSE
      REPORT "rotate is negative."
      SEVERITY WARNING ;
    result := (l ROL -r);
  END IF;
  RETURN result;
END "ror";


--   qsim_state_resolved_or_vector

FUNCTION "sll" (l:qsim_state_resolved_or_vector;
                r:integer) RETURN qsim_state_resolved_or_vector IS
                CONSTANT   len    : integer := l'length;
                ALIAS      ls     : qsim_state_resolved_or_vector(1 to len) is l;
                CONSTANT   zero   : qsim_state_resolved_or_vector(1 to len) :=
                  (others=>'0');
        -- VHDL 93 SLL
        VARIABLE result : qsim_state_resolved_or_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SLL";
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (ls(r+1 to len) & zero(1 to r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SRL -r);
  END IF;
  RETURN result;
END "sll";
  

FUNCTION "srl" (l : qsim_state_resolved_or_vector; r : integer)
        return qsim_state_resolved_or_vector IS
        CONSTANT    len   : integer := l'length;
        ALIAS       ls    : qsim_state_resolved_or_vector(1 to len) is l;
        CONSTANT    zero  : qsim_state_resolved_or_vector(1 to len) :=
          (others=>'0');
        -- VHDL 93 SRL
        VARIABLE result : qsim_state_resolved_or_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SRL";
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (zero(1 to r) & ls(1 to len-r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SLL -r);
  END IF;
  RETURN result;
END "srl";


FUNCTION "sla" (l : qsim_state_resolved_or_vector; r : integer)
        return qsim_state_resolved_or_vector IS
        CONSTANT    len   : integer := l'length;
        alias       ls    : qsim_state_resolved_or_vector(1 to len) is l;
        CONSTANT    zero  : qsim_state_resolved_or_vector(1 to len) :=
          (others=>l(l'right));
        -- VHDL 93 SLA
        VARIABLE result : qsim_state_resolved_or_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SLA";
begin
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (ls(r+1 to len) & zero(1 to r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SRA -r);
  END IF;
  RETURN result;
END "sla";

FUNCTION "sra" (l : qsim_state_resolved_or_vector; r : integer)
      return qsim_state_resolved_or_vector IS
      CONSTANT    len   : integer := l'length;
      ALIAS       ls    : qsim_state_resolved_or_vector(1 to len) IS l;
      CONSTANT    sign  : qsim_state_resolved_or_vector(1 to len) :=
         (others=>l(l'left));
        -- VHDL 93 SRA
        VARIABLE result : qsim_state_resolved_or_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SRA";
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (sign);
    ELSE
      result := (sign(1 to r) & ls(1 to len-r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SLA -r);
  END IF;
  RETURN result;
END "sra";

FUNCTION "rol" (l : qsim_state_resolved_or_vector; r : integer)
        return qsim_state_resolved_or_vector IS
        CONSTANT    len   : integer := l'length;
        ALIAS       ls    : qsim_state_resolved_or_vector(1 to len) IS l;
        CONSTANT    mr    : integer := r mod len;
        -- VHDL 93 ROL
        VARIABLE result : qsim_state_resolved_or_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "ROL";
BEGIN
  IF (r>=0) THEN
    ASSERT r > len
      REPORT "rotate is further then array size."
      SEVERITY WARNING ;
    IF (mr = 0) THEN
      result := (l);
    ELSE
      result := (ls(mr+1 to len) & ls(1 to mr));
    END IF;
  ELSE
    ASSERT FALSE
      REPORT "rotate is negative."
      SEVERITY WARNING ;
    result := (l ROR -r);
  END IF;
  RETURN result;
END "rol";

FUNCTION "ror" (l : qsim_state_resolved_or_vector; r : integer)
        return qsim_state_resolved_or_vector IS
        CONSTANT    len   : integer := l'length;
        ALIAS       ls    : qsim_state_resolved_or_vector(1 to len) IS l;
        CONSTANT    mr    : integer := r mod len;
        -- VHDL 93 ROR
        VARIABLE result : qsim_state_resolved_or_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "ROR";
BEGIN
  IF (r>=0) THEN
    ASSERT r > len
      REPORT "rotate is further then array size."
      SEVERITY WARNING ;
    IF (mr = 0) THEN
      result := (l);
    ELSE
      result := (ls(len-mr+1 to len) & ls(1 to len-mr));
    END IF;
  ELSE
    ASSERT FALSE
      REPORT "rotate is negative."
      SEVERITY WARNING ;
    result := (l ROL -r);
  END IF;
  RETURN result;
END "ror";


--   qsim_12state_vector

FUNCTION "sll" (l:qsim_12state_vector;
                r:integer) RETURN qsim_12state_vector IS
                CONSTANT   len    : integer := l'length;
                ALIAS      ls     : qsim_12state_vector(1 to len) is l;
                CONSTANT   zero   : qsim_12state_vector(1 to len) :=
                  (others=>s0s);
        -- VHDL 93 SLL
        VARIABLE result : qsim_12state_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SLL";
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (ls(r+1 to len) & zero(1 to r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SRL -r);
  END IF;
  RETURN result;
END "sll";
  

FUNCTION "srl" (l : qsim_12state_vector; r : integer)
        return qsim_12state_vector IS
        CONSTANT    len     : integer := l'length;
        ALIAS       ls      : qsim_12state_vector(1 to len) is l;
        CONSTANT    zero    : qsim_12state_vector(1 to len) :=
          (others=>s0s);
        -- VHDL 93 SRL
        VARIABLE result : qsim_12state_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SRL";
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (zero(1 to r) & ls(1 to len-r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SLL -r);
  END IF;
  RETURN result;
END "srl";


FUNCTION "sla" (l : qsim_12state_vector; r : integer)
        return qsim_12state_vector IS
        CONSTANT    len     : integer := l'length;
        alias       ls      : qsim_12state_vector(1 to len) is l;
        CONSTANT    zero    : qsim_12state_vector(1 to len) :=
          (others=>l(l'right));
        -- VHDL 93 SLA
        VARIABLE result : qsim_12state_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SLA";
begin
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (ls(r+1 to len) & zero(1 to r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SRA -r);
  END IF;
  RETURN result;
END "sla";

FUNCTION "sra" (l : qsim_12state_vector; r : integer)
      return qsim_12state_vector IS
      CONSTANT    len     : integer := l'length;
      ALIAS       ls      : qsim_12state_vector(1 to len) IS l;
      CONSTANT    sign    : qsim_12state_vector(1 to len) :=
         (others=>l(l'left));
        -- VHDL 93 SRA
        VARIABLE result : qsim_12state_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SRA";
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (sign);
    ELSE
      result := (sign(1 to r) & ls(1 to len-r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SLA -r);
  END IF;
  RETURN result;
END "sra";

FUNCTION "rol" (l : qsim_12state_vector; r : integer)
        return qsim_12state_vector IS
        CONSTANT    len     : integer := l'length;
        ALIAS       ls      : qsim_12state_vector(1 to len) IS l;
        CONSTANT    mr      : integer := r mod len;
        -- VHDL 93 ROL
        VARIABLE result : qsim_12state_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "ROL";
BEGIN
  IF (r>=0) THEN
    ASSERT r > len
      REPORT "rotate is further then array size."
      SEVERITY WARNING ;
    IF (mr = 0) THEN
      result := (l);
    ELSE
      result := (ls(mr+1 to len) & ls(1 to mr));
    END IF;
  ELSE
    ASSERT FALSE
      REPORT "rotate is negative."
      SEVERITY WARNING ;
    result := (l ROR -r);
  END IF;
  RETURN result;
END "rol";

FUNCTION "ror" (l : qsim_12state_vector; r : integer)
        return qsim_12state_vector IS
        CONSTANT    len     : integer := l'length;
        ALIAS       ls      : qsim_12state_vector(1 to len) IS l;
        CONSTANT    mr      : integer := r mod len;
        -- VHDL 93 ROR
        VARIABLE result : qsim_12state_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "ROR";
BEGIN
  IF (r>=0) THEN
    ASSERT r > len
      REPORT "rotate is further then array size."
      SEVERITY WARNING ;
    IF (mr = 0) THEN
      result := (l);
    ELSE
      result := (ls(len-mr+1 to len) & ls(1 to len-mr));
    END IF;
  ELSE
    ASSERT FALSE
      REPORT "rotate is negative."
      SEVERITY WARNING ;
    result := (l ROL -r);
  END IF;
  RETURN result;
END "ror";


--   qsim_12state_resolved_vector

FUNCTION "sll" (l:qsim_12state_resolved_vector;
                r:integer) RETURN qsim_12state_resolved_vector IS
                CONSTANT   len    : integer := l'length;
                alias      ls     : qsim_12state_resolved_vector(1 to len) is l;
                CONSTANT   zero   : qsim_12state_resolved_vector(1 to len) :=
                  (others=>s0s);
        -- VHDL 93 SLL
        VARIABLE result : qsim_12state_resolved_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SLL";
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (ls(r+1 to len) & zero(1 to r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SRL -r);
  END IF;
  RETURN result;
END "sll";
  

FUNCTION "srl" (l : qsim_12state_resolved_vector; r : integer)
        return qsim_12state_resolved_vector IS
        CONSTANT    len     : integer := l'length;
        ALIAS       ls      : qsim_12state_resolved_vector(1 to len) is l;
        CONSTANT    zero    : qsim_12state_resolved_vector(1 to len) :=
          (others=>s0s);
        -- VHDL 93 SRL
        VARIABLE result : qsim_12state_resolved_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SRL";
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (zero(1 to r) & ls(1 to len-r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SLL -r);
  END IF;
  RETURN result;
END "srl";


FUNCTION "sla" (l : qsim_12state_resolved_vector; r : integer)
        return qsim_12state_resolved_vector IS
        CONSTANT    len     : integer := l'length;
        alias       ls      : qsim_12state_resolved_vector(1 to len) is l;
        CONSTANT    zero    : qsim_12state_resolved_vector(1 to len) :=
          (others=>l(l'right));
        -- VHDL 93 SLA
        VARIABLE result : qsim_12state_resolved_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SLA";
begin
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (ls(r+1 to len) & zero(1 to r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SRA -r);
  END IF;
  RETURN result;
END "sla";

FUNCTION "sra" (l : qsim_12state_resolved_vector; r : integer)
      return qsim_12state_resolved_vector IS
      CONSTANT    len     : integer := l'length;
      ALIAS       ls      : qsim_12state_resolved_vector(1 to len) IS l;
      CONSTANT    sign    : qsim_12state_resolved_vector(1 to len) :=
        (others=>l(l'left));
        -- VHDL 93 SRA
        VARIABLE result : qsim_12state_resolved_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SRA";
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (sign);
    ELSE
      result := (sign(1 to r) & ls(1 to len-r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SLA -r);
  END IF;
  RETURN result;
END "sra";

FUNCTION "rol" (l : qsim_12state_resolved_vector; r : integer)
        return qsim_12state_resolved_vector IS
        CONSTANT    len     : integer := l'length;
        ALIAS       ls      : qsim_12state_resolved_vector(1 to len) IS l;
        CONSTANT    mr      : integer := r mod len;
        -- VHDL 93 ROL
        VARIABLE result : qsim_12state_resolved_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "ROL";
BEGIN
  IF (r>=0) THEN
    ASSERT r > len
      REPORT "rotate is further then array size."
      SEVERITY WARNING ;
    IF (mr = 0) THEN
      result := (l);
    ELSE
      result := (ls(mr+1 to len) & ls(1 to mr));
    END IF;
  ELSE
    ASSERT FALSE
      REPORT "rotate is negative."
      SEVERITY WARNING ;
    result := (l ROR -r);
  END IF;
  RETURN result;
END "rol";

FUNCTION "ror" (l : qsim_12state_resolved_vector; r : integer)
        return qsim_12state_resolved_vector IS
        CONSTANT    len     : integer := l'length;
        ALIAS       ls      : qsim_12state_resolved_vector(1 to len) IS l;
        CONSTANT    mr      : integer := r mod len;
        -- VHDL 93 ROR
        VARIABLE result : qsim_12state_resolved_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "ROR";
BEGIN
  IF (r>=0) THEN
    ASSERT r > len
      REPORT "rotate is further then array size."
      SEVERITY WARNING ;
    IF (mr = 0) THEN
      result := (l);
    ELSE
      result := (ls(len-mr+1 to len) & ls(1 to len-mr));
    END IF;
  ELSE
    ASSERT FALSE
      REPORT "rotate is negative."
      SEVERITY WARNING ;
    result := (l ROL -r);
  END IF;
  RETURN result;
END "ror";


--   bit_resolved_and_vector

FUNCTION "sll" (l:bit_resolved_and_vector;
                r:integer) RETURN bit_resolved_and_vector IS
                CONSTANT   len    : integer := l'length;
                ALIAS      ls     : bit_resolved_and_vector(1 to len) is l;
                CONSTANT   zero   : bit_resolved_and_vector(1 to len) :=
                  (others=>'0');
        -- VHDL 93 SLL
        VARIABLE result : bit_resolved_and_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SLL";
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (ls(r+1 to len) & zero(1 to r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SRL -r);
  END IF;
  RETURN result;
END "sll";
  

FUNCTION "srl" (l : bit_resolved_and_vector; r : integer)
        return bit_resolved_and_vector IS
        CONSTANT   len      : integer := l'length;
        ALIAS      ls       : bit_resolved_and_vector(1 to len) is l;
        CONSTANT   zero     : bit_resolved_and_vector(1 to len) :=
          (others=>'0');
        -- VHDL 93 SRL
        VARIABLE result : bit_resolved_and_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SRL";
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (zero(1 to r) & ls(1 to len-r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SLL -r);
  END IF;
  RETURN result;
END "srl";


FUNCTION "sla" (l : bit_resolved_and_vector; r : integer)
        return bit_resolved_and_vector IS
        CONSTANT   len      : integer := l'length;
        alias      ls       : bit_resolved_and_vector(1 to len) is l;
        CONSTANT   zero     : bit_resolved_and_vector(1 to len) :=
          (others=>l(l'right));
        -- VHDL 93 SLA
        VARIABLE result : bit_resolved_and_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SLA";
begin
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (ls(r+1 to len) & zero(1 to r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SRA -r);
  END IF;
  RETURN result;
END "sla";

FUNCTION "sra" (l : bit_resolved_and_vector; r : integer)
      return bit_resolved_and_vector IS
      CONSTANT   len      : integer := l'length;
      ALIAS      ls       : bit_resolved_and_vector(1 to len) IS l;
      CONSTANT   sign     : bit_resolved_and_vector(1 to len) :=
        (others=>l(l'left));
        -- VHDL 93 SRA
        VARIABLE result : bit_resolved_and_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SRA";
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (sign);
    ELSE
      result := (sign(1 to r) & ls(1 to len-r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SLA -r);
  END IF;
  RETURN result;
END "sra";

FUNCTION "rol" (l : bit_resolved_and_vector; r : integer)
        return bit_resolved_and_vector IS
        CONSTANT   len      : integer := l'length;
        ALIAS      ls       : bit_resolved_and_vector(1 to len) IS l;
        CONSTANT   mr       : integer := r mod len;
        -- VHDL 93 ROL
        VARIABLE result : bit_resolved_and_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "ROL";
BEGIN
  IF (r>=0) THEN
    ASSERT r > len
      REPORT "rotate is further then array size."
      SEVERITY WARNING ;
    IF (mr = 0) THEN
      result := (l);
    ELSE
      result := (ls(mr+1 to len) & ls(1 to mr));
    END IF;
  ELSE
    ASSERT FALSE
      REPORT "rotate is negative."
      SEVERITY WARNING ;
    result := (l ROR -r);
  END IF;
  RETURN result;
END "rol";

FUNCTION "ror" (l : bit_resolved_and_vector; r : integer)
        return bit_resolved_and_vector IS
        CONSTANT   len      : integer := l'length;
        ALIAS      ls       : bit_resolved_and_vector(1 to len) IS l;
        CONSTANT   mr       : integer := r mod len;
        -- VHDL 93 ROR
        VARIABLE result : bit_resolved_and_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "ROR";
BEGIN
  IF (r>=0) THEN
    ASSERT r > len
      REPORT "rotate is further then array size."
      SEVERITY WARNING ;
    IF (mr = 0) THEN
      result := (l);
    ELSE
      result := (ls(len-mr+1 to len) & ls(1 to len-mr));
    END IF;
  ELSE
    ASSERT FALSE
      REPORT "rotate is negative."
      SEVERITY WARNING ;
    result := (l ROL -r);
  END IF;
  RETURN result;
END "ror";


--   bit_resolved_or_vector

FUNCTION "sll" (l:bit_resolved_or_vector;
                r:integer) RETURN bit_resolved_or_vector IS
                CONSTANT   len    : integer := l'length;
                ALIAS      ls     : bit_resolved_or_vector(1 to len) is l;
                CONSTANT   zero   : bit_resolved_or_vector(1 to len) :=
                  (others=>'0');
        -- VHDL 93 SLL
        VARIABLE result : bit_resolved_or_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SLL";
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (ls(r+1 to len) & zero(1 to r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SRL -r);
  END IF;
  RETURN result;
END "sll";
  

FUNCTION "srl" (l : bit_resolved_or_vector; r : integer)
        return bit_resolved_or_vector IS
        CONSTANT   len      : integer := l'length;
        ALIAS      ls       : bit_resolved_or_vector(1 to len) is l;
        CONSTANT   zero     : bit_resolved_or_vector(1 to len) :=
         (others=>'0');
        -- VHDL 93 SRL
        VARIABLE result : bit_resolved_or_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SRL";
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (zero(1 to r) & ls(1 to len-r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SLL -r);
  END IF;
  RETURN result;
END "srl";


FUNCTION "sla" (l : bit_resolved_or_vector; r : integer)
        return bit_resolved_or_vector IS
        CONSTANT   len      : integer := l'length;
        alias      ls       : bit_resolved_or_vector(1 to len) is l;
        CONSTANT   zero     : bit_resolved_or_vector(1 to len) :=
          (others=>l(l'right));
        -- VHDL 93 SLA
        VARIABLE result : bit_resolved_or_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SLA";
begin
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (zero);
    ELSE
      result := (ls(r+1 to len) & zero(1 to r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SRA -r);
  END IF;
  RETURN result;
END "sla";

FUNCTION "sra" (l : bit_resolved_or_vector; r : integer)
      return bit_resolved_or_vector IS
      CONSTANT   len      : integer := l'length;
      ALIAS      ls       : bit_resolved_or_vector(1 to len) IS l;
      CONSTANT   sign     : bit_resolved_or_vector(1 to len) :=
        (others=>l(l'left));
        -- VHDL 93 SRA
        VARIABLE result : bit_resolved_or_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SRA";
BEGIN
  IF (r>0) THEN
    IF (r >= len) THEN
      ASSERT FALSE
        REPORT "shift is further then array size."
        SEVERITY WARNING ;
      result := (sign);
    ELSE
      result := (sign(1 to r) & ls(1 to len-r));
    END IF;
  ELSIF (r=0) THEN
    result := (l);
  ELSE
    ASSERT FALSE
      REPORT "shift is negative."
      SEVERITY WARNING ;
    result := (l SLA -r);
  END IF;
  RETURN result;
END "sra";

FUNCTION "rol" (l : bit_resolved_or_vector; r : integer)
        return bit_resolved_or_vector IS
        CONSTANT   len      : integer := l'length;
        ALIAS      ls       : bit_resolved_or_vector(1 to len) IS l;
        CONSTANT   mr       : integer := r mod len;
        -- VHDL 93 ROL
        VARIABLE result : bit_resolved_or_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "ROL";
BEGIN
  IF (r>=0) THEN
    ASSERT r > len
      REPORT "rotate is further then array size."
      SEVERITY WARNING ;
    IF (mr = 0) THEN
      result := (l);
    ELSE
      result := (ls(mr+1 to len) & ls(1 to mr));
    END IF;
  ELSE
    ASSERT FALSE
      REPORT "rotate is negative."
      SEVERITY WARNING ;
    result := (l ROR -r);
  END IF;
  RETURN result;
END "rol";

FUNCTION "ror" (l : bit_resolved_or_vector; r : integer)
        return bit_resolved_or_vector IS
        CONSTANT   len      : integer := l'length;
        ALIAS      ls       : bit_resolved_or_vector(1 to len) IS l;
        CONSTANT   mr       : integer := r mod len;
        -- VHDL 93 ROR
        VARIABLE result : bit_resolved_or_vector(1 to len) ;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "ROR";
BEGIN
  IF (r>=0) THEN
    ASSERT r > len
      REPORT "rotate is further then array size."
      SEVERITY WARNING ;
    IF (mr = 0) THEN
      result := (l);
    ELSE
      result := (ls(len-mr+1 to len) & ls(1 to len-mr));
    END IF;
  ELSE
    ASSERT FALSE
      REPORT "rotate is negative."
      SEVERITY WARNING ;
    result := (l ROL -r);
  END IF;
  RETURN result;
END "ror";


--   integer

FUNCTION  "sll" (l : integer; r : integer)
	return integer IS
        VARIABLE        bl       : bit_vector(1 to IntBitSize);
        VARIABLE        ls       : integer;
        -- VHDL 93 SLL
        VARIABLE result : integer;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SLL";
BEGIN
  bl := to_bit( l, IntBitSize );
  bl := bl sll r;
  ls := to_integer( bl );
  result := (ls);
  RETURN result;
END "sll";

FUNCTION  "srl" (l : integer; r : integer)
	return integer IS
        VARIABLE        bl       : bit_vector(1 to IntBitSize);
        VARIABLE        ls       : integer;
        -- VHDL 93 SRL
        VARIABLE result : integer;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SRL";
BEGIN
  bl := to_bit( l, IntBitSize );
  bl := bl srl r;
  ls := to_integer( bl );
  result := (ls);
  RETURN result;
END "srl";

FUNCTION  "sla" (l : integer; r : integer)
        return integer IS
        VARIABLE        bl       : bit_vector(1 to IntBitSize);
        VARIABLE        ls       : integer;
        -- VHDL 93 SLA
        VARIABLE result : integer;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SLA";
BEGIN
  bl := to_bit( l, IntBitSize );
  bl := bl sla r;
  ls := to_integer( bl );
  result := (ls);
  RETURN result;
END "sla";

FUNCTION  "sra" (l : integer; r : integer)
      return integer IS
      VARIABLE        bl       : bit_vector(1 to IntBitSize);
      VARIABLE        ls       : integer;
        -- VHDL 93 SRA
        VARIABLE result : integer;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "SRA";
BEGIN
  bl := to_bit( l, IntBitSize );
  bl := bl sra r;
  ls := to_integer( bl );
  result := (ls);
  RETURN result;
END "sra";

FUNCTION  "rol" (l : integer; r : integer)
        return integer IS
        VARIABLE        bl       : bit_vector(1 to IntBitSize);
        VARIABLE        ls       : integer;
        -- VHDL 93 ROL
        VARIABLE result : integer;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "ROL";
BEGIN
  bl := to_bit( l, IntBitSize );
  bl := bl rol r;
  ls := to_integer( bl );
  result := (ls);
  RETURN result;
END "rol";

FUNCTION  "ror" (l : integer; r : integer)
        return integer IS
        VARIABLE        bl       : bit_vector(1 to IntBitSize);
        VARIABLE        ls       : integer;
        -- VHDL 93 ROR
        VARIABLE result : integer;
        ATTRIBUTE synthesis_return OF result:VARIABLE IS "ROR";
BEGIN
  bl := to_bit( l, IntBitSize );
  bl := bl ror r;
  ls := to_integer( bl );
  result := (ls);
  RETURN result;
END "ror";


END qsim_logic;
