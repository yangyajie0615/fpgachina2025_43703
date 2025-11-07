module LIF #(
    parameter INPUT_WIDTH       = 8,    
    parameter VOLTAGE_WIDTH     = 16,  
    parameter VOLTAGE_FRAC_BITS = 8, 
    // 阈值设为1.0
    parameter THRESHOLD         = 16'h0100 
)(
    // 系统信号
    input                           clk,
    input                           rst_n,
    // 数据信号
    input                           i_valid,        // 输入数据有效信号
    input      signed [INPUT_WIDTH-1:0]   neuron_in,      // 输入数据（例如：来自卷积层的累加结果）
    // 输出信号
    output     reg                    spike_out,      // 输出脉冲 (1 表示发放, 0 表示不发放)
    output     reg                    o_valid         // 输出数据有效信号
);

// 内部膜电位寄存器，定义为有符号数以处理正负电压
reg   signed [VOLTAGE_WIDTH-1:0]    membrane_potential;

wire  signed [VOLTAGE_WIDTH-1:0]    leaky_potential;
wire  signed [VOLTAGE_WIDTH-1:0]    scaled_input;
wire  signed [VOLTAGE_WIDTH-1:0]    next_membrane_potential;

assign leaky_potential = membrane_potential - (membrane_potential >> 2);
assign scaled_input = {{(VOLTAGE_WIDTH-INPUT_WIDTH){neuron_in[INPUT_WIDTH-1]}}, neuron_in};
assign next_membrane_potential = leaky_potential + scaled_input;

//charge  0.25 0.4375 0.5781 0.6836
// def neuronal_charge_decay_input_reset0(x: torch.Tensor, v: torch.Tensor, tau: float):
// v = v + (x - v) / tau
// return v

// --- 延迟控制逻辑 ---
// 创建一个两级延迟的输入有效信号，用于同步输出
reg i_valid_d1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        i_valid_d1 <= 1'b0;
        o_valid    <= 1'b0;
    end else begin
        i_valid_d1 <= i_valid;
        o_valid <= i_valid_d1;
    end
end


// --- 膜电位更新逻辑 ---
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        membrane_potential <= 'd0;
        spike_out          <= 1'b0;
    end else begin
        // 默认情况下，脉冲输出为0
        spike_out <= 1'b0;

        if (i_valid_d1) begin // 在输入有效的下一拍进行计算
            // 检查上一周期的膜电位是否超过阈值
            if (membrane_potential > THRESHOLD) begin
                // A. 发放并重置 (Fire and Reset)
                spike_out          <= 1'b1;   // 发放脉冲
                membrane_potential <= 'd0;     // 膜电位重置为0
            end else begin
                // B. 泄漏并积分 (Leaky and Integrate)
                membrane_potential <= next_membrane_potential;
            end
        end
    end
end

endmodule