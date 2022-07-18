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
always_ff@(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) current_state <= IDLE_first;
    else            current_state <= next_state;
end
always_comb begin
    case(current_state)
        IDLE_first: begin
            if(flag_id)
                next_state = RD_invalid;
            else begin
                next_state = current_state;
            end
        end
        IDLE_else: begin
            if(flag_id == 1 && flag_act == 0) begin
                next_state = IDLE_first;
            end
            else if(flag_id && act_reg != Attack) begin
                next_state = RD_invalid;
            end
            else begin
                case(act_reg)
                    Buy: begin
                        if(flag_type || flag_item) begin
                            if(flag_type)
                                next_state = BUY_pkm;
                            else
                                next_state = BUY_item;
                        end
                        else begin
                            next_state = current_state;
                        end
                    end
                    Sell: begin
                        if(flag_type || flag_item) begin
                            if(flag_type)
                                next_state = SELL_pkm;
                            else
                                next_state = SELL_item;
                        end
                        else begin
                            next_state = current_state;
                        end
                    end
                    Deposit: begin
                        if(flag_amnt)
                            next_state = DEPOSIT;
                        else
                            next_state = current_state;
                    end
                    Check: begin
                        next_state = CHECK;
                    end
                    Use_item: begin
                        if(flag_item)
                            next_state = USE_ITEM;
                        else
                            next_state = current_state;
                    end
                    Attack: begin
                        if(opp == 0) begin
                            if(flag_opp_id)
                                next_state = RD_set_atk;
                            else
                                next_state = current_state;
                        end
                        else begin
                            next_state = ATTACK;
                        end
                    end
                    default: 
                        next_state = current_state;
                endcase
            end
        end
        //==========================================================================
        BUY_pkm: begin
            if(inf.complete)
                next_state = WR_set;
            else
                next_state = OUTPUT;
        end
        BUY_item: begin
            if(inf.complete)
                next_state = WR_set;
            else
                next_state = OUTPUT;
        end
        //==========================================================================
        SELL_pkm: begin
            if(inf.complete) 
                next_state = WR_set;
            else
                next_state = OUTPUT;
        end
        SELL_item: begin
            if(inf.complete)
                next_state = WR_set;
            else
                next_state = OUTPUT;
        end
        //==========================================================================
        DEPOSIT: begin
            next_state = WR_set;
        end
        //==========================================================================
        USE_ITEM: begin
            if((flag_bag_empty == 0 && p1.pkm_info != 0) || inf.complete)
                next_state = WR_set;
            else
                next_state = OUTPUT;
        end
        //==========================================================================
        CHECK: begin
            next_state = OUTPUT;
        end
        //==========================================================================
        ATTACK: begin
            if(inf.complete) 
                next_state = WR_set;
            else
                next_state = OUTPUT;
        end
        //==========================================================================
        RD_invalid: begin
            next_state = RD_wait;
        end
        RD_wait: begin
            if(inf.C_out_valid)
                next_state = RD_store;
            else
                next_state = current_state;
        end	
        RD_store: begin
            if(flag_C_out && flag_act) begin
                case(act_reg)
                    Buy: begin
                        if(flag_type || flag_item) begin
                            if(flag_type)
                                next_state = BUY_pkm;
                            else
                                next_state = BUY_item;
                        end
                        else begin
                            next_state = current_state;
                        end
                    end
                    Sell: begin
                        if(flag_type || flag_item) begin
                            if(flag_type)
                                next_state = SELL_pkm;
                            else
                                next_state = SELL_item;
                        end
                        else begin
                            next_state = current_state;
                        end
                    end
                    Deposit: begin
                        if(flag_amnt)
                                next_state = DEPOSIT;
                        else
                            next_state = current_state;
                    end
                    Check: begin
                        next_state = CHECK;
                    end
                    Use_item: begin
                        if(flag_item)
                            next_state = USE_ITEM;
                        else
                            next_state = current_state;
                    end
                    Attack: begin
                        if(opp == 0) begin
                            if(flag_opp_id)
                                next_state = RD_set_atk;
                            else
                                next_state = current_state;
                        end
                        else begin
                            next_state = ATTACK;
                        end
                    end
                    default: 
                        next_state = current_state;
                endcase
            end
            else
                next_state = current_state;
        end
        //==========================================================================
        RD_set_atk: begin
            next_state = RD_invalid_atk;
        end
        RD_invalid_atk: begin
            next_state = RD_wait_atk;
        end
        RD_wait_atk: begin
            if(inf.C_out_valid)
                next_state = RD_store_atk;
            else
                next_state = current_state;
        end	
        RD_store_atk: begin
            if(flag_C_out) 
                next_state = ATTACK;
            else
                next_state = current_state;
        end
        //==========================================================================
        WR_set: begin
            if(inf.complete)
                next_state = WR_invalid;
            else
                next_state = OUTPUT;
        end
        WR_invalid: begin
            next_state = WR_wait;
        end
        WR_wait: begin
            if(act_reg != Attack) begin
                if(inf.C_out_valid)
                    next_state = OUTPUT;
                else
                    next_state = current_state;
            end
            else begin
                if(inf.C_out_valid)
                    next_state = WR_set_atk;
                else
                    next_state = current_state;
            end
        end
        //==========================================================================
        WR_set_atk: begin
            if(inf.complete)
                next_state = WR_invalid_atk;
            else
                next_state = OUTPUT;
        end
        WR_invalid_atk: begin
            next_state = WR_wait_atk;
        end
        WR_wait_atk: begin
            if(inf.C_out_valid)
                    next_state = OUTPUT;
            else
                next_state = current_state;
        end
        //==========================================================================
        OUTPUT: begin
            next_state = IDLE_else;
        end
        default: 
            next_state = current_state;
    endcase
