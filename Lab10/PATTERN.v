`define CYCLE_TIME 12

module PATTERN(
	// Output signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	in_data,
	op,
	// Output signals
	out_valid,
	out_data
);

output reg clk;
output reg rst_n;
output reg cg_en;
output reg in_valid;
output reg signed [6:0] in_data;
output reg [3:0] op;

input out_valid;
input signed [6:0] out_data;

//================================================================
// clock
//================================================================
always	#(`CYCLE_TIME/2.0) clk = ~clk;
initial	clk = 0;
//================================================================
// integer
//================================================================
integer i, j;
integer pat;
integer gap, total_lat, lat, cnt;

parameter pat_num = 50;

parameter Midpoint 	= 'd0;
parameter Average	= 'd1;
parameter Inv_clk	= 'd2;
parameter Clock		= 'd3;
parameter Flip		= 'd4;
parameter Up		= 'd5;
parameter Left		= 'd6;
parameter Down		= 'd7;
parameter Right		= 'd8;


// ===============================================================
// Wire & Reg Declaration
// ===============================================================
reg signed [6:0] pat_map [0:7][0:7];
reg [3:0] pat_op [0:14];

wire [447:0] pat_fuck = 
{pat_map[0][0], pat_map[0][1], pat_map[0][2], pat_map[0][3], pat_map[0][4], pat_map[0][5], pat_map[0][6], pat_map[0][7], 
 pat_map[1][0], pat_map[1][1], pat_map[1][2], pat_map[1][3], pat_map[1][4], pat_map[1][5], pat_map[1][6], pat_map[1][7],
 pat_map[2][0], pat_map[2][1], pat_map[2][2], pat_map[2][3], pat_map[2][4], pat_map[2][5], pat_map[2][6], pat_map[2][7],
 pat_map[3][0], pat_map[3][1], pat_map[3][2], pat_map[3][3], pat_map[3][4], pat_map[3][5], pat_map[3][6], pat_map[3][7],
 pat_map[4][0], pat_map[4][1], pat_map[4][2], pat_map[4][3], pat_map[4][4], pat_map[4][5], pat_map[4][6], pat_map[4][7],
 pat_map[5][0], pat_map[5][1], pat_map[5][2], pat_map[5][3], pat_map[5][4], pat_map[5][5], pat_map[5][6], pat_map[5][7],
 pat_map[6][0], pat_map[6][1], pat_map[6][2], pat_map[6][3], pat_map[6][4], pat_map[6][5], pat_map[6][6], pat_map[6][7],
 pat_map[7][0], pat_map[7][1], pat_map[7][2], pat_map[7][3], pat_map[7][4], pat_map[7][5], pat_map[7][6], pat_map[7][7] };

reg signed [10:0] pat_av_1, pat_av_2;
reg signed [10:0] pat_av_3;
reg signed [10:0] pat_av;

reg signed [6:0] tmp, tmp_1;

reg signed [6:0] pat_mid_arr [0:3];
reg signed [7:0] pat_mid_1;
reg signed [6:0] pat_mid;

// golden
reg signed [6:0] golden_ans [0:15];

// x, y
reg [2:0] pat_x;
reg [2:0] pat_y;


initial begin
	// clk gating
	cg_en = 0;
    // golden
	for(i=0; i<15; i=i+1)
		pat_op[i] <= 0;
	for(i=0; i<8; i=i+1)
		for(j=0; j<8; j=j+1)
			pat_map[i][j] <= 0;
	in_data 	= 0;
	in_valid	= 0;
    rst_n       = 1;
    total_lat   = 0; 
	cnt 		= 0;
    
    reset_signal;
    for(pat=0 ; pat <= pat_num; pat=pat+1) begin
        set_input;
		operation;
		set_answer;
		wait_out_valid;
		check_ans;
		repeat(2)@(negedge clk);
		$display("PASS pattern: %d", pat);
	end
    $finish;
end

//================================================================
// reset_signal
//================================================================
task reset_signal; begin
	#(0.5); rst_n = 0;
	#(2/2.0);
	
	#(2); rst_n = 1;
end endtask

