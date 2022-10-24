(* fv_prop = "PINI", fv_strat = "composite", fv_order=d *)
module MSKpresent_encrypt #(
    // Number of masking shares
    parameter d = 2,
    // Ns - total number rounds.
    parameter Ns = 32,
    // Power (2**) Divider of the State for SBoxes - 0->16 SBoxes, 1->8, 2->4, 3->2, 4->Not supported.
    parameter PDSBOX = 0, //possible [3:0]
    parameter Nbits = 64,
    parameter NKbits = 128
)(clk, start, plaintext, key, ciphertext, valid_out, rnd1, rnd2, rnd1_ks, rnd2_ks);

`include "present_sbox_rnd.vh"

localparam IS_NOT_SERIAL = (PDSBOX==0);
localparam present_latency=IS_NOT_SERIAL ? (Ns-1)*5+1 : (Ns-1)*(2**PDSBOX+4+1) +2**PDSBOX+4+1 ;

localparam SB_DIVIDER = 2**PDSBOX;
localparam nrnd_each = (16/SB_DIVIDER)*present_sbox_rnd/2;
localparam nrnd_each_ks = present_sbox_rnd;

(* fv_type="clock" *) input clk;
(* fv_type="control" *) input start;
(* fv_type="sharing", fv_latency=`SB_IN_LAT, fv_count=Nbits *) input [d*Nbits-1:0] plaintext;
(* fv_type="sharing", fv_latency=`SB_IN_LAT, fv_count=NKbits *) input [d*NKbits-1:0] key;
(* fv_type="sharing", fv_latency=`SB_IN_LAT+present_latency, fv_count=Nbits *)
output [d*Nbits-1:0] ciphertext;
(* fv_type="control" *) output valid_out;
(* fv_type="random", fv_count=0 *) input [nrnd_each-1:0] rnd1;
(* fv_type="random", fv_count=0 *) input [nrnd_each-1:0] rnd2;
(* fv_type="random", fv_count=0 *) input [nrnd_each_ks-1:0] rnd1_ks;
(* fv_type="random", fv_count=0 *) input [nrnd_each_ks-1:0] rnd2_ks;

`ifdef USE_HPC1
    reg valid_in, start_prev;
    wire starting;
    assign starting = start | start_prev | valid_in;
    always @(posedge clk) begin
        start_prev <= start;
        valid_in <= start_prev;
    end
`else
    wire starting = start;
    wire start_prev = start;
    wire valid_in = start;
