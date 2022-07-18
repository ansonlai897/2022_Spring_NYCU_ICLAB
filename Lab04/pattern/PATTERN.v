`ifdef RTL
    `timescale 1ns/1fs
    `include "NN.v"  
    `define CYCLE_TIME 42.5
`endif
`ifdef GATE
    `timescale 1ns/1fs
    `include "NN_SYN.v"
    `define CYCLE_TIME 42.5
`endif


// TO DO    : Dump file for Debuging
// TO Solve : error calculation when golden is zero
// TO Solve : NaN in IEEE 754 problem check


// When I use the real tpye, it may cause undetected errors in the following condition
// 1. golden = 0
// 2. NaN appears


module PATTERN(
    // Output signals
    clk,
    rst_n,
    in_valid_i,
    in_valid_k,
    in_valid_o,
    Image1,
    Image2,
    Image3,
    Kernel1,
    Kernel2,
    Kernel3,
    Opt,
    // Input signals
    out_valid,
    out
);
//================================================================
//      PARAMETER FOR PORT
//================================================================
parameter inst_sig_width       = 23;
parameter inst_exp_width       = 8;
parameter inst_ieee_compliance = 1;
parameter inst_arch            = 0;

parameter imag_num = 3;
parameter imag_len = 4;

parameter kern_num = 4;
parameter kern_len = 3;

//======================================
//          I/O PORTS
//======================================
output reg                                   clk, rst_n;
output reg                                   in_valid_i;
output reg                                   in_valid_k;
output reg                                   in_valid_o;

output reg [inst_sig_width+inst_exp_width:0]   Kernel1;
output reg [inst_sig_width+inst_exp_width:0]   Kernel2;
output reg [inst_sig_width+inst_exp_width:0]   Kernel3;

output reg [inst_sig_width+inst_exp_width:0]    Image1;
output reg [inst_sig_width+inst_exp_width:0]    Image2;
output reg [inst_sig_width+inst_exp_width:0]    Image3;

output reg [1:0]                                   Opt;

input                                        out_valid;
input      [inst_sig_width+inst_exp_width:0]       out;

//======================================
//      PARAMETERS & VARIABLES
//======================================
parameter PATNUM = 100;
parameter CYCLE  = `CYCLE_TIME;
parameter DELAY  = 450;
integer   SEED   = 122;
reg[10:0] cnt;

// PATTERN CONTROL
integer       i;
integer       j;
integer       k;
integer       m;
integer    stop;
integer     pat;
integer exe_lat;
integer out_lat;
integer tot_lat;

// FILE CONTROL
integer file_tot;
integer file_idx1;
integer file_idx2;
integer file_idx3;
integer file_out;
real temp;

// INPUT INFO
reg [1:0]                              opt_in;
reg [inst_sig_width+inst_exp_width:0] imag_in[0:imag_num-1][0:imag_len+1][0:imag_len+1];               // Image  num : 3,   Size : 4x4, Padding : 6x6
reg [inst_sig_width+inst_exp_width:0] kern_in[0:imag_num-1][0:kern_num-1][0:kern_len-1][0:kern_len-1]; // Kernel num : 3x4, Size : 3x3

// OUTPUT INFO
reg [inst_sig_width+inst_exp_width:0] conv_gold[0:imag_num-1][0:kern_num-1][0:imag_len-1][0:imag_len-1]; // Convolution for 3 Image and 4 kernel
reg [inst_sig_width+inst_exp_width:0]  add_gold[0:kern_num-1][0:imag_len-1][0:imag_len-1];               // Addition for convolution outcome
reg [inst_sig_width+inst_exp_width:0] acti_gold[0:kern_num-1][0:imag_len-1][0:imag_len-1];
reg [inst_sig_width+inst_exp_width:0] shuf_gold[0:7][0:7];
reg [inst_sig_width+inst_exp_width:0] out_check;

reg [inst_sig_width+inst_exp_width:0] your_image[0:7][0:7];

// TEMP RESULT FOR CALCULATION
wire [inst_sig_width+inst_exp_width:0] conv_w[0:imag_num-1][0:kern_num-1][0:imag_len-1][0:imag_len-1];
wire [inst_sig_width+inst_exp_width:0]  add_w[0:kern_num-1][0:imag_len-1][0:imag_len-1];
wire [inst_sig_width+inst_exp_width:0] acti_w[0:kern_num-1][0:imag_len-1][0:imag_len-1];

// ERROR CHECK
wire [inst_sig_width+inst_exp_width:0] error_lim_pos = 32'h3A6BEDFA;
wire [inst_sig_width+inst_exp_width:0] error_lim_neg = 32'hBA6BEDFA;

wire [inst_sig_width+inst_exp_width:0] up_bound ;
wire [inst_sig_width+inst_exp_width:0] low_bound;

wire [inst_sig_width+inst_exp_width:0] error_diff;
wire up_flag, low_flag;

// DISPLAY 
real err_real;
real your_real;
real gold_real;

//======================================
//              MAIN
//======================================
initial exe_task;

//======================================
//              Clock
//======================================
initial clk = 1'b0;
always #(CYCLE/2.0) clk = ~clk;

//======================================
//              TASKS
//======================================
task exe_task; begin
    reset_task;
    for (pat=0 ; pat<PATNUM ; pat=pat+1) begin
        input_task;
        cal_task;
        wait_task;
        check_task;
        $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %3d\033[m", pat ,exe_lat);
    end
    pass_task;
end endtask

task reset_task; begin

    force clk  = 0;
    rst_n      = 1;
    
    in_valid_i = 0;
    in_valid_k = 0;
    in_valid_o = 0;
    
    Image1     = 'dx;
    Image2     = 'dx;
    Image3     = 'dx;
    
    Kernel1    = 'dx;
    Kernel2    = 'dx;
    Kernel3    = 'dx;

    Opt        = 'dx;
    

    tot_lat = 0;

    #(CYCLE/2.0) rst_n = 0;
    #(CYCLE/2.0) rst_n = 1;
    if (out_valid !== 0 || out !== 0) begin
        $display("                                           `:::::`                                                       ");
        $display("                                          .+-----++                                                      ");
        $display("                .--.`                    o:------/o                                                      ");
        $display("              /+:--:o/                   //-------y.          -//:::-        `.`                         ");
        $display("            `/:------y:                  `o:--::::s/..``    `/:-----s-    .:/:::+:                       ");
        $display("            +:-------:y                `.-:+///::-::::://:-.o-------:o  `/:------s-                      ");
        $display("            y---------y-        ..--:::::------------------+/-------/+ `+:-------/s                      ");
        $display("           `s---------/s       +:/++/----------------------/+-------s.`o:--------/s                      ");
        $display("           .s----------y-      o-:----:---------------------/------o: +:---------o:                      ");
        $display("           `y----------:y      /:----:/-------/o+----------------:+- //----------y`                      ");
        $display("            y-----------o/ `.--+--/:-/+--------:+o--------------:o: :+----------/o                       ");
        $display("            s:----------:y/-::::::my-/:----------/---------------+:-o-----------y.                       ");
        $display("            -o----------s/-:hmmdy/o+/:---------------------------++o-----------/o                        ");
        $display("             s:--------/o--hMMMMMh---------:ho-------------------yo-----------:s`                        ");
        $display("             :o--------s/--hMMMMNs---------:hs------------------+s------------s-                         ");
        $display("              y:-------o+--oyhyo/-----------------------------:o+------------o-                          ");
        $display("              -o-------:y--/s--------------------------------/o:------------o/                           ");
        $display("               +/-------o+--++-----------:+/---------------:o/-------------+/                            ");
        $display("               `o:-------s:--/+:-------/o+-:------------::+d:-------------o/                             ");
        $display("                `o-------:s:---ohsoosyhh+----------:/+ooyhhh-------------o:                              ");
        $display("                 .o-------/d/--:h++ohy/---------:osyyyyhhyyd-----------:o-                               ");
        $display("                 .dy::/+syhhh+-::/::---------/osyyysyhhysssd+---------/o`                                ");
        $display("                  /shhyyyymhyys://-------:/oyyysyhyydysssssyho-------od:                                 ");
        $display("                    `:hhysymmhyhs/:://+osyyssssydyydyssssssssyyo+//+ymo`                                 ");
        $display("                      `+hyydyhdyyyyyyyyyyssssshhsshyssssssssssssyyyo:`                                   ");
        $display("                        -shdssyyyyyhhhhhyssssyyssshssssssssssssyy+.    Output signal should be 0         ");
        $display("                         `hysssyyyysssssssssssssssyssssssssssshh+                                        ");
        $display("                        :yysssssssssssssssssssssssssssssssssyhysh-     after the reset signal is asserted");
        $display("                      .yyhhdo++oosyyyyssssssssssssssssssssssyyssyh/                                      ");
        $display("                      .dhyh/--------/+oyyyssssssssssssssssssssssssy:   at %4d ps                         ", $time*1000);
        $display("                       .+h/-------------:/osyyysssssssssssssssyyh/.                                      ");
        $display("                        :+------------------::+oossyyyyyyyysso+/s-                                       ");
        $display("                       `s--------------------------::::::::-----:o                                       ");
        $display("                       +:----------------------------------------y`                                      ");
        repeat(5) #(CYCLE);
        $finish;
    end
    #(CYCLE/2.0) release clk;
