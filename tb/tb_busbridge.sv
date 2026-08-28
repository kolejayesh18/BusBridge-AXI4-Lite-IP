`timescale 1ns/1ps

module tb_busbridge;

    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;

    logic clk;
    logic rst_n;

    // AXI Write Address
    logic [ADDR_WIDTH-1:0] s_axi_awaddr;
    logic                  s_axi_awvalid;
    logic                  s_axi_awready;

    // AXI Write Data
    logic [DATA_WIDTH-1:0]   s_axi_wdata;
    logic [DATA_WIDTH/8-1:0] s_axi_wstrb;
    logic                    s_axi_wvalid;
    logic                    s_axi_wready;

    // AXI Write Response
    logic [1:0] s_axi_bresp;
    logic       s_axi_bvalid;
    logic       s_axi_bready;

    // AXI Read Address
    logic [ADDR_WIDTH-1:0] s_axi_araddr;
    logic                  s_axi_arvalid;
    logic                  s_axi_arready;

    // AXI Read Data
    logic [DATA_WIDTH-1:0] s_axi_rdata;
    logic [1:0]            s_axi_rresp;
    logic                  s_axi_rvalid;
    logic                  s_axi_rready;

    // Peripheral
    logic event_i;
    logic ready_o;
    logic irq;

    integer pass_count;
    integer fail_count;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    busbridge_axi_lite #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),

        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),

        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),

        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),

        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),

        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),

        .event_i(event_i),
        .ready_o(ready_o),
        .irq(irq)
    );

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Waveform
    // ------------------------------------------------------------

    initial begin
        $dumpfile("sim/busbridge.vcd");
        $dumpvars(0, tb_busbridge);
    end

    // ------------------------------------------------------------
    // PASS / FAIL helper
    // ------------------------------------------------------------

    task check;
        input condition;
        input [255:0] test_name;

        begin
            if (condition) begin
                $display("[PASS] %s", test_name);
                pass_count = pass_count + 1;
            end
            else begin
                $display("[FAIL] %s", test_name);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ------------------------------------------------------------
    // AXI-Lite WRITE
    // ------------------------------------------------------------

    task axi_write;
        input [31:0] addr;
        input [31:0] data;
        input [3:0]  strb;
        input        separate_channels;

        begin

            if (separate_channels) begin

                // Send AW first
                @(posedge clk);
                s_axi_awaddr  <= addr;
                s_axi_awvalid <= 1'b1;

                wait (s_axi_awready);

                @(posedge clk);
                s_axi_awvalid <= 1'b0;

                // Send W later
                @(posedge clk);
                s_axi_wdata  <= data;
                s_axi_wstrb  <= strb;
                s_axi_wvalid <= 1'b1;

                wait (s_axi_wready);

                @(posedge clk);
                s_axi_wvalid <= 1'b0;

            end
            else begin

                // AW and W together
                @(posedge clk);

                s_axi_awaddr  <= addr;
                s_axi_awvalid <= 1'b1;

                s_axi_wdata   <= data;
                s_axi_wstrb   <= strb;
                s_axi_wvalid  <= 1'b1;

                wait (s_axi_awready && s_axi_wready);

                @(posedge clk);

                s_axi_awvalid <= 1'b0;
                s_axi_wvalid  <= 1'b0;

            end

            // Accept response
            s_axi_bready <= 1'b1;

            wait (s_axi_bvalid);

            @(posedge clk);

            s_axi_bready <= 1'b0;

        end
    endtask

    // ------------------------------------------------------------
    // AXI-Lite READ
    // ------------------------------------------------------------

    task axi_read;
        input  [31:0] addr;
        output [31:0] data;
        output [1:0]  resp;

        begin

            @(posedge clk);

            s_axi_araddr  <= addr;
            s_axi_arvalid <= 1'b1;

            wait (s_axi_arready);

            @(posedge clk);

            s_axi_arvalid <= 1'b0;

            s_axi_rready <= 1'b1;

            wait (s_axi_rvalid);

            data = s_axi_rdata;
            resp = s_axi_rresp;

            @(posedge clk);

            s_axi_rready <= 1'b0;

        end
    endtask

    // ------------------------------------------------------------
    // Main test
    // ------------------------------------------------------------

    logic [31:0] read_data;
    logic [1:0]  read_resp;

    initial begin

        pass_count = 0;
        fail_count = 0;

        // Initialize
        rst_n = 1'b0;

        s_axi_awaddr  = '0;
        s_axi_awvalid = 1'b0;

        s_axi_wdata   = '0;
        s_axi_wstrb   = '0;
        s_axi_wvalid  = 1'b0;

        s_axi_bready  = 1'b0;

        s_axi_araddr  = '0;
        s_axi_arvalid = 1'b0;
        s_axi_rready  = 1'b0;

        event_i = 1'b0;

        // Reset
        repeat (3) @(posedge clk);
        rst_n = 1'b1;

        $display("");
        $display("==============================================");
        $display(" BUSBRIDGE AXI-LITE VERIFICATION");
        $display("==============================================");

        // --------------------------------------------------------
        // TEST 1: CTRL WRITE
        // --------------------------------------------------------

        axi_write(
            32'h0000_0000,
            32'h0000_0001,
            4'b0001,
            1'b0
        );

        // --------------------------------------------------------
        // TEST 2: CTRL READ
        // --------------------------------------------------------

        axi_read(
            32'h0000_0000,
            read_data,
            read_resp
        );

        check(
            (read_data == 32'h0000_0001) &&
            (read_resp == 2'b00),
            "CTRL write/read"
        );

        // --------------------------------------------------------
        // TEST 3: DATA WRITE/READ
        // --------------------------------------------------------

        axi_write(
            32'h0000_0008,
            32'h1234_ABCD,
            4'b1111,
            1'b0
        );

        axi_read(
            32'h0000_0008,
            read_data,
            read_resp
        );

        check(
            (read_data == 32'h1234_ABCD) &&
            (read_resp == 2'b00),
            "DATA write/read"
        );

        // --------------------------------------------------------
        // TEST 4: IRQ ENABLE
        // --------------------------------------------------------

        axi_write(
            32'h0000_000C,
            32'h0000_0001,
            4'b0001,
            1'b0
        );

        // --------------------------------------------------------
        // TEST 5: EVENT -> IRQ
        // --------------------------------------------------------

        @(posedge clk);
        event_i <= 1'b1;

        @(posedge clk);
        event_i <= 1'b0;

        #1;

        check(
            irq == 1'b1,
            "IRQ assertion after event"
        );

        // --------------------------------------------------------
        // TEST 6: IRQ STATUS
        // --------------------------------------------------------

        axi_read(
            32'h0000_0010,
            read_data,
            read_resp
        );

        check(
            (read_data[0] == 1'b1) &&
            (read_resp == 2'b00),
            "IRQ status set"
        );

        // --------------------------------------------------------
        // TEST 7: CLEAR IRQ
        // --------------------------------------------------------

        axi_write(
            32'h0000_0010,
            32'h0000_0001,
            4'b0001,
            1'b0
        );

        @(posedge clk);

        check(
            irq == 1'b0,
            "IRQ clear"
        );

        // --------------------------------------------------------
        // TEST 8: INVALID WRITE ADDRESS
        // --------------------------------------------------------

        axi_write(
            32'h0000_0020,
            32'hDEAD_BEEF,
            4'b1111,
            1'b0
        );

        check(
            s_axi_bresp == 2'b10,
            "Invalid write returns SLVERR"
        );

        // --------------------------------------------------------
        // TEST 9: INVALID READ ADDRESS
        // --------------------------------------------------------

        axi_read(
            32'h0000_0020,
            read_data,
            read_resp
        );

        check(
            read_resp == 2'b10,
            "Invalid read returns SLVERR"
        );

        // --------------------------------------------------------
        // TEST 10: AW/W SEPARATE
        // --------------------------------------------------------

        axi_write(
            32'h0000_0008,
            32'hCAFE_BABE,
            4'b1111,
            1'b1
        );

        axi_read(
            32'h0000_0008,
            read_data,
            read_resp
        );

        check(
            (read_data == 32'hCAFE_BABE) &&
            (read_resp == 2'b00),
            "Independent AW/W channels"
        );

        // --------------------------------------------------------
        // SUMMARY
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display(" VERIFICATION SUMMARY");
        $display("==============================================");
        $display(" PASSED : %0d", pass_count);
        $display(" FAILED : %0d", fail_count);
        $display("==============================================");

        if (fail_count == 0)
            $display(" RESULT : ALL TESTS PASSED");
        else
            $display(" RESULT : TEST FAILURES PRESENT");

        $display("==============================================");
        $display("");

        #20;

        $finish;

    end
        // --------------------------------------------------------
    // AXI-LITE PROTOCOL CHECKS
    // --------------------------------------------------------

    // AW channel: address must remain stable while stalled
    logic [31:0] awaddr_check;

    always_ff @(posedge clk) begin
        if (rst_n && s_axi_awvalid && !s_axi_awready) begin
            if (awaddr_check !== s_axi_awaddr)
                $display("[ASSERT FAIL] AWADDR changed while AWVALID && !AWREADY");
        end

        if (rst_n && s_axi_awvalid && !s_axi_awready)
            awaddr_check <= s_axi_awaddr;
    end

    // W channel: data and strobe must remain stable while stalled
    logic [31:0] wdata_check;
    logic [3:0]  wstrb_check;

    always_ff @(posedge clk) begin
        if (rst_n && s_axi_wvalid && !s_axi_wready) begin
            if ((wdata_check !== s_axi_wdata) ||
                (wstrb_check !== s_axi_wstrb))
                $display("[ASSERT FAIL] WDATA/WSTRB changed while WVALID && !WREADY");
        end

        if (rst_n && s_axi_wvalid && !s_axi_wready) begin
            wdata_check <= s_axi_wdata;
            wstrb_check <= s_axi_wstrb;
        end
    end

    // B channel: response must remain stable while stalled
    logic [1:0] bresp_check;

    always_ff @(posedge clk) begin
        if (rst_n && s_axi_bvalid && !s_axi_bready) begin
            if (bresp_check !== s_axi_bresp)
                $display("[ASSERT FAIL] BRESP changed while BVALID && !BREADY");
        end

        if (rst_n && s_axi_bvalid && !s_axi_bready)
            bresp_check <= s_axi_bresp;
    end

    // R channel: data and response must remain stable while stalled
    logic [31:0] rdata_check;
    logic [1:0]  rresp_check;

    always_ff @(posedge clk) begin
        if (rst_n && s_axi_rvalid && !s_axi_rready) begin
            if ((rdata_check !== s_axi_rdata) ||
                (rresp_check !== s_axi_rresp))
                $display("[ASSERT FAIL] RDATA/RRESP changed while RVALID && !RREADY");
        end

        if (rst_n && s_axi_rvalid && !s_axi_rready) begin
            rdata_check <= s_axi_rdata;
            rresp_check <= s_axi_rresp;
        end
    end

endmodule