end
//===========================================================================
// AXI4 ( C_addr, C_r_wb, C_in_valid, C_data_w ), ( C_out_valid, C_data_r )
//===========================================================================
// C_addr
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.C_addr <= 0;
    end
    else begin
        case(next_state)
            IDLE_first: begin
                if(inf.id_valid) begin
                    inf.C_addr <= inf.D.d_id;
                end
            end
            IDLE_else: begin
                if(act_reg == Attack || act_reg == No_action) begin
                    if(inf.id_valid) begin
                        inf.C_addr <= inf.D.d_id;
                    end
                end
            end
            WR_set: begin
                if(inf.complete)
                    inf.C_addr <= id_reg;
                else
                    inf.C_addr <= 0;
            end
            WR_set_atk: begin
                if(inf.complete)
                    inf.C_addr <= id_opp_reg;
                else
                    inf.C_addr <= 0;
            end
            RD_set_atk: begin
                inf.C_addr <= id_opp_reg;
            end
        endcase
    end
end

// C_r_wb
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.C_r_wb <= Write;
    end
    else begin
        case(next_state)
            WR_set, WR_invalid, WR_wait: begin
                inf.C_r_wb <= Write;
            end
            WR_set_atk, WR_invalid_atk, WR_wait_atk: begin
                inf.C_r_wb <= Write;
            end
            default: begin
                inf.C_r_wb <= Read;
            end
        endcase
    end
end

// C_in_valid
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.C_in_valid <= 0;
    end
    else begin
        case(next_state)
            RD_invalid, RD_invalid_atk: begin
                inf.C_in_valid <= 1;
            end
            WR_invalid: begin
                inf.C_in_valid <= 1;
            end
            WR_invalid_atk: begin
                inf.C_in_valid <= 1;
            end
            default: begin
                inf.C_in_valid <= 0;
            end
        endcase
    end
end

// C_data_w
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.C_data_w <= 0;
    end
    else begin
        case(next_state)
            WR_set, WR_invalid, WR_wait: begin
                //inf.C_data_w <= p1;
                // bag
                inf.C_data_w[7:4] 	<= p1.bag_info.berry_num;
                inf.C_data_w[3:0] 	<= p1.bag_info.medicine_num;
                inf.C_data_w[15:12] <= p1.bag_info.candy_num;
                inf.C_data_w[11:8] 	<= p1.bag_info.bracer_num;
                inf.C_data_w[23:22] <= p1.bag_info.stone;
                {inf.C_data_w[21:16], inf.C_data_w[31:24]} <= p1.bag_info.money;

                // pkm
                inf.C_data_w[39:36] <= p1.pkm_info.stage   ;
                inf.C_data_w[35:32] <= p1.pkm_info.pkm_type;
                inf.C_data_w[47:40] <= p1.pkm_info.hp      ;
                inf.C_data_w[55:48]	<= p1.pkm_info.atk     ;
                inf.C_data_w[63:56] <= p1.pkm_info.exp     ;
            end
            WR_set_atk, WR_invalid_atk, WR_wait_atk: begin
                //inf.C_data_w <= opp;
                // bag
                inf.C_data_w[7:4] 	<= opp.bag_info.berry_num;
                inf.C_data_w[3:0] 	<= opp.bag_info.medicine_num;
                inf.C_data_w[15:12] <= opp.bag_info.candy_num;
                inf.C_data_w[11:8] 	<= opp.bag_info.bracer_num;
                inf.C_data_w[23:22] <= opp.bag_info.stone;
                {inf.C_data_w[21:16], inf.C_data_w[31:24]} <= opp.bag_info.money;
                // pkm
                inf.C_data_w[39:36] <= opp.pkm_info.stage   ;
                inf.C_data_w[35:32] <= opp.pkm_info.pkm_type;
                inf.C_data_w[47:40] <= opp.pkm_info.hp      ;
                inf.C_data_w[55:48]	<= opp.pkm_info.atk     ;
                inf.C_data_w[63:56] <= opp.pkm_info.exp     ;
            end
            default: begin
                inf.C_data_w <= 0;
            end
        endcase
    end
end
//===================================================================================================
// INPUT REG   
//===================================================================================================
//===========================================================================
// flag_C_out   
//===========================================================================
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		flag_C_out <= 0;
	end else begin
		case(next_state)
            IDLE_first, IDLE_else: begin
                flag_C_out <= 0;
            end
            RD_store, RD_store_atk, RD_set_atk: begin
                if(inf.C_out_valid) begin
                    flag_C_out <= 1;
                end
            end
            default: flag_C_out <= 0;
        endcase
	end
