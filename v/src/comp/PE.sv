/*
   C0 : in --> real_in (select)
   C1 : real_in --> in_latch  (pop)
   C3 : in_latch --> down_latch
   C3 : input buffer data come out

   input latency: 1 cycle
   previous input latency: 2 cycles
   butterfly latency: 2 cycle / 6 cycle

   output latency: 1 / 3 cycle

   Revisions:
     10/12/21:
       First Documentation
       Might want to use mout_full as inter_ready in the future 
*/
module PE #(
      parameter SET = 10,
      parameter POINT = 2**SET,
      parameter SRAM  = (POINT > 120) ? `FFT_SRAM : 0,
      parameter MOUT_SIZE = (POINT > 16) ? POINT / 2 : 8
) 
(
   input               clk,
   input               rst_n,
   input  FFT_DATA_BUS in,
   output FFT_DATA_BUS out,
   output logic        inter_ready,
   input               output_ready,
   input               select, // select should indicate if this PE is "activated" or not 
   input  [1:0]        scaling
);
   FFT_DATA_BUS real_in, out_pre, out_pre_real;

   logic in_push, in_pop, mout_push, mout_pop, aout_push, aout_pop, in_valid, mout_valid, aout_valid;
   logic in_full, mout_full, aout_full, in_empty, mout_empty, aout_empty;

   FFT_DATA_SAMPLE  in_wdata, in_rdata, mout_wdata, mout_rdata, aout_wdata, aout_rdata;

   logic [SET-2 : 0] out_count_w, out_count;
   logic [SET-2 : 0] pop_count_w, pop_count;


   d1fifo_wrap #(.WIDTH($bits(FFT_DATA_SAMPLE)), .SIZE(POINT/2), .SRAM(SRAM))  fifo_in (
      .wdata(in_wdata),
      .rdata(in_rdata),
      .push(in_push),
      .pop(in_pop),
      .valid(in_valid),
      .full(in_full),
      .empty(in_empty),
      .*
   );

   assign real_in = (select == 1) ? in : 0;
   assign out_pre_real = (select == 1) ? out_pre : in;


   FFT_DATA_BUS in_latch, down_latch;
   logic flag, flag_w;
   
   pipe_reg #(
      .WIDTH($bits(FFT_DATA_BUS)),
      .STAGE(1)
   ) pipe_in 
   (
      .in(real_in),
      .out(in_latch),
      .*
   );
/*
   2 stages to accomodate for 2 cyles of d1spfifo delay
*/   
   pipe_reg #(
      .WIDTH($bits(FFT_DATA_BUS)),
      .STAGE(2)
   ) pipe_down 
   (
      .in(in_latch),
      .out(down_latch),
      .*
   );

   FFT_DATA_BUS up, add_out, mult_out, add_out_d;

   assign up.valid = in_valid;
   assign in_wdata = in_latch.data;
   assign up.data  = in_rdata;
   
   
   logic in_flag, in_flag_w;
   logic [1:0] out_flag, out_flag_w;
//   assign out_w.data = mult_out.data;
`ifdef YET_ANOTHER
   assign inter_ready = aout_empty == 1 && mout_full == 0;
`else
   assign inter_ready = aout_empty == 1;
`endif
/*
  a delay exists between full / empty & in_flag flipping
*/
   always_comb begin
      in_flag_w = in_flag;
      if (in_flag == 0) begin
         in_flag_w = in_full;
      end
      else begin
         in_flag_w = ~in_empty;
      end
   end
   always_comb begin
      out_flag_w = out_flag;
      out_count_w = out_count;
      pop_count_w = pop_count;
      if (out_flag == 0) begin
`ifdef ANOTHER
         if (aout_valid == 1) begin
`else 
         if (aout_pop == 1) begin
`endif
            out_count_w = out_count + 1;
            if (out_count == 2**(SET-1) - 1) out_flag_w = 1;
         end
      end
/*
  use two counters
  one to count mout_pop
  one to count mout_valid
  mout_pop will reach threshold first
*/
      else if (out_flag == 1) begin
`ifdef ANOTHER
         if (mout_valid == 1) begin
            out_count_w = out_count + 1;
         end
         if (mout_pop == 1) begin
            pop_count_w = pop_count + 1;
            if (pop_count == 2**(SET-1) - 1) out_flag_w = 2;
         end
