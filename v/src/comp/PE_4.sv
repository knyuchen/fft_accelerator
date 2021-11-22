/*
   Special PE for 4 points
   Latency from last stage : 0
   Latency from input_latch : 1
   Latency from butterfly : 2
   aout / mout should have depth of at least 4

   output latency, 1 


   Revisions:
     10/12/21:
       First Documentation
       Might want to change fifo depth in the future
*/

module PE_4 (
   input              clk,
   input              rst_n,
   input FFT_DATA_BUS  in,
   output FFT_DATA_BUS out,
   output logic        inter_ready,
   input               output_ready,
   input              select, // select should indicate if this PE is "activated" or not 
   input  [1:0]       scaling
);
   FFT_DATA_BUS real_in, out_pre, out_pre_real;

/*
   input gating of input for compute / output selection
*/
   assign real_in = (select == 1) ? in : 0;
   assign out_pre_real = (select == 1) ? out_pre : in;


   FFT_DATA_BUS in_latch;
   logic [1:0] flag, flag_w;
   FFT_DATA_BUS  up, down, add_out, sub_out;
/*
   2 temps since we need to delay by 2
*/ 
   FFT_DATA_BUS  temp1, temp1_w;
   FFT_DATA_BUS  temp2, temp2_w;

   logic switch;

   logic mout_push, mout_pop, aout_push, aout_pop, mout_valid, aout_valid;
   logic mout_full, aout_full, mout_empty, aout_empty;
`ifdef YET_ANOTHER
   assign inter_ready = aout_empty == 1 && mout_empty == 1;
`else
   assign inter_ready = aout_empty == 1;
`endif
   FFT_DATA_SAMPLE  in_wdata, in_rdata, mout_wdata, mout_rdata, aout_wdata, aout_rdata;

   logic  out_count_w, out_count, out_flag, out_flag_w;
/*
   using aout_valid / mout_valid count to flip flag
   use actual data out counts instead of pops
*/
   always_comb begin
      out_flag_w = out_flag;
      out_count_w = out_count;
      if (out_flag == 0) begin
`ifdef ANOTHER
         if (aout_valid == 1) begin
`else
         if (aout_pop == 1) begin
`endif
            out_count_w = out_count + 1;
            if (out_count == 1) out_flag_w = 1;
         end
      end
      else begin
`ifdef ANOTHER
         if (mout_valid == 1) begin
`else
         if (mout_pop == 1) begin
`endif
            out_count_w = out_count + 1;
            if (out_count == 1) out_flag_w = 0;
         end
      end
   end
   always_comb begin
      up = 0;
      switch = 0;
      down = 0;
      flag_w = flag;
      temp1_w = temp1;
      temp2_w = temp2;
      if (in_latch.valid == 1) begin
      case (flag)
/*
   first one, move to temp1
*/
         0:begin
            temp1_w = in_latch;
            flag_w = 1;
         end
/*
   second one, move to temp 2
*/
         1:begin
            temp2_w = in_latch;
            flag_w = 2;
         end
         2:begin
            flag_w = 3;
            up = temp1;
            down = in_latch;
         end
         3:begin
            flag_w = 0;
            switch = 1;
            up = temp2;
            down = in_latch;
         end
         default:begin
         end
      endcase 
      end
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
      assign mout_pop   = output_ready && out_flag == 1;
`endif      
      
      assign aout_wdata = add_out.data;
      assign aout_push  = add_out.valid;
`ifndef ANOTHER
      assign aout_pop   = output_ready && out_flag == 0 && aout_empty == 0;
`else
/*
   allows feedthrough
*/
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

   butterfly_4 b1
   
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
         temp1 <= 0;
         temp2 <= 0;
         out_flag <= 0;
         out_count <= 0;
      end
      else begin
         flag <= flag_w;
         temp1 <= temp1_w;
         temp2 <= temp2_w;
         out_flag <= out_flag_w;
         out_count <= out_count_w;
      end
   end

endmodule 
