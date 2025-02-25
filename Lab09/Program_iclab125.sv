module Program(input clk, INF.Program_inf inf);
import usertype::*;
Action save_action;
Formula_Type save_formula;
Mode save_mode;
Data_No save_dram_no;
Date date_ff;
logic today_date_earlier;
logic [11:0] index_A_ff,index_B_ff,index_C_ff,index_D_ff;
Data_Dir dram_data_ff;
logic [12:0] index_A_amt,index_B_amt,index_C_amt,index_D_amt;
logic index_A_f,index_B_f,index_C_f,index_D_f;
logic index_A_0_f,index_B_0_f,index_C_0_f,index_D_0_f;
logic index_0_f;
logic index_f;
Data_Dir data_ff;
logic dram_A_larger,dram_B_larger,dram_C_larger,dram_D_larger;
logic A_exceed,B_exceed,C_exceed,D_exceed;
logic [13:0] R;
logic [12:0] array[4];
logic [12:0] array_m[4];
logic threshold_f;
logic R_VALID_save;
logic [2:0] index_cnt;
logic save_complete;
logic dram_enable;
DRAM_State current_state;
DRAM_State next_state;

logic [63:0] write_data;
logic [7:0] write_addr;
logic [7:0] read_addr;
logic threshold_ff;
logic today_date_earlier_ff;
logic [12:0] minus_result_1,minus_result_2,minus_result_3,minus_result_4;
logic [12:0] minus_result_1_abs,minus_result_2_abs,minus_result_3_abs,minus_result_4_abs;
///
//======================FSM======================//
State cs_state;
State ns_state; 
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		cs_state <= S_IDLE;
	else
		cs_state <= ns_state;
end

always_comb begin
    case(cs_state)
    S_IDLE:
    begin
        if(inf.sel_action_valid)
            case(inf.D.d_act[0])
                Index_Check: ns_state = S_CHECK_INDEX_READ;
                Update: ns_state = S_UPDATE_READ;
                Check_Valid_Date: ns_state = S_CHECK_VALID_DATE_READ;
                default: ns_state = S_IDLE;
            endcase
        else
            ns_state = S_IDLE;
    end
	S_CHECK_INDEX_READ: 
    begin   
        if(R_VALID_save && index_cnt==4) begin 
            ns_state = S_CHECK_INDEX_CAL;
        end
        else begin
            ns_state = S_CHECK_INDEX_READ;
        end
    end
    S_CHECK_INDEX_CAL:  
    begin
        ns_state = S_OUT;
    end
    S_UPDATE_READ: 
    begin
        if(R_VALID_save && index_cnt==4) begin
            ns_state = S_UPDATE_CAL;
        end
        else begin
            ns_state = S_UPDATE_READ;
        end
    end
    S_UPDATE_CAL:
    begin
        //if(finish_cal) begin//////////////////////
            ns_state = S_WRITE_UPDATE;
        // end
        // else begin
        //     ns_state = S_UPDATE_CAL;
        // end
    end
    S_WRITE_UPDATE: begin
        ns_state = S_WRITE_UPDATE_WAIT;
    end
    S_WRITE_UPDATE_WAIT: begin
        if(inf.B_VALID) begin
            ns_state = S_OUT;
        end
        else begin
            ns_state = S_WRITE_UPDATE_WAIT;
        end
    end
    S_CHECK_VALID_DATE_READ: begin
        if(R_VALID_save ) begin
            ns_state = S_CHECK_VALID_DATE_CAL;
        end
        else begin
            ns_state = S_CHECK_VALID_DATE_READ;
        end
    end
    S_CHECK_VALID_DATE_CAL:
    begin
        //ns_state = S_CHECK_VALID_DATE_WAIT;
        ns_state = S_OUT;
    end
    // S_CHECK_VALID_DATE_WAIT:    
    // begin
    //     ns_state = S_OUT;
    // end
	S_OUT: 
    begin
        ns_state = S_IDLE;
    end
    default: begin
        ns_state = S_IDLE;
    end
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        index_cnt <= 0;
    end
    else if(ns_state == S_IDLE) begin
        index_cnt <= 0;
    end 
    else if(cs_state == S_CHECK_INDEX_READ || cs_state == S_UPDATE_READ ) begin
        if(inf.index_valid) begin
            if(index_cnt == 4) begin
                index_cnt <= 0;
            end
            else begin
                index_cnt <= index_cnt + 1;
            end
        end
    end
    else begin
        index_cnt <= 0;
    end
