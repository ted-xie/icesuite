`default_nettype none
module uart #(
  parameter UART_DATA_BITS=8,
  parameter PARITY_BITS=0,
  parameter STOP_BITS=1
) (
  input wire clk,
  output wire led0,
  output wire led1,
  output wire led2,
  output wire led3,
  output wire led4,
  output wire led5,
  output wire led6,
  output wire led7,
  input wire uart0_cts,
  output wire uart0_txd,
  input wire uart0_rxd,
  output wire uart0_rts
);
  localparam BAUD_RATE_BPS = 9600; // bits per second
  localparam BAUD_RATE_COUNT = 12_000_000 / BAUD_RATE_BPS;
  localparam FRAME_SIZE = 1 /* start */ + UART_DATA_BITS /* data */ +
                          PARITY_BITS /* parity */ + STOP_BITS /* stop */;
  localparam FRAME_IDX_BITS = $clog2(FRAME_SIZE);
  localparam RESET_CYCLES = 100;
  localparam SYNC_STAGES = 3;

  // Flops reset by the fabric
  reg [31:0] counter_baud = 'h0;
  reg [15:0] counter_freerunning = 'h0;
  // Resettable flops
  reg uart0_txd_r;
  reg uart0_rts_r;
  reg [FRAME_SIZE:0] uart0_rx_frame;
  reg [FRAME_IDX_BITS-1:0] uart0_rx_idx;
  // Nonresettable flops
  reg [SYNC_STAGES-1:0] uart0_cts_sync_regs;
  reg [SYNC_STAGES-1:0] uart0_rxd_sync_regs;
  // Wire declarations
  // Assert reset for the first 100 cycles after configuration.
  wire resetn = (counter_freerunning < RESET_CYCLES) ? 1'b0 : 1'b1;
  wire uart0_cts_sync = uart0_cts_sync_regs[SYNC_STAGES-1];
  wire uart0_rxd_sync = uart0_rxd_sync_regs[SYNC_STAGES-1];
  assign uart0_txd = uart0_txd_r;
  assign uart0_rts = uart0_rts_r;
  assign {led7, led6, led5,led4,led3,led2,led1,led0} = uart0_rx_frame[FRAME_SIZE-STOP_BITS-PARITY_BITS-1:1];

  // Freerunning counter used to generate the reset.
  always @(posedge clk) begin
    counter_freerunning <= counter_freerunning + 1'b1;
  end

  // Synchronizer process for UART input pins.
  genvar sync_i;
  generate
    for (sync_i = 0; sync_i < SYNC_STAGES; sync_i = sync_i + 1) begin
      // FIXME Currently throws a lint violation due to selection index.
      if (sync_i == 0) begin
        always @(posedge clk) begin
          // Flop index 0 is the raw input signal.
          uart0_cts_sync_regs[sync_i] <= uart0_cts;
          uart0_rxd_sync_regs[sync_i] <= uart0_rxd;
        end
      end else begin
        always @(posedge clk) begin
          uart0_cts_sync_regs[sync_i] <= uart0_cts_sync_regs[sync_i-1];
          uart0_rxd_sync_regs[sync_i] <= uart0_rxd_sync_regs[sync_i-1];
        end
      end
    end
  endgenerate

  // Generates the control signal to sample the data
  always @(posedge clk) begin
    // No reset for counter_baud - it is set to 0 during bitfile programming
    // (see its initial assignment above).
    if (counter_baud == (BAUD_RATE_COUNT/2 - 1))
      counter_baud <= 32'h0;
    else
      counter_baud <= counter_baud + 1'b1;
  end

  always @(posedge clk) begin
    if (~resetn) begin
      uart0_txd_r <= 1'b0;
      // RTS# is active-low on the FTDI chip.
      uart0_rts_r <= 1'b1;
    end
  end

  always @(posedge clk) begin
    if (~resetn) begin
      uart0_rx_frame <= 'h0;
      uart0_rx_idx <= 'h0;
    end else begin
      if (uart0_cts_sync == 1'b0) begin
        uart0_rx_frame[uart0_rx_idx] <= uart0_rxd_sync;
        if (uart0_rx_idx < FRAME_SIZE-1) begin
          uart0_rx_idx <= uart0_rx_idx + 1'b1;
        end else begin
          uart0_rx_idx <= 'h0;
        end
      end 
    end
  end

endmodule
`resetall
