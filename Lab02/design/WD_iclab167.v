//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : WD.v
//   Module Name : WD
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module WD(
    // Input signals
    clk,
    rst_n,
    in_valid,
    keyboard,
    answer,
    weight,
    match_target,
    // Output signals
    out_valid,
    result,
    out_value
);
// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [4:0] keyboard, answer;
input [3:0] weight;
input [2:0] match_target;
output reg out_valid;
output reg [4:0]  result;
output reg [10:0] out_value;

// ===============================================================
// Parameters & Integer Declaration
// ===============================================================

parameter s_idle                = 'd0;
parameter s_input               = 'd1;
parameter s_combination         = 'd2;
parameter s_permutaion          = 'd3;
parameter s_calculate           = 'd4;
parameter s_replace             = 'd5;
parameter s_corner1             = 'd6;
parameter s_corner2             = 'd7;
parameter s_output              = 'd8;

// ===============================================================
// Wire & Reg Declaration
// ===============================================================
// state
reg [3:0] current_state, next_state;

// input
reg [4:0] keyboard_data [0:7];
reg [4:0] answer_data [0:4];
reg [2:0] target_data [0:4];
reg [3:0] weight_data [0:4];

// counter
reg [3:0] in_out_cnt;
wire [3:0] in_cnt_temp;

// output temp
reg [4:0] result_arr [0:4];
reg [10:0] out_value_temp;

// s_permutation
wire [2:0] B [0:119][0:4]; //5!
reg [7:0] cnt_perm;        //120
reg [4:0] perm [0:4];

// s_combination
wire [3:0] C [0:55][0:4];  //C8,5
reg [6:0] cnt_com;         //56
reg [4:0] com [0:4];


// s_check_combination
wire [2:0]total_AB_combination;
wire [2:0]total_AB;
assign total_AB = target_data[0] + target_data[1];
assign total_AB_combination =	(keyboard_data[C[cnt_com][0]] == answer_data[0]) + (keyboard_data[C[cnt_com][0]] == answer_data[1]) + (keyboard_data[C[cnt_com][0]] == answer_data[2]) + (keyboard_data[C[cnt_com][0]] == answer_data[3]) + (keyboard_data[C[cnt_com][0]] == answer_data[4]) +
								(keyboard_data[C[cnt_com][1]] == answer_data[0]) + (keyboard_data[C[cnt_com][1]] == answer_data[1]) + (keyboard_data[C[cnt_com][1]] == answer_data[2]) + (keyboard_data[C[cnt_com][1]] == answer_data[3]) + (keyboard_data[C[cnt_com][1]] == answer_data[4]) +
								(keyboard_data[C[cnt_com][2]] == answer_data[0]) + (keyboard_data[C[cnt_com][2]] == answer_data[1]) + (keyboard_data[C[cnt_com][2]] == answer_data[2]) + (keyboard_data[C[cnt_com][2]] == answer_data[3]) + (keyboard_data[C[cnt_com][2]] == answer_data[4]) +
								(keyboard_data[C[cnt_com][3]] == answer_data[0]) + (keyboard_data[C[cnt_com][3]] == answer_data[1]) + (keyboard_data[C[cnt_com][3]] == answer_data[2]) + (keyboard_data[C[cnt_com][3]] == answer_data[3]) + (keyboard_data[C[cnt_com][3]] == answer_data[4]) +
								(keyboard_data[C[cnt_com][4]] == answer_data[0]) + (keyboard_data[C[cnt_com][4]] == answer_data[1]) + (keyboard_data[C[cnt_com][4]] == answer_data[2]) + (keyboard_data[C[cnt_com][4]] == answer_data[3]) + (keyboard_data[C[cnt_com][4]] == answer_data[4]);

// s_check
wire [2:0]cnt_A;
wire [2:0]cnt_B;

assign cnt_A =	(answer_data[0] == com[B[cnt_perm][0]]) + (answer_data[1] == com[B[cnt_perm][1]]) + (answer_data[2] == com[B[cnt_perm][2]]) + (answer_data[3] == com[B[cnt_perm][3]]) + (answer_data[4] == com[B[cnt_perm][4]]);
assign cnt_B =	(answer_data[0] == com[B[cnt_perm][1]]) + (answer_data[0] == com[B[cnt_perm][2]]) + (answer_data[0] == com[B[cnt_perm][3]]) + (answer_data[0] == com[B[cnt_perm][4]]) +
				(answer_data[1] == com[B[cnt_perm][0]]) + (answer_data[1] == com[B[cnt_perm][2]]) + (answer_data[1] == com[B[cnt_perm][3]]) + (answer_data[1] == com[B[cnt_perm][4]]) +
				(answer_data[2] == com[B[cnt_perm][0]]) + (answer_data[2] == com[B[cnt_perm][1]]) + (answer_data[2] == com[B[cnt_perm][3]]) + (answer_data[2] == com[B[cnt_perm][4]]) +
				(answer_data[3] == com[B[cnt_perm][0]]) + (answer_data[3] == com[B[cnt_perm][1]]) + (answer_data[3] == com[B[cnt_perm][2]]) + (answer_data[3] == com[B[cnt_perm][4]]) +
				(answer_data[4] == com[B[cnt_perm][0]]) + (answer_data[4] == com[B[cnt_perm][1]]) + (answer_data[4] == com[B[cnt_perm][2]]) + (answer_data[4] == com[B[cnt_perm][3]]);

// s_calculate
reg [10:0] out_value_1 [0:1];

// s_corner1
reg [10:0] out_value_temp_1;

