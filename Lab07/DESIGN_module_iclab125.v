module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
	in_row,
    in_kernel,
    out_idle,
    handshake_sready,
    handshake_din,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

	fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    out_data,

    flag_clk1_to_fifo,
    flag_fifo_to_clk1
);
input clk;
input rst_n;
input in_valid;
input [17:0] in_row;
input [11:0] in_kernel;
input out_idle;
output reg handshake_sready;
output reg [29:0] handshake_din;
// You can use the the custom flag ports for your design
input  flag_handshake_to_clk1;
output flag_clk1_to_handshake;

input fifo_empty;
input [7:0] fifo_rdata;
output fifo_rinc;
output reg out_valid;
output reg [7:0] out_data;
// You can use the the custom flag ports for your design
output flag_clk1_to_fifo;
input flag_fifo_to_clk1;
reg fifo_empty_q ;
reg fifo_empty_qq;
reg fifo_empty_qqq;
reg fifo_empty_qqqq;

localparam IDLE = 0;
localparam INPUT = 1;
localparam TRANS = 2;
localparam OUTPUT = 3;
reg [2:0] cs_state,ns_state;
reg [2:0] cnt_input;
reg [4:0] cnt_trans;
reg [2:0] element_save [0:35];//18cycle
reg [2:0] kernel_save [0:23];//12cycle
integer i,j;
reg [7:0]cnt_output;
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
                ns_state = INPUT;
            end
            else begin
                ns_state = IDLE;
            end
        end
        INPUT: begin
            if(cnt_input==6) begin
                ns_state = TRANS;
            end
            else begin
                ns_state = INPUT;
            end
        end
        TRANS: begin
            if(cnt_trans==12) begin
                ns_state = OUTPUT;
            end
            else begin
                ns_state = TRANS;
            end
        end
        OUTPUT: begin
            if(cnt_output==149) begin
                ns_state = IDLE;
            end
            else begin
                ns_state = OUTPUT;
            end
        end
        default :begin
            ns_state = IDLE;
        end
    endcase
