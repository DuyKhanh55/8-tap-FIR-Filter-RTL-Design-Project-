
module fir_filter #(
    parameter DATA_WIDTH   = 16,
    parameter COEFF_WIDTH  = 16,
    parameter OUTPUT_WIDTH = 32,
    parameter TAPS         = 8
)(
    input  wire                          clk,
    input  wire                          rst_n,     // active-low reset
    input  wire                          data_valid,// input sample valid
    input  wire signed [DATA_WIDTH-1:0]  data_in,
    output reg                           out_valid,
    output reg  signed [OUTPUT_WIDTH-1:0] data_out
);

    // -----------------------------------------------------------
    // Coefficients (Q1.15, from fir_design.m)
    // -----------------------------------------------------------
    localparam signed [COEFF_WIDTH-1:0] COEFF_0 = 16'sd117;  // h[0]
    localparam signed [COEFF_WIDTH-1:0] COEFF_1 = 16'sd1248; // h[1]
    localparam signed [COEFF_WIDTH-1:0] COEFF_2 = 16'sd5277; // h[2]
    localparam signed [COEFF_WIDTH-1:0] COEFF_3 = 16'sd9743; // h[3]
    localparam signed [COEFF_WIDTH-1:0] COEFF_4 = 16'sd9743; // h[4]
    localparam signed [COEFF_WIDTH-1:0] COEFF_5 = 16'sd5277; // h[5]
    localparam signed [COEFF_WIDTH-1:0] COEFF_6 = 16'sd1248; // h[6]
    localparam signed [COEFF_WIDTH-1:0] COEFF_7 = 16'sd117;  // h[7]

    wire signed [COEFF_WIDTH-1:0] coeff [0:TAPS-1];
    assign coeff[0] = COEFF_0;
    assign coeff[1] = COEFF_1;
    assign coeff[2] = COEFF_2;
    assign coeff[3] = COEFF_3;
    assign coeff[4] = COEFF_4;
    assign coeff[5] = COEFF_5;
    assign coeff[6] = COEFF_6;
    assign coeff[7] = COEFF_7;

    // -----------------------------------------------------------
    // Stage 0: Shift register (tapped delay line)
    // -----------------------------------------------------------
    reg signed [DATA_WIDTH-1:0] shift_reg [0:TAPS-1];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < TAPS; i = i + 1)
                shift_reg[i] <= {DATA_WIDTH{1'b0}};
        end else if (data_valid) begin
            shift_reg[0] <= data_in;
            for (i = 1; i < TAPS; i = i + 1)
                shift_reg[i] <= shift_reg[i-1];
        end
    end

    // -----------------------------------------------------------
    // Valid signal, pipelined alongside the data (1 bit per stage)
    // -----------------------------------------------------------
    reg valid_s1, valid_s2, valid_s3;

    // -----------------------------------------------------------
    // Stage 1: Multiply, register each product individually
    // Critical path here = 1 multiplier only
    // -----------------------------------------------------------
    reg signed [DATA_WIDTH+COEFF_WIDTH-1:0] mult_reg [0:TAPS-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < TAPS; i = i + 1)
                mult_reg[i] <= 0;
            valid_s1 <= 1'b0;
        end else begin
            for (i = 0; i < TAPS; i = i + 1)
                mult_reg[i] <= shift_reg[i] * coeff[i];
            valid_s1 <= data_valid;
        end
    end

    // -----------------------------------------------------------
    // Stage 2: Adder tree level 1 (8 products -> 4 partial sums)
    // Critical path here = 1 two-input adder
    // -----------------------------------------------------------
    reg signed [OUTPUT_WIDTH-1:0] add1_reg [0:3];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            add1_reg[0] <= 0; add1_reg[1] <= 0;
            add1_reg[2] <= 0; add1_reg[3] <= 0;
            valid_s2 <= 1'b0;
        end else begin
            add1_reg[0] <= mult_reg[0] + mult_reg[1];
            add1_reg[1] <= mult_reg[2] + mult_reg[3];
            add1_reg[2] <= mult_reg[4] + mult_reg[5];
            add1_reg[3] <= mult_reg[6] + mult_reg[7];
            valid_s2 <= valid_s1;
        end
    end

    // -----------------------------------------------------------
    // Stage 3: Adder tree level 2 (4 partial sums -> 2)
    // -----------------------------------------------------------
    reg signed [OUTPUT_WIDTH-1:0] add2_reg [0:1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            add2_reg[0] <= 0; add2_reg[1] <= 0;
            valid_s3 <= 1'b0;
        end else begin
            add2_reg[0] <= add1_reg[0] + add1_reg[1];
            add2_reg[1] <= add1_reg[2] + add1_reg[3];
            valid_s3 <= valid_s2;
        end
    end

    // -----------------------------------------------------------
    // Stage 4: Final add -> registered output (data_out)
    // -----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= 0;
            out_valid <= 1'b0;
        end else begin
            data_out  <= add2_reg[0] + add2_reg[1];
            out_valid <= valid_s3;
        end
    end

endmodule

