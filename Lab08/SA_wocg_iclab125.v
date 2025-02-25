/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: SA
// FILE NAME: SA.v
// VERSRION: 1.0
// DATE: Nov 06, 2024
// AUTHOR: Yen-Ning Tung, NYCU AIG
// CODE TYPE: RTL or Behavioral Level (Verilog)
// DESCRIPTION: 2024 Fall IC Lab / Exersise Lab08 / SA
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

module SA(
	// Input signals
	clk,
	rst_n,
	in_valid,
	T,
	in_data,
	w_Q,
	w_K,
	w_V,
	// Output signals
	out_valid,
	out_data
);

input clk;
input rst_n;
input in_valid;
input [3:0] T;
input signed [7:0] in_data;
input signed [7:0] w_Q;
input signed [7:0] w_K;
input signed [7:0] w_V;

output reg out_valid;
output reg signed [63:0] out_data;
reg [8:0] cnt;
// reg [7:0] save_WK[0:7][0:7];
//==================INPUTSAVE===================//
reg signed[7:0] save_WQ[0:7][0:7];
reg signed[7:0] save_WK[0:7][0:7];
reg signed[7:0] save_WK_reg[0:7][0:7];
reg signed[7:0] save_WV[0:7][0:7];
reg signed[7:0] save_WV_reg[0:7][0:7];
reg signed[7:0] element[0:7][0:7];
//==================CALOUTCOMESAVE===================//
//==================SMALL===================//
reg signed[18:0] save_K[0:7][0:7];
reg signed[18:0] save_K_reg[0:7][0:7];
reg signed[18:0] save_Q[0:7][0:7];
reg signed[18:0] save_Q_reg[0:7][0:7];
reg signed[18:0] save_V[0:7][0:7];
reg signed[18:0] save_V_reg[0:7][0:7];
//==================MID===================//
reg signed[39:0] save_A[0:7][0:7];
//==================BIG===================//
reg signed[58:0] save_P[0:7][0:7];
//==================RECORDTSETSTING===================//
integer i,j;
reg [5:0] T_counting;
reg [2:0]T_save;
//===============COUNTFORSAVEINPUT======================//
reg [3:0] x_cnt,y_cnt;
//===============COUNTFORMUL======================//
reg [3:0] mul_x_cnt,mul_y_cnt;
//===============COUNTFORADD======================//
reg [3:0] add_x_cnt,add_y_cnt,super_cnt;
//===============SMALLMULPARAMETER======================//
reg signed [7:0] mul_in_1[0:7],mul_in_2[0:7];
wire signed [18:0] mul_out[0:7];
reg signed [18:0] mul_out_reg[0:7];
//===============BIGMULPARAMETER======================//
reg signed [39:0] mul_big_in_1[0:7];
reg signed [18:0] mul_big_in_2[0:7];
wire signed [58:0] mul_big_out[0:7];
reg signed [58:0] mul_big_out_reg[0:7];
//===============SMALLADDPARAMETER======================//
reg signed [18:0] add_in_1[0:3],add_in_2[0:3];
wire signed [18:0] add_out[0:3];//back to save_A
reg signed [18:0] add_in_sev_1[0:1],add_in_sev_2[0:1];
wire signed [18:0] add_out_sev[0:1];//back to save_A
reg signed [18:0] add_in_eig_1,add_in_eig_2;
wire signed [18:0] add_out_eig;//back to save_A
//===============BIGADDPARAMETER======================//
reg signed [58:0] add_big_in_1[0:3],add_big_in_2[0:3];
wire signed [61:0] add_big_out[0:3];//back to save_A
reg signed [58:0] add_bigadd_2_1[0:1],add_bigadd_2_2[0:1];
wire signed [61:0] add_bigout_2[0:1];//back to save_A
reg signed [58:0] add_bigadd_3_1,add_bigadd_3_2;
wire signed [61:0] add_bigout_3;//back to save_A
//===============GLOBALCOUNT======================//

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        T_counting <= 0;
    end
    else begin
        if(cnt==(256+T_counting)) begin
            T_counting <= 0;
        end
        else if(in_valid && cnt==0) begin
            case(T)
                1: T_counting <= 7;
                4: T_counting <= 31;
                8: T_counting <= 63;
                default: T_counting <= T_counting;
            endcase
        end
        else begin
            T_counting <= T_counting;
        end
    end
