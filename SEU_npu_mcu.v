// *****************************************************************************
// @Project Name : SEU_NPU 
// @Author       : Maos520
// @Email        : sujingjingabc@sina.com
// @File Name    : SEU_npu_mcu.v
// @Module Name  :
// @Created Time : 2019-10-23 21:20
//
// @Abstract     : This module is master contrl unit of npu ,achieving various 
//               ways of data reuse by controlling data transmission and computing.
//               
//
// Modification History
// ******************************************************************************
// Date           BY           Version         Change Description
// -------------------------------------------------------------------------
// 2019-10-23   maos520          v1.0a           initial version 
// 
// ******************************************************************************

`timescale 1ns/1ps

module SEU_npu_mcu(
    input                      clk_trans,
    input                      rst_n,

    // from CCR 
    input                      npu_en_processing,
    input                      npu_init_cmplt,
    input                      nn_img_new, 

    input  [`DDR_AW-1:0]       nn_map0_saddr,      
    input  [`DDR_AW-1:0]       nn_map1_saddr,      
    input  [`DDR_AW-1:0]       nn_img_saddr,
    input  [7:0]               nn_layers_num,     

    //to CCR                                     
    output reg                 npu_busy,
    output                     img_expired_flg,

    //layer para
    input                      CONV_lp,
    input                      BN_lp,
    input  [2:0]               reuse_pattern_lp,

    input  [7:0]               Nt_times,            
    input  [11:0]              Mt_times,            
    input  [10:0]              IYt_times,

    //from   MemCtrl 
    input                      ft_lyr_para_done, 
    input                      ft_bn_done,
    input                      ft_wt_done,
    input                      ft_ifm_done,
    input                      tx_ofm_done,
    
    //to MemCtrl 
    output reg [6:0]           mc_cs, //current state 
    output reg [6:0]           mc_ns, //next state 
    output reg [5:0]           or_cs,
    output reg [5:0]           or_ns,
    output reg [7:0]           tx_Nt_cnt,
    output reg [11:0]          tx_OYt_cnt,
    output reg [11:0]          ft_Mt_cnt,
    output reg [7:0]           ft_Nt_cnt,
    output reg [10:0]          ft_IYt_cnt,

    
    output reg [`DDR_AW-1:0]   nn_rd_ifm_saddr,
    output reg [`DDR_AW-1:0]   nn_wr_ofm_saddr,
    output reg [7:0]           nn_layers_cnt,

    //from   calculating unit                  
    input                      pe_cal_done_sync,
    input                      pe_tx_ofm_start_sync,
    //to    calculating unit
    output reg                 pe_cal_start,   
    output reg                 pe_ifm_rst,
    output reg                 pe_wt_rst,
    output reg                 pe_first_bn,
    output reg                 pe_last_bn,
    output reg                 pe_tx_ofm_done,
    output reg                 pe_ft_lyr_para_done

);

//********************************************************************
//Master control state declarations 
//********************************************************************
    localparam [6:0] IDLE     = 7'd0; // idle state
    localparam [6:0] IMG_UD   = 7'd1; // wait until the image is updated
    localparam [6:0] FT_PARA  = 7'd2; // read each layer specific parameter
    localparam [6:0] FT_BN    = 7'd3; // read each layer BN parameter
    localparam [6:0] DF_SLT   = 7'd4; // select dataflow mode according to para
    localparam [6:0] LY_DONE  = 7'd5; // end of layer calculation
    localparam [6:0] INF_DONE = 7'd6; // end of a inferrence

//******************************************************************************
// OR dataflow control state declarations 
//*******************************  ***********************************************
    localparam [5:0] OR_IDLE   = 6'd0;
    localparam [5:0] OR_FT_IFM = 6'd1;
    localparam [5:0] OR_FT_WT  = 6'd2;
    localparam [5:0] OR_CAL    = 6'd3;
    localparam [5:0] OR_TX_OFM = 6'd4;
    localparam [5:0] OR_DONE   = 6'd5;

