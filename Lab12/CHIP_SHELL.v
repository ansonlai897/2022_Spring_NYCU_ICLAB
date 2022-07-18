module CHIP(    
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
input [4:0] keyboard;
input [4:0] answer;
input [3:0] weight;
input [2:0] match_target;
output [4:0] result;
output [10:0] out_value;
input clk, rst_n, in_valid;
output out_valid;

wire   C_clk;
wire   C_rst_n;
wire   C_in_valid;
wire  [4:0] C_keyboard,C_answer;
wire  [3:0] C_weight;
wire  [2:0] C_match_target;

wire  C_out_valid;
wire  [4:0] C_result;
wire  [10:0] C_out_value;

wire BUF_clk;
CLKBUFX20 buf0(.A(C_clk),.Y(BUF_clk));


WD u_WD(
    // Input signals
    .clk(BUF_clk),
    .rst_n(C_rst_n),
    .in_valid(C_in_valid),
    .keyboard(C_keyboard),
    .answer(C_answer),
    .weight(C_weight),
    .match_target(C_match_target),
    // Output signals
    .out_valid(C_out_valid),
    .result(C_result),
    .out_value(C_out_value)
);
// Input Pads
P8C I_CLK      ( .Y(C_clk),   .P(clk),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b0), .CSEN(1'b1) );
P8C I_RESET    ( .Y(C_rst_n), .P(rst_n), .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_VALID    ( .Y(C_in_valid), .P(in_valid), .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );

// keyboard
P4C I_key_0     ( .Y(C_keyboard[0]), .P(keyboard[0]), .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_key_1     ( .Y(C_keyboard[1]), .P(keyboard[1]), .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_key_2     ( .Y(C_keyboard[2]), .P(keyboard[2]), .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_key_3     ( .Y(C_keyboard[3]), .P(keyboard[3]), .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_key_4     ( .Y(C_keyboard[4]), .P(keyboard[4]), .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );

// answer
P4C I_ans_0     ( .Y(C_answer[0]), .P(answer[0]), .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_ans_1     ( .Y(C_answer[1]), .P(answer[1]), .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_ans_2     ( .Y(C_answer[2]), .P(answer[2]), .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_ans_3     ( .Y(C_answer[3]), .P(answer[3]), .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_ans_4     ( .Y(C_answer[4]), .P(answer[4]), .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );

// weight
P4C I_wei_0     ( .Y(C_weight[0]), .P(weight[0]), .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_wei_1     ( .Y(C_weight[1]), .P(weight[1]), .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_wei_2     ( .Y(C_weight[2]), .P(weight[2]), .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_wei_3     ( .Y(C_weight[3]), .P(weight[3]), .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );

// match_target
P4C I_mat_0     ( .Y(C_match_target[0]), .P(match_target[0]), .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_mat_1     ( .Y(C_match_target[1]), .P(match_target[1]), .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_mat_2     ( .Y(C_match_target[2]), .P(match_target[2]), .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );

// Output Pads
P8C O_VALID    ( .A(C_out_valid), 	.P(out_valid), 	 .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));

// result
P8C O_res_0    ( .A(C_result[0]), .P(result[0]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_res_1    ( .A(C_result[1]), .P(result[1]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_res_2    ( .A(C_result[2]), .P(result[2]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_res_3    ( .A(C_result[3]), .P(result[3]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_res_4    ( .A(C_result[4]), .P(result[4]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));

// out_value
P8C O_val_0    ( .A(C_out_value[0 ]), .P(out_value[0 ]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_val_1    ( .A(C_out_value[1 ]), .P(out_value[1 ]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_val_2    ( .A(C_out_value[2 ]), .P(out_value[2 ]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_val_3    ( .A(C_out_value[3 ]), .P(out_value[3 ]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_val_4    ( .A(C_out_value[4 ]), .P(out_value[4 ]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_val_5    ( .A(C_out_value[5 ]), .P(out_value[5 ]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_val_6    ( .A(C_out_value[6 ]), .P(out_value[6 ]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_val_7    ( .A(C_out_value[7 ]), .P(out_value[7 ]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_val_8    ( .A(C_out_value[8 ]), .P(out_value[8 ]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_val_9    ( .A(C_out_value[9 ]), .P(out_value[9 ]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_val_10   ( .A(C_out_value[10]), .P(out_value[10]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
// IO power 
PVDDR VDDP0 ();
PVSSR GNDP0 ();

PVDDR VDDP1 ();
PVSSR GNDP1 ();

PVDDR VDDP2 ();
PVSSR GNDP2 ();

PVDDR VDDP3 ();
PVSSR GNDP3 ();

PVDDR VDDP4 ();
PVSSR GNDP4 ();

PVDDR VDDP5 ();
PVSSR GNDP5 ();

PVDDR VDDP6 ();
PVSSR GNDP6 ();

PVDDR VDDP7 ();
PVSSR GNDP7 ();

PVDDR VDDP8 ();
PVSSR GNDP8 ();

PVDDR VDDP9 ();
PVSSR GNDP9 ();

PVDDR VDDP10 ();
PVSSR GNDP10 ();

PVDDR VDDP11 ();
PVSSR GNDP11 ();

PVDDR VDDP12 ();
PVSSR GNDP12 ();

PVDDR VDDP13 ();
PVSSR GNDP13 ();

PVDDR VDDP14 ();
PVSSR GNDP14 ();

PVDDR VDDP15 ();
PVSSR GNDP15 ();

PVDDR VDDP16 ();
PVSSR GNDP16 ();

PVDDR VDDP17 ();
PVSSR GNDP17 ();

PVDDR VDDP18 ();
PVSSR GNDP18 ();

PVDDR VDDP19 ();
PVSSR GNDP19 ();

PVDDR VDDP20 ();
PVSSR GNDP20 ();
// Core power

PVDDC VDDC0 ();
PVSSC GNDC0 ();

PVDDC VDDC1 ();
PVSSC GNDC1 ();

PVDDC VDDC2 ();
PVSSC GNDC2 ();

PVDDC VDDC3 ();
PVSSC GNDC3 ();

PVDDC VDDC4 ();
PVSSC GNDC4 ();

PVDDC VDDC5 ();
PVSSC GNDC5 ();

PVDDC VDDC6 ();
PVSSC GNDC6 ();

PVDDC VDDC7 ();
PVSSC GNDC7 ();

PVDDC VDDC8 ();
PVSSC GNDC8 ();

PVDDC VDDC9 ();
PVSSC GNDC9 ();

PVDDC VDDC10 ();
PVSSC GNDC10 ();

PVDDC VDDC11 ();
PVSSC GNDC11 ();

PVDDC VDDC12 ();
PVSSC GNDC12 ();

PVDDC VDDC13 ();
PVSSC GNDC13 ();

PVDDC VDDC14 ();
PVSSC GNDC14 ();

PVDDC VDDC15 ();
PVSSC GNDC15 ();

PVDDC VDDC16 ();
PVSSC GNDC16 ();

PVDDC VDDC17 ();
PVSSC GNDC17 ();

PVDDC VDDC18 ();
PVSSC GNDC18 ();

PVDDC VDDC19 ();
PVSSC GNDC19 ();

endmodule