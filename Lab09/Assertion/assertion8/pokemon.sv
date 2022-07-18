module pokemon(input clk, INF.pokemon_inf inf);
import usertype::*;
//===========================================================================
// state 
//===========================================================================
typedef enum logic  [5:0] { 
    IDLE_first     ,
    IDLE_else      ,
	RD_invalid     , // C_in_valid <= 1;
    RD_wait        , // wait C_out_valid = 1
    RD_store       , // store data rd from dram
    RD_set_atk     ,
    RD_invalid_atk ,
    RD_wait_atk    ,
    RD_store_atk   ,
    WR_set         ,
    WR_invalid     ,
    WR_wait        ,
    BUY_pkm        ,
    BUY_item       ,
    SELL_pkm       ,
    SELL_item      ,
    DEPOSIT        ,
    CHECK          ,
    USE_ITEM       ,
    ATTACK         ,
    WR_set_atk     ,
    WR_invalid_atk ,
    WR_wait_atk    ,
	OUTPUT		         
	}  state_t ;
state_t current_state, next_state;
//===========================================================================
// parameter 
//===========================================================================
parameter Read  = 1;
parameter Write = 0;
//===========================================================================
// logic 
//===========================================================================
Player_Info p1;
//PKM_Info opp;
Player_Info opp;


// input reg
Player_id   id_reg, id_opp_reg;
Action 		act_reg;
PKM_Type	p1_pkm_type_reg;
Item		item_reg;
Money       amnt_reg;

HP    pkm_max_hp;
EXP   pkm_max_exp, opp_max_exp;
ATK   pkm_base_atk, pkm_base_atk_reg;
logic [8:0]  damage;

// attack
EXP atk_reward_exp;
EXP def_reward_exp;

// buy price
Money pkm_price_buy;
Money item_price_buy;

// sell price
Money pkm_price_sell;
Money item_price_sell;

reg flag_bag_full;
reg flag_bag_empty;
logic[31:0] cnt;
logic[31:0] cnt_1;


reg flag_p1;
//===========================================================================
reg flag_id;
reg flag_opp_id;
reg flag_type;
reg flag_item;
reg flag_amnt;
reg flag_act;
reg flag_C_out;
//===========================================================================
// FSM 
//===========================================================================
//===================================================================================================
// INPUT REG   
//===================================================================================================
//===========================================================================
// flag_C_out   
//===========================================================================
//===========================================================================
// id_reg, id_opp_reg, flag_opp_id, flag_id
//===========================================================================
//===========================================================================
// act_reg, flag_act
//===========================================================================
// act_reg
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		act_reg <= No_action;
	end 
    else begin
		if(inf.act_valid) begin
			act_reg <= inf.D.d_act;
		end 
        else begin
            if(next_state == OUTPUT) 
			    act_reg <= No_action;
		end
	end
end

// flag_act
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		flag_act <= 0;
	end else begin
		if(inf.act_valid) begin
			flag_act <= 1;
		end
        else begin
            if(next_state == OUTPUT)
                flag_act <= 0;
        end
	end
end

//===========================================================================
// p1_pkm_type_reg, flag_type
//===========================================================================
//p1_pkm_type_reg
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		p1_pkm_type_reg <= No_type;
	end else begin
		if(inf.type_valid) begin
			case(inf.D.d_type)
				Grass	 : p1_pkm_type_reg <= Grass;
				Fire	 : p1_pkm_type_reg <= Fire	;
                Water	 : p1_pkm_type_reg <= Water;
				Electric : p1_pkm_type_reg <= Electric;
                Normal   : p1_pkm_type_reg <= Normal;
				default  : p1_pkm_type_reg <= No_type;
			endcase
		end
	end
end

//flag_type
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		flag_type <= 0;
	end else begin
		if(inf.type_valid) begin
			flag_type <= 1;
		end
        else begin
            if(next_state == OUTPUT)
                flag_type <= 0;
        end
	end
end

//===========================================================================
// item_reg, flag_item
//===========================================================================
// item_reg
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		item_reg <= No_item;
	end else begin
		if(inf.item_valid) begin
			case(inf.D.d_item)
				Berry	      : item_reg <= Berry;
				Medicine      : item_reg <= Medicine;
				Candy	      : item_reg <= Candy;
				Bracer	      : item_reg <= Bracer;
                Water_stone   : item_reg <= Water_stone;
                Fire_stone    : item_reg <= Fire_stone;
                Thunder_stone : item_reg <= Thunder_stone;
				default  : item_reg <= No_item;
			endcase
		end
	end
