
`ifdef RTL
	`timescale 1ns/100ps
	`include "TOF.v"
    `define CYCLE_TIME 20
`endif
`ifdef GATE
	`timescale 1ns/100ps
	`include "TOF_SYN.v"
    `define CYCLE_TIME 20
`endif

`include "../00_TESTBED/pseudo_DRAM.v"


module PATTERN #(parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32)(
    // CHIP IO 
    clk,    
    rst_n,    
    in_valid,    
    start,
    stop,
    window,
    mode,
    frame_id,    
    busy,

    // AXI4 IO
    awid_s_inf,
    awaddr_s_inf,
    awsize_s_inf,
    awburst_s_inf,
    awlen_s_inf,
    awvalid_s_inf,
    awready_s_inf,

    wdata_s_inf,
    wlast_s_inf,
    wvalid_s_inf,
    wready_s_inf,

    bid_s_inf,
    bresp_s_inf,
    bvalid_s_inf,
    bready_s_inf,

    arid_s_inf,
    araddr_s_inf,
    arlen_s_inf,
    arsize_s_inf,
    arburst_s_inf,
    arvalid_s_inf,

    arready_s_inf, 
    rid_s_inf,
    rdata_s_inf,
    rresp_s_inf,
    rlast_s_inf,
    rvalid_s_inf,
    rready_s_inf 
);

// ===============================================================
//                      Input / Output 
// ===============================================================

// << CHIP io port with system >>
    output reg          clk, rst_n;
    output reg          in_valid;
    output reg          start;
    output reg [15: 0]  stop;     
    output reg [1: 0]   window; 
    output reg          mode;
    output reg [4: 0]   frame_id;
    input               busy;       

// << AXI Interface wire connecttion for pseudo DRAM read/write >>
// (1)     axi write address channel 
//         src master
    input wire [ID_WIDTH - 1: 0]    awid_s_inf;
    input wire [ADDR_WIDTH - 1: 0]  awaddr_s_inf;
    input wire [2: 0]               awsize_s_inf;
    input wire [1: 0]               awburst_s_inf;
    input wire [7: 0]               awlen_s_inf;
    input wire                      awvalid_s_inf;
//         src slave
    output wire                     awready_s_inf;
// -----------------------------

// (2)    axi write data channel 
//         src master
    input wire [DATA_WIDTH - 1: 0]  wdata_s_inf;
    input wire                      wlast_s_inf;
    input wire                      wvalid_s_inf;
//         src slave
    output wire                     wready_s_inf;

// (3)    axi write response channel 
//         src slave
    output wire  [ID_WIDTH - 1: 0]  bid_s_inf;
    output wire  [1: 0]             bresp_s_inf;
    output wire                     bvalid_s_inf;
//         src master 
    input wire                      bready_s_inf;
// -----------------------------

// (4)    axi read address channel 
//         src master
    input wire [ID_WIDTH - 1: 0]    arid_s_inf;
    input wire [ADDR_WIDTH - 1: 0]  araddr_s_inf;
    input wire [7: 0]               arlen_s_inf;
    input wire [2: 0]               arsize_s_inf;
    input wire [1: 0]               arburst_s_inf;
    input wire                      arvalid_s_inf;
//         src slave
    output wire                     arready_s_inf;
// -----------------------------

// (5)    axi read data channel 
//         src slave
    output wire [ID_WIDTH - 1: 0]    rid_s_inf;
    output wire [DATA_WIDTH - 1: 0]  rdata_s_inf;
    output wire [1: 0]               rresp_s_inf;
    output wire                      rlast_s_inf;
    output wire                      rvalid_s_inf;
//         src master
    input wire                       rready_s_inf;


// -------------------------//
//     DRAM Connection      //
//--------------------------//

pseudo_DRAM u_DRAM(
    .clk(clk),
    .rst_n(rst_n),

    .   awid_s_inf (   awid_s_inf),
    . awaddr_s_inf ( awaddr_s_inf),
    . awsize_s_inf ( awsize_s_inf),
    .awburst_s_inf (awburst_s_inf),
    .  awlen_s_inf (  awlen_s_inf),
    .awvalid_s_inf (awvalid_s_inf),
    .awready_s_inf (awready_s_inf),

    .  wdata_s_inf (  wdata_s_inf),
    .  wlast_s_inf (  wlast_s_inf),
    . wvalid_s_inf ( wvalid_s_inf),
    . wready_s_inf ( wready_s_inf),

    .    bid_s_inf (    bid_s_inf),
    .  bresp_s_inf (  bresp_s_inf),
    . bvalid_s_inf ( bvalid_s_inf),
    . bready_s_inf ( bready_s_inf),

    .   arid_s_inf (   arid_s_inf),
    . araddr_s_inf ( araddr_s_inf),
    .  arlen_s_inf (  arlen_s_inf),
    . arsize_s_inf ( arsize_s_inf),
    .arburst_s_inf (arburst_s_inf),
    .arvalid_s_inf (arvalid_s_inf),
    .arready_s_inf (arready_s_inf), 

    .    rid_s_inf (    rid_s_inf),
    .  rdata_s_inf (  rdata_s_inf),
    .  rresp_s_inf (  rresp_s_inf),
    .  rlast_s_inf (  rlast_s_inf),
    . rvalid_s_inf ( rvalid_s_inf),
    . rready_s_inf ( rready_s_inf) 
);

    // direct access DRAM: u_DRAM.DRAM_r[addr][7: 0];
  
// ===============================================================
// Parameter & Integer Declaration
// ===============================================================
    real CYCLE = `CYCLE_TIME;
    parameter PATNUM = 100;		//modify
    integer patcount;
    integer cycles, total_cycles;
    integer wait_gap;

    integer start_num;
    integer i, j;
    integer window_size;
    integer largest_value;
    integer largest_position_0,  largest_position_1,  largest_position_2,  largest_position_3,
            largest_position_4,  largest_position_5,  largest_position_6,  largest_position_7,
            largest_position_8,  largest_position_9,  largest_position_10, largest_position_11,
            largest_position_12, largest_position_13, largest_position_14, largest_position_15;
	integer output_file;
    parameter SIZE = 256;
//================================================================
// Wire & Reg Declaration
//================================================================
    reg [7: 0] histogram_0	[0: SIZE - 1];
    reg [7: 0] histogram_1	[0: SIZE - 1];
    reg [7: 0] histogram_2	[0: SIZE - 1];
    reg [7: 0] histogram_3 	[0: SIZE - 1];
    reg [7: 0] histogram_4 	[0: SIZE - 1];
    reg [7: 0] histogram_5 	[0: SIZE - 1];
    reg [7: 0] histogram_6	[0: SIZE - 1];
    reg [7: 0] histogram_7 	[0: SIZE - 1];
    reg [7: 0] histogram_8 	[0: SIZE - 1];
    reg [7: 0] histogram_9 	[0: SIZE - 1];
    reg [7: 0] histogram_10 [0: SIZE - 1];
    reg [7: 0] histogram_11	[0: SIZE - 1];
    reg [7: 0] histogram_12 [0: SIZE - 1];
    reg [7: 0] histogram_13 [0: SIZE - 1];
    reg [7: 0] histogram_14	[0: SIZE - 1];
    reg [7: 0] histogram_15 [0: SIZE - 1];


	reg [1:0] window_reg;
	reg mode_reg;
	reg [4:0] frame_id_reg;
	
    reg [7:0] dram_val;
	reg [7:0] golden_val;
	reg [7:0] golden_position;
	reg [3:0] histogram_num;
