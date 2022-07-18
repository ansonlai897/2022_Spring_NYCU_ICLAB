module TOF(
    // CHIP IO
    // in
    clk,
    rst_n,
    in_valid,
    start,
    stop,
    window,
    mode,
    frame_id,
    // out
    busy,

    // AXI4 IO
    arid_m_inf,
    araddr_m_inf,
    arlen_m_inf,
    arsize_m_inf,
    arburst_m_inf,
    arvalid_m_inf,
    arready_m_inf,
    
    rid_m_inf,
    rdata_m_inf,
    rresp_m_inf,
    rlast_m_inf,
    rvalid_m_inf,
    rready_m_inf,

    awid_m_inf,
    awaddr_m_inf,
    awsize_m_inf,
    awburst_m_inf,
    awlen_m_inf,
    awvalid_m_inf,
    awready_m_inf,

    wdata_m_inf,
    wlast_m_inf,
    wvalid_m_inf,
    wready_m_inf,
    
    bid_m_inf,
    bresp_m_inf,
    bvalid_m_inf,
    bready_m_inf 
);
// ===============================================================
//                      Parameter Declaration 
// ===============================================================
parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32;    // DO NOT modify AXI4 Parameter


// ===============================================================
//                      Input / Output 
// ===============================================================

// << CHIP io port with system >>
input           clk, rst_n;
input           in_valid;
input           start;
input [15:0]    stop;     
input [1:0]     window; 
input           mode;
input [4:0]     frame_id;

output reg      busy;       

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
    Your AXI-4 interface could be designed as a bridge in submodule,
    therefore I declared output of AXI as wire.  
    Ex: AXI4_interface AXI4_INF(...);
*/

//=====================================================================
// <<<<< AXI READ >>>>>
//=====================================================================
// (1)    axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output wire [7:0]              arlen_m_inf;
output wire                  arvalid_m_inf;
input  wire                  arready_m_inf;
output wire [ADDR_WIDTH-1:0]  araddr_m_inf;
//=====================================================================
// (2)    axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;
input  wire                   rvalid_m_inf;
output wire                   rready_m_inf;
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
input  wire                    rlast_m_inf;
input  wire [1:0]              rresp_m_inf;
//=====================================================================
// <<<<< AXI WRITE >>>>>
//=====================================================================
// (1)     axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [7:0]              awlen_m_inf;
output wire                  awvalid_m_inf;
input  wire                  awready_m_inf;
output wire [ADDR_WIDTH-1:0]  awaddr_m_inf;
//=====================================================================
// (2)    axi write data channel 
output wire                   wvalid_m_inf;
input  wire                   wready_m_inf;
output wire [DATA_WIDTH-1:0]   wdata_m_inf;
output wire                    wlast_m_inf;
//=====================================================================
// (3)    axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output wire                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
//==========================================================================================================================================
//=====================================================================
//   WIRE AND REG DECLARATION
//=====================================================================
// state
reg [5:0] current_state, next_state;

// window
reg [3:0] window_reg;

// frame_id_reg
reg [4:0] frame_id_reg;

// mode_reg
reg mode_reg;

// stop
reg [15:0] tmp_stop;
reg [7:0] tmp_sram [0:15];

// cnt
reg [8:0] cnt_start;
reg [7:0] cnt_start_1;
reg [8:0] cnt_window;
reg [4:0] cnt_sram;

// dram wr
reg [127:0] dram_w_data;
reg [127:0] dram_w_data_ns;

// dram rd
reg [127:0] dram_r_data;

// bus
reg [7:0] bus [0:15][0:7];
reg [7:0] best_loc [0:15];

// sum
reg [10:0] sum [0:15];
wire [10:0] sum_ns [0:15];

// flag
reg flag_win_id;
reg flag_finish_window_1;

// shift
reg shift_start_1, shift_start_2;

reg wlast_reg;

//=====================================================================
//   integer
//=====================================================================
integer i, j;
//=====================================================================
//   Read, Write
//=====================================================================
parameter Write = 'd0;
parameter Read  = 'd1;
//=====================================================================
//   mem1
//=====================================================================
// which_sram_write
reg which_sram;

reg  [7:0] mem1_addr;
wire [7:0] mem1_r_data [0:15];
reg  [7:0] mem1_w_data [0:15];
reg  w_r_1 [0:15];


