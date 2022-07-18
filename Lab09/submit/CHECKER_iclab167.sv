//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//
//   File Name   : CHECKER.sv
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module Checker(input clk, INF.CHECKER inf);
import usertype::*;

//covergroup Spec1 @();
	
       //finish your covergroup here
	
	
//endgroup

//declare other cover group
covergroup Spec1 @(negedge clk iff inf.out_valid);
	option.at_least = 20;
       option.per_instance = 1;
	Stage: coverpoint inf.out_info[31:28]
       {	
	       bins stage_non  = {No_stage};
	       bins stage_Low  = {Lowest  };
	       bins stage_Mid  = {Middle  };
	       bins stage_High = {Highest };
	}
	Type: coverpoint inf.out_info[27:24]
       {	
		bins type_No	     = {No_type };
		bins type_Grass    = {Grass	  };
		bins type_Fire     = {Fire	  };
		bins type_Water    = {Water	  };
		bins type_Electric = {Electric};
        bins type_Normal   = {Normal  };
	}
endgroup

covergroup Spec2 @(posedge clk iff inf.id_valid);
	option.at_least = 1;
       option.per_instance = 1;
	Id: coverpoint inf.D.d_id[0]{
		option.auto_bin_max = 256;	
	}
endgroup

covergroup Spec3 @(posedge clk iff inf.act_valid);
	option.at_least = 10;
	option.per_instance = 1;
	Act: coverpoint inf.D.d_act[0]{
              bins trans_bins[] = (Buy, Sell, Deposit, Check, Use_item, Attack => Buy, Sell, Deposit, Check, Use_item, Attack);
       }
endgroup

covergroup Spec4 @(negedge clk iff inf.out_valid);
	option.at_least = 200;
	option.per_instance = 1;
	Complete: coverpoint inf.complete{
		bins complete_0 = {0};
		bins complete_1 = {1};
	}
endgroup

covergroup Spec5 @(negedge clk iff inf.out_valid);
	option.at_least = 20;
	option.per_instance = 1;
	Err: coverpoint inf.err_msg
       {
		bins error0 = {Already_Have_PKM};
		bins error1 = {Out_of_money};
		bins error2 = {Bag_is_full};
		bins error3 = {Not_Having_PKM};
		bins error4 = {Has_Not_Grown};
		bins error5 = {Not_Having_Item};
		bins error6 = {HP_is_Zero};
	}
endgroup

//declare the cover group 
//Spec1 cov_inst_1 = new();
Spec1 cov_inst_1 = new();
Spec2 cov_inst_2 = new();
Spec3 cov_inst_3 = new();
Spec4 cov_inst_4 = new();
Spec5 cov_inst_5 = new();

//************************************ below assertion is to check your pattern ***************************************** 
//                                          Please finish and hand in it
// This is an example assertion given by TA, please write the required assertions below
//  assert_interval : assert property ( @(posedge clk)  inf.out_valid |=> inf.id_valid == 0 [*2])
//  else
//  begin
//  	$display("Assertion X is violated");
//  	$fatal; 
//  end
wire #(0.5) rst_reg = inf.rst_n;
//write other assertions
//========================================================================================================================================================
// Assertion 1 ( All outputs signals (including pokemon.sv and bridge.sv) should be zero after reset.)
//========================================================================================================================================================

assert_1_pkm_1 : assert property ( @(negedge rst_reg)  inf.out_valid === 0 && inf.complete === 0 && inf.out_info === 0 && inf.err_msg === No_Err)
else
begin
	$display("Assertion 1 is violated");
	$fatal; 
end
assert_1_pkm_2 : assert property ( @(negedge rst_reg)  inf.C_addr === 0 && inf.C_data_w === 0 && inf.C_in_valid === 0 && inf.C_r_wb === 0)
else
begin
	$display("Assertion 1 is violated");
	$fatal; 
end

assert_1_bridge_1 : assert property ( @(negedge rst_reg) inf.C_out_valid === 0 && inf.C_data_r === 0 )
else
begin
	$display("Assertion 1 is violated");
	$fatal; 
end

assert_1_bridge_2 : assert property ( @(negedge rst_reg) inf.AR_VALID === 0 && inf.AR_ADDR === 0 && inf.R_READY === 0 && inf.AW_VALID === 0 )
else
begin
	$display("Assertion 1 is violated");
	$fatal; 
end

assert_1_bridge_3 : assert property ( @(negedge rst_reg) inf.AW_ADDR === 0 && inf.W_VALID === 0 && inf.W_DATA === 0 && inf.B_READY === 0 )
else
begin
	$display("Assertion 1 is violated");
	$fatal; 
end
//========================================================================================================================================================
// Assertion 2 ( If action is completed, err_msg should be 4’b0. )
//========================================================================================================================================================
assert_2_completed : assert property ( @(negedge clk) inf.complete === 1 && inf.out_valid === 1 |-> (inf.err_msg === No_Err))
else
begin
	$display("Assertion 2 is violated");
	$fatal; 
end
//========================================================================================================================================================
// Assertion 3 ( If action is not completed, out_info should be 64’b0. )
//========================================================================================================================================================
assert_3_not_completed : assert property ( @(negedge clk) inf.complete === 0 && inf.out_valid === 1 |-> (inf.out_info === 0))
else
begin
	$display("Assertion 3 is violated");
	$fatal; 
