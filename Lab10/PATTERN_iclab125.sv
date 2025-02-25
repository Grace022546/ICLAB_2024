
// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"
`define CYCLE_TIME 10

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter MAX_CYCLE=1000;

//================================================================
//  integer & parameter
//================================================================
integer i, cycles, total_cycles, y;
integer patcount;
integer count;
parameter SEED = 127 ;
parameter PATNUM = 5800 ;
parameter BASE_Addr = 65536 ;
//================================================================
// logic
//================================================================
logic [7:0] golden_DRAM[(BASE_Addr+0):((BASE_Addr+256*8)-1)];
// operation info.
// Data golden_data;
Action     golden_act;
Formula_Type   golden_formula;
Mode       golden_mode;
Data_No        golden_DRAM_no;
Date       golden_date;
Index    golden_index;

// Dram info
Data_Dir   golden_dram_data_info;

// golden outputs
logic golden_complete;
Warn_Msg golden_warn_msg;
logic golden_out_valid;
logic [11:0] temp_index_A;
logic [11:0] temp_index_B;
logic [11:0] temp_index_C;
logic [11:0] temp_index_D;
logic [11:0]golden_index_A;
logic [11:0]golden_index_B;
logic [11:0]golden_index_C;
logic [11:0]golden_index_D;
logic [12:0] golden_temp_index_A,golden_temp_index_B,golden_temp_index_C,golden_temp_index_D;
logic [12:0]abs_index_A;
logic [12:0]abs_index_B;
logic [12:0]abs_index_C;
logic [12:0]abs_index_D;
logic [12:0]golden_R;
logic [12:0]sort_result[0:3];
logic [12:0]sort_minus[0:3];
logic [12:0]temp, temp2;
logic flag_A,flag_B,flag_C,flag_D;
logic abs_flag_A,abs_flag_B,abs_flag_C,abs_flag_D;
//================================================================
//  class
//================================================================
class rand_delay;
	rand int delay;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { delay inside {[0:3]}; } // Generates a delay between 1~4
endclass
class rand_formula;
	randc Formula_Type formula;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit {formula inside {Formula_A,Formula_B,Formula_C,Formula_D,Formula_E,Formula_F,Formula_G,Formula_H};}
endclass

class rand_mode;
	randc Mode mode;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit {mode inside {Insensitive,Normal,Sensitive};}
endclass

class rand_action;
	randc Action action;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { action inside {Index_Check, Update, Check_Valid_Date}; }
endclass

class rand_dram_no;
    rand int dram_no;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { dram_no inside {[0:255]}; }
endclass

class rand_index;
    randc int index;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { index inside {[0:4095]}; }
endclass

class rand_date;
	randc reg[3:0] month;
    rand reg[4:0] day;
	function new (int seed);
		this.srandom(seed);
	endfunction

    // Constraint can only be used once.
	constraint limit {
        month inside {[1:12]};
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12)
            day inside {[1:31]};
        else if (month == 4 || month == 6 || month == 9 || month == 11)
            day inside {[1:30]};
        else if (month == 2)
            day inside {[1:28]};
    }
endclass

//
rand_delay r_delay = new(SEED) ;
//
rand_formula r_formula = new(SEED) ;

rand_mode r_mode = new(SEED) ;
rand_action   r_action = new(SEED) ;
rand_dram_no  r_dram_no  = new(SEED) ;
rand_date     r_date     = new(SEED) ;
rand_index r_index = new(SEED);






//================================================================
//  initial
//================================================================
initial begin
	// read in initial DRAM data
	$readmemh(DRAM_p_r, golden_DRAM);
    golden_DRAM_no = 0;

	// reset output signals
	inf.rst_n = 1'b1 ;
	inf.sel_action_valid = 1'b0 ;
	inf.formula_valid = 1'b0 ;
	inf.mode_valid = 1'b0 ;
	inf.date_valid = 1'b0 ;
	inf.data_no_valid = 1'b0 ;
	inf.index_valid = 1'b0 ;
    inf.D = 'bx;

	// reset
	total_cycles = 0 ;
	reset_task;
	//
	@(negedge clk);
	
	for( patcount=0 ; patcount<PATNUM ; patcount+=1 ) begin
		// randomize, makes the r_give_id becomes a random number with the give constraints
		r_action.randomize();
//$display("PATNUM = %d", PATNUM);
		//golden_act  = r_action.action ;
		golden_warn_msg  = No_Warn;
		golden_complete = 1'b0;
		
		if(patcount<=2700) begin//index check 3600 update 900 check valid date 900
		case(patcount%9)
			0:golden_act = Index_Check ;
			1:golden_act = Update ;
			2:golden_act = Update ;
			3:golden_act = Index_Check ;
			4:golden_act = Check_Valid_Date ;
			5:golden_act = Check_Valid_Date ;
			6:golden_act = Update ;
			7:golden_act = Check_Valid_Date ;
			8:golden_act = Index_Check ;
		endcase
		end
		else begin
			golden_act =  Index_Check;
		end
		//Start giving inputs
		case(golden_act)
			Index_Check: begin
			//	$display("11111");
				index_check_task;
				index_check_cmp_task;
				//$display("11111");
				if (golden_warn_msg == No_Warn) begin
					sort;
					index_check_cal_task;
				//	$display("2222222");
				end

			end
			Update: begin
			//	$display("222222");
				update_task;
				update_dram_info_task;
			end
			Check_Valid_Date: begin
			//	$display("33333333333");
				check_valid_date_task;
			end
		endcase
	//	$display("33333333333");
        // For checking
		wait_outvalid_task;
	//	$display("444444");
		output_task;
		//
		delay_task;
		//
		// #(100);
        $display("PASS PATTERN NO.%4d", patcount);
	end
	// #(100);
    YOU_PASS_task;
    $finish;
end


//================================================================
//  reset task
//================================================================
task reset_task; begin
	#(3.0);
	inf.rst_n = 0 ;
	#(3.0);
	// if (inf.out_valid!==0 || inf.warn_msg!==0 || inf.complete !== 0) begin
	// 	 fail;
    //     // Spec. 3
    //     // Using  asynchronous  reset  active  low  architecture. All  outputs  should  be zero after reset.
    //     $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
    //     $display ("                                                                SPEC 3 FAIL!                                                                ");
    //     $display ("                                   All output signals should be reset after the reset signal is asserted.                                   ");
    //     $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
    //     #(10);
    //     $finish;
	// end
	#(2.0);	inf.rst_n = 1 ;
end endtask
//================================================================
//  update dram info task
//================================================================
task update_dram_info_task;
begin
    golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 7]      = golden_dram_data_info.Index_A[11:4];
    golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 6][7:4] = golden_dram_data_info.Index_A[3:0];
	golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 6][3:0] = golden_dram_data_info.Index_B[11:8];
    golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 5]      = golden_dram_data_info.Index_B[7:0];
    golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 4]      = golden_dram_data_info.M;
    golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 3]      = golden_dram_data_info.Index_C[11:4];
    golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 2][7:4] = golden_dram_data_info.Index_C[3:0];
    golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 2][3:0] = golden_dram_data_info.Index_D[11:8];
    golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 1]      = golden_dram_data_info.Index_D[7:0];
    golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 0]      = golden_dram_data_info.D;
end
endtask
//================================================================
//  index check task
//================================================================
task get_dram_info_task;
begin
    golden_dram_data_info.Index_A = {golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 7],golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 6][7:4]};
	golden_dram_data_info.Index_B = {golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 6][3:0],golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 5]};
	golden_dram_data_info.M       = golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 4];
	golden_dram_data_info.Index_C =  {golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 3],golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 2][7:4]};
	golden_dram_data_info.Index_D =  {golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 2][3:0],golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 1]};
	golden_dram_data_info.D       =  golden_DRAM[BASE_Addr+golden_DRAM_no*8 + 0];
end
endtask
//================================================================
//  index check task
//================================================================

task index_check_task; begin
	// Generate Input actions
	inf.sel_action_valid = 1'b1;
    inf.D = golden_act;
    @(negedge clk);
    inf.sel_action_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

	// Generate formula, 8 types
    inf.formula_valid = 1'b1;
    r_formula.randomize();
    golden_formula = r_formula.formula;
    inf.D  = golden_formula;
    @(negedge clk);
    inf.formula_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

	// Generate mode, 3 types
    inf.mode_valid = 1'b1;
    r_mode.randomize();
    golden_mode = r_mode.mode;
    inf.D  = golden_mode;
    @(negedge clk);
    inf.mode_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

	// Giving date
	inf.date_valid = 1'b1;
    r_date.randomize();
    golden_date.D = r_date.day;
    golden_date.M = r_date.month;
    inf.D  = {63'bx,golden_date.M,golden_date.D};
    @(negedge clk);
    inf.date_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

	// Giving dram #no.
	inf.data_no_valid = 1'b1;
    r_dram_no.randomize();
    golden_DRAM_no = r_dram_no.dram_no;
    inf.D  = golden_DRAM_no;
    @(negedge clk);
    inf.data_no_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

		//indexA
	inf.index_valid = 1'b1;
    r_index.randomize();
    golden_index_A = r_index.index;
    inf.D  = golden_index_A;
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

	//indexB
	inf.index_valid = 1'b1;
    r_index.randomize();
    golden_index_B = r_index.index;
    inf.D  = golden_index_B;
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

	//indexC
	inf.index_valid = 1'b1;
    r_index.randomize();
    golden_index_C = r_index.index;
    inf.D  = golden_index_C;
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

	//indexD
	inf.index_valid = 1'b1;
    r_index.randomize();
    golden_index_D = r_index.index;
    inf.D  = golden_index_D;
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;
    //delay_task;

	
    get_dram_info_task;
    // golden_complete = 1'b1;
    // golden_warn_msg  = No_Warn;
	  // Generate golden result
    temp_index_A = golden_dram_data_info.Index_A;
    temp_index_B = golden_dram_data_info.Index_B;
    temp_index_C = golden_dram_data_info.Index_C;
    temp_index_D = golden_dram_data_info.Index_D;
end endtask
task index_check_cmp_task; begin
	if((golden_dram_data_info.M > golden_date.M) || ((golden_dram_data_info.M == golden_date.M) && (golden_dram_data_info.D > golden_date.D)))
    begin
		golden_warn_msg = Date_Warn;
		golden_complete = 1'b0;
	end
	else
    begin
        golden_warn_msg  = No_Warn;
        //golden_complete = 1'b1;
    end
end endtask

task sort; begin
	sort_result[0:3] = {temp_index_A, temp_index_B, temp_index_C, temp_index_D};//small to large
        for (int j = 0; j < 3; j = j + 1) begin
            for (int i = 0; i < 4 ; i = i + 1) begin 
                if (sort_result[i] > sort_result[i + 1]) begin
                    int temp = sort_result[i];
                    sort_result[i] = sort_result[i + 1];
                    sort_result[i + 1] = temp;
                end
            end
        end
	abs_index_A = (temp_index_A>golden_index_A)?(temp_index_A - golden_index_A):(golden_index_A-temp_index_A);
	abs_index_B = (temp_index_B>golden_index_B)?(temp_index_B - golden_index_B):(golden_index_B-temp_index_B);
	abs_index_C = (temp_index_C>golden_index_C)?(temp_index_C - golden_index_C):(golden_index_C-temp_index_C);
	abs_index_D = (temp_index_D>golden_index_D)?(temp_index_D - golden_index_D):(golden_index_D-temp_index_D);
	sort_minus[0:3] = {abs_index_A,abs_index_B,abs_index_C,abs_index_D};
	for (int j = 0; j < 3; j = j + 1) begin
		for(int i=0;i<4;i=i+1) begin
			if(sort_minus[i]>sort_minus[i+1]) begin
				int temp2 = sort_minus[i];
				sort_minus[i] = sort_minus[i+1];
				sort_minus[i+1] = temp2;
			end
		end 
	end	
end endtask

task index_check_cal_task; begin
    
	abs_index_A = (temp_index_A>golden_index_A)?(temp_index_A - golden_index_A):(golden_index_A-temp_index_A);
	abs_index_B = (temp_index_B>golden_index_B)?(temp_index_B - golden_index_B):(golden_index_B-temp_index_B);
	abs_index_C = (temp_index_C>golden_index_C)?(temp_index_C - golden_index_C):(golden_index_C-temp_index_C);
	abs_index_D = (temp_index_D>golden_index_D)?(temp_index_D - golden_index_D):(golden_index_D-temp_index_D);
	case(golden_formula)
		Formula_A: 
		begin
			golden_R = (temp_index_A + temp_index_B + temp_index_C + temp_index_D)/4;
			case(golden_mode)
				Insensitive: 
				begin
					if(golden_R>=2047)  begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0;end
					else  begin golden_warn_msg = No_Warn; golden_complete = 1'b1;end
				end
				Normal: 
				begin
					if(golden_R>=1023) begin  golden_warn_msg = Risk_Warn; golden_complete = 1'b0;end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
				Sensitive: 
				begin
					if(golden_R>=511) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
			endcase
		end
		Formula_B: 
		begin
			golden_R = sort_result[3] - sort_result[0];
			case(golden_mode)
				Insensitive: 
				begin
					if(golden_R>=800) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
				Normal: 
				begin
					if(golden_R>=400) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
				Sensitive: 
				begin
					if(golden_R>=200) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
			endcase
		end
		Formula_C: 
		begin
			golden_R = sort_result[0];
			case(golden_mode)
				Insensitive: 
				begin
					if(golden_R>=2047) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
				Normal: 
				begin
					if(golden_R>=1023) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
				Sensitive: 
				begin
					if(golden_R>=511) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
			endcase
		end
		Formula_D: 
		begin
			flag_A = (temp_index_A>=2047)?1:0;
			flag_B = (temp_index_B>=2047)?1:0;
			flag_C = (temp_index_C>=2047)?1:0;
			flag_D = (temp_index_D>=2047)?1:0;
			golden_R = flag_A + flag_B + flag_C + flag_D;
			case(golden_mode)
				Insensitive: 
				begin
					if(golden_R>=3) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
				Normal: 
				begin
					if(golden_R>=2) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
				Sensitive: 
				begin
					if(golden_R>=1) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
			endcase
		end
		Formula_E: 
		begin
			abs_flag_A = (temp_index_A>=golden_index_A)?1:0;
			abs_flag_B = (temp_index_B>=golden_index_B)?1:0;
			abs_flag_C = (temp_index_C>=golden_index_C)?1:0;
			abs_flag_D = (temp_index_D>=golden_index_D)?1:0;
			golden_R = abs_flag_A + abs_flag_B + abs_flag_C + abs_flag_D;
			case(golden_mode)
				Insensitive: 
				begin
					if(golden_R>=3) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
				Normal: 
				begin
					if(golden_R>=2) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
				Sensitive: 
				begin
					if(golden_R>=1) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
			endcase
		end
		Formula_F: 
		begin
			golden_R = (sort_minus[0] + sort_minus[1] + sort_minus[2])/3;
			case(golden_mode)
				Insensitive: 
				begin
					if(golden_R>=800) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
				Normal: 
				begin
					if(golden_R>=400) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
				Sensitive: 
				begin
					if(golden_R>=200) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
			endcase
		end
		Formula_G: 
		begin
			golden_R = sort_minus[0]/2 + sort_minus[1]/4 + sort_minus[2]/4;
			case(golden_mode)
				Insensitive: 
				begin
					if(golden_R>=800) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
				Normal: 
				begin
					if(golden_R>=400) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
				Sensitive: 
				begin
					if(golden_R>=200) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
			endcase
		end
		Formula_H: 
		begin
			golden_R = (sort_minus[3] + sort_minus[2] + sort_minus[1] + sort_minus[0])/4;
			case(golden_mode)
				Insensitive: 
				begin
					if(golden_R>=800) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
				Normal: 
				begin
					if(golden_R>=400) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
				Sensitive: 
				begin
					if(golden_R>=200) begin golden_warn_msg = Risk_Warn; golden_complete = 1'b0; end
					else begin golden_warn_msg = No_Warn; golden_complete = 1'b1; end
				end
			endcase
		end
	endcase
end endtask

//================================================================
//  update task
//================================================================

task update_task; begin
	// Generate Input actions
	inf.sel_action_valid = 1'b1;
    inf.D = golden_act;
    @(negedge clk);
    inf.sel_action_valid = 1'b0;
    inf.D = 'bx;
    delay_task;
	
    // Giving date
	inf.date_valid = 1'b1;
    r_date.randomize();
    golden_date.D = r_date.day;
    golden_date.M = r_date.month;
    inf.D  = {3'b0,golden_date.M,golden_date.D};
    @(negedge clk);
    inf.date_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

	 // Giving dram #no.
	inf.data_no_valid = 1'b1;
    r_dram_no.randomize();
    golden_DRAM_no = r_dram_no.dram_no;
    inf.D  = golden_DRAM_no;
    @(negedge clk);
    inf.data_no_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

	//indexA
	inf.index_valid = 1'b1;
    r_index.randomize();
    golden_index_A = r_index.index;
    inf.D  = golden_index_A;
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

	//indexB
	inf.index_valid = 1'b1;
    r_index.randomize();
    golden_index_B = r_index.index;
    inf.D  = golden_index_B;
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

	//indexC
	inf.index_valid = 1'b1;
    r_index.randomize();
    golden_index_C = r_index.index;
    inf.D  = golden_index_C;
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

	//indexD
	inf.index_valid = 1'b1;
    r_index.randomize();
    golden_index_D = r_index.index;
    inf.D  = golden_index_D;
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

	get_dram_info_task;

	//golden_complete = 1'b1;

	    // Generate golden result
    temp_index_A = golden_dram_data_info.Index_A;
    temp_index_B = golden_dram_data_info.Index_B;
    temp_index_C = golden_dram_data_info.Index_C;
    temp_index_D = golden_dram_data_info.Index_D;
    // Add the supplies
    golden_temp_index_A = (golden_index_A[11])?({golden_index_A[11],golden_index_A} + temp_index_A):(golden_index_A + temp_index_A);
    golden_temp_index_B = (golden_index_B[11])?({golden_index_B[11],golden_index_B} + temp_index_B):(golden_index_B + temp_index_B);
	golden_temp_index_C = (golden_index_C[11])?({golden_index_C[11],golden_index_C} + temp_index_C):(golden_index_C + temp_index_C);
	golden_temp_index_D = (golden_index_D[11])?({golden_index_D[11],golden_index_D} + temp_index_D):(golden_index_D + temp_index_D);

	if((golden_index_A[11]==0&&golden_temp_index_A[12])||(golden_index_B[11]==0&&golden_temp_index_B[12])||(golden_index_C[11]==0&&golden_temp_index_C[12])||(golden_index_D[11]==0&&golden_temp_index_D[12]))
    begin
		//$display("123456789");
        golden_warn_msg  = Data_Warn;
        golden_complete = 1'b0;
    end
	else if((golden_index_A[11]&&golden_temp_index_A[12])||(golden_index_B[11]&&golden_temp_index_B[12])||(golden_index_C[11]&&golden_temp_index_C[12])||(golden_index_D[11]&&golden_temp_index_D[12]))
    begin
		//$display("123456789");
        golden_warn_msg  = Data_Warn;
        golden_complete = 1'b0;
    end
    else
    begin
        golden_warn_msg  = No_Warn;
        golden_complete = 1'b1;
    end

	if(golden_index_A[11]==0&&golden_temp_index_A[12]) begin
		golden_dram_data_info.Index_A = 4095; 
	end
	else if(golden_index_A[11]&&golden_temp_index_A[12]) begin
		golden_dram_data_info.Index_A = 0; 
	end
	else begin
		golden_dram_data_info.Index_A = golden_temp_index_A[11:0];
	end


    if(golden_index_B[11]==0&&golden_temp_index_B[12]) begin
		golden_dram_data_info.Index_B = 4095;
	end
	else if(golden_index_B[11]&&golden_temp_index_B[12]) begin
		golden_dram_data_info.Index_B = 0; 
	end
	else begin
		golden_dram_data_info.Index_B = golden_temp_index_B[11:0];
	end


	if(golden_index_C[11]==0&&golden_temp_index_C[12]) begin
		golden_dram_data_info.Index_C = 4095;
	end
	else if(golden_index_C[11]&&golden_temp_index_C[12]) begin
		golden_dram_data_info.Index_C = 0; 
	end
	else begin
		golden_dram_data_info.Index_C = golden_temp_index_C[11:0];
	end


	if(golden_index_D[11]==0&&golden_temp_index_D[12]) begin
		golden_dram_data_info.Index_D = 4095;
	end
	else if(golden_index_D[11]&&golden_temp_index_D[12]) begin
		golden_dram_data_info.Index_D = 0; 
	end
	else begin
		golden_dram_data_info.Index_D = golden_temp_index_D[11:0];
	end
	// if(golden_index_A[11]&&golden_temp_index_A[12]) begin
	// 	golden_dram_data_info.Index_A = 0; 
	// end
	// else begin
	// 	golden_dram_data_info.Index_A = golden_temp_index_A[11:0];
	// end
	// if(golden_index_B[11]&&golden_temp_index_B[12]) begin
	// 	golden_dram_data_info.Index_B = 0; 
	// end
	// else begin
	// 	golden_dram_data_info.Index_B = golden_temp_index_B[11:0];
	// end
	// if(golden_index_C[11]&&golden_temp_index_C[12]) begin
	// 	golden_dram_data_info.Index_C = 0; 
	// end
	// else begin
	// 	golden_dram_data_info.Index_C = golden_temp_index_C[11:0];
	// end
	// if(golden_index_D[11]&&golden_temp_index_D[12]) begin
	// 	golden_dram_data_info.Index_D = 0; 
	// end
	// else begin
	// 	golden_dram_data_info.Index_D = golden_temp_index_D[11:0];
	// end

    // The date must also gets updated when supplying
    golden_dram_data_info.M = golden_date.M;
    golden_dram_data_info.D = golden_date.D;


end endtask
//================================================================
//  check valid date task
//================================================================
task check_valid_date_task;
begin
    // Generate Input actions
	inf.sel_action_valid = 1'b1;
    inf.D = golden_act;
    @(negedge clk);
    inf.sel_action_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    // Give Today's Date
    inf.date_valid = 1'b1;
    r_date.randomize();
    golden_date.D = r_date.day;
    golden_date.M = r_date.month;

    inf.D  = {63'bx,golden_date.M,golden_date.D};
    @(negedge clk);
    inf.date_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    // Box #No.
    inf.data_no_valid= 1'b1;
    r_dram_no.randomize();
    golden_DRAM_no = r_dram_no.dram_no;
    inf.D  = {64'b0,golden_DRAM_no};
    @(negedge clk);
    inf.data_no_valid = 1'b0;
    inf.D = 'bx;
    delay_task;
	golden_complete = 1'b0;
    get_dram_info_task;
	if((golden_dram_data_info.M > golden_date.M) || ((golden_dram_data_info.M == golden_date.M) && (golden_dram_data_info.D > golden_date.D)))
    begin
		golden_warn_msg = Date_Warn;
		golden_complete = 1'b0;
	end
	else
    begin
        golden_warn_msg  = No_Warn;
        golden_complete = 1'b1;
    end 
	
    // // Start checking outputs, no need for updates
    // if(golden_dram_data_info.M >= golden_date.M && golden_dram_data_info.D >= golden_date.D)
    // begin
    //     golden_complete = 1'b1;
    //     golden_warn_msg  = No_Warn;
    // end
    // else
    // begin
    //     golden_complete = 1'b0;
    //     golden_warn_msg  = Date_Warn;
    // end
end
endtask

//================================================================
//  wait outvalid task
//================================================================
task wait_outvalid_task; begin
	cycles = 0 ;
	while (inf.out_valid!==1)
    begin
		cycles = cycles + 1 ;
		// if (cycles==1000) begin
		// 	 fail;
        //     // Spec. 8
        //     // Your latency should be less than 1200 cycle for each operation.
        //     $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        //     $display ("                                                                SPEC 4 FAIL!                                                                ");
        //     $display ("                                             The execution latency is limited in 1000 cycles.                                               ");
        //     $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        // 	//#(100);
        //     $finish;
		// end
		@(negedge clk);
	end
	total_cycles = total_cycles + cycles ;
end endtask
//================================================================
//  Delay task
//================================================================

task delay_task ; begin
	r_delay.randomize();
	//$display("r_delay = %d", r_delay.delay);
	//$display("11111");
	for( i=0 ; i<r_delay.delay ; i++ )	@(negedge clk);
end endtask
//================================================================
//  output task
//================================================================
task output_task; begin
	//y = 0;
	// while (inf.out_valid===1)
    // begin
		// if (y >= 1)
        // begin
		// 	fail;
		// 	$display ("--------------------------------------------------");
		// 	$display ("                        FAIL                      ");
		// 	$display ("          Outvalid is more than 1 cycles          ");
		// 	$display ("--------------------------------------------------");
	    //    // #(100);
		// 	$finish;
		// end
		// else 
		if (golden_act==Index_Check)
        begin
    		if ( (inf.complete!==golden_complete) || (inf.warn_msg!==golden_warn_msg))
            begin
				fail;
				$display("-----------------------------------------------------------");
    	    	$display("                       FAILIndex Check                     ");
    	    	$display("    Golden complete : %6d    your complete : %6d ", golden_complete, inf.complete);
    			$display("    Golden warn_msg  : %6d    your warn_msg  : %6d ", golden_warn_msg, inf.warn_msg);
    			$display("-----------------------------------------------------------");
                get_dram_info_task;
		      //  #(100);
    			$finish;
    		end
    	end
		else if (golden_act == Update)
        begin
    		if ( (inf.complete!==golden_complete) || (inf.warn_msg!==golden_warn_msg))
            begin
				fail;
				$display("-----------------------------------------------------------");
    	    	$display("                           FAIL Upddate                     ");
    	    	$display("    Golden complete : %6d    your complete : %6d ", golden_complete, inf.complete);
    			$display("    Golden warn_msg  : %6d    your warn_msg  : %6d ", golden_warn_msg, inf.warn_msg);
    			$display("-----------------------------------------------------------");
                get_dram_info_task;
		      //  #(100);
    			$finish;
    		end
        end
        else if(golden_act == Check_Valid_Date)
        begin
            if ( (inf.complete!==golden_complete) || (inf.warn_msg!==golden_warn_msg))
            begin
				fail;
				$display("-----------------------------------------------------------");
    	    	$display("                           FAIL Check Valid date                     ");
    	    	$display("    Golden complete : %6d    your complete : %6d ", golden_complete, inf.complete);
    			$display("    Golden warn_msg  : %6d    your warn_msg  : %6d ", golden_warn_msg, inf.warn_msg);
    			$display("-----------------------------------------------------------");
                get_dram_info_task;
		       // #(100);
    			$finish;
    		end
        end
    end
	@(negedge clk);
	//y = y + 1;
//end
endtask

task YOU_PASS_task; begin
    $display("                  Congratulations!               ");
    $display("              execution cycles = %7d", total_cycles);
    $display("              clock period = %4fns", `CYCLE_TIME);
	$display("              execution latency = %7d", total_cycles*`CYCLE_TIME);
    $finish;
end 
endtask
task fail; begin
$display("                                      Wrong Answer                        ");
end endtask
endprogram