end endtask

task input_task; begin
    //----------------------------
    // Prepare for Data
    //----------------------------
    // Option Random
    if(opt_in < 3)
        opt_in =  opt_in + 1;
    else 
        opt_in = 0;

    //----------------------
    // For easy pattern
    //----------------------
   // if(pat < 100) begin
        // Image Random w/o padding
        for(i=0 ; i<=imag_num ; i=i+1) begin
            for(j=1 ; j<=imag_len ; j=j+1) begin
                for(k=1 ; k<=imag_len ; k=k+1) begin
                    imag_in[i][j][k] = 0;
                    imag_in[i][j][k][inst_sig_width+:inst_exp_width] = {$random(SEED)} % 11 + 127;
                    imag_in[i][j][k][inst_sig_width+inst_exp_width]  = {$random(SEED)} % 2;
                end
            end
        end

        // Kernel Random
        for(i=0 ; i<imag_num ; i=i+1) begin
            for(j=0 ; j<kern_num ; j=j+1) begin
                for(k=0 ; k<kern_len ; k=k+1) begin
                    for(m=0 ; m<kern_len ; m=m+1) begin
                        kern_in[i][j][k][m] = 0;
                        kern_in[i][j][k][m][inst_sig_width+:inst_exp_width] = {$random(SEED)} % 11 + 127;
                        kern_in[i][j][k][m][inst_sig_width+inst_exp_width]  = {$random(SEED)} % 2;
                    end
                end
            end
        end
   // end
    //----------------------
    // For normal pattern
    //----------------------
   // else begin
        // Image Random w/o padding
        for(i=0 ; i<=imag_num ; i=i+1) begin
            for(j=1 ; j<=imag_len ; j=j+1) begin
                for(k=1 ; k<=imag_len ; k=k+1) begin
                    imag_in[i][j][k][0             +:inst_sig_width] = $random(SEED);
                    imag_in[i][j][k][inst_sig_width+:inst_exp_width] = {$random(SEED)} % 120 + 60;
                end
            end
        end

        // Kernel Random
        for(i=0 ; i<imag_num ; i=i+1) begin
            for(j=0 ; j<kern_num ; j=j+1) begin
                for(k=0 ; k<kern_len ; k=k+1) begin
                    for(m=0 ; m<kern_len ; m=m+1) begin
                        kern_in[i][j][k][m][0             +:inst_sig_width] = $random(SEED);
                        kern_in[i][j][k][m][inst_sig_width+:inst_exp_width] = {$random(SEED)} % 3 + 127;
                    end
                end
            end
        end
  // end

    // Padding for Image
    if(opt_in === 2'b10 || opt_in === 2'b11) begin
        for(i=0 ; i<=imag_num ; i=i+1) begin
            for(j=0 ; j<=imag_len+1 ; j=j+1) begin
                for(k=0 ; k<=imag_len+1 ; k=k+1) begin
                    if(k==0 || k==imag_len+1 || j==0 || j==imag_len+1) begin
                        imag_in[i][j][k] = 0;
                    end
                end
            end
        end
    end
    else begin
        for(i=0 ; i<=imag_num ; i=i+1) begin
            imag_in[i][0]         [0]          = imag_in[i][1]       [1];
            imag_in[i][0]         [imag_len+1] = imag_in[i][0]       [imag_len];
            imag_in[i][imag_len+1][0]          = imag_in[i][imag_len][0];
            imag_in[i][imag_len+1][imag_len+1] = imag_in[i][imag_len][imag_len];

            for(j=0 ; j<=imag_len+1 ; j=j+1) begin
                imag_in[i][j][0]          = imag_in[i][j][1];
                imag_in[i][j][imag_len+1] = imag_in[i][j][imag_len];
            end

            for(k=0 ; k<=imag_len+1 ; k=k+1) begin
                imag_in[i][0]         [k] = imag_in[i][1]       [k];
                imag_in[i][imag_len+1][k] = imag_in[i][imag_len][k];
            end
        end
    end

    //-----------------
    // Transfer input
    //-----------------
    repeat( ({$random(SEED)} % 3 + 2) ) @(negedge clk);

    // Option
    in_valid_o = 1;
    Opt        = opt_in;
    @(negedge clk);

    in_valid_o = 0;
    Opt        = 'dx;

    // Image
    repeat(2)@(negedge clk);
    for(j=1 ; j<=imag_len ; j=j+1) begin
        for(k=1 ; k<=imag_len ; k=k+1) begin
            in_valid_i = 1'b1;
            Image1    = imag_in[0][j][k];
            Image2    = imag_in[1][j][k];
            Image3    = imag_in[2][j][k];
            @(negedge clk);
        end
    end

    in_valid_i = 1'b0;
    Image1    = 'dx;
    Image2    = 'dx;
    Image3    = 'dx;

    // Kernel
    repeat(2)@(negedge clk);
    for(j=0 ; j<kern_num ; j=j+1) begin
        for(k=0 ; k<kern_len ; k=k+1) begin
            for(m=0 ; m<kern_len ; m=m+1) begin
                in_valid_k = 1'b1;
                Kernel1   = kern_in[0][j][k][m];
                Kernel2   = kern_in[1][j][k][m];
                Kernel3   = kern_in[2][j][k][m];
                @(negedge clk);
            end
        end
    end

    in_valid_k = 1'b0;
    Kernel1   = 'dx;
    Kernel2   = 'dx;
    Kernel3   = 'dx;
end endtask

task cal_task; begin
    conv_task;
    add_task;
    acti_task;
    shuf_task;
    dump_hex_task;
    dump_float_task;
end endtask