end

//===========================================================================
// id_reg, id_opp_reg, flag_opp_id, flag_id
//===========================================================================
// id_reg, id_opp_reg
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		id_reg <= 0;
        id_opp_reg <= 0;
	end else begin
		case(next_state)
            IDLE_first, IDLE_else: begin
                if(inf.id_valid) begin
                    if(act_reg == Attack) begin
                        if(flag_p1 == 0)
                            id_reg <= inf.D.d_id;
                        else
                            id_opp_reg <= inf.D.d_id;
                    end
                    else
                        id_reg <= inf.D.d_id;
                end
            end
            RD_invalid, RD_wait, RD_store: begin
                 if(inf.id_valid) begin
                    id_opp_reg <= inf.D.d_id;
                end
            end
            OUTPUT: begin
                id_opp_reg <= 0;
            end
        endcase
	end
end

// flag_id
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		flag_id <= 0;
	end else begin
        case(next_state)
            IDLE_first, IDLE_else: begin
                if(inf.id_valid) begin
                    flag_id <= 1;
                end
            end
            OUTPUT: begin
                flag_id <= 0;
            end
        endcase
		
	end
end

// flag_opp_id
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		flag_opp_id <= 0;
	end else begin
        case(next_state)
            IDLE_else, RD_invalid, RD_wait, RD_store: begin
                if(act_reg == Attack && inf.id_valid) begin
                    flag_opp_id <= 1;
                end
            end
            OUTPUT: begin
                flag_opp_id <= 0;
            end
        endcase
		
	end
end
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
// amnt_reg
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		amnt_reg <= 0;
	end else begin
		if(inf.amnt_valid) begin
            amnt_reg <= inf.D.d_money;
		end
	end
end

// flag_amnt
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		flag_amnt <= 0;
	end else begin
		if(inf.amnt_valid) begin
			flag_amnt <= 1;
		end
        else begin
            if(next_state == OUTPUT)
                flag_amnt <= 0;
        end
	end
end

//===========================================================================
// pkm parameters 
//===========================================================================
/*
typedef struct packed {
	Stage		stage;			// [31:28] 4
	PKM_Type	pkm_type;		// [27:24] 4
	HP			hp;				// [23:16] 8
	ATK			atk;			// [15: 8] 8
	EXP			exp;			// [7 : 0] 8
} PKM_Info; 

HP          pkm_max_hp;
EXP         pkm_max_exp;
PKM_Type	p1_pkm_type_reg;
*/
//===========================================================================
// pkm_price_buy
always_comb begin
    case(p1_pkm_type_reg)
        Grass:    pkm_price_buy = 100;
        Fire:     pkm_price_buy = 90;
        Water:    pkm_price_buy = 110;
        Electric: pkm_price_buy = 120;
        Normal:   pkm_price_buy = 130;
        default:  pkm_price_buy = 0;
    endcase
end

//price_sell_pkm
always_comb begin
	case({p1.pkm_info.pkm_type, p1.pkm_info.stage})
		{Grass, Middle}     : pkm_price_sell = 510;
        {Grass, Highest}    : pkm_price_sell = 1100;
        {Fire, Middle}      : pkm_price_sell = 450;
        {Fire, Highest}     : pkm_price_sell = 1000;
        {Water, Middle}     : pkm_price_sell = 500;
        {Water, Highest}    : pkm_price_sell = 1200;
        {Electric, Middle}  : pkm_price_sell = 550;
        {Electric, Highest} : pkm_price_sell = 1300;
        default             : pkm_price_sell = 0;
    endcase
end

// pkm_max_hp
always_comb begin
    case({p1.pkm_info.pkm_type, p1.pkm_info.stage})
        {Grass, Lowest}     : pkm_max_hp = 128;
        {Grass, Middle}     : pkm_max_hp = 192;
        {Grass, Highest}    : pkm_max_hp = 254;
        {Fire, Lowest}      : pkm_max_hp = 119;
        {Fire, Middle}      : pkm_max_hp = 177;
        {Fire, Highest}     : pkm_max_hp = 225;
        {Water, Lowest}     : pkm_max_hp = 125;
        {Water, Middle}     : pkm_max_hp = 187;
        {Water, Highest}    : pkm_max_hp = 245;
        {Electric, Lowest}  : pkm_max_hp = 122;
        {Electric, Middle}  : pkm_max_hp = 182;
        {Electric, Highest} : pkm_max_hp = 235;
        {Normal, Lowest}    : pkm_max_hp = 124;
        default             : pkm_max_hp = 0;
    endcase
end

