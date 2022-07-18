//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : RSA_TOP.v
//   Module Name : RSA_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
// synopsys translate_off
`include "RSA_IP.v"
// synopsys translate_on
module RSA_TOP (
    // Input signals
    clk, rst_n, in_valid,
    in_p, in_q, in_e, in_c,
    // Output signals
    out_valid, out_m
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [3:0] in_p, in_q;
input [7:0] in_e, in_c;
output reg out_valid;
output reg [7:0] out_m;

// ===============================================================
// Parameter & Integer Declaration
// ===============================================================

parameter s_idle         = 'd0;
parameter s_input_1      = 'd1;
parameter s_input_2      = 'd2;
parameter s_calculate_ND = 'd3;
parameter s_decode_1     = 'd4;
parameter s_out          = 'd5;

//================================================================
// Wire & Reg Declaration
//================================================================
reg [5:0] current_state, next_state;
reg [3:0] p_data, q_data;
reg [7:0] e_data;
reg [7:0] c_data [0:7];
reg [7:0] n_data, d_data;
reg [7:0] cnt;

reg [7:0] m_data [0:7];

reg  [7:0] in_A_1;
reg  [7:0] in_A_2;
reg  [7:0] in_A_3;
reg  [7:0] in_A_4;
reg  [7:0] in_A_5;
reg  [7:0] in_A_6;
reg  [7:0] in_A_7;
reg  [7:0] in_A_8;

reg  [7:0] in_B_1;
reg  [7:0] in_B_2;
reg  [7:0] in_B_3;
reg  [7:0] in_B_4;
reg  [7:0] in_B_5;
reg  [7:0] in_B_6;
reg  [7:0] in_B_7;
reg  [7:0] in_B_8;

wire [7:0] tmp_m_1;
wire [7:0] tmp_m_2;
wire [7:0] tmp_m_3;
wire [7:0] tmp_m_4;
wire [7:0] tmp_m_5;
wire [7:0] tmp_m_6;
wire [7:0] tmp_m_7;
wire [7:0] tmp_m_8;

reg flag_finish;

wire [7:0] n_data_1, d_data_1;

integer i;

// ===============================================================
// IP
// ===============================================================
RSA_IP #(4) R01(.IN_P(p_data), .IN_Q(q_data), .IN_E(e_data), .OUT_N(n_data_1), .OUT_D(d_data_1));
decoder d1(.A(in_A_1), .B(in_B_1), .C(n_data), .sol(tmp_m_1));
decoder d2(.A(in_A_2), .B(in_B_2), .C(n_data), .sol(tmp_m_2));
decoder d3(.A(in_A_3), .B(in_B_3), .C(n_data), .sol(tmp_m_3));
decoder d4(.A(in_A_4), .B(in_B_4), .C(n_data), .sol(tmp_m_4));
decoder d5(.A(in_A_5), .B(in_B_5), .C(n_data), .sol(tmp_m_5));
decoder d6(.A(in_A_6), .B(in_B_6), .C(n_data), .sol(tmp_m_6));
decoder d7(.A(in_A_7), .B(in_B_7), .C(n_data), .sol(tmp_m_7));
decoder d8(.A(in_A_8), .B(in_B_8), .C(n_data), .sol(tmp_m_8));
//================================================================
// DESIGN
//================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) current_state <= s_idle;
    else        current_state <= next_state;
end

// FSM
always@(*)begin
	case(current_state)
		s_idle: begin
            if(in_valid == 1)
                next_state = s_input_1;
            else
                next_state = current_state;
        end
        s_input_1: begin
                next_state = s_input_2;
        end
        s_input_2: begin
            if(in_valid == 0)
                next_state = s_decode_1;
            else
                next_state = current_state;
        end
        s_decode_1: begin
            if(flag_finish)
                next_state = s_out;
            else
                next_state = current_state;
        end
        s_out: begin
            if(cnt == 8)
                next_state = s_idle;
            else
                next_state = current_state;
        end
        default: 
            next_state = current_state;
    endcase
end
//================================================================
// input
//================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        // cnt
        cnt <= 0;
        flag_finish <= 0;

        // n, d
        n_data <= 0;
        d_data <= 0;

        // p, q, e, c
        p_data <= 0;
        q_data <= 0;
        e_data <= 0;
        for(i=0; i<8; i=i+1)
            c_data[i] <= 0;

        // A, B, m
        in_A_1<= 0;
        in_A_2<= 0;
        in_A_3<= 0;
        in_A_4<= 0;
        in_A_5<= 0;
        in_A_6<= 0;
        in_A_7<= 0;
        in_A_8<= 0;

        in_B_1<= 0;
        in_B_2<= 0;
        in_B_3<= 0;
        in_B_4<= 0;
        in_B_5<= 0;
        in_B_6<= 0;
        in_B_7<= 0;
        in_B_8<= 0;

        for(i=0; i<8; i=i+1)
            m_data[i] <= 0;
    end
    else begin
        case(next_state)
            s_idle: begin
                // cnt
                cnt <= 0;
                flag_finish <= 0;

                // n, d
                n_data <= 0;
                d_data <= 0;
                
                // p, q, e, c
                p_data <= 0;
                q_data <= 0;
                e_data <= 0;
                for(i=0; i<8; i=i+1)
                    c_data[i] <= 0;

                 // A, B, m
                in_A_1<= 0;
                in_A_2<= 0;
                in_A_3<= 0;
                in_A_4<= 0;
                in_A_5<= 0;
                in_A_6<= 0;
                in_A_7<= 0;
                in_A_8<= 0;

                in_B_1<= 0;
                in_B_2<= 0;
                in_B_3<= 0;
                in_B_4<= 0;
                in_B_5<= 0;
                in_B_6<= 0;
                in_B_7<= 0;
                in_B_8<= 0;
                for(i=0; i<8; i=i+1)
                    m_data[i] <= 0;
            end
            s_input_1:  begin
                p_data <= in_p;
                q_data <= in_q;
                e_data <= in_e;

                c_data[7] <= in_c;
            end
            s_input_2:  begin
                n_data <= n_data_1;
                d_data <= d_data_1;
                c_data[7] <= in_c;
                for(i=0; i<7; i=i+1)
                    c_data[i] <= c_data[i+1];
            end
            
            s_decode_1: begin
                if(cnt < d_data) begin
                    in_B_1 <= c_data[0];
                    in_B_2 <= c_data[1];
                    in_B_3 <= c_data[2];
                    in_B_4 <= c_data[3];
                    in_B_5 <= c_data[4];
                    in_B_6 <= c_data[5];
                    in_B_7 <= c_data[6];
                    in_B_8 <= c_data[7];

                    cnt <= cnt + 1;
                    if(cnt == 0) begin
                        in_A_1 <= 1;
                        in_A_2 <= 1;
                        in_A_3 <= 1;
                        in_A_4 <= 1;
                        in_A_5 <= 1;
                        in_A_6 <= 1;
                        in_A_7 <= 1;
                        in_A_8 <= 1;
                    end
                    else begin
                        in_A_1 <= tmp_m_1;
                        in_A_2 <= tmp_m_2;
                        in_A_3 <= tmp_m_3;
                        in_A_4 <= tmp_m_4;
                        in_A_5 <= tmp_m_5;
                        in_A_6 <= tmp_m_6;
                        in_A_7 <= tmp_m_7;
                        in_A_8 <= tmp_m_8;
                    end
                end
                else begin
                    flag_finish <= 1;
                    cnt <= 0;
                    m_data[0] <= tmp_m_1;
                    m_data[1] <= tmp_m_2;
                    m_data[2] <= tmp_m_3;
                    m_data[3] <= tmp_m_4;
                    m_data[4] <= tmp_m_5;
                    m_data[5] <= tmp_m_6;
                    m_data[6] <= tmp_m_7;
                    m_data[7] <= tmp_m_8;
                end     
            end
            
            s_out: begin
                flag_finish <= 0;
                cnt <= cnt + 1;
                m_data[0] <= m_data[1];
                m_data[1] <= m_data[2];
                m_data[2] <= m_data[3];
                m_data[3] <= m_data[4];
                m_data[4] <= m_data[5];
                m_data[5] <= m_data[6];
                m_data[6] <= m_data[7];
            end
            default: begin
            end
        endcase
    end
end

//================================================================
// out
//================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_m <= 0;
        out_valid <= 0;
    end
    else begin
        case(next_state)
            s_out: begin
                out_valid <= 1;
                out_m <= m_data[0];
            end
            default: begin
                out_m <= 0;
                out_valid <= 0;
            end
        endcase
    end
end

endmodule

module decoder (
    // in
    A, B, C,
    // out
    sol
);
input [7:0] A, B, C;
output[7:0] sol;
wire [15:0] tmp;
assign tmp = (A * B);
assign sol = tmp % C;
    
endmodule