//******************************************************************************
// FC dataflow control state declarations 
//******************************************************************************
    // localparam [5:0] FC_IDLE   = 6'd0;
    // localparam [5:0] FC_FT_IFM = 6'd1;
    // localparam [5:0] FC_FT_WT  = 6'd2;
    // localparam [5:0] FC_TX_OFM = 6'd3;
    // localparam [5:0] FC_CAL    = 6'd4;
    // localparam [5:0] FC_DONE   = 6'd5;

        
    wire       layer_processing_done; // pulse 
    wire [7:0] nn_layers_cnt_nxt;

    wire [11:0] ft_Mt_cnt_nxt;
    wire [7:0]  ft_Nt_cnt_nxt;
    wire [10:0] ft_IYt_cnt_nxt;
    
    wire [7:0]  tx_Nt_cnt_nxt;
    wire [10:0] tx_OYt_cnt_nxt;


//*******************************************************************
// Master control state machine control signals        
//******************************************************************


    // count the number of layers that having been computed 
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n) 
            nn_layers_cnt <= 8'b0;
        else
            if(mc_cs[INF_DONE] | mc_cs[IDLE] | mc_cs[IMG_UD])
                nn_layers_cnt <= 8'b0;
            else if (layer_processing_done)
                nn_layers_cnt <= nn_layers_cnt_nxt;

    assign nn_layers_cnt_nxt = nn_layers_cnt < nn_layers_num ? nn_layers_cnt + 1'b1 : 1'b0;
    assign nn_processing_done = nn_layers_cnt == nn_layers_num ? 1'b1 : 1'b0; 
    
    assign layer_processing_done = or_cs[OR_TX_OFM]&&or_ns[OR_DONE];
    
    
    
    
