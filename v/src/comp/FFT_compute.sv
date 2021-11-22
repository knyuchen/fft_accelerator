/*
   Connecting all the stages of PE, all 13 of them
   Starting from PE 13 --> PE 12 .... --> PE_4 --> PE_2
   check ifft --> compute --> shift_back --> check ifft

   Prvious stage: DMA, get data same cycle as ready
   Next Stage: bit rev fifo, send data same cycle as ready
   Revisions:
      10/08/21: First Documentation
      10/12/21: fix shifting, needs to be signed logic first
*/

module FFT_compute (
   input  FFT_DATA_BUS   in,
   output FFT_DATA_BUS   out,
   input                 ready,
   output logic          ready_out,
   input  [4:0]          shift_back, // total 13 stages, max 26 bit shift
   input  FFT_CONT_TO_COMP cont_to_comp,
   input             clk,
   input             rst_n

);

   FFT_DATA_BUS  par[$clog2(`FFT_MAX_POINT) : 0];
   
   FFT_DATA_BUS  real_in, real_in_w;
/*
   interchange real & imaginary for ifft
*/

   assign real_in_w.valid = in.valid;
   assign real_in_w.data  = (cont_to_comp.ifft == 1) ? {in.data.data_i, in.data.data_r} : in.data;
/*
   one stage of pipeline after accomadating for ifft, good for timing
   not a good practice but is accounted for by "using empty as ready" in all the PEs
*/


   pipe_reg #(
      .WIDTH($bits(FFT_DATA_BUS)),
      .STAGE(1)
   ) pipe_in 
   (
      .in(real_in_w),
      .out(real_in),
      .*
   );
/*
   finial shifting and final accomadation for ifft
   good practice since all combinational so that next stage gets data in the same cycle
   might be bad for timing
*/
   FFT_DATA_BUS  out_pre, out_shift;

   logic signed [`FFT_DATA_WIDTH - 1 : 0] data_r_pre, data_i_pre;

   assign data_r_pre = out_pre.data.data_r; 
   assign data_i_pre = out_pre.data.data_i; 
   
   assign out_shift.valid = out_pre.valid;
   assign out_shift.data =  {data_r_pre <<< shift_back, data_i_pre <<< shift_back};
   assign out.valid = out_shift.valid;

   logic signed [`FFT_DATA_WIDTH - 1 : 0] data_r_shift, data_i_shift;

   assign data_r_shift = out_shift.data.data_r; 
   assign data_i_shift = out_shift.data.data_i; 

   assign out.data = (cont_to_comp.ifft == 1) ? {(data_i_shift >>> cont_to_comp.point), (data_r_shift >>> cont_to_comp.point)} : out_shift.data;



   assign out_pre = par[0];
   assign par[$clog2(`FFT_MAX_POINT)] = real_in;

   logic [$clog2(`FFT_MAX_POINT) - 1 : 0] select, select_d;
   logic [2*$clog2(`FFT_MAX_POINT) - 1 : 0] scaling_d;
/*
   Decodign point to select
*/   

   always_comb begin
      case (cont_to_comp.point)
          1: select = 13'b0_0000_0000_0001;
          2: select = 13'b0_0000_0000_0011;
          3: select = 13'b0_0000_0000_0111;
          4: select = 13'b0_0000_0000_1111;
          5: select = 13'b0_0000_0001_1111;
          6: select = 13'b0_0000_0011_1111;
          7: select = 13'b0_0000_0111_1111;
          8: select = 13'b0_0000_1111_1111;
          9: select = 13'b0_0001_1111_1111;
         10: select = 13'b0_0011_1111_1111;
         11: select = 13'b0_0111_1111_1111;
         12: select = 13'b0_1111_1111_1111;
         13: select = 13'b1_1111_1111_1111;
         default: select = 0;  
      endcase
   end
/*
   pipelining scaling and select through stages
*/

   FFT_pipe fp1 (
      .scaling(cont_to_comp.scaling),
      .*
   );

   logic [$clog2(`FFT_MAX_POINT)  : 0] ready_pipe;
   assign ready_pipe[0] = ready;
   assign ready_out = ready_pipe[$clog2(`FFT_MAX_POINT)];

   genvar i;

   generate 

      for (i = 0; i < $clog2(`FFT_MAX_POINT); i = i + 1) begin
      PE_full #(.SET(i+1))  pp (
         .clk(clk),
         .rst_n(rst_n),
         .in(par[i+1]),
         .out(par[i]),
         .ready(ready_pipe[i+1]),
         .next_ready(ready_pipe[i]),
         .select(select_d[i]),
         .scaling(scaling_d[2*i + 1: 2*i])
      );

      end 

   endgenerate

endmodule