end
//======================OUTPUT SIGNAL RAISE======================//
Warn_Msg save_warn;
// No_Warn       		= 2'b00, 
// Date_Warn           = 2'b01, 
// Risk_Warn           = 2'b10,
// Data_Warn	        = 2'b11 
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        save_warn <= No_Warn;
    end
    else begin
       case(cs_state)
        S_IDLE: begin
            save_warn <= No_Warn;
        end
        S_CHECK_INDEX_CAL: begin
            if(today_date_earlier)
                save_warn <= Date_Warn;
            else if(threshold_f)
                save_warn <= Risk_Warn;
            else
                save_warn <= save_warn;
        end
        S_WRITE_UPDATE_WAIT: begin
            if(index_f || index_0_f) begin
                save_warn <= Data_Warn;
            end
            else begin
                save_warn <= save_warn;
            end
        end
        S_CHECK_VALID_DATE_CAL: begin
            if(today_date_earlier)
                save_warn <= Date_Warn;
            else
                save_warn <= No_Warn;
        end
        default: begin save_warn <= save_warn; end
        endcase
    end
end


//===============SAVE INPUT================///


always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)
        save_action <= 0;
    else
    begin
        if(inf.sel_action_valid)
            save_action <= inf.D.d_act[0];
        else
            save_action <= save_action;
    end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        save_formula <= 0;
    end
    else
    begin
        if(inf.formula_valid)
            save_formula <= inf.D.d_formula[0];
        else
            save_formula <= save_formula;
    end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)
        save_mode <= 0;
    else if(inf.mode_valid)
        save_mode <= inf.D.d_mode[0];
    else
        save_mode <= save_mode;
end
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)
        save_dram_no <= 0;
    else if(inf.data_no_valid)
        save_dram_no <= inf.D.d_data_no[0];
    else
        save_dram_no <= save_dram_no;
end
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        date_ff <= 0;
    end
    else begin
        if(inf.date_valid) begin
            date_ff <= inf.D.d_date[0];
        end
        else begin
            date_ff <= date_ff;
        end
    end
end

// always_ff @(posedge clk or negedge inf.rst_n) begin
//     if(!inf.rst_n) begin
//         today_date_earlier <= 0;
//     end
//     else begin
//         if(ns_state == S_IDLE) begin
//             today_date_earlier <= 0;
//         end
//        // else if((cs_state == S_CHECK_INDEX_READ||cs_state == S_CHECK_VALID_DATE_READ)&&R_VALID_save) begin
//         else if(cs_state == S_CHECK_INDEX_CAL||cs_state == S_CHECK_VALID_DATE_CAL) begin
//             if((dram_data_ff.M > date_ff.M) || (dram_data_ff.M == date_ff.M && dram_data_ff.D > date_ff.D))
//                 today_date_earlier <= 1;
//             else 
//                 today_date_earlier <= 0;
//         end
//         else begin
//             today_date_earlier <= today_date_earlier;
//         end
//     end
// end
assign today_date_earlier = ((cs_state == S_CHECK_VALID_DATE_CAL||cs_state == S_CHECK_INDEX_CAL)&&((dram_data_ff.M > date_ff.M) || (dram_data_ff.M == date_ff.M && dram_data_ff.D > date_ff.D)));
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		today_date_earlier_ff <= 0;
	else if(cs_state == S_OUT)
		today_date_earlier_ff <= 0;
    else if(today_date_earlier) begin
        today_date_earlier_ff <= 1;
    end
	else
		today_date_earlier_ff <= 0;
end

always_ff @(posedge clk) begin
	if(inf.index_valid) begin
		case(index_cnt)
            0: index_A_ff <= inf.D.d_index[0];
            1: index_B_ff <= inf.D.d_index[0];
            2: index_C_ff <= inf.D.d_index[0];
            3: index_D_ff <= inf.D.d_index[0];
        endcase
    end 
