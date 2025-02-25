module ISP(
    // Input Signals
    input clk,
    input rst_n,
    input in_valid,
    input [3:0] in_pic_no,
    input  [1:0]  in_mode,
    input [1:0] in_ratio_mode,

    // Output Signals
    output reg out_valid,
    output reg[7:0] out_data,
    
    // DRAM Signals
    // axi write address channel
    // src master
    output [3:0]  awid_s_inf,
    output  [31:0] awaddr_s_inf,
    output [2:0]  awsize_s_inf,
    output [1:0]  awburst_s_inf,
    output [7:0]  awlen_s_inf,
    output        awvalid_s_inf,
    // src slave
    input         awready_s_inf,
    // -----------------------------
  
    // axi write data channel 
    // src master
    output reg [127:0] wdata_s_inf,
    output         wlast_s_inf,
    output         wvalid_s_inf,
    // src slave
    input          wready_s_inf,
  
    // axi write response channel 
    // src slave
    input [3:0]    bid_s_inf,
    input [1:0]    bresp_s_inf,//00only
    input          bvalid_s_inf,
    // src master 
    output         bready_s_inf,
    // -----------------------------
  
    // axi read address channel 
    // src master
    output [3:0]   arid_s_inf,
    output reg [31:0]  araddr_s_inf,
    output [7:0]   arlen_s_inf,
    output [2:0]   arsize_s_inf,
    output [1:0]   arburst_s_inf,
    output    reg     arvalid_s_inf,
    // src slave
    input          arready_s_inf,
    // -----------------------------
  
    // axi read data channel 
    // slave
    input [3:0]    rid_s_inf,
    input [127:0]  rdata_s_inf,
    input [1:0]    rresp_s_inf,
    input          rlast_s_inf,
    input          rvalid_s_inf,
    // master
    output      reg   rready_s_inf
    
);

//=================================convert variable================================//
//============================DRAM READ================================//
reg [3:0]  read_id_from_ISP;
// reg [31:0] read_addr_from_ISP;
// reg [7:0] pattern_cnt;

reg read_valid_from_ISP;
wire read_ready_from_DRAM;
assign arid_s_inf = 0;
// assign araddr_s_inf = read_addr_from_ISP;
assign arlen_s_inf =191;//2*6*3*16k
assign arsize_s_inf = 3'b100;//fixed
assign arburst_s_inf = 2'b01;//fixed
// assign arvalid_s_inf = read_valid_from_ISP;
assign read_ready_from_DRAM = arready_s_inf;
// reg [3:0] read_id_from_dram;
// reg [127:0] read_data_from_dram;
// reg [1:0] read_resp_from_dram;
// reg read_last_from_dram;
reg read_valid_from_dram;
reg read_data_ready_from_ISP;

// assign rready_s_inf = read_data_ready_from_ISP;
always@(*) begin
    // read_id_from_dram = rid_s_inf;
    // read_data_from_dram = rdata_s_inf;
    // read_resp_from_dram = rresp_s_inf ;//2'b00
    // read_last_from_dram = rlast_s_inf;
    read_valid_from_dram = rvalid_s_inf;
end
//============================DRAM WRITE================================//
//reg [3:0]  write_id_from_ISP;
// reg [31:0] write_addr_from_ISP;
reg write_addr_valid_from_ISP;
// reg write_addr_ready_from_DRAM;
reg write_data_ready_from_DRAM;
reg write_data_ready_from_ISP;
reg [3:0] write_id_from_dram;
// reg [127:0] write_data_from_ISP;
// reg [1:0] write_resp_from_dram;
reg write_last_from_ISP;
// reg write_valid_from_dram;
// reg write_data_resp_from_ISP;
assign awid_s_inf = 0;
assign awsize_s_inf = 3'b100;
assign awburst_s_inf = 2'b01;
// assign awaddr_s_inf = araddr_s_inf;
assign awlen_s_inf =191;//2*6*3*16
assign awvalid_s_inf = write_addr_valid_from_ISP;
assign wvalid_s_inf = 1;
assign wlast_s_inf = write_last_from_ISP;
// assign wdata_s_inf = write_data_from_ISP;
// assign bready_s_inf = write_data_resp_from_ISP;
assign bready_s_inf = 1;
always@(*) begin
    write_id_from_dram = bid_s_inf;
    // write_resp_from_dram = bresp_s_inf ;//2'b00
    // write_valid_from_dram = bvalid_s_inf;
    // write_addr_ready_from_DRAM = awready_s_inf;
    write_data_ready_from_DRAM = wready_s_inf;
end

//================OUTPUT VARIABLE============================//
reg out_valid_temp;
reg [7:0] out_data_temp;
//assign out_valid = out_valid_temp;
//assign out_data = out_data_temp;
reg [7:0] data_shifted[0:15];
//=================================design variable================================//
// Your Design

reg pic_no_save[0:15];
integer i,j;
//====for basic setting=====//
reg [1:0] in_ratio_mode_save;
reg [1:0]in_mode_save;
//===counter for read picture and renew sram and renew dram===//
reg [8:0] rgb_cnt;
// reg [3:0] global_shift[0:15];
// reg [4:0] yaya1;
reg [127:0] write_data_temp[0:4];
reg finish_flag;
reg max_flag;
//=========================================FSM======================================//
reg [1:0] cs_state, ns_state;
localparam IDLE = 0;
localparam READ_INPUT = 1;
localparam READ_DRAM_DATA =2 ;
localparam OUTPUT =3 ;

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cs_state <= IDLE;
    end
    else begin
        cs_state <= ns_state;
    end
