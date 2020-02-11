(* fv_prop = "affine", fv_strat = "isolate", fv_order = d *)
module zero_sharing #(parameter d=1, parameter count=1) (out);

(* fv_type = "sharing", fv_count = count, fv_latency = 0 *) output [count*d-1:0] out;

assign out = {(count*d){1'b0}};

endmodule
