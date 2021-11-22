/*
   switch = 0 --> [(a+bi) - (c+di)] * 1    = (a-c) + (b-d)i
   switch = 1 --> [(a+bi) - (c+di)] * (-i) = (b-d) + (c-a)i
   Revisions:
      10/11/21: First Documentation
*/

module butterfly_4 
(
   input   FFT_DATA_BUS  up,
   input   FFT_DATA_BUS  down,
   input                 switch,
   input                 clk,
   input                 rst_n,
   output  FFT_DATA_BUS   add_out,
   output  FFT_DATA_BUS   sub_out
);


   FFT_DATA_SAMPLE add_opa, add_opb, sub_opa, sub_opb;
/*
   Sub data and switch are delayed by 1 cycle
*/
   FFT_DATA_BUS  up_d, down_d;
   logic    switch_d;

/*
   input gating
*/
   assign add_opa = (up.valid == 1) ? up.data   : 0;
   assign add_opb = (down.valid == 1) ? down.data : 0;
   always_comb begin
      sub_opa = 0;
      sub_opb = 0;
      if (up_d.valid == 1) begin
         if (switch_d == 0) begin
            sub_opa.data_r = up_d.data.data_r;  // a
            sub_opa.data_i = up_d.data.data_i;  // b
         end
         else begin
            sub_opa.data_r = up_d.data.data_i;  // b
            sub_opa.data_i = down_d.data.data_r;// c
         end
      end
      if (down_d.valid == 1) begin
         if (switch_d == 0) begin
            sub_opb.data_r = down_d.data.data_r;// c
            sub_opb.data_i = down_d.data.data_i;// d
         end
         else begin
            sub_opb.data_r = down_d.data.data_i;// d
            sub_opb.data_i = up_d.data.data_r;  // a
         end
      end
   end     
/*
  pipelining of valid / done signal
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
      .WIDTH(1),
      .STAGE(1)
   ) pipe_switch 
   ( 
      .in(switch),
      .out(switch_d),
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
