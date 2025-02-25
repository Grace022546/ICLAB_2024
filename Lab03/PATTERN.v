/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: PATTERN
// FILE NAME: PATTERN.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / PATTERN
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

`ifdef RTL
    `define CYCLE_TIME 7.6
`endif
`ifdef GATE
    `define CYCLE_TIME 7.6
`endif


module PATTERN(
	//OUTPUT
	rst_n,
	clk,
	in_valid,
	tetrominoes,
	position,
	//INPUT
	tetris_valid,
	score_valid,
	fail,
	score,
	tetris
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output reg			rst_n, clk, in_valid;
output reg	[2:0]	tetrominoes;
output reg  [2:0]	position;
input 				tetris_valid, score_valid, fail;
input 		[3:0]	score;
input		[71:0]	tetris;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
integer total_latency,latency_temp;
integer i_pat,a,pat_read,PAT_NUM;
integer tetris_valid_latency,score_valid_latency;
integer count;

//reg v_early_fail;
reg p_early_fail;
//reg p_tetris_valid;
reg [3:0] p_score;

integer i,j;
//for spec 8 score_valid and tetris_valid can't be high for more than 1 cycle

reg [2:0] tetrominoes_temp;
reg [2:0] position_temp;
reg [3:0] input_wait;

reg [3:0] height[0:5];
reg [3:0] heightest;
reg [5:0] map[0:14];
integer b;
//---------------------------------------------------------------------
//  CLOCK
//---------------------------------------------------------------------
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;
//---------------------------------------------------------------------
//   DATA_CHECK
//---------------------------------------------------------------------

initial begin
    pat_read = $fopen("../00_TESTBED/input.txt", "r");
    reset_signal_task;
    repeat(5) @(posedge clk);

    i_pat = 0;
    //total_latency = 0;
    score_valid_latency = 0;
	tetris_valid_latency = 0;
    $fscanf(pat_read, "%d", PAT_NUM);
    for (i_pat = 0; i_pat <= PAT_NUM; i_pat = i_pat + 1) begin//now the data is wrong
        $fscanf(pat_read, "%d", b);
        clear_task;
        for(count=0;count<=15;count = count+1) begin
            if(p_early_fail==0) begin
                input_task;
               // p_end_check;
                build_map;
                get_score_and_eliminate;
                p_fail_check;
                wait_score_valid_task;
                check_ans_task;
            end
            else begin
                fail_task;
            end
        end
        
        //total_latency = total_latency + latency_temp;
       
        $display("PASS PATTERN NO.%d", i_pat);
        
    end
    $fclose(pat_read);

    YOU_PASS_task;
    $finish;
end


//---------------------------------------------------------------------
//  SIMULATION
//---------------------------------------------------------------------

//**************************************
//      Input Task
//**************************************

task clear_task; begin
    for(i=0;i<6;i=i+1) begin
        height[i] = 'd0;
    end
    for(i=0;i<=14;i=i+1) begin
        map[i] = 'd0;
    end
    p_early_fail = 0;
    p_score = 0;
end
endtask


task fail_task; begin
   $fscanf(pat_read, "%d %d",tetrominoes_temp,position_temp);
end
endtask

task p_fail_check; begin
   /* if(count<=15) begin
        for(i=0;i<=5;i=i+1) begin
            if(height[i]>12) begin
                p_early_fail=1;
            end
            else begin
                p_early_fail=0;
       end
    end
    end*/
    if(map[12]||map[13]||map[14]) begin
        p_early_fail=1;
    end
    else begin
        p_early_fail=0;
    end
end
endtask
/*
task p_end_check; begin
    for(i=0;i<=5;i=i+1) begin
       if(height[i]==12&& count==15) begin
            p_tetris_valid=1;
       end
       else if(p_early_fail==1) begin
            p_tetris_valid=1;
       end
       else begin
            p_tetris_valid=0;
       end
    end
    
end
endtask*/

task get_score_and_eliminate; begin
    for(i=11;i>=0;i=i-1) begin
        if(map[i]==6'b111111) begin
            //$display("haha");
            for(j=i;j<=13;j=j+1) begin//eliminate which row
               map[j] = map[j+1];
            end
            map[14] = 0;
            p_score = p_score+1;
        end
        else begin
            map = map;
        end
    end
    
    for(i=0;i<6;i=i+1) begin//redefine height
        if(map[11][i]==1)
            height[i] = 12;
        else if(map[10][i]==1)
            height[i] = 11;
        else if(map[9][i]==1)
            height[i] = 10;
        else if(map[8][i]==1)
            height[i] = 9;
        else if(map[7][i]==1)
            height[i] = 8;
        else if(map[6][i]==1)
            height[i] = 7;
        else if(map[5][i]==1)
            height[i] = 6;
        else if(map[4][i]==1)
            height[i] = 5;
        else if(map[3][i]==1)
            height[i] = 4;
        else if(map[2][i]==1)
            height[i] = 3;
        else if(map[1][i]==1)
            height[i] = 2;
        else if(map[0][i]==1)
            height[i] = 1;
        else
            height[i] = 0;       
    end
   


end
endtask


task build_map; begin
    

    case(tetrominoes_temp)
        0: begin
            if(height[position_temp]>height[position_temp+1]) begin
                map[height[position_temp]+1][position_temp] = 1;
                map[height[position_temp]][position_temp] = 1;
                map[height[position_temp]+1][position_temp+1] = 1;
                map[height[position_temp]][position_temp+1] = 1;
            end
            else begin
                map[height[position_temp+1]][position_temp] = 1;
                map[height[position_temp+1]+1][position_temp] = 1;
                map[height[position_temp+1]][position_temp+1] = 1;
                map[height[position_temp+1]+1][position_temp+1] = 1;
            end
            
        end
        1: begin
            map[height[position_temp]][position_temp] = 1;
            map[height[position_temp]+1][position_temp] = 1;
            map[height[position_temp]+2][position_temp] = 1;
            map[height[position_temp]+3][position_temp] = 1;
        end
        2: begin
            if(height[position_temp]>=height[position_temp+1]&&height[position_temp]>=height[position_temp+2]&&height[position_temp]>=height[position_temp+3]) begin
                map[height[position_temp]][position_temp] = 1;
                map[height[position_temp]][position_temp+1] = 1;
                map[height[position_temp]][position_temp+2] = 1;
                map[height[position_temp]][position_temp+3] = 1;
            end
            else if(height[position_temp+1]>=height[position_temp]&&height[position_temp+1]>=height[position_temp+2]&&height[position_temp+1]>=height[position_temp+3]) begin
                map[height[position_temp+1]][position_temp] = 1;
                map[height[position_temp+1]][position_temp+1] = 1;
                map[height[position_temp+1]][position_temp+2] = 1;
                map[height[position_temp+1]][position_temp+3] = 1;
            end
            else if(height[position_temp+2]>=height[position_temp]&&height[position_temp+2]>=height[position_temp+1]&&height[position_temp+2]>=height[position_temp+3]) begin
                map[height[position_temp+2]][position_temp] = 1;
                map[height[position_temp+2]][position_temp+1] = 1;
                map[height[position_temp+2]][position_temp+2] = 1;
                map[height[position_temp+2]][position_temp+3] = 1;
            end
            else begin
                map[height[position_temp+3]][position_temp] = 1;
                map[height[position_temp+3]][position_temp+1] = 1;
                map[height[position_temp+3]][position_temp+2] = 1;
                map[height[position_temp+3]][position_temp+3] = 1;
            end
        end
        3: begin//question
            if(height[position_temp]>=height[position_temp+1]+2) begin
                map[height[position_temp]][position_temp] = 1;
                map[height[position_temp]][position_temp+1] = 1;
                map[height[position_temp]-1][position_temp+1] = 1;
                map[height[position_temp]-2][position_temp+1] = 1;
            end
            else begin
                map[height[position_temp+1]+2][position_temp] = 1;
                map[height[position_temp+1]+2][position_temp+1] = 1;
                map[height[position_temp+1]+1][position_temp+1] = 1;
                map[height[position_temp+1]][position_temp+1] = 1;
            end
    
        end
        4: begin
            if(height[position_temp]+1>=height[position_temp+1]&&height[position_temp]+1>=height[position_temp+2]) begin
                map[height[position_temp]][position_temp] = 1;
                map[height[position_temp]+1][position_temp] = 1;
                map[height[position_temp]+1][position_temp+1] = 1;
                map[height[position_temp]+1][position_temp+2] = 1;
            end
            else if(height[position_temp+1]>=height[position_temp]+1&&height[position_temp+1]>=height[position_temp+2]) begin
                map[height[position_temp+1]-1][position_temp] = 1;
                map[height[position_temp+1]][position_temp] = 1;
                map[height[position_temp+1]][position_temp+1] = 1;
                map[height[position_temp+1]][position_temp+2] = 1;
            end
            else begin
                map[height[position_temp+2]-1][position_temp] = 1;
                map[height[position_temp+2]][position_temp] = 1;
                map[height[position_temp+2]][position_temp+1] = 1;
                map[height[position_temp+2]][position_temp+2] = 1;
            end
        end
        5: begin
            if(height[position_temp]>=height[position_temp+1]) begin
                map[height[position_temp]][position_temp]= 1;
                map[height[position_temp]+1][position_temp]= 1;
                map[height[position_temp]+2][position_temp] = 1;
                map[height[position_temp]][position_temp+1] = 1;
            end
            else begin
                map[height[position_temp+1]][position_temp]= 1;
                map[height[position_temp+1]+1][position_temp]= 1;
                map[height[position_temp+1]+2][position_temp] = 1;
                map[height[position_temp+1]][position_temp+1] = 1;
            end
            
        end
        6: begin
            if(height[position_temp]>=height[position_temp+1]+1) begin
                map[height[position_temp]+1][position_temp] = 1;
                map[height[position_temp]][position_temp] = 1;
                map[height[position_temp]][position_temp+1] = 1;
                map[height[position_temp]-1][position_temp+1] = 1;
            end
            else begin
                map[height[position_temp+1]+2][position_temp] = 1;
                map[height[position_temp+1]+1][position_temp] = 1;
                map[height[position_temp+1]][position_temp+1] = 1;
                map[height[position_temp+1]+1][position_temp+1] = 1;
            end
            
        end
        7:  begin
            if(height[position_temp]+1>=height[position_temp+2]&&height[position_temp]>=height[position_temp+1]) begin
                map[height[position_temp]][position_temp] = 1;
                map[height[position_temp]][position_temp+1] = 1;
                map[height[position_temp]+1][position_temp+1] = 1;
                map[height[position_temp]+1][position_temp+2] = 1;
            end
            else if(height[position_temp+1]>=height[position_temp]&&height[position_temp+1]+1>=height[position_temp+2]) begin
                map[height[position_temp+1]][position_temp] = 1;
                map[height[position_temp+1]][position_temp+1] = 1;
                map[height[position_temp+1]+1][position_temp+1] = 1;
                map[height[position_temp+1]+1][position_temp+2] = 1;
            end
            else begin
                map[height[position_temp+2]-1][position_temp] = 1;
                map[height[position_temp+2]-1][position_temp+1] = 1;
                map[height[position_temp+2]][position_temp+1] = 1;
                map[height[position_temp+2]][position_temp+2] = 1;
            end
            
        end
        default:map[0] =6'b111111;
    endcase
    
end
endtask


//---------------------------------------------------------------------
//  SPEC-CHECK
//---------------------------------------------------------------------
/////////////SPEC-5///////////////////
always@(negedge clk)
begin//signal score,fail,and tetris_valid mus be 0 when the score_valid is low
    if((score_valid ===0 && score!==0)||(score_valid ===0 &&fail!==0)||(score_valid ===0 &&tetris_valid!==0)||tetris_valid ===0 && tetris!==0) begin
        $display("                    SPEC-5 FAIL   score, fail tetris_valid must be 0 when score_valid is 0                ");
        $finish;
    end
	// @(negedge clk);
end 
/////////////SPEC-4///////////////////
task reset_signal_task; begin 
    rst_n = 'b1;
    in_valid = 'b0;
    tetrominoes = 'bx;
    position = 'bx;
    force clk = 0;
    for(i=0;i<=5;i=i+1) begin
        height[i] = 0;
    end
    for(i=0;i<=14;i=i+1) begin
        map[i] = 0;
    end
   // v_early_fail = 0;
    p_early_fail = 0;
   
    p_score = 0;
    #CYCLE; rst_n = 1'b0; 
    #CYCLE; rst_n = 1'b1;
    #20
    if (tetris_valid !== 0 || score_valid !== 0||fail !== 0 || score !== 0||tetris!==0) begin  
        $display("                    SPEC-4 FAIL               ");
        repeat(2) #CYCLE;
        $finish;
    end
	#CYCLE; release clk;
end 
endtask



task input_task; begin 
    repeat(1)@(negedge clk);
    a = $fscanf(pat_read, "%d",tetrominoes_temp);
    a = $fscanf(pat_read, "%d",position_temp);
    input_wait = $urandom_range(1,4);//why 0 wrong
    repeat(input_wait) @(negedge clk);//change the latency between score_valid and in_valid
    in_valid = 1'b1;
    tetrominoes = tetrominoes_temp;
    position = position_temp;

    @(negedge clk);
    in_valid = 1'b0;
    tetrominoes = 'bx;
    position = 'bx;
end 
endtask

/////////////SPEC-6///////////////////
//the latency of each inputs set is limited in 1000 cycles
//falling edge of in_valid and rising edge of score_valid
task wait_score_valid_task; begin
    latency_temp = 0;
    while(score_valid !== 1'b1) begin
	latency_temp = latency_temp + 1;
      if( latency_temp == 1000) begin
        $display("                    SPEC-6 FAIL                 ");
	    repeat(2)@(negedge clk);
	    $finish;
      end
     @(negedge clk);
   end
   total_latency = total_latency + latency_temp;
end endtask


wire [71:0] tetris_correct = {map[11], map[10],map[9],map[8],map[7],map[6],map[5],map[4],map[3],map[2],map[1],map[0]};
/*
task check_ans_task; begin 
    score_valid_latency = 0;
	tetris_valid_latency = 0;
    if(score_valid===1) begin
        score_valid_latency = score_valid_latency + 1;
       // if(score_valid_latency>1) fail_in_8_1;
        if(p_score!==score) begin fail_in_7_1; end
        if(p_early_fail !== fail) begin fail_in_7_2; end
       
    end
  //  if(score_valid_latency!==1) fail_in_8;

	if(tetris_valid===1) begin
        $display("                    7-3                   ");
		tetris_valid_latency = tetris_valid_latency+1;
        if(tetris_correct!==tetris) fail_in_7_3;
		//if(tetris_valid_latency>1) fail_in_8_2;
        
        if (map[0] !== tetris[5:0] || map[1] !== tetris[11:6] || map[2] !== tetris[17:12] ||
    map[3] !== tetris[23:18] || map[4] !== tetris[29:24] || map[5] !== tetris[35:30] ||
    map[6] !== tetris[41:36] || map[7] !== tetris[47:42] || map[8] !== tetris[53:48] ||
    map[9] !== tetris[59:54] || map[10] !== tetris[65:60] || map[11] !== tetris[71:66]) begin
         $display("                    7-3                   ");
         fail_in_7_3;
         end

    
    end
    if(tetris_valid_latency!==1) fail_in_8;
end 
endtask*/
//correct//
/*task check_ans_task; begin 
    if((score_valid===1&&(p_score!==score||fail!==p_early_fail))||(tetris_valid===1&&tetris!==tetris_correct)) begin
        fail_in_7;
    end
end 
endtask*/
///////////
task check_ans_task; begin 
    if(score_valid===1&&p_score!==score) begin
        fail_in_7_1;
    end
    if(score_valid===1&&fail!==p_early_fail) begin
        fail_in_7_2;
    end
    if(tetris_valid===1&&tetris!==tetris_correct) begin
        fail_in_7_3;
    end
end 
endtask
always@(negedge clk) begin
    if(score_valid===1 || tetris_valid===1) begin
        @(negedge clk)
        if(score_valid!==0||tetris_valid!==0) begin
            fail_in_8;
        end
    end
end
/////////////SPEC-8///////////////////
task fail_in_8; begin
    $display("                    SPEC-8 FAIL                   ");
    repeat(2) @(negedge clk)
    $finish;
end 
endtask

/////////////SPEC-7///////////////////
task fail_in_7_1; begin
    $display("                    SPEC-7 FAIL                  ");
    repeat(2) @(negedge clk)
    $finish;
end 
endtask
task fail_in_7_2; begin
    $display("                    SPEC-7 FAIL                  ");
    repeat(2) @(negedge clk)
    $finish;
end 
endtask
task fail_in_7_3; begin
    $display("                    SPEC-7 FAIL                  ");
    repeat(2) @(negedge clk)
    $finish;
end 
endtask


task YOU_PASS_task; begin
 	$display("                  Congratulations!               ");
 	$display("              execution cycles = %7d", total_latency);
 	$display("              clock period = %4fns", CYCLE);
end endtask
endmodule
// for spec check
// $display("                    SPEC-4 FAIL                   ");
// $display("                    SPEC-5 FAIL                   ");
// $display("                    SPEC-6 FAIL                   ");
// $display("                    SPEC-7 FAIL                   ");
// $display("                    SPEC-8 FAIL                   ");
// for successful design
// $display("                  Congratulations!               ");
// $display("              execution cycles = %7d", total_latency);
// $display("              clock period = %4fns", CYCLE);