sram    mem1_1     (.A(mem1_addr),  .D(mem1_w_data[0]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_1[0 ]),    .OEN(1'd0),    .Q(mem1_r_data[0 ]));
sram    mem1_2     (.A(mem1_addr),  .D(mem1_w_data[1]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_1[1 ]),    .OEN(1'd0),    .Q(mem1_r_data[1 ]));
sram    mem1_3     (.A(mem1_addr),  .D(mem1_w_data[2]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_1[2 ]),    .OEN(1'd0),    .Q(mem1_r_data[2 ]));
sram    mem1_4     (.A(mem1_addr),  .D(mem1_w_data[3]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_1[3 ]),    .OEN(1'd0),    .Q(mem1_r_data[3 ]));
sram    mem1_5     (.A(mem1_addr),  .D(mem1_w_data[4]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_1[4 ]),    .OEN(1'd0),    .Q(mem1_r_data[4 ]));
sram    mem1_6     (.A(mem1_addr),  .D(mem1_w_data[5]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_1[5 ]),    .OEN(1'd0),    .Q(mem1_r_data[5 ]));
sram    mem1_7     (.A(mem1_addr),  .D(mem1_w_data[6]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_1[6 ]),    .OEN(1'd0),    .Q(mem1_r_data[6 ]));
sram    mem1_8     (.A(mem1_addr),  .D(mem1_w_data[7]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_1[7 ]),    .OEN(1'd0),    .Q(mem1_r_data[7 ]));
sram    mem1_9     (.A(mem1_addr),  .D(mem1_w_data[8]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_1[8 ]),    .OEN(1'd0),    .Q(mem1_r_data[8 ]));
sram    mem1_10    (.A(mem1_addr),  .D(mem1_w_data[9]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_1[9 ]),    .OEN(1'd0),    .Q(mem1_r_data[9 ]));
sram    mem1_11    (.A(mem1_addr), .D(mem1_w_data[10]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_1[10]),    .OEN(1'd0),    .Q(mem1_r_data[10]));
sram    mem1_12    (.A(mem1_addr), .D(mem1_w_data[11]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_1[11]),    .OEN(1'd0),    .Q(mem1_r_data[11]));
sram    mem1_13    (.A(mem1_addr), .D(mem1_w_data[12]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_1[12]),    .OEN(1'd0),    .Q(mem1_r_data[12]));
sram    mem1_14    (.A(mem1_addr), .D(mem1_w_data[13]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_1[13]),    .OEN(1'd0),    .Q(mem1_r_data[13]));
sram    mem1_15    (.A(mem1_addr), .D(mem1_w_data[14]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_1[14]),    .OEN(1'd0),    .Q(mem1_r_data[14]));
sram    mem1_16    (.A(mem1_addr), .D(mem1_w_data[15]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_1[15]),    .OEN(1'd0),    .Q(mem1_r_data[15]));

//=====================================================================
//   mem2
//=====================================================================
reg  [7:0] mem2_addr;
wire [7:0] mem2_r_data [0:15];
reg  [7:0] mem2_w_data [0:15];
reg  w_r_2 [0:15];


sram    mem2_1     (.A(mem2_addr), .D(mem2_w_data[0]),    .CLK(clk),.CEN(1'd0),   .WEN(w_r_2[0 ]),    .OEN(1'd0),    .Q(mem2_r_data[0 ]));
sram    mem2_2     (.A(mem2_addr), .D(mem2_w_data[1]),    .CLK(clk),.CEN(1'd0),   .WEN(w_r_2[1 ]),    .OEN(1'd0),    .Q(mem2_r_data[1 ]));
sram    mem2_3     (.A(mem2_addr), .D(mem2_w_data[2]),    .CLK(clk),.CEN(1'd0),   .WEN(w_r_2[2 ]),    .OEN(1'd0),    .Q(mem2_r_data[2 ]));
sram    mem2_4     (.A(mem2_addr), .D(mem2_w_data[3]),    .CLK(clk),.CEN(1'd0),   .WEN(w_r_2[3 ]),    .OEN(1'd0),    .Q(mem2_r_data[3 ]));
sram    mem2_5     (.A(mem2_addr), .D(mem2_w_data[4]),    .CLK(clk),.CEN(1'd0),   .WEN(w_r_2[4 ]),    .OEN(1'd0),    .Q(mem2_r_data[4 ]));
sram    mem2_6     (.A(mem2_addr), .D(mem2_w_data[5]),    .CLK(clk),.CEN(1'd0),   .WEN(w_r_2[5 ]),    .OEN(1'd0),    .Q(mem2_r_data[5 ]));
sram    mem2_7     (.A(mem2_addr), .D(mem2_w_data[6]),    .CLK(clk),.CEN(1'd0),   .WEN(w_r_2[6 ]),    .OEN(1'd0),    .Q(mem2_r_data[6 ]));
sram    mem2_8     (.A(mem2_addr), .D(mem2_w_data[7]),    .CLK(clk),.CEN(1'd0),   .WEN(w_r_2[7 ]),    .OEN(1'd0),    .Q(mem2_r_data[7 ]));
sram    mem2_9     (.A(mem2_addr), .D(mem2_w_data[8]),    .CLK(clk),.CEN(1'd0),   .WEN(w_r_2[8 ]),    .OEN(1'd0),    .Q(mem2_r_data[8 ]));
sram    mem2_10    (.A(mem2_addr), .D(mem2_w_data[9]),    .CLK(clk),.CEN(1'd0),   .WEN(w_r_2[9 ]),    .OEN(1'd0),    .Q(mem2_r_data[9 ]));
sram    mem2_11    (.A(mem2_addr), .D(mem2_w_data[10]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_2[10]),    .OEN(1'd0),    .Q(mem2_r_data[10]));
sram    mem2_12    (.A(mem2_addr), .D(mem2_w_data[11]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_2[11]),    .OEN(1'd0),    .Q(mem2_r_data[11]));
sram    mem2_13    (.A(mem2_addr), .D(mem2_w_data[12]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_2[12]),    .OEN(1'd0),    .Q(mem2_r_data[12]));
sram    mem2_14    (.A(mem2_addr), .D(mem2_w_data[13]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_2[13]),    .OEN(1'd0),    .Q(mem2_r_data[13]));
sram    mem2_15    (.A(mem2_addr), .D(mem2_w_data[14]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_2[14]),    .OEN(1'd0),    .Q(mem2_r_data[14]));
sram    mem2_16    (.A(mem2_addr), .D(mem2_w_data[15]),   .CLK(clk),.CEN(1'd0),   .WEN(w_r_2[15]),    .OEN(1'd0),    .Q(mem2_r_data[15]));

//=====================================================================
//   bus_sum
//=====================================================================

bus_sum bs1  (.b0(bus[0 ][0]), .b1(bus[0 ][1]), .b2(bus[0 ][2]), .b3(bus[0 ][3]), .b4(bus[0 ][4]), .b5(bus[0 ][5]), .b6(bus[0 ][6]), .b7(bus[0 ][7]), .sol(sum_ns[0 ]));
bus_sum bs2  (.b0(bus[1 ][0]), .b1(bus[1 ][1]), .b2(bus[1 ][2]), .b3(bus[1 ][3]), .b4(bus[1 ][4]), .b5(bus[1 ][5]), .b6(bus[1 ][6]), .b7(bus[1 ][7]), .sol(sum_ns[1 ]));
bus_sum bs3  (.b0(bus[2 ][0]), .b1(bus[2 ][1]), .b2(bus[2 ][2]), .b3(bus[2 ][3]), .b4(bus[2 ][4]), .b5(bus[2 ][5]), .b6(bus[2 ][6]), .b7(bus[2 ][7]), .sol(sum_ns[2 ]));
bus_sum bs4  (.b0(bus[3 ][0]), .b1(bus[3 ][1]), .b2(bus[3 ][2]), .b3(bus[3 ][3]), .b4(bus[3 ][4]), .b5(bus[3 ][5]), .b6(bus[3 ][6]), .b7(bus[3 ][7]), .sol(sum_ns[3 ]));
bus_sum bs5  (.b0(bus[4 ][0]), .b1(bus[4 ][1]), .b2(bus[4 ][2]), .b3(bus[4 ][3]), .b4(bus[4 ][4]), .b5(bus[4 ][5]), .b6(bus[4 ][6]), .b7(bus[4 ][7]), .sol(sum_ns[4 ]));
bus_sum bs6  (.b0(bus[5 ][0]), .b1(bus[5 ][1]), .b2(bus[5 ][2]), .b3(bus[5 ][3]), .b4(bus[5 ][4]), .b5(bus[5 ][5]), .b6(bus[5 ][6]), .b7(bus[5 ][7]), .sol(sum_ns[5 ]));
bus_sum bs7  (.b0(bus[6 ][0]), .b1(bus[6 ][1]), .b2(bus[6 ][2]), .b3(bus[6 ][3]), .b4(bus[6 ][4]), .b5(bus[6 ][5]), .b6(bus[6 ][6]), .b7(bus[6 ][7]), .sol(sum_ns[6 ]));
bus_sum bs8  (.b0(bus[7 ][0]), .b1(bus[7 ][1]), .b2(bus[7 ][2]), .b3(bus[7 ][3]), .b4(bus[7 ][4]), .b5(bus[7 ][5]), .b6(bus[7 ][6]), .b7(bus[7 ][7]), .sol(sum_ns[7 ]));
bus_sum bs9  (.b0(bus[8 ][0]), .b1(bus[8 ][1]), .b2(bus[8 ][2]), .b3(bus[8 ][3]), .b4(bus[8 ][4]), .b5(bus[8 ][5]), .b6(bus[8 ][6]), .b7(bus[8 ][7]), .sol(sum_ns[8 ]));
bus_sum bs10 (.b0(bus[9 ][0]), .b1(bus[9 ][1]), .b2(bus[9 ][2]), .b3(bus[9 ][3]), .b4(bus[9 ][4]), .b5(bus[9 ][5]), .b6(bus[9 ][6]), .b7(bus[9 ][7]), .sol(sum_ns[9 ]));
bus_sum bs11 (.b0(bus[10][0]), .b1(bus[10][1]), .b2(bus[10][2]), .b3(bus[10][3]), .b4(bus[10][4]), .b5(bus[10][5]), .b6(bus[10][6]), .b7(bus[10][7]), .sol(sum_ns[10]));
bus_sum bs12 (.b0(bus[11][0]), .b1(bus[11][1]), .b2(bus[11][2]), .b3(bus[11][3]), .b4(bus[11][4]), .b5(bus[11][5]), .b6(bus[11][6]), .b7(bus[11][7]), .sol(sum_ns[11]));
bus_sum bs13 (.b0(bus[12][0]), .b1(bus[12][1]), .b2(bus[12][2]), .b3(bus[12][3]), .b4(bus[12][4]), .b5(bus[12][5]), .b6(bus[12][6]), .b7(bus[12][7]), .sol(sum_ns[12]));
bus_sum bs14 (.b0(bus[13][0]), .b1(bus[13][1]), .b2(bus[13][2]), .b3(bus[13][3]), .b4(bus[13][4]), .b5(bus[13][5]), .b6(bus[13][6]), .b7(bus[13][7]), .sol(sum_ns[13]));
bus_sum bs15 (.b0(bus[14][0]), .b1(bus[14][1]), .b2(bus[14][2]), .b3(bus[14][3]), .b4(bus[14][4]), .b5(bus[14][5]), .b6(bus[14][6]), .b7(bus[14][7]), .sol(sum_ns[14]));
bus_sum bs16 (.b0(bus[15][0]), .b1(bus[15][1]), .b2(bus[15][2]), .b3(bus[15][3]), .b4(bus[15][4]), .b5(bus[15][5]), .b6(bus[15][6]), .b7(bus[15][7]), .sol(sum_ns[15]));


//=====================================================================
//   PARAMETER
//=====================================================================
parameter s_idle            = 'd0;

parameter s_mode_0          = 'd1;  // set histogram
parameter s_mode_0_1        = 'd2;  // set histogram
parameter s_mode_0_2        = 'd3;  // set histogram

parameter s_window_1        = 'd4;  // rd sram, get best_loc
parameter s_window_2        = 'd5;  // wr best_loc to sram
parameter s_window_3        = 'd6;  // reset window

parameter s_dram_wr_0       = 'd7;  // mode0( write address )
parameter s_dram_wr_1       = 'd8;  // mode0( set dram_w_data )
parameter s_dram_wr_2       = 'd9;  // mode0( write data    )
parameter s_dram_wr_3       = 'd10; // end write
parameter s_dram_wr_4       = 'd18;

parameter s_mode_1          = 'd11;
parameter s_dram_rd_0       = 'd12; // mode1( read address )
parameter s_dram_rd_1       = 'd13; // mode1( store read data )  
parameter s_dram_rd_2       = 'd14; // rready
parameter s_dram_rd_3       = 'd15;
parameter s_dram_rd_4       = 'd16;
parameter s_dram_rd_5       = 'd17; // end of read dram


//=====================================================================
//   AXI4 Write
//=====================================================================
assign awid_m_inf    = 0;
assign awburst_m_inf = 1;
assign awsize_m_inf  = 3'b100;
assign awlen_m_inf   = (mode_reg == 0) ? 255 : 0;

// write address channel
assign awaddr_m_inf  = (mode_reg == 0) ? (65536 + 4096 * frame_id_reg) : (65536 + 4096 * frame_id_reg + 256 * cnt_sram + 240);
assign awvalid_m_inf = (mode_reg == 0) ? ((current_state == s_dram_wr_0 || current_state == s_dram_wr_4) ? 1:0) : (((cnt_sram != 16) && (current_state == s_dram_wr_0 || current_state == s_dram_wr_4))? 1:0);

// write data channel
assign wdata_m_inf  = dram_w_data;
assign wlast_m_inf  = wlast_reg;
assign wvalid_m_inf = (current_state == s_dram_wr_2) ? 1:0;

// write response channel
assign bready_m_inf = 1;
//=====================================================================
//   AXI4 Read
//=====================================================================
assign arid_m_inf    = 0;
assign arburst_m_inf = 1;
assign arsize_m_inf  = 3'b100;
assign arlen_m_inf   = 255;

// read address channel
assign araddr_m_inf = 65536 + 4096 * frame_id_reg;
assign arvalid_m_inf = (current_state == s_dram_rd_0 || next_state == s_dram_rd_0) ? 1:0;

// read data channel
assign rready_m_inf = (current_state == s_dram_rd_2) ? 1:0;
//=====================================================================
//   wlast_reg
//=====================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wlast_reg <= 0;
    end
    else begin        
        if(mode_reg) begin
            if(next_state == s_dram_wr_1 || next_state == s_dram_wr_2)
                wlast_reg <= 1;
            else
                wlast_reg <= 0;
        end
        else begin
            if(next_state == s_dram_wr_2) begin
                if(cnt_sram == 16)
                    wlast_reg <= 1;
                else
                    wlast_reg <= 0;
            end
        end
    end
end
//=====================================================================
//   FSM
//=====================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) current_state <= s_idle;
    else        current_state <= next_state;
end

always@(*)begin
	case(current_state)
		s_idle: begin // 0
            if(in_valid == 1) begin
                if(mode) 
                    next_state = s_mode_1;
                else
                    next_state = s_mode_0;
            end
            else
                next_state = current_state;
        end
        s_mode_1: begin
            next_state = s_dram_rd_0;
        end
        //=====================================================================
        s_mode_0: begin //1
            if(in_valid)
                next_state = current_state;
            else
                next_state = s_mode_0_1;
        end
        s_mode_0_1: begin
            if(cnt_start == 257)
                next_state = s_mode_0_2;
            else
                next_state = current_state;
        end
        s_mode_0_2: begin
            next_state = s_window_1;
        end
        //===================================================================== 4 
        s_window_1: begin
            if(flag_finish_window_1)
                next_state = s_window_2;
            else
                next_state = current_state;
        end
        s_window_2: begin
            next_state = s_window_3;
        end
        s_window_3: begin
            next_state = s_dram_wr_0;  
        end
        //===================================================================== 7
        s_dram_wr_0: begin // w_address
            if(awready_m_inf)
                next_state = s_dram_wr_1;
            else
                next_state = current_state;
        end
        s_dram_wr_1: begin // w_data
            if(cnt_window != 17)
                next_state = current_state;
            else
                next_state = s_dram_wr_2;
        end
        s_dram_wr_2: begin // w_data_in
            if(mode_reg == 0) begin
                if(cnt_sram == 16)
                    next_state = s_dram_wr_3;
                else begin
                    if(wready_m_inf)
                        next_state = s_dram_wr_1;
                    else
                        next_state = current_state;
                end
            end
            else begin
                if(wready_m_inf)
                    next_state = s_dram_wr_3;
                else
                    next_state = current_state;
            end
        end
        s_dram_wr_3: begin
            if(bvalid_m_inf) begin
                next_state = s_dram_wr_4;
            end
            else
                next_state = current_state;
        end
        s_dram_wr_4: begin
            if(mode_reg == 0)
                next_state = s_idle;
            else begin
                if(cnt_sram != 16)
                    next_state = s_dram_wr_0;
                else
                    next_state = s_idle;
            end
        end
        //===================================================================== 12
        s_dram_rd_0: begin
            if(arready_m_inf)
                next_state = s_dram_rd_1;
            else
                next_state = current_state;
        end
        s_dram_rd_1: begin
            next_state = s_dram_rd_2;
        end
        s_dram_rd_2: begin
            if(rvalid_m_inf)
                next_state = s_dram_rd_3;
            else
                next_state = current_state;
        end
        s_dram_rd_3: begin
            next_state = s_dram_rd_4;
        end
        s_dram_rd_4: begin
            if(cnt_sram != 16) begin
                if(cnt_window != 16)
                    next_state = current_state;
                else
                    next_state = s_dram_rd_2;
            end
            else begin
                next_state = s_dram_rd_5;
            end
        end
        s_dram_rd_5: begin
            next_state = s_window_1;
        end
        default: 
            next_state = current_state;
    endcase
end
//=====================================================================
// which_sram
//=====================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		which_sram <= 0;
    end 
    else begin
        case(next_state)
            s_idle: which_sram <= 0;
            s_mode_0: begin
                which_sram <= cnt_start_1[0];
            end
            s_mode_1: begin
                which_sram <= 0;
            end
        endcase
    end
end
//=====================================================================
// mode 0, cnt_start
//=====================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		cnt_start <= 0;
        cnt_start_1 <= 0;
	end 
    else begin
        case(next_state)
            s_mode_0, s_mode_0_1: begin
                if(start)
                    cnt_start <= cnt_start + 1;
                else begin
                    if(cnt_start == 255 || cnt_start == 256)
                        cnt_start <= cnt_start + 1;
                    else
                        cnt_start <= 0;
                end
                if(cnt_start == 256)
                    cnt_start_1 <= cnt_start_1 + 1; 
            end
            default: begin
                cnt_start <= 0;
                cnt_start_1 <= 0;
            end
        endcase
    end
end
//=====================================================================
// mode 0, tmp_stop
//=====================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tmp_stop <= 0;
    end
    else begin
        tmp_stop <= stop;
    end
end
//=====================================================================
// mode 0, shift_start_1, shift_start_2
//=====================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        shift_start_1 <= 0;
        shift_start_2 <= 0;
    end
    else begin
        shift_start_1 <= start;
        shift_start_2 <= shift_start_1;
    end
end
//=====================================================================
// mem_addr
//=====================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mem1_addr <= 0;
        mem2_addr <= 0;
        cnt_sram <= 0;
    end 
    else begin
        case(next_state)
            s_idle : begin
                mem1_addr <= 0;
                mem2_addr <= 0;
                cnt_sram <= 0;
            end
            //=====================================================================
            s_mode_0, s_mode_0_1: begin
                if(start) begin
                    if(cnt_start_1 == 0) begin
                        if(mem1_addr!= 255) begin
                            mem1_addr <= mem1_addr + 1;
                        end
                        else begin
                            mem1_addr <= 0;
                        end
                    end
                    else begin
                        if(cnt_start_1[0] == 1)begin
                            if(mem1_addr != 255) begin
                                mem1_addr <= mem1_addr + 1;
                            end
                            
                            mem2_addr <= mem1_addr;
                        end
                        else begin
                            if(mem1_addr != 254) begin
                                mem2_addr <= mem2_addr + 1;
                            end
                            
                            mem1_addr <= mem2_addr;
                        end
                    end
                end
                else begin
                    if(cnt_start <= 256) begin
                        if(cnt_start_1[0] == 1) begin
                            mem2_addr <= mem1_addr;
                        end
                        else begin
                            mem1_addr <= mem2_addr;
                        end
                    end
                    else begin
                        mem1_addr <= 0;
                        mem2_addr <= 0;
                    end
                end
            end
            s_mode_0_2: begin
                mem1_addr <= 0;
                mem2_addr <= 0;
            end
            //=====================================================================
            s_window_1: begin
                if(which_sram == 1) begin
                    if(mem2_addr != 255)
                        mem2_addr <= mem2_addr + 1;
                end
                else begin
                    if(mem1_addr != 255)
                        mem1_addr <= mem1_addr + 1;
                end
            end
            s_window_3: begin
                if(mode_reg == 0) begin
                    mem1_addr <= 0;
                    mem2_addr <= 0;
                end
                else 
                    mem1_addr <= 240;
            end
            //===================================================================== 8
            s_dram_wr_1: begin
                if(mode_reg == 0) begin
                    if(which_sram == 1) begin
                        if(mem2_addr != 255) begin
                            if(cnt_window <= 15)
                                mem2_addr <= mem2_addr + 1;
                        end
                        else begin
                            if(cnt_window == 16) begin
                                cnt_sram <= cnt_sram + 1;
                                mem2_addr <= 0;
                            end
                        end  
                    end
                    else begin
                        if(mem1_addr != 255) begin
                            if(cnt_window <= 15)
                                mem1_addr <= mem1_addr + 1;
                        end
                        else begin
                            if(cnt_window == 16) begin
                                cnt_sram <= cnt_sram + 1;
                                mem1_addr <= 0;
                            end
                        end  
                    end
                end
                else begin
                    if(cnt_window <= 15)
                        mem1_addr <= mem1_addr + 1;
                end
            end
            s_dram_wr_2: begin
                if(mode_reg == 1) begin
                    mem1_addr <= 240;
                    if(cnt_window == 17)
                        cnt_sram <= cnt_sram + 1;
                end
            end
            //=====================================================================
            s_dram_rd_4: begin
                if(cnt_window <= 15)
                    mem1_addr <= mem1_addr + 1;
                if(mem1_addr == 255)
                    cnt_sram <= cnt_sram + 1;
            end
            s_dram_rd_5: begin
                mem1_addr <= 0;
                cnt_sram <= 0;
            end
            //=====================================================================
        endcase  
    end
end
//=====================================================================
// cnt_window, flag_finish_window_1
//=====================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		cnt_window <= 0;
        flag_finish_window_1 <= 0;
    end 
    else begin
        case(next_state)
            s_idle: begin
                cnt_window <= 0;
                flag_finish_window_1 <= 0;
            end
            s_window_1: begin
                cnt_window <= cnt_window + 1;
                if(cnt_window == 256)
                    flag_finish_window_1 <= 1;
            end
            s_window_2: begin
                cnt_window <= 0;
            end
            s_dram_wr_1: begin
                cnt_window <= cnt_window + 1;
            end
            s_dram_wr_2: begin
                cnt_window <= 0;
            end
            s_dram_rd_2: begin
                cnt_window <= 0;
            end
            s_dram_rd_4: begin
                cnt_window <= cnt_window + 1;
            end
            s_dram_rd_5: begin
                cnt_window <= 0;
            end
            default: begin
            end
        endcase  
    end
end
//=====================================================================
// dram_w_data
//=====================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		dram_w_data <= 0;
    end 
    else begin
        case(next_state)
            s_idle: begin
                dram_w_data <= 0;
            end
            s_dram_wr_1: begin
                dram_w_data <= (dram_w_data >> 8) + (dram_w_data_ns << 120);
            end
        endcase  
    end
end
//=====================================================================
// dram_w_data_ns
//=====================================================================
always@(*)begin
    dram_w_data_ns = 0;
    case(next_state)
        s_dram_wr_1: begin
            if(which_sram == 1) begin
                dram_w_data_ns = mem2_r_data[cnt_sram];
            end
            else begin
                dram_w_data_ns = mem1_r_data[cnt_sram];
            end
        end
        default: begin
            dram_w_data_ns = 0;
        end
    endcase
end
//=====================================================================
// dram_r_data
//=====================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		dram_r_data <= 0;
    end 
    else begin
        case(next_state)
            s_idle: begin
                dram_r_data <= 0;
            end
            s_dram_rd_3: begin
                dram_r_data <= rdata_m_inf;
            end
            s_dram_rd_4: begin
                dram_r_data <= (dram_r_data >> 8);
            end
        endcase  
    end
end
//=====================================================================
// bus[7:0]
//=====================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(j=0; j<16; j=j+1)
            for(i=0; i<8; i=i+1)
                bus[j][i] <= 0;
    end 
    else begin
        case(next_state)
            s_idle: begin
                for(j=0; j<16; j=j+1)
                    for(i=0; i<8; i=i+1)
                        bus[j][i] <= 0;
            end 
            s_window_1: begin
                if(which_sram == 1) begin
                    if(cnt_window >= 1) begin
                        for(i=0; i<16; i=i+1) begin
                            case(window_reg)
                                1:  begin
                                    bus[i][0] <= mem2_r_data[i];
                                end
                                2:  begin
                                    bus[i][0] <= mem2_r_data[i];
                                    bus[i][1] <= bus[i][0];
                                end
                                4:  begin
                                    bus[i][0] <= mem2_r_data[i];
                                    bus[i][1] <= bus[i][0];
                                    bus[i][2] <= bus[i][1];
                                    bus[i][3] <= bus[i][2];
                                end
                                8:  begin
                                    bus[i][0] <= mem2_r_data[i];
                                    bus[i][1] <= bus[i][0];
                                    bus[i][2] <= bus[i][1];
                                    bus[i][3] <= bus[i][2];
                                    bus[i][4] <= bus[i][3];
                                    bus[i][5] <= bus[i][4];
                                    bus[i][6] <= bus[i][5];
                                    bus[i][7] <= bus[i][6];
                                end
                            endcase
                        end
                    end
                end
                else begin
                    if(cnt_window >= 1) begin
                        for(i=0; i<16; i=i+1) begin
                            case(window_reg)
                                1:  begin
                                    bus[i][0] <= mem1_r_data[i];
                                end
                                2:  begin
                                    bus[i][0] <= mem1_r_data[i];
                                    bus[i][1] <= bus[i][0];
                                end
                                4:  begin
                                    bus[i][0] <= mem1_r_data[i];
                                    bus[i][1] <= bus[i][0];
                                    bus[i][2] <= bus[i][1];
                                    bus[i][3] <= bus[i][2];
                                end
                                8:  begin
                                    bus[i][0] <= mem1_r_data[i];
                                    bus[i][1] <= bus[i][0];
                                    bus[i][2] <= bus[i][1];
                                    bus[i][3] <= bus[i][2];
                                    bus[i][4] <= bus[i][3];
                                    bus[i][5] <= bus[i][4];
                                    bus[i][6] <= bus[i][5];
                                    bus[i][7] <= bus[i][6];
                                end
                            endcase
                        end
                    end
                end
            end
            s_window_3: begin
                for(j=0; j<16; j=j+1)
                    for(i=0; i<8; i=i+1)
                        bus[j][i] <= 0;
            end
        endcase
    end
end
//=====================================================================
// sum, best_loc
//=====================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<16; i=i+1) begin
		    sum[i] <= 0;
            best_loc[i] <= 0;
        end
    end 
    else begin
        case(next_state)
            s_idle: begin
                for(i=0; i<16; i=i+1) begin
                    sum[i] <= 0;
                    best_loc[i] <= 0;
                end
            end 
            s_window_1: begin
                if(cnt_window >= window_reg + 1) begin
                    if(cnt_window == window_reg + 1) begin
                        for(i=0; i<16; i=i+1) begin
                            sum[i] <= sum_ns[i];
                            best_loc[i] <= 1;
                        end
                    end
                    else begin
                        for(i=0; i<16; i=i+1) begin
                            if(sum_ns[i] > sum[i]) begin
                                sum[i] <= sum_ns[i];
                                best_loc[i] <= cnt_window - window_reg;
                            end
                        end
                    end
                end
            end
            s_window_3: begin
                for(i=0; i<16; i=i+1) begin
                    sum[i] <= 0;
                end
            end
        endcase
    end
end
//=====================================================================
// w_data_1
//=====================================================================
always@(*)begin
    for(i=0; i<16; i=i+1) mem1_w_data[i] = 0;
    case(next_state)
        s_mode_0, s_mode_0_1: begin
            if(cnt_start_1[0] == 0) begin // sram1
                if(cnt_start_1 == 0 && in_valid) begin // first one
                    if(start) begin
                        for(i=0; i<16; i=i+1) mem1_w_data[i] = stop[i];
                    end
                    else begin
                        for(i=0; i<16; i=i+1) mem1_w_data[i] = 0;
                    end
                end
                else begin// other
                    if(start) begin
                        for(i=0; i<16; i=i+1) mem1_w_data[i] = mem2_r_data[i] + tmp_stop[i];
                    end
                    else begin
                        if(cnt_start == 255) 
                            for(i=0; i<16; i=i+1) mem1_w_data[i] = mem2_r_data[i] + tmp_stop[i];
                        else
                            for(i=0; i<16; i=i+1) mem1_w_data[i] = 0;
                    end
                end
            end
            else begin // sram2
                mem1_w_data[i] = 0;
            end
        end
        s_window_2: begin
            if(which_sram == 0)
                for(i=0; i<16; i=i+1) mem1_w_data[i] = best_loc[i];
            else
                for(i=0; i<16; i=i+1) mem1_w_data[i] = 0;
        end
        s_dram_rd_4: begin
            for(i=0; i<16; i=i+1) begin
                mem1_w_data[i] = dram_r_data[7:0];
            end
        end
        default: begin
            for(i=0; i<16; i=i+1) mem1_w_data[i] = 0;
        end
    endcase
end
//=====================================================================
// w_data_2
//=====================================================================
always@(*)begin
    for(i=0; i<16; i=i+1) mem2_w_data[i] = 0;
    case(next_state)
        s_mode_0, s_mode_0_1: begin
            if(cnt_start_1[0] == 1) begin // sram2
                if(start) begin
                    for(i=0; i<16; i=i+1) mem2_w_data[i] = mem1_r_data[i] + tmp_stop[i];
                end
                else begin
                    if(cnt_start == 255)
                        for(i=0; i<16; i=i+1) mem2_w_data[i] = mem1_r_data[i] + tmp_stop[i];
                    else
                        for(i=0; i<16; i=i+1) mem2_w_data[i] = 0;
                end
            end
            else begin // sram1
                for(i=0; i<16; i=i+1) mem2_w_data[i] = 0;
            end
        end 
        s_window_2: begin
            for(i=0; i<16; i=i+1) begin
                if(which_sram == 1)
                    mem2_w_data[i] = best_loc[i];
                else
                    mem2_w_data[i] = 0;
            end
        end
        default: begin
            for(i=0; i<16; i=i+1) mem2_w_data[i] = 0;
        end
    endcase
end
//=====================================================================
// w_r_1
//=====================================================================
always@(*)begin
    for(i=0; i<16; i=i+1) w_r_1[i] = 0;
    case(next_state)
        s_mode_0, s_mode_0_1: begin
            if(cnt_start_1[0] == 0) begin
                if(cnt_start_1 == 0 && in_valid) begin
                    if(start) begin
                        if(cnt_start <= 254)
                            for(i=0; i<16; i=i+1) w_r_1[i] = Write;
                        else
                            for(i=0; i<16; i=i+1) w_r_1[i] = Read;
                    end
                    else begin
                        for(i=0; i<16; i=i+1) w_r_1[i] = Read;
                    end
                end
                else begin
                    if(start) begin
                        if(cnt_start <= 255)
                            for(i=0; i<16; i=i+1) w_r_1[i] = Write;
                        else
                            for(i=0; i<16; i=i+1) w_r_1[i] = Read;
                    end
                    else begin
                        if(cnt_start <= 256)
                            for(i=0; i<16; i=i+1) w_r_1[i] = Write;
                        else
                            for(i=0; i<16; i=i+1) w_r_1[i] = Read;
                    end
                end
            end
            else begin
                for(i=0; i<16; i=i+1) w_r_1[i] = Read;
            end
        end 
        s_window_2: begin
            if(which_sram == 0)
                for(i=0; i<16; i=i+1) w_r_1[i] = Write;
            else
                for(i=0; i<16; i=i+1) w_r_1[i] = Read;
        end
        s_dram_rd_4: begin
            for(i=0; i<16; i=i+1) begin
                if(i == cnt_sram)
                    w_r_1[i] = Write;
                else
                    w_r_1[i] = Read;
            end
        end
        default: begin
            for(i=0; i<16; i=i+1) w_r_1[i] = Read;
        end
    endcase
end
//=====================================================================
// w_r_2
//=====================================================================
always@(*)begin
    for(i=0; i<16; i=i+1) w_r_2[i] = 0;
    case(next_state)
        s_mode_0, s_mode_0_1: begin
            if(cnt_start_1[0] == 1) begin
                if(start) begin
                    if(cnt_start <= 255)
                        for(i=0; i<16; i=i+1) w_r_2[i] = Write;
                    else
                        for(i=0; i<16; i=i+1) w_r_2[i] = Read;
                end
                else begin
                    if(cnt_start <= 256)
                        for(i=0; i<16; i=i+1) w_r_2[i] = Write;
                    else
                        for(i=0; i<16; i=i+1) w_r_2[i] = Read;
                end
            end
            else begin
                for(i=0; i<16; i=i+1) w_r_2[i] = Read;
            end
        end 
        s_window_2: begin
            if(which_sram == 1)
                for(i=0; i<16; i=i+1) w_r_2[i] = Write;
            else
                for(i=0; i<16; i=i+1) w_r_2[i] = Read;
        end
        default: begin
            for(i=0; i<16; i=i+1) w_r_2[i] = Read;
        end
    endcase
end
//=====================================================================
// window, frame_id, mode_reg
//=====================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		window_reg <= 0;
        frame_id_reg <= 0;
        flag_win_id <= 0;
        mode_reg <= 0;
	end 
    else begin
        case(next_state)
            s_idle: begin
                window_reg <= 0;
                frame_id_reg <= 0;
                flag_win_id <= 0;
                mode_reg <= 0;
            end
            s_mode_0: begin
                mode_reg <= 0;
                if(flag_win_id == 0) begin
                    if(in_valid) begin
                        flag_win_id <= 1;
                        case(window)
                            0:  window_reg <= 1;
                            1:  window_reg <= 2;
                            2:  window_reg <= 4;
                            3:  window_reg <= 8;
                            default:  window_reg <= 0;
                        endcase
                        frame_id_reg <= frame_id;
                    end
                end
            end
            s_mode_1: begin
                mode_reg <= 1;
                if(flag_win_id == 0) begin
                    if(in_valid) begin
                        flag_win_id <= 1;
                        case(window)
                            0:  window_reg <= 1;
                            1:  window_reg <= 2;
                            2:  window_reg <= 4;
                            3:  window_reg <= 8;
                            default:  window_reg <= 0;
                        endcase
                        frame_id_reg <= frame_id;
                    end
                end
            end
            default: begin
            end
        endcase
    end
end
//=====================================================================
// busy
//=====================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		busy <= 0;
	end 
    else begin
        case(next_state)
            s_mode_0_1, s_mode_0_2, s_window_1, s_window_2, s_window_3, s_dram_wr_1, s_dram_wr_0, s_dram_wr_2, s_dram_wr_3: begin
                busy <= 1;
            end
            s_dram_rd_0, s_dram_rd_1, s_dram_rd_2, s_dram_rd_3, s_dram_rd_4, s_dram_rd_5: begin
                busy <= 1;
            end
            s_dram_wr_4: begin
                if(mode_reg == 0)
                    busy <= 0;
                else
                    busy <= 1;
            end
            default: begin
                busy <= 0;
            end
        endcase
    end
end
endmodule

module bus_sum (
    // in
    b0, b1, b2, b3, b4, b5, b6, b7,
    // out
    sol
);
input [7:0] b0, b1, b2, b3, b4, b5, b6, b7;
output [10:0] sol;
wire [8:0] a0 = b0 + b1;
wire [8:0] a1 = b2 + b3;
wire [8:0] a2 = b4 + b5;
wire [8:0] a3 = b6 + b7;

wire [9:0] c0 = a0 + a1;
wire [9:0] c1 = a2 + a3;

assign sol = c0 + c1;
endmodule