end
always_comb
begin
    if(cs_state == S_UPDATE_CAL) begin
        index_A_amt = (index_A_ff[11])?({index_A_ff[11],index_A_ff} + dram_data_ff.Index_A):(index_A_ff + dram_data_ff.Index_A);
        index_B_amt = (index_B_ff[11])?({index_B_ff[11],index_B_ff} + dram_data_ff.Index_B):(index_B_ff + dram_data_ff.Index_B);
        index_C_amt = (index_C_ff[11])?({index_C_ff[11],index_C_ff} + dram_data_ff.Index_C):(index_C_ff + dram_data_ff.Index_C);
        index_D_amt = (index_D_ff[11])?({index_D_ff[11],index_D_ff} + dram_data_ff.Index_D):(index_D_ff + dram_data_ff.Index_D);
    end
    else begin
        index_A_amt = 0;
        index_B_amt = 0;
        index_C_amt = 0;
        index_D_amt = 0;
    end
end


assign index_A_f  =(cs_state == S_UPDATE_CAL && index_A_ff[11]==0 && index_A_amt[12]==1)?1:0;
assign index_B_f  =(cs_state == S_UPDATE_CAL && index_B_ff[11]==0 && index_B_amt[12]==1)?1:0;
assign index_C_f  =(cs_state == S_UPDATE_CAL && index_C_ff[11]==0 && index_C_amt[12]==1)?1:0;
assign index_D_f  =(cs_state == S_UPDATE_CAL && index_D_ff[11]==0 && index_D_amt[12]==1)?1:0;

assign index_A_0_f = (cs_state == S_UPDATE_CAL && index_A_ff[11]==1 && index_A_amt[12]==1)?1:0;
assign index_B_0_f = (cs_state == S_UPDATE_CAL && index_B_ff[11]==1 && index_B_amt[12]==1)?1:0;
assign index_C_0_f = (cs_state == S_UPDATE_CAL && index_C_ff[11]==1 && index_C_amt[12]==1)?1:0;
assign index_D_0_f = (cs_state == S_UPDATE_CAL && index_D_ff[11]==1 && index_D_amt[12]==1)?1:0;

always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        index_0_f <= 0;
        index_f <= 0;
    end
    else begin
        if(ns_state == S_IDLE) begin
            index_0_f <= 0;
            index_f <= 0;
        end
        else if(cs_state == S_UPDATE_CAL) begin
        //else if(cs_state == S_UPDATE_CAL) begin
            index_0_f <= index_A_0_f || index_B_0_f || index_C_0_f || index_D_0_f;
            index_f  <= index_A_f||index_B_f||index_C_f||index_D_f;
        end
        else begin
            index_0_f <= index_0_f;
            index_f <= index_f;
        end
    end
end


always_ff @( posedge clk )
begin
    if(inf.R_VALID)begin//read from dram 
        dram_data_ff.Index_A <= inf.R_DATA[63:52];
        dram_data_ff.Index_B <= inf.R_DATA[51:40];
        dram_data_ff.Index_C <= inf.R_DATA[31:20];
        dram_data_ff.Index_D <= inf.R_DATA[19:8];
        dram_data_ff.M <= inf.R_DATA[39:32];
        dram_data_ff.D <= inf.R_DATA[7:0];
    end
    else if(cs_state == S_UPDATE_CAL) begin
        if(index_A_ff[11]==0) begin
            if(index_A_amt[12]) begin
                dram_data_ff.Index_A <= 4095;
            end
            else begin
                dram_data_ff.Index_A <= index_A_amt;
            end
        end
        else begin
            if(index_A_amt[12]) begin
                dram_data_ff.Index_A <= 0;
            end
            else begin
                dram_data_ff.Index_A <= index_A_amt;
            end
        end
        if(index_B_ff[11]==0) begin
            if(index_B_amt[12]) begin
                dram_data_ff.Index_B <= 4095;
            end
            else begin
                dram_data_ff.Index_B <= index_B_amt;
            end
        end
        else begin
            if(index_B_amt[12]) begin
                dram_data_ff.Index_B <= 0;
            end
            else begin
                dram_data_ff.Index_B <= index_B_amt;
            end
        end
        if(index_C_ff[11]==0) begin
            if(index_C_amt[12]) begin
                dram_data_ff.Index_C <= 4095;
            end
            else begin
                dram_data_ff.Index_C <= index_C_amt;
            end
        end
        else begin
            if(index_C_amt[12]) begin
                dram_data_ff.Index_C <= 0;
            end
            else begin
                dram_data_ff.Index_C <= index_C_amt;
            end
        end
        if(index_D_ff[11]==0) begin
            if(index_D_amt[12]) begin
                dram_data_ff.Index_D <= 4095;
            end
            else begin
                dram_data_ff.Index_D <= index_D_amt;
            end
        end
        else begin
            if(index_D_amt[12]) begin
                dram_data_ff.Index_D <= 0;
            end
            else begin
                dram_data_ff.Index_D <= index_D_amt;
            end
        end
    end
    else begin
        dram_data_ff <= dram_data_ff;
    end
    
