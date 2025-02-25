module FIFO_syn #(parameter WIDTH=8, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo,

    flag_fifo_to_clk1,
	flag_clk1_to_fifo
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
output  flag_fifo_to_clk2;
input flag_clk2_to_fifo;

output flag_fifo_to_clk1;
input flag_clk1_to_fifo;

wire [WIDTH-1:0] rdata_q;
reg [WIDTH-1:0] n_rdata;
// Remember: 
//   wptr and rptr should be gray coded
//   Don't modify the signal name


reg [$clog2(WORDS):0] wptr;
reg [$clog2(WORDS):0] rptr;


// pointer

wire [$clog2(WORDS):0] rptr_q;
wire [$clog2(WORDS):0] wptr_q;
reg  [$clog2(WORDS):0] rptr_q_2;
reg  [$clog2(WORDS):0] wptr_q_2;

wire write_enable;
wire w_enA;


wire read_enable;


wire [6:0]w_addr_q;
wire [6:0]r_addr_q;

reg  [6:0]w_addr;
reg  [6:0]r_addr;


assign write_enable = winc && !wfull;
assign w_enA = !write_enable;
assign w_addr_q = w_addr + write_enable;
assign wptr_q = (w_addr_q >> 1) ^ w_addr_q;
// initial begin
//     $display(w_addr_q>>1);
// end

always@(posedge wclk or negedge rst_n) begin
    if (!rst_n) begin
        w_addr <= 0;
    end
    else begin
        w_addr <= w_addr_q;
    end
end

always@(posedge wclk or negedge rst_n) begin
    if (!rst_n) begin
        wptr <= 0;
    end
    else begin
        wptr <= wptr_q;//gray code to binary
    end
end
reg n_wfull;
always@(*) begin
    if(({~rptr_q_2[6],~rptr_q_2[5],rptr_q_2[4:0]}==wptr_q)) begin
        n_wfull = 1;
    end
    else begin
        n_wfull = 0;
    end
    
end
always@(posedge wclk or negedge rst_n) begin
    if (!rst_n) begin
        wfull <= 0;
    end
    else begin
        wfull <= n_wfull;
    end
end
// always@(posedge wclk or negedge rst_n) begin
//     if (!rst_n) begin
//         wfull <= 0;
//     end
//     else begin
//         if({~rptr_q_2[6],~rptr_q_2[5],rptr_q_2[4:0]}==wptr_q) begin
//             wfull <= 1;
//         end
//         else begin
//             wfull <= 0;
//         end
//     end
// end
assign read_enable = rinc && !rempty;
assign r_addr_q = r_addr + read_enable;
assign rptr_q = (r_addr_q >> 1) ^ r_addr_q;
reg rinc_delay;
always@(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
        rinc_delay <= 0;
    end
    else begin
        rinc_delay <= rinc;
    end
end
// always@(*) begin
//     if(rinc_delay||rinc) begin
//         n_rdata = rdata_q;
//     end
//     else begin
//         n_rdata = rdata;
//     end
// end
always@(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
        rdata <= 0;
    end
    else begin
        // if(rinc_delay || rinc) begin
            rdata <= rdata_q;
        // end
        // else begin
        //     rdata <=;
        // end
    end
end

always@(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
        r_addr <= 0;
    end
    else begin
        r_addr <= r_addr_q;
    end
end

always@(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
        rptr <= 0;
    end
    else begin
        rptr <= rptr_q;//gray code to binary
    end
end
reg n_rempty;
always@(*) begin
    if(rptr_q==wptr_q_2) begin
        n_rempty = 1;
    end
    else n_rempty = 0;
end
always@(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
        rempty <= 1;
    end
    else begin
        rempty <= n_rempty;
    end
end
// always@(posedge rclk or negedge rst_n) begin
//     if (!rst_n) begin
//         rempty <= 1;
//     end
//     else begin
//         if(rptr_q==wptr_q_2) begin
//             rempty <= 1;
//         end
//         else begin
//             rempty <= 0;
//         end
//     end
// end
// always@(*) begin
//     if(rptr_q==wptr_q_2) begin
//         rempty = 0;
//     end
//     else begin
//         rempty = 1;
//     end
// end
    
// end
// --------------
// IPs
// --------------
NDFF_BUS_syn #(.WIDTH(WIDTH-1)) rtow_ptr(.D(rptr), .Q(rptr_q_2), .clk(wclk), .rst_n(rst_n));
NDFF_BUS_syn #(.WIDTH(WIDTH-1)) wtor_ptr(.D(wptr), .Q(wptr_q_2), .clk(rclk), .rst_n(rst_n));




DUAL_64X8X1BM1 u_dual_sram (
.CKA(wclk),     .CKB(rclk),
.WEAN(w_enA),//self define
.WEBN(1'b1),//read
.CSA(1'b1),     .CSB(1'b1),
.OEA(1'b1),     .OEB(1'b1),
//use A write and use B read 
.A0(w_addr[0]),  .A1(w_addr[1]),      .A2(w_addr[2]),      .A3(w_addr[3]),      .A4(w_addr[4]),      .A5(w_addr[5]),
.B0(r_addr[0]),  .B1(r_addr[1]),      .B2(r_addr[2]),      .B3(r_addr[3]),      .B4(r_addr[4]),      .B5(r_addr[5]),
//use DinA and DoutB
.DIA0(wdata[0]),    .DIA1(wdata[1]),    .DIA2(wdata[2]),    .DIA3(wdata[3]),    
.DIA4(wdata[4]),    .DIA5(wdata[5]),    .DIA6(wdata[6]),    .DIA7(wdata[7]),
.DOB0(rdata_q[0]),  .DOB1(rdata_q[1]),  .DOB2(rdata_q[2]),  .DOB3(rdata_q[3]),
.DOB4(rdata_q[4]),  .DOB5(rdata_q[5]),  .DOB6(rdata_q[6]),  .DOB7(rdata_q[7]));
endmodule
