/*
   Pipelining select / scaling stage by stage
   Revisions:
      10/08/21: First Documentation
*/
module FFT_pipe (
   input                                             clk,
   input                                             rst_n,
   input         [$clog2(`FFT_MAX_POINT) - 1 : 0]    select,
   output logic  [$clog2(`FFT_MAX_POINT) - 1 : 0]    select_d,
   input         [2*$clog2(`FFT_MAX_POINT) - 1 : 0]  scaling,
   output logic  [2*$clog2(`FFT_MAX_POINT) - 1 : 0]  scaling_d
);

   pipe_reg #(.WIDTH(1), .STAGE(1)) pipe_select_12 (.in(select[12]), .out(select_d[12]), .*);
   pipe_reg #(.WIDTH(1), .STAGE(2)) pipe_select_11 (.in(select[11]), .out(select_d[11]), .*);
   pipe_reg #(.WIDTH(1), .STAGE(3)) pipe_select_10 (.in(select[10]), .out(select_d[10]), .*);
   pipe_reg #(.WIDTH(1), .STAGE(4)) pipe_select_9  (.in(select[9]),  .out(select_d[9]),  .*);
   pipe_reg #(.WIDTH(1), .STAGE(5)) pipe_select_8  (.in(select[8]),  .out(select_d[8]),  .*);
   pipe_reg #(.WIDTH(1), .STAGE(6)) pipe_select_7  (.in(select[7]),  .out(select_d[7]),  .*);
   pipe_reg #(.WIDTH(1), .STAGE(7)) pipe_select_6  (.in(select[6]),  .out(select_d[6]),  .*);
   pipe_reg #(.WIDTH(1), .STAGE(6)) pipe_select_5  (.in(select[5]),  .out(select_d[5]),  .*);
   pipe_reg #(.WIDTH(1), .STAGE(5)) pipe_select_4  (.in(select[4]),  .out(select_d[4]),  .*);
   pipe_reg #(.WIDTH(1), .STAGE(4)) pipe_select_3  (.in(select[3]),  .out(select_d[3]),  .*);
   pipe_reg #(.WIDTH(1), .STAGE(3)) pipe_select_2  (.in(select[2]),  .out(select_d[2]),  .*);
   pipe_reg #(.WIDTH(1), .STAGE(2)) pipe_select_1  (.in(select[1]),  .out(select_d[1]),  .*);
   pipe_reg #(.WIDTH(1), .STAGE(1)) pipe_select_0  (.in(select[0]),  .out(select_d[0]),  .*);
   

   pipe_reg #(.WIDTH(2), .STAGE(1)) pipe_scaling_0   (.in(scaling[1:0]),    .out(scaling_d[1:0]),    .*);
   pipe_reg #(.WIDTH(2), .STAGE(2)) pipe_scaling_1   (.in(scaling[3:2]),    .out(scaling_d[3:2]),    .*);
   pipe_reg #(.WIDTH(2), .STAGE(3)) pipe_scaling_2   (.in(scaling[5:4]),    .out(scaling_d[5:4]),    .*);
   pipe_reg #(.WIDTH(2), .STAGE(4)) pipe_scaling_3   (.in(scaling[7:6]),    .out(scaling_d[7:6]),    .*);
   pipe_reg #(.WIDTH(2), .STAGE(5)) pipe_scaling_4   (.in(scaling[9:8]),    .out(scaling_d[9:8]),    .*);
   pipe_reg #(.WIDTH(2), .STAGE(6)) pipe_scaling_5   (.in(scaling[11:10]),  .out(scaling_d[11:10]),  .*);
   pipe_reg #(.WIDTH(2), .STAGE(7)) pipe_scaling_6   (.in(scaling[13:12]),  .out(scaling_d[13:12]),  .*);
   pipe_reg #(.WIDTH(2), .STAGE(6)) pipe_scaling_7   (.in(scaling[15:14]),  .out(scaling_d[15:14]),  .*);
   pipe_reg #(.WIDTH(2), .STAGE(5)) pipe_scaling_8   (.in(scaling[17:16]),  .out(scaling_d[17:16]),  .*);
   pipe_reg #(.WIDTH(2), .STAGE(4)) pipe_scaling_9   (.in(scaling[19:18]),  .out(scaling_d[19:18]),  .*);
   pipe_reg #(.WIDTH(2), .STAGE(3)) pipe_scaling_10  (.in(scaling[21:20]),  .out(scaling_d[21:20]),  .*);
   pipe_reg #(.WIDTH(2), .STAGE(2)) pipe_scaling_11  (.in(scaling[23:22]),  .out(scaling_d[23:22]),  .*);
   pipe_reg #(.WIDTH(2), .STAGE(1)) pipe_scaling_12  (.in(scaling[25:24]),  .out(scaling_d[25:24]),  .*);
endmodule
