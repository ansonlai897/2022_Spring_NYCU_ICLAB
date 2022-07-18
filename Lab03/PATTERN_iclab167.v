`ifdef RTL
    `timescale 1ns/10ps
    `define CYCLE_TIME 15.0
`endif
`ifdef GATE
    `timescale 1ns/10ps
    `define CYCLE_TIME 15.0
`endif

module PATTERN(
    // Output signals
	clk,
    rst_n,
	in_valid1,
	in_valid2,
	in,
	in_data,
    // Input signals
    out_valid1,
	out_valid2,
    out,
	out_data
);

output reg clk, rst_n, in_valid1, in_valid2;
output reg [1:0] in;
output reg [8:0] in_data;
input out_valid1, out_valid2;
input [2:0] out;
input [8:0] out_data;

//================================================================
// wires & registers
//================================================================
wire [4:0]check_maze;


reg [4:0] position_x;
reg [4:0] position_y;
reg [1:0] maze [0:18][0:18];

assign check_maze = maze[position_x][position_y];


reg [4:0] hostages_saved;
reg [8:0] in_data_arr [0:3];
reg signed [8:0] in_data_arr_1 [0:3];
reg signed [8:0] golden_out_data [0:3];
reg signed [10:0] golden_step;
reg [3:0] tmp2, tmp3;
reg tmp1;

// s_calculate
reg signed[8:0] half_of_range;

// sort
reg signed [8:0]sorted[0:3];
reg signed [8:0]sorted_1[0:3];
reg signed [8:0]sorted_2[0:3];
reg signed [8:0]sorted_3[0:3];
reg signed [8:0]sorted_4[0:3];
reg signed [8:0]sorted_5[0:3];
reg signed [8:0]sorted_6[0:3];
reg signed [8:0]sorted_7[0:3];

// convert
reg signed [8:0]converted[0:3];
reg signed [8:0]converted_1[0:3];

// substract
reg signed[8:0]substracted[0:3];
//================================================================
// parameters & integer
//================================================================
integer total_hostages;
integer input_patcount;
integer seed, seed1, seed2, seed3;
integer total_cycles;
integer patcount;
integer cycles;
integer gap;
integer a, b, i, j, input_file, flag_finish_rescue;


parameter PATNUM = 500;
//================================================================
// clock
//================================================================
always	#(`CYCLE_TIME/2.0) clk = ~clk;
initial	clk = 0;

//================================================================
// initial
//================================================================
always@*
begin
	if(rst_n)
	begin
		if(out_valid2 === 0 && out !== 0 )begin
			$display ("SPEC 4 IS FAIL!");
			repeat(2)@(negedge clk);
			$finish;
		end
		if(out_valid1 === 1 && (out_valid2 === 1 || in_valid1 === 1 || in_valid2 === 1)) begin
			$display ("SPEC 5 IS FAIL!");
			repeat(2)@(negedge clk);
			$finish;
		end
		if(out_valid2 === 1 && (out_valid1 === 1 || in_valid1 === 1 || in_valid2 === 1)) begin
			$display ("SPEC 5 IS FAIL!");
			repeat(2)@(negedge clk);
			$finish;
		end
		if(in_valid1 === 1 && (out_valid1 === 1 || out_valid2 === 1 || in_valid2 === 1)) begin
			$display ("SPEC 5 IS FAIL!");
			repeat(2)@(negedge clk);
			$finish;
		end
		if(in_valid2 === 1 && (out_valid1 === 1 || out_valid2 === 1 || in_valid1 === 1)) begin
			$display ("SPEC 5 IS FAIL!");
			repeat(2)@(negedge clk);
			$finish;
		end
	end	
