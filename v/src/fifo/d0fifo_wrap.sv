/*
   Revisions:
      10/08/21: First Documentation, changed AL_FULL parameter to SIZE
*/
module d0fifo_wrap # (
   parameter WIDTH = 16,
   parameter SIZE  = 32
) 
(
   input                          clk,
   input                          rst_n,
   input                          push,
   input                          pop,
   input         [WIDTH - 1 : 0]  wdata,
   output  logic [WIDTH - 1 : 0]  rdata,
   output  logic                  full,
   output  logic                  empty,
   output  logic                  valid
);

   logic al_empty, ack;
   logic flush, al_full;
     
// no flushing because expecting all FFT to be consumed  
   assign flush = 0;
   d0fifo #(
      .WIDTH(WIDTH),
      .SIZE(SIZE),
      .FULL(1),
      .EMPTY(1),
      .AL_FULL(SIZE),
      .AL_EMPTY(0),
      .ACK(0),
      .VALID(1),
      .PEEK(0),
      .FLUSH(0)
   )d1(.*);

endmodule
