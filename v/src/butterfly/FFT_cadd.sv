/*
   Complex Adder, no shift, latency = 2
   Revisions:
      10/08/21: First Documentation
*/


module FFT_cadd(
    input  FFT_DATA_SAMPLE              opa,
    input  FFT_DATA_SAMPLE              opb,
    output FFT_DATA_SAMPLE              out,
    input                               clk,
    input                               rst_n
    );

    logic  [$clog2(`FFT_DATA_WIDTH + 1) - 1 : 0] shift_zero;
    assign shift_zero = 0;

    fix_c_add_sub #(
       .IN_WIDTH(`FFT_DATA_WIDTH),
       .OUT_WIDTH(`FFT_DATA_WIDTH),
       .ARITH_MODE_R(0),
       .ARITH_MODE_I(0),
       .FLIP(0),
       .SHIFT_CONST(0),
       .SHIFT_MODE(0),
       .SAT_PIPE(1),
       .SHIFT_PIPE(0),
       .ADD_PIPE(1)
    ) fix_cadd (
       .opa_R(opa.data_r),
       .opb_R(opb.data_r),
       .opa_I(opa.data_i),
       .opb_I(opb.data_i),
       .arith_mode_R(1'b0),
       .arith_mode_I(1'b0),
       .flip(1'b0),
       .shift_amount(shift_zero),
       .out_R(out.data_r),
       .out_I(out.data_i),
       .*
    );
    

endmodule

