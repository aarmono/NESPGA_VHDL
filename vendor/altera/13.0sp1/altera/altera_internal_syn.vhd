-----------------------------------------------------------------------------
--                                                                         --
-- Copyright (c) 2003 by Altera Corp.  All rights reserved.                --
--                                                                         --
--                                                                         --
--  Description:  Declares utility package for internal Altera synthesis   --
--                support.                                                 --
--                                                                         --
--                                                                         --
--    *** USER DESIGNS SHOULD NOT INCLUDE THIS PACKAGE DIRECTLY ***        --  
--                                                                         --
------------------------------------------------------------------------------

PACKAGE altera_internal_syn is

  -- Specfies a built-in pragma function that should replace a user-defined
  -- subprogram during synthesis.  
  ATTRIBUTE synthesis_return : STRING;

  -- If a subprogram specifies a synthesis_return attribute, it may also
  -- use these additional attributes to fine-tune the behavior of a built-in
  -- function.
  
  -- Specifies the method for calculating the size of a unary or binary
  -- built-in pragma function's result.  The following values are supported:
  --
  -- LEFT:             Use the size of the left operand 
  -- RIGHT:            Use the size of the right operand
  -- MAX_LEFT_RIGHT:   Use the maximum of the left and right operands
  ATTRIBUTE synthesis_result_size : STRING;
  
  -- Flag that indicates if a type or an argument/result of a built-in pragma
  -- function is signed (TRUE) or unsigned (FALSE).  
  ATTRIBUTE is_signed : BOOLEAN;

  -- Flag that indicates if truncation should preserve the sign bit
  attribute signed_truncation : BOOLEAN;
  
END altera_internal_syn;