end

always@(*) begin
    case(cs_state)
        IDLE: begin
            if(in_valid) begin
                ns_state = READ_INPUT;
            end
            else begin
                ns_state = IDLE;
            end
        end
        READ_INPUT: begin
            // if((global_shift[read_id_from_ISP]>7)||(global_shift[read_id_from_ISP]==6 && in_ratio_mode_save==2)||(global_shift[read_id_from_ISP]==7 && in_ratio_mode_save==1)) begin//||(global_shift[read_id_from_ISP]==6 && in_ratio_mode_save==2)
            //     ns_state = OUTPUT;
            // end
            if(pic_no_save[read_id_from_ISP]==1 && in_ratio_mode_save==0) begin
                ns_state = OUTPUT;
            end
            else begin
                ns_state = READ_DRAM_DATA;
            end
        end
        READ_DRAM_DATA: begin
            // if(bvalid_s_inf) begin//6*6*3//one pic
            if(finish_flag && max_flag) begin//6*6*3//one pic
                ns_state = OUTPUT;
            end
            else begin
                ns_state = READ_DRAM_DATA;
            end
        end
        OUTPUT: begin
            ns_state = IDLE;
        end
        default: begin
            ns_state = IDLE;
        end
    endcase
end

//====================================BASIC SETTING======================================//

always@(posedge clk or negedge rst_n) begin//save total number of right shift and left shift?
    if(!rst_n) begin
       in_ratio_mode_save <= 0;
    end
    else begin
        if(in_valid) begin
            if(in_mode[0]==0) begin
                in_ratio_mode_save <= 0;
            end
            else begin
                case(in_ratio_mode)
                    0: in_ratio_mode_save <= 2;//0.25
                    1: in_ratio_mode_save <= 1;//0.5
                    2: in_ratio_mode_save <= 0;//1
                    3: in_ratio_mode_save <= 3;//left shift1
                endcase
            end
        end
    end
end
always@(posedge clk or negedge rst_n) begin//save total number of right shift and left shift?
    if(!rst_n) begin
       in_mode_save <= 0;
    end
    else begin
        if(in_valid) begin
            in_mode_save <= in_mode;
        end
    end
end

//====================================SAVE PIC FROM DRAM======================================//

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<16;i=i+1) begin
            pic_no_save[i] <= 4'b0;
        end
    end
    else begin
        if(cs_state==OUTPUT) begin
            pic_no_save[read_id_from_ISP] <= 1;
        end
        // else begin
        //     for(i=0;i<16;i=i+1) begin
        //         pic_no_save[i] <= pic_no_save[i];
        //     end
        // end
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        read_id_from_ISP <= 4'b0;
    end
    else begin
        if(in_valid) begin
            read_id_from_ISP <= in_pic_no;
        end
    end
end
always@(posedge clk) begin
    if(cs_state==READ_DRAM_DATA && rready_s_inf==0)begin
        arvalid_s_inf <= 1'b1;
    end
    else begin
        arvalid_s_inf <= 1'b0;
    end
end

reg [1:0]now_rgb;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        now_rgb <= 2'b0;
    end
    else begin
        if(cs_state== READ_DRAM_DATA) begin
            if(rgb_cnt==63 && now_rgb==2) begin//count r and g and b
                now_rgb <= now_rgb ;
            end
            else if(&rgb_cnt[5:0] && !rgb_cnt[8:6]) begin//count r and g and b
                now_rgb <= now_rgb + 2'd1;
            end
        end
        else begin
            now_rgb <= 2'b0;
        end
    end
end
reg read_valid_from_dram_reg;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        read_valid_from_dram_reg <= 0;
    end
    else begin
        read_valid_from_dram_reg <= read_valid_from_dram;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rgb_cnt <= 9'b0;
    end
    else begin
        if(cs_state == READ_DRAM_DATA) begin
           if(read_valid_from_dram_reg||now_rgb==2) begin
                // if(now_rgb==2) begin
                //     rgb_cnt <= rgb_cnt + 1'b1;
                // end
                // else begin
                    if(&rgb_cnt[5:0] && !rgb_cnt[8:6] && !now_rgb[1]) begin//count r and g and b
                        rgb_cnt <= 0;
                    end
                    else begin
                        rgb_cnt <= rgb_cnt + 1'b1;
                    end
                //end
            end
        end
        else begin
            rgb_cnt <= 9'b0;
        end
    end
end


reg [7:0] map_temp_2[0:5];
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<6;i=i+1) begin
                map_temp_2[i] <= 8'b0;
        end
    end
    else begin
        //if(cs_state==READ_DRAM_DATA && read_valid_from_dram) begin
            if(rgb_cnt>25&& rgb_cnt<38) begin
                if(rgb_cnt[0]==0) begin
                    map_temp_2[0] <= data_shifted[2];
                    map_temp_2[1] <= data_shifted[1];
                    map_temp_2[2] <= data_shifted[0];
                end
                else begin
                    map_temp_2[3] <= data_shifted[15];
                    map_temp_2[4] <= data_shifted[14];
                    map_temp_2[5] <= data_shifted[13];
                end
            end
            // else begin
            //     for(i=0;i<6;i=i+1) begin
            //         map_temp_2[i] <= map_temp_2[i];
            //     end
            // end
        //end
    end
end
always@(posedge clk) begin
    if(cs_state==READ_DRAM_DATA) begin
        rready_s_inf <= 1;
    end
    else begin
        rready_s_inf <= 0;
    end
