`timescale 1ns / 1ps
module tb_present_128();
	localparam N = 32;
	localparam Tclk = 2;
	localparam Tclkd = (Tclk/2.0);
	localparam TclkD = Tclk + 0.01;
	localparam d=2;

	`include "present_sbox_rnd.vh"

	reg [31:0] cycle_count;
	reg clk,rst,valid_in_dut;
        wire start_dut = valid_in_dut;
	always @(*) #(Tclk/2.0) clk <= ~clk;

	wire [64-1:0]    pl;
	wire [128-1:0]    key;
	assign pl = 64'h530f0f0f001f0f0f;
	assign key = 128'hff1111ffffffffffffffffffffffff00;

	wire [64*d-1:0]    MSKpl;
	wire [128*d-1:0]   MSKkey;
	wire [64-1:0] cipher_ref;
	wire [64*d-1:0] MSKcipher_dut;
	wire [64-1:0] unMSKcipher_dut;

        localparam PDSBOX = 0;
        localparam SB_DIVIDER = 2**PDSBOX;
        localparam nrnd_each = (16/SB_DIVIDER)*present_sbox_rnd/2;
        localparam nrnd_each_ks = present_sbox_rnd;

	wire v_out_ref, v_out_dut;
	wire [present_sbox_rnd*18-1:0] rnd;
        wire [nrnd_each-1:0] rnd1, rnd2;
        wire [nrnd_each_ks-1:0] rnd1_ks, rnd2_ks;
	assign rnd1 = {(nrnd_each){1'b1}};
	assign rnd2 = {(nrnd_each){1'b1}};
	assign rnd1_ks = {(nrnd_each_ks){1'b1}};
	assign rnd2_ks = {(nrnd_each_ks){1'b1}};
	//assign rnd = {(present_sbox_rnd*18){1'b1}};
        //assign rnd = { 64'h0123456789abcdef, 64'hdeadbeefcafed00d};

	always @(posedge clk) begin
		if (cycle_count != 32'hffffffff) begin
			cycle_count <= cycle_count +1;
		end
		else if (valid_in_dut) begin cycle_count <= 32'h0; end
	end


	// dut instance 
	MSKpresent_encrypt dut(clk,valid_in_dut,MSKpl,MSKkey,MSKcipher_dut,v_out_dut, rnd1, rnd2, rnd1_ks, rnd2_ks);

	genvar i;
	generate
		for(i=0; i<64; i=i+1) begin
			assign unMSKcipher_dut[i] = ^(MSKcipher_dut[d*(i+1)-1:d*i]);
		end
	endgenerate

	MSKcst #(.d(d), .count(64)) cst_mask_inst1(.cst(pl), .out(MSKpl));     //trivially extend constants with zeroes for masks
	MSKcst #(.d(d), .count(128)) cst_mask_inst3(.cst(key), .out(MSKkey));  //trivially extend constants with zeroes for masks

/*	// ref instance  - - not used - verified with a python code..
	present_128 present_clean_core(.clk(clk),
		.rst(rst),
		.valid_in(valid_in_dut),
		.plaintext(pl),
		.key(key),
		.ciphertext(cipher_ref),
		.valid_out(v_out_ref));
*/
	initial begin
`ifdef VCD_PATH
                $dumpfile(`VCD_PATH);
`else
               $dumpfile("a.vcd");
`endif
		$dumpvars(0, tb_present_128);

		cycle_count = 32'hffffffff;

		$display("init");


		clk = 0;
		valid_in_dut = 0;
		rst = 1;
                #(0.2*Tclk)

		#Tclkd;
		#TclkD;
		rst = 0;
		#Tclk;

		$display("reset finished");
		#(Tclk)
		valid_in_dut = 1;
		cycle_count = 32'h0;
		#(1*Tclk);
		valid_in_dut = 0;

		while(~v_out_dut) begin
			#Tclk;
		end
		$display("finished");

            #(Tclk) // For tool output checking
				
            #(6*Tclk) // For tool output checking
	    $finish;

	end

endmodule
