/*
  PE full, connecting PEs with output buffer
  input latency: 1 / 3 cycles
  output latency: 0 cycle
*/
module PE_full # (
      parameter SET = 3
)
(
   input               clk,
   input               rst_n,
   input  FFT_DATA_BUS in,
   output FFT_DATA_BUS out,
   input               next_ready,
   output logic        ready,
   input               select, // select should indicate if this PE is "activated" or not 
   input  [1:0]        scaling
);

   FFT_DATA_BUS      fft_in, fft_out;

   logic   full, empty, valid;
   logic   push, pop;
   logic [$bits(FFT_DATA_SAMPLE) - 1 : 0]  wdata, rdata;
   logic   inter_ready;

   d0fifo_wrap #(.SIZE(4), .WIDTH($bits(FFT_DATA_SAMPLE))) d1 (.*);  

generate if (SET > 2) begin
   PE # (.SET(SET)) p1
      (
         .*,
         .in(fft_in),
         .out(fft_out),
         .output_ready(empty)
      );
end else if (SET == 2) begin
   PE_4  p1
      (
         .*,
         .in(fft_in),
         .out(fft_out),
         .output_ready(empty)
      );
end else if (SET == 1) begin
   PE_2 p1
      (
         .*,
         .in(fft_in),
         .out(fft_out),
         .output_ready(empty)
      );
end endgenerate
   
   assign  out.valid = valid;
`ifdef YET_ANOTHER
   assign  ready = inter_ready;
`else
   assign  ready = empty && inter_ready;
`endif
   assign  pop = next_ready;
   assign  push = fft_out.valid;
   assign  wdata = fft_out.data;
   assign  out.data = rdata;
   assign  fft_in = in;

endmodule
