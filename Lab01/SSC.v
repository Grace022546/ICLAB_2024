//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Fall
//   Lab01 Exercise		: Snack Shopping Calculator
//   Author     		  : Yu-Hsiang Wang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SSC.v
//   Module Name : SSC
//   Release version : V1.0 (Release Date: 2024-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
/*
//synopsys translate_off
`include "/usr/synthesis/dw/sim_ver/DW01_addsub_inst.v"
//synopsys translate_on*/

module SSC(
    // Input signals
    card_num,
    input_money,
    snack_num,
    price, 
    // Output signals
    out_valid,
    out_change
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [63:0] card_num;
input [8:0] input_money;
input [31:0] snack_num;
input [31:0] price;
output    out_valid;
output [8:0] out_change;    

//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment
wire [8:0] sum;
reg [3:0] sum_cal[0:7];
reg [3:0] sum_cal_temp[0:7];

wire [7:0] total [7:0];
wire [7:0] sorted_value [0:7];
reg out_valid_reg;
reg [8:0] out_change_reg;  
//================================================================
//    DESIGN
//================================================================
/*
assign sum_cal[0] = 4'd0;
assign sum_cal[1] = 4'd2;
assign sum_cal[2] = 4'd4;
assign sum_cal[3] = 4'd6;
assign sum_cal[4] = 4'd8;
assign sum_cal[5] = 4'd1;
assign sum_cal[6] = 4'd3;
assign sum_cal[7] = 4'd5;
assign sum_cal[8] = 4'd7;
assign sum_cal[9] = 4'd9;
*/
always@(*) begin
    sum_cal[0] = (card_num[63:60]<4'd5)?(card_num[63:60]<<1):((card_num[63:60]<<1)+4'b0111);
    sum_cal[1] = (card_num[55:52]<4'd5)?(card_num[55:52]<<1):((card_num[55:52]<<1)+4'b0111);
    sum_cal[2] = (card_num[47:44]<4'd5)?(card_num[47:44]<<1):((card_num[47:44]<<1)-4'b1001);
    sum_cal[3] = (card_num[39:36]<4'd5)?(card_num[39:36]<<1):((card_num[39:36]<<1)-4'b1001);
    sum_cal[4] = (card_num[31:28]<4'd5)?(card_num[31:28]<<1):((card_num[31:28]<<1)-4'b1001);
    sum_cal[5] = (card_num[23:20]<4'd5)?(card_num[23:20]<<1):((card_num[23:20]<<1)-4'b1001);
    sum_cal[6] = (card_num[15:12]<4'd5)?(card_num[15:12]<<1):((card_num[15:12]<<1)-4'b1001);//51762
    sum_cal[7] = (card_num[7:4]<4'd5)?(card_num[7:4]<<1):((card_num[7:4]<<1)-4'b1001);
end/*
wire [3:0] haha;

reg [3:0] x,y,num;

always@(*) begin
  //  sum_cal_temp[0] = card_num[63:60]<<1;
    sum_cal_temp[1] = card_num[55:52]<<1;
    sum_cal_temp[2] = card_num[47:44]<<1;
    sum_cal_temp[3] = card_num[39:36]<<1;
    sum_cal_temp[4] = card_num[31:28]<<1;
    sum_cal_temp[5] = card_num[23:20]<<1;
    sum_cal_temp[6] = card_num[15:12]<<1;
    sum_cal_temp[7] = card_num[7:4]<<1;
end
always@(*) begin
    if(card_num[63:60]<4'd5) begin
        case(card_num[63:60])
            1:sum_cal[0] = 4'd2;
            2:sum_cal[0] = 4'd4;
            3:sum_cal[0] = 4'd6;
            4:sum_cal[0] = 4'd8;
            default:sum_cal[0] = 0;
        endcase
    end
    else begin
        case(card_num[63:60])
            5:sum_cal[0] = 4'd1;
            6:sum_cal[0] = 4'd3;
            7:sum_cal[0] = 4'd5;
            8:sum_cal[0] = 4'd7;
            9:sum_cal[0] = 4'd9;
            default:sum_cal[0] = 0;
        endcase
    end
    
    if(card_num[55:52]<4'd5) begin
        sum_cal[1] = sum_cal_temp[1];
    end
    else begin
        case(sum_cal_temp[1])
            2:sum_cal[1] = 4'd9;
            10:sum_cal[1] = 4'd1;
            12:sum_cal[1] = 4'd3;
            14:sum_cal[1] = 4'd5;
            0:sum_cal[1] = 4'd7;
            default:sum_cal[1] = sum_cal_temp[1];
        endcase
    end
    
    if(card_num[47:44]<4'd5) begin
        sum_cal[2] = sum_cal_temp[2];
    end
    else begin
        case(sum_cal_temp[2])
            2:sum_cal[2] = 4'd9;
            10:sum_cal[2] = 4'd1;
            12:sum_cal[2] = 4'd3;
            14:sum_cal[2] = 4'd5;
            0:sum_cal[2] = 4'd7;
            default:sum_cal[2] = sum_cal_temp[2];
        endcase
    end
    if(card_num[39:36]<4'd5) begin
        sum_cal[3] = sum_cal_temp[3];
    end
    else begin
        case(sum_cal_temp[3])
            2:sum_cal[3] = 4'd9;
            10:sum_cal[3] = 4'd1;
            12:sum_cal[3] = 4'd3;
            14:sum_cal[3] = 4'd5;
            0:sum_cal[3] = 4'd7;
            default:sum_cal[3] = sum_cal_temp[3];
        endcase
    end
    if(card_num[31:28]<4'd5) begin
        sum_cal[4] = sum_cal_temp[4];
    end
    else begin
        case(sum_cal_temp[4])
            2:sum_cal[4] = 4'd9;
            10:sum_cal[4] = 4'd1;
            12:sum_cal[4] = 4'd3;
            14:sum_cal[4] = 4'd5;
            0:sum_cal[4] = 4'd7;
            default:sum_cal[4] = sum_cal_temp[4];
        endcase
    end
    if(card_num[23:20]<4'd5) begin
        sum_cal[5] = sum_cal_temp[5];
    end
    else begin
        case(sum_cal_temp[5])
            2:sum_cal[5] = 4'd9;
            10:sum_cal[5] = 4'd1;
            12:sum_cal[5] = 4'd3;
            14:sum_cal[5] = 4'd5;
            0:sum_cal[5] = 4'd7;
            default:sum_cal[5] = sum_cal_temp[5];
        endcase
    end
    if(card_num[15:12]<4'd5) begin
        sum_cal[6] = sum_cal_temp[6];
    end
    else begin
        case(sum_cal_temp[6])
            
            10:sum_cal[6] = 4'd1;
            12:sum_cal[6] = 4'd3;
            14:sum_cal[6] = 4'd5;
            0:sum_cal[6] = 4'd7;
            2:sum_cal[6] = 4'd9;
            default:sum_cal[6] = sum_cal_temp[6];
        endcase
    end
    if(card_num[7:4]<4'd5) begin
        sum_cal[7] = sum_cal_temp[7];
    end
    else begin
        case(sum_cal_temp[7])
            10:sum_cal[7] = 4'd1;
            12:sum_cal[7] = 4'd3;
            14:sum_cal[7] = 4'd5;
            0:sum_cal[7] = 4'd7;
            2:sum_cal[7] = 4'd9;
            default:sum_cal[7] = sum_cal_temp[7];
        endcase
       // sum_cal[7] = sum_cal_temp[7] - 4'b1001;
    end
    
end*/
 //DW01_addsub addsuber_k (.A(x), .B(4'b0111), .CI(1'b0), .ADD_SUB(1'b1), .SUM(sum_cal[7]), .CO());
/*


assign haha =  card_num[59:56] + card_num[51:48] + card_num[43:40] + card_num[35:32] + card_num[27:24] + card_num[19:16] + card_num[11:8] + card_num[3:0];
assign sum = (sum_cal[0] + sum_cal[1])+ (sum_cal[2] + sum_cal[3]) + (sum_cal[4] + sum_cal[5]) + (sum_cal[6] + sum_cal[7]) + haha;*/

assign sum =  (sum_cal[0] + card_num[59:56]) + 
              (sum_cal[1] + card_num[51:48]) + 
              (sum_cal[2] + card_num[43:40]) + 
              (sum_cal[3] + card_num[35:32]) + 
              (sum_cal[4] + card_num[27:24]) + 
              (sum_cal[5] + card_num[19:16]) + 
              (sum_cal[6] + card_num[11:8]) + 
              (sum_cal[7] + card_num[3:0]) ;/*
assign sum =  (sum_cal[card_num[63:60]] + card_num[59:56]) + 
              (sum_cal[card_num[55:52]] + card_num[51:48]) + 
              (sum_cal[card_num[47:44]] + card_num[43:40]) + 
              (sum_cal[card_num[39:36]] + card_num[35:32]) + 
              (sum_cal[card_num[31:28]] + card_num[27:24]) + 
              (sum_cal[card_num[23:20]] + card_num[19:16]) + 
              (sum_cal[card_num[15:12]] + card_num[11:8]) + 
              (sum_cal[card_num[7:4]] + card_num[3:0]) ;*/
/*
always@(*) begin
   out_valid = ((sum%10)==0)?1:0; 
end*/



always@(*) begin
    case(sum)
        50,60,70,80,90,100,110,120:out_valid_reg = 1;
        default:out_valid_reg=0;
    endcase
end
assign out_valid = out_valid_reg;
/*
genvar i;
generate
    for(i=28;i>=0;i=i-4) begin:gen_loop
        assign total[i/4] = snack_num[i+3:i] * price[i+3:i];
    end
endgenerate*/
DW02_mult #(4, 4)mult0(.A(snack_num[31:28]),.B(price[31:28]),.TC(1'b0),.PRODUCT(total[7]));
DW02_mult #(4, 4)mult1(.A(snack_num[27:24]),.B(price[27:24]),.TC(1'b0),.PRODUCT(total[6]));
DW02_mult #(4, 4)mult2(.A(snack_num[23:20]),.B(price[23:20]),.TC(1'b0),.PRODUCT(total[5]));
//DW02_mult #(4, 4)mult3(.A(snack_num[19:16]),.B(price[19:16]),.TC(1'b0),.PRODUCT(total[4]));
//DW02_mult #(4, 4)mult4(.A(snack_num[15:12]),.B(price[15:12]),.TC(1'b0),.PRODUCT(total[3]));
//DW02_mult #(4, 4)mult5(.A(snack_num[11:8]),.B(price[11:8]),.TC(1'b0),.PRODUCT(total[2]));
//DW02_mult #(4, 4)mult6(.A(snack_num[7:4]),.B(price[7:4]),.TC(1'b0),.PRODUCT(total[1]));
//DW02_mult #(4, 4)mult7(.A(snack_num[3:0]),.B(price[3:0]),.TC(1'b0),.PRODUCT(total[0]));
//mul mul7(.result(total[7]),.a(snack_num[31:28]),.b(price[31:28]));
//mul mul6(.result(total[6]),.a(snack_num[27:24]),.b(price[27:24]));
//mul mul5(.result(total[5]),.a(snack_num[23:20]),.b(price[23:20]));
mul mul4(.result(total[4]),.a(snack_num[19:16]),.b(price[19:16]));
mul mul3(.result(total[3]),.a(snack_num[15:12]),.b(price[15:12]));
mul mul2(.result(total[2]),.a(snack_num[11:8]),.b(price[11:8]));
mul mul1(.result(total[1]),.a(snack_num[7:4]),.b(price[7:4]));
mul mul0(.result(total[0]),.a(snack_num[3:0]),.b(price[3:0]));



sorting_8 a(.in0(total[0]),.in1(total[1]),.in2(total[2]),.in3(total[3]),.in4(total[4]),.in5(total[5]),.in6(total[6]),.in7(total[7])
                    ,.out0(sorted_value[0]),.out1(sorted_value[1]),.out2(sorted_value[2]),.out3(sorted_value[3]),.out4(sorted_value[4]),.out5(sorted_value[5]),.out6(sorted_value[6]),.out7(sorted_value[7]));


wire  [8:0] t0;
wire [8:0] t1,t2,t3,t4,t5;
wire   [8:0] t6,t7;

DW01_addsub #(9)addsuber0(.A(input_money), .B({1'b0,sorted_value[0]}), .CI(1'b0), .ADD_SUB(1'b1), .SUM(t0), .CO());
DW01_addsub #(9)addsuber1(.A(t0), .B({1'b0,sorted_value[1]}), .CI(1'b0), .ADD_SUB(1'b1), .SUM(t1), .CO());
DW01_addsub #(9)addsuber2(.A(t1), .B({1'b0,sorted_value[2]}), .CI(1'b0), .ADD_SUB(1'b1), .SUM(t2), .CO());
DW01_addsub #(9)addsuber3(.A(t2), .B({1'b0,sorted_value[3]}), .CI(1'b0), .ADD_SUB(1'b1), .SUM(t3), .CO());
DW01_addsub #(9)addsuber4(.A(t3), .B({1'b0,sorted_value[4]}), .CI(1'b0), .ADD_SUB(1'b1), .SUM(t4), .CO());
DW01_addsub #(9)addsuber5(.A(t4), .B({1'b0,sorted_value[5]}), .CI(1'b0), .ADD_SUB(1'b1), .SUM(t5), .CO());
DW01_addsub #(9)addsuber6(.A(t5), .B({1'b0,sorted_value[6]}), .CI(1'b0), .ADD_SUB(1'b1), .SUM(t6), .CO());
DW01_addsub #(9)addsuber7(.A(t6), .B({1'b0,sorted_value[7]}), .CI(1'b0), .ADD_SUB(1'b1), .SUM(t7), .CO());
//assign t0 = input_money + ~sorted_value[0] + 1'b1;
//assign t1 = t0 + ~sorted_value[1] + 1'b1;
//assign t2 = t1 + ~sorted_value[2] + 1'b1;
//assign t3 = t2 - sorted_value[3] ;
//assign t4 = t3 - sorted_value[4] ;
//assign t5 = t4 - sorted_value[5] ;
//assign t6 = t5 - sorted_value[6] ;
//assign t7 = t6 - sorted_value[7] ;

always @(*) begin
    if (input_money < sorted_value[0] || out_valid == 0) begin
        out_change_reg = input_money;
    end 
    else if(t0 < sorted_value[1])begin
        out_change_reg = t0;
    end
    else if(t1 < sorted_value[2])begin
        out_change_reg = t1;
    end
    else if(t2 < sorted_value[3])begin
        out_change_reg = t2;
    end
    else if(t3 < sorted_value[4])begin
        out_change_reg = t3;
    end
    else if(t4 < sorted_value[5])begin
        out_change_reg = t4;
    end
    else if(t5 < sorted_value[6])begin
        out_change_reg = t5;
    end
    else if(t6 < sorted_value[7])begin
        out_change_reg = t6;
    end
    else begin
        out_change_reg = t7;
    end
    
end

assign out_change = out_change_reg;

endmodule

module sorting_8 (in0,in1,in2,in3,in4,in5,in6,in7,
                          out0,out1,out2,out3,out4,out5,out6,out7 );

input [7:0] in0,in1,in2,in3,in4,in5,in6,in7;
output [7:0] out0,out1,out2,out3,out4,out5,out6,out7;
integer m,k;
reg [7:0] value [8:0];
reg [7:0] value_a [8:0];
reg [7:0] value_b [8:0];
reg [7:0] value_c [8:0];
reg [7:0] value_d [8:0];
reg [7:0] value_e [8:0];
reg [7:0] value_f [8:0];


always@(*) begin
    value[0] = in0;
    value[1] = in1;
    value[2] = in2;
    value[3] = in3;
    value[4] = in4;
    value[5] = in5;
    value[6] = in6;
    value[7] = in7;
end
/*
assign value_a[0] = (value[0]>value[4])?value[0]:value[4];
assign value_a[4] = (value[0]>value[4])?value[4]:value[0];
assign value_a[1] = (value[1]>value[5])?value[1]:value[5];
assign value_a[5] = (value[1]>value[5])?value[5]:value[1];
assign value_a[2] = (value[2]>value[6])?value[2]:value[6];
assign value_a[6] = (value[2]>value[6])?value[6]:value[2];
assign value_a[3] = (value[3]>value[7])?value[3]:value[7];
assign value_a[7] = (value[3]>value[7])?value[7]:value[3];

assign value_c[0] = (value_b[0] > value_b[2]) ? value_b[0] : value_b[2];
assign value_c[2] = (value_b[0] > value_b[2]) ? value_b[2] : value_b[0];
assign value_c[1] = (value_b[1] > value_b[3]) ? value_b[1] : value_b[3];
assign value_c[3] = (value_b[1] > value_b[3]) ? value_b[3] : value_b[1];
assign value_c[4] = (value_b[4] > value_b[6]) ? value_b[4] : value_b[6];
assign value_c[6] = (value_b[4] > value_b[6]) ? value_b[6] : value_b[4];
assign value_c[5] = (value_b[5] > value_b[7]) ? value_b[5] : value_b[7];
assign value_c[7] = (value_b[5] > value_b[7]) ? value_b[7] : value_b[5];


assign value_b[0] = value_a[0];
assign value_b[1] = value_a[1];
assign value_b[2] = (value_a[2] > value_a[4]) ? value_a[2] : value_a[4];
assign value_b[4] = (value_a[2] > value_a[4]) ? value_a[4] : value_a[2];
assign value_b[3] = (value_a[3] > value_a[5]) ? value_a[3] : value_a[5];
assign value_b[5] = (value_a[3] > value_a[5]) ? value_a[5] : value_a[3];
assign value_b[6] = value_a[6];
assign value_b[7] = value_a[7];

assign value_e[0] = (value_d[0] > value_d[1]) ? value_d[0] : value_d[1];
assign value_e[1] = (value_d[0] > value_d[1]) ? value_d[1] : value_d[0];
assign value_e[2] = (value_d[2] > value_d[3]) ? value_d[2] : value_d[3];
assign value_e[3] = (value_d[2] > value_d[3]) ? value_d[3] : value_d[2];
assign value_e[4] = (value_d[4] > value_d[5]) ? value_d[4] : value_d[5];
assign value_e[5] = (value_d[4] > value_d[5]) ? value_d[5] : value_d[4];
assign value_e[6] = (value_d[6] > value_d[7]) ? value_d[6] : value_d[7];
assign value_e[7] = (value_d[6] > value_d[7]) ? value_d[7] : value_d[6];




assign value_d[0] = value_c[0];
assign value_d[1] = (value_c[1] > value_c[4]) ? value_c[1] : value_c[4];
assign value_d[4] = (value_c[1] > value_c[4]) ? value_c[4] : value_c[1];
assign value_d[3] = (value_c[3] > value_c[5]) ? value_c[3] : value_c[5];
assign value_d[5] = (value_c[3] > value_c[5]) ? value_c[5] : value_c[3];
assign value_d[2] = (value_c[2] > value_c[6]) ? value_c[2] : value_c[6];
assign value_d[6] = (value_c[2] > value_c[6]) ? value_c[6] : value_c[2];
assign value_d[7] = value_c[7];

assign value_f[0] = value_e[0];
assign value_f[2] = value_e[2];
assign value_f[5] = (value_e[5] > value_e[6]) ? value_e[5] : value_e[6];
assign value_f[6] = (value_e[5] > value_e[6]) ? value_e[6] : value_e[5];
assign value_f[3] = (value_e[3] > value_e[4]) ? value_e[3] : value_e[4];
assign value_f[4] = (value_e[3] > value_e[4]) ? value_e[4] : value_e[3];
assign value_f[1] = value_e[1];
assign value_f[7] = value_e[7];

assign out0 = value_e[0];
assign out1 = value_f[1];
assign out2 = value_f[2];
assign out3 = value_f[3];
assign out4 = value_f[4];
assign out5 = value_f[5];
assign out6 = value_f[6];
assign out7 = value_e[7];*/

always@(*) begin
    if(value[0]>value[2]) begin
        value_a[0] = value[0];
        value_a[2] = value[2];
    end
    else begin
        value_a[0] = value[2];
        value_a[2] = value[0];
    end
    if(value[1]>value[3]) begin
        value_a[1] = value[1];
        value_a[3] = value[3];
    end
    else begin
        value_a[1] = value[3];
        value_a[3] = value[1];
    end
    if(value[4]>value[6]) begin
        value_a[4] = value[4];
        value_a[6] = value[6];
    end
    else begin
        value_a[4] = value[6];
        value_a[6] = value[4];
    end
    if(value[5]>value[7]) begin
        value_a[5] = value[5];
        value_a[7] = value[7];
    end
    else begin
        value_a[5] = value[7];
        value_a[7] = value[5];
    end
end
always@(*) begin
    if(value_a[0]>value_a[4]) begin
        value_b[0] = value_a[0];
        value_b[4] = value_a[4];
    end
    else begin
        value_b[0] = value_a[4];
        value_b[4] = value_a[0];
    end
    if(value_a[1]>value_a[5]) begin
        value_b[1] = value_a[1];
        value_b[5] = value_a[5];
    end
    else begin
        value_b[1] = value_a[5];
        value_b[5] = value_a[1];
    end
    if(value_a[2]>value_a[6]) begin
        value_b[2] = value_a[2];
        value_b[6] = value_a[6];
    end
    else begin
        value_b[2] = value_a[6];
        value_b[6] = value_a[2];
    end
    if(value_a[3]>value_a[7]) begin
        value_b[3] = value_a[3];
        value_b[7] = value_a[7];
    end
    else begin
        value_b[3] = value_a[7];
        value_b[7] = value_a[3];
    end
end
always@(*) begin
    if(value_b[0]>value_b[1]) begin
        value_c[0] = value_b[0];
        value_c[1] = value_b[1];
    end
    else begin
        value_c[0] = value_b[1];
        value_c[1] = value_b[0];
    end
    if(value_b[2]>value_b[3]) begin
        value_c[2] = value_b[2];
        value_c[3] = value_b[3];
    end
    else begin
        value_c[2] = value_b[3];
        value_c[3] = value_b[2];
    end
    if(value_b[4]>value_b[5]) begin
        value_c[4] = value_b[4];
        value_c[5] = value_b[5];
    end
    else begin
        value_c[4] = value_b[5];
        value_c[5] = value_b[4];
    end
    if(value_b[6]>value_b[7]) begin
        value_c[6] = value_b[6];
        value_c[7] = value_b[7];
    end
    else begin
        value_c[6] = value_b[7];
        value_c[7] = value_b[6];
    end
end
always@(*) begin
    value_d[0] = value_c[0];
    value_d[1] = value_c[1];
    value_d[6] = value_c[6];
    value_d[7] = value_c[7];
    if(value_c[2]>value_c[4]) begin
        value_d[2] = value_c[2];
        value_d[4] = value_c[4];
    end
    else begin
        value_d[2] = value_c[4];
        value_d[4] = value_c[2];
    end
    if(value_c[3]>value_c[5]) begin
        value_d[3] = value_c[3];
        value_d[5] = value_c[5];
    end
    else begin
        value_d[3] = value_c[5];
        value_d[5] = value_c[3];
    end
end
always@(*) begin
    value_e[0] = value_d[0];
    value_e[2] = value_d[2];
    value_e[5] = value_d[5];
    value_e[7] = value_d[7];
    if(value_d[1]>value_d[4]) begin
        value_e[1] = value_d[1];
        value_e[4] = value_d[4];
    end
    else begin
        value_e[1] = value_d[4];
        value_e[4] = value_d[1];
    end
    if(value_d[3]>value_d[6]) begin
        value_e[3] = value_d[3];
        value_e[6] = value_d[6];
    end
    else begin
        value_e[3] = value_d[6];
        value_e[6] = value_d[3];
    end
end
always@(*) begin
 //   value_f[0] = value_e[0];
   // value_f[7] = value_e[7];
    if(value_e[1]>value_e[2]) begin
        value_f[0] = value_e[1];
        value_f[1] = value_e[2];
    end
    else begin
        value_f[0] = value_e[2];
        value_f[1] = value_e[1];
    end
    if(value_e[3]>value_e[4]) begin
        value_f[2] = value_e[3];
        value_f[3] = value_e[4];
    end
    else begin
        value_f[2] = value_e[4];
        value_f[3] = value_e[3];
    end
    if(value_e[5]>value_e[6]) begin
        value_f[4] = value_e[5];
        value_f[5] = value_e[6];
    end
    else begin
        value_f[4] = value_e[6];
        value_f[5] = value_e[5];
    end
end
assign out0 = value_e[0];
assign out1 = value_f[0];
assign out2 = value_f[1];
assign out3 = value_f[2];
assign out4 = value_f[3];
assign out5 = value_f[4];
assign out6 = value_f[5];
assign out7 = value_e[7];
endmodule

module mul(a,b,result);
    input [3:0] a, b;
    output [7:0] result;
    wire [3:0] temp0;
    wire [4:0] temp1;
    wire [5:0] temp2;
    wire [6:0] temp3;
    wire [7:0] ohs,ohs2;
    assign temp0 = (b[0])?a:0;
    assign temp1 = (b[1])?{a,1'b0}:0;
    assign temp2 = (b[2])?{a,2'b00}:0;
    assign temp3 = (b[3])?{a,3'b000}:0;
    //assign result = (temp2 + temp1) + (temp0 + temp3);
    DW01_addsub #(8)addsuber_0(.A({4'b0,temp0}), .B({3'b0,temp1}), .CI(1'b0), .ADD_SUB(1'b0), .SUM(ohs), .CO());
    DW01_addsub #(8)addsuber_1(.A({2'b0,temp2}), .B({1'b0,temp3}), .CI(1'b0), .ADD_SUB(1'b0), .SUM(ohs2), .CO());
    DW01_addsub #(8)addsuber_2(.A(ohs), .B(ohs2), .CI(1'b0), .ADD_SUB(1'b0), .SUM(result), .CO());
endmodule
