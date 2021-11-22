from fix_point import *
from math import *
from bin_hex import *
from BW import *


def bit_rev (num, bits):
   num_bin = dec_to_bin (num, bits)
   rev_num_bin = num_bin [::-1]
   return bin_to_dec_un (rev_num_bin, bits)

def bit_rev_order (data_in, point):

   num_of_sequence = floor(len(data_in) / point)
   out = [0] * len(data_in)
   for i in range (num_of_sequence):
      for j in range (point):
         src = i*point + bit_rev(j, ceil(log2(point)))
         out[i*point + j] = data_in[src]
   return out

def twiddle_gen (N):
   W_quant = BW - 2
   row_num = floor (log2(N))
   column_num = int(N/2)
   W = [[1*2**W_quant for i in range (column_num)] for j in range (row_num)]
   for i in range (row_num):
      num_of_twiddle = 2 ** i
      current_point = 2 ** (i+1)
      repeat_start = num_of_twiddle
      for k in range (1,min(num_of_twiddle, 4)):
         angle = -2.0*pi*k/current_point
         W[i][k] = quant_fp(complex(cos(angle), sin(angle)), W_quant)
      if i > 2:  # point > 8
         rotate_angle = -2.0*pi*3/current_point
         rotate = quant_fp (complex(cos(rotate_angle), sin(rotate_angle)), W_quant)
         W[i][3] = rotate
         for k in range (4, num_of_twiddle):
            W[i][k] = mult_fp (W[i][k-3], rotate, 0, W_quant) 
      for k in range (repeat_start, column_num):
         W[i][k] = W[i][k%num_of_twiddle]
   return W


def FFT_one_stage_DAP (data_in, W, point):
  
   W_quant = BW - 2
   num_of_sequence = floor(len(data_in) / point)
   out = [0] * len(data_in)
   for j in range (num_of_sequence):
      for k in range (int(point / 2)):
         up = int (j*point + k)
         down = int (j*point + k + point / 2)
         out [up] = add_fp (data_in[up], data_in[down])
      for k in range (int(point / 2)):
         up = int (j*point + k)
         down = int (j*point + k + point / 2)
         temp  = sub_fp (data_in[up], data_in[down])
         out [down] = mult_fp (temp, W[k], 0, W_quant)
   return out

def FFT_DAP (data_in, N):
   column_num = int(len(data_in))
   row_num = int(log2(N) + 2)
   R = [[0 for i in range (column_num)] for j in range (row_num)]
   W = twiddle_gen (N)
   R[0] = data_in
   for i in range (1, row_num - 1):
      current_point = int(N / 2**(i-1))
      R[i] = FFT_one_stage_DAP(R[i-1], W[int(log2(N))-i], current_point)
   R[row_num - 1] = bit_rev_order(R[row_num - 2], N)
   return R

def R_I_SWITCH (data_in):
   out = complex(data_in.imag, data_in.real)
   return out


def IFFT_DAP (data_in, N):
   out = [0]*N
   for i in range (len(data_in)):
      data_in[i] = R_I_SWITCH(data_in[i]) 
   FFT_pre = FFT_DAP(data_in, N)
   data_pre = FFT_pre[int(log2(N)+1)]
   for i in range (len(data_in)):
      data_pre[i] = R_I_SWITCH(data_pre[i]) 
   for i in range (len(data_pre)):
      out[i] = cshift_fp (data_pre[i], 0, log2(N))
   return out 

def FFT_DAP_scaling (data_in, N):
   column_num = int(len(data_in))
   row_num = int(log2(N) + 2)
   R = [[0 for i in range (column_num)] for j in range (row_num)]
   W = twiddle_gen (N)
   R[0] = data_in
   for i in range (1, row_num - 1):
      current_point = int(N / 2**(i-1))
      R[i] = FFT_one_stage_DAP(R[i-1], W[int(log2(N))-i], current_point)
   R[row_num - 1] = bit_rev_order(R[row_num - 2], N)
   return R

#W = twiddle_gen(8192)
#for j in range (5):
#   for i in range (0, 13):
#      print(W[i][j])