end
initial begin
	rst_n		   = 1'b1;
	in_valid1	   = 1'b0;
	in_valid2 	   = 1'b0;
	in       	   =  'dx;
	total_hostages = 0;
	hostages_saved = 0;
	in_data 	   = 'dx;
	seed 		   = 19;
	seed1          = 200;
	seed2          = 215;
	seed3          = 122;
	position_x     = 1;
	position_y     = 1;
	golden_step    = 0;
	golden_out_data[0] = 0;
	golden_out_data[1] = 0;
	golden_out_data[2] = 0;
	golden_out_data[3] = 0;
	
	force clk = 0;
	total_cycles = 0;
	reset_task;

	input_file=$fopen("../00_TESTBED/input.txt","r");
    @(negedge clk);

	for (patcount=0;patcount<PATNUM;patcount=patcount+1) begin
		input_data;
		for(i=0; i<total_hostages; i=i+1)begin
			wait_out_valid2;
			check_ans_in_maze;
		end
		wait_out_valid1;
		check_ans_finish_2;
		$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %3d\033[m", patcount ,cycles);
		gap = $urandom_range(1,3);
		repeat(gap) @(negedge clk);
		//@(negedge clk);
		
	end
	#(1000);
	YOU_PASS_task;
	$finish;
end

task reset_task ; 
begin
	#(10); rst_n = 0;

	#(10);
	if((out !== 0) || (out_valid1 !== 0) || (out_valid2 !== 0) || out_data !== 0) begin
		$display ("SPEC 3 IS FAIL!");
		#(100);
	    $finish ;
	end
	
	#(10); rst_n = 1 ;
	#(3.0); release clk;
end endtask

task input_data ; 
begin
	// =============================================================== //
	// input maze
	// =============================================================== //
	position_x = 1;
	position_y = 1;
	cycles = 0;
	in_valid1 = 'b1;
	for(i=0;i<=18;i=i+1)begin
		maze[0][i] = 0;
		maze[18][i] = 0;
	end
	for(i=1;i<=17;i=i+1)begin
		maze[i][0] = 0;
		maze[i][18] = 0;
	end
	for(i=1;i<=17;i=i+1)begin
		for(j=1;j<=17;j=j+1)begin
			b = $fscanf(input_file,"%d",in);
			maze[i][j] = in;
			if(in == 3) total_hostages = total_hostages + 1;
			if((out_valid1 === 1) || (out_valid2 === 1))begin
				$display ("SPEC 5 IS FAIL!");
				repeat(2)@(negedge clk);
				$finish;
			end
			@(negedge clk);
		end
	end
	in_valid1     = 'b0;
	in			 = 'bx;

	// =============================================================== //
	// generate golden
	// =============================================================== //
	// code
	if(total_hostages %2 == 1) begin
		for(i=0; i<total_hostages; i=i+1)
			in_data_arr[i] = $random(seed)%'d257;
	end
	else begin
		for(i=0; i<total_hostages; i=i+1) begin
			tmp1 = $random(seed1)%'d2;
			tmp2 = (($random(seed2)%'d10) + 3);
			tmp3 = ($random(seed3)%'d10) + 3;
			in_data_arr[i] = {tmp1, tmp2, tmp3};
		end
	end

	for(i=0; i<total_hostages; i=i+1) begin
		in_data_arr_1[i] = in_data_arr[i];
	end

	
	// decode
	case(total_hostages)
		0: golden_out_data[0] = 0;
		1: golden_out_data[0] = in_data_arr_1[0];
		2: begin
			// sort
			{sorted[0], sorted[1]} = (in_data_arr_1[0] > in_data_arr_1[1]) ? {in_data_arr_1[0], in_data_arr_1[1]} : {in_data_arr_1[1], in_data_arr_1[0]};

			for(i = 0; i < 2; i = i + 1) 
			begin
				converted_1[i] = 10 * sorted[i][7:4] + sorted[i][3:0] - 33;
				if(sorted[i][8]) converted[i] = ~converted_1[i] + 1;
				else converted[i] = converted_1[i];
			end

			// substract half of range
			half_of_range = (converted[0] + converted[1])/2;
			for(i = 0; i < 2; i = i + 1) 
			begin
				golden_out_data[i] = converted[i] - half_of_range;
			end
		end
		3: begin
			// sort
			{sorted[0], sorted[1]} = (in_data_arr_1[0] > in_data_arr_1[1]) ? {in_data_arr_1[0], in_data_arr_1[1]} : {in_data_arr_1[1], in_data_arr_1[0]};
			sorted[2] = in_data_arr_1[2];

			{sorted_1[1], sorted_1[2]} = (sorted[1] > sorted[2]) ? {sorted[1], sorted[2]} : {sorted[2], sorted[1]};
			sorted_1[0] = sorted[0];

			{sorted_2[0], sorted_2[1]} = (sorted_1[0] > sorted_1[1]) ? {sorted_1[0], sorted_1[1]} : {sorted_1[1], sorted_1[0]};
			sorted_2[2] = sorted_1[2];

			// convert to XS-3 (same)

			// substract half of range
			half_of_range = (sorted_2[0] + sorted_2[2])/2;
			for(i = 0; i < 3; i = i + 1) 
			begin
				substracted[i] = sorted_2[i] - half_of_range;
			end

			// Cumulation
			golden_out_data[0] = substracted[0];
			golden_out_data[1] = (golden_out_data[0]*2 + substracted[1])/3;
			golden_out_data[2] = (golden_out_data[1]*2 + substracted[2])/3;
		end
		4: begin
			// sort
			{sorted[0], sorted[1]} = (in_data_arr_1[0] > in_data_arr_1[1]) ? {in_data_arr_1[0], in_data_arr_1[1]} : {in_data_arr_1[1], in_data_arr_1[0]};
			{sorted[2], sorted[3]} = (in_data_arr_1[2] > in_data_arr_1[3]) ? {in_data_arr_1[2], in_data_arr_1[3]} : {in_data_arr_1[3], in_data_arr_1[2]};
			
			{sorted_1[1], sorted_1[2]} = (sorted[1] > sorted[2]) ? {sorted[1], sorted[2]} : {sorted[2], sorted[1]};
			sorted_1[0] = sorted[0];
			sorted_1[3] = sorted[3];

			{sorted_2[0], sorted_2[1]} = (sorted_1[0] > sorted_1[1]) ? {sorted_1[0], sorted_1[1]} : {sorted_1[1], sorted_1[0]};
			{sorted_2[2], sorted_2[3]} = (sorted_1[2] > sorted_1[3]) ? {sorted_1[2], sorted_1[3]} : {sorted_1[3], sorted_1[2]};

			{sorted_3[1], sorted_3[2]} = (sorted_2[1] > sorted_2[2]) ? {sorted_2[1], sorted_2[2]} : {sorted_2[2], sorted_2[1]};
			sorted_3[0] = sorted_2[0];
			sorted_3[3] = sorted_2[3];

			// convert to XS-3
			for(i = 0; i < 4; i = i + 1) 
			begin
				converted_1[i] = 10 * sorted_3[i][7:4] + sorted_3[i][3:0] - 33;
				if(sorted_3[i][8]) converted[i] = ~converted_1[i] + 1;
				else converted[i] = converted_1[i];
			end

			// sort again
			{sorted_4[0], sorted_4[1]} = (converted[0] > converted[1]) ? {converted[0], converted[1]} : {converted[1], converted[0]};
			{sorted_4[2], sorted_4[3]} = (converted[2] > converted[3]) ? {converted[2], converted[3]} : {converted[3], converted[2]};
			
			{sorted_5[1], sorted_5[2]} = (sorted_4[1] > sorted_4[2]) ? {sorted_4[1], sorted_4[2]} : {sorted_4[2], sorted_4[1]};
			sorted_5[0] = sorted_4[0];
			sorted_5[3] = sorted_4[3];

			{sorted_6[0], sorted_6[1]} = (sorted_5[0] > sorted_5[1]) ? {sorted_5[0], sorted_5[1]} : {sorted_5[1], sorted_5[0]};
			{sorted_6[2], sorted_6[3]} = (sorted_5[2] > sorted_5[3]) ? {sorted_5[2], sorted_5[3]} : {sorted_5[3], sorted_5[2]};

			{sorted_7[1], sorted_7[2]} = (sorted_6[1] > sorted_6[2]) ? {sorted_6[1], sorted_6[2]} : {sorted_6[2], sorted_6[1]};
			sorted_7[0] = sorted_6[0];
			sorted_7[3] = sorted_6[3];
			
			
			// substract half of range
			half_of_range = (sorted_7[0] + sorted_7[3])/2;
			for(i = 0; i < 4; i = i + 1) 
			begin
				substracted[i] = converted[i] - half_of_range;
			end

			// Cumulation
			golden_out_data[0] = substracted[0];
			golden_out_data[1] = (golden_out_data[0]*2 + substracted[1])/3;
			golden_out_data[2] = (golden_out_data[1]*2 + substracted[2])/3;
			golden_out_data[3] = (golden_out_data[2]*2 + substracted[3])/3;
		end
	endcase
	@(negedge clk);
end endtask

task wait_out_valid2; 
begin
	while(out_valid2 === 0)begin
		cycles = cycles + 1;
		if(cycles == 3000) begin
			$display ("SPEC 6 IS FAIL!");
			repeat(2)@(negedge clk);
			$finish;
		end
		@(negedge clk);
	end
	//total_cycles = total_cycles + cycles;
end endtask

task check_ans_in_maze; 
begin
	while(out_valid2 === 1)begin
		cycles = cycles + 1;
		// latency
		if(cycles == 3000) begin
			$display ("SPEC 6 IS FAIL!");
			repeat(2)@(negedge clk);
			$finish;
		end
		// overlap in_valid2
		if(in_valid2 === 1)begin
			$display ("SPEC 5 IS FAIL!");
			repeat(2)@(negedge clk);
			$finish;
		end

		// overlap out_valid1
		if( out_valid1 === 1 ) begin
			$display ("SPEC 5 IS FAIL!");
			repeat(2)@(negedge clk);
			$finish;
		end

		// hit the wall
		if(maze[position_x][position_y] == 0)begin
			$display ("SPEC 7 IS FAIL!");
			repeat(2)@(negedge clk);
			$finish;
		end

		// illegal out
		if( out >= 5 || out < 0) begin
			$display ("SPEC 7 IS FAIL!");
			repeat(2)@(negedge clk);
			$finish;
		end
		// move
		case(out)
			0:	position_y = position_y+1;
			1:	position_x = position_x+1;
			2:	position_y = position_y-1;
			3:	position_x = position_x-1;
			4:	begin
				position_x = position_x;
				position_y = position_y;
				if(maze[position_x][position_y] != 2) begin
					$display ("SPEC 7 IS FAIL!");
					repeat(2)@(negedge clk);
					$finish;
				end
			end
			default: begin
				position_x = position_x;
				position_y = position_y;
			end
		endcase
		@(negedge clk);
	end
	if(out_valid2 == 0)begin
		if(out !== 0)begin
			$display ("SPEC 4 IS FAIL!");
			@(negedge clk);
			$finish;
		end

		if( (position_x !== 17 || position_y !== 17) && maze[position_x][position_y] !== 3 )begin
			$display ("SPEC 8 IS FAIL!");
			repeat(2)@(negedge clk);
			$finish;
		end
	end
	if(maze[position_x][position_y] === 3) begin 
		gap = $urandom_range(2,4);
		repeat(gap) @(negedge clk);
		in_valid2 = 'b1;
		// generate in_data
		in_data = in_data_arr[hostages_saved];
		if(out_valid1 === 1 || out_valid2 === 1)begin
			$display ("SPEC 5 IS FAIL!");
			repeat(2)@(negedge clk);
			$finish;     
		end
		
		@(negedge clk);
		in_valid2     = 'b0;
		in_data		  = 'bx;
		cycles = cycles + 1;
		hostages_saved = hostages_saved + 1;
	end
end endtask

task check_ans_finish_1;
begin
	cycles = cycles + 1;
	if( (position_x !== 17 || position_y !== 17) )begin
		$display ("SPEC 8 IS FAIL!");
		repeat(2)@(negedge clk);
		$finish;
	end
	else if(hostages_saved !== total_hostages) begin
		$display ("SPEC 8 IS FAIL!");
		repeat(2)@(negedge clk);
		$finish;
	end

	if(out !== 0)begin
		$display ("SPEC 4 IS FAIL!");
		repeat(2)@(negedge clk);
		$finish;
	end
end endtask

task wait_out_valid1; 
begin
	while(out_valid1 === 0)begin
		cycles = cycles + 1;
		if(cycles == 3000) begin
			$display ("SPEC 6 IS FAIL!");
			repeat(2)@(negedge clk);
			$finish;
		end
		@(negedge clk);
	end
end endtask

task check_ans_finish_2;
begin
	// ===============================================================
	// Finish the maze & out_data is valid
	// ===============================================================
	while(out_valid1 === 1)begin
		// overlap out_valid2
		if( out_valid2 === 1 ) begin
			$display ("SPEC 5 IS FAIL!");
			repeat(2)@(negedge clk);
			$finish;
		end

		if( out_data != golden_out_data[golden_step]) begin
			$display ("SPEC 10 IS FAIL!");
			repeat(2)@(negedge clk);
			$finish;
		end
		@(negedge clk);
		golden_step = golden_step + 1;
	end

	if(hostages_saved != 0)begin
		if(golden_step != total_hostages) begin
			$display ("SPEC 9 IS FAIL!");
			repeat(2)@(negedge clk);
			$finish;
		end
	end
	if(hostages_saved == 0)begin
		if(golden_step != 1) begin
			$display ("SPEC 9 IS FAIL!");
			repeat(2)@(negedge clk);
			$finish;
		end
	end
	// ===============================================================
	// out_valid1 = 0
	// ===============================================================

	if(out_valid1 === 0 )begin
		golden_step = 0;
		for(i=0; i<4; i=i+1)
		begin
			// sort
			sorted[i] = 0;
			sorted_1[i] = 0;
			sorted_2[i] = 0;
			sorted_3[i] = 0;
			// convert
			converted_1[i] = 0;
			converted[i] = 0;
			// substract
			substracted[i] = 0;
			golden_out_data[i] = 0;
			in_data_arr_1[i] = 0;
			in_data_arr[i] = 0;

		end
		half_of_range = 0;
		total_hostages = 0;
		hostages_saved = 0;

		if(out_data !== 0)begin
			$display ("SPEC 11 IS FAIL!");
			repeat(2)@(negedge clk);
			$finish;
		end
	end
	@(negedge clk);
	total_cycles = total_cycles + cycles;
end endtask

task YOU_PASS_task;
	begin
	$display ("----------------------------------------------------------------------------------------------------------------------");
	$display ("                                                  Congratulations!                						            ");
	$display ("                                           You have passed all patterns!          						            ");
	$display ("                                           Your execution cycles = %5d cycles   						            ", total_cycles);
	$display ("                                           Your clock period = %.1f ns        					                ", `CYCLE_TIME);
	$display ("                                           Your total latency = %.1f ns         						            ", total_cycles * `CYCLE_TIME);
	$display ("----------------------------------------------------------------------------------------------------------------------");
	$finish;
	end
endtask

endmodule