(* fv_prop = "PINI", fv_strat = "composite", fv_order=d *)
module MSKpresent_sbox #(parameter d=4) (in, rnd1, rnd2, clk, out);

`include "present_sbox_rnd.vh"

(* fv_type = "sharing", fv_latency = `SB_IN_LAT, fv_count=present_sbox_nbits*)
input  [d*present_sbox_nbits-1:0] in;
(* fv_type = "sharing", fv_latency = present_sbox_lat, fv_count=present_sbox_nbits *)
output [d*present_sbox_nbits-1:0] out;
(* fv_type = "clock" *) input clk;
(* fv_type = "random", fv_count=1, fv_rnd_lat_0=0, fv_rnd_count_0=2*and_pini_nrnd *)
input [2*and_pini_nrnd-1:0] rnd1;
(* fv_type = "random", fv_count=1, fv_rnd_lat_0=1, fv_rnd_count_0=2*and_pini_nrnd *)
input [2*and_pini_nrnd-1:0] rnd2;

		// present K4D2F2 --> depth 2 and 1 on one input of the 2nd layer and to reduce delay on refresh on the critical-path
		wire [d-1:0]  temp_out3;
		// FF on the other AND input and synchronization/pipelining
			(* keep = "true" *) wire [d-1:0] q0F, q3F, q4F, q7F, x3F, x3FF, x3FFF, l1F, l1FF, l1FFF, l2F, l2FF, l3F, l3FF, l4F, l4FF, l4FFF, l5F, l5FF, l6F,  temp_out3F;

		wire  [d-1:0] l0, l1, l2, l3, l4, l5, l6, l7, l8, l9, q0, q1, q2, q3, q4, q6, q7, t0, t1, t2, t3;

		MSKreg #(d) reg1 (clk, q0, q0F);
		MSKreg #(d) reg2 (clk, q3, q3F);
		MSKreg #(d) reg3 (clk, q4, q4F);
		MSKreg #(d) reg4 (clk, q7, q7F);
		MSKreg #(d) reg5 (clk, in[d+d*(0)-1 -: d], x3F);
		MSKreg #(d) reg6 (clk, x3F, x3FF);
		MSKreg #(d) reg7 (clk, x3FF, x3FFF);
		MSKreg #(d) reg8 (clk, l1, l1F);
		MSKreg #(d) reg10 (clk, l1F, l1FF);
		MSKreg #(d) reg11 (clk, l1FF, l1FFF);
		MSKreg #(d) reg12 (clk, l2, l2F);
		MSKreg #(d) reg13 (clk, l2F, l2FF);
		MSKreg #(d) reg14 (clk, l3, l3F);
		MSKreg #(d) reg15 (clk, l3F, l3FF);
		MSKreg #(d) reg16 (clk, l4, l4F);
		MSKreg #(d) reg17 (clk, l4F, l4FF);
		MSKreg #(d) reg18 (clk, l4FF, l4FFF);
		MSKreg #(d) reg19 (clk, l5, l5F);
		MSKreg #(d) reg20 (clk, l5F, l5FF);
		MSKreg #(d) reg21 (clk, l6, l6F);
		MSKreg #(d) reg23 (clk, temp_out3, temp_out3F);
		
		`MSK_AND #(d) andg1(q0F, q1,                 rnd1[0 +: and_pini_nrnd],              clk ,t0);
		`MSK_AND #(d) andg2(q2, q3F,                 rnd2[0 +: and_pini_nrnd],              clk, t1);
		`MSK_AND #(d) andg3(q4F, in[d+d*(2)-1 -: d], rnd1[and_pini_nrnd +: and_pini_nrnd], clk, t2);
		`MSK_AND #(d) andg4(q6, q7F,                 rnd2[and_pini_nrnd +: and_pini_nrnd], clk, t3);
			
		MSKinv #(d) invg1(l0, q0);
		MSKinv #(d) invg2(in[d+d*(3)-1 -: d], q1);
		MSKinv #(d) invg3(l9, q2);
		MSKinv #(d) invg4(in[d+d*(1)-1 -: d], q4);
		MSKinv #(d) invg5(l4, l5);

		MSKxor #(d) xorg1(in[d+d*(2)-1 -: d], in[d+d*(1)-1 -: d], l0);
		MSKxor #(d) xorg2(in[d+d*(1)-1 -: d], in[d+d*(0)-1 -: d], l1);
		MSKxor #(d) xorg3(l1, in[d+d*(3)-1 -: d], l2);
		MSKxor #(d) xorg4(in[d+d*(3)-1 -: d], in[d+d*(0)-1 -: d], l3);
		MSKxor #(d) xorg5(t0, l2FF, l9);
		MSKxor #(d) xorg6(l0, l3, q3);
		MSKxor #(d) xorg7(in[d+d*(3)-1 -: d], in[d+d*(1)-1 -: d], l4);
		MSKxor #(d) xorg8(t0, t2, l6);
		MSKxor #(d) xorg9(l5FF, l6, q6);
		MSKxor #(d) xorg10(l1, in[d+d*(2)-1 -: d], q7);
		MSKxor #(d) xorg11(l6F, t3, l7);
		MSKxor #(d) xorg12(x3FFF, l7, out[d+d*(3)-1 -: d]);
		MSKxor #(d) xorg13(t1, l6F, l8);
		MSKxor #(d) xorg14(l1FFF, l8, out[d+d*(2)-1 -: d]);
		MSKxor #(d) xorg15(l4FFF, t3, out[d+d*(1)-1 -: d]);
		MSKxor #(d) xorg16(l3FF, t2, temp_out3);
		assign out[d+d*(0)-1 -: d] = temp_out3F;


	endmodule





