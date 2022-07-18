module ESCAPE(
    //Input Port
    clk,
    rst_n,
    in_valid1,
    in_valid2,
    in,
    in_data,
    //Output Port
    out_valid1,
    out_valid2,
    out,
    out_data
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid1, in_valid2;
input [1:0] in;
input [8:0] in_data;    
output reg	out_valid1, out_valid2;
output reg [2:0] out;
output reg [8:0] out_data;
//================================================//    
// ===============================================================
// Parameters & Integer Declaration
// ===============================================================
parameter s_idle      		    = 'd0;
parameter s_input1    		    = 'd1;
parameter s_output2   		    = 'd2;
parameter s_input2    		    = 'd3;
parameter s_calculate_sort1_x3  = 'd4;
parameter s_calculate_sort2_sub = 'd5;
parameter s_calculate_cum       = 'd6;
parameter s_calculate_final     = 'd7;
parameter s_output1             = 'd8;

parameter R = 'd0;
parameter D = 'd1;
parameter L = 'd2;
parameter U = 'd3;


// ===============================================================
// Wire & Reg Declaration
// ===============================================================
// state
reg [3:0] current_state, next_state;


// integer
integer i,j;

// map
reg [1:0] map [0:16][0:16];

// cnt
reg [4:0] cnt_input1[0:1];
reg [2:0] cnt_total_hostages;
reg [2:0] cnt_hostages_saved;
reg [2:0] cnt_data;

// stall
reg [2:0] out_stall;

// flag
reg flag_hostage;
reg flag_stall;
reg flag_finish;

// s_input2, hostage code
reg signed [8:0] data [0:3];
reg signed [8:0] data_1 [0:3];
reg signed [8:0] data_2 [0:3];
reg signed [8:0] data_3 [0:3];
reg signed [8:0] data_4 [0:3];
reg signed [8:0] data_5 [0:3];


// out_data tmp
reg signed [8:0] out_data_1 [0:3];
reg signed [8:0] out_data_2 [0:3];

// s_output2
reg [4:0] current_x;
reg [4:0] current_y;

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
reg signed [8:0]sorted_7[0:1];

// convert
reg signed [8:0]converted_1[0:3];


// check map
wire [1:0]check_map;
assign check_map = map[current_x][current_y];

reg [2:0] out_1;
reg out_valid2_1;


// ===============================================================
// DESIGN
// ===============================================================
// ===============================================================
// Finite State Machine
// ===============================================================
// current_state
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) current_state <= s_idle;
    else        current_state <= next_state;
end
// FSM
always@(*)begin
	case(current_state)
		s_idle: begin
			if(in_valid1)
				next_state = s_input1;					
			else
				next_state = current_state;
		end
		//==========================================//
		s_input1: begin
			if(!in_valid1)
					next_state = s_output2;
			else 
				next_state = current_state;
		end
		
		//==========================================//
		s_output2: begin
			if(flag_hostage == 1)
				next_state = s_input2;
			else if(flag_finish == 1) 
					next_state = s_calculate_sort1_x3;
			else
				next_state = current_state;
		end
		//==========================================//
		s_input2: begin
			if(flag_hostage == 0)
				next_state = s_output2;
			else
				next_state = current_state;
		end
		//==========================================//
		s_calculate_sort1_x3: begin 
			next_state = s_calculate_sort2_sub;
		end
		//==========================================//
		s_calculate_sort2_sub: begin
			next_state = s_calculate_cum;
		end
		//==========================================//
		s_calculate_cum: begin
			next_state = s_calculate_final;
		end
		//==========================================//
		s_calculate_final: begin
			next_state = s_output1;
		end
		//==========================================//
		s_output1: begin
			if(cnt_input1[0] < cnt_total_hostages)
				next_state = current_state;
			else
				next_state = s_idle;
		end
		//==========================================//
		default: begin
			next_state = current_state;
		end
	endcase