end


assign dram_A_larger = (dram_data_ff.Index_A >= index_A_ff)?1:0;
assign dram_B_larger = (dram_data_ff.Index_B >= index_B_ff)?1:0;
assign dram_C_larger = (dram_data_ff.Index_C >= index_C_ff)?1:0;
assign dram_D_larger = (dram_data_ff.Index_D >= index_D_ff)?1:0;

assign A_exceed = (dram_data_ff.Index_A[11])?1:0;
assign B_exceed = (dram_data_ff.Index_B[11])?1:0;
assign C_exceed = (dram_data_ff.Index_C[11])?1:0;
assign D_exceed = (dram_data_ff.Index_D[11])?1:0;

always_comb begin
    if(cs_state==S_CHECK_INDEX_CAL) begin
    case(save_formula)
        Formula_A: begin
            R = (dram_data_ff.Index_A + dram_data_ff.Index_B + dram_data_ff.Index_C+ dram_data_ff.Index_D)>>2;
        end
        Formula_B: begin
            R = array[3] - array[0];
        end
        Formula_C: begin
            R = array[0];
        end
        Formula_D: begin
            R = A_exceed + B_exceed + C_exceed + D_exceed;
        end
        Formula_E: begin
            R = dram_A_larger + dram_B_larger + dram_C_larger + dram_D_larger;
        end
        Formula_F: begin
            R = (array_m[0] + array_m[1] + array_m[2])/3;
        end
        Formula_G: begin
            R = (array_m[0]>>1) + (array_m[1]>>2) + (array_m[2]>>2);
        end
        Formula_H: begin
            R = (array_m[0] + array_m[1] + array_m[2] + array_m[3])>>2;
        end
        default: begin
            R = 0;
        end

    endcase
    end
    else begin
        R = 0;
    end
end

sort_four four_1(.a({1'b0,dram_data_ff.Index_A}),.b({1'b0,dram_data_ff.Index_B}),.c({1'b0,dram_data_ff.Index_C}),.d({1'b0,dram_data_ff.Index_D}),.one(array[3]),.two(array[2]),.three(array[1]),.four(array[0]));
sort_four four_2(.a(minus_result_1_abs),.b(minus_result_2_abs),.c(minus_result_3_abs),.d(minus_result_4_abs),.one(array_m[3]),.two(array_m[2]),.three(array_m[1]),.four(array_m[0]));

always_comb begin
    minus_result_1 = dram_data_ff.Index_A - index_A_ff;
    minus_result_2 = dram_data_ff.Index_B - index_B_ff;
    minus_result_3 = dram_data_ff.Index_C - index_C_ff;
    minus_result_4 = dram_data_ff.Index_D - index_D_ff;
