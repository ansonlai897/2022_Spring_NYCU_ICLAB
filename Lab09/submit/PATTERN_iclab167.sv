`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_PKG.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
//================================================================
// initial DRAM
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
logic [7:0] golden_mem[((65536+256*8)-1):(65536+0)];
initial $readmemh(DRAM_p_r, golden_mem);
//================================================================
// parameters
//================================================================
typedef enum logic  [5:0] { 
    SET_ID,
    SET_ACTION,
    BUY_PKM,
    BUY_ITEM,
    SELL_PKM,
    SELL_ITEM,
    DEPOSIT,
    CHECK,
    USE_ITEM,
    ATK_OPP,
    ATK_ATK,
    ATK_HP,
    ATK_EXP,
    ATK_RESET,
    WAIT_OUT_pre,
    WAIT_OUT,
    ANS
}  debug_state ;
//debug_state current_task;
parameter pat_num = 15;
parameter max_money = 14484; // 16384(2^14) - 1500
//================================================================
// integer
//================================================================
integer i, j;
integer gap, total_cycles, cycles, r_buy, r_sell;
//================================================================
// wire & registers 
//================================================================
Player_Info pat_p1;
Player_Info pat_opp;
Player_id   pat_id_reg, pat_id_opp_reg, pat_id_before, pat_atk_id_before;
Action      pat_act_reg;
Item        pat_item_reg;
Money       pat_amnt_reg;
PKM_Type    pat_p1_pkm_type_reg;

HP  pkm_max_hp;
EXP pkm_max_exp, opp_max_exp;
ATK pkm_base_atk_reg;
logic[8:0] damage;

// buy price
Money pkm_price_buy;
Money item_price_buy;

// sell price
Money pkm_price_sell;
Money item_price_sell;

// sell price
reg flag_bag_full;
reg flag_bag_empty;

// attack
EXP atk_reward_exp;
EXP def_reward_exp;

//================================================================
// golden_complete golden_err golden_out_info
//================================================================
reg         golden_complete;
logic[63:0] golden_out_info;
Error_Msg   golden_err;

//================================================================
// class
//================================================================
class random_act;
    rand Action act;
    constraint range{
	    act inside{Buy, Use_item, Check, Attack};
    }
endclass

class random_type;
    rand PKM_Type pkm_type;
    constraint range{
	    pkm_type inside{Grass, Fire, Water, Electric};
    }
endclass

class random_item;
    rand Item item;
    constraint range{
	    item inside{Berry, Medicine, Candy, Bracer, Water_stone, Fire_stone, Thunder_stone};
    }
endclass
random_act  r_act  = new();
random_type r_type = new();
random_item r_item = new();
//================================================================
// initial
//================================================================
initial begin
    // golden
    golden_complete = 1;
    golden_out_info = 0;
    golden_err      = No_Err;

    inf.rst_n       = 1;
    inf.id_valid    = 0;
    inf.act_valid   = 0;
    inf.type_valid  = 0;
    inf.item_valid  = 0;
    inf.amnt_valid  = 0;
    inf.D           = 0;

    total_cycles    = 0; 
    
    reset_signal;
    for(i=0 ; i<=pat_num; i=i+1) begin
		set_id;
        // current_task = SET_ID;
        for(j=0; j< 200; j=j+1) begin
            set_action;
            // current_task = SET_ACTION;

            case(pat_act_reg)
                Buy:    begin
                    r_buy = $urandom_range(0,1);
                    if(r_buy) begin
                        buy_pkm;
                        // current_task = BUY_PKM;
                    end
                    else begin
                        buy_item;
                        // current_task = BUY_ITEM;
                    end
                end
                Sell: begin
                    r_sell = $urandom_range(0,1);
                    if(r_sell) begin
                        sell_pkm;
                        // current_task = SELL_PKM;
                    end
                    else begin
                        sell_item;
                        // current_task = SELL_ITEM;
                    end
                end
                Deposit: begin
                    deposit;
                    // current_task = DEPOSIT;
                end
                Check: begin
                    check;
                    // current_task = CHECK;
                end
                Use_item: begin
                    use_item;
                    // current_task = USE_ITEM;
                end
                Attack: begin
                    attack_set_opp;
                    // current_task = ATK_OPP;

                    attack_atk;
                    // current_task = ATK_ATK;

                    attack_hp;
                    // current_task = ATK_HP;

                    attack_exp;
                    // current_task = ATK_EXP;

                    attack_reset;
                    // current_task = ATK_RESET;
                end
            endcase
            // current_task = WAIT_OUT_pre;
            wait_out_valid;
            // current_task = WAIT_OUT;
            check_ans;
            // current_task = ANS;

            // reset golden
            golden_complete = 1;
            golden_err = No_Err;
            golden_out_info = 0;

            // reset player
            pat_opp = 0;

            //gap=$urandom_range(1,5);
			//repeat(gap)@(negedge clk);
            //@(negedge clk);
        end
        //$display("PASS pattern: %d", i);
	end
    $finish;
end


//================================================================
// reset_signal
//================================================================
task reset_signal; begin
	#(0.5); inf.rst_n = 0;
	#(15/2.0);
	
	#(10); inf.rst_n = 1;
end endtask
//================================================================
// set_id
//================================================================
task set_id; begin
    @(negedge clk);
    pat_id_before = pat_id_reg;
    pat_id_reg = $urandom_range(0, 255);
    while(pat_id_reg == pat_id_before) begin
        pat_id_reg = $urandom_range(0, 255);
    end
    inf.id_valid = 1;
	inf.D.d_id = pat_id_reg;
    
	pat_p1.bag_info = {golden_mem[65536+8*pat_id_reg+0], golden_mem[65536+8*pat_id_reg+1], golden_mem[65536+8*pat_id_reg+2], golden_mem[65536+8*pat_id_reg+3]};
	pat_p1.pkm_info = {golden_mem[65536+8*pat_id_reg+4], golden_mem[65536+8*pat_id_reg+5], golden_mem[65536+8*pat_id_reg+6], golden_mem[65536+8*pat_id_reg+7]};
	
    // pkm_base_atk_reg
    case({pat_p1.pkm_info.pkm_type, pat_p1.pkm_info.stage}) // type, stage
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
    if(pat_p1.pkm_info.atk != pkm_base_atk_reg)
        pat_p1.pkm_info.atk = pkm_base_atk_reg;
    @(negedge clk);
	inf.id_valid = 0;
	inf.D = 'x;
end endtask
//================================================================
// set_action
//================================================================
//wire flag_overflow = (pat_p1.bag_info.money >= max_money) ? 1 : 0;

task set_action; begin
    //gap=$urandom_range(1,5);
    //repeat(gap)@(negedge clk);
    @(negedge clk);
    // random
    if(j == 0) begin
        pat_act_reg   = Buy;
    end
    else if(j == 1)begin
        pat_act_reg   = Buy;
    end
    else if(j == 2)begin
        pat_act_reg   = Sell;
    end
    else if(j == 3)begin
        pat_act_reg   = Buy;
    end
    else if(j == 4)begin
        pat_act_reg   = Use_item;
    end
    else if(j == 5)begin
        pat_act_reg   = Buy;
    end
    else if(j == 6)begin
        pat_act_reg   = Attack;
    end
    else if(j == 7)begin
        pat_act_reg   = Buy;
    end
    else if(j == 8)begin
        pat_act_reg   = Deposit;
    end
    else if(j == 9)begin
        pat_act_reg   = Buy;
    end
    else if(j == 10)begin
        pat_act_reg   = Check;
    end
    else if(j == 11)begin
        pat_act_reg   = Buy;
    end
    //==================================================================
    else if(j == 12)begin
        pat_act_reg   = Sell;
    end
    else if(j == 13)begin
        pat_act_reg   = Sell;
    end
    else if(j == 14)begin
        pat_act_reg   = Deposit;
    end
    else if(j == 15)begin
        pat_act_reg   = Sell;
    end
    else if(j == 16)begin
        pat_act_reg   = Use_item;
    end
    else if(j == 17)begin
        pat_act_reg   = Sell;
    end
    else if(j == 18)begin
        pat_act_reg   = Check;
    end
    else if(j == 19)begin
        pat_act_reg   = Sell;
    end
    else if(j == 20)begin
        pat_act_reg   = Attack;
    end
    else if(j == 21)begin
        pat_act_reg   = Sell;
    end
    //==================================================================
    else if(j == 22)begin
        pat_act_reg   = Deposit;
    end
    else if(j == 23)begin
       pat_act_reg   = Deposit;
    end
    else if(j == 24)begin
        pat_act_reg   = Use_item;
    end
    else if(j == 25)begin
        pat_act_reg   = Deposit;
    end
    else if(j == 26)begin
        pat_act_reg   = Check;
    end
    else if(j == 27)begin
        pat_act_reg   = Deposit;
    end
    else if(j == 28)begin
        pat_act_reg   = Attack;
    end
    else if(j == 29)begin
        pat_act_reg   = Deposit;
    end
    //==================================================================
    else if(j == 30)begin
        pat_act_reg   = Use_item;
    end
    else if(j == 31)begin
        pat_act_reg   = Use_item;
    end
    else if(j == 32)begin
        pat_act_reg   = Check;
    end
    else if(j == 33)begin
        pat_act_reg   = Use_item;
    end
    else if(j == 34)begin
        pat_act_reg   = Attack;
    end
    else if(j == 35)begin
        pat_act_reg   = Use_item;
    end
    //==================================================================
    else if(j == 36)begin
        pat_act_reg   = Check;
    end
    else if(j == 37)begin
        pat_act_reg   = Check;
    end
    else if(j == 38)begin
        pat_act_reg   = Attack;
    end
    else if(j == 39)begin
        pat_act_reg   = Check;
    end
    //==================================================================
    else if(j == 40)begin
        pat_act_reg   = Attack;
    end
    else if(j == 41)begin
        pat_act_reg   = Attack;
    end
    else begin
        if(i < 7)
            pat_act_reg   = Attack;
        else begin
            r_act.randomize();
            pat_act_reg = r_act.act;
        end

    end

    inf.act_valid = 1;
    inf.D.d_act   = pat_act_reg; 

    @(negedge clk);
    inf.act_valid = 0;
    inf.D = 'bx; 
end endtask

//================================================================
// buy_pkm 
//================================================================
task buy_pkm; begin
    //gap=$urandom_range(1,5);
    //repeat(gap)@(negedge clk);
    @(negedge clk);
    // random
    r_type.randomize();
    pat_p1_pkm_type_reg = r_type.pkm_type;

    inf.type_valid = 1;
    inf.D.d_type = pat_p1_pkm_type_reg;

    // pkm parameter
    case(pat_p1_pkm_type_reg)
        Grass:    pkm_price_buy = 100;
        Fire:     pkm_price_buy = 90;
        Water:    pkm_price_buy = 110;
        Electric: pkm_price_buy = 120;
        Normal:   pkm_price_buy = 130;
        default:  pkm_price_buy = 0;
    endcase

    // error
    if(pat_p1.bag_info.money < pkm_price_buy) begin
        golden_complete = 0;
        golden_err = Out_of_money;
        golden_out_info = 0;
    end
    else if(pat_p1.pkm_info != 0) begin
        golden_complete = 0;
        golden_err = Already_Have_PKM;
        golden_out_info = 0;
    end  
    else begin
        // bag
        pat_p1.bag_info.money = pat_p1.bag_info.money - pkm_price_buy;
        // pkm
        pat_p1.pkm_info.stage = Lowest;        
        pat_p1.pkm_info.pkm_type = pat_p1_pkm_type_reg;        
        pat_p1.pkm_info.exp = 0;  
        case(pat_p1_pkm_type_reg)
            Grass: begin
                pat_p1.pkm_info.hp  = 128;
                pat_p1.pkm_info.atk = 63;
            end
            Fire: begin
                pat_p1.pkm_info.hp  = 119;
                pat_p1.pkm_info.atk = 64;
            end
            Water: begin
                pat_p1.pkm_info.hp  = 125;
                pat_p1.pkm_info.atk = 60;
            end
            Electric: begin
                pat_p1.pkm_info.hp  = 122;
                pat_p1.pkm_info.atk = 65;
            end
            Normal: begin
                pat_p1.pkm_info.hp  = 124;
                pat_p1.pkm_info.atk = 62;
            end
        endcase
        // golden
        {golden_mem[65536+8*pat_id_reg+2][5:0], golden_mem[65536+8*pat_id_reg+3]} = pat_p1.bag_info.money;
        golden_mem[65536+8*pat_id_reg+4][7:4] = pat_p1.pkm_info.stage;
        golden_mem[65536+8*pat_id_reg+4][3:0] = pat_p1.pkm_info.pkm_type;
        golden_mem[65536+8*pat_id_reg+7] = pat_p1.pkm_info.exp;
        golden_mem[65536+8*pat_id_reg+5] = pat_p1.pkm_info.hp;
        golden_mem[65536+8*pat_id_reg+6] = pat_p1.pkm_info.atk;

        golden_complete = 1;
        golden_err = No_Err;
        golden_out_info = pat_p1;
    end
    @(negedge clk);
    inf.type_valid = 0;
    inf.D = 'bx; 
end endtask

//================================================================
// buy_item 
//================================================================
task buy_item; begin
    //gap=$urandom_range(1,5);
    //repeat(gap)@(negedge clk);
    @(negedge clk);
    // random
    r_item.randomize();
    pat_item_reg = r_item.item;
    
    inf.item_valid = 1;
    inf.D.d_item = pat_item_reg;
    


    // item parameter
    case(pat_item_reg)
        Berry	      : item_price_buy = 16;
        Medicine      : item_price_buy = 128;
        Candy	      : item_price_buy = 300;
        Bracer	      : item_price_buy = 64;
        Water_stone   : item_price_buy = 800;
        Fire_stone    : item_price_buy = 800;
        Thunder_stone : item_price_buy = 800;
        default  :      item_price_buy = 0;
    endcase

    // flag_bag_full
    case(pat_item_reg)
        Berry: begin
            if(pat_p1.bag_info.berry_num == 15) flag_bag_full = 1;
            else flag_bag_full = 0;
        end
        Medicine: begin
            if(pat_p1.bag_info.medicine_num == 15) flag_bag_full = 1;
            else flag_bag_full = 0;
        end
        Candy: begin
            if(pat_p1.bag_info.candy_num == 15) flag_bag_full = 1;
            else flag_bag_full = 0;
        end
        Bracer: begin
            if(pat_p1.bag_info.bracer_num == 15) flag_bag_full = 1;
            else flag_bag_full = 0;
        end 
        Water_stone, Fire_stone, Thunder_stone: begin
            if(pat_p1.bag_info.stone != No_stone) flag_bag_full = 1;
            else flag_bag_full = 0;
        end
        default: flag_bag_full = 0;  
    endcase

    // error
    if(pat_p1.bag_info.money < item_price_buy) begin
        golden_complete = 0;
        golden_err = Out_of_money;
        golden_out_info = 0;
    end
    else if(flag_bag_full) begin
        golden_complete = 0;
        golden_err = Bag_is_full;
        golden_out_info = 0;
    end
    else begin
        pat_p1.bag_info.money = pat_p1.bag_info.money - item_price_buy;
        case(pat_item_reg)
            Berry	      : pat_p1.bag_info.berry_num    = pat_p1.bag_info.berry_num + 1;
            Medicine      : pat_p1.bag_info.medicine_num = pat_p1.bag_info.medicine_num + 1;
            Candy	      : pat_p1.bag_info.candy_num    = pat_p1.bag_info.candy_num + 1;
            Bracer	      : pat_p1.bag_info.bracer_num   = pat_p1.bag_info.bracer_num + 1;
            Water_stone   : pat_p1.bag_info.stone        = W_stone;
            Fire_stone    : pat_p1.bag_info.stone        = F_stone;
            Thunder_stone : pat_p1.bag_info.stone        = T_stone;
        endcase
        
        // golden
        {golden_mem[65536+8*pat_id_reg+2][5:0], golden_mem[65536+8*pat_id_reg+3]} = pat_p1.bag_info.money;
        golden_mem[65536+8*pat_id_reg+0][7:4] = pat_p1.bag_info.berry_num;
        golden_mem[65536+8*pat_id_reg+0][3:0] = pat_p1.bag_info.medicine_num;
        golden_mem[65536+8*pat_id_reg+1][7:4] = pat_p1.bag_info.candy_num;
        golden_mem[65536+8*pat_id_reg+1][3:0] = pat_p1.bag_info.bracer_num;
        golden_mem[65536+8*pat_id_reg+2][7:6] = pat_p1.bag_info.stone;
        
        golden_complete = 1;
        golden_err = No_Err;
        golden_out_info = pat_p1;
    end
    @(negedge clk);
    inf.item_valid = 0;
    inf.D = 'bx; 
end endtask

//================================================================
// sell_pkm 
//================================================================
task sell_pkm; begin
    //gap=$urandom_range(1,5);
    //repeat(gap)@(negedge clk);
    @(negedge clk);

    inf.type_valid = 1;
    inf.D = 0;
    pat_p1_pkm_type_reg = inf.D.d_type;

    // pkm parameter
    case({pat_p1.pkm_info.pkm_type, pat_p1.pkm_info.stage})
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

    // error
    if(pat_p1.pkm_info == 0) begin
        golden_complete = 0;
        golden_err = Not_Having_PKM;
        golden_out_info = 0;
    end     
    else if(pat_p1.pkm_info.stage == Lowest) begin
        golden_complete = 0;
        golden_err = Has_Not_Grown;
        golden_out_info = 0;
    end
    else begin
        // bag
        pat_p1.bag_info.money = pat_p1.bag_info.money + pkm_price_sell;
        // pkm
        pat_p1.pkm_info.stage    = 0;
        pat_p1.pkm_info.pkm_type = No_type;
        pat_p1.pkm_info.exp      = 0;
        pat_p1.pkm_info.hp       = 0;
        pat_p1.pkm_info.atk      = 0;

        // golden
        {golden_mem[65536+8*pat_id_reg+2][5:0], golden_mem[65536+8*pat_id_reg+3]} = pat_p1.bag_info.money;
        golden_mem[65536+8*pat_id_reg+4][7:4] = pat_p1.pkm_info.stage;
        golden_mem[65536+8*pat_id_reg+4][3:0] = pat_p1.pkm_info.pkm_type;
        golden_mem[65536+8*pat_id_reg+7] = pat_p1.pkm_info.exp;
        golden_mem[65536+8*pat_id_reg+5] = pat_p1.pkm_info.hp;
        golden_mem[65536+8*pat_id_reg+6] = pat_p1.pkm_info.atk;

        golden_complete = 1;
        golden_err = No_Err;
        golden_out_info = pat_p1;
    end
    @(negedge clk);
    inf.type_valid = 0;
    inf.D = 'bx; 
end endtask

//================================================================
// sell_item 
//================================================================
task sell_item; begin
    //gap=$urandom_range(1,5);
    //repeat(gap)@(negedge clk);
    @(negedge clk);
    // random
    r_item.randomize();
    if(pat_p1.bag_info.berry_num < 5)
        pat_item_reg = Berry;
    else if(pat_p1.bag_info.medicine_num < 5)
        pat_item_reg = Medicine;
    else if(pat_p1.bag_info.candy_num < 5) 
        pat_item_reg = Candy;
    else if(pat_p1.bag_info.bracer_num < 5)
        pat_item_reg = Bracer;
    else 
        pat_item_reg = r_item.item;

    inf.item_valid = 1;
    inf.D.d_item = pat_item_reg;
 


    // item parameter
    case(pat_item_reg)
        Berry	      : item_price_sell = 12;
        Medicine      : item_price_sell = 96;
        Candy	      : item_price_sell = 225;
        Bracer	      : item_price_sell = 48;
        Water_stone   : item_price_sell = 600;
        Fire_stone    : item_price_sell = 600;
        Thunder_stone : item_price_sell = 600;
        default  :      item_price_sell = 0;
    endcase

    // flag_bag_empty
    case(pat_item_reg)
        Berry: begin
            if(pat_p1.bag_info.berry_num == 0) flag_bag_empty = 1;
            else flag_bag_empty = 0;
        end
        Medicine: begin
            if(pat_p1.bag_info.medicine_num == 0) flag_bag_empty = 1;
            else flag_bag_empty = 0;
        end
        Candy: begin
            if(pat_p1.bag_info.candy_num == 0) flag_bag_empty = 1;
            else flag_bag_empty = 0;
        end
        Bracer: begin
            if(pat_p1.bag_info.bracer_num == 0) flag_bag_empty = 1;
            else flag_bag_empty = 0;
        end 
        Water_stone, Fire_stone: begin
            if(pat_p1.bag_info.stone != pat_item_reg[1:0]) flag_bag_empty = 1;
            else flag_bag_empty = 0;
        end
        Thunder_stone: begin
            if(pat_p1.bag_info.stone != 3) flag_bag_empty = 1;
            else flag_bag_empty = 0;
        end

        default: flag_bag_full = 0;  
    endcase

    // error
    if(flag_bag_empty) begin
        golden_complete = 0;
        golden_err = Not_Having_Item;
        golden_out_info = 0;
    end
    else begin
        pat_p1.bag_info.money = pat_p1.bag_info.money + item_price_sell;
        case(pat_item_reg)
            Berry	      : pat_p1.bag_info.berry_num    = pat_p1.bag_info.berry_num - 1;
            Medicine      : pat_p1.bag_info.medicine_num = pat_p1.bag_info.medicine_num - 1;
            Candy	      : pat_p1.bag_info.candy_num    = pat_p1.bag_info.candy_num - 1;
            Bracer	      : pat_p1.bag_info.bracer_num   = pat_p1.bag_info.bracer_num - 1;
            Water_stone   : pat_p1.bag_info.stone        = No_stone;
            Fire_stone    : pat_p1.bag_info.stone        = No_stone;
            Thunder_stone : pat_p1.bag_info.stone        = No_stone;
        endcase
        
        // golden
        {golden_mem[65536+8*pat_id_reg+2][5:0], golden_mem[65536+8*pat_id_reg+3]} = pat_p1.bag_info.money;
        golden_mem[65536+8*pat_id_reg+0][7:4] = pat_p1.bag_info.berry_num;
        golden_mem[65536+8*pat_id_reg+0][3:0] = pat_p1.bag_info.medicine_num;
        golden_mem[65536+8*pat_id_reg+1][7:4] = pat_p1.bag_info.candy_num;
        golden_mem[65536+8*pat_id_reg+1][3:0] = pat_p1.bag_info.bracer_num;
        golden_mem[65536+8*pat_id_reg+2][7:6] = pat_p1.bag_info.stone;
        
        golden_complete = 1;
        golden_err = No_Err;
        golden_out_info = pat_p1;
    end
    @(negedge clk);
    inf.item_valid = 0;
    inf.D = 'bx; 
end endtask

//================================================================
// deposit 
//================================================================
task deposit; begin
    //gap=$urandom_range(1,5);
    //repeat(gap)@(negedge clk);
    @(negedge clk);

    inf.amnt_valid = 1;
    inf.D.d_money = $urandom_range(1,10);
    pat_amnt_reg = inf.D.d_money;

    pat_p1.bag_info.money = pat_p1.bag_info.money + pat_amnt_reg;

    // golden
    {golden_mem[65536+8*pat_id_reg+2][5:0], golden_mem[65536+8*pat_id_reg+3]} = pat_p1.bag_info.money;
    
    golden_complete = 1;
    golden_err = No_Err;
    golden_out_info = pat_p1;

    @(negedge clk);
    inf.amnt_valid = 0;
    inf.D = 'bx; 
end endtask

//================================================================
// check 
//================================================================
task check; begin
    golden_complete = 1;
    golden_err = No_Err;
    golden_out_info = pat_p1;

    @(negedge clk);
end endtask

//================================================================
// use_item (start from here)
//================================================================
task use_item; begin
    //gap=$urandom_range(1,5);
    //repeat(gap)@(negedge clk);
    @(negedge clk);
    // random
    r_item.randomize();
    if(pat_p1.bag_info.berry_num > 10)
        pat_item_reg = Berry;
    else if(pat_p1.bag_info.medicine_num > 10)
        pat_item_reg = Medicine;
    else if(pat_p1.bag_info.candy_num > 10) 
        pat_item_reg = Candy;
    else if(pat_p1.bag_info.bracer_num > 10)
        pat_item_reg = Bracer;
    else 
        pat_item_reg = r_item.item;

    inf.item_valid = 1;
    inf.D.d_item = pat_item_reg;

    // pkm_max_hp
    case({pat_p1.pkm_info.pkm_type, pat_p1.pkm_info.stage})
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

    // pkm_base_atk_reg
    case({pat_p1.pkm_info.pkm_type, pat_p1.pkm_info.stage}) // type, stage
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

    // pkm_max_exp
    case({pat_p1.pkm_info.pkm_type, pat_p1.pkm_info.stage})
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

    // flag_bag_empty
    case(pat_item_reg)
        Berry: begin
            if(pat_p1.bag_info.berry_num == 0) flag_bag_empty = 1;
            else flag_bag_empty = 0;
        end
        Medicine: begin
            if(pat_p1.bag_info.medicine_num == 0) flag_bag_empty = 1;
            else flag_bag_empty = 0;
        end
        Candy: begin
            if(pat_p1.bag_info.candy_num == 0) flag_bag_empty = 1;
            else flag_bag_empty = 0;
        end
        Bracer: begin
            if(pat_p1.bag_info.bracer_num == 0) flag_bag_empty = 1;
            else flag_bag_empty = 0;
        end 
        Water_stone, Fire_stone: begin
            if(pat_p1.bag_info.stone != pat_item_reg[1:0]) flag_bag_empty = 1;
            else flag_bag_empty = 0;
        end
        Thunder_stone: begin
            if(pat_p1.bag_info.stone != 3) flag_bag_empty = 1;
            else flag_bag_empty = 0;
        end
        default: flag_bag_full = 0;  
    endcase

    case(pat_item_reg)
        Berry: begin
            if(pat_p1.pkm_info == 0) begin
                golden_complete = 0;
                golden_err = Not_Having_PKM;
                golden_out_info = 0;
            end
            else if(flag_bag_empty) begin
                golden_complete = 0;
                golden_err = Not_Having_Item;
                golden_out_info = 0;
            end
            else begin
                pat_p1.bag_info.berry_num = pat_p1.bag_info.berry_num - 1;
                if(pat_p1.pkm_info.hp >= (pkm_max_hp - 32))
                    pat_p1.pkm_info.hp = pkm_max_hp;
                else
                    pat_p1.pkm_info.hp = pat_p1.pkm_info.hp + 32;

                // golden
                golden_mem[65536+8*pat_id_reg+0][7:4] = pat_p1.bag_info.berry_num;
                golden_mem[65536+8*pat_id_reg+5] = pat_p1.pkm_info.hp;
                
                golden_complete = 1;
                golden_err = No_Err;
                golden_out_info = pat_p1;
            end
        end
        Medicine: begin
            if(pat_p1.pkm_info == 0) begin
                golden_complete = 0;
                golden_err = Not_Having_PKM;
                golden_out_info = 0;
            end
            else if(flag_bag_empty) begin
                golden_complete = 0;
                golden_err = Not_Having_Item;
                golden_out_info = 0;
            end
            else begin
                pat_p1.bag_info.medicine_num = pat_p1.bag_info.medicine_num - 1;
                pat_p1.pkm_info.hp = pkm_max_hp;

                // golden
                golden_mem[65536+8*pat_id_reg+0][3:0] = pat_p1.bag_info.medicine_num;
                golden_mem[65536+8*pat_id_reg+5] = pat_p1.pkm_info.hp;

                golden_complete = 1;
                golden_err = No_Err;
                golden_out_info = pat_p1;
            end
        end
        Candy: begin
            if(pat_p1.pkm_info == 0) begin
                golden_complete = 0;
                golden_err = Not_Having_PKM;
                golden_out_info = 0;
            end
            else if(flag_bag_empty) begin
                golden_complete = 0;
                golden_err = Not_Having_Item;
                golden_out_info = 0;
            end
            else begin
                pat_p1.bag_info.candy_num = pat_p1.bag_info.candy_num - 1;
                if(pat_p1.pkm_info.pkm_type == Normal) begin
                    if(pat_p1.pkm_info.exp >= pkm_max_exp - 15)
                        pat_p1.pkm_info.exp = pkm_max_exp;
                    else
                        pat_p1.pkm_info.exp = pat_p1.pkm_info.exp + 15;
                end
                else begin
                    if(pat_p1.pkm_info.stage != Highest) begin
                        if(pat_p1.pkm_info.exp >= pkm_max_exp - 15) begin // evolve
                            pat_p1.pkm_info.stage = (pat_p1.pkm_info.stage << 1);
                            pat_p1.pkm_info.exp = 0;
                            case({pat_p1.pkm_info.pkm_type, pat_p1.pkm_info.stage})
                                {Grass, Middle}      : pat_p1.pkm_info.atk = 94;
                                {Grass, Highest}     : pat_p1.pkm_info.atk = 123;
                                {Fire, Middle}       : pat_p1.pkm_info.atk = 96;
                                {Fire, Highest}      : pat_p1.pkm_info.atk = 127;
                                {Water, Middle}      : pat_p1.pkm_info.atk = 89;
                                {Water, Highest}     : pat_p1.pkm_info.atk = 113;
                                {Electric, Middle}   : pat_p1.pkm_info.atk = 97;
                                {Electric, Highest}  : pat_p1.pkm_info.atk = 124;
                            endcase
                            case({pat_p1.pkm_info.pkm_type, pat_p1.pkm_info.stage})
                                {Grass, Middle}      : pat_p1.pkm_info.hp = 192;
                                {Grass, Highest}     : pat_p1.pkm_info.hp = 254;
                                {Fire, Middle}       : pat_p1.pkm_info.hp = 177;
                                {Fire, Highest}      : pat_p1.pkm_info.hp = 225;
                                {Water, Middle}      : pat_p1.pkm_info.hp = 187;
                                {Water, Highest}     : pat_p1.pkm_info.hp = 245;
                                {Electric, Middle}   : pat_p1.pkm_info.hp = 182;
                                {Electric, Highest}  : pat_p1.pkm_info.hp = 235;
                            endcase
                        end
                        else
                            pat_p1.pkm_info.exp = pat_p1.pkm_info.exp + 15;
                    end
                    else begin
                        pat_p1.pkm_info.exp = 0;
                    end
                end
                //golden
                golden_mem[65536+8*pat_id_reg+1][7:4] = pat_p1.bag_info.candy_num;
                golden_mem[65536+8*pat_id_reg+4][7:4] = pat_p1.pkm_info.stage;
                golden_mem[65536+8*pat_id_reg+7] = pat_p1.pkm_info.exp;
                golden_mem[65536+8*pat_id_reg+5] = pat_p1.pkm_info.hp;
                golden_mem[65536+8*pat_id_reg+6] = pat_p1.pkm_info.atk;

                golden_complete = 1;
                golden_err = No_Err;
                golden_out_info = pat_p1;
            end
        end
        Bracer: begin
            if(pat_p1.pkm_info == 0) begin
                golden_complete = 0;
                golden_err = Not_Having_PKM;
                golden_out_info = 0;
            end
            else if(flag_bag_empty) begin
                golden_complete = 0;
                golden_err = Not_Having_Item;
                golden_out_info = 0;
            end
            else begin
                pat_p1.bag_info.bracer_num = pat_p1.bag_info.bracer_num - 1;
                if(pat_p1.pkm_info.atk == pkm_base_atk_reg)
                    pat_p1.pkm_info.atk = pat_p1.pkm_info.atk + 32;

                // golden
                golden_mem[65536+8*pat_id_reg+6] = pat_p1.pkm_info.atk;
                golden_mem[65536+8*pat_id_reg+1][3:0] = pat_p1.bag_info.bracer_num;
                
                golden_complete = 1;
                golden_err = No_Err;
                golden_out_info = pat_p1;
            end

        end 
        Water_stone, Fire_stone, Thunder_stone: begin
            if(pat_p1.pkm_info == 0) begin
                golden_complete = 0;
                golden_err = Not_Having_PKM;
                golden_out_info = 0;
            end
            else if(flag_bag_empty) begin
                golden_complete = 0;
                golden_err = Not_Having_Item;
                golden_out_info = 0;
            end
            else begin
                pat_p1.bag_info.stone = No_stone;
                if(pat_p1.pkm_info.pkm_type == Normal) begin
                    if(pat_p1.pkm_info.exp == pkm_max_exp) begin // evolve
                        pat_p1.pkm_info.stage = Highest;
                        pat_p1.pkm_info.exp = 0;
                        case(pat_item_reg)
                            Water_stone: begin
                                pat_p1.pkm_info.hp  = 245;
                                pat_p1.pkm_info.atk = 113;
                                pat_p1.pkm_info.pkm_type = Water;
                            end
                            Fire_stone: begin
                                pat_p1.pkm_info.hp  = 225;
                                pat_p1.pkm_info.atk = 127;
                                pat_p1.pkm_info.pkm_type = Fire;
                            end
                            Thunder_stone: begin
                                pat_p1.pkm_info.hp  = 235;
                                pat_p1.pkm_info.atk = 124;
                                pat_p1.pkm_info.pkm_type = Electric;
                            end
                        endcase
                    end
                    else begin // can't evolve
                        pat_p1.bag_info.stone = No_stone;
                    end
                end

                // golden
                golden_mem[65536+8*pat_id_reg+2][7:6] = pat_p1.bag_info.stone;
                golden_mem[65536+8*pat_id_reg+4][7:4] = pat_p1.pkm_info.stage;
                golden_mem[65536+8*pat_id_reg+4][3:0] = pat_p1.pkm_info.pkm_type;
                golden_mem[65536+8*pat_id_reg+7] = pat_p1.pkm_info.exp;
                golden_mem[65536+8*pat_id_reg+5] = pat_p1.pkm_info.hp;
                golden_mem[65536+8*pat_id_reg+6] = pat_p1.pkm_info.atk;

                golden_complete = 1;
                golden_err = No_Err;
                golden_out_info = pat_p1;
            end
        end
    endcase


    @(negedge clk);
    inf.item_valid = 0;
    inf.D = 'bx; 
end endtask

//================================================================
//  attack
//================================================================
task attack_set_opp; begin
    //gap=$urandom_range(1,5);
    //repeat(gap)@(negedge clk);
    @(negedge clk);
    pat_atk_id_before = pat_id_opp_reg;
    pat_id_opp_reg = $urandom_range(0, 255);
    while(pat_id_opp_reg == pat_id_reg || pat_id_opp_reg == pat_atk_id_before) begin
        pat_id_opp_reg = $urandom_range(0, 255);
    end

    inf.id_valid = 1;
	inf.D.d_id = pat_id_opp_reg;

	pat_opp.bag_info = {golden_mem[65536+8*pat_id_opp_reg+0], golden_mem[65536+8*pat_id_opp_reg+1], golden_mem[65536+8*pat_id_opp_reg+2], golden_mem[65536+8*pat_id_opp_reg+3]};
	pat_opp.pkm_info = {golden_mem[65536+8*pat_id_opp_reg+4], golden_mem[65536+8*pat_id_opp_reg+5], golden_mem[65536+8*pat_id_opp_reg+6], golden_mem[65536+8*pat_id_opp_reg+7]};
	// pkm_base_atk_reg
    case({pat_opp.pkm_info.pkm_type, pat_opp.pkm_info.stage}) // type, stage
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
    if(pat_opp.pkm_info.atk != pkm_base_atk_reg)
        pat_opp.pkm_info.atk = pkm_base_atk_reg;
    @(negedge clk);
	inf.id_valid = 0;
	inf.D = 'x;
end endtask

task attack_atk; begin // complete
    if(pat_p1.pkm_info == 0 || pat_opp.pkm_info == 0) begin
        golden_complete = 0;
        golden_err = Not_Having_PKM;
        golden_out_info = 0;
    end     
    else if(pat_p1.pkm_info.hp == 0 || pat_opp.pkm_info.hp == 0) begin
        golden_complete = 0;
        golden_err = HP_is_Zero;
        golden_out_info = 0;
    end
    else begin
        if(pat_p1.pkm_info.pkm_type == pat_opp.pkm_info.pkm_type) begin
            if(pat_p1.pkm_info.pkm_type != Normal)
                damage = pat_p1.pkm_info.atk >> 1;
            else
                damage = pat_p1.pkm_info.atk;
        end
        else begin
            case({pat_p1.pkm_info.pkm_type, pat_opp.pkm_info.pkm_type})
                // 0.5
                {Grass, Fire}:      damage = pat_p1.pkm_info.atk >> 1; 
                {Fire, Water}:      damage = pat_p1.pkm_info.atk >> 1; 
                {Water, Grass}:     damage = pat_p1.pkm_info.atk >> 1; 
                {Electric, Grass}:  damage = pat_p1.pkm_info.atk >> 1; 
                // 2
                {Grass, Water}:     damage = pat_p1.pkm_info.atk << 1;
                {Fire, Grass}:      damage = pat_p1.pkm_info.atk << 1;
                {Water, Fire}:      damage = pat_p1.pkm_info.atk << 1;
                {Electric, Water}:  damage = pat_p1.pkm_info.atk << 1;
                default:            damage = pat_p1.pkm_info.atk;
            endcase
        end
    end
end endtask

task attack_hp; begin
    if(golden_complete) begin
        if(pat_opp.pkm_info.hp >= damage)
            pat_opp.pkm_info.hp = pat_opp.pkm_info.hp - damage;
        else
            pat_opp.pkm_info.hp = 0;
    end
end endtask

task attack_exp; begin
    // atk_reward_exp
    case(pat_opp.pkm_info.stage)
        Lowest:  atk_reward_exp = 16;
        Middle:  atk_reward_exp = 24;
        Highest: atk_reward_exp = 32;
    endcase
    // def_reward_exp
    case(pat_p1.pkm_info.stage)
        Lowest:  def_reward_exp = 8;
        Middle:  def_reward_exp = 12;
        Highest: def_reward_exp = 16;
    endcase
    // pkm_max_exp (p1)
    case({pat_p1.pkm_info.pkm_type, pat_p1.pkm_info.stage})
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
    // opp_max_exp (opp)
    case({pat_opp.pkm_info.pkm_type, pat_opp.pkm_info.stage})
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
    if(golden_complete) begin
        // pat_p1 (atk) atk_reward_exp pkm_max_exp
        if(pat_p1.pkm_info.pkm_type == Normal) begin
            if((pat_p1.pkm_info.exp >= pkm_max_exp - atk_reward_exp) || (pkm_max_exp < atk_reward_exp))
                pat_p1.pkm_info.exp = pkm_max_exp;
            else
                pat_p1.pkm_info.exp = pat_p1.pkm_info.exp + atk_reward_exp;
        end
        else begin
            if(pat_p1.pkm_info.stage != Highest) begin
                if((pat_p1.pkm_info.exp >= pkm_max_exp - atk_reward_exp) || (pkm_max_exp < atk_reward_exp)) begin // evolve
                    pat_p1.pkm_info.stage = (pat_p1.pkm_info.stage << 1);
                    pat_p1.pkm_info.exp = 0;
                    case({pat_p1.pkm_info.pkm_type, pat_p1.pkm_info.stage})
                        {Grass, Middle}     : pat_p1.pkm_info.atk = 94;
                        {Grass, Highest}    : pat_p1.pkm_info.atk = 123;
                        {Fire, Middle}      : pat_p1.pkm_info.atk = 96;
                        {Fire, Highest}     : pat_p1.pkm_info.atk = 127;
                        {Water, Middle}     : pat_p1.pkm_info.atk = 89;
                        {Water, Highest}    : pat_p1.pkm_info.atk = 113;
                        {Electric, Middle}  : pat_p1.pkm_info.atk = 97;
                        {Electric, Highest} : pat_p1.pkm_info.atk = 124;
                    endcase
                    case({pat_p1.pkm_info.pkm_type, pat_p1.pkm_info.stage})
                        {Grass, Middle}     : pat_p1.pkm_info.hp = 192;
                        {Grass, Highest}    : pat_p1.pkm_info.hp = 254;
                        {Fire, Middle}      : pat_p1.pkm_info.hp = 177;
                        {Fire, Highest}     : pat_p1.pkm_info.hp = 225;
                        {Water, Middle}     : pat_p1.pkm_info.hp = 187;
                        {Water, Highest}    : pat_p1.pkm_info.hp = 245;
                        {Electric, Middle}  : pat_p1.pkm_info.hp = 182;
                        {Electric, Highest} : pat_p1.pkm_info.hp = 235;
                    endcase
                end
                else
                    pat_p1.pkm_info.exp = pat_p1.pkm_info.exp + atk_reward_exp;
            end
            else
                pat_p1.pkm_info.exp = 0;
        end
        // pat_opp (def) def_reward_exp opp_max_exp
        if(pat_opp.pkm_info.pkm_type == Normal) begin
            if((pat_opp.pkm_info.exp > opp_max_exp - def_reward_exp) || (opp_max_exp < def_reward_exp))
                pat_opp.pkm_info.exp = opp_max_exp;
            else
                pat_opp.pkm_info.exp = pat_opp.pkm_info.exp + def_reward_exp;
        end
        else begin
            if(pat_opp.pkm_info.stage != Highest) begin
                if((pat_opp.pkm_info.exp >= opp_max_exp - def_reward_exp) || (opp_max_exp < def_reward_exp)) begin // evolve
                    pat_opp.pkm_info.stage = (pat_opp.pkm_info.stage << 1);
                    pat_opp.pkm_info.exp = 0;
                    case({pat_opp.pkm_info.pkm_type, pat_opp.pkm_info.stage})
                        {Grass, Middle}      : pat_opp.pkm_info.atk = 94;
                        {Grass, Highest}     : pat_opp.pkm_info.atk = 123;
                        {Fire, Middle}       : pat_opp.pkm_info.atk = 96;
                        {Fire, Highest}      : pat_opp.pkm_info.atk = 127;
                        {Water, Middle}      : pat_opp.pkm_info.atk = 89;
                        {Water, Highest}     : pat_opp.pkm_info.atk = 113;
                        {Electric, Middle}   : pat_opp.pkm_info.atk = 97;
                        {Electric, Highest}  : pat_opp.pkm_info.atk = 124;
                    endcase
                    case({pat_opp.pkm_info.pkm_type, pat_opp.pkm_info.stage})
                        {Grass, Middle}      : pat_opp.pkm_info.hp = 192;
                        {Grass, Highest}     : pat_opp.pkm_info.hp = 254;
                        {Fire, Middle}       : pat_opp.pkm_info.hp = 177;
                        {Fire, Highest}      : pat_opp.pkm_info.hp = 225;
                        {Water, Middle}      : pat_opp.pkm_info.hp = 187;
                        {Water, Highest}     : pat_opp.pkm_info.hp = 245;
                        {Electric, Middle}   : pat_opp.pkm_info.hp = 182;
                        {Electric, Highest}  : pat_opp.pkm_info.hp = 235;
                    endcase
                end
                else
                    pat_opp.pkm_info.exp = pat_opp.pkm_info.exp + def_reward_exp;
            end
            else
                pat_opp.pkm_info.exp = 0;
        end
    end
end endtask

task attack_reset; begin // attack end
    // pkm_base_atk_reg
    case({pat_p1.pkm_info.pkm_type, pat_p1.pkm_info.stage}) // type, stage
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
    if(golden_complete) begin
        if(pat_p1.pkm_info.atk > pkm_base_atk_reg)
            pat_p1.pkm_info.atk = pkm_base_atk_reg;
        // golden
        golden_out_info = {pat_p1.pkm_info, pat_opp.pkm_info};
        golden_complete = 1;
        golden_err = No_Err;

        // pat_p1
        golden_mem[65536+8*pat_id_reg+4][7:4] = pat_p1.pkm_info.stage;
        golden_mem[65536+8*pat_id_reg+4][3:0] = pat_p1.pkm_info.pkm_type;
        golden_mem[65536+8*pat_id_reg+7]      = pat_p1.pkm_info.exp;
        golden_mem[65536+8*pat_id_reg+5]      = pat_p1.pkm_info.hp;
        golden_mem[65536+8*pat_id_reg+6]      = pat_p1.pkm_info.atk;

        // pat_opp
        golden_mem[65536+8*pat_id_opp_reg+4][7:4] = pat_opp.pkm_info.stage;
        golden_mem[65536+8*pat_id_opp_reg+4][3:0] = pat_opp.pkm_info.pkm_type;
        golden_mem[65536+8*pat_id_opp_reg+7]      = pat_opp.pkm_info.exp;
        golden_mem[65536+8*pat_id_opp_reg+5]      = pat_opp.pkm_info.hp;
        golden_mem[65536+8*pat_id_opp_reg+6]      = pat_opp.pkm_info.atk;
    end
    else begin
        golden_out_info = 0;
        golden_complete = 0;
    end

end endtask

//================================================================
// wait_out_valid
//================================================================
task wait_out_valid; begin
    cycles = 0;
    while(inf.out_valid !== 1) begin
        cycles = cycles + 1;
        /*
        if(cycles == 1200) begin
            $display ("---------------------------------------------------------");
            $display ("                    FAIL!                                ");
            $display ("     The execution cycles are over 1200   cycles         ");
            $display ("---------------------------------------------------------");

            repeat(2)@(negedge clk);
            $finish;
        end
        */
        @(negedge clk);
    end
  total_cycles = total_cycles + cycles;
end endtask

//================================================================
// check_ans
//================================================================
task check_ans; begin
	cycles = 0;
	while (inf.out_valid === 1) begin
		if (cycles >= 1) begin
            /*
			$display ("--------------------------------------------------");
			$display ("                       FAIL                      ");
			$display ("          Outvalid is more than 1 cycles          ");
			$display ("--------------------------------------------------");
			repeat(2) @(negedge clk);
            
			$finish;
            */
		end
		else begin
			if((inf.complete !== golden_complete)||(inf.err_msg !== golden_err)||(inf.out_info !== golden_out_info)) begin
                $display ("Wrong Answer");
    			$finish;
    		end
		end
		@(negedge clk);
		cycles = cycles + 1;
	end
end endtask
//================================================================
endprogram