end
//===================================RENEW AUTOFOCUS======================================//

// //==============================CALCULATE AUTOFOCUS======================================//
// //0.25(>>2)0.5(>>1)
// //==============================GRAYSCALE======================================//
// reg [7:0]six_add_in_1[0:5], six_add_in_2[0:5],six_add_result[0:5];
//reg [7:0]six_add1,six_add2,six_result,six_result_reg[0:5][0:5];
reg [7:0] six_result_reg[0:5][0:5];
// reg [7:0]six_add_2_1, six_add_2_2;
// reg [7:0]six_add_3_1, six_add_3_2;
// reg [7:0]six_add_4_1, six_add_4_2;
// reg [7:0]six_add_5_1, six_add_5_2;
// reg [7:0]six_add_6_1, six_add_6_2;
//six_result_reg new version
always @(posedge clk or negedge rst_n)begin 
    if(!rst_n)begin 
        for(i=0;i<6;i=i+1) begin
            for(j=0;j<6;j=j+1) begin
                six_result_reg[i][j] <= 0;
            end
        end
    end
    else begin
        if(cs_state == 2)begin 
            if(rgb_cnt>27 && rgb_cnt <46 )begin 
                if(!rgb_cnt[0] && rgb_cnt < 39)begin //28to39
                    if(now_rgb==1)begin
                        for(j = 0; j < 6; j = j + 1) begin
                            six_result_reg[0][j] <= (map_temp_2[j]>>1) + six_result_reg[0][j];
                        end
                    end
                    else begin
                        for(j = 0; j < 6; j = j + 1) begin
                            six_result_reg[0][j] <= (map_temp_2[j]>>2) + six_result_reg[0][j];
                        end
                    end
                end
                else begin//40to45
                    for(i=0;i<5;i=i+1) begin
                        for(j=0;j<6;j=j+1) begin
                            six_result_reg[i][j] <= six_result_reg[i+1][j];
                            six_result_reg[5][j] <= six_result_reg[0][j];
                        end
                    end
                end

            end
            else if(rgb_cnt>45 && rgb_cnt<52 && now_rgb==2) begin
                     for(i=0;i<6;i=i+1) begin
                        for(j=0;j<6;j=j+1) begin
                            six_result_reg[i][j] <= six_result_reg[i][j+1];
                            six_result_reg[i][5] <= six_result_reg[i][0];
                        end
                    end
            end
        end
        else begin 
            for(i=0;i<6;i=i+1) begin
                for(j=0;j<6;j=j+1) begin
                    six_result_reg[i][j] <= 0;
                end
            end
        end
    end
end

// always@(*) begin
//     for(integer i=0;i<6;i=i+1) begin
//         six_add_result[i] = six_add_in_1[i] + six_add_in_2[i];
//     end
// end
// genvar k;
// generate
//     for(k=0;k<=5;k=k+1)begin
//         always@(*) begin
//             if (rgb_cnt>26 && rgb_cnt<39) begin
//                 if(now_rgb[0]) begin   
//                     six_add_in_1[k] = six_result_reg[0][k];
//                     six_add_in_2[k] = map_temp_2[k]>>1;
//                 end
//                 else begin
//                      six_add_in_1[k] = six_result_reg[0][k];
//                     six_add_in_2[k]= map_temp_2[k]>>2;
//                 end
//             end
//             else begin
//                 six_add_in_1[k] = 8'b0;
//                 six_add_in_2[k] = 8'b0;
//              end
//         end
//     end
// endgenerate


//===============================================//
// //=============================DISTANCE======================================//
reg [7:0] minus_result[0:5];
reg [7:0] minus_result_reg[0:5];
reg [9:0] two_distance;//specify in particular cycle
reg [13:0] four_distance;
reg [10:0] six_distance;
reg [13:0] six_distance_temp;
reg [7:0] focus_big[0:5];
reg [7:0] focus_small[0:5];

always @(*) begin
    for(i=0;i<=5;i=i+1) begin
        minus_result[i] = focus_big[i] - focus_small[i];
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<=5;i=i+1) begin
            minus_result_reg[i] <= 0;
        end
    end
    else begin
        for(i=0;i<=5;i=i+1) begin
            minus_result_reg[i] <= minus_result[i];
        end
    end
end
///adder for distance
reg [9:0] adder_stage1[0:2];
// 0 indicate the addition of first and 6th element, 
// 1 indicate the addition of second and 5th element,
// 2 indicate the addition of third and 4th element
always @(posedge clk or negedge rst_n)begin 
    if(!rst_n) begin
        for(i=0;i<=2;i=i+1) begin
            adder_stage1[i] <= 0;
        end
    end
    else begin
        adder_stage1[0] <= minus_result_reg[0] + minus_result_reg[5];
        adder_stage1[1] <= minus_result_reg[1] + minus_result_reg[4];
        adder_stage1[2] <= minus_result_reg[2] + minus_result_reg[3];
    end
end
reg [10:0] adder_stage2 ;//addition of adder_stage1[1] and adder_stage1[2]
reg [9:0] adder_stage1_buffer;// buffer of adder_stage1[0]
always @(posedge clk or negedge rst_n)begin 
    if(!rst_n) begin
        adder_stage2 <= 0;
    end
    else begin
        adder_stage2 <= adder_stage1[1] + adder_stage1[2];
    end
end
always @(posedge clk or negedge rst_n)begin 
    if(!rst_n) begin
        adder_stage1_buffer <= 0;
    end
    else begin
        adder_stage1_buffer <= adder_stage1[0];
    end
