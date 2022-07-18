module TMIP(
// input signals
    clk,
    rst_n,
    in_valid,
	in_valid_2,
    image,
	img_size,
    template, 
    action,
	
// output signals
    out_valid,
    out_x,
    out_y,
    out_img_pos,
    out_value
);

input        clk, rst_n, in_valid, in_valid_2;
input [15:0] image, template;
input [4:0]  img_size;
input [2:0]  action;

output reg        out_valid;
output reg [3:0]  out_x, out_y; 
output reg [7:0]  out_img_pos;
output reg signed[39:0] out_value;
// ===============================================================
// Parameters & Integer Declaration
// ===============================================================
parameter s_idle      		        = 'd0;
parameter s_in_1    		        = 'd1;
parameter s_in_2   	        	    = 'd2;
parameter s_in_3    		        = 'd3;
parameter s_reset                   = 'd4;
parameter s_hor_flip                = 'd5;
parameter s_ver_flip                = 'd6;
parameter s_left_flip_pre           = 'd7;
parameter s_left_flip               = 'd8;
parameter s_right_flip              = 'd9;

parameter s_zoom_in_set             = 'd10;
parameter s_zoom_in                 = 'd11;

parameter s_short_cut_bright_pre    = 'd12;
parameter s_short_cut_bright        = 'd13;

parameter s_max_reset               = 'd14;
parameter s_max_read_1              = 'd15;
parameter s_max_read_2              = 'd16;
parameter s_max_read_3              = 'd17;
parameter s_max_read_4              = 'd18;
parameter s_max_write               = 'd19;

parameter s_conv_reset              = 'd20;
parameter s_conv_read_1             = 'd21;
parameter s_conv_read_2             = 'd22;
parameter s_conv_read_3             = 'd23;
parameter s_conv_read_4             = 'd24;
parameter s_conv_read_5             = 'd25;
parameter s_conv_read_6             = 'd26;
parameter s_conv_read_7             = 'd27;
parameter s_conv_read_8             = 'd28;
parameter s_conv_read_9             = 'd29;
parameter s_conv_read_10            = 'd30;
parameter s_conv_write              = 'd31;

parameter s_out_pre                 = 'd32;
parameter s_out                     = 'd33;

parameter s_max_read_5              = 'd34;

parameter Write = 'd0;
parameter Read  = 'd1;

parameter min = 16'b1000_0000_0000_0000;
// ===============================================================
integer i;
// ===============================================================
// Wire & Reg Declaration
// ===============================================================
// state
reg [5:0] current_state, next_state;
reg [7:0] addr_1, addr_2;
reg [8:0] addr_3;

// mem
reg w_r_1, w_r_2;
reg signed [15:0] w_data_1, w_data_2;
wire signed [15:0] r_data_1, r_data_2;
reg signed [35:0] w_data_3;
wire signed [35:0] r_data_3;
reg w_r_3;

// cnt
reg [8:0] cnt;
reg [3:0] cnt_in_1;
reg [3:0] cnt_act;
reg [3:0] cnt_current_act;
reg [3:0] cnt_zoom;

// size
reg [4:0] size;

// template
reg signed [15:0] temp [0:8];

// action
reg [2:0] act [0:15];

// which_sram_read
reg which_sram_rd;

// area
wire [8:0] area = (size == 4) ? 16 : (size == 8) ? 64 : 256;

// max pooling
reg signed [15:0] max;
reg signed [15:0] tmp_max;

// conv
reg signed [4:0] center_x, center_y;
reg signed [4:0] legal_x, legal_y;
reg signed [35:0] conv_max_value;
reg [7:0] conv_max_position;

// flag
reg flag_hor_flip;
reg flag_ver_flip;
reg flag_left_flip;
reg flag_right_flip;
reg flag_short_cut_bright;
reg flag_zoom_in;
reg flag_next_zoom;
reg flag_max;
reg flag_next_max;
reg flag_conv;
reg flag_next_conv;
reg flag_bound;

// out_img_pos
reg flag_out_img_pos[8:0];

// ===============================================================
// debug
// ===============================================================
// wire [4:0] check_action = act[cnt_current_act];

// ===============================================================
// IP
// ===============================================================

reg signed  [15:0] mult_a;
reg signed  [15:0] mult_b;

wire signed  [35:0] total_conv_ans;
reg signed [35:0] conv_ans;

MAC M0(.A(mult_a), .B(mult_b), .C(conv_ans), .sol(total_conv_ans));
// ===============================================================
// DESIGN
// ===============================================================
sram_16 mem1(.A(addr_1),.D(w_data_1),.CLK(clk),.CEN(1'd0),.WEN(w_r_1),.OEN(1'd0),.Q(r_data_1));
sram_16 mem2(.A(addr_2),.D(w_data_2),.CLK(clk),.CEN(1'd0),.WEN(w_r_2),.OEN(1'd0),.Q(r_data_2));
sram_36 mem3(.A(addr_3[7:0]),.D(w_data_3),.CLK(clk),.CEN(1'd0),.WEN(w_r_3),.OEN(1'd0),.Q(r_data_3));
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
                next_state = s_in_1;
            else
                next_state = current_state;
        end
        s_in_1: begin
            if(in_valid == 0)
                next_state = s_in_2;
            else
                next_state = current_state;
        end
        s_in_2: begin
            if(in_valid_2 == 1)
                next_state = s_in_3;
            else
                next_state = current_state;
        end
        s_in_3: begin
            if(in_valid_2 == 0) 
               next_state = s_reset;
            else
                next_state = current_state;
        end
        s_reset: begin
            case(act[0])
                0: next_state = s_conv_reset;
                1: next_state = s_max_reset;
                2: next_state = s_hor_flip;
                3: next_state = s_ver_flip;
                4: next_state = s_left_flip_pre;
                5: next_state = s_right_flip;
                6: next_state = s_zoom_in_set;
                7: next_state = s_short_cut_bright_pre;
                default: next_state = current_state;
            endcase
        end
        s_hor_flip: begin
            if(flag_hor_flip == 1) begin
                case(act[cnt_current_act])
                    0: next_state = s_conv_reset;
                    1: next_state = s_max_reset;
                    2: next_state = s_hor_flip;
                    3: next_state = s_ver_flip;
                    4: next_state = s_left_flip_pre;
                    5: next_state = s_right_flip;
                    6: next_state = s_zoom_in_set;
                    7: next_state = s_short_cut_bright_pre;
                    default: next_state = current_state;
                endcase
            end
            else
                next_state = current_state;
        end
        s_ver_flip: begin
            if(flag_ver_flip == 1) begin
                case(act[cnt_current_act])
                    0: next_state = s_conv_reset;
                    1: next_state = s_max_reset;
                    2: next_state = s_hor_flip;
                    3: next_state = s_ver_flip;
                    4: next_state = s_left_flip_pre;
                    5: next_state = s_right_flip;
                    6: next_state = s_zoom_in_set;
                    7: next_state = s_short_cut_bright_pre;
                    default: next_state = current_state;
                endcase
            end
            else
                next_state = current_state;
        end
        s_left_flip_pre: begin
            next_state = s_left_flip;
        end
        s_left_flip: begin
            if(flag_left_flip == 1) begin
                case(act[cnt_current_act])
                    0: next_state = s_conv_reset;
                    1: next_state = s_max_reset;
                    2: next_state = s_hor_flip;
                    3: next_state = s_ver_flip;
                    4: next_state = s_left_flip_pre;
                    5: next_state = s_right_flip;
                    6: next_state = s_zoom_in_set;
                    7: next_state = s_short_cut_bright_pre;
                    default: next_state = current_state;
                endcase
            end
            else
                next_state = current_state;
        end
        s_right_flip: begin
            if(flag_right_flip == 1) begin
                case(act[cnt_current_act])
                    0: next_state = s_conv_reset;
                    1: next_state = s_max_reset;
                    2: next_state = s_hor_flip;
                    3: next_state = s_ver_flip;
                    4: next_state = s_left_flip_pre;
                    5: next_state = s_right_flip;
                    6: next_state = s_zoom_in_set;
                    7: next_state = s_short_cut_bright_pre;
                    default: next_state = current_state;
                endcase
            end
            else
                next_state = current_state;
        end
        s_short_cut_bright_pre:begin
            next_state = s_short_cut_bright;
        end
        s_short_cut_bright: begin
            if(flag_short_cut_bright == 1) begin
                case(act[cnt_current_act])
                    0: next_state = s_conv_reset;
                    1: next_state = s_max_reset;
                    2: next_state = s_hor_flip;
                    3: next_state = s_ver_flip;
                    4: next_state = s_left_flip_pre;
                    5: next_state = s_right_flip;
                    6: next_state = s_zoom_in_set;
                    7: next_state = s_short_cut_bright_pre;
                    default: next_state = current_state;
                endcase
            end
            else
                next_state = current_state;
        end
        s_zoom_in_set: begin
            if(flag_zoom_in == 1) begin
                case(act[cnt_current_act])
                    0: next_state = s_conv_reset;
                    1: next_state = s_max_reset;
                    2: next_state = s_hor_flip;
                    3: next_state = s_ver_flip;
                    4: next_state = s_left_flip_pre;
                    5: next_state = s_right_flip;
                    6: next_state = s_zoom_in_set;
                    7: next_state = s_short_cut_bright_pre;
                    default: next_state = current_state;
                endcase
            end
            else
                next_state = s_zoom_in;
        end
        s_zoom_in: begin
            if(flag_next_zoom == 1)
                next_state = s_zoom_in_set;
            else
                next_state = current_state;
        end
        s_max_reset: begin
            if(flag_max == 1) begin
                case(act[cnt_current_act])
                    0: next_state = s_conv_reset;
                    1: next_state = s_max_reset;
                    2: next_state = s_hor_flip;
                    3: next_state = s_ver_flip;
                    4: next_state = s_left_flip_pre;
                    5: next_state = s_right_flip;
                    6: next_state = s_zoom_in_set;
                    7: next_state = s_short_cut_bright_pre;
                    default: next_state = current_state;
                endcase
            end
            else
                next_state = s_max_read_1;
        end
        s_max_read_1: begin
            next_state = s_max_read_2;
        end
        s_max_read_2: begin
            next_state = s_max_read_3;
        end
        s_max_read_3: begin
            next_state = s_max_read_4;
        end
        s_max_read_4: begin
            next_state = s_max_read_5;
        end
        s_max_read_5: begin
            next_state = s_max_write;
        end
        s_max_write: begin
            next_state = s_max_reset;
        end
        s_conv_reset: begin
            if(flag_conv == 1)
                next_state = s_out_pre;
            else
                next_state = s_conv_read_1;
        end
        s_conv_read_1: begin
            next_state = s_conv_read_2;
        end
        s_conv_read_2: begin
            next_state = s_conv_read_3;
        end
        s_conv_read_3: begin
            next_state = s_conv_read_4;
        end
        s_conv_read_4: begin
            next_state = s_conv_read_5;
        end
        s_conv_read_5: begin
            next_state = s_conv_read_6;
        end
        s_conv_read_6: begin
            next_state = s_conv_read_7;
        end
        s_conv_read_7: begin
            next_state = s_conv_read_8;
        end
        s_conv_read_8: begin
            next_state = s_conv_read_9;
        end
        s_conv_read_9: begin
            next_state = s_conv_read_10;
        end
        s_conv_read_10: begin
            next_state = s_conv_write;
        end
        s_conv_write: begin
            next_state = s_conv_reset;
        end
        s_out_pre: begin
            next_state = s_out;
        end
        s_out: begin
            if(cnt < area)
                next_state = current_state;
            else
                next_state = s_idle;
        end
        default: 
            next_state = current_state;
	endcase
