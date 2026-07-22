module fir_filter #(
    parameter DATA_WIDTH  = 12,   // input sample width
    parameter COEFF_WIDTH = 16,   // Q1.15
    parameter TAPS        = 8
)(
    input  wire                          clk,
    input  wire                          rst_n,     // active-low reset
    input  wire                          data_valid,// input sample valid
    input  wire signed [DATA_WIDTH-1:0]  data_in,
    output reg                           out_valid,
    output reg  signed [DATA_WIDTH+COEFF_WIDTH-1:0] data_out
);

    // -----------------------------------------------------------
    // coefficients (Q1.15 format, i.e. value*32768)
    // -----------------------------------------------------------
    localparam signed [COEFF_WIDTH-1:0] COEFF_0 = 16'sd117;  // h[0]
    localparam signed [COEFF_WIDTH-1:0] COEFF_1 = 16'sd1248; // h[1]
    localparam signed [COEFF_WIDTH-1:0] COEFF_2 = 16'sd5277; // h[2]
    localparam signed [COEFF_WIDTH-1:0] COEFF_3 = 16'sd9743; // h[3]
    localparam signed [COEFF_WIDTH-1:0] COEFF_4 = 16'sd9743; // h[4]
    localparam signed [COEFF_WIDTH-1:0] COEFF_5 = 16'sd5277; // h[5]
    localparam signed [COEFF_WIDTH-1:0] COEFF_6 = 16'sd1248; // h[6]
    localparam signed [COEFF_WIDTH-1:0] COEFF_7 = 16'sd117;  // h[7]

    // Coefficient array (for iteration in synthesis-friendly form)
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
    // Shift register (tapped delay line) holding last TAPS samples
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
    // Multiply-Accumulate (MAC)
    // -----------------------------------------------------------
    reg signed [DATA_WIDTH+COEFF_WIDTH-1:0] mac_sum;

    always @(*) begin
        mac_sum = 0;
        for (i = 0; i < TAPS; i = i + 1)
            mac_sum = mac_sum + (shift_reg[i] * coeff[i]);
    end

    // -----------------------------------------------------------
    // Output register + valid pipeline (1 cycle latency)
    // -----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= 0;
            out_valid <= 1'b0;
        end else begin
            data_out  <= mac_sum;
            out_valid <= data_valid;
        end
    end

endmodule
