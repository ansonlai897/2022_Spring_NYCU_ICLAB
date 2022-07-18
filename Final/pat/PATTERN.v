`ifdef RTL
	`timescale 1ns/100ps
	`include "TOF.v"
    `define CYCLE_TIME 8.0
`endif
`ifdef GATE
	`timescale 1ns/100ps
	`include "TOF_SYN.v"
    `define CYCLE_TIME 4.2
`endif
`ifdef POST
	`timescale 1ns/10ps
	`include "CHIP.v"
    `define CYCLE_TIME 8.0
`endif

`include "../00_TESTBED/pseudo_DRAM.v"

module PATTERN #(parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32)(
    // CHIP IO 
    clk,    
    rst_n,    
    in_valid,    
    start,
    stop,
    inputtype,
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
output reg              clk, rst_n;
output reg              in_valid;
output reg              start;
output reg [15:0]       stop;     
output reg [1:0]        inputtype; 
output reg [4:0]        frame_id;
input                   busy;       

// << AXI Interface wire connecttion for pseudo DRAM read/write >>
// (1)     axi write address channel 
//         src master
input wire [ID_WIDTH-1:0]      awid_s_inf;
input wire [ADDR_WIDTH-1:0]  awaddr_s_inf;
input wire [2:0]             awsize_s_inf;
input wire [1:0]            awburst_s_inf;
input wire [7:0]              awlen_s_inf;
input wire                  awvalid_s_inf;
//         src slave
output wire                 awready_s_inf;
// -----------------------------

// (2)    axi write data channel 
//         src master
input wire [DATA_WIDTH-1:0]   wdata_s_inf;
input wire                    wlast_s_inf;
input wire                   wvalid_s_inf;
//         src slave
output wire                  wready_s_inf;

// (3)    axi write response channel 
//         src slave
output wire  [ID_WIDTH-1:0]     bid_s_inf;
output wire  [1:0]            bresp_s_inf;
output wire                  bvalid_s_inf;
//         src master 
input wire                   bready_s_inf;
// -----------------------------

// (4)    axi read address channel 
//         src master
input wire [ID_WIDTH-1:0]      arid_s_inf;
input wire [ADDR_WIDTH-1:0]  araddr_s_inf;
input wire [7:0]              arlen_s_inf;
input wire [2:0]             arsize_s_inf;
input wire [1:0]            arburst_s_inf;
input wire                  arvalid_s_inf;
//         src slave
output wire                 arready_s_inf;
// -----------------------------

// (5)    axi read data channel 
//         src slave
output wire [ID_WIDTH-1:0]      rid_s_inf;
output wire [DATA_WIDTH-1:0]  rdata_s_inf;
output wire [1:0]             rresp_s_inf;
output wire                   rlast_s_inf;
output wire                  rvalid_s_inf;
//         src master
input wire                   rready_s_inf;


// -------------------------//
//     DRAM Connection      //
//--------------------------//