end
// ===============================================================
// s_in_1
// ===============================================================
// size, temp
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i=0; i<9; i=i+1)
            temp[i] <= 0;
    end
    else begin
        case(next_state)
            s_idle: begin
                for(i=0; i<9; i=i+1)
                    temp[i] <= 0;
            end
            s_in_1: begin
                if(cnt_in_1 <= 8)
                    temp[cnt_in_1] <= template;
                else begin
                end
            end
            default: begin
            end
        endcase
    end
end

// cnt_in_1
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt_in_1 <= 0;
    end
    else begin
        case(next_state)
            s_idle: begin
               cnt_in_1 <= 0;
            end
            s_in_1: begin
                if(cnt_in_1 < 9)
                    cnt_in_1 <= cnt_in_1 + 1;
                else begin
                end
                    
            end
            default: begin
            end
        endcase
    end
end

// ===============================================================
// s_in_3
// ===============================================================
// act, cnt_act
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt_act <= 0;
        for(i=0; i<16; i=i+1)
            act[i] <= 0;
    end
    else begin
        case(next_state)
            s_idle: begin
                cnt_act <= 0;
                for(i=0; i<16; i=i+1)
                    act[i] <= 0;
            end
            s_in_3: begin
                act[cnt_act] <= action;
                if(in_valid_2 == 1)
                    cnt_act <= cnt_act + 1;
                else
                    cnt_act <= 0;
            end
            default: begin
            end
        endcase
    end
end

