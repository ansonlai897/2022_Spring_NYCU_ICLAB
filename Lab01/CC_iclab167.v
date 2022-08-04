module CC(
	in_n0,
	in_n1, 
	in_n2, 
	in_n3, 
        in_n4, 
	in_n5, 
	opt,
        equ,
	out_n
);
input [3:0]in_n0;
input [3:0]in_n1;
input [3:0]in_n2;
input [3:0]in_n3;
input [3:0]in_n4;
input [3:0]in_n5;
input [2:0] opt;
input equ;
output signed [9:0] out_n;
//==================================================================
// reg & wire
//==================================================================
wire signed [4:0]encoded[0:5];
wire signed [4:0]sorted[0:5];
wire signed [4:0]cumulated[0:4];

//================================================================
//    DESIGN
//================================================================

// Encode 1:signed 
assign encoded[0]=(opt[0])? {in_n0[3],in_n0}:{1'b0,in_n0};
assign encoded[1]=(opt[0])? {in_n1[3],in_n1}:{1'b0,in_n1};
assign encoded[2]=(opt[0])? {in_n2[3],in_n2}:{1'b0,in_n2};
assign encoded[3]=(opt[0])? {in_n3[3],in_n3}:{1'b0,in_n3};
assign encoded[4]=(opt[0])? {in_n4[3],in_n4}:{1'b0,in_n4};
assign encoded[5]=(opt[0])? {in_n5[3],in_n5}:{1'b0,in_n5};

// Sort 1:L2S
Sort sort(
	.in0(encoded[0]), .in1(encoded[1]), .in2(encoded[2]), .in3(encoded[3]), .in4(encoded[4]), .in5(encoded[5]),
	.flag_sort(opt[1]),
	.out0(sorted[0]), .out1(sorted[1]), .out2(sorted[2]), .out3(sorted[3]), .out4(sorted[4]), .out5(sorted[5])
);

// Cumulate
Cumulate cumulate(
	.in0(sorted[0]), .in1(sorted[1]), .in2(sorted[2]), .in3(sorted[3]), .in4(sorted[4]), .in5(sorted[5]),
	.flag_cumulate(opt[2]),
	.out_cum0(cumulated[0]), .out_cum1(cumulated[1]), .out_cum3(cumulated[2]), .out_cum4(cumulated[3]), .out_cum5(cumulated[4])
);

// Eq
Eq eq(
	.in0(cumulated[0]), .in1(cumulated[1]), .in3(cumulated[2]), .in4(cumulated[3]), .in5(cumulated[4]),
	.flag_eq(equ),
	.out_eq(out_n)
);
endmodule

//================================================================
//    Sort
//================================================================
module Sort(
    // Input signals
    in0, in1, in2, in3, in4, in5,
	// S2L or L2S
	flag_sort,
    // Output signals
    out0, out1, out2, out3, out4, out5
);
//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input signed [4:0] in0, in1, in2, in3, in4, in5;
input flag_sort;
output signed [4:0] out0, out1, out2, out3, out4, out5;
//================================================================
//    Wire & Registers 
//================================================================
wire signed [4:0]layer1[0:3];
wire signed [4:0]layer2[0:3];
wire signed [4:0]layer3[0:3];
wire signed [4:0]out_t1[0:5];
wire signed [4:0]out_t2[0:5];
wire signed [4:0]out_t3[0:5];
//================================================================
//    DESIGN
//================================================================
//
//flag_sort == 0		 S2L
// layer1
assign {out_t1[0], layer1[0]} = (in0 > in1) ? {in1, in0} : {in0, in1};
assign {layer1[1], layer1[2]} = (in2 > in3) ? {in3, in2} : {in2, in3};
assign {layer1[3], out_t1[5]} = (in4 > in5) ? {in5, in4} : {in4, in5};
assign {out_t1[1], out_t1[2]} = (layer1[0] > layer1[1]) ? {layer1[1], layer1[0]} : {layer1[0], layer1[1]};
assign {out_t1[3], out_t1[4]} = (layer1[2] > layer1[3]) ? {layer1[3], layer1[2]} : {layer1[2], layer1[3]};

// layer 2
assign {out_t2[0], layer2[0]} = (out_t1[0] > out_t1[1]) ? {out_t1[1], out_t1[0]} : {out_t1[0], out_t1[1]};
assign {layer2[1], layer2[2]} = (out_t1[2] > out_t1[3]) ? {out_t1[3], out_t1[2]} : {out_t1[2], out_t1[3]};
assign {layer2[3], out_t2[5]} = (out_t1[4] > out_t1[5]) ? {out_t1[5], out_t1[4]} : {out_t1[4], out_t1[5]};
assign {out_t2[1], out_t2[2]} = (layer2[0] > layer2[1]) ? {layer2[1], layer2[0]} : {layer2[0], layer2[1]};
assign {out_t2[3], out_t2[4]} = (layer2[2] > layer2[3]) ? {layer2[3], layer2[2]} : {layer2[2], layer2[3]};

// layer 3
assign {out_t3[0], layer3[0]} = (out_t2[0] > out_t2[1]) ? {out_t2[1], out_t2[0]} : {out_t2[0], out_t2[1]};
assign {layer3[1], layer3[2]} = (out_t2[2] > out_t2[3]) ? {out_t2[3], out_t2[2]} : {out_t2[2], out_t2[3]};
assign {layer3[3], out_t3[5]} = (out_t2[4] > out_t2[5]) ? {out_t2[5], out_t2[4]} : {out_t2[4], out_t2[5]};
assign {out_t3[1], out_t3[2]} = (layer3[0] > layer3[1]) ? {layer3[1], layer3[0]} : {layer3[0], layer3[1]};
assign {out_t3[3], out_t3[4]} = (layer3[2] > layer3[3]) ? {layer3[3], layer3[2]} : {layer3[2], layer3[3]};

//**************************************************************//
assign out5 = (flag_sort) ? out_t3[0] : out_t3[5];
assign out4 = (flag_sort) ? out_t3[1] : out_t3[4];
assign out3 = (flag_sort) ? out_t3[2] : out_t3[3];
assign out2 = (flag_sort) ? out_t3[3] : out_t3[2];
assign out1 = (flag_sort) ? out_t3[4] : out_t3[1];
assign out0 = (flag_sort) ? out_t3[5] : out_t3[0];
//**************************************************************//

endmodule


//================================================================
//    Cumulate
//================================================================
module Cumulate(
	// Input signals
    in0, in1, in2, in3, in4, in5,
	// cumulate
	flag_cumulate,
    // Output signals
    out_cum0, out_cum1, out_cum3, out_cum4, out_cum5
);
//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input signed [4:0] in0, in1, in2, in3, in4, in5;
input flag_cumulate;
output signed [4:0] out_cum0, out_cum1, out_cum3, out_cum4, out_cum5;

//================================================================
//    Wire & Registers 
//================================================================
wire signed [4:0]out_cum_t1[0:4];
wire signed [4:0]out_cum_t2[0:4];
//================================================================
//    DESIGN
//================================================================

// flag_cumulate == 0 
assign out_cum_t1[0] = in1 - in0;
assign out_cum_t1[1] = in2 - in0;
assign out_cum_t1[2] = in3 - in0;
assign out_cum_t1[3] = in4 - in0;
assign out_cum_t1[4] = in5 - in0;

// flag_cumulate == 1
assign out_cum_t2[0] = ((in0 <<< 1) + in1)/3;  	
assign out_cum_t2[1] = ((out_cum_t2[0] <<< 1) + in2)/3;  	
assign out_cum_t2[2] = ((out_cum_t2[1] <<< 1) + in3)/3;  	
assign out_cum_t2[3] = ((out_cum_t2[2] <<< 1) + in4)/3;  	
assign out_cum_t2[4] = ((out_cum_t2[3] <<< 1) + in5)/3;  	

//**************************************************************//
assign out_cum0 = (flag_cumulate) ? in0 : 0;
assign out_cum1 = (flag_cumulate) ? out_cum_t2[0] : out_cum_t1[0];
assign out_cum3 = (flag_cumulate) ? out_cum_t2[2] : out_cum_t1[2];
assign out_cum4 = (flag_cumulate) ? out_cum_t2[3] : out_cum_t1[3];
assign out_cum5 = (flag_cumulate) ? out_cum_t2[4] : out_cum_t1[4];
//**************************************************************//

endmodule

//================================================================
//    Eq
//================================================================
module Eq(
	// Input signals
    in0, in1, in3, in4, in5,
	// eq
	flag_eq,
    // Output signals
    out_eq
);
//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input signed [4:0] in0, in1, in3, in4, in5;
input flag_eq;
output signed [9:0] out_eq;
//================================================================
//    Wire & Registers 
//================================================================
wire signed [7:0]eq0, mult;
wire signed [4:0]eq1;
wire signed [11:0]ans1;
wire signed [9:0] ans[0:1];

//================================================================
//    DESIGN
//================================================================
assign eq0 = in3 + (in4 <<< 2);
assign eq1 = in1 - in0;
assign mult = (flag_eq) ? eq1 : eq0;
assign ans1 = in5 * mult;

assign ans[0] = (flag_eq) ? 0 : ans1/3;
assign ans[1] = (flag_eq && ans1[11]) ? ~ans1+1 : ans1;

//**************************************************************//
assign out_eq = (flag_eq) ? ans[1] : ans[0];
//**************************************************************//

endmodule
