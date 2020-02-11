(* fv_prop = "affine", fv_strat = "flatten", fv_order = d *)
module MSKreg_rst #(parameter d=1, parameter count=1) (clk, rst, in, out);


(* fv_type = "clock" *)   input clk;
(* fv_type = "control" *) input rst;
(* fv_type = "sharing", fv_latency = 0 *) input  [count*d-1:0] in;
(* fv_type = "sharing", fv_latency = 1 *) output [count*d-1:0] out;

	wire [count*d-1:0] inner_in;

        wire [count*d-1:0] msk_zeros_1bit;
        MSKcst #(.d(d), .count(count)) cst_mask_zeros_1bit(.cst({(count){1'b0}}), .out(msk_zeros_1bit));

        MSKmux #(.d(d), .count(count)) mux_rst (.sel(rst), .in_true(msk_zeros_1bit), .in_false(in), .out(inner_in));
        MSKreg #(.d(d), .count(count)) inner(.clk(clk), .in(inner_in), .out(out));

endmodule