task wait_task; begin
    exe_lat = -1;
    while (out_valid !== 1) begin
        if (out !== 0) begin
            $display("                                           `:::::`                                                       ");
            $display("                                          .+-----++                                                      ");
            $display("                .--.`                    o:------/o                                                      ");
            $display("              /+:--:o/                   //-------y.          -//:::-        `.`                         ");
            $display("            `/:------y:                  `o:--::::s/..``    `/:-----s-    .:/:::+:                       ");
            $display("            +:-------:y                `.-:+///::-::::://:-.o-------:o  `/:------s-                      ");
            $display("            y---------y-        ..--:::::------------------+/-------/+ `+:-------/s                      ");
            $display("           `s---------/s       +:/++/----------------------/+-------s.`o:--------/s                      ");
            $display("           .s----------y-      o-:----:---------------------/------o: +:---------o:                      ");
            $display("           `y----------:y      /:----:/-------/o+----------------:+- //----------y`                      ");
            $display("            y-----------o/ `.--+--/:-/+--------:+o--------------:o: :+----------/o                       ");
            $display("            s:----------:y/-::::::my-/:----------/---------------+:-o-----------y.                       ");
            $display("            -o----------s/-:hmmdy/o+/:---------------------------++o-----------/o                        ");
            $display("             s:--------/o--hMMMMMh---------:ho-------------------yo-----------:s`                        ");
            $display("             :o--------s/--hMMMMNs---------:hs------------------+s------------s-                         ");
            $display("              y:-------o+--oyhyo/-----------------------------:o+------------o-                          ");
            $display("              -o-------:y--/s--------------------------------/o:------------o/                           ");
            $display("               +/-------o+--++-----------:+/---------------:o/-------------+/                            ");
            $display("               `o:-------s:--/+:-------/o+-:------------::+d:-------------o/                             ");
            $display("                `o-------:s:---ohsoosyhh+----------:/+ooyhhh-------------o:                              ");
            $display("                 .o-------/d/--:h++ohy/---------:osyyyyhhyyd-----------:o-                               ");
            $display("                 .dy::/+syhhh+-::/::---------/osyyysyhhysssd+---------/o`                                ");
            $display("                  /shhyyyymhyys://-------:/oyyysyhyydysssssyho-------od:                                 ");
            $display("                    `:hhysymmhyhs/:://+osyyssssydyydyssssssssyyo+//+ymo`                                 ");
            $display("                      `+hyydyhdyyyyyyyyyyssssshhsshyssssssssssssyyyo:`                                   ");
            $display("                        -shdssyyyyyhhhhhyssssyyssshssssssssssssyy+.    Output signal should be 0         ");
            $display("                         `hysssyyyysssssssssssssssyssssssssssshh+                                        ");
            $display("                        :yysssssssssssssssssssssssssssssssssyhysh-     when the out_valid is pulled down ");
            $display("                      .yyhhdo++oosyyyyssssssssssssssssssssssyyssyh/                                      ");
            $display("                      .dhyh/--------/+oyyyssssssssssssssssssssssssy:   at %4d ps                         ", $time*1000);
            $display("                       .+h/-------------:/osyyysssssssssssssssyyh/.                                      ");
            $display("                        :+------------------::+oossyyyyyyyysso+/s-                                       ");
            $display("                       `s--------------------------::::::::-----:o                                       ");
            $display("                       +:----------------------------------------y`                                      ");
            repeat(5) #(CYCLE);
            $finish;
        end
        if (exe_lat == DELAY) begin
            $display("                                   ..--.                                ");                          
            $display("                                `:/:-:::/-                              ");                         
            $display("                                `/:-------o                             ");
            $display("                                /-------:o:                             "); 
            $display("                                +-:////+s/::--..                        ");                         
            $display("    The execution latency      .o+/:::::----::::/:-.       at %-12d ps  ", $time*1000);                         
            $display("    is over %5d   cycles    `:::--:/++:----------::/:.                ", DELAY);                          
            $display("                            -+:--:++////-------------::/-               ");                          
            $display("                            .+---------------------------:/--::::::.`   ");                          
            $display("                          `.+-----------------------------:o/------::.  ");                          
            $display("                       .-::-----------------------------:--:o:-------:  ");                          
            $display("                     -:::--------:/yy------------------/y/--/o------/-  ");                          
            $display("                    /:-----------:+y+:://:--------------+y--:o//:://-   ");                          
            $display("                   //--------------:-:+ssoo+/------------s--/. ````     ");                          
            $display("                   o---------:/:------dNNNmds+:----------/-//           ");                          
            $display("                   s--------/o+:------yNNNNNd/+--+y:------/+            ");                          
            $display("                 .-y---------o:-------:+sso+/-:-:yy:------o`            ");                          
            $display("              `:oosh/--------++-----------------:--:------/.            ");                          
            $display("              +ssssyy--------:y:---------------------------/            ");                          
            $display("              +ssssyd/--------/s/-------------++-----------/`           ");                          
            $display("              `/yyssyso/:------:+o/::----:::/+//:----------+`           ");                          
            $display("             ./osyyyysssso/------:/++o+++///:-------------/:            ");                          
            $display("           -osssssssssssssso/---------------------------:/.             ");                          
            $display("         `/sssshyssssssssssss+:---------------------:/+ss               ");                          
            $display("        ./ssssyysssssssssssssso:--------------:::/+syyys+               ");                          
            $display("     `-+sssssyssssssssssssssssso-----::/++ooooossyyssyy:                ");                          
            $display("     -syssssyssssssssssssssssssso::+ossssssssssssyyyyyss+`              ");                          
            $display("     .hsyssyssssssssssssssssssssyssssssssssyhhhdhhsssyssso`             ");                          
            $display("     +/yyshsssssssssssssssssssysssssssssyhhyyyyssssshysssso             ");                          
            $display("    ./-:+hsssssssssssssssssssssyyyyyssssssssssssssssshsssss:`           ");                          
            $display("    /---:hsyysyssssssssssssssssssssssssssssssssssssssshssssy+           ");                          
            $display("    o----oyy:-:/+oyysssssssssssssssssssssssssssssssssshssssy+-          ");                          
            $display("    s-----++-------/+sysssssssssssssssssssssssssssssyssssyo:-:-         ");                          
            $display("    o/----s-----------:+syyssssssssssssssssssssssyso:--os:----/.        ");                          
            $display("    `o/--:o---------------:+ossyysssssssssssyyso+:------o:-----:        ");                          
            $display("      /+:/+---------------------:/++ooooo++/:------------s:---::        ");                          
            $display("       `/o+----------------------------------------------:o---+`        ");                          
            $display("         `+-----------------------------------------------o::+.         ");                          
            $display("          +-----------------------------------------------/o/`          ");                          
            $display("          ::----------------------------------------------:-            ");
            repeat(5) @(negedge clk);
            $finish; 
        end
        exe_lat = exe_lat + 1;
        //cnt = cnt + 1;
        @(negedge clk);
    end
end endtask

