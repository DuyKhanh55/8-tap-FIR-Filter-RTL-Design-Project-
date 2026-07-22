`timescale 1ns/1ps
module tb_fir_filter;
    parameter DATA_WIDTH   = 16;
    parameter COEFF_WIDTH  = 16;
    parameter OUTPUT_WIDTH = 32;
    parameter TAPS         = 8;
    parameter CLK_PERIOD   = 10;    // 100 MHz
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
    // DUT
    //=========================================================
    fir_filter #(
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
    //=========================================================
    // Clock Generation
    //=========================================================
    always #(CLK_PERIOD/2) clk = ~clk;
    //=========================================================
    // File I/O
    //=========================================================
    integer infile;
    integer outfile;
    integer sample;
    integer status;
    //=========================================================
    // Main Test Process
    //=========================================================
    initial begin
        // Initial values
        clk        = 0;
        rst_n      = 0;
        data_valid = 0;
        data_in    = 0;
        // Reset
        #(CLK_PERIOD*3);
        rst_n = 1;
        // Open files
        infile  = $fopen("input_samples.txt","r");
        outfile = $fopen("sim_output.txt","w");
        // Check file opening
        if(infile == 0) begin
            $display("ERROR : Cannot open input_samples.txt");
            $finish;
        end
        if(outfile == 0) begin
            $display("ERROR : Cannot create sim_output.txt");
            $finish;
        end
        //=====================================================
        // Feed input samples to DUT
        //=====================================================
        while(!$feof(infile)) begin
            status = $fscanf(infile,"%d\n",sample);
            @(negedge clk);
            data_in   = sample;
            data_valid = 1'b1;
            @(posedge clk);
            if(out_valid)
                $fwrite(outfile,"%d\n",data_out);
        end
        // Stop feeding new samples
        data_valid = 1'b0;
        //=====================================================
        // Flush remaining pipeline outputs
        //=====================================================
        repeat(TAPS+2) begin
            @(posedge clk);
            if(out_valid)
                $fwrite(outfile,"%d\n",data_out);
        end
        //=====================================================
        // Close files
        //=====================================================
        $fclose(infile);
        $fclose(outfile);
        $display("----------------------------------------");
        $display("Simulation completed successfully.");
        $display("Generated file : sim_output.txt");
        $display("Compare it with expected_output.txt");
        $display("----------------------------------------");
        $finish;
    end
endmodule