// ===============================================================
// Seq
// ===============================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // max pooling
        max <= 0;

        // cnt
        cnt <= 0;
        cnt_current_act <= 0;
        cnt_zoom <= 0;
        
        // addr
        addr_1 <= 0;
        addr_2 <= 0;
        addr_3 <= 0;
        
        // conv_max
        conv_max_value <= 0;
        conv_max_position <= 0;

        // which_sram_read
        which_sram_rd <= 0;

        // flag
        flag_hor_flip <= 0;
        flag_ver_flip <= 0;
        flag_left_flip <= 0;
        flag_right_flip <= 0;
        flag_short_cut_bright <= 0;
        flag_zoom_in <= 0;
        flag_conv <= 0;
        flag_max <= 0;
        flag_next_conv <= 0;
        flag_next_zoom <= 0;
        flag_next_max <= 0;
    end
    else begin
        case(next_state)
            s_idle: begin
                // max pooling
                max <= 0;

                // cnt
                cnt <= 0;
                cnt_current_act <= 0;
                cnt_zoom <= 0;
                
                // addr
                addr_1 <= 0;
                addr_2 <= 0;
                addr_3 <= 0;
               
               // conv_max
               conv_max_value <= 0;
               conv_max_position <= 0;

                // which_sram_read
                which_sram_rd <= 0;

                // flag
                flag_hor_flip <= 0;
                flag_ver_flip <= 0;
                flag_left_flip <= 0;
                flag_right_flip <= 0;
                flag_short_cut_bright <= 0;
                flag_zoom_in <= 0;
                flag_conv <= 0;
                flag_max <= 0;
                flag_next_conv <= 0;
                flag_next_zoom <= 0;
                flag_next_max <= 0;
            end
            s_in_1: begin
                // mem 1
                addr_1 <= addr_1 + 1;

                // size
                if(cnt_in_1 == 0)begin
                    size <= img_size;
                end
                else begin
                end
            end
            s_in_2: begin   // read
                addr_1 <= 0;
                addr_2 <= 0;
            end
            s_in_3: begin   // read
                //w_r_1 <= Read;
                //w_r_2 <= Read;
            end
            s_hor_flip: begin
                // flag
                flag_ver_flip <= 0;
                //flag_hor_flip <= 0;
                flag_left_flip <= 0;
                flag_right_flip <= 0;
                flag_short_cut_bright <= 0;
                flag_zoom_in <= 0;
                flag_max <= 0;
                flag_conv <= 0;

                case(size)
                    4:  begin
                        if(which_sram_rd == 0) begin
                            if(cnt < 17) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_hor_flip <= 0;
                                // addr_1
                                if(addr_1 < 15)
                                    addr_1 <= addr_1 + 1;
                                else begin
                                    
                                end
                                // addr_2
                                case(addr_1 % 4)
                                    0:  addr_2 <= addr_1 + 3;
                                    1:  addr_2 <= addr_1 + 1;
                                    2:  addr_2 <= addr_1 - 1;
                                    3:  addr_2 <= addr_1 - 3;
                                    default: begin
                                    end
                                endcase
                            end
                            else begin
                                // flag
                                flag_hor_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 1;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 2) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 1;
                                    cnt_current_act <= cnt_current_act + 1;
                                end

                            end
                        end
                        else begin // which_sram_rd == 1
                            if(cnt < 17) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_hor_flip <= 0;
                                // addr_1
                                if(addr_2 < 15)
                                    addr_2 <= addr_2 + 1;
                                else begin
                                    
                                end
                                // addr_2
                                case(addr_2 % 4)
                                    0:  addr_1 <= addr_2 + 3;
                                    1:  addr_1 <= addr_2 + 1;
                                    2:  addr_1 <= addr_2 - 1;
                                    3:  addr_1 <= addr_2 - 3;
                                    default: begin
                                    end
                                endcase
                            end
                            else begin
                                // flag
                                flag_hor_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 0;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 2) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 0;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                    end
                    8:  begin
                        if(which_sram_rd == 0) begin
                            if(cnt < 65) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_hor_flip <= 0;
                                // addr_1
                                if(addr_1 < 63)
                                    addr_1 <= addr_1 + 1;
                                else begin
                                    
                                end
                                // addr_2
                                case(addr_1 % 8)
                                    0:  addr_2 <= addr_1 + 7;
                                    1:  addr_2 <= addr_1 + 5;
                                    2:  addr_2 <= addr_1 + 3;
                                    3:  addr_2 <= addr_1 + 1;
                                    4:  addr_2 <= addr_1 - 1;
                                    5:  addr_2 <= addr_1 - 3;
                                    6:  addr_2 <= addr_1 - 5;
                                    7:  addr_2 <= addr_1 - 7;
                                    default: begin
                                    end
                                endcase
                            end
                            else begin
                                // flag
                                flag_hor_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 1;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 2) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 1;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                        else begin // which_sram_rd == 1
                            if(cnt < 65) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_hor_flip <= 0;
                                // addr_1
                                if(addr_2 < 63)
                                    addr_2 <= addr_2 + 1;
                                else begin
                                    
                                end
                                // addr_2
                                case(addr_2 % 8)
                                    0:  addr_1 <= addr_2 + 7;
                                    1:  addr_1 <= addr_2 + 5;
                                    2:  addr_1 <= addr_2 + 3;
                                    3:  addr_1 <= addr_2 + 1;
                                    4:  addr_1 <= addr_2 - 1;
                                    5:  addr_1 <= addr_2 - 3;
                                    6:  addr_1 <= addr_2 - 5;
                                    7:  addr_1 <= addr_2 - 7;
                                    default: begin
                                    end
                                endcase
                            end
                            else begin
                                // flag
                                flag_hor_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 0;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 2) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 0;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                    end
                    16: begin
                        if(which_sram_rd == 0) begin
                            if(cnt < 257) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_hor_flip <= 0;
                                // addr_1
                                if(addr_1 < 255)
                                    addr_1 <= addr_1 + 1;
                                else begin
                                    
                                end
                                // addr_2
                                case(addr_1 % 16)
                                    0:   addr_2 <= addr_1 + 15;
                                    1:   addr_2 <= addr_1 + 13;
                                    2:   addr_2 <= addr_1 + 11;
                                    3:   addr_2 <= addr_1 + 9;
                                    4:   addr_2 <= addr_1 + 7;
                                    5:   addr_2 <= addr_1 + 5;
                                    6:   addr_2 <= addr_1 + 3;
                                    7:   addr_2 <= addr_1 + 1;
                                    8:   addr_2 <= addr_1 - 1;
                                    9:   addr_2 <= addr_1 - 3;
                                    10:  addr_2 <= addr_1 - 5;
                                    11:  addr_2 <= addr_1 - 7;
                                    12:  addr_2 <= addr_1 - 9;  
                                    13:  addr_2 <= addr_1 - 11;
                                    14:  addr_2 <= addr_1 - 13;
                                    15:  addr_2 <= addr_1 - 15;
                                    default: begin
                                    end
                                endcase
                            end
                            else begin
                                // flag
                                flag_hor_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 1;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 2) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 1;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                        else begin // which_sram_rd == 1
                            if(cnt < 257) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_hor_flip <= 0;
                                // addr_1
                                if(addr_2 < 255)
                                    addr_2 <= addr_2 + 1;
                                else begin
                                    
                                end
                                // addr_2
                                case(addr_2 % 16)
                                    0:   addr_1 <= addr_2 + 15;
                                    1:   addr_1 <= addr_2 + 13;
                                    2:   addr_1 <= addr_2 + 11;
                                    3:   addr_1 <= addr_2 + 9;
                                    4:   addr_1 <= addr_2 + 7;
                                    5:   addr_1 <= addr_2 + 5;
                                    6:   addr_1 <= addr_2 + 3;
                                    7:   addr_1 <= addr_2 + 1;
                                    8:   addr_1 <= addr_2 - 1;
                                    9:   addr_1 <= addr_2 - 3;
                                    10:  addr_1 <= addr_2 - 5;
                                    11:  addr_1 <= addr_2 - 7;
                                    12:  addr_1 <= addr_2 - 9;  
                                    13:  addr_1 <= addr_2 - 11;
                                    14:  addr_1 <= addr_2 - 13;
                                    15:  addr_1 <= addr_2 - 15;
                                    default: begin
                                    end
                                endcase
                            end
                            else begin
                                // flag
                                flag_hor_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 0;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 2) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 0;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                    end
                    default: begin
                    end
                endcase
            end
            s_ver_flip: begin
                // flag
                //flag_ver_flip <= 0;
                flag_hor_flip <= 0;
                flag_left_flip <= 0;
                flag_right_flip <= 0;
                flag_short_cut_bright <= 0;
                flag_zoom_in <= 0;
                flag_max <= 0;
                flag_conv <= 0;

                case(size)
                    4:  begin
                        if(which_sram_rd == 0) begin
                            if(cnt < 17) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_ver_flip <= 0;
                                // addr_1
                                if(addr_1 < 16)
                                    addr_1 <= addr_1 + 1;
                                else begin
                                    
                                end
                                // addr_2
                                case(addr_1 >> 2)
                                    0:  addr_2 <= addr_1 + 12;
                                    1:  addr_2 <= addr_1 + 4;
                                    2:  addr_2 <= addr_1 - 4;
                                    3:  addr_2 <= addr_1 - 12;
                                    default: begin
                                    end
                                endcase
                            end
                            else begin
                                // flag
                                flag_ver_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 1;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 3) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 1;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                        else begin // which_sram_rd == 1
                            if(cnt < 17) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_ver_flip <= 0;
                                // addr_1
                                if(addr_2 < 16)
                                    addr_2 <= addr_2 + 1;
                                else begin
                                    
                                end
                                // addr_2
                                case(addr_2 >> 2)
                                    0:  addr_1 <= addr_2 + 12;
                                    1:  addr_1 <= addr_2 + 4;
                                    2:  addr_1 <= addr_2 - 4;
                                    3:  addr_1 <= addr_2 - 12;
                                    default: begin
                                    end
                                endcase
                            end
                            else begin
                                // flag
                                flag_ver_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 0;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 3) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 0;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                    end
                    8:  begin
                        if(which_sram_rd == 0) begin
                            if(cnt < 65) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_ver_flip <= 0;
                                // addr_1
                                if(addr_1 < 64)
                                    addr_1 <= addr_1 + 1;
                                else begin
                                    
                                end
                                // addr_2
                                case(addr_1 >> 3)
                                    0:  addr_2 <= addr_1 + 56;
                                    1:  addr_2 <= addr_1 + 40;
                                    2:  addr_2 <= addr_1 + 24;
                                    3:  addr_2 <= addr_1 + 8;
                                    4:  addr_2 <= addr_1 - 8;
                                    5:  addr_2 <= addr_1 - 24;
                                    6:  addr_2 <= addr_1 - 40;
                                    7:  addr_2 <= addr_1 - 56;
                                    default: begin
                                    end
                                endcase
                            end
                            else begin
                                // flag
                                flag_ver_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 1;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 3) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 1;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                        else begin // which_sram_rd == 1
                            if(cnt < 65) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_ver_flip <= 0;
                                // addr_1
                                if(addr_2 < 64)
                                    addr_2 <= addr_2 + 1;
                                else begin
                                    
                                end
                                // addr_2
                                case(addr_2 >> 3)
                                    0:  addr_1 <= addr_2 + 56;
                                    1:  addr_1 <= addr_2 + 40;
                                    2:  addr_1 <= addr_2 + 24;
                                    3:  addr_1 <= addr_2 + 8;
                                    4:  addr_1 <= addr_2 - 8;
                                    5:  addr_1 <= addr_2 - 24;
                                    6:  addr_1 <= addr_2 - 40;
                                    7:  addr_1 <= addr_2 - 56;
                                    default: begin
                                    end
                                endcase
                            end
                            else begin
                                // flag
                                flag_ver_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 0;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 3) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 0;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                    end
                    16: begin
                        if(which_sram_rd == 0) begin
                            if(cnt < 257) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_ver_flip <= 0;
                                // addr_1
                                if(addr_1 < 256)
                                    addr_1 <= addr_1 + 1;
                                else begin
                                    
                                end
                                // addr_2
                                case(addr_1 >> 4)
                                    0:   addr_2 <= addr_1 + 240;
                                    1:   addr_2 <= addr_1 + 208;
                                    2:   addr_2 <= addr_1 + 176;
                                    3:   addr_2 <= addr_1 + 144;
                                    4:   addr_2 <= addr_1 + 112;
                                    5:   addr_2 <= addr_1 + 80;
                                    6:   addr_2 <= addr_1 + 48;
                                    7:   addr_2 <= addr_1 + 16;
                                    8:   addr_2 <= addr_1 - 16;
                                    9:   addr_2 <= addr_1 - 48;
                                    10:  addr_2 <= addr_1 - 80;
                                    11:  addr_2 <= addr_1 - 112;
                                    12:  addr_2 <= addr_1 - 144;  
                                    13:  addr_2 <= addr_1 - 176;
                                    14:  addr_2 <= addr_1 - 208;
                                    15:  addr_2 <= addr_1 - 240;
                                    default: begin
                                    end
                                endcase
                            end
                            else begin
                                // flag
                                flag_ver_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 1;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 3) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 1;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                        else begin // which_sram_rd == 1
                            if(cnt < 257) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_ver_flip <= 0;
                                // addr_1
                                if(addr_2 < 256)
                                    addr_2 <= addr_2 + 1;
                                else begin
                                    
                                end
                                // addr_2
                                case(addr_2 >> 4)
                                    0:   addr_1 <= addr_2 + 240;
                                    1:   addr_1 <= addr_2 + 208;
                                    2:   addr_1 <= addr_2 + 176;
                                    3:   addr_1 <= addr_2 + 144;
                                    4:   addr_1 <= addr_2 + 112;
                                    5:   addr_1 <= addr_2 + 80;
                                    6:   addr_1 <= addr_2 + 48;
                                    7:   addr_1 <= addr_2 + 16;
                                    8:   addr_1 <= addr_2 - 16;
                                    9:   addr_1 <= addr_2 - 48;
                                    10:  addr_1 <= addr_2 - 80;
                                    11:  addr_1 <= addr_2 - 112;
                                    12:  addr_1 <= addr_2 - 144;  
                                    13:  addr_1 <= addr_2 - 176;
                                    14:  addr_1 <= addr_2 - 208;
                                    15:  addr_1 <= addr_2 - 240;
                                    default: begin
                                    end
                                endcase
                            end
                            else begin
                                // flag
                                flag_ver_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 0;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 3) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 0;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                    end
                    default: begin
                    end
                endcase
            end
            s_left_flip_pre: begin
                // flag
                flag_hor_flip <= 0;
                flag_ver_flip <= 0;
                flag_left_flip <= 0;
                flag_right_flip <= 0;
                flag_short_cut_bright <= 0;
                flag_zoom_in <= 0;
                flag_max <= 0;
                flag_conv <= 0;

                if(which_sram_rd == 0) begin
                    case(size)
                        4: begin
                            addr_1 <= 15;
                            addr_2 <= 0;
                        end
                        8: begin
                            addr_1 <= 63;
                            addr_2 <= 0;
                        end
                        16: begin
                            addr_1 <= 255;
                            addr_2 <= 0;
                        end
                        default: begin
                        end
                    endcase
                end
                else begin
                     case(size)
                        4: begin
                            addr_1 <= 0;
                            addr_2 <= 15;
                        end
                        8: begin
                            addr_1 <= 0;
                            addr_2 <= 63;
                        end
                        16: begin
                            addr_1 <= 0;
                            addr_2 <= 255;
                        end
                        default: begin
                        end
                    endcase
                end
            end
            s_left_flip: begin
                case(size)
                    4:  begin
                        if(which_sram_rd == 0) begin
                            if(cnt < 17) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_left_flip <= 0;
                            
                                // calculate
                                if(cnt >= 1) addr_2 <= addr_2 + 1;
                                else addr_2 <= 0;

                                case(addr_1)
                                    0:       addr_1 <= 0;
                                    1:       addr_1 <= 12;                         
                                    2:       addr_1 <= 13;                               
                                    3:       addr_1 <= 14;
                                    default: addr_1 <= addr_1 - 4;
                                endcase
                            end
                            else begin
                                // flag
                                flag_left_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 1;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 4) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 1;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                        else begin // which_sram_rd == 1
                            if(cnt < 17) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_left_flip <= 0;

                                // calculate
                                if(cnt >= 1) addr_1 <= addr_1 + 1;
                                else addr_1 <= 0;

                                case(addr_2)
                                    0:       addr_2 <= 0;
                                    1:       addr_2 <= 12;                         
                                    2:       addr_2 <= 13;                               
                                    3:       addr_2 <= 14;
                                    default: addr_2 <= addr_2 - 4;
                                endcase
                            end
                            else begin
                                // flag
                                flag_left_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 0;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 4) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 0;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                    end
                    8:  begin
                        if(which_sram_rd == 0) begin
                            if(cnt < 65) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_left_flip <= 0;
                            
                                // calculate
                                if(cnt >= 1) addr_2 <= addr_2 + 1;
                                else addr_2 <= 0;

                                case(addr_1)
                                    0:       addr_1 <= 0;
                                    1:       addr_1 <= 56;                         
                                    2:       addr_1 <= 57;                               
                                    3:       addr_1 <= 58;
                                    4:       addr_1 <= 59;
                                    5:       addr_1 <= 60;
                                    6:       addr_1 <= 61;
                                    7:       addr_1 <= 62;
                                    default: addr_1 <= addr_1 - 8;
                                endcase
                            end
                            else begin
                                // flag
                                flag_left_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 1;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 4) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 1;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                        else begin // which_sram_rd == 1
                            if(cnt < 65) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_left_flip <= 0;

                                // calculate
                                if(cnt >= 1) addr_1 <= addr_1 + 1;
                                else addr_1 <= 0;

                                case(addr_2)
                                    0:       addr_2 <= 0;
                                    1:       addr_2 <= 56;                         
                                    2:       addr_2 <= 57;                               
                                    3:       addr_2 <= 58;
                                    4:       addr_2 <= 59;
                                    5:       addr_2 <= 60;
                                    6:       addr_2 <= 61;
                                    7:       addr_2 <= 62;
                                    default: addr_2 <= addr_2 - 8;
                                endcase
                            end
                            else begin
                                // flag
                                flag_left_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 0;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 4) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 0;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                    end
                    16: begin
                        if(which_sram_rd == 0) begin
                            if(cnt < 257) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_left_flip <= 0;
                            
                                // calculate
                                if(cnt >= 1) addr_2 <= addr_2 + 1;
                                else addr_2 <= 0;

                                case(addr_1)
                                    0:       addr_1 <= 0;
                                    1:       addr_1 <= 240;
                                    2:       addr_1 <= 241;
                                    3:       addr_1 <= 242;
                                    4:       addr_1 <= 243;
                                    5:       addr_1 <= 244;
                                    6:       addr_1 <= 245;
                                    7:       addr_1 <= 246;
                                    8:       addr_1 <= 247;
                                    9:       addr_1 <= 248;
                                    10:      addr_1 <= 249;
                                    11:      addr_1 <= 250;
                                    12:      addr_1 <= 251;
                                    13:      addr_1 <= 252;
                                    14:      addr_1 <= 253;
                                    15:      addr_1 <= 254;
                                    default: addr_1 <= addr_1 - 16;
                                endcase
                            end
                            else begin
                                // flag
                                flag_left_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 1;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 4) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 1;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                        else begin // which_sram_rd == 1
                            if(cnt < 257) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_left_flip <= 0;

                                // calculate
                                if(cnt >= 1) addr_1 <= addr_1 + 1;
                                else addr_1 <= 0;

                                case(addr_2)
                                    0:       addr_2 <= 0;
                                    1:       addr_2 <= 240;
                                    2:       addr_2 <= 241;
                                    3:       addr_2 <= 242;
                                    4:       addr_2 <= 243;
                                    5:       addr_2 <= 244;
                                    6:       addr_2 <= 245;
                                    7:       addr_2 <= 246;
                                    8:       addr_2 <= 247;
                                    9:       addr_2 <= 248;
                                    10:      addr_2 <= 249;
                                    11:      addr_2 <= 250;
                                    12:      addr_2 <= 251;
                                    13:      addr_2 <= 252;
                                    14:      addr_2 <= 253;
                                    15:      addr_2 <= 254;
                                    default: addr_2 <= addr_2 - 16;
                                endcase
                            end
                            else begin
                                // flag
                                flag_left_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 0;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 4) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 0;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                    end
                    default: begin
                    end
                endcase
            end
            s_right_flip: begin
                // flag
                flag_hor_flip <= 0;
                flag_ver_flip <= 0;
                flag_left_flip <= 0;
                flag_short_cut_bright <= 0;
                //flag_right_flip <= 0;
                flag_zoom_in <= 0;
                flag_max <= 0;
                flag_conv <= 0;

                case(size)
                    4:  begin
                        if(which_sram_rd == 0) begin
                            if(cnt < 17) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_right_flip <= 0;
                            
                                // calculate
                                if(cnt >= 1) addr_2 <= addr_2 + 1;
                                else addr_2 <= 0;

                                case(addr_1)
                                    12:      addr_1 <= 1;                         
                                    13:      addr_1 <= 2;                               
                                    14:      addr_1 <= 3;
                                    15:      addr_1 <= 0;
                                    default: addr_1 <= addr_1 + 4;
                                endcase
                            end
                            else begin
                                // flag
                                flag_right_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 1;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 5) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 1;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                        else begin // which_sram_rd == 1
                            if(cnt < 17) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_right_flip <= 0;

                                // calculate
                                if(cnt >= 1) addr_1 <= addr_1 + 1;
                                else addr_1 <= 0;

                                case(addr_2)
                                    12:      addr_2 <= 1;                         
                                    13:      addr_2 <= 2;                               
                                    14:      addr_2 <= 3;
                                    15:      addr_2 <= 0;
                                    default: addr_2 <= addr_2 + 4;
                                endcase
                            end
                            else begin
                                // flag
                                flag_right_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 0;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 5) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 0;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                    end
                    8:  begin
                        if(which_sram_rd == 0) begin
                            if(cnt < 65) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_right_flip <= 0;
                            
                                // calculate
                                if(cnt >= 1) addr_2 <= addr_2 + 1;
                                else addr_2 <= 0;

                                case(addr_1)
                                    56:      addr_1 <= 1;                         
                                    57:      addr_1 <= 2;                               
                                    58:      addr_1 <= 3;
                                    59:      addr_1 <= 4;
                                    60:      addr_1 <= 5;
                                    61:      addr_1 <= 6;
                                    62:      addr_1 <= 7;
                                    63:      addr_1 <= 0;
                                    default: addr_1 <= addr_1 + 8;
                                endcase
                            end
                            else begin
                                // flag
                                flag_right_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 1;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 5) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 1;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                        else begin // which_sram_rd == 1
                            if(cnt < 65) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_right_flip <= 0;

                                // calculate
                                if(cnt >= 1) addr_1 <= addr_1 + 1;
                                else addr_1 <= 0;

                                case(addr_2)
                                    56:      addr_2 <= 1;                         
                                    57:      addr_2 <= 2;                               
                                    58:      addr_2 <= 3;
                                    59:      addr_2 <= 4;
                                    60:      addr_2 <= 5;
                                    61:      addr_2 <= 6;
                                    62:      addr_2 <= 7;
                                    63:      addr_2 <= 0;
                                    default: addr_2 <= addr_2 + 8;
                                endcase
                            end
                            else begin
                                // flag
                                flag_right_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 0;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 5) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 0;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                    end
                    16: begin
                        if(which_sram_rd == 0) begin
                            if(cnt < 257) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_right_flip <= 0;
                            
                                // calculate
                                if(cnt >= 1) addr_2 <= addr_2 + 1;
                                else addr_2 <= 0;

                                case(addr_1)
                                    240:     addr_1 <= 1;
                                    241:     addr_1 <= 2;
                                    242:     addr_1 <= 3;
                                    243:     addr_1 <= 4;
                                    244:     addr_1 <= 5;
                                    245:     addr_1 <= 6;
                                    246:     addr_1 <= 7;
                                    247:     addr_1 <= 8;
                                    248:     addr_1 <= 9;
                                    249:     addr_1 <= 10;
                                    250:     addr_1 <= 11;
                                    251:     addr_1 <= 12;
                                    252:     addr_1 <= 13;
                                    253:     addr_1 <= 14;
                                    254:     addr_1 <= 15;
                                    255:     addr_1 <= 0;
                                    default: addr_1 <= addr_1 + 16;
                                endcase
                            end
                            else begin
                                // flag
                                flag_right_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 1;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 5) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 1;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                        else begin // which_sram_rd == 1
                            if(cnt < 257) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_right_flip <= 0;

                                // calculate
                                if(cnt >= 1) addr_1 <= addr_1 + 1;
                                else addr_1 <= 0;

                                case(addr_2)
                                    240:     addr_2 <= 1;
                                    241:     addr_2 <= 2;
                                    242:     addr_2 <= 3;
                                    243:     addr_2 <= 4;
                                    244:     addr_2 <= 5;
                                    245:     addr_2 <= 6;
                                    246:     addr_2 <= 7;
                                    247:     addr_2 <= 8;
                                    248:     addr_2 <= 9;
                                    249:     addr_2 <= 10;
                                    250:     addr_2 <= 11;
                                    251:     addr_2 <= 12;
                                    252:     addr_2 <= 13;
                                    253:     addr_2 <= 14;
                                    254:     addr_2 <= 15;
                                    255:     addr_2 <= 0;
                                    default: addr_2 <= addr_2 + 16;
                                endcase
                            end
                            else begin
                                // flag
                                flag_right_flip <= 1;
                                // which_sram_rd
                                // which_sram_rd <= 0;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                // cnt_current_act <= cnt_current_act + 1;
                                if(act[cnt_current_act+1] == 5) begin
                                    cnt_current_act <= cnt_current_act + 2;
                                end
                                else begin
                                    which_sram_rd <= 0;
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                        end
                    end
                    default: begin
                    end
                endcase
            end
            s_short_cut_bright_pre: begin
                // flag
                flag_hor_flip <= 0;
                flag_ver_flip <= 0;
                flag_left_flip <= 0;
                flag_right_flip <= 0;
                flag_short_cut_bright <= 0;
                flag_zoom_in <= 0;
                flag_max <= 0;
                flag_conv <= 0;

                if(which_sram_rd == 0) begin
                    case(size)
                        4: begin
                            addr_1 <= 0;
                            addr_2 <= 0;
                        end
                        8: begin
                            addr_1 <= 18;
                            addr_2 <= 0;
                        end
                        16: begin
                            addr_1 <= 68;
                            addr_2 <= 0;
                        end
                        default: begin
                        end
                    endcase
                end
                else begin
                     case(size)
                        4: begin
                            addr_1 <= 0;
                            addr_2 <= 0;
                        end
                        8: begin
                            addr_1 <= 0;
                            addr_2 <= 18;
                        end
                        16: begin
                            addr_1 <= 0;
                            addr_2 <= 68;
                        end
                        default: begin
                        end
                    endcase
                end
            end
            s_short_cut_bright: begin
                case(size)
                    4:  begin
                        if(which_sram_rd == 0) begin
                            if(cnt < 17) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_short_cut_bright <= 0;
                            
                                // calculate
                                addr_1 <= addr_1 + 1;
                                if(cnt >= 1) addr_2 <= addr_2 + 1;
                                else addr_2 <= 0;

                            end
                            else begin
                                // flag
                                flag_short_cut_bright <= 1;
                                // which_sram_rd
                                which_sram_rd <= 1;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                cnt_current_act <= cnt_current_act + 1;
                            end
                        end
                        else begin // which_sram_rd == 1
                            if(cnt < 17) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_short_cut_bright <= 0;

                                // calculate
                                if(cnt >= 1) addr_1 <= addr_1 + 1;
                                else addr_1 <= 0;
                                addr_2 <= addr_2 + 1;
                            end
                            else begin
                                // flag
                                flag_short_cut_bright <= 1;
                                // which_sram_rd
                                which_sram_rd <= 0;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                cnt_current_act <= cnt_current_act + 1;
                            end
                        end
                    end
                    8:  begin
                        if(which_sram_rd == 0) begin
                            if(cnt < 17) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_short_cut_bright <= 0;
                            
                                // calculate
                                if(cnt >= 1) addr_2 <= addr_2 + 1;
                                else addr_2 <= 0;
                                
                                case(addr_1)
                                    21:      addr_1 <= 26;
                                    29:      addr_1 <= 34;
                                    37:      addr_1 <= 42;
                                    45:      addr_1 <= 0;
                                    default: addr_1 <= addr_1 + 1;
                                endcase
                            end
                            else begin
                                // flag
                                flag_short_cut_bright <= 1;
                                // which_sram_rd
                                which_sram_rd <= 1;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                cnt_current_act <= cnt_current_act + 1;
                                // size
                                size <= (size >> 1);
                            end
                        end
                        else begin // which_sram_rd == 1
                            if(cnt < 17) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_short_cut_bright <= 0;

                                // calculate
                                if(cnt >= 1) addr_1 <= addr_1 + 1;
                                else addr_1 <= 0;

                                case(addr_2)
                                    21:      addr_2 <= 26;
                                    29:      addr_2 <= 34;
                                    37:      addr_2 <= 42;
                                    45:      addr_2 <= 0;
                                    default: addr_2 <= addr_2 + 1;
                                endcase
                            end
                            else begin
                                // flag
                                flag_short_cut_bright <= 1;
                                // which_sram_rd
                                which_sram_rd <= 0;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                cnt_current_act <= cnt_current_act + 1;
                                // size
                                size <= (size >> 1);
                            end
                        end
                    end
                    16: begin
                        if(which_sram_rd == 0) begin
                            if(cnt < 65) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_short_cut_bright <= 0;
                            
                                // calculate
                                if(cnt >= 1) addr_2 <= addr_2 + 1;
                                else addr_2 <= 0;

                                case(addr_1)
                                    75:      addr_1 <= 84;
                                    91:      addr_1 <= 100;
                                    107:     addr_1 <= 116;
                                    123:     addr_1 <= 132;
                                    139:     addr_1 <= 148;
                                    155:     addr_1 <= 164;
                                    171:     addr_1 <= 180;
                                    187:     addr_1 <= 0;
                                    default: addr_1 <= addr_1 + 1;
                                endcase
                            end
                            else begin
                                // flag
                                flag_short_cut_bright <= 1;
                                // which_sram_rd
                                which_sram_rd <= 1;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                cnt_current_act <= cnt_current_act + 1;
                                // size
                                size <= (size >> 1);
                            end
                        end
                        else begin // which_sram_rd == 1
                            if(cnt < 65) begin
                                // cnt
                                cnt <= cnt + 1;
                                // flag
                                flag_short_cut_bright <= 0;

                                // calculate
                                if(cnt >= 1) addr_1 <= addr_1 + 1;
                                else addr_1 <= 0;

                                case(addr_2)
                                    75:      addr_2 <= 84;
                                    91:      addr_2 <= 100;
                                    107:     addr_2 <= 116;
                                    123:     addr_2 <= 132;
                                    139:     addr_2 <= 148;
                                    155:     addr_2 <= 164;
                                    171:     addr_2 <= 180;
                                    187:     addr_2 <= 0;
                                    default: addr_2 <= addr_2 + 1;
                                endcase
                            end
                            else begin
                                // flag
                                flag_short_cut_bright <= 1;
                                // which_sram_rd
                                which_sram_rd <= 0;
                                // cnt
                                cnt <= 0;
                                // addr
                                addr_1 <= 0;
                                addr_2 <= 0;
                                // cnt_current_act
                                cnt_current_act <= cnt_current_act + 1;
                                // size
                                size <= (size >> 1);
                            end
                        end
                    end
                    default: begin
                    end
                endcase
            end
            s_zoom_in_set: begin
                // flag
                flag_hor_flip <= 0;
                flag_ver_flip <= 0;
                flag_left_flip <= 0;
                flag_short_cut_bright <= 0;
                flag_right_flip <= 0;
                //flag_zoom_in <= 0;
                flag_next_zoom <= 0;
                flag_max <= 0;
                flag_conv <= 0;

                if(size == 16) begin
                    // cnt_zoom
                    cnt_zoom <= 0;
                    // flag
                    flag_zoom_in <= 1;
                   
                    // addr
                    addr_1 <= 0;
                    addr_2 <= 0;
                    // cnt_current_act
                    cnt_current_act <= cnt_current_act + 1;
                end
                else if(cnt_zoom == 4) begin
                    // cnt_zoom
                    cnt_zoom <= 0;
                    // flag
                    flag_zoom_in <= 1;
                    // which_sram_rd
                    which_sram_rd <= (which_sram_rd == 0) ? 1 : 0;
                    // addr
                    addr_1 <= 0;
                    addr_2 <= 0;
                    // cnt_current_act
                    cnt_current_act <= cnt_current_act + 1;
                    // size
                    size <= size << 1;
                end
                else begin
                    flag_zoom_in <= 0;
                    case(size)
                        4:  begin
                            case(cnt_zoom)
                                1:  begin
                                    addr_1 <= (which_sram_rd == 0) ? 0 : 1;
                                    addr_2 <= (which_sram_rd == 0) ? 1 : 0;
                                end
                                2:  begin
                                    addr_1 <= (which_sram_rd == 0) ? 0 : 8;
                                    addr_2 <= (which_sram_rd == 0) ? 8 : 0;
                                end
                                3:  begin
                                    addr_1 <= (which_sram_rd == 0) ? 0 : 9;
                                    addr_2 <= (which_sram_rd == 0) ? 9 : 0;
                                end
                                default: begin
                                    addr_1 <= 0;
                                    addr_2 <= 0;
                                end
                            endcase
                        end
                        8:  begin
                            case(cnt_zoom)
                                1:  begin
                                    addr_1 <= (which_sram_rd == 0) ? 0 : 1;
                                    addr_2 <= (which_sram_rd == 0) ? 1 : 0;
                                end
                                2:  begin
                                    addr_1 <= (which_sram_rd == 0) ? 0 : 16;
                                    addr_2 <= (which_sram_rd == 0) ? 16 : 0;
                                end
                                3:  begin
                                    addr_1 <= (which_sram_rd == 0) ? 0 : 17;
                                    addr_2 <= (which_sram_rd == 0) ? 17 : 0;
                                end
                                default: begin
                                    addr_1 <= 0;
                                    addr_2 <= 0;
                                end
                            endcase
                        end
                        default: begin
                            addr_1 <= 0;
                            addr_2 <= 0;
                        end
                    endcase
                end
            end
            s_zoom_in: begin
                case(size)
                    4:  begin
                        if(which_sram_rd == 0) begin
                            if(cnt < 17) begin
                                // cnt
                                cnt <= cnt + 1;
                               
                                // calculate
                                addr_1 <= addr_1 + 1;
                                case(cnt_zoom)
                                    0:  begin
                                        case(addr_2)
                                            6:  addr_2 <= 16;
                                            22: addr_2 <= 32;
                                            38: addr_2 <= 48;
                                            54: addr_2 <= 0;
                                            default: begin
                                                if(cnt >= 1) addr_2 <= addr_2 + 2;
                                                else begin
                                                end
                                            end
                                        endcase
                                    end
                                    1:  begin
                                        case(addr_2)
                                            7:  addr_2 <= 17;
                                            23: addr_2 <= 33;
                                            39: addr_2 <= 49;
                                            55: addr_2 <= 0;
                                            default: begin
                                                if(cnt >= 1) addr_2 <= addr_2 + 2;
                                                else begin
                                                end
                                            end
                                        endcase
                                    end
                                    2:  begin
                                        case(addr_2)
                                            14: addr_2 <= 24;
                                            30: addr_2 <= 40;
                                            46: addr_2 <= 56;
                                            62: addr_2 <= 0;
                                            default: begin
                                                if(cnt >= 1) addr_2 <= addr_2 + 2;
                                                else begin
                                                end
                                            end
                                        endcase
                                    end
                                    3:  begin
                                        case(addr_2)
                                            15: addr_2 <= 25;
                                            31: addr_2 <= 41;
                                            47: addr_2 <= 57;
                                            63: addr_2 <= 0;
                                            default: begin
                                                if(cnt >= 1) addr_2 <= addr_2 + 2;
                                                else begin
                                                end
                                            end
                                        endcase
                                    end
                                    default:begin
                                    end 
                                endcase
                            end
                            else begin
                                cnt_zoom <= cnt_zoom + 1;
                                flag_next_zoom <= 1;
                                cnt <= 0;
                            end
                        end
                        else begin // which_sram_rd == 1
                            if(cnt < 17) begin
                                // cnt
                                cnt <= cnt + 1;
                                
                                // calculate
                                addr_2 <= addr_2 + 1;
                                case(cnt_zoom)
                                    0:  begin
                                        case(addr_1)
                                            6:  addr_1 <= 16;
                                            22: addr_1 <= 32;
                                            38: addr_1 <= 48;
                                            54: addr_1 <= 0;
                                            default: begin
                                                if(cnt >= 1) addr_1 <= addr_1 + 2;
                                                else begin
                                                end
                                            end
                                        endcase
                                    end
                                    1:  begin
                                        case(addr_1)
                                            7:  addr_1 <= 17;
                                            23: addr_1 <= 33;
                                            39: addr_1 <= 49;
                                            55: addr_1 <= 0;
                                            default: begin
                                                if(cnt >= 1) addr_1 <= addr_1 + 2;
                                                else begin
                                                end
                                            end
                                        endcase
                                    end
                                    2:  begin
                                        case(addr_1)
                                            14: addr_1 <= 24;
                                            30: addr_1 <= 40;
                                            46: addr_1 <= 56;
                                            62: addr_1 <= 0;
                                            default: begin
                                                if(cnt >= 1) addr_1 <= addr_1 + 2;
                                                else begin
                                                end
                                            end
                                        endcase
                                    end
                                    3:  begin
                                        case(addr_1)
                                            15: addr_1 <= 25;
                                            31: addr_1 <= 41;
                                            47: addr_1 <= 57;
                                            63: addr_1 <= 0;
                                            default: begin
                                                if(cnt >= 1) addr_1 <= addr_1 + 2;
                                                else begin
                                                end
                                            end
                                        endcase
                                    end
                                    default:begin
                                    end 
                                endcase
                            end
                            else begin
                                cnt_zoom <= cnt_zoom + 1;
                                flag_next_zoom <= 1;
                                cnt <= 0;
                            end
                        end
                    end
                    8:  begin
                        if(which_sram_rd == 0) begin
                            if(cnt < 65) begin
                                // cnt
                                cnt <= cnt + 1;
                                // calculate
                                addr_1 <= addr_1 + 1;
                                case(cnt_zoom)
                                    0:  begin
                                        case(addr_2)
                                            14:  addr_2 <= 32;
                                            46:  addr_2 <= 64;
                                            78:  addr_2 <= 96;
                                            110: addr_2 <= 128;
                                            142: addr_2 <= 160;
                                            174: addr_2 <= 192;
                                            206: addr_2 <= 224;
                                            238: addr_2 <= 0;
                                            default: begin
                                                if(cnt >= 1) addr_2 <= addr_2 + 2;
                                                else begin
                                                end
                                            end
                                        endcase
                                    end
                                    1:  begin
                                        case(addr_2)
                                            15:  addr_2 <= 33;
                                            47:  addr_2 <= 65;
                                            79:  addr_2 <= 97;
                                            111: addr_2 <= 129;
                                            143: addr_2 <= 161;
                                            175: addr_2 <= 193;
                                            207: addr_2 <= 225;
                                            239: addr_2 <= 0;
                                            default: begin
                                                if(cnt >= 1) addr_2 <= addr_2 + 2;
                                                else begin
                                                end
                                            end
                                        endcase
                                    end
                                    2:  begin
                                        case(addr_2)
                                            30:  addr_2 <= 48;
                                            62:  addr_2 <= 80;
                                            94:  addr_2 <= 112;
                                            126: addr_2 <= 144;
                                            158: addr_2 <= 176;
                                            190: addr_2 <= 208;
                                            222: addr_2 <= 240;
                                            254: addr_2 <= 0;
                                            default: begin
                                                if(cnt >= 1) addr_2 <= addr_2 + 2;
                                                else begin
                                                end
                                            end
                                        endcase
                                    end
                                    3:  begin
                                        case(addr_2)
                                            31:  addr_2 <= 49;
                                            63:  addr_2 <= 81;
                                            95:  addr_2 <= 113;
                                            127: addr_2 <= 145;
                                            159: addr_2 <= 177;
                                            191: addr_2 <= 209;
                                            223: addr_2 <= 241;
                                            255: addr_2 <= 0;
                                            default: begin
                                                if(cnt >= 1) addr_2 <= addr_2 + 2;
                                                else begin
                                                end
                                            end
                                        endcase
                                    end
                                    default:begin
                                    end 
                                endcase
                            end
                            else begin
                                cnt_zoom <= cnt_zoom + 1;
                                flag_next_zoom <= 1;
                                cnt <= 0;
                            end
                        end
                        else begin // which_sram_rd == 1
                            if(cnt < 65) begin
                                // cnt
                                cnt <= cnt + 1;
                                // calculate
                                addr_2 <= addr_2 + 1;
                                case(cnt_zoom)
                                    0:  begin
                                        case(addr_1)
                                            14:  addr_1 <= 32;
                                            46:  addr_1 <= 64;
                                            78:  addr_1 <= 96;
                                            110: addr_1 <= 128;
                                            142: addr_1 <= 160;
                                            174: addr_1 <= 192;
                                            206: addr_1 <= 224;
                                            238: addr_1 <= 0;
                                            default: begin
                                                if(cnt >= 1) addr_1 <= addr_1 + 2;
                                                else begin
                                                end
                                            end
                                        endcase
                                    end
                                    1:  begin
                                        case(addr_1)
                                            15:  addr_1 <= 33;
                                            47:  addr_1 <= 65;
                                            79:  addr_1 <= 97;
                                            111: addr_1 <= 129;
                                            143: addr_1 <= 161;
                                            175: addr_1 <= 193;
                                            207: addr_1 <= 225;
                                            239: addr_1 <= 0;
                                            default: begin
                                                if(cnt >= 1) addr_1 <= addr_1 + 2;
                                                else begin
                                                end
                                            end
                                        endcase
                                    end
                                    2:  begin
                                        case(addr_1)
                                            30:  addr_1 <= 48;
                                            62:  addr_1 <= 80;
                                            94:  addr_1 <= 112;
                                            126: addr_1 <= 144;
                                            158: addr_1 <= 176;
                                            190: addr_1 <= 208;
                                            222: addr_1 <= 240;
                                            254: addr_1 <= 0;
                                            default: begin
                                                if(cnt >= 1) addr_1 <= addr_1 + 2;
                                                else begin
                                                end
                                            end
                                        endcase
                                    end
                                    3:  begin
                                        case(addr_1)
                                            31:  addr_1 <= 49;
                                            63:  addr_1 <= 81;
                                            95:  addr_1 <= 113;
                                            127: addr_1 <= 145;
                                            159: addr_1 <= 177;
                                            191: addr_1 <= 209;
                                            223: addr_1 <= 241;
                                            255: addr_1 <= 0;
                                            default: begin
                                                if(cnt >= 1) addr_1 <= addr_1 + 2;
                                                else begin
                                                end
                                            end
                                        endcase
                                    end
                                    default:begin
                                    end 
                                endcase
                            end
                            else begin
                                cnt_zoom <= cnt_zoom + 1;
                                flag_next_zoom <= 1;
                                cnt <= 0;
                            end
                        end
                    end
                    default: begin 
                    end
                endcase
            end
            s_max_reset: begin // 14
                // flag
                flag_hor_flip <= 0;
                flag_ver_flip <= 0;
                flag_left_flip <= 0;
                flag_short_cut_bright <= 0;
                flag_right_flip <= 0;
                flag_zoom_in <= 0;
                // flag_max <= 0;
                flag_conv <= 0;

                if(size == 4) begin
                    // flag
                    flag_max <= 1;
                    flag_next_max <= 0;
                    // addr
                    addr_1 <= 0;
                    addr_2 <= 0;
                    // cnt_current_act
                    cnt_current_act <= cnt_current_act + 1;
                end
                else begin
                    if(which_sram_rd == 0) begin
                        case(size)
                            8:  begin
                                if(addr_2 < 16) begin
                                    // flag
                                    flag_max <= 0;
                                    // addr
                                    if(flag_next_max == 1) begin
                                        flag_next_max <= 0;
                                        case(addr_1)
                                            14:      addr_1 <= 16;
                                            30:      addr_1 <= 32;
                                            46:      addr_1 <= 48;
                                            62:      addr_1 <= 0;
                                            default: addr_1 <= addr_1 - 6;
                                        endcase
                                    end
                                    else 
                                        addr_1 <= 0;
                                end
                                else begin
                                    // flag
                                    flag_max <= 1;
                                    flag_next_max <= 0;
                                    // which_sram_rd
                                    which_sram_rd <= 1;
                                    // addr
                                    addr_1 <= 0;
                                    addr_2 <= 0;
                                    // size 
                                    size <= size >> 1;
                                    // cnt_current_act
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                            16: begin
                                if(addr_2 < 64) begin
                                    // flag
                                    flag_max <= 0;
                                    // addr
                                    if(flag_next_max == 1) begin
                                        flag_next_max <= 0;
                                        case(addr_1)
                                            30:      addr_1 <= 32;
                                            62:      addr_1 <= 64;
                                            94:      addr_1 <= 96;
                                            126:     addr_1 <= 128;
                                            158:     addr_1 <= 160;
                                            190:     addr_1 <= 192;
                                            222:     addr_1 <= 224;
                                            254:     addr_1 <= 0;
                                            default: addr_1 <= addr_1 - 14;
                                        endcase
                                    end
                                    else 
                                        addr_1 <= 0;
                                end
                                else begin
                                    // flag
                                    flag_max <= 1;
                                    flag_next_max <= 0;
                                    // which_sram_rd
                                    which_sram_rd <= 1;
                                    // addr
                                    addr_1 <= 0;
                                    addr_2 <= 0;
                                    // size 
                                    size <= size >> 1;
                                    // cnt_current_act
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                            default: begin
                            end
                        endcase
                    end
                    else begin // which_sram_rd == 1
                        case(size)
                            8:  begin
                                if(addr_1 < 16) begin
                                    // flag
                                    flag_max <= 0;
                                    // addr
                                    if(flag_next_max == 1) begin
                                        flag_next_max <= 0;
                                        case(addr_2)
                                            14:      addr_2 <= 16;
                                            30:      addr_2 <= 32;
                                            46:      addr_2 <= 48;
                                            62:      addr_2 <= 0;
                                            default: addr_2 <= addr_2 - 6;
                                        endcase
                                    end
                                    else 
                                        addr_2 <= 0;
                                end
                                else begin
                                    // flag
                                    flag_max <= 1;
                                    flag_next_max <= 0;
                                    // which_sram_rd
                                    which_sram_rd <= 0;
                                    // addr
                                    addr_1 <= 0;
                                    addr_2 <= 0;
                                    // size 
                                    size <= size >> 1;
                                    // cnt_current_act
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                            end
                            16: begin
                                if(addr_1 < 64) begin
                                    // flag
                                    flag_max <= 0;
                                    // addr
                                    if(flag_next_max == 1) begin
                                        flag_next_max <= 0;
                                        case(addr_2)
                                            30:      addr_2 <= 32;
                                            62:      addr_2 <= 64;
                                            94:      addr_2 <= 96;
                                            126:     addr_2 <= 128;
                                            158:     addr_2 <= 160;
                                            190:     addr_2 <= 192;
                                            222:     addr_2 <= 224;
                                            254:     addr_2 <= 0;
                                            default: addr_2 <= addr_2 - 14;
                                        endcase
                                    end
                                    else 
                                        addr_2 <= 0;
                                end
                                else begin
                                    // flag
                                    flag_max <= 1;
                                    flag_next_max <= 0;
                                    // which_sram_rd
                                    which_sram_rd <= 0;
                                    // addr
                                    addr_1 <= 0;
                                    addr_2 <= 0;
                                    // size 
                                    size <= size >> 1;
                                    // cnt_current_act
                                    cnt_current_act <= cnt_current_act + 1;
                                end
                                
                            end
                            default: begin
                            end
                        endcase
                    end
                end
            end
            s_max_read_1: begin // 15
                // 8
                max <= tmp_max;
                if(which_sram_rd == 0)
                    addr_1 <= addr_1 + 1;
                else
                    addr_2 <= addr_2 + 1;
            end
            s_max_read_2: begin //  16
                // 8
                max <= tmp_max;
                if(which_sram_rd == 0)
                    addr_1 <= addr_1 + size;
                else
                    addr_2 <= addr_2 + size;
            end
            s_max_read_3: begin // 17
                // 8
                max <= tmp_max;
                if(which_sram_rd == 0)
                    addr_1 <= addr_1 - 1;
                else
                    addr_2 <= addr_2 - 1;
            end
            s_max_read_4, s_max_read_5: begin // 18
                // 8
                max <= tmp_max;
            end
            s_max_write: begin // 19
                // flag
                flag_next_max <= 1;
                // cnt <= cnt + 1;
                if(which_sram_rd == 0)
                    addr_2 <= addr_2 + 1;
                else
                    addr_1 <= addr_1 + 1;
            end
            s_conv_reset: begin // 20
                // flag
                flag_hor_flip <= 0;
                flag_ver_flip <= 0;
                flag_left_flip <= 0;
                flag_short_cut_bright <= 0;
                flag_right_flip <= 0;
                flag_zoom_in <= 0;
                flag_max <= 0;
                // flag_conv <= 0;
                // 4
                if(addr_3 < area) begin
                    flag_conv <= 0;
                    if(which_sram_rd == 0) 
                        addr_1 <= addr_3;
                    else
                        addr_2 <= addr_3;
                end
                else begin
                    flag_conv <= 1;
                    addr_1 <= 0;
                    addr_2 <= 0;
                    addr_3 <= 0;
                end     
            end
            s_conv_read_1: begin 
                if(which_sram_rd == 0) 
                    addr_1 <= addr_3 - size - 1;
                else
                    addr_2 <= addr_3 - size - 1;
            end
            s_conv_read_2: begin 
                if(which_sram_rd == 0) 
                    addr_1 <= addr_3 - size;
                else
                    addr_2 <= addr_3 - size;
            end
            s_conv_read_3: begin 
                if(which_sram_rd == 0) 
                    addr_1 <= addr_3 - size + 1;
                else
                    addr_2 <= addr_3 - size + 1;
            end
            s_conv_read_4: begin
                if(which_sram_rd == 0) 
                    addr_1 <= addr_3 - 1;
                else
                    addr_2 <= addr_3 - 1;
            end
            s_conv_read_5: begin
                if(which_sram_rd == 0) 
                    addr_1 <= addr_3 + 1;
                else
                    addr_2 <= addr_3 + 1;
            end
            s_conv_read_6: begin
                if(which_sram_rd == 0) 
                    addr_1 <= addr_3 + size - 1;
                else
                    addr_2 <= addr_3 + size - 1;
            end
            s_conv_read_7: begin
                if(which_sram_rd == 0) 
                    addr_1 <= addr_3 + size;
                else
                    addr_2 <= addr_3 + size;
            end
            s_conv_read_8: begin
                if(which_sram_rd == 0) 
                    addr_1 <= addr_3 + size + 1;
                else
                    addr_2 <= addr_3 + size + 1;
            end
            s_conv_read_9: begin
                addr_1 <= 0;
                addr_2 <= 0;
            end
            s_conv_read_10: begin
                addr_1 <= 0;
                addr_2 <= 0;
            end
            s_conv_write: begin // 31
                // conv_max
                if(addr_3 == 0) begin
                    conv_max_value <= total_conv_ans;
                    conv_max_position <= addr_3;
                end
                else begin
                    if(total_conv_ans > conv_max_value) begin
                        conv_max_value <= total_conv_ans;
                        conv_max_position <= addr_3;
                    end
                    else begin
                        
                    end
                end
                addr_3 <= addr_3 + 1;
            end
            s_out_pre: begin
                flag_conv <= 0;
                addr_3 <= addr_3 + 1;
            end
            s_out: begin
                addr_3 <= addr_3 + 1;
                cnt <= cnt + 1;
            end
            default: begin
            end
        endcase
    end
