module TMIP(
    // input signals
    clk,
    rst_n,
    in_valid, 
    in_valid2,
    
    image,
    template,
    image_size,
	action,
	
    // output signals
    out_valid,
    out_value
    );

input            clk, rst_n;
input            in_valid, in_valid2;

input      [7:0] image;
input      [7:0] template;
input      [1:0] image_size;
input      [2:0] action;

output reg       out_valid;
output reg       out_value;

//==================================================================
// parameter & integer
//==================================================================


//==================================================================
// reg & wire
//==================================================================
localparam IDLE = 0;
localparam READ_IMG = 1;
localparam ACTION_WAIT = 2;
localparam SAVE_ACTION = 3;
localparam MAX_POOLING = 4;
localparam MEDIUM = 5 ;
localparam CROSS = 6 ;
localparam NEG_FLIP = 7;
//state reg
reg [3:0] cs_state, ns_state;

reg [7:0] a,b,c;
//2bit image size
reg [1:0] image_size_reg;
// end address of image SRAM
reg [13:0] addr_img_read_end;

// 10-bit image address
reg [9:0] global_count;
reg [2:0] local_count;
// 9-bit kernel address
reg [7:0] addr_template;

// data_out of image SRAM and kernel SRAM
wire  [63:0] data_out_img;
wire  data_out_template;
reg [7:0] template_reg[0:2][0:2];
integer i,j;

reg [3:0] set_count;
reg [3:0] template_count;
// data_in of image SRAM and action 

reg [2:0] cal_count;
reg [4:0]control_count;
reg [2:0] action_reg;
reg [2:0] action_save[0:7];

reg [6:0] image_address,image_address_reg;
reg [63:0] data_in,data_in_reg;
reg web_ctrl;
reg start_flag;
reg finish_read_flag;
reg start_flag_reg;
reg [4:0]medium_count;
reg [4:0]medium_count_reg;
reg [4:0]medium_count_reg_reg;
reg [4:0]medium_count_end;
//reg [7:0] in_00,in_01,in_02,in_03,in_04,in_05,in_06,in_07,in_07;
reg [7:0] in_0[0:8], in_1[0:8], in_2[0:8], in_3[0:8], in_4[0:8], in_5[0:8], in_6[0:8], in_7[0:8];
reg [7:0] in_8[0:8],in_9[0:8], in_10[0:8], in_11[0:8], in_12[0:8], in_13[0:8], in_14[0:8], in_15[0:8];
reg [7:0] in_0_reg[0:8], in_1_reg[0:8], in_2_reg[0:8], in_3_reg[0:8], in_4_reg[0:8], in_5_reg[0:8], in_6_reg[0:8], in_7_reg[0:8];
reg [7:0] in_8_reg[0:8],in_9_reg[0:8], in_10_reg[0:8], in_11_reg[0:8], in_12_reg[0:8], in_13_reg[0:8], in_14_reg[0:8], in_15_reg[0:8];
wire [7:0] out[0:15];
reg end_flag;
reg [3:0]y_count;
reg [3:0]y_count_reg; 
reg [7:0] cal_temp0;
reg [9:0] cal_temp1;
reg [7:0] cal_temp2;
reg [7:0] cal_temp0_reg;
reg [9:0] cal_temp1_reg;
reg [7:0] cal_temp2_reg;
reg [5:0] read_count;
reg [5:0] read_count_reg;
reg [7:0] image_reg;
reg [7:0] cal [0:15][0:15];
reg [7:0] cal_reg [0:15][0:15];
reg [7:0] cal_temp[0:1][0:15];
wire [7:0] max0[0:15];
wire [7:0] max1[0:15];
reg [7:0] max0_reg[0:15];
reg [7:0] max1_reg[0:15];
reg max_pool_flag;
reg [2:0] cnt_save;
reg [3:0] cnt_action;

//reg [3:0]curr_size;
//reg [3:0] curr_size_reg;
reg negative_flag;
reg flip_flag;
reg max_pool_ready;
reg [4:0] cross_x_count;
reg [4:0] cross_y_count;
reg [4:0] cross_cnt; 
reg [15:0] tempa,tempb,tempc,tempd,tempe,tempf;
reg [19:0] temp1,temp2,temp3,temp_sum,temp_sum_reg,out_temp;
reg [4:0] border;
reg midium_finish;
reg [2:0] max_counter;
wire set_flag;
//==================================================================
// FSM
//==================================================================

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cs_state <= IDLE;
    end
    else begin
        cs_state <= ns_state;
    end
end

