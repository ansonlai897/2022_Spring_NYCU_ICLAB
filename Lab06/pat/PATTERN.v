//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifdef RTL_TOP
    `define CYCLE_TIME 28.0
`endif

`ifdef GATE_TOP
    `define CYCLE_TIME 28.0
`endif

module PATTERN (
    // Output signals
    clk, rst_n, in_valid,
    in_p, in_q, in_e, in_c,
    // Input signals
    out_valid, out_m
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
output reg clk, rst_n, in_valid;
output reg [3:0] in_p, in_q;
output reg [7:0] in_e, in_c;
input out_valid;
input [7:0] out_m;

// ===============================================================
// Parameter & Integer Declaration
// ===============================================================
real CYCLE = `CYCLE_TIME;

parameter PATNUM = 1000;

integer prime[0:5];
integer SEED = 120;
integer patcount;
integer i,j,a,b,c,f,Eu_N,e,N,g,h,k,x,gap,y,t,u;
integer lat, total_latency;
integer plaintext[0:7];
//integer ciphertext[0:7];

//================================================================
// Wire & Reg Declaration
//================================================================
reg [7:0] ccc;
//================================================================
// Clock
//================================================================
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

//================================================================
// Initial
//================================================================
initial 
begin
	
	prime[0] = 2;
	prime[1] = 3;
	prime[2] = 5;
	prime[3] = 7;
	prime[4] = 11;
	prime[5] = 13;
	
	rst_n = 1'b1;
	in_valid = 1'b0;
	total_latency=0;
	
	force clk = 0;
	reset_signal_task;
	
	for(patcount=1; patcount<=PATNUM; patcount=patcount+1) begin
		input_task;
		wait_out_valid;
		check_ans;
		
		//$finish;
		
	end

	YOU_PASS_task;
end

//================================================================
// TASK
//================================================================
task reset_signal_task; begin 
  #(0.5);	rst_n=0;
  #(CYCLE/2);
  if((out_valid !== 0)||(out_m !== 0)) 
  begin
    $display("**************************************************************");
    $display("*   Output signal should be 0 after initial RESET at %4t     *",$time);
    $display("**************************************************************");
    $finish;
  end
  #(10);	rst_n=1;
  #(3);		release clk;
end 
endtask

task input_task; begin
	gap = $urandom_range(2,4);
	repeat(gap)@(negedge clk);
	i = 0;
	j = 0;
  
	while(i === j) begin
		i = $urandom_range(0,5);
		j = $urandom_range(0,5);
	end
	
	g = prime[i];
	h = prime[j];
	
	
	N = g*h;
	a = g - 1;
	b = h - 1;
	f=0;
	Eu_N = a*b;
	c = 0;
	while(c === 0)begin
		c = 1;
		e = $urandom_range(3,Eu_N);
		if(e % 2 == 0)
			c = 0;
		if((a == 6 || b == 6 || a == 12 || b == 12) && e % 3 == 0)
			c = 0;
		if((a == 10 || b == 10) && e % 5 == 0)
			c = 0;
	end
	
	//
	in_valid = 1'b1;
	for(k=0;k<8;k=k+1)begin
		if(k == 0)begin
			in_p = g;
			in_q = h;
			in_e = e;
		end
		else if(k == 1)begin
			in_p = 'bx;
			in_q = 'bx;
			in_e = 'bx;
		end
		plaintext[k] = $urandom_range(0,N-1);
		
		y = plaintext[k] % N;
		//y = y**e;
		u = 1;
		
		for(t=0;t<e;t=t+1)begin
			u = (u * y)%N;
		end
		
		in_c = u % N;
		@(negedge clk);
	end
	
	in_valid = 1'b0;
	in_c = 'bx;
	//@(negedge clk);

end endtask

task wait_out_valid; begin
  lat = 0;
  while(out_valid === 0) begin
	lat = lat + 1;
	if(lat === 10000) begin//wait limit
		$display("***************************************************************");
		$display("*     		    ICLAB_FAIL      							*");
		$display("*         The execution latency are over 10000 cycles.          *");
		$display("***************************************************************");
		repeat(2)@(negedge clk);
		$finish;
	end
	@(negedge clk);
  end
  total_latency = total_latency + lat;
end endtask

task check_ans; begin
	x = 0;
	while (out_valid === 1)begin
		if(x === 8)begin
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                  ICLAB_FAIL!                                                               ");
			$display ("                                       Outvalid is more than 8 cycles                                                   ");
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			repeat(2) @(negedge clk);
			$finish;
		end
	
		if(plaintext[x] !== out_m)begin
			ccc = plaintext[x];
			$display("----------------------------------------------------------------------------------------------------------------");
			$display("                    				Pattern No. %d ",patcount);
			$display("                    				P:          %d ",g);
			$display("                    				Q:          %d ",h);
			$display("                    				e:          %d ",e);
			$display("                    				Answer plaintext:   %d ",ccc);
			$display("                    				Your   plaintext:   %d ",out_m);
			$display("----------------------------------------------------------------------------------------------------------------");
			@(negedge clk);
			$finish;
		end
		x = x + 1;
		@(negedge clk);
	end
	
	if(x < 8)begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                  ICLAB_FAIL!                                                               ");
		$display ("                                       Outvalid is less than 8 cycles                                                   ");
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		repeat(2) @(negedge clk);
		$finish;
	end
	
	if(out_m !== 0)begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                  ICLAB_FAIL!                                                               ");
		$display ("                                Out_m should be reset after out_valid is pulled down                                                   ");
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		repeat(2) @(negedge clk);
		$finish;
	end
  
	$display("Pattern No.%d : %d cycles",patcount, lat);
	
end endtask


task YOU_PASS_task; begin
	$display ("----------------------------------------------------------------------------------------------------------------------");
	$display ("                                                  Congratulations!                						             ");
	$display ("                                           You have passed all patterns!          						             ");
	$display ("                                           Your execution cycles = %5d cycles   						                 ", total_latency);
	//$display ("                                           Your clock period = %.1f ns        					                     ", `CYCLE_TIME);
	//$display ("                                           Your total latency = %.1f ns         						                 ", total_latency*`CYCLE_TIME);
	$display ("----------------------------------------------------------------------------------------------------------------------");
	$finish;
end endtask
endmodule