end

// ===============================================================
// conv_ans
// ===============================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        conv_ans <= 0;
    end
    else begin
        case(next_state)
            s_conv_reset, s_conv_read_1, s_conv_read_2, s_conv_read_3, s_conv_read_4, s_conv_read_5:  begin
                conv_ans <= total_conv_ans;
            end
            s_conv_read_6, s_conv_read_7, s_conv_read_8, s_conv_read_9, s_conv_read_10: begin
                conv_ans <= total_conv_ans;
            end
            default:
                conv_ans <= 0;
        endcase
        // conv_ans <= total_conv_ans;
    end
end

// ===============================================================
// w_r_1, w_r_2, w_data_2, w_data_2
// ===============================================================
always@(*)begin
    w_r_1 = Read;
    w_r_2 = Read;
    w_data_1 = 0;
    w_data_2 = 0;
    
	case(next_state)
        s_in_1: begin
            w_r_1 = Write;
            w_r_2 = Read;
            w_data_1 = image;
            w_data_2 = 0;
        end
        s_hor_flip:begin
            case(size)
                4: begin
                    if(which_sram_rd == 0) begin
                        if(cnt < 17) begin
                            w_r_1 = Read;
                            w_r_2 = Write;
                            w_data_1 = 0;
                            w_data_2 = r_data_1;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                    else begin
                        if(cnt < 17) begin
                            w_r_1 = Write;
                            w_r_2 = Read;
                            w_data_1 = r_data_2;
                            w_data_2 = 0;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                end
                8: begin
                    if(which_sram_rd == 0) begin
                        if(cnt < 65) begin
                            w_r_1 = Read;
                            w_r_2 = Write;
                            w_data_1 = 0;
                            w_data_2 = r_data_1;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                    else begin
                        if(cnt < 65) begin
                            w_r_1 = Write;
                            w_r_2 = Read;
                            w_data_1 = r_data_2;
                            w_data_2 = 0;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                end
                16:begin
                    if(which_sram_rd == 0) begin
                        if(cnt < 257) begin
                            w_r_1 = Read;
                            w_r_2 = Write;
                            w_data_1 = 0;
                            w_data_2 = r_data_1;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                    else begin
                        if(cnt < 257) begin
                            w_r_1 = Write;
                            w_r_2 = Read;
                            w_data_1 = r_data_2;
                            w_data_2 = 0;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                end
                default:begin
                    w_r_1 = Read;
                    w_r_2 = Read;
                    w_data_1 = 0;
                    w_data_2 = 0;
                end
            endcase
        end
        s_ver_flip:begin
            case(size)
                4: begin
                    if(which_sram_rd == 0) begin
                        if(cnt < 17) begin
                            w_r_1 = Read;
                            w_r_2 = Write;
                            w_data_1 = 0;
                            w_data_2 = r_data_1;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                    else begin
                        if(cnt < 17) begin
                            w_r_1 = Write;
                            w_r_2 = Read;
                            w_data_1 = r_data_2;
                            w_data_2 = 0;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                end
                8: begin
                    if(which_sram_rd == 0) begin
                        if(cnt < 65) begin
                            w_r_1 = Read;
                            w_r_2 = Write;
                            w_data_1 = 0;
                            w_data_2 = r_data_1;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                    else begin
                        if(cnt < 65) begin
                            w_r_1 = Write;
                            w_r_2 = Read;
                            w_data_1 = r_data_2;
                            w_data_2 = 0;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                end
                16:begin
                    if(which_sram_rd == 0) begin
                        if(cnt < 257) begin
                            w_r_1 = Read;
                            w_r_2 = Write;
                            w_data_1 = 0;
                            w_data_2 = r_data_1;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                    else begin
                        if(cnt < 257) begin
                            w_r_1 = Write;
                            w_r_2 = Read;
                            w_data_1 = r_data_2;
                            w_data_2 = 0;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                end
                default:begin
                    w_r_1 = Read;
                    w_r_2 = Read;
                    w_data_1 = 0;
                    w_data_2 = 0;
                end
            endcase
        end 
        s_left_flip:begin
            case(size)
                4: begin
                    if(which_sram_rd == 0) begin
                        if(cnt < 17 && cnt >= 1) begin
                            w_r_1 = Read;
                            w_r_2 = Write;
                            w_data_1 = 0;
                            w_data_2 = r_data_1;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                    else begin
                        if(cnt < 17 && cnt >= 1) begin
                            w_r_1 = Write;
                            w_r_2 = Read;
                            w_data_1 = r_data_2;
                            w_data_2 = 0;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                end
                8: begin
                    // tmp_max = 0;
                    if(which_sram_rd == 0) begin
                        if(cnt < 65 && cnt >= 1) begin
                            // mem 
                            w_r_1 = Read;
                            w_r_2 = Write;
                            w_data_1 = 0;
                            w_data_2 = r_data_1;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                    else begin
                        if(cnt < 65 && cnt >= 1) begin
                            w_r_1 = Write;
                            w_r_2 = Read;
                            w_data_1 = r_data_2;
                            w_data_2 = 0;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                end
                16:begin
                    if(which_sram_rd == 0) begin
                        if(cnt < 257 && cnt >= 1) begin
                            w_r_1 = Read;
                            w_r_2 = Write;
                            w_data_1 = 0;
                            w_data_2 = r_data_1;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                    else begin
                        if(cnt < 257 && cnt >= 1) begin
                            w_r_1 = Write;
                            w_r_2 = Read;
                            w_data_1 = r_data_2;
                            w_data_2 = 0;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                end
                default:begin
                    w_r_1 = Read;
                    w_r_2 = Read;
                    w_data_1 = 0;
                    w_data_2 = 0;
                end
            endcase
        end
        s_right_flip:begin
            case(size)
                4:  begin
                    if(which_sram_rd == 0) begin
                        if(cnt < 17 && cnt >= 1) begin
                            w_r_1 = Read;
                            w_r_2 = Write;
                            w_data_1 = 0;
                            w_data_2 = r_data_1;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                    else begin
                        if(cnt < 17 && cnt >= 1) begin
                            w_r_1 = Write;
                            w_r_2 = Read;
                            w_data_1 = r_data_2;
                            w_data_2 = 0;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                end
                8:  begin
                    if(which_sram_rd == 0) begin
                        if(cnt < 65 && cnt >= 1) begin
                            w_r_1 = Read;
                            w_r_2 = Write;
                            w_data_1 = 0;
                            w_data_2 = r_data_1;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                    else begin
                        if(cnt < 65 && cnt >= 1) begin
                            w_r_1 = Write;
                            w_r_2 = Read;
                            w_data_1 = r_data_2;
                            w_data_2 = 0;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                end
                16: begin
                    if(which_sram_rd == 0) begin
                        if(cnt < 257 && cnt >= 1) begin
                            w_r_1 = Read;
                            w_r_2 = Write;
                            w_data_1 = 0;
                            w_data_2 = r_data_1;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                    else begin
                        if(cnt < 257 && cnt >= 1) begin
                            w_r_1 = Write;
                            w_r_2 = Read;
                            w_data_1 = r_data_2;
                            w_data_2 = 0;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                end
                default:begin
                    w_r_1 = Read;
                    w_r_2 = Read;
                    w_data_1 = 0;
                    w_data_2 = 0;
                end
            endcase
        end
        s_short_cut_bright:begin // special
            case(size)
                4:  begin
                    if(which_sram_rd == 0) begin
                        if(cnt < 17 && cnt >= 1) begin
                            // mem 
                            w_r_1 = Read;
                            w_r_2 = Write;
                            w_data_1 = 0;
                            w_data_2 = (r_data_1 >>> 1) + 50;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                    else begin
                        if(cnt < 17 && cnt >= 1) begin
                            w_r_1 = Write;
                            w_r_2 = Read;
                            w_data_1 = (r_data_2 >>> 1) + 50;
                            w_data_2 = 0;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                end
                8:  begin
                    if(which_sram_rd == 0) begin
                        if(cnt < 17 && cnt >= 1) begin
                            w_r_1 = Read;
                            w_r_2 = Write;
                            w_data_1 = 0;
                            w_data_2 = (r_data_1 >>> 1) + 50;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                    else begin
                        if(cnt < 17 && cnt >= 1) begin
                            w_r_1 = Write;
                            w_r_2 = Read;
                            w_data_1 = (r_data_2 >>> 1) + 50;
                            w_data_2 = 0;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                end
                16: begin
                    if(which_sram_rd == 0) begin
                        if(cnt < 257 && cnt >= 1) begin
                            w_r_1 = Read;
                            w_r_2 = Write;
                            w_data_1 = 0;
                            w_data_2 = (r_data_1 >>> 1) + 50;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                    else begin
                        if(cnt < 257 && cnt >= 1) begin 
                            w_r_1 = Write;
                            w_r_2 = Read;
                            w_data_1 = (r_data_2 >>> 1) + 50;
                            w_data_2 = 0;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                end
                default:begin
                    w_r_1 = Read;
                    w_r_2 = Read;
                    w_data_1 = 0;
                    w_data_2 = 0;
                end
            endcase
        end
        s_zoom_in: begin    // special
            case(size)
                4:  begin
                    if(which_sram_rd == 0) begin
                        if(cnt < 17 && cnt >= 1) begin
                            // mem 
                            w_r_1 = Read;
                            w_r_2 = Write;
                            w_data_1 = 0;
                            case(cnt_zoom)
                                0:  w_data_2 = r_data_1;
                                1:  w_data_2 = r_data_1 / 3;
                                2:  w_data_2 = (r_data_1 <<< 1) / 3 + 20;
                                3:  w_data_2 = r_data_1 >>> 1;
                                default: w_data_2 = 0;
                            endcase
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                    else begin
                        // tmp_max = 0;
                        if(cnt < 17 && cnt >= 1) begin
                            // mem 
                            w_r_1 = Write;
                            w_r_2 = Read;
                            case(cnt_zoom)
                                0:  w_data_1 = r_data_2;
                                1:  w_data_1 = r_data_2 / 3;
                                2:  w_data_1 = (r_data_2 <<< 1) / 3 + 20;
                                3:  w_data_1 = r_data_2 >>> 1;
                                default: w_data_1 = 0;
                            endcase
                            w_data_2 = 0;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                            // tmp_max = 0;
                        end
                    end
                end
                8:  begin
                    // tmp_max = 0;
                     if(which_sram_rd == 0) begin
                        if(cnt < 65 && cnt >= 1) begin
                            // mem 
                            w_r_1 = Read;
                            w_r_2 = Write;
                            w_data_1 = 0;
                            case(cnt_zoom)
                                0:  w_data_2 = r_data_1;
                                1:  w_data_2 = r_data_1 / 3;
                                2:  w_data_2 = (r_data_1 <<< 1) / 3 + 20;
                                3:  w_data_2 = r_data_1 >>> 1;
                                default: w_data_2 = 0;
                            endcase
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                        end
                    end
                    else begin
                        // tmp_max = 0;
                        if(cnt < 65 && cnt >= 1) begin
                            // mem 
                            w_r_1 = Write;
                            w_r_2 = Read;
                            case(cnt_zoom)
                                0:  w_data_1 = r_data_2;
                                1:  w_data_1 = r_data_2 / 3;
                                2:  w_data_1 = (r_data_2 <<< 1) / 3 + 20;
                                3:  w_data_1 = r_data_2 >>> 1;
                                default: w_data_1 = 0;
                            endcase
                            w_data_2 = 0;
                        end
                        else begin
                            w_r_1 = Read;
                            w_r_2 = Read;
                            w_data_1 = 0;
                            w_data_2 = 0;
                            // tmp_max = 0;
                        end
                    end
                end
                default:begin
                    w_r_1 = Read;
                    w_r_2 = Read;
                    w_data_1 = 0;
                    w_data_2 = 0;
                    // tmp_max = 0;
                end
            endcase
        end
        s_max_write: begin
            if(which_sram_rd == 0) begin
                w_r_1 = Read;
                w_r_2 = Write;
                w_data_1 = 0;
                w_data_2 = max;
            end
            else begin
                w_r_1 = Write;
                w_r_2 = Read;
                w_data_1 = max;
                w_data_2 = 0;
            end
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
// tmp_max
// ===============================================================
always@(*) begin
    tmp_max = 0;
    case(next_state)
        s_max_read_2: begin
            tmp_max = (which_sram_rd == 0) ? r_data_1 : r_data_2;
        end
        s_max_read_3: begin
            if(which_sram_rd == 0) begin
                if(max > r_data_1)
                    tmp_max = max;
                else
                    tmp_max = r_data_1;  
            end
            else begin
                 if(max > r_data_2)
                    tmp_max = max;
                else
                    tmp_max = r_data_2;  
            end
        end
        s_max_read_4: begin
            if(which_sram_rd == 0) begin
                if(max > r_data_1)
                    tmp_max = max;
                else
                    tmp_max = r_data_1;  
            end
            else begin
                 if(max > r_data_2)
                    tmp_max = max;
                else
                    tmp_max = r_data_2;  
            end  
        end
        s_max_read_5: begin
            if(which_sram_rd == 0) begin
                if(max > r_data_1)
                    tmp_max = max;
                else
                    tmp_max = r_data_1;  
            end
            else begin
                 if(max > r_data_2)
                    tmp_max = max;
                else
                    tmp_max = r_data_2;  
            end  
        end
        default: begin
            tmp_max = 0;
        end
    endcase