task check_task; begin
    out_lat = 0;
    i = 0;
    j = 0;
    while (out_valid === 1) begin
        if (out_lat == 64) begin
            $display("                                                                                ");
            $display("                                                   ./+oo+/.                     ");
            $display("    Out cycles is more than 64                    /s:-----+s`     at %-12d ps   ", $time*1000);
            $display("                                                  y/-------:y                   ");
            $display("                                             `.-:/od+/------y`                  ");
            $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");
            $display("                              -m+:::::::---------------------::o+.              ");
            $display("                             `hod-------------------------------:o+             ");
            $display("                       ./++/:s/-o/--------------------------------/s///::.      ");
            $display("                      /s::-://--:--------------------------------:oo/::::o+     ");
            $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");
            $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");
            $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");
            $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");
            $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");
            $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");
            $display("                 s:----------------/s+///------------------------------o`       ");
            $display("           ``..../s------------------::--------------------------------o        ");
            $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");
            $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");
            $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");
            $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");
            $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");
            $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");
            $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");
            $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");
            $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");
            $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");
            $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");
            $display("  `s+--------------------------------------:syssssssssssssssyo                  ");
            $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");
            $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");
            $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");
            $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");
            $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");
            $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");
            $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");
            $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");
            $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");
            $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");
            $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   ");
            repeat(5) @(negedge clk);
            $finish;
        end

        //====================
        // Check
        //====================
        // Out_x and Out_y
        your_image[i][j] = out;
        out_check        = shuf_gold[i][j];
        //convert_float(error_diff,       err_real);
        convert_float(out_check,  gold_real);
        convert_float(out, your_real);
        if(out_check !== 0) err_real = (your_real - gold_real) / gold_real;
        else                err_real = (your_real - gold_real);
        //if(error_diff !== 0 && up_flag == low_flag) begin
        if(err_real >= 0.0009 || err_real <= -0.0009) begin
            $display("                                                                                ");
            $display("                                                   ./+oo+/.                     ");
            $display("    Err is too large!!!                            /s:-----+s`     at %-12d ps   ", $time*1000);
            $display("                                                  y/-------:y                   ");
            $display("                                             `.-:/od+/------y`                  ");
            $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");
            $display("                              -m+:::::::---------------------::o+.              ");
            $display("                             `hod-------------------------------:o+             ");
            $display("                       ./++/:s/-o/--------------------------------/s///::.      ");
            $display("                      /s::-://--:--------------------------------:oo/::::o+     ");
            $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");
            $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");
            $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");
            $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");
            $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");
            $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");
            $display("                 s:----------------/s+///------------------------------o`       ");
            $display("           ``..../s------------------::--------------------------------o        ");
            $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");
            $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");
            $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");
            $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");
            $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");
            $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");
            $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");
            $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");
            $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");
            $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");
            $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");
            $display("  `s+--------------------------------------:syssssssssssssssyo                  ");
            $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");
            $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");
            $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");
            $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");
            $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");
            $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");
            $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");
            $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");
            $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");
            $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");
            $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   ");
            $display("The index of pixel is ( %-1d, %-1d )", i, j);
            $display("Your pixel is         %-50f", your_real);
            $display("Gold pixel is         %-50f", gold_real);
            $display("The value of error is %-10f", err_real);
            repeat(5) @(negedge clk);
            $finish;
        end

        if ( i<8 && j<8 ) begin
            // Update index
            if ( i<8 )  j=j+1;
            if ( j==8 ) begin
                i=i+1;
                j=0;
            end
        end
        out_lat = out_lat + 1;
        @(negedge clk);
    end

    if (out_lat<64) begin     
        $display("                                                                                ");
        $display("                                                   ./+oo+/.                     ");
        $display("    Out cycles is less than 64                    /s:-----+s`     at %-12d ps   ", $time*1000);
        $display("                                                  y/-------:y                   ");
        $display("                                             `.-:/od+/------y`                  ");
        $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");
        $display("                              -m+:::::::---------------------::o+.              ");
        $display("                             `hod-------------------------------:o+             ");
        $display("                       ./++/:s/-o/--------------------------------/s///::.      ");
        $display("                      /s::-://--:--------------------------------:oo/::::o+     ");
        $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");
        $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");
        $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");
        $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");
        $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");
        $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");
        $display("                 s:----------------/s+///------------------------------o`       ");
        $display("           ``..../s------------------::--------------------------------o        ");
        $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");
        $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");
        $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");
        $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");
        $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");
        $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");
        $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");
        $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");
        $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");
        $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");
        $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");
        $display("  `s+--------------------------------------:syssssssssssssssyo                  ");
        $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");
        $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");
        $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");
        $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");
        $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");
        $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");
        $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");
        $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");
        $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");
        $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");
        $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   "); 
        repeat(5) @(negedge clk);
        $finish;
    end

    tot_lat = tot_lat + exe_lat;
end endtask

task pass_task; begin
    $display("\033[1;33m                `oo+oy+`                            \033[1;35m Congratulation!!! \033[1;0m                                   ");
    $display("\033[1;33m               /h/----+y        `+++++:             \033[1;35m PASS This Lab........Maybe \033[1;0m                          ");
    $display("\033[1;33m             .y------:m/+ydoo+:y:---:+o             \033[1;35m Total Latency : %-10d\033[1;0m                                ", tot_lat);
    $display("\033[1;33m              o+------/y--::::::+oso+:/y                                                                                     ");
    $display("\033[1;33m              s/-----:/:----------:+ooy+-                                                                                    ");
    $display("\033[1;33m             /o----------------/yhyo/::/o+/:-.`                                                                              ");
    $display("\033[1;33m            `ys----------------:::--------:::+yyo+                                                                           ");
    $display("\033[1;33m            .d/:-------------------:--------/--/hos/                                                                         ");
    $display("\033[1;33m            y/-------------------::ds------:s:/-:sy-                                                                         ");
    $display("\033[1;33m           +y--------------------::os:-----:ssm/o+`                                                                          ");
    $display("\033[1;33m          `d:-----------------------:-----/+o++yNNmms                                                                        ");
    $display("\033[1;33m           /y-----------------------------------hMMMMN.                                                                      ");
    $display("\033[1;33m           o+---------------------://:----------:odmdy/+.                                                                    ");
    $display("\033[1;33m           o+---------------------::y:------------::+o-/h                                                                    ");
    $display("\033[1;33m           :y-----------------------+s:------------/h:-:d                                                                    ");
    $display("\033[1;33m           `m/-----------------------+y/---------:oy:--/y                                                                    ");
    $display("\033[1;33m            /h------------------------:os++/:::/+o/:--:h-                                                                    ");
    $display("\033[1;33m         `:+ym--------------------------://++++o/:---:h/                                                                     ");
    $display("\033[1;31m        `hhhhhoooo++oo+/:\033[1;33m--------------------:oo----\033[1;31m+dd+                                                 ");
    $display("\033[1;31m         shyyyhhhhhhhhhhhso/:\033[1;33m---------------:+/---\033[1;31m/ydyyhs:`                                              ");
    $display("\033[1;31m         .mhyyyyyyhhhdddhhhhhs+:\033[1;33m----------------\033[1;31m:sdmhyyyyyyo:                                            ");
    $display("\033[1;31m        `hhdhhyyyyhhhhhddddhyyyyyo++/:\033[1;33m--------\033[1;31m:odmyhmhhyyyyhy                                            ");
    $display("\033[1;31m        -dyyhhyyyyyyhdhyhhddhhyyyyyhhhs+/::\033[1;33m-\033[1;31m:ohdmhdhhhdmdhdmy:                                           ");
    $display("\033[1;31m         hhdhyyyyyyyyyddyyyyhdddhhyyyyyhhhyyhdhdyyhyys+ossyhssy:-`                                                           ");
    $display("\033[1;31m         `Ndyyyyyyyyyyymdyyyyyyyhddddhhhyhhhhhhhhy+/:\033[1;33m-------::/+o++++-`                                            ");
    $display("\033[1;31m          dyyyyyyyyyyyyhNyydyyyyyyyyyyhhhhyyhhy+/\033[1;33m------------------:/ooo:`                                         ");
    $display("\033[1;31m         :myyyyyyyyyyyyyNyhmhhhyyyyyhdhyyyhho/\033[1;33m-------------------------:+o/`                                       ");
    $display("\033[1;31m        /dyyyyyyyyyyyyyyddmmhyyyyyyhhyyyhh+:\033[1;33m-----------------------------:+s-                                      ");
    $display("\033[1;31m      +dyyyyyyyyyyyyyyydmyyyyyyyyyyyyyds:\033[1;33m---------------------------------:s+                                      ");
    $display("\033[1;31m      -ddhhyyyyyyyyyyyyyddyyyyyyyyyyyhd+\033[1;33m------------------------------------:oo              `-++o+:.`             ");
    $display("\033[1;31m       `/dhshdhyyyyyyyyyhdyyyyyyyyyydh:\033[1;33m---------------------------------------s/            -o/://:/+s             ");
    $display("\033[1;31m         os-:/oyhhhhyyyydhyyyyyyyyyds:\033[1;33m----------------------------------------:h:--.`      `y:------+os            ");
    $display("\033[1;33m         h+-----\033[1;31m:/+oosshdyyyyyyyyhds\033[1;33m-------------------------------------------+h//o+s+-.` :o-------s/y  ");
    $display("\033[1;33m         m:------------\033[1;31mdyyyyyyyyymo\033[1;33m--------------------------------------------oh----:://++oo------:s/d  ");
    $display("\033[1;33m        `N/-----------+\033[1;31mmyyyyyyyydo\033[1;33m---------------------------------------------sy---------:/s------+o/d  ");
    $display("\033[1;33m        .m-----------:d\033[1;31mhhyyyyyyd+\033[1;33m----------------------------------------------y+-----------+:-----oo/h  ");
    $display("\033[1;33m        +s-----------+N\033[1;31mhmyyyyhd/\033[1;33m----------------------------------------------:h:-----------::-----+o/m  ");
    $display("\033[1;33m        h/----------:d/\033[1;31mmmhyyhh:\033[1;33m-----------------------------------------------oo-------------------+o/h  ");
    $display("\033[1;33m       `y-----------so /\033[1;31mNhydh:\033[1;33m-----------------------------------------------/h:-------------------:soo  ");
    $display("\033[1;33m    `.:+o:---------+h   \033[1;31mmddhhh/:\033[1;33m---------------:/osssssoo+/::---------------+d+//++///::+++//::::::/y+`  ");
    $display("\033[1;33m   -s+/::/--------+d.   \033[1;31mohso+/+y/:\033[1;33m-----------:yo+/:-----:/oooo/:----------:+s//::-.....--:://////+/:`    ");
    $display("\033[1;33m   s/------------/y`           `/oo:--------:y/-------------:/oo+:------:/s:                                                 ");
    $display("\033[1;33m   o+:--------::++`              `:so/:-----s+-----------------:oy+:--:+s/``````                                             ");
    $display("\033[1;33m    :+o++///+oo/.                   .+o+::--os-------------------:oy+oo:`/o+++++o-                                           ");
    $display("\033[1;33m       .---.`                          -+oo/:yo:-------------------:oy-:h/:---:+oyo                                          ");
    $display("\033[1;33m                                          `:+omy/---------------------+h:----:y+//so                                         ");
    $display("\033[1;33m                                              `-ys:-------------------+s-----+s///om                                         ");
    $display("\033[1;33m                                                 -os+::---------------/y-----ho///om                                         ");
    $display("\033[1;33m                                                    -+oo//:-----------:h-----h+///+d                                         ");
    $display("\033[1;33m                                                       `-oyy+:---------s:----s/////y                                         ");
    $display("\033[1;33m                                                           `-/o+::-----:+----oo///+s                                         ");
    $display("\033[1;33m                                                               ./+o+::-------:y///s:                                         ");
    $display("\033[1;33m                                                                   ./+oo/-----oo/+h                                          ");
    $display("\033[1;33m                                                                       `://++++syo`                                          ");
    $display("\033[1;0m"); 
    repeat(5) @(negedge clk);
    $finish;