end
//save data
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_input <= 0; 
    end
    else begin
        if(cs_state==OUTPUT && ns_state==IDLE) begin
            cnt_input <= 0;
        end
        // else if(fifo_empty_qqq==0) begin
        //     cnt_input <= cnt_input+1;
        // end
        else if(in_valid) begin
            cnt_input <= cnt_input + 1;
        end
        else begin
            cnt_input <= cnt_input;
        end
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<=35;i=i+1) begin
            element_save[i] <= 0;
        end
    end
    else begin
        if(cs_state==OUTPUT && ns_state==IDLE) begin
            for(i=0;i<=35;i=i+1) begin
                element_save[i] <= 0;
            end
        end
        else if(in_valid) begin
            case (cnt_input)
                0: begin
                    element_save[0] <= in_row[2:0];
                    element_save[1] <= in_row[5:3];
                    element_save[2] <= in_row[8:6];
                    element_save[3] <= in_row[11:9];
                    element_save[4] <= in_row[14:12];
                    element_save[5] <= in_row[17:15];
                end 
                1: begin
                    element_save[6] <= in_row[2:0];
                    element_save[7] <= in_row[5:3];
                    element_save[8] <= in_row[8:6];
                    element_save[9] <= in_row[11:9];
                    element_save[10] <= in_row[14:12];
                    element_save[11] <= in_row[17:15];
                end 
                2: begin
                    element_save[12] <= in_row[2:0];
                    element_save[13] <= in_row[5:3];
                    element_save[14] <= in_row[8:6];
                    element_save[15] <= in_row[11:9];
                    element_save[16] <= in_row[14:12];
                    element_save[17] <= in_row[17:15];
                end 
                3: begin
                    element_save[18] <= in_row[2:0];
                    element_save[19] <= in_row[5:3];
                    element_save[20] <= in_row[8:6];
                    element_save[21] <= in_row[11:9];
                    element_save[22] <= in_row[14:12];
                    element_save[23] <= in_row[17:15];
                end 
                4: begin
                    element_save[24] <= in_row[2:0];
                    element_save[25] <= in_row[5:3];
                    element_save[26] <= in_row[8:6];
                    element_save[27] <= in_row[11:9];
                    element_save[28] <= in_row[14:12];
                    element_save[29] <= in_row[17:15];
                end 
                5: begin
                    element_save[30] <= in_row[2:0];
                    element_save[31] <= in_row[5:3];
                    element_save[32] <= in_row[8:6];
                    element_save[33] <= in_row[11:9];
                    element_save[34] <= in_row[14:12];
                    element_save[35] <= in_row[17:15];
                end
                default: begin
                    for(i=0;i<=35;i=i+1) begin
                        element_save[i] <= element_save[i];
                    end
                end 
            endcase
        end
        else begin
            for(i=0;i<=35;i=i+1) begin
                element_save[i] <= element_save[i];
            end
        end
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<=23;i=i+1) begin
            kernel_save[i] <= 0;
        end
    end
    else begin
        if(cs_state==OUTPUT && ns_state==IDLE) begin
            for(i=0;i<=23;i=i+1) begin
                kernel_save[i] <= 0;
            end
        end 
        else if(in_valid) begin
            case (cnt_input)
                0: begin
                    kernel_save[0] <= in_kernel[2:0];
                    kernel_save[1] <= in_kernel[5:3];
                    kernel_save[2] <= in_kernel[8:6];
                    kernel_save[3] <= in_kernel[11:9];
                end 
                1: begin
                    kernel_save[4] <= in_kernel[2:0];
                    kernel_save[5] <= in_kernel[5:3];
                    kernel_save[6] <= in_kernel[8:6];
                    kernel_save[7] <= in_kernel[11:9];
                end 
                2: begin
                    kernel_save[8] <= in_kernel[2:0];
                    kernel_save[9] <= in_kernel[5:3];
                    kernel_save[10] <= in_kernel[8:6];
                    kernel_save[11] <= in_kernel[11:9];
                end 
                3: begin
                    kernel_save[12] <= in_kernel[2:0];
                    kernel_save[13] <= in_kernel[5:3];
                    kernel_save[14] <= in_kernel[8:6];
                    kernel_save[15] <= in_kernel[11:9];
                end 
                4: begin
                    kernel_save[16] <= in_kernel[2:0];
                    kernel_save[17] <= in_kernel[5:3];
                    kernel_save[18] <= in_kernel[8:6];
                    kernel_save[19] <= in_kernel[11:9];
                end 
                5: begin
                    kernel_save[20] <= in_kernel[2:0];
                    kernel_save[21] <= in_kernel[5:3];
                    kernel_save[22] <= in_kernel[8:6];
                    kernel_save[23] <= in_kernel[11:9];
                end
                default: begin
                    for(i=0;i<=23;i=i+1) begin
                        kernel_save[i] <= 0;
                    end
                end 
            endcase
        end
        else begin
            for(i=0;i<=23;i=i+1) begin
                kernel_save[i] <= kernel_save[i];
            end
        end
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_trans <= 0;
    end
    else begin
        if(cs_state==IDLE) begin
            cnt_trans <= 0;
        end
        else if(cs_state == TRANS) begin
            if(handshake_sready) begin
                if(cnt_trans<=12) begin
                   cnt_trans <= cnt_trans + 1; 
                end
                else begin
                    cnt_trans <= 0;
                end
            end
        end
        else begin
            cnt_trans <= cnt_trans;
        end
    end
