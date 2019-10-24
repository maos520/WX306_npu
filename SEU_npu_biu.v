// *****************************************************************************
// @Project Name :
// @Author       : Maos520
// @Email        : sujingjingabc@sina.com
// @File Name    : SEU_npu_biu.v
// @Module Name  : SEU_npu_biu
// @Created Time : 2019-10-11 10:25
//
// @Abstract     :   This module includes three  kinds of interface, AXI_S, AXI_M. The AXI_S
//                 is used to recieve the base fabric info of neural network, such as the 
//                 number of network layers and storage address,and related control signals.
//                 The AXI_M is used to read layer parameter and read or write feature map and 
//                 weight.  
//                   The function of this module is to convert transactions that follow the 
//                 AXI protocal to simple write and read for the internal module.
//                   
//
// Modification History
// ******************************************************************************
// Date           BY           Version         Change Description
// -------------------------------------------------------------------------
// 2019-10-11   Maos520          v1.0a            initial version 
// 
// ******************************************************************************
`timescale 1ns/1ps

module SEU_npu_biu(
    input wire          clk_trans,
    input wire          rst_n,
//-----------------------------------------------------------------------
//AXI_S interface ports          PCI-e AXI master ------>  NPU AXI slave
//---------------------,--------------------------------------------------

    //write address channel  
    input  wire [3:0]   npu_s_axi_wid,         
    input  wire [31:0]  npu_s_axi_waddr,
    input  wire [7:0]   npu_s_axi_wlen,
    input  wire [2:0]   npu_s_axi_wsize,
    input  wire [1:0]   npu_s_axi_wburst, 
    input  wire [3:0]   npu_s_axi_wcache,
    input  wire [2:0]   npu_s_axi_wprot,
    input  wire [1:0]   npu_s_axi_wlock,
    input  wire         npu_s_axi_wvalid,
    output wire         npu_s_axi_wready,
    //write data channel
    input  wire [3:0]   npu_s_axi_wd_wid,
    input  wire [63:0]  npu_s_axi_wd_data,
    input  wire [7:0]   npu_s_axi_wd_strb,
    input  wire         npu_s_axi_wd_last,
    input  wire         npu_s_axi_wd_valid,
    output wire         npu_s_axi_wd_wready,
    //write response channel 
    output wire [3:0]   npu_s_axi_wd_bid,
    output wire [1:0]   npu_s_axi_wd_bresp,
    output wire         npu_s_axi_wd_bvalid,
    input  wire         npu_s_axi_wd_bready,
    //read address channel 
    input  wire [3:0]   npu_s_axi_rid,
    input  wire [31:0]  npu_s_axi_raddr,
    input  wire [7:0]   npu_s_axi_rlen,
    input  wire [2:0]   npu_s_axi_rsize,
    input  wire [1:0]   npu_s_axi_rburst,
    input  wire [3:0]   npu_s_axi_rcache,
    input  wire [2:0]   npu_s_axi_rprot,
    //read address channel 
    output wire [3:0]   npu_s_axi_rd_bid,
    output wire [63:0]  npu_s_axi_rd_data,
    output wire [1:0]   npu_s_axi_rd_rresp,
    output wire         npu_s_axi_rd_last,
    output wire         npu_s_axi_rd_rvalid,
    input  wire         npu_s_axi_rd_rready,

//----------------------------------------------------------------------------
// NPU configration register read/write interface  
//----------------------------------------------------------------------------
    
    output wire         sys_ren   // ??????????
    output wire [31:0]  reg_addr, // read/write address 
    output wire [63:0]  reg_wdata,// write data 
    output wire [7:0]   reg_sel,  // write byte select 
    output wire         reg_wen,  // write enable 
    output wire         reg_ren,  // read enable 
    input  wire [63:0]  reg_rdata,// read data 
    input  wire         reg_err,  // error indicator 
    input  wire         reg_ack,  // acknowledge signal 

//-----------------------------------------------------------------------------
//--AXI_M interface port                NPU AXI master ----->  DDR 
//-----------------------------------------------------------------------------

    //AXI write address channel 
    input  wire        npu_m_axi_wready, // Indicates slave is ready to accept a 
    output wire [3:0]  npu_m_axi_wid,    // Write ID  3:0
    output wire [31:0] npu_m_axi_waddr,  // Write address  29:0
    output wire [7:0]  npu_m_axi_wlen,   // Write Burst Length
    output wire [2:0]  npu_m_axi_wsize,  // Write Burst size
    output wire [1:0]  npu_m_axi_wburst, // Write Burst type
    output wire [1:0]  npu_m_axi_wlock,  // Write lock type
    output wire [3:0]  npu_m_axi_wcache, // Write Cache type
    output wire [2:0]  npu_m_axi_wprot,  // Write Protection type
    output wire        npu_m_axi_wvalid, // Write address valid
    
    //AXI write data channel signals
    input  wire        npu_m_axi_wd_wready,  // Write data ready
    output wire [3:0]  npu_m_axi_wd_wid,     // Write ID tag
    output wire [63:0] npu_m_axi_wd_data,    // Write data
    output wire [7:0]  npu_m_axi_wd_strb,    // Write strobes
    output wire        npu_m_axi_wd_last,    // Last write transaction   
    output wire        npu_m_axi_wd_valid,   // Write valid
    
    //AXI write response channel signals
    input  wire [3:0]  npu_m_axi_wd_bid,     // Response ID
    input  wire [1:0]  npu_m_axi_wd_bresp,   // Write response
    input  wire        npu_m_axi_wd_bvalid,  // Write reponse valid
    output wire        npu_m_axi_wd_bready,  // Response ready
    
    //AXI read address channel signals
    input  wire        npu_m_axi_rready,     // Read address ready
    output wire [3:0]  npu_m_axi_rid,        // Read ID
    output wire [31:0] npu_m_axi_raddr,      // Read address
    output wire [7:0]  npu_m_axi_rlen,       // Read Burst Length
    output wire [2:0]  npu_m_axi_rsize,      // Read Burst size
    output wire [1:0]  npu_m_axi_rburst,     // Read Burst type
    output wire [1:0]  npu_m_axi_rlock,      // Read lock type
    output wire [3:0]  npu_m_axi_rcache,     // Read Cache type
    output wire [2:0]  npu_m_axi_rprot,      // Read Protection type
    output wire        npu_m_axi_rvalid,     // Read address valid
    
    //AXI read data channel signals   
    input  wire [3:0]  npu_m_axi_rd_bid,     // Response ID
    input  wire [1:0]  npu_m_axi_rd_rresp,   // Read response
    input  wire        npu_m_axi_rd_rvalid,  // Read reponse valid
    input  wire [63:0] npu_m_axi_rd_data,    // Read data
    input  wire        npu_m_axi_rd_last,    // Read last
    output wire        npu_m_axi_rd_rready,   // Read Response ready

 //-------------------------------------------------------------------------------
 // User interface         
 //-------------------------------------------------------------------------------

    //User interface command port
    input  wire        ui_cmd_en,  // Asserted to indicate a valid command and address
    input  wire [2:0]  ui_cmd,     // Write or read command
    //                          // 000 - READ with INCR bursts
    //                          // 001 - READ with WRAP bursts
    //                          // 01x - Reserved
    //                          // 100 - WRITE with INCR bursts
    //                         // 101 - WRITE with WRAP bursts
    input  wire [7:0]  ui_blen,    // Burst length calculated as blen+1
    input  wire [31:0] ui_addr,    // Address for the read or the write transaction
    input  wire [1:0]  ui_ctl,     // control command for read or write transaction 
    input  wire        ui_wdog_mask, // Mask the watchdog timeouts
    output wire        ui_cmd_ack,// Indicates the command has been accepted
  
    //User interface write ports
    input  wire        ui_wrdata_vld,  // Asserted to indicate a valid write data
    input  wire [63:0] ui_wrdata,      // Write data
    input  wire [7:0]  ui_wrdata_bvld, // Byte valids for the write data
    input  wire        ui_wrdata_cmptd,// Last data to be transferred
    output wire        ui_wrdata_rdy,  // Indicates that the write data is ready to be accepted
    output wire        ui_wrdata_sts_vld, // Indicates a write status after 
    //                                 // completion of a write transfer   
    output wire [15:0] ui_wrdata_sts,     // Status of the write transaction

    //User interface read ports
    input  wire        ui_rddata_rdy,   // Data ready to be accepted
    output wire        ui_rddata_vld,   // Indicates a valid read data available
    output wire [63:0] ui_rddata,       // Read data
    output wire [7:0]  ui_rddata_bvld,  // Byte valids for read data 
    output wire        ui_rddata_cmptd, // Indicates last data present and valid status
    output wire [15:0] ui_rddata_sts   // Status of the read transaction
);


    //-----------------------------------------------------------------------------------
    //-------instantiate the module that convert UI to AXI_M------------------------------ 
    //----------------------------------------------------------------------------------

    mig_7series_v4_1_axi4_wrapper u_axi_m_user(
        
        .aclk           ( clk_trans           ), // AXI input clock
        .aresetn        ( rst_n               ), // Active low AXI reset signal
        
        // user interface command port
        .cmd_en         ( ui_cmd_en           ), // Asserted to indicate a valid command
        .cmd            ( ui_cmd              ), // Write or read command
        .blen           ( ui_blen             ), // Burst length calculated as blen+1
        .addr           ( ui_addr             ), // Address for the read or the write
        .ctl            ( ui_ctl              ), // control command for read or write
        .wdog_mask      ( ui_wdog_mask        ), // Mask the watchdog timeouts
        .cmd_ack        ( ui_cmd_ack          ), // Indicates the command has been accepted
        
        // user interface write ports 
        .wrdata_vld     ( ui_wrdata_vld       ), // Asserted to indicate a valid write
        .wrdata         ( ui_wrdata           ), // Write data
        .wrdata_bvld    ( ui_wrdata_bvld      ), // Byte valids for the write data
        .wrdata_cmptd   ( ui_wrdata_cmptd     ), // Last data to be transferred
        .wrdata_rdy     ( ui_wrdata_rdy       ), // Indicates that the write data is
        .wrdata_sts_vld ( ui_wrdata_sts_vld   ), // Indicates a write status after
        .wrdata_sts     ( ui_wrdata_sts       ), // Status of the write transaction
        
        // user interface read ports 
        .rddata_rdy     ( ui_rddata_rdy       ), // Data ready to be accepted
        .rddata_vld     ( ui_rddata_vld       ), // Indicates a valid read data available
        .rddata         ( ui_rddata           ), // Read data
        .rddata_bvld    ( ui_rddata_bvld      ), // Byte valids for read data
        .rddata_cmptd   ( ui_rddata_cmptd     ), // Indicates last data present and
        .rddata_sts     ( ui_rddata_sts       ), // Status of the read transaction
        
        //AXI write address channel signals
        .axi_wready     ( npu_m_axi_wready    ), // Indicates slave is ready to accept a
        .axi_wid        ( npu_m_axi_wid       ), // Write ID
        .axi_waddr      ( npu_m_axi_waddr     ), // Write address
        .axi_wlen       ( npu_m_axi_wlen      ), // Write Burst Length
        .axi_wsize      ( npu_m_axi_wsize     ), // Write Burst size
        .axi_wburst     ( npu_m_axi_wburst    ), // Write Burst type
        .axi_wlock      ( npu_m_axi_wlock     ), // Write lock type
        .axi_wcache     ( npu_m_axi_wcache    ), // Write Cache type
        .axi_wprot      ( npu_m_axi_wprot     ), // Write Protection type
        .axi_wvalid     ( npu_m_axi_wvalid    ), // Write address valid
    
        //AXI write data channel signals 
        .axi_wd_wready  ( npu_m_axi_wd_wready ), // Write data ready
        .axi_wd_wid     ( npu_m_axi_wd_wid    ), // Write ID tag
        .axi_wd_data    ( npu_m_axi_wd_data   ), // Write data
        .axi_wd_strb    ( npu_m_axi_wd_strb   ), // Write strobes
        .axi_wd_last    ( npu_m_axi_wd_last   ), // Last write transaction
        .axi_wd_valid   ( npu_m_axi_wd_valid  ), // Write valid
        
        //AXI response channel signals 
        .axi_wd_bid     ( npu_m_axi_wd_bid    ), // Response ID
        .axi_wd_bresp   ( npu_m_axi_wd_bresp  ), // Write response
        .axi_wd_bvalid  ( npu_m_axi_wd_bvalid ), // Write reponse valid
        .axi_wd_bready  ( npu_m_axi_wd_bready ), // Response ready
        
        //AXI read address channel signals 
        .axi_rready     ( npu_m_axi_rready    ), // Read address ready
        .axi_rid        ( npu_m_axi_rid       ), // Read ID
        .axi_raddr      ( npu_m_axi_raddr     ), // Read address
        .axi_rlen       ( npu_m_axi_rlen      ), // Read Burst Length
        .axi_rsize      ( npu_m_axi_rsize     ), // Read Burst size
        .axi_rburst     ( npu_m_axi_rburst    ), // Read Burst type
        .axi_rlock      ( npu_m_axi_rlock     ), // Read lock type
        .axi_rcache     ( npu_m_axi_rcache    ), // Read Cache type
        .axi_rprot      ( npu_m_axi_rprot     ), // Read Protection type
        .axi_rvalid     ( npu_m_axi_rvalid    ), // Read address valid
       
        //AXI read data channel signals   
        .axi_rd_bid     ( npu_m_axi_rd_bid    ), // Response ID
        .axi_rd_rresp   ( npu_m_axi_rd_rresp  ), // Read response
        .axi_rd_rvalid  ( npu_m_axi_rd_rvalid ), // Read reponse valid
        .axi_rd_data    ( npu_m_axi_rd_data   ), // Read data
        .axi_rd_last    ( npu_m_axi_rd_last   ), // Read last
        .axi_rd_rready  ( npu_m_axi_rd_rready )  // Read Response ready

);     


    //------------------------------------------------------------------------------
    //----instantiate the module that convert  AXI_S to write and read signals----- 
    //------------------------------------------------------------------------------
    

    
    axi_slave_wrapper u_axi_s_user(

        .axi_clk_i     ( clk_trans         ),  //!< AXI global clock
        .axi_rstn_i    ( rst_n             ),  //!< AXI global reset
        
        // axi write address channel
        .axi_awid_i    ( net_s_axi_awid    ),  //!< AXI write address ID
        .axi_awaddr_i  ( net_s_axi_awaddr  ),  //!< AXI write address
        .axi_awlen_i   ( net_s_axi_awlen   ),  //!< AXI write burst length
        .axi_awsize_i  ( net_s_axi_awsize  ),  //!< AXI write burst size
        .axi_awburst_i ( net_s_axi_awburst ),  //!< AXI write burst type
        .axi_awlock_i  ( net_s_axi_awlock  ),  //!< AXI write lock type
        .axi_awcache_i ( net_s_axi_awcache ),  //!< AXI write cache type
        .axi_awprot_i  ( net_s_axi_awprot  ),  //!< AXI write protection type
        .axi_awvalid_i ( net_s_axi_awvalid ),  //!< AXI write address valid
        .axi_awready_o ( net_s_axi_awready ),  //!< AXI write ready
        
        // axi write data channel
        .axi_wid_i     ( net_s_axi_wid     ),  //!< AXI write data ID
        .axi_wdata_i   ( net_s_axi_wdata   ),  //!< AXI write data
        .axi_wstrb_i   ( net_s_axi_wstrb   ),  //!< AXI write strobes
        .axi_wlast_i   ( net_s_axi_wlast   ),  //!< AXI write last
        .axi_wvalid_i  ( net_s_axi_wvalid  ),  //!< AXI write valid
        .axi_wready_o  ( net_s_axi_wready  ),  //!< AXI write ready
        .axi_bid_o     ( net_s_axi_bid     ),  //!< AXI write response ID
        .axi_bresp_o   ( net_s_axi_bresp   ),  //!< AXI write response
        .axi_bvalid_o  ( net_s_axi_bvalid  ),  //!< AXI write response valid
        .axi_bready_i  ( net_s_axi_bready  ),  //!< AXI write response ready
        
        // axi read address channel
        .axi_arid_i    ( net_s_axi_arid    ),  //!< AXI read address ID
        .axi_araddr_i  ( net_s_axi_araddr  ),  //!< AXI read address
        .axi_arlen_i   ( net_s_axi_arlen   ),  //!< AXI read burst length
        .axi_arsize_i  ( net_s_axi_arsize  ),  //!< AXI read burst size
        .axi_arburst_i ( net_s_axi_arburst ),  //!< AXI read burst type
        .axi_arlock_i  ( net_s_axi_arlock  ),  //!< AXI read lock type
        .axi_arcache_i ( net_s_axi_arcache ),  //!< AXI read cache type
        .axi_arprot_i  ( net_s_axi_arprot  ),  //!< AXI read protection type
        .axi_arvalid_i ( net_s_axi_arvalid ),  //!< AXI read address valid
        .axi_arready_o ( net_s_axi_arready ),  //!< AXI read address ready
       
        // axi read data channel
        .axi_rid_o     ( net_s_axi_rid     ),  //!< AXI read response ID
        .axi_rdata_o   ( net_s_axi_rdata   ),  //!< AXI read data
        .axi_rresp_o   ( net_s_axi_rresp   ),  //!< AXI read response
        .axi_rlast_o   ( net_s_axi_rlast   ),  //!< AXI read last
        .axi_rvalid_o  ( net_s_axi_rvalid  ),  //!< AXI read response valid
        .axi_rready_i  ( net_s_axi_rready  ),  //!< AXI read response ready
        
        // register read/write channel                                                     
        .sys_ren       ( sys_ren           ),
        .sys_addr_o    ( reg_addr          ),  //!< system bus read/write address.
        .sys_wdata_o   ( reg_wdata         ),  //!< system bus write data.
        .sys_sel_o     ( reg_sel           ),  //!< system bus write byte select.
        .sys_wen_o     ( reg_wen           ),  //!< system bus write enable.
        .sys_ren_o     ( reg_ren           ),  //!< system bus read enable.
        .sys_rdata_i   ( reg_rdata         ),  //!< system bus read data.
        .sys_err_i     ( reg_err           ),  //!< system bus error indicator.
        .sys_ack_i     ( reg_ack           )   //!< system bus acknowledge signal.
    );


endmodule 