end endtask

//===========================================================================

// Display float point
integer exp;
real    frac;
real    float;
task display_float;
    input reg[inst_sig_width+inst_exp_width:0] x;
begin
    // Exponent
    exp = -127;
    for(i=0 ; i<inst_exp_width ; i=i+1) begin
        exp = exp + (2**i)*x[inst_sig_width+i];
        //$display("%d %d %d\n", exp, x[inst_sig_width+i], inst_sig_width+i);
    end
    // Fraction
    frac = 1;
    for(i=0 ; i<inst_sig_width ; i=i+1) begin
        frac = frac + 2.0**(i-inst_sig_width)*x[i];
        //$display("%.31f %d %d\n", frac, x[i], i);
    end
    // Float
    float = 0;
    float = x[inst_sig_width+inst_exp_width] ? -frac * (2.0**exp) : frac * (2.0**exp);

    //Display
    $display("Original : %-b , %-b , %-b", x[inst_sig_width+inst_exp_width], x[inst_sig_width+:inst_exp_width], x[0+:inst_sig_width]);
    $display("Sign     : %-d", x[inst_sig_width+inst_exp_width]);
    $display("Exponet  : %-d", exp);
    $display("Fraction : %-.31f", frac);
    $display("Value    : %-.31f", float);
end endtask

task convert_float;
    input reg[inst_sig_width+inst_exp_width:0] x;
    output real y;
begin
    // Exponent
    exp = -127;
    for(k=0 ; k<inst_exp_width ; k=k+1) begin
        exp = exp + (2**k)*x[inst_sig_width+k];
        //$display("%d %d %d\n", exp, x[inst_sig_width+k], inst_sig_width+k);
    end
    // Fraction
    frac = 1;
    for(k=0 ; k<inst_sig_width ; k=k+1) begin
        frac = frac + 2.0**(k-inst_sig_width)*x[k];
        //$display("%.31f %d %d\n", frac, x[k], k);
    end
    // Float
    float = 0;
    float = x[inst_sig_width+inst_exp_width] ? -frac * (2.0**exp) : frac * (2.0**exp);

    y = float;
end endtask

//===========================================================================
//=========================
// Dump Hex
//=========================