end
//================================================================
//  s_input1, map                
//================================================================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
	// cnt
	cnt_input1[0] <= 0;
	cnt_input1[1] <= 0;

	// map
	for(i=0; i<17; i=i+1)
		for(j=0; j<17; j=j+1)
			map[i][j] <= 0;
	end
	else begin
	case(next_state)
		s_idle: begin
			// cnt
			cnt_input1[0] <= 0;
			cnt_input1[1] <= 0;
			cnt_total_hostages <= 0;

			// map
			for(i=0; i<17; i=i+1)
				for(j=0; j<17; j=j+1)
					map[i][j] <= 0;
		end
		//==========================================//
		s_input1: begin
			// store map
			if(cnt_input1[1] < 16) begin
				map[cnt_input1[0]][cnt_input1[1]] <= in;
				cnt_input1[1] <= cnt_input1[1] + 1;
			end
			else begin
				map[cnt_input1[0]][16] <= in;
				cnt_input1[1] <= 0;
				cnt_input1[0] <= cnt_input1[0] + 1;
			end
			// store hostage
			if(in == 3) begin
				cnt_total_hostages <= cnt_total_hostages + 1;
			end
			else begin
			end
		end
		//==========================================//
		s_input2: begin
			// return to road after saving hostage
			map[current_x][current_y] <= 1;
		end
		//==========================================//
		s_output1: begin
			cnt_input1[0] <= cnt_input1[0] + 1;
		end
		//==========================================//
		default: begin
			cnt_input1[1] <= 0;
			cnt_input1[0] <= 0;
		end
	endcase
	end
