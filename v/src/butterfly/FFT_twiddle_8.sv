/*
  twiddle generator for 8 point is special
  no multiplication is needed
  Revisions:
    10/12/21:
       First Documentation
*/
module FFT_twiddle_8 #(
   // log2 (point)
   parameter   SET = 3,
   // number of twiddle factors is POINT / 2
   parameter   REAL_SET = SET - 1,
   parameter   COUNT = 2**REAL_SET - 1
)
(
    input                               valid,
    output FFT_DATA_SAMPLE              out,
    input                               clk,
    input                               rst_n
);

/*
  no pushing, just rotating
*/ 
    logic   pop;
    assign pop = valid;
    FFT_DATA_SAMPLE [3:0] store, store_w;
    logic [1:0] rd_ptr, rd_ptr_w;
    assign out = store[rd_ptr];
    always_comb begin
       rd_ptr_w = rd_ptr;
       if (pop == 1) rd_ptr_w = rd_ptr + 1;
    end
   
    assign store_w = store;
     
    always_ff @(posedge clk or negedge rst_n) begin
       if (rst_n == 0) begin
          rd_ptr <= 0;
          store[0].data_r <= TWIDDLE_0_R[REAL_SET];
          store[0].data_i <= TWIDDLE_0_I[REAL_SET];
          store[1].data_r <= TWIDDLE_1_R[REAL_SET];
          store[1].data_i <= TWIDDLE_1_I[REAL_SET];
          store[2].data_r <= TWIDDLE_2_R[REAL_SET];
          store[2].data_i <= TWIDDLE_2_I[REAL_SET];
          store[3].data_r <= TWIDDLE_3_R[REAL_SET];
          store[3].data_i <= TWIDDLE_3_I[REAL_SET];
       end
       else begin
          store <= store_w;
          rd_ptr <= rd_ptr_w;
       end
    end   
 
endmodule