end

// 
//================GLOBALCOUNT============//
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt <= 4'b0;
    end
    else begin
        if(in_valid||(cnt>=192 && cnt<=256+T_counting)) begin
            cnt <= cnt + 1;
        end
        else begin
            cnt <= 4'b0;
        end
    end
end
//================COUNTFORINPUT============//
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        x_cnt <= 4'b0;
    end
    else begin
        // if(cs_state !=ns_state) begin
        //     x_cnt <= 4'b0;
        // end
        // else 
        if(in_valid) begin
            if(x_cnt==7) begin
                x_cnt <= 4'b0;
            end
            else begin
                x_cnt <= x_cnt + 1;
            end   
        end
        else begin
            x_cnt <= 4'b0;
        end
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        y_cnt <= 4'b0;
    end
    else begin
        if(in_valid) begin
            if(x_cnt==7 && y_cnt==7) begin
                y_cnt <= 4'b0;
            end
            else if(x_cnt==7) begin
                y_cnt <= y_cnt + 1;
            end
            else begin
                y_cnt <= y_cnt;
            end
        end
        else begin
            y_cnt <= 4'b0;
        end
    end
end
//================COUNTFORMUL============//
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mul_x_cnt <= 0; 
    end
    else begin
        if(cnt>=63 && cnt<=256+T_counting) begin
            if(mul_x_cnt==7) begin
                mul_x_cnt <= 0;
            end
            else begin
                mul_x_cnt <= mul_x_cnt + 1;
            end   
        end
        else begin
            mul_x_cnt <= 0;
        end
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mul_y_cnt <= 4'b0;
    end
    else begin
        if(cnt>=63&& cnt<=256+T_counting) begin
            if(mul_x_cnt==7 && mul_y_cnt==7) begin
                mul_y_cnt <= 4'b0;
            end
            else if(mul_x_cnt==7) begin
                mul_y_cnt <= mul_y_cnt + 1;
            end
            else begin
                mul_y_cnt <= mul_y_cnt;
            end
        end
        else begin
            mul_y_cnt <= 4'b0;
        end
    end
end
//================COUNTFORADD============//
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        add_x_cnt <= 0; 
    end
    else begin
        if(cnt>=64&& cnt<=256+T_counting) begin
            if(add_x_cnt==7) begin
                add_x_cnt <= 0;
            end
            else begin
                add_x_cnt <= add_x_cnt + 1;
            end   
        end
        else begin
            add_x_cnt <= 0;
        end
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        add_y_cnt <= 4'b0;
    end
    else begin
        if(cnt>=64&& cnt<=256+T_counting) begin
            if(add_x_cnt==7 && add_y_cnt==7) begin
                add_y_cnt <= 4'b0;
            end
            else if(add_x_cnt==7) begin
                add_y_cnt <= add_y_cnt + 1;
            end
            else begin
                add_y_cnt <= add_y_cnt;
            end
        end
        else begin
            add_y_cnt <= 4'b0;
        end
    end
end
//==================INPUTSAVE===================//
//WV and WQ can sha
always@(posedge clk or negedge rst_n) begin//1
    if(!rst_n) begin
        for(i=0;i<8;i=i+1) begin
            for(j=0;j<8;j=j+1) begin
                save_WQ[i][j] <= 0;
            end
        end
    end
    else begin
        if(in_valid && 0<=cnt && cnt<=63 ) begin
                save_WQ[y_cnt][x_cnt] <= w_Q;
        end
        else begin
            for(i=0;i<8;i=i+1) begin
                for(j=0;j<8;j=j+1) begin
                    save_WQ[i][j] <= save_WQ[i][j];
                end
            end
        end
    end
end
genvar n;
always@(*) begin
    for(i=0;i<8;i=i+1) begin
        for(j=0;j<8;j=j+1) begin
            save_WV[i][j] = save_WV_reg[i][j];
        end
    end
    if(cnt>=128 && cnt<=191) begin
        save_WV[y_cnt][x_cnt] = w_V;
    end
end
generate
for(n=0;n<8;n=n+1) begin
    always@(posedge clk or negedge rst_n) begin//3
        if(!rst_n) begin
            for(j=0;j<8;j=j+1) begin
                save_WV_reg[n][j] <= 0;
            end
        end
        else begin
            for(j=0;j<8;j=j+1) begin
                save_WV_reg[n][j] <= save_WV[n][j];
            end
        end
        
    end
