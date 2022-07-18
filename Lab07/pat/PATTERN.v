`ifdef RTL
	`timescale 1ns/1ps
	`define CYCLE_TIME_clk1 16
	`define CYCLE_TIME_clk2 15
`endif
`ifdef GATE
	`timescale 1ns/1ps
	`define CYCLE_TIME_clk1 16
	`define CYCLE_TIME_clk2 15
`endif


module PATTERN #(parameter DSIZE = 8,
			   parameter ASIZE = 4)(
	//Output Port
	rst_n,
	clk1,
    clk2,
	in_valid,
	in_account,
	in_A,
	in_T,

    //Input Port
	ready,
    out_valid,
	out_account
); 
//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg				rst_n, clk1, clk2, in_valid;
output reg [DSIZE-1:0] 	in_account,in_A,in_T;

input 				ready, out_valid;
input [DSIZE-1:0] 	out_account;

//================================================================
// parameters & integer
//================================================================
real CYCLE_TIME_clk1 = `CYCLE_TIME_clk1;
real CYCLE_TIME_clk2 = `CYCLE_TIME_clk2;

parameter PATNUM = 10;

integer a,b,c,d,input_file,output_file,i;
integer lat, total_latency;
integer patcount,incount,outcount;
integer account, areas, times; 
reg start;
reg [DSIZE-1:0 ]gold_ans[0:3995];
reg [DSIZE-1:0 ]temp_ans[0:3995];
//================================================================
// clock
//================================================================
initial begin
	clk1 = 0; 
	clk2 = 0;
end 
always #(CYCLE_TIME_clk2/2.0) clk2 = ~clk2;
always #(CYCLE_TIME_clk1/2.0) clk1 = ~clk1;

always @(posedge clk2) begin
	if(out_valid===1)begin
		temp_ans[outcount] = out_account;
		outcount = outcount+1'b1;	
	end 
	else begin
		outcount = outcount+1'b0;
	end 
end

always @(posedge clk2) begin
	if(start===1)begin
		lat = lat+1'b1;
		if(lat>100000)begin
		$display ("-------------------------------------------------------------------");
		$display ("                        latency too long!                        ");
		$display ("-------------------------------------------------------------------");    
		$finish;	
		end
	end 
	else begin
		lat = lat;
	end 
end
//================================================================
// initial
//================================================================
initial begin

    rst_n    = 1'b1;
    in_valid = 1'b0;
	in_account = 'bx;
	lat = 0;
	in_A ='bx;
	in_T ='bx;
	start = 0;
    total_latency = 0;
	incount = 0;
	outcount = 0;
    force clk1 = 0;
	force clk2 = 0;
    reset_task;
	@(negedge clk1);	
    input_file=$fopen("../00_TESTBED/input.txt","r");
	output_file=$fopen("../00_TESTBED/output.txt","r");
	for (i =0 ;i<3996 ;i=i+1 ) begin
		a= $fscanf(output_file,"%d",gold_ans[i]);
	end
	input_task;
	check_ans;


    YOU_PASS_task;
end


//================================================================
// task
//================================================================
task reset_task ; begin
	#(10); rst_n = 0;
	#(10);
	if((ready !== 0)||(out_valid !== 0) || (out_account!==0 ))begin
		$display ("-------------------------------------------------------------------");
        $display("                  \033[0;34m output signal should reset\033[m            ");
		$display ("-------------------------------------------------------------------");
        $finish;
    end 
	#(10); rst_n = 1 ;
	#(10); 
	release clk1;
	release clk2;
	#(10); 
end endtask

task input_task; begin
	
	while (incount<4000)begin


		if(incount == 1000||incount == 2000 ||incount == 3995)begin
			repeat(150)@(negedge clk1);
		end 

		if(ready === 1)begin
			a = $fscanf(input_file,"%d",account);
			b = $fscanf(input_file,"%d",areas);
			c = $fscanf(input_file,"%d",times);
			
			in_valid = 1'b1;
			start =1;
			in_account = account;
			in_A = areas;
			in_T = times;
			@(negedge clk1);
			in_valid = 1'b0;

			in_account = 'bx;
			in_A ='bx;
			in_T ='bx;

			incount = incount + 1;
		end
		else begin
			@(negedge clk1);	
		end

		
		
	end 

	while(outcount<3996)begin
		@(negedge clk2);
	end
	if(outcount == 3996)start = 0;
end endtask

task check_ans; begin
	for(i=0;i<3996;i=i+1)begin
		if(gold_ans[i]!==temp_ans[i])begin
			$display ("-------------------------------------------------------------------");
			$display ("                        No.%d wrong!                             ",i+1);
			$display ("		Your output:%d ; Golden output:%d               ",temp_ans[i],gold_ans[i]);  
			$display ("-------------------------------------------------------------------");    
			$finish;
		end
	end
end endtask

task YOU_PASS_task; begin
    $display ("-------------------------------------------------------------------");
    $display ("             \033[0;34m            Congratulations!     \033[m                      ");
    $display ("              \033[0;34m     You have passed all inputs!  \033[m                   ");
	$display ("              \033[0;34m        clk1:%dns  \033[m            ",CYCLE_TIME_clk1);
	$display ("              \033[0;34m        clk2:%dns  \033[m            ",CYCLE_TIME_clk2);
    $display ("              \033[0;34m      Total latency: %d         \033[m ",lat);
    $display ("-------------------------------------------------------------------");    
    $finish;	
end endtask

endmodule 