module BB(
    //Input Ports
    input clk,
    input rst_n,
    input in_valid,
    input [1:0] inning,   // Current inning number
    input half,           // 0: top of the inning, 1: bottom of the inning
    input [2:0] action,   // Action code

    //Output Ports
    output reg out_valid,  // Result output valid
    output reg [7:0] score_A,  // Score of team A (guest team)
    output reg [7:0] score_B,  // Score of team B (home team)
    output reg [1:0] result    // 0: Team A wins, 1: Team B wins, 2: Darw
);

//==============================================//
//             Action Memo for Students         //
// Action code interpretation:
// 3’d0: Walk (BB)
// 3’d1: 1H (single hit)
// 3’d2: 2H (double hit)
// 3’d3: 3H (triple hit)
// 3’d4: HR (home run)
// 3’d5: Bunt (short hit)
// 3’d6: Ground ball
// 3’d7: Fly ball
//==============================================//

//==============================================//
//             Parameter and Integer            //
//==============================================//
// State declaration for FSM
// Example: parameter IDLE = 3'b000;
localparam Walk = 3'd0;
localparam Single_hit = 3'd1;
localparam Double_hit = 3'd2;
localparam Triple_hit = 3'd3;
localparam HR = 3'd4;
localparam Bunt = 3'd5;
localparam Ground_ball = 3'd6;
localparam Fly_ball = 3'd7;
/*
localparam IDLE = 4'd8;
localparam COMPUTE = 4'd9;
localparam DONE = 4'd10;*/


//==============================================//
//                 reg declaration              //
//==============================================//
/*reg [3:0] cs_state;
reg [3:0] ns_state;*/
reg [3:1] base;
reg [3:1] next_base;
reg [1:0] out_num;
//reg [1:0] out_num_reg;
reg [2:0] change_score;
//reg stop;
reg hehe;
//reg half_reg;
reg [3:0] add_select,sum;
reg in_valid_reg;
//wire haha;
reg early_change;
reg [3:0] score_A_temp;  // Score of team A (guest team)
reg [2:0] score_B_temp;
reg [3:0] score_temp;
wire DP;


