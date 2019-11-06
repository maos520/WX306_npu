// *****************************************************************************
// @Project Name : SEU_NPU 
// @Author       : Maos520
// @Email        : sujingjingabc@sina.com
// @File Name    : SEU_npu_sync.v
// @Module Name  : SEU_npu_sync
// @Created Time : 2019-10-23 16:58
//
// @Abstract     : This module is used to synchronize signals cross clock domain 
//
// Modification History
// ******************************************************************************
// Date           BY           Version         Change Description
// -------------------------------------------------------------------------
// 2019-10-23   maos520         v1.0a            initial version 
// 
// ******************************************************************************
`timescale 1ns/1ps


module SEU_npu_sync(

    input  clk_cal,
    input  clk_trans,
    input  rst_n,
    
    // clk_trans clock domain 
    input  pe_cal_start,
    input  pe_ifm_rst,
    input  pe_wt_rst,
    input  pe_first_bn,
    input  pe_last_bn,
    input  pe_tx_ofm_done,
    input  pe_ft_lyr_para_done,
    
    output pe_cal_done_sync,
    output pe_tx_ofm_start_sync,

    //clk_cal clock domain
    input  pe_cal_done,
    input  pe_tx_ofm_start,

    output pe_cal_start_sync,
    output pe_ifm_rst_sync,
    output pe_wt_rst_sync,
    output pe_first_bn_sync,
    output pe_tx_ofm_done_sync,
    output pe_ft_lyr_para_done_sync

);


    reg [2:0] pe_cal_start_r;
    reg [2:0] pe_ifm_rst_r;
    reg [2:0] pe_wt_rst_r;
    reg [1:0] pe_first_bn_r;
    reg [2:0] pe_last_bn_r;
    reg [2:0] pe_tx_ofm_done_r;
    reg [2:0] pe_ft_lyr_para_done_r;
    reg [2:0] pe_cal_done_r;
    reg [2:0] pe_tx_ofm_start_r;



//******************************************************************************
//  clk_trans  ------->  clk_cal 
//******************************************************************************

    always @(posedge clk_cal or negedge rst_n)
        if(!rst_n) begin 
            pe_cal_start_r        <= 3'b0;
            pe_ifm_rst_r          <= 3'b0;
            pe_wt_rst_r           <= 3'b0;
            pe_first_bn_r         <= 2'b0;
            pe_last_bn_r          <= 3'b0;
            pe_tx_ofm_done_r      <= 3'b0;
            pe_ft_lyr_para_done_r <= 3'b0;
        end 
        else begin
            pe_cal_start_r        <= {pe_cal_start_r[1:0]        , pe_cal_start_r[2]        };
            pe_ifm_rst_r          <= {pe_ifm_rst_r[1:0]          , pe_ifm_rst_r[2]          };
            pe_wt_rst_r           <= {pe_wt_rst_r[1:0]           , pe_wt_rst_r[2]           };
            pe_first_bn_r         <= {pe_first_bn_r[0]           , pe_first_bn_r[1]         };
            pe_last_bn_r          <= {pe_last_bn_r[1:0]          , pe_last_bn_r[2]          };
            pe_tx_ofm_done_r      <= {pe_tx_ofm_done_r[1:0]      , pe_tx_ofm_done_r[2]      };
            pe_ft_lyr_para_done_r <= {pe_ft_lyr_para_done_r[1:0] , pe_ft_lyr_para_done_r[2] };
        end
     
    assign pe_cal_start_sync        = pe_cal_start_r[1]        && ~pe_cal_start_r[2];           
    assign pe_ifm_rst_sync          = pe_ifm_rst_r[1]          && ~pe_cal_start_r[2];
    assign pe_wt_rst_sync           = pe_wt_rst_r[1]           && ~pe_wt_rst_r[2];
    assign pe_first_bn_sync         = pe_first_bn_r[1];
    assign pe_tx_ofm_done_sync      = pe_tx_ofm_done_r[1]      && ~pe_tx_ofm_done_r[2];
    assign pe_ft_lyr_para_done_sync = pe_ft_lyr_para_done_r[1] && ~pe_ft_lyr_para_done_r[2];


//******************************************************************************
//   clk_cal -------->  clk_trans 
//******************************************************************************
    
    always @(posedge clk_trans or negedge rst_n)
        if(!rst_n) begin 
            pe_cal_done_r     <= 3'b0;
            pe_tx_ofm_start_r <= 3'b0;
        end 
        else begin
            pe_cal_start_r    <= {pe_cal_start_r[1:0]    , pe_cal_start_r[2]    };
            pe_tx_ofm_start_r <= {pe_tx_ofm_start_r[1:0] , pe_tx_ofm_start_r[2] };
        end
    
    assign pe_cal_done_sync     = pe_cal_done_r[1]     && ~pe_cal_done_r[2];
    assign pe_tx_ofm_start_sync = pe_tx_ofm_start_r[1] && ~pe_tx_ofm_start_r[2];

endmodule 