end
reg [11:0] adder_stage3;// addition of adder_stage2 and adder_stage1_buffer
always @(posedge clk or negedge rst_n)begin 
    if(!rst_n) begin
        adder_stage3 <= 0;
    end
    else begin
        adder_stage3 <= adder_stage2 + adder_stage1_buffer;
    end
end
//two distance newest version
always @(posedge clk or negedge rst_n)begin 
    if(!rst_n) begin
        two_distance <= 0;
    end
    else begin
        if(now_rgb==2) begin
            if(rgb_cnt==45 ||rgb_cnt==51) begin
                two_distance <=  two_distance + adder_stage1[2];
            end
        end
        else begin
            two_distance <= 0;
        end
    end
end
//four distance newest version
always @(posedge clk or negedge rst_n)begin 
    if(!rst_n) begin
        four_distance <= 0;
    end
    else begin
        if(now_rgb==2) begin
            if(rgb_cnt>44 && rgb_cnt<48) begin
                four_distance <= four_distance + adder_stage2;
            end
            else if(rgb_cnt>50 && rgb_cnt<54) begin
                four_distance <= four_distance + adder_stage2;
            end
        end
        else begin
            four_distance <= 0;
        end
    end
end
//six distance  temp , newest version
always @(posedge clk or negedge rst_n)begin 
    if(!rst_n) begin
        six_distance_temp <= 0;
    end
    else begin
        if(now_rgb == 2) begin
            if(rgb_cnt>55 && six_distance_temp>35) begin
                six_distance_temp <= six_distance_temp - 36;
            end
            else begin
                six_distance_temp <= six_distance_temp + adder_stage3;
            end
        end
        else begin
            six_distance_temp <= 0;
        end
    end
end
//six distance newest version
always @(posedge clk or negedge rst_n)begin 
    if(!rst_n) begin
        six_distance <= 0;
    end
    else begin
        if(now_rgb == 2) begin
            if(rgb_cnt > 55 && six_distance_temp>35) begin
                six_distance <= six_distance + 1;
            end
        end
        else begin
            six_distance <= 0;
        end
    end
end

// always@(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         finish_flag <= 1'b0;
//     end
//     else begin
//         if(rgb_cnt>67&& six_distance_temp<36 ) begin
//             finish_flag <= 1'b1;
//         end
//         else begin
//             finish_flag <= 1'b0;
//         end
//     end
// end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        finish_flag <= 1'b0;
    end
    else begin
        if(rgb_cnt>67&& six_distance_temp<36 ) begin
            finish_flag <= 1'b1;
        end
        else begin
            finish_flag <= 1'b0;
        end
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<=5;i=i+1) begin
            focus_big[i] <= 0;
            focus_small[i] <= 0;
        end
    end
    else begin
            if(39<rgb_cnt && rgb_cnt<45 ) begin
                for(i=0;i<=5;i=i+1) begin
                    {focus_big[i], focus_small[i]} <= (six_result_reg[0][i] > six_result_reg[1][i])?{six_result_reg[0][i],six_result_reg[1][i]}:{six_result_reg[1][i],six_result_reg[0][i]};
                end
            end
            else if( 45<rgb_cnt && rgb_cnt<51) begin
                for(i=0;i<=5;i=i+1) begin
                    {focus_big[i] , focus_small[i]} <= (six_result_reg[i][0] > six_result_reg[i][1])?{six_result_reg[i][0],six_result_reg[i][1]}:{six_result_reg[i][1],six_result_reg[i][0]};
                end
            end
            else begin
                for(i=0;i<=5;i=i+1) begin
                    focus_big[i] <= 1'b0;
                    focus_small[i] <= 1'b0;
                end
            end
    end
end

//==========================SAVE AUTOFOCUS======================================//
reg [7:0] autofocus_save[0:15];
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<16;i=i+1) begin
                autofocus_save[i] <= 0;
        end
    end
    else if( cs_state == READ_DRAM_DATA) begin
        //if( cs_state == READ_DRAM_DATA) begin
        autofocus_save[read_id_from_ISP] <= compare(two_distance>>2,four_distance>>4,six_distance);
    end
    //     else begin
    //         for(i=0;i<16;i=i+1) begin
            
    //                 autofocus_save[i] <= autofocus_save[i];
                
    //         end
    //     end
    // end
end

function [1:0] compare;
    input[10:0] ain;
    input[10:0] bin;
    input[10:0] cin;
    begin
        if(ain>=bin && ain>=cin)  begin
            compare = 0;
        end
        else if(bin>=cin && bin>ain) begin
            compare = 1;
        end
        else begin
            compare = 2;
        end
    end
endfunction

//==========================CAL AUTOEXP======================================//
reg [17:0] exposure_outcome;

genvar n;
generate
for(n=0;n<=15;n=n+1) begin
always@(*) begin
        if(in_ratio_mode_save==3) begin
            // if(write_data_temp[0][(127 - n*8):(120 - n*8)]>=128 ) begin
            if(write_data_temp[0][127 - n*8] ) begin
                data_shifted[n] = 8'b11111111;
            end
            else begin
                data_shifted[n] = write_data_temp[0][(127 - n*8):(120 - n*8)]<<1;
            end
        end
        else begin
                data_shifted[n] = write_data_temp[0][(127 - n*8):(120 - n*8)]>>(in_ratio_mode_save);
        end
    end