//================================================================
// set_input
//================================================================
task set_input; begin
	@(negedge clk);
	in_valid = 1;
	cnt = 0;
	while(cnt<64) begin
		if(cnt<15) begin
			/*
			// debug
			pat_op[0]  = 8;
			pat_op[1]  = 8;
			pat_op[2]  = 6;
			pat_op[3]  = 5;
			pat_op[4]  = 2;
			pat_op[5]  = 5;
			pat_op[6]  = 5;
			pat_op[7]  = 2;
			pat_op[8]  = 7;
			pat_op[9]  = 4;
			pat_op[10] = 2;
			pat_op[11] = 3;
			pat_op[12] = 8;
			pat_op[13] = 1;
			pat_op[14] = 1;

			op = pat_op[cnt];
			*/
			// op
			op = $urandom_range(0, 8);
			pat_op[cnt] = op;
			
			// data
			in_data = $urandom_range(0, 127);
			pat_map[cnt/8][cnt%8] = in_data;
		end
		else begin
			// op
			op = 'dx;

			// data
			in_data = $urandom_range(0, 127);
			pat_map[cnt/8][cnt%8] = in_data;
		end
		@(negedge clk);
		cnt = cnt + 1;
	end
	in_valid = 0;
	in_data = 'dx;
end endtask

//================================================================
// operation
//================================================================
reg signed[7:0] temp0=0,temp1=0,temp2=0,temp3=0;
reg signed[8:0] temp=0;
task operation; begin
	@(negedge clk);
	cnt = 0;
	pat_x = 3;
	pat_y = 3;

	while(cnt < 15) begin
		case(pat_op[cnt])
			Up: begin
				if(pat_x != 0)  pat_x = pat_x - 1;
			end
			Down: begin
				if(pat_x != 6)  pat_x = pat_x + 1;
			end
			Left: begin
				if(pat_y != 0)  pat_y = pat_y - 1;
			end
			Right: begin
				if(pat_y != 6)  pat_y = pat_y + 1;
			end
			Average: begin
				temp = (pat_map[pat_x][pat_y] + pat_map[pat_x+1][pat_y]
				      + pat_map[pat_x][pat_y+1] + pat_map[pat_x+1][pat_y+1])/4;

				pat_map[pat_x][pat_y]     = temp;
				pat_map[pat_x+1][pat_y]   = temp;
				pat_map[pat_x][pat_y+1]   = temp;
				pat_map[pat_x+1][pat_y+1] = temp;
			end
			Flip: begin
				pat_map[pat_x][pat_y]     = pat_map[pat_x][pat_y]	  *(-1);
				pat_map[pat_x+1][pat_y]   = pat_map[pat_x+1][pat_y]	  *(-1);
				pat_map[pat_x][pat_y+1]   = pat_map[pat_x][pat_y+1]	  *(-1);
				pat_map[pat_x+1][pat_y+1] = pat_map[pat_x+1][pat_y+1] *(-1);
			end
			Inv_clk: begin
				tmp = pat_map[pat_x][pat_y];
				pat_map[pat_x][pat_y] = pat_map[pat_x][pat_y+1];

				tmp_1 = pat_map[pat_x+1][pat_y];
				pat_map[pat_x+1][pat_y] = tmp;

				tmp = pat_map[pat_x+1][pat_y+1];
				pat_map[pat_x+1][pat_y+1] = tmp_1;

				pat_map[pat_x][pat_y+1] = tmp;
				
				/*
				temp0=pat_map[pat_x][pat_y];
				temp1=pat_map[pat_x+1][pat_y];
				temp2=pat_map[pat_x][pat_y+1];
				temp3=pat_map[pat_x+1][pat_y+1];


				pat_map[pat_x][pat_y]=temp2;
				pat_map[pat_x+1][pat_y]=temp0;
				pat_map[pat_x][pat_y+1]=temp3;
				pat_map[pat_x+1][pat_y+1]=temp1;
				*/
			end
			Clock: begin
				tmp = pat_map[pat_x][pat_y];
				pat_map[pat_x][pat_y] = pat_map[pat_x+1][pat_y];

				tmp_1 = pat_map[pat_x][pat_y+1];
				pat_map[pat_x][pat_y+1] = tmp;

				tmp = pat_map[pat_x+1][pat_y+1];
				pat_map[pat_x+1][pat_y+1] = tmp_1;

				pat_map[pat_x+1][pat_y] = tmp;
				/*
				temp0=pat_map[pat_x][pat_y];
				temp1=pat_map[pat_x+1][pat_y];
				temp2=pat_map[pat_x][pat_y+1];
				temp3=pat_map[pat_x+1][pat_y+1];


				pat_map[pat_x][pat_y]=temp1;
				pat_map[pat_x+1][pat_y]=temp3;
				pat_map[pat_x][pat_y+1]=temp0;
				pat_map[pat_x+1][pat_y+1]=temp2;
				*/
			end
			Midpoint: begin
				pat_mid_arr[0] = pat_map[pat_x][pat_y];
				pat_mid_arr[1] = pat_map[pat_x+1][pat_y];
				pat_mid_arr[2] = pat_map[pat_x][pat_y+1];
				pat_mid_arr[3] = pat_map[pat_x+1][pat_y+1];

				// sort
				for(i=0;i<4;i=i+1)
				begin
					for(j=0;j<4-i;j=j+1)
					begin
						if(pat_mid_arr[j]<pat_mid_arr[j+1])
						begin
							tmp = pat_mid_arr[j];
							pat_mid_arr[j] = pat_mid_arr[j+1];
							pat_mid_arr[j+1] =tmp;
						end
					end
				end
				pat_mid_1 = pat_mid_arr[1] + pat_mid_arr[2];
				pat_mid = pat_mid_1 / 2;

				pat_map[pat_x][pat_y]     = pat_mid;
				pat_map[pat_x+1][pat_y]   = pat_mid;
				pat_map[pat_x][pat_y+1]   = pat_mid;
				pat_map[pat_x+1][pat_y+1] = pat_mid;
			end
		endcase
		@(negedge clk);
		cnt = cnt + 1;
	end