pseudo_DRAM u_DRAM(
    .clk(clk),
    .rst_n(rst_n),

    .   awid_s_inf(   awid_s_inf),
    . awaddr_s_inf( awaddr_s_inf),
    . awsize_s_inf( awsize_s_inf),
    .awburst_s_inf(awburst_s_inf),
    .  awlen_s_inf(  awlen_s_inf),
    .awvalid_s_inf(awvalid_s_inf),
    .awready_s_inf(awready_s_inf),

    .  wdata_s_inf(  wdata_s_inf),
    .  wlast_s_inf(  wlast_s_inf),
    . wvalid_s_inf( wvalid_s_inf),
    . wready_s_inf( wready_s_inf),

    .    bid_s_inf(    bid_s_inf),
    .  bresp_s_inf(  bresp_s_inf),
    . bvalid_s_inf( bvalid_s_inf),
    . bready_s_inf( bready_s_inf),

    .   arid_s_inf(   arid_s_inf),
    . araddr_s_inf( araddr_s_inf),
    .  arlen_s_inf(  arlen_s_inf),
    . arsize_s_inf( arsize_s_inf),
    .arburst_s_inf(arburst_s_inf),
    .arvalid_s_inf(arvalid_s_inf),
    .arready_s_inf(arready_s_inf), 

    .    rid_s_inf(    rid_s_inf),
    .  rdata_s_inf(  rdata_s_inf),
    .  rresp_s_inf(  rresp_s_inf),
    .  rlast_s_inf(  rlast_s_inf),
    . rvalid_s_inf( rvalid_s_inf),
    . rready_s_inf( rready_s_inf) 
);
// ===============================================================
// Parameter & Integer Declaration
// ===============================================================
    real CYCLE = `CYCLE_TIME;
    parameter PATNUM = 500;		//modify
    integer patcount;
    integer cycles, total_cycles;
    integer wait_gap;

    integer start_num;
    reg signed [20:0] i, j, k, newi, newj;
    integer rand_num;
    integer pixel[0:15] , pixel_center ; //aka distance of histogram
	integer output_file,input_file,a;
    integer   SEED         = 5200122;
    parameter SIZE = 256;
    integer hit0,hit1,hit2,hit3;
    integer t1count,t2count,t3count;
//================================================================
// Wire & Reg Declaration
//================================================================
    reg [7: 0] histogram_0	[0: SIZE - 1]; //histogram a.k.a. pixel
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

    reg [1:0] inputtype_reg;
	reg [4:0] frame_id_reg;

    reg [7:0] dram_val;
	reg [7:0] golden_val;
	reg [7:0] golden_position;
	reg [3:0] histogram_num;
    reg [4:0] pixel_hit_count;
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
        inputtype = 2'bx;
        frame_id = 5'bx;
        
        force clk = 0;
        total_cycles = 0;
	
        reset_task;
        hit0 = 0;
        hit1 = 0;
		hit2 = 0;
        hit3 = 0;
        t1count=0;
        t2count=0;
        t3count=0;
		output_file = $fopen("../00_TESTBED/error_pattern.txt","w");
		input_file  = $fopen("../00_TESTBED/golden_distance.txt","r");  
        @(negedge clk);
        
        for (patcount = 0; patcount < PATNUM; patcount = patcount + 1) begin
            if(patcount < 32)
                input_data_type0;
            else
                input_data_type123;
            wait_busy;
            
            check_ans;
            $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %3d\033[m", patcount ,cycles);
            total_cycles = total_cycles + cycles;
        end
        #(10*`CYCLE_TIME);
        if(hit0<512*0.5)begin
            $display ("                                        TYPE0        FAIL!      ACCURACY < 0.5                                 ");
            $finish;
        end
        else $display("Hit0 :",hit0,"/",16*32);
        
        if(hit1<t1count*8)begin
            $display ("                                        TYPE1        FAIL!      ACCURACY < 0.5                                 ");
            $finish;
        end
        else $display("Hit1 :",hit1,"/%d",t1count*16);
        
        $display("Hit2 :",hit2,"/%d",t2count*16);
        $display("Hit3 :",hit3,"/%d",t3count*16);
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

    task input_data_type0; begin
	
        wait_gap = $urandom_range(2, 4);
        repeat(wait_gap)@(negedge clk);
        in_valid = 1'b1;
        start = 0;
		stop = 0;
		
        frame_id  = patcount;	//0~31
        inputtype = 0       ;   
		

        start = 0;
		frame_id_reg = frame_id;
        inputtype_reg = inputtype;
		
		@(negedge clk);
		
		frame_id = 5'bx;
        in_valid = 0;
		start = 'bx;//here
		stop = 'bx;
        // update golden distance to pixels
        a = $fscanf(input_file,"%d" ,pixel[0]);	
        a = $fscanf(input_file,"%d" ,pixel[1]);
        a = $fscanf(input_file,"%d" ,pixel[2]);
        a = $fscanf(input_file,"%d" ,pixel[3]);
        a = $fscanf(input_file,"%d" ,pixel[4]);
        a = $fscanf(input_file,"%d" ,pixel[5]);	
        a = $fscanf(input_file,"%d" ,pixel[6]);
        a = $fscanf(input_file,"%d" ,pixel[7]);
        a = $fscanf(input_file,"%d" ,pixel[8]);
        a = $fscanf(input_file,"%d" ,pixel[9]);
        a = $fscanf(input_file,"%d" ,pixel[10]);	
        a = $fscanf(input_file,"%d" ,pixel[11]);
        a = $fscanf(input_file,"%d" ,pixel[12]);
        a = $fscanf(input_file,"%d" ,pixel[13]);
        a = $fscanf(input_file,"%d" ,pixel[14]);
        a = $fscanf(input_file,"%d" ,pixel[15]);			
        // update dram data to histograms 
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
    end endtask

    task input_data_type123; begin
        wait_gap = $urandom_range(2, 4);
        repeat(wait_gap)@(negedge clk);
        in_valid = 1'b1;
        start = 0;
		stop = 0;
		
        frame_id  = $urandom_range(0, 31);	//modify
        inputtype = $urandom_range(1, 3);   //modify  
		start_num = (inputtype == 1) ? 4 : 7;
        if(inputtype_reg==1)t1count = t1count+1;
        else if(inputtype_reg==2)t2count = t2count+1;
        else t3count = t3count+1;
        start = 0;
		frame_id_reg = frame_id;
        inputtype_reg = inputtype;

        @(negedge clk);
        frame_id  = 5'bx;
        inputtype = 2'bx;
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
        //==========================================
        //  assign pixel start
        //==========================================

        if(inputtype_reg == 1) begin
            pixel[0] = $urandom_range(1, 251);
            pixel[1] = pixel[0]; pixel[4] = pixel[0]; pixel[5] = pixel[0];
            pixel[2] = $urandom_range(1, 251);
            pixel[3] = pixel[2]; pixel[6] = pixel[2]; pixel[7] = pixel[2];
            pixel[8] = $urandom_range(1, 251);
            pixel[9] = pixel[8]; pixel[12] = pixel[8]; pixel[13] = pixel[8];
            pixel[10] = $urandom_range(1, 251);
            pixel[11] = pixel[10]; pixel[14] = pixel[10]; pixel[15] = pixel[10];
            //pixel aka the distance of histogram
            // $display(pixel[0],pixel[1],pixel[2],pixel[3],pixel[4],pixel[5],pixel[6],pixel[7],pixel[8],pixel[9],pixel[10],pixel[11],pixel[12],pixel[13],pixel[14],pixel[15]);
        end
        else if (inputtype_reg == 2)begin
            pixel_center = $urandom_range(0 , 15);
            pixel[pixel_center] = $urandom_range(1, 221);                  
                i = pixel_center/4; j = pixel_center %4;
                //first propagate circle
                newi = i-1; newj = j-1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+5;
                newi = i-1; newj = j;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+5;
                newi = i-1; newj = j+1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+5;
                newi = i; newj = j-1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+5;
                newi = i; newj = j+1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+5;
                newi = i+1; newj = j-1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+5;
                newi = i+1; newj = j;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+5;
                newi = i+1; newj = j+1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+5;
                //second propagate circle
                newi = i-2; newj = j-2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+10;
                newi = i-2; newj = j-1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+10;
                newi = i-2; newj = j ;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+10;
                newi = i-2; newj = j+1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+10;
                newi = i-2; newj = j+2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+10;
                newi = i-1; newj = j-2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+10;
                newi = i-1; newj = j+2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+10;
                newi = i  ; newj = j-2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+10;
                newi = i  ; newj = j+2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+10;
                newi = i+1; newj = j-2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+10;
                newi = i+1; newj = j+2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+10;
                newi = i+2; newj = j-2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+10;
                newi = i+2; newj = j-1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+10;
                newi = i+2; newj = j;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+10;
                newi = i+2; newj = j+1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+10;
                newi = i+2; newj = j+2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+10;
                //third propagate circle
                newi = i-3; newj = j-3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i-3; newj = j-2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i-3; newj = j-1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i-3; newj = j;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i-3; newj = j+1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i-3; newj = j+2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i-3; newj = j+3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;

                newi = i-2; newj = j-3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i-2; newj = j+3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i-1; newj = j-3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i+1; newj = j+3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i  ; newj = j-3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i  ; newj = j+3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i+1 ; newj = j-3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i+1 ; newj = j+3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i+2; newj = j-3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i+2; newj = j+3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                
                newi = i+3; newj = j-3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i+3; newj = j-2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i+3; newj = j-1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i+3; newj = j;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i+3; newj = j+1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i+3; newj = j+2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
                newi = i+3; newj = j+3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]+15;
        end
        else if (inputtype_reg == 3)begin
            pixel_center = $urandom_range(0 , 15);
            pixel[pixel_center] = $urandom_range(1, 236);          
                i = pixel_center/4; j = pixel_center %4;
                //first propagate circle
                newi = i-1; newj = j-1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-5;
                newi = i-1; newj = j;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-5;
                newi = i-1; newj = j+1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-5;
                newi = i; newj = j-1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-5;
                newi = i; newj = j+1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-5;
                newi = i+1; newj = j-1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-5;
                newi = i+1; newj = j;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-5;
                newi = i+1; newj = j+1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-5;
                //second propagate circle
                newi = i-2; newj = j-2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-10;
                newi = i-2; newj = j-1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-10;
                newi = i-2; newj = j ;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-10;
                newi = i-2; newj = j+1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-10;
                newi = i-2; newj = j+2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-10;
                newi = i-1; newj = j-2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-10;
                newi = i-1; newj = j+2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-10;
                newi = i  ; newj = j-2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-10;
                newi = i  ; newj = j+2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-10;
                newi = i+1; newj = j-2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-10;
                newi = i+1; newj = j+2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-10;
                newi = i+2; newj = j-2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-10;
                newi = i+2; newj = j-1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-10;
                newi = i+2; newj = j;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-10;
                newi = i+2; newj = j+1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-10;
                newi = i+2; newj = j+2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-10;
                //third propagate circle
                newi = i-3; newj = j-3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i-3; newj = j-2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i-3; newj = j-1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i-3; newj = j;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i-3; newj = j+1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i-3; newj = j+2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i-3; newj = j+3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;

                newi = i-2; newj = j-3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i-2; newj = j+3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i-1; newj = j-3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i+1; newj = j+3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i  ; newj = j-3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i  ; newj = j+3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i+1 ; newj = j-3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i+1 ; newj = j+3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i+2; newj = j-3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i+2; newj = j+3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                
                newi = i+3; newj = j-3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i+3; newj = j-2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i+3; newj = j-1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i+3; newj = j;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i+3; newj = j+1;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i+3; newj = j+2;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
                newi = i+3; newj = j+3;
                if(newi >= 0 && newi <= 3 && newj >= 0 && newj <= 3)
                    pixel[newi*4 + newj] = pixel[pixel_center]-15;
            
        end
        //========================================
        //   assign pixel end
        //========================================
        
        //========================================
        //   generate start and stop signal 
        //========================================
        for (i = 0; i < start_num; i = i + 1)begin
            wait_gap = $urandom_range(3, 8);
            repeat(wait_gap)@(negedge clk);

            for (j = 0; j < SIZE - 1; j = j + 1)begin //j=bin,  0~254
                start = 1;

                //generates 16 bits stop
                for( k = 0; k < 16 ; k = k +1 )begin //k = which histogram
                    //rand_num = $urandom_range(0, 60000);
                    // rand_num = {$random(SEED)}%10;
                    if(pixel[k] == j) begin
                        if(inputtype_reg == 1)
                            stop[k] = ( {$random(SEED)}%10 < 6 ) ? 1 : 0;
                        else  // type = 2 or 3
                            stop[k] = ( {$random(SEED)}%10 < 4 ) ? 1 : 0;
                    end
                    else if (pixel[k]+1 == j)begin
                        if(inputtype_reg == 1)
                            stop[k] = ( {$random(SEED)}%10 < 3 ) ? 1 : 0;
                        else  // type = 2 or 3
                            stop[k] = ( {$random(SEED)}%10 < 7 ) ? 1 : 0;
                    end
                    else if (pixel[k]+2 == j)begin
                        if(inputtype_reg == 1)
                            stop[k] = ( {$random(SEED)}%10 < 6 ) ? 1 : 0;
                        else  // type = 2 or 3
                            stop[k] = ( {$random(SEED)}%10 < 6 ) ? 1 : 0;
                    end
                    else if (pixel[k]+3 == j)begin
                        if(inputtype_reg == 1)
                            stop[k] = ( {$random(SEED)}%10 < 3 ) ? 1 : 0;
                        else  // type = 2 or 3
                            stop[k] = ( {$random(SEED)}%10 < 5 ) ? 1 : 0;
                    end
                    else if (pixel[k]+4 == j)begin
                        if(inputtype_reg == 1)
                            stop[k] = ( {$random(SEED)}%10 < 6 ) ? 1 : 0;
                        else  // type = 2 or 3
                            stop[k] = ( {$random(SEED)}%10 < 4 ) ? 1 : 0;
                    end
                    else begin
                        stop[k] = ( {$random(SEED)}%10 < 3 ) ? 1 : 0;
                    end
                end 
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
        in_valid = 0;
		start = 'bx;//here
		stop = 'bx;
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

    task check_ans; begin
        pixel_hit_count = 0;
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 0 * 16 * 16 + i * 16 + j]; //user dram data
                golden_val = histogram_0[i * 16 + j]; // golden dram data
                golden_position = pixel[0]; // golden distance bin
                histogram_num = 0; 
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                    
                end
                else begin
                    // $display ("                                                  		   Golden answer: %d                                                              ",golden_position);
		            // $display ("                                                  		   Your   answer: %d                                                              ",dram_val);

                    if(dram_val <= (golden_position + 3) && dram_val >= (golden_position - 3)  )begin
                        pixel_hit_count = pixel_hit_count + 1;
					end
                    else if (golden_position <= 2 && dram_val <= (golden_position + 3)) begin //because 2-3 = -1 will cause overflow
                        pixel_hit_count = pixel_hit_count + 1;
                    end
                    else begin
                        // accuracy_wrong_task;
                    end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 1 * 16 * 16 + i * 16 + j];
                golden_val = histogram_1[i * 16 + j];
                golden_position = pixel[1]; // golden distance bin
                histogram_num = 1;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)	begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end 
                end
                else begin
                    // $display ("                                                  		   Golden answer: %d                                                              ",golden_position);
		            // $display ("                                                  		   Your   answer: %d                                                              ",dram_val);
                    if(dram_val <= (golden_position + 3) && dram_val >= (golden_position - 3)  )begin
                        pixel_hit_count = pixel_hit_count + 1;
					end
                    else if (golden_position <= 2 && dram_val <= (golden_position + 3)) begin //because 2-3 = -1 will cause overflow
                        pixel_hit_count = pixel_hit_count + 1;
                    end
                    else begin
                        // accuracy_wrong_task;
                    end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 2 * 16 * 16 + i * 16 + j];
                golden_val = histogram_2[i * 16 + j];
                golden_position = pixel[2]; // golden distance bin
                histogram_num = 2;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    // $display ("                                                  		   Golden answer: %d                                                              ",golden_position);
		            // $display ("                                                  		   Your   answer: %d                                                              ",dram_val);
                    
                    if(dram_val <= (golden_position + 3) && dram_val >= (golden_position - 3)  )begin
                        pixel_hit_count = pixel_hit_count + 1;
					end
                    else if (golden_position <= 2 && dram_val <= (golden_position + 3)) begin //because 2-3 = -1 will cause overflow
                        pixel_hit_count = pixel_hit_count + 1;
                    end
                    else begin
                        // accuracy_wrong_task;
                    end
				end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 3 * 16 * 16 + i * 16 + j];
                golden_val = histogram_3[i * 16 + j];
                golden_position = pixel[3]; // golden distance bin
                histogram_num = 3;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    // $display ("                                                  		   Golden answer: %d                                                              ",golden_position);
		            // $display ("                                                  		   Your   answer: %d                                                              ",dram_val);
                    
                    if(dram_val <= (golden_position + 3) && dram_val >= (golden_position - 3)  )begin
                        pixel_hit_count = pixel_hit_count + 1;
					end
                    else if (golden_position <= 2 && dram_val <= (golden_position + 3)) begin //because 2-3 = -1 will cause overflow
                        pixel_hit_count = pixel_hit_count + 1;
                    end
                    else begin
                        // accuracy_wrong_task;
                    end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 4 * 16 * 16 + i * 16 + j];
                golden_val = histogram_4[i * 16 + j];
                golden_position = pixel[4]; // golden distance bin
                histogram_num = 4;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    // $display ("                                                  		   Golden answer: %d                                                              ",golden_position);
		            // $display ("                                                  		   Your   answer: %d                                                              ",dram_val);
                    
                    if(dram_val <= (golden_position + 3) && dram_val >= (golden_position - 3)  )begin
                        pixel_hit_count = pixel_hit_count + 1;
					end
                    else if (golden_position <= 2 && dram_val <= (golden_position + 3)) begin //because 2-3 = -1 will cause overflow
                        pixel_hit_count = pixel_hit_count + 1;
                    end
                    else begin
                        // accuracy_wrong_task;
                    end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 5 * 16 * 16 + i * 16 + j];
                golden_val = histogram_5[i * 16 + j];
                golden_position = pixel[5]; // golden distance bin
                histogram_num = 5;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    // $display ("                                                  		   Golden answer: %d                                                              ",golden_position);
		            // $display ("                                                  		   Your   answer: %d                                                              ",dram_val);
                    
                    if(dram_val <= (golden_position + 3) && dram_val >= (golden_position - 3)  )begin
                        pixel_hit_count = pixel_hit_count + 1;
					end
                    else if (golden_position <= 2 && dram_val <= (golden_position + 3)) begin //because 2-3 = -1 will cause overflow
                        pixel_hit_count = pixel_hit_count + 1;
                    end
                    else begin
                        // accuracy_wrong_task;
                    end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 6 * 16 * 16 + i * 16 + j];
                golden_val = histogram_6[i * 16 + j];
                golden_position = pixel[6]; // golden distance bin
                histogram_num = 6;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    // $display ("                                                  		   Golden answer: %d                                                              ",golden_position);
		            // $display ("                                                  		   Your   answer: %d                                                              ",dram_val);
                    
                    if(dram_val <= (golden_position + 3) && dram_val >= (golden_position - 3)  )begin
                        pixel_hit_count = pixel_hit_count + 1;
					end
                    else if (golden_position <= 2 && dram_val <= (golden_position + 3)) begin //because 2-3 = -1 will cause overflow
                        pixel_hit_count = pixel_hit_count + 1;
                    end
                    else begin
                        // accuracy_wrong_task;
                    end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 7 * 16 * 16 + i * 16 + j];
                golden_val = histogram_7[i * 16 + j];
                golden_position = pixel[7]; // golden distance bin
                histogram_num = 7;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    // $display ("                                                  		   Golden answer: %d                                                              ",golden_position);
		            // $display ("                                                  		   Your   answer: %d                                                              ",dram_val);
                    
                    if(dram_val <= (golden_position + 3) && dram_val >= (golden_position - 3)  )begin
                        pixel_hit_count = pixel_hit_count + 1;
					end
                    else if (golden_position <= 2 && dram_val <= (golden_position + 3)) begin //because 2-3 = -1 will cause overflow
                        pixel_hit_count = pixel_hit_count + 1;
                    end
                    else begin
                        // accuracy_wrong_task;
                    end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 8 * 16 * 16 + i * 16 + j];
                golden_val = histogram_8[i * 16 + j];
                golden_position = pixel[8]; // golden distance bin
                histogram_num = 8;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    // $display ("                                                  		   Golden answer: %d                                                              ",golden_position);
		            // $display ("                                                  		   Your   answer: %d                                                              ",dram_val);
                    
                    if(dram_val <= (golden_position + 3) && dram_val >= (golden_position - 3)  )begin
                        pixel_hit_count = pixel_hit_count + 1;
					end
                    else if (golden_position <= 2 && dram_val <= (golden_position + 3)) begin //because 2-3 = -1 will cause overflow
                        pixel_hit_count = pixel_hit_count + 1;
                    end
                    else begin
                        // accuracy_wrong_task;
                    end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 9 * 16 * 16 + i * 16 + j];
                golden_val = histogram_9[i * 16 + j];
                golden_position = pixel[9]; // golden distance bin
                histogram_num = 9;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    // $display ("                                                  		   Golden answer: %d                                                              ",golden_position);
		            // $display ("                                                  		   Your   answer: %d                                                              ",dram_val);
                    
                    if(dram_val <= (golden_position + 3) && dram_val >= (golden_position - 3)  )begin
                        pixel_hit_count = pixel_hit_count + 1;
					end
                    else if (golden_position <= 2 && dram_val <= (golden_position + 3)) begin //because 2-3 = -1 will cause overflow
                        pixel_hit_count = pixel_hit_count + 1;
                    end
                    else begin
                        // accuracy_wrong_task;
                    end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 10 * 16 * 16 + i * 16 + j];
                golden_val = histogram_10[i * 16 + j];
                golden_position = pixel[10]; // golden distance bin
                histogram_num = 10;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    // $display ("                                                  		   Golden answer: %d                                                              ",golden_position);
		            // $display ("                                                  		   Your   answer: %d                                                              ",dram_val);
                    
                    if(dram_val <= (golden_position + 3) && dram_val >= (golden_position - 3)  )begin
                        pixel_hit_count = pixel_hit_count + 1;
					end
                    else if (golden_position <= 2 && dram_val <= (golden_position + 3)) begin //because 2-3 = -1 will cause overflow
                        pixel_hit_count = pixel_hit_count + 1;
                    end
                    else begin
                        // accuracy_wrong_task;
                    end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 11 * 16 * 16 + i * 16 + j];
                golden_val = histogram_11[i * 16 + j];
                golden_position = pixel[11]; // golden distance bin
                histogram_num = 11;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    // $display ("                                                  		   Golden answer: %d                                                              ",golden_position);
		            // $display ("                                                  		   Your   answer: %d                                                              ",dram_val);
                    
                    if(dram_val <= (golden_position + 3) && dram_val >= (golden_position - 3)  )begin
                        pixel_hit_count = pixel_hit_count + 1;
					end
                    else if (golden_position <= 2 && dram_val <= (golden_position + 3)) begin //because 2-3 = -1 will cause overflow
                        pixel_hit_count = pixel_hit_count + 1;
                    end
                    else begin
                        // accuracy_wrong_task;
                    end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 12 * 16 * 16 + i * 16 + j];
                golden_val = histogram_12[i * 16 + j];
                golden_position = pixel[12]; // golden distance bin
                histogram_num = 12;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    // $display ("                                                  		   Golden answer: %d                                                              ",golden_position);
		            // $display ("                                                  		   Your   answer: %d                                                              ",dram_val);
                    
                    if(dram_val <= (golden_position + 3) && dram_val >= (golden_position - 3)  )begin
                        pixel_hit_count = pixel_hit_count + 1;
					end
                    else if (golden_position <= 2 && dram_val <= (golden_position + 3)) begin //because 2-3 = -1 will cause overflow
                        pixel_hit_count = pixel_hit_count + 1;
                    end
                    else begin
                        // accuracy_wrong_task;
                    end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 13 * 16 * 16 + i * 16 + j];
                golden_val = histogram_13[i * 16 + j];
                golden_position = pixel[13]; // golden distance bin
                histogram_num = 13;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    // $display ("                                                  		   Golden answer: %d                                                              ",golden_position);
		            // $display ("                                                  		   Your   answer: %d                                                              ",dram_val);
                    
                    if(dram_val <= (golden_position + 3) && dram_val >= (golden_position - 3)  )begin
                        pixel_hit_count = pixel_hit_count + 1;
					end
                    else if (golden_position <= 2 && dram_val <= (golden_position + 3)) begin //because 2-3 = -1 will cause overflow
                        pixel_hit_count = pixel_hit_count + 1;
                    end
                    else begin
                        // accuracy_wrong_task;
                    end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 14 * 16 * 16 + i * 16 + j];
                golden_val = histogram_14[i * 16 + j];
                golden_position = pixel[14]; // golden distance bin
                histogram_num = 14;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    // $display ("                                                  		   Golden answer: %d                                                              ",golden_position);
		            // $display ("                                                  		   Your   answer: %d                                                              ",dram_val);
                    
                    if(dram_val <= (golden_position + 3) && dram_val >= (golden_position - 3)  )begin
                        pixel_hit_count = pixel_hit_count + 1;
					end
                    else if (golden_position <= 2 && dram_val <= (golden_position + 3)) begin //because 2-3 = -1 will cause overflow
                        pixel_hit_count = pixel_hit_count + 1;
                    end
                    else begin
                        // accuracy_wrong_task;
                    end
                end
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                dram_val = u_DRAM.DRAM_r['h10000 + frame_id_reg * 16 * 16 * 16 + 15 * 16 * 16 + i * 16 + j];
                golden_val = histogram_15[i * 16 + j];
                golden_position = pixel[15]; // golden distance bin
                histogram_num = 15;
                if (i != 15 || j != 15) begin
                    if(dram_val !== golden_val)begin
						WIRTE_WRONG_ANS;
						histogram_wrong_task;
					end
                end
                else begin
                    // $display ("                                                  		   Golden answer: %d                                                              ",golden_position);
		            // $display ("                                                  		   Your   answer: %d                                                              ",dram_val);
                    
                    if(dram_val <= (golden_position + 3) && dram_val >= (golden_position - 3)  )begin
                        pixel_hit_count = pixel_hit_count + 1;
					end
                    else if (golden_position <= 2 && dram_val <= (golden_position + 3)) begin //because 2-3 = -1 will cause overflow
                        pixel_hit_count = pixel_hit_count + 1;
                    end
                    else begin
                        // accuracy_wrong_task;
                    end
                end
            end
        end
        $display("pixel_hit_count:",pixel_hit_count);
        if(inputtype_reg==2)hit2 = hit2 + pixel_hit_count;
        else if(inputtype_reg==3)hit3 = hit3 + pixel_hit_count;
        else if(inputtype_reg==0)hit0 = hit0+pixel_hit_count;
        else hit1 = hit1 + pixel_hit_count;

        // if( pixel_hit_count <= 7 && (inputtype_reg == 0 || inputtype_reg ==1))begin
        //     $display ("                                                           FAIL!      ACCURACY < 0.5                                 ");
        //     $finish;
        // end

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

    task accuracy_wrong_task; begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                            Accuracy fail message                                                               ");
        $display ("                                                            inputtype : %d                                                                  ",inputtype_reg);       
        $display ("                                                            Histogram distance at frame_id: %d                                             ",frame_id_reg);
		$display ("                                                            Histogram : %d                                                                 ",histogram_num);
		$display ("                                                  		   Golden answer: %d                                                              ",golden_position);
		$display ("                                                  		   Your   answer: %d                                                              ",dram_val);
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            
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

