`include "AFIFO.v"

module CDC #(parameter DSIZE = 8,
			   parameter ASIZE = 4)(
	//Input Port
	rst_n,
	clk1,
    clk2,
	in_valid,
	in_account,
	in_A,
	in_T,

    //Output Port
	ready,
    out_valid,
	out_account
); 
//=====================================================================
//   INPUT AND OUTPUT DECLARATION
//=====================================================================

input 				rst_n, clk1, clk2, in_valid;
input [DSIZE-1:0] 	in_account,in_A,in_T;

output reg				out_valid,ready;
output reg [DSIZE-1:0] 	out_account;

//=====================================================================
//   WIRE AND REG DECLARATION
//=====================================================================

reg [7:0] account [0:4];
reg [15:0] performance [0:4];

// mem
wire [7:0] w_data;
wire w_full;
wire r_empty;
wire [7:0] r_data;
reg w_addr;
reg r_addr;

// cnt_in
reg [11:0] cnt_in;

// flag
//=====================================================================
//   PARAMETER
//=====================================================================
parameter patnum = 4000;
//=====================================================================
//   IP
//=====================================================================
reg [7:0] mult1, mult2;
wire [15:0] perf;
wire [7:0] tmp_acc;

get_performance g1(.m1(mult1), .m2(mult2), .sol(perf));
get_best_perf g2(
    .a0(account[0]), .a1(account[1]), .a2(account[2]), .a3(account[3]),.a4(account[4]),
    .p0(performance[0]), .p1(performance[1]), .p2(performance[2]), .p3(performance[3]),.p4(performance[4]),
    .acc(w_data)
);
//=====================================================================
//   DESIGN
//=====================================================================
//=====================================================================
// read input, write in FIFO / clk1 
//=====================================================================
always @(posedge clk1 or negedge rst_n) begin //clk1 10
	if(!rst_n) begin
        account[0] <= 0;
        account[1] <= 0;
        account[2] <= 0;
        account[3] <= 0;
        account[4] <= 0;
        performance[0] <= 0;
        performance[1] <= 0;
        performance[2] <= 0;
        performance[3] <= 0;
        performance[4] <= 0;
        cnt_in <= 0;
	end 
    else begin
        if(cnt_in == patnum) begin
            cnt_in <= cnt_in + 1;
        end
        else begin
            if(in_valid) begin
                cnt_in <= cnt_in + 1;
                account[0] <= in_account;
                performance[0] <= perf;
            
                account[4] <= account[3];
                account[3] <= account[2];
                account[2] <= account[1];
                account[1] <= account[0];

                performance[4] <= performance[3];
                performance[3] <= performance[2];
                performance[2] <= performance[1];
                performance[1] <= performance[0];
            end
        end
	end
end
// mult1, mult2
always@(*) begin
    w_addr = 0;
    if(cnt_in == patnum) begin
        if(w_full)
            w_addr = 0;
        else 
            w_addr = 1;
    end
    else if(cnt_in == patnum + 1)
        w_addr = 0;
    else begin
        if(in_valid) begin
            if(cnt_in > 4) begin
                if(w_full)
                    w_addr = 0;
                else 
                    w_addr = 1;
            end
            else
                w_addr = 0;
        end
        else
            w_addr = 0;
    end
end

// mult1, mult2
always@(*) begin
    mult1 = 0;
    mult2 = 0;
    if(in_valid) begin
        mult1 = in_A;
        mult2 = in_T;
    end
end
//=====================================================================
// ready / flag
//=====================================================================
always@(*) begin
    ready = 0;
    if(!rst_n) begin
        ready = 0;
    end
    else begin
        ready = ~w_full;
    end
end
//=====================================================================
// out / clk2
//=====================================================================

always @(*) begin
	if(!rst_n) begin
        r_addr = 0;
	end 
    else begin
        if(!r_empty) begin
            r_addr = 1;
        end
        else
            r_addr = 0;
	end
end

//=====================================================================
always @(posedge clk2 or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
	    out_account <= 0;
	end 
    else begin
        if(in_valid) begin
            if(r_addr) begin
                out_valid <= 1;
                out_account <= r_data;
            end
            else begin
                out_valid <= 0;
                out_account <= 0;
            end
        end
        else begin
            if(!r_empty) begin
                out_valid <= 1;
                out_account <= r_data;
            end
            else begin
                out_valid <= 0;
                out_account <= 0;
            end       
        end   
	end
end
//=====================================================================
// read / clk1 
//=====================================================================

AFIFO u_AFIFO(
    .rst_n(rst_n),
    // read
    .rclk(clk2),
    .rinc(r_addr),
    // write
	.wclk(clk1),
    .winc(w_addr),
    .wdata(w_data),
    // out
    .wfull(w_full),
    .rempty(r_empty),
    .rdata(r_data)
    );


endmodule
//=====================================================================
// get_performance
//=====================================================================
module get_performance(
    // in
    m1, m2,
    // out
    sol
);
input [7:0] m1, m2;
output [15:0] sol;
assign sol = m1 * m2;

endmodule
//=====================================================================
// get_best_perf
//=====================================================================
module get_best_perf(
    // in
    p0, p1, p2, p3, p4,
    a0, a1, a2, a3, a4,

    // out
    acc
);
input [7:0] a0, a1, a2, a3, a4;
input [15:0] p0, p1, p2, p3, p4;
output [7:0] acc;
//================================================================
//    Wire & Registers 
//================================================================
wire [15:0]layer1_p[0:3];
wire [15:0]layer2_p[0:3];

wire [7:0]layer1_a[0:3];
wire [7:0]layer2_a[0:3];
//================================================================
//    DESIGN
//================================================================
// perf
assign layer1_p[0] = (p0 <= p1) ? p0 : p1;
assign layer1_p[1] = p2;
assign layer1_p[2] = (p3 <= p4) ? p3 : p4;
assign layer2_p[0] = (layer1_p[0] <= layer1_p[1]) ? layer1_p[0] : layer1_p[1];
assign layer2_p[1] = layer1_p[2];
// assign a =  (layer2_p[0] < layer2_p[1])

// acc
assign layer1_a[0] = (p0 <= p1) ? a0 : a1;
assign layer1_a[1] = a2;
assign layer1_a[2] = (p3 <= p4) ? a3 : a4;
assign layer2_a[0] = (layer1_p[0] <= layer1_p[1]) ? layer1_a[0] : layer1_a[1];
assign layer2_a[1] = layer1_a[2];
assign acc = (layer2_p[0] <= layer2_p[1]) ? layer2_a[0] : layer2_a[1];

endmodule