task dump_hex_task; begin
    //=========================
    // Dump Image and Kernel
    //=========================
    for(file_tot=0 ; file_tot<imag_num ; file_tot=file_tot+1) begin
        if(file_tot==0)      file_out = $fopen("Image 1 and Kernel 1.txt", "w");
        else if(file_tot==1) file_out = $fopen("Image 2 and Kernel 2.txt", "w");
        else if(file_tot==2) file_out = $fopen("Image 3 and Kernel 3.txt", "w");

        $fwrite(file_out, "Iteration : %-d\n", pat);
        $fwrite(file_out, "Image %-1d with padding\n", file_tot);

        // Image 
        // row index
        $fwrite(file_out, "         ");
        for(file_idx1=0 ; file_idx1<imag_len+2 ; file_idx1=file_idx1+1)
            $fwrite(file_out, "       %-1d ", file_idx1);
        $fwrite(file_out, "\n");

        for(file_idx1=0 ; file_idx1<imag_len+2 ; file_idx1=file_idx1+1) begin
            // column index
            $fwrite(file_out, "       %-1d ", file_idx1);
            // value
            for(file_idx2=0 ; file_idx2<imag_len+2 ; file_idx2=file_idx2+1) begin
                $fwrite(file_out, "%-8h ", imag_in[file_tot][file_idx1][file_idx2]);
            end
            $fwrite(file_out, "\n");
        end
        $fwrite(file_out, "\n");

        // Kernel
        for(file_idx1=0 ; file_idx1<4 ; file_idx1=file_idx1+1) begin
            $fwrite(file_out, "Kern  %-1d-%-1d",file_tot, file_idx1);
            for(file_idx2=0 ; file_idx2<kern_len ; file_idx2=file_idx2+1) begin
                $fwrite(file_out, "         ");
            end
            $fwrite(file_out, "         ");
        end
        $fwrite(file_out, "\n");

        // row index
        $fwrite(file_out, "         ");
        for(file_idx2=0 ; file_idx2<4 ; file_idx2=file_idx2+1) begin
            for(file_idx1=0 ; file_idx1<kern_len; file_idx1=file_idx1+1)
                $fwrite(file_out, "       %-1d ", file_idx1);
            $fwrite(file_out, "         ");
            $fwrite(file_out, "         ");
        end
        $fwrite(file_out, "\n");

        for(file_idx1=0 ; file_idx1<kern_len ; file_idx1=file_idx1+1) begin
            for(file_idx2=0 ; file_idx2<4 ; file_idx2=file_idx2+1) begin
                // column index
                $fwrite(file_out, "       %-1d ", file_idx1);
                // value
                for(file_idx3=0 ; file_idx3<kern_len ; file_idx3=file_idx3+1) begin
                    $fwrite(file_out, "%-8h ", kern_in[file_tot][file_idx2][file_idx1][file_idx3]);
                end
                $fwrite(file_out, "         ");
            end
            $fwrite(file_out, "\n");
        end
        $fclose(file_out);
    end
    

    //=========================
    // Dump Convolution result
    //=========================
    for(file_tot=0 ; file_tot<imag_num ; file_tot=file_tot+1) begin
        if(file_tot==0)      file_out = $fopen("Convolution 1.txt", "w");
        else if(file_tot==1) file_out = $fopen("Convolution 2.txt", "w");
        else if(file_tot==2) file_out = $fopen("Convolution 3.txt", "w");

        $fwrite(file_out, "Iteration : %-d\n", pat);
        $fwrite(file_out, "Convolution %-1d\n", file_tot);

        // Convolution
        for(file_idx1=0 ; file_idx1<4 ; file_idx1=file_idx1+1) begin
            $fwrite(file_out, "Conv  %-1d-%-1d",file_tot, file_idx1);
            for(file_idx2=0 ; file_idx2<imag_len ; file_idx2=file_idx2+1) begin
                $fwrite(file_out, "         ");
            end
            $fwrite(file_out, "         ");
        end
        $fwrite(file_out, "\n");

        // row index
        $fwrite(file_out, "         ");
        for(file_idx2=0 ; file_idx2<4 ; file_idx2=file_idx2+1) begin
            for(file_idx1=0 ; file_idx1<imag_len; file_idx1=file_idx1+1)
                $fwrite(file_out, "       %-1d ", file_idx1);
            $fwrite(file_out, "         ");
            $fwrite(file_out, "         ");
        end
        $fwrite(file_out, "\n");

        for(file_idx1=0 ; file_idx1<imag_len ; file_idx1=file_idx1+1) begin
            for(file_idx2=0 ; file_idx2<4 ; file_idx2=file_idx2+1) begin
                // column index
                $fwrite(file_out, "       %-1d ", file_idx1);
                // value
                for(file_idx3=0 ; file_idx3<imag_len ; file_idx3=file_idx3+1) begin
                    $fwrite(file_out, "%-8h ", conv_gold[file_tot][file_idx2][file_idx1][file_idx3]);
                end
                $fwrite(file_out, "         ");
            end
            $fwrite(file_out, "\n");
        end
        $fclose(file_out);
    end
    

    //=========================
    // Dump Addition result
    //=========================
    file_out = $fopen("Addition.txt", "w");
    $fwrite(file_out, "Iteration : %-d\n", pat);
    $fwrite(file_out, "Addition \n");

    // Addition
    for(file_idx1=0 ; file_idx1<4 ; file_idx1=file_idx1+1) begin
        $fwrite(file_out, "Add   %-1d  ", file_idx1);
        for(file_idx2=0 ; file_idx2<imag_len ; file_idx2=file_idx2+1) begin
            $fwrite(file_out, "         ");
        end
        $fwrite(file_out, "         ");
    end
    $fwrite(file_out, "\n");

    // row index
    $fwrite(file_out, "         ");
    for(file_idx2=0 ; file_idx2<4 ; file_idx2=file_idx2+1) begin
        for(file_idx1=0 ; file_idx1<imag_len; file_idx1=file_idx1+1)
            $fwrite(file_out, "       %-1d ", file_idx1);
        $fwrite(file_out, "         ");
        $fwrite(file_out, "         ");
    end
    $fwrite(file_out, "\n");

    for(file_idx1=0 ; file_idx1<imag_len ; file_idx1=file_idx1+1) begin
        for(file_idx2=0 ; file_idx2<4 ; file_idx2=file_idx2+1) begin
            // column index
            $fwrite(file_out, "       %-1d ", file_idx1);
            // value
            for(file_idx3=0 ; file_idx3<imag_len ; file_idx3=file_idx3+1) begin
                $fwrite(file_out, "%-8h ", add_gold[file_idx2][file_idx1][file_idx3]);
            end
            $fwrite(file_out, "         ");
        end
        $fwrite(file_out, "\n");
    end
    $fclose(file_out);

    //=========================
    // Dump Activation result
    //=========================
    file_out = $fopen("Activation.txt", "w");
    $fwrite(file_out, "Iteration : %-d\n", pat);
    $fwrite(file_out, "Activation \n");

    // Activation
    for(file_idx1=0 ; file_idx1<4 ; file_idx1=file_idx1+1) begin
        $fwrite(file_out, "Acti   %-1d ", file_idx1);
        for(file_idx2=0 ; file_idx2<imag_len ; file_idx2=file_idx2+1) begin
            $fwrite(file_out, "         ");
        end
        $fwrite(file_out, "         ");
    end
    $fwrite(file_out, "\n");

    // row index
    $fwrite(file_out, "         ");
    for(file_idx2=0 ; file_idx2<4 ; file_idx2=file_idx2+1) begin
        for(file_idx1=0 ; file_idx1<imag_len; file_idx1=file_idx1+1)
            $fwrite(file_out, "       %-1d ", file_idx1);
        $fwrite(file_out, "         ");
        $fwrite(file_out, "         ");
    end
    $fwrite(file_out, "\n");

    for(file_idx1=0 ; file_idx1<imag_len ; file_idx1=file_idx1+1) begin
        for(file_idx2=0 ; file_idx2<4 ; file_idx2=file_idx2+1) begin
            // column index
            $fwrite(file_out, "       %-1d ", file_idx1);
            // value
            for(file_idx3=0 ; file_idx3<imag_len ; file_idx3=file_idx3+1) begin
                $fwrite(file_out, "%-8h ", acti_gold[file_idx2][file_idx1][file_idx3]);
            end
            $fwrite(file_out, "         ");
        end
        $fwrite(file_out, "\n");
    end
    $fclose(file_out);

    //=========================
    // Dump Golden Result
    //=========================
    file_out = $fopen("Golden.txt", "w");
    $fwrite(file_out, "Iteration : %-d\n", pat);
    $fwrite(file_out, "Golden \n");

    // row index
    $fwrite(file_out, "         ");
    for(file_idx1=0 ; file_idx1<8 ; file_idx1=file_idx1+1)
        $fwrite(file_out, "       %-1d ", file_idx1);
    $fwrite(file_out, "\n");

    for(file_idx1=0 ; file_idx1<8 ; file_idx1=file_idx1+1) begin
        // column index
        $fwrite(file_out, "       %-1d ", file_idx1);
        // value
        for(file_idx2=0 ; file_idx2<8 ; file_idx2=file_idx2+1) begin
            $fwrite(file_out, "%-8h ", shuf_gold[file_idx1][file_idx2]);
        end
        $fwrite(file_out, "\n");
    end
    $fwrite(file_out, "\n");
    $fclose(file_out);

end endtask

//===========================================================================
//=========================
// Dump Float
//=========================

