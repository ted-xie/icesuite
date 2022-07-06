`default_nettype none
module uart #(
  parameter UART_DATA_BITS=8,
  parameter PARITY_BITS=0,
  parameter STOP_BITS=1
) (
  input wire ice_clk,
  output wire [7:0] led,
  input wire uart0_cts,
  output wire uart0_txd,
  input wire uart0_rxd,
  output wire uart0_rts
);
  localparam BAUD_RATE_BPS = 9600; // bits per second
  localparam BAUD_RATE_COUNT = 12_000_000 / BAUD_RATE_BPS;
  localparam RESET_CYCLES = 100;
  localparam SYNC_STAGES = 3;

  reg [31:0] counter_baud = 'h0;
  reg [15:0] counter_freerunning = 'h0;
  reg [SYNC_STAGES-1:0] uart0_cts_sync_regs;
  reg [SYNC_STAGES-1:0] uart0_rxd_sync_regs;
  // Assert reset for the first 100 cycles after configuration.
  wire resetn = (counter_freerunning < RESET_CYCLES) ? 1'b0 : 1'b1;

  // Freerunning counter used to generate the reset.
  always @(posedge ice_clk) begin
    counter_freerunning <= counter_freerunning + 1'b1;
  end

  // Synchronizer process for UART input pins.
  genvar sync_i;
  generate
    for (sync_i = 0; sync_i < SYNC_STAGES; sync_i = sync_i + 1) begin
      // FIXME Currently throws a lint violation due to selection index.
      if (sync_i == 0) begin
        always @(posedge ice_clk) begin
          // Flop index 0 is the raw input signal.
          uart0_cts_sync_regs[sync_i] <= uart0_cts;
          uart0_rxd_sync_regs[sync_i] <= uart0_rxd;
        end
      end else begin
        always @(posedge ice_clk) begin
          uart0_cts_sync_regs[sync_i] <= uart0_cts_sync_regs[sync_i-1];
          uart0_rxd_sync_regs[sync_i] <= uart0_rxd_sync_regs[sync_i-1];
        end
      end
    end
  endgenerate

  // Generates the control signal to sample the data
  always @(posedge ice_clk) begin
    if (counter_baud == (BAUD_RATE_COUNT/2 - 1))
      counter_baud <= 32'h0;
    else
      counter_baud <= counter_baud + 1'b1;
  end

  always @(posedge ice_clk) begin

  end

endmodule
`resetall