//**********************************************************************
// Master control state machine 
//**********************************************************************

    always @(posedge clk_trans or negedge rst_n) 
        if(!rst_n)
            mc_cs <= 7'b1;
        else 
            mc_cs <= mc_ns;

    always @(*) begin
        mc_ns = 7'b0;
        case(1'b1)
            mc_cs[IDLE]     : begin
                if(npu_en_processing && npu_init_cmplt)
                    mc_ns[IMG_UD] = 1'b1;
                else
                    mc_ns[IDLE]   = 1'b1;
            end
            mc_cs[IMG_UD]   : begin
                if(nn_img_new)
                    mc_ns[FT_PARA] = 1'b1;
                else
                    mc_ns[IMG_UD]  = 1'b1;
            end
            mc_cs[FT_PARA]  : begin 
                if(!ft_lyr_para_done)
                   mc_ns[FT_PARA] = 1'b1;
                else 
                    if(BN_lp)
                        mc_ns[FT_BN] = 1'b1;
                    else
                        mc_ns[DF_SLT] = 1'b1;
            end
            mc_cs[FT_BN]    : begin
                if(ft_bn_done)
                    mc_ns[DF_SLT] = 1'b1;
                else
                    mc_ns[FT_BN] = 1'b1;
            end
            mc_cs[DF_SLT]   : begin
                if(layer_processing_done)
                    mc_ns[LY_DONE] =1'b1;
                else
                    mc_ns[DF_SLT] = 1'b1;
            end
            mc_cs[LY_DONE]  : begin
                if(nn_processing_done)
                    mc_ns[INF_DONE] = 1'b1;
                else
                    mc_ns[FT_PARA] = 1'b1;
            end
            mc_cs[INF_DONE] : begin
                if(npu_en_processing && npu_init_cmplt)
                    mc_ns[IMG_UD] = 1'b1;
                else
                    mc_ns[IDLE] =1'b1;
            end
        endcase
    
    end

     

//******************************************************************************
// Master control state machine output 
//******************************************************************************
    always @(posedge clk_trans or negedge rst_n) begin 
        if(!rst_n)
            npu_busy <= 1'b0;
        else if(|mc_ns[6:2])        
            npu_busy <= 1'b1;
        else
            npu_busy <= 1'b0;        
    end
    
    assign img_expired_flg = (nn_layers_cnt == 8'b1 && mc_cs[LY_DONE]) ? 1'b1 : 1'b0;

    always @(*)
        if(nn_layers_cnt == 8'b0) begin 
            nn_rd_ifm_saddr = nn_img_saddr;
            nn_wr_ofm_saddr = nn_map0_saddr;
        end    
        else if(nn_layers_cnt!=8'b0 && nn_layers_cnt[0]==1'b0) begin 
            nn_rd_ifm_saddr = nn_map1_saddr;
            nn_wr_ofm_saddr = nn_map0_saddr;
        end 
        else if(nn_layers_cnt!=8'b0 && nn_layers_cnt[0]==1'b1) begin 
            nn_rd_ifm_saddr = nn_map0_saddr;
            nn_wr_ofm_saddr = nn_map1_saddr;
        end 
        else begin 
            nn_rd_ifm_saddr = nn_img_new;
            nn_wr_ofm_saddr = nn_map0_saddr;    
        end
    
    // to calculating unit
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            pe_ft_lyr_para_done <= 1'b0;
        else if(mc_ns[FT_PARA]&&(mc_cs[IMG_UD]|mc_cs[LY_DONE]))
            pe_ft_lyr_para_done <= 1'b0;
        else if(mc_cs[FT_PARA]&&(mc_ns[FT_BN]|mc_ns[DF_SLT]))
            pe_ft_lyr_para_done <= 1'b1;

//******************************************************************************
//  dataflow  control signals 
//******************************************************************************
    

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            ft_Mt_cnt <= 12'b0;
        else if(or_ns[OR_FT_IFM]&&or_cs[OR_IDLE])
            ft_Mt_cnt <= 12'b0;
        else begin
            ft_Mt_cnt <= 12'b0;
            case(1'b1)
               !or_cs[OR_IDLE] : 
                    if(or_cs[OR_FT_WT]&&or_ns[OR_CAL])
                        ft_Mt_cnt <= ft_Mt_cnt_nxt;
            endcase
        end 
    assign ft_Mt_cnt_nxt = ft_Mt_cnt == Mt_times-1'b1 ? 12'b0 : ft_Mt_cnt+1'b1;

    always @(posedge clk_trans or negedge rst_n)
        if (!rst_n)
            ft_IYt_cnt <= 11'b0;
        else if (or_ns[OR_FT_IFM]&&or_ns[OR_IDLE])
            ft_IYt_cnt <= 11'b0;
        else begin
            ft_IYt_cnt <= 11'b0;
            case(1'b1)
                !or_cs[OR_IDLE] : 
                    if (ft_Mt_cnt==Mt_times-1'b1&&pe_cal_done_sync)
                        ft_IYt_cnt  <= ft_IYt_cnt_nxt;
            endcase
        end  
    assign or_IYt_cnt_nxt = or_IYt_cnt == IYt_times-1'b1 ? 12'b0 : or_IYt_cnt+1'b1;

    always @(posedge clk_trans or negedge rst_n)
        if (!rst_n)
            ft_Nt_cnt <= 8'b0;
        else if (or_ns[OR_FT_IFM]&&or_cs[OR_IDLE])
            ft_Nt_cnt <= 8'b0;
        else begin
            case(1'b1) 
                !or_cs[OR_IDLE] :
                    if (ft_Mt_cnt==Mt_times-1'b1&&ft_IYt_cnt==IYt_times-1'b1&&pe_cal_done_sync)
                        ft_Nt_cnt <= ft_Nt_cnt_nxt;
            endcase 
        end 
    assign ft_Nt_cnt_nxt = ft_Nt_cnt==Nt_times-1'b1 ? 8'b0 : ft_Nt_cnt+1'b1;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            tx_OYt_cnt <= 11'b0;
        else if(or_ns[OR_FT_IFM]&&or_cs[OR_IDLE])
            tx_OYt_cnt <= 11'b0;
        else 
            case(1'b1)
                !or_cs[OR_IDLE] : begin
                    if(tx_ofm_done)
                        tx_OYt_cnt <= tx_OYt_cnt_nxt;
                end 
                default : tx_OYt_cnt     <= 11'b0;
            endcase 
    assign tx_OYt_cnt_nxt = tx_OYt_cnt==IYt_times-1'b1 ? 11'b0 : tx_OYt_cnt+1'b1;
    
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            tx_Nt_cnt <= 8'b0;
        else if(or_ns[OR_FT_IFM]&&or_cs[OR_IDLE])
            tx_Nt_cnt <= 8'b0;
        else 
            case(1'b1)
                !or_cs[OR_IDLE] : begin
                    if(tx_ofm_done&&tx_OYt_cnt==IYt_times-1'b1)
                        tx_Nt_cnt <= tx_Nt_cnt_nxt;
                end
                default : tx_Nt_cnt <= 8'b0;
            endcase
    assign tx_Nt_cnt_nxt = tx_Nt_cnt==Nt_times-1'b1 ? 8'b0 : tx_Nt_cnt+1'b1;


//******************************************************************************
// OR dataflow state machine 
//******************************************************************************

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            or_cs <= 7'b1;
        else  
            or_cs <= or_ns;

    always @(*) begin
        or_ns = 6'b0;
        case (1'b1)
            or_cs[OR_IDLE]    : begin
                if(mc_cs[DF_SLT]&&(reuse_pattern_lp==3'b010)&&CONV_lp)
                    or_ns[OR_FT_IFM]  = 1'b1;
                else 
                    or_ns[OR_IDLE]    = 1'b1;
            end 
            or_cs[OR_FT_IFM]  : begin
                if(ft_ifm_done)
                    or_ns[OR_FT_WT]   = 1'b1;
                else
                    or_ns[OR_FT_IFM]  = 1'b1;
            end 
            or_cs[OR_FT_WT]   : begin
                if(ft_wt_done)
                    or_ns[OR_CAL]     = 1'b1;
                else
                    or_ns[OR_FT_WT]   = 1'b1;
            end 
            or_cs[OR_CAL]     : begin
                if(ft_Mt_cnt==Mt_times-1'b1&&pe_tx_ofm_start_sync)
                    or_ns[OR_TX_OFM]  = 1'b1;
                else if(pe_cal_done_sync&&(ft_Mt_cnt!=Mt_times-1'b1))
                    or_ns[OR_FT_IFM]  = 1'b1;
                else 
                    or_ns[OR_CAL]     = 1'b1;
            end 
            or_cs[OR_TX_OFM]  : begin
                if (!tx_ofm_done)
                    or_ns[OR_TX_OFM]  = 1'b1;
                else if ((tx_OYt_cnt==IYt_times-1'b1)&&
                        (tx_Nt_cnt==Nt_times-1'b1))
                    or_ns[OR_DONE]    = 1'b1;
                else 
                    or_ns[OR_FT_IFM]  = 1'b1;
            end 
            or_cs[OR_DONE]    : begin
                or_ns[IDLE]           = 1'b1;
            end 
        endcase 
    end  

//******************************************************************************
// dataflow FSM output signals  
//******************************************************************************
    
    //to calculating unit 
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            pe_cal_start <= 1'b0;
        else if((or_ns[OR_FT_IFM]|or_ns[OR_TX_OFM])&&or_cs[OR_CAL])
            pe_cal_start <= 1'b0;
        else if(or_cs[OR_FT_WT]&&or_ns[OR_CAL])
            pe_cal_start <= 1'b1;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            pe_ifm_rst <= 1'b0;
        else if(mc_cs[OR_FT_IFM]&&mc_ns[OR_FT_WT])
            pe_ifm_rst <= 1'b0;
        else if(mc_ns[OR_FT_IFM]&&(mc_cs[OR_CAL]|mc_cs[OR_TX_OFM]))
            pe_ifm_rst <= 1'b1;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            pe_wt_rst <= 1'b0;
        else if(mc_cs[OR_FT_WT]&&mc_ns[OR_CAL])
           pe_wt_rst <= 1'b0;
        else if(mc_cs[OR_FT_IFM]&&mc_ns[OR_FT_WT])
           pe_wt_rst <= 1'b1; 

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            pe_first_bn <= 1'b0;
        else 
            pe_first_bn <= ft_Mt_cnt==12'b0 ? 1'b1 : 1'b0;

    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            pe_last_bn  <= 1'b0;
        else if(ft_Mt_cnt!=12'b0)
            pe_last_bn  <= 1'b0;
        else if(ft_Mt_cnt==Mt_times-1'b1&&pe_cal_done_sync)
            pe_last_bn  <= 1'b1; 
    
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n)
            pe_tx_ofm_done <= 1'b0;
        else if(mc_cs[OR_CAL]&&mc_ns[OR_TX_OFM])
            pe_tx_ofm_done <= 1'b0;
        else if(mc_cs[OR_TX_OFM]&&(mc_ns[OR_FT_IFM]|mc_ns[OR_DONE]))
            pe_tx_ofm_done <= 1'b1;

endmodule




    
    
    
    
    
    
    
    
    
    
    
    