end

// flag_item
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		flag_item <= 0;
	end else begin
		if(inf.item_valid) begin
			flag_item <= 1;
		end
        else begin
            if(next_state == OUTPUT)
                flag_item <= 0;
        end
	end
end

//===========================================================================
// amnt_reg, flag_amnt
//===========================================================================
//===================================================================================================
// OUTPUT 
//===================================================================================================
//===========================================================================
// out_valid 
//===========================================================================
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		inf.out_valid <= 0;
        inf.C_addr <= 0;
        inf.C_data_w <= 0;
        inf.C_in_valid <= 0;
        inf.C_r_wb <= 0;
	end 
    else begin
        if(inf.out_valid) begin
            inf.out_valid <= 0;
        end
        if(act_reg == Buy) begin
            if(flag_type || flag_item) begin
            end
        end
        if(cnt == 1200)
            inf.out_valid <= 1;
        
	end
end

always_ff@(negedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
        cnt <= 0;
	end 
    else begin
        if(inf.out_valid) begin
            cnt <= 0;
        end
        if(act_reg == Buy) begin
            if(flag_type || flag_item) begin
                cnt <= cnt + 1;
            end
        end
        
    end
end
//===========================================================================
// complete, err_msg
//===========================================================================
/*
typedef enum logic  [3:0] { No_Err       		= 4'd0 ,
                            Already_Have_PKM	= 4'd1 ,
							Out_of_money		= 4'd2 ,
							Bag_is_full			= 4'd4 , 
							Not_Having_PKM	    = 4'd6 ,
						    Has_Not_Grown	    = 4'd8 ,
							Not_Having_Item		= 4'd10 ,
							HP_is_Zero			= 4'd13
							}  Error_Msg ;
*/
//===========================================================================
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.complete <= 0;
        inf.err_msg <= No_Err;
    end
    else begin
        case(next_state)
            IDLE_first, IDLE_else: begin
                inf.complete <= 1;
                inf.err_msg <= No_Err;
            end
            BUY_pkm: begin
                if(p1.bag_info.money < pkm_price_buy) begin
                    inf.complete <= 0;
                    inf.err_msg <= Out_of_money;
                end
                else if(p1.pkm_info != 0) begin
                    inf.complete <= 0;
                    inf.err_msg <= Already_Have_PKM;
                end     
            end
            BUY_item: begin
                if(p1.bag_info.money < item_price_buy) begin
                    inf.complete <= 0;
                    inf.err_msg <= Out_of_money;
                end
                else if(flag_bag_full) begin
                    inf.complete <= 0;
                    inf.err_msg <= Bag_is_full;
                end
            end
            SELL_pkm: begin
                if(p1.pkm_info == 0) begin
                    inf.complete <= 0;
                    inf.err_msg <= Not_Having_PKM;
                end     
                else if(p1.pkm_info.stage == Lowest) begin
                    inf.complete <= 0;
                    inf.err_msg <= Has_Not_Grown;
                end
            end
            SELL_item: begin
                if(flag_bag_empty) begin
                    inf.complete <= 0;
                    inf.err_msg <= Not_Having_Item;
                end
            end
            USE_ITEM: begin
                if(p1.pkm_info == 0) begin
                    inf.complete <= 0;
                    inf.err_msg <= Not_Having_PKM;
                end    
                else if(flag_bag_empty) begin
                    inf.complete <= 0;
                    inf.err_msg <= Not_Having_Item;
                end
            end
            ATTACK: begin
                if(p1.pkm_info == 0 || opp.pkm_info == 0) begin
                    inf.complete <= 0;
                    inf.err_msg <= Not_Having_PKM;
                end     
                else if(p1.pkm_info.hp == 0 || opp.pkm_info.hp == 0) begin
                    inf.complete <= 0;
                    inf.err_msg <= HP_is_Zero;
                end
            end
        endcase
    end
end

//===========================================================================
// out_info
//===========================================================================
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.out_info <= 0;
    end
    else begin
        case(next_state)
            WR_set, CHECK:    begin
                if(inf.complete) 
                    inf.out_info <= p1;
                else
                    inf.out_info <= 0;
            end
            WR_set_atk:    begin
                if(inf.complete) 
                    inf.out_info <= {p1.pkm_info, opp.pkm_info};
                else
                    inf.out_info <= 0;
            end
            default: begin
                if(inf.complete == 0) 
                    inf.out_info <= 0;   
            end
        endcase
    end
end

endmodule