end endtask

//================================================================
// set_answer
//================================================================
task set_answer; begin
	if(pat_x >= 4 || pat_y >= 4) begin
		golden_ans[0]  = pat_map[0][0]; golden_ans[1]  = pat_map[0][2]; golden_ans[2]  = pat_map[0][4]; golden_ans[3]  = pat_map[0][6];
		golden_ans[4]  = pat_map[2][0]; golden_ans[5]  = pat_map[2][2]; golden_ans[6]  = pat_map[2][4]; golden_ans[7]  = pat_map[2][6];
		golden_ans[8]  = pat_map[4][0]; golden_ans[9]  = pat_map[4][2]; golden_ans[10] = pat_map[4][4]; golden_ans[11] = pat_map[4][6];
		golden_ans[12] = pat_map[6][0]; golden_ans[13] = pat_map[6][2]; golden_ans[14] = pat_map[6][4]; golden_ans[15] = pat_map[6][6];
	end
	else begin
		golden_ans[0]  = pat_map[pat_x+1][pat_y+1]; golden_ans[1]  = pat_map[pat_x+1][pat_y+2]; golden_ans[2]  = pat_map[pat_x+1][pat_y+3]; golden_ans[3]  = pat_map[pat_x+1][pat_y+4];
		golden_ans[4]  = pat_map[pat_x+2][pat_y+1]; golden_ans[5]  = pat_map[pat_x+2][pat_y+2]; golden_ans[6]  = pat_map[pat_x+2][pat_y+3]; golden_ans[7]  = pat_map[pat_x+2][pat_y+4];
		golden_ans[8]  = pat_map[pat_x+3][pat_y+1]; golden_ans[9]  = pat_map[pat_x+3][pat_y+2]; golden_ans[10] = pat_map[pat_x+3][pat_y+3]; golden_ans[11] = pat_map[pat_x+3][pat_y+4];
		golden_ans[12] = pat_map[pat_x+4][pat_y+1]; golden_ans[13] = pat_map[pat_x+4][pat_y+2]; golden_ans[14] = pat_map[pat_x+4][pat_y+3]; golden_ans[15] = pat_map[pat_x+4][pat_y+4];
	end
end endtask

//================================================================
// wait_out_valid
//================================================================
task wait_out_valid; begin
	lat = 0;
    while(out_valid !== 1) begin
		if(lat > 100) begin
			$display ("NO out_valid");
			repeat(5)@(negedge clk);
			$finish;
		end
        @(negedge clk);
		lat = lat + 1;
    end
end endtask

//================================================================
// check_ans
//================================================================
task check_ans; begin
	lat = 0;
	while (out_valid === 1) begin
		if(out_data != golden_ans[lat]) begin
			$display ("Wrong Answer %d", lat);
			repeat(20)@(negedge clk);
			$finish;
		end
		if(lat > 15) begin
			$display ("Wrong out_valid");
			repeat(5)@(negedge clk);
			$finish;
		end
		@(negedge clk);
		lat = lat + 1;
	end
	for(i=0; i<16; i=i+1) golden_ans[i] = 0;
	for(i=0; i<15; i=i+1)
		pat_op[i] <= 0;
	for(i=0; i<8; i=i+1)
		for(j=0; j<8; j=j+1)
			pat_map[i][j] <= 0;
end endtask

endmodule

