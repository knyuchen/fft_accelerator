/*
  Special PE for 2 point stage

  if ready is one, it will get data in the same cycle
  in --> in_latch latency is 1
  Butterfly latency is 2 
  --> total_latency is 3, after ready is 0, 3 pairs will come out
  In theory, afifo & mfifo should be at least 4 (using aout_empty as inter_ready)

  latency from output_ready to out is 1 cycle

  Revisions:
    10/12/21:
       First Documentation,
       fix shifting, needs to be signed logic first
       May want to make the buffer size smaller in the future, don't change for now
*/

module PE_2 (
   input              clk,
   input              rst_n,
   input FFT_DATA_BUS  in,
   output FFT_DATA_BUS out,
   output logic        inter_ready,
// input ready from output buffer
   input               output_ready,
   input              select, // select should indicate if this PE is "activated" or not 
   input  [1:0]       scaling
);
   FFT_DATA_BUS real_in, out_pre, out_pre_real;

/*
   real_in goes into in_latch --> compute
   input gating
*/
   assign real_in = (select == 1) ? in : 0;
/*
   Feeding through or passing output
*/
   assign out_pre_real = (select == 1) ? out_pre : in;

   logic mout_push, mout_pop, aout_push, aout_pop, in_valid, mout_valid, aout_valid;
   logic mout_full, aout_full, mout_empty, aout_empty;

   FFT_DATA_SAMPLE  mout_wdata, mout_rdata, aout_wdata, aout_rdata;

   FFT_DATA_BUS in_latch;
   logic flag, flag_w;
   FFT_DATA_BUS  up, down, add_out, sub_out, temp, temp_w;
`ifdef YET_ANOTHER   
   assign inter_ready = aout_empty == 1 && mout_empty == 1;
`else
   assign inter_ready = aout_empty == 1;
`endif

   logic  out_count_w, out_count, out_flag, out_flag_w;

   always_comb begin
      out_flag_w = out_flag;
/*
   counting aout_valid / mout_valid to flip flags
   fifo are all d0 fifos, no delay issues
*/
      if (out_flag == 0) begin
`ifdef ANOTHER
         if (aout_valid == 1) begin
`else
         if (aout_pop == 1) begin
`endif
             out_flag_w = 1;
         end
      end
      else begin
`ifdef ANOTHER
         if (mout_valid == 1) begin
`else
         if (mout_pop == 1) begin
`endif
             out_flag_w = 0;
         end
      end
   end
/*
   go means can compute
*/
   logic go;

   assign go = flag == 1 && in_latch.valid == 1;

   assign up = (go == 1) ? temp : 0;
   assign down = (go == 1) ? in_latch : 0;

/*
   everything goes to in_latch
   down stays in in_latch
   up move from in_latch to temp when up arrives in in_latch
*/
   always_comb begin
      flag_w = flag;
      temp_w = temp;
// up arrives, copy it into temp
      if (flag == 0 && in_latch.valid == 1) begin
         flag_w = 1;
         temp_w = in_latch;
      end
// down arrives, can compute
      else if (flag == 1 && in_latch.valid == 1) flag_w = 0;
   end
 
   pipe_reg #(
      .WIDTH($bits(FFT_DATA_BUS)),
      .STAGE(1)
   ) pipe_in 
   (
      .in(real_in),
      .out(in_latch),
      .*
   );
   
      assign mout_wdata = sub_out.data;
      assign mout_push  = sub_out.valid;
`ifndef ANOTHER
      assign mout_pop   = output_ready && out_flag == 1 && mout_empty == 0;
`else
// enable feedthrough
      assign mout_pop   = output_ready && out_flag == 1;
`endif      
      assign aout_wdata = add_out.data;
      assign aout_push  = add_out.valid;
`ifndef ANOTHER
      assign aout_pop   = output_ready && out_flag == 0 && aout_empty == 0;
`else
// enable feedthrough so that inter_ready doesn't go to 0 unnecessarily
      assign aout_pop   = output_ready && out_flag == 0;
`endif     
 
      d0fifo_wrap #(.WIDTH($bits(FFT_DATA_SAMPLE)), .SIZE(8))  mfifo_out (
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


   pipe_reg #(
      .WIDTH($bits(FFT_DATA_BUS)),
      .STAGE(1)
   ) pipe_out 
   (
      .in(out_pre_real),
      .out(out),
      .*
   );

   butterfly_2 b1
   
   ( 
      .up(up),
      .down(down),
      .add_out(add_out),
      .sub_out(sub_out),
      .*
   ); 

   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         flag <= 0;
         temp <= 0;
         out_flag <= 0;
      end
      else begin
         out_flag <= out_flag_w;
         flag <= flag_w;
         temp <= temp_w;
      end
   end

endmodule 
