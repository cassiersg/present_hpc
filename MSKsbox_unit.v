(* fv_prop = "PINI", fv_strat = "flatten", fv_order=d *)

module MSKsbox_unit
#
(
    parameter d = 2, // Number of masking shares
    parameter PDSBOX = 0,
    parameter Nbits = 128 // Number of state bits.
)
(inp, rnd1, rnd2, clk, outp);

// Generation params (DO NOT TOUCH)
localparam AM_BUND_cols = 2**PDSBOX; // Amount of column bundles
localparam SIZE_BUND_cols = d*Nbits/AM_BUND_cols; // Size of each column bundles
localparam AM_cols = 16/AM_BUND_cols; // Amount of column per column bundles

`include "present_sbox_rnd.vh"

(* fv_type = "sharing", fv_latency = 0, fv_count=Nbits/AM_BUND_cols *)
input    [SIZE_BUND_cols-1:0]      inp;
(* fv_type = "random", fv_count=0 *) 
input [present_sbox_rnd*16/(2**PDSBOX)/2-1:0] rnd1;
(* fv_type = "random", fv_count=0 *) 
input [present_sbox_rnd*16/(2**PDSBOX)/2-1:0] rnd2;
(* fv_type = "clock" *) 
input clk;
(* fv_type = "sharing", fv_latency = 3, fv_count=Nbits/AM_BUND_cols *)
output    [SIZE_BUND_cols-1:0]      outp;


genvar i;
generate
for(i=0;i<AM_cols;i=i+1) begin: sb
    MSKpresent_sbox #(.d(d)) sbi (
        .in(inp[(i+1)*4*d-1:i*4*d]), 
        .rnd1(rnd1[i*present_sbox_rnd/2 +: present_sbox_rnd/2]),
        .rnd2(rnd2[i*present_sbox_rnd/2 +: present_sbox_rnd/2]),
        .clk(clk), 
        .out(outp[(i+1)*4*d-1:i*4*d])
    );
end
endgenerate


endmodule