// pkm_max_exp (p1)
always_comb begin
    case({p1.pkm_info.pkm_type, p1.pkm_info.stage})
        {Grass, Lowest}     : pkm_max_exp = 32;
        {Grass, Middle}     : pkm_max_exp = 63;
        {Fire, Lowest}      : pkm_max_exp = 30;
        {Fire, Middle}      : pkm_max_exp = 59;
        {Water, Lowest}     : pkm_max_exp = 28;
        {Water, Middle}     : pkm_max_exp = 55;
        {Electric, Lowest}  : pkm_max_exp = 26;
        {Electric, Middle}  : pkm_max_exp = 51;
        {Normal, Lowest}    : pkm_max_exp = 29;
        default             : pkm_max_exp = 0;
    endcase
end

// opp_max_exp (opp)
always_comb begin
    case({opp.pkm_info.pkm_type, opp.pkm_info.stage})
        {Grass, Lowest}     : opp_max_exp = 32;
        {Grass, Middle}     : opp_max_exp = 63;
        {Fire, Lowest}      : opp_max_exp = 30;
        {Fire, Middle}      : opp_max_exp = 59;
        {Water, Lowest}     : opp_max_exp = 28;
        {Water, Middle}     : opp_max_exp = 55;
        {Electric, Lowest}  : opp_max_exp = 26;
        {Electric, Middle}  : opp_max_exp = 51;
        {Normal, Lowest}    : opp_max_exp = 29;
        default             : opp_max_exp = 0;
    endcase
end

// atk_reward_exp
always_comb begin
    case(opp.pkm_info.stage)
        Lowest:  atk_reward_exp = 16;
        Middle:  atk_reward_exp = 24;
        Highest: atk_reward_exp = 32;
        default: atk_reward_exp = 0;
    endcase
end

// def_reward_exp
always_comb begin
    case(p1.pkm_info.stage)
        Lowest:  def_reward_exp = 8;
        Middle:  def_reward_exp = 12;
        Highest: def_reward_exp = 16;
        default: def_reward_exp = 0;
    endcase
end

// pkm_base_atk
always_comb begin
    case({inf.C_data_r[35:32], inf.C_data_r[39:36]}) // type, stage
        {Grass, Lowest}     : pkm_base_atk = 63;
        {Grass, Middle}     : pkm_base_atk = 94;
        {Grass, Highest}    : pkm_base_atk = 123;
        {Fire, Lowest}      : pkm_base_atk = 64;
        {Fire, Middle}      : pkm_base_atk = 96;
        {Fire, Highest}     : pkm_base_atk = 127;
        {Water, Lowest}     : pkm_base_atk = 60;
        {Water, Middle}     : pkm_base_atk = 89;
        {Water, Highest}    : pkm_base_atk = 113;
        {Electric, Lowest}  : pkm_base_atk = 65;
        {Electric, Middle}  : pkm_base_atk = 97;
        {Electric, Highest} : pkm_base_atk = 124;
        {Normal, Lowest}    : pkm_base_atk = 62;
        default             : pkm_base_atk = 0;
    endcase
end

// pkm_base_atk_reg
always_comb begin
    case({p1.pkm_info.pkm_type, p1.pkm_info.stage}) // type, stage
        {Grass, Lowest}     : pkm_base_atk_reg = 63;
        {Grass, Middle}     : pkm_base_atk_reg = 94;
        {Grass, Highest}    : pkm_base_atk_reg = 123;
        {Fire, Lowest}      : pkm_base_atk_reg = 64;
        {Fire, Middle}      : pkm_base_atk_reg = 96;
        {Fire, Highest}     : pkm_base_atk_reg = 127;
        {Water, Lowest}     : pkm_base_atk_reg = 60;
        {Water, Middle}     : pkm_base_atk_reg = 89;
        {Water, Highest}    : pkm_base_atk_reg = 113;
        {Electric, Lowest}  : pkm_base_atk_reg = 65;
        {Electric, Middle}  : pkm_base_atk_reg = 97;
        {Electric, Highest} : pkm_base_atk_reg = 124;
        {Normal, Lowest}    : pkm_base_atk_reg = 62;
        default             : pkm_base_atk_reg = 0;
    endcase
end
// damage
always_comb begin
    case(next_state)
        RD_store_atk, ATTACK: begin
            if(p1.pkm_info.pkm_type == opp.pkm_info.pkm_type) begin
                if(p1.pkm_info.pkm_type != Normal)
                    damage = p1.pkm_info.atk >> 1;
                else
                    damage = p1.pkm_info.atk;
            end
            else begin
                case({p1.pkm_info.pkm_type, opp.pkm_info.pkm_type})
                    // 0.5
                    {Grass, Fire}:      damage = p1.pkm_info.atk >> 1; 
                    {Fire, Water}:      damage = p1.pkm_info.atk >> 1; 
                    {Water, Grass}:     damage = p1.pkm_info.atk >> 1; 
                    {Electric, Grass}:  damage = p1.pkm_info.atk >> 1; 
                    // 2
                    {Grass, Water}:     damage = p1.pkm_info.atk << 1;
                    {Fire, Grass}:      damage = p1.pkm_info.atk << 1;
                    {Water, Fire}:      damage = p1.pkm_info.atk << 1;
                    {Electric, Water}:  damage = p1.pkm_info.atk << 1;
                    default:            damage = p1.pkm_info.atk;
                endcase
            end
        end
        default: damage = 0;
    endcase