//================================================================
// Clock
//================================================================
    initial clk = 0;
    always #(CYCLE/2.0) clk = ~clk;
//================================================================
// Initial
//================================================================
    initial begin
	
        $readmemh("../00_TESTBED/dram.dat", u_DRAM.DRAM_r);
        rst_n    = 1'b1;
        in_valid = 1'b0;	
        start = 1'bx;
        stop  = 1'bx;
        window = 2'bx;
        mode = 1'bx;
        frame_id = 5'bx;
        
        force clk = 0;
        total_cycles = 0;
        window_size = 0;
	
        reset_task;
		
		output_file = $fopen("../00_TESTBED/error_pattern.txt","w");
		
        @(negedge clk);
        for (patcount = 0; patcount < PATNUM; patcount = patcount + 1) begin
            input_data;
            calculate_ans;
            wait_busy;
            check_ans;
            $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %3d\033[m", patcount ,cycles);
            total_cycles = total_cycles + cycles;
        end
        #(10*`CYCLE_TIME);
        YOU_pass_task;
        $finish;
    end	

   task reset_task; begin
        #(`CYCLE_TIME);	
		rst_n = 0;
        #(`CYCLE_TIME);
        if (busy !== 0) begin
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                        FAIL!                                                               ");
            $display ("                                                  Output signal should be 0 after initial RESET at %8t                                      ",$time);
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            
            #(10*`CYCLE_TIME);
            $finish;
        end
        #(`CYCLE_TIME); rst_n = 1 ;
        #(3.0); release clk;	
    end endtask

    task input_data; begin
	
        wait_gap = $urandom_range(2, 4);
        repeat(wait_gap)@(negedge clk);
        in_valid = 1'b1;
        
        frame_id = $urandom_range(0, 31);		//modify
        mode = $urandom_range(0, 1);			//modify
        window = $urandom_range(0, 3);			//modify
		start_num = $urandom_range(200, 255);	//modify
		
        start = 0;
		frame_id_reg = frame_id;
        mode_reg = mode;
        window_reg = window;
		
		@(negedge clk);
		
		frame_id = 5'bx;
        mode = 1'bx;
        window = 2'bx;
		
        if (mode_reg == 0)begin
            for (i = 0; i < SIZE; i = i + 1)begin
                histogram_0	[i] = 0;
                histogram_1	[i] = 0;
                histogram_2	[i] = 0;
                histogram_3 [i] = 0;
                histogram_4 [i] = 0;
                histogram_5 [i] = 0;
                histogram_6	[i] = 0;
                histogram_7 [i] = 0;
                histogram_8 [i] = 0;
                histogram_9 [i] = 0;
                histogram_10[i] = 0;
                histogram_11[i] = 0;
                histogram_12[i] = 0;
                histogram_13[i] = 0;
                histogram_14[i] = 0;
                histogram_15[i] = 0;
            end

            
            for (i = 0; i < start_num; i = i + 1)begin
                wait_gap = $urandom_range(3, 10);
                repeat(wait_gap)@(negedge clk);
        
                for (j = 0; j < SIZE - 1; j = j + 1)begin
                    start = 1;
                    stop = $urandom_range(0, 65535);
                    if (stop[0] == 1)	histogram_0[j]  = histogram_0[j]  + 1;
                    if (stop[1] == 1)	histogram_1[j]  = histogram_1[j]  + 1;
                    if (stop[2] == 1)	histogram_2[j]  = histogram_2[j]  + 1;
                    if (stop[3] == 1)	histogram_3[j]  = histogram_3[j]  + 1;
                    if (stop[4] == 1)	histogram_4[j]  = histogram_4[j]  + 1;
                    if (stop[5] == 1)	histogram_5[j]  = histogram_5[j]  + 1;
                    if (stop[6] == 1)	histogram_6[j]  = histogram_6[j]  + 1;
                    if (stop[7] == 1)	histogram_7[j]  = histogram_7[j]  + 1;
                    if (stop[8] == 1)	histogram_8[j]  = histogram_8[j]  + 1;
                    if (stop[9] == 1)	histogram_9[j]  = histogram_9[j]  + 1;
                    if (stop[10] == 1)	histogram_10[j] = histogram_10[j] + 1;
                    if (stop[11] == 1)	histogram_11[j] = histogram_11[j] + 1;
                    if (stop[12] == 1)	histogram_12[j] = histogram_12[j] + 1;
                    if (stop[13] == 1)	histogram_13[j] = histogram_13[j] + 1;
                    if (stop[14] == 1)	histogram_14[j] = histogram_14[j] + 1;
                    if (stop[15] == 1)	histogram_15[j] = histogram_15[j] + 1;
                    @(negedge clk);
                end
                start = 0;
				stop = 0;
            end	
        end
        else begin
            for (i = 0; i < 16; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    if (i != 15 || j != 15)
                        histogram_0[i * 16 + j] = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 0 * 16 * 16 + i * 16 + j];
                    else begin

                    end
                end
            end

            for (i = 0; i < 16; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    if (i != 15 || j != 15)
                        histogram_1[i * 16 + j] = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 1 * 16 * 16 + i * 16 + j];
                    else begin
                        
                    end
                end
            end
            for (i = 0; i < 16; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    if (i != 15 || j != 15)
                        histogram_2[i * 16 + j] = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 2 * 16 * 16 + i * 16 + j];
                    else begin
                        
                    end
                end
            end
            for (i = 0; i < 16; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    if (i != 15 || j != 15)
                        histogram_3[i * 16 + j] = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 3 * 16 * 16 + i * 16 + j];
                    else begin
                        
                    end
                end
            end
            for (i = 0; i < 16; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    if (i != 15 || j != 15)
                        histogram_4[i * 16 + j] = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 4 * 16 * 16 + i * 16 + j];
                    else begin
                        
                    end
                end
            end
            for (i = 0; i < 16; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    if (i != 15 || j != 15)
                        histogram_5[i * 16 + j] = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 5 * 16 * 16 + i * 16 + j];
                    else begin
                        
                    end
                end
            end
            for (i = 0; i < 16; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    if (i != 15 || j != 15)
                        histogram_6[i * 16 + j] = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 6 * 16 * 16 + i * 16 + j];
                    else begin
                        
                    end
                end
            end
            for (i = 0; i < 16; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    if (i != 15 || j != 15)
                        histogram_7[i * 16 + j] = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 7 * 16 * 16 + i * 16 + j];
                    else begin
                        
                    end
                end
            end
            for (i = 0; i < 16; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    if (i != 15 || j != 15)
                        histogram_8[i * 16 + j] = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 8 * 16 * 16 + i * 16 + j];
                    else begin
                        
                    end
                end
            end
            for (i = 0; i < 16; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    if (i != 15 || j != 15)
                        histogram_9[i * 16 + j] = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 9 * 16 * 16 + i * 16 + j];
                    else begin
                        
                    end
                end
            end
            for (i = 0; i < 16; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    if (i != 15 || j != 15)
                        histogram_10[i * 16 + j] = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 10 * 16 * 16 + i * 16 + j];
                    else begin
                        
                    end
                end
            end
            for (i = 0; i < 16; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    if (i != 15 || j != 15)
                        histogram_11[i * 16 + j] = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 11 * 16 * 16 + i * 16 + j];
                    else begin
                        
                    end
                end
            end
            for (i = 0; i < 16; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    if (i != 15 || j != 15)
                        histogram_12[i * 16 + j] = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 12 * 16 * 16 + i * 16 + j];
                    else begin
                        
                    end
                end
            end
            for (i = 0; i < 16; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    if (i != 15 || j != 15)
                        histogram_13[i * 16 + j] = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 13 * 16 * 16 + i * 16 + j];
                    else begin
                        
                    end
                end
            end
            for (i = 0; i < 16; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    if (i != 15 || j != 15)
                        histogram_14[i * 16 + j] = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 14 * 16 * 16 + i * 16 + j];
                    else begin
                        
                    end
                end
            end
            for (i = 0; i < 16; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    if (i != 15 || j != 15)
                        histogram_15[i * 16 + j] = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 15 * 16 * 16 + i * 16 + j];
                    else begin
                        
                    end
                end
            end
        end
		in_valid = 0;
		

    end endtask

    task wait_busy; begin
        @(negedge clk);
        cycles = 0;
        while(busy === 1)begin
            cycles = cycles + 1;
            if (cycles == 1000000) begin
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                $display ("                                                                        FAIL!                                                               ");
                $display ("                                                                   Pattern NO.%03d                                                          ", patcount);
                $display ("                                                     The execution latency are over 1000000 cycles                                            ");
                $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
                repeat(2)@(negedge clk);
                $finish;
            end
        @(negedge clk);
        end
    end endtask

    task calculate_ans; begin
        largest_position_0 = 0;  largest_position_1  = 0; largest_position_2  = 0; largest_position_3  = 0;
        largest_position_4 = 0;  largest_position_5  = 0; largest_position_6  = 0; largest_position_7  = 0;
        largest_position_8 = 0;  largest_position_9  = 0; largest_position_10 = 0; largest_position_11 = 0;
        largest_position_12 = 0; largest_position_13 = 0; largest_position_14 = 0; largest_position_15 = 0;
        largest_value = 0;
        if (window_reg === 0) begin
            for (i = 0; i < SIZE - 1; i = i + 1) begin
                if (histogram_0[i] > largest_value && i > largest_position_0) begin
                    largest_value = histogram_0[i]; largest_position_0 = i; 
                end

                if (i == 0)
                    largest_value = histogram_0[0];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 1; i = i + 1) begin
                if (histogram_1[i] > largest_value && i > largest_position_1) begin
                    largest_value = histogram_1[i]; largest_position_1 = i;
                end

                if (i == 0)
                    largest_value = histogram_1[0];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 1; i = i + 1) begin
                if (histogram_2[i] > largest_value && i > largest_position_2) begin
                    largest_value = histogram_2[i]; largest_position_2 = i;
                end

                if (i == 0)
                    largest_value = histogram_2[0];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 1; i = i + 1) begin
                if (histogram_3[i] > largest_value && i > largest_position_3) begin
                    largest_value = histogram_3[i]; largest_position_3 = i;
                end

                if (i == 0)
                    largest_value = histogram_3[0];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 1; i = i + 1) begin
                if (histogram_4[i] > largest_value && i > largest_position_4) begin
                    largest_value = histogram_4[i]; largest_position_4 = i;
                end

                if (i == 0)
                    largest_value = histogram_4[0];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 1; i = i + 1) begin
                if (histogram_5[i] > largest_value && i > largest_position_5) begin
                    largest_value = histogram_5[i]; largest_position_5 = i;
                end

                if (i == 0)
                    largest_value = histogram_5[0];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 1; i = i + 1) begin
                if (histogram_6[i] > largest_value && i > largest_position_6) begin
                    largest_value = histogram_6[i]; largest_position_6 = i;
                end

                if (i == 0)
                    largest_value = histogram_6[0];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 1; i = i + 1) begin
                if (histogram_7[i] > largest_value && i > largest_position_7) begin
                    largest_value = histogram_7[i]; largest_position_7 = i;
                end

                if (i == 0)
                    largest_value = histogram_7[0];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 1; i = i + 1) begin
                if (histogram_8[i] > largest_value && i > largest_position_8) begin
                    largest_value = histogram_8[i]; largest_position_8 = i;
                end

                if (i == 0)
                    largest_value = histogram_8[0];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 1; i = i + 1) begin
                if (histogram_9[i] > largest_value && i > largest_position_9) begin
                    largest_value = histogram_9[i]; largest_position_9 = i;
                end

                if (i == 0)
                    largest_value = histogram_9[0];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 1; i = i + 1) begin
                if (histogram_10[i] > largest_value && i > largest_position_10) begin
                    largest_value = histogram_10[i]; largest_position_10 = i;
                end

                if (i == 0)
                    largest_value = histogram_10[0];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 1; i = i + 1) begin
                if (histogram_11[i] > largest_value && i > largest_position_11) begin
                    largest_value = histogram_11[i]; largest_position_11 = i;
                end

                if (i == 0)
                    largest_value = histogram_11[0];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 1; i = i + 1) begin
                if (histogram_12[i] > largest_value && i > largest_position_12) begin
                    largest_value = histogram_12[i]; largest_position_12 = i;
                end

                if (i == 0)
                    largest_value = histogram_12[0];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 1; i = i + 1) begin
                if (histogram_13[i] > largest_value && i > largest_position_13) begin
                    largest_value = histogram_13[i]; largest_position_13 = i;
                end

                if (i == 0)
                    largest_value = histogram_13[0];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 1; i = i + 1) begin
                if (histogram_14[i] > largest_value && i > largest_position_14) begin
                    largest_value = histogram_14[i]; largest_position_14 = i;
                end

                if (i == 0)
                    largest_value = histogram_14[0];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 1; i = i + 1) begin
                if (histogram_15[i] > largest_value && i > largest_position_15) begin
                    largest_value = histogram_15[i]; largest_position_15 = i;
                end

                if (i == 0)
                    largest_value = histogram_15[0];
            end
        end
        else if (window_reg === 1) begin
            for (i = 0; i < SIZE - 2; i = i + 1) begin
                if (histogram_0[i] + histogram_0[i + 1] > largest_value && i > largest_position_0) begin
                    largest_value = histogram_0[i] + histogram_0[i + 1]; largest_position_0 = i; 
                end

                if (i == 0)
                    largest_value = histogram_0[0] + histogram_0[1];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 2; i = i + 1) begin
                if (histogram_1[i] + histogram_1[i + 1] > largest_value && i > largest_position_2) begin
                    largest_value = histogram_1[i] + histogram_1[i + 1]; largest_position_1 = i; 
                end

                if (i == 0)
                    largest_value = histogram_1[0] + histogram_1[1];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 2; i = i + 1) begin
                if (histogram_2[i] + histogram_2[i + 1] > largest_value && i > largest_position_2) begin
                    largest_value = histogram_2[i] + histogram_2[i + 1]; largest_position_2 = i; 
                end

                if (i == 0)
                    largest_value = histogram_2[0] + histogram_2[1];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 2; i = i + 1) begin
                if (histogram_3[i] + histogram_3[i + 1] > largest_value && i > largest_position_3) begin
                    largest_value = histogram_3[i] + histogram_3[i + 1]; largest_position_3 = i; 
                end

                if (i == 0)
                    largest_value = histogram_3[0] + histogram_3[1];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 2; i = i + 1) begin
                if (histogram_4[i] + histogram_4[i + 1] > largest_value && i > largest_position_4) begin
                    largest_value = histogram_4[i] + histogram_4[i + 1]; largest_position_4 = i; 
                end

                if (i == 0)
                    largest_value = histogram_4[0] + histogram_4[1];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 2; i = i + 1) begin
                if (histogram_5[i] + histogram_5[i + 1] > largest_value && i > largest_position_5) begin
                    largest_value = histogram_5[i] + histogram_5[i + 1]; largest_position_5 = i; 
                end

                if (i == 0)
                    largest_value = histogram_5[0] + histogram_5[1];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 2; i = i + 1) begin
                if (histogram_6[i] + histogram_6[i + 1] > largest_value && i > largest_position_6) begin
                    largest_value = histogram_6[i] + histogram_6[i + 1]; largest_position_6 = i; 
                end

                if (i == 0)
                    largest_value = histogram_6[0] + histogram_6[1];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 2; i = i + 1) begin
                if (histogram_7[i] + histogram_7[i + 1] > largest_value && i > largest_position_7) begin
                    largest_value = histogram_7[i] + histogram_7[i + 1]; largest_position_7 = i; 
                end

                if (i == 0)
                    largest_value = histogram_7[0] + histogram_7[1];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 2; i = i + 1) begin
                if (histogram_8[i] + histogram_8[i + 1] > largest_value && i > largest_position_8) begin
                    largest_value = histogram_8[i] + histogram_8[i + 1]; largest_position_8 = i; 
                end

                if (i == 0)
                    largest_value = histogram_8[0] + histogram_8[1];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 2; i = i + 1) begin
                if (histogram_9[i] + histogram_9[i + 1] > largest_value && i > largest_position_9) begin
                    largest_value = histogram_9[i] + histogram_9[i + 1]; largest_position_9 = i; 
                end

                if (i == 0)
                    largest_value = histogram_9[0] + histogram_9[1];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 2; i = i + 1) begin
                if (histogram_10[i] + histogram_10[i + 1] > largest_value && i > largest_position_10) begin
                    largest_value = histogram_10[i] + histogram_10[i + 1]; largest_position_10 = i; 
                end

                if (i == 0)
                    largest_value = histogram_10[0] + histogram_10[1];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 2; i = i + 1) begin
                if (histogram_11[i] + histogram_11[i + 1] > largest_value && i > largest_position_11) begin
                    largest_value = histogram_11[i] + histogram_11[i + 1]; largest_position_11 = i; 
                end

                if (i == 0)
                    largest_value = histogram_11[0] + histogram_11[1];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 2; i = i + 1) begin
                if (histogram_12[i] + histogram_12[i + 1] > largest_value && i > largest_position_12) begin
                    largest_value = histogram_12[i] + histogram_12[i + 1]; largest_position_12 = i; 
                end

                if (i == 0)
                    largest_value = histogram_12[0] + histogram_12[1];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 2; i = i + 1) begin
                if (histogram_13[i] + histogram_13[i + 1] > largest_value && i > largest_position_13) begin
                    largest_value = histogram_13[i] + histogram_13[i + 1]; largest_position_13 = i; 
                end

                if (i == 0)
                    largest_value = histogram_13[0] + histogram_13[1];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 2; i = i + 1) begin
                if (histogram_14[i] + histogram_14[i + 1] > largest_value && i > largest_position_14) begin
                    largest_value = histogram_14[i] + histogram_14[i + 1]; largest_position_14 = i; 
                end

                if (i == 0)
                    largest_value = histogram_14[0] + histogram_14[1];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 2; i = i + 1) begin
                if (histogram_15[i] + histogram_15[i + 1] > largest_value && i > largest_position_15) begin
                    largest_value = histogram_15[i] + histogram_15[i + 1]; largest_position_15 = i; 
                end

                if (i == 0)
                    largest_value = histogram_15[0] + histogram_15[1];
            end
        end
        else if (window_reg === 2) begin
            largest_value = 0;
            for (i = 0; i < SIZE - 4; i = i + 1) begin
               if (histogram_0[i] + histogram_0[i + 1] + histogram_0[i + 2] + histogram_0[i + 3] > largest_value && i > largest_position_0) begin
                    largest_value = histogram_0[i] + histogram_0[i + 1] + histogram_0[i + 2] + histogram_0[i + 3]; largest_position_0 = i;
                end

                if (i == 0)
                    largest_value = histogram_0[0] + histogram_0[1] + histogram_0[2] + histogram_0[3];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 4; i = i + 1) begin
               if (histogram_1[i] + histogram_1[i + 1] + histogram_1[i + 2] + histogram_1[i + 3] > largest_value && i > largest_position_1) begin
                    largest_value = histogram_1[i] + histogram_1[i + 1] + histogram_1[i + 2] + histogram_1[i + 3]; largest_position_1 = i;
                end

                if (i == 0)
                    largest_value = histogram_1[0] + histogram_1[1] + histogram_1[2] + histogram_1[3];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 4; i = i + 1) begin
               if (histogram_2[i] + histogram_2[i + 1] + histogram_2[i + 2] + histogram_2[i + 3] > largest_value && i > largest_position_2) begin
                    largest_value = histogram_2[i] + histogram_2[i + 1] + histogram_2[i + 2] + histogram_2[i + 3]; largest_position_2 = i;
                end

                if (i == 0)
                    largest_value = histogram_2[0] + histogram_2[1] + histogram_2[2] + histogram_2[3];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 4; i = i + 1) begin
               if (histogram_3[i] + histogram_3[i + 1] + histogram_3[i + 2] + histogram_3[i + 3] > largest_value && i > largest_position_3) begin
                    largest_value = histogram_3[i] + histogram_3[i + 1] + histogram_3[i + 2] + histogram_3[i + 3]; largest_position_3 = i;
                end

                if (i == 0)
                    largest_value = histogram_3[0] + histogram_3[1] + histogram_3[2] + histogram_3[3];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 4; i = i + 1) begin
               if (histogram_4[i] + histogram_4[i + 1] + histogram_4[i + 2] + histogram_4[i + 3] > largest_value && i > largest_position_4) begin
                    largest_value = histogram_4[i] + histogram_4[i + 1] + histogram_4[i + 2] + histogram_4[i + 3]; largest_position_4 = i;
                end

                if (i == 0)
                    largest_value = histogram_4[0] + histogram_4[1] + histogram_4[2] + histogram_4[3];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 4; i = i + 1) begin
               if (histogram_5[i] + histogram_5[i + 1] + histogram_5[i + 2] + histogram_5[i + 3] > largest_value && i > largest_position_5) begin
                    largest_value = histogram_5[i] + histogram_5[i + 1] + histogram_5[i + 2] + histogram_5[i + 3]; largest_position_5 = i;
                end

                if (i == 0)
                    largest_value = histogram_5[0] + histogram_5[1] + histogram_5[2] + histogram_5[3];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 4; i = i + 1) begin
               if (histogram_6[i] + histogram_6[i + 1] + histogram_6[i + 2] + histogram_6[i + 3] > largest_value && i > largest_position_6) begin
                    largest_value = histogram_6[i] + histogram_6[i + 1] + histogram_6[i + 2] + histogram_6[i + 3]; largest_position_6 = i;
                end

                if (i == 0)
                    largest_value = histogram_6[0] + histogram_6[1] + histogram_6[2] + histogram_6[3];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 4; i = i + 1) begin
               if (histogram_7[i] + histogram_7[i + 1] + histogram_7[i + 2] + histogram_7[i + 3] > largest_value && i > largest_position_7) begin
                    largest_value = histogram_7[i] + histogram_7[i + 1] + histogram_7[i + 2] + histogram_7[i + 3]; largest_position_7 = i;
                end

                if (i == 0)
                    largest_value = histogram_7[0] + histogram_7[1] + histogram_7[2] + histogram_7[3];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 4; i = i + 1) begin
               if (histogram_8[i] + histogram_8[i + 1] + histogram_8[i + 2] + histogram_8[i + 3] > largest_value && i > largest_position_8) begin
                    largest_value = histogram_8[i] + histogram_8[i + 1] + histogram_8[i + 2] + histogram_8[i + 3]; largest_position_8 = i;
                end

                if (i == 0)
                    largest_value = histogram_8[0] + histogram_8[1] + histogram_8[2] + histogram_8[3];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 4; i = i + 1) begin
               if (histogram_9[i] + histogram_9[i + 1] + histogram_9[i + 2] + histogram_9[i + 3] > largest_value && i > largest_position_9) begin
                    largest_value = histogram_9[i] + histogram_9[i + 1] + histogram_9[i + 2] + histogram_9[i + 3]; largest_position_9 = i;
                end

                if (i == 0)
                    largest_value = histogram_9[0] + histogram_9[1] + histogram_9[2] + histogram_9[3];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 4; i = i + 1) begin
               if (histogram_10[i] + histogram_10[i + 1] + histogram_10[i + 2] + histogram_10[i + 3] > largest_value && i > largest_position_10) begin
                    largest_value = histogram_10[i] + histogram_10[i + 1] + histogram_10[i + 2] + histogram_10[i + 3]; largest_position_10 = i;
                end

                if (i == 0)
                    largest_value = histogram_10[0] + histogram_10[1] + histogram_10[2] + histogram_10[3];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 4; i = i + 1) begin
               if (histogram_11[i] + histogram_11[i + 1] + histogram_11[i + 2] + histogram_11[i + 3] > largest_value && i > largest_position_11) begin
                    largest_value = histogram_11[i] + histogram_11[i + 1] + histogram_11[i + 2] + histogram_11[i + 3]; largest_position_11 = i;
                end

                if (i == 0)
                    largest_value = histogram_11[0] + histogram_11[1] + histogram_11[2] + histogram_11[3];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 4; i = i + 1) begin
               if (histogram_12[i] + histogram_12[i + 1] + histogram_12[i + 2] + histogram_12[i + 3] > largest_value && i > largest_position_12) begin
                    largest_value = histogram_12[i] + histogram_12[i + 1] + histogram_12[i + 2] + histogram_12[i + 3]; largest_position_12 = i;
                end

                if (i == 0)
                    largest_value = histogram_12[0] + histogram_12[1] + histogram_12[2] + histogram_12[3];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 4; i = i + 1) begin
               if (histogram_13[i] + histogram_13[i + 1] + histogram_13[i + 2] + histogram_13[i + 3] > largest_value && i > largest_position_13) begin
                    largest_value = histogram_13[i] + histogram_13[i + 1] + histogram_13[i + 2] + histogram_13[i + 3]; largest_position_13 = i;
                end

                if (i == 0)
                    largest_value = histogram_13[0] + histogram_13[1] + histogram_13[2] + histogram_13[3];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 4; i = i + 1) begin
               if (histogram_14[i] + histogram_14[i + 1] + histogram_14[i + 2] + histogram_14[i + 3] > largest_value && i > largest_position_14) begin
                    largest_value = histogram_14[i] + histogram_14[i + 1] + histogram_14[i + 2] + histogram_14[i + 3]; largest_position_14 = i;
                end

                if (i == 0)
                    largest_value = histogram_14[0] + histogram_14[1] + histogram_14[2] + histogram_14[3];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 4; i = i + 1) begin
               if (histogram_15[i] + histogram_15[i + 1] + histogram_15[i + 2] + histogram_15[i + 3] > largest_value && i > largest_position_15) begin
                    largest_value = histogram_15[i] + histogram_15[i + 1] + histogram_15[i + 2] + histogram_15[i + 3]; largest_position_15 = i;
                end

                if (i == 0)
                    largest_value = histogram_15[0] + histogram_15[1] + histogram_15[2] + histogram_15[3];
            end
        end
        else if (window_reg === 3) begin
            largest_value = 0;
            for (i = 0; i < SIZE - 8; i = i + 1) begin
               if (histogram_0[i] + histogram_0[i + 1] + histogram_0[i + 2] + histogram_0[i + 3] + histogram_0[i + 4] + histogram_0[i + 5] + histogram_0[i + 6] + histogram_0[i + 7] > largest_value && i > largest_position_0) begin
                    largest_value = histogram_0[i] + histogram_0[i + 1] + histogram_0[i + 2] + histogram_0[i + 3] + histogram_0[i + 4] + histogram_0[i + 5] + histogram_0[i + 6] + histogram_0[i + 7]; largest_position_0= i;
                end

                if (i == 0)
                    largest_value = histogram_0[0] + histogram_0[1] + histogram_0[2] + histogram_0[3] + histogram_0[4] + histogram_0[5] + histogram_0[6] + histogram_0[7];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 8; i = i + 1) begin
               if (histogram_1[i] + histogram_1[i + 1] + histogram_1[i + 2] + histogram_1[i + 3] + histogram_1[i + 4] + histogram_1[i + 5] + histogram_1[i + 6] + histogram_1[i + 7] > largest_value && i > largest_position_1) begin
                    largest_value = histogram_1[i] + histogram_1[i + 1] + histogram_1[i + 2] + histogram_1[i + 3] + histogram_1[i + 4] + histogram_1[i + 5] + histogram_1[i + 6] + histogram_1[i + 7]; largest_position_1= i;
                end

                if (i == 0)
                    largest_value = histogram_1[0] + histogram_1[1] + histogram_1[2] + histogram_1[3] + histogram_1[4] + histogram_1[5] + histogram_1[6] + histogram_1[7];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 8; i = i + 1) begin
               if (histogram_2[i] + histogram_2[i + 1] + histogram_2[i + 2] + histogram_2[i + 3] + histogram_2[i + 4] + histogram_2[i + 5] + histogram_2[i + 6] + histogram_2[i + 7] > largest_value && i > largest_position_2) begin
                    largest_value = histogram_2[i] + histogram_2[i + 1] + histogram_2[i + 2] + histogram_2[i + 3] + histogram_2[i + 4] + histogram_2[i + 5] + histogram_2[i + 6] + histogram_2[i + 7]; largest_position_2= i;
                end

                if (i == 0)
                    largest_value = histogram_2[0] + histogram_2[1] + histogram_2[2] + histogram_2[3] + histogram_2[4] + histogram_2[5] + histogram_2[6] + histogram_2[7];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 8; i = i + 1) begin
               if (histogram_3[i] + histogram_3[i + 1] + histogram_3[i + 2] + histogram_3[i + 3] + histogram_3[i + 4] + histogram_3[i + 5] + histogram_3[i + 6] + histogram_3[i + 7] > largest_value && i > largest_position_3) begin
                    largest_value = histogram_3[i] + histogram_3[i + 1] + histogram_3[i + 2] + histogram_3[i + 3] + histogram_3[i + 4] + histogram_3[i + 5] + histogram_3[i + 6] + histogram_3[i + 7]; largest_position_3= i;
                end

                if (i == 0)
                    largest_value = histogram_3[0] + histogram_3[1] + histogram_3[2] + histogram_3[3] + histogram_3[4] + histogram_3[5] + histogram_3[6] + histogram_3[7];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 8; i = i + 1) begin
               if (histogram_4[i] + histogram_4[i + 1] + histogram_4[i + 2] + histogram_4[i + 3] + histogram_4[i + 4] + histogram_4[i + 5] + histogram_4[i + 6] + histogram_4[i + 7] > largest_value && i > largest_position_4) begin
                    largest_value = histogram_4[i] + histogram_4[i + 1] + histogram_4[i + 2] + histogram_4[i + 3] + histogram_4[i + 4] + histogram_4[i + 5] + histogram_4[i + 6] + histogram_4[i + 7]; largest_position_4= i;
                end

                if (i == 0)
                    largest_value = histogram_4[0] + histogram_4[1] + histogram_4[2] + histogram_4[3] + histogram_4[4] + histogram_4[5] + histogram_4[6] + histogram_4[7];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 8; i = i + 1) begin
               if (histogram_5[i] + histogram_5[i + 1] + histogram_5[i + 2] + histogram_5[i + 3] + histogram_5[i + 4] + histogram_5[i + 5] + histogram_5[i + 6] + histogram_5[i + 7] > largest_value && i > largest_position_5) begin
                    largest_value = histogram_5[i] + histogram_5[i + 1] + histogram_5[i + 2] + histogram_5[i + 3] + histogram_5[i + 4] + histogram_5[i + 5] + histogram_5[i + 6] + histogram_5[i + 7]; largest_position_5= i;
                end

                if (i == 0)
                    largest_value = histogram_5[0] + histogram_5[1] + histogram_5[2] + histogram_5[3] + histogram_5[4] + histogram_5[5] + histogram_5[6] + histogram_5[7];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 8; i = i + 1) begin
               if (histogram_6[i] + histogram_6[i + 1] + histogram_6[i + 2] + histogram_6[i + 3] + histogram_6[i + 4] + histogram_6[i + 5] + histogram_6[i + 6] + histogram_6[i + 7] > largest_value && i > largest_position_6) begin
                    largest_value = histogram_6[i] + histogram_6[i + 1] + histogram_6[i + 2] + histogram_6[i + 3] + histogram_6[i + 4] + histogram_6[i + 5] + histogram_6[i + 6] + histogram_6[i + 7]; largest_position_6= i;
                end

                if (i == 0)
                    largest_value = histogram_6[0] + histogram_6[1] + histogram_6[2] + histogram_6[3] + histogram_6[4] + histogram_6[5] + histogram_6[6] + histogram_6[7];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 8; i = i + 1) begin
               if (histogram_7[i] + histogram_7[i + 1] + histogram_7[i + 2] + histogram_7[i + 3] + histogram_7[i + 4] + histogram_7[i + 5] + histogram_7[i + 6] + histogram_7[i + 7] > largest_value && i > largest_position_7) begin
                    largest_value = histogram_7[i] + histogram_7[i + 1] + histogram_7[i + 2] + histogram_7[i + 3] + histogram_7[i + 4] + histogram_7[i + 5] + histogram_7[i + 6] + histogram_7[i + 7]; largest_position_7= i;
                end

                if (i == 0)
                    largest_value = histogram_7[0] + histogram_7[1] + histogram_7[2] + histogram_7[3] + histogram_7[4] + histogram_7[5] + histogram_7[6] + histogram_7[7];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 8; i = i + 1) begin
               if (histogram_8[i] + histogram_8[i + 1] + histogram_8[i + 2] + histogram_8[i + 3] + histogram_8[i + 4] + histogram_8[i + 5] + histogram_8[i + 6] + histogram_8[i + 7] > largest_value && i > largest_position_8) begin
                    largest_value = histogram_8[i] + histogram_8[i + 1] + histogram_8[i + 2] + histogram_8[i + 3] + histogram_8[i + 4] + histogram_8[i + 5] + histogram_8[i + 6] + histogram_8[i + 7]; largest_position_8= i;
                end

                if (i == 0)
                    largest_value = histogram_8[0] + histogram_8[1] + histogram_8[2] + histogram_8[3] + histogram_8[4] + histogram_8[5] + histogram_8[6] + histogram_8[7];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 8; i = i + 1) begin
               if (histogram_9[i] + histogram_9[i + 1] + histogram_9[i + 2] + histogram_9[i + 3] + histogram_9[i + 4] + histogram_9[i + 5] + histogram_9[i + 6] + histogram_9[i + 7] > largest_value && i > largest_position_9) begin
                    largest_value = histogram_9[i] + histogram_9[i + 1] + histogram_9[i + 2] + histogram_9[i + 3] + histogram_9[i + 4] + histogram_9[i + 5] + histogram_9[i + 6] + histogram_9[i + 7]; largest_position_9= i;
                end

                if (i == 0)
                    largest_value = histogram_9[0] + histogram_9[1] + histogram_9[2] + histogram_9[3] + histogram_9[4] + histogram_9[5] + histogram_9[6] + histogram_9[7];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 8; i = i + 1) begin
               if (histogram_10[i] + histogram_10[i + 1] + histogram_10[i + 2] + histogram_10[i + 3] + histogram_10[i + 4] + histogram_10[i + 5] + histogram_10[i + 6] + histogram_10[i + 7] > largest_value && i > largest_position_10) begin
                    largest_value = histogram_10[i] + histogram_10[i + 1] + histogram_10[i + 2] + histogram_10[i + 3] + histogram_10[i + 4] + histogram_10[i + 5] + histogram_10[i + 6] + histogram_10[i + 7]; largest_position_10= i;
                end

                if (i == 0)
                    largest_value = histogram_10[0] + histogram_10[1] + histogram_10[2] + histogram_10[3] + histogram_10[4] + histogram_10[5] + histogram_10[6] + histogram_10[7];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 8; i = i + 1) begin
               if (histogram_11[i] + histogram_11[i + 1] + histogram_11[i + 2] + histogram_11[i + 3] + histogram_11[i + 4] + histogram_11[i + 5] + histogram_11[i + 6] + histogram_11[i + 7] > largest_value && i > largest_position_11) begin
                    largest_value = histogram_11[i] + histogram_11[i + 1] + histogram_11[i + 2] + histogram_11[i + 3] + histogram_11[i + 4] + histogram_11[i + 5] + histogram_11[i + 6] + histogram_11[i + 7]; largest_position_11= i;
                end

                if (i == 0)
                    largest_value = histogram_11[0] + histogram_11[1] + histogram_11[2] + histogram_11[3] + histogram_11[4] + histogram_11[5] + histogram_11[6] + histogram_11[7];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 8; i = i + 1) begin
               if (histogram_12[i] + histogram_12[i + 1] + histogram_12[i + 2] + histogram_12[i + 3] + histogram_12[i + 4] + histogram_12[i + 5] + histogram_12[i + 6] + histogram_12[i + 7] > largest_value && i > largest_position_12) begin
                    largest_value = histogram_12[i] + histogram_12[i + 1] + histogram_12[i + 2] + histogram_12[i + 3] + histogram_12[i + 4] + histogram_12[i + 5] + histogram_12[i + 6] + histogram_12[i + 7]; largest_position_12= i;
                end

                if (i == 0)
                    largest_value = histogram_12[0] + histogram_12[1] + histogram_12[2] + histogram_12[3] + histogram_12[4] + histogram_12[5] + histogram_12[6] + histogram_12[7];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 8; i = i + 1) begin
               if (histogram_13[i] + histogram_13[i + 1] + histogram_13[i + 2] + histogram_13[i + 3] + histogram_13[i + 4] + histogram_13[i + 5] + histogram_13[i + 6] + histogram_13[i + 7] > largest_value && i > largest_position_13) begin
                    largest_value = histogram_13[i] + histogram_13[i + 1] + histogram_13[i + 2] + histogram_13[i + 3] + histogram_13[i + 4] + histogram_13[i + 5] + histogram_13[i + 6] + histogram_13[i + 7]; largest_position_13= i;
                end

                if (i == 0)
                    largest_value = histogram_13[0] + histogram_13[1] + histogram_13[2] + histogram_13[3] + histogram_13[4] + histogram_13[5] + histogram_13[6] + histogram_13[7];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 8; i = i + 1) begin
               if (histogram_14[i] + histogram_14[i + 1] + histogram_14[i + 2] + histogram_14[i + 3] + histogram_14[i + 4] + histogram_14[i + 5] + histogram_14[i + 6] + histogram_14[i + 7] > largest_value && i > largest_position_14) begin
                    largest_value = histogram_14[i] + histogram_14[i + 1] + histogram_14[i + 2] + histogram_14[i + 3] + histogram_14[i + 4] + histogram_14[i + 5] + histogram_14[i + 6] + histogram_14[i + 7]; largest_position_14= i;
                end

                if (i == 0)
                    largest_value = histogram_14[0] + histogram_14[1] + histogram_14[2] + histogram_14[3] + histogram_14[4] + histogram_14[5] + histogram_14[6] + histogram_14[7];
            end
            largest_value = 0;
            for (i = 0; i < SIZE - 8; i = i + 1) begin
               if (histogram_15[i] + histogram_15[i + 1] + histogram_15[i + 2] + histogram_15[i + 3] + histogram_15[i + 4] + histogram_15[i + 5] + histogram_15[i + 6] + histogram_15[i + 7] > largest_value && i > largest_position_15) begin
                    largest_value = histogram_15[i] + histogram_15[i + 1] + histogram_15[i + 2] + histogram_15[i + 3] + histogram_15[i + 4] + histogram_15[i + 5] + histogram_15[i + 6] + histogram_15[i + 7]; largest_position_15= i;
                end

                if (i == 0)
                    largest_value = histogram_15[0] + histogram_15[1] + histogram_15[2] + histogram_15[3] + histogram_15[4] + histogram_15[5] + histogram_15[6] + histogram_15[7];
            end

        end
    end endtask

    task check_ans; begin
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 0 * 16 * 16 + i * 16 + j];
                golden_val = histogram_0[i * 16 + j];
                golden_position = largest_position_0+1;
                histogram_num = 0;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    if(dram_val !== golden_position)begin
						WIRTE_WRONG_ANS;
						distance_wrong_task;
					end
                end
            end
        end
		
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 1 * 16 * 16 + i * 16 + j];
                golden_val = histogram_1[i * 16 + j];
                golden_position = largest_position_1+1;
                histogram_num = 1;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)	begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end 
                end
                else begin
                    if(dram_val !== golden_position)begin
						WIRTE_WRONG_ANS;
						distance_wrong_task;
					end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 2 * 16 * 16 + i * 16 + j];
                golden_val = histogram_2[i * 16 + j];
                golden_position = largest_position_2+1;
                histogram_num = 2;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    if(dram_val !== golden_position)begin
						WIRTE_WRONG_ANS;
						distance_wrong_task;
					end
				end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 3 * 16 * 16 + i * 16 + j];
                golden_val = histogram_3[i * 16 + j];
                golden_position = largest_position_3+1;
                histogram_num = 3;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    if(dram_val !== golden_position)begin
						WIRTE_WRONG_ANS;
						distance_wrong_task;
					end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 4 * 16 * 16 + i * 16 + j];
                golden_val = histogram_4[i * 16 + j];
                golden_position = largest_position_4+1;
                histogram_num = 4;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    if(dram_val !== golden_position)begin
						WIRTE_WRONG_ANS;
						distance_wrong_task;
					end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 5 * 16 * 16 + i * 16 + j];
                golden_val = histogram_5[i * 16 + j];
                golden_position = largest_position_5+1;
                histogram_num = 5;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    if(dram_val !== golden_position)begin
						WIRTE_WRONG_ANS;
						distance_wrong_task;
					end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 6 * 16 * 16 + i * 16 + j];
                golden_val = histogram_6[i * 16 + j];
                golden_position = largest_position_6+1;
                histogram_num = 6;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    if(dram_val !== golden_position)begin
						WIRTE_WRONG_ANS;
						distance_wrong_task;
					end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 7 * 16 * 16 + i * 16 + j];
                golden_val = histogram_7[i * 16 + j];
                golden_position = largest_position_7+1;
                histogram_num = 7;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    if(dram_val !== golden_position)begin
						WIRTE_WRONG_ANS;
						distance_wrong_task;
					end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 8 * 16 * 16 + i * 16 + j];
                golden_val = histogram_8[i * 16 + j];
                golden_position = largest_position_8+1;
                histogram_num = 8;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    if(dram_val !== golden_position)begin
						WIRTE_WRONG_ANS;
						distance_wrong_task;
					end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 9 * 16 * 16 + i * 16 + j];
                golden_val = histogram_9[i * 16 + j];
                golden_position = largest_position_9+1;
                histogram_num = 9;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    if(dram_val !== golden_position)begin
						WIRTE_WRONG_ANS;
						distance_wrong_task;
					end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 10 * 16 * 16 + i * 16 + j];
                golden_val = histogram_10[i * 16 + j];
                golden_position = largest_position_10+1;
                histogram_num = 10;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    if(dram_val !== golden_position)begin
						WIRTE_WRONG_ANS;
						distance_wrong_task;
					end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 11 * 16 * 16 + i * 16 + j];
                golden_val = histogram_11[i * 16 + j];
                golden_position = largest_position_11+1;
                histogram_num = 11;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    if(dram_val !== golden_position)begin
						WIRTE_WRONG_ANS;
						distance_wrong_task;
					end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 12 * 16 * 16 + i * 16 + j];
                golden_val = histogram_12[i * 16 + j];
                golden_position = largest_position_12+1;
                histogram_num = 12;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    if(dram_val !== golden_position)begin
						WIRTE_WRONG_ANS;
						distance_wrong_task;
					end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 13 * 16 * 16 + i * 16 + j];
                golden_val = histogram_13[i * 16 + j];
                golden_position = largest_position_13+1;
                histogram_num = 13;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    if(dram_val !== golden_position)begin
						WIRTE_WRONG_ANS;
						distance_wrong_task;
					end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 14 * 16 * 16 + i * 16 + j];
                golden_val = histogram_14[i * 16 + j];
                golden_position = largest_position_14+1;
                histogram_num = 14;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    if(dram_val !== golden_position)begin
						WIRTE_WRONG_ANS;
						distance_wrong_task;
					end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 15 * 16 * 16 + i * 16 + j];
                golden_val = histogram_15[i * 16 + j];
                golden_position = largest_position_15+1;
                histogram_num = 15;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    if(dram_val !== golden_position)begin
						WIRTE_WRONG_ANS;
						distance_wrong_task;
					end
                end
            end
        end
    end endtask

	task histogram_wrong_task; begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                        FAIL!                                                               ");
        $display ("                                                            Histogram data at frame_id: %d                                                 ",frame_id_reg);
		$display ("                                                            Histogram : %d                                                                 ",histogram_num);
		$display ("                                                            Golden answer: %d                                                              ",golden_val);
		$display ("                                                            Your   answer: %d                                                              ",dram_val);
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            
        #(10*`CYCLE_TIME);
        $finish;
	end endtask

	task distance_wrong_task; begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                        FAIL!                                                               ");
        $display ("                                                            Histogram distance at frame_id: %d                                             ",frame_id_reg);
		$display ("                                                            Histogram : %d                                                                 ",histogram_num);
		$display ("                                                  		   Golden answer: %d                                                              ",golden_position);
		$display ("                                                  		   Your   answer: %d                                                              ",dram_val);
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            
        #(10*`CYCLE_TIME);
        $finish;
	end endtask

    task YOU_pass_task; begin
        $display ("----------------------------------------------------------------------------------------------------------------------");
        $display ("                                                  Congratulations!                						            ");
        $display ("                                           You have pased all patterns!          						            ");
        $display ("                                           Your execution latency = %5d cycles   						            ", total_cycles);
        $display ("                                           Your clock period = %.1f ns        					                ", `CYCLE_TIME);
        $display ("                                           Your total latency = %.1f ns         						            ", total_cycles*`CYCLE_TIME);
        $display ("----------------------------------------------------------------------------------------------------------------------");
        $finish;

    end endtask
	
	task WIRTE_WRONG_ANS; begin
		$fwrite(output_file, "frame_id:%d, histogram:%d \n",frame_id_reg,histogram_num);
		$fwrite(output_file, "Golden position:%d\n",golden_position);
		$fwrite(output_file, "ANS:\n");
		case(histogram_num)
		0:begin
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",histogram_0[i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
			$fwrite(output_file, "\nYOUR DRAM:\n");
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 0 * 16 * 16 + i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end 
		end
		1:begin
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",histogram_1[i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
			$fwrite(output_file, "\nYOUR DRAM:\n");
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 1 * 16 * 16 + i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
		end
		2:begin
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",histogram_2[i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
			$fwrite(output_file, "\nYOUR DRAM:\n");
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 2 * 16 * 16 + i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
		end
		3:begin
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",histogram_3[i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
			$fwrite(output_file, "\nYOUR DRAM:\n");
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 3 * 16 * 16 + i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
		end
		4:begin
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",histogram_4[i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
			$fwrite(output_file, "\nYOUR DRAM:\n");
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 4 * 16 * 16 + i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
		end
		5:begin
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",histogram_5[i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
			$fwrite(output_file, "\nYOUR DRAM:\n");
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 5 * 16 * 16 + i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
		end
		6:begin
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",histogram_6[i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
			$fwrite(output_file, "\nYOUR DRAM:\n");
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 6 * 16 * 16 + i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
		end
		7:begin
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",histogram_7[i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
			$fwrite(output_file, "\nYOUR DRAM:\n");
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 7 * 16 * 16 + i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
		end
		8:begin
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",histogram_8[i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
			$fwrite(output_file, "\nYOUR DRAM:\n");
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 8 * 16 * 16 + i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
		end
		9:begin
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",histogram_9[i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
			$fwrite(output_file, "\nYOUR DRAM:\n");
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 9 * 16 * 16 + i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
		end
		10:begin
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",histogram_10[i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
			$fwrite(output_file, "\nYOUR DRAM:\n");
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 10 * 16 * 16 + i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
		end
		11:begin
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",histogram_11[i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
			$fwrite(output_file, "\nYOUR DRAM:\n");
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 11 * 16 * 16 + i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
		end
		12:begin
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",histogram_12[i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
			$fwrite(output_file, "\nYOUR DRAM:\n");
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 12 * 16 * 16 + i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
		end
		13:begin
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",histogram_13[i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
			$fwrite(output_file, "\nYOUR DRAM:\n");
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 13 * 16 * 16 + i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
		end
		14:begin
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",histogram_14[i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
			$fwrite(output_file, "\nYOUR DRAM:\n");
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 14 * 16 * 16 + i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
		end
		15:begin
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",histogram_15[i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
			$fwrite(output_file, "\nYOUR DRAM:\n");
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					$fwrite(output_file, "%d ",u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 15 * 16 * 16 + i * 16 + j]);
				end
					$fwrite(output_file, "\n");
			end
		end
		endcase
	end endtask
endmodule
