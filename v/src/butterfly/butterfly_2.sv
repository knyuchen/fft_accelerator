/*
  2 point only does +,-
  + goes out first, latency is 2 
   Revisions:
      10/10/21: First Documentation
*/

module butterfly_2 
(
   input   FFT_DATA_BUS  up,
   input   FFT_DATA_BUS  down,
   input                 clk,
   input                 rst_n,
   output  FFT_DATA_BUS   add_out,
   output  FFT_DATA_BUS   sub_out
);


   FFT_DATA_SAMPLE add_opa, add_opb, sub_opa, sub_opb;

   FFT_DATA_BUS  up_d, down_d;

/*
   input gating, the input of subtractor is delayed
*/
   assign add_opa = (up.valid == 1) ? up.data   : 0;
   assign add_opb = (down.valid == 1) ? down.data : 0;
   assign sub_opa = (up_d.valid == 1) ? up_d.data   : 0;
   assign sub_opb = (down_d.valid == 1) ? down_d.data : 0;
/*
   pipelining valid signal to become done signal, accounting for adder latency
*/     
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
      .in(up_d.valid&&down_d.valid),
      .out(sub_out.valid),
      .*
   );

   pipe_reg #(
      .WIDTH($bits(FFT_DATA_BUS)),
      .STAGE(1)
   ) pipe_up 
   (
      .in(up),
      .out(up_d),
      .*
   );


   pipe_reg #(
      .WIDTH($bits(FFT_DATA_BUS)),
      .STAGE(1)
   ) pipe_down 
   (
      .in(down),
      .out(down_d),
      .*
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
      .out(sub_out.data),
      .*
   ); 
endmodule