end
//===========================================================================
// bag parameters 
//===========================================================================
/*
typedef struct packed {
	Item_num	berry_num; 		// [31:28] 4
	Item_num	medicine_num;	// [27:24] 4
	Item_num	candy_num;		// [23:20] 4
	Item_num	bracer_num;		// [19:16] 4
	Stone		stone;			// [15:14] 2
	Money		money;			// [13:	0] 14
} Bag_Info; 
// full
reg atk_bag_full;
*/
//===========================================================================
// item_price_buy
always_comb begin
    case(item_reg)
        Berry	      : item_price_buy = 16;
        Medicine      : item_price_buy = 128;
        Candy	      : item_price_buy = 300;
        Bracer	      : item_price_buy = 64;
        Water_stone   : item_price_buy = 800;
        Fire_stone    : item_price_buy = 800;
        Thunder_stone : item_price_buy = 800;
        default  :      item_price_buy = 0;
    endcase
end

// item_price_sell
always_comb begin
    case(item_reg)
        Berry	      : item_price_sell = 12;
        Medicine      : item_price_sell = 96;
        Candy	      : item_price_sell = 225;
        Bracer	      : item_price_sell = 48;
        Water_stone   : item_price_sell = 600;
        Fire_stone    : item_price_sell = 600;
        Thunder_stone : item_price_sell = 600;
        default  :      item_price_sell = 0;
    endcase
end

// flag_bag_full
always_comb begin
    case(item_reg)
        Berry: begin
            if(p1.bag_info.berry_num == 15) flag_bag_full = 1;
            else flag_bag_full = 0;
        end
        Medicine: begin
            if(p1.bag_info.medicine_num == 15) flag_bag_full = 1;
            else flag_bag_full = 0;
        end
        Candy: begin
            if(p1.bag_info.candy_num == 15) flag_bag_full = 1;
            else flag_bag_full = 0;
        end
        Bracer: begin
            if(p1.bag_info.bracer_num == 15) flag_bag_full = 1;
            else flag_bag_full = 0;
        end 
        Water_stone, Fire_stone, Thunder_stone: begin
            if(p1.bag_info.stone != No_stone) flag_bag_full = 1;
            else flag_bag_full = 0;
        end
        default: flag_bag_full = 0;  
    endcase
end

// flag_bag_empty
always_comb begin
    case(item_reg)
        Berry: begin
            if(p1.bag_info.berry_num == 0) flag_bag_empty = 1;
            else flag_bag_empty = 0;
        end
        Medicine: begin
            if(p1.bag_info.medicine_num == 0) flag_bag_empty = 1;
            else flag_bag_empty = 0;
        end
        Candy: begin
            if(p1.bag_info.candy_num == 0) flag_bag_empty = 1;
            else flag_bag_empty = 0;
        end
        Bracer: begin
            if(p1.bag_info.bracer_num == 0) flag_bag_empty = 1;
            else flag_bag_empty = 0;
        end 
        Water_stone, Fire_stone: begin
            if(p1.bag_info.stone != item_reg[1:0]) flag_bag_empty = 1;
            else flag_bag_empty = 0;
        end
        Thunder_stone: begin
            if(p1.bag_info.stone != 3) flag_bag_empty = 1;
            else flag_bag_empty = 0;
        end
        default: flag_bag_empty = 0;  
    endcase
end

