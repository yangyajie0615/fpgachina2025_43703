
module lif_top (
    // system signals
    input                   sclk,
    input                   s_rst_n,
    // Stream Data (Ignored, for interface compatibility)
    input           [63:0]  stream_rx_data,
    input                   stream_leakyrelu_vld,
    input                   write_finish,
    // Channel Data Input
    input           [7:0]   ch0_data_i,
    input           [7:0]   ch1_data_i,
    input           [7:0]   ch2_data_i,
    input           [7:0]   ch3_data_i,
    input           [7:0]   ch4_data_i,
    input           [7:0]   ch5_data_i,
    input           [7:0]   ch6_data_i,
    input           [7:0]   ch7_data_i,
    input                   ch_data_vld_i,
    // Channel Data Output
    output  wire    [7:0]   ch0_data_o,
    output  wire    [7:0]   ch1_data_o,
    output  wire    [7:0]   ch2_data_o,
    output  wire    [7:0]   ch3_data_o,
    output  wire    [7:0]   ch4_data_o,
    output  wire    [7:0]   ch5_data_o,
    output  wire    [7:0]   ch6_data_o,
    output  wire    [7:0]   ch7_data_o,
    output  wire            ch_data_vld_o
);

wire                    spike_out_ch0, spike_out_ch1, spike_out_ch2, spike_out_ch3;
wire                    spike_out_ch4, spike_out_ch5, spike_out_ch6, spike_out_ch7;

// 输出有效信号的延迟寄存器，与原始 leaky_relu 模块逻辑保持一致
reg     [1:0]           data_vld_delay;

// 为了与原始设计的时序保持一致，输出有效信号 ch_data_vld_o 
// 是输入有效信号 ch_data_vld_i 延迟两个时钟周期的结果。
always @(posedge sclk or negedge s_rst_n) begin
    if (s_rst_n == 1'b0)
        data_vld_delay <= 2'd0;
    else
        data_vld_delay <= {data_vld_delay[0], ch_data_vld_i};
end

assign ch_data_vld_o = data_vld_delay[1];

genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin : lif_channel_inst
        
        wire [7:0] current_ch_data_i;
        wire [7:0] current_ch_data_o;
        wire       current_spike_out;
        // 使用 case 语句将通用连线连接到具体通道
        case (i)
            0: begin
                assign current_ch_data_i = ch0_data_i;
                assign ch0_data_o = {7'b0, current_spike_out};
            end
            1: begin
                assign current_ch_data_i = ch1_data_i;
                assign ch1_data_o = {7'b0, current_spike_out};
            end
            2: begin
                assign current_ch_data_i = ch2_data_i;
                assign ch2_data_o = {7'b0, current_spike_out};
            end
            3: begin
                assign current_ch_data_i = ch3_data_i;
                assign ch3_data_o = {7'b0, current_spike_out};
            end
            4: begin
                assign current_ch_data_i = ch4_data_i;
                assign ch4_data_o = {7'b0, current_spike_out};
            end
            5: begin
                assign current_ch_data_i = ch5_data_i;
                assign ch5_data_o = {7'b0, current_spike_out};
            end
            6: begin
                assign current_ch_data_i = ch6_data_i;
                assign ch6_data_o = {7'b0, current_spike_out};
            end
            7: begin
                assign current_ch_data_i = ch7_data_i;
                assign ch7_data_o = {7'b0, current_spike_out};
            end
        endcase

        LIF #(
            .INPUT_WIDTH(8),
            .VOLTAGE_WIDTH(16)
        ) u_lif_neuron (
            .clk        (sclk),
            .rst_n      (s_rst_n),
            .i_valid    (ch_data_vld_i),
            .neuron_in  (current_ch_data_i),
            .spike_out  (current_spike_out),
            .o_valid    ()
        );
    end
endgenerate


endmodule