end
endgenerate
always@(*) begin
    for(i=0;i<8;i=i+1) begin
        for(j=0;j<8;j=j+1) begin
            save_WK[i][j] = save_WK_reg[i][j];
        end
    end
    if(cnt>=64 && cnt<=127) begin
        save_WK[y_cnt][x_cnt] = w_K;
    end
end
generate
    for(n=0;n<8;n=n+1) begin
        always@(posedge clk or negedge rst_n) begin//2
            if(!rst_n) begin
                for(i=0;i<8;i=i+1) begin
                    for(j=0;j<8;j=j+1) begin
                        save_WK_reg[n][j] <= 0;
                    end
                end
            end
            else begin
                for(i=0;i<8;i=i+1) begin
                    for(j=0;j<8;j=j+1) begin
                        save_WK_reg[n][j] <= save_WK[n][j];
                    end
                end
            end
        end
    end
endgenerate
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<8;i=i+1) begin
            for(j=0;j<8;j=j+1) begin
                element[i][j] <= 0;
            end
        end
    end
    else begin
        if(cnt==256) begin
            for(i=0;i<8;i=i+1) begin
                for(j=0;j<8;j=j+1) begin
                    element[i][j] <= 0;
                end
            end
        end
        else if(in_valid ) begin
            //element[y_cnt][x_cnt] <=(cnt<=T_counting )? in_data:0;
            if(0<=cnt && cnt<=T_counting) begin
                element[y_cnt][x_cnt] <=in_data;
            end
            else begin
                for(i=0;i<8;i=i+1) begin
                    for(j=0;j<8;j=j+1) begin
                        element[i][j] <= element[i][j];
                    end
                end
            end
        end
        else begin
            for(i=0;i<8;i=i+1) begin
                for(j=0;j<8;j=j+1) begin
                    element[i][j] <= element[i][j];
                end
            end
        end
    end
end
//==================SMALL===================//
always@(*) begin
    for(i=0;i<8;i=i+1) begin
        for(j=0;j<8;j=j+1) begin
            save_K[i][j] = save_K_reg[i][j];
        end
    end
    if(cnt>=128&&cnt<=191) begin
        save_K[add_y_cnt][add_x_cnt] = add_out_eig;
    end
end
generate
for(n=0;n<=7;n=n+1) begin
    always@(posedge clk or negedge rst_n) begin//3
        if(!rst_n) begin
            for(j=0;j<8;j=j+1) begin
                save_K_reg[n][j] <= 0;
            end
        end
        else begin
            for(j=0;j<8;j=j+1) begin
                save_K_reg[n][j] <= save_K[n][j];
            end
        end
    end
end
endgenerate
always@(*) begin
    for(i=0;i<8;i=i+1) begin
        for(j=0;j<8;j=j+1) begin
            save_Q[i][j] = save_Q_reg[i][j];
        end
    end
    if(cnt>=64&&cnt<=127) begin
        save_Q[add_y_cnt][add_x_cnt] = add_out_eig;
    end
end
generate
for(n=0;n<=7;n=n+1) begin
    always@(posedge clk or negedge rst_n) begin//3
        if(!rst_n) begin
            for(j=0;j<8;j=j+1) begin
                save_Q_reg[n][j] <= 0;
            end
        end
        else begin
            for(j=0;j<8;j=j+1) begin
                save_Q_reg[n][j] <= save_Q[n][j];
            end
        end
    end
end
endgenerate
// always@(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         for(i=0;i<8;i=i+1) begin
//             for(j=0;j<8;j=j+1) begin
//                 save_Q[i][j] <= 0;
//             end
//         end
//     end
//     else begin
//         if(cnt>=64&&cnt<=127) begin
//             save_Q[add_y_cnt][add_x_cnt] <= add_out_eig;
//         end
//         else begin
//             for(i=0;i<8;i=i+1) begin
//                 for(j=0;j<8;j=j+1) begin
//                     save_Q[i][j] <= save_Q[i][j];
//                 end
//             end
//         end
//     end
// end
always@(*) begin
    for(i=0;i<8;i=i+1) begin
        for(j=0;j<8;j=j+1) begin
            save_V[i][j] = save_V_reg[i][j];
        end
    end
    if(cnt>=192 &&cnt<=255) begin
        save_V[add_y_cnt][add_x_cnt] = add_out_eig;
    end