// Repository for present and Present_inv (Dec.):

		
////    present K4D2F2(3-4) --> depth 2 and 1 on one input of the 2nd layer and to reduce delay on refresh on the critical-path

	/*assign q_0 = 1 + x_1 + x_2
	assign q_1 = 1 + x_0
	assign t_0 = q_0 * q_1
	assign q_2 = 1 + x_0 + x_2 + x_3 + t_0
	assign q_3 = x_0 + x_1 + x_2 + x_3
	assign t_1 = q_2 * q_3
	assign q_4 = 1 + x_2
	assign t_2 = q_4 * x_1
	assign q_6 = 1 + x_0 + x_2 + t_0 + t_2
	assign q_7 = x_1 + x_2 + x_3
	assign t_3 = q_6 * q_7
	assign y_0 = x_3 + t_0 + t_2 + t_3
	assign y_1 = x_2 + x_3 + t_0 + t_1 + t_2
	assign y_2 = x_0 + x_2 + t_3
	assign y_3 = x_0 + x_3 + t_2*/
		


////    present_inv with K4D2 but one AND input always a linear combination of the main inputs

////    q_0 = x_1 + x_2 + x_3
////    q_1 = 1 + x_0 + x_2
////    t_0 = q_0 * q_1
////    q_2 = 1 + x_2 + t_0
////    q_3 = x_1 + x_2
////    t_1 = q_2 * q_3
////    q_4 = 1 + x_1 + x_3
////    q_5 = 1 + x_0 + x_2
////    t_2 = q_4 * q_5
////    q_6 = x_1 + x_2 + t_0 + t_2
////    q_7 = 1 + x_2 + x_3
////    t_3 = q_6 * q_7
////    y_0 = x_0 + x_1 + x_2 + x_3 + t_1 + t_2 + t_3
////    y_1 = x_1 + x_2 + x_3 + t_1 + t_2
////    y_2 = x_0 + x_2 + x_3 + t_1
////    y_3 = x_0 + x_1 + x_2 + x_3 + t_0 + t_2
