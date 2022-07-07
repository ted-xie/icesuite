`default_nettype none
`timescale 1ns/1ps

module uart_tb #(
  parameter UART_DATA_BITS=8,
  parameter PARITY_BITS=0,
  parameter STOP_BITS=1,
  parameter BAUD_RATE_BPS = 9600, // bits per second
  parameter BAUD_RATE_COUNT = 12_000_000 / BAUD_RATE_BPS,
  parameter FRAME_SIZE = 1 /* start */ + UART_DATA_BITS /* data */ +
                          PARITY_BITS /* parity */ + STOP_BITS /* stop */
);
  // 12 MHz clock
  localparam CLK_PERIOD = 83.3333;
  reg clk = 1'b0;

  wire uart0_txd;
  wire uart0_rts;
  wire [7:0] led;

  reg uart0_cts = 'h0;
  reg uart0_rxd = 'h0;

  reg [FRAME_SIZE-1:0] uart0_frame = 'h0;

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

  initial begin
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

    // Everything OK here.
    $display ("DONE!");
    $finish;
  end

endmodule

`resetall