end
generate
for(n=0;n<=7;n=n+1) begin
    always@(posedge clk or negedge rst_n) begin//3
        if(!rst_n) begin
            for(j=0;j<8;j=j+1) begin
                save_V_reg[n][j] <= 0;
            end
        end
        else begin
            for(j=0;j<8;j=j+1) begin
                save_V_reg[n][j] <= save_V[n][j];
            end
        end
    end
end
endgenerate
// always@(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         for(i=0;i<8;i=i+1) begin
//             for(j=0;j<8;j=j+1) begin
//                 save_V[i][j] <= 0;
//             end
//         end
//     end
//     else begin
//         if(cnt>=192 &&cnt<=255) begin
//             save_V[add_y_cnt][add_x_cnt] <= add_out_eig;
//         end
//         else begin
//             for(i=0;i<8;i=i+1) begin
//                 for(j=0;j<8;j=j+1) begin
//                     save_V[i][j] <= save_V[i][j];
//                 end
//             end
//         end
//     end
// end
//==================MID===================//
wire [61:0] divided_result = add_bigout_3 / 3;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<8;i=i+1) begin
            for(j=0;j<8;j=j+1) begin
                save_A[i][j] <= 0;
            end
        end
    end
    else begin
        if(cnt>=192&&cnt<=255) begin
            save_A[add_y_cnt][add_x_cnt] <= (divided_result[61]) ? 0 : divided_result;
        end
        else begin
            for(i=0;i<8;i=i+1) begin
                for(j=0;j<8;j=j+1) begin
                    save_A[i][j] <= save_A[i][j];
                end
            end
        end
    end
end
//==================BIG===================//


// reg signed [18:0] mul_mid_in_1[0:7],mul_mid_in_2[0:7];
// wire signed [37:0] mul_mid_out[0:7];


eightmul  m1(.a(mul_in_1[0]),.b(mul_in_2[0]),.out(mul_out[0]));
eightmul  m2(.a(mul_in_1[1]),.b(mul_in_2[1]),.out(mul_out[1]));
eightmul  m3(.a(mul_in_1[2]),.b(mul_in_2[2]),.out(mul_out[2]));
eightmul  m4(.a(mul_in_1[3]),.b(mul_in_2[3]),.out(mul_out[3]));
eightmul  m5(.a(mul_in_1[4]),.b(mul_in_2[4]),.out(mul_out[4]));
eightmul  m6(.a(mul_in_1[5]),.b(mul_in_2[5]),.out(mul_out[5]));
eightmul  m7(.a(mul_in_1[6]),.b(mul_in_2[6]),.out(mul_out[6]));
eightmul  m8(.a(mul_in_1[7]),.b(mul_in_2[7]),.out(mul_out[7]));


always@(*) begin
    if(cnt>=63) begin
        for(i=0;i<=7;i=i+1) begin
            mul_in_1[i] = element[mul_y_cnt][i];
        end
    end
    else begin
        for(i=0;i<=7;i=i+1) begin
            mul_in_1[i] = 0;
        end
    end
end
always@(*) begin
    if(cnt>=63&&cnt<=126) begin
       for(i=0;i<=7;i=i+1) begin
            mul_in_2[i] = save_WQ[i][mul_x_cnt];
        end
    end
    else if(cnt>=127&&cnt<=190) begin
       for(i=0;i<=7;i=i+1) begin
            mul_in_2[i] = save_WK_reg[i][mul_x_cnt];
        end
    end
    else if(cnt>=191 && cnt<=254) begin
       for(i=0;i<=7;i=i+1) begin
            mul_in_2[i] = save_WV_reg[i][mul_x_cnt];
        end
    end
    else begin
        for(i=0;i<=7;i=i+1) begin
            mul_in_2[i] = 0;
        end
    end
