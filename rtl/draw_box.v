module  draw_box(
        // system signals
        input                   sclk                    ,       
        input                   s_rst_n                 ,       
        //
        input   [31:0]          box_x1                  ,
        input   [31:0]          box_y1                  ,
        input   [31:0]          box_x2                  ,
        input   [31:0]          box_y2                  ,
        //
        input                   vga_hsync_i             ,       
        input                   vga_vsync_i             ,       
        input                   vga_de_i                ,       
        input           [23:0]  vga_data_i              ,       
        //
        output  wire            vga_hsync_o             ,       
        output  wire            vga_vsync_o             ,       
        output  wire            vga_de_o                ,       
        output  wire    [23:0]  vga_data_o                     
);

//========================================================================\
// =========== Define Parameter and Internal signals =========== 
//========================================================================/

localparam      H_ACTIVE        =       'd1280                  ;
localparam      X_OFFSET        =       'd16                    ;
localparam      Y_OFFSET        =       'd48                    ;

reg                             draw_flag                       ;     
reg     [10:0]                  cnt_h                           ;
reg     [ 9:0]                  cnt_v                           ;

reg     [31:0]                  box_x1_reg                      ;  
reg     [31:0]                  box_y1_reg                      ;  
reg     [31:0]                  box_x2_reg                      ;  
reg     [31:0]                  box_y2_reg                      ;  




//=============================================================================
//**************    Main Code   **************
//=============================================================================
assign  vga_hsync_o     =       vga_hsync_i;
assign  vga_vsync_o     =       vga_vsync_i;
assign  vga_de_o        =       vga_de_i;

assign  vga_data_o      =       (draw_flag == 1'b1) ? 24'hFF0000 : vga_data_i;

always  @(posedge sclk) begin
        box_x1_reg      <=       box_x1+X_OFFSET;
        box_y1_reg      <=       box_y1+Y_OFFSET;
        box_x2_reg      <=       box_x2+X_OFFSET;
        box_y2_reg      <=       box_y2+Y_OFFSET;
end

always  @(posedge sclk or negedge s_rst_n) begin
        if(s_rst_n == 1'b0)
                cnt_h   <=      'd0;
        else if(vga_hsync_i == 1'b1)
                cnt_h   <=      'd0;
        else if(vga_de_i == 1'b1)
                cnt_h   <=      cnt_h + 1'b1;
end

always  @(posedge sclk or negedge s_rst_n) begin
        if(s_rst_n == 1'b0)
                cnt_v   <=      'd0;
        else if(vga_vsync_i == 1'b1)
                cnt_v   <=      'd0;
        else if(cnt_h == (H_ACTIVE-1) && vga_de_i == 1'b1)
                cnt_v   <=      cnt_v + 1'b1;
end

always  @(posedge sclk or negedge s_rst_n) begin
        if(s_rst_n == 1'b0)
                draw_flag       <=      1'b0;
        else if(cnt_v == box_y1_reg && cnt_h >= box_x1_reg && cnt_h < box_x2_reg) // TOP
                draw_flag       <=      1'b1;
        else if(cnt_v == box_y2_reg && cnt_h >= box_x1_reg && cnt_h < box_x2_reg) // BOTTOM
                draw_flag       <=      1'b1;
        else if(cnt_h == box_x1_reg && cnt_v >= box_y1_reg && cnt_v < box_y2_reg) // LEFT
                draw_flag       <=      1'b1;
        else if(cnt_h == box_x2_reg && cnt_v >= box_y1_reg && cnt_v < box_y2_reg) // RIGHT
                draw_flag       <=      1'b1;
        else
                draw_flag       <=      1'b0;
end

endmodule