end
//================================================================
//  s_output2
//================================================================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		// out_1
		out_1 <= 0;
		out_valid2_1 <= 0;
		out_stall <= 4;  // different from 0,1,2,3 

		// flag
		flag_hostage <= 0;
		flag_stall <= 0;
		flag_finish <= 0;
		
		// current_x, current_y
		current_x<=0;
		current_y<=0;
	end
	else begin
	case(next_state)
		//==========================================//
		s_idle:begin
			// out_1
			out_1 <= 0;
			out_valid2_1 <= 0;
			out_stall <= 4;  // different from 0,1,2,3 

			// flag
			flag_hostage <= 0;
			flag_stall <= 0;
			flag_finish <= 0;

			// current_x, current_y
			current_x <= 0;
			current_y <= 0;
		end
		//==========================================//
		s_output2:begin
			// hostage
			if(map[current_x][current_y] == 3) begin 		
				// out_valid2_1
				out_valid2_1 <= 0;

				// out_1
				out_1 <= 0;

				// flag									
				flag_hostage <= 1;
				flag_stall <= 0;
			end
			// trap
			else if(map[current_x][current_y] == 2) begin	
				//flag	
				flag_stall <= 1;

				// last out_1
				out_stall <= out_1;

				// out_1
				if(flag_stall == 0)
					out_1 <= 4;
				else
				begin
					case(out_stall)
						R: begin
							// up
							if(map[current_x-1][current_y] != 0  && current_x != 0)		
							begin
								out_valid2_1 <= 1;
								out_1 <= 3;
								current_x <= current_x - 1;
							end
							// right
							else if(map[current_x][current_y+1] != 0 && current_y != 16) 
							begin		
								out_valid2_1 <= 1;
								out_1 <= 0;
								current_y <= current_y + 1;
							end
							// down
							else if(map[current_x+1][current_y] != 0 && current_x != 16)
							begin
								out_valid2_1 <= 1;
								out_1 <= 1;
								current_x <= current_x + 1;
							end
							// left (back track)
							else begin		
							end
						end
						D: begin
							if(map[current_x][current_y+1] != 0 && current_y != 16)
							begin			
								out_valid2_1 <= 1;
								out_1 <= 0;
								current_y <= current_y + 1;
							end
							else if(map[current_x+1][current_y] != 0 && current_x != 16)
							begin		
								out_valid2_1 <= 1;
								out_1 <= 1;
								current_x <= current_x + 1;
							end
							else if(map[current_x][current_y-1] != 0 && current_y != 0)
							begin		
								out_valid2_1 <= 1;
								out_1 <= 2;
								current_y <= current_y - 1;
							end
							else begin															
							end
						end	
						L: begin
							if(map[current_x+1][current_y] != 0 && current_x != 16)
							begin			
								out_valid2_1 <= 1;
								out_1 <= 1;
								current_x <= current_x + 1;
							end
							else if(map[current_x][current_y-1] != 0 && current_y != 0)
							begin		
								out_valid2_1 <= 1;
								out_1 <= 2;
								current_y <= current_y - 1;
							end
							else if(map[current_x-1][current_y] != 0 && current_x != 0)
							begin		
								out_valid2_1 <= 1;
								out_1 <= 3;
								current_x <= current_x - 1;
							end
							else begin															
							end
						end	
						U: begin
							if(map[current_x][current_y-1] != 0 && current_y != 0)
							begin				
								out_valid2_1 <= 1;
								out_1 <= 2;
								current_y <= current_y - 1;
							end
							else if(map[current_x-1][current_y] != 0 && current_x != 0)
							begin		
								out_valid2_1 <= 1;
								out_1 <= 3;
								current_x <= current_x - 1;
							end
							else if(map[current_x][current_y+1] != 0 && current_y != 16)
							begin		
								out_valid2_1 <= 1;
								out_1 <= 0;
								current_y <= current_y + 1;
							end
							else begin														
							end
						end
						default:begin	
						end
					endcase
				end	
			end
			// road
			else begin
				flag_stall <= 0;
				if( ((current_x == 16) && (current_y == 16)) && (cnt_hostages_saved == cnt_total_hostages) ) begin // finish + hostages saved
					out_valid2_1 <= 0;
					out_1 <= 0;
					flag_finish <= 1;
				end
				else begin
					//out_valid2_1 <= 1;
					case(out_1)
						R: begin // right
							// up
							if(map[current_x-1][current_y] != 0  && current_x != 0)		
							begin
								out_valid2_1 <= 1;
								out_1 <= 3;
								current_x <= current_x - 1;
							end
							// right
							else if(map[current_x][current_y+1] != 0 && current_y != 16) 
							begin		
								out_valid2_1 <= 1;
								out_1 <= 0;
								current_y <= current_y + 1;
							end
							// down
							else if(map[current_x+1][current_y] != 0 && current_x != 16)
							begin
								out_valid2_1 <= 1;
								out_1 <= 1;
								current_x <= current_x + 1;
							end
							// left (back track)
							else begin	
								out_valid2_1 <= 1;
								out_1 <= 2;
								current_y <= current_y - 1;					
							end
							
						end
						D:begin // down
							if(map[current_x][current_y+1] != 0 && current_y != 16)
							begin			
								out_valid2_1 <= 1;
								out_1 <= 0;
								current_y <= current_y + 1;
							end
							else if(map[current_x+1][current_y] != 0 && current_x != 16)
							begin		
								out_valid2_1 <= 1;
								out_1 <= 1;
								current_x <= current_x + 1;
							end
							else if(map[current_x][current_y-1] != 0 && current_y != 0)
							begin		
								out_valid2_1 <= 1;
								out_1 <= 2;
								current_y <= current_y - 1;
							end
							else begin			
								out_valid2_1 <= 1;												
								out_1 <= 3;
								current_x <= current_x - 1;
							end
							
						end
						L:begin // left
							if(map[current_x+1][current_y] != 0 && current_x != 16)
							begin			
								out_valid2_1 <= 1;
								out_1 <= 1;
								current_x <= current_x + 1;
							end
							else if(map[current_x][current_y-1] != 0 && current_y != 0)
							begin		
								out_valid2_1 <= 1;
								out_1 <= 2;
								current_y <= current_y - 1;
							end
							else if(map[current_x-1][current_y] != 0 && current_x != 0)
							begin		
								out_valid2_1 <= 1;
								out_1 <= 3;
								current_x <= current_x - 1;
							end
							else begin			
								out_valid2_1 <= 1;												
								out_1 <= 0;
								current_y <= current_y + 1;
							end
						end
						U:begin //up
							if(map[current_x][current_y-1] != 0 && current_y != 0)
							begin			
								out_valid2_1 <= 1;	
								out_1 <= 2;
								current_y <= current_y - 1;
							end
							else if(map[current_x-1][current_y] != 0 && current_x != 0)
							begin		
								out_valid2_1 <= 1;
								out_1 <= 3;
								current_x <= current_x - 1;
							end
							else if(map[current_x][current_y+1] != 0 && current_y != 16)
							begin		
								out_valid2_1 <= 1;
								out_1 <= 0;
								current_y <= current_y + 1;
							end
							else begin			
								out_valid2_1 <= 1;													
								out_1 <= 1;
								current_x <= current_x + 1;
							end
						end
						default:
							out_valid2_1 <= 1;
				endcase
				end		
			end
		end	
		//==========================================//
		s_input2: begin
			if(in_valid2)
				flag_hostage <= 0;
			else begin
			end
		end
		default: begin
			flag_finish <= 0;
		end
		//==========================================//
	endcase
	end
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		out <= 0;
		out_valid2 <= 0;
	end
	else begin
	case(current_state)
		s_idle:	begin
			out <= 0;
			out_valid2 <= 0;
		end
		s_output2:	begin
			out <= out_1;
			out_valid2 <= out_valid2_1;
		end
		default:begin
			out <= 0;
			out_valid2 <= 0;
		end
	endcase
	end
