//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/10
//		Version		: v1.0
//   	File Name   : HAMMING_IP.v
//   	Module Name : HAMMING_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module HAMMING_IP #(parameter IP_BIT =8) (
    // Input signals
    IN_code,
    // Output signals
    OUT_code
);

// ===============================================================
// Input & Output
// ===============================================================
//input [IP_BIT+4-1:0]  IN_code;
input [IP_BIT+4-1:0]  IN_code;
output reg [IP_BIT-1:0] OUT_code;

// ===============================================================
// Design
// ===============================================================
reg [0:IP_BIT+4-1]  IN_code_temp;
reg [0:IP_BIT+4-1] save_code;

wire [4:0] change_which_bit;
wire [3:0]temp_result[0:IP_BIT+4-1];
genvar i;
integer j,k;
always@(*) begin
    for(j=0;j<=IP_BIT+4-1;j=j+1) begin
        IN_code_temp[j] = IN_code[IP_BIT+4-1-j];
    end
end
generate
for(i=0;i<=IP_BIT+4-1;i=i+1) begin :loop_1
    wire [4:0]which_bit_one;
    assign which_bit_one = (IN_code_temp[i])?(i+1):0;
    if(i==0) begin
        assign temp_result[i] = which_bit_one;
    end
    else begin
        assign temp_result[i] = which_bit_one ^ temp_result[i-1];
    end
end

endgenerate
assign change_which_bit = temp_result[IP_BIT+4-1];

always@(*) begin
    if(change_which_bit!=0) begin
        for(j=0;j<=IP_BIT+4-1;j=j+1) begin
            save_code[j] = IN_code_temp[j];
        end
        save_code[change_which_bit-1] = ~IN_code_temp[change_which_bit-1];
    end
    else begin
        for(j=0;j<=IP_BIT+4-1;j=j+1) begin
            save_code[j] = IN_code_temp[j];
        end
    end
end


always@(*) begin
    for(k=IP_BIT-1;k>=0;k=k-1) begin
        if(k==IP_BIT-1) begin
             OUT_code[IP_BIT-1] = save_code[2];
        end
        else if(k==IP_BIT-2) begin
             OUT_code[IP_BIT-2] = save_code[4];
        end
        else if(k==IP_BIT-3) begin
             OUT_code[IP_BIT-3] = save_code[5];
        end
        else if (k==IP_BIT-4) begin
             OUT_code[IP_BIT-4] = save_code[6];
        end
        else begin
             OUT_code[k] = save_code[IP_BIT+4-1-k];
        end
    end
end


endmodule
