module busbridge_regs #(
    parameter DATA_WIDTH = 32
)(
    input  logic                     clk,
    input  logic                     rst_n,

    // Register write interface
    input  logic                     reg_wr_en,
    input  logic [4:0]               reg_wr_addr,
    input  logic [DATA_WIDTH-1:0]    reg_wr_data,
    input  logic [DATA_WIDTH/8-1:0]  reg_wr_strb,

    // Register read interface
    input  logic [4:0]               reg_rd_addr,
    output logic [DATA_WIDTH-1:0]    reg_rd_data,

    // Peripheral status
    input  logic                     event_i,
    output logic                     ready_o,

    // Interrupt
    output logic                     irq
);

    // Register storage
    logic [DATA_WIDTH-1:0] ctrl_reg;
    logic [DATA_WIDTH-1:0] data_reg;
    logic [DATA_WIDTH-1:0] irq_en_reg;
    logic [DATA_WIDTH-1:0] irq_status_reg;

    // Register addresses
    localparam logic [4:0] ADDR_CTRL       = 5'h00;
    localparam logic [4:0] ADDR_STATUS     = 5'h04;
    localparam logic [4:0] ADDR_DATA       = 5'h08;
    localparam logic [4:0] ADDR_IRQ_EN     = 5'h0C;
    localparam logic [4:0] ADDR_IRQ_STATUS = 5'h10;

    // Write logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg       <= '0;
            data_reg       <= '0;
            irq_en_reg     <= '0;
            irq_status_reg <= '0;
        end
        else begin

            // Event sets interrupt status
            if (event_i)
                irq_status_reg[0] <= 1'b1;

            // Register writes
            if (reg_wr_en) begin

                case (reg_wr_addr)

                    ADDR_CTRL: begin
                        if (reg_wr_strb[0])
                            ctrl_reg[7:0] <= reg_wr_data[7:0];
                    end

                    ADDR_DATA: begin
                        if (reg_wr_strb[0])
                            data_reg[7:0] <= reg_wr_data[7:0];

                        if (reg_wr_strb[1])
                            data_reg[15:8] <= reg_wr_data[15:8];

                        if (reg_wr_strb[2])
                            data_reg[23:16] <= reg_wr_data[23:16];

                        if (reg_wr_strb[3])
                            data_reg[31:24] <= reg_wr_data[31:24];
                    end

                    ADDR_IRQ_EN: begin
                        if (reg_wr_strb[0])
                            irq_en_reg[0] <= reg_wr_data[0];
                    end

                    ADDR_IRQ_STATUS: begin
                        // Write 1 to clear interrupt
                        if (reg_wr_strb[0] && reg_wr_data[0])
                            irq_status_reg[0] <= 1'b0;
                    end

                    default: begin
                    end

                endcase
            end
        end
    end

    // Read logic
    always_comb begin

        reg_rd_data = '0;

        case (reg_rd_addr)

            ADDR_CTRL: begin
                reg_rd_data = ctrl_reg;
            end

            ADDR_STATUS: begin
                reg_rd_data[0] = ready_o;
            end

            ADDR_DATA: begin
                reg_rd_data = data_reg;
            end

            ADDR_IRQ_EN: begin
                reg_rd_data = irq_en_reg;
            end

            ADDR_IRQ_STATUS: begin
                reg_rd_data = irq_status_reg;
            end

            default: begin
                reg_rd_data = '0;
            end

        endcase
    end

    // Status
    assign ready_o = ctrl_reg[0];

    // Interrupt
    assign irq = irq_en_reg[0] & irq_status_reg[0];

endmodule