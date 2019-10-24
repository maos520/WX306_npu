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

    input clk_cal;
    input clk_trans;
    input rst_n;
    
    // clk_trans clock domain 
    input  npu_en_processing;
    input  npu_init_cmplt;
    output npu_busy_sync;    



    //clk_cal clock domain
    output npu_en_processing_sync;
    output npu_init_cmplt_sync;
    input  npu_busy;

);




    reg npu_en_processing_sync0;
    reg npu_en_processing_sync1;
    reg npu_en_processing_sync2;

    reg npu_init_cmplt_sync0;
    reg npu_init_cmplt_sync1;
    reg npu_init_cmplt_sync2;

    reg npu_busy_sync0;
    reg npu_busy_sync1;


    

































endmodule 