end
//================================================================
//  s_input2              
//================================================================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		// cnt
		cnt_hostages_saved <= 0;
		// data
		for(i=0;i<4; i=i+1)
			data[i] <= 0;
	end
	else begin
		case(next_state)
			s_idle: begin
				// cnt
				cnt_hostages_saved <= 0;
				// data
				for(i=0;i<4; i=i+1)
					data[i] <= 0;
			end
			s_input2: begin
				if(in_valid2)
				begin
					data[cnt_hostages_saved] <= in_data;
					cnt_hostages_saved <= cnt_hostages_saved + 1;
				end
				else begin
				end
			end
			default: begin
			end
		endcase
	end
end
//================================================================
//  s_calculate sequencial sort1_x3,  data_1 <= data
//================================================================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0; i<4; i=i+1)
			data_1[i] <= 0;
	end
	else begin
		case(next_state)
			s_idle: begin
				for(i=0; i<4; i=i+1)
					data_1[i] <= 0;
			end
			s_calculate_sort1_x3: begin
				for(i=0; i<4; i=i+1)
					data_1[i] <= data[i];
			end
			default: begin
			end
		endcase
	end
end
//================================================================
//  s_calculate combination1 sort1_x3,  data_2 <= data_1
//================================================================
always@* 
begin
	// zero
	for(i=0; i<4; i=i+1)
	begin
		data_2[i] = 0;
		// sort
		sorted[i] = 0;
		sorted_1[i] = 0;
		sorted_2[i] = 0;
		sorted_3[i] = 0;
		// convert
		converted_1[i] =0;
	end
	case(cnt_total_hostages)
		0:	begin
			for(i=0; i<4; i=i+1)
			begin
				data_2[i] = 0;
			end
			// zero

			for(i=0; i<4; i=i+1)
			begin
				// sort
				sorted[i] = 0;
				sorted_1[i] = 0;
				sorted_2[i] = 0;
				sorted_3[i] = 0;
				// convert
				converted_1[i] =0;
			end
		end
		1:	begin
			for(i=0; i<4; i=i+1)
			begin
				data_2[i] = data_1[i];
			end
			// zero
			for(i=1; i<4; i=i+1)
				data_2[i] = 0;
			
			for(i=0; i<4; i=i+1)
			begin
				// sort
				sorted[i] = 0;
				sorted_1[i] = 0;
				sorted_2[i] = 0;
				sorted_3[i] = 0;
				// convert
				converted_1[i] =0;
			end
		end 
		2:	begin
			// sort
			{sorted[0], sorted[1]} = (data_1[0] > data_1[1]) ? {data_1[0], data_1[1]} : {data_1[1], data_1[0]};
			
			// convert to XS-3

			for(i = 0; i < 2; i = i + 1) 
			begin
				converted_1[i] = 10 * sorted[i][7:4] + sorted[i][3:0] - 33;
				if(sorted[i][8]) data_2[i] = ~converted_1[i] + 1;
				else data_2[i] = converted_1[i];
			end

			// zero
			for(i=2; i<4; i=i+1)
				data_2[i] = 0;
			sorted[2] = 0;
			sorted[3] = 0;
			for(i=0; i<4; i=i+1)
			begin
				// sort
				sorted_1[i] = 0;
				sorted_2[i] = 0;
				sorted_3[i] = 0;
			end
		end
		3:	begin
			// sort
			{sorted[0], sorted[1]} = (data_1[0] > data_1[1]) ? {data_1[0], data_1[1]} : {data_1[1], data_1[0]};
			sorted[2] = data_1[2];

			{sorted_1[1], sorted_1[2]} = (sorted[1] > sorted[2]) ? {sorted[1], sorted[2]} : {sorted[2], sorted[1]};
			sorted_1[0] = sorted[0];

			{data_2[0], data_2[1]} = (sorted_1[0] > sorted_1[1]) ? {sorted_1[0], sorted_1[1]} : {sorted_1[1], sorted_1[0]};
			data_2[2] = sorted_1[2];
			// zero
			for(i=3; i<4; i=i+1)
				data_2[i] = 0;

			sorted[3] = 0;
			sorted_1[3] = 0;
			for(i=0; i<4; i=i+1)
			begin
				// sort
				sorted_2[i] = 0;
				sorted_3[i] = 0;
				// convert
				converted_1[i] =0;
			end

		end
		4:	begin
			// sort
			{sorted[0], sorted[1]} = (data_1[0] > data_1[1]) ? {data_1[0], data_1[1]} : {data_1[1], data_1[0]};
			{sorted[2], sorted[3]} = (data_1[2] > data_1[3]) ? {data_1[2], data_1[3]} : {data_1[3], data_1[2]};
			
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
				if(sorted_3[i][8]) data_2[i] = ~converted_1[i] + 1;
				else data_2[i] = converted_1[i];
			end	
		end
		default: begin
			// zero
			for(i=0; i<4; i=i+1)
			begin
				data_2[i] = 0;
				// sort
				sorted[i] = 0;
				sorted_1[i] = 0;
				sorted_2[i] = 0;
				sorted_3[i] = 0;
				// convert
				converted_1[i] =0;
			end
		end
	endcase
