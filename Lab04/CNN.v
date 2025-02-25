//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Convolution Neural Network 
//   Author     		: Yu-Chi Lin (a6121461214.st12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CNN.v
//   Module Name : CNN
//   Release version : V1.0 (Release Date: 2024-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel_ch1,
    Kernel_ch2,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );


//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel_ch1, Kernel_ch2, Weight;
input Opt;

output reg	out_valid;
output reg [inst_sig_width +inst_exp_width:0] out;


//---------------------------------------------------------------------
//   Reg & Wires
//---------------------------------------------------------------------
parameter FP_ZERO = 32'b00000000000000000000000000000000 ;
parameter FP_ONE = 32'b00111111100000000000000000000000 ;
parameter FP_min = 32'b1_1111111011111111111111111111111;
//reg [2:0] cs_state;
//reg [2:0] ns_state;

reg [inst_sig_width+inst_exp_width:0] kernel_ch1_1_save [1:4];
reg [inst_sig_width+inst_exp_width:0] kernel_ch1_1_save_reg [1:4];
reg [inst_sig_width+inst_exp_width:0] kernel_ch1_2_save [1:4];
reg [inst_sig_width+inst_exp_width:0] kernel_ch1_2_save_reg [1:4];
reg [inst_sig_width+inst_exp_width:0] kernel_ch1_3_save [1:4];
reg [inst_sig_width+inst_exp_width:0] kernel_ch1_3_save_reg [1:4];
reg [inst_sig_width+inst_exp_width:0] kernel_ch2_1_save [1:4];
reg [inst_sig_width+inst_exp_width:0] kernel_ch2_1_save_reg [1:4];
reg [inst_sig_width+inst_exp_width:0] kernel_ch2_2_save [1:4];
reg [inst_sig_width+inst_exp_width:0] kernel_ch2_2_save_reg [1:4];
reg [inst_sig_width+inst_exp_width:0] kernel_ch2_3_save [1:4];
reg [inst_sig_width+inst_exp_width:0] kernel_ch2_3_save_reg [1:4];
reg  [inst_sig_width+inst_exp_width:0] CNN_image[1:5][1:5];
reg  [inst_sig_width+inst_exp_width:0] CNN_image_reg[1:5][1:5];

reg [2:0] local_cnt;
reg [6:0] counting;
reg [6:0] n_counting;
reg [inst_sig_width+inst_exp_width:0] multiplicand1[1:8];
reg [inst_sig_width+inst_exp_width:0] multiplicand2[1:8];
reg [inst_sig_width+inst_exp_width:0] multiplier1[1:8];
reg [inst_sig_width+inst_exp_width:0] multiplier2[1:8];
wire [inst_sig_width+inst_exp_width:0] save_mult_temp1[1:8];
wire [inst_sig_width+inst_exp_width:0] save_mult_temp2[1:8];
reg [inst_sig_width+inst_exp_width:0] save_mult_temp1_reg[1:8];
reg [inst_sig_width+inst_exp_width:0] save_mult_temp2_reg[1:8];
reg [inst_sig_width+inst_exp_width:0] augmend1[1:8];
reg [inst_sig_width+inst_exp_width:0] augmend2[1:8];
reg [inst_sig_width+inst_exp_width:0] addend1[1:8];
reg [inst_sig_width+inst_exp_width:0] addend2[1:8];

wire  [inst_sig_width+inst_exp_width:0] partial_sum1[1:8];
reg  [inst_sig_width+inst_exp_width:0] partial_sum1_reg[1:8];
wire  [inst_sig_width+inst_exp_width:0] partial_sum2[1:8];
reg  [inst_sig_width+inst_exp_width:0] partial_sum2_reg[1:8];