end
bigmul b1(.a(mul_big_in_1[0]),.b( mul_big_in_2[0]),.out(mul_big_out[0]));
bigmul b2(.a(mul_big_in_1[1]),.b( mul_big_in_2[1]),.out(mul_big_out[1]));
bigmul b3(.a(mul_big_in_1[2]),.b( mul_big_in_2[2]),.out(mul_big_out[2]));
bigmul b4(.a(mul_big_in_1[3]),.b( mul_big_in_2[3]),.out(mul_big_out[3]));
bigmul b5(.a(mul_big_in_1[4]),.b( mul_big_in_2[4]),.out(mul_big_out[4]));
bigmul b6(.a(mul_big_in_1[5]),.b( mul_big_in_2[5]),.out(mul_big_out[5]));
bigmul b7(.a(mul_big_in_1[6]),.b( mul_big_in_2[6]),.out(mul_big_out[6]));
bigmul b8(.a(mul_big_in_1[7]),.b( mul_big_in_2[7]),.out(mul_big_out[7]));
genvar k;
generate
    for (k = 0; k <= 7; k = k + 1) begin : gen_block1
        always @(*) begin
            if(cnt>=191&&cnt<=254) begin
               // mul_big_in_1[k] = SAVE_Q_flat[mul_y_cnt * 8 + k];
                mul_big_in_1[k] =save_Q[mul_y_cnt][k];
            end
            else if(cnt>=255&&cnt<=319) begin
                //mul_big_in_1[k] = save_A_flat[mul_y_cnt * 8 + k];
                mul_big_in_1[k] = save_A[mul_y_cnt][k];
            end
            else begin
                mul_big_in_1[k] = 0;
            end
        end
    end
endgenerate

generate
    for(k=0;k<=7;k=k+1) begin
        always@(*) begin
            if(cnt>=191&&cnt<=254) begin
               // mul_big_in_2[k] = SAVE_K_flat[mul_y_cnt * 8 + k];
                mul_big_in_2[k] = save_K_reg[mul_x_cnt][k];
            end
            else if(cnt>=255&&cnt<=319) begin
                //mul_big_in_2[k] = SAVE_V_flat[mul_y_cnt * 8 + k];
                mul_big_in_2[k] = save_V[k][mul_x_cnt];
            end
            else begin
                mul_big_in_2[k] = 0;
            end
        end
    end
endgenerate
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<8;i=i+1) begin
            mul_out_reg[i] <= 0;
        end
    end
    else begin
        for(i=0;i<8;i=i+1) begin
            mul_out_reg[i] <= mul_out[i];
        end
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<8;i=i+1) begin
            mul_big_out_reg[i] <= 0;
        end
    end
    else begin
        for(i=0;i<8;i=i+1) begin
            mul_big_out_reg[i] <= mul_big_out[i];
        end
    end
end


eightteenadd a1(.a(add_in_1[0]),.b(add_in_2[0]),.out(add_out[0]));
eightteenadd a2(.a(add_in_1[1]),.b(add_in_2[1]),.out(add_out[1]));
eightteenadd a3(.a(add_in_1[2]),.b(add_in_2[2]),.out(add_out[2]));
eightteenadd a4(.a(add_in_1[3]),.b(add_in_2[3]),.out(add_out[3]));
eightteenadd a5(.a(add_in_sev_1[0]),.b(add_in_sev_2[0]),.out(add_out_sev[0]));
eightteenadd a6(.a(add_in_sev_1[1]),.b(add_in_sev_2[1]),.out(add_out_sev[1]));
eightteenadd a7(.a(add_in_eig_1),.b(add_in_eig_2),.out(add_out_eig));


always@(*) begin
    //if((cnt>=64&&cnt<=127)||(cnt>=128&&cnt<=191)||(cnt>=192 && cnt<=255)) begin
    if(cnt>=64) begin
        add_in_1[0] = mul_out_reg[0];
        add_in_2[0] = mul_out_reg[1];
        add_in_1[1] = mul_out_reg[2];
        add_in_2[1] = mul_out_reg[3];
        add_in_1[2] = mul_out_reg[4];
        add_in_2[2] = mul_out_reg[5];
        add_in_1[3] = mul_out_reg[6];
        add_in_2[3] = mul_out_reg[7];
    end
    else begin
        for(i=0;i<=3;i=i+1) begin
            add_in_1[i] = 0;
            add_in_2[i] = 0;
        end
    end
