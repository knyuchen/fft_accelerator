/*
  Revisions:
    10/12/21:
      First Documented
*/
module FFT_top # (
    parameter AXI_DATA_WIDTH = 64,
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_ID_WIDTH = 8,
    parameter AXIL_DATA_WIDTH	= 64, 
    parameter NUM_REGISTER          =   6,
    parameter TOP_LEN_WIDTH   = 32,
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH/8),
    parameter AXIL_ADDR_WIDTH	= AXI_ADDR_WIDTH
)
(
    input             clk,
    input             rst_n,
// AXI READ Master    
    output   logic [AXI_ID_WIDTH-1:0]    m_axi_arid,
    output   logic [AXI_ADDR_WIDTH-1:0]  m_axi_araddr,
    output   logic [7:0]                 m_axi_arlen,
    output   logic [2:0]                 m_axi_arsize,
    output   logic [1:0]                 m_axi_arburst,
    output   logic                       m_axi_arlock,
    output   logic [3:0]                 m_axi_arcache,
    output   logic [2:0]                 m_axi_arprot,
    output   logic                       m_axi_arvalid,
    input                                m_axi_arready,
    input          [AXI_ID_WIDTH-1:0]    m_axi_rid,
    input          [AXI_DATA_WIDTH-1:0]  m_axi_rdata,
    input          [1:0]                 m_axi_rresp,
    input                                m_axi_rlast,
    input                                m_axi_rvalid,
    output   logic                       m_axi_rready,
// AXI WRITE Master    
    output   logic [AXI_ID_WIDTH-1:0]    m_axi_awid,
    output   logic [AXI_ADDR_WIDTH-1:0]  m_axi_awaddr,
    output   logic [7:0]                 m_axi_awlen,
    output   logic [2:0]                 m_axi_awsize,
    output   logic [1:0]                 m_axi_awburst,
    output   logic                       m_axi_awlock,
    output   logic [3:0]                 m_axi_awcache,
    output   logic [2:0]                 m_axi_awprot,
    output   logic                       m_axi_awvalid,
    input                                m_axi_awready,
    output   logic [AXI_DATA_WIDTH-1:0]  m_axi_wdata,
    output   logic [AXI_STRB_WIDTH-1:0]  m_axi_wstrb,
    output   logic                       m_axi_wlast,
    output   logic                       m_axi_wvalid,
    input                                m_axi_wready,
    input          [AXI_ID_WIDTH-1:0]    m_axi_bid,
    input          [1:0]                 m_axi_bresp,
    input                                m_axi_bvalid,
    output   logic                       m_axi_bready,
// axi-lite slave		
    input        [AXIL_ADDR_WIDTH-1 : 0] s_axil_awaddr,
    input        [2 : 0] s_axil_awprot,
    input         s_axil_awvalid,
    output logic  s_axil_awready,
    input        [AXIL_DATA_WIDTH-1 : 0] s_axil_wdata,
    input        [(AXIL_DATA_WIDTH/8)-1 : 0] s_axil_wstrb,
    input         s_axil_wvalid,
    output logic  s_axil_wready,
    output logic [1 : 0] s_axil_bresp,
    output logic  s_axil_bvalid,
    input         s_axil_bready,
    input        [AXIL_ADDR_WIDTH-1 : 0] s_axil_araddr,
    input        [2 : 0] s_axil_arprot,
    input         s_axil_arvalid,
    output logic  s_axil_arready,
    output logic [AXIL_DATA_WIDTH-1 : 0] s_axil_rdata,
    output logic [1 : 0] s_axil_rresp,
    output logic  s_axil_rvalid,
    input         s_axil_rready,
/*
    interrupt
*/
    output logic   interrupt_out

);
/*
   Standard AXIL output
*/


  logic [NUM_REGISTER*AXIL_DATA_WIDTH - 1 : 0] slv_reg_down;
  logic [NUM_REGISTER*AXIL_DATA_WIDTH - 1 : 0] slv_reg_up;
  logic [$clog2(NUM_REGISTER) - 1 : 0] access_addr;
  logic                            read_valid;
  logic                            write_valid;

   AXIL_S_wrap axil (.*);
/*
   Control Signals to DMA_wrap
*/
   logic                             read_start;
   logic                             read_restart;
   logic                             top_read_valid;
   logic     [TOP_LEN_WIDTH - 1 : 0] top_read_len;
   logic     [AXI_ADDR_WIDTH-1:0]    top_read_addr;

   logic                             write_start;
   logic                             write_restart;
   logic                             top_write_valid;
   logic     [TOP_LEN_WIDTH - 1 : 0] top_write_len;
   logic     [AXI_ADDR_WIDTH-1:0]    top_write_addr;

   logic write_done, read_done;
   FFT_CONT_TO_COMP   cont_to_comp; 

   logic [4:0]  shift_back;

   top_decoder_FFT td1 (.*);
   
   logic                                 input_ready;
   logic [AXI_DATA_WIDTH-1:0]   data_out;
   logic                        valid_out;
   logic                        last_out;
    
   logic                         output_ready;
   logic                                  valid_in;
   logic           [AXI_DATA_WIDTH - 1 : 0]  data_in;

   dma_wrap dm1 (.*);

   FFT_DATA_BUS  in, out;
   logic  output_buffer_full;

   assign in.valid = valid_out;
   assign in.data = data_out;

   FFT_compute fc1 (.*, .ready(~output_buffer_full), .ready_out(input_ready));

   logic bit_rev_empty, bit_rev_valid;
   logic   full, empty, valid;
   logic   push, pop;
   logic [$bits(FFT_DATA_SAMPLE) - 1 : 0]  wdata, rdata;
   bitrev_fifo bf1 (.*, .empty(bit_rev_empty), .point(cont_to_comp.point), .data_in(out.data), .push(out.valid), .data_out(wdata), .valid(bit_rev_valid), .pop(empty), .full(output_buffer_full)); 


   d0fifo_wrap #(.SIZE(4), .WIDTH($bits(FFT_DATA_SAMPLE))) d1 (.*); 
   assign pop = output_ready;
   assign push = bit_rev_valid; 
   assign valid_in = valid;
   assign data_in = rdata;

   FFT_DATA_SAMPLE  monitor_bit_rev_output;
   assign monitor_bit_rev_output = rdata;

   FFT_DATA_SAMPLE  monitor_axi_wdata;
   FFT_DATA_SAMPLE  monitor_axi_rdata;
   FFT_DATA_SAMPLE  monitor_data_in;

   assign monitor_axi_wdata = m_axi_wdata; 
   assign monitor_axi_rdata = m_axi_rdata; 
   assign monitor_data_in = data_in; 
   
 
endmodule
