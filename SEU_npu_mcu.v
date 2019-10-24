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


    //the base para of NN  
    input  [`DDR_AW-1:0]       nn_wt_saddr,        
    input  [`DDR_AW-1:0]       nn_map0_saddr,      
    input  [`DDR_AW-1:0]       nn_map1_saddr,      
    input  [`DDR_AW-1:0]       nn_bn_saddr,        
    input  [`DDR_AW-1:0]       nn_layer_para_saddr,
    input  [`DDR_AW-1:0]       nn_first_map_saddr, 
    input  [7:0]               nn_layers_num      

    

);


localparam 








endmodule 