end
always@(*) begin
   // if((cnt>=64&&cnt<=127)||(cnt>=128&&cnt<=191)||(cnt>=192 && cnt<=255)) begin
    if(cnt>=64) begin
        add_in_sev_1[0] = add_out[0];
        add_in_sev_2[0] = add_out[1];
        add_in_sev_1[1] = add_out[2];
        add_in_sev_2[1] = add_out[3];
    end
    else begin
        add_in_sev_1[0] = 0;
        add_in_sev_2[0] = 0;
        add_in_sev_1[1] = 0;
        add_in_sev_2[1] = 0;
    end
end
always@(*) begin
    //if((cnt>=64&&cnt<=127)||(cnt>=128&&cnt<=191)||(cnt>=192 && cnt<=255)) begin
    if(cnt>=64) begin
        add_in_eig_1 = add_out_sev[0];
        add_in_eig_2 = add_out_sev[1];
    end
    else begin
        add_in_eig_1 = 0;
        add_in_eig_2 = 0;
    end
end

bigadd_3 ba1(.a(add_big_in_1[0]),.b(add_big_in_2[0]),.out(add_big_out[0]));
bigadd_3 ba2(.a(add_big_in_1[1]),.b(add_big_in_2[1]),.out(add_big_out[1]));
bigadd_3 ba3(.a(add_big_in_1[2]),.b(add_big_in_2[2]),.out(add_big_out[2]));
bigadd_3 ba4(.a(add_big_in_1[3]),.b(add_big_in_2[3]),.out(add_big_out[3]));
bigadd_3 ba5(.a(add_bigadd_2_1[0]),.b(add_bigadd_2_2[0]),.out(add_bigout_2[0]));
bigadd_3 ba6(.a(add_bigadd_2_1[1]),.b(add_bigadd_2_2[1]),.out(add_bigout_2[1]));
bigadd_3 ba7(.a(add_bigadd_3_1),.b(add_bigadd_3_2),.out(add_bigout_3));


always@(*) begin
    if(cnt>=192&&cnt<=320) begin
        add_big_in_1[0] = mul_big_out_reg[0];
        add_big_in_2[0] = mul_big_out_reg[1];
        add_big_in_1[1] = mul_big_out_reg[2];
        add_big_in_2[1] = mul_big_out_reg[3];
        add_big_in_1[2] = mul_big_out_reg[4];
        add_big_in_2[2] = mul_big_out_reg[5];
        add_big_in_1[3] = mul_big_out_reg[6];
        add_big_in_2[3] = mul_big_out_reg[7];
    end
    else begin
        for(i=0;i<=3;i=i+1) begin
            add_big_in_1[i] = 0;
            add_big_in_2[i] = 0;
        end
    end
end
always@(*) begin
    if(cnt>=192&&cnt<=320) begin
        add_bigadd_2_1[0] = add_big_out[0];
        add_bigadd_2_2[0] = add_big_out[1];
        add_bigadd_2_1[1] = add_big_out[2];
        add_bigadd_2_2[1] = add_big_out[3];
    end
    else begin
        add_bigadd_2_1[0] = 0;
        add_bigadd_2_2[0] = 0;
        add_bigadd_2_1[1] = 0;
        add_bigadd_2_2[1] = 0;
    end
end
always@(*) begin
    if(cnt>=192&&cnt<=320) begin
        add_bigadd_3_1 = add_bigout_2[0];
        add_bigadd_3_2 = add_bigout_2[1];
    end
    else begin
        add_bigadd_3_1 = 0;
        add_bigadd_3_2 = 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 1'b0;
        out_data <= 64'b0;
    end
    else begin
        if(cnt>=256&&cnt<=256+T_counting) begin
            out_valid <= 1'b1;
            out_data <= add_bigout_3;
        end
        else begin
            out_valid <= 1'b0;
            out_data <= 64'b0;
        end
    end
end
endmodule

module eightmul  (a,b,out);
    input signed [7:0] a,b;
    output signed [18:0] out;
    assign out = a*b;
endmodule


module bigmul  (a,b,out);
    input signed [39:0] a;
    input signed [18:0] b;
    output signed [58:0] out;
    assign out = a*b;
endmodule

module eightteenadd (a,b,out);
    input signed [18:0] a,b;
    output signed [18:0] out;
    assign out = a+b;
endmodule

module bigadd_3 (a,b,out);
    input signed [58:0] a,b;
    output signed [61:0] out;
    assign out = a+b;
endmodule
