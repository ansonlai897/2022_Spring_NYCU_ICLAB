module NN(
	// Input signals
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
	// Output signals
	out_valid,
	out
);
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 1;
parameter inst_arch = 2;

// ===============================================================
// Parameters 
// ===============================================================

parameter zero_point_one = 32'b0_0111_1011_10011001100110011001101;
parameter one =            32'b00111111100000000000000000000000;

// ===============================================================
// integer
// ===============================================================
integer i, j;
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input  clk, rst_n, in_valid_i, in_valid_k, in_valid_o;
input [inst_sig_width+inst_exp_width:0] Image1, Image2, Image3;
input [inst_sig_width+inst_exp_width:0] Kernel1, Kernel2, Kernel3;
input [1:0] Opt;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
// state
wire [inst_sig_width+inst_exp_width:0] pixel_tmp;
wire [inst_sig_width+inst_exp_width:0] out_1;

// cnt
reg [5:0] cnt_k;
reg [6:0] cnt_p;
reg [2:0] image_x, image_y;
reg [2:0] kernel_page, image_page;
reg [7:0] cnt_c;

// Image 
reg [inst_sig_width+inst_exp_width:0] image_data   [0:2][0:5][0:5];
reg [inst_sig_width+inst_exp_width:0] image_data_1 [0:2][0:5][0:5];


// kernel
reg [inst_sig_width+inst_exp_width:0] kernel_data  [0:2][0:3][0:8];
reg [inst_sig_width+inst_exp_width:0] kernel_data_1[0:2][0:3][0:8];


wire [inst_sig_width+inst_exp_width:0] exp_pos;
wire [inst_sig_width+inst_exp_width:0] exp_neg;

wire [inst_sig_width+inst_exp_width:0] sigmod;
wire [inst_sig_width+inst_exp_width:0] sigmod_1;


wire [inst_sig_width+inst_exp_width:0] tanh_mom;
wire [inst_sig_width+inst_exp_width:0] tanh_child;
wire [inst_sig_width+inst_exp_width:0] tanh;

wire [inst_sig_width+inst_exp_width:0] leaky_relu;

wire [inst_sig_width+inst_exp_width:0] relu;
wire [inst_sig_width+inst_exp_width:0] le_relu;

wire [inst_sig_width+inst_exp_width:0] conv1_out;
wire [inst_sig_width+inst_exp_width:0] conv2_out;

reg [inst_sig_width+inst_exp_width:0] adder[0:2];

reg  [inst_sig_width+inst_exp_width:0] conved [0:3][0:15];

reg [inst_sig_width+inst_exp_width:0] act;


// opt
reg [1:0]opt;

// flag
reg flag;
reg flag_conv;
reg flag_pixel;

wire [2:0] p1, p2, p3, p4;
assign p1 = image_x + 1;
assign p2 = image_x + 2;
assign p3 = image_y + 1;
assign p4 = image_y + 2;

// ===============================================================
// DESIGN
// ===============================================================

// ===============================================================
// INPUT
// ===============================================================
// flag;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	flag <= 0 ;
	else begin
		if (in_valid_i == 1)		flag <= 1 ;
		else if (out_valid == 1)	flag <= 0 ;
		else begin
		end
	end
end

// opt
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		opt <= 0;
	end
	else begin
		if(in_valid_o == 1)
			opt <= Opt;	
		else begin
		end
	end
end