end
endgenerate
// reg [7:0] c,d,e,f,g,h,p,q;
// reg [8:0] s1, s2, s3, s4;
// reg [9:0] s5, s6;
// reg [10:0] temp_exp;
reg [9:0] c,d,e,f,g,h,p,q;
reg [10:0] s1, s2, s3, s4;
reg [11:0] s5, s6;
reg [12:0] temp_exp;
reg [7:0] autoexp_save[0:15];
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        exposure_outcome <= 0;
    end
    else begin
        if(cs_state==IDLE) begin
            exposure_outcome <= 0;
        end
        else begin
            exposure_outcome <= exposure_outcome + temp_exp;
        end
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        temp_exp <= 0;
    end
    else begin
        temp_exp <= s5 + s6;
    end
end
always@(posedge clk or negedge rst_n ) begin
    if(!rst_n) begin
        c <= 0;
        d <= 0;
        e <= 0;
        f <= 0;
        g <= 0;
        h <= 0;
        p <= 0;
        q <= 0;
        s1 <= 0;
        s2 <= 0;
        s3 <= 0;
        s4 <= 0;
        s5 <= 0;
        s6 <= 0;
    end
    else begin
        if(cs_state==READ_DRAM_DATA) begin
            if(now_rgb==0||now_rgb==2) begin
                c <= (write_data_temp[1][127:120]>>2) + (write_data_temp[1][119:112]>>2);
                d <= (write_data_temp[1][111:104]>>2) + (write_data_temp[1][103:96]>>2);
                e <= (write_data_temp[1][95:88]>>2) + (write_data_temp[1][87:80]>>2);
                f <= (write_data_temp[1][79:72]>>2) + (write_data_temp[1][71:64]>>2);
                g <= (write_data_temp[1][63:56]>>2) + (write_data_temp[1][55:48]>>2);
                h <= (write_data_temp[1][47:40]>>2) + (write_data_temp[1][39:32]>>2);
                p <= (write_data_temp[1][31:24]>>2) + (write_data_temp[1][23:16]>>2);
                q <= (write_data_temp[1][15:8]>>2) + (write_data_temp[1][7:0]>>2);
                s1 <= c + d;
                s2 <= e + f;
                s3 <= g + h;
                s4 <= p + q;
                s5 <= s1 + s2;
                s6 <= s3 + s4;
            end
            else begin
                c <= (write_data_temp[1][127:120]>>1) + (write_data_temp[1][119:112]>>1);
                d <= (write_data_temp[1][111:104]>>1) + (write_data_temp[1][103:96]>>1);
                e <= (write_data_temp[1][95:88]>>1) + (write_data_temp[1][87:80]>>1);
                f <= (write_data_temp[1][79:72]>>1) + (write_data_temp[1][71:64]>>1);
                g <= (write_data_temp[1][63:56]>>1) + (write_data_temp[1][55:48]>>1);
                h <= (write_data_temp[1][47:40]>>1) + (write_data_temp[1][39:32]>>1);
                p <= (write_data_temp[1][31:24]>>1) + (write_data_temp[1][23:16]>>1);
                q <= (write_data_temp[1][15:8]>>1) + (write_data_temp[1][7:0]>>1);
                s1 <= c + d;
                s2 <= e + f;
                s3 <= g + h;
                s4 <= p + q;
                s5 <= s1 + s2;
                s6 <= s3 + s4;
            end
        end
        else begin
            c <= 0;
            d <= 0;
            e <= 0;
            f <= 0;
            g <= 0;
            h <= 0;
            s1 <= 0;
            s2 <= 0;
        end
    end
end

//==========================SAVE AUTOEXP======================================//

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<16;i=i+1) begin
            autoexp_save[i] <= 0;
        end
    end
    else if(cs_state==READ_DRAM_DATA ) begin
            autoexp_save[read_id_from_ISP] <= exposure_outcome[17:10];
        // else begin
        //     for(i=0;i<16;i=i+1) begin
        //         autoexp_save[i] <= autoexp_save[i];
        //     end
        // end
    end
end
// //==============================WRITE BACK TO DRAM======================================//