end
always_comb begin
    minus_result_1_abs = (minus_result_1[12])?{~minus_result_1+1'b1}:minus_result_1;
    minus_result_2_abs = (minus_result_2[12])?{~minus_result_2+1'b1}:minus_result_2;
    minus_result_3_abs = (minus_result_3[12])?{~minus_result_3+1'b1}:minus_result_3;
    minus_result_4_abs = (minus_result_4[12])?{~minus_result_4+1'b1}:minus_result_4;
end

always_comb begin
    if(cs_state == S_CHECK_INDEX_CAL) begin
    case(save_formula)
        Formula_A,Formula_C: begin
            case(save_mode)
                Insensitive: begin 
                    threshold_f = (R[11]||&R[10:0])?1:0;//exceed2047
                end
                Normal: begin
                   // threshold_f = (R[11]||R[10]||&R[9:0])?1:0;//exceed1023
                    threshold_f = (R>=1023)?1:0;//exceed1023
                end
                Sensitive: begin
                    threshold_f = (R>=511)?1:0;//exceed511
                end
                default: begin
                    threshold_f = 0;
                end
            endcase
        end
        Formula_D,Formula_E: begin
            case(save_mode)
                Insensitive: begin 
                    threshold_f = (R>=3)?1:0;
                end
                Normal: begin
                    threshold_f = (R>=2)?1:0;
                end
                Sensitive: begin
                    threshold_f = (R>=1)?1:0;
                end
                default: begin
                    threshold_f = 0;
                end
            endcase
        end
        Formula_B,Formula_F,Formula_G,Formula_H: begin
            case(save_mode)
                Insensitive: begin 
                    threshold_f = (R>=800)?1:0;
                end
                Normal: begin
                    threshold_f = (R>=400)?1:0;
                end
                Sensitive: begin
                    threshold_f = (R>=200)?1:0;
                end
                default: begin
                    threshold_f = 0;
                end
            endcase
        end
        default: begin 
            threshold_f = 0;
        end
    endcase
    end
    else begin
        threshold_f = 0;
    end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		threshold_ff <= 0;
	else if(cs_state == S_OUT)
		threshold_ff <= 0;
    else if(threshold_f) begin
        threshold_ff <= 1;
    end
	else
		threshold_ff <= 0;
end
//======================OUTPUT======================//
//out_valid, err_msg,  complete, out_info, 
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.out_valid <= 0;
	else if(ns_state == S_OUT)
		inf.out_valid <= 1;
	else
		inf.out_valid <= 0;
end

always_comb  begin
	// if(!inf.rst_n)
	// 	inf.warn_msg <= No_Warn;
	// else 
    if(cs_state == S_OUT)
		inf.warn_msg = save_warn;
	else
		inf.warn_msg = No_Warn;
end
// always_ff @(posedge clk or negedge inf.rst_n) begin
//     if(!inf.rst_n) begin
//         save_complete <= 0;
//     end
//     else begin
//         case(cs_state)
//         // S_IDLE: begin
//         //     save_complete <= 0;
//         // end
//         S_CHECK_INDEX_CAL: begin
//             if(!today_date_earlier && !threshold_f)
//                  save_complete <= 1;
//             else
//                 save_complete <= 1;
//         end
//         S_WRITE_UPDATE_WAIT: begin
//             if(!index_f && !index_0_f) begin
//                 save_complete <= 1;
//             end
//             else begin
//                 save_complete <= save_complete;
//             end
//         end
//         S_CHECK_VALID_DATE_CAL: begin
//             if(!today_date_earlier) begin
//                 save_complete <= 1;
//             end
//             else
//                 save_complete <= 1;
//         end
//         default: begin save_complete <= 1; end
//         endcase
        // if(cs_state == S_UPDATE_CAL) begin
        //     if(index_f==0 && index_0_f==0)
        //         save_complete <= 1;
        //     else
        //         save_complete <= save_complete;
        // end
        // else if(cs_state == S_CHECK_VALID_DATE_CAL) begin
        //     if(today_date_earlier==0) begin
        //         save_complete <= 1;
        //     end
        //     else begin
        //         save_complete <= save_complete;
        //     end
        // end
        // else begin
        //     save_complete <= save_complete;
//         // end
//     end
// end
always_comb begin
	// if(!inf.rst_n)
	// 	inf.complete <= 0;
	// else 
    if(cs_state == S_OUT)
		//inf.complete = save_complete;
        inf.complete = (!today_date_earlier_ff && !threshold_ff && !index_f && !index_0_f)?1:0;
	else
		inf.complete = 0;
end
// endmodule
// module bridge(input clk, INF.Program_inf inf);

// // parameters




assign inf.R_READY  = (current_state == S_READ_WAIT);
assign inf.AR_ADDR  = (current_state == S_READ_REQUEST) ? {6'b1_0000_0, read_addr, 3'b000} : 0;
assign inf.AR_VALID = (current_state == S_READ_REQUEST);
// write assign
assign inf.AW_ADDR  = (current_state == S_WRITE_REQUEST) ? {6'b1_0000_0, write_addr, 3'b000} : 0;
assign inf.AW_VALID = (current_state == S_WRITE_REQUEST);
assign inf.W_DATA   = (current_state == S_WRITE_SEND) ? write_data : 0;
assign inf.W_VALID  = (current_state == S_WRITE_SEND);
assign inf.B_READY  = (current_state == S_WRITE_WAIT);

always_comb begin
	if(current_state==S_CHECK_INDEX_READ || current_state == S_UPDATE_READ || current_state == S_CHECK_VALID_DATE_READ) begin
        read_addr = save_dram_no;
    end
    else begin
        read_addr = 0;
    end
end


logic write_enable;
assign write_enable = (cs_state == S_WRITE_UPDATE) || (cs_state == S_WRITE_UPDATE_WAIT);

always_comb begin
	if(cs_state == S_WRITE_UPDATE || cs_state ==S_WRITE_UPDATE_WAIT) begin
        write_addr = save_dram_no;
    end
    else begin
        write_addr = 0;
    end
end

always_comb begin
	if(current_state==S_WRITE_SEND) begin
        write_data = {dram_data_ff.Index_A,dram_data_ff.Index_B,4'b0000,date_ff.M,dram_data_ff.Index_C,dram_data_ff.Index_D,3'b000,date_ff.D};
    end
    else begin
        write_data = 0;
    end
end

assign dram_enable = ((cs_state == S_UPDATE_READ  && inf.data_no_valid)|| (cs_state == S_CHECK_INDEX_READ && inf.data_no_valid)|| (cs_state == S_CHECK_VALID_DATE_READ && inf.data_no_valid)|| cs_state == S_WRITE_UPDATE ||cs_state == S_WRITE_UPDATE_WAIT);


always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		current_state <= S_DRAM_IDLE;
	else
		current_state <= next_state;
end

always_comb begin
	case(current_state)
	S_DRAM_IDLE:
		if(dram_enable && !write_enable )
			next_state = S_READ_REQUEST;
		else if(dram_enable && write_enable)
			next_state = S_WRITE_REQUEST;
		else
			next_state = S_DRAM_IDLE;
	S_READ_REQUEST:
		if(inf.AR_READY)
			next_state = S_READ_WAIT;
		else
			next_state = S_READ_REQUEST;
	S_READ_WAIT:
		if(inf.R_VALID)
			next_state = S_DRAM_OUT;
		else
			next_state = S_READ_WAIT;
	S_WRITE_REQUEST:
		if(inf.AW_READY)
			next_state = S_WRITE_SEND;
		else
			next_state = S_WRITE_REQUEST;
	S_WRITE_SEND:
		if(inf.W_READY)
			next_state = S_WRITE_WAIT;
		else
			next_state = S_WRITE_SEND;
	S_WRITE_WAIT:
		if(inf.B_VALID)
			next_state = S_DRAM_OUT;
		else
			next_state = S_WRITE_WAIT;
	S_DRAM_OUT:
		next_state = S_DRAM_IDLE;
	default: next_state = S_DRAM_IDLE;
	endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin//read?
	if(!inf.rst_n) begin
		R_VALID_save <= 0;
    end
    else if(cs_state == S_OUT) begin
        R_VALID_save <= 0;
    end
	else if(current_state == S_READ_WAIT && next_state == S_DRAM_OUT) begin
		R_VALID_save <= 1;
    end
    else begin
        R_VALID_save <= R_VALID_save;
    end
end



endmodule


module sort_four(a,b,c,d,one,two,three,four);
    input logic [12:0] a,b,c,d;
    output logic [12:0] one,two,three,four;
    logic [12:0] value [0:3];
    logic [12:0] value_a [0:3];
    logic [12:0] value_b [0:3];
    logic [12:0] value_c[0:1];
    assign value[0] = a;
    assign value[1] = b;
    assign value[2] = c;
    assign value[3] = d;

    assign value_a[0] = (value[0]>value[2])?value[0]:value[2];
    assign value_a[2] = (value[0]>value[2])?value[2]:value[0];
    assign value_a[1] = (value[1]>value[3])?value[1]:value[3];
    assign value_a[3] = (value[1]>value[3])?value[3]:value[1];

    assign value_b[0] = (value_a[0]>value_a[1])?value_a[0]:value_a[1];
    assign value_b[1] = (value_a[0]>value_a[1])?value_a[1]:value_a[0];
    assign value_b[2] = (value_a[2]>value_a[3])?value_a[2]:value_a[3];
    assign value_b[3] = (value_a[2]>value_a[3])?value_a[3]:value_a[2];

    assign value_c[0] = (value_b[1]>value_b[2])?value_b[1]:value_b[2];
    assign value_c[1] = (value_b[1]>value_b[2])?value_b[2]:value_b[1];

    assign one = value_b[0];
    assign two = value_c[0];
    assign three = value_c[1];
    assign four = value_b[3];

endmodule