task dump_float_task; begin
    //=========================
    // Dump Image and Kernel
    //=========================
    for(file_tot=0 ; file_tot<imag_num ; file_tot=file_tot+1) begin
        if(file_tot==0)      file_out = $fopen("Image 1 and Kernel 1 float.txt", "w");
        else if(file_tot==1) file_out = $fopen("Image 2 and Kernel 2 float.txt", "w");
        else if(file_tot==2) file_out = $fopen("Image 3 and Kernel 3 float.txt", "w");

        $fwrite(file_out, "Iteration : %-d\n", pat);
        $fwrite(file_out, "Image %-1d with padding\n", file_tot);

        // Image 
        for(file_idx1=0 ; file_idx1<imag_len+2 ; file_idx1=file_idx1+1) begin
            // value
            for(file_idx2=0 ; file_idx2<imag_len+2 ; file_idx2=file_idx2+1) begin
                convert_float(imag_in[file_tot][file_idx1][file_idx2], temp);
                $fwrite(file_out, "%10.10f ", temp);
            end
            $fwrite(file_out, "\n");
        end
        $fwrite(file_out, "\n");

        // Kernel
        
        for(file_idx2=0 ; file_idx2<4 ; file_idx2=file_idx2+1) begin
            $fwrite(file_out, "Kern  %-1d-%-1d\n",file_tot, file_idx2);
            // value
            for(file_idx1=0 ; file_idx1<kern_len ; file_idx1=file_idx1+1) begin
                for(file_idx3=0 ; file_idx3<kern_len ; file_idx3=file_idx3+1) begin
                    convert_float(kern_in[file_tot][file_idx2][file_idx1][file_idx3], temp);
                    $fwrite(file_out, "%10.10f ", temp);
                end
                $fwrite(file_out, "\n");
            end
            $fwrite(file_out, "\n");
        end
        $fclose(file_out);
    end
    

    //=========================
    // Dump Convolution result
    //=========================
    for(file_tot=0 ; file_tot<imag_num ; file_tot=file_tot+1) begin
        if(file_tot==0)      file_out = $fopen("Convolution 1 float.txt", "w");
        else if(file_tot==1) file_out = $fopen("Convolution 2 float.txt", "w");
        else if(file_tot==2) file_out = $fopen("Convolution 3 float.txt", "w");

        $fwrite(file_out, "Iteration : %-d\n", pat);
        $fwrite(file_out, "Convolution %-1d\n", file_tot);

        for(file_idx2=0 ; file_idx2<4 ; file_idx2=file_idx2+1) begin
            $fwrite(file_out, "Convolution  %-1d-%-1d\n",file_tot, file_idx2);
            for(file_idx1=0 ; file_idx1<imag_len ; file_idx1=file_idx1+1) begin
                // value
                for(file_idx3=0 ; file_idx3<imag_len ; file_idx3=file_idx3+1) begin
                    convert_float(conv_gold[file_tot][file_idx2][file_idx1][file_idx3], temp);
                    $fwrite(file_out, "%10.10f ", temp);
                end
                $fwrite(file_out, "\n");
            end
            $fwrite(file_out, "\n");
        end
        $fclose(file_out);
    end
    

    //=========================
    // Dump Addition result
    //=========================
    file_out = $fopen("Addition float.txt", "w");

    $fwrite(file_out, "Iteration : %-d\n", pat);
    $fwrite(file_out, "Addition \n");

    for(file_idx2=0 ; file_idx2<4 ; file_idx2=file_idx2+1) begin
        $fwrite(file_out, "Addition  %-1d\n",file_idx2);
        for(file_idx1=0 ; file_idx1<imag_len ; file_idx1=file_idx1+1) begin
            // value
            for(file_idx3=0 ; file_idx3<imag_len ; file_idx3=file_idx3+1) begin
                convert_float(add_gold[file_idx2][file_idx1][file_idx3], temp);
                $fwrite(file_out, "%10.10f ", temp);
            end
            $fwrite(file_out, "\n");
        end
        $fwrite(file_out, "\n");
    end
    $fclose(file_out);

    //=========================
    // Dump Activation result
    //=========================
    file_out = $fopen("Activation float.txt", "w");
    $fwrite(file_out, "Iteration : %-d\n", pat);
    $fwrite(file_out, "Activation \n");

    
    for(file_idx2=0 ; file_idx2<4 ; file_idx2=file_idx2+1) begin
        $fwrite(file_out, "Activation  %-1d\n",file_idx2);
        for(file_idx1=0 ; file_idx1<imag_len ; file_idx1=file_idx1+1) begin
            // value
            for(file_idx3=0 ; file_idx3<imag_len ; file_idx3=file_idx3+1) begin
                convert_float(acti_gold[file_idx2][file_idx1][file_idx3], temp);
                $fwrite(file_out, "%10.10f ", temp);
            end
            $fwrite(file_out, "\n");
        end
        $fwrite(file_out, "\n");
    end
    $fclose(file_out);

    //=========================
    // Dump Golden Result
    //=========================
    file_out = $fopen("Golden float.txt", "w");
    $fwrite(file_out, "Iteration : %-d\n", pat);
    $fwrite(file_out, "Golden \n");


    for(file_idx1=0 ; file_idx1<8 ; file_idx1=file_idx1+1) begin
        // value
        for(file_idx2=0 ; file_idx2<8 ; file_idx2=file_idx2+1) begin
            convert_float(shuf_gold[file_idx1][file_idx2], temp);
            $fwrite(file_out, "%10.10f ", temp);
        end
        $fwrite(file_out, "\n");
    end
    $fwrite(file_out, "\n");
    $fclose(file_out);
end endtask

//=================
// Convolution
//=================
genvar i_imag, i_kern, i_row, i_col;
generate //: gen_conv
    for(i_imag=0 ; i_imag<imag_num ; i_imag=i_imag+1) begin
        for(i_kern=0 ; i_kern<kern_num ; i_kern=i_kern+1) begin
            for(i_row=0 ; i_row<=imag_len-1 ; i_row=i_row+1) begin
                for(i_col=0 ; i_col<=imag_len-1 ; i_col=i_col+1) begin
                    wire [inst_sig_width+inst_exp_width:0] out1;
                    Con_float #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                    CF(
                        // Image
                        imag_in[i_imag][i_row][i_col],   imag_in[i_imag][i_row][i_col+1],   imag_in[i_imag][i_row][i_col+2],
                        imag_in[i_imag][i_row+1][i_col], imag_in[i_imag][i_row+1][i_col+1], imag_in[i_imag][i_row+1][i_col+2],
                        imag_in[i_imag][i_row+2][i_col], imag_in[i_imag][i_row+2][i_col+1], imag_in[i_imag][i_row+2][i_col+2],
                        // Kernel
                        kern_in[i_imag][i_kern][0][0], kern_in[i_imag][i_kern][0][1], kern_in[i_imag][i_kern][0][2],
                        kern_in[i_imag][i_kern][1][0], kern_in[i_imag][i_kern][1][1], kern_in[i_imag][i_kern][1][2],
                        kern_in[i_imag][i_kern][2][0], kern_in[i_imag][i_kern][2][1], kern_in[i_imag][i_kern][2][2],
                        // Output
                        out1
                    );
                    assign conv_w[i_imag][i_kern][i_row][i_col] = out1;
                end
            end
        end
    end
endgenerate

task conv_task; begin
    for(i=0 ; i<imag_num ; i=i+1)
        for(j=0 ; j<kern_num ; j=j+1)
            for(k=0 ; k<=imag_len-1 ; k=k+1)
                for(m=0 ; m<=imag_len-1 ; m=m+1)
                    conv_gold[i][j][k][m] = conv_w[i][j][k][m];
end endtask

//=================
// Addition
//=================
generate
    for(i_kern=0 ; i_kern<kern_num ; i_kern=i_kern+1) begin
        for(i_row=0 ; i_row<=imag_len-1 ; i_row=i_row+1) begin
            for(i_col=0 ; i_col<=imag_len-1 ; i_col=i_col+1) begin
                wire [inst_sig_width+inst_exp_width:0] out1;
                wire [inst_sig_width+inst_exp_width:0] out2;

                DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
                    A0 (.a(conv_w[0][i_kern][i_row][i_col]), .b(conv_w[1][i_kern][i_row][i_col]), .op(1'd0), .rnd(3'd0), .z(out1));
                
                DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
                    A1 (.a(conv_w[2][i_kern][i_row][i_col]), .b(out1),                            .op(1'd0), .rnd(3'd0), .z(out2));

                assign add_w[i_kern][i_row][i_col] = out2;
            end
        end
    end
endgenerate

task add_task; begin
    for(j=0 ; j<kern_num ; j=j+1)
        for(k=0 ; k<=imag_len-1 ; k=k+1)
            for(m=0 ; m<=imag_len-1 ; m=m+1) begin
                add_gold[j][k][m] = add_w[j][k][m];
            end
end endtask