end
//assign handshake_sready = (cnt_trans!=30)?0:out_idle;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        handshake_sready <= 0;
    end
    else begin
        if(cs_state==IDLE) begin
            handshake_sready <= 0;
        end
        else if(cs_state==TRANS) begin
            handshake_sready <= out_idle;
        end
        else begin
            handshake_sready <= 0;
        end
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        handshake_din <= 0;
    end
    else begin
        if(cs_state==IDLE) begin
            handshake_din <= 0;
        end
        else if(cs_state==TRANS) begin
            if(out_idle) begin
                case(cnt_trans)
                0:handshake_din <= {12'b0,element_save[0],element_save[1],element_save[2],element_save[3],element_save[4],element_save[5]};
                1:handshake_din <= {12'b0,element_save[6],element_save[7],element_save[8],element_save[9],element_save[10],element_save[11]};
                2:handshake_din <= {12'b0,element_save[12],element_save[13],element_save[14],element_save[15],element_save[16],element_save[17]};
                3:handshake_din <= {12'b0,element_save[18],element_save[19],element_save[20],element_save[21],element_save[22],element_save[23]};
                4:handshake_din <= {12'b0,element_save[24],element_save[25],element_save[26],element_save[27],element_save[28],element_save[29]};
                5:handshake_din <= {12'b0,element_save[30],element_save[31],element_save[32],element_save[33],element_save[34],element_save[35]};
                6:handshake_din <= {18'b0,kernel_save[0],kernel_save[1],kernel_save[2],kernel_save[3]};
                7:handshake_din <= {18'b0,kernel_save[4],kernel_save[5],kernel_save[6],kernel_save[7]};
                8:handshake_din <= {18'b0,kernel_save[8],kernel_save[9],kernel_save[10],kernel_save[11]};
                9:handshake_din <= {18'b0,kernel_save[12],kernel_save[13],kernel_save[14],kernel_save[15]};
                10:handshake_din <= {18'b0,kernel_save[16],kernel_save[17],kernel_save[18],kernel_save[19]};
                11:handshake_din <= {18'b0,kernel_save[20],kernel_save[21],kernel_save[22],kernel_save[23]};
                default:handshake_din <= 0;
                endcase
            end
            else begin
                handshake_din <= 0;
            end
        end
        else begin
            handshake_din <= 0;
        end
    end
end

//----------------------------
// Read data from FIFO
//----------------------------

//* fifo_rinc
assign fifo_rinc = (~fifo_empty && ~in_valid) ? 1 : 0;
reg fifo_rinc_delay;
always @(posedge clk or negedge rst_n) fifo_rinc_delay <= (~rst_n) ? 1'b0 : fifo_rinc;
//* fifo_empty
always @(posedge clk or negedge rst_n) fifo_empty_q <= (~rst_n) ? 1'b1 : fifo_empty;

//* fifo_empty_qq
always @(posedge clk or negedge rst_n) fifo_empty_qq <= (~rst_n) ? 1'b1 : fifo_empty_q;
always @(posedge clk or negedge rst_n) fifo_empty_qqq <= (~rst_n) ? 1'b1 : fifo_empty_qq;
always @(posedge clk or negedge rst_n) fifo_empty_qqqq <= (~rst_n) ? 1'b1 : fifo_empty_qqq;
//----------------------------
// Output data
//----------------------------
//

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        cnt_output <= 0;
     end 
    else begin
        if(cs_state==OUTPUT&& ns_state==IDLE) begin
            cnt_output <= 0;
        end
        else if(cs_state==OUTPUT && out_valid ) begin
             cnt_output <= cnt_output+1;
            // $display("AA");
        end 
        else begin
            cnt_output<=cnt_output;
        end
    end
end
reg [2:0] out_count;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_count <= 0;
    end
    else begin
        if(cs_state==OUTPUT) begin
            if(out_count==2) begin
                out_count <= 0;
            end
            else if(fifo_rinc) begin
                out_count <= out_count +1;
            end
            else begin
                out_count <= 0;
            end
        end
        else begin
            out_count <= 0;
        end
    end

end
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        out_valid <= 0 ;
     end 
    else begin
        if(cnt_output<=150) begin
            if(fifo_rinc_delay) begin
                out_valid <= 1'b1 ;
            end else begin
                out_valid <= 0 ;
            end
        end
        else begin
            out_valid <= 0 ;
        end
    end
end
// always @(*) begin
   
//         if(1<=cnt_output && cnt_output<=150) begin
//             if(fifo_empty_qqq && ~fifo_empty_qq) begin
//                 out_valid = 1 ;
//             end else begin
//                 out_valid = 0 ;
//             end
//         end
//         else begin
//             out_valid = 0 ;
//         end
  
// end
// always @(posedge clk or negedge rst_n) begin
//     if(~rst_n)begin
//         out_data <= 0 ;
//      end 
//     // else begin
//     //     if(cnt_output<=149) begin
//     //         if(~fifo_empty_qqqq) begin
//     //             out_data <= fifo_rdata ;
//     //         end else begin
//     //             out_data <= 0 ;
//     //         end
//     //     end
//     //     else begin
//     //         out_data <= 0 ;
//     //     end
//     // end
// end
always @(*) begin
    
       
            if(out_valid) begin
                out_data = fifo_rdata ;
            end else begin
                out_data = 0 ;
            end
        
    
end
endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    in_data,
    out_valid,
    out_data,
    busy,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [29:0] in_data;
output reg out_valid;
output reg [7:0] out_data;
output reg busy;

// You can use the the custom flag ports for your design
input  flag_handshake_to_clk2;
output flag_clk2_to_handshake;

input  flag_fifo_to_clk2;
output flag_clk2_to_fifo;
reg [2:0] element_save_d [0:5][0:5];//18cycle
reg [2:0] kernel_save_d [0:5][0:3];//12cycle
reg [3:0] cnt_input_d;
integer i,j;
reg in_valid_reg;
localparam IDLE = 0;
localparam INPUT = 1;
localparam OUTPUT = 2;
reg [2:0] cs_state,ns_state;
reg [5:0] ns_element[0:3];
reg [5:0] cs_element[0:3];
reg [5:0] x_count;
reg [5:0] y_count;
reg [5:0] ker_count;
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
                ns_state = INPUT;
            end
            else begin
                ns_state = IDLE;
            end
        end
        INPUT: begin
            if(cnt_input_d==12) begin
                ns_state = OUTPUT;
            end
            else begin
                ns_state = INPUT;
            end
        end
        OUTPUT: begin
            if(x_count==4 && y_count==4 && ker_count==5 && (!fifo_full)) begin
                ns_state = IDLE;
            end
            else begin
                ns_state = OUTPUT;
            end
        end
        default: begin
            ns_state = IDLE;
        end
    endcase
end
always@(posedge clk ) begin
    in_valid_reg <= in_valid;
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_input_d <= 0;
    end
    else begin
        if(cs_state==OUTPUT && ns_state ==IDLE) begin
            cnt_input_d <= 0;
        end
        else if(in_valid&&!in_valid_reg) begin
            if(cnt_input_d==12) begin
                cnt_input_d <= 0;
            end
            else begin
                cnt_input_d <= cnt_input_d + 1;
            end
        end
        // else if(!fifo_full) begin
        //     if(cnt_input_d==149) begin
        //         cnt_input_d <= 0;
        //     end
        //     else begin
        //         cnt_input_d <= cnt_input_d + 1;
        //     end
        // end
        else begin
            cnt_input_d <= cnt_input_d;
        end
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<=5;i=i+1) begin
            for(j=0;j<=5;j=j+1) begin
                element_save_d[i][j] <= 0;
            end
        end
    end
    else begin
        if(cs_state==OUTPUT && ns_state == IDLE) begin
            for(i=0;i<=5;i=i+1) begin
                for(j=0;j<=5;j=j+1) begin
                    element_save_d[i][j] <= 0;
                end
            end
        end
        else if(cs_state==INPUT||in_valid) begin
            // for(i=cnt_input_d;i<=5;i=i+1) begin 
                element_save_d[cnt_input_d][0] <= in_data[17:15];
                element_save_d[cnt_input_d][1] <= in_data[14:12];
                element_save_d[cnt_input_d][2] <= in_data[11:9];
                element_save_d[cnt_input_d][3] <= in_data[8:6];
                element_save_d[cnt_input_d][4] <= in_data[5:3];
                element_save_d[cnt_input_d][5] <= in_data[2:0];
            // end
        end
        else begin
            for(i=0;i<=5;i=i+1) begin
                for(j=0;j<=5;j=j+1) begin
                    element_save_d[i][j] <= element_save_d[i][j];
                end
            end
        end
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<=5;i=i+1) begin
            for(j=0;j<=3;j=j+1) begin
                kernel_save_d[i][j] <= 0;
            end
        end
    end
    else begin
        if(cs_state==OUTPUT && ns_state==IDLE) begin
            for(i=0;i<=5;i=i+1) begin
                for(j=0;j<=3;j=j+1) begin
                    kernel_save_d[i][j] <= 0;
                end
            end
        end
        else if(in_valid) begin
            // for(i=cnt_input_d-6;i<=5;i=i+1) begin 
            if(cnt_input_d>=6) begin
                kernel_save_d[cnt_input_d-6][0] <= in_data[11:9];
                kernel_save_d[cnt_input_d-6][1] <= in_data[8:6];
                kernel_save_d[cnt_input_d-6][2] <= in_data[5:3];
                kernel_save_d[cnt_input_d-6][3] <= in_data[2:0];
            end
        end
        else begin
            for(i=0;i<=5;i=i+1) begin
                for(j=0;j<=3;j=j+1) begin
                    kernel_save_d[i][j] <= kernel_save_d[i][j];
                end
            end
        end
    end
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        x_count <= 0;
    end
    else begin
        if(cs_state==OUTPUT ) begin
            if(!fifo_full) begin
                if(x_count==4 && y_count==4 && ker_count==5) begin
                    x_count <= 0;
                end
                else if(x_count==4) begin
                    x_count <= 0;
                end
                else begin
                    x_count <= x_count + 1;
                end
            end
            else begin
                x_count <= x_count;
            end
        end
        else begin
            x_count <= 0;
        end
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        y_count <= 0;
    end
    else begin
        if(cs_state==OUTPUT ) begin
            if(!fifo_full) begin
                if(x_count==4 && y_count==4 && ker_count==5) begin
                    y_count <= 0;
                end
                else if(x_count==4 && y_count==4) begin
                    y_count <= 0;
                end
                else if(x_count==4)begin
                    y_count <= y_count + 1;
                end
                else begin
                    y_count <= y_count;
                end
            end
            else begin
                y_count <= y_count;
            end
        end
        else begin
            y_count <= 0;
        end
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ker_count <= 0;
    end
    else begin
        if(cs_state==OUTPUT ) begin
            if(!fifo_full) begin
                if(x_count==4 && y_count==4 && ker_count==5) begin
                    ker_count <= 0;
                end
                /* else if(ker_count==5 &&x_count==4 && y_count==4)begin
                    ker_count <= 6;
                end */
                else if(x_count==4 && y_count==4) begin
                    ker_count <= ker_count+1;
                end
                else begin
                    ker_count <= ker_count;
                end
            end
            else begin
                ker_count <= ker_count;
            end
        end
        else begin
            ker_count <= 0;
        end
    end
end
always @(*) begin
    /* if(cs_state==OUTPUT && ns_state==IDLE) begin
        ns_element[0]  = 0;
        ns_element[1]  = 0;
        ns_element[2]  = 0;
        ns_element[3]  = 0;
    end
    else  */if(cs_state==OUTPUT) begin
        if(!fifo_full) begin
            ns_element[0]  = element_save_d[y_count][x_count]*kernel_save_d[ker_count][0];
            ns_element[1]  = element_save_d[y_count][x_count+1]*kernel_save_d[ker_count][1];
            ns_element[2]  = element_save_d[y_count+1][x_count]*kernel_save_d[ker_count][2];
            ns_element[3]  = element_save_d[y_count+1][x_count+1]*kernel_save_d[ker_count][3];
        end    
        else begin
            ns_element[0]  = cs_element[0];
            ns_element[1]  = cs_element[1];
            ns_element[2]  = cs_element[2];
            ns_element[3]  = cs_element[3];
        end
    end
    else begin
        ns_element[0]  = 0;
        ns_element[1]  = 0;
        ns_element[2]  = 0;
        ns_element[3]  = 0;
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<=3;i=i+1) begin
            cs_element[i] <= 0;
        end
    end
    else begin
        for(i=0;i<=3;i=i+1) begin
            cs_element[i] <= ns_element[i];
        end
    end
end
reg [7:0] ns_add;
reg fifo_full_reg;
always@(posedge clk ) begin
    fifo_full_reg <= fifo_full;
end
always @(*) begin
    if(!fifo_full) begin
        ns_add = cs_element[0]+cs_element[1]+cs_element[2]+cs_element[3];
    end
    else begin
        ns_add = out_data;
    end
end
// always@(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         out_data <= 0;
//     end
//     // else begin
//     //     if(cs_state==OUTPUT ) begin
//     //         if(!fifo_full) begin
//     //             out_data <= ns_add;
//     //         end
//     //         else begin
//     //             out_data <= out_data;
//     //         end
//     //     end
//     //     else begin
//     //         out_data <= 0;
//     //     end
//     // end
// end
always@(*) begin
    
        if(cs_state==OUTPUT ) begin
            if(!fifo_full) begin
                out_data = ns_element[0]+ns_element[1]+ns_element[2]+ns_element[3];
            end
            else begin
                out_data = 0;
            end
        end
        else begin
            out_data = 0;
        end
    
end
// always@(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         out_valid <= 0;
//     end
//     // else begin
//     //     if(cs_state==OUTPUT ) begin
//     //         if(!fifo_full) begin
//     //             out_valid <= 1;
//     //         end
//     //         else begin
//     //             out_valid <= 0;
//     //         end
//     //     end
//     //     else begin
//     //         out_valid <= 0;
//     //     end
//     // end
// end
always@(*) begin
    if(cs_state==OUTPUT ) begin
        if(!fifo_full) begin
            out_valid = 1;
        end
        else begin
            out_valid = 0;
        end
    end
    else begin
        out_valid = 0;
    end
    
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        busy <= 0;
    end
    else begin
        busy <=(fifo_full)?1: 0;
    end
end
endmodule