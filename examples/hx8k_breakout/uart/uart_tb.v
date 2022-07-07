`default_nettype none
`timescale 1ns/1ps

`ifndef UART_CLOCK_DELAY
  // Use this to test skew, but delayed assignments don't seem to work in
  // iverilog.
  `define UART_CLOCK_DELAY 10ns
`endif

module uart_tb #(
  parameter UART_DATA_BITS=8,
  parameter PARITY_BITS=0,
  parameter STOP_BITS=1,
  // NOTE: This baud rate is unrealistically high for the sake of making the
  // testbench run faster.
  parameter BAUD_RATE_BPS = 3_000_000, // bits per second
  parameter BAUD_RATE_COUNT = 12_000_000 / BAUD_RATE_BPS,
  parameter FRAME_SIZE = 1 /* start */ + UART_DATA_BITS /* data */ +
                          PARITY_BITS /* parity */ + STOP_BITS /* stop */
);
  // 12 MHz clock
  localparam CLK_PERIOD = 83.3333;
  localparam UART_CLK_PERIOD = 1.0 / (BAUD_RATE_BPS) * 1_000_000_000; 
  localparam NUM_TEST_FRAMES = 10;
  reg [FRAME_SIZE-1:0] test_frames [0:NUM_TEST_FRAMES-1];

  reg clk = 1'b0;
  reg uart_clk = 1'b0;

  wire uart0_txd;
  wire uart0_rts;
  wire [7:0] led;

  reg uart0_cts = 1'b1;
  reg uart0_rxd = 1'b0;

  uart #(
    .UART_DATA_BITS(UART_DATA_BITS),
    .PARITY_BITS(PARITY_BITS),
    .STOP_BITS(STOP_BITS),
    .BAUD_RATE_BPS(BAUD_RATE_BPS)
  ) dut (
    .clk(clk),
    .led0(led[0]),
    .led1(led[1]),
    .led2(led[2]),
    .led3(led[3]),
    .led4(led[4]),
    .led5(led[5]),
    .led6(led[6]),
    .led7(led[7]),
    .uart0_cts(uart0_cts),
    .uart0_txd(uart0_txd),
    .uart0_rxd(uart0_rxd),
    .uart0_rts(uart0_rts)
  );

  always begin
    #(CLK_PERIOD/2) clk = ~clk;
  end

  always begin
    #(UART_CLK_PERIOD/2) uart_clk = ~uart_clk;
  end

  initial begin
    $dumpfile("waves_uart.vcd");
    $dumpvars;
    $display ("Starting UART test...");
    // Wait for resets
    $display ("Waiting for internal reset deassertion at ", $time, "ns");
    wait (dut.resetn === 1'b1);
    @(posedge clk);
    $display ("DUT internal reset has been deasserted at ", $time, "ns");

    if (uart0_rts != 1'b1) begin
      // This should really be an SV assertion but I can't figure out how to
      // get it to work with iverilog.
      $error("Expected RTS# to be 1 after reset");
      $finish;
    end

    repeat (20) @(posedge clk);

    // Generate a bunch of test data
    for (int i = 0; i < NUM_TEST_FRAMES; i = i + 1) begin
      test_frames[i][0] = 1'b1; // Start bit always 1
      test_frames[i][1 +: UART_DATA_BITS] = $random() & {UART_DATA_BITS{1'b1}};
      if (PARITY_BITS > 0) begin
        test_frames[i][1+UART_DATA_BITS +: PARITY_BITS] = {PARITY_BITS{1'b0}};
      end
      test_frames[i][1+UART_DATA_BITS+PARITY_BITS +: STOP_BITS] = {STOP_BITS{1'b1}};
      $display("Frame %d data: %x", i, test_frames[i]);
    end 

    uart0_cts = 1'b1;
    $display ("Waiting for next UART clock rising edge.");
    @(posedge uart_clk);
    #1ps;
    // Bit-bang the data through UART.
    for (int i = 0; i < NUM_TEST_FRAMES; i = i + 1) begin
      for (int j = 0; j < FRAME_SIZE; j = j + 1) begin
        $display ("UART sending frame %d bit %d (1'b%d) at %d ns", i, j, test_frames[i][j], $time);
        uart0_rxd = test_frames[i][j];
        uart0_cts = 1'b0;
        @(posedge uart_clk);
      end
      // End of frame check
      // After 10 fast-clock cycles, check that the expected data is
      // correct.
      repeat (10) @(posedge clk);
      if (led != test_frames[i][8:1]) begin
        $error("Frame %d: Expected %x, got %x", i, test_frames[i][8:1], led);
        //$finish;
      end
    end
    // Deassert CTS
    uart0_cts = 1'b1;

    // Everything OK here.
    $display ("DONE!");
    $finish;
  end

endmodule

`resetall
