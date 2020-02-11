//`define USE_HPC1
`ifdef USE_HPC1
`include "MSKand_HPC1.vh"
`define SB_IN_LAT 2
`define MSK_AND MSKand_HPC1
`else
`include "MSKand_HPC2.vh"
`define SB_IN_LAT 0
`define MSK_AND MSKand_HPC2
`endif
localparam present_sbox_nbits=4;
localparam present_sbox_nands=4;
//localparam present_sbox_lat= 5;
localparam present_sbox_lat= 3+`SB_IN_LAT;
localparam present_sbox_tot_size= d * present_sbox_nbits;
localparam present_sbox_rnd= present_sbox_nands * and_pini_nrnd;
