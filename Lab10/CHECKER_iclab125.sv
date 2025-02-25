/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

// integer fp_w;

// initial begin
// fp_w = $fopen("out_valid.txt", "w");
// end

/**
 * This section contains the definition of the class and the instantiation of the object.
 *  * 
 * The always_ff blocks update the object based on the values of valid signals.
 * When valid signal is true, the corresponding property is updated with the value of inf.D
 */

class Formula_and_mode;
    Formula_Type f_type;
    Mode f_mode;
endclass

Formula_and_mode fm_info = new();


/*
    Cover group define
*/
/*
1. Each case of Beverage_Type should be select at least 100 times.
*/

always_ff @(posedge clk) begin
    if (inf.formula_valid) begin
        fm_info.f_type = inf.D.d_formula[0];
    end
end

always_ff @(posedge clk) begin
    if (inf.mode_valid) begin
        fm_info.f_mode = inf.D.d_mode[0];
    end
end

Action cur_act;
always_ff @(posedge clk or negedge inf.rst_n)  begin
	if (!inf.rst_n)				        cur_act <= Index_Check;
	else begin
		if (inf.sel_action_valid==1) 	cur_act <= inf.D.d_act[0] ;
	end
end

covergroup Spec1 @(posedge clk iff(inf.formula_valid));
    option.per_instance = 1;
    option.at_least = 150;

    bin_formula: coverpoint fm_info.f_type{
    bins f_formula_type[] ={[Formula_A:Formula_H]};
    }
endgroup:Spec1

/*
2.	Each case of Bererage_Size should be select at least 100 times.
*/
covergroup Spec2 @(posedge clk iff(inf.mode_valid));
    option.per_instance = 1;
	option.at_least = 150;
	bin_mode: coverpoint fm_info.f_mode{
        bins m_mode[] = {[Insensitive:Sensitive]};
    }
endgroup:Spec2

/*
3.	Create a cross bin for the SPEC1 and SPEC2. Each combination should be selected at least 100 times.
(Black Tea, Milk Tea, Extra Milk Tea, Green Tea, Green Milk Tea, Pineapple Juice, Super Pineapple Tea, Super Pineapple Tea) x (L, M, S)
*/
covergroup Spec3 @(posedge clk iff(inf.date_valid && cur_act==Index_Check));
    option.per_instance = 1;
   	option.at_least = 150 ; // At least 100 times for this variable

    cross fm_info.f_type,fm_info.f_mode;
endgroup : Spec3

/*
4.	Output signal inf.err_msg should be No_Err, No_Exp, No_Ing and Ing_OF, each at least 20 times. (Sample the value when inf.out_valid is high)
*/
covergroup Spec4 @(negedge clk iff(inf.out_valid));
    option.per_instance = 1;
   	coverpoint inf.warn_msg {
   		option.at_least = 50 ; // At least 50 times for this variable
   		bins b1 = {No_Warn};
   		bins b2 = {Date_Warn};
   		bins b3 = {Risk_Warn};
   		bins b4 = {Data_Warn};
    }
endgroup : Spec4

/*
5.	Create the transitions bin for the inf.D.cur_act[0] signal from [0:2] to [0:2]. Each transition should be hit at least 200 times. (sample the value at posedge clk iff inf.sel_action_valid)
*/
covergroup Spec5 @(posedge clk iff(inf.sel_action_valid));
    option.per_instance = 1;
   	coverpoint inf.D.d_act[0] {
   		option.at_least = 300 ; // At least 10 times for this variable
   		bins act_trans[] = (Index_Check,Update,Check_Valid_Date=>Index_Check,Update,Check_Valid_Date);// Each cross couple terms
   	}
endgroup: Spec5

/*
6.	Create a covergroup for material of supply action with auto_bin_max = 32, and each bin have to hit at least one time.
*/
covergroup Spec6 @(posedge clk iff(inf.index_valid&&cur_act===Update));
    option.per_instance = 1;
	option.auto_bin_max = 32;
   	coverpoint inf.D.d_index[0] {
   		option.at_least = 1 ; // At least 10 times for this variable
   	}
endgroup: Spec6
/*
    Create instances of Spec1, Spec2, Spec3, Spec4, Spec5, and Spec6
*/
Spec1 cg_1 = new();
Spec2 cg_2 = new();
Spec3 cg_3 = new();
Spec4 cg_4 = new();
Spec5 cg_5 = new();
Spec6 cg_6 = new();
/*
    Asseration
*/

/*
    If you need, you can declare some FSM, logic, flag, and etc. here.
*/
wire none = !((inf.sel_action_valid===1) || (inf.formula_valid===1) || (inf.mode_valid===1) || (inf.date_valid===1) || (inf.data_no_valid===1) || (inf.index_valid===1) );