end

// ===============================================================
// w_r_3, w_data_3
// ===============================================================
always@(*)begin
    w_r_3 = Read;
    w_data_3 = 0;

    case(next_state)
        s_conv_read_10: begin
            w_r_3 = Write;
            w_data_3 = total_conv_ans;
        end
        default: begin
            w_r_3 = Read;
            w_data_3 = 0;
        end
    endcase
end

// ===============================================================
// center_x, center_y
// ===============================================================
always@(*) begin
    case(size)
        4:  begin
            center_x = addr_3 >> 2;
            center_y = addr_3[1:0];
        end
        8:  begin
            center_x = addr_3 >> 3;
            center_y = addr_3[2:0];
        end
        16: begin
            center_x = addr_3 >> 4;
            center_y = addr_3[3:0];
        end
        default: begin
            center_x = 0;
            center_y = 0;
        end
    endcase
end

// ===============================================================
// legal_x, legal_y
// ===============================================================
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        legal_x <= 0;
        legal_y <= 0;
    end
    else begin
        case(next_state)
            s_idle: begin
                legal_x <= 0;
                legal_y <= 0;
            end
            s_conv_read_1: begin
                legal_x <= center_x - 1;
                legal_y <= center_y - 1;
            end
            s_conv_read_2: begin
                legal_x <= center_x - 1;
                legal_y <= center_y;
            end
            s_conv_read_3: begin
                legal_x <= center_x - 1;
                legal_y <= center_y + 1;
            end
            s_conv_read_4: begin
                legal_x <= center_x;
                legal_y <= center_y - 1;
            end
            s_conv_read_5: begin
                legal_x <= center_x;
                legal_y <= center_y + 1;
            end
            s_conv_read_6: begin
                legal_x <= center_x + 1;
                legal_y <= center_y - 1;
            end
            s_conv_read_7: begin
                legal_x <= center_x + 1;
                legal_y <= center_y;
            end
            s_conv_read_8: begin
                legal_x <= center_x + 1;
                legal_y <= center_y + 1;
            end
            default : begin
                legal_x <= center_x ;
                legal_y <= center_y ;
            end
        endcase
    end
    