// image 
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for(i=0; i<6; i=i+1) begin
			for (j=0; j<6; j=j+1) begin
				image_data[0][i][j] <= 0;
				image_data[1][i][j] <= 0;
				image_data[2][i][j] <= 0;
			end
		end									
	end
	else begin
		if(in_valid_i == 1) begin
			// 1
			image_data[0][0][5] <= (opt[1] == 1) ? 0 : image_data[0][2][1];
			image_data[0][0][4] <= (opt[1] == 1) ? 0 : image_data[0][2][1];
			image_data[0][0][3] <= (opt[1] == 1) ? 0 : image_data[0][1][4];
			image_data[0][0][2] <= (opt[1] == 1) ? 0 : image_data[0][1][3];
			image_data[0][0][1] <= (opt[1] == 1) ? 0 : image_data[0][1][2];
			image_data[0][0][0] <= (opt[1] == 1) ? 0 : image_data[0][1][2];

			image_data[0][1][5] <= (opt[1] == 1) ? 0 : image_data[0][2][1];
			image_data[0][1][4] <= image_data[0][2][1];
			image_data[0][1][3] <= image_data[0][1][4];
			image_data[0][1][2] <= image_data[0][1][3];
			image_data[0][1][1] <= image_data[0][1][2];
			image_data[0][1][0] <= (opt[1] == 1) ? 0 : image_data[0][1][2];

			image_data[0][2][5] <= (opt[1] == 1) ? 0 : image_data[0][3][1];
			image_data[0][2][4] <= image_data[0][3][1];
			image_data[0][2][3] <= image_data[0][2][4];
			image_data[0][2][2] <= image_data[0][2][3];
			image_data[0][2][1] <= image_data[0][2][2];
			image_data[0][2][0] <= (opt[1] == 1) ? 0 : image_data[0][2][2];

			image_data[0][3][5] <= (opt[1] == 1) ? 0 : image_data[0][4][1];
			image_data[0][3][4] <= image_data[0][4][1];
			image_data[0][3][3] <= image_data[0][3][4];
			image_data[0][3][2] <= image_data[0][3][3];
			image_data[0][3][1] <= image_data[0][3][2];
			image_data[0][3][0] <= (opt[1] == 1) ? 0 : image_data[0][3][2];

			image_data[0][4][5] <= (opt[1] == 1) ? 0 : Image1;
			image_data[0][4][4] <= Image1;
			image_data[0][4][3] <= image_data[0][4][4];
			image_data[0][4][2] <= image_data[0][4][3];
			image_data[0][4][1] <= image_data[0][4][2];
			image_data[0][4][0] <= (opt[1] == 1) ? 0 : image_data[0][4][2];

			image_data[0][5][5] <= (opt[1] == 1) ? 0 : Image1;
			image_data[0][5][4] <= (opt[1] == 1) ? 0 : Image1;
			image_data[0][5][3] <= (opt[1] == 1) ? 0 : image_data[0][4][4];
			image_data[0][5][2] <= (opt[1] == 1) ? 0 : image_data[0][4][3];
			image_data[0][5][1] <= (opt[1] == 1) ? 0 : image_data[0][4][2];
			image_data[0][5][0] <= (opt[1] == 1) ? 0 : image_data[0][4][2];
			// ===============================================================
			// 2
			image_data[1][0][5] <= (opt[1] == 1) ? 0 : image_data[1][2][1];
			image_data[1][0][4] <= (opt[1] == 1) ? 0 : image_data[1][2][1];
			image_data[1][0][3] <= (opt[1] == 1) ? 0 : image_data[1][1][4];
			image_data[1][0][2] <= (opt[1] == 1) ? 0 : image_data[1][1][3];
			image_data[1][0][1] <= (opt[1] == 1) ? 0 : image_data[1][1][2];
			image_data[1][0][0] <= (opt[1] == 1) ? 0 : image_data[1][1][2];

			image_data[1][1][5] <= (opt[1] == 1) ? 0 : image_data[1][2][1];
			image_data[1][1][4] <= image_data[1][2][1];
			image_data[1][1][3] <= image_data[1][1][4];
			image_data[1][1][2] <= image_data[1][1][3];
			image_data[1][1][1] <= image_data[1][1][2];
			image_data[1][1][0] <= (opt[1] == 1) ? 0 : image_data[1][1][2];

			image_data[1][2][5] <= (opt[1] == 1) ? 0 : image_data[1][3][1];
			image_data[1][2][4] <= image_data[1][3][1];
			image_data[1][2][3] <= image_data[1][2][4];
			image_data[1][2][2] <= image_data[1][2][3];
			image_data[1][2][1] <= image_data[1][2][2];
			image_data[1][2][0] <= (opt[1] == 1) ? 0 : image_data[1][2][2];

			image_data[1][3][5] <= (opt[1] == 1) ? 0 : image_data[1][4][1];
			image_data[1][3][4] <= image_data[1][4][1];
			image_data[1][3][3] <= image_data[1][3][4];
			image_data[1][3][2] <= image_data[1][3][3];
			image_data[1][3][1] <= image_data[1][3][2];
			image_data[1][3][0] <= (opt[1] == 1) ? 0 : image_data[1][3][2];

			image_data[1][4][5] <= (opt[1] == 1) ? 0 : Image2;
			image_data[1][4][4] <= Image2;
			image_data[1][4][3] <= image_data[1][4][4];
			image_data[1][4][2] <= image_data[1][4][3];
			image_data[1][4][1] <= image_data[1][4][2];
			image_data[1][4][0] <= (opt[1] == 1) ? 0 : image_data[1][4][2];

			image_data[1][5][5] <= (opt[1] == 1) ? 0 : Image2;
			image_data[1][5][4] <= (opt[1] == 1) ? 0 : Image2;
			image_data[1][5][3] <= (opt[1] == 1) ? 0 : image_data[1][4][4];
			image_data[1][5][2] <= (opt[1] == 1) ? 0 : image_data[1][4][3];
			image_data[1][5][1] <= (opt[1] == 1) ? 0 : image_data[1][4][2];
			image_data[1][5][0] <= (opt[1] == 1) ? 0 : image_data[1][4][2];
			// ===============================================================
			// 3
			image_data[2][0][5] <= (opt[1] == 1) ? 0 : image_data[2][2][1];
			image_data[2][0][4] <= (opt[1] == 1) ? 0 : image_data[2][2][1];
			image_data[2][0][3] <= (opt[1] == 1) ? 0 : image_data[2][1][4];
			image_data[2][0][2] <= (opt[1] == 1) ? 0 : image_data[2][1][3];
			image_data[2][0][1] <= (opt[1] == 1) ? 0 : image_data[2][1][2];
			image_data[2][0][0] <= (opt[1] == 1) ? 0 : image_data[2][1][2];

			image_data[2][1][5] <= (opt[1] == 1) ? 0 : image_data[2][2][1];
			image_data[2][1][4] <= image_data[2][2][1];
			image_data[2][1][3] <= image_data[2][1][4];
			image_data[2][1][2] <= image_data[2][1][3];
			image_data[2][1][1] <= image_data[2][1][2];
			image_data[2][1][0] <= (opt[1] == 1) ? 0 : image_data[2][1][2];

			image_data[2][2][5] <= (opt[1] == 1) ? 0 : image_data[2][3][1];
			image_data[2][2][4] <= image_data[2][3][1];
			image_data[2][2][3] <= image_data[2][2][4];
			image_data[2][2][2] <= image_data[2][2][3];
			image_data[2][2][1] <= image_data[2][2][2];
			image_data[2][2][0] <= (opt[1] == 1) ? 0 : image_data[2][2][2];

			image_data[2][3][5] <= (opt[1] == 1) ? 0 : image_data[2][4][1];
			image_data[2][3][4] <= image_data[2][4][1];
			image_data[2][3][3] <= image_data[2][3][4];
			image_data[2][3][2] <= image_data[2][3][3];
			image_data[2][3][1] <= image_data[2][3][2];
			image_data[2][3][0] <= (opt[1] == 1) ? 0 : image_data[2][3][2];

			image_data[2][4][5] <= (opt[1] == 1) ? 0 : Image3;
			image_data[2][4][4] <= Image3;
			image_data[2][4][3] <= image_data[2][4][4];
			image_data[2][4][2] <= image_data[2][4][3];
			image_data[2][4][1] <= image_data[2][4][2];
			image_data[2][4][0] <= (opt[1] == 1) ? 0 : image_data[2][4][2];

			image_data[2][5][5] <= (opt[1] == 1) ? 0 : Image3;
			image_data[2][5][4] <= (opt[1] == 1) ? 0 : Image3;
			image_data[2][5][3] <= (opt[1] == 1) ? 0 : image_data[2][4][4];
			image_data[2][5][2] <= (opt[1] == 1) ? 0 : image_data[2][4][3];
			image_data[2][5][1] <= (opt[1] == 1) ? 0 : image_data[2][4][2];
			image_data[2][5][0] <= (opt[1] == 1) ? 0 : image_data[2][4][2];
		end
		else begin
			if(flag == 0)begin
				for(i=0; i<6; i=i+1) begin
					for (j=0; j<6; j=j+1) begin
						image_data[0][i][j] <= 0;
						image_data[1][i][j] <= 0;
						image_data[2][i][j] <= 0;
					end
				end		
			end
			else begin
			end
		end
	end
