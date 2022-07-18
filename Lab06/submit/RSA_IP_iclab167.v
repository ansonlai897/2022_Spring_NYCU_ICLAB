//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : RSA_IP.v
//   Module Name : RSA_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module RSA_IP #(parameter WIDTH = 3) (
    // Input signals
    IN_P, IN_Q, IN_E,
    // Output signals
    OUT_N, OUT_D
);
// ===============================================================
// Declaration
// ===============================================================
input  [WIDTH-1:0]   IN_P, IN_Q;
input  [WIDTH*2-1:0] IN_E;
output [WIDTH*2-1:0] OUT_N, OUT_D;

// ===============================================================
// Soft IP DESIGN
// ===============================================================
assign OUT_N = IN_P * IN_Q;
wire [WIDTH*2-1:0] q = OUT_N - IN_P - IN_Q + 1;

wire signed [WIDTH*2-1:0] out;
// IN_P, IN_Q, IN_E,
genvar level_idx;
generate 
    // divide
    for(level_idx = 1 ; level_idx <= 7  ; level_idx= level_idx+1)begin:gen_level
        if(level_idx == 1 )begin:   if_lv_1 // down 2
            wire signed [WIDTH*2-1:0] arr_1[0:1][0:1] ;

            assign arr_1[0][0] = IN_E;
            assign arr_1[0][1] = 1;
            assign arr_1[1][0] = q % IN_E;
            assign arr_1[1][1] = ~ (q / IN_E) + 1; 
        end
        if(level_idx == 2 )begin:   if_lv_2 // up 2
            wire signed [WIDTH*2-1:0] arr_2[0:1][0:1] ;

            assign arr_2[0][0] = (gen_level[level_idx-1].if_lv_1.arr_1[1][0] == 1) ? 
            gen_level[level_idx-1].if_lv_1.arr_1[0][0] : 
            gen_level[level_idx-1].if_lv_1.arr_1[0][0] % gen_level[level_idx-1].if_lv_1.arr_1[1][0];

            assign arr_2[0][1] = (gen_level[level_idx-1].if_lv_1.arr_1[1][0] == 1) ? 
            gen_level[level_idx-1].if_lv_1.arr_1[0][1] : 
            1 + gen_level[level_idx-1].if_lv_1.arr_1[0][1] + ~(gen_level[level_idx-1].if_lv_1.arr_1[1][1] * 
            (gen_level[level_idx-1].if_lv_1.arr_1[0][0] / gen_level[level_idx-1].if_lv_1.arr_1[1][0] ));
                                       
            assign arr_2[1][0] = gen_level[level_idx-1].if_lv_1.arr_1[1][0];
            assign arr_2[1][1] = gen_level[level_idx-1].if_lv_1.arr_1[1][1]; 
        end
        if(level_idx == 3 )begin:   if_lv_3 // down 2
            wire signed [WIDTH*2-1:0] arr_3[0:1][0:1] ;

            assign arr_3[0][0] = gen_level[level_idx-1].if_lv_2.arr_2[0][0];
            assign arr_3[0][1] = gen_level[level_idx-1].if_lv_2.arr_2[0][1];

            assign arr_3[1][0] = (gen_level[level_idx-1].if_lv_2.arr_2[0][0] == 1) ? 
            gen_level[level_idx-1].if_lv_2.arr_2[1][0] : 
            gen_level[level_idx-1].if_lv_2.arr_2[1][0] % gen_level[level_idx-1].if_lv_2.arr_2[0][0];

            assign arr_3[1][1] = (gen_level[level_idx-1].if_lv_2.arr_2[0][0] == 1) ? 
            gen_level[level_idx-1].if_lv_2.arr_2[1][1] : 
            1 + gen_level[level_idx-1].if_lv_2.arr_2[1][1] + 
            ~(gen_level[level_idx-1].if_lv_2.arr_2[0][1] * 
            (gen_level[level_idx-1].if_lv_2.arr_2[1][0] / gen_level[level_idx-1].if_lv_2.arr_2[0][0] ));
        end
        if(level_idx == 4 )begin:   if_lv_4 // up 2
            wire signed [WIDTH*2-1:0] arr_4[0:1][0:1] ;

            assign arr_4[0][0] = (gen_level[level_idx-1].if_lv_3.arr_3[1][0] == 1) ? 
            gen_level[level_idx-1].if_lv_3.arr_3[0][0] : 
            gen_level[level_idx-1].if_lv_3.arr_3[0][0] % gen_level[level_idx-1].if_lv_3.arr_3[1][0];

            assign arr_4[0][1] = (gen_level[level_idx-1].if_lv_3.arr_3[1][0] == 1) ? 
            gen_level[level_idx-1].if_lv_3.arr_3[0][1] : 
            1 + gen_level[level_idx-1].if_lv_3.arr_3[0][1] + ~(gen_level[level_idx-1].if_lv_3.arr_3[1][1] * 
            (gen_level[level_idx-1].if_lv_3.arr_3[0][0] / gen_level[level_idx-1].if_lv_3.arr_3[1][0] ));
                                       
            assign arr_4[1][0] = gen_level[level_idx-1].if_lv_3.arr_3[1][0];
            assign arr_4[1][1] = gen_level[level_idx-1].if_lv_3.arr_3[1][1]; 
        end
        if(level_idx == 5 )begin:   if_lv_5 // down 2
            wire signed [WIDTH*2-1:0] arr_5[0:1][0:1] ;

            assign arr_5[0][0] = gen_level[level_idx-1].if_lv_4.arr_4[0][0];
            assign arr_5[0][1] = gen_level[level_idx-1].if_lv_4.arr_4[0][1];

            assign arr_5[1][0] = (gen_level[level_idx-1].if_lv_4.arr_4[0][0] == 1) ? 
            gen_level[level_idx-1].if_lv_4.arr_4[1][0] : 
            gen_level[level_idx-1].if_lv_4.arr_4[1][0] % gen_level[level_idx-1].if_lv_4.arr_4[0][0];

            assign arr_5[1][1] = (gen_level[level_idx-1].if_lv_4.arr_4[0][0] == 1) ? 
            gen_level[level_idx-1].if_lv_4.arr_4[1][1] : 
            1 + gen_level[level_idx-1].if_lv_4.arr_4[1][1] + 
            ~(gen_level[level_idx-1].if_lv_4.arr_4[0][1] * 
            (gen_level[level_idx-1].if_lv_4.arr_4[1][0] / gen_level[level_idx-1].if_lv_4.arr_4[0][0] ));
        end
        if(level_idx == 6 )begin:   if_lv_6 // up 2
            wire signed [WIDTH*2-1:0] arr_6[0:1][0:1] ;

            assign arr_6[0][0] = (gen_level[level_idx-1].if_lv_5.arr_5[1][0] == 1) ? 
            gen_level[level_idx-1].if_lv_5.arr_5[0][0] : 
            gen_level[level_idx-1].if_lv_5.arr_5[0][0] % gen_level[level_idx-1].if_lv_5.arr_5[1][0];

            assign arr_6[0][1] = (gen_level[level_idx-1].if_lv_5.arr_5[1][0] == 1) ? 
            gen_level[level_idx-1].if_lv_5.arr_5[0][1] : 
            1 + gen_level[level_idx-1].if_lv_5.arr_5[0][1] + ~(gen_level[level_idx-1].if_lv_5.arr_5[1][1] * 
            (gen_level[level_idx-1].if_lv_5.arr_5[0][0] / gen_level[level_idx-1].if_lv_5.arr_5[1][0] ));
                                       
            assign arr_6[1][0] = gen_level[level_idx-1].if_lv_5.arr_5[1][0];
            assign arr_6[1][1] = gen_level[level_idx-1].if_lv_5.arr_5[1][1]; 
        end
        if(level_idx == 7 )begin:   if_lv_7 // down 2
            assign out = (gen_level[level_idx-1].if_lv_6.arr_6[1][0] == 1) ?
            gen_level[level_idx-1].if_lv_6.arr_6[1][1] : gen_level[level_idx-1].if_lv_6.arr_6[0][1] ;
        end
    end     
endgenerate
assign OUT_D = (out[WIDTH*2-1] == 1) ? out + q : out;

endmodule