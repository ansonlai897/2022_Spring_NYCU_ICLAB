module IDC(
	// Input signals
	clk,
	rst_n,
	in_valid,
	in_data,
	op,
	// Output signals
	out_valid,
	out_data
);

// ===============================================================
// INPUT AND OUTPUT DECLARATION  
// ===============================================================
input		clk;
input		rst_n;
input		in_valid;
input signed [6:0] in_data;
input [3:0] op;

output reg 		  out_valid;//
output reg  signed [6:0] out_data;

// ===============================================================
// Parameters
// ===============================================================
parameter IDLE  	= 'd0;
parameter INPUT 	= 'd1;
parameter SET_OP	= 'd2;
parameter OPERATION = 'd3;
parameter SET_OUT	= 'd4;
parameter OUT		= 'd5;
parameter RESET		= 'd6;


parameter Midpoint 	= 'd0;
parameter Average	= 'd1;
parameter Inv_clk	= 'd2;
parameter Clock		= 'd3;
parameter Flip		= 'd4;
parameter Up		= 'd5;
parameter Left		= 'd6;
parameter Down		= 'd7;
parameter Right		= 'd8;

integer i, j;
// ===============================================================
// Wire & Reg Declaration
// ===============================================================
// state
reg [5:0] current_state, next_state;

// cnt
reg [3:0] cnt;
reg [3:0] cnt_1;
reg [3:0] cnt_op;
reg [6:0] cnt_out;

// op
reg [3:0] op_reg [0:14];

// map
reg signed [6:0] map [0:7][0:7];

// x, y
reg [2:0] current_x;
reg [2:0] current_y;

// flag
reg flag_finish;
wire flag_zoom = (next_state == OUT) ? (current_x >= 4 || current_y >= 4) : 0;

// ===============================================================
// IP
// ===============================================================

wire signed [6:0] x_plus_one = current_x + 1;
wire signed [6:0] y_plus_one = current_y + 1;
wire signed [6:0] average_sol, mid_sol;
wire signed [6:0] in_a0 = (next_state == OPERATION && op_reg[0] == Average ) ? map[current_x][current_y]: 0;
wire signed [6:0] in_a1 = (next_state == OPERATION && op_reg[0] == Average ) ? map[x_plus_one][current_y]: 0;
wire signed [6:0] in_a2 = (next_state == OPERATION && op_reg[0] == Average ) ? map[current_x][y_plus_one]: 0;
wire signed [6:0] in_a3 = (next_state == OPERATION && op_reg[0] == Average ) ? map[x_plus_one][y_plus_one]: 0;

wire signed [6:0] in_m0 = (next_state == OPERATION && op_reg[0] == Midpoint ) ? map[current_x][current_y]: 0;
wire signed [6:0] in_m1 = (next_state == OPERATION && op_reg[0] == Midpoint ) ? map[x_plus_one][current_y]: 0;
wire signed [6:0] in_m2 = (next_state == OPERATION && op_reg[0] == Midpoint ) ? map[current_x][y_plus_one]: 0;
wire signed [6:0] in_m3 = (next_state == OPERATION && op_reg[0] == Midpoint ) ? map[x_plus_one][y_plus_one]: 0;

//Average_ip  A1(.a0(map[current_x][current_y]), .a1(map[x_plus_one][current_y]), .a2(map[current_x][y_plus_one]), .a3(map[x_plus_one][y_plus_one]), .out(average_sol));
//Midpoint_ip M1(.m0(map[current_x][current_y]), .m1(map[x_plus_one][current_y]), .m2(map[current_x][y_plus_one]), .m3(map[x_plus_one][y_plus_one]), .out(mid_sol));
Average_ip  A1(.a0(in_a0), .a1(in_a1), .a2(in_a2), .a3(in_a3), .out(average_sol));
Midpoint_ip M1(.m0(in_m0), .m1(in_m1), .m2(in_m2), .m3(in_m3), .out(mid_sol));
// ===============================================================
// FSM
// ===============================================================
// current_state
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) current_state <= IDLE;
    else        current_state <= next_state;
end
// FSM
always@(*)begin
	case(current_state)
		IDLE: begin
			if(in_valid)	next_state = INPUT;
			else			next_state = current_state;
		end
		INPUT: begin
			if(!in_valid)	next_state = SET_OP;
			else			next_state = current_state;
		end
		SET_OP: begin
			next_state = OPERATION;
		end
		OPERATION: begin
			if(flag_finish)
				next_state = SET_OUT;
			else
				next_state = current_state;
		end
		SET_OUT: begin
			next_state = OUT;
		end
		OUT: begin
			if(flag_finish)
				next_state = RESET;
			else
				next_state = current_state;
		end
		RESET: begin
			next_state = IDLE;
		end
		default: next_state = current_state;
	endcase