end

// ===============================================================
// flag_bound
// ===============================================================
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        flag_bound <= 0;
    end
    else begin
        if( legal_x < 0 || legal_y < 0 || legal_x == size || legal_y == size) begin
            flag_bound <= 1;
        end
        else begin
            flag_bound <= 0;
        end
    end
    
end

// ===============================================================
// mult_a
// ===============================================================
always@(*) begin
    case(next_state)
        s_conv_reset:   mult_a = 0;
        s_conv_read_1:  mult_a = 0;
        s_conv_read_2:  mult_a = temp[4];
        s_conv_read_3:  mult_a = temp[0];
        s_conv_read_4:  mult_a = temp[1];
        s_conv_read_5:  mult_a = temp[2];
        s_conv_read_6:  mult_a = temp[3];
        s_conv_read_7:  mult_a = temp[5];
        s_conv_read_8:  mult_a = temp[6];
        s_conv_read_9:  mult_a = temp[7];
        s_conv_read_10: mult_a = temp[8];
        s_conv_write:   mult_a = 0;
        default: begin
            mult_a = 0;
        end
    endcase
end

// ===============================================================
// mult_b
// ===============================================================
always@(*) begin
    case(next_state)
        s_conv_reset, s_conv_read_1, s_conv_read_2, s_conv_read_3, s_conv_read_4, s_conv_read_5:  begin
            if(flag_bound == 0)
                mult_b = (which_sram_rd == 0) ? r_data_1 : r_data_2;
            else
                mult_b = 0;
        end
        s_conv_read_6, s_conv_read_7, s_conv_read_8, s_conv_read_9, s_conv_read_10, s_conv_write: begin
            if(flag_bound == 0)
                mult_b = (which_sram_rd == 0) ? r_data_1 : r_data_2;
            else
                mult_b = 0;
        end
        default:
            mult_b = 0;
    endcase
