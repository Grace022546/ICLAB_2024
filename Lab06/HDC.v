//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/9
//		Version		: v1.0
//   	File Name   : MDC.v
//   	Module Name : MDC
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "HAMMING_IP.v"
//synopsys translate_on

module MDC(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_data, 
	in_mode,
    // Output signals
    out_valid, 
	out_data
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [8:0] in_mode;
input [14:0] in_data;



integer i,j;

wire signed [4:0] in_mode_decode;
wire signed [10:0] in_data_decode;
reg  signed [10:0] in_data_decode_reg[0:7];

output reg out_valid;
output reg [206:0] out_data;

HAMMING_IP #(.IP_BIT(5)) I_HAMMING_IP1(.IN_code(in_mode), .OUT_code(in_mode_decode)); //9to5
HAMMING_IP #(.IP_BIT(11)) I_HAMMING_IP2(.IN_code(in_data), .OUT_code(in_data_decode)); //15to11

reg [4:0] cnt;
//small mul
reg signed [10:0]small_mul_1_in1,small_mul_1_in2,small_mul_2_in1,small_mul_2_in2;//two small mul
reg signed [21:0]small_mul_1_out,small_mul_2_out,small_out;//one small minus
reg signed [21:0]small_out_reg;
// //small result
// reg signed [22:0]two_result[0:4];
// reg signed [22:0]two_result_reg[0:4];
//save 2x2 result
reg signed [22:0]save_2x2_result[0:9];
reg signed [22:0]save_2x2_result_reg[0:9];
//mid mul
reg signed [22:0]mid_mul_1_in1,mid_mul_2_in1;
reg signed [22:0]mid_mul_1_in2,mid_mul_2_in2;
reg signed [31:0]mid_mul_1_out,mid_mul_2_out;
// reg signed [31:0]mid_mul_1_out_reg,mid_mul_2_out_reg;
//mid add
reg signed [32:0] mid_add_in1,mid_add_in2;
reg signed [33:0] mid_add_out;
reg signed [33:0] mid_add_out_reg;
reg signed [34:0]three_result[1:4];//mid_add_out_reg
reg signed [34:0]three_result_reg[1:4];//mid_add_out_reg
//big mul
reg signed [10:0] big_mul_in1;
reg signed [34:0] big_mul_in2;
reg signed [43:0] big_mul_out;
//big add
reg signed [45:0] big_add_in1,big_add_in2;
reg signed [45:0] big_add_out;
reg signed [45:0] big_add_out_reg;
reg signed [45:0] four_result;
reg signed [45:0] four_result_reg;
//===============================================================
reg invalidreg;
reg [1:0] in_mode_reg;// store the in_mode
//---------------------------------------------------------------//

// always@(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         invalidreg <= 1'b0;
//     end
//     else begin
//         invalidreg <= in_valid;
//     end
// end
always@(posedge clk) begin
     begin
        invalidreg <= in_valid;
    end
end
always @(posedge clk) begin
    if(!in_valid && !invalidreg) begin
        for(i=0;i<8;i=i+1) begin
            in_data_decode_reg[i] <= 0;
        end
    end
    else if(in_valid  )begin
        for(i=0;i<8;i=i+1) begin
            in_data_decode_reg[i] <= in_data_decode_reg[i+1];
        end
        in_data_decode_reg[7] <= in_data_decode;
    end
    else begin
        for(i=0;i<8;i=i+1) begin
            in_data_decode_reg[i] <= in_data_decode_reg[i];
        end
    end
end
// always @(posedge clk or negedge rst_n)begin 
//     if(!rst_n) begin
//         in_mode_reg <= 2'd0;
//     end
//     else begin
//     if(in_valid && !invalidreg)begin
//         if(in_mode_decode == 5'b00100)begin
//             in_mode_reg <= 2'd1;
//         end
//         else if(in_mode_decode == 5'b00110)begin 
//             in_mode_reg <= 2'd2;
//         end
//         else begin
//             in_mode_reg <= 2'd3;
//         end
//     end
//     else if(invalidreg)begin
//         in_mode_reg <= in_mode_reg;
//     end
//     else begin
//         in_mode_reg <= 2'd0;
//     end
//     end
// end
always @(posedge clk)begin 
    if(in_valid && !invalidreg)begin
        if(in_mode_decode == 5'b00100)begin
            in_mode_reg <= 2'd1;
        end
        else if(in_mode_decode == 5'b00110)begin 
            in_mode_reg <= 2'd2;
        end
        else begin
            in_mode_reg <= 2'd3;
        end
    end
    else if(invalidreg)begin
        in_mode_reg <= in_mode_reg;
    end
    else begin
        in_mode_reg <= 2'd0;
    end
    
end
always @(posedge clk or negedge rst_n)begin 
    if(!rst_n) begin
        cnt <= 0;
    end
    else begin
    if(in_valid||cnt==5'd16)begin
        cnt <= cnt + 1;
    end
    else begin
        cnt <= 0;
    end
    end
end
always @(posedge clk ) begin
    if(!invalidreg) begin
        mid_add_out_reg <= 0;
    end
    else begin
        mid_add_out_reg <= mid_add_out;
    end
end
always @(posedge clk ) begin
    if(!invalidreg) begin
        big_add_out_reg <= 0;
    end
    else begin
        big_add_out_reg <= big_add_out;
    end
end
always @(posedge clk ) begin
    if(!invalidreg) begin
        for(i=1;i<=4;i=i+1) begin
            three_result_reg[i] <= 0;
        end
    end
    else begin
        for(i=1;i<=4;i=i+1) begin
            three_result_reg[i] <= three_result[i];
        end
    end
end




////////////////////////////////////////////////////////////////////////////
// always @(*) begin
//     if(cnt==6||cnt==7||cnt==8||cnt==10||cnt==11||cnt==12 ) begin
//         small_mul_1_in1 = in_data_decode_reg[2];//0
//         small_mul_1_in2 = in_data_decode_reg[7];//5
//         small_mul_2_in1 = in_data_decode_reg[3];//1
//         small_mul_2_in2 = in_data_decode_reg[6];//4
//     end
//     else if(in_mode_reg==2'd1 &&(cnt==14||cnt==15||cnt==16)) begin
//         small_mul_1_in1 = in_data_decode_reg[2];//0
//         small_mul_1_in2 = in_data_decode_reg[7];//5
//         small_mul_2_in1 = in_data_decode_reg[3];//1
//         small_mul_2_in2 = in_data_decode_reg[6];//4
//     end
//     else if(in_mode_reg==2'd3 &&(cnt==9)) begin
//         small_mul_1_in1 = in_data_decode_reg[0];//0
//         small_mul_1_in2 = in_data_decode_reg[6];//5
//         small_mul_2_in1 = in_data_decode_reg[2];//1
//         small_mul_2_in2 = in_data_decode_reg[4];//4
//     end
//     else begin
//         small_mul_1_in1 = 0;
//         small_mul_1_in2 = 0;
//         small_mul_2_in1 = 0;
//         small_mul_2_in2 = 0;
//     end
// end
always @(*) begin
    if(in_mode_reg==2'd3 &&(cnt==9)) begin
        small_mul_1_in1 = in_data_decode_reg[0];//0
        small_mul_1_in2 = in_data_decode_reg[6];//5
        small_mul_2_in1 = in_data_decode_reg[2];//1
        small_mul_2_in2 = in_data_decode_reg[4];//4
    end
    else begin
        small_mul_1_in1 = in_data_decode_reg[2];//0
        small_mul_1_in2 = in_data_decode_reg[7];//5
        small_mul_2_in1 = in_data_decode_reg[3];//1
        small_mul_2_in2 = in_data_decode_reg[6];//4
    end
end

always@(*) begin
    small_mul_1_out = small_mul_1_in1*small_mul_1_in2;
    small_mul_2_out = small_mul_2_in1*small_mul_2_in2;
    small_out = small_mul_1_out-small_mul_2_out;
end
// always@(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         small_out_reg <='d0;
//     end
//     else begin
//          if(invalidreg) begin
//             small_out_reg <=small_out;
//         end
//         else begin
//             small_out_reg <= 'd0;
//         end
//     end
// end
////////////////////////////////////////////////////////////////////////////

always @(*) begin
    case (in_mode_reg)
        2'd2 :begin/////////////////////////////////
            case(cnt)
                5'd7,5'd8,5'd11,5'd12: begin
                    mid_mul_1_in1 = in_data_decode_reg[1];
                    mid_mul_1_in2 = in_data_decode_reg[7];
                    mid_mul_2_in1 = in_data_decode_reg[3];
                    mid_mul_2_in2 = in_data_decode_reg[5];
                end
                5'd9: begin
                    mid_mul_1_in1 = in_data_decode_reg[7];
                    mid_mul_1_in2 = save_2x2_result_reg[1];
                    mid_mul_2_in1 = 0;
                    mid_mul_2_in2 = 0;
                end
                5'd10: begin
                    mid_mul_1_in1 = in_data_decode_reg[7];
                    mid_mul_1_in2 = save_2x2_result_reg[0];
                    mid_mul_2_in1 = in_data_decode_reg[7];
                    mid_mul_2_in2 = save_2x2_result_reg[4];
                end
                5'd13: begin
                    mid_mul_1_in1 = in_data_decode_reg[6];
                    mid_mul_1_in2 = save_2x2_result_reg[1];
                    mid_mul_2_in1 = in_data_decode_reg[7];
                    mid_mul_2_in2 = save_2x2_result_reg[8];
                end
                5'd14: begin
                    mid_mul_1_in1 = in_data_decode_reg[7];//13//for4
                    mid_mul_1_in2 = save_2x2_result_reg[9];
                    mid_mul_2_in1 = in_data_decode_reg[7];//13//for3
                    mid_mul_2_in2 = save_2x2_result_reg[7];
                end
                5'd15: begin
                    mid_mul_1_in1 = in_data_decode_reg[7];//5
                    mid_mul_1_in2 = save_2x2_result_reg[5];
                    mid_mul_2_in1 = in_data_decode_reg[7];//7
                    mid_mul_2_in2 = save_2x2_result_reg[6];
                end
                5'd16: begin
                    mid_mul_1_in1 = in_data_decode_reg[7];//yellow//14//for3
                    mid_mul_1_in2 = save_2x2_result_reg[8];
                    mid_mul_2_in1 = 0;
                    mid_mul_2_in2 = 0;
                end
                default: begin
                    mid_mul_1_in1 = 0;
                    mid_mul_1_in2 = 0;
                    mid_mul_2_in1 = 0;
                    mid_mul_2_in2 = 0;
                    
                end
            endcase
        end
        2'd3 :begin
            case(cnt)
                5'd7: begin
                    mid_mul_1_in1 = in_data_decode_reg[1];
                    mid_mul_1_in2 = in_data_decode_reg[7];
                    mid_mul_2_in1 = in_data_decode_reg[3];
                    mid_mul_2_in2 = in_data_decode_reg[5];
                end
                5'd8: begin
                    mid_mul_1_in1 = in_data_decode_reg[0];
                    mid_mul_1_in2 = in_data_decode_reg[7];
                    mid_mul_2_in1 = in_data_decode_reg[3];
                    mid_mul_2_in2 = in_data_decode_reg[4];
                end
                5'd9: begin
                    mid_mul_1_in1 = in_data_decode_reg[7];
                    mid_mul_1_in2 = save_2x2_result_reg[0];
                    // mid_mul_2_in1 = in_data_decode_reg[7];
                    // mid_mul_2_in2 = small_out;
                    mid_mul_2_in1 = 0;
                    mid_mul_2_in2 = 0;
                end
                5'd10: begin
                    mid_mul_1_in1 = in_data_decode_reg[7];//9
                    mid_mul_1_in2 = save_2x2_result_reg[0];
                    mid_mul_2_in1 = in_data_decode_reg[7];
                    mid_mul_2_in2 = save_2x2_result_reg[2];
                end
                5'd11: begin
                    mid_mul_1_in1 = in_data_decode_reg[7];//9
                    mid_mul_1_in2 = save_2x2_result_reg[1];
                    mid_mul_2_in1 = in_data_decode_reg[7];//10
                    mid_mul_2_in2 = save_2x2_result_reg[2];
                end
                5'd12: begin
                    mid_mul_1_in1 = in_data_decode_reg[7];//10
                    mid_mul_1_in2 = save_2x2_result_reg[3];
                    mid_mul_2_in1 = in_data_decode_reg[7];//9
                    mid_mul_2_in2 = save_2x2_result_reg[4];
                end
                5'd13: begin
                    mid_mul_1_in1 = in_data_decode_reg[3];//10//notchange?//11
                    mid_mul_1_in2 = save_2x2_result_reg[3];
                    mid_mul_2_in1 = in_data_decode_reg[6];//11//10
                    mid_mul_2_in2 = save_2x2_result_reg[5];
                end
                5'd14: begin
                    mid_mul_1_in1 = in_data_decode_reg[3];//8
                    mid_mul_1_in2 = save_2x2_result_reg[4];
                    mid_mul_2_in1 = in_data_decode_reg[2];
                    mid_mul_2_in2 = save_2x2_result_reg[1];
                end
                5'd15: begin
                    mid_mul_1_in1 = in_data_decode_reg[3];//9
                    mid_mul_1_in2 = save_2x2_result_reg[5];
                    mid_mul_2_in1 = 0;
                    mid_mul_2_in2 = 0;
                end
               
                default: begin
                    mid_mul_1_in1 = 0;
                    mid_mul_1_in2 = 0;
                    mid_mul_2_in1 = 0;
                    mid_mul_2_in2 = 0;
                end
            endcase
        end
        default: begin
            mid_mul_1_in1 = 0;
            mid_mul_1_in2 = 0;
            mid_mul_2_in1 = 0;
            mid_mul_2_in2 = 0;
        end
    endcase
end
//additional two mult
always@(*) begin
    mid_mul_1_out = mid_mul_1_in1*mid_mul_1_in2;
    mid_mul_2_out = mid_mul_2_in1*mid_mul_2_in2;  
end

// always@(posedge clk ) begin
//          if(invalidreg) begin
//             mid_mul_1_out_reg <= mid_mul_1_out;
//             mid_mul_2_out_reg <= mid_mul_2_out;
//         end
//         else begin
//             mid_mul_1_out_reg <= 0;
//             mid_mul_2_out_reg <= 0;
//         end
//     // end
// end


always@(*) begin
    if(in_mode_reg==2'd2) begin
        case (cnt)
            5'd11: begin
                    big_mul_in1 = in_data_decode_reg[7];
                    big_mul_in2 = save_2x2_result_reg[2];
            end
            5'd12: begin
                    big_mul_in1 = in_data_decode_reg[6];
                    big_mul_in2 = save_2x2_result_reg[3];
            end
            default: begin
                big_mul_in1 = 11'd0;
                big_mul_in2 = 35'd0;
            end
        endcase
    end
    else if(in_mode_reg==2'd3) begin
        case(cnt)
            5'd13:begin
                big_mul_in1 = in_data_decode_reg[7];
                big_mul_in2 = three_result_reg[1];
            end
            5'd14:begin
                big_mul_in1 = in_data_decode_reg[7];
                big_mul_in2 = three_result_reg[2];
            end
            5'd15:begin
                big_mul_in1 = in_data_decode_reg[7];
                big_mul_in2 = three_result_reg[3];
            end
            5'd16:begin
                big_mul_in1 = in_data_decode_reg[7];
                big_mul_in2 = three_result_reg[4];
            end
            default: begin
                big_mul_in1 = 11'd0;
                big_mul_in2 = 35'd0;
            end
        endcase
    end
    else  begin
        big_mul_in1 = 11'd0;
        big_mul_in2 = 35'd0;
    end
end
always@(*) begin
    big_mul_out = big_mul_in1*big_mul_in2;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        four_result_reg <= 49'd0;
    end
    else begin
        if(invalidreg) begin
                four_result_reg <= four_result;
            end
            else begin
                four_result_reg <= 49'd0;
            end
    end
end
always@(*) begin
    four_result = four_result_reg;
    if(in_mode_reg==2'd3&& cnt>=5'd13) begin
        four_result = big_add_out;
    end
end
always@(*) begin//put small_out_reg
        for(i=0;i<10;i=i+1) begin
                save_2x2_result[i] = save_2x2_result_reg[i];
        end
    case(in_mode_reg) 
        2'd1: begin
            case(cnt)
                5'd6: begin
                   save_2x2_result[0] = small_out;
                end
                5'd7: begin
                   save_2x2_result[1] = small_out;
                end
                5'd8: begin
                    save_2x2_result[2] = small_out;
                end
                5'd10: begin
                    save_2x2_result[3] = small_out;
                end
                5'd11: begin
                    save_2x2_result[4] = small_out;
                end
                5'd12: begin
                    save_2x2_result[5] = small_out;
                end
                5'd14: begin
                    save_2x2_result[6] = small_out;
                end
                5'd15: begin
                    save_2x2_result[7] = small_out;
                end
                5'd16: begin
                    save_2x2_result[8] = small_out;
                end
            endcase
        end
        2'd2: begin
            case(cnt)
                5'd6: begin
                    save_2x2_result[2] = small_out;
                end
                5'd7: begin
                    save_2x2_result[1] = small_out;
                    save_2x2_result[0] = mid_add_out;
                end
                5'd8: begin
                    save_2x2_result[4] = small_out;
                    save_2x2_result[3] = mid_add_out;
                end
                // 5'd9: begin
                //     // save_2x2_result[0] = save_2x2_result_reg[1];
                //     // save_2x2_result[1] = save_2x2_result_reg[2];
                //     // save_2x2_result[2] = save_2x2_result_reg[3];
                //     // save_2x2_result[3] = save_2x2_result_reg[4];
                // end
                5'd10: begin
                    save_2x2_result[5] = small_out;
                end
                5'd11: begin
                    save_2x2_result[8] = small_out;
                    save_2x2_result[9] = mid_add_out;
                end
                5'd12: begin
                    save_2x2_result[7] = small_out;
                    save_2x2_result[6] = mid_add_out;
                end
            endcase
        end
        2'd3: begin
            case (cnt)
                5'd6: begin
                    save_2x2_result[5] = small_out;
                end
                5'd7: begin
                    save_2x2_result[3] = small_out;
                    save_2x2_result[4] = mid_add_out;
                end
                5'd8: begin
                    save_2x2_result[0] = small_out;
                    save_2x2_result[2] = mid_add_out;
                end
                5'd9: begin
                    save_2x2_result[1] = small_out;
                end
            endcase
        end
    endcase
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<10;i=i+1) begin
            save_2x2_result_reg[i] <=0;
        end
    end
    else begin
        if(invalidreg) begin
            for(i=0;i<10;i=i+1) begin
                save_2x2_result_reg[i] <= save_2x2_result[i];
            end
        end
        else begin
            for(i=0;i<10;i=i+1) begin
                save_2x2_result_reg[i] <= 0;
            end
        end
    end
end
///////////////////////////////////////////////////////////////////////////////////////////////////////////


always @(*) begin
    for(i=1;i<=4;i=i+1) begin
        three_result[i] = three_result_reg[i];
    end
    if(in_mode_reg==2'd2)begin
            case (cnt)
                5'd9: begin
                   three_result[1] = mid_add_out;
                end
                5'd10: begin
                    three_result[1] = mid_add_out;
                    three_result[2] = big_add_out;
                end
                5'd11: begin
                    three_result[1] = big_add_out;
                end
                5'd12: begin
                    three_result[2] = big_add_out;
                end
                5'd13: begin
                    three_result[2] = mid_add_out;
                    three_result[3] = big_add_out;
                end
                5'd14: begin
                    three_result[3] = mid_add_out;
                    three_result[4] = big_add_out;
                end
                5'd15: begin
                    three_result[3] = mid_add_out;
                    three_result[4] = big_add_out;
                end
                5'd16: begin
                    three_result[4] = mid_add_out;
                end
            endcase
        end
    else if(in_mode_reg==2'd3) begin
        case (cnt)
            5'd9: begin
                three_result[2] = mid_add_out;
                
            end
            5'd10: begin
                three_result[1] = mid_add_out;
                three_result[3] = big_add_out;
    
            end
            5'd11: begin
                three_result[1] = mid_add_out;
                three_result[2] = big_add_out;
            end
            5'd12: begin
                three_result[1] = mid_add_out;
                three_result[2] = big_add_out;
            end
            5'd13: begin
                three_result[4] = mid_add_out;
                three_result[3] = three_result_reg[3]+mid_mul_2_out;
            end
            5'd14: begin
                three_result[4] = mid_add_out;
                three_result[3] = three_result_reg[3]+mid_mul_2_out;
            end
            5'd15: begin
                three_result[4] = mid_add_out;
            end
        endcase
     end
end

always@(*) begin

    mid_add_in1  = 0;
    mid_add_in2  = 0;
    if(in_mode_reg==2'd2) begin
            case (cnt)
                5'd7,5'd8,5'd11,5'd12: begin
                    mid_add_in1 = mid_mul_1_out;
                    mid_add_in2 = $signed(~mid_mul_2_out+1'b1);
                end
                5'd9: begin
                    mid_add_in1 = three_result_reg[1];
                    mid_add_in2 = mid_mul_1_out;
                end
                5'd10: begin
                    mid_add_in1 = three_result_reg[1];
                    mid_add_in2 = $signed(~mid_mul_1_out+1'b1);
                end
                5'd13: begin
                    mid_add_in1 = three_result_reg[2];
                    mid_add_in2 = mid_mul_1_out;
                end
                5'd14: begin
                    mid_add_in1 = three_result_reg[3];
                    mid_add_in2 = $signed(~mid_mul_1_out+1'b1);
                end
                5'd15: begin
                    mid_add_in1 = three_result_reg[3];
                    mid_add_in2 = mid_mul_1_out;
                end
                5'd16: begin
                    mid_add_in1 = three_result_reg[4];
                    mid_add_in2 = mid_mul_1_out;
                end
            endcase
        end
    else if(in_mode_reg==2'd3)begin
        case (cnt)
            5'd7,5'd8: begin
                mid_add_in1 = mid_mul_1_out;
                mid_add_in2 = $signed(~mid_mul_2_out+1'b1);
            end
            5'd9: begin
                mid_add_in1 = three_result_reg[2];
                mid_add_in2 = mid_mul_1_out;
            end
            5'd10: begin
                mid_add_in1 = three_result_reg[1];
                mid_add_in2 = mid_mul_1_out;
            end
            5'd11: begin
                mid_add_in1 = three_result_reg[1];
                mid_add_in2 = $signed(~mid_mul_1_out+1'b1);
            end
            5'd12: begin
                mid_add_in1 = three_result_reg[1];
                mid_add_in2 = mid_mul_1_out;
            end
            5'd13: begin
                mid_add_in1 = three_result_reg[4];
                mid_add_in2 = mid_mul_1_out;
            end
            5'd14: begin
                mid_add_in1 = three_result_reg[4];
                mid_add_in2 = $signed(~mid_mul_1_out+1'b1);
            end
            5'd15: begin
                mid_add_in1 = three_result_reg[4];
                mid_add_in2 = mid_mul_1_out;
            end
        endcase
        end
end
always@(*) begin
    big_add_in1 = 0;
    big_add_in2 = 0;
    if (in_mode_reg==2'd2) begin
            case (cnt)
                5'd10: begin
                    big_add_in1 = three_result_reg[2];
                    big_add_in2 = mid_mul_2_out;
                end
                5'd11: begin
                    big_add_in1 = three_result_reg[1];
                    big_add_in2 = big_mul_out;
                end
                5'd12: begin
                    big_add_in1 = three_result_reg[2];
                    big_add_in2 = $signed(~big_mul_out+1'b1);
                end
                5'd13: begin
                    big_add_in1 = three_result_reg[3];
                    big_add_in2 = mid_mul_2_out;
                end
                5'd14: begin
                    big_add_in1 = three_result_reg[4];
                    big_add_in2 = mid_mul_2_out;
                end
                5'd15: begin
                    big_add_in1 = three_result_reg[4];
                    big_add_in2 = $signed(~mid_mul_2_out+1'b1);
                end
            endcase
    end
    else if(in_mode_reg==2'd3)begin
        case (cnt)
            // 5'd9: begin
            //     big_add_in1 = three_result_reg[3];
            //     big_add_in2 = mid_mul_2_out;
            // end
            5'd10: begin
                big_add_in1 = three_result_reg[3];
                big_add_in2 = $signed(~mid_mul_2_out+1'b1);
            end
            5'd11: begin
                big_add_in1 = three_result_reg[2];
                big_add_in2 = $signed(~mid_mul_2_out+1'b1);
            end
            5'd12: begin
                big_add_in1 = three_result_reg[2];
                big_add_in2 = mid_mul_2_out;
            end
            // 5'd13: begin
            //     big_add_in1 = three_result_reg[3];
            //     big_add_in2 = mid_mul_2_out;
            // end
            5'd13,5'd15: begin
                big_add_in1 = four_result_reg;
                big_add_in2 = $signed(~big_mul_out+1'b1);
            end
             5'd14,5'd16: begin
                big_add_in1 = four_result_reg;
                big_add_in2 = big_mul_out;
            end
            default: begin
                big_add_in1 = 0;
                big_add_in2 = 0;
            end
        endcase
    end
end
always@(*) begin
    mid_add_out = mid_add_in1 + mid_add_in2;
    big_add_out = big_add_in1 + big_add_in2;
end

//////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////
always@(*) begin
    if(out_valid) begin//change to cnt==5'd17
        //out_valid = 1'b1;
        case (in_mode_reg)
            2'd1: begin
                out_data = {save_2x2_result_reg[0],save_2x2_result_reg[1],save_2x2_result_reg[2],save_2x2_result_reg[3],save_2x2_result_reg[4],save_2x2_result_reg[5],save_2x2_result_reg[6],save_2x2_result_reg[7],save_2x2_result_reg[8]};
             //   out_data = {two_result[0][21],two_result[0],two_result[1][21],two_result[1],two_result[2][21],two_result[2],two_result[3][21],two_result[3],two_result[4][21],two_result[4],save_2x2_result[0],save_2x2_result[1],save_2x2_result[2],save_2x2_result[3]};
            // out_data = {two_result[0],two_result[1],two_result[2],two_result[3],two_result[4],two_result[5],two_result[6],two_result[7],two_result[8]};
            end
            2'd2: begin
                out_data = {3'b000,{16{three_result_reg[1][34]}},three_result_reg[1],{16{three_result_reg[2][34]}},three_result_reg[2],{16{three_result_reg[3][34]}},three_result_reg[3],{16{three_result_reg[4][34]}},three_result_reg[4]};
            end
            2'd3: begin
             //   out_data = four_result_reg;
                out_data = {{{161{four_result_reg[45]}}}, four_result_reg};//cycletime15//area280213
            end
            default: out_data = 0;
        endcase
        
    end
    else begin
       // out_valid = 1'b0;
        out_data = 0;
    end
end
always @(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        out_valid <= 0;
    end
    else if(cnt == 5'd16)begin
        out_valid <= 1;
    end
    else begin
        out_valid <= 0;
    end
end
endmodule