/*
    1. All outputs signals (including BEV.sv and bridge.sv) should be zero after reset.
*/
always @(negedge inf.rst_n) begin
	#2;
    // Check initial states for output all values
	assert_1 : assert ((inf.out_valid===0)&&(inf.warn_msg==No_Warn)&&(inf.complete===0)
    &&(inf.AR_VALID===0)&&(inf.AR_ADDR===0)&&(inf.R_READY===0)
    &&(inf.AW_VALID===0)&&(inf.AW_ADDR===0)&&(inf.W_VALID===0)&&(inf.W_DATA===0)&&(inf.B_READY===0))
	else begin
        $display("===================================================");
		$display("              Assertion 1 is violated              ");
		$display("===================================================");
		$fatal;
	end
end



wire[4:0] month = inf.D.d_date[0].M;
wire[5:0] day   = inf.D.d_date[0].D;

/*
    2.	Latency should be less than 1000 cycles for each operation.
*/
assert_2_1 : assert property (latency_violation_property_check_date)
else
begin
	$display("====================================");
	$display("      Assertion 2 is violated       ");
    $display("====================================");
	$fatal;
end


assert_2_2 : assert property (latency_violation_property_update)
else
begin
	$display("====================================");
	$display("      Assertion 2 is violated       ");
    $display("====================================");
	$fatal;
end



/*
    3. If action is completed, warn_msg should be no_warn
*/
assert_3_0 : assert property (action_complete_check_property)
else
begin
	$display("=========================");
	$display("  Assertion 3 is violated");
    $display("=========================");
	$fatal;
end




logic[1:0] cnt;
always_ff @(posedge clk or negedge inf.rst_n)
begin
	if (!inf.rst_n) cnt <= 0 ;
	else
	begin
		if (inf.index_valid==1) cnt <= cnt + 1;
	end
end
/*
    4. Next input valid will be valid 1-4 cycles after previous input valid fall
*/
// Make drink
assert_4_0 : assert property (Index_Check_1_property)
else
begin
	$display("=========================");
	$display("  Assertion 4 is violated");
    $display("=========================");
	$fatal;
end

assert_4_1 : assert property (Index_Check_2_property)
else
begin
	$display("==========================");
	$display("  Assertion 4 is violated");
    $display("==========================");
	$fatal;
end

assert_4_2 : assert property (Index_Check_3_property)
else
begin
	$display("=========================");
	$display("  Assertion 4 is violated");
    $display("=========================");
	$fatal;
end

assert_4_3 : assert property (Index_Check_4_property)
else
begin
	$display("==========================");
	$display("  Assertion 4 is violated");
    $display("==========================");
	$fatal;
end

// Supply
assert_4_4 : assert property (Index_Check_5_property)
else
begin
	$display("=========================");
	$display("  Assertion 4 is violated");
    $display("=========================");
	$fatal;
end

assert_4_5 : assert property (Update_1_property)
else
begin
	$display("=========================");
	$display("  Assertion 4 is violated");
    $display("=========================");
	$fatal;
end

assert_4_6 : assert property (Update_2_property)
else
begin
	$display("=========================");
	$display("  Assertion 4 is violated");
    $display("=========================");
	$fatal;
end

assert_4_7 : assert property (Update_3_property)
else
begin
	$display("=========================");
	$display("  Assertion 4 is violated");
    $display("=========================");
	$fatal;
end

assert_4_7_1 : assert property (Update_4_property)
else
begin
	$display("=========================");
	$display("  Assertion 4 is violated");
    $display("=========================");
	$fatal;
end

// Check valid date
assert_4_8 : assert property (Check_Valid_Date_1_property)
else
begin
	$display("=========================");
	$display("  Assertion 4 is violated");
    $display("=========================");
	$fatal;
end

assert_4_9 : assert property (Check_Valid_Date_2_property)
else
begin
	$display("=========================");
	$display("  Assertion 4 is violated");
    $display("=========================");
	$fatal;
end

 /*
    5. All input valid signals won't overlap with each other.
*/
assert_5: assert property (overlap_property)
else
begin
 	$display("============================================");
 	$display("          Assertion 5 is violated           ");
 	$display("============================================");
 	$fatal;
end

/*
    6. Out_valid can only be high for exactly one cycle.
*/
assert_6 : assert property (out_valid_once_property)
else
begin
	$display("==========================");
	$display("  Assertion 6 is violated");
    $display("==========================");
	$fatal;
end

/*
    7. Next operation will be valid 1-4 cycles after out_valid fall.
*/
assert_7 : assert property (random_gap_property)
else
begin
	$display("=========================");
	$display("  Assertion 7 is violated");
    $display("=========================");
	$fatal;
end



/*
    8. The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases)
*/
// 1,3,5,7,8,10,12
// 2
// 4,6,9,11
assert_8_0: assert property(month_check_property_1)
else
begin
	$display("=========================");
	$display("  Assertion 8 is violated");
    $display("=========================");
	$fatal;
end

assert_8_1: assert property(month_range_check_property)
else
begin
	$display("==========================");
	$display("  Assertion 8 is violated");
    $display("==========================");
	$fatal;
end