`endif




///////////////////////////////////////
/////// Computing  parameters /////////
///////////////////////////////////////

// Actual SB divider - how many chuncks to serially process.
// Actual chunk size (if PDSBOX=0: 64, 1: 32, 2: 16, 3: 8, 4: 4).
localparam SIZE_SB_CHUNK = d*Nbits/SB_DIVIDER;
// The size of the rounds iterator - used for a counter.
parameter SIZE_R_CNT = 5;
// The size of the SBox iterator - used for a counter.
parameter SIZE_S_CNT = $clog2(SB_DIVIDER);

//////////////////////////
// General Architecture //
//////////////////////////

///////// CTRL //////////

// General SBox-internal+serialization counter//
// Should be able to count up to 5 + 2**PDSBOX// 
reg [6-1:0] masking_cnt;
wire rst_masking_cnt;
// On control path - does not need special consideration for masking (not shared)
always@(posedge clk)
if(valid_in || rst_masking_cnt) 
    masking_cnt <= 0;
else
    masking_cnt <= masking_cnt + 1'b1;

reg [6-1:0] random_cnt;
wire rst_random_cnt;
// On control path - does not need special consideration for masking (not shared)
always@(posedge clk)
if(start || rst_random_cnt) 
    random_cnt <= 0;
else
    random_cnt <= random_cnt + 1'b1;



// General round counter /////////////
reg [SIZE_R_CNT-1:0] r_cnt;
wire [SIZE_R_CNT-1:0] to_r_cnt;
wire en_r_cnt;
wire last_round;

// On control path - does not need special consideration for masking (not shared)
always@(posedge clk) begin
    if(valid_in)
        r_cnt <= 0;
    else
    if(en_r_cnt) 
        r_cnt <= to_r_cnt;
    else
        r_cnt <= r_cnt;
end

    wire  [SIZE_R_CNT*d-1:0] MSK_r_cnt;  // Masked round counter
    MSKcst #(.d(d), .count(SIZE_R_CNT)) cst_mask_zeros_r_cnt(.cst((r_cnt + 1'b1)), .out(MSK_r_cnt));

////// DATAPATH //////

//---------declerations----------
wire  [NKbits*d-1:0] keyReg, to_keyReg;                 // key   reg
wire  [Nbits*d-1:0]  stReg;                             // state reg
wire  [Nbits*d-1:0]  stint1,stint3, to_stReginp;        // intermediate states
wire  [NKbits*d-1:0] kint1,kint2;                       // intermediate key-states
wire  [120*d-1:0]    kint2F, kint2FF, kint2FFF;         // for synch. due to SBox 3 pipeline stages..
	
	
//---------comb.-----------------

// Output assignment - // assign ciphertext = stint1;  
wire [d*Nbits-1:0] msk_zeros_nb;
MSKcst #(.d(d), .count(Nbits)) cst_mask_zeros(.cst({(Nbits){1'b0}}), .out(msk_zeros_nb));
MSKmux #(.d(d), .count(Nbits)) MSKmux_par_ciphertext (
    .sel(valid_out),
    .in_true(stint1),
    .in_false(msk_zeros_nb),
    .out(ciphertext)
);

// Xor add_round_key /////
MSKxor #(.d(d), .count(Nbits)) MSKxor_par_inst1 (.ina(keyReg[NKbits*d-1:(NKbits/2)*d]), .inb(stReg), .out(stint1));

wire [NKbits*d-1:0] k_inp_mux_FF;
// key update	
assign kint1               = {k_inp_mux_FF[67*d-1:0], k_inp_mux_FF[128*d-1:67*d]}; // Rotate key 61 bits to the left
assign kint2[62*d-1:0 ]    = kint1[62*d-1:0 ];
// Xor round /////////////
MSKxor #(.d(d), .count(5))    MSKxor_par_inst2 (.ina(kint1[67*d-1:62*d]), .inb(MSK_r_cnt), .out(kint2[67*d-1:62*d]));
assign kint2[120*d-1:67*d] = kint1[120*d-1:67*d];


//---------instantiations--------------------
	
	// Sboxes unit  - Plaintext DATAPATH /////////////
		wire [SIZE_SB_CHUNK-1:0] SBin, SBout;
		MSKsbox_unit #(.d(d), .PDSBOX(PDSBOX), .Nbits(Nbits)) MSKsbox_unit_inst(
			.inp(SBin),
			.rnd1(rnd1),
			.rnd2(rnd2),
			.clk(clk),
			.outp(SBout)
		);
		
	// Shift_register_sboxes
	genvar i;
	generate
		 for (i=0;i<SB_DIVIDER;i=i+1) begin: GenSHREG
		 	(* keep = "true" *)  wire [SIZE_SB_CHUNK-1:0] serializedSBoxOutpSHREG;
				if (i==0)
					MSKreg_rst #(.d(d), .count(SIZE_SB_CHUNK/d)) MSKreg_par_state_inst(
						clk,
						valid_out,//1'b0,   // Added to solve "late-computations" when SB_DIVIDER == 3
						SBout,
						serializedSBoxOutpSHREG
					);
				else 
					MSKreg_rst #(.d(d), .count(SIZE_SB_CHUNK/d)) MSKreg_par_state_inst(
						clk,
						valid_out,//1'b0,   // Added to solve "late-computations" when SB_DIVIDER == 2
						GenSHREG[i-1].serializedSBoxOutpSHREG,
						serializedSBoxOutpSHREG
					);
		 end
	endgenerate
	
	(* keep = "true" *)  reg [Nbits*d-1:0] GenConcetSHreg;
	generate
	if (SB_DIVIDER != 1) begin
		 for (i=0; i<SB_DIVIDER; i=i+1) begin: GenConcetSHIFTREG
			always @(*)
				begin
					GenConcetSHreg[Nbits*d-(i)*Nbits*d/SB_DIVIDER-1 -: Nbits*d/SB_DIVIDER] = GenSHREG[i].serializedSBoxOutpSHREG;
				end
			end
	end
	else begin
		always @(*) begin
				GenConcetSHreg <= SBout;
				end
		end
	endgenerate
	
	
	// Permutation unit /////////////
	wire [d*Nbits-1:0] merge_to_perm;
		MSKpermbox #(d) MSKpermbox_inst (GenConcetSHreg, stint3);
		

	// Load data
	wire [Nbits*d-1:0] to_stReg;
	MSKmux #(.d(d), .count(Nbits)) MSKmux_par_inst_stReg (
		.sel(valid_in),
		.in_true(plaintext[Nbits*d-1 : 0]),
		.in_false(stint3[Nbits*d-1 : 0]),
		.out(to_stReg)
	);


	MSKregEn_rst #(.d(d), .count(Nbits)) MSKreg_par_stReg(
		clk,
		(valid_out),                       // reset
		(valid_in | rst_masking_cnt ),     // enable
		to_stReg,
		stReg
	);
	

	// Manage Sboxes Inputs as a function of PDSBOX 
wire [SIZE_SB_CHUNK-1:0] zero_sharing_SIZE_SB_CHUNK;
zero_sharing #(.d(d), .count(SIZE_SB_CHUNK/d)) zero_sharing_state (.out(zero_sharing_SIZE_SB_CHUNK)); 

	generate
		if (SB_DIVIDER == 2) begin
	
       		        wire [SIZE_SB_CHUNK-1:0] to_SBinp_intermediate;
			MSKmux #(.d(d), .count(SIZE_SB_CHUNK/d)) MSKmux_par_inst_SBinp_inp (
				.sel(masking_cnt == 0),
				.in_true(stint1[SIZE_SB_CHUNK-1 : 0]),
				.in_false(stint1[(2)*SIZE_SB_CHUNK-1 : (1)*SIZE_SB_CHUNK]),
				.out(to_SBinp_intermediate)
			);
			wire [SIZE_SB_CHUNK-1:0] to_SBinp_intermediate_zero;
			MSKmux #(.d(d), .count(SIZE_SB_CHUNK/d)) MSKmux_par_inst_SBinp_inp_zero (
				.sel(masking_cnt > SB_DIVIDER-1),
				.in_true(zero_sharing_SIZE_SB_CHUNK),
				.in_false(to_SBinp_intermediate),
				.out(to_SBinp_intermediate_zero)
			);
			MSKreg_rst #(.d(d), .count(SIZE_SB_CHUNK/d)) MSKreg_par_SBinp1(
				clk,
				(valid_out),               // reset
				to_SBinp_intermediate_zero,
				SBin
			);

			end
		else
		if (SB_DIVIDER == 4) begin
			wire [2*SIZE_SB_CHUNK-1:0] to_SBinp_intermediate1;
			MSKmux #(.d(d), .count(2*SIZE_SB_CHUNK/d)) MSKmux_par_inst_SBinp_inp1 (
				.sel(masking_cnt < SB_DIVIDER/2),
				.in_true(stint1[2*SIZE_SB_CHUNK-1 : 0]),
				.in_false(stint1[(4)*SIZE_SB_CHUNK-1 : (2)*SIZE_SB_CHUNK]),
				.out(to_SBinp_intermediate1)
			);
			wire [SIZE_SB_CHUNK-1:0] to_SBinp_intermediate2;
			MSKmux #(.d(d), .count(SIZE_SB_CHUNK/d)) MSKmux_par_inst_SBinp_inp2 (
				.sel(masking_cnt[0] == 0),
				.in_true(to_SBinp_intermediate1[SIZE_SB_CHUNK-1 : 0]),
				.in_false(to_SBinp_intermediate1[(2)*SIZE_SB_CHUNK-1 : (1)*SIZE_SB_CHUNK]),
				.out(to_SBinp_intermediate2)
			);
			wire [SIZE_SB_CHUNK-1:0] to_SBinp_intermediate_zero;
			MSKmux #(.d(d), .count(SIZE_SB_CHUNK/d)) MSKmux_par_inst_SBinp_inp_zero (
				.sel(masking_cnt > SB_DIVIDER-1),
				.in_true(zero_sharing_SIZE_SB_CHUNK),
				.in_false(to_SBinp_intermediate2),
				.out(to_SBinp_intermediate_zero)
			);
			MSKreg_rst #(.d(d), .count(SIZE_SB_CHUNK/d)) MSKreg_par_SBinp1(
				clk,
				( valid_out),                // reset
				to_SBinp_intermediate_zero,
				SBin
			);
			end
		else
		if (SB_DIVIDER == 8) begin
				wire [4*SIZE_SB_CHUNK-1:0] to_SBinp_intermediate1;
				MSKmux #(.d(d), .count(4*SIZE_SB_CHUNK/d)) MSKmux_par_inst_SBinp_inp1 (
					.sel(masking_cnt < SB_DIVIDER/2 ),
					.in_true(stint1[4*SIZE_SB_CHUNK-1 : 0]),
					.in_false(stint1[(8)*SIZE_SB_CHUNK-1 : (4)*SIZE_SB_CHUNK]),
					.out(to_SBinp_intermediate1)
				);
				wire [2*SIZE_SB_CHUNK-1:0] to_SBinp_intermediate2;
				MSKmux #(.d(d), .count(2*SIZE_SB_CHUNK/d)) MSKmux_par_inst_SBinp_inp2 (
					.sel(masking_cnt[1] == 0),
					.in_true(to_SBinp_intermediate1[2*SIZE_SB_CHUNK-1 : 0]),
					.in_false(to_SBinp_intermediate1[(4)*SIZE_SB_CHUNK-1 : (2)*SIZE_SB_CHUNK]),
					.out(to_SBinp_intermediate2)
				);
				wire [SIZE_SB_CHUNK-1:0] to_SBinp_intermediate3;
				MSKmux #(.d(d), .count(SIZE_SB_CHUNK/d)) MSKmux_par_inst_SBinp_inp3 (
					.sel(masking_cnt[0] == 0),
					.in_true(to_SBinp_intermediate2[SIZE_SB_CHUNK-1 : 0]),
					.in_false(to_SBinp_intermediate2[(2)*SIZE_SB_CHUNK-1 : (1)*SIZE_SB_CHUNK]),
					.out(to_SBinp_intermediate3)
				);
				wire [SIZE_SB_CHUNK-1:0] to_SBinp_intermediate_zero;
				MSKmux #(.d(d), .count(SIZE_SB_CHUNK/d)) MSKmux_par_inst_SBinp_inp_zero (
					.sel(masking_cnt > SB_DIVIDER-1),
					.in_true(zero_sharing_SIZE_SB_CHUNK),
					.in_false(to_SBinp_intermediate3),
					.out(to_SBinp_intermediate_zero)
				);
				MSKreg_rst #(.d(d), .count(SIZE_SB_CHUNK/d)) MSKreg_par_SBinp1(
					clk,
					(  valid_out),                // reset
					to_SBinp_intermediate_zero,
					SBin
				);					
				end
			else
			begin
				wire [SIZE_SB_CHUNK-1:0] to_SBinp_intermediate;
				MSKmux #(.d(d), .count(SIZE_SB_CHUNK/d)) MSKmux_par_inst_SBinp_inp (
					.sel(masking_cnt == 0),
					.in_true(stint1[SIZE_SB_CHUNK-1 : 0]),
					.in_false(zero_sharing_SIZE_SB_CHUNK),
					.out(to_SBinp_intermediate)
				);
				MSKreg_rst #(.d(d), .count(SIZE_SB_CHUNK/d)) MSKreg_par_SBinp1(
					clk,
					(valid_out),             //reset
					to_SBinp_intermediate,
					SBin
				);
			end
	endgenerate

	// 2*SBox for key scheduler
		MSKpresent_sbox #(d) MSKsbox_inst_k1 (kint1[124*d-1:120*d], rnd1_ks[2*and_pini_nrnd-1 : 0] , rnd2_ks[2*and_pini_nrnd-1 : 0] , clk, kint2[124*d-1:120*d]);
		MSKpresent_sbox #(d) MSKsbox_inst_k2 (kint1[128*d-1:124*d], rnd1_ks[4*and_pini_nrnd-1 : 2*and_pini_nrnd] , rnd2_ks[4*and_pini_nrnd-1 : 2*and_pini_nrnd] , clk, kint2[128*d-1:124*d]);

    MSKreg #(.d(d), .count(120)) MSKreg_par_keySc_ShReg1(
        clk,
        kint2[120*d-1:0],
        kint2F
    );
    MSKreg #(.d(d), .count(120)) MSKreg_par_keySc_ShReg2(
        clk,
        kint2F,
        kint2FF
    );
    MSKreg #(.d(d), .count(120)) MSKreg_par_keySc_ShReg3(
        clk,
        kint2FF,
        kint2FFF
    );

	// shift_register_key - for all key bits as a function of the PDSBOX needed
	generate
		 for (i=0;i<SB_DIVIDER;i=i+1) begin: GenKSHREG
		 	(* keep = "true" *)  wire [NKbits*d-1:0] keyReg_SHREG;
				if (i==0)
					MSKreg #(.d(d), .count(NKbits)) MSKreg_par_key_inst(
						clk,
						{kint2[128*d-1:120*d], kint2FFF},
						keyReg_SHREG
					);
				else 
					MSKreg #(.d(d), .count(NKbits)) MSKreg_par_key_inst(
						clk,
						GenKSHREG[i-1].keyReg_SHREG,
						keyReg_SHREG
					);
		 end
	endgenerate
	
	(* keep = "true" *) reg [NKbits*d-1:0] GenConcetkey_SHreg;
	generate
	if (SB_DIVIDER != 1) begin
			always @(*)
				begin
					GenConcetkey_SHreg <= GenKSHREG[SB_DIVIDER-1].keyReg_SHREG;
				end
	end
	else begin
		always @(*) begin
				GenConcetkey_SHreg <= {kint2[128*d-1:120*d], kint2FFF};
				end
		end
	endgenerate

	// Load key
	wire [NKbits*d-1:0] zero_sharing_key;
	zero_sharing #(.d(d), .count(NKbits)) zero_sharing_key_inst (.out(zero_sharing_key)); 
	wire [NKbits*d-1:0] to_k_inp_mux_FF;
			MSKmux #(.d(d), .count(NKbits)) MSKmux_par_inst_key_inp (
				.sel(valid_in ),
				.in_true(key),
				.in_false(GenConcetkey_SHreg),
				.out(to_keyReg)
			);

			MSKregEn_rst #(.d(d), .count(NKbits)) MSKreg_par_keyReg(
				clk,
				( last_round & ( masking_cnt == 1)), // reset
				(valid_in | rst_masking_cnt),        // enable
				to_keyReg,
				keyReg
			);

	// "zero" key when not needed..
			MSKmux #(.d(d), .count(NKbits)) MSKmux_par_inst_key_inp_zero (
				.sel(masking_cnt == 0),
				.in_true(keyReg),
				.in_false(zero_sharing_key),
				.out(to_k_inp_mux_FF)
			);
			MSKreg_rst #(.d(d), .count(NKbits)) MSKreg_par_key_zeroed(
				clk,
				last_round,      //reset
				to_k_inp_mux_FF,
				k_inp_mux_FF
			);

	
///////////////////////////
// Specific Architecture //
///////////////////////////

// Validity signal architecture /////////////
reg in_process, in_process_delayed;
wire to_in_process, end_process;

// On control path - does not need special consideration for masking (not shared)
assign to_in_process = (in_process & (~end_process)) | valid_in;

always@(posedge clk) begin
    in_process <= to_in_process;
    in_process_delayed <= in_process;
end

	assign valid_out = starting ? 0 : in_process_delayed & (~in_process);


generate
if(IS_NOT_SERIAL) begin
    // CTRL
    // On control path - does not need special consideration for masking (not shared)
    assign to_r_cnt = valid_in ? {SIZE_R_CNT{1'b0}} : r_cnt +1'b1;
    assign en_r_cnt = (masking_cnt == 2**PDSBOX+3) | valid_in;
    assign last_round = starting ? 0 : (r_cnt == (Ns-2));
    assign end_process = last_round & ( masking_cnt == SB_DIVIDER+3);
    assign rst_masking_cnt = en_r_cnt;
    assign rst_random_cnt = (random_cnt == 2**PDSBOX+3);

    // DATAPATH

end else begin // IS_SERIAL
    // CTRL
    // On control path - does not need special consideration for masking (not shared)
    wire end_SB = (masking_cnt == SB_DIVIDER+3+1);
    wire end_round = end_SB;
    assign last_round = starting ? 0: (r_cnt == (Ns-1));

    assign to_r_cnt = valid_in ? {SIZE_R_CNT{1'b0}} : r_cnt +1'b1;
    assign en_r_cnt = end_round | valid_in;
    assign end_process = last_round & ( masking_cnt == SB_DIVIDER+3);
    assign rst_masking_cnt = end_round;
    assign rst_random_cnt = (random_cnt == SB_DIVIDER+3+1);
end
endgenerate
	
endmodule

