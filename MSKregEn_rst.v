(* fv_prop = "affine", fv_strat = "flatten", fv_order = d *)
module MSKregEn_rst #(parameter d=1, parameter count=1) (clk, rst, en, in, out);

(* fv_type = "clock" *)   input clk;	
(* fv_type = "control" *) input rst;	
(* fv_type = "control" *) input en;
(* fv_type = "sharing", fv_latency = 0 *) input  [count*d-1:0] in;	
(* fv_type = "sharing", fv_latency = 1 *) output [count*d-1:0] out;

wire [count*d-1:0] reg_in;

MSKmux #(.d(d), .count(count)) mux (.sel(en), .in_true(in), .in_false(out), .out(reg_in));
MSKreg_rst #(.d(d), .count(count)) state_reg (.clk(clk), .rst(rst), .in(reg_in), .out(out));

endmodule 

