/*
   Pure Combinational Complex Multiplier based twiddle generator
   shift amount is fixed
   Revisions:
     10/12/21:
        First Documentation
*/
module FFT_twiddle #(
   parameter   SET = 3,
   parameter   REAL_SET = SET - 1,
   parameter   COUNT = 2**REAL_SET - 1
)
(
    input                               valid,
    output FFT_DATA_SAMPLE              out,
    input                               clk,
    input                               rst_n
);
  
    // opb is fixed, opa / out is output of FIFO
    // out pre goes into FIFO
 
    FFT_DATA_SAMPLE   opa, opb, out_pre;
    
    assign opb.data_r = TWIDDLE_4_R[REAL_SET];
    assign opb.data_i = TWIDDLE_4_I[REAL_SET];

/*
  mult latency is 3 cycles
*/ 
    fix_c_mult #(
       .IN_WIDTH(`FFT_DATA_WIDTH),
       .OUT_WIDTH(`FFT_DATA_WIDTH),
       .ARITH_MODE_R(1),
       .ARITH_MODE_I(0),
       .FLIP(0),
       .SHIFT_CONST(`FFT_SHIFT_AMOUNT),
       .SHIFT_MODE(1),
       .SAT_PIPE(1),
       .SHIFT_PIPE(0),
       .ADD_PIPE(1),
       .MULT_PIPE(1)
    ) fix_cmult (
       .opa_R(opa.data_r),
       .opb_R(opb.data_r),
       .opa_I(opa.data_i),
       .opb_I(opb.data_i),
       .arith_mode_R('0),
       .arith_mode_I('0),
       .flip('0),
       .shift_amount('0),
       .out_R(out_pre.data_r),
       .out_I(out_pre.data_i),
       .*
    );

    logic  valid_pipe;
    pipe_reg #(.STAGE(3), .WIDTH(1)) pr1 (.*, .in(valid), .out(valid_pipe)); 

    
    logic   pop, push;
    assign pop = valid;
    assign push = valid_pipe;
    FFT_DATA_SAMPLE [3:0] store, store_w;
    logic [1:0] wr_ptr_w, wr_ptr, rd_ptr, rd_ptr_w;
    assign out = store[rd_ptr];
    logic [REAL_SET - 1 : 0] count, count_w;
    logic restart;
    logic real_push;
/*
   use this to compensate for mult latency
   sometimes we are already restarting but previous results can come back
*/
    assign real_push = push && restart == 0;


    logic flag_w, flag;
    logic [1:0] small_count, small_count_w;

    assign restart = (flag == 0 && pop == 1 && count == 0) || (flag == 1);
/*
   opa is the same as out
*/
    assign opa = store[rd_ptr];

    always_comb begin
       count_w = count;
       if (pop == 1) begin
// popping the last one, time to reset
          if (count == 0) begin
             count_w = COUNT;
          end
          else count_w = count - 1;
       end
    end
/*
  make sure that restart is high for 3 cycles, so that wrong results doesn't come in 
*/
    always_comb begin
       flag_w = flag;
       small_count_w = small_count;
       if (flag == 0 && restart == 1) begin
          flag_w = 1;
          small_count_w = 2;
       end
       else if (flag == 1) begin
          if (small_count_w == 0) flag_w = 0;
          else small_count_w = small_count - 1;
       end
    end

    always_comb begin
       store_w = store;
       wr_ptr_w = wr_ptr;
       if (restart == 1) begin
          wr_ptr_w = 0;
          store_w[0].data_r = TWIDDLE_0_R[REAL_SET];
          store_w[0].data_i = TWIDDLE_0_I[REAL_SET];
          store_w[1].data_r = TWIDDLE_1_R[REAL_SET];
          store_w[1].data_i = TWIDDLE_1_I[REAL_SET];
          store_w[2].data_r = TWIDDLE_2_R[REAL_SET];
          store_w[2].data_i = TWIDDLE_2_I[REAL_SET];
          store_w[3].data_r = TWIDDLE_3_R[REAL_SET];
          store_w[3].data_i = TWIDDLE_3_I[REAL_SET];
       end
       else if (real_push == 1) begin
          wr_ptr_w = wr_ptr + 1;
          store_w[wr_ptr] = out_pre;
       end
    end
  
    always_comb begin
       rd_ptr_w = rd_ptr;
       if (restart == 1) rd_ptr_w = 0;
       else if (pop == 1) rd_ptr_w = rd_ptr + 1;
    end
     
    always_ff @(posedge clk or negedge rst_n) begin
       if (rst_n == 0) begin
          rd_ptr <= 0;
          wr_ptr <= 0;
          count <= COUNT;
          store[0].data_r <= TWIDDLE_0_R[REAL_SET];
          store[0].data_i <= TWIDDLE_0_I[REAL_SET];
          store[1].data_r <= TWIDDLE_1_R[REAL_SET];
          store[1].data_i <= TWIDDLE_1_I[REAL_SET];
          store[2].data_r <= TWIDDLE_2_R[REAL_SET];
          store[2].data_i <= TWIDDLE_2_I[REAL_SET];
          store[3].data_r <= TWIDDLE_3_R[REAL_SET];
          store[3].data_i <= TWIDDLE_3_I[REAL_SET];
          flag <= 0;
          small_count <= 0;
       end
       else begin
          count <= count_w;
          store <= store_w;
          rd_ptr <= rd_ptr_w;
          wr_ptr <= wr_ptr_w;
          flag <= flag_w;
          small_count <= small_count_w;
       end
    end   
 
endmodule

