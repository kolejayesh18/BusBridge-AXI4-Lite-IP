module busbridge_axi_lite #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic                     clk,
    input  logic                     rst_n,

    // AXI4-Lite Write Address Channel
    input  logic [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  logic                     s_axi_awvalid,
    output logic                     s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  logic [DATA_WIDTH-1:0]    s_axi_wdata,
    input  logic [DATA_WIDTH/8-1:0]  s_axi_wstrb,
    input  logic                     s_axi_wvalid,
    output logic                     s_axi_wready,

    // AXI4-Lite Write Response Channel
    output logic [1:0]               s_axi_bresp,
    output logic                     s_axi_bvalid,
    input  logic                     s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  logic [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  logic                     s_axi_arvalid,
    output logic                     s_axi_arready,

    // AXI4-Lite Read Data Channel
    output logic [DATA_WIDTH-1:0]    s_axi_rdata,
    output logic [1:0]               s_axi_rresp,
    output logic                     s_axi_rvalid,
    input  logic                     s_axi_rready,

    // Peripheral signals
    input  logic                     event_i,
    output logic                     ready_o,
    output logic                     irq
);

    // ------------------------------------------------------------
    // AXI response codes
    // ------------------------------------------------------------

    localparam logic [1:0] RESP_OKAY   = 2'b00;
    localparam logic [1:0] RESP_SLVERR = 2'b10;

    // ------------------------------------------------------------
    // Register addresses
    // ------------------------------------------------------------

    localparam logic [ADDR_WIDTH-1:0] ADDR_CTRL =
        {{(ADDR_WIDTH-5){1'b0}}, 5'h00};

    localparam logic [ADDR_WIDTH-1:0] ADDR_STATUS =
        {{(ADDR_WIDTH-5){1'b0}}, 5'h04};

    localparam logic [ADDR_WIDTH-1:0] ADDR_DATA =
        {{(ADDR_WIDTH-5){1'b0}}, 5'h08};

    localparam logic [ADDR_WIDTH-1:0] ADDR_IRQ_EN =
        {{(ADDR_WIDTH-5){1'b0}}, 5'h0C};

    localparam logic [ADDR_WIDTH-1:0] ADDR_IRQ_STATUS =
        {{(ADDR_WIDTH-5){1'b0}}, 5'h10};

    // ------------------------------------------------------------
    // Write channel storage
    // ------------------------------------------------------------

    logic                  aw_pending;
    logic [ADDR_WIDTH-1:0] awaddr_reg;

    logic                  w_pending;
    logic [DATA_WIDTH-1:0] wdata_reg;
    logic [DATA_WIDTH/8-1:0] wstrb_reg;

    // ------------------------------------------------------------
    // Internal register interface
    // ------------------------------------------------------------

    logic                    reg_wr_en;
    logic [ADDR_WIDTH-1:0]   reg_wr_addr;
    logic [DATA_WIDTH-1:0]   reg_wr_data;
    logic [DATA_WIDTH/8-1:0] reg_wr_strb;

    logic [ADDR_WIDTH-1:0]   reg_rd_addr;
    logic [DATA_WIDTH-1:0]   reg_rd_data;

    // ------------------------------------------------------------
    // Address validity
    // ------------------------------------------------------------

    logic write_addr_valid;
    logic read_addr_valid;

    always_comb begin

        case (awaddr_reg)
            ADDR_CTRL,
            ADDR_DATA,
            ADDR_IRQ_EN,
            ADDR_IRQ_STATUS:
                write_addr_valid = 1'b1;

            default:
                write_addr_valid = 1'b0;
        endcase

        case (s_axi_araddr)
            ADDR_CTRL,
            ADDR_STATUS,
            ADDR_DATA,
            ADDR_IRQ_EN,
            ADDR_IRQ_STATUS:
                read_addr_valid = 1'b1;

            default:
                read_addr_valid = 1'b0;
        endcase
    end

    // ------------------------------------------------------------
    // AXI ready signals
    // ------------------------------------------------------------

    assign s_axi_awready = !aw_pending && !s_axi_bvalid;

    assign s_axi_wready  = !w_pending && !s_axi_bvalid;

    assign s_axi_arready = !s_axi_rvalid;

    // ------------------------------------------------------------
    // Register write interface
    // ------------------------------------------------------------

    assign reg_wr_en   = aw_pending &&
                         w_pending &&
                         !s_axi_bvalid &&
                         write_addr_valid;

    assign reg_wr_addr = awaddr_reg;
    assign reg_wr_data = wdata_reg;
    assign reg_wr_strb = wstrb_reg;

    // ------------------------------------------------------------
    // Write channel
    // ------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            aw_pending   <= 1'b0;
            awaddr_reg   <= '0;

            w_pending    <= 1'b0;
            wdata_reg    <= '0;
            wstrb_reg    <= '0;

            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= RESP_OKAY;
        end

        else begin

            // Capture write address
            if (s_axi_awvalid && s_axi_awready) begin
                aw_pending <= 1'b1;
                awaddr_reg <= s_axi_awaddr;
            end

            // Capture write data
            if (s_axi_wvalid && s_axi_wready) begin
                w_pending <= 1'b1;
                wdata_reg <= s_axi_wdata;
                wstrb_reg <= s_axi_wstrb;
            end

            // Both AW and W have arrived
            if (aw_pending && w_pending && !s_axi_bvalid) begin

                aw_pending   <= 1'b0;
                w_pending    <= 1'b0;

                s_axi_bvalid <= 1'b1;

                if (write_addr_valid)
                    s_axi_bresp <= RESP_OKAY;
                else
                    s_axi_bresp <= RESP_SLVERR;
            end

            // Master accepts write response
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end

        end
    end

    // ------------------------------------------------------------
    // Read channel
    // ------------------------------------------------------------

    assign reg_rd_addr = s_axi_araddr;

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= '0;
            s_axi_rresp  <= RESP_OKAY;
        end

        else begin

            // Accept read address
            if (s_axi_arvalid && s_axi_arready) begin

                s_axi_rvalid <= 1'b1;
                s_axi_rdata  <= reg_rd_data;

                if (read_addr_valid)
                    s_axi_rresp <= RESP_OKAY;
                else
                    s_axi_rresp <= RESP_SLVERR;
            end

            // Master accepts read data
            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end

        end
    end

    // ------------------------------------------------------------
    // Register block
    // ------------------------------------------------------------

    busbridge_regs #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_regs (

        .clk          (clk),
        .rst_n        (rst_n),

        .reg_wr_en    (reg_wr_en),
        .reg_wr_addr  (reg_wr_addr[4:0]),
        .reg_wr_data  (reg_wr_data),
        .reg_wr_strb  (reg_wr_strb),

        .reg_rd_addr  (reg_rd_addr[4:0]),
        .reg_rd_data  (reg_rd_data),

        .event_i      (event_i),
        .ready_o      (ready_o),
        .irq          (irq)

    );

endmodule