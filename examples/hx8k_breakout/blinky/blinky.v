module blinky (
  input wire clk, // assume 12 MHz
  output wire led0,
  output wire led1,
  output wire led2
);
  localparam COUNTER_SIZE = 32;
  reg [COUNTER_SIZE-1:0] ctr = {COUNTER_SIZE{1'b0}};

  assign led0 = ctr[21]; // 0.2 seconds
  assign led1 = ctr[22]; // 0.4 seconds
  assign led2 = ctr[23]; // 0.8 seconds

  always @(posedge clk) begin
    ctr <= ctr + 1'b1;
  end

endmodule