end

// kernel
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for(i=0; i<4; i=i+1)begin
			for(j=0; j<9; j=j+1) begin
				kernel_data[0][i][j] <= 0;
				kernel_data[1][i][j] <= 0;
				kernel_data[2][i][j] <= 0;
			end
		end
	end
	else begin
		if(in_valid_k == 1) begin
			kernel_data[0][3][8] <= Kernel1;
			kernel_data[1][3][8] <= Kernel2;
			kernel_data[2][3][8] <= Kernel3;

			for(i=2; i>=0; i=i-1) begin
				kernel_data[0][i][8] <= kernel_data[0][i+1][0];
				kernel_data[1][i][8] <= kernel_data[1][i+1][0];
				kernel_data[2][i][8] <= kernel_data[2][i+1][0];
			end

			for(j=3; j>=0; j=j-1) begin
				for(i=7; i>=0; i=i-1) begin
					kernel_data[0][j][i] <= kernel_data[0][j][i+1];
					kernel_data[1][j][i] <= kernel_data[1][j][i+1];
					kernel_data[2][j][i] <= kernel_data[2][j][i+1];
				end
			end
		end
		else begin
		end	
	end
end

// cnt_k
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cnt_k <= 0;
	end
	else begin
		if(in_valid_k == 1)
			cnt_k <= cnt_k + 1;
		else begin
			if(flag == 0)
				cnt_k <= 0;
			else begin
			end
		end
	end
