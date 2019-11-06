// *****************************************************************************
// @Project Name : SEU_NPU
// @Author       : Maos520
// @Email        : sujingjingabc@sina.com
// @File Name    : SEU_npu_constants.v
// @Module Name  : NULL
// @Created Time : 2019-10-22 22:25
//
// @Abstract     : This file defines various constants used by every module.
//
// Modification History
// ******************************************************************************
// Date           BY           Version         Change Description
// -------------------------------------------------------------------------
// 2019-10-22   maos520         v1.0a            initial version 
// 
// ******************************************************************************


//-------------------------------------------------------------------------------
//------------------------CCR related-------------------------------------------
//------------------------------------------------------------------------------


`define CCR_S_ADDR 32'h0  //the starting address of CCR
`define CCR_AW     32
`define CCR_DW     64
`define CCR_OS_AW  16    // offset address width of CCR  

`define NPU_EN_WIDTH   1   // width of npu enable register 
`define NPU_CTRL_WIDTH 1 // width of npu control rtegister
`define NPU_STAT_WIDTH 1 // width of npu status register
`define NPU_CFG_WIDTH  64 // width of configration register 
`define NPU_CFG_DEPT   8  // deepth of configuration register 


//******************************************************************************
// UI related 
//******************************************************************************
  
`define DDR_AW   32
`define DDR_DW   64

