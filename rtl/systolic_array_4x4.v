// systolic_array_4x4.v
module systolic_array_4x4 #(
  parameter DATA_W = 8,
  parameter ACC_W  = 16,
  parameter N      = 4
)(
  input  logic                 clk,
  input  logic                 rst_n,
  input  logic [DATA_W-1:0]    a_in [N],
  input  logic [DATA_W-1:0]    w_in [N],
  output logic [ACC_W-1:0]     result [N][N]
);

  logic [DATA_W-1:0]  a_reg [N][N];
  logic [DATA_W-1:0]  w_reg [N][N];
  logic [ACC_W-1:0]   psum [N][N];

  integer i, j;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < N; i++) begin
        a_reg[i][0] <= 0;
        w_reg[0][i] <= 0;
        for (j = 0; j < N; j++) begin
          psum[i][j] <= 0;
        end
      end
    end else begin
      for (i = 0; i < N; i++) begin
        a_reg[i][0] <= a_in[i];
        w_reg[0][i] <= w_in[i];
      end
    end
  end

  genvar gi, gj;
  generate
    for (gi = 0; gi < N; gi++) begin : ROW
      for (gj = 0; gj < N; gj++) begin : COL
        pe #(.DATA_W(DATA_W), .ACC_W(ACC_W)) u_pe (
          .clk(clk), .rst_n(rst_n),
          .a_in   (a_reg[gi][gj]),
          .w_in   (w_reg[gi][gj]),
          .psum_in(psum[gi][gj]),
          .a_out  (a_reg[gi][gj+1]),
          .w_out  (w_reg[gi+1][gj]),
          .psum_out(psum[gi][gj])
        );
        assign result[gi][gj] = psum[gi][gj];
      end
    end
  endgenerate

endmodule
