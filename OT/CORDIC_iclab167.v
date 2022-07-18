module	CORDIC (
	input	wire				clk, rst_n, in_valid,
	input	wire	signed	[11:0]	in_x, in_y,
	output	reg		[11:0]	out_mag,
	output	reg		[20:0]	out_phase,
	output	reg					out_valid

	);

// input_x and input_y -> 1'b sign , 3'b int , 8'b fraction
// out_mag -> 4b int , 8'b fraction
// output -> 1'b int , 20'b fraction 
wire	  [20:0]	cordic_angle [0:17];
wire    [14:0]	Constant;

//cordic angle -> 1'b int, 20'b fraciton
assign   cordic_angle[ 0] = 21'h04_0000; //  45        deg
assign   cordic_angle[ 1] = 21'h02_5c81; //  26.565051 deg
assign   cordic_angle[ 2] = 21'h01_3f67; //  14.036243 deg
assign   cordic_angle[ 3] = 21'h00_a222; //   7.125016 deg
assign   cordic_angle[ 4] = 21'h00_5162; //   3.576334 deg
assign   cordic_angle[ 5] = 21'h00_28bb; //   1.789911 deg
assign   cordic_angle[ 6] = 21'h00_145f; //   0.895174 deg
assign   cordic_angle[ 7] = 21'h00_0a30; //   0.447614 deg
assign   cordic_angle[ 8] = 21'h00_0518; //   0.223811 deg
assign   cordic_angle[ 9] = 21'h00_028b; //   0.111906 deg
assign   cordic_angle[10] = 21'h00_0146; //   0.055953 deg
assign   cordic_angle[11] = 21'h00_00a3; //   0.027976 deg
assign   cordic_angle[12] = 21'h00_0051; //   0.013988 deg
assign   cordic_angle[13] = 21'h00_0029; //   0.006994 deg
assign   cordic_angle[14] = 21'h00_0014; //   0.003497 deg
assign   cordic_angle[15] = 21'h00_000a; //   0.001749 deg
assign   cordic_angle[16] = 21'h00_0005; //   0.000874 deg
assign   cordic_angle[17] = 21'h00_0003; //   0.000437 deg
   
//Constant-> 1'b int, 14'b fraction
assign  Constant = {1'b0,14'b10011011011101}; // 1/K = 0.6072387695


reg [9:0] addr_1;
reg signed [11:0] w_data_1;
wire signed [11:0] r_data_1;
reg w_r_1;

reg [9:0] addr_2;
reg signed [20:0] w_data_2;
wire signed [20:0] r_data_2;
reg w_r_2;

//12bits * 1024 SRAM
RA1SH_12 MEM_12 ( .Q(r_data_1), .CLK(clk), .CEN(1'b0), .WEN(w_r_1), .A(addr_1), .D(w_data_1), .OEN(1'b0));

//21bits * 1024 SRAM
RA1SH_21 MEM_21( .Q(r_data_2), .CLK(clk), .CEN(1'b0), .WEN(w_r_2), .A(addr_2), .D(w_data_2), .OEN(1'b0));



// ===============================================================
// Parameters & Integer Declaration
// ===============================================================
parameter s_idle      		        = 'd0;
parameter s_in    		           = 'd1;
parameter s_get                    = 'd2;
parameter s_get_1                  = 'd3;  
parameter s_get_2                  = 'd4;
parameter s_calculate_1            = 'd5;   
parameter s_save_1                 = 'd6;  
parameter s_save_2                 = 'd7;
parameter s_out                    = 'd8;
parameter s_out_1 = 'd9;
parameter s_approximate = 'd10;
// mem
parameter Write = 'd0;
parameter Read  = 'd1;

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 1;
parameter inst_arch = 2;

// 0.5, 1.5
parameter point_five       = 21'b0_1000_0000_0000_0000_0000;
parameter one_point_five   = 21'b1_1000_0000_0000_0000_0000;
parameter one              = 21'b1_0000_0000_0000_0000_0000;


// 1 sign, 3 int, 8 fraction
// ===============================================================
// Wire & Reg Declaration
// ===============================================================
// state
reg [3:0] current_state, next_state;

reg signed [20:0] now_x;
reg signed [20:0] now_y;

reg [20:0] now_z;
reg [20:0] tmp_z;


// cnt
reg [9:0] cnt;
reg [9:0] cnt_total;
reg [4:0] cnt_rotation;


wire flag_rotation;
reg  flag_calculated;
reg flag_finish;
reg flag_out;
wire [31:0] tmp = (now_x <<< 6) * Constant;

assign flag_rotation = (now_y[11] == 0) ? 1 : 0;
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
         if(in_valid == 1)
               next_state = s_in;
         else
               next_state = current_state;
      end
      s_in: begin
         if(in_valid == 0)
            next_state = s_get;
         else
            next_state = current_state;
      end
      s_get:   begin
         next_state = s_get_1;
      end
      s_get_1: begin
         next_state = s_get_2;
      end
      s_get_2: begin
         next_state = s_calculate_1;
      end
      s_calculate_1 : begin
         if(flag_calculated)
            next_state = s_save_1;
         else
            next_state = current_state;
      end
      s_save_1: begin
         if(flag_finish)
            next_state = s_save_2;
         else
            next_state = s_get;
      end
      s_save_2: begin
         next_state = s_out_1;
      end
      s_out_1: begin
         next_state = s_out;
      end
      s_out: begin
         if(flag_out)
            next_state = s_idle;
         else
            next_state = current_state;
      end
      default:
         next_state = current_state;
   endcase