reg  [inst_sig_width+inst_exp_width:0] feature_map1[1:6][1:6];
reg  [inst_sig_width+inst_exp_width:0] feature_map2[1:6][1:6];
reg  [inst_sig_width+inst_exp_width:0] max_pooling1[1:4];
reg  [inst_sig_width+inst_exp_width:0] max_pooling2[1:4];
wire [inst_sig_width+inst_exp_width:0] temp_max1_1;
reg [inst_sig_width+inst_exp_width:0] temp_max1_1_reg;
wire [inst_sig_width+inst_exp_width:0] temp_max1_2;
reg [inst_sig_width+inst_exp_width:0] temp_max1_2_reg;
wire [inst_sig_width+inst_exp_width:0] temp_max1_3;
reg [inst_sig_width+inst_exp_width:0] temp_max1_3_reg;
wire  [inst_sig_width+inst_exp_width:0] temp_max2_1;
reg  [inst_sig_width+inst_exp_width:0] temp_max2_1_reg;
wire  [inst_sig_width+inst_exp_width:0] temp_max2_2;
reg  [inst_sig_width+inst_exp_width:0] temp_max2_2_reg;
wire  [inst_sig_width+inst_exp_width:0] temp_max2_3;
reg  [inst_sig_width+inst_exp_width:0] temp_max2_3_reg;
reg  [inst_sig_width+inst_exp_width:0] comparewho_1_1;
reg  [inst_sig_width+inst_exp_width:0] comparewho_1_2;
reg  [inst_sig_width+inst_exp_width:0] comparewho_1_3;
reg  [inst_sig_width+inst_exp_width:0] comparewho_1_4;
reg  [inst_sig_width+inst_exp_width:0] comparewho_2_1;
reg  [inst_sig_width+inst_exp_width:0] comparewho_2_2;
reg  [inst_sig_width+inst_exp_width:0] comparewho_2_3;
reg  [inst_sig_width+inst_exp_width:0] comparewho_2_4;
reg  [inst_sig_width+inst_exp_width:0] max_pooling_result1[0:1][0:1];
reg  [inst_sig_width+inst_exp_width:0] max_pooling_result2[0:1][0:1];
reg [31:0] exp_time1;
reg [31:0] exp_time2;
reg [31:0] exp_time3;
reg [31:0] exp_time4;
wire [31:0] after_exp1;
wire [31:0] after_exp2;
wire [31:0] after_exp3;
wire [31:0] after_exp4;
reg [31:0] after_exp1_reg;
reg [31:0] after_exp2_reg;
reg [31:0] after_exp3_reg;
reg [31:0] after_exp4_reg;
reg opt_reg;
integer i,j;
reg [31:0] mp_1,mp_2;
wire [31:0] partial_sum3_1;
reg [31:0] partial_sum3_reg_1;
wire [31:0] partial_sum3_2;
reg [31:0] partial_sum3_reg_2;
reg [31:0] div_value1[1:2];
reg [31:0] div_value2[1:2];
reg [31:0] after_div_reg1;
reg [31:0] after_div_reg2[1:4];
wire [31:0] after_div1;
wire [31:0] after_div2;
reg [31:0] minus_constant1;
reg [31:0] minus_constant2;
reg option,option2;
reg [inst_sig_width+inst_exp_width:0] Weight_save1[1:8];
reg [inst_sig_width+inst_exp_width:0] Weight_save2[1:8];
reg [inst_sig_width+inst_exp_width:0] Weight_save3[1:8];
reg [inst_sig_width+inst_exp_width:0] Weight_save1_reg[1:8];
reg [inst_sig_width+inst_exp_width:0] Weight_save2_reg[1:8];
reg [inst_sig_width+inst_exp_width:0] Weight_save3_reg[1:8];
reg [inst_sig_width+inst_exp_width:0] fully_map[1:3];
reg [31:0] soft_max_exp[1:3];
reg [31:0] c,d,f,mother_out,mother_out_reg;
wire [31:0] temp_out;
reg [31:0] n_after_ful[1:3];
reg [31:0] after_ful[1:3];
reg [31:0]conv1_a,conv1_b,conv1_c,conv1_d,conv1_e,conv1_f,conv1_g,conv1_h,z_conv1;
reg [31:0]z_conv1_reg;
reg [31:0]a,b,z;
//---------------------------------------------------------------------
// CNN
//---------------------------------------------------------------------
always@(posedge clk) begin
    if(in_valid&&counting==1) begin
        opt_reg <= Opt;
    end
    
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counting <= 7'b0;
    end
    else if(!in_valid && counting>=76 &&counting<=109) begin
        counting <= counting + 7'd1;
    end 
    /*else if(!in_valid && (counting==7'd76||counting==7'd77||counting==7'd78||counting==7'd79||counting==7'd80||counting==7'd81||counting==7'd82||counting==7'd83)) begin
        counting <= counting + 7'd1;
    end */
    else if(in_valid) begin
        counting <= counting + 7'd1;
    end 
    else begin
        counting <= 7'd1;
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        local_cnt <= 3'b0;
    end
    else if(local_cnt==3'd5) begin
        local_cnt <= 7'd1;
    end
    else if(in_valid) begin
        local_cnt <= local_cnt + 7'd1;
    end 
    else begin
        local_cnt <= 7'd1;
    end
end
always@(*) begin//maybe can delete reset 
    for(i=1;i<=4;i=i+1) begin
            kernel_ch1_1_save[i] = kernel_ch1_1_save_reg[i]; 
    end 
    
        case (counting)
            1: begin
                kernel_ch1_1_save[1] = Kernel_ch1;
                kernel_ch1_1_save[2] = kernel_ch1_1_save_reg[2];
                kernel_ch1_1_save[3] = kernel_ch1_1_save_reg[3]; 
                kernel_ch1_1_save[4] = kernel_ch1_1_save_reg[4]; 
            end
            2: begin
                kernel_ch1_1_save[1] = kernel_ch1_1_save_reg[1];
                kernel_ch1_1_save[2] = Kernel_ch1;
                kernel_ch1_1_save[3] = kernel_ch1_1_save_reg[3];
                kernel_ch1_1_save[4] = kernel_ch1_1_save_reg[4];
            end
            3: begin
                kernel_ch1_1_save[1] = kernel_ch1_1_save_reg[1];
                kernel_ch1_1_save[2] = kernel_ch1_1_save_reg[2];
                kernel_ch1_1_save[3] = Kernel_ch1;
                kernel_ch1_1_save[4] = kernel_ch1_1_save_reg[4];
            end
            4:  begin
                kernel_ch1_1_save[1] = kernel_ch1_1_save_reg[1];
                kernel_ch1_1_save[2] = kernel_ch1_1_save_reg[2];
                kernel_ch1_1_save[3] = kernel_ch1_1_save_reg[3];
                kernel_ch1_1_save[4] = Kernel_ch1;
            end
        endcase
    
end
always@(posedge clk) begin//maybe can delete reset
    for(i=1;i<=4;i=i+1) begin
        kernel_ch1_1_save_reg[i] <= kernel_ch1_1_save[i]; 
    end 
end
always@(*) begin//maybe can delete reset
    for(i=1;i<=4;i=i+1) begin
        kernel_ch1_2_save[i] = kernel_ch1_2_save_reg[i]; 
    end 
    
        case (counting)
            5: begin
                kernel_ch1_2_save[1] = Kernel_ch1;
                kernel_ch1_2_save[2] = kernel_ch1_2_save_reg[2];
                kernel_ch1_2_save[3] = kernel_ch1_2_save_reg[3]; 
                kernel_ch1_2_save[4] = kernel_ch1_2_save_reg[4];
            end
            6: begin
                kernel_ch1_2_save[1] = kernel_ch1_2_save_reg[1];
                kernel_ch1_2_save[2] = Kernel_ch1;
                kernel_ch1_2_save[3] = kernel_ch1_2_save_reg[3];
                kernel_ch1_2_save[4] = kernel_ch1_2_save_reg[4];
            end
            7: begin
                kernel_ch1_2_save[1] = kernel_ch1_2_save_reg[1];
                kernel_ch1_2_save[2] = kernel_ch1_2_save_reg[2];
                kernel_ch1_2_save[3] = Kernel_ch1;
                kernel_ch1_2_save[4] = kernel_ch1_2_save_reg[4];
            end
            8:  begin
                kernel_ch1_2_save[1] = kernel_ch1_2_save_reg[1];
                kernel_ch1_2_save[2] = kernel_ch1_2_save_reg[2];
                kernel_ch1_2_save[3] = kernel_ch1_2_save_reg[3];
                kernel_ch1_2_save[4] = Kernel_ch1;
            end
        endcase
    
end
always@(posedge clk) begin//maybe can delete reset
    for(i=1;i<=4;i=i+1) begin
        kernel_ch1_2_save_reg[i] <= kernel_ch1_2_save[i]; 
    end 
end

always@(*) begin//maybe can delete reset
    for(i=1;i<=4;i=i+1) begin
            kernel_ch1_3_save[i] = kernel_ch1_3_save_reg[i]; 
    end 
    
        case (counting)
            9: begin
                kernel_ch1_3_save[1] = Kernel_ch1;
                kernel_ch1_3_save[2] = kernel_ch1_3_save_reg[2];
                kernel_ch1_3_save[3] = kernel_ch1_3_save_reg[3];
                kernel_ch1_3_save[4] = kernel_ch1_3_save_reg[4];
            end
            10: begin
                kernel_ch1_3_save[1] = kernel_ch1_3_save_reg[1];
                kernel_ch1_3_save[2] = Kernel_ch1;
                kernel_ch1_3_save[3] = kernel_ch1_3_save_reg[3];
                kernel_ch1_3_save[4] = kernel_ch1_3_save_reg[4];
            end
            11: begin
                kernel_ch1_3_save[1] = kernel_ch1_3_save_reg[1];
                kernel_ch1_3_save[2] = kernel_ch1_3_save_reg[2];
                kernel_ch1_3_save[3] = Kernel_ch1;
                kernel_ch1_3_save[4] = kernel_ch1_3_save_reg[4];
            end
            12:  begin
                kernel_ch1_3_save[1] = kernel_ch1_3_save_reg[1];
                kernel_ch1_3_save[2] = kernel_ch1_3_save_reg[2];
                kernel_ch1_3_save[3] = kernel_ch1_3_save_reg[3];
                kernel_ch1_3_save[4] = Kernel_ch1;
            end
        endcase
end
always@(posedge clk) begin//maybe can delete reset
    for(i=1;i<=4;i=i+1) begin
        kernel_ch1_3_save_reg[i] <= kernel_ch1_3_save[i]; 
    end 
end
always@(*) begin//maybe can delete reset
    for(i=1;i<=4;i=i+1) begin
        kernel_ch2_1_save[i] = kernel_ch2_1_save_reg[i]; 
    end 
    
        case (counting)
            1: begin
                kernel_ch2_1_save[1] = Kernel_ch2;
            end
            2: begin
                kernel_ch2_1_save[2] = Kernel_ch2;
            end
            3: begin
                kernel_ch2_1_save[3] = Kernel_ch2;
            end
            4:  begin
                kernel_ch2_1_save[4] = Kernel_ch2;
            end
        endcase
    
end
always@(posedge clk) begin//maybe can delete reset
    for(i=1;i<=4;i=i+1) begin
        kernel_ch2_1_save_reg[i] <= kernel_ch2_1_save[i]; 
    end 
end
always@(*) begin//maybe can delete reset
    for(i=1;i<=4;i=i+1) begin
        kernel_ch2_2_save[i] = kernel_ch2_2_save_reg[i]; 
    end
        case (counting)
            5: begin
                kernel_ch2_2_save[1] = Kernel_ch2;
            end
            6: begin
                kernel_ch2_2_save[2] = Kernel_ch2;
            end
            7: begin
                kernel_ch2_2_save[3] = Kernel_ch2;
            end
            8:  begin
                kernel_ch2_2_save[4] = Kernel_ch2;
            end
        endcase
end
always@(posedge clk) begin//maybe can delete reset
    for(i=1;i<=4;i=i+1) begin
        kernel_ch2_2_save_reg[i] <= kernel_ch2_2_save[i]; 
    end 
end

always@(*) begin//maybe can delete reset
    for(i=1;i<=4;i=i+1) begin
        kernel_ch2_3_save[i] = kernel_ch2_3_save_reg[i]; 
    end
    
        case (counting)
            9: begin
                kernel_ch2_3_save[1] = Kernel_ch2;
            end
            10: begin
                kernel_ch2_3_save[2] = Kernel_ch2;
            end
            11: begin
                kernel_ch2_3_save[3] = Kernel_ch2;
            end
            12:  begin
                kernel_ch2_3_save[4] = Kernel_ch2;
            end
        endcase
    
end
always@(posedge clk) begin//maybe can delete reset
    for(i=1;i<=4;i=i+1) begin
        kernel_ch2_3_save_reg[i] <= kernel_ch2_3_save[i]; 
    end 
end
always@(*) begin
    for(i=1;i<=5;i=i+1) begin
        for(j=1;j<=5;j=j+1) begin
            CNN_image[i][j] = CNN_image_reg[i][j];
        end 
    end 
    
        if((counting==1 || counting == 26  || counting == 51)&& local_cnt==1) begin
            CNN_image[1][1] = Img;
        end 
        else if((counting==2 || counting == 27 || counting == 52)&& local_cnt==2) begin
            CNN_image[1][2] = Img;
        end 
        else if((counting==3 || counting == 28 || counting == 53)&& local_cnt==3) begin
            CNN_image[1][3] = Img;
        end 
        else if((counting==4 || counting == 29 || counting == 54)&& local_cnt==4) begin
            CNN_image[1][4] = Img;
        end
        else if((counting==5 || counting == 30 || counting == 55)&& local_cnt==5) begin
            CNN_image[1][5] = Img;
        end
        else if((counting==6 || counting == 31 || counting == 56 )&& local_cnt==1) begin
            CNN_image[2][1] = Img;
        end 
        else if((counting==7 || counting == 32 || counting == 57)&& local_cnt==2) begin
            CNN_image[2][2] = Img;
        end 
        else if((counting==8 || counting == 33 || counting == 58)&& local_cnt==3) begin
            CNN_image[2][3] = Img;
        end 
        else if((counting==9 || counting == 34 || counting == 59) && local_cnt==4) begin
            CNN_image[2][4] = Img;
        end
        else if((counting==10 || counting == 35 || counting == 60) && local_cnt==5) begin
            CNN_image[2][5] = Img;
        end
        else if((counting==11 || counting == 36 || counting == 61) && local_cnt==1) begin
            CNN_image[3][1] = Img;
        end 
        else if((counting==12 || counting == 37 || counting == 62) && local_cnt==2) begin
            CNN_image[3][2] = Img;
        end 
        else if((counting==13 || counting == 38 || counting == 63) && local_cnt==3) begin
            CNN_image[3][3] = Img;
        end 
        else if((counting==14 || counting == 39 || counting == 64) && local_cnt==4) begin
            CNN_image[3][4] = Img;
        end
        else if((counting==15 || counting == 40 || counting == 65) && local_cnt==5) begin
            CNN_image[3][5] = Img;
        end
        else if((counting==16 || counting == 41 || counting == 66) && local_cnt==1) begin
            CNN_image[4][1] = Img;
        end 
        else if((counting==17 || counting == 42 || counting == 67) && local_cnt==2) begin
            CNN_image[4][2] = Img;
        end 
        else if((counting==18 || counting == 43 || counting == 68) && local_cnt==3) begin
            CNN_image[4][3] = Img;
        end 
        else if((counting==19 || counting == 44 || counting == 69) && local_cnt==4) begin
            CNN_image[4][4] = Img;
        end
        else if((counting==20 || counting == 45 || counting == 70) && local_cnt==5) begin
            CNN_image[4][5] = Img;
        end
        else if((counting==21 || counting == 46 || counting == 71) && local_cnt==1) begin
            CNN_image[5][1] = Img;
        end 
        else if((counting==22 || counting == 47 || counting == 72) && local_cnt==2) begin
            CNN_image[5][2] = Img;
        end 
        else if((counting==23 || counting == 48 || counting == 73) && local_cnt==3) begin
            CNN_image[5][3] = Img;
        end 
        else if((counting==24 || counting == 49 || counting == 74) && local_cnt==4) begin
            CNN_image[5][4] = Img;
        end
        else if((counting==25 || counting == 50 || counting == 75) && local_cnt==5) begin
            CNN_image[5][5] = Img;
        end
        
    
end
always@(posedge clk) begin
    for(i=1;i<=5;i=i+1) begin
        for(j=1;j<=5;j=j+1) begin
            CNN_image_reg[i][j] <= CNN_image[i][j];
        end 
    end 
end

always@(*) begin
        if(counting==13 || counting == 38 || counting == 60) begin
            multiplicand1[1] = (opt_reg) ? CNN_image_reg[1][1] : FP_ZERO;//1
            multiplicand1[2] = (opt_reg) ? CNN_image_reg[1][1] : FP_ZERO;//2
            multiplicand1[3] = (opt_reg) ? CNN_image_reg[1][1] : FP_ZERO;//3
            multiplicand1[4] = CNN_image_reg[1][1];//4
            multiplicand1[5] = (opt_reg) ? CNN_image_reg[1][1] : FP_ZERO;//1
            multiplicand1[6] = (opt_reg) ? CNN_image_reg[1][2] : FP_ZERO;//2
            multiplicand1[7] = CNN_image_reg[1][1];//3
            multiplicand1[8] = CNN_image_reg[1][2];//4
        end
        else if(counting==14 || counting == 39 || counting == 61) begin
            multiplicand1[1] = (opt_reg) ? CNN_image_reg[1][2] : FP_ZERO;//1
            multiplicand1[2] = (opt_reg) ? CNN_image_reg[1][3] : FP_ZERO;//2
            multiplicand1[3] = CNN_image_reg[1][2];//3
            multiplicand1[4] = CNN_image_reg[1][3];//4
            multiplicand1[5] = (opt_reg) ? CNN_image_reg[1][3] : FP_ZERO;//1
            multiplicand1[6] = (opt_reg) ? CNN_image_reg[1][4] : FP_ZERO;//2
            multiplicand1[7] = CNN_image_reg[1][3];//3
            multiplicand1[8] = CNN_image_reg[1][4];//4
        end
        else if(counting==15 || counting == 40 || counting == 62) begin
            multiplicand1[1] = (opt_reg) ? CNN_image_reg[1][4] : FP_ZERO;//1
            multiplicand1[2] = (opt_reg) ? CNN_image_reg[1][5] : FP_ZERO;//2
            multiplicand1[3] = CNN_image_reg[1][4];//3
            multiplicand1[4] = CNN_image_reg[1][5];//4
            multiplicand1[5] = (opt_reg) ? CNN_image_reg[1][5] : FP_ZERO;//1
            multiplicand1[6] = (opt_reg) ? CNN_image_reg[1][5] : FP_ZERO;//2
            multiplicand1[7] = CNN_image_reg[1][5];//3
            multiplicand1[8] = (opt_reg) ? CNN_image_reg[1][5] : FP_ZERO;//4
        end
        else if(counting==16 || counting == 41 || counting == 63) begin
            multiplicand1[1] = (opt_reg) ? CNN_image_reg[1][1] : FP_ZERO;//1
            multiplicand1[2] = CNN_image_reg[1][1];//2
            multiplicand1[3] = (opt_reg) ? CNN_image_reg[2][1] : FP_ZERO;//3
            multiplicand1[4] = CNN_image_reg[2][1];//4
            multiplicand1[5] = CNN_image_reg[1][1];//1
            multiplicand1[6] = CNN_image_reg[1][2];//2
            multiplicand1[7] = CNN_image_reg[2][1];//3
            multiplicand1[8] = CNN_image_reg[2][2];//4
        end
        else if(counting==17 || counting == 42 || counting == 64) begin
            multiplicand1[1] = CNN_image_reg[1][2];//1
            multiplicand1[2] = CNN_image_reg[1][3];//2
            multiplicand1[3] = CNN_image_reg[2][2];//3
            multiplicand1[4] = CNN_image_reg[2][3];//4
            multiplicand1[5] = CNN_image_reg[1][3];//1
            multiplicand1[6] = CNN_image_reg[1][4];//2
            multiplicand1[7] = CNN_image_reg[2][3];//3
            multiplicand1[8] = CNN_image_reg[2][4];//4
        end
        else if(counting==18 || counting == 43 || counting == 65) begin
            multiplicand1[1] = CNN_image_reg[1][4];//1
            multiplicand1[2] = CNN_image_reg[1][5];//2
            multiplicand1[3] = CNN_image_reg[2][4];//3
            multiplicand1[4] = CNN_image_reg[2][5];//4
            multiplicand1[5] = CNN_image_reg[1][5];//1
            multiplicand1[6] = (opt_reg) ? CNN_image_reg[1][5] : FP_ZERO;//2
            multiplicand1[7] = CNN_image_reg[2][5];//3
            multiplicand1[8] = (opt_reg) ? CNN_image_reg[2][5] : FP_ZERO;//4
        end
        else if(counting==19 || counting == 44 || counting == 66) begin
            multiplicand1[1] = (opt_reg) ? CNN_image_reg[2][1] : FP_ZERO;//1
            multiplicand1[2] = CNN_image_reg[2][1];//2
            multiplicand1[3] = (opt_reg) ? CNN_image_reg[3][1] : FP_ZERO;//3
            multiplicand1[4] = CNN_image_reg[3][1];//4
            multiplicand1[5] = CNN_image_reg[2][1];//1
            multiplicand1[6] = CNN_image_reg[2][2];//2
            multiplicand1[7] = CNN_image_reg[3][1];//3
            multiplicand1[8] = CNN_image_reg[3][2];//4
        end
        else if(counting==20 || counting == 45 || counting == 67) begin
            multiplicand1[1] = CNN_image_reg[2][2];//1
            multiplicand1[2] = CNN_image_reg[2][3];//2
            multiplicand1[3] = CNN_image_reg[3][2];//3
            multiplicand1[4] = CNN_image_reg[3][3];//4
            multiplicand1[5] = CNN_image_reg[2][3];//1
            multiplicand1[6] = CNN_image_reg[2][4];//2
            multiplicand1[7] = CNN_image_reg[3][3];//3
            multiplicand1[8] = CNN_image_reg[3][4];//4
        end
        else if(counting==21 || counting == 46 || counting == 68) begin
            multiplicand1[1] = CNN_image_reg[2][4];//1
            multiplicand1[2] = CNN_image_reg[2][5];//2
            multiplicand1[3] = CNN_image_reg[3][4];//3
            multiplicand1[4] = CNN_image_reg[3][5];//4
            multiplicand1[5] = CNN_image_reg[2][5];//1
            multiplicand1[6] = (opt_reg) ? CNN_image_reg[2][5] : FP_ZERO;//2
            multiplicand1[7] = CNN_image_reg[3][5];//3
            multiplicand1[8] = (opt_reg) ? CNN_image_reg[3][5] : FP_ZERO;//4
        end
        else if(counting==22 || counting == 47 || counting == 69) begin
            multiplicand1[1] = (opt_reg) ? CNN_image_reg[3][1] : FP_ZERO;//1
            multiplicand1[2] = CNN_image_reg[3][1];//2
            multiplicand1[3] = (opt_reg) ? CNN_image_reg[4][1] : FP_ZERO;//3
            multiplicand1[4] = CNN_image_reg[4][1];//4
            multiplicand1[5] = CNN_image_reg[3][1];//1
            multiplicand1[6] = CNN_image_reg[3][2];//2
            multiplicand1[7] = CNN_image_reg[4][1];//3
            multiplicand1[8] = CNN_image_reg[4][2];//4
        end
        else if(counting==23 || counting == 48 ) begin
            multiplicand1[1] = CNN_image_reg[3][2];//1
            multiplicand1[2] = CNN_image_reg[3][3];//2
            multiplicand1[3] = CNN_image_reg[4][2];//3
            multiplicand1[4] = CNN_image_reg[4][3];//4
            multiplicand1[5] = CNN_image_reg[3][3];//1
            multiplicand1[6] = CNN_image_reg[3][4];//2
            multiplicand1[7] = CNN_image_reg[4][3];//3
            multiplicand1[8] = CNN_image_reg[4][4];//4
        end
        else if(counting==24 || counting == 49 ) begin
            multiplicand1[1] = CNN_image_reg[3][4];//1
            multiplicand1[2] = CNN_image_reg[3][5];//2
            multiplicand1[3] = CNN_image_reg[4][4];//3
            multiplicand1[4] = CNN_image_reg[4][5];//4
            multiplicand1[5] = CNN_image_reg[3][5];//1
            multiplicand1[6] = (opt_reg) ? CNN_image_reg[3][5] : FP_ZERO;//2
            multiplicand1[7] = CNN_image_reg[4][5];//3
            multiplicand1[8] = (opt_reg) ? CNN_image_reg[4][5] : FP_ZERO;//4
        end
        else if(counting==25 || counting == 50 ) begin
            multiplicand1[1] = (opt_reg) ? CNN_image_reg[4][1] : FP_ZERO;//1
            multiplicand1[2] = CNN_image_reg[4][1];//2
            multiplicand1[3] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//3
            multiplicand1[4] = CNN_image_reg[5][1];//4
            multiplicand1[5] = CNN_image_reg[4][1];//1
            multiplicand1[6] = CNN_image_reg[4][2];//2
            multiplicand1[7] = CNN_image_reg[5][1];//3
            multiplicand1[8] = CNN_image_reg[5][2];//4
        end
        else if(counting==26 || counting == 51 ) begin
            multiplicand1[1] = CNN_image_reg[4][2];//1
            multiplicand1[2] = CNN_image_reg[4][3];//2
            multiplicand1[3] = CNN_image_reg[5][2];//3
            multiplicand1[4] = CNN_image_reg[5][3];//4
            multiplicand1[5] = CNN_image_reg[4][3];//1
            multiplicand1[6] = CNN_image_reg[4][4];//2
            multiplicand1[7] = CNN_image_reg[5][3];//3
            multiplicand1[8] = CNN_image_reg[5][4];//4
        end
        else if(counting==27 || counting == 52 ) begin
            multiplicand1[1] = CNN_image_reg[4][4];//1
            multiplicand1[2] = CNN_image_reg[4][5];//2
            multiplicand1[3] = CNN_image_reg[5][4];//3
            multiplicand1[4] = CNN_image_reg[5][5];//4
            multiplicand1[5] = CNN_image_reg[4][5];//1
            multiplicand1[6] = (opt_reg) ? CNN_image_reg[4][5] : FP_ZERO;//2
            multiplicand1[7] = CNN_image_reg[5][5];//3
            multiplicand1[8] = (opt_reg) ? CNN_image_reg[5][5] : FP_ZERO;//4
        end
        else if(counting==28 || counting == 53 ) begin
            multiplicand1[1] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//1
            multiplicand1[2] = CNN_image_reg[5][1];//2
            multiplicand1[3] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//3
            multiplicand1[4] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//4
            multiplicand1[5] = CNN_image_reg[5][1];//1
            multiplicand1[6] = CNN_image_reg[5][2];//2
            multiplicand1[7] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//3
            multiplicand1[8] = (opt_reg) ? CNN_image_reg[5][2] : FP_ZERO;//4
        end
        else if(counting==29 || counting == 54 ) begin
            multiplicand1[1] =CNN_image_reg[5][2];//1
            multiplicand1[2] =CNN_image_reg[5][3];//2
            multiplicand1[3] = (opt_reg) ? CNN_image_reg[5][2] : FP_ZERO;//3
            multiplicand1[4] = (opt_reg) ? CNN_image_reg[5][3] : FP_ZERO;//4
            multiplicand1[5] =CNN_image_reg[5][3];//1
            multiplicand1[6] =CNN_image_reg[5][4];//2
            multiplicand1[7] = (opt_reg) ? CNN_image_reg[5][3] : FP_ZERO;//3
            multiplicand1[8] = (opt_reg) ? CNN_image_reg[5][4] : FP_ZERO;//4
        end
        else if(counting==30  || counting == 55 ) begin
            multiplicand1[1] = CNN_image_reg[5][4];//1
            multiplicand1[2] = CNN_image_reg[5][5];//2
            multiplicand1[3] = (opt_reg) ? CNN_image_reg[5][4] : FP_ZERO;//3
            multiplicand1[4] = (opt_reg) ? CNN_image_reg[5][5] : FP_ZERO;//4
            multiplicand1[5] = CNN_image_reg[5][5];//1
            multiplicand1[6] = (opt_reg) ? CNN_image_reg[5][5] : FP_ZERO;//2
            multiplicand1[7] = (opt_reg) ? CNN_image_reg[5][5] : FP_ZERO;//3
            multiplicand1[8] = (opt_reg) ? CNN_image_reg[5][5] : FP_ZERO;//4
        end
        else if( counting == 70) begin
            multiplicand1[1] =CNN_image_reg[3][2];//1
            multiplicand1[2] =CNN_image_reg[3][3];//2
            multiplicand1[3] =CNN_image_reg[4][2];//3
            multiplicand1[4] =CNN_image_reg[4][3];//4
            multiplicand1[5] =CNN_image_reg[3][3];//1
            multiplicand1[6] =CNN_image_reg[3][4];//2
            multiplicand1[7] =CNN_image_reg[4][3];//3
            multiplicand1[8] =CNN_image_reg[4][4];//4
        end
        else if(counting==71 ) begin
            multiplicand1[1] =CNN_image_reg[3][4];//1
            multiplicand1[2] =CNN_image_reg[3][5];//2
            multiplicand1[3] =CNN_image_reg[4][4];//3
            multiplicand1[4] =CNN_image_reg[4][5];//4
            multiplicand1[5] =CNN_image_reg[3][5];//1
            multiplicand1[6] = (opt_reg) ? CNN_image_reg[3][5] : FP_ZERO;//2
            multiplicand1[7] =CNN_image_reg[4][5];//3
            multiplicand1[8] = (opt_reg) ? CNN_image_reg[4][5] : FP_ZERO;//4
        end
        else if(counting==72 ) begin
            multiplicand1[1] = (opt_reg) ? CNN_image_reg[4][1] : FP_ZERO;//1
            multiplicand1[2] = CNN_image_reg[4][1];//2
            multiplicand1[3] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//3
            multiplicand1[4] = CNN_image_reg[5][1];//4
            multiplicand1[5] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//1
            multiplicand1[6] = CNN_image_reg[5][1];//2
            multiplicand1[7] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//3
            multiplicand1[8] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//4
        end
        else if(counting==73 ) begin
            multiplicand1[1] = CNN_image_reg[4][1];//1
            multiplicand1[2] = CNN_image_reg[4][2];//2
            multiplicand1[3] = CNN_image_reg[5][1];//3
            multiplicand1[4] = CNN_image_reg[5][2];//4
            multiplicand1[5] = CNN_image_reg[5][1];//1
            multiplicand1[6] = CNN_image_reg[5][2];//2
            multiplicand1[7] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//3
            multiplicand1[8] = (opt_reg) ? CNN_image_reg[5][2] : FP_ZERO;//4
        end
        else if(counting==74 ) begin
            multiplicand1[1] = CNN_image_reg[4][2];//1
            multiplicand1[2] = CNN_image_reg[4][3];//2
            multiplicand1[3] = CNN_image_reg[5][2];//3
            multiplicand1[4] = CNN_image_reg[5][3];//4
            multiplicand1[5] = CNN_image_reg[5][2];//1
            multiplicand1[6] = CNN_image_reg[5][3];//2
            multiplicand1[7] = (opt_reg) ? CNN_image_reg[5][2] : FP_ZERO;//3
            multiplicand1[8] = (opt_reg) ? CNN_image_reg[5][3] : FP_ZERO;//4
        end
        else if(counting==75 ) begin
            multiplicand1[1] = CNN_image_reg[4][3];//1
            multiplicand1[2] = CNN_image_reg[4][4];//2
            multiplicand1[3] = CNN_image_reg[5][3];//3
            multiplicand1[4] = CNN_image_reg[5][4];//4
            multiplicand1[5] = CNN_image_reg[5][3];//1
            multiplicand1[6] = CNN_image_reg[5][4];//2
            multiplicand1[7] = (opt_reg) ? CNN_image_reg[5][3] : FP_ZERO;//3
            multiplicand1[8] = (opt_reg) ? CNN_image_reg[5][4] : FP_ZERO;//4
        end
        else if(counting==76 ) begin
            multiplicand1[1] =CNN_image_reg[4][4];//1
            multiplicand1[2] =CNN_image_reg[4][5];//2
            multiplicand1[3] =CNN_image_reg[5][4];//3
            multiplicand1[4] =CNN_image_reg[5][5];//4
            multiplicand1[5] =CNN_image_reg[5][4];//1
            multiplicand1[6] =CNN_image_reg[5][5];//2
            multiplicand1[7] = (opt_reg) ? CNN_image_reg[5][4] : FP_ZERO;//3
            multiplicand1[8] = (opt_reg) ? CNN_image_reg[5][5] : FP_ZERO;//4
        end
        else if(counting==77 ) begin
            multiplicand1[1] = CNN_image_reg[4][5];//1
            multiplicand1[2] = (opt_reg) ? CNN_image_reg[4][5]: FP_ZERO;//2
            multiplicand1[3] = CNN_image_reg[5][5];//3
            multiplicand1[4] = (opt_reg) ? CNN_image_reg[5][5]: FP_ZERO;//4
            multiplicand1[5] = CNN_image_reg[5][5];//1
            multiplicand1[6] = (opt_reg) ? CNN_image_reg[5][5]: FP_ZERO;//2
            multiplicand1[7] = (opt_reg) ? CNN_image_reg[5][5] : FP_ZERO;//3
            multiplicand1[8] = (opt_reg) ? CNN_image_reg[5][5] : FP_ZERO;//4
        end
       
        else begin
            multiplicand1[1] = 0;
            multiplicand1[2] = 0;
            multiplicand1[3] = 0;
            multiplicand1[4] = 0;
            multiplicand1[5] = 0;
            multiplicand1[6] = 0;
            multiplicand1[7] = 0;
            multiplicand1[8] = 0;
        end
end

always@(*) begin
        if(counting==13 || counting == 38 || counting == 60) begin
            multiplicand2[1] = (opt_reg) ? CNN_image_reg[1][1] : FP_ZERO;//1
            multiplicand2[2] = (opt_reg) ? CNN_image_reg[1][1] : FP_ZERO;//2
            multiplicand2[3] = (opt_reg) ? CNN_image_reg[1][1] : FP_ZERO;//3
            multiplicand2[4] =  CNN_image_reg[1][1];//4
            multiplicand2[5] = (opt_reg) ? CNN_image_reg[1][1] : FP_ZERO;//1
            multiplicand2[6] = (opt_reg) ? CNN_image_reg[1][2] : FP_ZERO;//2
            multiplicand2[7] = CNN_image_reg[1][1] ;//3
            multiplicand2[8] = CNN_image_reg[1][2] ;//4
        end
        else if(counting==14 || counting == 39 || counting == 61) begin
            multiplicand2[1] = (opt_reg) ? CNN_image_reg[1][2] : FP_ZERO;//1
            multiplicand2[2] = (opt_reg) ? CNN_image_reg[1][3] : FP_ZERO;//2
            multiplicand2[3] = CNN_image_reg[1][2];//3
            multiplicand2[4] = CNN_image_reg[1][3];//4
            multiplicand2[5] = (opt_reg) ? CNN_image_reg[1][3] : FP_ZERO;//1
            multiplicand2[6] = (opt_reg) ? CNN_image_reg[1][4] : FP_ZERO;//2
            multiplicand2[7] = CNN_image_reg[1][3];//3
            multiplicand2[8] = CNN_image_reg[1][4];//4
        end
        else if(counting==15 || counting == 40 || counting == 62) begin
            multiplicand2[1] = (opt_reg) ? CNN_image_reg[1][4] : FP_ZERO;//1
            multiplicand2[2] = (opt_reg) ? CNN_image_reg[1][5] : FP_ZERO;//2
            multiplicand2[3] = CNN_image_reg[1][4];//3
            multiplicand2[4] = CNN_image_reg[1][5];//4
            multiplicand2[5] = (opt_reg) ? CNN_image_reg[1][5] : FP_ZERO;//1
            multiplicand2[6] = (opt_reg) ? CNN_image_reg[1][5] : FP_ZERO;//2
            multiplicand2[7] = CNN_image_reg[1][5];//3
            multiplicand2[8] = (opt_reg) ? CNN_image_reg[1][5] : FP_ZERO;//4
        end
        else if(counting==16 || counting == 41 || counting == 63) begin
            multiplicand2[1] = (opt_reg) ? CNN_image_reg[1][1] : FP_ZERO;//1
            multiplicand2[2] = CNN_image_reg[1][1];//2
            multiplicand2[3] = (opt_reg) ? CNN_image_reg[2][1] : FP_ZERO;//3
            multiplicand2[4] = CNN_image_reg[2][1];//4
            multiplicand2[5] = CNN_image_reg[1][1];//1
            multiplicand2[6] = CNN_image_reg[1][2];//2
            multiplicand2[7] = CNN_image_reg[2][1];//3
            multiplicand2[8] = CNN_image_reg[2][2];//4
        end
        else if(counting==17 || counting == 42 || counting == 64) begin
            multiplicand2[1] = CNN_image_reg[1][2];//1
            multiplicand2[2] = CNN_image_reg[1][3];//2
            multiplicand2[3] = CNN_image_reg[2][2];//3
            multiplicand2[4] = CNN_image_reg[2][3];//4
            multiplicand2[5] = CNN_image_reg[1][3];//1
            multiplicand2[6] = CNN_image_reg[1][4];//2
            multiplicand2[7] = CNN_image_reg[2][3];//3
            multiplicand2[8] = CNN_image_reg[2][4];//4
        end
        else if(counting==18 || counting == 43 || counting == 65) begin
            multiplicand2[1] =  CNN_image_reg[1][4] ;//1
            multiplicand2[2] =  CNN_image_reg[1][5] ;//2
            multiplicand2[3] =  CNN_image_reg[2][4] ;//3
            multiplicand2[4] =  CNN_image_reg[2][5] ;//4
            multiplicand2[5] = CNN_image_reg[1][5];
            multiplicand2[6] = (opt_reg) ? CNN_image_reg[1][5] : FP_ZERO;//1
            multiplicand2[7] = CNN_image_reg[2][5];//4
            multiplicand2[8] = (opt_reg) ? CNN_image_reg[2][5] : FP_ZERO;//3
        end
        else if(counting==19 || counting == 44 || counting == 66) begin
            multiplicand2[1] = (opt_reg) ? CNN_image_reg[2][1] : FP_ZERO;//1
            multiplicand2[2] = CNN_image_reg[2][1];//2
            multiplicand2[3] = (opt_reg) ? CNN_image_reg[3][1] : FP_ZERO;//3
            multiplicand2[4] = CNN_image_reg[3][1];//4
            multiplicand2[5] = CNN_image_reg[2][1];//1
            multiplicand2[6] = CNN_image_reg[2][2];//2
            multiplicand2[7] = CNN_image_reg[3][1];//3
            multiplicand2[8] = CNN_image_reg[3][2];//4
        end
        else if(counting==20 || counting == 45 || counting == 67) begin
            multiplicand2[1] = CNN_image_reg[2][2];//1
            multiplicand2[2] = CNN_image_reg[2][3];//2
            multiplicand2[3] = CNN_image_reg[3][2];//3
            multiplicand2[4] = CNN_image_reg[3][3];//4
            multiplicand2[5] = CNN_image_reg[2][3];//1
            multiplicand2[6] = CNN_image_reg[2][4];//2
            multiplicand2[7] = CNN_image_reg[3][3];//3
            multiplicand2[8] = CNN_image_reg[3][4];//4
        end
        else if(counting==21 || counting == 46 || counting == 68) begin
            multiplicand2[1] = CNN_image_reg[2][4];//1
            multiplicand2[2] = CNN_image_reg[2][5];//2
            multiplicand2[3] = CNN_image_reg[3][4];//3
            multiplicand2[4] = CNN_image_reg[3][5];//4
            multiplicand2[5] = CNN_image_reg[2][5];//1
            multiplicand2[6] = (opt_reg) ? CNN_image_reg[2][5] : FP_ZERO;//2
            multiplicand2[7] = CNN_image_reg[3][5];//3
            multiplicand2[8] = (opt_reg) ? CNN_image_reg[3][5] : FP_ZERO;//4
        end
        else if(counting==22 || counting == 47 || counting == 69) begin
            multiplicand2[1] = (opt_reg) ? CNN_image_reg[3][1] : FP_ZERO;//1
            multiplicand2[2] = CNN_image_reg[3][1];//2
            multiplicand2[3] = (opt_reg) ? CNN_image_reg[4][1] : FP_ZERO;//3
            multiplicand2[4] = CNN_image_reg[4][1];//4
            multiplicand2[5] = CNN_image_reg[3][1];//1
            multiplicand2[6] = CNN_image_reg[3][2];//2
            multiplicand2[7] = CNN_image_reg[4][1];//3
            multiplicand2[8] = CNN_image_reg[4][2];//4
        end
        else if(counting==23 || counting == 48 ) begin
            multiplicand2[1] = CNN_image_reg[3][2];//1
            multiplicand2[2] = CNN_image_reg[3][3];//2
            multiplicand2[3] = CNN_image_reg[4][2];//3
            multiplicand2[4] = CNN_image_reg[4][3];//4
            multiplicand2[5] = CNN_image_reg[3][3];//1
            multiplicand2[6] = CNN_image_reg[3][4];//2
            multiplicand2[7] = CNN_image_reg[4][3];//3
            multiplicand2[8] = CNN_image_reg[4][4];//4
        end
        else if(counting==24 || counting == 49 ) begin
            multiplicand2[1] = CNN_image_reg[3][4];//1
            multiplicand2[2] = CNN_image_reg[3][5];//2
            multiplicand2[3] = CNN_image_reg[4][4];//3
            multiplicand2[4] = CNN_image_reg[4][5];//4
            multiplicand2[5] = CNN_image_reg[3][5];//1
            multiplicand2[6] = (opt_reg) ? CNN_image_reg[3][5] : FP_ZERO;//2
            multiplicand2[7] = CNN_image_reg[4][5];//3
            multiplicand2[8] = (opt_reg) ? CNN_image_reg[4][5] : FP_ZERO;//4
        end
        else if(counting==25 || counting == 50 ) begin
            multiplicand2[1] = (opt_reg) ? CNN_image_reg[4][1] : FP_ZERO;//1
            multiplicand2[2] = CNN_image_reg[4][1];//2
            multiplicand2[3] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//3
            multiplicand2[4] = CNN_image_reg[5][1];//4
            multiplicand2[5] = CNN_image_reg[4][1];//1
            multiplicand2[6] = CNN_image_reg[4][2];//2
            multiplicand2[7] = CNN_image_reg[5][1];//3
            multiplicand2[8] = CNN_image_reg[5][2];//4
        end
        else if(counting==26 || counting == 51 ) begin
            multiplicand2[1] = CNN_image_reg[4][2];//1
            multiplicand2[2] = CNN_image_reg[4][3];//2
            multiplicand2[3] = CNN_image_reg[5][2];//3
            multiplicand2[4] = CNN_image_reg[5][3];//4
            multiplicand2[5] = CNN_image_reg[4][3];//1
            multiplicand2[6] = CNN_image_reg[4][4];//2
            multiplicand2[7] = CNN_image_reg[5][3];//3
            multiplicand2[8] = CNN_image_reg[5][4];//4
        end
        else if(counting==27 || counting == 52 ) begin
            multiplicand2[1] = CNN_image_reg[4][4];//1
            multiplicand2[2] = CNN_image_reg[4][5];//2
            multiplicand2[3] = CNN_image_reg[5][4];//3
            multiplicand2[4] = CNN_image_reg[5][5];//4
            multiplicand2[5] = CNN_image_reg[4][5];//1
            multiplicand2[6] = (opt_reg) ? CNN_image_reg[4][5] : FP_ZERO;//2
            multiplicand2[7] = CNN_image_reg[5][5];//3
            multiplicand2[8] = (opt_reg) ? CNN_image_reg[5][5] : FP_ZERO;//4
        end
        else if(counting==28 || counting == 53 ) begin
            multiplicand2[1] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//1
            multiplicand2[2] = CNN_image_reg[5][1];//2
            multiplicand2[3] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//3
            multiplicand2[4] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//4
            multiplicand2[5] = CNN_image_reg[5][1];//1
            multiplicand2[6] = CNN_image_reg[5][2];//2
            multiplicand2[7] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//3
            multiplicand2[8] = (opt_reg) ? CNN_image_reg[5][2] : FP_ZERO;//4
        end
        else if(counting==29 || counting == 54 ) begin
            multiplicand2[1] =CNN_image_reg[5][2];//1
            multiplicand2[2] =CNN_image_reg[5][3];//2
            multiplicand2[3] = (opt_reg) ? CNN_image_reg[5][2] : FP_ZERO;//3
            multiplicand2[4] = (opt_reg) ? CNN_image_reg[5][3] : FP_ZERO;//4
            multiplicand2[5] =CNN_image_reg[5][3];//1
            multiplicand2[6] =CNN_image_reg[5][4];//2
            multiplicand2[7] = (opt_reg) ? CNN_image_reg[5][3] : FP_ZERO;//3
            multiplicand2[8] = (opt_reg) ? CNN_image_reg[5][4] : FP_ZERO;//4
        end
        else if(counting==30  || counting == 55 ) begin
            multiplicand2[1] = CNN_image_reg[5][4];//1
            multiplicand2[2] = CNN_image_reg[5][5];//2
            multiplicand2[3] = (opt_reg) ? CNN_image_reg[5][4] : FP_ZERO;//3
            multiplicand2[4] = (opt_reg) ? CNN_image_reg[5][5] : FP_ZERO;//4
            multiplicand2[5] = CNN_image_reg[5][5];//1
            multiplicand2[6] = (opt_reg) ? CNN_image_reg[5][5] : FP_ZERO;//2
            multiplicand2[7] = (opt_reg) ? CNN_image_reg[5][5] : FP_ZERO;//3
            multiplicand2[8] = (opt_reg) ? CNN_image_reg[5][5] : FP_ZERO;//4
        end
        else if( counting == 70) begin
            multiplicand2[1] =CNN_image_reg[3][2];//1
            multiplicand2[2] =CNN_image_reg[3][3];//2
            multiplicand2[3] =CNN_image_reg[4][2];//3
            multiplicand2[4] =CNN_image_reg[4][3];//4
            multiplicand2[5] =CNN_image_reg[3][3];//1
            multiplicand2[6] =CNN_image_reg[3][4];//2
            multiplicand2[7] =CNN_image_reg[4][3];//3
            multiplicand2[8] =CNN_image_reg[4][4];//4
        end
        else if(counting==71 ) begin
            multiplicand2[1] =CNN_image_reg[3][4];//1
            multiplicand2[2] =CNN_image_reg[3][5];//2
            multiplicand2[3] =CNN_image_reg[4][4];//3
            multiplicand2[4] =CNN_image_reg[4][5];//4
            multiplicand2[5] =CNN_image_reg[3][5];//1
            multiplicand2[6] = (opt_reg) ? CNN_image_reg[3][5] : FP_ZERO;//2
            multiplicand2[7] =CNN_image_reg[4][5];//3
            multiplicand2[8] = (opt_reg) ? CNN_image_reg[4][5] : FP_ZERO;//4
        end
        else if(counting==72 ) begin
            multiplicand2[1] = (opt_reg) ? CNN_image_reg[4][1] : FP_ZERO;//1
            multiplicand2[2] = CNN_image_reg[4][1];//2
            multiplicand2[3] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//3
            multiplicand2[4] = CNN_image_reg[5][1];//4
            multiplicand2[5] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//1
            multiplicand2[6] = CNN_image_reg[5][1];//2
            multiplicand2[7] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//3
            multiplicand2[8] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//4
        end
        else if(counting==73 ) begin
            multiplicand2[1] = CNN_image_reg[4][1];//1
            multiplicand2[2] = CNN_image_reg[4][2];//2
            multiplicand2[3] = CNN_image_reg[5][1];//3
            multiplicand2[4] = CNN_image_reg[5][2];//4
            multiplicand2[5] = CNN_image_reg[5][1];//1
            multiplicand2[6] = CNN_image_reg[5][2];//2
            multiplicand2[7] = (opt_reg) ? CNN_image_reg[5][1] : FP_ZERO;//3
            multiplicand2[8] = (opt_reg) ? CNN_image_reg[5][2] : FP_ZERO;//4
        end
        else if(counting==74 ) begin
            multiplicand2[1] = CNN_image_reg[4][2];//1
            multiplicand2[2] = CNN_image_reg[4][3];//2
            multiplicand2[3] = CNN_image_reg[5][2];//3
            multiplicand2[4] = CNN_image_reg[5][3];//4
            multiplicand2[5] = CNN_image_reg[5][2];//1
            multiplicand2[6] = CNN_image_reg[5][3];//2
            multiplicand2[7] = (opt_reg) ? CNN_image_reg[5][2] : FP_ZERO;//3
            multiplicand2[8] = (opt_reg) ? CNN_image_reg[5][3] : FP_ZERO;//4
        end
        else if(counting==75 ) begin
            multiplicand2[1] = CNN_image_reg[4][3];//1
            multiplicand2[2] = CNN_image_reg[4][4];//2
            multiplicand2[3] = CNN_image_reg[5][3];//3
            multiplicand2[4] = CNN_image_reg[5][4];//4
            multiplicand2[5] = CNN_image_reg[5][3];//1
            multiplicand2[6] = CNN_image_reg[5][4];//2
            multiplicand2[7] = (opt_reg) ? CNN_image_reg[5][3] : FP_ZERO;//3
            multiplicand2[8] = (opt_reg) ? CNN_image_reg[5][4] : FP_ZERO;//4
        end
        else if(counting==76 ) begin
            multiplicand2[1] =CNN_image_reg[4][4];//1
            multiplicand2[2] =CNN_image_reg[4][5];//2
            multiplicand2[3] =CNN_image_reg[5][4];//3
            multiplicand2[4] =CNN_image_reg[5][5];//4
            multiplicand2[5] =CNN_image_reg[5][4];//1
            multiplicand2[6] =CNN_image_reg[5][5];//2
            multiplicand2[7] = (opt_reg) ? CNN_image_reg[5][4] : FP_ZERO;//3
            multiplicand2[8] = (opt_reg) ? CNN_image_reg[5][5] : FP_ZERO;//4
        end
        else if(counting==77 ) begin
            multiplicand2[1] = CNN_image_reg[4][5];//1
            multiplicand2[2] = (opt_reg) ? CNN_image_reg[4][5] : FP_ZERO;//2
            multiplicand2[3] = CNN_image_reg[5][5];//3
            multiplicand2[4] = (opt_reg) ? CNN_image_reg[5][5] : FP_ZERO;//4
            multiplicand2[5] = CNN_image_reg[5][5];//1
            multiplicand2[6] = (opt_reg) ? CNN_image_reg[5][5] : FP_ZERO;//2
            multiplicand2[7] = (opt_reg) ? CNN_image_reg[5][5] : FP_ZERO;//3
            multiplicand2[8] = (opt_reg) ? CNN_image_reg[5][5] : FP_ZERO;//4
        end
        
        else begin
            multiplicand2[1] = 0;
            multiplicand2[2] = 0;
            multiplicand2[3] = 0;
            multiplicand2[4] = 0;
            multiplicand2[5] = 0;
            multiplicand2[6] = 0;
            multiplicand2[7] = 0;
            multiplicand2[8] = 0;
        end
     
    
end
always@(*) begin
        if(13<=counting && counting <=30) begin
            multiplier1[1] = kernel_ch1_1_save_reg[1];
            multiplier1[2] = kernel_ch1_1_save_reg[2];
            multiplier1[3] = kernel_ch1_1_save_reg[3];
            multiplier1[4] = kernel_ch1_1_save_reg[4];
            multiplier1[5] = kernel_ch1_1_save_reg[1];
            multiplier1[6] = kernel_ch1_1_save_reg[2];
            multiplier1[7] = kernel_ch1_1_save_reg[3];
            multiplier1[8] = kernel_ch1_1_save_reg[4];
        end
        else if(38<=counting && counting <=55) begin
            multiplier1[1] = kernel_ch1_2_save_reg[1];
            multiplier1[2] = kernel_ch1_2_save_reg[2];
            multiplier1[3] = kernel_ch1_2_save_reg[3];
            multiplier1[4] = kernel_ch1_2_save_reg[4];
            multiplier1[5] = kernel_ch1_2_save_reg[1];
            multiplier1[6] = kernel_ch1_2_save_reg[2];
            multiplier1[7] = kernel_ch1_2_save_reg[3];
            multiplier1[8] = kernel_ch1_2_save_reg[4];
        end
        else if(60<=counting && counting <=77) begin
            multiplier1[1] = kernel_ch1_3_save_reg[1];
            multiplier1[2] = kernel_ch1_3_save_reg[2];
            multiplier1[3] = kernel_ch1_3_save_reg[3];
            multiplier1[4] = kernel_ch1_3_save_reg[4];
            multiplier1[5] = kernel_ch1_3_save_reg[1];
            multiplier1[6] = kernel_ch1_3_save_reg[2];
            multiplier1[7] = kernel_ch1_3_save_reg[3];
            multiplier1[8] = kernel_ch1_3_save_reg[4];
        end
        
        
        else begin
            multiplier1[1] = 0;
            multiplier1[2] = 0;
            multiplier1[3] = 0;
            multiplier1[4] = 0;
            multiplier1[5] = 0;
            multiplier1[6] = 0;
            multiplier1[7] = 0;
            multiplier1[8] = 0;
        end
end
always@(*) begin
    
        if(13<=counting && counting <=30) begin
            multiplier2[1] = kernel_ch2_1_save_reg[1];
            multiplier2[2] = kernel_ch2_1_save_reg[2];
            multiplier2[3] = kernel_ch2_1_save_reg[3];
            multiplier2[4] = kernel_ch2_1_save_reg[4];
            multiplier2[5] = kernel_ch2_1_save_reg[1];
            multiplier2[6] = kernel_ch2_1_save_reg[2];
            multiplier2[7] = kernel_ch2_1_save_reg[3];
            multiplier2[8] = kernel_ch2_1_save_reg[4];
        end
        else if(38<=counting && counting <=55) begin
            multiplier2[1] = kernel_ch2_2_save_reg[1];
            multiplier2[2] = kernel_ch2_2_save_reg[2];
            multiplier2[3] = kernel_ch2_2_save_reg[3];
            multiplier2[4] = kernel_ch2_2_save_reg[4];
            multiplier2[5] = kernel_ch2_2_save_reg[1];
            multiplier2[6] = kernel_ch2_2_save_reg[2];
            multiplier2[7] = kernel_ch2_2_save_reg[3];
            multiplier2[8] = kernel_ch2_2_save_reg[4];
        end
        else if(60<=counting && counting <=77) begin
            multiplier2[1] = kernel_ch2_3_save_reg[1];
            multiplier2[2] = kernel_ch2_3_save_reg[2];
            multiplier2[3] = kernel_ch2_3_save_reg[3];
            multiplier2[4] = kernel_ch2_3_save_reg[4];
            multiplier2[5] = kernel_ch2_3_save_reg[1];
            multiplier2[6] = kernel_ch2_3_save_reg[2];
            multiplier2[7] = kernel_ch2_3_save_reg[3];
            multiplier2[8] = kernel_ch2_3_save_reg[4];
        end
        else if(counting==82) begin
            multiplier2[1] = Weight_save3_reg[5];//-0.0625
            multiplier2[2] = Weight_save3_reg[6];//0.5
            multiplier2[3] = Weight_save1_reg[7];//-0.25
            multiplier2[4] = Weight_save1_reg[8];//0.5
            multiplier2[5] = Weight_save2_reg[7];//-0.5
            multiplier2[6] = Weight_save2_reg[8];//0.5
            multiplier2[7] = Weight_save3_reg[7];//0.125
            multiplier2[8] = Weight_save3_reg[8];//-0.25
        end
        else begin
            multiplier2[1] = 0;
            multiplier2[2] = 0;
            multiplier2[3] = 0;
            multiplier2[4] = 0;
            multiplier2[5] = 0;
            multiplier2[6] = 0;
            multiplier2[7] = 0;
            multiplier2[8] = 0;
        end
    
end
fp_MULT MULT_a11( .inst_a(multiplicand1[1]), .inst_b(multiplier1[1]), .z_inst(save_mult_temp1[1]) );
fp_MULT MULT_a12( .inst_a(multiplicand1[2]), .inst_b(multiplier1[2]), .z_inst(save_mult_temp1[2]) );
fp_MULT MULT_a13( .inst_a(multiplicand1[3]), .inst_b(multiplier1[3]), .z_inst(save_mult_temp1[3]) );
fp_MULT MULT_a14( .inst_a(multiplicand1[4]), .inst_b(multiplier1[4]), .z_inst(save_mult_temp1[4]) );
fp_MULT MULT_a15( .inst_a(multiplicand1[5]), .inst_b(multiplier1[5]), .z_inst(save_mult_temp1[5]) );
fp_MULT MULT_a16( .inst_a(multiplicand1[6]), .inst_b(multiplier1[6]), .z_inst(save_mult_temp1[6]) );
fp_MULT MULT_a17( .inst_a(multiplicand1[7]), .inst_b(multiplier1[7]), .z_inst(save_mult_temp1[7]) );
fp_MULT MULT_a18( .inst_a(multiplicand1[8]), .inst_b(multiplier1[8]), .z_inst(save_mult_temp1[8]) );

fp_MULT MULT_a21( .inst_a(multiplicand2[1]), .inst_b(multiplier2[1]), .z_inst(save_mult_temp2[1]) );
fp_MULT MULT_a22( .inst_a(multiplicand2[2]), .inst_b(multiplier2[2]), .z_inst(save_mult_temp2[2]) );
fp_MULT MULT_a23( .inst_a(multiplicand2[3]), .inst_b(multiplier2[3]), .z_inst(save_mult_temp2[3]) );
fp_MULT MULT_a24( .inst_a(multiplicand2[4]), .inst_b(multiplier2[4]), .z_inst(save_mult_temp2[4]) );
fp_MULT MULT_a25( .inst_a(multiplicand2[5]), .inst_b(multiplier2[5]), .z_inst(save_mult_temp2[5]) );
fp_MULT MULT_a26( .inst_a(multiplicand2[6]), .inst_b(multiplier2[6]), .z_inst(save_mult_temp2[6]) );
fp_MULT MULT_a27( .inst_a(multiplicand2[7]), .inst_b(multiplier2[7]), .z_inst(save_mult_temp2[7]) );
fp_MULT MULT_a28( .inst_a(multiplicand2[8]), .inst_b(multiplier2[8]), .z_inst(save_mult_temp2[8]) );

always@(posedge clk) begin
    for(i=1;i<=8;i=i+1) begin
        save_mult_temp1_reg[i] <= save_mult_temp1[i];
    end
end
always@(posedge clk) begin
    for(i=1;i<=8;i=i+1) begin
        save_mult_temp2_reg[i] <= save_mult_temp2[i];
    end
end
always@(*) begin
    if(14<=counting&&counting<=31) begin///////////////////////////////////////
        augmend1[1] = save_mult_temp1_reg[1];
        augmend1[2] = partial_sum1[1];
        augmend1[3] = partial_sum1[2];
        augmend1[4] = 0;
        augmend1[5] = save_mult_temp1_reg[5];
        augmend1[6] = partial_sum1[5];
        augmend1[7] = partial_sum1[6];
        augmend1[8] = 0;
    end
    else if(39<=counting && counting<=56) begin
        augmend1[1] = save_mult_temp1_reg[1];
        augmend1[2] = partial_sum1[1];
        augmend1[3] = partial_sum1[2];
        augmend1[4] = partial_sum1[3];
        augmend1[5] = save_mult_temp1_reg[5];
        augmend1[6] = partial_sum1[5];
        augmend1[7] = partial_sum1[6];
        augmend1[8] = partial_sum1[7];
    end
    else if(61<=counting && counting<=78) begin
        augmend1[1] = save_mult_temp1_reg[1];
        augmend1[2] = partial_sum1[1];
        augmend1[3] = partial_sum1[2];
        augmend1[4] = partial_sum1[3];
        augmend1[5] = save_mult_temp1_reg[5];
        augmend1[6] = partial_sum1[5];
        augmend1[7] = partial_sum1[6];
        augmend1[8] = partial_sum1[7];
    end
    else begin
        augmend1[1] = 0;
        augmend1[2] = 0;
        augmend1[3] = 0;
        augmend1[4] = 0;
        augmend1[5] = 0;
        augmend1[6] = 0;
        augmend1[7] = 0;
        augmend1[8] = 0;
    end
    
end
always@(*) begin
    if(14<=counting&&counting<=31) begin
        augmend2[1] = save_mult_temp2_reg[1];
        augmend2[2] = partial_sum2[1];
        augmend2[3] = partial_sum2[2];
        augmend2[4] = 0;
        augmend2[5] = save_mult_temp2_reg[5];
        augmend2[6] = partial_sum2[5];
        augmend2[7] = partial_sum2[6];
        augmend2[8] = 0;
    end
    else if(39<=counting && counting<=56) begin
        augmend2[1] = save_mult_temp2_reg[1];
        augmend2[2] = partial_sum2[1];
        augmend2[3] = partial_sum2[2];
        augmend2[4] = partial_sum2[3];
        augmend2[5] = save_mult_temp2_reg[5];
        augmend2[6] = partial_sum2[5];
        augmend2[7] = partial_sum2[6];
        augmend2[8] = partial_sum2[7];
    end
    else if(61<=counting && counting<=78) begin
        augmend2[1] = save_mult_temp2_reg[1];
        augmend2[2] = partial_sum2[1];
        augmend2[3] = partial_sum2[2];
        augmend2[4] = partial_sum2[3];
        augmend2[5] = save_mult_temp2_reg[5];
        augmend2[6] = partial_sum2[5];
        augmend2[7] = partial_sum2[6];
        augmend2[8] = partial_sum2[7];
    end
    else begin
        augmend2[1] = 0;
        augmend2[2] = 0;
        augmend2[3] = 0;
        augmend2[4] = 0;
        augmend2[5] = 0;
        augmend2[6] = 0;
        augmend2[7] = 0;
        augmend2[8] = 0;
    end
    
end
always@(*) begin
    if(14<=counting&&counting<=31) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = 0;
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = 0;
    end 
    else if(counting==39||counting==61) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[1][1];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[1][2];
    end 
    else if(counting==40||counting==62) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[1][3];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[1][4];
    end 
    else if(counting==41||counting==63) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[1][5];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[1][6];
    end 
    else if(counting==42||counting==64) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[2][1];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[2][2];
    end 
    else if(counting==43||counting==65) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[2][3];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[2][4];
    end 
    else if(counting==44||counting==66) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[2][5];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[2][6];
    end 
    else if(counting==45||counting==67) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[3][1];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[3][2];
    end 
    else if(counting==46||counting==68) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[3][3];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[3][4];
    end 
    else if(counting==47||counting==69) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[3][5];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[3][6];
    end 
    else if(counting==48||counting==70) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[4][1];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[4][2];
    end 
    else if(counting==49||counting==71) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[4][3];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[4][4];
    end 
    else if(counting==50||counting==72) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[4][5];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[4][6];
    end 
    else if(counting==51) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[5][1];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[5][2];
    end 
    else if(counting==52) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[5][3];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[5][4];
    end 
    else if(counting==53) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[5][5];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[5][6];
    end 
    else if(counting==54) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[6][1];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[6][2];
    end 
    else if(counting==55) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[6][3];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[6][4];
    end 
    else if(counting==56) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[6][5];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[6][6];
    end 
    else if(counting==73) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[5][1];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[6][1];
    end 
    else if(counting==74) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[5][2];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[6][2];
    end 
    else if(counting==75) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[5][3];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[6][3];
    end 
    else if(counting==76) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[5][4];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[6][4];
    end 
    else if(counting==77) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[5][5];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[6][5];
    end 
    else if(counting==78) begin
        addend1[1] = save_mult_temp1_reg[2];
        addend1[2] = save_mult_temp1_reg[3];
        addend1[3] = save_mult_temp1_reg[4];
        addend1[4] = feature_map1[5][6];
        addend1[5] = save_mult_temp1_reg[6];
        addend1[6] = save_mult_temp1_reg[7];
        addend1[7] = save_mult_temp1_reg[8];
        addend1[8] = feature_map1[6][6];
    end 

    else begin
        addend1[1] = 0;
        addend1[2] = 0;
        addend1[3] = 0;
        addend1[4] = 0;
        addend1[5] = 0;
        addend1[6] = 0;
        addend1[7] = 0;
        addend1[8] = 0;
    end 
end

always@(*) begin
    if(14<=counting&&counting<=31) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = 0;
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = 0;
    end 
    else if(counting==39||counting==61) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[1][1];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[1][2];
    end 
    else if(counting==40||counting==62) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[1][3];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[1][4];
    end 
    else if(counting==41||counting==63) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[1][5];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[1][6];
    end 
    else if(counting==42||counting==64) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[2][1];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[2][2];
    end 
    else if(counting==43||counting==65) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[2][3];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[2][4];
    end 
    else if(counting==44||counting==66) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[2][5];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[2][6];
    end 
    else if(counting==45||counting==67) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[3][1];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[3][2];
    end 
    else if(counting==46||counting==68) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[3][3];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[3][4];
    end 
    else if(counting==47||counting==69) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[3][5];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[3][6];
    end 
    else if(counting==48||counting==70) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[4][1];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[4][2];
    end 
    else if(counting==49||counting==71) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[4][3];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[4][4];
    end 
    else if(counting==50||counting==72) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[4][5];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[4][6];
    end 
    else if(counting==51) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[5][1];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[5][2];
    end 
    else if(counting==52) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[5][3];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[5][4];
    end 
    else if(counting==53) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[5][5];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[5][6];
    end 
    else if(counting==54) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[6][1];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[6][2];
    end 
    else if(counting==55) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[6][3];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[6][4];
    end 
    else if(counting==56) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[6][5];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[6][6];
    end 
    else if(counting==73) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[5][1];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[6][1];
    end 
    else if(counting==74) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[5][2];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[6][2];
    end 
    else if(counting==75) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[5][3];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[6][3];
    end 
    else if(counting==76) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[5][4];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[6][4];
    end 
    else if(counting==77) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[5][5];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[6][5];
    end 
    else if(counting==78) begin
        addend2[1] = save_mult_temp2_reg[2];
        addend2[2] = save_mult_temp2_reg[3];
        addend2[3] = save_mult_temp2_reg[4];
        addend2[4] = feature_map2[5][6];
        addend2[5] = save_mult_temp2_reg[6];
        addend2[6] = save_mult_temp2_reg[7];
        addend2[7] = save_mult_temp2_reg[8];
        addend2[8] = feature_map2[6][6];
    end 

    else begin
        addend2[1] = 0;
        addend2[2] = 0;
        addend2[3] = 0;
        addend2[4] = 0;
        addend2[5] = 0;
        addend2[6] = 0;
        addend2[7] = 0;
        addend2[8] = 0;
    end 
end


DW_fp_add_inst adder11(.inst_a(augmend1[1]),.inst_b(addend1[1]),.z_inst(partial_sum1[1]) );
DW_fp_add_inst adder12(.inst_a(augmend1[2]),.inst_b(addend1[2]),.z_inst(partial_sum1[2]) );
DW_fp_add_inst adder13(.inst_a(augmend1[3]),.inst_b(addend1[3]),.z_inst(partial_sum1[3]) );
DW_fp_add_inst adder14(.inst_a(augmend1[4]),.inst_b(addend1[4]),.z_inst(partial_sum1[4]) );
DW_fp_add_inst adder15(.inst_a(augmend1[5]),.inst_b(addend1[5]),.z_inst(partial_sum1[5]) );
DW_fp_add_inst adder16(.inst_a(augmend1[6]),.inst_b(addend1[6]),.z_inst(partial_sum1[6]) );
DW_fp_add_inst adder17(.inst_a(augmend1[7]),.inst_b(addend1[7]),.z_inst(partial_sum1[7]) );
DW_fp_add_inst adder18(.inst_a(augmend1[8]),.inst_b(addend1[8]),.z_inst(partial_sum1[8]) );

DW_fp_add_inst adder21(.inst_a(augmend2[1]),.inst_b(addend2[1]),.z_inst(partial_sum2[1]) );
DW_fp_add_inst adder22(.inst_a(augmend2[2]),.inst_b(addend2[2]),.z_inst(partial_sum2[2]) );
DW_fp_add_inst adder23(.inst_a(augmend2[3]),.inst_b(addend2[3]),.z_inst(partial_sum2[3]) );
DW_fp_add_inst adder24(.inst_a(augmend2[4]),.inst_b(addend2[4]),.z_inst(partial_sum2[4]) );
DW_fp_add_inst adder25(.inst_a(augmend2[5]),.inst_b(addend2[5]),.z_inst(partial_sum2[5]) );
DW_fp_add_inst adder26(.inst_a(augmend2[6]),.inst_b(addend2[6]),.z_inst(partial_sum2[6]) );
DW_fp_add_inst adder27(.inst_a(augmend2[7]),.inst_b(addend2[7]),.z_inst(partial_sum2[7]) );
DW_fp_add_inst adder28(.inst_a(augmend2[8]),.inst_b(addend2[8]),.z_inst(partial_sum2[8]) );

always@(posedge clk) begin
    for(i=1;i<=8;i=i+1) begin
        partial_sum1_reg[i] <= partial_sum1[i];
    end
end
always@(posedge clk) begin
    for(i=1;i<=8;i=i+1) begin
        partial_sum2_reg[i] <= partial_sum2[i];
    end
end

//maybe feature map not used
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=1;i<=6;i=i+1) begin
           for(j=1;j<=6;j=j+1) begin
                feature_map1[i][j] <=0;
            end 
        end
    end
    else if(counting==1) begin
        for(i=1;i<=6;i=i+1) begin
           for(j=1;j<=6;j=j+1) begin
                feature_map1[i][j] <=0;
            end 
        end
    end
    else if(counting==14) begin
        feature_map1[1][1] <= partial_sum1[3];
        feature_map1[1][2] <= partial_sum1[7];
    end
    else if(counting==15) begin
        feature_map1[1][3] <= partial_sum1[3];
        feature_map1[1][4] <= partial_sum1[7];
    end
    else if(counting==16) begin
        feature_map1[1][5] <= partial_sum1[3];
        feature_map1[1][6] <= partial_sum1[7];
    end
    else if(counting==17) begin
        feature_map1[2][1] <= partial_sum1[3];
        feature_map1[2][2] <= partial_sum1[7];
    end
    else if(counting==18) begin
        feature_map1[2][3] <= partial_sum1[3];
        feature_map1[2][4] <= partial_sum1[7];
    end
    else if(counting==19) begin
        feature_map1[2][5] <= partial_sum1[3];
        feature_map1[2][6] <= partial_sum1[7];
    end
    else if(counting==20) begin
        feature_map1[3][1] <= partial_sum1[3];
        feature_map1[3][2] <= partial_sum1[7];
    end
    else if(counting==21) begin
        feature_map1[3][3] <= partial_sum1[3];
        feature_map1[3][4] <= partial_sum1[7];
    end
    else if(counting==22) begin
        feature_map1[3][5] <= partial_sum1[3];
        feature_map1[3][6] <= partial_sum1[7];
    end
    else if(counting==23) begin
        feature_map1[4][1] <= partial_sum1[3];
        feature_map1[4][2] <= partial_sum1[7];
    end
    else if(counting==24) begin
        feature_map1[4][3] <= partial_sum1[3];
        feature_map1[4][4] <= partial_sum1[7];
    end
    else if(counting==25) begin
        feature_map1[4][5] <= partial_sum1[3];
        feature_map1[4][6] <= partial_sum1[7];
    end
    else if(counting==26) begin
        feature_map1[5][1] <= partial_sum1[3];
        feature_map1[5][2] <= partial_sum1[7];
    end
    else if(counting==27) begin
        feature_map1[5][3] <= partial_sum1[3];
        feature_map1[5][4] <= partial_sum1[7];
    end
    else if(counting==28) begin
        feature_map1[5][5] <= partial_sum1[3];
        feature_map1[5][6] <= partial_sum1[7];
    end
    else if(counting==29) begin
        feature_map1[6][1] <= partial_sum1[3];
        feature_map1[6][2] <= partial_sum1[7];
    end
    else if(counting==30) begin
        feature_map1[6][3] <= partial_sum1[3];
        feature_map1[6][4] <= partial_sum1[7];
    end
    else if(counting==31) begin
        feature_map1[6][5] <= partial_sum1[3];
        feature_map1[6][6] <= partial_sum1[7];
    end
    else if(counting==39||counting==61) begin
        feature_map1[1][1] <= partial_sum1[4];
        feature_map1[1][2] <= partial_sum1[8];
    end
    else if(counting==40||counting==62) begin
        feature_map1[1][3] <= partial_sum1[4];
        feature_map1[1][4] <= partial_sum1[8];
    end
    else if(counting==41||counting==63) begin
        feature_map1[1][5] <= partial_sum1[4];
        feature_map1[1][6] <= partial_sum1[8];
    end
    else if(counting==42||counting==64) begin
        feature_map1[2][1] <= partial_sum1[4];
        feature_map1[2][2] <= partial_sum1[8];
    end
    else if(counting==43||counting==65) begin
        feature_map1[2][3] <= partial_sum1[4];
        feature_map1[2][4] <= partial_sum1[8];
    end
    else if(counting==44||counting==66) begin
        feature_map1[2][5] <= partial_sum1[4];
        feature_map1[2][6] <= partial_sum1[8];
    end
    else if(counting==45||counting==67) begin
        feature_map1[3][1] <= partial_sum1[4];
        feature_map1[3][2] <= partial_sum1[8];
    end
    else if(counting==46||counting==68) begin
        feature_map1[3][3] <= partial_sum1[4];
        feature_map1[3][4] <= partial_sum1[8];
    end
    else if(counting==47||counting==69) begin
        feature_map1[3][5] <= partial_sum1[4];
        feature_map1[3][6] <= partial_sum1[8];
    end
    else if(counting==48||counting==70) begin
        feature_map1[4][1] <= partial_sum1[4];
        feature_map1[4][2] <= partial_sum1[8];
    end
    else if(counting==49||counting==71) begin
        feature_map1[4][3] <= partial_sum1[4];
        feature_map1[4][4] <= partial_sum1[8];
    end
    else if(counting==50||counting==72) begin
        feature_map1[4][5] <= partial_sum1[4];
        feature_map1[4][6] <= partial_sum1[8];
    end
    else if(counting==51) begin
        feature_map1[5][1] <= partial_sum1[4];
        feature_map1[5][2] <= partial_sum1[8];
    end
    else if(counting==52) begin
        feature_map1[5][3] <= partial_sum1[4];
        feature_map1[5][4] <= partial_sum1[8];
    end
    else if(counting==53) begin
        feature_map1[5][5] <= partial_sum1[4];
        feature_map1[5][6] <= partial_sum1[8];
    end
    else if(counting==54) begin
        feature_map1[6][1] <= partial_sum1[4];
        feature_map1[6][2] <= partial_sum1[8];
    end
    else if(counting==55) begin
        feature_map1[6][3] <= partial_sum1[4];
        feature_map1[6][4] <= partial_sum1[8];
    end
    else if(counting==56) begin
        feature_map1[6][5] <= partial_sum1[4];
        feature_map1[6][6] <= partial_sum1[8];
    end
    else if(counting==73) begin
        feature_map1[5][1] <= partial_sum1[4];
        feature_map1[6][1] <= partial_sum1[8];
    end
    else if(counting==74) begin
        feature_map1[5][2] <= partial_sum1[4];
        feature_map1[6][2] <= partial_sum1[8];
    end
    else if(counting==75) begin
        feature_map1[5][3] <= partial_sum1[4];
        feature_map1[6][3] <= partial_sum1[8];
    end
    else if(counting==76) begin
        feature_map1[5][4] <= partial_sum1[4];
        feature_map1[6][4] <= partial_sum1[8];
    end
    else if(counting==77) begin
        feature_map1[5][5] <= partial_sum1[4];
        feature_map1[6][5] <= partial_sum1[8];
    end
    else if(counting==78) begin
        feature_map1[5][6] <= partial_sum1[4];
        feature_map1[6][6] <= partial_sum1[8];
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=1;i<=6;i=i+1) begin
           for(j=1;j<=6;j=j+1) begin
                feature_map2[i][j] <=0;
            end 
        end
    end
    else if(counting==1) begin
        for(i=1;i<=6;i=i+1) begin
           for(j=1;j<=6;j=j+1) begin
                feature_map2[i][j] <=0;
            end 
        end
    end
    else if(counting==14) begin
        feature_map2[1][1] <= partial_sum2[3];
        feature_map2[1][2] <= partial_sum2[7];
    end
    else if(counting==15) begin
        feature_map2[1][3] <= partial_sum2[3];
        feature_map2[1][4] <= partial_sum2[7];
    end
    else if(counting==16) begin
        feature_map2[1][5] <= partial_sum2[3];
        feature_map2[1][6] <= partial_sum2[7];
    end
    else if(counting==17) begin
        feature_map2[2][1] <= partial_sum2[3];
        feature_map2[2][2] <= partial_sum2[7];
    end
    else if(counting==18) begin
        feature_map2[2][3] <= partial_sum2[3];
        feature_map2[2][4] <= partial_sum2[7];
    end
    else if(counting==19) begin
        feature_map2[2][5] <= partial_sum2[3];
        feature_map2[2][6] <= partial_sum2[7];
    end
    else if(counting==20) begin
        feature_map2[3][1] <= partial_sum2[3];
        feature_map2[3][2] <= partial_sum2[7];
    end
    else if(counting==21) begin
        feature_map2[3][3] <= partial_sum2[3];
        feature_map2[3][4] <= partial_sum2[7];
    end
    else if(counting==22) begin
        feature_map2[3][5] <= partial_sum2[3];
        feature_map2[3][6] <= partial_sum2[7];
    end
    else if(counting==23) begin
        feature_map2[4][1] <= partial_sum2[3];
        feature_map2[4][2] <= partial_sum2[7];
    end
    else if(counting==24) begin
        feature_map2[4][3] <= partial_sum2[3];
        feature_map2[4][4] <= partial_sum2[7];
    end
    else if(counting==25) begin
        feature_map2[4][5] <= partial_sum2[3];
        feature_map2[4][6] <= partial_sum2[7];
    end
    else if(counting==26) begin
        feature_map2[5][1] <= partial_sum2[3];
        feature_map2[5][2] <= partial_sum2[7];
    end
    else if(counting==27) begin
        feature_map2[5][3] <= partial_sum2[3];
        feature_map2[5][4] <= partial_sum2[7];
    end
    else if(counting==28) begin
        feature_map2[5][5] <= partial_sum2[3];
        feature_map2[5][6] <= partial_sum2[7];
    end
    else if(counting==29) begin
        feature_map2[6][1] <= partial_sum2[3];
        feature_map2[6][2] <= partial_sum2[7];
    end
    else if(counting==30) begin
        feature_map2[6][3] <= partial_sum2[3];
        feature_map2[6][4] <= partial_sum2[7];
    end
    else if(counting==31) begin
        feature_map2[6][5] <= partial_sum2[3];
        feature_map2[6][6] <= partial_sum2[7];
    end
    else if(counting==39||counting==61) begin
        feature_map2[1][1] <= partial_sum2[4];
        feature_map2[1][2] <= partial_sum2[8];
    end
    else if(counting==40||counting==62) begin
        feature_map2[1][3] <= partial_sum2[4];
        feature_map2[1][4] <= partial_sum2[8];
    end
    else if(counting==41||counting==63) begin
        feature_map2[1][5] <= partial_sum2[4];
        feature_map2[1][6] <= partial_sum2[8];
    end
    else if(counting==42||counting==64) begin
        feature_map2[2][1] <= partial_sum2[4];
        feature_map2[2][2] <= partial_sum2[8];
    end
    else if(counting==43||counting==65) begin
        feature_map2[2][3] <= partial_sum2[4];
        feature_map2[2][4] <= partial_sum2[8];
    end
    else if(counting==44||counting==66) begin
        feature_map2[2][5] <= partial_sum2[4];
        feature_map2[2][6] <= partial_sum2[8];
    end
    else if(counting==45||counting==67) begin
        feature_map2[3][1] <= partial_sum2[4];
        feature_map2[3][2] <= partial_sum2[8];//
    end
    else if(counting==46||counting==68) begin
        feature_map2[3][3] <= partial_sum2[4];
        feature_map2[3][4] <= partial_sum2[8];
    end
    else if(counting==47||counting==69) begin
        feature_map2[3][5] <= partial_sum2[4];
        feature_map2[3][6] <= partial_sum2[8];
    end
    else if(counting==48||counting==70) begin
        feature_map2[4][1] <= partial_sum2[4];
        feature_map2[4][2] <= partial_sum2[8];//
    end
    else if(counting==49||counting==71) begin
        feature_map2[4][3] <= partial_sum2[4];
        feature_map2[4][4] <= partial_sum2[8];
    end
    else if(counting==50||counting==72) begin
        feature_map2[4][5] <= partial_sum2[4];
        feature_map2[4][6] <= partial_sum2[8];
    end
    else if(counting==51) begin
        feature_map2[5][1] <= partial_sum2[4];
        feature_map2[5][2] <= partial_sum2[8];
    end
    else if(counting==52) begin
        feature_map2[5][3] <= partial_sum2[4];
        feature_map2[5][4] <= partial_sum2[8];
    end
    else if(counting==53) begin
        feature_map2[5][5] <= partial_sum2[4];
        feature_map2[5][6] <= partial_sum2[8];
    end
    else if(counting==54) begin
        feature_map2[6][1] <= partial_sum2[4];
        feature_map2[6][2] <= partial_sum2[8];
    end
    else if(counting==55) begin
        feature_map2[6][3] <= partial_sum2[4];
        feature_map2[6][4] <= partial_sum2[8];
    end
    else if(counting==56) begin
        feature_map2[6][5] <= partial_sum2[4];
        feature_map2[6][6] <= partial_sum2[8];
    end
    else if(counting==73) begin
        feature_map2[5][1] <= partial_sum2[4];
        feature_map2[6][1] <= partial_sum2[8];
    end
    else if(counting==74) begin
        feature_map2[5][2] <= partial_sum2[4];
        feature_map2[6][2] <= partial_sum2[8];
    end
    else if(counting==75) begin
        feature_map2[5][3] <= partial_sum2[4];
        feature_map2[6][3] <= partial_sum2[8];
    end
    else if(counting==76) begin
        feature_map2[5][4] <= partial_sum2[4];
        feature_map2[6][4] <= partial_sum2[8];
    end
    else if(counting==77) begin
        feature_map2[5][5] <= partial_sum2[4];
        feature_map2[6][5] <= partial_sum2[8];
    end
    else if(counting==78) begin
        feature_map2[5][6] <= partial_sum2[4];
        feature_map2[6][6] <= partial_sum2[8];
    end