//=================
// Activation
//=================
wire a;
generate
    for(i_kern=0 ; i_kern<kern_num ; i_kern=i_kern+1) begin
        for(i_row=0 ; i_row<=imag_len-1 ; i_row=i_row+1) begin
            for(i_col=0 ; i_col<=imag_len-1 ; i_col=i_col+1) begin
                wire [inst_sig_width+inst_exp_width:0] out0, out1, out2, out3;
                ReLu #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                    R0 (add_w[i_kern][i_row][i_col], out0);

                Leaky_ReLu #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
                    R1 (add_w[i_kern][i_row][i_col], out1);

                Sigmoid #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch)
                    S0 (add_w[i_kern][i_row][i_col], out2);

                Tanh #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch)
                    S1 (add_w[i_kern][i_row][i_col], out3);

                assign acti_w[i_kern][i_row][i_col] = (opt_in == 2'd0) ? out0 :
                                                      (opt_in == 2'd1) ? out1 :
                                                      (opt_in == 2'd2) ? out2 : out3;
            end
        end
    end
endgenerate

task acti_task; begin
    for(j=0 ; j<kern_num ; j=j+1)
        for(k=0 ; k<=imag_len-1 ; k=k+1)
            for(m=0 ; m<=imag_len-1 ; m=m+1) begin
                acti_gold[j][k][m] = acti_w[j][k][m];
            end
end endtask

//=================
// Shuffle
//=================
task shuf_task; begin
    for(k=0 ; k<=imag_len-1 ; k=k+1) begin
        for(m=0 ; m<=imag_len-1 ; m=m+1) begin
            shuf_gold[2*k]  [2*m]   = acti_w[0][k][m];
            shuf_gold[2*k]  [2*m+1] = acti_w[1][k][m];
            shuf_gold[2*k+1][2*m]   = acti_w[2][k][m];
            shuf_gold[2*k+1][2*m+1] = acti_w[3][k][m];
        end
    end
end endtask

//=================
// Error
//=================

// gold - ans
DW_fp_sub
#(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    Err_S0 (.a(out_check), .b(out), .z(error_diff), .rnd(3'd0));

// ans * 0.9
DW_fp_mult
#(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    Err_M0 (.a(error_lim_pos), .b(out_check), .z(up_bound), .rnd(3'd0));

// ans * -0.9
DW_fp_mult
#(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    Err_M1 (.a(error_lim_neg), .b(out_check), .z(low_bound), .rnd(3'd0));

// check (gold - ans) ? 0.9ans
DW_fp_cmp
#(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    Err_C0 (.a(error_diff), .b(up_bound), .agtb(up_flag), .zctr(1'd0));

// check (gold - ans) ? -0.9ans
DW_fp_cmp
#(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
    Err_C1 (.a(error_diff), .b(low_bound), .agtb(low_flag), .zctr(1'd0));

endmodule

module Con_float
#(  parameter inst_sig_width       = 23,
    parameter inst_exp_width       = 8,
    parameter inst_ieee_compliance = 1
)
(
    input  [inst_sig_width+inst_exp_width:0] a0, a1, a2, a3, a4, a5, a6, a7, a8,
    input  [inst_sig_width+inst_exp_width:0] b0, b1, b2, b3, b4, b5, b6, b7, b8,
    output [inst_sig_width+inst_exp_width:0] out
);

    wire [inst_sig_width+inst_exp_width:0] pixel0, pixel1, pixel2, pixel3, pixel4, pixel5, pixel6, pixel7, pixel8;

    // Multiplication
    DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
        M0 (.a(a0), .b(b0), .rnd(3'd0), .z(pixel0));
    
    DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
        M1 (.a(a1), .b(b1), .rnd(3'd0), .z(pixel1));
    
    DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
        M2 (.a(a2), .b(b2), .rnd(3'd0), .z(pixel2));
    
    DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
        M3 (.a(a3), .b(b3), .rnd(3'd0), .z(pixel3));
    
    DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
        M4 (.a(a4), .b(b4), .rnd(3'd0), .z(pixel4));
    
    DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
        M5 (.a(a5), .b(b5), .rnd(3'd0), .z(pixel5));
    
    DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
        M6 (.a(a6), .b(b6), .rnd(3'd0), .z(pixel6));
    
    DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
        M7 (.a(a7), .b(b7), .rnd(3'd0), .z(pixel7));
    
    DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
        M8 (.a(a8), .b(b8), .rnd(3'd0), .z(pixel8));

    wire [inst_sig_width+inst_exp_width:0] add0, add1, add2, add3, add4, add5, add6;

    // Addition
    DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
        A0 (.a(pixel0), .b(pixel1), .op(1'd0), .rnd(3'd0), .z(add0));

    DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
        A1 (.a(add0), .b(pixel2), .op(1'd0), .rnd(3'd0), .z(add1));

    DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
        A2 (.a(add1), .b(pixel3), .op(1'd0), .rnd(3'd0), .z(add2));

    DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
        A3 (.a(add2), .b(pixel4), .op(1'd0), .rnd(3'd0), .z(add3));

    DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
        A4 (.a(add3), .b(pixel5), .op(1'd0), .rnd(3'd0), .z(add4));

    DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
        A5 (.a(add4), .b(pixel6), .op(1'd0), .rnd(3'd0), .z(add5));

    DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
        A6 (.a(add5), .b(pixel7), .op(1'd0), .rnd(3'd0), .z(add6));

    DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
        A7 (.a(add6), .b(pixel8), .op(1'd0), .rnd(3'd0), .z(out));

endmodule


module ReLu
#(  parameter inst_sig_width       = 23,
    parameter inst_exp_width       = 8,
    parameter inst_ieee_compliance = 1
)
(
    input  [inst_sig_width+inst_exp_width:0] in,
    output [inst_sig_width+inst_exp_width:0] out
);
    assign out = in[inst_sig_width+inst_exp_width] ? 0 : in;

endmodule

module Leaky_ReLu
#(  parameter inst_sig_width       = 23,
    parameter inst_exp_width       = 8,
    parameter inst_ieee_compliance = 1
)
(
    input  [inst_sig_width+inst_exp_width:0] in,
    output [inst_sig_width+inst_exp_width:0] out
);
    wire [inst_sig_width+inst_exp_width:0] float_ratio = 32'h3DCCCCCD; // Leaky ReLu ratio 0.1
    wire [inst_sig_width+inst_exp_width:0] leaky_relu_cal;

    DW_fp_mult
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
        M0 (.a(in), .b(float_ratio), .rnd(3'd0), .z(leaky_relu_cal));

    assign out = in[inst_sig_width+inst_exp_width] ? leaky_relu_cal : in;
endmodule

module Sigmoid
#(  parameter inst_sig_width       = 23,
    parameter inst_exp_width       = 8,
    parameter inst_ieee_compliance = 1,
    parameter inst_arch            = 0
)
(
    input  [inst_sig_width+inst_exp_width:0] in,
    output [inst_sig_width+inst_exp_width:0] out
);
    wire [inst_sig_width+inst_exp_width:0] float_gain1 = 32'h3F800000; // Activation 1.0
    wire [inst_sig_width+inst_exp_width:0] float_gain2 = 32'hBF800000; // Activation -1.0
    wire [inst_sig_width+inst_exp_width:0] x_neg;
    wire [inst_sig_width+inst_exp_width:0] exp;
    wire [inst_sig_width+inst_exp_width:0] deno;

    DW_fp_mult // -x
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance)
        M0 (.a(in), .b(float_gain2), .rnd(3'd0), .z(x_neg));
    
    DW_fp_exp // exp(-x)
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch)
        E0 (.a(x_neg), .z(exp));
    
    DW_fp_addsub // 1+exp(-x)
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance)
        A0 (.a(float_gain1), .b(exp), .op(1'd0), .rnd(3'd0), .z(deno));
    
    DW_fp_div // 1 / [1+exp(-x)]
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance, 0)
        D0 (.a(float_gain1), .b(deno), .rnd(3'd0), .z(out));
endmodule

module Tanh
#(  parameter inst_sig_width       = 23,
    parameter inst_exp_width       = 8,
    parameter inst_ieee_compliance = 1,
    parameter inst_arch            = 0
)
(
    input  [inst_sig_width+inst_exp_width:0] in,
    output [inst_sig_width+inst_exp_width:0] out
);
    wire [inst_sig_width+inst_exp_width:0] float_gain1 = 32'h3F800000; // Activation 1.0
    wire [inst_sig_width+inst_exp_width:0] float_gain2 = 32'hBF800000; // Activation -1.0
    wire [inst_sig_width+inst_exp_width:0] x_neg;
    wire [inst_sig_width+inst_exp_width:0] exp_pos;
    wire [inst_sig_width+inst_exp_width:0] exp_neg;
    wire [inst_sig_width+inst_exp_width:0] nume;
    wire [inst_sig_width+inst_exp_width:0] deno;

    DW_fp_mult // -x
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance)
        M0 (.a(in), .b(float_gain2), .rnd(3'd0), .z(x_neg));
    
    DW_fp_exp // exp(-x)
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch)
        E0 (.a(x_neg), .z(exp_neg));

    DW_fp_exp // exp(x)
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch)
        E1 (.a(in), .z(exp_pos));

    //

    DW_fp_addsub // exp(x)-exp(-x)
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance)
        A0 (.a(exp_pos), .b(exp_neg), .op(1'd1), .rnd(3'd0), .z(nume));

    DW_fp_addsub // exp(x)+exp(-x)
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance)
        A1 (.a(exp_pos), .b(exp_neg), .op(1'd0), .rnd(3'd0), .z(deno));

    DW_fp_div // [exp(x)-exp(-x)] / [exp(x)+exp(-x)]
    #(inst_sig_width,inst_exp_width,inst_ieee_compliance, 0)
        D0 (.a(nume), .b(deno), .rnd(3'd0), .z(out));


endmodule