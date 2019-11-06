// *****************************************************************************
// @Project Name : SEU_NPU 
// @Author       : Maos520
// @Email        : sujingjingabc@sina.com
// @File Name    : SEU_npu_MemCtrl.v
// @Module Name  : SEU_npu_MemCtrl
// @Created Time : 2019-10-26 17:33
//
// @Abstract     : This module control the DDR access logic according to mcu 
//              control signals.  
//
// Modification History
// ******************************************************************************
// Date           BY           Version         Change Description
// -------------------------------------------------------------------------
// 2019-10-26   maos520         v1.0a           initial version 
// ******************************************************************************

`timescale 1ns/1ps

module SEU_npu_MemCtrl(
    input                    clk_trans,
    input                    rst_n,

    output reg               ui_cmd_en,  // Asserted to indicate a valid command and address
    output reg  [2:0]        ui_cmd,     // Write or read command
    //                          // 000 - READ with INCR bursts
    //                          // 001 - READ with WRAP bursts
    //                          // 01x - Reserved
    //                          // 100 - WRITE with INCR bursts
    //                         // 101 - WRITE with WRAP bursts
    output reg [15:0]        ui_blen,    // Burst length calculated as blen+1
    output reg [`DDR_AW-1:0] ui_addr,    // Address for the read or the write transaction
    output     [1:0]         ui_ctl,     // control command for read or write transaction 
    output                   ui_wdog_mask, // Mask the watchdog timeouts
    input                    ui_cmd_ack,// Indicates the command has been accepted
                                                                                                
    //User interface write ports
    output reg               ui_wrdata_vld,  // Asserted to indicate a valid write data
    output     [`DDR_DW-1:0] ui_wrdata,      // Write data
    output reg [7:0]         ui_wrdata_bvld, // Byte valids for the write data
    output reg               ui_wrdata_cmptd,// Last data to be transferred
    input                    ui_wrdata_rdy,  // Indicates that the write data is ready to be accepted
    input                    ui_wrdata_sts_vld, // Indicates a write status after 
    //                                 // completion of a write transfer   
    input      [15:0]        ui_wrdata_sts,     // Status of the write transaction
                                                                                                
    //User interface read ports
    output reg               ui_rddata_rdy,   // Data ready to be accepted
    input                    ui_rddata_vld,   // Indicates a valid read data available
    input      [`DDR_DW-1:0] ui_rddata,       // Read data
    input      [7:0]         ui_rddata_bvld,  // Byte valids for read data 
    input                    ui_rddata_cmptd, // Indicates last data present and valid status
    input      [15:0]        ui_rddata_sts,   // Status of the read transaction



    // from MCU
    input      [6:0]         mc_cs,
    input      [6:0]         mc_ns,
    input      [5:0]         or_cs,
    input      [5:0]         or_ns,
    input      [11:0]        ft_Mt_cnt,
    input      [7:0]         ft_Nt_cnt,
    input      [10:0]        ft_IYt_cnt,
    input      [7:0]         tx_Nt_cnt,
    input      [11:0]        tx_OYt_cnt,
        
    input  [`DDR_AW-1:0]     nn_rd_ifm_saddr,  
    input  [`DDR_AW-1:0]     nn_wr_ofm_saddr,
    input  [7:0]             nn_layers_cnt,     

    // to mcu
    output reg               ft_lyr_para_done,
    output reg               ft_bn_done,
    output reg               ft_ifm_done,
    output reg               ft_wt_done,
    output reg               tx_ofm_done,
      
    //from CCR                                     
    input  [`DDR_AW-1:0]     nn_wt_saddr,        
    input  [`DDR_AW-1:0]     nn_bn_saddr,        
    input  [`DDR_AW-1:0]     nn_layer_para_saddr,

    // layer para
    output                   CONV_lp,   //mcu 
    output                   BN_lp,   //mcu  
    output [2:0]             reuse_pattern_lp,//mcu     

    output [7:0]             Nt_times,            //mcu 
    output [11:0]            Mt_times,            //mcu 
    output [10:0]            IYt_times,            //mcu 
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
    //from sync
    input                    pe_tx_ofm_start_sync,
    
    //from pe unit
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
    output                   ft_bn_rvld
);    
    //-------------------------------------
    //Master control state declarations 
    //------------------------------------
    localparam [6:0] IDLE     = 7'd0; // idle state
    localparam [6:0] IMG_UD   = 7'd1; // wait until the image is updated
    localparam [6:0] FT_PARA  = 7'd2; // read each layer specific parameter
    localparam [6:0] FT_BN    = 7'd3; // read each layer BN parameter
    localparam [6:0] DF_SLT   = 7'd4; // select dataflow mode according to para
    localparam [6:0] LY_DONE  = 7'd5; // end of layer calculation
    localparam [6:0] INF_DONE = 7'd6; // end of a inferrence
                                          
    //------------------------------------------
    // OR dataflow control state declarations 
    //-----------------------------------------
    
    localparam [6:0] OR_IDLE   = 6'd0;   
    localparam [5:0] OR_FT_IFM = 6'd1;
    localparam [5:0] OR_FT_WT  = 6'd2;
    localparam [5:0] OR_CAL    = 6'd3;
    localparam [5:0] OR_TX_OFM = 6'd4;
    localparam [5:0] OR_DONE   = 6'd5;

    //-----------------------------------------
    // FC dataflow control state declarations 
    //----------------------------------------
    localparam [5:0] FC_IDLE   = 6'd0;
    localparam [5:0] FC_FT_IFM = 6'd1;
    localparam [5:0] FC_FT_WT  = 6'd2;
    localparam [5:0] FC_TX_OFM = 6'd3;
    localparam [5:0] FC_CAL    = 6'd4;
    localparam [5:0] FC_DONE   = 6'd5;


    //---------------------------------------------
    // Fetch input feature map state declarations 
    //---------------------------------------------

    localparam [5:0] IFM_IDLE     = 6'd0;
    localparam [5:0] IFM_LD       = 6'd1;
    localparam [5:0] IFM_PD_U     = 6'd2;
    localparam [5:0] IFM_PD_B     = 6'd3;
    localparam [5:0] IFM_PD_D     = 6'd4;
    localparam [5:0] IFM_SLC_DONE = 6'd5;
                                          
    //fetch layer parameter signals related     
    reg                        ft_lyr_para_cmd_en;
    reg  [2:0]                 ft_lyr_para_cmd;
    reg  [7:0]                 ft_lyr_para_rblen;
    reg  [`DDR_AW-1:0]         ft_lyr_para_raddr;
    reg                        ft_lyr_para_rrdy; 
    wire                       ft_lyr_para_rvld;
    wire [`DDR_DW-1:0]         ft_lyr_para_rdata;

    reg  [`DDR_DW-1:0]         nn_para_mem[0:7];
    reg  [2:0]                 nn_para_mem_addr; 
    
    reg  [8:0]                 ft_bn_burst_cnt;      
    wire [8:0]                 ft_bn_burst_times;
    reg                        ft_bn_burst_done;   

    //fetch input feature map signals related 
    reg                        ft_ifm_cmd_en;
    reg  [2:0]                 ft_ifm_cmd;
    reg  [7:0]                 ft_ifm_rblen;
    reg  [`DDR_AW-1:0]         ft_ifm_raddr;
    reg                        ft_ifm_rrdy;
    
    reg  [5:0]                 ft_ifm_cs;  
    reg  [5:0]                 ft_ifm_ns;

    wire                       ft_ifm_en;
    reg                        ft_ifm_slice_start;    
    reg  [7:0]                 ft_ifm_slice_cnt;
    wire [7:0]                 ft_ifm_slice_cnt_nxt;
    wire                       ft_ifm_slice_done;
    reg  [15:0]                ft_ifm_slice_len;
    reg  [15:0]                ft_ifm_slice_len_nxt;
    reg  [`DDR_AW-1:0]         ft_ifm_slice_saddr;
    reg  [`DDR_AW-1:0]         ft_ifm_slice_saddr_nxt;
    
    reg  [15:0]                ifm_pd_neurons_cnt; 
    wire [15:0]                ifm_pd_neurons_cnt_nxt;
    reg  [15:0]                ifm_pd_neurons_num;
    wire                       ifm_pd_d_rows_num;
    wire                       ifm_pd_u_rows_num;
    wire                       ifm_pd_symmetry;     
    reg                        ifm_pd_done;
                                                
    reg  [8:0]                 ft_ifm_burst_cnt;
    wire [8:0]                 ft_ifm_burst_cnt_nxt;
    wire [7:0]                 ft_ifm_burst_len;
    wire [8:0]                 ft_ifm_burst_num;
    reg                        ft_ifm_burst_done;
    
    // fetch weight signals related
    reg                        ft_wt_cmd_en;
    reg  [2:0]                 ft_wt_cmd;
    reg  [7:0]                 ft_wt_rblen;
    reg  [`DDR_AW-1:0]         ft_wt_raddr;
    reg                        ft_wt_rrdy;
    
    
    reg                        ft_wt_start;          
    reg  [5:0]                 ft_wt_kkm8_cnt;
    wire [5:0]                 ft_wt_kkm8_cnt_nxt;
    reg  [`DDR_AW-1:0]         ft_wt_kkm8_saddr;
    wire [`DDR_AW-1:0]         ft_wt_kkm8_saddr_nxt;
    wire [15:0]                ft_wt_kkm8_len;
    reg                        ft_wt_kkm8_done;
    reg                        ft_wt_kkm8_done_r0;
                                                     
    wire [8:0]                 ft_wt_burst_num;
    wire [7:0]                 ft_wt_burst_len;
    reg  [8:0]                 ft_wt_burst_cnt;
    wire [8:0]                 ft_wt_burst_cnt_nxt;
    reg                        ft_wt_burst_done;
    
    // transmit output feature map signals related 
    reg                        tx_ofm_cmd_en;
    reg  [2:0]                 tx_ofm_cmd;
    reg  [7:0]                 tx_ofm_wblen;
    reg  [`DDR_AW-1:0]         tx_ofm_waddr;
    reg  [7:0]                 tx_ofm_wbvld;
    wire                       tx_ofm_wvld;
    reg                        tx_ofm_wcmptd;
    
    reg  [7:0]                 tx_ofm_slice_cnt;        
    wire [7:0]                 tx_ofm_slice_cnt_nxt;
    reg                        tx_ofm_slice_done;
    reg                        tx_ofm_slice_done_r0;
    wire [15:0]                tx_ofm_slice_len;
    reg  [`DDR_AW-1:0]         tx_ofm_slice_saddr;
    wire [`DDR_AW-1:0]         tx_ofm_slice_saddr_nxt;
    
                                                       
    reg  [8:0]                 tx_ofm_burst_cnt;
    wire [8:0]                 tx_ofm_burst_cnt_nxt;
    wire [7:0]                 tx_ofm_burst_len;
    wire [8:0]                 tx_ofm_burst_num;
    reg                        tx_ofm_burst_done;
                                                         
    reg  [7:0]                 tx_ofm_sent_cnt;
    wire [7:0]                 tx_ofm_sent_cnt_nxt;
    reg                        tx_ofm_start;

    reg                        ft_bn_cmd_en;
    reg  [2:0]                 ft_bn_cmd;
    reg  [15:0]                ft_bn_rblen;
    reg  [`DDR_AW-1:0]         ft_bn_raddr;
    reg                        ft_bn_rrdy;
    
    

    //layer parameters             
    wire                       FCN_lp;
    wire [3:0]                 KY_lp;
    wire [5:0]                 Batch_size_lp;
    wire [10:0]                IY_lp;
    wire [10:0]                OX_lp;
    wire [8:0]                 CONV_POOL_OX4_lp;
    wire [10:0]                POOL_OY_lp;
    wire                       ofm_div_flg;                                      
    wire                       wt_div_flg;          
    wire                       ifm_div_flg;         
    wire                       ofm_div_wt_reuse_flg;                            
    wire [7:0]                 Mt_last_num;
    wire [3:0]                 IYt_last_num;   
    wire [9:0]                 OXt4;                
    wire [9:0]                 OX4_align;                 
    wire [9:0]                 POOL_OX4_align;            
    wire [7:0]                 send_FC_cnt;         
    wire [10:0]                IYt_last;            
    wire                       IYt_dif;             
    wire [16:0]                bn_para_num;            
    wire [14:0]                bn_para_num4;
        
    wire [`DDR_AW-1:0]         cur_lyr_bn_saddr;
    wire [`DDR_AW-1:0]         cur_lyr_wt_saddr;
    