end
//================================================================
//  s_calculate sequencial sort2_sub,  data_3 <= data_2
//================================================================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0; i<4; i=i+1)
			data_3[i] <= 0;
	end
	else begin
		case(next_state)
			s_idle: begin
				for(i=0; i<4; i=i+1)
					data_3[i] <= 0;
			end
			s_calculate_sort2_sub: begin
				for(i=0; i<4; i=i+1)
					data_3[i] <= data_2[i];
			end
			default: begin
			end
		endcase
	end
end
//================================================================
//  s_calculate combination1 sort2_sub,  data_4 <= data_3
//================================================================
always@* 
begin
	// zero
	for(i=0; i<4; i=i+1)
	begin
		data_4[i] = 0;
		// sort
		sorted_4[i] = 0;
		sorted_5[i] = 0;
		sorted_6[i] = 0;
	end
	half_of_range = 0;
	case(cnt_total_hostages)
		0:	begin
			for(i=0; i<4; i=i+1)
			begin
				data_4[i] = data_3[i];
			end

			// zero
			for(i=0; i<4; i=i+1)
			begin
				// sort
				sorted_4[i] = 0;
				sorted_5[i] = 0;
				sorted_6[i] = 0;
			end
			half_of_range = 0;
		end
		1:	begin
			for(i=0; i<4; i=i+1)
			begin
				data_4[i] = data_3[i];
			end

			// zero
			for(i=0; i<4; i=i+1)
			begin
				// sort
				sorted_4[i] = 0;
				sorted_5[i] = 0;
				sorted_6[i] = 0;
			end
			half_of_range = 0;
		end 
		2:	begin
			half_of_range = (data_3[0] + data_3[1])/2;
			for(i = 0; i < 2; i = i + 1) 
			begin
				data_4[i] = data_3[i] - half_of_range;
			end
			// zero
			for(i=2; i<4; i=i+1)
				data_4[i] = 0;

			for(i=0; i<4; i=i+1)
			begin
				// sort
				sorted_4[i] = 0;
				sorted_5[i] = 0;
				sorted_6[i] = 0;
			end
		end
		3:	begin
			half_of_range = (data_3[0] + data_3[2])/2;
			for(i = 0; i < 3; i = i + 1) 
			begin
				data_4[i] = data_3[i] - half_of_range;
			end

			// zero
			for(i=3; i<4; i=i+1)
				data_4[i] = 0;

			for(i=0; i<4; i=i+1)
			begin
				// sort
				sorted_4[i] = 0;
				sorted_5[i] = 0;
				sorted_6[i] = 0;
			end
		end
		4:	begin
			{sorted_4[0], sorted_4[1]} = (data_3[0] > data_3[1]) ? {data_3[0], data_3[1]} : {data_3[1], data_3[0]};
			{sorted_4[2], sorted_4[3]} = (data_3[2] > data_3[3]) ? {data_3[2], data_3[3]} : {data_3[3], data_3[2]};
			
			{sorted_5[1], sorted_5[2]} = (sorted_4[1] > sorted_4[2]) ? {sorted_4[1], sorted_4[2]} : {sorted_4[2], sorted_4[1]};
			sorted_5[0] = sorted_4[0];
			sorted_5[3] = sorted_4[3];

			{sorted_6[0], sorted_6[1]} = (sorted_5[0] > sorted_5[1]) ? {sorted_5[0], sorted_5[1]} : {sorted_5[1], sorted_5[0]};
			{sorted_6[2], sorted_6[3]} = (sorted_5[2] > sorted_5[3]) ? {sorted_5[2], sorted_5[3]} : {sorted_5[3], sorted_5[2]};

			//{sorted_7[1], sorted_7[2]} = (sorted_7[1] > sorted_7[2]) ? {sorted_7[1], sorted_7[2]} : {sorted_7[2], sorted_7[1]};
			sorted_7[0] = sorted_6[0];
			sorted_7[1] = sorted_6[3];
			
			
			// substract half of range
			half_of_range = (sorted_7[0] + sorted_7[1])/2;
			for(i = 0; i < 4; i = i + 1) 
			begin
				data_4[i] = data_3[i] - half_of_range;
			end
		end
		default: begin
			// zero
			for(i=0; i<4; i=i+1)
			begin
				data_4[i] = 0;
				// sort
				sorted_4[i] = 0;
				sorted_5[i] = 0;
				sorted_6[i] = 0;
			end
			half_of_range = 0;
		end
	endcase