// wire [5:0] addr;
// assign addr = (read_id_from_ISP<<1) + read_id_from_ISP;
assign awaddr_s_inf = araddr_s_inf;
//araddr_s_inf  using non-blocking
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        araddr_s_inf <= 0;
    end
    else begin
        case(read_id_from_ISP)
            4'b0000: begin 
                araddr_s_inf <= {16'h0001,6'b000000,10'd0};
                end
            4'b0001: begin
                araddr_s_inf <= {16'h0001,6'b000011,10'd0};
                end
            4'b0010: begin
                araddr_s_inf <= {16'h0001,6'b000110,10'd0};
                end
            4'b0011: begin
                araddr_s_inf <= {16'h0001,6'b001001,10'd0};
                end
            4'b0100: begin
                araddr_s_inf <= {16'h0001,6'b001100,10'd0};
                end
            4'b0101: begin
                araddr_s_inf <= {16'h0001,6'b001111,10'd0};
                end
            4'b0110: begin
                araddr_s_inf <= {16'h0001,6'b010010,10'd0};
                end
            4'b0111: begin
                araddr_s_inf <= {16'h0001,6'b010101,10'd0};
                end
            4'b1000: begin
                araddr_s_inf <= {16'h0001,6'b011000,10'd0};
                end
            4'b1001: begin
                araddr_s_inf <= {16'h0001,6'b011011,10'd0};
                end
            4'b1010: begin
                araddr_s_inf <= {16'h0001,6'b011110,10'd0};
                end
            4'b1011: begin
                araddr_s_inf <= {16'h0001,6'b100001,10'd0};
                end
            4'b1100: begin
                araddr_s_inf <= {16'h0001,6'b100100,10'd0};
                end
            4'b1101: begin
                araddr_s_inf <= {16'h0001,6'b100111,10'd0};
                end
            4'b1110: begin
                araddr_s_inf <= {16'h0001,6'b101010,10'd0};
                end
            4'b1111: begin
                araddr_s_inf <= {16'h0001,6'b101101,10'd0};
                end
            default: begin
                araddr_s_inf <= 0;
            end
        endcase
        // araddr_s_inf <= {16'h0001,addr,10'd0};
        // awaddr_s_inf <= {16'h0001,addr,10'd0};
    end
end


//==============================old version======================================//


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        write_addr_valid_from_ISP <= 0;
    end
    else begin
        if(read_valid_from_dram && (now_rgb == 0) && (rgb_cnt ==0)) begin
            write_addr_valid_from_ISP <= 1;
        end
        else begin
            write_addr_valid_from_ISP <= 0;
        end
    end
end



//==============================old version======================================//
// new write_data_temp[i] 
always @(posedge clk or negedge rst_n)begin 
    if(!rst_n) begin
       for(i=0;i<5;i=i+1) begin
            write_data_temp[i] <= 128'b0;
        end
    end
    else begin
        write_data_temp[0] <= rdata_s_inf;
        write_data_temp[1] <= {data_shifted[0],data_shifted[1],data_shifted[2],data_shifted[3],
                                data_shifted[4],data_shifted[5],data_shifted[6],data_shifted[7],
                                data_shifted[8],data_shifted[9],data_shifted[10],data_shifted[11],
                                data_shifted[12],data_shifted[13],data_shifted[14],data_shifted[15]};
        write_data_temp[2] <= write_data_temp[1];
        write_data_temp[3] <= write_data_temp[2];
        write_data_temp[4] <= write_data_temp[3];
    end
end

//original code
/////////////////////////////////// write_data_temp[i]  ///////////////////////////////////////
// always@(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         for(i=0;i<5;i=i+1) begin
//             write_data_temp[i] <= 128'b0;
//         end
//     end
//     else begin
//         if(cs_state==READ_DRAM_DATA) begin
//             if(read_valid_from_dram ||now_rgb==2) begin
//                 // write_data_temp[0] <= read_data_from_dram;
//                 write_data_temp[1] <= {data_shifted[0],data_shifted[1],data_shifted[2],data_shifted[3],
//                                         data_shifted[4],data_shifted[5],data_shifted[6],data_shifted[7],
//                                         data_shifted[8],data_shifted[9],data_shifted[10],data_shifted[11],
//                                         data_shifted[12],data_shifted[13],data_shifted[14],data_shifted[15]};
//                 write_data_temp[2] <= write_data_temp[1];
//                 write_data_temp[3] <= write_data_temp[2];
//                 write_data_temp[4] <= write_data_temp[3];
//             end
//         end
//         else begin
//             for(i=0;i<5;i=i+1) begin
//                 write_data_temp[i] <= 128'b0;
//             end
//         end
//     end
// end
/////////////////////////////////// write_data_temp[i]  ///////////////////////////////////////
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        write_data_ready_from_ISP <= 0;
    end
    else begin
        // if(cs_state == READ_DRAM_DATA) begin
            if(bvalid_s_inf) begin
                write_data_ready_from_ISP <= 0;
            end
            else if(awready_s_inf) begin
                write_data_ready_from_ISP <= 1;
            end
        // end
        // else begin
        //     write_data_ready_from_ISP<= 0;
        // end
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        write_last_from_ISP <= 0;
    end
    else begin
       if(rgb_cnt == 67) begin         
            write_last_from_ISP <= 1;        
        end
        else begin
            write_last_from_ISP<= 0;
        end
    end
end
// always@(posedge clk ) begin
//     if(rgb_cnt == 67) begin         
//         write_last_from_ISP <= 1;        
//     end
//     else begin
//         write_last_from_ISP<= 0;
//     end
// end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wdata_s_inf <= 0;
    end
    // else begin
    //     if(cs_state == READ_DRAM_DATA) begin
    //         write_data_from_ISP <= write_data_temp[4];
    //     end
    //     else begin
    //         write_data_from_ISP<= 0;
    //     end
    // end
    else begin 
        wdata_s_inf <= write_data_temp[4];
    end
end

// always@(posedge clk or negedge rst_n)
// begin
//     if(!rst_n) begin
//         yaya1 <= 0;
//     end
//     else begin
//         yaya1 <= (in_valid && in_pic_no==3)?(yaya1+1):yaya1;
//     end
// end

//==============================CALCULATE SHIFT NUM======================================//
// always@(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         for(i = 0; i < 16; i = i + 1)begin 
//             global_shift[i] <= 0;
//         end
//     end
//     else begin
//         if(cs_state==OUTPUT && (!global_shift[read_id_from_ISP][3])) begin
//                 if(in_ratio_mode_save==2'd3) begin
//                     global_shift[read_id_from_ISP] <= (global_shift[read_id_from_ISP]==0)?0:(global_shift[read_id_from_ISP]-1);
//                 end
//                 else begin
//                     global_shift[read_id_from_ISP] <= global_shift[read_id_from_ISP]+in_ratio_mode_save;
//                 end
//             // end
//         end
//     end
// end

//===============================CALCULATE MAX MIN======================================//
wire [7:0] sorted_dram_data[0:7];
wire [7:0] temp_max;
wire [7:0] temp_min;
sorting_16 sort_1(.clk(clk),.rst_n(rst_n),.in0(write_data_temp[1][127:120]),.in1(write_data_temp[1][119:112]),.in2(write_data_temp[1][111:104]),.in3(write_data_temp[1][103:96]),
                            .in4(write_data_temp[1][95:88]),.in5(write_data_temp[1][87:80]),.in6(write_data_temp[1][79:72]),.in7(write_data_temp[1][71:64]),
                            .in8(write_data_temp[1][63:56]),.in9(write_data_temp[1][55:48]),.in10(write_data_temp[1][47:40]),.in11(write_data_temp[1][39:32]),
                            .in12(write_data_temp[1][31:24]),.in13(write_data_temp[1][23:16]),.in14(write_data_temp[1][15:8]),.in15(write_data_temp[1][7:0]),
                            .out0(temp_max),.out1(temp_min) );


reg [7:0] max_save;
reg [7:0] min_save, min_save_buffer;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        max_save <= 0;
    end
    else begin
        if(cs_state == READ_DRAM_DATA) begin
            if(rgb_cnt==5) begin
                    max_save <= temp_max;
                end
                // else if(rgb_cnt>67)begin
                //     max_save <= max_save;
                // end
            else begin
                if(max_save<temp_max) begin
                    max_save <= temp_max;
                end
                // else begin
                //     max_save <= max_save;
                // end
            end
        end
        else begin
            max_save <= 0;
        end
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        min_save <= 0;
    end
    else begin
        if(cs_state == READ_DRAM_DATA) begin
            if(rgb_cnt==5) begin
                    min_save <= temp_min;
                end
            else begin
                    if(min_save>temp_min) begin
                        min_save <= temp_min;
                    end
                end
        end
        else begin
            min_save <= 0;
        end
    end
end
//min_save_buffer
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        min_save_buffer <= 0;
    end
    else begin
        min_save_buffer <= min_save;
    end
end
reg [10:0] max_min_total;
// max_min_total calculation
always @(posedge clk or negedge rst_n)begin 
    if(!rst_n) begin
        max_min_total <= 0;
    end
    else begin
        if(cs_state == READ_DRAM_DATA) begin
            if((rgb_cnt==5 && (^now_rgb)) || rgb_cnt == 68) begin
                max_min_total <= max_min_total + max_save;
            end
            else if((rgb_cnt==6 && (^now_rgb)) || rgb_cnt == 69)begin 
                max_min_total <= max_min_total + min_save_buffer;
            end
            else if(max_min_total > 5) begin
                max_min_total <= max_min_total - 6;
            end
            
            end
        else begin
            max_min_total <= 0;
        end
    end
end
reg [7:0] max_min_count;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        max_min_count <= 0;
    end
    else begin
        if(now_rgb!=0) begin
            if(max_min_total>5) begin
                if(rgb_cnt!=68 && rgb_cnt!=69 && rgb_cnt != 6  && rgb_cnt != 5 ) begin
                    max_min_count <= max_min_count + 1;
                end
            end
        end
        else begin
            max_min_count <= 0;
        end
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        max_flag <= 1'b0;
    end
    else begin
        if(rgb_cnt >69 &&  max_min_total<6 ) begin
            max_flag <= 1'b1;
        end
        else begin
            max_flag <= 1'b0;
        end
    end
end

reg [8:0] max_min_result[0:15];
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<16;i=i+1) begin
            max_min_result[i] <= 0;
        end
    end
    else if(cs_state==READ_DRAM_DATA) begin
        
            for(i=0;i<16;i=i+1) begin
                max_min_result[read_id_from_ISP] <= max_min_count;
            end
        //end
    end
end

//==============================OUTPUT======================================//
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
    end
    else begin
        if(ns_state == OUTPUT) begin
            out_valid <= 1;
        end
        else begin
            out_valid <= 0;
        end
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_data <= 0;
    end
    else begin
        if(ns_state == OUTPUT) begin
            // if((global_shift[read_id_from_ISP]>7)||(global_shift[read_id_from_ISP]==6 && in_ratio_mode_save==2)||(global_shift[read_id_from_ISP]==7 && in_ratio_mode_save==1)) begin//||(global_shift[read_id_from_ISP]==6 && in_ratio_mode_save==2)
            //     out_data<=0;
            // end
            // else  begin
                case(in_mode_save)
                    2'd0: out_data <= autofocus_save[read_id_from_ISP];
                    2'd1: out_data <= autoexp_save[read_id_from_ISP];
                    2'd2: out_data <= max_min_result[read_id_from_ISP];
                    default: out_data <= 0;
                endcase
            // end
        end
        else begin
            out_data <= 0;
        end
    end
end

endmodule 

module sorting_16 (clk,rst_n,in0,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15,out0,out1);

input [7:0] in0,in1,in2,in3,in4,in5,in6,in7,in8,in9,in10,in11,in12,in13,in14,in15;
input clk,rst_n;
output reg [7:0] out0,out1;
reg [7:0] value [0:15];
wire [7:0] value_a [0:15];
reg [7:0] value_a_max_ff [0:7];
reg [7:0] value_a_min_ff [0:7];
wire [7:0] value_b [0:7];
reg [7:0] value_b_max_ff [0:3];
reg [7:0] value_b_min_ff [0:3];
wire [7:0] value_c [0:3];
reg [7:0] value_c_max_ff [0:1];
reg [7:0] value_c_min_ff [0:1];
wire [7:0] value_d [0:1];
// reg [7:0] value_d_ff[0:1];
integer m;

always@(*) begin
    value[0] = in0;
    value[1] = in1;
    value[2] = in2;
    value[3] = in3;
    value[4] = in4;
    value[5] = in5;
    value[6] = in6;
    value[7] = in7;
    value[8] = in8;
    value[9] = in9;
    value[10] = in10;
    value[11] = in11;
    value[12] = in12;
    value[13] = in13;
    value[14] = in14;
    value[15] = in15;
end

assign {value_a[0], value_a[8]}  =  (value[0] > value[1]) ? {value[0], value[1]} : {value[1], value[0]};
assign {value_a[1], value_a[9]}  =  (value[2] > value[3]) ? {value[2], value[3]} : {value[3], value[2]};
assign {value_a[2], value_a[10]} =  (value[4] > value[5]) ? {value[4], value[5]} : {value[5], value[4]};
assign {value_a[3], value_a[11]} =  (value[6] > value[7]) ? {value[6], value[7]} : {value[7], value[6]};
assign {value_a[4], value_a[12]} =  (value[8] > value[9]) ? {value[8], value[9]} : {value[9], value[8]};
assign {value_a[5], value_a[13]} =  (value[10] > value[11]) ? {value[10], value[11]} : {value[11], value[10]};
assign {value_a[6], value_a[14]} =  (value[12] > value[13]) ? {value[12], value[13]} : {value[13], value[12]};
assign {value_a[7], value_a[15]} =  (value[14] > value[15]) ? {value[14], value[15]} : {value[15], value[14]};
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(m=0;m<8;m=m+1) begin
            value_a_max_ff[m] <= 0;
        end
    end
    else begin
        for(m=0;m<8;m=m+1) begin
            value_a_max_ff[m] <= value_a[m];
        end
    end
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(m=0;m<8;m=m+1) begin
            value_a_min_ff[m] <= 0;
        end
    end
    else begin
        for(m=0;m<8;m=m+1) begin
            value_a_min_ff[m] <= value_a[m+8];
        end
    end
end

assign value_b[0] = (value_a_max_ff[0] > value_a_max_ff[1]) ? value_a_max_ff[0] : value_a_max_ff[1];
assign value_b[1] = (value_a_max_ff[2] > value_a_max_ff[3]) ? value_a_max_ff[2] : value_a_max_ff[3];
assign value_b[2] = (value_a_max_ff[4] > value_a_max_ff[5]) ? value_a_max_ff[4] : value_a_max_ff[5];
assign value_b[3] = (value_a_max_ff[6] > value_a_max_ff[7]) ? value_a_max_ff[6] : value_a_max_ff[7];

assign value_b[4] = (value_a_min_ff[0] < value_a_min_ff[1]) ? value_a_min_ff[0] : value_a_min_ff[1];
assign value_b[5] = (value_a_min_ff[2] < value_a_min_ff[3]) ? value_a_min_ff[2] : value_a_min_ff[3];
assign value_b[6] = (value_a_min_ff[4] < value_a_min_ff[5]) ? value_a_min_ff[4] : value_a_min_ff[5];
assign value_b[7] = (value_a_min_ff[6] < value_a_min_ff[7]) ? value_a_min_ff[6] : value_a_min_ff[7];


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(m=0;m<4;m=m+1) begin
            value_b_max_ff[m] <= 0;
        end
    end
    else begin
        for(m=0;m<4;m=m+1) begin
            value_b_max_ff[m] <= value_b[m];
        end
    end
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(m=0;m<4;m=m+1) begin
            value_b_min_ff[m] <= 0;
        end
    end
    else begin
        value_b_min_ff[0] <= value_b[4];
        value_b_min_ff[1] <= value_b[5];
        value_b_min_ff[2] <= value_b[6];
        value_b_min_ff[3] <= value_b[7];
    end
end

assign value_c[0] = (value_b_max_ff[0] > value_b_max_ff[1]) ? value_b_max_ff[0] : value_b_max_ff[1];
assign value_c[1] = (value_b_max_ff[2] > value_b_max_ff[3]) ? value_b_max_ff[2] : value_b_max_ff[3];

assign value_c[2] = (value_b_min_ff[0] < value_b_min_ff[1]) ? value_b_min_ff[0] : value_b_min_ff[1];
assign value_c[3] = (value_b_min_ff[2] < value_b_min_ff[3]) ? value_b_min_ff[2] : value_b_min_ff[3];


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(m=0;m<2;m=m+1) begin
            value_c_max_ff[m] <= 0;
        end
    end
    else begin
        for(m=0;m<2;m=m+1) begin
            value_c_max_ff[m] <= value_c[m];
        end
    end
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(m=0;m<2;m=m+1) begin
            value_c_min_ff[m] <= 0;
        end
    end
    else begin
        //for(m=0;m<2;m=m+1) begin
            value_c_min_ff[0] <= value_c[2];
            value_c_min_ff[1] <= value_c[3];
        //end
    end
end

assign value_d[0] = (value_c_max_ff[0] > value_c_max_ff[1]) ? value_c_max_ff[0] : value_c_max_ff[1];
assign value_d[1] = (value_c_min_ff[0] < value_c_min_ff[1]) ? value_c_min_ff[0] : value_c_min_ff[1];

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out0 <= 0;
        out1 <= 0;
    end
    else begin
        out0 <= value_d[0];
        out1 <= value_d[1];
    end
end




endmodule