end
// ===============================================================
// Seq
// ===============================================================
always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      cnt <= 0;
      cnt_rotation <= 0;
      cnt_total <= 0;

      now_x <= 0;
      now_y <= 0;
      now_z <= 0;

      addr_1 <= 0;
      addr_2 <= 0;

      flag_calculated <= 0;
      flag_finish <= 0;
      flag_out <= 0;
   end
   else begin
      case(next_state)
         s_idle: begin
            cnt <= 0;
            cnt_rotation <= 0;
            cnt_total <= 0;

            now_x <= 0;
            now_y <= 0;
            now_z <= 0;

            addr_1 <= 0;
            addr_2 <= 0;

            flag_calculated <= 0;
            flag_finish <= 0;
            flag_out <= 0;
         end
         s_in: begin
            addr_1 <= addr_1 + 1;
            addr_2 <= addr_2 + 1;
            cnt_total <= cnt_total + 1;
         end
         s_get: begin
            addr_1 <= cnt;
            addr_2 <= cnt;
         end
         s_get_2: begin
            cnt_rotation <= cnt_rotation + 1;
            if(r_data_1 < 0 && r_data_2 < 0) begin
               now_x <= (~r_data_1 + 1)   +     (~r_data_2 + 1);
               now_y <= (~r_data_2 + 1)   -     (~r_data_1 + 1);
               now_z <= one               +     cordic_angle[0];
            end
            else if(r_data_1 < 0 && r_data_2 > 0) begin 
               now_x <= r_data_2          +    (~r_data_1 + 1);
               now_y <= (~r_data_1 + 1)   -    r_data_2;
               now_z <= point_five        +    cordic_angle[0];
            end
            else if(r_data_1 > 0 && r_data_2 < 0) begin
               now_x <= (~r_data_2 + 1)   +    r_data_1;
               now_y <= r_data_1          -    (~r_data_2 + 1);
               now_z <= one_point_five + cordic_angle[0];
            end
            else begin
               now_x <= r_data_1 + r_data_2;
               now_y <= r_data_2 - r_data_1;
               now_z <= cordic_angle[0];
            end  
         end
         s_calculate_1: begin
            if(cnt_rotation < 11) begin
               if(flag_rotation == 1) begin
                  now_x <= now_x + (now_y >>> cnt_rotation);
                  now_y <= now_y - (now_x >>> cnt_rotation);
                  now_z <= now_z + cordic_angle[cnt_rotation];
               end
               else begin
                  now_x <= now_x - (now_y >>> cnt_rotation);
                  now_y <= now_y + (now_x >>> cnt_rotation);
                  now_z <= now_z - cordic_angle[cnt_rotation];
               end 
            end
            else if(cnt_rotation == 11)begin
               if(flag_rotation == 1) begin
                  now_x <= now_x ;
                  now_y <= now_y - (now_x >>> cnt_rotation);
                  now_z <= now_z + cordic_angle[cnt_rotation];
               end
               else begin
                  now_x <= now_x ;
                  now_y <= now_y + (now_x >>> cnt_rotation);
                  now_z <= now_z - cordic_angle[cnt_rotation];
               end 
            end
            else begin
               if(flag_rotation == 1) begin
                  now_x <= now_x ;
                  now_y <= now_y ;
                  now_z <= now_z + cordic_angle[cnt_rotation];
               end
               else begin
                  now_x <= now_x ;
                  now_y <= now_y ;
                  now_z <= now_z - cordic_angle[cnt_rotation];
               end 
            end
            if(cnt_rotation == 17) begin
               flag_calculated <= 1;
            end
            else begin
               cnt_rotation <= cnt_rotation + 1;
            end
         end
         
         s_save_1: begin
            cnt_rotation <= 0;
            flag_calculated <= 0;

            if(cnt < cnt_total - 1) begin
               cnt <= cnt + 1; 
            end
            else begin
               flag_finish <= 1;
               addr_1 <= 0;
               addr_2 <= 0;
            end
         end
         s_out_1: begin
            addr_1 <= addr_1 + 1;
            addr_2 <= addr_2 + 1;
         end
         s_out: begin
            flag_finish <= 0;
            if(addr_1 < cnt_total) begin
               addr_1 <= addr_1 + 1;
               addr_2 <= addr_2 + 1;
               flag_out <= 0;
            end
            else begin
               flag_out <= 1;
               addr_1 <= 0;
               addr_2 <= 0;
            end
         end
         default: begin
         end
      endcase
   end
end
// ===============================================================
// w_r_x, w_r_y, w_data_x, w_data_y
// ===============================================================
always@(*)begin
   w_r_1 = Read;
   w_r_2 = Read;
   w_data_1 = 0;
   w_data_2 = 0; 
	case(next_state)
      s_in: begin
         w_r_1 = Write;
         w_r_2 = Write;
         w_data_1 = in_x;
         w_data_2 = in_y;
      end
      s_save_1: begin
         w_r_1 = Write;
         w_r_2 = Write;
         w_data_1 = tmp[31:20]; 
         w_data_2 = now_z;
      end
      default: begin
         w_r_1 = Read;
         w_r_2 = Read;
         w_data_1 = 0;
         w_data_2 = 0;
      end
   endcase
end
// ===============================================================
// out
// ===============================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_mag <= 0;
      out_phase <= 0;
      out_valid <= 0;
	end
	else begin
      case(next_state)
         s_out:   begin
            out_mag <= r_data_1;
            out_phase <= r_data_2;
            out_valid <= 1;
         end
         default: begin
            out_mag <= 0;
            out_phase <= 0;
            out_valid <= 0;
         end
      endcase
	end 	
end
endmodule