always@(*) begin
    case(cs_state)
        IDLE: begin
            if( in_valid) begin
                ns_state = READ_IMG;
            end
            else begin
                ns_state = IDLE;
            end
        end
        READ_IMG: begin
            //if(image_address == addr_img_read_end) begin
            if(in_valid2&&local_count==0&&cal_count==2) begin////////////////////////////////////////////////////////////////////
                ns_state = ACTION_WAIT;
            end
            else 
            if(!in_valid&&local_count==0&&cal_count==2) begin
                ns_state = ACTION_WAIT;
            end
            else begin
                ns_state = READ_IMG;
            end
        end
        ACTION_WAIT: begin
            if(cnt_save!=0&&!in_valid2) begin
                ns_state = SAVE_ACTION;
            end
            else if(in_valid2) begin
                ns_state = SAVE_ACTION;
            end
            else begin
                ns_state = ACTION_WAIT;
            end
        end
        SAVE_ACTION: begin
            if(action_save[cnt_action]==3'd3&&finish_read_flag) begin
                ns_state = MAX_POOLING;//suppose to be maxpooling but i do medium first
            end
            else if(action_save[cnt_action]==3'd6&&finish_read_flag) begin
                ns_state = MEDIUM;
            end
            else if(action_save[cnt_action]==3'd7&&finish_read_flag) begin
                ns_state = CROSS;
            end
            else if ((action_save[cnt_action]==3'd4||action_save[cnt_action]==3'd5)&&finish_read_flag) begin
                ns_state = NEG_FLIP;
            end
            else begin
                ns_state = SAVE_ACTION;
            end
        end
        MAX_POOLING: begin
            if(action_save[cnt_action]==3'd3&&max_pool_ready) begin
                ns_state = MAX_POOLING;
            end
            else if(action_save[cnt_action]==3'd6&&max_pool_ready) begin
                ns_state = MEDIUM;
            end
            else if(action_save[cnt_action]==3'd7&&max_pool_ready) begin
                ns_state = CROSS;
            end
            else if ((action_save[cnt_action]==3'd4||action_save[cnt_action]==3'd5)&&max_pool_ready) begin
                ns_state = NEG_FLIP;
            end
            else begin
                ns_state = MAX_POOLING;
            end
        end
        MEDIUM: begin
            if(action_save[cnt_action]==3'd3&&midium_finish) begin//4//sppose to be maxpooling
                ns_state = MAX_POOLING;
            end
            else if(action_save[cnt_action]==3'd6&&midium_finish) begin//5
                ns_state = MEDIUM;
            end
            else if(action_save[cnt_action]==3'd7&&midium_finish) begin//6
                ns_state = CROSS;
            end
            else if((action_save[cnt_action]==3'd4||action_save[cnt_action]==3'd5)&&midium_finish) begin
                ns_state = NEG_FLIP;
            end
            else begin
                ns_state = MEDIUM;
            end
        end
        CROSS: begin   
            if(set_flag) begin
                ns_state = IDLE;
            end
            else if(end_flag && cross_cnt==19) begin
                ns_state = ACTION_WAIT;
            end
            else begin
                ns_state = CROSS;
            end
        end
        NEG_FLIP: begin
            if(action_save[cnt_action]==3'd3) begin
                ns_state = MAX_POOLING;
            end
            else if(action_save[cnt_action]==3'd6) begin
                ns_state = MEDIUM;
            end
            else if(action_save[cnt_action]==3'd7) begin
                ns_state = CROSS;
            end
            else if((action_save[cnt_action]==3'd4)||(action_save[cnt_action]==3'd5)) begin
                ns_state = NEG_FLIP;
            end
            else begin
                ns_state = MEDIUM;
            end
        end
        default: begin
            ns_state = IDLE;
        end
    endcase
end

//==================================================================
// design
//==================================================================

//==============================================//
//        Write Image and Kernel to SRAM        //
//==============================================//

assign set_flag = (set_count==4'd7 &&cs_state==CROSS&&ns_state!=CROSS)?1'b1:1'b0;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        set_count <= 4'd0;
    end
    else if(cs_state==IDLE) begin
        set_count <= 4'd0;
    end
    else if(cs_state==CROSS) begin
        if(set_count==8) begin
            set_count <= 4'd0;
        end
       /* else 
        if(set_flag) begin
            set_count <= 4'd0;
        end*/
        else if(cs_state== CROSS && ns_state!=CROSS) begin
            set_count <= set_count + 4'd1;
        end
        else begin
            set_count <= set_count;
        end
    end
    else begin
        set_count <= set_count;
    end
    
end 
//read image size
reg temp_finish;
reg [1:0]image_size_save;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        image_size_save <= 2'd3;
    end
    else if(in_valid &&  cs_state==IDLE) begin
        image_size_save <= image_size;
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        image_size_reg <= 2'd3;
    end
    else if(in_valid &&  cs_state==IDLE && cal_count==0) begin
        image_size_reg <= image_size;
    end
    else if(cs_state==ACTION_WAIT) begin
        image_size_reg <=image_size_save;
    end
    else if(image_size_reg==1) begin//8*8
        if(cs_state==MAX_POOLING && max_pool_ready) begin//suppose to be maxpooling
            image_size_reg<=0;
        end
    end
    else if(image_size_reg==2) begin
        if(cs_state==MAX_POOLING && max_pool_ready) begin//suppose to be maxpooling
            image_size_reg<=1;
        end
    end
    
end
// maximum image address
// matrix_size_reg = 2'd0 : global_count < 4 * 4 * 3 = 47
// matrix_size_reg = 2'd1 : global_count < 7 * 7 * 3 = 192
// matrix_size_reg = 2'd2 : global_count < 16 * 16 * 3 = 767
always@(*) begin
    if(image_size_reg == 2'd0) begin //47-1
        addr_img_read_end = 65;
    end
    else if(image_size_reg == 2'd1) begin//192-1
        addr_img_read_end = 71;
    end
    else  begin//767-1
        addr_img_read_end = 95;
    end
end
 always@(*) begin
    if(cs_state==SAVE_ACTION||cs_state==IDLE) begin
        max_pool_ready = 1'b0;
    end
    else if(cs_state==MAX_POOLING) begin
         if((image_size_reg==1 ||image_size_reg==0 )&&max_counter ==2) begin//2do3up
             max_pool_ready = 1'b1;
         end
         else if(image_size_reg==2 && max_counter==4) begin//2and3do4up
             max_pool_ready = 1'b1;
         end
         else begin
             max_pool_ready = 1'b0;
         end
     end
    else begin
        max_pool_ready = 1'b0;
    end
 end
 /*
 always@(posedge clk or negedge rst_n) begin
     if(!rst_n) begin
         max_pool_ready <= 1'b0;
     end
     else if(cs_state==MAX_POOLING) begin
         if(image_size_reg==1 ||image_size_reg==0 ) begin
             max_pool_ready <= 1'b1;
         end
         else if(image_size_reg==2 && max_counter==3) begin//notsure
             max_pool_ready <= 1'b1;
         end
         else begin
             max_pool_ready <= 1'b0;
         end
     end
     else begin
         max_pool_ready <= 1'b0;
     end
 end*/
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        control_count <= 0;
    // read image
    end 
    else if(cs_state==READ_IMG) begin
        if(image_size_reg==0 &&control_count==3'd1&&local_count==3'd7&&cal_count==2) begin//0~1
            control_count <= 5'd0;
        end
        else if(image_size_reg==1 &&control_count==5'd7&&local_count==3'd7&&cal_count==2) begin//0~7
            control_count <= 5'd0;
        end
        else if(image_size_reg==2 &&control_count==5'd31&&local_count==3'd7&&cal_count==2) begin//0~31
            control_count <= 5'd0;
        end
        else if(local_count==3'd7&&cal_count==2)begin
            control_count <= control_count + 5'd1;
        end
        
    end 
    else begin
        control_count <= 0;
    end
end
reg [4:0] control_count_reg;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        control_count_reg <= 0;
    end
    else if(local_count==0&&cal_count==2) begin
        control_count_reg <= control_count;
    end
    
end
always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            temp_finish <= 1'b0;
        end
        else if(local_count==3'd7 && cal_count==2) begin
            temp_finish <= 1'b1;
        end
        else if(local_count==3'd0 && cal_count==2)begin
            temp_finish <= 1'b0;
        end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        local_count <= 3'd0;
    // read image
    end 
    else if(cs_state==READ_IMG) begin
        if(local_count==3'd7 && cal_count==2) begin
            local_count <= 3'd0;
        end
        else if(cal_count==2)begin
            local_count <= local_count + 1;
        end
        
    end 
    else begin
        local_count <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cal_count <= 3'd0;
    end
    else if(cs_state==READ_IMG) begin
        if(cal_count==3'd2) begin
            cal_count <= 3'd0;
        end
        else begin
           cal_count <= cal_count + 3'd1; 
        end
    end
    else begin
        cal_count <= 3'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        image_reg <= 8'b0;
    end
    else begin
        if(in_valid)begin
            image_reg <= image;
        end
        else begin
            image_reg <= 0;
        end
    end
    
end

always@(*) begin
    for(i=0;i<=15;i=i+1) begin
        for(j=0;j<=15;j=j+1) begin
            cal[i][j] = cal_reg[i][j];
        end
    end
    if(cs_state==READ_IMG) begin
        if(cal_count==2) begin
            cal[0][local_count] = cal_temp0;/////////////////////////////////////////////////////////////////
            cal[1][local_count] = cal_temp1;
            cal[2][local_count] = cal_temp2; 
        end
    end
    else if(cs_state==SAVE_ACTION)begin//constrol by read_count
        case(image_size_reg) 
            2'd0: begin
                if(read_count_reg==0) begin//2
                    cal[0][0] = {data_out_img[63], data_out_img[62], data_out_img[61], data_out_img[60], data_out_img[59], data_out_img[58], data_out_img[57], data_out_img[56]};
                    cal[0][1] = {data_out_img[55], data_out_img[54], data_out_img[53], data_out_img[52], data_out_img[51], data_out_img[50], data_out_img[49], data_out_img[48]};
                    cal[0][2] = {data_out_img[47], data_out_img[46], data_out_img[45], data_out_img[44], data_out_img[43], data_out_img[42], data_out_img[41], data_out_img[40]};
                    cal[0][3] = {data_out_img[39], data_out_img[38], data_out_img[37], data_out_img[36], data_out_img[35], data_out_img[34], data_out_img[33], data_out_img[32]};
                    cal[1][0] = {data_out_img[31], data_out_img[30], data_out_img[29], data_out_img[28], data_out_img[27], data_out_img[26], data_out_img[25], data_out_img[24]};
                    cal[1][1] = {data_out_img[23], data_out_img[22], data_out_img[21], data_out_img[20], data_out_img[19], data_out_img[18], data_out_img[17], data_out_img[16]};
                    cal[1][2] = {data_out_img[15], data_out_img[14], data_out_img[13], data_out_img[12], data_out_img[11], data_out_img[10], data_out_img[9], data_out_img[8]};
                    cal[1][3] = {data_out_img[7], data_out_img[6], data_out_img[5], data_out_img[4], data_out_img[3], data_out_img[2], data_out_img[1], data_out_img[0]};
                end
                else if(read_count_reg==1)begin
                    cal[2][0] = {data_out_img[63], data_out_img[62], data_out_img[61], data_out_img[60], data_out_img[59], data_out_img[58], data_out_img[57], data_out_img[56]};
                    cal[2][1] = {data_out_img[55], data_out_img[54], data_out_img[53], data_out_img[52], data_out_img[51], data_out_img[50], data_out_img[49], data_out_img[48]};
                    cal[2][2] = {data_out_img[47], data_out_img[46], data_out_img[45], data_out_img[44], data_out_img[43], data_out_img[42], data_out_img[41], data_out_img[40]};
                    cal[2][3] = {data_out_img[39], data_out_img[38], data_out_img[37], data_out_img[36], data_out_img[35], data_out_img[34], data_out_img[33], data_out_img[32]};
                    cal[3][0] = {data_out_img[31], data_out_img[30], data_out_img[29], data_out_img[28], data_out_img[27], data_out_img[26], data_out_img[25], data_out_img[24]};
                    cal[3][1] = {data_out_img[23], data_out_img[22], data_out_img[21], data_out_img[20], data_out_img[19], data_out_img[18], data_out_img[17], data_out_img[16]};
                    cal[3][2] = {data_out_img[15], data_out_img[14], data_out_img[13], data_out_img[12], data_out_img[11], data_out_img[10], data_out_img[9], data_out_img[8]};
                    cal[3][3] = {data_out_img[7], data_out_img[6], data_out_img[5], data_out_img[4], data_out_img[3], data_out_img[2], data_out_img[1], data_out_img[0]};
                end
            end
            2'd1: begin//7
                    cal[read_count_reg][0] = {data_out_img[63], data_out_img[62], data_out_img[61], data_out_img[60], data_out_img[59], data_out_img[58], data_out_img[57], data_out_img[56]};
                    cal[read_count_reg][1] = {data_out_img[55], data_out_img[54], data_out_img[53], data_out_img[52], data_out_img[51], data_out_img[50], data_out_img[49], data_out_img[48]};
                    cal[read_count_reg][2] = {data_out_img[47], data_out_img[46], data_out_img[45], data_out_img[44], data_out_img[43], data_out_img[42], data_out_img[41], data_out_img[40]};
                    cal[read_count_reg][3] = {data_out_img[39], data_out_img[38], data_out_img[37], data_out_img[36], data_out_img[35], data_out_img[34], data_out_img[33], data_out_img[32]};
                    cal[read_count_reg][4] = {data_out_img[31], data_out_img[30], data_out_img[29], data_out_img[28], data_out_img[27], data_out_img[26], data_out_img[25], data_out_img[24]};
                    cal[read_count_reg][5] = {data_out_img[23], data_out_img[22], data_out_img[21], data_out_img[20], data_out_img[19], data_out_img[18], data_out_img[17], data_out_img[16]};
                    cal[read_count_reg][6] = {data_out_img[15], data_out_img[14], data_out_img[13], data_out_img[12], data_out_img[11], data_out_img[10], data_out_img[9], data_out_img[8]};
                    cal[read_count_reg][7] = {data_out_img[7], data_out_img[6], data_out_img[5], data_out_img[4], data_out_img[3], data_out_img[2], data_out_img[1], data_out_img[0]};
               // cal[read_count] = data_out_img;
            end
            2'd2:begin//32
                if(!read_count_reg[0])begin
                    cal[read_count_reg>>1][0] = {data_out_img[63], data_out_img[62], data_out_img[61], data_out_img[60], data_out_img[59], data_out_img[58], data_out_img[57], data_out_img[56]};
                    cal[read_count_reg>>1][1] = {data_out_img[55], data_out_img[54], data_out_img[53], data_out_img[52], data_out_img[51], data_out_img[50], data_out_img[49], data_out_img[48]};
                    cal[read_count_reg>>1][2] = {data_out_img[47], data_out_img[46], data_out_img[45], data_out_img[44], data_out_img[43], data_out_img[42], data_out_img[41], data_out_img[40]};
                    cal[read_count_reg>>1][3] = {data_out_img[39], data_out_img[38], data_out_img[37], data_out_img[36], data_out_img[35], data_out_img[34], data_out_img[33], data_out_img[32]};
                    cal[read_count_reg>>1][4] = {data_out_img[31], data_out_img[30], data_out_img[29], data_out_img[28], data_out_img[27], data_out_img[26], data_out_img[25], data_out_img[24]};
                    cal[read_count_reg>>1][5] = {data_out_img[23], data_out_img[22], data_out_img[21], data_out_img[20], data_out_img[19], data_out_img[18], data_out_img[17], data_out_img[16]};
                    cal[read_count_reg>>1][6] = {data_out_img[15], data_out_img[14], data_out_img[13], data_out_img[12], data_out_img[11], data_out_img[10], data_out_img[9], data_out_img[8]};
                    cal[read_count_reg>>1][7] = {data_out_img[7], data_out_img[6], data_out_img[5], data_out_img[4], data_out_img[3], data_out_img[2], data_out_img[1], data_out_img[0]};
                end
                else begin 
                    cal[read_count_reg >>1][8] = {data_out_img[63], data_out_img[62], data_out_img[61], data_out_img[60], data_out_img[59], data_out_img[58], data_out_img[57], data_out_img[56]};
                    cal[read_count_reg >>1][9] = {data_out_img[55], data_out_img[54], data_out_img[53], data_out_img[52], data_out_img[51], data_out_img[50], data_out_img[49], data_out_img[48]};
                    cal[read_count_reg >>1][10] = {data_out_img[47], data_out_img[46], data_out_img[45], data_out_img[44], data_out_img[43], data_out_img[42], data_out_img[41], data_out_img[40]};
                    cal[read_count_reg >>1][11] = {data_out_img[39], data_out_img[38], data_out_img[37], data_out_img[36], data_out_img[35], data_out_img[34], data_out_img[33], data_out_img[32]};
                    cal[read_count_reg >>1][12] = {data_out_img[31], data_out_img[30], data_out_img[29], data_out_img[28], data_out_img[27], data_out_img[26], data_out_img[25], data_out_img[24]};
                    cal[read_count_reg >>1][13] = {data_out_img[23], data_out_img[22], data_out_img[21], data_out_img[20], data_out_img[19], data_out_img[18], data_out_img[17], data_out_img[16]};
                    cal[read_count_reg >>1][14] = {data_out_img[15], data_out_img[14], data_out_img[13], data_out_img[12], data_out_img[11], data_out_img[10], data_out_img[9], data_out_img[8]};
                    cal[read_count_reg >>1][15] = {data_out_img[7], data_out_img[6], data_out_img[5], data_out_img[4], data_out_img[3], data_out_img[2], data_out_img[1], data_out_img[0]};
            
                end
            end
        endcase
    end
    
    else if(cs_state==MEDIUM) begin
        
           if(image_size_reg==0) begin///
                cal[0][0] = cal_temp[0][0];   cal[1][0] = cal_temp[0][4];    cal[2][0] = cal_temp[0][8];    cal[3][0] = cal_temp[0][12]; 
                cal[0][1] = cal_temp[0][1];   cal[1][1] = cal_temp[0][5];    cal[2][1] = cal_temp[0][9];    cal[3][1] = cal_temp[0][13];
                cal[0][2] = cal_temp[0][2];   cal[1][2] = cal_temp[0][6];    cal[2][2] = cal_temp[0][10];   cal[3][2] = cal_temp[0][14];
                cal[0][3] = cal_temp[0][3];   cal[1][3] = cal_temp[0][7];    cal[2][3] = cal_temp[0][11];   cal[3][3] = cal_temp[0][15];
            end
            else if(image_size_reg==1) begin
                case(medium_count)
                    3: begin
                        for(i=0;i<=7;i=i+1) begin
                            cal[0][i] = cal_temp[0][i];
                            cal[1][i] = cal_temp[0][i+8];
                        end
                    end
                    4:begin
                        for(i=0;i<=7;i=i+1) begin
                            cal[2][i] = cal_temp[1][i];
                            cal[3][i] = cal_temp[1][i+8];
                        end
                    end
                    5:begin
                        for(i=0;i<=7;i=i+1) begin
                            cal[4][i] = cal_temp[0][i];
                            cal[5][i] = cal_temp[0][i+8];
                        end
                    end
                    6:begin
                        for(i=0;i<=7;i=i+1) begin
                            cal[6][i] = cal_temp[1][i];
                            cal[7][i] = cal_temp[1][i+8];
                        end
                    end
                endcase 
            end   
            else if(image_size_reg==2) begin//notdone
            case(medium_count) 
                3,5,7,9,11,13,15,17,19: begin
                    for(i=0;i<=15;i=i+1) begin
                        cal[medium_count-3][i] = cal_temp[0][i];
                    end 
                end
                4,6,8,10,12,14,16,18: begin
                    for(i=0;i<=15;i=i+1) begin
                        cal[medium_count-3][i] = cal_temp[1][i];
                    end 
                end
            endcase
            end
    end
    else if(cs_state==MAX_POOLING) begin
        if(image_size_reg==0) begin
            for(i=0;i<=3;i=i+1) begin
                for(j=0;j<=3;j=j+1) begin
                    cal[i][j] = cal_reg[i][j];
                end
            end
        end
        else if(image_size_reg==1) begin
            cal[0][0] = max0_reg[0]; cal[0][1] = max0_reg[1]; cal[0][2] = max0_reg[2]; cal[0][3] = max0_reg[3]; cal[2][0] = max0_reg[4]; cal[2][1] = max0_reg[5]; cal[2][2] = max0_reg[6]; cal[2][3] = max0_reg[7];
            cal[1][0] = max1_reg[0]; cal[1][1] = max1_reg[1]; cal[1][2] = max1_reg[2]; cal[1][3] = max1_reg[3]; cal[3][0] = max1_reg[4]; cal[3][1] = max1_reg[5]; cal[3][2] = max1_reg[6]; cal[3][3] = max1_reg[7];
            if(max_pool_ready) begin
                cal = cal_reg;
                for(integer i=4;i<=15;i=i+1) begin
                    for(integer j=0;j<=15;j=j+1) begin
                        cal[i][j] = 0;                
                end
                end
                for(integer i=0;i<=3;i=i+1) begin
                    for(integer j=4;j<=15;j=j+1) begin
                        cal[i][j] = 0;                
                end
                end
            end
        end
        else if(image_size_reg==2) begin   
             //if(max_pool_flag==0) begin
             if(max_counter==2) begin
                cal[0][0] = max0_reg[0]; cal[0][1] = max0_reg[1]; cal[0][2] = max0_reg[2]; cal[0][3] = max0_reg[3]; cal[0][4] = max0_reg[8]; cal[0][5] = max0_reg[9]; cal[0][6] = max0_reg[10]; cal[0][7] = max0_reg[11];
                cal[1][0] = max1_reg[0]; cal[1][1] = max1_reg[1]; cal[1][2] = max1_reg[2]; cal[1][3] = max1_reg[3]; cal[1][4] = max1_reg[8]; cal[1][5] = max1_reg[9]; cal[1][6] = max1_reg[10]; cal[1][7] = max1_reg[11];
                cal[2][0] = max0_reg[4]; cal[2][1] = max0_reg[5]; cal[2][2] = max0_reg[6]; cal[2][3] = max0_reg[7]; cal[2][4] = max0_reg[12]; cal[2][5] = max0_reg[13]; cal[2][6] = max0_reg[14]; cal[2][7] = max0_reg[15]; 
                cal[3][0] = max1_reg[4]; cal[3][1] = max1_reg[5]; cal[3][2] = max1_reg[6]; cal[3][3] = max1_reg[7]; cal[3][4] = max1_reg[12]; cal[3][5] = max1_reg[13]; cal[3][6] = max1_reg[14]; cal[3][7] = max1_reg[15];
             end
             else if(max_counter==3)begin
                cal = cal_reg;
                cal[4][0] = max0_reg[0]; cal[4][1] = max0_reg[1]; cal[4][2] = max0_reg[2]; cal[4][3] = max0_reg[3]; cal[4][4] = max0_reg[8]; cal[4][5] = max0_reg[9]; cal[4][6] = max0_reg[10]; cal[4][7] = max0_reg[11];
                cal[5][0] = max1_reg[0]; cal[5][1] = max1_reg[1]; cal[5][2] = max1_reg[2]; cal[5][3] = max1_reg[3]; cal[5][4] = max1_reg[8]; cal[5][5] = max1_reg[9]; cal[5][6] = max1_reg[10]; cal[5][7] = max1_reg[11];
                cal[6][0] = max0_reg[4]; cal[6][1] = max0_reg[5]; cal[6][2] = max0_reg[6]; cal[6][3] = max0_reg[7]; cal[6][4] = max0_reg[12]; cal[6][5] = max0_reg[13]; cal[6][6] = max0_reg[14]; cal[6][7] = max0_reg[15]; 
                cal[7][0] = max1_reg[4]; cal[7][1] = max1_reg[5]; cal[7][2] = max1_reg[6]; cal[7][3] = max1_reg[7]; cal[7][4] = max1_reg[12]; cal[7][5] = max1_reg[13]; cal[7][6] = max1_reg[14]; cal[7][7] = max1_reg[15];
             end   
            if(max_pool_ready) begin
                    cal = cal_reg;
                    for(integer i=8;i<=15;i=i+1) begin
                        for(integer j=0;j<=15;j=j+1) begin
                            cal[i][j] = 0;                
                        end
                    end
                    for(integer i=0;i<=7;i=i+1) begin
                        for(integer j=8;j<=15;j=j+1) begin
                            cal[i][j] = 0;                
                        end
                    end
                   
            end
            
        end
    end
    else if(cs_state==NEG_FLIP) begin
        if(action_save[cnt_action-1]==3'd5) begin
        for(i=0;i<=border;i=i+1) begin
            for(j=0;j<=border;j=j+1) begin
                cal[i][j] = cal_reg[i][border-j];
            end
        end
        end
        else if(action_save[cnt_action-1]==3'd4) begin
            for(i=0;i<=border;i=i+1) begin
                for(j=0;j<=border;j=j+1) begin
                    cal[i][j] = ~cal_reg[i][j];
                end
            end
        end
    end
end   

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<=15;i=i+1) begin
            for(j=0;j<=15;j=j+1) begin
                cal_reg[i][j] <= 0;
            end
        end
    end
    else if(cs_state==IDLE) begin
         for(i=0;i<=15;i=i+1) begin
            for(j=0;j<=15;j=j+1) begin
                cal_reg[i][j] <= 0;
            end
        end    
    end
    else if(cs_state==ACTION_WAIT) begin
         for(i=0;i<=15;i=i+1) begin
            for(j=0;j<=15;j=j+1) begin
                cal_reg[i][j] <= 0;
            end
        end    
    end
    else  begin
         for(i=0;i<=15;i=i+1) begin
            for(j=0;j<=15;j=j+1) begin
                cal_reg[i][j] <= cal[i][j];
            end
        end    
    end
end

always@(*) begin
    if(cs_state==SAVE_ACTION&&!in_valid2) begin
       case (image_size_reg)
        2'd0: begin
            if(read_count==2) begin
                finish_read_flag = 1'b1;
            end
            else begin
                finish_read_flag = 1'b0;
            end
        end
        2'd1: begin
            if(read_count==8) begin
                finish_read_flag = 1'b1;
            end
            else begin
                finish_read_flag = 1'b0;
            end
        end
        2'd2: begin
            if(read_count==32) begin
                finish_read_flag = 1'b1;
            end
            else begin
                finish_read_flag = 1'b0;
            end
        end
        default: begin
            finish_read_flag = 1'b0;
        end
        endcase 
    end
    else begin
        finish_read_flag = 1'b0;
    end
    
end
always@(*) begin
    
   // if(cs_state==SAVE_ACTION&&start_flag_reg) begin
    if(cs_state==SAVE_ACTION&&start_flag) begin///////////////////////////////////////////////////////////////////////////////
      //  read_count = read_count_reg + 3'd1;
        case (image_size_reg)
            2'd0: begin
                if(read_count_reg==2) begin//2cycle
                    read_count = 0;
                end
                else begin
                    read_count = read_count_reg + 3'd1;
                end
            end
            2'd1: begin
                if(read_count_reg==8) begin//7cycle
                    read_count = 0;
                end
                else begin
                    read_count = read_count_reg + 3'd1;
                end
            end
            2'd2: begin
                if(read_count_reg==32) begin//32cycle
                    read_count = 0;
                end
                else begin
                    read_count = read_count_reg + 3'd1;
                end
            end 
            default: begin
                read_count = 0;
            end
        endcase    
    end
    else begin
        read_count = read_count_reg ;
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        read_count_reg <= 3'b0;
    end
    else begin
        if(cs_state==IDLE||cs_state == ACTION_WAIT) begin
            read_count_reg <= 3'b0;
        end
        else  begin
            read_count_reg <= read_count;
        end
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cal_temp0_reg <= 0;
    end
    else if(cs_state ==ACTION_WAIT||cs_state == IDLE) begin
        cal_temp0_reg <= 0;
    end
    else begin
        cal_temp0_reg <= cal_temp0;
    end
    
end
always@(*) begin
    
    if(cs_state==READ_IMG) begin
        case (cal_count)
        0: cal_temp0 = image_reg;
        1: begin
            if(image_reg>cal_temp0_reg) begin
                cal_temp0 = image_reg;
            end
            else begin
                cal_temp0 = cal_temp0_reg;
            end
        end
        2: begin
            if(image_reg>cal_temp0_reg) begin
                cal_temp0 = image_reg;
            end
            else begin
                cal_temp0 = cal_temp0_reg;
            end
        end
        default: begin
            cal_temp0 = cal_temp0_reg;
        end
    endcase
    end
    else begin
        cal_temp0 = cal_temp0_reg;
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cal_temp1_reg <= 0;
    end
    else if(cs_state ==ACTION_WAIT||cs_state == IDLE) begin
        cal_temp1_reg <= 0;
    end
    else begin
        cal_temp1_reg <= cal_temp1;
    end
end
always@(*) begin
    if(cs_state==READ_IMG) begin
       case(cal_count)
        0: cal_temp1 = image_reg;
        1: begin
           cal_temp1 = cal_temp1_reg + image_reg;
        end
        2: begin
           cal_temp1 = (cal_temp1_reg + image_reg)/3;
        end
        default: begin
            cal_temp1 = cal_temp1_reg;
        end
    endcase 
    end
    else begin
        cal_temp1 = cal_temp1_reg;
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cal_temp2_reg <= 0;
    end
    else if(cs_state ==ACTION_WAIT||cs_state == IDLE) begin
        cal_temp2_reg <= 0;
    end
    else begin
        cal_temp2_reg <= cal_temp2;
    end
end
always@(*) begin
    if(cs_state==READ_IMG) begin
        case(cal_count)
        0: cal_temp2 = image_reg/4;
        1: begin
           cal_temp2 = cal_temp2_reg + image_reg/2;
        end
        2: begin
           cal_temp2 = cal_temp2_reg + image_reg/4;
        end
        default: begin
            cal_temp2 = cal_temp2_reg;
        end
    endcase 
    end
    else begin
        cal_temp2 = cal_temp2_reg;
    end
end

always@(*) begin
    data_in = data_in_reg;
    if(cs_state==READ_IMG) begin
        if(temp_finish) begin
           case (cal_count)
                0: begin
                    data_in = {cal_reg[0][0], cal_reg[0][1], cal_reg[0][2], cal_reg[0][3], cal_reg[0][4], cal_reg[0][5], cal_reg[0][6], cal_reg[0][7]};
                end
                1:begin
                    data_in = {cal_reg[1][0], cal_reg[1][1], cal_reg[1][2], cal_reg[1][3], cal_reg[1][4], cal_reg[1][5], cal_reg[1][6], cal_reg[1][7]};//(red+green+blue)/3
                end
                2:begin
                    data_in = {cal_reg[2][0], cal_reg[2][1], cal_reg[2][2], cal_reg[2][3], cal_reg[2][4], cal_reg[2][5], cal_reg[2][6], cal_reg[2][7]};//red/4+green/2+blue/4
                end
            endcase   
        end
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_in_reg <= 64'b0;
    end
    else begin
        if(cs_state==IDLE) begin
            data_in_reg <= 64'b0;
        end
        else if(cs_state==READ_IMG) begin
            data_in_reg <= data_in;
        end
        else begin
            data_in_reg <= 64'b0;
        end
    end
end


always@(*) begin
   
    if(cs_state==READ_IMG) begin//write
        if(temp_finish) begin
            case (cal_count)
            0: begin
                image_address = control_count_reg;//0
            end
            1:begin
                image_address = control_count_reg+'d32;
            end
            2:begin
                image_address = control_count_reg+'d64;
            end
            default: begin
                image_address = image_address_reg;//////////////////////////////////////////////////////////////////////
            end
            endcase 
        end
        else begin
            image_address = image_address_reg;//////////////////////////////////////////////////////////////////////
        end
    end
    else if(cs_state==SAVE_ACTION) begin//control by sizereg//012//read_count//r
            if(action_save[0]==0) begin//0
                image_address = read_count;
                
            end
            else if(action_save[0]==1) begin
                image_address = read_count + 'd32;
            end
            else if(action_save[0]==2) begin
                image_address = read_count + 'd64;
            end
            else begin
                image_address = 0;//////////////////////////////////////////////////////////////////////
            end
    end
    else begin
         image_address = image_address_reg;//////////////////////////////////////////////////////////////////////
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        image_address_reg <= 6'b0;
    end
    else begin
    if(cs_state==IDLE) begin
        image_address_reg <= 6'b0;
    end
    else if(cs_state==READ_IMG) begin
        image_address_reg <= image_address;
    end
    else if(cs_state == SAVE_ACTION) begin
        image_address_reg <= image_address;
    end
    else begin
        image_address_reg <= 0;//////////////////////////////////////////////////////////////////////
    end
    end
end

always@(*) begin
    if(cs_state==READ_IMG) begin//
        web_ctrl = 1'b0;
    end
    else  begin//read
        web_ctrl = 1'b1;
    end
    
end
/*
always@(posedge clk) begin
    if(cs_state==SAVE_ACTION) begin//read
        web_ctrl <= 1'b1;
    end
    else  begin//write
        web_ctrl <= 1'b0;
    end
end*/
// 96*64 single-port SRAM for image
// 10-bit address, 7-bit data
// mem_img m0(.clk(clk), .addr(global_count), .data_in(data_in), .WEB(web_img), .data_out(data_out_img));
sram_128x64_inst m0(.A(image_address), .DO(data_out_img), .DI(data_in), .CK(clk), .WEB(web_ctrl), .OE(1'b1), .CS(1'b1));
//==================================================================
// ACTION
//==================================================================

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        cnt_save <= 0;
    end
    else begin
        if(in_valid2) cnt_save <= cnt_save + 1;
        else cnt_save <= 0;
    end
end


always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        cnt_action <= 1;
    end
    else begin
        if(cs_state == SAVE_ACTION) begin
            cnt_action <= (finish_read_flag) ? cnt_action + 1 : cnt_action;
        end
        else if(cs_state == CROSS&&(ns_state==IDLE||ns_state==ACTION_WAIT))begin
            cnt_action <= 1;
        end
        
        else begin
            case (cs_state)
                4: cnt_action <= ((image_size_reg == 0&&max_pool_ready )|| (image_size_reg == 1 &&max_pool_ready) || (image_size_reg == 2 && max_pool_ready) ) ? cnt_action + 1 : cnt_action;
                5: cnt_action <= (midium_finish ) ? cnt_action + 1 : cnt_action;
                7: cnt_action <= cnt_action + 1;
                default: cnt_action <= cnt_action ;
            endcase
            /*
            case (action_save[cnt_action])
                3: cnt_action <= ((image_size_reg == 0&&max_pool_ready )|| (image_size_reg == 1 &&max_pool_ready) || (image_size_reg == 2 && max_pool_ready) ) ? cnt_action + 1 : cnt_action;
                4: cnt_action <= cnt_action + 1; 
                5: cnt_action <= cnt_action + 1;
                6: cnt_action <= (midium_finish ) ? cnt_action + 1 : cnt_action;
                default: cnt_action <= cnt_action ;
            endcase*/
        end
        
    end
end

always@(posedge clk or negedge rst_n) begin//how to remember maxpooling and medium
    if(~rst_n)begin
        for(integer i = 0; i < 8; i = i + 1) begin
            action_save[i] <= 0;
        end
    end
    else begin
        if(in_valid2)begin
            action_save[cnt_save] <= action;
        end
        else if(cs_state == CROSS)begin
            for(integer i = 0; i < 8; i = i + 1) begin
                action_save[i] <= 0;
            end
        end
        else action_save <= action_save;
    end
    
    
end
/*
always@(*) begin
    start_flag = start_flag_reg;
    if(cs_state==SAVE_ACTION&&(action_save[0]==0||action_save[0]==1||action_save[0]==2)) begin//until first element is zero
        start_flag=1'b1;
    end
    else begin
        start_flag = 1'b0;
    end
   
end
always@(posedge clk) begin
    if(cs_state==IDLE) begin
        start_flag_reg <= 1'b0;
    end
    else begin
       start_flag_reg <= start_flag; 
    end
end*/
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        start_flag <= 1'b0;
    end
    else if(cs_state==IDLE) begin
        start_flag <= 1'b0;
    end
    else if(cs_state==SAVE_ACTION) begin
        case(image_size_reg)
        0: begin    
            if(read_count==2) begin
                start_flag <= 1'b0;
            end  
            else begin
                start_flag <= 1'b1;
            end             
        end
        1: begin    
            if(read_count==8) begin
                start_flag <= 1'b0;
            end  
            else begin
                start_flag <= 1'b1;
            end             
        end                //8
        2: begin    
            if(read_count==32) begin
                start_flag <= 1'b0;
            end  
            else begin
                start_flag <= 1'b1;
            end             
        end
        endcase
    end
    else begin
        start_flag <= 1'b0;
    end
end
//==================================================================
// MAX-POOLING
//==================================================================
//==================================================================
// MEDIUM
//==================================================================


always@(*) begin//not sure
    if(image_size_reg==0) begin //4*4
        medium_count_end = 3;
    end
    else if(image_size_reg==1) begin//8*8
        medium_count_end = 6;
    end
    else  begin//767-1
        medium_count_end = 18;
    end
end
always@(*) begin
    if(cs_state==ACTION_WAIT) begin
        midium_finish=0;
    end
    else if(medium_count==medium_count_end) begin
            midium_finish =1;
        end
    else begin
            midium_finish=0;
    end
end
/*
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        midium_finish<=0;
    end
    else if(cs_state==ACTION_WAIT) begin
        midium_finish<=0;
    end
    else begin
        if(medium_count==medium_count_end) begin
            midium_finish <=1;
        end
        else begin
            midium_finish<=0;
        end
    end
end*/

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        max_counter<=3'b00;
    end
    else if(max_pool_ready) begin
        max_counter<=3'd0;
    end
    else if(cs_state==MAX_POOLING&&(image_size_reg==1||image_size_reg==0)) begin
        max_counter <= max_counter+3'd1;
    end
    else if(cs_state==MAX_POOLING&&image_size_reg==2) begin
        max_counter <= max_counter+3'd1;
    end
    else begin
        max_counter <= 3'b0;
    end
end

always@(*) begin
    medium_count = medium_count_reg ;
    if(cs_state==MEDIUM) begin
        if(medium_count_reg==medium_count_end) begin//16cycle
            medium_count = 5'd1;
        end
        else begin
            medium_count = medium_count_reg + 5'd1;
        end        
    end
    else begin
        medium_count = 5'b0;
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        medium_count_reg <= 5'b0;
    end
    else if(cs_state==IDLE) begin
        medium_count_reg <= 5'b0;
    end
    else  begin
        medium_count_reg <= medium_count;
    end
end

always@(*) begin
    y_count = y_count_reg;
    if(cs_state==MEDIUM) begin
        if(image_size_reg==1) begin
            /*case(medium_count_reg)
                0: y_count = 0;
                1: y_count = 1;
                2: y_count = 3;
                3: y_count = 5;
            endcase*/
            case(medium_count)
                2: y_count = 1;
                3: y_count = 3;
                default: y_count = 0;
            endcase
        end
        else if(image_size_reg==2) begin
            y_count = medium_count - 2;
        end
    end
    else begin
        y_count = 4'b0;
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        y_count_reg <= 4'b0;
    end
    else if(cs_state==IDLE) begin
        y_count_reg <= 4'b0;
    end
    else  begin
        y_count_reg <= y_count;
    end
end
always@(*) begin
     for(i=0;i<=8;i=i+1) begin 
            in_0[i]= in_0_reg[i];in_1[i]= in_1_reg[i];in_2[i]= in_2_reg[i];in_3[i]= in_3_reg[i];in_4[i]= in_4_reg[i];in_5[i]= in_5_reg[i];
            in_6[i]= in_6_reg[i];in_7[i]= in_7_reg[i];in_8[i]= in_8_reg[i];in_9[i]= in_9_reg[i];in_10[i]= in_10_reg[i];in_11[i]= in_11_reg[i];
            in_12[i]= in_12_reg[i];in_13[i]= in_13_reg[i];in_14[i]= in_14_reg[i];in_15[i]= in_15_reg[i];
        end
    if(cs_state==MEDIUM) begin
       if (image_size_reg==0) begin//4*4
            in_0[0] = cal_reg[0][0];   in_1[0] = cal_reg[0][0];    in_2[0] = cal_reg[0][1];    in_3[0] = cal_reg[0][2];    in_4[0] = cal_reg[0][0];   in_5[0] = cal_reg[0][0];    in_6[0] = cal_reg[0][1];    in_7[0] = cal_reg[0][2];      
            in_0[1] = cal_reg[0][0];   in_1[1] = cal_reg[0][1];    in_2[1] = cal_reg[0][2];    in_3[1] = cal_reg[0][3];    in_4[1] = cal_reg[0][0];   in_5[1] = cal_reg[0][1];    in_6[1] = cal_reg[0][2];    in_7[1] = cal_reg[0][3]; 
            in_0[2] = cal_reg[0][1];   in_1[2] = cal_reg[0][2];    in_2[2] = cal_reg[0][3];    in_3[2] = cal_reg[0][3];    in_4[2] = cal_reg[0][1];   in_5[2] = cal_reg[0][2];    in_6[2] = cal_reg[0][3];    in_7[2] = cal_reg[0][3]; 
            in_0[3] = cal_reg[0][0];   in_1[3] = cal_reg[0][0];    in_2[3] = cal_reg[0][1];    in_3[3] = cal_reg[0][2];    in_4[3] = cal_reg[1][0];   in_5[3] = cal_reg[1][0];    in_6[3] = cal_reg[1][1];    in_7[3] = cal_reg[1][2]; 
            in_0[4] = cal_reg[0][0];   in_1[4] = cal_reg[0][1];    in_2[4] = cal_reg[0][2];    in_3[4] = cal_reg[0][3];    in_4[4] = cal_reg[1][0];   in_5[4] = cal_reg[1][1];    in_6[4] = cal_reg[1][2];    in_7[4] = cal_reg[1][3]; 
            in_0[5] = cal_reg[0][1];   in_1[5] = cal_reg[0][2];    in_2[5] = cal_reg[0][3];    in_3[5] = cal_reg[0][3];    in_4[5] = cal_reg[1][1];   in_5[5] = cal_reg[1][2];    in_6[5] = cal_reg[1][3];    in_7[5] = cal_reg[1][3]; 
            in_0[6] = cal_reg[1][0];   in_1[6] = cal_reg[1][0];    in_2[6] = cal_reg[1][1];    in_3[6] = cal_reg[1][2];    in_4[6] = cal_reg[2][0];   in_5[6] = cal_reg[2][0];    in_6[6] = cal_reg[2][1];    in_7[6] = cal_reg[2][2]; 
            in_0[7] = cal_reg[1][0];   in_1[7] = cal_reg[1][1];    in_2[7] = cal_reg[1][2];    in_3[7] = cal_reg[1][3];    in_4[7] = cal_reg[2][0];   in_5[7] = cal_reg[2][1];    in_6[7] = cal_reg[2][2];    in_7[7] = cal_reg[2][3]; 
            in_0[8] = cal_reg[1][1];   in_1[8] = cal_reg[1][2];    in_2[8] = cal_reg[1][3];    in_3[8] = cal_reg[1][3];    in_4[8] = cal_reg[2][1];   in_5[8] = cal_reg[2][2];    in_6[8] = cal_reg[2][3];    in_7[8] = cal_reg[2][3];

            in_8[0] = cal_reg[1][0];   in_9[0] = cal_reg[1][0];    in_10[0] = cal_reg[1][1];    in_11[0] = cal_reg[1][2];    in_12[0] = cal_reg[2][0];   in_13[0] = cal_reg[2][0];    in_14[0] = cal_reg[2][1];    in_15[0] = cal_reg[2][2];      
            in_8[1] = cal_reg[1][0];   in_9[1] = cal_reg[1][1];    in_10[1] = cal_reg[1][2];    in_11[1] = cal_reg[1][3];    in_12[1] = cal_reg[2][0];   in_13[1] = cal_reg[2][1];    in_14[1] = cal_reg[2][2];    in_15[1] = cal_reg[2][3]; 
            in_8[2] = cal_reg[1][1];   in_9[2] = cal_reg[1][2];    in_10[2] = cal_reg[1][3];    in_11[2] = cal_reg[1][3];    in_12[2] = cal_reg[2][1];   in_13[2] = cal_reg[2][2];    in_14[2] = cal_reg[2][3];    in_15[2] = cal_reg[2][3]; 
            in_8[3] = cal_reg[2][0];   in_9[3] = cal_reg[2][0];    in_10[3] = cal_reg[2][1];    in_11[3] = cal_reg[2][2];    in_12[3] = cal_reg[3][0];   in_13[3] = cal_reg[3][0];    in_14[3] = cal_reg[3][1];    in_15[3] = cal_reg[3][2]; 
            in_8[4] = cal_reg[2][0];   in_9[4] = cal_reg[2][1];    in_10[4] = cal_reg[2][2];    in_11[4] = cal_reg[2][3];    in_12[4] = cal_reg[3][0];   in_13[4] = cal_reg[3][1];    in_14[4] = cal_reg[3][2];    in_15[4] = cal_reg[3][3]; 
            in_8[5] = cal_reg[2][1];   in_9[5] = cal_reg[2][2];    in_10[5] = cal_reg[2][3];    in_11[5] = cal_reg[2][3];    in_12[5] = cal_reg[3][1];   in_13[5] = cal_reg[3][2];    in_14[5] = cal_reg[3][3];    in_15[5] = cal_reg[3][3]; 
            in_8[6] = cal_reg[3][0];   in_9[6] = cal_reg[3][0];    in_10[6] = cal_reg[3][1];    in_11[6] = cal_reg[3][2];    in_12[6] = cal_reg[3][0];   in_13[6] = cal_reg[3][0];    in_14[6] = cal_reg[3][1];    in_15[6] = cal_reg[3][2]; 
            in_8[7] = cal_reg[3][0];   in_9[7] = cal_reg[3][1];    in_10[7] = cal_reg[3][2];    in_11[7] = cal_reg[3][3];    in_12[7] = cal_reg[3][0];   in_13[7] = cal_reg[3][1];    in_14[7] = cal_reg[3][2];    in_15[7] = cal_reg[3][3]; 
            in_8[8] = cal_reg[3][1];   in_9[8] = cal_reg[3][2];    in_10[8] = cal_reg[3][3];    in_11[8] = cal_reg[3][3];    in_12[8] = cal_reg[3][1];   in_13[8] = cal_reg[3][2];    in_14[8] = cal_reg[3][3];    in_15[8] = cal_reg[3][3];
       end 
       else if(medium_count==1 && image_size_reg==1) begin//7*7
            in_0[0] = cal_reg[0][0];       in_1[0] = cal_reg[0][0];   in_2[0] = cal_reg[0][1];     in_3[0] = cal_reg[0][2];     in_4[0] = cal_reg[0][3];     in_5[0] = cal_reg[0][4];     in_6[0] = cal_reg[0][5];     in_7[0] = cal_reg[0][6];  
            in_0[1] = cal_reg[0][0];       in_1[1] = cal_reg[0][1];   in_2[1] = cal_reg[0][2];     in_3[1] = cal_reg[0][3];     in_4[1] = cal_reg[0][4];     in_5[1] = cal_reg[0][5];     in_6[1] = cal_reg[0][6];     in_7[1] = cal_reg[0][7];  
            in_0[2] = cal_reg[0][1];       in_1[2] = cal_reg[0][2];   in_2[2] = cal_reg[0][3];     in_3[2] = cal_reg[0][4];     in_4[2] = cal_reg[0][5];     in_5[2] = cal_reg[0][6];     in_6[2] = cal_reg[0][7];     in_7[2] = cal_reg[0][7];  
            in_0[3] = cal_reg[0][0];       in_1[3] = cal_reg[0][0];   in_2[3] = cal_reg[0][1];     in_3[3] = cal_reg[0][2];     in_4[3] = cal_reg[0][3];     in_5[3] = cal_reg[0][4];     in_6[3] = cal_reg[0][5];     in_7[3] = cal_reg[0][6];  
            in_0[4] = cal_reg[0][0];       in_1[4] = cal_reg[0][1];   in_2[4] = cal_reg[0][2];     in_3[4] = cal_reg[0][3];     in_4[4] = cal_reg[0][4];     in_5[4] = cal_reg[0][5];     in_6[4] = cal_reg[0][6];     in_7[4] = cal_reg[0][7];  
            in_0[5] = cal_reg[0][1];       in_1[5] = cal_reg[0][2];   in_2[5] = cal_reg[0][3];     in_3[5] = cal_reg[0][4];     in_4[5] = cal_reg[0][5];     in_5[5] = cal_reg[0][6];     in_6[5] = cal_reg[0][7];     in_7[5] = cal_reg[0][7];  
            in_0[6] = cal_reg[1][0];       in_1[6] = cal_reg[1][0];   in_2[6] = cal_reg[1][1];     in_3[6] = cal_reg[1][2];     in_4[6] = cal_reg[1][3];     in_5[6] = cal_reg[1][4];     in_6[6] = cal_reg[1][5];     in_7[6] = cal_reg[1][6];  
            in_0[7] = cal_reg[1][0];       in_1[7] = cal_reg[1][1];   in_2[7] = cal_reg[1][2];     in_3[7] = cal_reg[1][3];     in_4[7] = cal_reg[1][4];     in_5[7] = cal_reg[1][5];     in_6[7] = cal_reg[1][6];     in_7[7] = cal_reg[1][7];  
            in_0[8] = cal_reg[1][1];       in_1[8] = cal_reg[1][2];   in_2[8] = cal_reg[1][3];     in_3[8] = cal_reg[1][4];     in_4[8] = cal_reg[1][5];     in_5[8] = cal_reg[1][6];     in_6[8] = cal_reg[1][7];     in_7[8] = cal_reg[1][7];

            in_8[0] = cal_reg[0][0];        in_9[0] = cal_reg[0][0];   in_10[0] = cal_reg[0][1];     in_11[0] = cal_reg[0][2];     in_12[0] = cal_reg[0][3];     in_13[0] = cal_reg[0][4];     in_14[0] = cal_reg[0][5];     in_15[0] = cal_reg[0][6];  
            in_8[1] = cal_reg[0][0];        in_9[1] = cal_reg[0][1];   in_10[1] = cal_reg[0][2];     in_11[1] = cal_reg[0][3];     in_12[1] = cal_reg[0][4];     in_13[1] = cal_reg[0][5];     in_14[1] = cal_reg[0][6];     in_15[1] = cal_reg[0][7];  
            in_8[2] = cal_reg[0][1];        in_9[2] = cal_reg[0][2];   in_10[2] = cal_reg[0][3];     in_11[2] = cal_reg[0][4];     in_12[2] = cal_reg[0][5];     in_13[2] = cal_reg[0][6];     in_14[2] = cal_reg[0][7];     in_15[2] = cal_reg[0][7];  
            in_8[3] = cal_reg[1][0];        in_9[3] = cal_reg[1][0];   in_10[3] = cal_reg[1][1];     in_11[3] = cal_reg[1][2];     in_12[3] = cal_reg[1][3];     in_13[3] = cal_reg[1][4];     in_14[3] = cal_reg[1][5];     in_15[3] = cal_reg[1][6];  
            in_8[4] = cal_reg[1][0];        in_9[4] = cal_reg[1][1];   in_10[4] = cal_reg[1][2];     in_11[4] = cal_reg[1][3];     in_12[4] = cal_reg[1][4];     in_13[4] = cal_reg[1][5];     in_14[4] = cal_reg[1][6];     in_15[4] = cal_reg[1][7];  
            in_8[5] = cal_reg[1][1];        in_9[5] = cal_reg[1][2];   in_10[5] = cal_reg[1][3];     in_11[5] = cal_reg[1][4];     in_12[5] = cal_reg[1][5];     in_13[5] = cal_reg[1][6];     in_14[5] = cal_reg[1][7];     in_15[5] = cal_reg[1][7];  
            in_8[6] = cal_reg[2][0];        in_9[6] = cal_reg[2][0];   in_10[6] = cal_reg[2][1];     in_11[6] = cal_reg[2][2];     in_12[6] = cal_reg[2][3];     in_13[6] = cal_reg[2][4];     in_14[6] = cal_reg[2][5];     in_15[6] = cal_reg[2][6];  
            in_8[7] = cal_reg[2][0];        in_9[7] = cal_reg[2][1];   in_10[7] = cal_reg[2][2];     in_11[7] = cal_reg[2][3];     in_12[7] = cal_reg[2][4];     in_13[7] = cal_reg[2][5];     in_14[7] = cal_reg[2][6];     in_15[7] = cal_reg[2][7]; 
            in_8[8] = cal_reg[2][1];        in_9[8] = cal_reg[2][2];   in_10[8] = cal_reg[2][3];     in_11[8] = cal_reg[2][4];     in_12[8] = cal_reg[2][5];     in_13[8] = cal_reg[2][6];     in_14[8] = cal_reg[2][7];     in_15[8] = cal_reg[2][7];         
        end
        else if(medium_count==4&& image_size_reg==1) begin//7*7
            in_0[0] = cal_reg[5][0];   in_1[0] = cal_reg[5][0];    in_2[0] = cal_reg[5][1];    in_3[0] = cal_reg[5][2];    in_4[0] = cal_reg[5][3];    in_5[0] = cal_reg[5][4];    in_6[0] = cal_reg[5][5];    in_7[0] = cal_reg[5][6];
            in_0[1] = cal_reg[5][0];   in_1[1] = cal_reg[5][1];    in_2[1] = cal_reg[5][2];    in_3[1] = cal_reg[5][3];    in_4[1] = cal_reg[5][4];    in_5[1] = cal_reg[5][5];    in_6[1] = cal_reg[5][6];    in_7[1] = cal_reg[5][7];
            in_0[2] = cal_reg[5][1];   in_1[2] = cal_reg[5][2];    in_2[2] = cal_reg[5][3];    in_3[2] = cal_reg[5][4];    in_4[2] = cal_reg[5][5];    in_5[2] = cal_reg[5][6];    in_6[2] = cal_reg[5][7];    in_7[2] = cal_reg[5][7];  
            in_0[3] = cal_reg[6][0];   in_1[3] = cal_reg[6][0];    in_2[3] = cal_reg[6][1];    in_3[3] = cal_reg[6][2];    in_4[3] = cal_reg[6][3];    in_5[3] = cal_reg[6][4];    in_6[3] = cal_reg[6][5];    in_7[3] = cal_reg[6][6];
            in_0[4] = cal_reg[6][0];   in_1[4] = cal_reg[6][1];    in_2[4] = cal_reg[6][2];    in_3[4] = cal_reg[6][3];    in_4[4] = cal_reg[6][4];    in_5[4] = cal_reg[6][5];    in_6[4] = cal_reg[6][6];    in_7[4] = cal_reg[6][7];
            in_0[5] = cal_reg[6][1];   in_1[5] = cal_reg[6][2];    in_2[5] = cal_reg[6][3];    in_3[5] = cal_reg[6][4];    in_4[5] = cal_reg[6][5];    in_5[5] = cal_reg[6][6];    in_6[5] = cal_reg[6][7];    in_7[5] = cal_reg[6][7];
            in_0[6] = cal_reg[7][0];   in_1[6] = cal_reg[7][0];    in_2[6] = cal_reg[7][1];    in_3[6] = cal_reg[7][2];    in_4[6] = cal_reg[7][3];    in_5[6] = cal_reg[7][4];    in_6[6] = cal_reg[7][5];    in_7[6] = cal_reg[7][6];
            in_0[7] = cal_reg[7][0];   in_1[7] = cal_reg[7][1];    in_2[7] = cal_reg[7][2];    in_3[7] = cal_reg[7][3];    in_4[7] = cal_reg[7][4];    in_5[7] = cal_reg[7][5];    in_6[7] = cal_reg[7][6];    in_7[7] = cal_reg[7][7];  
            in_0[8] = cal_reg[7][1];   in_1[8] = cal_reg[7][2];    in_2[8] = cal_reg[7][3];    in_3[8] = cal_reg[7][4];    in_4[8] = cal_reg[7][5];    in_5[8] = cal_reg[7][6];    in_6[8] = cal_reg[7][7];    in_7[8] = cal_reg[7][7];

            in_8[0] = cal_reg[6][0];   in_9[0] = cal_reg[6][0];    in_10[0] = cal_reg[6][1];  in_11[0] = cal_reg[6][2];  in_12[0] = cal_reg[6][3];  in_13[0] = cal_reg[6][4];  in_14[0] = cal_reg[6][5]; in_15[0] = cal_reg[6][6];
            in_8[1] = cal_reg[6][0];   in_9[1] = cal_reg[6][1];    in_10[1] = cal_reg[6][2];  in_11[1] = cal_reg[6][3];  in_12[1] = cal_reg[6][4];  in_13[1] = cal_reg[6][5];  in_14[1] = cal_reg[6][6]; in_15[1] = cal_reg[6][7]; 
            in_8[2] = cal_reg[6][1];   in_9[2] = cal_reg[6][2];    in_10[2] = cal_reg[6][3];  in_11[2] = cal_reg[6][4];  in_12[2] = cal_reg[6][5];  in_13[2] = cal_reg[6][6];  in_14[2] = cal_reg[6][7]; in_15[2] = cal_reg[6][7];
            in_8[3] = cal_reg[7][0];   in_9[3] = cal_reg[7][0];    in_10[3] = cal_reg[7][1];  in_11[3] = cal_reg[7][2];  in_12[3] = cal_reg[7][3];  in_13[3] = cal_reg[7][4];  in_14[3] = cal_reg[7][5]; in_15[3] = cal_reg[7][6];  
            in_8[4] = cal_reg[7][0];   in_9[4] = cal_reg[7][1];    in_10[4] = cal_reg[7][2];  in_11[4] = cal_reg[7][3];  in_12[4] = cal_reg[7][4];  in_13[4] = cal_reg[7][5];  in_14[4] = cal_reg[7][6]; in_15[4] = cal_reg[7][7]; 
            in_8[5] = cal_reg[7][1];   in_9[5] = cal_reg[7][2];    in_10[5] = cal_reg[7][3];  in_11[5] = cal_reg[7][4];  in_12[5] = cal_reg[7][5];  in_13[5] = cal_reg[7][6];  in_14[5] = cal_reg[7][7]; in_15[5] = cal_reg[7][7]; 
            in_8[6] = cal_reg[7][0];   in_9[6] = cal_reg[7][0];    in_10[6] = cal_reg[7][1];  in_11[6] = cal_reg[7][2];  in_12[6] = cal_reg[7][3];  in_13[6] = cal_reg[7][4];  in_14[6] = cal_reg[7][5]; in_15[6] = cal_reg[7][6];  
            in_8[7] = cal_reg[7][0];   in_9[7] = cal_reg[7][1];    in_10[7] = cal_reg[7][2];  in_11[7] = cal_reg[7][3];  in_12[7] = cal_reg[7][4];  in_13[7] = cal_reg[7][5];  in_14[7] = cal_reg[7][6]; in_15[7] = cal_reg[7][7];      
            in_8[8] = cal_reg[7][1];   in_9[8] = cal_reg[7][2];    in_10[8] = cal_reg[7][3];  in_11[8] = cal_reg[7][4];  in_12[8] = cal_reg[7][5];  in_13[8] = cal_reg[7][6];  in_14[8] = cal_reg[7][7]; in_15[8] = cal_reg[7][7];
        end
        else if((medium_count==2||medium_count==3)&&image_size_reg==1) begin//7*7
            in_0[0] = cal_reg[y_count][0];   in_1[0] = cal_reg[y_count][0];    in_2[0] = cal_reg[y_count][1];    in_3[0] = cal_reg[y_count][2];    in_4[0] = cal_reg[y_count][3];    in_5[0] = cal_reg[y_count][4];    in_6[0] = cal_reg[y_count][5];   in_7[0] = cal_reg[y_count][6];
            in_0[1] = cal_reg[y_count][0];   in_1[1] = cal_reg[y_count][1];    in_2[1] = cal_reg[y_count][2];    in_3[1] = cal_reg[y_count][3];    in_4[1] = cal_reg[y_count][4];    in_5[1] = cal_reg[y_count][5];    in_6[1] = cal_reg[y_count][6];   in_7[1] = cal_reg[y_count][7];
            in_0[2] = cal_reg[y_count][1];   in_1[2] = cal_reg[y_count][2];    in_2[2] = cal_reg[y_count][3];    in_3[2] = cal_reg[y_count][4];    in_4[2] = cal_reg[y_count][5];    in_5[2] = cal_reg[y_count][6];    in_6[2] = cal_reg[y_count][7];   in_7[2] = cal_reg[y_count][7];  
            in_0[3] = cal_reg[y_count+1][0]; in_1[3] = cal_reg[y_count+1][0];  in_2[3] = cal_reg[y_count+1][1];  in_3[3] = cal_reg[y_count+1][2];  in_4[3] = cal_reg[y_count+1][3];  in_5[3] = cal_reg[y_count+1][4];  in_6[3] = cal_reg[y_count+1][5]; in_7[3] = cal_reg[y_count+1][6];
            in_0[4] = cal_reg[y_count+1][0]; in_1[4] = cal_reg[y_count+1][1];  in_2[4] = cal_reg[y_count+1][2];  in_3[4] = cal_reg[y_count+1][3];  in_4[4] = cal_reg[y_count+1][4];  in_5[4] = cal_reg[y_count+1][5];  in_6[4] = cal_reg[y_count+1][6]; in_7[4] = cal_reg[y_count+1][7];
            in_0[5] = cal_reg[y_count+1][1]; in_1[5] = cal_reg[y_count+1][2];  in_2[5] = cal_reg[y_count+1][3];  in_3[5] = cal_reg[y_count+1][4];  in_4[5] = cal_reg[y_count+1][5];  in_5[5] = cal_reg[y_count+1][6];  in_6[5] = cal_reg[y_count+1][7]; in_7[5] = cal_reg[y_count+1][7];
            in_0[6] = cal_reg[y_count+2][0]; in_1[6] = cal_reg[y_count+2][0];  in_2[6] = cal_reg[y_count+2][1];  in_3[6] = cal_reg[y_count+2][2];  in_4[6] = cal_reg[y_count+2][3];  in_5[6] = cal_reg[y_count+2][4];  in_6[6] = cal_reg[y_count+2][5]; in_7[6] = cal_reg[y_count+2][6];
            in_0[7] = cal_reg[y_count+2][0]; in_1[7] = cal_reg[y_count+2][1];  in_2[7] = cal_reg[y_count+2][2];  in_3[7] = cal_reg[y_count+2][3];  in_4[7] = cal_reg[y_count+2][4];  in_5[7] = cal_reg[y_count+2][5];  in_6[7] = cal_reg[y_count+2][6]; in_7[7] = cal_reg[y_count+2][7];  
            in_0[8] = cal_reg[y_count+2][1]; in_1[8] = cal_reg[y_count+2][2];  in_2[8] = cal_reg[y_count+2][3];  in_3[8] = cal_reg[y_count+2][4];  in_4[8] = cal_reg[y_count+2][5];  in_5[8] = cal_reg[y_count+2][6];  in_6[8] = cal_reg[y_count+2][7]; in_7[8] = cal_reg[y_count+2][7];

            in_8[0] = cal_reg[y_count+1][0];   in_9[0] = cal_reg[y_count+1][0];    in_10[0] = cal_reg[y_count+1][1];   in_11[0] = cal_reg[y_count+1][2];  in_12[0] = cal_reg[y_count+1][3];    in_13[0] = cal_reg[y_count+1][4];  in_14[0] = cal_reg[y_count+1][5]; in_15[0] = cal_reg[y_count+1][6];
            in_8[1] = cal_reg[y_count+1][0];   in_9[1] = cal_reg[y_count+1][1];    in_10[1] = cal_reg[y_count+1][2];   in_11[1] = cal_reg[y_count+1][3];  in_12[1] = cal_reg[y_count+1][4];    in_13[1] = cal_reg[y_count+1][5];  in_14[1] = cal_reg[y_count+1][6]; in_15[1] = cal_reg[y_count+1][7]; 
            in_8[2] = cal_reg[y_count+1][1];   in_9[2] = cal_reg[y_count+1][2];    in_10[2] = cal_reg[y_count+1][3];   in_11[2] = cal_reg[y_count+1][4];  in_12[2] = cal_reg[y_count+1][5];    in_13[2] = cal_reg[y_count+1][6];  in_14[2] = cal_reg[y_count+1][7]; in_15[2] = cal_reg[y_count+1][7];
            in_8[3] = cal_reg[y_count+2][0];   in_9[3] = cal_reg[y_count+2][0];    in_10[3] = cal_reg[y_count+2][1];   in_11[3] = cal_reg[y_count+2][2];  in_12[3] = cal_reg[y_count+2][3];    in_13[3] = cal_reg[y_count+2][4];  in_14[3] = cal_reg[y_count+2][5]; in_15[3] = cal_reg[y_count+2][6];  
            in_8[4] = cal_reg[y_count+2][0];   in_9[4] = cal_reg[y_count+2][1];    in_10[4] = cal_reg[y_count+2][2];   in_11[4] = cal_reg[y_count+2][3];  in_12[4] = cal_reg[y_count+2][4];    in_13[4] = cal_reg[y_count+2][5];  in_14[4] = cal_reg[y_count+2][6]; in_15[4] = cal_reg[y_count+2][7]; 
            in_8[5] = cal_reg[y_count+2][1];   in_9[5] = cal_reg[y_count+2][2];    in_10[5] = cal_reg[y_count+2][3];   in_11[5] = cal_reg[y_count+2][4];  in_12[5] = cal_reg[y_count+2][5];    in_13[5] = cal_reg[y_count+2][6];  in_14[5] = cal_reg[y_count+2][7]; in_15[5] = cal_reg[y_count+2][7]; 
            in_8[6] = cal_reg[y_count+3][0];   in_9[6] = cal_reg[y_count+3][0];    in_10[6] = cal_reg[y_count+3][1];   in_11[6] = cal_reg[y_count+3][2];  in_12[6] = cal_reg[y_count+3][3];    in_13[6] = cal_reg[y_count+3][4];  in_14[6] = cal_reg[y_count+3][5]; in_15[6] = cal_reg[y_count+3][6];  
            in_8[7] = cal_reg[y_count+3][0];   in_9[7] = cal_reg[y_count+3][1];    in_10[7] = cal_reg[y_count+3][2];   in_11[7] = cal_reg[y_count+3][3];  in_12[7] = cal_reg[y_count+3][4];    in_13[7] = cal_reg[y_count+3][5];  in_14[7] = cal_reg[y_count+3][6]; in_15[7] = cal_reg[y_count+3][7];      
            in_8[8] = cal_reg[y_count+3][1];   in_9[8] = cal_reg[y_count+3][2];    in_10[8] = cal_reg[y_count+3][3];   in_11[8] = cal_reg[y_count+3][4];  in_12[8] = cal_reg[y_count+3][5];    in_13[8] = cal_reg[y_count+3][6];  in_14[8] = cal_reg[y_count+3][7]; in_15[8] = cal_reg[y_count+3][7];
        end 
        else if(medium_count==1&&image_size_reg==2) begin
            in_0[0] = cal_reg[0][0];   in_1[0] = cal_reg[0][0];    in_2[0] = cal_reg[0][1];    in_3[0] = cal_reg[0][2];  in_4[0] = cal_reg[0][3];    in_5[0] = cal_reg[0][4];    in_6[0] = cal_reg[0][5];    in_7[0] = cal_reg[0][6];
            in_0[1] = cal_reg[0][0];   in_1[1] = cal_reg[0][1];    in_2[1] = cal_reg[0][2];    in_3[1] = cal_reg[0][3];  in_4[1] = cal_reg[0][4];    in_5[1] = cal_reg[0][5];    in_6[1] = cal_reg[0][6];    in_7[1] = cal_reg[0][7];
            in_0[2] = cal_reg[0][1];   in_1[2] = cal_reg[0][2];    in_2[2] = cal_reg[0][3];    in_3[2] = cal_reg[0][4];  in_4[2] = cal_reg[0][5];    in_5[2] = cal_reg[0][6];    in_6[2] = cal_reg[0][7];    in_7[2] = cal_reg[0][8];  
            in_0[3] = cal_reg[0][0];   in_1[3] = cal_reg[0][0];    in_2[3] = cal_reg[0][1];    in_3[3] = cal_reg[0][2];  in_4[3] = cal_reg[0][3];    in_5[3] = cal_reg[0][4];    in_6[3] = cal_reg[0][5];    in_7[3] = cal_reg[0][6];
            in_0[4] = cal_reg[0][0];   in_1[4] = cal_reg[0][1];    in_2[4] = cal_reg[0][2];    in_3[4] = cal_reg[0][3];  in_4[4] = cal_reg[0][4];    in_5[4] = cal_reg[0][5];    in_6[4] = cal_reg[0][6];    in_7[4] = cal_reg[0][7];
            in_0[5] = cal_reg[0][1];   in_1[5] = cal_reg[0][2];    in_2[5] = cal_reg[0][3];    in_3[5] = cal_reg[0][4];  in_4[5] = cal_reg[0][5];    in_5[5] = cal_reg[0][6];    in_6[5] = cal_reg[0][7];    in_7[5] = cal_reg[0][8];
            in_0[6] = cal_reg[1][0];   in_1[6] = cal_reg[1][0];    in_2[6] = cal_reg[1][1];    in_3[6] = cal_reg[1][2];  in_4[6] = cal_reg[1][3];    in_5[6] = cal_reg[1][4];    in_6[6] = cal_reg[1][5];    in_7[6] = cal_reg[1][6];
            in_0[7] = cal_reg[1][0];   in_1[7] = cal_reg[1][1];    in_2[7] = cal_reg[1][2];    in_3[7] = cal_reg[1][3];  in_4[7] = cal_reg[1][4];    in_5[7] = cal_reg[1][5];    in_6[7] = cal_reg[1][6];    in_7[7] = cal_reg[1][7];  
            in_0[8] = cal_reg[1][1];   in_1[8] = cal_reg[1][2];    in_2[8] = cal_reg[1][3];    in_3[8] = cal_reg[1][4];  in_4[8] = cal_reg[1][5];    in_5[8] = cal_reg[1][6];    in_6[8] = cal_reg[1][7];    in_7[8] = cal_reg[1][8];

            in_8[0] = cal_reg[0][7];   in_9[0] = cal_reg[0][8];    in_10[0] = cal_reg[0][9];   in_11[0] = cal_reg[0][10];    in_12[0] = cal_reg[0][11];    in_13[0] = cal_reg[0][12];    in_14[0] = cal_reg[0][13]; in_15[0] = cal_reg[0][14];
            in_8[1] = cal_reg[0][8];   in_9[1] = cal_reg[0][9];    in_10[1] = cal_reg[0][10];  in_11[1] = cal_reg[0][11];    in_12[1] = cal_reg[0][12];    in_13[1] = cal_reg[0][13];    in_14[1] = cal_reg[0][14]; in_15[1] = cal_reg[0][15]; 
            in_8[2] = cal_reg[0][9];   in_9[2] = cal_reg[0][10];   in_10[2] = cal_reg[0][11];  in_11[2] = cal_reg[0][12];    in_12[2] = cal_reg[0][13];    in_13[2] = cal_reg[0][14];    in_14[2] = cal_reg[0][15]; in_15[2] = cal_reg[0][15];
            in_8[3] = cal_reg[0][7];   in_9[3] = cal_reg[0][8];    in_10[3] = cal_reg[0][9];   in_11[3] = cal_reg[0][10];    in_12[3] = cal_reg[0][11];    in_13[3] = cal_reg[0][12];    in_14[3] = cal_reg[0][13]; in_15[3] = cal_reg[0][14];  
            in_8[4] = cal_reg[0][8];   in_9[4] = cal_reg[0][9];    in_10[4] = cal_reg[0][10];  in_11[4] = cal_reg[0][11];    in_12[4] = cal_reg[0][12];    in_13[4] = cal_reg[0][13];    in_14[4] = cal_reg[0][14]; in_15[4] = cal_reg[0][15]; 
            in_8[5] = cal_reg[0][9];   in_9[5] = cal_reg[0][10];   in_10[5] = cal_reg[0][11];  in_11[5] = cal_reg[0][12];    in_12[5] = cal_reg[0][13];    in_13[5] = cal_reg[0][14];    in_14[5] = cal_reg[0][15]; in_15[5] = cal_reg[0][15]; 
            in_8[6] = cal_reg[1][7];   in_9[6] = cal_reg[1][8];    in_10[6] = cal_reg[1][9];   in_11[6] = cal_reg[1][10];    in_12[6] = cal_reg[1][11];    in_13[6] = cal_reg[1][12];    in_14[6] = cal_reg[1][13]; in_15[6] = cal_reg[1][14];  
            in_8[7] = cal_reg[1][8];   in_9[7] = cal_reg[1][9];    in_10[7] = cal_reg[1][10];  in_11[7] = cal_reg[1][11];    in_12[7] = cal_reg[1][12];    in_13[7] = cal_reg[1][13];    in_14[7] = cal_reg[1][14]; in_15[7] = cal_reg[1][15];      
            in_8[8] = cal_reg[1][9];   in_9[8] = cal_reg[1][10];   in_10[8] = cal_reg[1][11];  in_11[8] = cal_reg[1][12];    in_12[8] = cal_reg[1][13];    in_13[8] = cal_reg[1][14];    in_14[8] = cal_reg[1][15]; in_15[8] = cal_reg[1][15];
        end
        else if(medium_count==16&&image_size_reg==2) begin//16*16
            in_0[0] = cal_reg[14][0];   in_1[0] = cal_reg[14][0];    in_2[0] = cal_reg[14][1];    in_3[0] = cal_reg[14][2];  in_4[0] = cal_reg[14][3];  in_5[0] = cal_reg[14][4];  in_6[0] = cal_reg[14][5];  in_7[0] = cal_reg[14][6];
            in_0[1] = cal_reg[14][0];   in_1[1] = cal_reg[14][1];    in_2[1] = cal_reg[14][2];    in_3[1] = cal_reg[14][3];  in_4[1] = cal_reg[14][4];  in_5[1] = cal_reg[14][5];  in_6[1] = cal_reg[14][6];  in_7[1] = cal_reg[14][7];
            in_0[2] = cal_reg[14][1];   in_1[2] = cal_reg[14][2];    in_2[2] = cal_reg[14][3];    in_3[2] = cal_reg[14][4];  in_4[2] = cal_reg[14][5];  in_5[2] = cal_reg[14][6];  in_6[2] = cal_reg[14][7];  in_7[2] = cal_reg[14][8];  
            in_0[3] = cal_reg[15][0];   in_1[3] = cal_reg[15][0];    in_2[3] = cal_reg[15][1];    in_3[3] = cal_reg[15][2];  in_4[3] = cal_reg[15][3];  in_5[3] = cal_reg[15][4];  in_6[3] = cal_reg[15][5];  in_7[3] = cal_reg[15][6];
            in_0[4] = cal_reg[15][0];   in_1[4] = cal_reg[15][1];    in_2[4] = cal_reg[15][2];    in_3[4] = cal_reg[15][3];  in_4[4] = cal_reg[15][4];  in_5[4] = cal_reg[15][5];  in_6[4] = cal_reg[15][6];  in_7[4] = cal_reg[15][7];
            in_0[5] = cal_reg[15][1];   in_1[5] = cal_reg[15][2];    in_2[5] = cal_reg[15][3];    in_3[5] = cal_reg[15][4];  in_4[5] = cal_reg[15][5];  in_5[5] = cal_reg[15][6];  in_6[5] = cal_reg[15][7];  in_7[5] = cal_reg[15][8];
            in_0[6] = cal_reg[15][0];   in_1[6] = cal_reg[15][0];    in_2[6] = cal_reg[15][1];    in_3[6] = cal_reg[15][2];  in_4[6] = cal_reg[15][3];  in_5[6] = cal_reg[15][4];  in_6[6] = cal_reg[15][5];  in_7[6] = cal_reg[15][6];
            in_0[7] = cal_reg[15][0];   in_1[7] = cal_reg[15][1];    in_2[7] = cal_reg[15][2];    in_3[7] = cal_reg[15][3];  in_4[7] = cal_reg[15][4];  in_5[7] = cal_reg[15][5];  in_6[7] = cal_reg[15][6];  in_7[7] = cal_reg[15][7];  
            in_0[8] = cal_reg[15][1];   in_1[8] = cal_reg[15][2];    in_2[8] = cal_reg[15][3];    in_3[8] = cal_reg[15][4];  in_4[8] = cal_reg[15][5];  in_5[8] = cal_reg[15][6];  in_6[8] = cal_reg[15][7];  in_7[8] = cal_reg[15][8];

            in_8[0] = cal_reg[14][7]; in_9[0] = cal_reg[14][8];  in_10[0] = cal_reg[14][9];   in_11[0] = cal_reg[14][10];  in_12[0] = cal_reg[14][11];  in_13[0] = cal_reg[14][12];  in_14[0] = cal_reg[14][13]; in_15[0] = cal_reg[14][14];
            in_8[1] = cal_reg[14][8]; in_9[1] = cal_reg[14][9];  in_10[1] = cal_reg[14][10];  in_11[1] = cal_reg[14][11];  in_12[1] = cal_reg[14][12];  in_13[1] = cal_reg[14][13];  in_14[1] = cal_reg[14][14]; in_15[1] = cal_reg[14][15]; 
            in_8[2] = cal_reg[14][9]; in_9[2] = cal_reg[14][10]; in_10[2] = cal_reg[14][11];  in_11[2] = cal_reg[14][12];  in_12[2] = cal_reg[14][13];  in_13[2] = cal_reg[14][14];  in_14[2] = cal_reg[14][15]; in_15[2] = cal_reg[14][15];
            in_8[3] = cal_reg[15][7]; in_9[3] = cal_reg[15][8];  in_10[3] = cal_reg[15][9];   in_11[3] = cal_reg[15][10];  in_12[3] = cal_reg[15][11];  in_13[3] = cal_reg[15][12];  in_14[3] = cal_reg[15][13]; in_15[3] = cal_reg[15][14];  
            in_8[4] = cal_reg[15][8]; in_9[4] = cal_reg[15][9];  in_10[4] = cal_reg[15][10];  in_11[4] = cal_reg[15][11];  in_12[4] = cal_reg[15][12];  in_13[4] = cal_reg[15][13];  in_14[4] = cal_reg[15][14]; in_15[4] = cal_reg[15][15]; 
            in_8[5] = cal_reg[15][9]; in_9[5] = cal_reg[15][10]; in_10[5] = cal_reg[15][11];  in_11[5] = cal_reg[15][12];  in_12[5] = cal_reg[15][13];  in_13[5] = cal_reg[15][14];  in_14[5] = cal_reg[15][15]; in_15[5] = cal_reg[15][15]; 
            in_8[6] = cal_reg[15][7]; in_9[6] = cal_reg[15][8];  in_10[6] = cal_reg[15][9];   in_11[6] = cal_reg[15][10];  in_12[6] = cal_reg[15][11];  in_13[6] = cal_reg[15][12];  in_14[6] = cal_reg[15][13]; in_15[6] = cal_reg[15][14];  
            in_8[7] = cal_reg[15][8]; in_9[7] = cal_reg[15][9];  in_10[7] = cal_reg[15][10];  in_11[7] = cal_reg[15][11];  in_12[7] = cal_reg[15][12];  in_13[7] = cal_reg[15][13];  in_14[7] = cal_reg[15][14]; in_15[7] = cal_reg[15][15];      
            in_8[8] = cal_reg[15][9]; in_9[8] = cal_reg[15][10]; in_10[8] = cal_reg[15][11];  in_11[8] = cal_reg[15][12];  in_12[8] = cal_reg[15][13];  in_13[8] = cal_reg[15][14];  in_14[8] = cal_reg[15][15]; in_15[8] = cal_reg[15][15];
        end 
         else if(medium_count>1&&medium_count<16&&image_size_reg==2) begin//16*16
            in_0[0] = cal_reg[y_count][0];   in_1[0] = cal_reg[y_count][0];    in_2[0] = cal_reg[y_count][1];    in_3[0] = cal_reg[y_count][2];    in_4[0] = cal_reg[y_count][3];    in_5[0] = cal_reg[y_count][4];    in_6[0] = cal_reg[y_count][5];    in_7[0] = cal_reg[y_count][6];
            in_0[1] = cal_reg[y_count][0];   in_1[1] = cal_reg[y_count][1];    in_2[1] = cal_reg[y_count][2];    in_3[1] = cal_reg[y_count][3];    in_4[1] = cal_reg[y_count][4];    in_5[1] = cal_reg[y_count][5];    in_6[1] = cal_reg[y_count][6];    in_7[1] = cal_reg[y_count][7];
            in_0[2] = cal_reg[y_count][1];   in_1[2] = cal_reg[y_count][2];    in_2[2] = cal_reg[y_count][3];    in_3[2] = cal_reg[y_count][4];    in_4[2] = cal_reg[y_count][5];    in_5[2] = cal_reg[y_count][6];    in_6[2] = cal_reg[y_count][7];    in_7[2] = cal_reg[y_count][8];  
            in_0[3] = cal_reg[y_count+1][0]; in_1[3] = cal_reg[y_count+1][0];  in_2[3] = cal_reg[y_count+1][1];  in_3[3] = cal_reg[y_count+1][2];  in_4[3] = cal_reg[y_count+1][3];  in_5[3] = cal_reg[y_count+1][4];  in_6[3] = cal_reg[y_count+1][5];  in_7[3] = cal_reg[y_count+1][6];
            in_0[4] = cal_reg[y_count+1][0]; in_1[4] = cal_reg[y_count+1][1];  in_2[4] = cal_reg[y_count+1][2];  in_3[4] = cal_reg[y_count+1][3];  in_4[4] = cal_reg[y_count+1][4];  in_5[4] = cal_reg[y_count+1][5];  in_6[4] = cal_reg[y_count+1][6];  in_7[4] = cal_reg[y_count+1][7];
            in_0[5] = cal_reg[y_count+1][1]; in_1[5] = cal_reg[y_count+1][2];  in_2[5] = cal_reg[y_count+1][3];  in_3[5] = cal_reg[y_count+1][4];  in_4[5] = cal_reg[y_count+1][5];  in_5[5] = cal_reg[y_count+1][6];  in_6[5] = cal_reg[y_count+1][7];  in_7[5] = cal_reg[y_count+1][8];
            in_0[6] = cal_reg[y_count+2][0]; in_1[6] = cal_reg[y_count+2][0];  in_2[6] = cal_reg[y_count+2][1];  in_3[6] = cal_reg[y_count+2][2];  in_4[6] = cal_reg[y_count+2][3];  in_5[6] = cal_reg[y_count+2][4];  in_6[6] = cal_reg[y_count+2][5];  in_7[6] = cal_reg[y_count+2][6];
            in_0[7] = cal_reg[y_count+2][0]; in_1[7] = cal_reg[y_count+2][1];  in_2[7] = cal_reg[y_count+2][2];  in_3[7] = cal_reg[y_count+2][3];  in_4[7] = cal_reg[y_count+2][4];  in_5[7] = cal_reg[y_count+2][5];  in_6[7] = cal_reg[y_count+2][6];  in_7[7] = cal_reg[y_count+2][7];  
            in_0[8] = cal_reg[y_count+2][1]; in_1[8] = cal_reg[y_count+2][2];  in_2[8] = cal_reg[y_count+2][3];  in_3[8] = cal_reg[y_count+2][4];  in_4[8] = cal_reg[y_count+2][5];  in_5[8] = cal_reg[y_count+2][6];  in_6[8] = cal_reg[y_count+2][7];  in_7[8] = cal_reg[y_count+2][8];

            in_8[0] = cal_reg[y_count][7];   in_9[0] = cal_reg[y_count][8];    in_10[0] = cal_reg[y_count][9];   in_11[0] = cal_reg[y_count][10];    in_12[0] = cal_reg[y_count][11];    in_13[0] = cal_reg[y_count][12];    in_14[0] = cal_reg[y_count][13];    in_15[0] = cal_reg[y_count][14];
            in_8[1] = cal_reg[y_count][8];   in_9[1] = cal_reg[y_count][9];    in_10[1] = cal_reg[y_count][10];  in_11[1] = cal_reg[y_count][11];    in_12[1] = cal_reg[y_count][12];    in_13[1] = cal_reg[y_count][13];    in_14[1] = cal_reg[y_count][14];    in_15[1] = cal_reg[y_count][15]; 
            in_8[2] = cal_reg[y_count][9];   in_9[2] = cal_reg[y_count][10];   in_10[2] = cal_reg[y_count][11];  in_11[2] = cal_reg[y_count][12];    in_12[2] = cal_reg[y_count][13];    in_13[2] = cal_reg[y_count][14];    in_14[2] = cal_reg[y_count][15];    in_15[2] = cal_reg[y_count][15];
            in_8[3] = cal_reg[y_count+1][7]; in_9[3] = cal_reg[y_count+1][8];  in_10[3] = cal_reg[y_count+1][9]; in_11[3] = cal_reg[y_count+1][10];  in_12[3] = cal_reg[y_count+1][11];  in_13[3] = cal_reg[y_count+1][12];  in_14[3] = cal_reg[y_count+1][13];  in_15[3] = cal_reg[y_count+1][14];  
            in_8[4] = cal_reg[y_count+1][8]; in_9[4] = cal_reg[y_count+1][9];  in_10[4] = cal_reg[y_count+1][10];in_11[4] = cal_reg[y_count+1][11];  in_12[4] = cal_reg[y_count+1][12];  in_13[4] = cal_reg[y_count+1][13];  in_14[4] = cal_reg[y_count+1][14];  in_15[4] = cal_reg[y_count+1][15]; 
            in_8[5] = cal_reg[y_count+1][9]; in_9[5] = cal_reg[y_count+1][10]; in_10[5] = cal_reg[y_count+1][11];in_11[5] = cal_reg[y_count+1][12];  in_12[5] = cal_reg[y_count+1][13];  in_13[5] = cal_reg[y_count+1][14];  in_14[5] = cal_reg[y_count+1][15];  in_15[5] = cal_reg[y_count+1][15]; 
            in_8[6] = cal_reg[y_count+2][7]; in_9[6] = cal_reg[y_count+2][8];  in_10[6] = cal_reg[y_count+2][9]; in_11[6] = cal_reg[y_count+2][10];  in_12[6] = cal_reg[y_count+2][11];  in_13[6] = cal_reg[y_count+2][12];  in_14[6] = cal_reg[y_count+2][13];  in_15[6] = cal_reg[y_count+2][14];  
            in_8[7] = cal_reg[y_count+2][8]; in_9[7] = cal_reg[y_count+2][9];  in_10[7] = cal_reg[y_count+2][10];in_11[7] = cal_reg[y_count+2][11];  in_12[7] = cal_reg[y_count+2][12];  in_13[7] = cal_reg[y_count+2][13];  in_14[7] = cal_reg[y_count+2][14];  in_15[7] = cal_reg[y_count+2][15];      
            in_8[8] = cal_reg[y_count+2][9]; in_9[8] = cal_reg[y_count+2][10]; in_10[8] = cal_reg[y_count+2][11];in_11[8] = cal_reg[y_count+2][12];  in_12[8] = cal_reg[y_count+2][13];  in_13[8] = cal_reg[y_count+2][14];  in_14[8] = cal_reg[y_count+2][15];  in_15[8] = cal_reg[y_count+2][15];

        end 
    end
    else if(cs_state==MAX_POOLING) begin
        
           case(image_size_reg) 
            1: begin
                in_0[0] = cal_reg[0][0]; in_0[1] = cal_reg[0][1]; in_0[2] = cal_reg[1][0]; in_0[3] = cal_reg[1][1]; in_0[4] = cal_reg[2][0]; in_0[5] = cal_reg[2][1]; in_0[6] = cal_reg[3][0]; in_0[7] = cal_reg[3][1]; in_0[8] = 0;
                in_1[0] = cal_reg[0][2]; in_1[1] = cal_reg[0][3]; in_1[2] = cal_reg[1][2]; in_1[3] = cal_reg[1][3]; in_1[4] = cal_reg[2][2]; in_1[5] = cal_reg[2][3]; in_1[6] = cal_reg[3][2]; in_1[7] = cal_reg[3][3]; in_1[8] = 0;
                in_2[0] = cal_reg[0][4]; in_2[1] = cal_reg[0][5]; in_2[2] = cal_reg[1][4]; in_2[3] = cal_reg[1][5]; in_2[4] = cal_reg[2][4]; in_2[5] = cal_reg[2][5]; in_2[6] = cal_reg[3][4]; in_2[7] = cal_reg[3][5]; in_2[8] = 0;
                in_3[0] = cal_reg[0][6]; in_3[1] = cal_reg[0][7]; in_3[2] = cal_reg[1][6]; in_3[3] = cal_reg[1][7]; in_3[4] = cal_reg[2][6]; in_3[5] = cal_reg[2][7]; in_3[6] = cal_reg[3][6]; in_3[7] = cal_reg[3][7]; in_3[8] = 0;
                in_4[0] = cal_reg[4][0]; in_4[1] = cal_reg[4][1]; in_4[2] = cal_reg[5][0]; in_4[3] = cal_reg[5][1]; in_4[4] = cal_reg[6][0]; in_4[5] = cal_reg[6][1]; in_4[6] = cal_reg[7][0]; in_4[7] = cal_reg[7][1]; in_4[8] = 0;
                in_5[0] = cal_reg[4][2]; in_5[1] = cal_reg[4][3]; in_5[2] = cal_reg[5][2]; in_5[3] = cal_reg[5][3]; in_5[4] = cal_reg[6][2]; in_5[5] = cal_reg[6][3]; in_5[6] = cal_reg[7][2]; in_5[7] = cal_reg[7][3]; in_5[8] = 0;
                in_6[0] = cal_reg[4][4]; in_6[1] = cal_reg[4][5]; in_6[2] = cal_reg[5][4]; in_6[3] = cal_reg[5][5]; in_6[4] = cal_reg[6][4]; in_6[5] = cal_reg[6][5]; in_6[6] = cal_reg[7][4]; in_6[7] = cal_reg[7][5]; in_6[8] = 0;
                in_7[0] = cal_reg[4][6]; in_7[1] = cal_reg[4][7]; in_7[2] = cal_reg[5][6]; in_7[3] = cal_reg[5][7]; in_7[4] = cal_reg[6][6]; in_7[5] = cal_reg[6][7]; in_7[6] = cal_reg[7][6]; in_7[7] = cal_reg[7][7]; in_7[8] = 0;
            end
            2: begin
                if(max_counter==1) begin
                    in_0[0] = cal_reg[0][0]; in_0[1] = cal_reg[0][1]; in_0[2] = cal_reg[1][0]; in_0[3] = cal_reg[1][1]; in_0[4] = cal_reg[2][0]; in_0[5] = cal_reg[2][1]; in_0[6] = cal_reg[3][0]; in_0[7] = cal_reg[3][1]; in_0[8] = 0;
                    in_1[0] = cal_reg[0][2]; in_1[1] = cal_reg[0][3]; in_1[2] = cal_reg[1][2]; in_1[3] = cal_reg[1][3]; in_1[4] = cal_reg[2][2]; in_1[5] = cal_reg[2][3]; in_1[6] = cal_reg[3][2]; in_1[7] = cal_reg[3][3]; in_1[8] = 0;
                    in_2[0] = cal_reg[0][4]; in_2[1] = cal_reg[0][5]; in_2[2] = cal_reg[1][4]; in_2[3] = cal_reg[1][5]; in_2[4] = cal_reg[2][4]; in_2[5] = cal_reg[2][5]; in_2[6] = cal_reg[3][4]; in_2[7] = cal_reg[3][5]; in_2[8] = 0;
                    in_3[0] = cal_reg[0][6]; in_3[1] = cal_reg[0][7]; in_3[2] = cal_reg[1][6]; in_3[3] = cal_reg[1][7]; in_3[4] = cal_reg[2][6]; in_3[5] = cal_reg[2][7]; in_3[6] = cal_reg[3][6]; in_3[7] = cal_reg[3][7]; in_3[8] = 0;
                    in_4[0] = cal_reg[4][0]; in_4[1] = cal_reg[4][1]; in_4[2] = cal_reg[5][0]; in_4[3] = cal_reg[5][1]; in_4[4] = cal_reg[6][0]; in_4[5] = cal_reg[6][1]; in_4[6] = cal_reg[7][0]; in_4[7] = cal_reg[7][1]; in_4[8] = 0;
                    in_5[0] = cal_reg[4][2]; in_5[1] = cal_reg[4][3]; in_5[2] = cal_reg[5][2]; in_5[3] = cal_reg[5][3]; in_5[4] = cal_reg[6][2]; in_5[5] = cal_reg[6][3]; in_5[6] = cal_reg[7][2]; in_5[7] = cal_reg[7][3]; in_5[8] = 0;
                    in_6[0] = cal_reg[4][4]; in_6[1] = cal_reg[4][5]; in_6[2] = cal_reg[5][4]; in_6[3] = cal_reg[5][5]; in_6[4] = cal_reg[6][4]; in_6[5] = cal_reg[6][5]; in_6[6] = cal_reg[7][4]; in_6[7] = cal_reg[7][5]; in_6[8] = 0;
                    in_7[0] = cal_reg[4][6]; in_7[1] = cal_reg[4][7]; in_7[2] = cal_reg[5][6]; in_7[3] = cal_reg[5][7]; in_7[4] = cal_reg[6][6]; in_7[5] = cal_reg[6][7]; in_7[6] = cal_reg[7][6]; in_7[7] = cal_reg[7][7]; in_7[8] = 0;
                    in_8[0] = cal_reg[0][8]; in_8[1] = cal_reg[0][9]; in_8[2] = cal_reg[1][8]; in_8[3] = cal_reg[1][9]; in_8[4] = cal_reg[2][8]; in_8[5] = cal_reg[2][9]; in_8[6] = cal_reg[3][8]; in_8[7] = cal_reg[3][9]; in_8[8] = 0;
                    in_9[0] = cal_reg[0][10]; in_9[1] = cal_reg[0][11]; in_9[2] = cal_reg[1][10]; in_9[3] = cal_reg[1][11]; in_9[4] = cal_reg[2][10]; in_9[5] = cal_reg[2][11]; in_9[6] = cal_reg[3][10]; in_9[7] = cal_reg[3][11]; in_9[8] = 0;
                    in_10[0] = cal_reg[0][12]; in_10[1] = cal_reg[0][13]; in_10[2] = cal_reg[1][12]; in_10[3] = cal_reg[1][13]; in_10[4] = cal_reg[2][12]; in_10[5] = cal_reg[2][13]; in_10[6] = cal_reg[3][12]; in_10[7] = cal_reg[3][13]; in_10[8] = 0;
                    in_11[0] = cal_reg[0][14]; in_11[1] = cal_reg[0][15]; in_11[2] = cal_reg[1][14]; in_11[3] = cal_reg[1][15]; in_11[4] = cal_reg[2][14]; in_11[5] = cal_reg[2][15]; in_11[6] = cal_reg[3][14]; in_11[7] = cal_reg[3][15]; in_11[8] = 0;
                    in_12[0] = cal_reg[4][8]; in_12[1] = cal_reg[4][9]; in_12[2] = cal_reg[5][8]; in_12[3] = cal_reg[5][9]; in_12[4] = cal_reg[6][8]; in_12[5] = cal_reg[6][9]; in_12[6] = cal_reg[7][8]; in_12[7] = cal_reg[7][9]; in_12[8] = 0;
                    in_13[0] = cal_reg[4][10]; in_13[1] = cal_reg[4][11]; in_13[2] = cal_reg[5][10]; in_13[3] = cal_reg[5][11]; in_13[4] = cal_reg[6][10]; in_13[5] = cal_reg[6][11]; in_13[6] = cal_reg[7][10]; in_13[7] = cal_reg[7][11]; in_13[8] = 0;
                    in_14[0] = cal_reg[4][12]; in_14[1] = cal_reg[4][13]; in_14[2] = cal_reg[5][12]; in_14[3] = cal_reg[5][13]; in_14[4] = cal_reg[6][12]; in_14[5] = cal_reg[6][13]; in_14[6] = cal_reg[7][12]; in_14[7] = cal_reg[7][13]; in_14[8] = 0;
                    in_15[0] = cal_reg[4][14]; in_15[1] = cal_reg[4][15]; in_15[2] = cal_reg[5][14]; in_15[3] = cal_reg[5][15]; in_15[4] = cal_reg[6][14]; in_15[5] = cal_reg[6][15]; in_15[6] = cal_reg[7][14]; in_15[7] = cal_reg[7][15]; in_15[8] = 0;
                end
                else if(max_counter==2)begin
                   
                    in_0[0] = cal_reg[8][0];  in_0[1] = cal_reg[8][1]; in_0[2] = cal_reg[9][0]; in_0[3] = cal_reg[9][1]; in_0[4] = cal_reg[10][0]; in_0[5] = cal_reg[10][1]; in_0[6] = cal_reg[11][0]; in_0[7] = cal_reg[11][1]; in_0[8] = 0;
                    in_1[0] = cal_reg[8][2];  in_1[1] = cal_reg[8][3]; in_1[2] = cal_reg[9][2]; in_1[3] = cal_reg[9][3]; in_1[4] = cal_reg[10][2]; in_1[5] = cal_reg[10][3]; in_1[6] = cal_reg[11][2]; in_1[7] = cal_reg[11][3]; in_1[8] = 0;
                    in_2[0] = cal_reg[8][4]; in_2[1] = cal_reg[8][5]; in_2[2] = cal_reg[9][4]; in_2[3] = cal_reg[9][5]; in_2[4] = cal_reg[10][4]; in_2[5] = cal_reg[10][5]; in_2[6] = cal_reg[11][4]; in_2[7] = cal_reg[11][5]; in_2[8] = 0;
                    in_3[0] = cal_reg[8][6]; in_3[1] = cal_reg[8][7]; in_3[2] = cal_reg[9][6]; in_3[3] = cal_reg[9][7]; in_3[4] = cal_reg[10][6]; in_3[5] = cal_reg[10][7]; in_3[6] = cal_reg[11][6]; in_3[7] = cal_reg[11][7]; in_3[8] = 0;
                    in_4[0] = cal_reg[12][0]; in_4[1] = cal_reg[12][1]; in_4[2] = cal_reg[13][0]; in_4[3] = cal_reg[13][1]; in_4[4] = cal_reg[14][0]; in_4[5] = cal_reg[14][1]; in_4[6] = cal_reg[15][0]; in_4[7] = cal_reg[15][1]; in_4[8] = 0;
                    in_5[0] = cal_reg[12][2]; in_5[1] = cal_reg[12][3]; in_5[2] = cal_reg[13][2]; in_5[3] = cal_reg[13][3]; in_5[4] = cal_reg[14][2]; in_5[5] = cal_reg[14][3]; in_5[6] = cal_reg[15][2]; in_5[7] = cal_reg[15][3]; in_5[8] = 0;
                    in_6[0] = cal_reg[12][4]; in_6[1] = cal_reg[12][5]; in_6[2] = cal_reg[13][4]; in_6[3] = cal_reg[13][5]; in_6[4] = cal_reg[14][4]; in_6[5] = cal_reg[14][5]; in_6[6] = cal_reg[15][4]; in_6[7] = cal_reg[15][5]; in_6[8] = 0;
                    in_7[0] = cal_reg[12][6]; in_7[1] = cal_reg[12][7]; in_7[2] = cal_reg[13][6]; in_7[3] = cal_reg[13][7]; in_7[4] = cal_reg[14][6]; in_7[5] = cal_reg[14][7]; in_7[6] = cal_reg[15][6]; in_7[7] = cal_reg[15][7]; in_7[8] = 0;
                    in_8[0] = cal_reg[8][8]; in_8[1] = cal_reg[8][9]; in_8[2] = cal_reg[9][8]; in_8[3] = cal_reg[9][9]; in_8[4] = cal_reg[10][8]; in_8[5] = cal_reg[10][9]; in_8[6] = cal_reg[11][8]; in_8[7] = cal_reg[11][9]; in_8[8] = 0;
                    in_9[0] = cal_reg[8][10]; in_9[1] = cal_reg[8][11]; in_9[2] = cal_reg[9][10]; in_9[3] = cal_reg[9][11]; in_9[4] = cal_reg[10][10]; in_9[5] = cal_reg[10][11]; in_9[6] = cal_reg[11][10]; in_9[7] = cal_reg[11][11]; in_9[8] = 0;
                    in_10[0] = cal_reg[8][12]; in_10[1] = cal_reg[8][13]; in_10[2] = cal_reg[9][12]; in_10[3] = cal_reg[9][13]; in_10[4] = cal_reg[10][12]; in_10[5] = cal_reg[10][13]; in_10[6] = cal_reg[11][12]; in_10[7] = cal_reg[11][13]; in_10[8] = 0;
                    in_11[0] = cal_reg[8][14]; in_11[1] = cal_reg[8][15]; in_11[2] = cal_reg[9][14]; in_11[3] = cal_reg[9][15]; in_11[4] = cal_reg[10][14]; in_11[5] = cal_reg[10][15]; in_11[6] = cal_reg[11][14]; in_11[7] = cal_reg[11][15]; in_11[8] = 0;
                    in_12[0] = cal_reg[12][8]; in_12[1] = cal_reg[12][9]; in_12[2] = cal_reg[13][8]; in_12[3] = cal_reg[13][9]; in_12[4] = cal_reg[14][8]; in_12[5] = cal_reg[14][9]; in_12[6] = cal_reg[15][8]; in_12[7] = cal_reg[15][9]; in_12[8] = 0;
                    in_13[0] = cal_reg[12][10]; in_13[1] = cal_reg[12][11]; in_13[2] = cal_reg[13][10]; in_13[3] = cal_reg[13][11]; in_13[4] = cal_reg[14][10]; in_13[5] = cal_reg[14][11]; in_13[6] = cal_reg[15][10]; in_13[7] = cal_reg[15][11]; in_13[8] = 0;
                    in_14[0] = cal_reg[12][12]; in_14[1] = cal_reg[12][13]; in_14[2] = cal_reg[13][12]; in_14[3] = cal_reg[13][13]; in_14[4] = cal_reg[14][12]; in_14[5] = cal_reg[14][13]; in_14[6] = cal_reg[15][12]; in_14[7] = cal_reg[15][13]; in_14[8] = 0;
                    in_15[0] = cal_reg[12][14]; in_15[1] = cal_reg[12][15]; in_15[2] = cal_reg[13][14]; in_15[3] = cal_reg[13][15]; in_15[4] = cal_reg[14][14]; in_15[5] = cal_reg[14][15]; in_15[6] = cal_reg[15][14]; in_15[7] = cal_reg[15][15]; in_15[8] = 0;
                end
            end
            endcase 
        
        
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
       for(i=0;i<=8;i=i+1) begin     
            in_0_reg[i]<= 0; in_1_reg[i]<= 0;in_2_reg[i]<= 0;in_3_reg[i]<= 0;in_4_reg[i]<= 0;in_5_reg[i]<= 0;
            in_6_reg[i]<= 0;in_7_reg[i]<= 0;in_8_reg[i]<= 0;in_9_reg[i]<= 0;in_10_reg[i]<= 0;in_11_reg[i]<= 0;
            in_12_reg[i]<= 0;in_13_reg[i]<= 0;in_14_reg[i]<= 0;in_15_reg[i]<= 0;
        end 
    end
    else begin
        if(cs_state==IDLE) begin
            for(i=0;i<=8;i=i+1) begin     
                in_0_reg[i]<= 0; in_1_reg[i]<= 0;in_2_reg[i]<= 0;in_3_reg[i]<= 0;in_4_reg[i]<= 0;in_5_reg[i]<= 0;
                in_6_reg[i]<= 0;in_7_reg[i]<= 0;in_8_reg[i]<= 0;in_9_reg[i]<= 0;in_10_reg[i]<= 0;in_11_reg[i]<= 0;
                in_12_reg[i]<= 0;in_13_reg[i]<= 0;in_14_reg[i]<= 0;in_15_reg[i]<= 0;
            end
        end
        else  begin
            for(i=0;i<=8;i=i+1) begin 
                in_0_reg[i]<= in_0[i];in_1_reg[i]<= in_1[i];in_2_reg[i]<= in_2[i];in_3_reg[i]<= in_3[i];in_4_reg[i]<= in_4[i];in_5_reg[i]<= in_5[i];
                in_6_reg[i]<= in_6[i];in_7_reg[i]<= in_7[i];in_8_reg[i]<= in_8[i];in_9_reg[i]<= in_9[i];in_10_reg[i]<= in_10[i];in_11_reg[i]<= in_11[i];
                in_12_reg[i]<= in_12[i];in_13_reg[i]<= in_13[i];in_14_reg[i]<= in_14[i];in_15_reg[i]<= in_15[i];
            end
        end
    end
end

sorting_8 S0(.in0(in_0[0]),.in1(in_0[1]),.in2(in_0[2]),.in3(in_0[3]),.in4(in_0[4]),.in5(in_0[5]),.in6(in_0[6]),.in7(in_0[7]),.in8(in_0[8]),.clock(clk),.out(out[0]),.max0(max0[0]),.max1(max1[0]));//suppose output 3 and 4
sorting_8 S1(.in0(in_1[0]),.in1(in_1[1]),.in2(in_1[2]),.in3(in_1[3]),.in4(in_1[4]),.in5(in_1[5]),.in6(in_1[6]),.in7(in_1[7]),.in8(in_1[8]),.clock(clk),.out(out[1]),.max0(max0[1]),.max1(max1[1]));//1347
sorting_8 S2(.in0(in_2[0]),.in1(in_2[1]),.in2(in_2[2]),.in3(in_2[3]),.in4(in_2[4]),.in5(in_2[5]),.in6(in_2[6]),.in7(in_2[7]),.in8(in_2[8]),.clock(clk),.out(out[2]),.max0(max0[2]),.max1(max1[2]));
sorting_8 S3(.in0(in_3[0]),.in1(in_3[1]),.in2(in_3[2]),.in3(in_3[3]),.in4(in_3[4]),.in5(in_3[5]),.in6(in_3[6]),.in7(in_3[7]),.in8(in_3[8]),.clock(clk),.out(out[3]),.max0(max0[3]),.max1(max1[3]));
sorting_8 S4(.in0(in_4[0]),.in1(in_4[1]),.in2(in_4[2]),.in3(in_4[3]),.in4(in_4[4]),.in5(in_4[5]),.in6(in_4[6]),.in7(in_4[7]),.in8(in_4[8]),.clock(clk),.out(out[4]),.max0(max0[4]),.max1(max1[4]));
sorting_8 S5(.in0(in_5[0]),.in1(in_5[1]),.in2(in_5[2]),.in3(in_5[3]),.in4(in_5[4]),.in5(in_5[5]),.in6(in_5[6]),.in7(in_5[7]),.in8(in_5[8]),.clock(clk),.out(out[5]),.max0(max0[5]),.max1(max1[5]));
sorting_8 S6(.in0(in_6[0]),.in1(in_6[1]),.in2(in_6[2]),.in3(in_6[3]),.in4(in_6[4]),.in5(in_6[5]),.in6(in_6[6]),.in7(in_6[7]),.in8(in_6[8]),.clock(clk),.out(out[6]),.max0(max0[6]),.max1(max1[6]));
sorting_8 S7(.in0(in_7[0]),.in1(in_7[1]),.in2(in_7[2]),.in3(in_7[3]),.in4(in_7[4]),.in5(in_7[5]),.in6(in_7[6]),.in7(in_7[7]),.in8(in_7[8]),.clock(clk),.out(out[7]),.max0(max0[7]),.max1(max1[7]));
sorting_8 S8(.in0(in_8[0]),.in1(in_8[1]),.in2(in_8[2]),.in3(in_8[3]),.in4(in_8[4]),.in5(in_8[5]),.in6(in_8[6]),.in7(in_8[7]),.in8(in_8[8]),.clock(clk),.out(out[8]),.max0(max0[8]),.max1(max1[8]));
sorting_8 S9(.in0(in_9[0]),.in1(in_9[1]),.in2(in_9[2]),.in3(in_9[3]),.in4(in_9[4]),.in5(in_9[5]),.in6(in_9[6]),.in7(in_9[7]),.in8(in_9[8]),.clock(clk),.out(out[9]),.max0(max0[9]),.max1(max1[9]));
sorting_8 S10(.in0(in_10[0]),.in1(in_10[1]),.in2(in_10[2]),.in3(in_10[3]),.in4(in_10[4]),.in5(in_10[5]),.in6(in_10[6]),.in7(in_10[7]),.in8(in_10[8]),.clock(clk),.out(out[10]),.max0(max0[10]),.max1(max1[10]));
sorting_8 S11(.in0(in_11[0]),.in1(in_11[1]),.in2(in_11[2]),.in3(in_11[3]),.in4(in_11[4]),.in5(in_11[5]),.in6(in_11[6]),.in7(in_11[7]),.in8(in_11[8]),.clock(clk),.out(out[11]),.max0(max0[11]),.max1(max1[11]));
sorting_8 S12(.in0(in_12[0]),.in1(in_12[1]),.in2(in_12[2]),.in3(in_12[3]),.in4(in_12[4]),.in5(in_12[5]),.in6(in_12[6]),.in7(in_12[7]),.in8(in_12[8]),.clock(clk),.out(out[12]),.max0(max0[12]),.max1(max1[12]));
sorting_8 S13(.in0(in_13[0]),.in1(in_13[1]),.in2(in_13[2]),.in3(in_13[3]),.in4(in_13[4]),.in5(in_13[5]),.in6(in_13[6]),.in7(in_13[7]),.in8(in_13[8]),.clock(clk),.out(out[13]),.max0(max0[13]),.max1(max1[13]));
sorting_8 S14(.in0(in_14[0]),.in1(in_14[1]),.in2(in_14[2]),.in3(in_14[3]),.in4(in_14[4]),.in5(in_14[5]),.in6(in_14[6]),.in7(in_14[7]),.in8(in_14[8]),.clock(clk),.out(out[14]),.max0(max0[14]),.max1(max1[14]));
sorting_8 S15(.in0(in_15[0]),.in1(in_15[1]),.in2(in_15[2]),.in3(in_15[3]),.in4(in_15[4]),.in5(in_15[5]),.in6(in_15[6]),.in7(in_15[7]),.in8(in_15[8]),.clock(clk),.out(out[15]),.max0(max0[15]),.max1(max1[15]));

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
       for(i=0;i<=15;i=i+1) begin
            cal_temp[0][i] <= 0;
            cal_temp[1][i] <= 0;
        end 
    end
    else begin
        if(cs_state==IDLE)begin
            for(i=0;i<=15;i=i+1) begin
                cal_temp[0][i] <= 0;
                cal_temp[1][i] <= 0;
            end
        end
        else if(cs_state==SAVE_ACTION)begin
            for(i=0;i<=15;i=i+1) begin
                cal_temp[0][i] <= 0;
                cal_temp[1][i] <= 0;
            end
        end
    /*  else if(cs_state==MEDIUM&&ns_state!=MEDIUM)begin
            for(i=0;i<=15;i=i+1) begin
                cal_temp[0][i] <= cal_temp[0][i];
                cal_temp[1][i] <= cal_temp[1][i];
            end
        end*/
        else if(cs_state==MEDIUM)begin
            case(image_size_reg) 
            0: begin
                for(i=0;i<=15;i=i+1) begin
                    cal_temp[0][i] <= out[i];
                end
            end
            1:begin
                case(medium_count)
                    3,5: begin
                        for(i=0;i<=15;i=i+1) begin
                        cal_temp[1][i] <= out[i];
                    end
                    end
                    2,4:begin
                        for(i=0;i<=15;i=i+1) begin
                        cal_temp[0][i] <= out[i];
                        end
                    end
                endcase
            end
            2:begin
                    case(medium_count)
                        3,5,7,9,11,13,15,17,19: begin
                            for(i=0;i<=15;i=i+1) begin
                            cal_temp[1][i] <= out[i];
                            cal_temp[0][i] <= cal_temp[0][i];
                        end
                        end
                        2,4,6,8,10,12,14,16,18:begin
                            for(i=0;i<=15;i=i+1) begin
                                cal_temp[1][i] <= cal_temp[1][i];
                                cal_temp[0][i] <= out[i];
                            end
                        end
                        default: begin
                            for(i=0;i<=15;i=i+1) begin
                                cal_temp[0][i] <= cal_temp[0][i];
                                cal_temp[1][i] <= cal_temp[1][i];
                            end
                        end
                    endcase
                end
            default: begin
                for(i=0;i<=15;i=i+1) begin
                    cal_temp[0][i] <= cal_temp[0][i];
                    cal_temp[1][i] <= cal_temp[1][i];
                end
            end
            endcase
        end
        
        else begin
            for(i=0;i<=15;i=i+1) begin
                    cal_temp[0][i] <= 0;
                    cal_temp[1][i] <= 0;
            end
        end
    end    
end





always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<=15;i=i+1) begin
            max0_reg[i] <= 0;
        end
    end
    else begin
    if(cs_state== SAVE_ACTION) begin
        for(i=0;i<=15;i=i+1) begin
            max0_reg[i] <= 0;
        end
    end
    else if(cs_state==MAX_POOLING) begin
        for(i=0;i<=15;i=i+1) begin
            max0_reg[i] <= max0[i];
        end
    end
    else begin
        for(i=0;i<=15;i=i+1) begin
            max0_reg[i] <= max0_reg[i];
        end
    end
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<=15;i=i+1) begin
            max1_reg[i] <= 0;
        end
    end
    else begin
    if(cs_state== SAVE_ACTION) begin
        for(i=0;i<=15;i=i+1) begin
            max1_reg[i] <= 0;
        end
    end
    else if(cs_state==MAX_POOLING) begin
        for(i=0;i<=15;i=i+1) begin
            max1_reg[i] <= max1[i];
        end
    end
    else begin
        for(i=0;i<=15;i=i+1) begin
            max1_reg[i] <= max1_reg[i];
        end
    end
    end
end

//==================================================================
// CROSS-CORRELATION
//==================================================================
/*
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        template_count <= 4'd0;
    end
    else begin
     if (ns_state==IDLE) begin
        template_count <= 4'd0;
    end
    else if(template_count==4'd9) begin
        template_count <= 4'd9;
    end
    else if(in_valid) begin
        template_count <= template_count + 4'd1;
    end
    end
end*/
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        template_count <= 4'd0;
    end
    else begin
        if (cs_state==IDLE&&!in_valid) begin
            template_count <= 4'd0;
        end
        else if(template_count==4'd9) begin
            template_count <= 4'd9;
        end
        else if(in_valid) begin
            template_count <= template_count + 4'd1;
        end
        else begin
            template_count <= template_count;
        end
    end
end

always@(posedge clk  or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<=2;i=i+1) begin
            for(j=0;j<=2;j=j+1) begin
                template_reg[i][j] <= 1'b0;
            end
        end
    end
    else begin
        if(in_valid) begin
            case(template_count)
                'd0: template_reg[0][0] <= template;
                'd1: template_reg[0][1] <= template;
                'd2: template_reg[0][2] <= template;
                'd3: template_reg[1][0] <= template;
                'd4: template_reg[1][1] <= template;
                'd5: template_reg[1][2] <= template;
                'd6: template_reg[2][0] <= template;
                'd7: template_reg[2][1] <= template;
                'd8: template_reg[2][2] <= template;
            endcase
        end
        else begin
            for(i=0;i<=2;i=i+1) begin
                for(j=0;j<=2;j=j+1) begin
                    template_reg[i][j] <= template_reg[i][j];
                end
            end
        end
    end
end


always@(*) begin
    temp1 = tempa*tempb;
    temp2 = tempc*tempd;
    temp3 = tempe*tempf;
    temp_sum =(cross_cnt==15)? 0 : (temp1 + temp2 + temp3 + temp_sum_reg);
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        temp_sum_reg <= 0;
    end
    else  begin
        if(cs_state==ACTION_WAIT) begin
            temp_sum_reg <= 0;
        end
        else begin
            temp_sum_reg <= temp_sum;
        end
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_temp <= 0;
    end

    else begin
        if(cs_state==ACTION_WAIT) begin
            out_temp <= 0;
        end
        else if(cs_state == CROSS && cross_cnt==19)begin
            out_temp <= temp_sum;
        end
        else  begin
            out_temp <= out_temp<<1;
        end
    end
end
reg [7:0] zero_padding_cal[0:17][0:17] ;
always@(*) begin
    for(i=0;i<=17;i=i+1) begin
            for(j=0;j<=17;j=j+1) begin
                zero_padding_cal[i][j] = 0;
            end
        end
    if(image_size_reg==0) begin
        for(i=1;i<=4;i=i+1) begin
            for(j=1;j<=4;j=j+1) begin
                zero_padding_cal[i][j] = cal_reg[i-1][j-1];
            end
        end
    end
    else if(image_size_reg==1) begin
        for(i=1;i<=8;i=i+1) begin
            for(j=1;j<=8;j=j+1) begin
                zero_padding_cal[i][j] = cal_reg[i-1][j-1];
            end
        end
    end
    else if(image_size_reg==2) begin
        for(i=1;i<=16;i=i+1) begin
            for(j=1;j<=16;j=j+1) begin
                zero_padding_cal[i][j] = cal_reg[i-1][j-1];
            end
        end
    end
end
always@(*) begin
    if(cs_state==CROSS) begin
    case (cross_cnt)
        17: begin
            tempa = zero_padding_cal[cross_y_count][cross_x_count];
            tempb = template_reg[0][0];
            tempc = zero_padding_cal[cross_y_count][cross_x_count + 1];
            tempd = template_reg[0][1];
            tempe = zero_padding_cal[cross_y_count][cross_x_count + 2];
            tempf = template_reg[0][2];
        end 
        18: begin
            tempa = zero_padding_cal[cross_y_count+1][cross_x_count];
            tempb = template_reg[1][0];
            tempc = zero_padding_cal[cross_y_count+1][cross_x_count + 1];
            tempd = template_reg[1][1];
            tempe = zero_padding_cal[cross_y_count+1][cross_x_count + 2];
            tempf = template_reg[1][2];
        end
        19: begin
            tempa = zero_padding_cal[cross_y_count+2][cross_x_count];
            tempb = template_reg[2][0];
            tempc = zero_padding_cal[cross_y_count+2][cross_x_count + 1];
            tempd = template_reg[2][1];
            tempe = zero_padding_cal[cross_y_count+2][cross_x_count + 2];
            tempf = template_reg[2][2];
        end
        default: begin
            tempa = 0;
            tempb = 0;
            tempc = 0;
            tempd = 0;
            tempe = 0;
            tempf = 0;
        end
    endcase
    end
    else begin
        tempa = 0;
        tempb = 0;
        tempc = 0;
        tempd = 0;
        tempe = 0;
        tempf = 0;
    end
end
always@(*) begin
        case(image_size_reg)
            0: border = 5'd3;
            1: border = 5'd7;
            2: border = 5'd15;
            default: border = 5'd0;
        endcase
    
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cross_x_count<=0;
    end
    else  begin
        if(cs_state==CROSS &&cross_cnt==15)begin
            if(cross_x_count==border) begin
                cross_x_count<=0;
            end
            else  begin
                cross_x_count<=cross_x_count+1;
            end
            end
            else begin
                cross_x_count<=cross_x_count;
            end
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cross_y_count<=0;
    end
    else  begin
        if(cs_state==CROSS&&cross_cnt==15)begin
            if( cross_x_count==border&&cross_y_count==border) begin
                cross_y_count<=0;
            end
            else if(cross_x_count==border) begin
                cross_y_count<=cross_y_count+1;
            end
            else  begin
                cross_y_count<=cross_y_count;
            end
        end
        else begin
            cross_y_count<=cross_y_count;
        end
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cross_cnt <= 5'b0;
    end
    else begin
        if(cs_state==CROSS ) begin 
            if(cross_cnt==5'd19) begin
                cross_cnt <= 0;
            end
            else begin
                cross_cnt <= cross_cnt +1;
            end
        end
        else if(ns_state==CROSS) begin
            cross_cnt <= 5'd16;
        end
        else begin
            cross_cnt <= 0;
        end
    end
    
end

// always@(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//        end_flag <= 0;
//     end
//     else if(cross_x_count==border&&cross_y_count==border&&cross_cnt==19) begin
//         end_flag <= 1;
//     end
//     else if (cross_cnt==19) begin
//         end_flag <= 0;
//     end
//     else begin
//         end_flag <= end_flag;
//     end
// end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        end_flag <= 0;
    end
    else begin
        if(cs_state == CROSS)begin
            if(cross_x_count==border&&cross_y_count==border&&cross_cnt==19) begin
                end_flag <= 1;
            end
            else  begin
                end_flag <=end_flag;
            end
        end 
        else begin
            end_flag <= 0;
        end
    end
end
//==================================================================
// OUT 
//==================================================================

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 1'b0;
    end
    else begin
        if(cs_state==CROSS) begin
            if(end_flag && cross_cnt==19) begin
                out_valid <= 1'b0;
            end
            else if(cross_cnt==19) begin
                out_valid <= 1'b1;
            end
            else begin
                out_valid <= out_valid;
            end
        end    
        else begin
            out_valid <= 1'b0;
        end
    end
end

always@(*) begin
    if(out_valid) begin
        out_value = out_temp[19];
    end
    else begin
        out_value = 1'b0;
    end
end

endmodule
//==========================================//
//             Memory Module                //
//==========================================//
module sram_128x64_inst(A, DO, DI, CK, WEB, OE, CS);
input [6:0] A;
input [63:0] DI;
input CK, CS, OE, WEB;
output [63:0] DO;

 MEM_128_64 U1(.A0(A[0]),.A1(A[1]),.A2(A[2]),.A3(A[3]),.A4(A[4]),.A5(A[5]),.A6(A[6])
            ,.DO0(DO[0]),.DO1(DO[1]),.DO2(DO[2]),.DO3(DO[3]),.DO4(DO[4]),.DO5(DO[5])
            ,.DO6(DO[6]),.DO7(DO[7]),.DO8(DO[8]),.DO9(DO[9]),.DO10(DO[10]),.DO11(DO[11])
            ,.DO12(DO[12]),.DO13(DO[13]),.DO14(DO[14]),.DO15(DO[15])
            ,.DO16(DO[16]), .DO17(DO[17]), .DO18(DO[18]), .DO19(DO[19]),
            .DO20(DO[20]), .DO21(DO[21]), .DO22(DO[22]), .DO23(DO[23]),
            .DO24(DO[24]), .DO25(DO[25]), .DO26(DO[26]), .DO27(DO[27]),
            .DO28(DO[28]), .DO29(DO[29]), .DO30(DO[30]), .DO31(DO[31]),
            .DO32(DO[32]), .DO33(DO[33]), .DO34(DO[34]), .DO35(DO[35]),
            .DO36(DO[36]), .DO37(DO[37]), .DO38(DO[38]), .DO39(DO[39]),
            .DO40(DO[40]), .DO41(DO[41]), .DO42(DO[42]), .DO43(DO[43]),
            .DO44(DO[44]), .DO45(DO[45]), .DO46(DO[46]), .DO47(DO[47]),
            .DO48(DO[48]), .DO49(DO[49]), .DO50(DO[50]), .DO51(DO[51]),
            .DO52(DO[52]), .DO53(DO[53]), .DO54(DO[54]), .DO55(DO[55]),
            .DO56(DO[56]), .DO57(DO[57]), .DO58(DO[58]), .DO59(DO[59]),
            .DO60(DO[60]), .DO61(DO[61]), .DO62(DO[62]), .DO63(DO[63])
            ,.DI0(DI[0]),.DI1(DI[1]),.DI2(DI[2]),.DI3(DI[3])
            ,.DI4(DI[4]),.DI5(DI[5]),.DI6(DI[6]),.DI7(DI[7]),
            .DI8(DI[8]), .DI9(DI[9]), .DI10(DI[10]), .DI11(DI[11]),
            .DI12(DI[12]), .DI13(DI[13]), .DI14(DI[14]), .DI15(DI[15]),
            .DI16(DI[16]), .DI17(DI[17]), .DI18(DI[18]), .DI19(DI[19]),
            .DI20(DI[20]), .DI21(DI[21]), .DI22(DI[22]), .DI23(DI[23]),
            .DI24(DI[24]), .DI25(DI[25]), .DI26(DI[26]), .DI27(DI[27]),
            .DI28(DI[28]), .DI29(DI[29]), .DI30(DI[30]), .DI31(DI[31]),
            .DI32(DI[32]), .DI33(DI[33]), .DI34(DI[34]), .DI35(DI[35]),
            .DI36(DI[36]), .DI37(DI[37]), .DI38(DI[38]), .DI39(DI[39]),
            .DI40(DI[40]), .DI41(DI[41]), .DI42(DI[42]), .DI43(DI[43]),
            .DI44(DI[44]), .DI45(DI[45]), .DI46(DI[46]), .DI47(DI[47]),
            .DI48(DI[48]), .DI49(DI[49]), .DI50(DI[50]), .DI51(DI[51]),
            .DI52(DI[52]), .DI53(DI[53]), .DI54(DI[54]), .DI55(DI[55]),
            .DI56(DI[56]), .DI57(DI[57]), .DI58(DI[58]), .DI59(DI[59]),
            .DI60(DI[60]), .DI61(DI[61]), .DI62(DI[62]), .DI63(DI[63])
            ,.CK(CK),.WEB(WEB),.OE(OE),.CS(CS));
endmodule


module sorting_8 (in0,in1,in2,in3,in4,in5,in6,in7,in8,clock,
                          out,max0,max1 );

input [7:0] in0,in1,in2,in3,in4,in5,in6,in7,in8;
output reg [7:0] out;
wire [7:0] out1,out2,out5,out6,out0,out3,out4,out7;
input clock;
integer m,k;
wire [7:0] value [0:7];
wire [7:0] value_a [0:7];
wire [7:0] value_b [0:7];
wire [7:0] value_c [0:7];
reg [7:0] value_c_reg [0:7];
wire [7:0] value_d [0:7];
wire [7:0] value_e [0:7];
wire [7:0] value_f [0:7];
reg [7:0] in8_reg ;
output [7:0] max0, max1;

always@(posedge clock) begin
    in8_reg <= in8;
end
assign value[0] = in0;
assign value[1] = in1;
assign value[2] = in2;
assign value[3] = in3;
assign value[4] = in4;
assign value[5] = in5;
assign value[6] = in6;
assign value[7] = in7;

// Step 1: Assign values to value_a based on comparisons
assign value_a[0] = (value[0] > value[2]) ? value[0] : value[2];
assign value_a[2] = (value[0] > value[2]) ? value[2] : value[0];
assign value_a[1] = (value[1] > value[3]) ? value[1] : value[3];
assign value_a[3] = (value[1] > value[3]) ? value[3] : value[1];
assign value_a[4] = (value[4] > value[6]) ? value[4] : value[6];
assign value_a[6] = (value[4] > value[6]) ? value[6] : value[4];
assign value_a[5] = (value[5] > value[7]) ? value[5] : value[7];
assign value_a[7] = (value[5] > value[7]) ? value[7] : value[5];

assign max0 = (value_a[0] > value_a[1]) ? value_a[0] : value_a[1];
assign max1 = (value_a[4] > value_a[5]) ? value_a[4] : value_a[5];


// Step 2: Assign values to value_b
assign value_b[0] = (value_a[0] > value_a[4]) ? value_a[0] : value_a[4];
assign value_b[4] = (value_a[0] > value_a[4]) ? value_a[4] : value_a[0];
assign value_b[1] = (value_a[1] > value_a[5]) ? value_a[1] : value_a[5];
assign value_b[5] = (value_a[1] > value_a[5]) ? value_a[5] : value_a[1];
assign value_b[2] = (value_a[2] > value_a[6]) ? value_a[2] : value_a[6];
assign value_b[6] = (value_a[2] > value_a[6]) ? value_a[6] : value_a[2];
assign value_b[3] = (value_a[3] > value_a[7]) ? value_a[3] : value_a[7];
assign value_b[7] = (value_a[3] > value_a[7]) ? value_a[7] : value_a[3];

// Step 3: Assign values to value_c
assign value_c[0] = (value_b[0] > value_b[1]) ? value_b[0] : value_b[1];
assign value_c[1] = (value_b[0] > value_b[1]) ? value_b[1] : value_b[0];
assign value_c[2] = (value_b[2] > value_b[3]) ? value_b[2] : value_b[3];
assign value_c[3] = (value_b[2] > value_b[3]) ? value_b[3] : value_b[2];
assign value_c[4] = (value_b[4] > value_b[5]) ? value_b[4] : value_b[5];
assign value_c[5] = (value_b[4] > value_b[5]) ? value_b[5] : value_b[4];
assign value_c[6] = (value_b[6] > value_b[7]) ? value_b[6] : value_b[7];
assign value_c[7] = (value_b[6] > value_b[7]) ? value_b[7] : value_b[6];

always@(posedge clock) begin
    for(m=0;m<=7;m=m+1) begin
        value_c_reg[m] <= value_c[m];
    end
end

// Step 4: Assign values to value_d
assign value_d[0] = value_c_reg[0];
assign value_d[1] = value_c_reg[1];
assign value_d[2] = (value_c_reg[2] > value_c_reg[4]) ? value_c_reg[2] : value_c_reg[4];
assign value_d[4] = (value_c_reg[2] > value_c_reg[4]) ? value_c_reg[4] : value_c_reg[2];
assign value_d[3] = (value_c_reg[3] > value_c_reg[5]) ? value_c_reg[3] : value_c_reg[5];
assign value_d[5] = (value_c_reg[3] > value_c_reg[5]) ? value_c_reg[5] : value_c_reg[3];
assign value_d[6] = value_c_reg[6];
assign value_d[7] = value_c_reg[7];

// Step 5: Assign values to value_e
assign value_e[0] = value_d[0];
assign value_e[2] = value_d[2];
assign value_e[1] = (value_d[1] > value_d[4]) ? value_d[1] : value_d[4];
assign value_e[4] = (value_d[1] > value_d[4]) ? value_d[4] : value_d[1];
assign value_e[3] = (value_d[3] > value_d[6]) ? value_d[3] : value_d[6];
assign value_e[6] = (value_d[3] > value_d[6]) ? value_d[6] : value_d[3];
assign value_e[5] = value_d[5];
assign value_e[7] = value_d[7];

// Step 6: Assign values to value_f
assign value_f[0] = value_e[0];
assign value_f[1] = value_e[1];
assign value_f[2] = value_e[2];
assign value_f[3] = (value_e[3] > value_e[4]) ? value_e[3] : value_e[4];
assign value_f[4] = (value_e[3] > value_e[4]) ? value_e[4] : value_e[3];
assign value_f[5] = value_e[5];
assign value_f[6] = value_e[6];
assign value_f[7] = value_e[7];
always@(*) begin
    if(value_f[3]<in8_reg) begin
        out = value_f[3];
    end
    else if(value_f[4]>in8_reg) begin
        out = value_f[4];
    end
    else begin
        out = in8_reg;
    end
end


// Step 7: Assign output
assign out0 = value_e[0];
assign out1 = value_f[1];
assign out2 = value_f[2];
assign out3 = value_f[3];
assign out4 = value_f[4];
assign out5 = value_f[5];
assign out6 = value_f[6];
assign out7 = value_e[7];

endmodule

