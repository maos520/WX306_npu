// *****************************************************************************
// @Project Name : npu 
// @Author       : Maos520
// @Email        : sujingjingabc@sina.com
// @File Name    : SEU_npu_CCReg.v
// @Module Name  : SEU_npu_CCReg
// @Created Time : 2019-10-22 19:59
//
// @Abstract     : This module mainly generate the register arrays used to control
//               and configure the npu.In general, the external master,cpu or host 
//               computer, deposits the fabric parameters of NN and address that 
//               store specific parameters to configration register array , and 
//               then start the npu by writing the control signals to control register.
//               Besides,the external master also acquire the npu status by reading
//               the status register. 
//
// Modification History
// ******************************************************************************
// Date           BY           Version         Change Description
// -------------------------------------------------------------------------
// 2019-10-22   Maos520         v1.0a            initial version 
// 
// ******************************************************************************

`timescale 1ns/1ps

`define NPU_EN_OS           16'h0
`define NPU_CTRL_OS         16'h8 
`define NPU_STAT_OS         16'h10

`define NPU_CFG_0_OS        16'h400    
`define NPU_CFG_1_OS        16'h408 
`define NPU_CFG_2_OS        16'h410 
`define NPU_CFG_3_OS        16'h418
`define NPU_CFG_4_OS        16'h420
`define NPU_CFG_5_OS        16'h428
`define NPU_CFG_6_OS        16'h430
`define NPU_CFG_7_OS        16'h438


