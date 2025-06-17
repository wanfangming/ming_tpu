// pe.v
module pe #(
  parameter DATA_W = 8,
  parameter ACC_W  = 16
)(
  input  logic                 clk,
  input  logic                 rst_n,
  input  logic [DATA_W-1:0]    a_in,
  input  logic [DATA_W-1:0]    w_in,
  input  logic [ACC_W-1:0]     psum_in,
  output logic [DATA_W-1:0]    a_out,
  output logic [DATA_W-1:0]    w_out,
  output logic [ACC_W-1:0]     psum_out
);
  logic [ACC_W-1:0] mult;
  assign mult     = a_in * w_in;
  assign psum_out = mult + psum_in;
  assign a_out    = a_in;
  assign w_out    = w_in;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      ;  // 状态无寄存器
  end
endmodule
