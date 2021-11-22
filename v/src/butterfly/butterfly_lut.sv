/*
   add_out = add_up + add_down;
   mult_out = twiddle * (sub_up - sub_down)
   
   C0: add_up, add_down both ready
   C1: add_out is ready

   C0: sub_up, sub_down both ready
   C1: mult_valid, (should also consider twiddle valid)
   C3: mult_out is ready
   
*/

module butterfly # (
   parameter POINT = 8,
   parameter SET   = $clog2(POINT)
)
(
//   input   [$clog2(POINT) - 2 : 0]    lut_index,
   input   FFT_DATA_BUS  up,
   input   FFT_DATA_BUS  down,
   input                 clk,
   input                 rst_n,
   output  FFT_DATA_BUS   add_out,
   output  FFT_DATA_BUS   mult_out
);

   FFT_DATA_SAMPLE  twiddle;

   FFT_DATA_SAMPLE add_opa, add_opb, sub_opa, sub_opb, mult_opa, mult_opb;
   FFT_DATA_SAMPLE sub_out;
   logic mult_valid;

   logic [$clog2(POINT) - 2 : 0]  lut_index_w, lut_index;

   assign lut_index_w = (up.valid && down.valid) ? lut_index + 1 : lut_index;

   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         lut_index <= 0;
      end
      else begin
         lut_index <= lut_index_w;
      end
   end

/*
   input gating
*/
   assign add_opa = (up.valid == 1) ? up.data   : 0;
   assign add_opb = (down.valid == 1) ? down.data : 0;
   assign sub_opa = (up.valid == 1) ? up.data   : 0;
   assign sub_opb = (down.valid == 1) ? down.data : 0;
   assign mult_opa = (mult_valid == 1)? sub_out : 0;
   assign mult_opb = (mult_valid == 1)? twiddle : 0;
     
   pipe_reg #(
      .WIDTH(1),
      .STAGE(2)
   ) pipe_add_valid 
   ( 
      .in(up.valid&&down.valid),
      .out(add_out.valid),
      .*
   );
   pipe_reg #(
      .WIDTH(1),
      .STAGE(2)
   ) pipe_sub_valid 
   ( 
      .in(up.valid&&down.valid),
      .out(mult_valid),
      .*
   );
   pipe_reg #(
      .WIDTH(1),
      .STAGE(4)
   ) pipe_mult_valid 
   ( 
      .in(mult_valid),
      .out(mult_out.valid),
      .*
   );


   FFT_cmult m1 (
      .*,
      .opa(mult_opa),
      .opb(mult_opb),
      .out(mult_out_pre)
   ); 

   FFT_cadd a1 (
      .opa(add_opa),
      .opb(add_opb),
      .out(add_out.data)
   ); 

   FFT_csub s1 (
      .opa(sub_opa),
      .opb(sub_opb),
      .out(sub_out)
   ); 

   lut #(
      .POINT(POINT)
   ) l1 
   (
      .*,
      .idx(lut_index),
      .twiddle (twiddle)
   );

endmodule