//===================================================================================================
// design 
//===================================================================================================
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        p1 <= 0;
        opp <= 0;
        flag_p1 <= 0;
    end
    else begin
        case(next_state)
            IDLE_else: begin
                if(act_reg != Attack && inf.id_valid)
                    flag_p1 <= 0;
            end
            RD_store: begin
                if(inf.C_out_valid) begin
                    // bag
                    flag_p1 <= 1;
                    p1.bag_info.berry_num    <=  inf.C_data_r[ 7:4 ];  // 4
                    p1.bag_info.medicine_num <=  inf.C_data_r[ 3:0 ];  // 4
                    p1.bag_info.candy_num    <=  inf.C_data_r[15:12];  // 4
                    p1.bag_info.bracer_num   <=  inf.C_data_r[11: 8];  // 4
                    p1.bag_info.stone        <=  inf.C_data_r[23:22];  // 2
                    p1.bag_info.money        <= {inf.C_data_r[21:16], inf.C_data_r[31:24]};  // 14
                    // pkm
                    p1.pkm_info.stage        <= inf.C_data_r[39:36];  // 4
                    p1.pkm_info.pkm_type     <= inf.C_data_r[35:32];  // 4
                    p1.pkm_info.hp           <= inf.C_data_r[47:40];  // 8
                    p1.pkm_info.atk          <= pkm_base_atk;// 8
                    p1.pkm_info.exp          <= inf.C_data_r[63:56];  // 8
                end
            end
            RD_store_atk: begin
                if(inf.C_out_valid) begin
                    // bag
                    opp.bag_info.berry_num    <=  inf.C_data_r[ 7:4 ];  // 4
                    opp.bag_info.medicine_num <=  inf.C_data_r[ 3:0 ];  // 4
                    opp.bag_info.candy_num    <=  inf.C_data_r[15:12];  // 4
                    opp.bag_info.bracer_num   <=  inf.C_data_r[11: 8];  // 4
                    opp.bag_info.stone        <=  inf.C_data_r[23:22];  // 2
                    opp.bag_info.money        <= {inf.C_data_r[21:16], inf.C_data_r[31:24]};  // 14
                    // pkm
                    opp.pkm_info.stage        <= inf.C_data_r[39:36];  // 4
                    opp.pkm_info.pkm_type     <= inf.C_data_r[35:32];  // 4
                    opp.pkm_info.hp           <= inf.C_data_r[47:40];  // 8
                    opp.pkm_info.atk          <= pkm_base_atk;         // 8
                    opp.pkm_info.exp          <= inf.C_data_r[63:56];  // 8
                end
            end
            BUY_pkm: begin
                if(p1.bag_info.money >= pkm_price_buy && p1.pkm_info == 0) begin
                    // bag
                    p1.bag_info.money <= p1.bag_info.money - pkm_price_buy;
                    // pkm
                    p1.pkm_info.stage    <= Lowest;
                    p1.pkm_info.pkm_type <= p1_pkm_type_reg;
                    p1.pkm_info.exp      <= 0;
                    case(p1_pkm_type_reg)
                        Grass: begin
                            p1.pkm_info.hp  <= 128;
                            p1.pkm_info.atk <= 63;
                        end
                        Fire: begin
                            p1.pkm_info.hp  <= 119;
                            p1.pkm_info.atk <= 64;
                        end
                        Water: begin
                            p1.pkm_info.hp  <= 125;
                            p1.pkm_info.atk <= 60;
                        end
                        Electric: begin
                            p1.pkm_info.hp  <= 122;
                            p1.pkm_info.atk <= 65;
                        end
                        Normal: begin
                            p1.pkm_info.hp  <= 124;
                            p1.pkm_info.atk <= 62;
                        end
                    endcase
                end 
            end
            BUY_item: begin
                if(p1.bag_info.money >= item_price_buy && flag_bag_full == 0) begin
                    // bag
                    p1.bag_info.money <= p1.bag_info.money - item_price_buy;
                    case(item_reg)
                        Berry	      : p1.bag_info.berry_num    <= p1.bag_info.berry_num + 1;
                        Medicine      : p1.bag_info.medicine_num <= p1.bag_info.medicine_num + 1;
                        Candy	      : p1.bag_info.candy_num    <= p1.bag_info.candy_num + 1;
                        Bracer	      : p1.bag_info.bracer_num   <= p1.bag_info.bracer_num + 1;
                        Water_stone   : p1.bag_info.stone        <= W_stone;
                        Fire_stone    : p1.bag_info.stone        <= F_stone;
                        Thunder_stone : p1.bag_info.stone        <= T_stone;
                    endcase
                end
            end
            SELL_pkm: begin
                if(p1.pkm_info != 0 && p1.pkm_info.stage != Lowest) begin
                    // bag
                    p1.bag_info.money <= p1.bag_info.money + pkm_price_sell;
                    // pkm
                    p1.pkm_info.stage    <= 0;
                    p1.pkm_info.pkm_type <= No_type;
                    p1.pkm_info.exp      <= 0;
                    p1.pkm_info.hp       <= 0;
                    p1.pkm_info.atk      <= 0;
                end 
            end
            SELL_item: begin
                if(flag_bag_empty == 0) begin
                    // bag
                    p1.bag_info.money <= p1.bag_info.money + item_price_sell;
                    case(item_reg)
                        Berry	      : p1.bag_info.berry_num    <= p1.bag_info.berry_num - 1;
                        Medicine      : p1.bag_info.medicine_num <= p1.bag_info.medicine_num - 1;
                        Candy	      : p1.bag_info.candy_num    <= p1.bag_info.candy_num - 1;
                        Bracer	      : p1.bag_info.bracer_num   <= p1.bag_info.bracer_num - 1;
                        Water_stone   : p1.bag_info.stone        <= No_stone;
                        Fire_stone    : p1.bag_info.stone        <= No_stone;
                        Thunder_stone : p1.bag_info.stone        <= No_stone;
                    endcase
                end 
            end
            DEPOSIT: begin
                // bag
                p1.bag_info.money <= p1.bag_info.money + amnt_reg;
            end
            USE_ITEM: begin
                if(flag_bag_empty == 0 && p1.pkm_info != 0) begin
                    case(item_reg)
                        Berry: begin
                            p1.bag_info.berry_num <= p1.bag_info.berry_num - 1;
                            if(p1.pkm_info.hp >= (pkm_max_hp - 32))
                                p1.pkm_info.hp <= pkm_max_hp;
                            else
                                p1.pkm_info.hp <= p1.pkm_info.hp + 32;
                        end
                        Medicine: begin
                            p1.bag_info.medicine_num <= p1.bag_info.medicine_num - 1;
                            p1.pkm_info.hp <= pkm_max_hp;
                        end
                        Candy: begin
                            p1.bag_info.candy_num <= p1.bag_info.candy_num - 1;
                            if(p1.pkm_info.pkm_type == Normal) begin
                                if(p1.pkm_info.exp > pkm_max_exp - 15)
                                    p1.pkm_info.exp <= pkm_max_exp;
                                else
                                    p1.pkm_info.exp <= p1.pkm_info.exp + 15;
                            end
                            else begin
                                if(p1.pkm_info.stage != Highest) begin
                                    if( (p1.pkm_info.exp + 15) >= pkm_max_exp) begin // evolve
                                        p1.pkm_info.stage <= (p1.pkm_info.stage << 1);
                                        p1.pkm_info.exp <= 0;
                                        case({p1.pkm_info.pkm_type, p1.pkm_info.stage})
                                            {Grass, Lowest}     : p1.pkm_info.atk <= 94;
                                            {Grass, Middle}     : p1.pkm_info.atk <= 123;
                                            {Fire, Lowest}      : p1.pkm_info.atk <= 96;
                                            {Fire, Middle}      : p1.pkm_info.atk <= 127;
                                            {Water, Lowest}     : p1.pkm_info.atk <= 89;
                                            {Water, Middle}     : p1.pkm_info.atk <= 113;
                                            {Electric, Lowest}  : p1.pkm_info.atk <= 97;
                                            {Electric, Middle}  : p1.pkm_info.atk <= 124;
                                        endcase
                                        case({p1.pkm_info.pkm_type, p1.pkm_info.stage})
                                            {Grass, Lowest}     : p1.pkm_info.hp <= 192;
                                            {Grass, Middle}     : p1.pkm_info.hp <= 254;
                                            {Fire, Lowest}      : p1.pkm_info.hp <= 177;
                                            {Fire, Middle}      : p1.pkm_info.hp <= 225;
                                            {Water, Lowest}     : p1.pkm_info.hp <= 187;
                                            {Water, Middle}     : p1.pkm_info.hp <= 245;
                                            {Electric, Lowest}  : p1.pkm_info.hp <= 182;
                                            {Electric, Middle}  : p1.pkm_info.hp <= 235;
                                            default             : p1.pkm_info.hp <= 0;
                                        endcase
                                    end
                                    else
                                        p1.pkm_info.exp <= p1.pkm_info.exp + 15;
                                end
                                else
                                    p1.pkm_info.exp <= 0;
                            end
                        end
                        Bracer: begin
                            p1.bag_info.bracer_num <= p1.bag_info.bracer_num - 1;
                            if(p1.pkm_info.atk == pkm_base_atk_reg)
                                p1.pkm_info.atk <= p1.pkm_info.atk + 32;
                        end 
                        Water_stone, Fire_stone, Thunder_stone: begin
                            p1.bag_info.stone <= No_stone;
                            if(p1.pkm_info.pkm_type == Normal) begin
                                if(p1.pkm_info.exp == pkm_max_exp) begin // evolve
                                    p1.pkm_info.stage <= Highest;
                                    p1.pkm_info.exp <= 0;
                                    case(item_reg)
                                        Water_stone: begin
                                            p1.pkm_info.hp  <= 245;
                                            p1.pkm_info.atk <= 113;
                                            p1.pkm_info.pkm_type <= Water;
                                        end
                                        Fire_stone: begin
                                            p1.pkm_info.hp  <= 225;
                                            p1.pkm_info.atk <= 127;
                                            p1.pkm_info.pkm_type <= Fire;
                                        end
                                        Thunder_stone: begin
                                            p1.pkm_info.hp  <= 235;
                                            p1.pkm_info.atk <= 124;
                                            p1.pkm_info.pkm_type <= Electric;
                                        end
                                    endcase
                                end
                                else begin // can't evolve
                                    p1.bag_info.stone <= No_stone;
                                end
                            end
                        end
                    endcase
                end
            end
            ATTACK: begin
                if(p1.pkm_info != 0 && p1.pkm_info.hp != 0 && opp.pkm_info.hp != 0) begin
                    // reset p1 atk
                    if(p1.pkm_info.atk > pkm_base_atk_reg)
                        p1.pkm_info.atk <= pkm_base_atk_reg;
                    // p1 (atk) atk_reward_exp pkm_max_exp
                    if(p1.pkm_info.pkm_type == Normal) begin
                        if( (p1.pkm_info.exp + atk_reward_exp) >= pkm_max_exp )
                            p1.pkm_info.exp <= pkm_max_exp;
                        else
                            p1.pkm_info.exp <= p1.pkm_info.exp + atk_reward_exp;
                    end
                    else begin
                        if(p1.pkm_info.stage != Highest) begin
                            if( (p1.pkm_info.exp + atk_reward_exp) >= pkm_max_exp ) begin // evolve
                                p1.pkm_info.stage <= (p1.pkm_info.stage << 1);
                                p1.pkm_info.exp <= 0;
                                case({p1.pkm_info.pkm_type, p1.pkm_info.stage})
                                    {Grass, Lowest}     : p1.pkm_info.atk <= 94;
                                    {Grass, Middle}     : p1.pkm_info.atk <= 123;
                                    {Fire, Lowest}      : p1.pkm_info.atk <= 96;
                                    {Fire, Middle}      : p1.pkm_info.atk <= 127;
                                    {Water, Lowest}     : p1.pkm_info.atk <= 89;
                                    {Water, Middle}     : p1.pkm_info.atk <= 113;
                                    {Electric, Lowest}  : p1.pkm_info.atk <= 97;
                                    {Electric, Middle}  : p1.pkm_info.atk <= 124;
                                endcase
                                case({p1.pkm_info.pkm_type, p1.pkm_info.stage})
                                    {Grass, Lowest}     : p1.pkm_info.hp <= 192;
                                    {Grass, Middle}     : p1.pkm_info.hp <= 254;
                                    {Fire, Lowest}      : p1.pkm_info.hp <= 177;
                                    {Fire, Middle}      : p1.pkm_info.hp <= 225;
                                    {Water, Lowest}     : p1.pkm_info.hp <= 187;
                                    {Water, Middle}     : p1.pkm_info.hp <= 245;
                                    {Electric, Lowest}  : p1.pkm_info.hp <= 182;
                                    {Electric, Middle}  : p1.pkm_info.hp <= 235;
                                    default             : p1.pkm_info.hp <= 0;
                                endcase
                            end
                            else
                                p1.pkm_info.exp <= p1.pkm_info.exp + atk_reward_exp;
                        end
                        else
                            p1.pkm_info.exp <= 0;
                    end
                    // opp (def) def_reward_exp opp_max_exp
                    if(opp.pkm_info.pkm_type == Normal) begin
                        // hp
                        if(opp.pkm_info.hp >= damage)
                            opp.pkm_info.hp <= opp.pkm_info.hp - damage;
                        else
                            opp.pkm_info.hp <= 0;
                        // exp
                        if( (opp.pkm_info.exp + def_reward_exp) >= opp_max_exp )
                            opp.pkm_info.exp <= opp_max_exp;
                        else
                            opp.pkm_info.exp <= opp.pkm_info.exp + def_reward_exp;
                    end
                    else begin
                        if(opp.pkm_info.stage != Highest) begin
                            if((opp.pkm_info.exp + def_reward_exp) >= opp_max_exp) begin // evolve
                                opp.pkm_info.stage <= (opp.pkm_info.stage << 1);
                                opp.pkm_info.exp <= 0;
                                case({opp.pkm_info.pkm_type, opp.pkm_info.stage})
                                    {Grass, Lowest}     : opp.pkm_info.atk <= 94;
                                    {Grass, Middle}     : opp.pkm_info.atk <= 123;
                                    {Fire, Lowest}      : opp.pkm_info.atk <= 96;
                                    {Fire, Middle}      : opp.pkm_info.atk <= 127;
                                    {Water, Lowest}     : opp.pkm_info.atk <= 89;
                                    {Water, Middle}     : opp.pkm_info.atk <= 113;
                                    {Electric, Lowest}  : opp.pkm_info.atk <= 97;
                                    {Electric, Middle}  : opp.pkm_info.atk <= 124;
                                endcase
                                case({opp.pkm_info.pkm_type, opp.pkm_info.stage})
                                    {Grass, Lowest}     : opp.pkm_info.hp <= 192;
                                    {Grass, Middle}     : opp.pkm_info.hp <= 254;
                                    {Fire, Lowest}      : opp.pkm_info.hp <= 177;
                                    {Fire, Middle}      : opp.pkm_info.hp <= 225;
                                    {Water, Lowest}     : opp.pkm_info.hp <= 187;
                                    {Water, Middle}     : opp.pkm_info.hp <= 245;
                                    {Electric, Lowest}  : opp.pkm_info.hp <= 182;
                                    {Electric, Middle}  : opp.pkm_info.hp <= 235;
                                    default             : opp.pkm_info.hp <= 0;
                                endcase
                            end
                            else begin
                                // hp
                                if(opp.pkm_info.hp >= damage)
                                    opp.pkm_info.hp <= opp.pkm_info.hp - damage;
                                else
                                    opp.pkm_info.hp <= 0;
                                // exp
                                opp.pkm_info.exp <= opp.pkm_info.exp + def_reward_exp;
                            end
                        end
                        else begin
                            // hp
                            if(opp.pkm_info.hp >= damage)
                                opp.pkm_info.hp <= opp.pkm_info.hp - damage;
                            else
                                opp.pkm_info.hp <= 0;
                            // exp
                            opp.pkm_info.exp <= 0;
                        end
                    end
                end
            end
            OUTPUT: begin
                opp <= 0;
            end
        endcase
    end
end

//===================================================================================================
// OUTPUT 
//===================================================================================================
//===========================================================================
// out_valid 
//===========================================================================
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		inf.out_valid <= 0;
	end 
    else begin
		case(next_state)
            OUTPUT: begin
                inf.out_valid <= 1;
            end
            default
                inf.out_valid <= 0;
        endcase
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