end
//========================================================================================================================================================
// Assertion 4 ( The gap between each input valid is at least 1 cycle and at most 5 cycles. )
//========================================================================================================================================================
Action act_reg;

always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		act_reg <= No_action;
	end else begin
		if(inf.act_valid) begin
			act_reg <= inf.D.d_act;
		end 
		else if(inf.out_valid == 1) begin
			act_reg <= No_action;
		end
	end
end

// start case
assert_4_start : assert property ( @(posedge clk) act_reg == No_action && inf.id_valid === 1 |-> ##[2:6] (inf.act_valid === 1) )
else
begin
	$display("Assertion 4 is violated");
	$fatal; 
end

// buy
assert_4_buy : assert property ( @(posedge clk) inf.act_valid === 1 && inf.D.d_act[0] == Buy |-> ##[2:6] (inf.type_valid === 1||inf.item_valid === 1) )
else
begin
	$display("Assertion 4 is violated");
	$fatal; 
end

// sell
assert_4_sell : assert property ( @(posedge clk) inf.act_valid === 1 && inf.D.d_act[0] == Sell |-> ##[2:6] (inf.type_valid === 1||inf.item_valid === 1) )
else
begin
	$display("Assertion 4 is violated");
	$fatal; 
end

// Use item
assert_4_use_item : assert property ( @(posedge clk) inf.act_valid === 1 && inf.D.d_act[0] == Use_item |-> ##[2:6] (inf.item_valid === 1) )
else
begin
	$display("Assertion 4 is violated");
	$fatal; 
end

// Attack
assert_4_atk : assert property ( @(posedge clk) inf.act_valid === 1 && inf.D.d_act[0] == Attack |-> ##[2:6] (inf.id_valid === 1) )
else
begin
	$display("Assertion 4 is violated");
	$fatal; 
end

// Deposit
assert_4_deposit : assert property ( @(posedge clk) inf.act_valid === 1 && inf.D.d_act[0] == Deposit |-> ##[2:6] (inf.amnt_valid === 1) )
else
begin
	$display("Assertion 4 is violated");
	$fatal; 
end


//========================================================================================================================================================
// Assertion 5 ( All input valid signals won’t overlap with each other. )
//========================================================================================================================================================
assert_5 : assert property ( @(posedge clk)  (inf.id_valid + inf.act_valid + inf.item_valid + inf.type_valid + inf.amnt_valid) < 2)
else
begin
	$display("Assertion 5 is violated");
	$fatal; 
end

//========================================================================================================================================================
// Assertion 6 ( Out_valid can only be high for exactly one cycle. )
//========================================================================================================================================================
assert_6_outvalid :  assert property( @(posedge clk) inf.out_valid === 1 |=> inf.out_valid === 0 )
else begin
	$display("Assertion 6 is violated");
	$fatal; 
end
//========================================================================================================================================================
// Assertion 7 ( Next operation will be valid 2-10 cycles after out_valid fall. )
//========================================================================================================================================================
reg flag_out;
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		flag_out <= 0;
	end else begin
		if(inf.out_valid) begin
			flag_out <= 1;
		end 
		else if(flag_out && (inf.id_valid||inf.act_valid)) begin
			flag_out <= 0;
		end
	end
end

assert_7 : assert property ( @(posedge clk) (inf.out_valid) |-> ##[2:10] flag_out && (inf.id_valid || inf.act_valid))
else
begin
	$display("Assertion 7 is violated");
	$fatal; 
end
//========================================================================================================================================================
// Assertion 8 ( Latency should be less than 1200 cycles for each operation. )
//========================================================================================================================================================
// buy
assert_8_buy : assert property ( @(posedge clk) inf.act_valid === 1 && inf.D.d_act[0] == Buy |-> ##[2:6] (inf.type_valid === 1||inf.item_valid === 1) ##[1:1201] (inf.out_valid) ) 
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

// sell
assert_8_sell : assert property ( @(posedge clk) inf.act_valid === 1 && inf.D.d_act[0] == Sell |-> ##[2:6] (inf.type_valid === 1||inf.item_valid === 1) ##[1:1201] (inf.out_valid) ) 
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

// Use item
assert_8_use_item : assert property ( @(posedge clk) inf.act_valid === 1 && inf.D.d_act[0] == Use_item |-> ##[2:6] (inf.item_valid === 1) ##[1:1201] (inf.out_valid) ) 
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

// Attack
assert_8_atk : assert property ( @(posedge clk) inf.act_valid === 1 && inf.D.d_act[0] == Attack |-> ##[2:6] (inf.id_valid === 1) ##[1:1201] (inf.out_valid) ) 
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

// Deposit
assert_8_deposit : assert property ( @(posedge clk) inf.act_valid === 1 && inf.D.d_act[0] == Deposit |-> ##[2:6] (inf.amnt_valid === 1) ##[1:1201] (inf.out_valid) ) 
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

// Check
assert_8_check : assert property ( @(posedge clk) inf.act_valid === 1 && inf.D.d_act[0] == Check |-> ##[1:1201] (inf.out_valid) ) 
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

endmodule