//**************************************************************************
// mux for user interface  
//**************************************************************************

    always @(*) begin
        ui_cmd_en               <= 1'b0;
        ui_cmd                  <= 3'b0;
        ui_blen                 <= 8'b0;
        ui_addr                 <= 32'b0;
        ui_rddata_rdy           <= 1'b0;
        ui_wrdata_vld           <= 1'b0;
        ui_wrdata_cmptd         <= 1'b0;
        ui_wrdata_bvld          <= 1'b0;
        case(1'b1)
            mc_cs[FT_PARA]                                      : begin
                ui_cmd_en       <= ft_lyr_para_cmd_en; 
                ui_cmd          <= ft_lyr_para_cmd;    
                ui_blen         <= ft_lyr_para_rblen;  
                ui_addr         <= ft_lyr_para_raddr;  
                ui_rddata_rdy   <= ft_lyr_para_rrdy;   
            end
            mc_cs[FT_BN]                                        : begin
                ui_cmd_en       <= ft_bn_cmd_en;
                ui_cmd          <= ft_bn_cmd;
                ui_blen         <= ft_bn_rblen;
                ui_addr         <= ft_bn_raddr;
                ui_rddata_rdy   <= ft_bn_rrdy;
            end
            mc_cs[DF_SLT]&&(or_cs[OR_FT_IFM])  : begin
                ui_cmd_en       <= ft_ifm_cmd_en;
                ui_cmd          <= ft_ifm_cmd;
                ui_blen         <= ft_ifm_rblen;
                ui_addr         <= ft_ifm_raddr;
                ui_rddata_rdy   <= ft_ifm_rrdy;
            end 
            mc_cs[DF_SLT]&&(or_cs[OR_FT_WT])    : begin
                ui_cmd_en       <= ft_wt_cmd_en;
                ui_cmd          <= ft_wt_cmd;
                ui_blen         <= ft_wt_rblen;
                ui_addr         <= ft_wt_raddr;
                ui_rddata_rdy   <= ft_wt_rrdy;
            end
            mc_cs[DF_SLT]&&(or_cs[OR_TX_OFM])  : begin
                ui_cmd_en       <= tx_ofm_cmd_en;
                ui_cmd          <= tx_ofm_cmd;
                ui_blen         <= tx_ofm_wblen;
                ui_addr         <= tx_ofm_waddr;
                ui_wrdata_vld   <= tx_ofm_wvld;
                ui_wrdata_cmptd <= tx_ofm_wcmptd;
                ui_wrdata_bvld  <= tx_ofm_wbvld;
            end
        endcase 
    end
    
    assign ui_ctl       = 2'd3;
    assign ui_wdog_mask = 1'b0;

//******************************************************************************
//  read layers parameter channel control logic and data signals  
//******************************************************************************
    

// read layer parameters control logic

    always @(posedge clk_trans or negedge rst_n) 
        if(!rst_n) 
            ft_lyr_para_rrdy <= 1'b0;
        else if (mc_ns[FT_PARA]&&(mc_cs[IMG_UD]|mc_cs[LY_DONE]|ui_cmd_ack))
            ft_lyr_para_rrdy <= 1'b1;
        else if (mc_cs[FT_PARA]&&ui_rddata_cmptd)
            ft_lyr_para_rrdy <= 1'b0;
    
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_lyr_para_cmd_en <= 1'b0;
        else if(mc_ns[FT_PARA]&&(mc_cs[IMG_UD]|mc_cs[LY_DONE]))
            ft_lyr_para_cmd_en <= 1'b1;
        else if(mc_cs[FT_PARA]&&ui_cmd_ack)
            ft_lyr_para_cmd_en <= 1'b0;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_lyr_para_cmd <= 3'b0;
        else if (mc_ns[FT_PARA]&&(mc_cs[IMG_UD]|mc_cs[LY_DONE]))
            ft_lyr_para_cmd <= 3'b0;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_lyr_para_rblen <= 8'b0;
        else if (mc_ns[FT_PARA]&&(mc_cs[IMG_UD]|mc_cs[LY_DONE]))
            ft_lyr_para_rblen <= 8'd7;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_lyr_para_raddr <= `DDR_AW'b0;
        else if(mc_ns[FT_PARA]&&(mc_cs[IMG_UD]|mc_cs[LY_DONE]))  
            ft_lyr_para_raddr <= nn_layer_para_saddr + {nn_layers_cnt,{6{1'b0}}}; 
    
    // read layer parameters data signals

    assign ft_lyr_para_rdata = ft_lyr_para_rvld ? ui_rddata : `DDR_DW'b0;
    assign ft_lyr_para_rvld  = mc_cs[FT_PARA] && ui_rddata_vld; 

    // to mcu
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_lyr_para_done <= 1'b0;
        else if (mc_ns[FT_PARA]&&(mc_cs[IMG_UD]|mc_cs[LY_DONE]))
            ft_lyr_para_done <= 1'b0;
        else if (mc_cs[FT_PARA] && ui_rddata_cmptd)
            ft_lyr_para_done <= 1'b1; 
            
    //store para in registers
    always @(posedge clk_trans or negedge rst_n) 
        if(!rst_n) 
            nn_para_mem_addr <= 3'b0;
        else if(mc_ns[FT_PARA]&&(mc_cs[IMG_UD]|mc_cs[LY_DONE]))
            nn_para_mem_addr <= 3'b0;
        else if(mc_cs[FT_PARA]&&ft_lyr_para_rvld)
            nn_para_mem_addr <= nn_para_mem_addr + 1'b1;

    always @(posedge clk_trans)
        if(mc_cs[FT_PARA]&&ft_lyr_para_rvld)
            nn_para_mem[nn_para_mem_addr] <= ft_lyr_para_rdata;
         
    // parse layer parameter     
    assign  cur_lyr_bn_saddr  = nn_para_mem[0][63:32] + nn_bn_saddr;
    assign  cur_lyr_wt_saddr  = nn_para_mem[0][31:0] + nn_wt_saddr;
    
    assign  CONV_lp             = nn_para_mem[1][0];
    assign  FCN_lp              = nn_para_mem[1][1];
    assign  BN_lp               = nn_para_mem[1][2];
    assign  MAX_lp              = nn_para_mem[1][3];
    assign  AVG_lp              = nn_para_mem[1][4];
    assign  RELU_lp             = nn_para_mem[1][5];
    assign  reuse_pattern_lp    = nn_para_mem[1][8:6];
    assign  KX_lp               = nn_para_mem[1][12:9];
    assign  KY_lp               = nn_para_mem[1][16:13];
    assign  CONV_stride_lp      = nn_para_mem[1][20:17];
    assign  CONV_pad_size_lp    = nn_para_mem[1][24:21];
    assign  Batch_size_lp       = nn_para_mem[1][30:25];
    assign  POOL_size_lp        = nn_para_mem[1][33:31];
    assign  POOL_pad_size_lp    = nn_para_mem[1][36:34];
    assign  POOL_stride_lp      = nn_para_mem[1][39:37];
    assign  CONV_last_lp        = nn_para_mem[1][40];
    assign  IX_lp               = nn_para_mem[2][10:0];
    assign  IY_lp               = nn_para_mem[2][21:11];
    assign  IX4_lp              = nn_para_mem[2][30:22];
    assign  in_channel_num_lp   = nn_para_mem[2][46:31];
    assign  out_channel_num_lp  = nn_para_mem[2][60:47];
    assign  OX_lp               = nn_para_mem[3][10:0];
    assign  OY_lp               = nn_para_mem[3][21:11];
    assign  CONV_POOL_OX4_lp    = nn_para_mem[3][30:22];
    assign  POOL_OX_lp          = nn_para_mem[3][41:31];
    assign  POOL_OY_lp          = nn_para_mem[3][52:42];
    assign  Mt_lp               = nn_para_mem[4][7:0];
    assign  Nt_lp               = nn_para_mem[4][13:8];                   
    assign  OYt_lp              = nn_para_mem[4][17:14];
    assign  OXt_lp              = nn_para_mem[4][28:18];
    assign  IXt_lp              = nn_para_mem[4][39:29];
    assign  IXt4_lp             = nn_para_mem[4][48:40];
    assign  IYt_lp              = nn_para_mem[4][59:49];
    assign  KKM_lp              = nn_para_mem[5][7:0];
    assign  KKM8_lp             = nn_para_mem[5][15:8];   
    assign  Bm_lp               = nn_para_mem[5][19:16];
    assign  Hu_Bm_lp            = nn_para_mem[5][27:20];
                                                                                                                              
    assign ofm_div_flg          = (out_channel_num_lp * OXt_lp * OYt_lp > (1 << 17)) ? 1 : 0;//input reuse
    assign wt_div_flg           = (in_channel_num_lp * KX_lp * KY_lp * out_channel_num_lp > (1 << 12)) ? 1 : 0;//input reuse//output reuse
    assign ifm_div_flg          = (in_channel_num_lp * IXt_lp * IYt_lp > (1 << 17)) ? 1 : 0;//output reuse
    assign ofm_div_wt_reuse_flg = (Nt_lp * OX_lp * OY_lp > (1 << 17)) ? 1 : 0;//weight reuse

    assign Nt_times             = out_channel_num_lp / Nt_lp;
    assign Mt_times             = (in_channel_num_lp % Mt_lp == 1'b0) ? in_channel_num_lp / Mt_lp : (in_channel_num_lp / Mt_lp+1'b1) ;
    assign Mt_last_num          = in_channel_num_lp-Mt_lp*(Mt_times-1'b1);
    assign IYt_times            = (OY_lp%OYt_lp==1'b0) ? OY_lp/OYt_lp : (OY_lp/OYt_lp+1'b1) ;
    assign IYt_last_num         = ((OY_lp-(IYt_times-1'b1)*OYt_lp)-1'b1)*CONV_stride_lp+KX_lp;
    assign OXt4                 = (OXt_lp[1:0] == 2'b0)? (OXt_lp>>2) : ((OXt_lp>>2)+1);
    assign OX4_align            = (OX_lp[1:0]  == 2'b0)? (OX_lp>>2) : ((OX_lp>>2)+1);
    assign POOL_OX4_align       = (POOL_OX_lp[1:0] == 2'b0)? (POOL_OX_lp>>2):((POOL_OX_lp>>2)+1'b1);
    assign send_FC_cnt          = (out_channel_num_lp%512 == 0)? out_channel_num_lp/512 : out_channel_num_lp/512 +1'b1 ;
    assign IYt_dif              = (OY_lp!=IYt_times*OYt_lp&&IYt_times!=1'b1)? 1'b1:1'b0;
    
    assign bn_para_num             = 2*out_channel_num_lp;
    assign bn_para_num4            = bn_para_num[1]==1'b0 ? bn_para_num4>>4 : (bn_para_num4>>4) + 1'b1;

//******************************************************************************
// read bn channel control logic and data signals 
//******************************************************************************
    
    
    
    
    assign ft_bn_burst_times = bn_para_num4[6:0]==7'b0 ? bn_para_num4 >> 7 : (bn_para_num4 >> 7) +1'b1;
    
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_bn_burst_done <= 1'b0;
        else if(mc_cs[FT_PARA]&&mc_ns[FT_BN])
            ft_bn_burst_done <= 1'b0;
        else if (mc_cs[FT_BN])
            ft_bn_burst_done <= ui_rddata_cmptd;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_bn_burst_cnt <= 9'b0;
        else if(!mc_cs[FT_BN])
            ft_bn_burst_cnt <= 9'b0;
        else if(mc_cs[FT_BN]&&ui_rddata_cmptd&&ft_bn_rrdy)
            ft_bn_burst_cnt <= ft_bn_burst_cnt + 1'b1;
    
    // control logic     
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_bn_rrdy <= 1'b0;
        else if(mc_cs[FT_PARA]&&mc_ns[FT_BN])
            ft_bn_rrdy <= 1'b1;
        else if(mc_cs[FT_BN]&&ft_bn_done)
            ft_bn_rrdy <= 1'b0;          
                                         
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)                      
            ft_bn_cmd <= 3'b0;          
        else if(mc_cs[FT_PARA]&&mc_ns[FT_BN])
            ft_bn_cmd <= 3'b0;  
                               
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)            
            ft_bn_rblen <=8'b0;
        else if ((mc_cs[FT_BN]|(mc_cs[FT_PARA]&&mc_ns[FT_BN]))&&
            (ft_bn_burst_cnt < (ft_bn_burst_times - 1'b1)))
            ft_bn_rblen <=8'd127;
        else if ((mc_cs[FT_BN]|(mc_cs[FT_PARA]&&mc_ns[FT_BN]))&&
            (ft_bn_burst_cnt == (ft_bn_burst_times - 1'b1)))
            ft_bn_rblen <=  bn_para_num4 - (ft_bn_burst_times-1'b1)*128 - 1'b1;
                             
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)            
            ft_bn_raddr <= `DDR_AW'b0;
        else if(mc_cs[FT_BN]|(mc_cs[FT_PARA]&&mc_ns[FT_BN]))
            ft_bn_raddr <= cur_lyr_bn_saddr + 128*ft_bn_burst_cnt;
    
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_bn_cmd_en <= 1'b0;
        else if((mc_cs[FT_PARA]&&mc_ns[FT_BN])|(mc_cs[FT_BN]&&ft_bn_burst_done))
            ft_bn_cmd_en <= 1'b1;
        else if(mc_cs[FT_BN]&&ui_cmd_ack)
            ft_bn_cmd_en <= 1'b0;
    
    // data signal 
    assign ft_bn_rdata = ft_bn_rvld ? ui_rddata : `DDR_DW'b0;
    assign ft_bn_rvld  = ui_rddata_vld && mc_cs[FT_BN];


    // to mcu
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_bn_done <= 1'b0;
        else if(mc_cs[FT_PARA]&&mc_ns[FT_BN])
            ft_bn_done <= 1'b0;
        else if(mc_cs[FT_BN]&&(ft_bn_burst_cnt==ft_bn_burst_times))
            ft_bn_done <= 1'b1;


//******************************************************************************
// read input feature map control logic and data signals                          
//******************************************************************************
   
    //completing a calculation need IYt*IX*Mt input feature map neurons ,refered to as a block
    //a block = Mt * slice or (in_channel_num - Mt*(Mt_times-1))*slice 
    //a slice = IYt*IX   

    //-------------------------------------------------------
    // read input feature map FSM control signals 
    //-------------------------------------------------------

    assign ft_ifm_en = mc_cs[DF_SLT]&&or_cs[OR_FT_IFM];
    
    always @(posedge clk_trans or negedge rst_n)
        if (!rst_n)
            ft_ifm_slice_cnt <= 8'b0;
        else if (ft_ifm_cs[IFM_IDLE]&&(ft_ifm_ns[IFM_PD_U]|ft_ifm_ns[IFM_LD]))
            ft_ifm_slice_cnt <= 8'b0;
        else if (ft_ifm_ns[IFM_SLC_DONE]&&(ft_ifm_cs[IFM_LD]|ft_ifm_cs[IFM_PD_B]|ft_ifm_cs[IFM_PD_D]))
            ft_ifm_slice_cnt <= ft_ifm_slice_cnt_nxt;
    assign ft_ifm_slice_cnt_nxt = ft_ifm_slice_cnt == Mt_lp ? 8'b0 : ft_ifm_slice_cnt+1'b1;

    //-------------------------------------------------------
    // read input feature map  FSM  
    //------------------------------------------------------
    always @(posedge clk_trans or negedge rst_n)
        if (!rst_n)
            ft_ifm_cs <= 6'b1;
        else
            ft_ifm_cs <= ft_ifm_ns;

    always @(*) begin
        ft_ifm_ns = 6'b0;
        case (1'b1)
            ft_ifm_cs[IFM_IDLE]      : begin
                if(!ft_ifm_en)
                    ft_ifm_ns[IFM_IDLE]     = 1'b1;
                else if(CONV_pad_size_lp==4'b0)
                    ft_ifm_ns[IFM_LD]       = 1'b1;
                else if(ft_IYt_cnt==11'b0)
                    ft_ifm_ns[IFM_PD_U]     = 1'b1;
                else 
                    ft_ifm_ns[IFM_LD]       = 1'b1;
            end 
            ft_ifm_cs[IFM_PD_U]      : begin 
                if (!ifm_pd_done)
                    ft_ifm_ns[IFM_PD_U]     = 1'b1;
                else 
                    ft_ifm_ns[IFM_LD]       = 1'b1;
                end
            ft_ifm_cs[IFM_PD_B]      : begin  
                if(!ifm_pd_done)
                    ft_ifm_ns[IFM_PD_B]     = 1'b1;
                else
                    ft_ifm_ns[IFM_SLC_DONE] = 1'b1;        
            end 
            ft_ifm_cs[IFM_PD_D]      : begin      
                if(!ifm_pd_done)
                    ft_ifm_ns[IFM_PD_D]     =1'b1;
                else 
                    ft_ifm_ns[IFM_SLC_DONE] = 1'b1;
            end
            ft_ifm_cs[IFM_LD]        : begin
                if (!ft_ifm_slice_done)
                    ft_ifm_ns[IFM_LD]       = 1'b1;
                else if ((ft_IYt_cnt==IYt_times-1'b1)&&
                    (CONV_pad_size_lp!=0||(CONV_pad_size_lp==0&&IYt_last_num!=IYt_lp)))
                    ft_ifm_ns[IFM_PD_D]     = 1'b1;
                else 
                    ft_ifm_ns[IFM_SLC_DONE] = 1'b1;
            end
            ft_ifm_cs[IFM_SLC_DONE]  : begin
                if (ft_ifm_slice_cnt==Mt_lp)
                    ft_ifm_ns[IFM_IDLE]     = 1'b1;
                else if (ft_IYt_cnt==11'b0)
                    ft_ifm_ns[IFM_PD_U]     = 1'b1;
                else if (ft_Mt_cnt==Mt_times-1'b1&&ft_ifm_slice_cnt==Mt_last_num)
                    ft_ifm_ns[IFM_PD_B]     = 1'b1;
                else 
                    ft_ifm_ns[IFM_LD]       = 1'b1;
            end
        endcase         
    end 
    
    //-------------------------------------------
    // Padding  control logic
    //------------------------------------------
    assign ifm_pd_symmetry      = (CONV_pad_size_lp[0] == 0)?1'b1:1'b0;
    assign ifm_pd_u_rows_num    = (CONV_pad_size_lp==0) ? 4'b0 : 
                                    (CONV_pad_size_lp[0]==0)?
                                    (CONV_pad_size_lp>>1):((CONV_pad_size_lp>>1)+1'b1);
    assign ifm_pd_d_rows_num    = (CONV_pad_size_lp==0) ? 4'b0 : 
                                    ifm_pd_symmetry?ifm_pd_d_rows_num:ifm_pd_d_rows_num-1'b1;    
    
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ifm_pd_neurons_cnt <= 16'b0;
        else if (ft_ifm_ns[IFM_PD_U]&&(ft_ifm_cs[IFM_IDLE]|ft_ifm_cs[IFM_SLC_DONE])||
                (ft_ifm_ns[IFM_PD_B]&&ft_ifm_cs[IFM_SLC_DONE])||
                (ft_ifm_ns[IFM_PD_D]&&ft_ifm_cs[IFM_SLC_DONE]))
            ifm_pd_neurons_cnt <= 16'b0;
        else if (ft_ifm_cs[IFM_PD_B]|ft_ifm_cs[IFM_PD_D]|ft_ifm_cs[IFM_PD_U])
            ifm_pd_neurons_cnt <= ifm_pd_neurons_cnt_nxt;
    
    assign ifm_pd_neurons_cnt_nxt = ifm_pd_neurons_cnt==ifm_pd_neurons_num ? 
                                    16'b0 : ifm_pd_neurons_cnt+1'b1;
    
    always @(*) begin
        ifm_pd_neurons_num = 16'b0;
        case (1'b1)
            ft_ifm_cs[IFM_PD_D] : ifm_pd_neurons_num = (IYt_lp-IYt_last_num+ifm_pd_d_rows_num)*IX4_lp;
            ft_ifm_cs[IFM_PD_B] : ifm_pd_neurons_num = IYt_lp*IX4_lp;
            ft_ifm_cs[IFM_PD_U] : ifm_pd_neurons_num = ifm_pd_u_rows_num*IX4_lp;
        endcase
    end

    always @(*)
        if(~|ft_ifm_cs[4:2])
            ifm_pd_done <= 1'b0;
        else if(ifm_pd_neurons_cnt==ifm_pd_neurons_num-1'b1)
            ifm_pd_done <= 1'b1;
        else 
            ifm_pd_done <= 1'b0;

    //--------------------------------------------------------------
    // fetch a slice of input feature map control logic 
    //--------------------------------------------------------------

    // control logic signals
    assign ft_ifm_burst_num = ft_ifm_slice_len[6:0]==7'b0 ? 
                                (ft_ifm_slice_len>>7) : (ft_ifm_slice_len>>7+1'b1);
    assign ft_ifm_burst_len = ft_ifm_burst_cnt==ft_ifm_burst_num-1'b1 ?
                                ft_ifm_slice_len-ft_ifm_burst_cnt*8'd128 : 8'd128;
    always @(posedge clk_trans or negedge rst_n)
        if (!rst_n)
            ft_ifm_burst_cnt <= 8'b0;
        else if (ft_ifm_ns[IFM_LD]&&(ft_ifm_cs[IFM_IDLE]|ft_ifm_cs[IFM_PD_U]|ft_ifm_cs[IFM_SLC_DONE]))
            ft_ifm_burst_cnt <= 8'b0;
        else if (ft_ifm_cs[IFM_LD]&&ui_rddata_cmptd)
            ft_ifm_burst_cnt <= ft_ifm_burst_cnt_nxt;
    assign ft_ifm_burst_cnt_nxt = ft_ifm_burst_cnt==ft_ifm_burst_num ? 8'b0 : ft_ifm_burst_cnt+1'b1; 

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_ifm_burst_done <= 1'b0;
        else if (ft_ifm_ns[IFM_LD]&&(ft_ifm_cs[IFM_IDLE]|ft_ifm_cs[IFM_PD_U]|ft_ifm_cs[IFM_SLC_DONE]))
            ft_ifm_burst_done <= 1'b0;
        else if (ft_ifm_cs[IFM_LD])
            ft_ifm_burst_done <= ui_rddata_cmptd;

    assign ft_ifm_slice_done = ft_ifm_burst_cnt==ft_ifm_burst_num ? 1'b1 : 1'b0; 

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_ifm_slice_start <= 1'b0;
        else if (ft_ifm_ns[IFM_LD]&&(ft_ifm_cs[IFM_PD_U]|ft_ifm_cs[IFM_SLC_DONE]|ft_ifm_cs[IFM_IDLE]))
            ft_ifm_slice_start <= 1'b1;
        else if (ft_ifm_slice_start)
            ft_ifm_slice_start <= 1'b0;
    
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_ifm_slice_len <= 16'b0;
        else if (ft_ifm_cs[IFM_IDLE]&&(ft_ifm_ns[IFM_PD_U]|ft_ifm_ns[IFM_LD]))
            ft_ifm_slice_len <= ft_ifm_slice_len_nxt;

    always @(*)
        if (IYt_times==11'b1)
            ft_ifm_slice_len_nxt = IX4_lp*(IYt_last_num-ifm_pd_d_rows_num-ifm_pd_u_rows_num);
        else if (ft_IYt_cnt==1'b0) 
            ft_ifm_slice_len_nxt = IX4_lp*(IYt_lp-ifm_pd_u_rows_num); 
        else if (ft_IYt_cnt==IYt_times-1'b1)
            ft_ifm_slice_len_nxt = IX4_lp*(IYt_last_num-ifm_pd_d_rows_num);
        else 
            ft_ifm_slice_len_nxt = IX4_lp*IYt_lp;
    
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_ifm_slice_saddr = nn_rd_ifm_saddr;
        else if (ft_ifm_ns[IFM_LD]&&(ft_ifm_cs[IFM_PD_U]|ft_ifm_cs[IFM_IDLE]|ft_ifm_cs[IFM_SLC_DONE]))
            ft_ifm_slice_saddr = ft_ifm_slice_saddr_nxt;
    always @(*)
        if(ft_IYt_cnt==11'b0)
            ft_ifm_slice_saddr_nxt = nn_rd_ifm_saddr+(ft_Mt_cnt+ft_ifm_slice_cnt)*IX4_lp*IY_lp;
        else 
            ft_ifm_slice_saddr_nxt =  nn_rd_ifm_saddr+(ft_Mt_cnt*Mt_lp+ft_ifm_slice_cnt)*IX4_lp*IY_lp*8+
            ((IYt_lp-KX_lp+CONV_stride_lp)*ft_IYt_cnt-ifm_pd_u_rows_num)*IX4_lp*8;
       
    
    //UI control logic  
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_ifm_rrdy <= 1'b0;
        else 
            ft_ifm_rrdy <= ft_ifm_cs[IFM_LD] ? 1'b1 : 1'b0;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_ifm_cmd <= 3'b0;
        else if(ft_ifm_cs[IFM_LD])
            ft_ifm_cmd <= 3'b0;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_ifm_rblen <= 8'b0;
        else if(ft_ifm_ns[IFM_LD])
            ft_ifm_rblen <= ft_ifm_burst_len;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_ifm_raddr <= `DDR_AW'b0;
        else if(ft_ifm_ns[IFM_LD])
             ft_ifm_raddr <= ft_ifm_slice_saddr+ft_ifm_burst_cnt*8'd128;
    
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_ifm_cmd_en <= 1'b0;
        else if (ft_ifm_slice_start||(ft_ifm_cs[IFM_LD]&&ft_ifm_burst_done))
            ft_ifm_cmd_en <= 1'b1;
        else if (ft_ifm_cs[IFM_LD]&&ui_cmd_ack)
            ft_ifm_cmd_en <= 1'b0;
            

    //data signals
    assign ft_ifm_rdata = |ft_ifm_cs[4:2] ? `DDR_DW'b0 : ui_rddata;
    assign ft_ifm_rvld  = |ft_ifm_cs[4:2] || (ui_rddata_vld&&ft_ifm_cs[IFM_LD]); 

    //to mcu
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_ifm_done <= 1'b0;
        else if(!or_cs[OR_FT_IFM])
            ft_ifm_done <= 1'b0;
        else if(ft_ifm_slice_cnt==Mt_lp)
            ft_ifm_done <= 1'b1;

//******************************************************************************
// read weight control logic and data signals 
//******************************************************************************
    

    always @(posedge clk_trans or negedge rst_n)                      
        if(!rst_n)
            ft_wt_start <= 1'b0;
        else if (or_ns[OR_FT_WT]&&or_cs[OR_FT_IFM])
            ft_wt_start <= 1'b1;
        else if (ft_wt_start)
            ft_wt_start <= 1'b0;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_wt_kkm8_cnt <= 6'b0;
        else if (or_cs[OR_FT_IFM]&&or_ns[OR_FT_WT])
            ft_wt_kkm8_cnt <= 6'b0;
        else if (ft_wt_burst_cnt==ft_wt_burst_num-1'b1&&ui_rddata_cmptd)
            ft_wt_kkm8_cnt <= ft_wt_kkm8_cnt_nxt;
    assign ft_wt_kkm8_cnt_nxt = ft_wt_kkm8_cnt==Nt_lp-1'b1 ? 6'b0 : ft_wt_kkm8_cnt+1'b1;
    
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_wt_kkm8_done <= 1'b0;
        else if(or_cs[OR_FT_WT])
            ft_wt_kkm8_done <= ft_wt_burst_cnt==ft_wt_burst_num-1'b1&&ui_rddata_cmptd?1'b1:1'b0;
    
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
           ft_wt_kkm8_done_r0 <= 1'b0;
        else 
           ft_wt_kkm8_done_r0 <= ft_wt_kkm8_done; 
    
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_wt_kkm8_saddr <= nn_wt_saddr+KKM8_lp*Mt_times*Nt_lp*ft_Nt_cnt*8+ft_Mt_cnt*KKM8_lp*8;
        else if(ft_wt_kkm8_done)
            ft_wt_kkm8_saddr <= nn_wt_saddr+KKM8_lp*Mt_times*8*(Nt_lp*ft_Nt_cnt+ft_wt_kkm8_cnt)+
                                ft_Mt_cnt*KKM8_lp*8;

    assign ft_wt_kkm8_len = KKM8_lp;
   
    assign ft_wt_burst_num = ft_wt_kkm8_len[6:0]==7'b0 ? 
                                ft_wt_kkm8_len>>7 : ft_wt_kkm8_len>>7+1'b1;
    
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_wt_burst_cnt <= 8'b0;
        else if(ui_rddata_cmptd&&or_cs[OR_FT_WT])
            ft_wt_burst_cnt <= ft_wt_burst_cnt_nxt;
    assign ft_wt_burst_cnt_nxt = ft_wt_burst_cnt==ft_wt_burst_num-1'b1 ?
                                8'b0 : ft_wt_burst_cnt+1'b1;
   
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_wt_burst_done <= 1'b0;
        else if(or_cs[OR_FT_WT])
            ft_wt_burst_done <= ui_rddata_cmptd;

    assign ft_wt_burst_len = ft_wt_burst_cnt==ft_wt_burst_num-1'b1 ?
                                8'd128 : ft_wt_kkm8_len-ft_wt_burst_cnt*8'd128;
    
    // fetch weight ui control signals
    
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_wt_rrdy <= 1'b0;
        else 
            ft_wt_rrdy <= or_cs[OR_FT_WT] ? 1'b1 : 1'b0;

    always @(posedge clk_trans or negedge rst_n)
        if (!rst_n)
            ft_wt_cmd <= 3'b0;
        else if (or_cs[OR_FT_WT])
            ft_wt_cmd <= 3'b0;
    
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_wt_rblen <= 8'b0;
        else if (or_cs[OR_FT_WT])
            ft_wt_rblen <= ft_wt_burst_len;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_wt_raddr <= `DDR_AW'b0;
        else if (or_cs[OR_FT_WT])
            ft_wt_raddr <= ft_wt_kkm8_saddr+8'd128*ft_wt_burst_cnt;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_wt_cmd_en <= 1'b0;
        else if(!or_cs[OR_FT_WT])
            ft_wt_cmd_en <= 1'b0;
        else if(ft_wt_start||(ft_wt_burst_done&&!ft_wt_kkm8_done)||
               (ft_wt_kkm8_done_r0&&ft_wt_kkm8_cnt!=6'b0))
            ft_wt_cmd_en <= 1'b1;
        else if(or_cs[OR_FT_WT]&&ui_cmd_ack)
            ft_wt_cmd_en <= 1'b0;
   
    // fetch weight data signals

    assign ft_wt_rdata = ui_rddata;
    assign ft_wt_rvld  = or_cs[OR_FT_WT]&&ui_rddata_vld;

    // to mcu

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_wt_done <= 1'b0;
        else if (or_cs[OR_FT_IFM]&&or_cs[OR_FT_WT])
            ft_wt_done <= 1'b0;
        else if (ft_wt_kkm8_cnt == Nt_lp-1'b1&&
                    ft_wt_burst_cnt==ft_wt_burst_num-1'b1&&ui_rddata_cmptd)  
            ft_wt_done <= 1'b1;
   
  
//******************************************************************************
// Transmit output feature map control logic and data signals  
//******************************************************************************

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            tx_ofm_start <= 1'b0;
        else if(or_cs[OR_CAL]&&or_cs[OR_TX_OFM])
            tx_ofm_start <= 1'b0;
        else if(or_cs[OR_TX_OFM]&&pe_tx_ofm_start_sync)
            tx_ofm_start <= 1'b1;
        else if(tx_ofm_start)
            tx_ofm_start <= 1'b0;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            tx_ofm_slice_cnt <= 8'b0;
        else if(or_cs[OR_CAL]&&or_ns[OR_TX_OFM])
            tx_ofm_slice_cnt <= 8'b0;
        else if((tx_ofm_burst_cnt==tx_ofm_burst_num-1'b1)&&tx_ofm_wcmptd&&ui_wrdata_rdy)
            tx_ofm_slice_cnt <= tx_ofm_slice_cnt_nxt;
    assign tx_ofm_slice_cnt_nxt = tx_ofm_slice_cnt==Nt_lp-1'b1 ? 
                                    8'b0 : tx_ofm_slice_cnt+1'b1;
    
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            tx_ofm_slice_done <= 1'b0;
        else if(tx_ofm_burst_cnt==tx_ofm_burst_num-1'b1&&ui_wrdata_rdy&&tx_ofm_wcmptd)
            tx_ofm_slice_done <= 1'b1;
        else 
            tx_ofm_slice_done <= 1'b0;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            tx_ofm_slice_done_r0 <= 1'b0;
        else 
            tx_ofm_slice_done_r0 <= tx_ofm_slice_done;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            tx_ofm_slice_saddr <= `DDR_AW'b0;
        else if(tx_ofm_burst_cnt==tx_ofm_burst_num-1'b1&&ui_wrdata_rdy&&tx_ofm_wcmptd) 
            tx_ofm_slice_saddr <= tx_ofm_slice_saddr_nxt;
    assign tx_ofm_slice_saddr_nxt = nn_wr_ofm_saddr+(tx_Nt_cnt*Nt_lp+tx_ofm_slice_cnt)*
                                    ((AVG_lp||MAX_lp)?POOL_OY_lp*POOL_OX4_align:OY_lp*OX4_align)*8+
                                    tx_OYt_cnt*tx_ofm_slice_len*8;
                                

    assign tx_ofm_slice_len = (MAX_lp||AVG_lp) ? pe_tx_ofm_rows_num*POOL_OX4_align :
                                OX4_align*pe_tx_ofm_rows_num;


    assign tx_ofm_burst_num = tx_ofm_slice_len[6:0]==7'b0 ? 
                                tx_ofm_slice_len>>7 : tx_ofm_slice_len>>7+1'b1;
    
    assign tx_ofm_burst_len = tx_ofm_burst_cnt==tx_ofm_burst_num-1'b1 ?
                                tx_ofm_burst_cnt*8'd128 : 8'd128;
    
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            tx_ofm_burst_cnt <= 9'b0;
        else if(or_cs[OR_CAL]&&or_ns[OR_TX_OFM])
            tx_ofm_burst_cnt <= 9'b0;
        else if(or_cs[OR_TX_OFM]&&tx_ofm_wcmptd)
            tx_ofm_burst_cnt <=tx_ofm_burst_cnt_nxt;
    assign tx_ofm_burst_cnt_nxt = tx_ofm_burst_cnt==tx_ofm_burst_num-1'b1 ? 
                                    9'b0 : tx_ofm_burst_cnt+1'b1;
    
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            tx_ofm_burst_done <= 1'b0;
        else if (or_cs[OR_CAL]&&or_ns[OR_TX_OFM])
            tx_ofm_burst_done <= 1'b0;
        else if (or_cs[OR_TX_OFM])
            tx_ofm_burst_done <= ui_wrdata_cmptd;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            tx_ofm_sent_cnt <= 8'b0;
        else if(ui_wrdata_rdy&&ui_wrdata_cmptd&&or_cs[OR_TX_OFM])
            tx_ofm_sent_cnt <= tx_ofm_slice_cnt_nxt;
    assign tx_ofm_sent_cnt_nxt = tx_ofm_sent_cnt==tx_ofm_burst_len-1'b1 ? 8'b0 : tx_ofm_sent_cnt+1'b1;

    //ui control signals
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            tx_ofm_cmd <= 3'b0;
        else if (or_cs[OR_TX_OFM])
            tx_ofm_cmd <= 3'b100;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            tx_ofm_wblen <= 8'b0;
        else if(or_cs[OR_TX_OFM])
            tx_ofm_wblen <= tx_ofm_slice_len;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            tx_ofm_waddr <= `DDR_AW'b0;
        else if(or_cs[OR_TX_OFM])
            tx_ofm_waddr <= tx_ofm_slice_saddr+8'd128*tx_ofm_slice_cnt;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            tx_ofm_wcmptd <= 1'b0;
        else if(tx_ofm_sent_cnt==tx_ofm_burst_len-2'd2)
            tx_ofm_wcmptd <= 1'b1;
        else if(pe_tx_ofm_wrdy&&pe_tx_ofm_wvld&&tx_ofm_sent_cnt==tx_ofm_burst_len-1'b1)
            tx_ofm_wcmptd <= 1'b0;
        
   always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
           tx_ofm_wbvld <= 8'b0;
        else if(or_cs[OR_TX_OFM])
           tx_ofm_wbvld <= 8'hff;
        else 
           tx_ofm_wbvld <= 8'b0;


    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            tx_ofm_cmd_en <= 1'b0;
        else if(tx_ofm_start||(tx_ofm_burst_done&&!tx_ofm_slice_done)||
                (tx_ofm_slice_done_r0&&tx_ofm_sent_cnt!=8'b0))
            tx_ofm_cmd_en <= 1'b1;
        else if(ui_cmd_ack&&or_cs[OR_TX_OFM])
            tx_ofm_cmd_en <= 1'b0;

    // ui data signals
    
    assign pe_tx_ofm_wrdy = or_cs[OR_TX_OFM]&&ui_wrdata_rdy;
    assign ui_wrdata      = pe_tx_ofm_wdata;
    assign tx_ofm_wvld  = pe_tx_ofm_wvld;

   // to mcu
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            tx_ofm_done <= 1'b0;
        else if(or_cs[OR_CAL]&&or_ns[OR_TX_OFM])
            tx_ofm_done <= 1'b0;
        else if(tx_ofm_slice_cnt==Nt_lp-1'b1&&tx_ofm_burst_cnt==tx_ofm_burst_num-1'b1&&
                    tx_ofm_wcmptd)
            tx_ofm_done <= 1'b1;
    
endmodule