end
//================================================================
//  s_calculate sequencial cum,           data_5 <= data_4
//================================================================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0; i<4; i=i+1)
			data_5[i] <= 0;
	end
	else begin
		case(next_state)
			s_idle: begin
				for(i=0; i<4; i=i+1)
					data_5[i] <= 0;
			end
			s_calculate_cum: begin
				for(i=0; i<4; i=i+1)
					data_5[i] <= data_4[i];
			end
			default: begin
			end
		endcase
	end
end
//================================================================
//  s_calculate combination1 cum,        out_data_1 <= data5
//================================================================
always@* 
begin
	// zero
	for(i=0; i<4; i=i+1)
	begin
		out_data_1[i] = 0;
	end
	case(cnt_total_hostages)
		0:	begin
			for(i=0; i<4; i=i+1)
			begin
				out_data_1[i] = data_5[i];
			end
		end
		1:	begin
			for(i=0; i<4; i=i+1)
			begin
				out_data_1[i] = data_5[i];
			end
		end 
		2:	begin
			for(i=0; i<4; i=i+1)
			begin
				out_data_1[i] = data_5[i];
			end
		end
		3:	begin
			out_data_1[0] = data_5[0];
			out_data_1[1] = ( (out_data_1[0] <<< 1) + data_5[1])/3;
			out_data_1[2] = ( (out_data_1[1] <<< 1) + data_5[2])/3;
			out_data_1[3] = 0;
		end
		4:	begin
			out_data_1[0] = data_5[0];
			out_data_1[1] = ( (out_data_1[0] <<< 1) + data_5[1])/3;
			out_data_1[2] = ( (out_data_1[1] <<< 1) + data_5[2])/3;
			out_data_1[3] = ( (out_data_1[2] <<< 1) + data_5[3])/3;
		end
		default: begin
			// zero
			for(i=0; i<4; i=i+1)
			begin
				out_data_1[i] = 0;
			end
		end
	endcase
end
//================================================================
//  s_calculate sequencial cum,        out_data_1 <= out_data_2
//================================================================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0; i<4; i=i+1)
			out_data_2[i] <= 0;
	end
	else begin
		case(next_state)
			s_idle: begin
				for(i=0; i<4; i=i+1)
					out_data_2[i] <= 0;
			end
			s_calculate_final: begin
				for(i=0; i<4; i=i+1)
					out_data_2[i] <= out_data_1[i];
			end
			default: begin
			end
		endcase
	end
end
//================================================================
//  s_output1
//================================================================
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_data <= 0;
		out_valid1 <= 0;
	end
	else begin
		case(next_state)
			s_idle: begin 
				out_data <= 0;
				out_valid1 <= 0;
			end
			//==========================================//
			s_output1: begin
				out_valid1 <= 1;
				out_data <= out_data_2[cnt_input1[0]];
			end
			//==========================================//
			default: begin
				out_data <= 0;
				out_valid1 <= 0;
			end
		endcase
	end
end

endmodule
