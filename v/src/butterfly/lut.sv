module lut#
( parameter POINT = 64 
)
(
   input      clk,
   input      rst_n,
   input [$clog2(POINT/2) - 1 : 0] index,
   output FFT_DATA_SAMPLE  twiddle
);


`define LUT(point)   \
     lut_``point`` l1 (.*);    \

   `LUT(POINT)

endmodule