always@(*) begin
    if(action==3'd6) begin
        if(out_num ==2)begin
            early_change=1'b1; 
        end
        else if(out_num==1) begin
            if(base[1])
                early_change=1'b1; 
            else 
                early_change=1'b0;
        end
        else begin
            early_change=1'b0;
        end
    end
    else if(action==3'd7) begin
        if(out_num==2) begin
            early_change=1'b1;
        end
        else begin
            early_change=1'b0;
        end
    end
    else begin
        early_change=1'b0;
    end
end

always@(posedge clk ) begin//3176
    in_valid_reg <= in_valid;
end

always@(posedge clk ) begin//2854
    if(in_valid) begin
        case(action) 
        Walk: begin
            if(base == 3'b000)
                base <= 3'b001; 
            else if(base == 3'b001 || base == 3'b010)
                base <= 3'b011;
            else if(base == 3'b100) 
                base <= 3'b101;
            else 
                base <= 3'b111;
        end
        Single_hit: begin
            if(out_num==0 || out_num == 1) begin
                base <= {base[2:1],1'b1};
            end
            else if(out_num==2) begin
                if(base[1]) base <= 3'b101;//3389
                else base <= 3'b001;
            end
        end
        Double_hit: begin
            if(out_num==2'd0 || out_num == 2'd1) begin
                if(base[1]) begin
                    base <= 3'b110;
                end
                else begin
                    base <= 3'b010;
                end
            end
            else if(out_num==2'd2) begin
                base <= 3'b010;
            end
        end
        Triple_hit: begin
            base <= 3'b100;
        end
        HR: begin
            base <= 3'b000;
        end
        Bunt: begin//no 000
            base <= {base[2:1],1'b0};
        end
        Ground_ball: begin
            if(early_change) base <= 3'b000;
            else if(base[2]) base <= 3'b100;
            else base <= 3'b000;//3389
        end
        Fly_ball: begin
            if(early_change) base <= 3'b000;
            else if(out_num==0 || out_num==1) begin
                if(base==3'b100)
                    base <= 3'b000;
                else if(base==3'b101)
                    base <= 3'b001;
                else if(base==3'b110)
                    base <= 3'b010;
                else if(base==3'b111)
                    base <= 3'b011;
            end
            else if(out_num==2)begin
                base <= 3'b000;
            end
        end
    endcase
    end
    else begin
        base <= 3'b000;
    end
    
end
/*
always@(posedge clk ) begin//3166
    if(!in_valid||early_change) begin
        base <= 3'b000;
    end
    else if(out_valid) begin
        base <= 3'b000;
    end
    else begin
        base <= next_base;
    end
    
end
always@(*) begin
    case(action) 
        Walk: begin
            if(base == 3'b000)
                next_base = 3'b001; 
            else if(base == 3'b001 || base == 3'b010)
                next_base = 3'b011;
            else if(base == 3'b100) 
                next_base = 3'b101;
            else 
                next_base = 3'b111;
        end
        Single_hit: begin
            if(out_num==0 || out_num == 1) begin
                next_base = {base[2:1],1'b1};
            end
            else if(out_num==2) begin
                if(base[1]) next_base = 3'b101;//3389
                else next_base = 3'b001;
            end
            else begin
                next_base = base;
            end
        end
        Double_hit: begin
            if(out_num==2'd0 || out_num == 2'd1) begin
                if(base[1]) begin
                    next_base = 3'b110;
                end
                else begin
                    next_base = 3'b010;
                end
            end
            else if(out_num==2'd2) begin
                next_base = 3'b010;
            end
            else begin
                next_base = base;
            end
        end
        Triple_hit: begin
            next_base = 3'b100;
        end
        HR: begin
            next_base = 3'b000;
        end
        Bunt: begin//no 000
            next_base = {base[2:1],1'b0};
        end
        Ground_ball: begin
            if(base[2]) next_base = 3'b100;
            else next_base = 3'b000;//3389
        end
        Fly_ball: begin
            if(out_num==0 || out_num==1) begin
                if(base==3'b100)
                    next_base = 3'b000;
                else if(base==3'b101)
                    next_base = 3'b001;
                else if(base==3'b110)
                    next_base = 3'b010;
                else if(base==3'b111)
                    next_base = 3'b011;
                else
                    next_base = base;
            end
            else if(out_num==2)begin
                next_base = 3'b000;
            end
            else begin
                next_base = base;
            end
        end
        default: next_base = base;
    endcase
end
*/
always@(posedge clk) begin//2864
    if(in_valid) begin
        case(action)
            Bunt: begin
                out_num <= out_num + 2'd1;
            end
            Ground_ball: begin
                if((out_num==1 && base[1])||out_num==2) begin
                    out_num <= 2'd0;
                end
                else if(out_num==0 && base[1]) begin
                    out_num <= 2'd2;
                end
                else
                begin 
                    out_num <= out_num + 2'd1;
                end
            end
            Fly_ball : begin
                out_num <= (out_num==2)?0:(out_num + 2'd1);
            end
            default: out_num <= out_num;
        endcase
    end
    else begin
        out_num <= 0;
    end
end

 
/*
always@(posedge clk ) begin//3206
    half_reg <= half;
end*/
/*
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        score_A <= 8'b0;
    end*/
   /* else if(~in_valid && ~in_valid_reg)
        score_A <= 8'b0;
    else if(in_valid_reg && ~in_valid)
        score_A <= score_A;
    else if(out_valid)
        score_A <= 8'd0;
    else if(!half)
        score_A <= sum;
end
*/

always@(posedge half) begin
    if (inning == 3)
        hehe <= (score_A_temp < score_B_temp);
    else
        hehe <= 0;
end
/*
always@(posedge clk) begin
    if(!in_valid || out_valid) 
        hehe<=0;
    else if(inning==2'd3 && score_A_temp[3:0]<score_B_temp[2:0] &&early_change==1)
        hehe<=1;
    
end*/

//assign hehe=(inning==2'd3 && score_A[3:0]<score_B[2:0] &&early_change==1 )&&in_valid;
//assign haha=inning==2'd3 && (score_A[3:0]<score_B[2:0]) &&half==1&&half_reg==0  &&!out_valid;

/*
always@(posedge clk ) begin
    if(in_valid==0 &&in_valid_reg==0)//2903
        score_A_temp <= 4'b0;
    else if(in_valid_reg==1 && !in_valid||hehe)
        score_A_temp <= score_A_temp;
    else if(!half)//B
        score_A_temp <= sum;
end*/
/*
always@(posedge clk ) begin
    if(in_valid==0&&in_valid_reg==0)//2903
        score_B_temp <= 4'b0;
    else 
    if(in_valid_reg==1 && !in_valid||hehe)
        score_B_temp <= score_B_temp;
    else if(half)//B
        score_B_temp <= sum;
end*/
always@(posedge clk ) begin//2814
    if(in_valid )
    begin
        if(!half)//B
            score_A_temp <= sum;
    end
    else if(!in_valid&&!in_valid_reg)
        score_A_temp <= 0;
end
always@(posedge clk ) begin
    if(in_valid && !hehe)
    begin
        if(half)//B
            score_B_temp <= sum;
    end
    else if(!in_valid&&!in_valid_reg)
        score_B_temp <= 0;
end

/*
always@(posedge clk ) begin
    if(in_valid==0 &&in_valid_reg==0)//2903
        score_temp <= 4'b0;
    else if(in_valid_reg==1 && !in_valid)
        score_temp <= score_temp;
    else if(hehe) begin
        score_temp <= score_temp;
    end
end
always@(posedge clk) begin
    if(!half)
        score_A_temp <= score_temp;
end
always@(posedge clk) begin
    if(half)
        score_B_temp <= score_temp;
end*/
always@(*) begin
    if(out_valid) begin
        score_A = score_A_temp;
    end
    else begin
        score_A = 8'b0;
    end
end
always@(*) begin
    if(out_valid) begin
        score_B = score_B_temp;
    end
    else begin
        score_B = 8'b0;
    end
end
always@(*) begin
    add_select = (!half)?score_A_temp[3:0]:score_B_temp[2:0];
    sum = add_select + change_score; 
end
//assign change_score_temp = base[3] + base[2] + base[1];
/*
always @(*)begin 
    if((action ==0 & base==3'b111)||(action ==1 & out_num != 2 & base[3])||(action ==1 & out_num ==2 & (base[2]^base[3]) ) || (action ==2 & out_num !=2 & (base[2]^base[3])) || (action ==2 & out_num ==2 & base==3'b100) ||(action ==2 & out_num ==2 & base==3'b001)||(action ==2 & out_num ==2 & base==3'b010) ||(action ==3 & base[1] &!base[2] &!base[3]) ||(action ==3 & !base[1] &base[2] &!base[3]) ||(action ==3 & !base[1] &!base[2] &base[3]) || (action ==4 &!base[1] &!base[2] &!base[3]) ||(action ==5 & base[3])||(action==6 & out_num==1 &!DP &base[3])||(action==6 & out_num==0 &base[3])||(action ==7 & out_num!=2 & base[3]))begin 
        change_score=1;
    end
    else if((action ==1 && out_num==2 && base[2] && base[3]) || (action ==2 & out_num==2 &!base[1] & base[2] & base[3]) || (action ==2 & out_num==2 & base[1] & !base[2] & base[3])||(action ==2 & out_num==2 &base[1] & base[2] & !base[3]) || (action ==2 & out_num!= 2 &base[2] & base[3]) || (action ==3 & !base[1]&base[2]&base[3])  || (action ==3 & base[1]&!base[2]&base[3]) || (action ==3 & base[1]&base[2]&!base[3]) || (action ==4 &!base[1]&!base[2]&base[3]) || (action ==4 &!base[1]&base[2]&!base[3]) || (action ==4 &base[1]&!base[2]&!base[3]))begin 
        change_score=2;
    end
    else if((action ==2 & out_num==2 &base[1]&base[2]&base[3])||(action ==3 & base[1]&base[2]&base[3])||(action ==4 &base[1]&!base[2]&base[3]) ||(action ==4 &base[1]&base[2]&!base[3])||(action ==4 &!base[1]&base[2]&base[3]))begin 
        change_score=3;
    end
    else if(action ==4 &base[1]&base[2]&base[3])begin 
        change_score=4;
    end
    else change_score=0;
end
*/
always@(*) begin
    case(action) 
        Walk : begin
            if(base==3'b111) begin
                change_score = 3'd1;
            end
            else begin
                change_score = 3'd0;
            end
        end
        Single_hit : begin
            if(out_num==0 || out_num==1) begin
                if(base[3]==1'b1)  begin
                    change_score = 3'd1;
                end
                else begin
                    change_score = 3'd0;
                end
            end
            else if(out_num==2) begin
                if(base[3]==1 && base[2]==1) begin
                    change_score = 3'd2;
                end
                else if(base[3]^base[2]) begin
                    change_score = 3'd1;
                end
                else begin
                    change_score = 3'd0;
                end
            end
            else begin
                change_score = 3'd0;
            end
        end
        Double_hit : begin
            
            if(out_num==0 || out_num==1) begin
                case (base)
                    3'b010: change_score =  3'd1;
                    3'b100: change_score =  3'd1;
                    3'b011: change_score =  3'd1;
                    3'b101: change_score =  3'd1;
                    3'b110: change_score =  3'd2;
                    3'b111: change_score =  3'd2;
                    default: change_score = 3'd0 ;
                endcase
            end
            else if(out_num[1]==1)begin
                change_score = base[3] + base[2] + base[1];
            end
            else begin
                change_score = 3'd0;
            end
        end
        Triple_hit : begin
            change_score = base[3]+base[2]+base[1];
        end
        HR: begin
            case (base)
                3'b000: change_score =  3'd1;
                3'b001: change_score =  3'd2;
                3'b010: change_score =  3'd2;
                3'b100: change_score =  3'd2;
                3'b011: change_score =  3'd3;
                3'b101: change_score =  3'd3;
                3'b110: change_score =  3'd3;
                3'b111: change_score =  3'd4;
                default: change_score = 3'd0 ;
            endcase
        end
        Bunt: begin
            if(out_num==0 || out_num == 1) begin
                if(base[3])
                    change_score = 3'd1;
                else 
                    change_score = 3'd0; 
                end
            else begin
                change_score = 3'd0; 
            end
        end
        Ground_ball: begin
            if((out_num==0 ||(out_num==1 && base[1]==0)) && base[3]) begin
                change_score = 3'd1;
            end
            
            else begin
                change_score = 3'd0; 
            end
        end
        Fly_ball: begin
            if((out_num==0 || out_num==1)&&base[3]) begin
                change_score = 3'd1;
            end
            else begin
                change_score = 3'd0;
            end
        end
        default: change_score = 3'd0;
    endcase
end
   
      

    


//==============================================//
//                Output Block                  //
//==============================================//
// Decide when to set out_valid high, and output change_score, score_B, and result.
reg out_valid_temp;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 1'b0;
    end
    else begin
        if(in_valid==0 && in_valid_reg==1) begin
            out_valid <= 1'b1;
        end
        else begin
            out_valid <= 1'b0;
        end
    end
end
/*
always@(posedge clk) begin
        if(!in_valid||out_valid)  out_valid<=1'b0;
        else out_valid<=1'b1;
    
end*/
/*
always@(posedge clk ) begin
    
        if(in_valid==0 && in_valid_reg==1) begin
            out_valid_temp <= 1'b1;
        end
        else begin
            out_valid_temp <= 1'b0;
        end
    
end
always@(*) begin
    out_valid  = out_valid_temp;
end*/
/*
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        result <= 2'b00;
    end
    else begin
        if(in_valid==0 && in_valid_reg==1) begin
            if(score_A_temp[3:0]>score_B_temp[2:0]) begin
                result <= 2'd0;
            end
            else if(score_B_temp[2:0]>score_A_temp[3:0]) begin
                result <= 2'd1;
            end
            else if(score_A_temp[3:0]==score_B_temp[2:0])begin//3093
                result <= 2'd2;
            end
        end
        else begin
            result <= 2'd0;
        end
    end
end*/
/*
reg [1:0] result_temp;
always@(posedge clk ) begin//2880
     
            if(score_A_temp[3:0]>score_B_temp[2:0]) begin
                result_temp <= 2'd0;
            end
            else if(score_B_temp[2:0]>score_A_temp[3:0]) begin
                result_temp <= 2'd1;
            end
            else if(score_A_temp[3:0]==score_B_temp[2:0])begin//3093
                result_temp <= 2'd2;
            end
    
end*/
always@(*) begin
    if(out_valid) begin
        if(score_A_temp>score_B_temp) begin
            result = 2'd0;
        end
        else if(score_B_temp>score_A_temp) begin
            result = 2'd1;
        end
        else begin
            result = 2'd2;
        end
    end
    else begin
        result = 2'b0;
    end
end
endmodule
