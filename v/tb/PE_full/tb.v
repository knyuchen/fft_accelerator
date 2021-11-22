module test ();
   logic clk, rst_n;
   clk_gen c1 (.*);

   FFT_DATA_BUS  in, out;

   logic next_ready, ready, select;

   logic [1:0] scaling;

   assign next_ready = 1;
   assign select = 1;
   assign scaling = 0;
  
   initial  in = 0;

   parameter SET = 1;

   PE_full # (.SET(SET)) pf1 (.*);


   initial begin
      #(`RESET_CYCLE*`CLK_CYCLE)
      #(3*`CLK_CYCLE)
      @(negedge clk) 
      for (integer i = 0; i < 64; i = i + 1) begin
      @(negedge clk)
      in.valid = 1;
      in.data.data_r = i + 1;
      in.data.data_i = 0;
      end
      @(negedge clk)
      in = 0;
      #(20*`CLK_CYCLE)
      $finish();
   end

endmodule