end

// ===============================================================
// flag_out_img_pos, garbage
// ===============================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0; i<9; i=i+1)
            flag_out_img_pos[i] <= 1;
	end
	else begin
        case(next_state)
            s_idle: begin
                for(i=0; i<9; i=i+1)
                    flag_out_img_pos[i] <= 1;
            end
            s_out_pre: begin
                if(out_x == 0) begin
                    if(out_y == 0) begin
                        flag_out_img_pos[0] <= 0;
                        flag_out_img_pos[1] <= 0;
                        flag_out_img_pos[2] <= 0;

                        flag_out_img_pos[3] <= 0;
                        flag_out_img_pos[6] <= 0;
                    end
                    else if(out_y == size - 1)  begin
                        flag_out_img_pos[0] <= 0;
                        flag_out_img_pos[1] <= 0;
                        flag_out_img_pos[2] <= 0;

                        flag_out_img_pos[5] <= 0;
                        flag_out_img_pos[8] <= 0;
                    end
                    else begin
                        flag_out_img_pos[0] <= 0;
                        flag_out_img_pos[1] <= 0;
                        flag_out_img_pos[2] <= 0;
                    end
                end
                else if(out_x == size - 1)begin
                    if(out_y == 0) begin
                        flag_out_img_pos[6] <= 0;
                        flag_out_img_pos[7] <= 0;
                        flag_out_img_pos[8] <= 0;

                        flag_out_img_pos[0] <= 0;
                        flag_out_img_pos[3] <= 0;
                    end
                    else if(out_y == size - 1)  begin
                        flag_out_img_pos[6] <= 0;
                        flag_out_img_pos[7] <= 0;
                        flag_out_img_pos[8] <= 0;

                        flag_out_img_pos[2] <= 0;
                        flag_out_img_pos[5] <= 0;
                    end
                    else begin
                        flag_out_img_pos[6] <= 0;
                        flag_out_img_pos[7] <= 0;
                        flag_out_img_pos[8] <= 0;
                    end
                end
                else if(out_y == 0) begin
                    flag_out_img_pos[0] <= 0;
                    flag_out_img_pos[3] <= 0;
                    flag_out_img_pos[6] <= 0;
                end
                else if(out_y == size - 1) begin
                    flag_out_img_pos[2] <= 0;
                    flag_out_img_pos[5] <= 0;
                    flag_out_img_pos[8] <= 0;
                end
                else begin
                    for(i=0; i<9; i=i+1)
                        flag_out_img_pos[i] <= 1;
                end
            end
            s_out: begin
                if(flag_out_img_pos[0] == 1)    flag_out_img_pos[0] <= 0;
                else if(flag_out_img_pos[1] == 1)    flag_out_img_pos[1] <= 0;
                else if(flag_out_img_pos[2] == 1)    flag_out_img_pos[2] <= 0;
                else if(flag_out_img_pos[3] == 1)    flag_out_img_pos[3] <= 0;
                else if(flag_out_img_pos[4] == 1)    flag_out_img_pos[4] <= 0;
                else if(flag_out_img_pos[5] == 1)    flag_out_img_pos[5] <= 0;
                else if(flag_out_img_pos[6] == 1)    flag_out_img_pos[6] <= 0;
                else if(flag_out_img_pos[7] == 1)    flag_out_img_pos[7] <= 0;
                else if(flag_out_img_pos[8] == 1)    flag_out_img_pos[8] <= 0;
                else begin
                    for(i=0; i<9; i=i+1)
                        flag_out_img_pos[i] <= 0;
                end
            end
            default: begin
                for(i=0; i<9; i=i+1)
                    flag_out_img_pos[i] <= 1;
            end
        endcase
	end 	