end
// ===============================================================
// Design
// ===============================================================
// ===============================================================
// clk5 (next_state == IDLE || (next_state == INPUT && cnt < 15 ))
// ===============================================================
// cnt 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		cnt <= 0;
	end
    else begin
		case(next_state)
			IDLE: begin
				cnt <= 0;
			end
			INPUT: begin
				if(cnt < 15)
					cnt <= cnt + 1;		
			end
		endcase
	end
end

// ===============================================================
// clk6 (next_state == OPERATION || next_state == SET_OUT) 
// ===============================================================
// cnt_op
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		cnt_op <= 0;
	end
    else begin
		case(next_state)
			OPERATION: begin
				if(cnt_op < 15)
					cnt_op <= cnt_op + 1;		
			end
			SET_OUT: begin
				cnt_op <= 0;
			end
		endcase
	end
end

// ===============================================================
// clk7 (next_state == SET_OUT || next_state == OUT) 
// ===============================================================
// cnt_out
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		cnt_out <= 0;
	end
    else begin
		case(next_state)
			SET_OUT: begin
				if(current_x >= 4 || current_y >= 4) begin
					cnt_out <= 0;
				end
				else begin
					cnt_out <= (current_x << 3) + current_y + 9;
				end
			end
			OUT: begin
				if(flag_zoom) begin
					if(cnt_out == 6 || cnt_out == 22 || cnt_out == 38) 
						cnt_out <= cnt_out + 10;
					else
						cnt_out <= cnt_out + 2;
				end
				else begin
					if(cnt_1 == 3 || cnt_1 == 7 || cnt_1 == 11)
						cnt_out <= cnt_out + 5;
					else
						cnt_out <= cnt_out + 1;
				end
			end
		endcase
	end
end

// ===============================================================
// clk1 (next_state == IDLE || next_state == INPUT || next_state == OPERATION)
// ===============================================================
// map
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		for(i=0; i<8; i=i+1)
			for(j=0; j<8; j=j+1)
				map[i][j] <= 0;
	end
    else begin
		case(next_state)
			IDLE: begin
				for(i=0; i<8; i=i+1)
					for(j=0; j<8; j=j+1)
						map[i][j] <= 0;
			end
			INPUT: begin
				map[7][7] <= in_data;
				for(i=0; i<7; i=i+1)
					map[i][7] <= map[i+1][0];
				for(i=0; i<8; i=i+1)
					for(j=0; j<7; j=j+1)
						map[i][j] <= map[i][j+1];
			end
			OPERATION: begin
				if(cnt_op < 15) begin
					case(op_reg[0])
						Average: begin
							map[current_x][current_y]   <= average_sol;
							map[x_plus_one][current_y]  <= average_sol;
							map[current_x][y_plus_one]  <= average_sol;
							map[x_plus_one][y_plus_one] <= average_sol;
						end
						Flip: begin
							map[current_x][current_y]   <= ~map[current_x][current_y]   + 1;
							map[x_plus_one][current_y]  <= ~map[x_plus_one][current_y]  + 1;
							map[current_x][y_plus_one]  <= ~map[current_x][y_plus_one]  + 1;
							map[x_plus_one][y_plus_one] <= ~map[x_plus_one][y_plus_one] + 1;
						end
						Clock: begin
							map[current_x][current_y]   <= map[x_plus_one][current_y];
							map[x_plus_one][current_y]  <= map[x_plus_one][y_plus_one];
							map[x_plus_one][y_plus_one] <= map[current_x][y_plus_one];
							map[current_x][y_plus_one]  <= map[current_x][current_y];
						end
						Inv_clk: begin
							map[current_x][current_y]   <= map[current_x][y_plus_one];
							map[x_plus_one][current_y]  <= map[current_x][current_y];
							map[x_plus_one][y_plus_one] <= map[x_plus_one][current_y];
							map[current_x][y_plus_one]  <= map[x_plus_one][y_plus_one];
						end
						Midpoint: begin
							map[current_x][current_y]   <= mid_sol;
							map[x_plus_one][current_y]  <= mid_sol;
							map[current_x][y_plus_one]  <= mid_sol;
							map[x_plus_one][y_plus_one] <= mid_sol;
						end
					endcase
				end
			end
		endcase
	end