end
//---------------------------------------------------------------------
// MAX-POOLING
//---------------------------------------------------------------------
reg [31:0] comparea1[1:4];
reg [31:0] comparea2[1:4];
wire [31:0] compareresult_1[1:8];
reg [31:0] compareb1[1:5];
reg [31:0] compareb2[1:5];
wire [31:0] compareresult_2[1:8];
reg [31:0] aftermaxpool[1:8];
reg [31:0]n_aftermaxpool[1:8];


always@(*) begin
    comparea1[1] =0;           comparea2[1] =0;
    comparea1[2] =0;           comparea2[2] =0;
    comparea1[3] =0;           comparea2[3] =0;
    comparea1[4] =0;           comparea2[4] =0;
    compareb1[1] =0;           compareb2[1] =0;
    compareb1[2] =0;           compareb2[2] =0;
    compareb1[3] =0;           compareb2[3] =0;
    compareb1[4] =0;           compareb2[4] =0;
    compareb1[5] =0;           compareb2[5] =0;

    if(counting==80) begin
        comparea1[1] = feature_map1[1][1];   comparea2[1] = feature_map2[1][1];
        comparea1[2] = feature_map1[1][2];   comparea2[2] = feature_map2[1][2];
        comparea1[3] = feature_map1[1][3];   comparea2[3] = feature_map2[1][3];
        comparea1[4] = feature_map1[2][1];   comparea2[4] = feature_map2[2][1];

        compareb1[1] = feature_map1[2][2];   compareb2[1] = feature_map2[2][2];
        compareb1[2] = feature_map1[2][3];   compareb2[2] = feature_map2[2][3];
        compareb1[3] = feature_map1[3][1];   compareb2[3] = feature_map2[3][1];
        compareb1[4] = feature_map1[3][2];   compareb2[4] = feature_map2[3][2];
        compareb1[5] = feature_map1[3][3];   compareb2[5] = feature_map2[3][3];
    end
    else if(counting==81)begin
        comparea1[1] = feature_map1[1][4];   comparea2[1] = feature_map2[1][4];
        comparea1[2] = feature_map1[1][5];   comparea2[2] = feature_map2[1][5];
        comparea1[3] = feature_map1[1][6];   comparea2[3] = feature_map2[1][6];
        comparea1[4] = feature_map1[2][4];   comparea2[4] = feature_map2[2][4];
        compareb1[1] = feature_map1[2][5];   compareb2[1] = feature_map2[2][5];
        compareb1[2] = feature_map1[2][6];   compareb2[2] = feature_map2[2][6];
        compareb1[3] = feature_map1[3][4];   compareb2[3] = feature_map2[3][4];
        compareb1[4] = feature_map1[3][5];   compareb2[4] = feature_map2[3][5];
        compareb1[5] = feature_map1[3][6];   compareb2[5] = feature_map2[3][6];
    end
    else if(counting==82)begin
        comparea1[1] = feature_map1[4][1];   comparea2[1] = feature_map2[4][1];
        comparea1[2] = feature_map1[4][2];   comparea2[2] = feature_map2[4][2];
        comparea1[3] = feature_map1[4][3];   comparea2[3] = feature_map2[4][3];
        comparea1[4] = feature_map1[5][1];   comparea2[4] = feature_map2[5][1];
        compareb1[1] = feature_map1[5][2];   compareb2[1] = feature_map2[5][2];
        compareb1[2] = feature_map1[5][3];   compareb2[2] = feature_map2[5][3];
        compareb1[3] = feature_map1[6][1];   compareb2[3] = feature_map2[6][1];
        compareb1[4] = feature_map1[6][2];   compareb2[4] = feature_map2[6][2];
        compareb1[5] = feature_map1[6][3];   compareb2[5] = feature_map2[6][3];
    end
    else if(counting==83)begin
        comparea1[1] = feature_map1[4][4];   comparea2[1] = feature_map2[4][4];
        comparea1[2] = feature_map1[4][5];   comparea2[2] = feature_map2[4][5];
        comparea1[3] = feature_map1[4][6];   comparea2[3] = feature_map2[4][6];
        comparea1[4] = feature_map1[5][4];   comparea2[4] = feature_map2[5][4];
        compareb1[1] = feature_map1[5][5];   compareb2[1] = feature_map2[5][5];
        compareb1[2] = feature_map1[5][6];   compareb2[2] = feature_map2[5][6];
        compareb1[3] = feature_map1[6][4];   compareb2[3] = feature_map2[6][4];
        compareb1[4] = feature_map1[6][5];   compareb2[4] = feature_map2[6][5];
        compareb1[5] = feature_map1[6][6];   compareb2[5] = feature_map2[6][6];
    end
    end
