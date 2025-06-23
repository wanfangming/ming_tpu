module tensor_dma #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                 clk,
    input  wire                 rst_n,

    // 控制接口
    input  wire                 start,         // 启动 DMA
    input  wire [ADDR_WIDTH-1:0] src_addr,     // 源地址
    input  wire [ADDR_WIDTH-1:0] dst_addr,     // 目的地址
    input  wire [15:0]          len,           // 搬运长度（单位：word）
    output reg                  done,          // 完成标志

    // AXI读通道简化信号
    output reg  [ADDR_WIDTH-1:0] axi_araddr,
    output reg                  axi_arvalid,
    input  wire                 axi_arready,

    input  wire [DATA_WIDTH-1:0] axi_rdata,
    input  wire                 axi_rvalid,
    output reg                  axi_rready,

    // AXI写通道简化信号
    output reg  [ADDR_WIDTH-1:0] axi_awaddr,
    output reg                  axi_awvalid,
    input  wire                 axi_awready,

    output reg  [DATA_WIDTH-1:0] axi_wdata,
    output reg                  axi_wvalid,
    input  wire                 axi_wready
);

    // FSM 状态
    typedef enum logic [1:0] {
        IDLE,
        READ,
        WRITE,
        DONE
    } dma_state_t;

    dma_state_t state, next_state;

    reg [15:0] cnt;
    reg [ADDR_WIDTH-1:0] src_ptr, dst_ptr;
    reg [DATA_WIDTH-1:0] data_buf;
    reg                  data_buf_valid;

    // FSM状态转移
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE:   if (start) next_state = READ;
            READ:   if (axi_rvalid) next_state = WRITE;
            WRITE:  if (axi_wready) next_state = (cnt == 1) ? DONE : READ;
            DONE:   next_state = IDLE;
        endcase
    end

    // 主逻辑
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
            src_ptr <= 0;
            dst_ptr <= 0;
            done <= 0;
            axi_arvalid <= 0;
            axi_rready  <= 0;
            axi_awvalid <= 0;
            axi_wvalid  <= 0;
            data_buf_valid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        cnt <= len;
                        src_ptr <= src_addr;
                        dst_ptr <= dst_addr;
                    end
                end

                READ: begin
                    axi_araddr <= src_ptr;
                    axi_arvalid <= 1;
                    axi_rready <= 1;
                    if (axi_arvalid && axi_arready)
                        axi_arvalid <= 0;
                    if (axi_rvalid) begin
                        data_buf <= axi_rdata;
                        data_buf_valid <= 1;
                        src_ptr <= src_ptr + (DATA_WIDTH / 8);
                        axi_rready <= 0;
                    end
                end

                WRITE: begin
                    if (data_buf_valid) begin
                        axi_awaddr <= dst_ptr;
                        axi_awvalid <= 1;
                        axi_wdata <= data_buf;
                        axi_wvalid <= 1;
                        if (axi_awvalid && axi_awready)
                            axi_awvalid <= 0;
                        if (axi_wvalid && axi_wready) begin
                            axi_wvalid <= 0;
                            dst_ptr <= dst_ptr + (DATA_WIDTH / 8);
                            cnt <= cnt - 1;
                            data_buf_valid <= 0;
                        end
                    end
                end

                DONE: begin
                    done <= 1;
                end
            endcase
        end
    end

endmodule
