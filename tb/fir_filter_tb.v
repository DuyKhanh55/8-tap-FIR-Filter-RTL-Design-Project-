`timescale 1ns/1ps

module tb_fir_filter;
    parameter DATA_WIDTH   = 16;
    parameter COEFF_WIDTH  = 16;
    parameter OUTPUT_WIDTH = 32;
    parameter TAPS         = 8;
    parameter CLK_PERIOD   = 10; // 100 MHz

    //=========================================================
    // Signals
    //=========================================================
    reg                            clk;
    reg                            rst_n;
    reg                            data_valid;
    reg  signed [DATA_WIDTH-1:0]   data_in;
    wire                           out_valid;
    wire signed [OUTPUT_WIDTH-1:0] data_out;

    //=========================================================
    // DUT Selection
    // Compile with: vlog +define+DUT_PIPELINED fir_filter_pipelined.v tb_fir_filter.v
    //           or: vlog +define+DUT_COMB      fir_filter_comb.v      tb_fir_filter.v
    //=========================================================
`ifdef DUT_PIPELINED
    fir_filter_pipelined #(
        .DATA_WIDTH   (DATA_WIDTH),
        .COEFF_WIDTH  (COEFF_WIDTH),
        .OUTPUT_WIDTH (OUTPUT_WIDTH),
        .TAPS         (TAPS)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_valid (data_valid),
        .data_in    (data_in),
        .out_valid  (out_valid),
        .data_out   (data_out)
    );
`elsif DUT_COMB
    fir_filter_comb #(
        .DATA_WIDTH   (DATA_WIDTH),
        .COEFF_WIDTH  (COEFF_WIDTH),
        .OUTPUT_WIDTH (OUTPUT_WIDTH),
        .TAPS         (TAPS)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_valid (data_valid),
        .data_in    (data_in),
        .out_valid  (out_valid),
        .data_out   (data_out)
    );
`else
    initial begin
        $display("ERROR: compile with +define+DUT_PIPELINED or +define+DUT_COMB");
        $finish;
    end
`endif

    //=========================================================
    // Clock Generation
    //=========================================================
    always #(CLK_PERIOD/2) clk = ~clk;

    //=========================================================
    // File Handles
    //=========================================================
    integer infile;
    integer outfile;
    integer sample;
    integer status;
    integer cycle_count;
    reg     file_open; // guard flag: outfile đã mở chưa

    //=========================================================
    // Main Stimulus Process
    //=========================================================
    initial begin
        clk         = 0;
        rst_n       = 0;
        data_valid  = 0;
        data_in     = 0;
        cycle_count = 0;
        file_open   = 0;

        // Reset
        #(CLK_PERIOD*3);
        rst_n = 1;

        // Open files
        infile = $fopen("input_samples.txt", "r");
        if (infile == 0) begin
            $display("ERROR : Cannot open input_samples.txt");
            $finish;
        end

`ifdef DUT_PIPELINED
        outfile = $fopen("sim_output_pipelined.txt", "w");
        $display("Output : sim_output_pipelined.txt");
`else
        outfile = $fopen("sim_output_comb.txt", "w");
        $display("Output : sim_output_comb.txt");
`endif

        if (outfile == 0) begin
            $display("ERROR : Cannot create output file");
            $finish;
        end
        file_open = 1; // báo cho always block bên dưới là file đã sẵn sàng

        // Wait 1 cycle after reset
        @(posedge clk);

        // Feed samples
        while (!$feof(infile)) begin
            status = $fscanf(infile, "%d\n", sample);
            if (status == 1) begin
                data_in    <= sample;
                data_valid <= 1'b1;
                @(posedge clk);
            end
        end

        // Stop input
        data_valid <= 1'b0;
        data_in    <= 0;

        // Flush pipeline (TAPS+2 covers both v1 and v2)
        repeat(TAPS + 2) @(posedge clk);

        // Close
        $fclose(infile);
        $fclose(outfile);
        $display("----------------------------------------");
        $display("Simulation completed successfully.");
        $display("----------------------------------------");
        $finish;
    end

    //=========================================================
    // Output Collector
    //=========================================================
    always @(posedge clk) begin
    if (rst_n && file_open) begin
        cycle_count <= cycle_count + 1;
        
        // Nếu ngõ ra CHƯA hợp lệ (đang bận trễ pipeline) -> Ghi 0 vào file
        // Nếu ngõ ra ĐÃ hợp lệ -> Ghi giá trị thực data_out
        if (out_valid) begin
            $fwrite(outfile, "%d\n", data_out);
            $display("[cycle %0d] VALID OUT = %0d", cycle_count, data_out);
        end else begin
            $fwrite(outfile, "0\n"); // Ghi trễ (latency padding)
            $display("[cycle %0d] INVALID (WAITING...)", cycle_count);
        end
    end
end

endmodule