always@(*) begin
    for(i=1;i<=8;i=i+1) begin
       n_aftermaxpool[i] = aftermaxpool[i]; 
    end
    if(counting==80) begin
        n_aftermaxpool[1] = compareresult_1[8];  
        n_aftermaxpool[5] = compareresult_2[8];
    end
    else if(counting==81) begin
        n_aftermaxpool[2] = compareresult_1[8];  
        n_aftermaxpool[6] = compareresult_2[8];
    end
    else if(counting==82) begin
        n_aftermaxpool[3] = compareresult_1[8];  
        n_aftermaxpool[7] = compareresult_2[8];
    end
    else if(counting==83) begin
        n_aftermaxpool[4] = compareresult_1[8];  
        n_aftermaxpool[8] = compareresult_2[8];
    end
end
always@(posedge clk) begin
    for(i=1;i<=8;i=i+1) begin
       aftermaxpool[i] <= n_aftermaxpool[i]; 
    end
end



DW_fp_cmp_inst cmp1(.inst_a(comparea1[1]), .inst_b(compareb1[1]), .inst_zctr(1'b0),.z0_inst(), .z1_inst(compareresult_1[1]));
DW_fp_cmp_inst cmp2(.inst_a(comparea1[2]), .inst_b(compareb1[2]), .inst_zctr(1'b0),.z0_inst(), .z1_inst(compareresult_1[2]));
DW_fp_cmp_inst cmp3(.inst_a(comparea1[3]), .inst_b(compareb1[3]), .inst_zctr(1'b0),.z0_inst(), .z1_inst(compareresult_1[3]));
DW_fp_cmp_inst cmp4(.inst_a(comparea1[4]), .inst_b(compareb1[4]), .inst_zctr(1'b0),.z0_inst(), .z1_inst(compareresult_1[4]));
DW_fp_cmp_inst cmp5(.inst_a(compareresult_1[1]), .inst_b(compareresult_1[2]), .inst_zctr(1'b0),.z0_inst(), .z1_inst(compareresult_1[5]));
DW_fp_cmp_inst cmp6(.inst_a(compareresult_1[3]), .inst_b(compareresult_1[4]), .inst_zctr(1'b0),.z0_inst(), .z1_inst(compareresult_1[6]));
DW_fp_cmp_inst cmp7(.inst_a(compareresult_1[5]), .inst_b(compareresult_1[6]), .inst_zctr(1'b0),.z0_inst(), .z1_inst(compareresult_1[7]));
DW_fp_cmp_inst cmp8(.inst_a(compareresult_1[7]), .inst_b(compareb1[5]), .inst_zctr(1'b0),.z0_inst(), .z1_inst(compareresult_1[8]));

DW_fp_cmp_inst cmp9(.inst_a(comparea2[1]), .inst_b(compareb2[1]), .inst_zctr(1'b0),.z0_inst(), .z1_inst(compareresult_2[1]));
DW_fp_cmp_inst cmp10(.inst_a(comparea2[2]), .inst_b(compareb2[2]), .inst_zctr(1'b0),.z0_inst(), .z1_inst(compareresult_2[2]));
DW_fp_cmp_inst cmp11(.inst_a(comparea2[3]), .inst_b(compareb2[3]), .inst_zctr(1'b0),.z0_inst(), .z1_inst(compareresult_2[3]));
DW_fp_cmp_inst cmp12(.inst_a(comparea2[4]), .inst_b(compareb2[4]), .inst_zctr(1'b0),.z0_inst(), .z1_inst(compareresult_2[4]));
DW_fp_cmp_inst cmp13(.inst_a(compareresult_2[1]), .inst_b(compareresult_2[2]), .inst_zctr(1'b0),.z0_inst(), .z1_inst(compareresult_2[5]));
DW_fp_cmp_inst cmp14(.inst_a(compareresult_2[3]), .inst_b(compareresult_2[4]), .inst_zctr(1'b0),.z0_inst(), .z1_inst(compareresult_2[6]));
DW_fp_cmp_inst cmp15(.inst_a(compareresult_2[5]), .inst_b(compareresult_2[6]), .inst_zctr(1'b0),.z0_inst(), .z1_inst(compareresult_2[7]));
DW_fp_cmp_inst cmp16(.inst_a(compareresult_2[7]), .inst_b(compareb2[5]), .inst_zctr(1'b0),.z0_inst(), .z1_inst(compareresult_2[8]));



//---------------------------------------------------------------------
// ACTIVATION_FUNCTION
//---------------------------------------------------------------------
reg [31:0] afteractivation[1:8];
reg [31:0]n_afteractivation[1:8];
reg [31:0]keep_exp[1:8];
reg [31:0] inputa1,inputa2,inputb1,inputb2;
reg [31:0] upper,bottom;
reg [31:0] upper_reg,bottom_reg;

always@(*) begin
    if(counting==84) begin
        exp_time1 = (opt_reg)?{aftermaxpool[1][31],aftermaxpool[1][30:23]+8'b1,aftermaxpool[1][22:0]}:aftermaxpool[1];
    end
    else if(counting==85) begin
        exp_time1 = (opt_reg)?{aftermaxpool[2][31],aftermaxpool[2][30:23]+8'b1,aftermaxpool[2][22:0]}:aftermaxpool[2];
    end
    else if(counting==86) begin
        exp_time1 = (opt_reg)?{aftermaxpool[3][31],aftermaxpool[3][30:23]+8'b1,aftermaxpool[3][22:0]}:aftermaxpool[3];
    end
    else if(counting==87) begin
        exp_time1 = (opt_reg)?{aftermaxpool[4][31],aftermaxpool[4][30:23]+8'b1,aftermaxpool[4][22:0]}:aftermaxpool[4];
    end
    else if(counting==88) begin
        exp_time1 = (opt_reg)?{aftermaxpool[5][31],aftermaxpool[5][30:23]+8'b1,aftermaxpool[5][22:0]}:aftermaxpool[5];
    end
    else if(counting==89) begin
        exp_time1 = (opt_reg)?{aftermaxpool[6][31],aftermaxpool[6][30:23]+8'b1,aftermaxpool[6][22:0]}:aftermaxpool[6];
    end
    else if(counting==90) begin
        exp_time1 = (opt_reg)?{aftermaxpool[7][31],aftermaxpool[7][30:23]+8'b1,aftermaxpool[7][22:0]}:aftermaxpool[7];
    end
    else if(counting==91) begin
        exp_time1 = (opt_reg)?{aftermaxpool[8][31],aftermaxpool[8][30:23]+8'b1,aftermaxpool[8][22:0]}:aftermaxpool[8];
    end
    else if(counting==102) begin////////////////////
        exp_time1 = after_ful[1];
    end
    else if(counting==103) begin///////////////////////
        exp_time1 = after_ful[2];
    end
    else if(counting==104) begin/////////////////
        exp_time1 = after_ful[3];
    end
    else begin
        exp_time1 = FP_min;
    end
end
fp_exp exp1( .inst_a(exp_time1), .z_inst(after_exp1));

always@(posedge clk) begin
    after_exp1_reg <= after_exp1;
end

always@(*) begin
    if(counting==85) begin
        inputa1 = after_exp1_reg;
        inputa2 = (opt_reg)?FP_ONE:FP_ZERO;
    end
    else if(counting==86) begin
        inputa1 = after_exp1_reg;
        inputa2 = (opt_reg)?FP_ONE:FP_ZERO;
    end
    else if(counting==87) begin
        inputa1 = after_exp1_reg;
        inputa2 = (opt_reg)?FP_ONE:FP_ZERO;
    end
    else if(counting==88) begin
        inputa1 = after_exp1_reg;
        inputa2 = (opt_reg)?FP_ONE:FP_ZERO;
    end
    else if(counting==89) begin
        inputa1 = after_exp1_reg;
        inputa2 = (opt_reg)?FP_ONE:FP_ZERO;
    end
    else if(counting==90) begin
        inputa1 = after_exp1_reg;
        inputa2 = (opt_reg)?FP_ONE:FP_ZERO;
    end
    else if(counting==91) begin
        inputa1 = after_exp1_reg;
        inputa2 = (opt_reg)?FP_ONE:FP_ZERO;
    end
    else if(counting==92) begin
        inputa1 = after_exp1_reg;
        inputa2 = (opt_reg)?FP_ONE:FP_ZERO;
    end
    else begin
        inputa1 =FP_min;
        inputa2 =FP_min;
    end
end

DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
        Uadd1 ( .a(inputa1), .b(inputa2), .rnd(3'b0),.op(1'b1), .z(upper), .status() );//op0add1sub
always@(posedge clk) begin
    upper_reg <= upper;
end
always@(*) begin
    if(counting==85) begin
        inputb1 = after_exp1_reg;
        inputb2 = FP_ONE;
    end
    else if(counting==86) begin
        inputb1 = after_exp1_reg;
        inputb2 = FP_ONE;
    end
    else if(counting==87) begin
        inputb1 = after_exp1_reg;
        inputb2 = FP_ONE;
    end
    else if(counting==88) begin
        inputb1 = after_exp1_reg;
        inputb2 = FP_ONE;
    end
    else if(counting==89) begin
        inputb1 = after_exp1_reg;
        inputb2 = FP_ONE;
    end
    else if(counting==90) begin
        inputb1 = after_exp1_reg;
        inputb2 = FP_ONE;
    end
    else if(counting==91) begin
        inputb1 = after_exp1_reg;
        inputb2 = FP_ONE;
    end
    else if(counting==92) begin
        inputb1 = after_exp1_reg;
        inputb2 = FP_ONE;
    end
    else begin
        inputb1 = FP_min;
        inputb2 =FP_min;
    end
end

DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
        Uadd2 ( .a(inputb1), .b(inputb2), .rnd(3'b0),.op(1'b0), .z(bottom), .status() );//op0add1sub
always@(posedge clk) begin
    bottom_reg <= bottom;
end

always @(*) begin
    if(counting==86) begin
        div_value1[1]= upper_reg;
        div_value1[2]= bottom_reg;
    end
    else if(counting==87) begin
        div_value1[1] = upper_reg;
        div_value1[2] = bottom_reg;
    end
    else if(counting==88) begin
        div_value1[1] = upper_reg;
        div_value1[2] = bottom_reg;
    end
    else if(counting==89) begin
        div_value1[1] = upper_reg;
        div_value1[2] = bottom_reg;
    end
    else if(counting==90) begin
        div_value1[1] = upper_reg;
        div_value1[2] = bottom_reg;
    end
    else if(counting==91) begin
        div_value1[1] = upper_reg;
        div_value1[2] = bottom_reg;
    end
    else if(counting==92) begin
        div_value1[1] = upper_reg;
        div_value1[2] = bottom_reg;
    end
    else if(counting==93) begin
        div_value1[1] = upper_reg;
        div_value1[2] = bottom_reg;
    end
    else if(counting==106) begin
        div_value1[1] = soft_max_exp[1] ;
        div_value1[2] = mother_out_reg;
    end
    else if(counting==107) begin
        div_value1[1] = soft_max_exp[2] ;
        div_value1[2] = mother_out_reg;
    end
    else if(counting==108) begin
        div_value1[1] = soft_max_exp[3] ;
        div_value1[2] = mother_out_reg;
    end
    else begin
        div_value1[1] = FP_min;
        div_value1[2] =FP_min;
    end
end
DW_fp_div_inst div1( .inst_a(div_value1[1]), .inst_b(div_value1[2]), .z_inst(after_div1));

always@(posedge clk ) begin
    if(counting==1) begin
        for(i=1;i<=8;i=i+1) begin
            afteractivation[i] <= 0;
        end
    end
    else begin
        if(counting==86) begin
            afteractivation[1] <= after_div1;
        end
        else if(counting==87) begin
            afteractivation[2] <= after_div1;
        end
        else if(counting==88) begin
            afteractivation[3] <= after_div1;
        end
        else if(counting==89) begin
            afteractivation[4] <= after_div1;
        end
        else if(counting==90) begin
            afteractivation[5] <= after_div1;
        end
        else if(counting==91) begin
            afteractivation[6] <= after_div1;
        end
        else if(counting==92) begin
            afteractivation[7] <= after_div1;
        end
        else if(counting==93) begin
            afteractivation[8] <= after_div1;
        end
    end
end 
always@(posedge clk) begin
    after_div_reg1 <= after_div1;
end
//---------------------------------------------------------------------
// SOFTMAX
//---------------------------------------------------------------------

always@(posedge clk) begin
    if(counting==1) begin
        for(i=1;i<=3;i=i+1) begin
            soft_max_exp[i] <= 0;
        end
    end
    else begin
        if(counting==102) begin
            soft_max_exp[1] <= after_exp1;
        end
        else if(counting==103) begin
            soft_max_exp[2] <= after_exp1;
        end
        else if(counting==104) begin
            soft_max_exp[3] <= after_exp1;
        end
    end
end

always@(*) begin
    c = soft_max_exp[1];
    d = soft_max_exp[2];
    f = soft_max_exp[3];
    
end
DW_fp_add_inst adder7777(.inst_a(c),.inst_b(d),.z_inst(temp_out) );
DW_fp_add_inst adder8888(.inst_a(temp_out),.inst_b(f),.z_inst(mother_out) );

always@(posedge clk) begin
    if(counting==105)
        mother_out_reg <= mother_out;
end

//---------------------------------------------------------------------
// WEIGHT
//---------------------------------------------------------------------
always@(*) begin
    for(i=1;i<=8;i=i+1) begin
        Weight_save1[i] = Weight_save1_reg[i];
    end
    
        if(counting==1) begin
            Weight_save1[1] = Weight;
        end
        else if(counting==2) begin
            Weight_save1[2] = Weight;
        end
        else if(counting==3) begin
            Weight_save1[3] = Weight;
        end
        else if(counting==4) begin
            Weight_save1[4] = Weight;
        end
        else if(counting==5) begin
            Weight_save1[5] = Weight;
        end
        else if(counting==6) begin
            Weight_save1[6] = Weight;
        end
        else if(counting==7) begin
            Weight_save1[7] = Weight;
        end
        else if(counting==8) begin
            Weight_save1[8] = Weight;
        end
        else begin
            for(i=1;i<=8;i=i+1) begin
                Weight_save1[i] = Weight_save1_reg[i];
            end
        end
end
always@(posedge clk) begin
     for(i=1;i<=8;i=i+1) begin
        Weight_save1_reg[i] <= Weight_save1[i];
    end
end
always@(*) begin
    for(i=1;i<=8;i=i+1) begin
        Weight_save2[i] = Weight_save2_reg[i];
    end
    if(counting==9) begin
        Weight_save2[1] = Weight;
    end
    else if(counting==10) begin
        Weight_save2[2] = Weight;
    end
    else if(counting==11) begin
        Weight_save2[3] = Weight;
    end
    else if(counting==12) begin
        Weight_save2[4] = Weight;
    end
    else if(counting==13) begin
        Weight_save2[5] = Weight;
    end
    else if(counting==14) begin
        Weight_save2[6] = Weight;
    end
    else if(counting==15) begin
        Weight_save2[7] = Weight;
    end
    else if(counting==16) begin
        Weight_save2[8] = Weight;
    end
    else begin
        for(i=1;i<=8;i=i+1) begin
            Weight_save2[i] = Weight_save2_reg[i];
        end
    end
end
always@(posedge clk) begin
     for(i=1;i<=8;i=i+1) begin
        Weight_save2_reg[i] <= Weight_save2[i];
    end
end
always@(*) begin
    for(i=1;i<=8;i=i+1) begin
        Weight_save3[i] = Weight_save3_reg[i];
    end
    if(counting==17) begin
        Weight_save3[1] = Weight;
    end
    else if(counting==18) begin
        Weight_save3[2] = Weight;
    end
    else if(counting==19) begin
        Weight_save3[3] = Weight;
    end
    else if(counting==20) begin
        Weight_save3[4] = Weight;
    end
    else if(counting==21) begin
        Weight_save3[5] = Weight;
    end
    else if(counting==22) begin
        Weight_save3[6] = Weight;
    end
    else if(counting==23) begin
        Weight_save3[7] = Weight;
    end
    else if(counting==24) begin
        Weight_save3[8] = Weight;
    end
    else begin
        for(i=1;i<=8;i=i+1) begin
            Weight_save3[i] = Weight_save3_reg[i];
        end
    end
end
always@(posedge clk) begin
     for(i=1;i<=8;i=i+1) begin
        Weight_save3_reg[i] <= Weight_save3[i];
    end
end

//---------------------------------------------------------------------
// FULLY_CONNECTED
//---------------------------------------------------------------------


always@(*) begin
    if(counting==95) begin
        conv1_a = afteractivation[1];
        conv1_b = Weight_save1_reg[1];
        conv1_c = afteractivation[2];
        conv1_d = Weight_save1_reg[2];
        conv1_e = afteractivation[3];
        conv1_f = Weight_save1_reg[3];
        conv1_g = afteractivation[4];
        conv1_h = Weight_save1_reg[4];
    end
    else if(counting==96) begin
        conv1_a = afteractivation[5];
        conv1_b = Weight_save1_reg[5];
        conv1_c = afteractivation[6];
        conv1_d = Weight_save1_reg[6];
        conv1_e = afteractivation[7];
        conv1_f = Weight_save1_reg[7];
        conv1_g = afteractivation[8];
        conv1_h = Weight_save1_reg[8];
    end
    else if(counting==97) begin
       conv1_a  = afteractivation[1];
       conv1_b  = Weight_save2_reg[1];
       conv1_c  = afteractivation[2];
       conv1_d  = Weight_save2_reg[2];
       conv1_e  = afteractivation[3];
       conv1_f  = Weight_save2_reg[3];
       conv1_g  = afteractivation[4];
       conv1_h  = Weight_save2_reg[4];
    end
    else if(counting==98) begin
        conv1_a = afteractivation[5];
        conv1_b = Weight_save2_reg[5];
        conv1_c = afteractivation[6];
        conv1_d = Weight_save2_reg[6];
        conv1_e = afteractivation[7];
        conv1_f = Weight_save2_reg[7];
        conv1_g = afteractivation[8];
        conv1_h = Weight_save2_reg[8];
    end
    else if(counting==99) begin
         conv1_a = afteractivation[1];
         conv1_b = Weight_save3_reg[1];
         conv1_c = afteractivation[2];
         conv1_d = Weight_save3_reg[2];
         conv1_e = afteractivation[3];
         conv1_f = Weight_save3_reg[3];
         conv1_g = afteractivation[4];
         conv1_h = Weight_save3_reg[4];
    end
    else if(counting==100) begin
        conv1_a = afteractivation[5];
        conv1_b = Weight_save3_reg[5];
        conv1_c = afteractivation[6];
        conv1_d = Weight_save3_reg[6];
        conv1_e = afteractivation[7];
        conv1_f = Weight_save3_reg[7];
        conv1_g = afteractivation[8];
        conv1_h = Weight_save3_reg[8];
    end
    else begin
        conv1_a = 0;
        conv1_b = 0;
        conv1_c = 0;
        conv1_d = 0;
        conv1_e = 0;
        conv1_f = 0;
        conv1_g = 0;
        conv1_h = 0;
    end
end

DW_fp_dp4 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
    U1 (.a(conv1_a),.b(conv1_b),.c(conv1_c),.d(conv1_d),.e(conv1_e),.f(conv1_f),.g(conv1_g),.h(conv1_h),.rnd(3'd0),.z(z_conv1),.status() );


always@(posedge clk) begin
    z_conv1_reg <= z_conv1;
end
always@(*) begin
    if(counting==96) begin
        a = after_ful[1];
        b = z_conv1_reg;
    end
    else if(counting==97) begin
        a = after_ful[1];
        b = z_conv1_reg;
    end
    else if(counting==98) begin
        a = after_ful[2] ;
        b = z_conv1_reg;
    end
    else if(counting==99) begin
        a = after_ful[2] ;
        b = z_conv1_reg;
    end
    else if(counting==100) begin
        a = after_ful[3] ;
        b = z_conv1_reg;
    end
    else if(counting==101) begin
        a = after_ful[3] ;
        b = z_conv1_reg;
    end
    else begin
        a = FP_min;
        b = FP_min;
    end
end

DW_fp_add_inst adder66666(.inst_a(a),.inst_b(b),.z_inst(z) );

always@(*) begin
    for(i=1;i<=3;i=i+1) begin
        n_after_ful[i] = after_ful[i] ;
    end
    if(counting==96) begin
       n_after_ful[1] = z;
    end
    else if(counting==97) begin
        n_after_ful[1] = z;
    end
    else if(counting==98) begin
        n_after_ful[2] = z;
    end
    else if(counting==99) begin
        n_after_ful[2] = z;
    end
    else if(counting==100) begin
        n_after_ful[3] = z;
    end
    else if(counting==101) begin
        n_after_ful[3] = z;
    end
end

always@(posedge clk) begin
    if(counting==1) begin
        for(i=1;i<=3;i=i+1) begin
            after_ful[i] <= 0;
        end
    end
    else begin
    for(i=1;i<=3;i=i+1) begin
        after_ful[i] <= n_after_ful[i] ;
    end
    end
end

//---------------------------------------------------------------------
// SOFTMAX
//---------------------------------------------------------------------
reg [31:0] soft_max_ans[1:3];

always@(*) begin
    if(counting==85) begin
        soft_max_ans[1] = after_div1;
    end
    else if(counting==86) begin
        soft_max_ans[2] = after_div1;
    end
    else if(counting==87) begin
        soft_max_ans[3] = after_div1;
    end
end
//---------------------------------------------------------------------
// OUTPUT
//---------------------------------------------------------------------

always@(*) begin
    if(counting==1) begin
        out=32'b0;
        out_valid = 1'b0;
    end
    else if(counting==107) begin
        out_valid = 1'b1;
        out =after_div_reg1;
    end
    else if(counting==108) begin
        out_valid = 1'b1;
        out =after_div_reg1;
    end
    else if(counting==109) begin
        out_valid = 1'b1;
        out =after_div_reg1;
    end
    else begin
        out= 32'b0;
        out_valid = 1'b0; 
    end
end


endmodule
//---------------------------------------------------------------------
// IPs
//---------------------------------------------------------------------

module DW_fp_add_inst( inst_a, inst_b,  z_inst );

parameter sig_width = 23;
parameter exp_width = 8;
parameter ieee_compliance = 0;

input [sig_width+exp_width : 0] inst_a;
input [sig_width+exp_width : 0] inst_b;

output [sig_width+exp_width : 0] z_inst;

    // Instance of DW_fp_add
    DW_fp_add #(sig_width, exp_width, ieee_compliance)
      U1 ( .a(inst_a), .b(inst_b), .rnd(3'b000), .z(z_inst));

endmodule
module fp_MULT(inst_a, inst_b, z_inst);
// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 0;

input  [inst_sig_width+inst_exp_width:0] inst_a, inst_b;
output [inst_sig_width+inst_exp_width:0] z_inst;

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1( .a(inst_a),
        .b(inst_b),
        .rnd(3'b000),
        .z(z_inst) );

// synopsys dc_script_begin
// set_implementation rtl U1
// synopsys dc_script_end

endmodule

module fp_exp( inst_a, z_inst);
// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 1;

input [inst_sig_width+inst_exp_width : 0] inst_a;
output [inst_sig_width+inst_exp_width : 0] z_inst;
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch)
    U5 (.a(inst_a),
        .z(z_inst),
        .status());

// synopsys dc_script_begin
// set_implementation rtl U5
// synopsys dc_script_end
endmodule
module DW_fp_cmp_inst( inst_a, inst_b, inst_zctr,z0_inst, z1_inst);

parameter sig_width = 23;
parameter exp_width = 8;
parameter ieee_compliance = 0;

input [sig_width+exp_width : 0] inst_a;
input [sig_width+exp_width : 0] inst_b;
input inst_zctr;

output [sig_width+exp_width : 0] z0_inst;
output [sig_width+exp_width : 0] z1_inst;

    // Instance of DW_fp_cmp
    DW_fp_cmp #(sig_width, exp_width, ieee_compliance)
      U1 ( .a(inst_a), .b(inst_b), .zctr(inst_zctr), 
        .z0(z0_inst), .z1(z1_inst));

endmodule
module DW_fp_div_inst( inst_a, inst_b, z_inst);

parameter sig_width = 23;
parameter exp_width = 8;
parameter ieee_compliance = 0;
parameter faithful_round = 0;
parameter en_ubr_flag = 0;

input [sig_width+exp_width : 0] inst_a;
input [sig_width+exp_width : 0] inst_b;

output [sig_width+exp_width : 0] z_inst;

  // Instance of DW_fp_div
DW_fp_div #(sig_width, exp_width, ieee_compliance, faithful_round, en_ubr_flag) U1 
( .a(inst_a), .b(inst_b), .rnd(3'b000), .z(z_inst));

endmodule
