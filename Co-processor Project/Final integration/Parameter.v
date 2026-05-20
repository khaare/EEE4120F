//parameters are verilog constructs that allow a module to be reused with a different specification
// What i need to use : Verilog macros - they allow you to define a piece of code that can be reused throught the design

// Syntax - `define MACRO_NAME [(arguments)] macro_body
 
`ifndef PARAMETER_H_
`define PARAMETER_H_

`define COL       16
`define ROW_I     16
`define ROW_D      8

`define SIM_TIME  #140

`define DMEM_LOG  "./waves/dmem_log.txt"

`endif