end

// ===============================================================
// convoltion
// ===============================================================
// ===============================================================
fp_conv conv1(
	// in1
	.in1_1(kernel_data_1[image_page][kernel_page][0]), .in1_2(kernel_data_1[image_page][kernel_page][1]), .in1_3(kernel_data_1[image_page][kernel_page][2]), 
	.in1_4(kernel_data_1[image_page][kernel_page][3]), .in1_5(kernel_data_1[image_page][kernel_page][4]), .in1_6(kernel_data_1[image_page][kernel_page][5]), 
	.in1_7(kernel_data_1[image_page][kernel_page][6]), .in1_8(kernel_data_1[image_page][kernel_page][7]), .in1_9(kernel_data_1[image_page][kernel_page][8]),
	// in2
	.in2_1(image_data_1[image_page][image_x][image_y]), .in2_2(image_data_1[image_page][image_x][p3]  ), .in2_3(image_data_1[image_page][image_x][p4]), 
	.in2_4(image_data_1[image_page][p1][image_y]),      .in2_5(image_data_1[image_page][p1][p3]),        .in2_6(image_data_1[image_page][p1][p4]), 
	.in2_7(image_data_1[image_page][p2][image_y]),      .in2_8(image_data_1[image_page][p2][p3]),        .in2_9(image_data_1[image_page][p2][p4]),
	// out
	.out(conv1_out)
);
// sum3
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U04 ( .a(adder[0]), .b(adder[1]),  .c(adder[2]), .rnd(3'b000), .z(conv2_out) );
// ===============================================================
// flag_conv
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		flag_conv <= 0;
		for(i=0; i<6; i=i+1) begin
			for (j=0; j<6; j=j+1) begin
				image_data_1[0][i][j] <= 0;
				image_data_1[1][i][j] <= 0;
				image_data_1[2][i][j] <= 0;
			end
		end		
		for(i=0; i<4; i=i+1)begin
			for(j=0; j<9; j=j+1) begin
				kernel_data_1[0][i][j] <= 0;
				kernel_data_1[1][i][j] <= 0;
				kernel_data_1[2][i][j] <= 0;
			end
		end
	end
	else begin
		if(cnt_p >= 65) begin
			flag_conv <= 0;
			for(i=0; i<6; i=i+1) begin
				for (j=0; j<6; j=j+1) begin
					image_data_1[0][i][j] <= 0;
					image_data_1[1][i][j] <= 0;
					image_data_1[2][i][j] <= 0;
				end
			end		
			for(i=0; i<4; i=i+1)begin
				for(j=0; j<9; j=j+1) begin
					kernel_data_1[0][i][j] <= 0;
					kernel_data_1[1][i][j] <= 0;
					kernel_data_1[2][i][j] <= 0;
				end
			end
		end
		else begin
			if(cnt_k == 36)	begin
				flag_conv <= 1;
				for(i=0; i<6; i=i+1) begin
					for (j=0; j<6; j=j+1) begin
						image_data_1[0][i][j] <= image_data[0][i][j];
						image_data_1[1][i][j] <= image_data[1][i][j];
						image_data_1[2][i][j] <= image_data[2][i][j];
					end
				end		
				for(i=0; i<4; i=i+1)begin
					for(j=0; j<9; j=j+1) begin
						kernel_data_1[0][i][j] <= kernel_data[0][i][j];
						kernel_data_1[1][i][j] <= kernel_data[1][i][j];
						kernel_data_1[2][i][j] <= kernel_data[2][i][j];
					end
				end
			end
			else begin
			end
		end
	end
end

// cnt_c
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cnt_c <= 0;
	end
	else begin
		if(cnt_p >= 65) begin
			cnt_c <= 0;
		end
		else begin
			if(cnt_k == 36)begin
				if(cnt_c < 196)
					cnt_c <= cnt_c + 1;
				else begin
				end
			end
			else begin
			end
		end
	end
end

// image_page
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		image_page <= 0;
	end
	else begin
		if(cnt_p >= 65) begin
			image_page <= 0;
		end
		else begin
			if(flag_conv) begin
				if(image_page < 2)
					image_page <= image_page + 1;
				else begin
					image_page <= 0;
				end
			end
		end
	end
end

// image_x, image_y
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		image_x <= 0;
		image_y <= 0;	
	end
	else begin
		if(cnt_p >= 65) begin
			image_x <= 0;
			image_y <= 0;	
		end
		else begin
			if(flag_conv) begin
				if(image_page == 2) begin
					if(image_y < 3) begin
						image_y <= image_y + 1;
					end
					else begin
						if(image_x < 3)begin
							image_x <= image_x + 1;
							image_y <= 0;
						end
						else begin
							image_x <= 0;
							image_y <= 0;	
						end
					end
				end
				else begin
				end
			end
			else begin
			end
		end
	end
end

// kernel_page
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		kernel_page <= 0;	
	end
	else begin
		if(cnt_p >= 65) begin
			kernel_page <= 0;	
		end
		else begin
			if(flag_conv) begin
				if(cnt_c % 'd48 == 0) begin
					if(kernel_page < 3)
						kernel_page <= kernel_page + 1;
					else begin
						kernel_page <= 0;	
					end
				end
				else begin
				end
			end
			else begin
			end
		end
	end
end

// adder
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for(i=0; i<3; i=i+1) begin
			adder[i] <= 0;
		end
	end
	else begin
		if(cnt_p >= 65) begin
			for(i=0; i<3; i=i+1) begin
				adder[i] <= 0;
			end
		end
		else begin
			if(cnt_k == 36) begin
				adder[2] <= conv1_out;
				adder[1] <= adder[2];
				adder[0] <= adder[1];
			end
			else begin
				for(i=0; i<3; i=i+1) begin
					adder[i] <= 0;
				end
			end
		end
	end
end

//conved
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for(i=0; i<4; i=i+1)
			for(j=0; j<16; j=j+1)
				conved[i][j] <= 0;
	end
	else begin
		if(cnt_p >= 65) begin
			for(i=0; i<4; i=i+1)
				for(j=0; j<16; j=j+1)
					conved[i][j] <= 0;
		end
		else begin
			if(flag_conv) begin
				if(cnt_c % 'd3 == 1 && cnt_c <= 193) begin
					conved[3][15] <= conv2_out;
					conved[2][15] <= conved[3][0];
					conved[1][15] <= conved[2][0];
					conved[0][15] <= conved[1][0];
					for(i=3; i>=0; i=i-1)begin
						for(j=14; j>=0; j=j-1)begin
							conved[i][j] <= conved[i][j+1];
						end
					end
				end
				else begin
				end
			end
			else begin
			end
		end
	end
end
// ===============================================================
// activation
// ===============================================================
// ===============================================================
assign pixel_tmp = {~act[31], act[30:0]};
assign relu = (act[31] == 1) ? 0 : act;
assign le_relu = (act[31] == 1) ? leaky_relu : act;
assign out_1 = (opt == 0) ? relu: (opt == 1) ? le_relu : (opt == 2) ? sigmod : tanh; 
// ===============================================================
// e^x
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  exp1    ( .a(act), .z(exp_pos));
// 0.1x   
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) mul1    ( .a(act), .b(zero_point_one), .rnd(3'b000), .z(leaky_relu) );
// e^-x   
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  exp2    ( .a(pixel_tmp), .z(exp_neg));
// 1 + e^-x   
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  add1    ( .a(one),  .b(exp_neg),  .rnd(3'b000),  .z(sigmod_1) );
// e^x + e^-x   
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  add2    ( .a(exp_pos),  .b(exp_neg),  .rnd(3'b000),  .z(tanh_mom) );
// e^x - e^-x   
DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  sub1    ( .a(exp_pos),  .b(exp_neg),  .rnd(3'b000),  .z(tanh_child) );
// e^x - e^-x / e^x + e^-x   
DW_fp_div   #(inst_sig_width, inst_exp_width, inst_ieee_compliance) D1     (.a(tanh_child), .b(tanh_mom), .rnd(3'b000), .z(tanh));
// 1 / 1 + e^-x
DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance) recip2 ( .a(sigmod_1),  .rnd(3'b000),  .z(sigmod) );
// ===============================================================
// flag_pixel, pixel
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		flag_pixel <= 0;	
		act <= 0;
	end
	else begin
		if(cnt_p >= 65) begin
			flag_pixel <= 0;
			act <= 0;
		end
		else begin
			if(cnt_c >= 194)begin
				flag_pixel <= 1;
				case(cnt_p)
					// 0
					0:	act <= conved[0][0];
					2:	act <= conved[0][1];
					4:	act <= conved[0][2];
					6:	act <= conved[0][3];

					16:	act <= conved[0][4];
					18: act <= conved[0][5];
					20: act <= conved[0][6];
					22: act <= conved[0][7];

					32: act <= conved[0][8];
					34: act <= conved[0][9];
					36: act <= conved[0][10];
					38: act <= conved[0][11];

					48: act <= conved[0][12];
					50: act <= conved[0][13];
					52: act <= conved[0][14];
					54: act <= conved[0][15];

					// 1
					1:	act <= conved[1][0];
					3:	act <= conved[1][1];
					5:	act <= conved[1][2];
					7:	act <= conved[1][3];

					17:	act <= conved[1][4];
					19: act <= conved[1][5];
					21: act <= conved[1][6];
					23: act <= conved[1][7];

					33: act <= conved[1][8];
					35: act <= conved[1][9];
					37: act <= conved[1][10];
					39: act <= conved[1][11];

					49: act <= conved[1][12];
					51: act <= conved[1][13];
					53: act <= conved[1][14];
					55: act <= conved[1][15];

					// 2
					8:	act <= conved[2][0];
					10:	act <= conved[2][1];
					12:	act <= conved[2][2];
					14:	act <= conved[2][3];

					24:	act <= conved[2][4];
					26: act <= conved[2][5];
					28: act <= conved[2][6];
					30: act <= conved[2][7];

					40: act <= conved[2][8];
					42: act <= conved[2][9];
					44: act <= conved[2][10];
					46: act <= conved[2][11];

					56: act <= conved[2][12];
					58: act <= conved[2][13];
					60: act <= conved[2][14];
					62: act <= conved[2][15];

					// 3
					9:	act <= conved[3][0];
					11:	act <= conved[3][1];
					13:	act <= conved[3][2];
					15:	act <= conved[3][3];

					25:	act <= conved[3][4];
					27: act <= conved[3][5];
					29: act <= conved[3][6];
					31: act <= conved[3][7];

					41: act <= conved[3][8];
					43: act <= conved[3][9];
					45: act <= conved[3][10];
					47: act <= conved[3][11];

					57: act <= conved[3][12];
					59: act <= conved[3][13];
					61: act <= conved[3][14];
					63: act <= conved[3][15];
					default: act <= 0;
				endcase
			end
			else begin
				flag_pixel <= 0;	
				act <= 0;
			end
		end
	end

end

// cnt_p
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cnt_p <= 0;
	end
	else begin
		if(cnt_c >= 194)begin
			cnt_p <= cnt_p + 1;
		end
		else begin
			if (in_valid_i)
				cnt_p <= 0;
			else begin
			end
		end
	end
end

// ===============================================================
// out
// ===============================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		out <= 0;
		out_valid <= 0;
	end
	else begin
		if(cnt_p >= 65) begin
			out <= 0;	
			out_valid <= 0;
		end
		else begin
			if(cnt_c >= 195)begin
				out_valid <= flag_pixel;
				out <= out_1;
			end
			else begin
				out <= 0;
				out_valid <= 0;
			end
		end
	end
end

endmodule
//================================================================
//  SUBMODULE : DesignWare
//================================================================
//================================================================
// fp_conv
//================================================================
module fp_conv(
	// in1
	in1_1, in1_2, in1_3, 
	in1_4, in1_5, in1_6, 
	in1_7, in1_8, in1_9,
	// in2
	in2_1, in2_2, in2_3, 
	in2_4, in2_5, in2_6, 
	in2_7, in2_8, in2_9,
	// out
	out
);
// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 1;
parameter inst_arch = 2;

input [inst_sig_width+inst_exp_width:0] in1_1, in1_2, in1_3, in1_4, in1_5, in1_6, in1_7, in1_8, in1_9;
input [inst_sig_width+inst_exp_width:0] in2_1, in2_2, in2_3, in2_4, in2_5, in2_6, in2_7, in2_8, in2_9;
output [inst_sig_width+inst_exp_width:0] out;
wire [inst_sig_width+inst_exp_width:0] ot1, ot2, ot3;
DW_fp_dp3  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U01 ( .a(in1_1), .b(in2_1),  .c(in1_2), .d(in2_2), .e(in1_3), .f(in2_3), .rnd(3'b000), .z(ot1) );
DW_fp_dp3  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U02 ( .a(in1_4), .b(in2_4),  .c(in1_5), .d(in2_5), .e(in1_6), .f(in2_6), .rnd(3'b000), .z(ot2) );
DW_fp_dp3  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U03 ( .a(in1_7), .b(in2_7),  .c(in1_8), .d(in2_8), .e(in1_9), .f(in2_9), .rnd(3'b000), .z(ot3) );
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U04 ( .a(ot1), .b(ot2),  .c(ot3), .rnd(3'b000), .z(out) );
endmodule