module SEU_npu_CCReg
(
    input clk_trans,
    input rst_n,

    //register read/write interface   ------from the SEU_npu_biu module 
    
    output                      sys_ren,  // ?????                                         
    output  [`CCR_AW-1:0]       reg_addr, // read/write address 
    output  [`CCR_DW-1:0]       reg_wdata,  // wreg_wdata,// write data 
    output  [7:0]               reg_sel,  // write byte select 
    output                      reg_wen,  // write enable                                        );
    output                      reg_ren,  // read enable 
    input   [`CCR_DW-1:0]       reg_rdata,// read data 
    input                       reg_err,  // error indicator 
    input                       reg_ack,  // acknowledge signal

   
    
    input                       npu_busy_sync,              // from the sync module 
    input                       first_map_expired_flg_sync, // from the sync module
   
    // output the control signals of NN  -------- to the sync moudle 
    output                      npu_en_processing,  // to the sync module 
    output                      npu_init_cmplt,     // to the sync module
    
    // output the base para of NN        --------to the SEU_npu_mcu 
    output  [`DDR_AW-1:0]       nn_wt_saddr,        
    output  [`DDR_AW-1:0]       nn_map0_saddr,      
    output  [`DDR_AW-1:0]       nn_map1_saddr,      
    output  [`DDR_AW-1:0]       nn_bn_saddr,        
    output  [`DDR_AW-1:0]       nn_layer_para_saddr,
    output  [`DDR_AW-1:0]       nn_first_map_saddr, 
    output  [7:0]               nn_layers_num      
);   
    
    
    reg  [`NPU_EN_WIDTH-1:0]    npu_en;
    reg  [`NPU_CFG_WIDTH-1:0]   npu_ctrl;
    wire [`NPU_STAT_WIDTH-1:0]  npu_stat;
    reg  [`NPU_CFG_WIDTH-1:0]   npu_cfg_mem[0:`NPU_CFG_DEPT-1];
    
    wire                        ccr_sel;


    assign ccr_sel = (reg_addr[`CCR_AW-1:`CCR_OS_AW] == (`CCR_S_ADDR >> `CCR_OS_AW)) ? 1'b1 : 1'b0;


//----------------------------------------------------------------------
//------Status Register -Read Only 
// 1-bit register
// 
// This register is split into the following bit fields
// 
// [0] - Busy --npu is busy 
//
//------------------------------------------------------------------------

    assign npu_stat[0] = npu_busy_sync;

//----------------------------------------------------------------------
//-----Enable Register  -R/W
// 1-bit register 
//
// This register is split into the following bit fields
//
// [0] - Enable --start npu
//
// --------------------------------------------------------------------- 

    always @(posedge clk_trans or negedge rst_n) begin
        if(!rst_n) 
            npu_en <= `NPU_EN_WIDTH'b0;
        else if(ccr_sel && (reg_addr[`CCR_OS_AW-1:3] == (NPU_EN_OS >> 3)) && reg_wen)
            npu_en <= reg_wdata[`NPU_EN_WIDTH-1:0];
        else 
            npu_en <= npu_en;
    
    end
    
    assign npu_en_processing = npu_en[0];

//---------------------------------------------------------------------
//--------Control Register   -R/W
// 1-bit register
//
//
// This register is split into the following bit fields
//
// [0] - Init_cmplt      -- indicate the npu configuration is completed
// [1] - Map_is_new      -- incicate the first map is not handled 
//----------------------------------------------------------------------

    always @(posedge clk_trans or negedge rst_n) begin
        if(!rst_n)
            npu_ctrl[0] <= 1'b0;
        else if(ccr_sel && (reg_addr[`CCR_OS_AW-1:3] == (NPU_CTRL_OS >> 3)) && reg_wen)
            npu_ctrl[0] <= reg_wdata[0];
        else
           npu_ctrl <= npu_ctrl; 
    end

    always @(posedge clk_trans or negedge rst_n) begin
        if(!rst_n) 
            npu_ctrl[1] <= 1'b0;
        else if (ccr_sel && (reg_addr[`CCR_OS_AW-1:3] == (NPU_CTRL_OS >> 3)) && reg_wen && reg_wdata[1])
            npu_ctrl[1] <= 1'b1;
        else if (first_map_expired_flg_sync)
            npu_ctrl[1] <= 1'b0;
        else 
            npu_ctrl <= npu_ctrl;
    end
    
    assign  npu_init_cmplt = npu_ctrl[0];

//-----------------------------------------------------------------------
//--------NN Configuration Register
// 64*8-bits register 
// 
//
// This register is split into the following bit fields:
// 
// [0][31:0]  -nn_wt_saddr         -- weight start address in DDR
// [0][55:32] -nn_first_map_saddr  -- first map start address in DDR
// [0][63:56] -nn_layers_num       -- the number of nn
// [1][31:0]  -nn_bn_saddr         -- BN store start address in DDR
// [1][63:32] -nn_layer_para_saddr -- layer parameter start address in DDR
// [2][31:0]  -nn_map0_saddr       -- map0 start address in DDR 
// [2][63:32] -nn_map1_saddr       -- map1 start address in DDR

//------------------------------------------------------------------------- 


    always @(posedge clk_trans or negedge rst_n) begin
        if(!rst_n) begin
            npu_cfg_mem[0] <= 'b0;
            npu_cfg_mem[1] <= 'b0;
            npu_cfg_mem[2] <= 'b0;
            npu_cfg_mem[3] <= 'b0;
            npu_cfg_mem[4] <= 'b0;
            npu_cfg_mem[5] <= 'b0;
            npu_cfg_mem[6] <= 'b0;
            npu_cfg_mem[7] <= 'b0;
        end
        else if (ccr_sel && reg_wen)begin
            case (reg_addr[`CCR_OS_AW-1:3])
                (NPU_CFG_0_OS >> 3) : npu_cfg_mem[0] <= reg_wdata; 
                (NPU_CFG_1_OS >> 3) : npu_cfg_mem[1] <= reg_wdata; 
                (NPU_CFG_2_OS >> 3) : npu_cfg_mem[2] <= reg_wdata; 
                (NPU_CFG_3_OS >> 3) : npu_cfg_mem[3] <= reg_wdata; 
                (NPU_CFG_4_OS >> 3) : npu_cfg_mem[4] <= reg_wdata; 
                (NPU_CFG_5_OS >> 3) : npu_cfg_mem[5] <= reg_wdata; 
                (NPU_CFG_6_OS >> 3) : npu_cfg_mem[6] <= reg_wdata; 
                (NPU_CFG_7_OS >> 3) : npu_cfg_mem[7] <= reg_wdata; 
                            default : begin
                                npu_cfg_mem[0] <= npu_cfg_mem[0];
                                npu_cfg_mem[1] <= npu_cfg_mem[1];
                                npu_cfg_mem[2] <= npu_cfg_mem[2];
                                npu_cfg_mem[3] <= npu_cfg_mem[3];
                                npu_cfg_mem[4] <= npu_cfg_mem[4];
                                npu_cfg_mem[5] <= npu_cfg_mem[5];
                                npu_cfg_mem[6] <= npu_cfg_mem[6];
                                npu_cfg_mem[7] <= npu_cfg_mem[7];
                            end
            endcase
    
        end
    end

   assign nn_wt_saddr         = npu_cfg_mem[0][31:0];
   assign nn_first_map_saddr  = {npu_cfg_mem[0][55:32],8{1'b0}};
   assign nn_map1_saddr       = npu_cfg_mem[2][63:32];
   assign nn_map0_saddr       = npu_cfg_mem[2][31:0];
   assign nn_layers_num       = npu_cfg_mem[0][63:56];
   assign nn_bn_saddr         = npu_cfg_mem[1][31:0];
   assign nn_layer_para_saddr = npu_cfg_mem[1][63:3];



//-----------------------------------------------------------------------
//----------read logic---------------------------------------------------
//------------------------------------------------------------------------

    always @(*) begin
        reg_rdata <= {`CCR_DW{1'b0}};
        
        case (1'b1) 
            (reg_addr[`CCR_OS_AW-1:3] == (NPU_EN_OS   >> 3))  : reg_rdata[`NPU_EN_WIDTH-1:0]   = npu_en;
            (reg_addr[`CCR_OS_AW-1:3] == (NPU_STAT_OS >> 3))  : reg_rdata[`NPU_STAT_WIDTH-1:0] = npu_stat;
            (reg_addr[`CCR_OS_AW-1:3] == (NPU_CTRL_OS >> 3))  : reg_rdata[`NPU_CTRL_WIDTH-1:0] = npu_ctrl;
            (reg_addr[`CCR_OS_AW-1:3] == (NPU_CFG_0_OS >> 3)) : reg_rdata[`NPU_CFG_WIDTH-1:0]  = npu_cfg_mem[0];
            (reg_addr[`CCR_OS_AW-1:3] == (NPU_CFG_1_OS >> 3)) : reg_rdata[`NPU_CFG_WIDTH-1:0]  = npu_cfg_mem[1];
            (reg_addr[`CCR_OS_AW-1:3] == (NPU_CFG_2_OS >> 3)) : reg_rdata[`NPU_CFG_WIDTH-1:0]  = npu_cfg_mem[2];
            (reg_addr[`CCR_OS_AW-1:3] == (NPU_CFG_3_OS >> 3)) : reg_rdata[`NPU_CFG_WIDTH-1:0]  = npu_cfg_mem[3];
            (reg_addr[`CCR_OS_AW-1:3] == (NPU_CFG_4_OS >> 3)) : reg_rdata[`NPU_CFG_WIDTH-1:0]  = npu_cfg_mem[4];
            (reg_addr[`CCR_OS_AW-1:3] == (NPU_CFG_5_OS >> 3)) : reg_rdata[`NPU_CFG_WIDTH-1:0]  = npu_cfg_mem[5];
            (reg_addr[`CCR_OS_AW-1:3] == (NPU_CFG_6_OS >> 3)) : reg_rdata[`NPU_CFG_WIDTH-1:0]  = npu_cfg_mem[6];
            (reg_addr[`CCR_OS_AW-1:3] == (NPU_CFG_7_OS >> 3)) : reg_rdata[`NPU_CFG_WIDTH-1:0]  = npu_cfg_mem[7];
        endcase
    
    end

endmodule 