end

// op_reg
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		for(i=0; i<15; i=i+1)
			op_reg[i] <= 0;
	end
    else begin
		case(next_state)
			IDLE: begin
				for(i=0; i<15; i=i+1)
					op_reg[i] <= 0;
			end
			INPUT: begin
				if(cnt < 15) begin
					op_reg[14] <= op;
					for(i=0; i<14; i=i+1)begin
						op_reg[i] <= op_reg[i+1];
					end
				end
			end
			OPERATION: begin
				for(i=0; i<14; i=i+1)begin
					op_reg[i] <= op_reg[i+1];
				end
			end
		endcase
	end
end

// ===============================================================
// clk2 (next_state == IDLE || next_state == OUT)
// ===============================================================
// cnt_1
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		cnt_1 <= 0;
	end
    else begin
		case(next_state)
			OUT: begin
				if(flag_zoom == 0) begin
					cnt_1 <= cnt_1 + 1;
				end
			end
			default: begin
				cnt_1 <= 0;
			end
		endcase
	end
end

// output
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		out_valid <= 0;
		out_data <= 0;
	end
    else begin
		case(next_state)
			OUT: begin
				out_valid <= 1;
				out_data <= map[cnt_out >> 3][cnt_out[2:0]];
			end
			default: begin
				out_valid <= 0;
				out_data <= 0;
			end
		endcase
	end
end

// ===============================================================
// clk3 (next_state == IDLE || next_state == OPERATION)
// ===============================================================
// x, y
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		current_x <= 0;
		current_y <= 0;
	end
    else begin
		case(next_state)
			IDLE: begin
				current_x <= 3;
				current_y <= 3;
			end
			OPERATION: begin
				if(cnt_op < 15) begin
					case(op_reg[0])
						Up:    if(current_x != 0)  current_x <= current_x - 1;
						Down:  if(current_x != 6)  current_x <= current_x + 1;
						Left:  if(current_y != 0)  current_y <= current_y - 1;
						Right: if(current_y != 6)  current_y <= current_y + 1;
					endcase
				end
			end
		endcase
	end
end

// ===============================================================
// clk4 (next_state == IDLE || next_state == OPERATION || next_state == SET_OUT || next_state == OUT)
// ===============================================================
//flag_finish
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		flag_finish <= 0;
	end
    else begin
		case(next_state)
			RESET, SET_OUT: begin
				flag_finish <= 0;
			end
			OPERATION: begin
				if(cnt_op == 15) begin
					flag_finish <= 1;
				end
			end
			OUT: begin
				if(flag_zoom) begin // Zoom out
					if(cnt_out == 54) flag_finish <= 1;
				end
				else begin	// Zoom in
					if(cnt_1 == 15) flag_finish <= 1;
				end
			end
		endcase
	end
end

endmodule 
// ===============================================================
// Average_ip
// ===============================================================
module Average_ip(
	// in
	a0, a1, a2, a3,
	// out
	out
);
input  signed [6:0] a0, a1, a2, a3;
output signed [6:0] out;
wire signed   [7:0] b1 = a0 + a1; 
wire signed   [7:0] b2 = a2 + a3;
wire signed   [8:0] b3 = b1 + b2; 
assign out = b3 / 4;
endmodule
// ===============================================================
// Midpoint_ip
// ===============================================================
module Midpoint_ip(
	// in
	m0, m1, m2, m3,
	// out
	out
);
input  signed [6:0] m0, m1, m2, m3;
output signed [6:0] out;
wire signed [6:0] layer1 [0:3];
wire signed [6:0] layer2 [0:3];
wire signed [6:0] b0;
wire signed [6:0] b1;
wire signed [7:0] b3;
assign {layer1[0], layer1[1]} = (m0 > m1) ? {m1, m0} : {m0, m1};
assign {layer1[2], layer1[3]} = (m2 > m3) ? {m3, m2} : {m2, m3};

assign layer2[0] = layer1[0];
assign layer2[3] = layer1[3];
assign {layer2[1], layer2[2]} = (layer1[1] > layer1[2]) ? {layer1[2], layer1[1]} : {layer1[1], layer1[2]};

assign b0 = (layer2[0] > layer2[1]) ? layer2[0] : layer2[1];
assign b1 = (layer2[2] > layer2[3]) ? layer2[3] : layer2[2];

assign b3 = b0 + b1;
assign out = b3 / 2;

endmodule