module stream_rx(
    // system signals
    input                   sclk,
    input                   s_rst_n,
    // Stream Rx Interface
    input           [63:0]  s_axis_mm2s_tdata,
    input           [ 7:0]  s_axis_mm2s_tkeep, // tkeep 应该也被传递，即使未使用
    input                   s_axis_mm2s_tvalid,
    output  wire            s_axis_mm2s_tready,
    input                   s_axis_mm2s_tlast,
    // Main Ctrl Interface
    input           [ 1:0]  data_type,
    input           [ 5:0]  state,
    output  wire            write_finish,
    // Output data and valid signals
    output  reg     [63:0]  stream_rx_data,
    output  reg             stream_feature_vld,
    output  reg             stream_weight_vld,
    output  reg             stream_bias_vld,
    output  reg             stream_leakyrelu_vld
);

//========================================================================\
// =========== Define Parameter and Internal signals =========== 
//========================================================================/
localparam      FEATURE_DATA    = 2'b00;
localparam      WEIGHT_DATA     = 2'b01;
localparam      BIAS_DATA       = 2'b10;
localparam      LEAKYRELU_DATA  = 2'b11;

// 内部流水线寄存器
reg             internal_vld;
reg             internal_tlast;
reg     [63:0]  internal_tdata;
reg     [ 1:0]  internal_data_type; // 锁存data_type以防传输中变化

//=============================================================================
//**************    Main Code   **************
//=============================================================================

// 1. 决定何时接收上游数据
// 当主状态允许(state[1]) 并且 内部流水线为空闲时( !internal_vld )，我们才准备好接收新数据
assign  s_axis_mm2s_tready = state[1] & !internal_vld;

// 2. 锁存输入数据到内部流水线寄存器
// 当握手成功时 (tvalid & tready)，将输入数据打入寄存器
always @(posedge sclk or negedge s_rst_n) begin
    if (s_rst_n == 1'b0) begin
        internal_vld <= 1'b0;
    end else if (s_axis_mm2s_tvalid && s_axis_mm2s_tready) begin
        internal_vld <= 1'b1; // 数据有效
        internal_tdata <= s_axis_mm2s_tdata;
        internal_tlast <= s_axis_mm2s_tlast;
        internal_data_type <= data_type; // 在数据包开始时锁存类型
    end else begin
        internal_vld <= 1'b0; // 其他情况，流水线变无效
    end
end

// 3. 根据锁存的数据产生输出
// 输出信号现在是寄存器输出，有明确的时序
always @(posedge sclk or negedge s_rst_n) begin
    if (s_rst_n == 1'b0) begin
        stream_rx_data <= 64'b0;
        stream_feature_vld <= 1'b0;
        stream_weight_vld <= 1'b0;
        stream_bias_vld <= 1'b0;
        stream_leakyrelu_vld <= 1'b0;
    end else if (internal_vld) begin // 当内部寄存器有效时
        stream_rx_data <= internal_tdata;
        // 根据锁存的data_type来产生对应的vld信号
        stream_feature_vld <= (internal_data_type == FEATURE_DATA) ? 1'b1 : 1'b0;
        stream_weight_vld  <= (internal_data_type == WEIGHT_DATA) ? 1'b1 : 1'b0;
        stream_bias_vld    <= (internal_data_type == BIAS_DATA) ? 1'b1 : 1'b0;
        stream_leakyrelu_vld <= (internal_data_type == LEAKYRELU_DATA) ? 1'b1 : 1'b0;
    end else begin
        stream_rx_data <= 64'b0; // 默认值
        stream_feature_vld <= 1'b0;
        stream_weight_vld <= 1'b0;
        stream_bias_vld <= 1'b0;
        stream_leakyrelu_vld <= 1'b0;
    end
end

// 4. write_finish 信号
// 当内部寄存器有效且是最后一个数据包时，产生完成信号
assign write_finish = internal_vld & internal_tlast;


endmodule