assert_8_2: assert property(feb_check_property)
else
begin
	$display("==========================");
	$display("  Assertion 8 is violated");
    $display("==========================");
	$fatal;
end

assert_8_3: assert property(month_check_property_2)
else
begin
	$display("=========================");
	$display("  Assertion 8 is violated");
    $display("=========================");
	$fatal;
end

/*
    9. C_in_valid can only be high for one cycle and can't be pulled high again before C_out_valid
*/
assert_9: assert property(AR_valid_low_property)
else
begin
	$display("=========================");
	$display("  Assertion 9 is violated");
    $display("=========================");
	$fatal;
end



//================================================================
//  Properties
//================================================================
property Index_Check_1_property;
	@(negedge clk) ( (inf.D.d_act[0]==Index_Check) && (inf.sel_action_valid===1) ) |-> ( ##[1:4] inf.formula_valid===1 );
endproperty

property Index_Check_2_property;
	@(posedge clk) ( (cur_act===Index_Check) && (inf.formula_valid===1) ) |-> ( ##[1:4] inf.mode_valid===1 ) ;
endproperty

property Index_Check_3_property;
	@(posedge clk) ( (cur_act===Index_Check) && (inf.mode_valid===1) ) |-> ( ##[1:4] inf.date_valid===1 ) ;
endproperty

property Index_Check_4_property;
	@(posedge clk) ( (cur_act===Index_Check) && (inf.date_valid===1) ) |-> ( ##[1:4] inf.data_no_valid===1 ) ;
endproperty

property Index_Check_5_property;
	@(posedge clk) ( (cur_act===Index_Check) && (inf.data_no_valid===1) ) |-> ( ##[1:4] inf.index_valid===1 ) ;
endproperty



property Update_1_property;
	@(negedge clk) ( (inf.D.d_act[0]==Update) && (inf.sel_action_valid===1) ) |-> ( ##[1:4] inf.date_valid===1 ) ;
endproperty

property Update_2_property;
	@(posedge clk) ( (cur_act===Update) && (inf.date_valid===1) ) |-> ( ##[1:4] inf.data_no_valid===1 ) ;
endproperty

property Update_3_property;
	@(posedge clk) ( (cur_act===Update) && (inf.data_no_valid===1) ) |-> ( ##[1:4] inf.index_valid===1 ) ;
endproperty

property Update_4_property;
	@(posedge clk) ( (cur_act===Update||cur_act===Index_Check) && (inf.index_valid===1) && (cnt!==3)) |-> ( ##[1:4] inf.index_valid===1 ) ;
endproperty


property Check_Valid_Date_1_property;
	 @(negedge clk) ( (inf.D.d_act[0]==Check_Valid_Date) && (inf.sel_action_valid===1) ) |-> ( ##[1:4] inf.date_valid===1 );
endproperty

property Check_Valid_Date_2_property;
	 @(posedge clk) ( (cur_act===Check_Valid_Date) && (inf.date_valid===1) ) |-> ( ##[1:4] inf.data_no_valid===1 ) ;
endproperty
//////////////////////////////////
property latency_violation_property_check_date;
	@(posedge clk) ( (cur_act===Index_Check||cur_act===Update) && (inf.index_valid===1) ) |-> ( ##[1:1000] inf.out_valid===1 );
endproperty

property latency_violation_property_update;
	@(posedge clk) ( (cur_act===Check_Valid_Date) && (inf.data_no_valid===1)  |-> ( ##[1:1000] inf.out_valid===1 ) );
endproperty

property overlap_property;
	@(posedge clk) $onehot({inf.sel_action_valid, inf.formula_valid,inf.mode_valid, inf.date_valid, inf.data_no_valid, inf.index_valid, none}) ;
endproperty

property out_valid_once_property;
	@(posedge clk) (inf.out_valid===1) |=> (inf.out_valid===0) ;
endproperty


property random_gap_property;
	@(posedge clk) (inf.out_valid===1) |-> ##[1:4] (inf.sel_action_valid === 1) ;
endproperty

property month_check_property_1;
	@(posedge clk) ( (inf.date_valid) && (month===1 || month===3 || month===5 || month===7 || month===8 || month===10 || month===12) ) |-> ( day>=1 && day<=31);
endproperty

property month_range_check_property;
	@(posedge clk) (inf.date_valid) |-> ( month >= 1 && month <= 12);
endproperty

property feb_check_property;
	@(posedge clk) ( (inf.date_valid) && (month===2)) |-> (day>=1 && day<=28);
endproperty

property month_check_property_2;
	@(posedge clk) ( (inf.date_valid) && (month===4 || month===6 || month===9 || month===11)) |-> (day>=1 && day<=30);
endproperty



property AR_valid_low_property;
	@(posedge clk) !(inf.AR_VALID && inf.AW_VALID);
endproperty

property action_complete_check_property;
	@(negedge clk) ( (inf.complete === 1) |-> (inf.warn_msg === No_Warn) );
endproperty

endmodule