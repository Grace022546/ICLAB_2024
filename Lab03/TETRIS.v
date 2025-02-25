/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: TETRIS
// FILE NAME: TETRIS.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / TETRIS
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
module TETRIS (
	//INPUT
	rst_n,
	clk,
	in_valid,
	tetrominoes,
	position,
	//OUTPUT
	tetris_valid,
	score_valid,
	fail,
	score,
	tetris
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
input				rst_n, clk, in_valid;
input		[2:0]	tetrominoes;
input		[2:0]	position;
output reg			tetris_valid, score_valid, fail;
output reg	[3:0]	score;
output reg 	[71:0]	tetris;


//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
localparam IDLE = 1'b0;
//localparam INPUT = 3'd1 ;
localparam SCORE_ELI = 1'b1;


//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg cs_state;
reg  ns_state;
reg [2:0] position_temp;
reg [2:0] tetrominoes_temp;
reg [5:0] map[0:13];
reg [5:0] n_map[0:13];

reg [3:0] height[0:5];
reg [3:0] n_height[0:5];
reg row_filled;
reg [3:0] row_eli;
reg [3:0] count;
reg [3:0] score_temp;
integer i;
//reg [2:0]how_many_row_eli;
reg [3:0] cmp_result;
reg [3:0] a,b,c,d;
reg [3:0] t1,t2;
reg in_valid_reg;
reg [3:0] row_eli_reg;
//reg score_valid_reg;
//reg [2:0]how_many_row_eli ;
//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------

always@(posedge clk) begin
    in_valid_reg <= in_valid;
end
/*
always@(posedge clk) begin
    score_valid_reg <= score_valid;
end*/

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
			if(in_valid) begin
				ns_state = SCORE_ELI;
			end
			else begin
				ns_state = IDLE;
			end
		end
		SCORE_ELI: begin//map
            if(row_eli==4'd12) begin
				ns_state = IDLE;
			end
			else begin
				ns_state = SCORE_ELI;
			end
		end
		default: begin
            ns_state = IDLE;
        end
	endcase
end
always@(*) begin
    case(tetrominoes)
        0: begin
           a = height[position];
           b = height[position+1];
           c = 0;
           d = 0; 
        end
        1: begin
           a = height[position];
           b = 0;
           c = 0;
           d = 0; 
        end
        2: begin
           a = height[position];
           b = height[position+1];
           c = height[position+2];
           d = height[position+3];
        end
        3: begin
           a = height[position];
           b = height[position+1]+2;
           c = 0;
           d = 0; 
        end
        4: begin
           a = height[position]+1;
           b = height[position+1];
           c = height[position+2];
           d = 0;
        end
        5: begin
           a = height[position];
           b = height[position+1];
           c = 0;
           d = 0;
        end
        6: begin
           a = height[position];
           b = height[position+1]+1;
           c = 0;
           d = 0; 
        end
        7: begin
           a = height[position]+1;
           b = height[position+1]+1;
           c = height[position+2];
           d = 0; 
        end
        default: begin
           a = 0;
           b = 0;
           c = 0;
           d = 0; 
        end
    endcase
    t1 = (a>b)?a:b;
    t2 = (c>d)?c:d;
    cmp_result = (t1>t2)?t1:t2;

end
always@(*) begin
    for(i=0;i<=13;i=i+1) begin
            n_map[i] = map[i];
        end
    if(tetris_valid) begin
        for(i=0;i<=13;i=i+1) begin
            n_map[i] = 0;
        end
    end
    else if(!in_valid_reg&&in_valid) begin
        case (tetrominoes)
            0: begin
                n_map[cmp_result][position] = 1;
                n_map[cmp_result][position+1] = 1;
                n_map[cmp_result+1][position] = 1;
                n_map[cmp_result+1][position+1] = 1;
                /*if(height[position]>height[position+1]) begin
                    n_map[height[position]+1][position] = 1;
                    n_map[height[position]][position] = 1;
                    n_map[height[position]+1][position+1] = 1;
                    n_map[height[position]][position+1] = 1;
                end
                else begin
                    n_map[height[position+1]][position] = 1;
                    n_map[height[position+1]+1][position] = 1;
                    n_map[height[position+1]][position+1] = 1;
                    n_map[height[position+1]+1][position+1] = 1;
                end*/
            end
            1: begin
                n_map[cmp_result][position] = 1;
                n_map[cmp_result+1][position] = 1;
                n_map[cmp_result+2][position] = 1;
                n_map[cmp_result+3][position] = 1;
               /* n_map[height[position]][position] = 1;
                n_map[height[position]+1][position] = 1;
                n_map[height[position]+2][position] = 1;
                n_map[height[position]+3][position] = 1;*/
            end
            2: begin
                n_map[cmp_result][position] = 1;
                n_map[cmp_result][position+1] = 1;
                n_map[cmp_result][position+2] = 1;
                n_map[cmp_result][position+3] = 1;
                /*
                if(height[position]>=height[position+1]&&height[position]>=height[position+2]&&height[position]>=height[position+3]) begin
                    n_map[height[position]][position] = 1;
                    n_map[height[position]][position+1] = 1;
                    n_map[height[position]][position+2] = 1;
                    n_map[height[position]][position+3] = 1;
                end
                else if(height[position+1]>=height[position]&&height[position+1]>=height[position+2]&&height[position+1]>=height[position+3]) begin
                    n_map[height[position+1]][position] = 1;
                    n_map[height[position+1]][position+1] = 1;
                    n_map[height[position+1]][position+2] = 1;
                    n_map[height[position+1]][position+3] = 1;
                end
                else if(height[position+2]>=height[position]&&height[position+2]>=height[position+1]&&height[position+2]>=height[position+3]) begin
                    n_map[height[position+2]][position] = 1;
                    n_map[height[position+2]][position+1] = 1;
                    n_map[height[position+2]][position+2] = 1;
                    n_map[height[position+2]][position+3] = 1;
                end
                else begin
                    n_map[height[position+3]][position] = 1;
                    n_map[height[position+3]][position+1] = 1;
                    n_map[height[position+3]][position+2] = 1;
                    n_map[height[position+3]][position+3] = 1;
                end*/
            end
            3: begin//question
                n_map[cmp_result][position] = 1;
                n_map[cmp_result][position+1] = 1;
                n_map[cmp_result-1][position+1] = 1;
                n_map[cmp_result-2][position+1] = 1;
               /* if(height[position]>=height[position+1]+2) begin
                    n_map[height[position]][position] = 1;
                    n_map[height[position]][position+1] = 1;
                    n_map[height[position]-1][position+1] = 1;
                    n_map[height[position]-2][position+1] = 1;
                end
                else begin
                    n_map[height[position+1]+2][position] = 1;
                    n_map[height[position+1]+2][position+1] = 1;
                    n_map[height[position+1]+1][position+1] = 1;
                    n_map[height[position+1]][position+1] = 1;
                end
        */
            end
            4: begin
                n_map[cmp_result-1][position] = 1;
                n_map[cmp_result][position] = 1;
                n_map[cmp_result][position+1] = 1;
                n_map[cmp_result][position+2] = 1;
                /*
                if(height[position]+1>=height[position+1]&&height[position]+1>=height[position+2]) begin
                    n_map[height[position]][position] = 1;
                    n_map[height[position]+1][position] = 1;
                    n_map[height[position]+1][position+1] = 1;
                    n_map[height[position]+1][position+2] = 1;
                end
                else if(height[position+1]>=height[position]+1&&height[position+1]>=height[position+2]) begin
                    n_map[height[position+1]-1][position] = 1;
                    n_map[height[position+1]][position] = 1;
                    n_map[height[position+1]][position+1] = 1;
                    n_map[height[position+1]][position+2] = 1;
                end
                else begin
                    n_map[height[position+2]-1][position] = 1;
                    n_map[height[position+2]][position] = 1;
                    n_map[height[position+2]][position+1] = 1;
                    n_map[height[position+2]][position+2] = 1;
                end
                */
            end
            5: begin
                n_map[cmp_result][position]= 1;
                n_map[cmp_result+1][position]= 1;
                n_map[cmp_result+2][position] = 1;
                n_map[cmp_result][position+1] = 1;
                /*
                if(height[position]>=height[position+1]) begin
                    n_map[height[position]][position]= 1;
                    n_map[height[position]+1][position]= 1;
                    n_map[height[position]+2][position] = 1;
                    n_map[height[position]][position+1] = 1;
                end
                else begin
                    n_map[height[position+1]][position]= 1;
                    n_map[height[position+1]+1][position]= 1;
                    n_map[height[position+1]+2][position] = 1;
                    n_map[height[position+1]][position+1] = 1;
                end
                */
            end
            6: begin
                n_map[cmp_result+1][position] = 1;
                n_map[cmp_result][position] = 1;
                n_map[cmp_result][position+1] = 1;
                n_map[cmp_result-1][position+1] = 1;
                /*
                if(height[position]>=height[position+1]+1) begin
                    n_map[height[position]+1][position] = 1;
                    n_map[height[position]][position] = 1;
                    n_map[height[position]][position+1] = 1;
                    n_map[height[position]-1][position+1] = 1;
                end
                else begin
                    n_map[height[position+1]+2][position] = 1;
                    n_map[height[position+1]+1][position] = 1;
                    n_map[height[position+1]][position+1] = 1;
                    n_map[height[position+1]+1][position+1] = 1;
                end
                */
            end
            7:  begin
                n_map[cmp_result-1][position] = 1;
                n_map[cmp_result-1][position+1] = 1;
                n_map[cmp_result][position+1] = 1;
                n_map[cmp_result][position+2] = 1;
               /* if(height[position]+1>=height[position+2]&&height[position]>=height[position+1]) begin
                    n_map[height[position]][position] = 1;
                    n_map[height[position]][position+1] = 1;
                    n_map[height[position]+1][position+1] = 1;
                    n_map[height[position]+1][position+2] = 1;
                end
                else if(height[position+1]>=height[position]&&height[position+1]+1>=height[position+2]) begin
                    n_map[height[position+1]][position] = 1;
                    n_map[height[position+1]][position+1] = 1;
                    n_map[height[position+1]+1][position+1] = 1;
                    n_map[height[position+1]+1][position+2] = 1;
                end
                else begin
                    n_map[height[position+2]-1][position] = 1;
                    n_map[height[position+2]-1][position+1] = 1;
                    n_map[height[position+2]][position+1] = 1;
                    n_map[height[position+2]][position+2] = 1;
                end
                */
            end
         //   default:n_map[0] =6'b111111;
        endcase
    end
   // else if(cs_state==SCORE_ELI)begin
    //else if(row_eli!=12||(in_valid_reg&&!score_valid_reg)) begin//eliminate the row and shift other row
  //  else if(how_many_row_eli!=0) begin
     else if(row_eli!=4'd12) begin
       // n_map[13] = 0;
        case (row_eli)
            0:begin
                for(i=0;i<=12;i=i+1) begin
                    n_map[i] = map[i+1];
                end
            end 
            1:begin
                for(i=1;i<=12;i=i+1) begin
                    n_map[i] = map[i+1];
                end
            end 
            2:begin
                for(i=2;i<=12;i=i+1) begin
                    n_map[i] = map[i+1];
                end
            end 
            3:begin
                for(i=3;i<=12;i=i+1) begin
                    n_map[i] = map[i+1];
                end
            end 
            4:begin
                for(i=4;i<=12;i=i+1) begin
                    n_map[i] = map[i+1];
                end
            end 
            5:begin
                for(i=5;i<=12;i=i+1) begin
                    n_map[i] = map[i+1];
                end
            end 
            6:begin
                for(i=6;i<=12;i=i+1) begin
                    n_map[i] = map[i+1];
                end
            end 
            7:begin
                for(i=7;i<=12;i=i+1) begin
                    n_map[i] = map[i+1];
                end
            end 
            8:begin
                for(i=8;i<=12;i=i+1) begin
                    n_map[i] = map[i+1];
                end
            end 
            9:begin
                n_map[9] = map[10];
                n_map[10] = map[11];
                n_map[11] = map[12];
                n_map[12] = map[13];
            end 
            10:begin
                n_map[10] = map[11];
                n_map[11] = map[12];
                n_map[12] = map[13];
            end 
            11:begin
                n_map[11] = map[12];
                n_map[12] = map[13];
            end 
           /* default: begin
                for(i=0;i<=11;i=i+1) begin
                        n_map[i] = map[i];
                    end
            end*/
        endcase
	end
    /*
    else begin
        for(i=0;i<=13;i=i+1) begin
            n_map[i] = map[i];
        end
    end*/
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<=13;i=i+1) begin
            map[i] <= 0;
        end
    end
    else  begin
        map[0] <=  n_map[0];
        map[1] <=  n_map[1];
        map[2] <=  n_map[2];
        map[3] <=  n_map[3];
        map[4] <=  n_map[4];
        map[5] <=  n_map[5];
        map[6] <=  n_map[6];
        map[7] <=  n_map[7];
        map[8] <=  n_map[8];
        map[9] <=  n_map[9];
        map[10] <=  n_map[10];
        map[11] <=  n_map[11];
        map[12] <=  n_map[12];
        map[13] <=  n_map[13];
    end
    
end

always@(*) begin//comb
    if(tetris_valid) begin
        tetris = {map[11], map[10],map[9],map[8],map[7],map[6],map[5],map[4],map[3],map[2],map[1],map[0]};
    end
    else begin
        tetris = 72'b0;
    end
end


/*
always@(*) begin//INPUT discover
    if(cs_state==INPUT) begin
        if(&map[0]||&map[1]||&map[2]||&map[3]||&map[4]||&map[5]||&map[6]||&map[7]||&map[8]||&map[9]||&map[10]||&map[11]) begin
            row_filled = 1;
        end
        else begin
            row_filled = 0;
        end
    end
    else begin
        row_filled = 0;
    end
end*/
/*
always@(*) begin
   
    how_many_row_eli = &map[0]+&map[1]+&map[2]+&map[3]+&map[4]+&map[5]+&map[6]+&map[7]+&map[8]+&map[9]+&map[10]+&map[11];
    
end*/
always@(*) begin//see which row is filled
  //  if(cs_state==SCORE_ELI) begin
    //if(row_eli!=12||(in_valid_reg&&!score_valid_reg)) begin
  /*  if(how_many_row_eli!=0) begin*/
        if(&map[0]) begin
            row_eli = 4'd0;
        end
        else if(&map[1]) begin
            row_eli = 4'd1;
        end
        else if(&map[2]) begin
            row_eli = 4'd2;
        end
        else if(&map[3]) begin
            row_eli = 4'd3;
        end
        else if(&map[4]) begin
            row_eli = 4'd4;
        end
        else if(&map[5]) begin
            row_eli = 4'd5;
        end
        else if(&map[6]) begin
            row_eli = 4'd6;
        end
        else if(&map[7]) begin
            row_eli = 4'd7;
        end
        else if(&map[8]) begin
            row_eli = 4'd8;
        end
        else if(&map[9]) begin
            row_eli = 4'd9;
        end
        else if(&map[10]) begin
            row_eli = 4'd10;
        end
        else if(&map[11]) begin
            row_eli = 4'd11;
        end
        else begin
            row_eli = 4'd12;
        end
   /* end
    else begin
        row_eli = 5'd12;
    end*/
end


always@(posedge clk) begin
    row_eli_reg <= row_eli;
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        score_temp <= 4'b0;
    end
    else if(count==0) begin
        score_temp <= 4'd0;
    end
   
   else if(row_eli!=4'd12) begin
   // else if(cs_state==SCORE_ELI &&row_eli!=5'd12) begin
        score_temp <= score_temp+1;
    end
    
end
always@(*) begin
    if(score_valid) begin
        score = score_temp;
    end
    else begin
        score = 4'b0;
    end
end
/*
always @(*) begin//when?//change n_height everytime
    if(tetris_valid) begin
            for(i=0;i<6;i=i+1) begin
                n_height[i] = 0;
            end
    end
    else if(cs_state==SCORE_ELI&&row_eli==5'd12) begin
        for(i=0;i<6;i=i+1) begin//redefine n_height
            if(map[11][i]==1)//how to fix it into map without having12,13,14
                n_height[i] = 12;
            else if(map[10][i]==1)
                n_height[i] = 11;
            else if(map[9][i]==1)
                n_height[i] = 10;
            else if(map[8][i]==1)
                n_height[i] = 9;
            else if(map[7][i]==1)
                n_height[i] = 8;
            else if(map[6][i]==1)
                n_height[i] = 7;
            else if(map[5][i]==1)
                n_height[i] = 6;
            else if(map[4][i]==1)
                n_height[i] = 5;
            else if(map[3][i]==1)
                n_height[i] = 4;
            else if(map[2][i]==1)
                n_height[i] = 3;
            else if(map[1][i]==1)
                n_height[i] = 2;
            else if(map[0][i]==1)
                n_height[i] = 1;
            else
                n_height[i] = 0;       
        end
    end
    else begin
        for(i=0;i<6;i=i+1) begin
            n_height[i] = height[i];
        end
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<6;i=i+1) begin
            height[i] <= 0;
        end
    end
    else  begin
        for(i=0;i<6;i=i+1) begin//redefine height
            height[i] <= n_height[i];
        end
    end
   
end
*/
always @(*) begin//when?//change n_height everytime
    
   
        for(i=0;i<6;i=i+1) begin//redefine n_height
            if(map[11][i]==1'b1)//how to fix it into map without having12,13,14
                height[i] = 4'd12;
            else if(map[10][i]==1'b1)
                height[i] = 4'd11;
            else if(map[9][i]==1'b1)
                height[i] = 4'd10;
            else if(map[8][i]==1'b1)
                height[i] = 4'd9;
            else if(map[7][i]==1'b1)
                height[i] = 4'd8;
            else if(map[6][i]==1'b1)
                height[i] = 4'd7;
            else if(map[5][i]==1'b1)
                height[i] = 4'd6;
            else if(map[4][i]==1'b1)
                height[i] = 4'd5;
            else if(map[3][i]==1'b1)
                height[i] = 4'd4;
            else if(map[2][i]==1'b1)
                height[i] = 4'd3;
            else if(map[1][i]==1'b1)
                height[i] = 4'd2;
            else if(map[0][i]==1'b1)
                height[i] = 4'd1;
            else
                height[i] = 4'd0;       
        end
    
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        count <= 0;
    end
    else if(tetris_valid) begin//changefail//26012
        count <= 0;
    end
	else if(score_valid) begin
		count <= count + 4'd1;
	end
	
end
always@(*) begin
        //if(cs_state==SCORE_ELI&&row_eli==5'd12) begin
    if(score_valid&&map[12]!=6'b000000&&row_eli==4'd12) begin
        fail = 1;
    end
    else begin
        fail = 0;
    end 
end
/*
always@(*) begin
   // if(how_many_row_eli==0&&(fail||count==15)) begin
    if((cs_state==SCORE_ELI)&&(fail||count==4'd15)&&row_eli==4'd12) begin
        tetris_valid = 1;
    end
    else begin
        tetris_valid = 0;
    end
end
*/
always@(*) begin
 /*  if(cs_state==SCORE_ELI&&(fail||count==15)&&row_eli==5'd12) begin
    tetris_valid = 1;
   end*/
    if((score_valid)&&(fail||count==4'd15)) begin tetris_valid = 1; end
    else begin
        tetris_valid = 0;
    end
end


/*
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        score_valid <= 0;
    end
    else if(!in_valid_reg) begin
        score_valid <= 1;
    end
   
    else begin
        score_valid <= 0;
    end
    
end  */
 /*
    else if(((in_valid&&in_valid_reg)||in_valid_reg)&&row_eli==4'd12) begin
        score_valid <= 1;
    end
    else if(row_eli==4'd12 && row_eli_reg!=4'd12) begin 
        score_valid <= 1; 
    end
    */


 
always@(*) begin
   if(cs_state==SCORE_ELI&&row_eli==4'd12) begin score_valid = 1; end
   else score_valid = 0;
end

endmodule
