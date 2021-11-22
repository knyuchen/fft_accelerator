/*
   add_out = add_up + add_down;
   mult_out = twiddle * (sub_up - sub_down)
   twiddle factor is self generated
   add latency: 2 cycle 
   sub latency: 2 cycle
   mult latency: 4 cycle
   twidle latency: 0 cycle --> using mult_valid as valid
   up latency: 2 cycle
   down latency 6 cycle     
   Revisions:
      10/11/21: First Documentation
*/

module butterfly # (
   parameter SET   = 4 
)
(
   input   FFT_DATA_BUS  up,
   input   FFT_DATA_BUS  down,
   input                 clk,
   input                 rst_n,
   output  FFT_DATA_BUS   add_out,
   output  FFT_DATA_BUS   mult_out
);

   FFT_DATA_SAMPLE  twiddle;

   FFT_DATA_SAMPLE add_opa, add_opb, sub_opa, sub_opb, mult_opa, mult_opb, mult_out_pre;
   FFT_DATA_SAMPLE sub_out;
   logic mult_valid;

/*
   input gating
*/
   assign add_opa = (up.valid == 1 && down.valid) ? up.data   : 0;
   assign add_opb = (up.valid == 1 && down.valid) ? down.data : 0;
   assign sub_opa = (up.valid == 1 && down.valid) ? up.data   : 0;
   assign sub_opb = (up.valid == 1 && down.valid) ? down.data : 0;
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
      .out(add_out.data),
      .*
   ); 

   FFT_csub s1 (
      .opa(sub_opa),
      .opb(sub_opb),
      .out(sub_out),
      .*
   );
   assign mult_out.data = mult_out_pre; 
generate if (SET == 3) begin : eight_point
   FFT_twiddle_8 #(
      .SET(3)
   ) l1 
   (
      .*,
      .valid(mult_valid),
      .out (twiddle)
   );
end else begin : other_points
   FFT_twiddle #(
      .SET(SET)
   ) l1 
   (
      .*,
      .valid(mult_valid),
      .out (twiddle)
   );
 
end endgenerate
endmodule