`else 
         if (mout_pop == 1) begin
            out_count_w = out_count + 1;
            if (out_count == 2**(SET-1) - 1) out_flag_w = 0;
         end
`endif
      end
/*
  output the residue of mout
  protect it from aout_valid
*/
      else begin
         if (mout_valid == 1) begin
            out_count_w = out_count + 1;
            if (out_count == 2**(SET-1) - 1) out_flag_w = 0;
         end
      end
   end

   always_comb begin
      in_push = 0;
      in_pop = 0;
/*
  in_flag hasn't flipped & in_flag about to flip
*/
      if ((in_flag == 0 && in_full == 0) || (in_flag == 1 && in_empty == 1)) begin
         in_push = in_latch.valid;
      end
      if ((in_flag == 0 && in_full == 1) || (in_flag == 1 && in_empty == 0)) begin
         in_pop = in_latch.valid;
      end
   end
   
//   generate if (POINT > 8) begin  : larger_point
      assign mout_wdata = mult_out.data;
      assign mout_push  = mult_out.valid;
      assign mout_pop   = output_ready && out_flag == 1 && mout_empty == 0;
      
      assign aout_wdata = add_out.data;
      assign aout_push  = add_out.valid;
`ifdef ANOTHER
      assign aout_pop   = output_ready && out_flag == 0;
`else
      assign aout_pop   = output_ready && out_flag == 0 && aout_empty == 0;
`endif     
 
      d1fifo_wrap #(.WIDTH($bits(FFT_DATA_SAMPLE)), .SIZE(MOUT_SIZE), .SRAM(SRAM))  mfifo_out (
         .wdata(mout_wdata),
         .rdata(mout_rdata),
         .push(mout_push),
         .pop(mout_pop),
         .valid(mout_valid),
         .full(mout_full),
         .empty(mout_empty),
         .*
      );
      d0fifo_wrap #(.WIDTH($bits(FFT_DATA_SAMPLE)), .SIZE(8))  afifo_out (
         .wdata(aout_wdata),
         .rdata(aout_rdata),
         .push(aout_push),
         .pop(aout_pop),
         .valid(aout_valid),
         .full(aout_full),
         .empty(aout_empty),
         .*
      );
      logic signed [`FFT_DATA_WIDTH - 1 : 0] a_data_r, a_data_i, m_data_r, m_data_i;

      assign a_data_r = aout_rdata.data_r;
      assign a_data_i = aout_rdata.data_i;
      assign m_data_r = mout_rdata.data_r;
      assign m_data_i = mout_rdata.data_i;

      assign out_pre.data.data_r = (aout_valid == 1) ? a_data_r >>> scaling : m_data_r >>> scaling; 
      assign out_pre.data.data_i = (aout_valid == 1) ? a_data_i >>> scaling : m_data_i >>> scaling;
      assign out_pre.valid = aout_valid || mout_valid;
/*        
   end
   else begin : smaller_point
      assign out_pre.data.data_r = (add_out.valid == 1) ? add_out.data.data_r >>> scaling : mult_out.data.data_r >>> scaling; 
      assign out_pre.data.data_i = (add_out.valid == 1) ? add_out.data.data_i >>> scaling : mult_out.data.data_i >>> scaling;
      assign out_pre.valid = add_out.valid || mult_out.valid;
   end endgenerate
*/
   pipe_reg #(
      .WIDTH($bits(FFT_DATA_BUS)),
      .STAGE(1)
   ) pipe_out 
   (
      .in(out_pre_real),
      .out(out),
      .*
   );

   butterfly #(
      .SET(SET)
   )b1
   ( 
      .up(up),
      .down(down_latch),
      .add_out(add_out),
      .mult_out(mult_out),
      .*
   ); 

   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         in_flag <= 0;
         out_flag <= 0;
         out_count <= 0;
         pop_count <= 0;
      end
      else begin
         in_flag <= in_flag_w;
         out_flag <= out_flag_w;
         out_count <= out_count_w;
         pop_count <= pop_count_w;
      end
   end

endmodule 
