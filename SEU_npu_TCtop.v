    // ui data signals// *****************************************************************************
// @Project Name : SEU_NPU 
// @Author       : Maos520
// @Email        : sujingjingabc@sina.com
// @File Name    : SEU_npu_TCtop.v
// @Module Name  :
// @Created Time : 2019-11-04 11:26
//
// @Abstract     : This file is the top file of transmission control.
//
// Modification History
// ******************************************************************************
// Date           BY           Version         Change Description
// -------------------------------------------------------------------------
// 2019-11-04   Maos520         v1.0a            initial version 
// 
// ******************************************************************************
`timescale 1ns/1ps

module SEU_npu_TCtop(
                    
    input                     clk_trans,
    input                     clk_cal,
    input                     rst_n,

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

    //layer para 
    output                   BN_lp,   
    output [2:0]             reuse_pattern_lp,    
                                                          
    output [7:0]             Nt_times,            
    output [10:0]            IYt_times,             
    output [7:0]             ft_Nt_cnt,   
    output [10:0]            ft_IYt_cnt,
   
    output [3:0]             KX_lp,
    output [3:0]             CONV_stride_lp,
    output [3:0]             CONV_pad_size_lp,
    output [3:0]             Bm_lp,
    output [3:0]             OYt_lp,  
    output [7:0]             Mt_lp,
    output [7:0]             KKM_lp,
    output [7:0]             KKM8_lp,
    output [7:0]             Hu_Bm_lp,
    output [5:0]             Nt_lp,
    output [10:0]            IYt_lp,
    output [10:0]            OXt_lp,
    output [10:0]            IXt_lp,
    output [10:0]            IX_lp,
    output [16:0]            in_channel_num_lp,
    output [14:0]            out_channel_num_lp,
    output [8:0]             IXt4_lp,
    output [8:0]             IX4_lp,
    output                   CONV_last_lp,
    output [10:0]            OY_lp,
    output [10:0]            POOL_OX_lp,
    output                   RELU_lp,
    output                   AVG_lp,
    output                   MAX_lp,
    output [2:0]             POOL_size_lp,
    output [2:0]             POOL_pad_size_lp,
    output [2:0]             POOL_stride_lp,

    input  [`DDR_DW-1:0]     pe_tx_ofm_wdata,     
    input                    pe_tx_ofm_wvld,
    input  [7:0]             pe_tx_ofm_rows_num,
    //to pe unit
    output                   pe_tx_ofm_wrdy,
    output                   ft_ifm_rvld,
    output [`DDR_DW-1:0]     ft_ifm_rdata,
    output [`DDR_DW-1:0]     ft_wt_rdata, 
    output                   ft_wt_rvld, 
    output [`DDR_DW-1:0]     ft_bn_rdata,    
    output                   ft_bn_rvld,


    input                    pe_cal_done,                
    input                    pe_tx_ofm_start,
                                                      
    output                   pe_cal_start_sync,
    output                   pe_ifm_rst_sync,
    output                   pe_wt_rst_sync,
    output                   pe_first_bn_sync,
    output                   pe_tx_ofm_done_sync,
    output                   pe_ft_lyr_para_done_sync
);

    wire         sys_ren;   
    wire [31:0]  reg_addr; 
    wire [63:0]  reg_wdata;
    wire [7:0]   reg_sel;  
    wire         reg_wen;  
    wire         reg_ren;  
    wire [63:0]  reg_rdata;
    wire         reg_err;  
    wire         reg_ack;  
    wire        ui_cmd_en;  
    wire [2:0]  ui_cmd;     
    wire [7:0]  ui_blen;    
    wire [31:0] ui_addr;    
    wire [1:0]  ui_ctl;     
    wire        ui_wdog_mask; 
    wire        ui_cmd_ack;
    wire        ui_wrdata_vld;  
    wire [63:0] ui_wrdata;      
    wire [7:0]  ui_wrdata_bvld; 
    wire        ui_wrdata_cmptd;
    wire        ui_wrdata_rdy;  
    wire        ui_wrdata_sts_vld; 
    wire [15:0] ui_wrdata_sts;     
    wire        ui_rddata_rdy;   
    wire        ui_rddata_vld;   
    wire [63:0] ui_rddata;       
    wire [7:0]  ui_rddata_bvld;  
    wire        ui_rddata_cmptd; 
    wire [15:0] ui_rddata_sts;   


    wire               npu_busy;              
    wire               img_expired_flg; 
    wire               npu_en_processing;  
    wire               npu_init_cmplt;     
    wire               nn_img_new;   
    wire [`DDR_AW-1:0] nn_wt_saddr;        
    wire [`DDR_AW-1:0] nn_map0_saddr;      
    wire [`DDR_AW-1:0] nn_map1_saddr;      
    wire [`DDR_AW-1:0] nn_bn_saddr;        
    wire [`DDR_AW-1:0] nn_layer_para_saddr;
    wire [`DDR_AW-1:0] nn_img_saddr; 
    wire [7:0]         nn_layers_num;      

    wire [6:0]         mc_cs;
    wire [6:0]         mc_ns;
    wire [5:0]         or_cs;
    wire [5:0]         or_ns;
    wire [11:0]        ft_Mt_cnt;
    
    
    wire [7:0]         tx_Nt_cnt;
    wire [11:0]        tx_OYt_cnt;

    wire [`DDR_AW-1:0] nn_rd_ifm_saddr;  
    wire [`DDR_AW-1:0] nn_wr_ofm_saddr;
    wire [7:0]         nn_layers_cnt;   
                                       
    wire              ft_lyr_para_done;
    wire              ft_bn_done;
    wire              ft_ifm_done;
    wire              ft_wt_done;
    wire              tx_ofm_done;

    wire [11:0]       Mt_times;
    wire              CONV_lp;

    wire              pe_tx_ofm_start_sync;
    wire              pe_cal_start;
    wire              pe_ifm_rst;
    wire              pe_wt_rst;
    wire              pe_first_bn;
    wire              pe_last_bn;
    wire              pe_tx_ofm_done;
    wire              pe_ft_lyr_para_done;
    wire              pe_cal_done_sync;









    SEU_npu_biu u_SEU_npu_biu(
        .clk_trans            ( clk_trans           ),
        .rst_n                ( rst_n               ),
        .npu_s_axi_wid        ( npu_s_axi_wid       ),
        .npu_s_axi_waddr      ( npu_s_axi_waddr     ),
        .npu_s_axi_wlen       ( npu_s_axi_wlen      ),
        .npu_s_axi_wsize      ( npu_s_axi_wsize     ),
        .npu_s_axi_wburst     ( npu_s_axi_wburst    ),
        .npu_s_axi_wcache     ( npu_s_axi_wcache    ),
        .npu_s_axi_wprot      ( npu_s_axi_wprot     ),
        .npu_s_axi_wlock      ( npu_s_axi_wlock     ),
        .npu_s_axi_wvalid     ( npu_s_axi_wvalid    ),
        .npu_s_axi_wready     ( npu_s_axi_wready    ),
        .npu_s_axi_wd_wid     ( npu_s_axi_wd_wid    ),
        .npu_s_axi_wd_data    ( npu_s_axi_wd_data   ),
        .npu_s_axi_wd_strb    ( npu_s_axi_wd_strb   ),
        .npu_s_axi_wd_last    ( npu_s_axi_wd_last   ),
        .npu_s_axi_wd_valid   ( npu_s_axi_wd_valid  ),
        .npu_s_axi_wd_wready  ( npu_s_axi_wd_wready ),
        .npu_s_axi_wd_bid     ( npu_s_axi_wd_bid    ),
        .npu_s_axi_wd_bresp   ( npu_s_axi_wd_bresp  ),
        .npu_s_axi_wd_bvalid  ( npu_s_axi_wd_bvalid ),
        .npu_s_axi_wd_bready  ( npu_s_axi_wd_bready ),
        .npu_s_axi_rid        ( npu_s_axi_rid       ),
        .npu_s_axi_raddr      ( npu_s_axi_raddr     ),
        .npu_s_axi_rlen       ( npu_s_axi_rlen      ),
        .npu_s_axi_rsize      ( npu_s_axi_rsize     ),
        .npu_s_axi_rburst     ( npu_s_axi_rburst    ),
        .npu_s_axi_rcache     ( npu_s_axi_rcache    ),
        .npu_s_axi_rprot      ( npu_s_axi_rprot     ),
        .npu_s_axi_rd_bid     ( npu_s_axi_rd_bid    ),
        .npu_s_axi_rd_data    ( npu_s_axi_rd_data   ),
        .npu_s_axi_rd_rresp   ( npu_s_axi_rd_rresp  ),
        .npu_s_axi_rd_last    ( npu_s_axi_rd_last   ),
        .npu_s_axi_rd_rvalid  ( npu_s_axi_rd_rvalid ),
        .npu_s_axi_rd_rready  ( npu_s_axi_rd_rready ),
        .sys_ren              ( sys_ren             ),
        .reg_addr             ( reg_addr            ),
        .reg_wdata            ( reg_wdata           ),
        .reg_sel              ( reg_sel             ),
        .reg_wen              ( reg_wen             ),
        .reg_ren              ( reg_ren             ),
        .reg_rdata            ( reg_rdata           ),
        .reg_err              ( reg_err             ),
        .reg_ack              ( reg_ack             ),
        .npu_m_axi_wready     ( npu_m_axi_wready    ),
        .npu_m_axi_wid        ( npu_m_axi_wid       ),
        .npu_m_axi_waddr      ( npu_m_axi_waddr     ),
        .npu_m_axi_wlen       ( npu_m_axi_wlen      ),
        .npu_m_axi_wsize      ( npu_m_axi_wsize     ),
        .npu_m_axi_wburst     ( npu_m_axi_wburst    ),
        .npu_m_axi_wlock      ( npu_m_axi_wlock     ),
        .npu_m_axi_wcache     ( npu_m_axi_wcache    ),
        .npu_m_axi_wprot      ( npu_m_axi_wprot     ),
        .npu_m_axi_wvalid     ( npu_m_axi_wvalid    ),
        .npu_m_axi_wd_wready  ( npu_m_axi_wd_wready ),
        .npu_m_axi_wd_wid     ( npu_m_axi_wd_wid    ),
        .npu_m_axi_wd_data    ( npu_m_axi_wd_data   ),
        .npu_m_axi_wd_strb    ( npu_m_axi_wd_strb   ),
        .npu_m_axi_wd_last    ( npu_m_axi_wd_last   ),
        .npu_m_axi_wd_valid   ( npu_m_axi_wd_valid  ),
        .npu_m_axi_wd_bid     ( npu_m_axi_wd_bid    ),
        .npu_m_axi_wd_bresp   ( npu_m_axi_wd_bresp  ),
        .npu_m_axi_wd_bvalid  ( npu_m_axi_wd_bvalid ),
        .npu_m_axi_wd_bready  ( npu_m_axi_wd_bready ),
        .npu_m_axi_rready     ( npu_m_axi_rready    ),
        .npu_m_axi_rid        ( npu_m_axi_rid       ),
        .npu_m_axi_raddr      ( npu_m_axi_raddr     ),
        .npu_m_axi_rlen       ( npu_m_axi_rlen      ),
        .npu_m_axi_rsize      ( npu_m_axi_rsize     ),
        .npu_m_axi_rburst     ( npu_m_axi_rburst    ),
        .npu_m_axi_rlock      ( npu_m_axi_rlock     ),
        .npu_m_axi_rcache     ( npu_m_axi_rcache    ),
        .npu_m_axi_rprot      ( npu_m_axi_rprot     ),
        .npu_m_axi_rvalid     ( npu_m_axi_rvalid    ),
        .npu_m_axi_rd_bid     ( npu_m_axi_rd_bid    ),
        .npu_m_axi_rd_rresp   ( npu_m_axi_rd_rresp  ),
        .npu_m_axi_rd_rvalid  ( npu_m_axi_rd_rvalid ),
        .npu_m_axi_rd_data    ( npu_m_axi_rd_data   ),
        .npu_m_axi_rd_last    ( npu_m_axi_rd_last   ),
        .npu_m_axi_rd_rready  ( npu_m_axi_rd_rready ),
        .ui_cmd_en            ( ui_cmd_en           ),
        .ui_cmd               ( ui_cmd              ),
        .ui_blen              ( ui_blen             ),
        .ui_addr              ( ui_addr             ),
        .ui_ctl               ( ui_ctl              ),
        .ui_wdog_mask         ( ui_wdog_mask        ),
        .ui_cmd_ack           ( ui_cmd_ack          ),
        .ui_wrdata_vld        ( ui_wrdata_vld       ),
        .ui_wrdata            ( ui_wrdata           ),
        .ui_wrdata_bvld       ( ui_wrdata_bvld      ),
        .ui_wrdata_cmptd      ( ui_wrdata_cmptd     ),
        .ui_wrdata_rdy        ( ui_wrdata_rdy       ),
        .ui_wrdata_sts_vld    ( ui_wrdata_sts_vld   ),
        .ui_wrdata_sts        ( ui_wrdata_sts       ),
        .ui_rddata_rdy        ( ui_rddata_rdy       ),
        .ui_rddata_vld        ( ui_rddata_vld       ),
        .ui_rddata            ( ui_rddata           ),
        .ui_rddata_bvld       ( ui_rddata_bvld      ),
        .ui_rddata_cmptd      ( ui_rddata_cmptd     ),
        .ui_rddata_sts        ( ui_rddata_sts       )
    );


    SEU_npu_CCReg u_SEU_npu_CCReg(
        .clk_trans                ( clk_trans           ),
        .rst_n                    ( rst_n               ),
        .sys_ren                  ( sys_ren             ),
        .reg_addr                 ( reg_addr            ),
        .reg_wdata                ( reg_wdata           ),
        .reg_sel                  ( reg_sel             ),
        .reg_wen                  ( reg_wen             ),
        .reg_ren                  ( reg_ren             ),
        .reg_rdata                ( reg_rdata           ),
        .reg_err                  ( reg_err             ),
        .reg_ack                  ( reg_ack             ),
        .npu_busy                 ( npu_busy            ),
        .img_expired_flg          ( img_expired_flg     ),
        .npu_en_processing        ( npu_en_processing   ),
        .npu_init_cmplt           ( npu_init_cmplt      ),
        .nn_img_new               ( nn_img_new          ),
        .nn_wt_saddr              ( nn_wt_saddr         ),
        .nn_map0_saddr            ( nn_map0_saddr       ),
        .nn_map1_saddr            ( nn_map1_saddr       ),
        .nn_bn_saddr              ( nn_bn_saddr         ),
        .nn_layer_para_saddr      ( nn_layer_para_saddr ),
        .nn_img_saddr             ( nn_img_saddr        ),
        .nn_layers_num            ( nn_layers_num       )
    );


    SEU_npu_mcu u_SEU_npu_mcu(
        .clk_trans            ( clk_trans            ),
        .rst_n                ( rst_n                ),
        .npu_en_processing    ( npu_en_processing    ),
        .npu_init_cmplt       ( npu_init_cmplt       ),
        .nn_img_new           ( nn_img_new           ),
        .nn_map0_saddr        ( nn_map0_saddr        ),
        .nn_map1_saddr        ( nn_map1_saddr        ),
        .nn_img_saddr         ( nn_img_saddr         ),
        .nn_layers_num        ( nn_layers_num        ),
        .npu_busy             ( npu_busy             ),
        .img_expired_flg      ( img_expired_flg      ),
        .CONV_lp              ( CONV_lp              ),
        .BN_lp                ( BN_lp                ),
        .reuse_pattern_lp     ( reuse_pattern_lp     ),
        .Nt_times             ( Nt_times             ),
        .Mt_times             ( Mt_times             ),
        .IYt_times            ( IYt_times            ),
        .ft_lyr_para_done     ( ft_lyr_para_done     ),
        .ft_bn_done           ( ft_bn_done           ),
        .ft_wt_done           ( ft_wt_done           ),
        .ft_ifm_done          ( ft_ifm_done          ),
        .tx_ofm_done          ( tx_ofm_done          ),
        .mc_cs                ( mc_cs                ),
        .mc_ns                ( mc_ns                ),
        .or_cs                ( or_cs                ),
        .or_ns                ( or_ns                ),
        .tx_Nt_cnt            ( tx_Nt_cnt            ),
        .tx_OYt_cnt           ( tx_OYt_cnt           ),
        .ft_Mt_cnt            ( ft_Mt_cnt            ),
        .ft_Nt_cnt            ( ft_Nt_cnt            ),
        .ft_IYt_cnt           ( ft_IYt_cnt           ),
        .nn_rd_ifm_saddr      ( nn_rd_ifm_saddr      ),
        .nn_wr_ofm_saddr      ( nn_wr_ofm_saddr      ),
        .nn_layers_cnt        ( nn_layers_cnt        ),
        .pe_cal_done_sync     ( pe_cal_done_sync     ),
        .pe_tx_ofm_start_sync ( pe_tx_ofm_start_sync ),
        .pe_cal_start         ( pe_cal_start         ),
        .pe_ifm_rst           ( pe_ifm_rst           ),
        .pe_wt_rst            ( pe_wt_rst            ),
        .pe_first_bn          ( pe_first_bn          ),
        .pe_last_bn           ( pe_last_bn           ),
        .pe_tx_ofm_done       ( pe_tx_ofm_done       ),
        .pe_ft_lyr_para_done  ( pe_ft_lyr_para_done  )
    ) ;

    SEU_npu_MemCtrl u_SEU_npu_MemCtrl(
        .clk_trans            ( clk_trans            ),
        .rst_n                ( rst_n                ),
        .ui_cmd_en            ( ui_cmd_en            ),
        .ui_cmd               ( ui_cmd               ),
        .ui_blen              ( ui_blen              ),
        .ui_addr              ( ui_addr              ),
        .ui_ctl               ( ui_ctl               ),
        .ui_wdog_mask         ( ui_wdog_mask         ),
        .ui_cmd_ack           ( ui_cmd_ack           ),
        .ui_wrdata_vld        ( ui_wrdata_vld        ),
        .ui_wrdata            ( ui_wrdata            ),
        .ui_wrdata_bvld       ( ui_wrdata_bvld       ),
        .ui_wrdata_cmptd      ( ui_wrdata_cmptd      ),
        .ui_wrdata_rdy        ( ui_wrdata_rdy        ),
        .ui_wrdata_sts_vld    ( ui_wrdata_sts_vld    ),
        .ui_wrdata_sts        ( ui_wrdata_sts        ),
        .ui_rddata_rdy        ( ui_rddata_rdy        ),
        .ui_rddata_vld        ( ui_rddata_vld        ),
        .ui_rddata            ( ui_rddata            ),
        .ui_rddata_bvld       ( ui_rddata_bvld       ),
        .ui_rddata_cmptd      ( ui_rddata_cmptd      ),
        .ui_rddata_sts        ( ui_rddata_sts        ),
        .mc_cs                ( mc_cs                ),
        .mc_ns                ( mc_ns                ),
        .or_cs                ( or_cs                ),
        .or_ns                ( or_ns                ),
        .ft_Mt_cnt            ( ft_Mt_cnt            ),
        .ft_Nt_cnt            ( ft_Nt_cnt            ),
        .ft_IYt_cnt           ( ft_IYt_cnt           ),
        .tx_Nt_cnt            ( tx_Nt_cnt            ),
        .tx_OYt_cnt           ( tx_OYt_cnt           ),
        .nn_rd_ifm_saddr      ( nn_rd_ifm_saddr      ),
        .nn_wr_ofm_saddr      ( nn_wr_ofm_saddr      ),
        .nn_layers_cnt        ( nn_layers_cnt        ),
        .ft_lyr_para_done     ( ft_lyr_para_done     ),
        .ft_bn_done           ( ft_bn_done           ),
        .ft_ifm_done          ( ft_ifm_done          ),
        .ft_wt_done           ( ft_wt_done           ),
        .tx_ofm_done          ( tx_ofm_done          ),
        .nn_wt_saddr          ( nn_wt_saddr          ),
        .nn_bn_saddr          ( nn_bn_saddr          ),
        .nn_layer_para_saddr  ( nn_layer_para_saddr  ),
        .CONV_lp              ( CONV_lp              ),
        .BN_lp                ( BN_lp                ),
        .reuse_pattern_lp     ( reuse_pattern_lp     ),
        .Nt_times             ( Nt_times             ),
        .Mt_times             ( Mt_times             ),
        .IYt_times            ( IYt_times            ),
        .KX_lp                ( KX_lp                ),
        .CONV_stride_lp       ( CONV_stride_lp       ),
        .CONV_pad_size_lp     ( CONV_pad_size_lp     ),
        .Bm_lp                ( Bm_lp                ),
        .OYt_lp               ( OYt_lp               ),
        .Mt_lp                ( Mt_lp                ),
        .KKM_lp               ( KKM_lp               ),
        .KKM8_lp              ( KKM8_lp              ),
        .Hu_Bm_lp             ( Hu_Bm_lp             ),
        .Nt_lp                ( Nt_lp                ),
        .IYt_lp               ( IYt_lp               ),
        .OXt_lp               ( OXt_lp               ),
        .IXt_lp               ( IXt_lp               ),
        .IX_lp                ( IX_lp                ),
        .in_channel_num_lp    ( in_channel_num_lp    ),
        .out_channel_num_lp   ( out_channel_num_lp   ),
        .IXt4_lp              ( IXt4_lp              ),
        .IX4_lp               ( IX4_lp               ),
        .CONV_last_lp         ( CONV_last_lp         ),
        .OY_lp                ( OY_lp                ),
        .POOL_OX_lp           ( POOL_OX_lp           ),
        .RELU_lp              ( RELU_lp              ),
        .AVG_lp               ( AVG_lp               ),
        .MAX_lp               ( MAX_lp               ),
        .POOL_size_lp         ( POOL_size_lp         ),
        .POOL_pad_size_lp     ( POOL_pad_size_lp     ),
        .POOL_stride_lp       ( POOL_stride_lp       ),
        .pe_tx_ofm_start_sync ( pe_tx_ofm_start_sync ),
        .pe_tx_ofm_wdata      ( pe_tx_ofm_wdata      ),
        .pe_tx_ofm_wvld       ( pe_tx_ofm_wvld       ),
        .pe_tx_ofm_rows_num   ( pe_tx_ofm_rows_num   ),
        .pe_tx_ofm_wrdy       ( pe_tx_ofm_wrdy       ),
        .ft_ifm_rvld          ( ft_ifm_rvld          ),
        .ft_ifm_rdata         ( ft_ifm_rdata         ),
        .ft_wt_rdata          ( ft_wt_rdata          ),
        .ft_wt_rvld           ( ft_wt_rvld           ),
        .ft_bn_rdata          ( ft_bn_rdata          ),
        .ft_bn_rvld           ( ft_bn_rvld           )
    );


    SEU_npu_sync u_SEU_npu_sync(
        .clk_cal                  ( clk_cal                  ),
        .clk_trans                ( clk_trans                ),
        .rst_n                    ( rst_n                    ),
        .pe_cal_start             ( pe_cal_start             ),
        .pe_ifm_rst               ( pe_ifm_rst               ),
        .pe_wt_rst                ( pe_wt_rst                ),
        .pe_first_bn              ( pe_first_bn              ),
        .pe_last_bn               ( pe_last_bn               ),
        .pe_tx_ofm_done           ( pe_tx_ofm_done           ),
        .pe_ft_lyr_para_done      ( pe_ft_lyr_para_done      ),
        .pe_cal_done_sync         ( pe_cal_done_sync         ),
        .pe_tx_ofm_start_sync     ( pe_tx_ofm_start_sync     ),
        .pe_cal_done              ( pe_cal_done              ),
        .pe_tx_ofm_start          ( pe_tx_ofm_start          ),
        .pe_cal_start_sync        ( pe_cal_start_sync        ),
        .pe_ifm_rst_sync          ( pe_ifm_rst_sync          ),
        .pe_wt_rst_sync           ( pe_wt_rst_sync           ),
        .pe_first_bn_sync         ( pe_first_bn_sync         ),
        .pe_tx_ofm_done_sync      ( pe_tx_ofm_done_sync      ),
        .pe_ft_lyr_para_done_sync ( pe_ft_lyr_para_done_sync )
    );

endmodule 