// s_corner2
reg [2:0] cnt_corner2;

// debug
reg c2_swap;
reg c2_flag;
reg c1_flag;

// 5!
assign {B[0][0], B[0][1], B[0][2], B[0][3], B[0][4]} = {3'd2, 3'd1, 3'd4, 3'd3, 3'd0};
assign {B[1][0], B[1][1], B[1][2], B[1][3], B[1][4]} = {3'd1, 3'd2, 3'd4, 3'd3, 3'd0};
assign {B[2][0], B[2][1], B[2][2], B[2][3], B[2][4]} = {3'd4, 3'd2, 3'd1, 3'd3, 3'd0};
assign {B[3][0], B[3][1], B[3][2], B[3][3], B[3][4]} = {3'd2, 3'd4, 3'd1, 3'd3, 3'd0};
assign {B[4][0], B[4][1], B[4][2], B[4][3], B[4][4]} = {3'd1, 3'd4, 3'd2, 3'd3, 3'd0};
assign {B[5][0], B[5][1], B[5][2], B[5][3], B[5][4]} = {3'd4, 3'd1, 3'd2, 3'd3, 3'd0};				 
assign {B[6][0], B[6][1], B[6][2], B[6][3], B[6][4]} = {3'd0, 3'd1, 3'd2, 3'd3, 3'd4};
assign {B[7][0], B[7][1], B[7][2], B[7][3], B[7][4]} = {3'd1, 3'd0, 3'd2, 3'd3, 3'd4};
assign {B[8][0], B[8][1], B[8][2], B[8][3], B[8][4]} = {3'd2, 3'd0, 3'd1, 3'd3, 3'd4};
assign {B[9][0], B[9][1], B[9][2], B[9][3], B[9][4]} = {3'd0, 3'd2, 3'd1, 3'd3, 3'd4};
assign {B[10][0], B[10][1], B[10][2], B[10][3], B[10][4]} = {3'd1, 3'd2, 3'd0, 3'd3, 3'd4};
assign {B[11][0], B[11][1], B[11][2], B[11][3], B[11][4]} = {3'd2, 3'd1, 3'd0, 3'd3, 3'd4};
assign {B[12][0], B[12][1], B[12][2], B[12][3], B[12][4]} = {3'd3, 3'd1, 3'd0, 3'd2, 3'd4};
assign {B[13][0], B[13][1], B[13][2], B[13][3], B[13][4]} = {3'd1, 3'd3, 3'd0, 3'd2, 3'd4};
assign {B[14][0], B[14][1], B[14][2], B[14][3], B[14][4]} = {3'd0, 3'd3, 3'd1, 3'd2, 3'd4};
assign {B[15][0], B[15][1], B[15][2], B[15][3], B[15][4]} = {3'd3, 3'd0, 3'd1, 3'd2, 3'd4};
assign {B[16][0], B[16][1], B[16][2], B[16][3], B[16][4]} = {3'd1, 3'd0, 3'd3, 3'd2, 3'd4};
assign {B[17][0], B[17][1], B[17][2], B[17][3], B[17][4]} = {3'd0, 3'd1, 3'd3, 3'd2, 3'd4};
assign {B[18][0], B[18][1], B[18][2], B[18][3], B[18][4]} = {3'd0, 3'd2, 3'd3, 3'd1, 3'd4};
assign {B[19][0], B[19][1], B[19][2], B[19][3], B[19][4]} = {3'd2, 3'd0, 3'd3, 3'd1, 3'd4};
assign {B[20][0], B[20][1], B[20][2], B[20][3], B[20][4]} = {3'd3, 3'd0, 3'd2, 3'd1, 3'd4};
assign {B[21][0], B[21][1], B[21][2], B[21][3], B[21][4]} = {3'd0, 3'd3, 3'd2, 3'd1, 3'd4};
assign {B[22][0], B[22][1], B[22][2], B[22][3], B[22][4]} = {3'd2, 3'd3, 3'd0, 3'd1, 3'd4};
assign {B[23][0], B[23][1], B[23][2], B[23][3], B[23][4]} = {3'd3, 3'd2, 3'd0, 3'd1, 3'd4};
assign {B[24][0], B[24][1], B[24][2], B[24][3], B[24][4]} = {3'd3, 3'd2, 3'd1, 3'd0, 3'd4};
assign {B[25][0], B[25][1], B[25][2], B[25][3], B[25][4]} = {3'd2, 3'd3, 3'd1, 3'd0, 3'd4};
assign {B[26][0], B[26][1], B[26][2], B[26][3], B[26][4]} = {3'd1, 3'd3, 3'd2, 3'd0, 3'd4};
assign {B[27][0], B[27][1], B[27][2], B[27][3], B[27][4]} = {3'd3, 3'd1, 3'd2, 3'd0, 3'd4};
assign {B[28][0], B[28][1], B[28][2], B[28][3], B[28][4]} = {3'd2, 3'd1, 3'd3, 3'd0, 3'd4};
assign {B[29][0], B[29][1], B[29][2], B[29][3], B[29][4]} = {3'd1, 3'd2, 3'd3, 3'd0, 3'd4};
assign {B[30][0], B[30][1], B[30][2], B[30][3], B[30][4]} = {3'd4, 3'd2, 3'd3, 3'd0, 3'd1};
assign {B[31][0], B[31][1], B[31][2], B[31][3], B[31][4]} = {3'd2, 3'd4, 3'd3, 3'd0, 3'd1};
assign {B[32][0], B[32][1], B[32][2], B[32][3], B[32][4]} = {3'd3, 3'd4, 3'd2, 3'd0, 3'd1};
assign {B[33][0], B[33][1], B[33][2], B[33][3], B[33][4]} = {3'd4, 3'd3, 3'd2, 3'd0, 3'd1};
assign {B[34][0], B[34][1], B[34][2], B[34][3], B[34][4]} = {3'd2, 3'd3, 3'd4, 3'd0, 3'd1};
assign {B[35][0], B[35][1], B[35][2], B[35][3], B[35][4]} = {3'd3, 3'd2, 3'd4, 3'd0, 3'd1};
assign {B[36][0], B[36][1], B[36][2], B[36][3], B[36][4]} = {3'd0, 3'd2, 3'd4, 3'd3, 3'd1};
assign {B[37][0], B[37][1], B[37][2], B[37][3], B[37][4]} = {3'd2, 3'd0, 3'd4, 3'd3, 3'd1};
assign {B[38][0], B[38][1], B[38][2], B[38][3], B[38][4]} = {3'd4, 3'd0, 3'd2, 3'd3, 3'd1};
assign {B[39][0], B[39][1], B[39][2], B[39][3], B[39][4]} = {3'd0, 3'd4, 3'd2, 3'd3, 3'd1};
assign {B[40][0], B[40][1], B[40][2], B[40][3], B[40][4]} = {3'd2, 3'd4, 3'd0, 3'd3, 3'd1};
assign {B[41][0], B[41][1], B[41][2], B[41][3], B[41][4]} = {3'd4, 3'd2, 3'd0, 3'd3, 3'd1};
assign {B[42][0], B[42][1], B[42][2], B[42][3], B[42][4]} = {3'd4, 3'd3, 3'd0, 3'd2, 3'd1};
assign {B[43][0], B[43][1], B[43][2], B[43][3], B[43][4]} = {3'd3, 3'd4, 3'd0, 3'd2, 3'd1};
assign {B[44][0], B[44][1], B[44][2], B[44][3], B[44][4]} = {3'd0, 3'd4, 3'd3, 3'd2, 3'd1};
assign {B[45][0], B[45][1], B[45][2], B[45][3], B[45][4]} = {3'd4, 3'd0, 3'd3, 3'd2, 3'd1};
assign {B[46][0], B[46][1], B[46][2], B[46][3], B[46][4]} = {3'd3, 3'd0, 3'd4, 3'd2, 3'd1};
assign {B[47][0], B[47][1], B[47][2], B[47][3], B[47][4]} = {3'd0, 3'd3, 3'd4, 3'd2, 3'd1};
assign {B[48][0], B[48][1], B[48][2], B[48][3], B[48][4]} = {3'd0, 3'd3, 3'd2, 3'd4, 3'd1};
assign {B[49][0], B[49][1], B[49][2], B[49][3], B[49][4]} = {3'd3, 3'd0, 3'd2, 3'd4, 3'd1};
assign {B[50][0], B[50][1], B[50][2], B[50][3], B[50][4]} = {3'd2, 3'd0, 3'd3, 3'd4, 3'd1};
assign {B[51][0], B[51][1], B[51][2], B[51][3], B[51][4]} = {3'd0, 3'd2, 3'd3, 3'd4, 3'd1};
assign {B[52][0], B[52][1], B[52][2], B[52][3], B[52][4]} = {3'd3, 3'd2, 3'd0, 3'd4, 3'd1};
assign {B[53][0], B[53][1], B[53][2], B[53][3], B[53][4]} = {3'd2, 3'd3, 3'd0, 3'd4, 3'd1};
assign {B[54][0], B[54][1], B[54][2], B[54][3], B[54][4]} = {3'd1, 3'd3, 3'd0, 3'd4, 3'd2};
assign {B[55][0], B[55][1], B[55][2], B[55][3], B[55][4]} = {3'd3, 3'd1, 3'd0, 3'd4, 3'd2};
assign {B[56][0], B[56][1], B[56][2], B[56][3], B[56][4]} = {3'd0, 3'd1, 3'd3, 3'd4, 3'd2};
assign {B[57][0], B[57][1], B[57][2], B[57][3], B[57][4]} = {3'd1, 3'd0, 3'd3, 3'd4, 3'd2};
assign {B[58][0], B[58][1], B[58][2], B[58][3], B[58][4]} = {3'd3, 3'd0, 3'd1, 3'd4, 3'd2};
assign {B[59][0], B[59][1], B[59][2], B[59][3], B[59][4]} = {3'd0, 3'd3, 3'd1, 3'd4, 3'd2};
assign {B[60][0], B[60][1], B[60][2], B[60][3], B[60][4]} = {3'd4, 3'd3, 3'd1, 3'd0, 3'd2};
assign {B[61][0], B[61][1], B[61][2], B[61][3], B[61][4]} = {3'd3, 3'd4, 3'd1, 3'd0, 3'd2};
assign {B[62][0], B[62][1], B[62][2], B[62][3], B[62][4]} = {3'd1, 3'd4, 3'd3, 3'd0, 3'd2};
assign {B[63][0], B[63][1], B[63][2], B[63][3], B[63][4]} = {3'd4, 3'd1, 3'd3, 3'd0, 3'd2};
assign {B[64][0], B[64][1], B[64][2], B[64][3], B[64][4]} = {3'd3, 3'd1, 3'd4, 3'd0, 3'd2};
assign {B[65][0], B[65][1], B[65][2], B[65][3], B[65][4]} = {3'd1, 3'd3, 3'd4, 3'd0, 3'd2};
assign {B[66][0], B[66][1], B[66][2], B[66][3], B[66][4]} = {3'd1, 3'd0, 3'd4, 3'd3, 3'd2};
assign {B[67][0], B[67][1], B[67][2], B[67][3], B[67][4]} = {3'd0, 3'd1, 3'd4, 3'd3, 3'd2};
assign {B[68][0], B[68][1], B[68][2], B[68][3], B[68][4]} = {3'd4, 3'd1, 3'd0, 3'd3, 3'd2};
assign {B[69][0], B[69][1], B[69][2], B[69][3], B[69][4]} = {3'd1, 3'd4, 3'd0, 3'd3, 3'd2};
assign {B[70][0], B[70][1], B[70][2], B[70][3], B[70][4]} = {3'd0, 3'd4, 3'd1, 3'd3, 3'd2};
assign {B[71][0], B[71][1], B[71][2], B[71][3], B[71][4]} = {3'd4, 3'd0, 3'd1, 3'd3, 3'd2};
assign {B[72][0], B[72][1], B[72][2], B[72][3], B[72][4]} = {3'd4, 3'd0, 3'd3, 3'd1, 3'd2};
assign {B[73][0], B[73][1], B[73][2], B[73][3], B[73][4]} = {3'd0, 3'd4, 3'd3, 3'd1, 3'd2};
assign {B[74][0], B[74][1], B[74][2], B[74][3], B[74][4]} = {3'd3, 3'd4, 3'd0, 3'd1, 3'd2};
assign {B[75][0], B[75][1], B[75][2], B[75][3], B[75][4]} = {3'd4, 3'd3, 3'd0, 3'd1, 3'd2};
assign {B[76][0], B[76][1], B[76][2], B[76][3], B[76][4]} = {3'd0, 3'd3, 3'd4, 3'd1, 3'd2};
assign {B[77][0], B[77][1], B[77][2], B[77][3], B[77][4]} = {3'd3, 3'd0, 3'd4, 3'd1, 3'd2};
assign {B[78][0], B[78][1], B[78][2], B[78][3], B[78][4]} = {3'd2, 3'd0, 3'd4, 3'd1, 3'd3};
assign {B[79][0], B[79][1], B[79][2], B[79][3], B[79][4]} = {3'd0, 3'd2, 3'd4, 3'd1, 3'd3};
assign {B[80][0], B[80][1], B[80][2], B[80][3], B[80][4]} = {3'd4, 3'd2, 3'd0, 3'd1, 3'd3};
assign {B[81][0], B[81][1], B[81][2], B[81][3], B[81][4]} = {3'd2, 3'd4, 3'd0, 3'd1, 3'd3};
assign {B[82][0], B[82][1], B[82][2], B[82][3], B[82][4]} = {3'd0, 3'd4, 3'd2, 3'd1, 3'd3};
assign {B[83][0], B[83][1], B[83][2], B[83][3], B[83][4]} = {3'd4, 3'd0, 3'd2, 3'd1, 3'd3};
assign {B[84][0], B[84][1], B[84][2], B[84][3], B[84][4]} = {3'd1, 3'd0, 3'd2, 3'd4, 3'd3};
assign {B[85][0], B[85][1], B[85][2], B[85][3], B[85][4]} = {3'd0, 3'd1, 3'd2, 3'd4, 3'd3};
assign {B[86][0], B[86][1], B[86][2], B[86][3], B[86][4]} = {3'd2, 3'd1, 3'd0, 3'd4, 3'd3};
assign {B[87][0], B[87][1], B[87][2], B[87][3], B[87][4]} = {3'd1, 3'd2, 3'd0, 3'd4, 3'd3};
assign {B[88][0], B[88][1], B[88][2], B[88][3], B[88][4]} = {3'd0, 3'd2, 3'd1, 3'd4, 3'd3};
assign {B[89][0], B[89][1], B[89][2], B[89][3], B[89][4]} = {3'd2, 3'd0, 3'd1, 3'd4, 3'd3};
assign {B[90][0], B[90][1], B[90][2], B[90][3], B[90][4]} = {3'd2, 3'd4, 3'd1, 3'd0, 3'd3};
assign {B[91][0], B[91][1], B[91][2], B[91][3], B[91][4]} = {3'd4, 3'd2, 3'd1, 3'd0, 3'd3};
assign {B[92][0], B[92][1], B[92][2], B[92][3], B[92][4]} = {3'd1, 3'd2, 3'd4, 3'd0, 3'd3};
assign {B[93][0], B[93][1], B[93][2], B[93][3], B[93][4]} = {3'd2, 3'd1, 3'd4, 3'd0, 3'd3};
assign {B[94][0], B[94][1], B[94][2], B[94][3], B[94][4]} = {3'd4, 3'd1, 3'd2, 3'd0, 3'd3};
assign {B[95][0], B[95][1], B[95][2], B[95][3], B[95][4]} = {3'd1, 3'd4, 3'd2, 3'd0, 3'd3};
assign {B[96][0], B[96][1], B[96][2], B[96][3], B[96][4]} = {3'd1, 3'd4, 3'd0, 3'd2, 3'd3};
assign {B[97][0], B[97][1], B[97][2], B[97][3], B[97][4]} = {3'd4, 3'd1, 3'd0, 3'd2, 3'd3};
assign {B[98][0], B[98][1], B[98][2], B[98][3], B[98][4]} = {3'd0, 3'd1, 3'd4, 3'd2, 3'd3};
assign {B[99][0], B[99][1], B[99][2], B[99][3], B[99][4]} = {3'd1, 3'd0, 3'd4, 3'd2, 3'd3};
assign {B[100][0], B[100][1], B[100][2], B[100][3], B[100][4]} = {3'd4, 3'd0, 3'd1, 3'd2, 3'd3};
assign {B[101][0], B[101][1], B[101][2], B[101][3], B[101][4]} = {3'd0, 3'd4, 3'd1, 3'd2, 3'd3};
assign {B[102][0], B[102][1], B[102][2], B[102][3], B[102][4]} = {3'd3, 3'd4, 3'd1, 3'd2, 3'd0};
assign {B[103][0], B[103][1], B[103][2], B[103][3], B[103][4]} = {3'd4, 3'd3, 3'd1, 3'd2, 3'd0};
assign {B[104][0], B[104][1], B[104][2], B[104][3], B[104][4]} = {3'd1, 3'd3, 3'd4, 3'd2, 3'd0};
assign {B[105][0], B[105][1], B[105][2], B[105][3], B[105][4]} = {3'd3, 3'd1, 3'd4, 3'd2, 3'd0};
assign {B[106][0], B[106][1], B[106][2], B[106][3], B[106][4]} = {3'd4, 3'd1, 3'd3, 3'd2, 3'd0};
assign {B[107][0], B[107][1], B[107][2], B[107][3], B[107][4]} = {3'd1, 3'd4, 3'd3, 3'd2, 3'd0};
assign {B[108][0], B[108][1], B[108][2], B[108][3], B[108][4]} = {3'd2, 3'd4, 3'd3, 3'd1, 3'd0};
assign {B[109][0], B[109][1], B[109][2], B[109][3], B[109][4]} = {3'd4, 3'd2, 3'd3, 3'd1, 3'd0};
assign {B[110][0], B[110][1], B[110][2], B[110][3], B[110][4]} = {3'd3, 3'd2, 3'd4, 3'd1, 3'd0};
assign {B[111][0], B[111][1], B[111][2], B[111][3], B[111][4]} = {3'd2, 3'd3, 3'd4, 3'd1, 3'd0};
assign {B[112][0], B[112][1], B[112][2], B[112][3], B[112][4]} = {3'd4, 3'd3, 3'd2, 3'd1, 3'd0};
assign {B[113][0], B[113][1], B[113][2], B[113][3], B[113][4]} = {3'd3, 3'd4, 3'd2, 3'd1, 3'd0};
assign {B[114][0], B[114][1], B[114][2], B[114][3], B[114][4]} = {3'd3, 3'd1, 3'd2, 3'd4, 3'd0};
assign {B[115][0], B[115][1], B[115][2], B[115][3], B[115][4]} = {3'd1, 3'd3, 3'd2, 3'd4, 3'd0};
assign {B[116][0], B[116][1], B[116][2], B[116][3], B[116][4]} = {3'd2, 3'd3, 3'd1, 3'd4, 3'd0};
assign {B[117][0], B[117][1], B[117][2], B[117][3], B[117][4]} = {3'd3, 3'd2, 3'd1, 3'd4, 3'd0};
assign {B[118][0], B[118][1], B[118][2], B[118][3], B[118][4]} = {3'd1, 3'd2, 3'd3, 3'd4, 3'd0};
assign {B[119][0], B[119][1], B[119][2], B[119][3], B[119][4]} = {3'd2, 3'd1, 3'd3, 3'd4, 3'd0};

// C8,5
assign {C[0][0], C[0][1], C[0][2], C[0][3], C[0][4]} = {4'd0, 4'd1, 4'd2, 4'd3, 4'd4};
assign {C[1][0], C[1][1], C[1][2], C[1][3], C[1][4]} = {4'd0, 4'd1, 4'd2, 4'd3, 4'd5};
assign {C[2][0], C[2][1], C[2][2], C[2][3], C[2][4]} = {4'd0, 4'd1, 4'd2, 4'd3, 4'd6};
assign {C[3][0], C[3][1], C[3][2], C[3][3], C[3][4]} = {4'd0, 4'd1, 4'd2, 4'd3, 4'd7};
assign {C[4][0], C[4][1], C[4][2], C[4][3], C[4][4]} = {4'd0, 4'd1, 4'd2, 4'd4, 4'd5};
assign {C[5][0], C[5][1], C[5][2], C[5][3], C[5][4]} = {4'd0, 4'd1, 4'd2, 4'd4, 4'd6};
assign {C[6][0], C[6][1], C[6][2], C[6][3], C[6][4]} = {4'd0, 4'd1, 4'd2, 4'd4, 4'd7};
assign {C[7][0], C[7][1], C[7][2], C[7][3], C[7][4]} = {4'd0, 4'd1, 4'd2, 4'd5, 4'd6};
assign {C[8][0], C[8][1], C[8][2], C[8][3], C[8][4]} = {4'd0, 4'd1, 4'd2, 4'd5, 4'd7};
assign {C[9][0], C[9][1], C[9][2], C[9][3], C[9][4]} = {4'd0, 4'd1, 4'd2, 4'd6, 4'd7};
assign {C[10][0], C[10][1], C[10][2], C[10][3], C[10][4]} = {4'd0, 4'd1, 4'd3, 4'd4, 4'd5};
assign {C[11][0], C[11][1], C[11][2], C[11][3], C[11][4]} = {4'd0, 4'd1, 4'd3, 4'd4, 4'd6};
assign {C[12][0], C[12][1], C[12][2], C[12][3], C[12][4]} = {4'd0, 4'd1, 4'd3, 4'd4, 4'd7};
assign {C[13][0], C[13][1], C[13][2], C[13][3], C[13][4]} = {4'd0, 4'd1, 4'd3, 4'd5, 4'd6};
assign {C[14][0], C[14][1], C[14][2], C[14][3], C[14][4]} = {4'd0, 4'd1, 4'd3, 4'd5, 4'd7};
assign {C[15][0], C[15][1], C[15][2], C[15][3], C[15][4]} = {4'd0, 4'd1, 4'd3, 4'd6, 4'd7};
assign {C[16][0], C[16][1], C[16][2], C[16][3], C[16][4]} = {4'd0, 4'd1, 4'd4, 4'd5, 4'd6};
assign {C[17][0], C[17][1], C[17][2], C[17][3], C[17][4]} = {4'd0, 4'd1, 4'd4, 4'd5, 4'd7};
assign {C[18][0], C[18][1], C[18][2], C[18][3], C[18][4]} = {4'd0, 4'd1, 4'd4, 4'd6, 4'd7};
assign {C[19][0], C[19][1], C[19][2], C[19][3], C[19][4]} = {4'd0, 4'd1, 4'd5, 4'd6, 4'd7};
assign {C[20][0], C[20][1], C[20][2], C[20][3], C[20][4]} = {4'd0, 4'd2, 4'd3, 4'd4, 4'd5};
assign {C[21][0], C[21][1], C[21][2], C[21][3], C[21][4]} = {4'd0, 4'd2, 4'd3, 4'd4, 4'd6};
assign {C[22][0], C[22][1], C[22][2], C[22][3], C[22][4]} = {4'd0, 4'd2, 4'd3, 4'd4, 4'd7};
assign {C[23][0], C[23][1], C[23][2], C[23][3], C[23][4]} = {4'd0, 4'd2, 4'd3, 4'd5, 4'd6};
assign {C[24][0], C[24][1], C[24][2], C[24][3], C[24][4]} = {4'd0, 4'd2, 4'd3, 4'd5, 4'd7};
assign {C[25][0], C[25][1], C[25][2], C[25][3], C[25][4]} = {4'd0, 4'd2, 4'd3, 4'd6, 4'd7};
assign {C[26][0], C[26][1], C[26][2], C[26][3], C[26][4]} = {4'd0, 4'd2, 4'd4, 4'd5, 4'd6};
assign {C[27][0], C[27][1], C[27][2], C[27][3], C[27][4]} = {4'd0, 4'd2, 4'd4, 4'd5, 4'd7};
assign {C[28][0], C[28][1], C[28][2], C[28][3], C[28][4]} = {4'd0, 4'd2, 4'd4, 4'd6, 4'd7};
assign {C[29][0], C[29][1], C[29][2], C[29][3], C[29][4]} = {4'd0, 4'd2, 4'd5, 4'd6, 4'd7};
assign {C[30][0], C[30][1], C[30][2], C[30][3], C[30][4]} = {4'd0, 4'd3, 4'd4, 4'd5, 4'd6};
assign {C[31][0], C[31][1], C[31][2], C[31][3], C[31][4]} = {4'd0, 4'd3, 4'd4, 4'd5, 4'd7};
assign {C[32][0], C[32][1], C[32][2], C[32][3], C[32][4]} = {4'd0, 4'd3, 4'd4, 4'd6, 4'd7};
assign {C[33][0], C[33][1], C[33][2], C[33][3], C[33][4]} = {4'd0, 4'd3, 4'd5, 4'd6, 4'd7};
assign {C[34][0], C[34][1], C[34][2], C[34][3], C[34][4]} = {4'd0, 4'd4, 4'd5, 4'd6, 4'd7};
assign {C[35][0], C[35][1], C[35][2], C[35][3], C[35][4]} = {4'd1, 4'd2, 4'd3, 4'd4, 4'd5};
assign {C[36][0], C[36][1], C[36][2], C[36][3], C[36][4]} = {4'd1, 4'd2, 4'd3, 4'd4, 4'd6};
assign {C[37][0], C[37][1], C[37][2], C[37][3], C[37][4]} = {4'd1, 4'd2, 4'd3, 4'd4, 4'd7};
assign {C[38][0], C[38][1], C[38][2], C[38][3], C[38][4]} = {4'd1, 4'd2, 4'd3, 4'd5, 4'd6};
assign {C[39][0], C[39][1], C[39][2], C[39][3], C[39][4]} = {4'd1, 4'd2, 4'd3, 4'd5, 4'd7};
assign {C[40][0], C[40][1], C[40][2], C[40][3], C[40][4]} = {4'd1, 4'd2, 4'd3, 4'd6, 4'd7};
assign {C[41][0], C[41][1], C[41][2], C[41][3], C[41][4]} = {4'd1, 4'd2, 4'd4, 4'd5, 4'd6};
assign {C[42][0], C[42][1], C[42][2], C[42][3], C[42][4]} = {4'd1, 4'd2, 4'd4, 4'd5, 4'd7};
assign {C[43][0], C[43][1], C[43][2], C[43][3], C[43][4]} = {4'd1, 4'd2, 4'd4, 4'd6, 4'd7};
assign {C[44][0], C[44][1], C[44][2], C[44][3], C[44][4]} = {4'd1, 4'd2, 4'd5, 4'd6, 4'd7};
assign {C[45][0], C[45][1], C[45][2], C[45][3], C[45][4]} = {4'd1, 4'd3, 4'd4, 4'd5, 4'd6};
assign {C[46][0], C[46][1], C[46][2], C[46][3], C[46][4]} = {4'd1, 4'd3, 4'd4, 4'd5, 4'd7};
assign {C[47][0], C[47][1], C[47][2], C[47][3], C[47][4]} = {4'd1, 4'd3, 4'd4, 4'd6, 4'd7};
assign {C[48][0], C[48][1], C[48][2], C[48][3], C[48][4]} = {4'd1, 4'd3, 4'd5, 4'd6, 4'd7};
assign {C[49][0], C[49][1], C[49][2], C[49][3], C[49][4]} = {4'd1, 4'd4, 4'd5, 4'd6, 4'd7};
assign {C[50][0], C[50][1], C[50][2], C[50][3], C[50][4]} = {4'd2, 4'd3, 4'd4, 4'd5, 4'd6};
assign {C[51][0], C[51][1], C[51][2], C[51][3], C[51][4]} = {4'd2, 4'd3, 4'd4, 4'd5, 4'd7};
assign {C[52][0], C[52][1], C[52][2], C[52][3], C[52][4]} = {4'd2, 4'd3, 4'd4, 4'd6, 4'd7};
assign {C[53][0], C[53][1], C[53][2], C[53][3], C[53][4]} = {4'd2, 4'd3, 4'd5, 4'd6, 4'd7};
assign {C[54][0], C[54][1], C[54][2], C[54][3], C[54][4]} = {4'd2, 4'd4, 4'd5, 4'd6, 4'd7};
assign {C[55][0], C[55][1], C[55][2], C[55][3], C[55][4]} = {4'd3, 4'd4, 4'd5, 4'd6, 4'd7};

// ===============================================================
// Integer
// ===============================================================
integer  i;
// ===============================================================
// DESIGN
// ===============================================================
// ===============================================================
// Finite State Machine
// ===============================================================

// Current State
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) current_state <= s_idle;
    else        current_state <= next_state;
end

//================================================================
//  Next State                     
//================================================================
always @(*) begin 
    case (current_state)
    s_idle: begin
        if(in_valid) next_state = s_input;
        else         next_state = s_idle;
    end
    //================================================================
    s_input: begin
        if (in_out_cnt == 'd6) next_state = s_combination;
        else next_state = current_state;
    end
    //================================================================
    s_combination: begin                                //56
        if(target_data[0] == 'd5 || cnt_com == 'd56)  next_state = s_output;
        else if(total_AB_combination != total_AB) next_state = current_state;
        else    next_state = s_permutaion;
    end
    //================================================================
    s_permutaion: begin                                 //120
        if(cnt_perm == 'd120) next_state = s_combination;
        else if(cnt_A == target_data[0] && cnt_B == target_data[1]) next_state = s_calculate;
        else next_state = current_state;
    end
    //================================================================
    s_calculate: begin
        next_state = s_replace;
    end
    //================================================================
    s_replace: begin
        if(c1_flag) next_state = s_corner1;
        else next_state = s_permutaion;
    end
    //================================================================
    s_corner1: begin
        if(c2_flag)  next_state = s_corner2;
        else next_state = s_permutaion;
    end
    //================================================================
    s_corner2: begin
        if(c2_swap) next_state = s_permutaion;
        else next_state = current_state;
    end
    //================================================================
    s_output: begin
        if (in_out_cnt == 4) next_state = s_idle;
        else next_state = current_state;
    end
    //================================================================
    default: next_state = current_state;
    endcase
end
//================================================================
//  in_out_cnt                     
//================================================================
// in_cnt
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        in_out_cnt <= 4'b0;
    else
    case(current_state)
    s_input:    in_out_cnt <= in_out_cnt + 1'b1;
    s_output:   in_out_cnt <= in_out_cnt + 1'b1;
    default:    in_out_cnt <= 4'b0;
    endcase
end
assign in_cnt_temp = in_out_cnt+1;
//================================================================
//  s_input                
//================================================================
// store input
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<8; i = i+1) begin
            keyboard_data[i] <= 5'b0;
            
        end
        for(i=0; i<5; i = i+1) begin
            answer_data[i] <= 5'b0;
            weight_data[i] <= 4'b0;
        end
        for(i=0; i<2; i = i+1) begin
            target_data[i] <= 3'b0;
        end

    end
    else begin
        case(current_state)
        s_idle:begin
            if(in_valid) begin
                keyboard_data[in_out_cnt] <= keyboard;
                answer_data[in_out_cnt] <= answer;
                weight_data[in_out_cnt] <= weight;
                target_data[in_out_cnt] <= match_target;
            end
        end
        s_input:begin
            keyboard_data[in_cnt_temp] <= keyboard;
            answer_data[in_cnt_temp] <= answer;
            weight_data[in_cnt_temp] <= weight;
            target_data[in_cnt_temp] <= match_target;
        end
        
        default: begin
            for(i=0; i<8; i = i+1) begin
                keyboard_data[i] <= keyboard_data[i];
            end
            for(i=0; i<5; i = i+1) begin
                answer_data[i] <= answer_data[i];
                weight_data[i] <= weight_data[i];
            end
            for(i=0; i<2; i = i+1) begin
                target_data[i] <= target_data[i];
            end
        end
        endcase
    end
end

//================================================================
//  s_combination              
//================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        // cnt
        cnt_com <= 'd0;
        cnt_perm <= 'd0;
        cnt_corner2 <= 'd0;

        // out
        out_value_temp <= 'd1;
        out_value_temp_1 <= 'd0;
        for(i=0; i<5; i=i+1) begin
            result_arr[i] <= 'd0;
            com[i] <= 'd0;
            perm[i] <= 'd0;
        end
        out_value_1[0] <= 'd0;
        out_value_1[1] <= 'd0;
    end
    else begin
        case(current_state)
        //================================================================
        s_idle: begin
            // cnt
            cnt_com <= 'd0;
            cnt_perm <= 'd0;
            cnt_corner2 <= 'd0;

            // out
            out_value_temp <= 'd1;
            out_value_temp_1 <= 'd0;
            for(i=0; i<5; i=i+1) begin
                result_arr[i] <= 'd0;
                com[i] <= 'd0;
                perm[i] <= 'd0;
            end
            out_value_1[0] <= 'd0;
            out_value_1[1] <= 'd0;
        end
        //================================================================
        s_combination: begin
            cnt_com <= cnt_com + 1;
            cnt_perm <= 0;
            if(target_data[0] == 'd5) begin // 5A
                out_value_temp <= (answer_data[0] * weight_data[0]) + (answer_data[1] * weight_data[1]) + (answer_data[2] * weight_data[2]) + 
                (answer_data[3] * weight_data[3]) + (answer_data[4] * weight_data[4]);

                for(i=0; i<5; i=i+1) begin
                    result_arr[i] <= answer_data[i];
                end
            end
            else begin
                for(i=0; i<5; i=i+1)
                begin
                    com[i] <= keyboard_data[C[cnt_com][i]];
                end
            end
        end
        //================================================================
        s_permutaion: begin
            cnt_perm <= cnt_perm + 1;
            for(i=0; i<5; i=i+1)
            begin
                perm[i] <= com[B[cnt_perm][i]];
            end
        end
        //================================================================
        s_calculate: begin
            out_value_1[0] <= (perm[0] * weight_data[0]) + (perm[1] * weight_data[1]) + (perm[2] * weight_data[2]) + (perm[3] * weight_data[3]) + (perm[4] * weight_data[4]);
        end
        //================================================================
        s_replace: begin 
            cnt_corner2 <= 0;
            if(out_value_temp < out_value_1[0])
            begin
                out_value_temp <= out_value_1[0];
                for(i=0; i<5; i=i+1) result_arr[i] <= perm[i];
            end
            else if(out_value_temp == out_value_1[0])
            begin
                out_value_1[1] <= (perm[0] << 4) + (perm[1] << 3) + (perm[2] << 2) + (perm[3] << 1) + perm[4];
                out_value_temp_1 <= (result_arr[0] << 4) + (result_arr[1] << 3) + (result_arr[2] << 2) + (result_arr[3] << 1) + result_arr[4];
            end
            else
            begin
                out_value_temp <= out_value_temp;
                for(i=0; i<5; i=i+1) result_arr[i] <= result_arr[i];
                out_value_1[0] <= 0;
            end 
        end
         //================================================================
        s_corner1: begin
            if(out_value_1[1] > out_value_temp_1)
            begin
                for(i=0; i<5; i=i+1) begin
                    result_arr[i] <= perm[i];
                end
            end
            else begin
            end
        end
        //================================================================
        s_corner2: begin
            if(result_arr[0] > perm[0]) begin 
                for(i=0; i<5; i=i+1) result_arr[i] <= perm[i];
                c2_swap <= 1;
            end
            else if (result_arr[0] == perm[0]) begin
                if(result_arr[1] > perm[1]) begin
                    for(i=0; i<5; i=i+1) result_arr[i] <= perm[i];
                    c2_swap <= 1;
                end
                else if (result_arr[1] == perm[1]) begin
                    if(result_arr[2] > perm[2]) begin
                        for(i=0; i<5; i=i+1) result_arr[i] <= perm[i];
                        c2_swap <= 1;
                    end
                    else if (result_arr[2] == perm[2]) begin
                        if(result_arr[3] > perm[3]) begin
                            for(i=0; i<5; i=i+1) result_arr[i] <= perm[i];
                            c2_swap <= 1;
                        end
                        else if (result_arr[3] == perm[3]) begin
                            if(result_arr[4] > perm[4]) begin 
                                for(i=0; i<5; i=i+1) result_arr[i] <= perm[i];
                                c2_swap <= 1;
                            end
                            else begin
                                c2_swap <= 1;
                            end
                        end
                        else begin
                            c2_swap <= 1;
                        end
                    end
                    else begin
                        c2_swap <= 1;
                    end
                end
                else begin
                    c2_swap <= 1;
                end
            end
            else begin
                c2_swap <= 1;
            end
        end
        //================================================================
        default: begin

        end
        endcase
    end
end

//================================================================
//  flag                   
//================================================================
always @(*) begin
    case(current_state)
    //================================================================
    s_replace: begin
        c1_flag = (out_value_temp == out_value_1[0]);
        c2_flag = 0;
    end
    //================================================================
    s_corner1: begin
        c1_flag = 0;
        c2_flag = (out_value_1[1] == out_value_temp_1);
    end
    //================================================================
    default: begin
        c1_flag = 0;
        c2_flag = 0;
    end
    endcase
end

//================================================================
//  Output                         
//================================================================
// out_valid
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 1'b0;
    end
    else begin
        case(current_state)
        s_output: out_valid <= 1'b1;
        default: out_valid <= 1'b0;
        endcase
    end
end

// out_value
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_value <= 11'b0;
    end
    else begin
        case(current_state)
        s_output: begin
            out_value <= out_value_temp;
        end
        default: out_value <= 11'b0;
        endcase
    end
end

// result
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        result <= 5'b0;
    end
    else begin
        case(current_state)
        s_output: begin
            result <= result_arr[in_out_cnt];
        end
        default: result <= 5'b0;
        endcase
    end
end

endmodule