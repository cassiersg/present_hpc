(* fv_strat = "flatten" *)
module MSKpermbox #(parameter d=1) (in, out);

	input  [64*d-1:0] in;
	output [64*d-1:0] out;

			genvar i;
			generate
			for(i=0; i<63; i=i+1)
				begin: permbundelI
					assign out[(((i*16) % 63)+1)*d-1  -: d] = in[(i+1)*d-1  -: d];
				end
			endgenerate
			assign out[(63+1)*d-1  -: d] = in[(63+1)*d-1  -: d];

endmodule