end

// ===============================================================
// out_img_pos
// ===============================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_img_pos <= 0;
	end
	else begin 
		if(next_state == s_out) begin
            if(flag_out_img_pos[0] == 1)      out_img_pos <= conv_max_position - size - 1;
            else if(flag_out_img_pos[1] == 1) out_img_pos <= conv_max_position - size;
            else if(flag_out_img_pos[2] == 1) out_img_pos <= conv_max_position - size + 1;
            else if(flag_out_img_pos[3] == 1) out_img_pos <= conv_max_position - 1;
            else if(flag_out_img_pos[4] == 1) out_img_pos <= conv_max_position;
            else if(flag_out_img_pos[5] == 1) out_img_pos <= conv_max_position + 1;
            else if(flag_out_img_pos[6] == 1) out_img_pos <= conv_max_position + size - 1;
            else if(flag_out_img_pos[7] == 1) out_img_pos <= conv_max_position + size;
            else if(flag_out_img_pos[8] == 1) out_img_pos <= conv_max_position + size + 1;
            else                              out_img_pos <= 0;
        end
        else begin
            out_img_pos <= 0;
        end
	end 	
end
// ===============================================================
// out_x, out_y
// ===============================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_x <= 0;
		out_y <= 0;
	end
	else begin
        case(next_state)
            s_out_pre, s_out, s_conv_reset: begin
                case(size)
                    4:  begin
                        out_x <= conv_max_position >> 2;
                        out_y <= conv_max_position[1:0];
                    end
                    8:  begin
                        out_x <= conv_max_position >> 3;
                        out_y <= conv_max_position[2:0];
                    end
                    16: begin
                        out_x <= conv_max_position >> 4;
                        out_y <= conv_max_position[3:0];
                    end
                    default: begin
                        out_x <= 0;
                        out_y <= 0;
                    end
                endcase
            end
            default: begin
                out_x <= 0;
                out_y <= 0;
            end
        endcase
	end 	
end

// ===============================================================
// out_valid
// ===============================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
	end
	else begin
        case(next_state)
            s_out:  out_valid <= 1;
            default: out_valid <= 0;
        endcase
	end 	
end

// ===============================================================
// out_value
// ===============================================================
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_value <= 0;
	end
	else begin
        case(next_state)
            s_out:  out_value <= r_data_3;
            default: out_value <= 0;
        endcase
	end 	
end

endmodule

module MAC (
    A, B, C,
    sol
);
input signed [15:0] A, B;
input signed [35:0] C;
output signed [35:0] sol;

assign sol = (A * B) + C;
    
endmodule