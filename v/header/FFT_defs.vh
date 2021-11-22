`define ANOTHER
`define FFT_SRAM           1
`define FFT_DATA_WIDTH     32
`define FFT_SHIFT_AMOUNT   30
`define FFT_MAX_POINT         8192
//`define FFT_INDEX_WIDTH    $clog2(`FFT_MAX_POINT) - 1
//typedef logic [`FFT_INDEX_WIDTH - 1 : 0]  LUT_INDEX;
typedef struct packed {
   logic  [`FFT_DATA_WIDTH - 1 : 0] data_r;
   logic  [`FFT_DATA_WIDTH - 1 : 0] data_i;
} FFT_DATA_SAMPLE;

typedef struct packed {
   logic                        valid;
   FFT_DATA_SAMPLE                  data;
} FFT_DATA_BUS;


typedef struct packed {
   logic  [$clog2($clog2(`FFT_MAX_POINT)) - 1 : 0]   point;
   logic  [2*$clog2(`FFT_MAX_POINT) - 1 : 0]         scaling;
   logic                                             ifft;
} FFT_CONT_TO_COMP;


parameter signed [12:0][31:0] TWIDDLE_0_R = {
    32'd1073741824,
    32'd1073741824,
    32'd1073741824,
    32'd1073741824,
    32'd1073741824,
    32'd1073741824,
    32'd1073741824,
    32'd1073741824,
    32'd1073741824,
    32'd1073741824,
    32'd1073741824,
    32'd1073741824,
    32'd1073741824
};

parameter signed [12:0][31:0] TWIDDLE_0_I = {
    32'd0,
    32'd0,
    32'd0,
    32'd0,
    32'd0,
    32'd0,
    32'd0,
    32'd0,
    32'd0,
    32'd0,
    32'd0,
    32'd0,
    32'd0
};
parameter signed [12:0][31:0] TWIDDLE_1_R = {
    32'd1073741508,
    32'd1073740561,
    32'd1073736771,
    32'd1073721611,
    32'd1073660973,
    32'd1073418433,
    32'd1072448455,
    32'd1068571464,
    32'd1053110176,
    32'd992008094,
    32'd759250125,
   -32'd0,
   -32'd1073741824
};
parameter signed [12:0][31:0] TWIDDLE_1_I = {
   -32'd823550,
   -32'd1647099,
   -32'd3294194,
   -32'd6588356,
   -32'd13176464,
   -32'd26350943,
   -32'd52686014,
   -32'd105245103,
   -32'd209476638,
   -32'd410903207,
   -32'd759250125,
   -32'd1073741824,
   -32'd1
};
parameter signed [12:0][31:0] TWIDDLE_2_R = {
    32'd1073740561,
    32'd1073736771,
    32'd1073721611,
    32'd1073660973,
    32'd1073418433,
    32'd1072448455,
    32'd1068571464,
    32'd1053110176,
    32'd992008094,
    32'd759250125,
   -32'd0,
   -32'd1073741824,
    32'd1073741824
};
parameter signed [12:0][31:0] TWIDDLE_2_I = {
   -32'd1647099,
   -32'd3294193,
   -32'd6588356,
   -32'd13176464,
   -32'd26350943,
   -32'd52686014,
   -32'd105245103,
   -32'd209476638,
   -32'd410903207,
   -32'd759250125,
   -32'd1073741824,
   -32'd1,
   -32'd0
};
parameter signed [12:0][31:0] TWIDDLE_3_R = {
    32'd1073738982,
    32'd1073730454,
    32'd1073696345,
    32'd1073559913,
    32'd1073014240,
    32'd1070832474,
    32'd1062120190,
    32'd1027506862,
    32'd892783698,
    32'd410903207,
   -32'd759250125,
   -32'd1,
   -32'd1073741824
};
parameter signed [12:0][31:0] TWIDDLE_3_I = {
   -32'd2470647,
   -32'd4941281,
   -32'd9882456,
   -32'd19764076,
   -32'd39521455,
   -32'd78989349,
   -32'd157550647,
   -32'd311690799,
   -32'd596538995,
   -32'd992008094,
   -32'd759250125,
    32'd1073741824,
   -32'd1
};
parameter signed [12:0][31:0] TWIDDLE_4_R = {
    32'd1073736771,
    32'd1073721611,
    32'd1073660973,
    32'd1073418433,
    32'd1072448454,
    32'd1068571463,
    32'd1053110175,
    32'd992008095,
    32'd759250125,
   -32'd0,
   -32'd1073741824,
    32'd1073741824,
    32'd1073741824
};
parameter signed [12:0][31:0] TWIDDLE_4_I = {
   -32'd3294195,
   -32'd6588357,
   -32'd13176463,
   -32'd26350944,
   -32'd52686015,
   -32'd105245103,
   -32'd209476638,
   -32'd410903207,
   -32'd759250125,
   -32'd1073741824,
   -32'd1,
   -32'd0,
   -32'd0
};