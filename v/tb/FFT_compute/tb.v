module test ();
   logic clk, rst_n;
   clk_gen c1 (.*);

   FFT_DATA_BUS  in, out;

   logic ready;

   FFT_CONT_TO_COMP cont_to_comp;

  
   initial  in = 0;

   initial cont_to_comp = 0;

   logic [3:0]  point;
   logic [63:0] data_in, data_out;
   logic        empty, full, valid;
   logic        push, pop;

   assign point = cont_to_comp.point;
   assign data_in = out.data;
   assign push = out.valid;
   assign ready = ~full;

   assign pop = 1;

   FFT_compute  pf1 (.*);
   bitrev_fifo bf1 (.*);

   initial begin
      #(`RESET_CYCLE*`CLK_CYCLE)
      #(3*`CLK_CYCLE)
      cont_to_comp.point = 4;
      #(13*`CLK_CYCLE)
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
