/*
   Reg 0: command (start)
   Reg 1: {read_start_addr(32), read_len (32)}
   Reg 2: {write_start_addr(32), write_len (32)}
   Reg 3: configuration
   Reg 4: interrupt handling
   Reg 5: status
   Revisions:
     10/12/21:
       First Documentation, take out read_restart & write_restart
       Fix slv_reg_up number of 0
*/
module top_decoder_FFT #(
   parameter   AXIL_DATA_WIDTH  = 64,
   parameter   AXI_ADDR_WIDTH  = 32,
   parameter   NUM_REGISTER     = 6, 
   parameter   TOP_LEN_WIDTH     = 32 
) (
   input [AXIL_DATA_WIDTH*NUM_REGISTER - 1 : 0] slv_reg_down,
   output logic [AXIL_DATA_WIDTH*NUM_REGISTER - 1 : 0] slv_reg_up,
   input  [$clog2(NUM_REGISTER) - 1 : 0]   access_addr,
   input                                    write_valid,
/*
   to DMA controller
*/    
   output  logic                          read_start,
//   output  logic                          read_restart,
   output  logic                          top_read_valid,
   output  logic  [TOP_LEN_WIDTH - 1 : 0] top_read_len,
   output  logic  [AXI_ADDR_WIDTH-1:0]    top_read_addr,

   output  logic                          write_start,
//   output  logic                          write_restart,
   output  logic                          top_write_valid,
   output  logic  [TOP_LEN_WIDTH - 1 : 0] top_write_len,
   output  logic  [AXI_ADDR_WIDTH-1:0]    top_write_addr,

/*
   custom stuff
*/
   input                                  write_done,
   output  logic                          interrupt_out,
   output  FFT_CONT_TO_COMP               cont_to_comp,

   output  logic  [4:0]                   shift_back,

   input                                   clk,
   input                                   rst_n 
);

   logic  [AXIL_DATA_WIDTH - 1 : 0]  read_command, write_command, general_command;
      
   assign general_command = slv_reg_down[(0+1)*AXIL_DATA_WIDTH-1 : 0*AXIL_DATA_WIDTH];
   assign read_command = slv_reg_down[(1+1)*AXIL_DATA_WIDTH-1 : 1*AXIL_DATA_WIDTH];
   assign write_command = slv_reg_down[(2+1)*AXIL_DATA_WIDTH-1 : 2*AXIL_DATA_WIDTH];

   assign top_read_valid  = write_valid == 1 && access_addr == 1;
   assign top_write_valid = write_valid == 1 && access_addr == 2;

//   assign read_restart  = write_valid == 1 && access_addr == 0 && general_command == 1;
//   assign write_restart = write_valid == 1 && access_addr == 0 && general_command == 1;

   assign read_start  = write_valid == 1 && access_addr == 0 && general_command == 2;
   assign write_start = write_valid == 1 && access_addr == 0 && general_command == 2;

   assign top_read_len = read_command [TOP_LEN_WIDTH - 1 : 0];
   assign top_read_addr = read_command [32 + AXI_ADDR_WIDTH - 1 : 32];
   assign top_write_len = write_command [TOP_LEN_WIDTH - 1 : 0];
   assign top_write_addr = write_command [32 + AXI_ADDR_WIDTH - 1 : 32];

/*
   custom thing
*/
   logic  [AXIL_DATA_WIDTH - 1 : 0]  config_command, status, interrupt_reg;
   logic  [AXIL_DATA_WIDTH - 1 : 0]  interrupt_command, status_w, interrupt_reg_w;
   assign config_command = slv_reg_down[(3+1)*AXIL_DATA_WIDTH-1 : 3*AXIL_DATA_WIDTH];
   assign interrupt_command = slv_reg_down[(4+1)*AXIL_DATA_WIDTH-1 : 4*AXIL_DATA_WIDTH];

   FFT_CONT_TO_COMP  cont_to_comp_w;
/*
   cont_to_comp should hold, it's not a pulse
*/
   logic  [4:0]  shift_back_w;
   always_comb begin
      cont_to_comp_w = cont_to_comp;
      shift_back_w = shift_back;
      if (write_valid == 1 && access_addr == 3) begin
         cont_to_comp_w.ifft = config_command[0];
         cont_to_comp_w.point = config_command[4:1];
         cont_to_comp_w.scaling = config_command[30:5];
         shift_back_w = config_command[35:31];
      end
   end
   
   assign interrupt_out = interrupt_reg != 0;    


//   assign shift_back_w = (write_valid == 1 && access_addr == 3) ? config_command[35:31] : shift_back;


   always_comb begin
      interrupt_reg_w = interrupt_reg;
      if (write_done == 1 && status == 0) interrupt_reg_w = 1; 
      else if (write_valid == 1 && access_addr == 4) interrupt_reg_w = interrupt_command;
   end 

   assign slv_reg_up = {status, 320'b0}; 

   always_comb begin
      status_w = status;
      if (read_start == 1) status_w = 0;
      else if (write_done == 1) status_w = 1;
   end  

   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         status <= 1;
         interrupt_reg <= 0;
         cont_to_comp <= 0;
         shift_back <= 0; 
      end
      else begin
         status <= status_w;
         interrupt_reg <= interrupt_reg_w;
         cont_to_comp <= cont_to_comp_w; 
         shift_back <= shift_back_w;
      end
   end

endmodule
