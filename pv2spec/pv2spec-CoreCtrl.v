//=========================================================================
// 5-Stage PARCv2 Control Unit
//=========================================================================

`ifndef PARC_CORE_CTRL_V
`define PARC_CORE_CTRL_V

`include "pv2spec-InstMsg.v"
`include "pv2spec-CoreScoreboard.v"
`include "pv2spec-CoreReorderBuffer.v"

module parc_CoreCtrl
(
  input clk,
  input reset,

  // Instruction Memory Port
  output        imemreq_val,
  input         imemreq_rdy,
  input  [31:0] imemresp_msg_data,
  input         imemresp_val,

  // Data Memory Port

  output        dmemreq_msg_rw,
  output  [1:0] dmemreq_msg_len,
  output        dmemreq_val,
  input         dmemreq_rdy,
  input         dmemresp_val,

  // Controls Signals (ctrl->dpath)

  output  [1:0] pc_mux_sel_Phl,
  output  [2:0] op0_byp_mux_sel_Dhl,
  output  [3:0] op0_byp_rob_slot_Dhl,
  output  [1:0] op0_mux_sel_Dhl,
  output  [2:0] op1_byp_mux_sel_Dhl,
  output  [3:0] op1_byp_rob_slot_Dhl,
  output  [2:0] op1_mux_sel_Dhl,
  output [31:0] inst_Dhl,
  output  [3:0] alu_fn_Xhl,
  output  [2:0] muldivreq_msg_fn_Ihl,
  output        muldivreq_val,
  input         muldivreq_rdy,
  input         muldivresp_val,
  output        muldivresp_rdy,
  output        muldiv_mux_sel_X3hl,
  output  [2:0] dmemresp_mux_sel_Mhl,
  output        dmemresp_queue_en_Mhl,
  output        dmemresp_queue_val_Mhl,
  output  [1:0] wb_mux_sel_Whl,
  output        rf_wen_out_Whl,
  output  [4:0] rf_waddr_Whl,
  output        rob_fill_wen_Whl,
  output [ 3:0] rob_fill_slot_Whl,
  output        rob_commit_wen_Chl,
  output [ 3:0] rob_commit_slot_Chl,
  output [ 4:0] rob_commit_waddr_Chl,
  output        stall_Fhl,
  output        stall_Dhl,
  output        stall_Ihl,
  output        stall_Xhl,
  output        stall_Mhl,
  output        stall_Whl,

  // Control Signals (dpath->ctrl)

  input         branch_cond_eq_Xhl,
  input         branch_cond_zero_Xhl,
  input         branch_cond_neg_Xhl,
  input  [31:0] proc2cop_data_Whl,

  // CP0 Status

  output [31:0] cp0_status
);

  //----------------------------------------------------------------------
  // PC Stage: Instruction Memory Request
  //----------------------------------------------------------------------

  // PC Mux Select

  assign pc_mux_sel_Phl
    = brj_taken_Xhl    ? pm_b
    : brj_taken_Dhl    ? pc_mux_sel_Dhl
    :                    pm_p;

  // Only send a valid imem request if not stalled

  wire   imemreq_val_Phl = reset || !stall_Phl;
  assign imemreq_val     = imemreq_val_Phl;

  // Dummy Squash Signal

  wire squash_Phl = 1'b0;

  // Stall in PC if F is stalled

  wire stall_Phl = stall_Fhl;

  // Next bubble bit

  wire bubble_next_Phl = ( squash_Phl || stall_Phl );

  //----------------------------------------------------------------------
  // F <- P
  //----------------------------------------------------------------------

  reg imemreq_val_Fhl;

  reg bubble_Fhl;

  always @ ( posedge clk ) begin
    // Only pipeline the bubble bit if the next stage is not stalled
    if ( reset ) begin
      imemreq_val_Fhl <= 1'b0;

      bubble_Fhl <= 1'b0;
    end
    else if( !stall_Fhl ) begin
      imemreq_val_Fhl <= imemreq_val_Phl;

      bubble_Fhl <= bubble_next_Phl;
    end
  end

  //----------------------------------------------------------------------
  // Fetch Stage: Instruction Memory Response
  //----------------------------------------------------------------------

  // Is the current stage valid?

  wire inst_val_Fhl = ( !bubble_Fhl && !squash_Fhl );

  // Squash instruction in F stage if branch taken for a valid
  // instruction or if there was an exception in X stage

  wire squash_Fhl
    = ( inst_val_Dhl && brj_taken_Dhl )
   || ( inst_val_Xhl && brj_taken_Xhl );

  // Stall in F if D is stalled

  assign stall_Fhl = stall_Dhl;

  // Next bubble bit

  wire bubble_sel_Fhl  = ( squash_Fhl || stall_Fhl );
  wire bubble_next_Fhl = ( !bubble_sel_Fhl ) ? bubble_Fhl
                       : ( bubble_sel_Fhl )  ? 1'b1
                       :                       1'bx;

  //----------------------------------------------------------------------
  // Queue for instruction memory response
  //----------------------------------------------------------------------

  wire imemresp_queue_en_Fhl = ( stall_Dhl && imemresp_val );
  wire imemresp_queue_val_next_Fhl
    = stall_Dhl && ( imemresp_val || imemresp_queue_val_Fhl );

  reg [31:0] imemresp_queue_reg_Fhl;
  reg        imemresp_queue_val_Fhl;

  always @ ( posedge clk ) begin
    if ( imemresp_queue_en_Fhl ) begin
      imemresp_queue_reg_Fhl <= imemresp_msg_data;
    end
    imemresp_queue_val_Fhl <= imemresp_queue_val_next_Fhl;
  end

  //----------------------------------------------------------------------
  // Instruction memory queue mux
  //----------------------------------------------------------------------

  wire [31:0] imemresp_queue_mux_out_Fhl
    = ( !imemresp_queue_val_Fhl ) ? imemresp_msg_data
    : ( imemresp_queue_val_Fhl )  ? imemresp_queue_reg_Fhl
    :                               32'bx;

  //----------------------------------------------------------------------
  // D <- F
  //----------------------------------------------------------------------

  reg [31:0] ir_Dhl;
  reg        bubble_Dhl;

  always @ ( posedge clk ) begin
    if ( reset ) begin
      bubble_Dhl <= 1'b1;
    end
    else if( !stall_Dhl ) begin
      ir_Dhl     <= imemresp_queue_mux_out_Fhl;
      bubble_Dhl <= bubble_next_Fhl;
    end
  end

  //----------------------------------------------------------------------
  // Decode Stage: Constants
  //----------------------------------------------------------------------

  // Generic Parameters

  localparam n = 1'd0;
  localparam y = 1'd1;

  // Register specifiers

  localparam rx = 5'bx;
  localparam r0 = 5'd0;
  localparam rL = 5'd31;

  // Branch Type

  localparam br_x    = 3'bx;
  localparam br_none = 3'd0;
  localparam br_beq  = 3'd1;
  localparam br_bne  = 3'd2;
  localparam br_blez = 3'd3;
  localparam br_bgtz = 3'd4;
  localparam br_bltz = 3'd5;
  localparam br_bgez = 3'd6;

  // PC Mux Select

  localparam pm_x   = 2'bx;  // Don't care
  localparam pm_p   = 2'd0;  // Use pc+4
  localparam pm_b   = 2'd1;  // Use branch address
  localparam pm_j   = 2'd2;  // Use jump address
  localparam pm_r   = 2'd3;  // Use jump register

  // Operand 0 Bypass Mux Select

  localparam am_r0    = 3'd0; // Use rdata0
  localparam am_X_byp = 3'd1; // Bypass from X
  localparam am_M_byp = 3'd2; // Bypass from M
  localparam am_X3_byp= 3'd3; // Bypass from X3
  localparam am_W_byp = 3'd4; // Bypass from W

  // Operand 0 Mux Select

  localparam am_x     = 2'bx; // Don't care
  localparam am_rdat  = 2'd0; // Use output of bypass mux
  localparam am_sh    = 2'd1; // Use shamt
  localparam am_16    = 2'd2; // Use constant 16
  localparam am_0     = 2'd3; // Use constant 0 (for mtc0)

  // Operand 1 Bypass Mux Select

  localparam bm_r1    = 3'd0; // Use rdata1
  localparam bm_X_byp = 3'd1; // Bypass from X
  localparam bm_M_byp = 3'd2; // Bypass from M
  localparam bm_X3_byp= 3'd3; // Bypass from X3
  localparam bm_W_byp = 3'd4; // Bypass from W

  // Operand 1 Mux Select

  localparam bm_x     = 3'bx; // Don't care
  localparam bm_rdat  = 3'd0; // Use output of bypass mux
  localparam bm_zi    = 3'd1; // Use zero-extended immediate
  localparam bm_si    = 3'd2; // Use sign-extended immediate
  localparam bm_pc    = 3'd3; // Use PC
  localparam bm_0     = 3'd4; // Use constant 0

  // ALU Function

  localparam alu_x    = 4'bx;
  localparam alu_add  = 4'd0;
  localparam alu_sub  = 4'd1;
  localparam alu_sll  = 4'd2;
  localparam alu_or   = 4'd3;
  localparam alu_lt   = 4'd4;
  localparam alu_ltu  = 4'd5;
  localparam alu_and  = 4'd6;
  localparam alu_xor  = 4'd7;
  localparam alu_nor  = 4'd8;
  localparam alu_srl  = 4'd9;
  localparam alu_sra  = 4'd10;

  // Muldiv Function

  localparam md_x    = 3'bx;
  localparam md_mul  = 3'd0;
  localparam md_div  = 3'd1;
  localparam md_divu = 3'd2;
  localparam md_rem  = 3'd3;
  localparam md_remu = 3'd4;

  // MulDiv Mux Select

  localparam mdm_x = 1'bx; // Don't Care
  localparam mdm_l = 1'd0; // Take lower half of 64-bit result, mul/div/divu
  localparam mdm_u = 1'd1; // Take upper half of 64-bit result, rem/remu

  // Execute Mux Select

  localparam em_x   = 1'bx; // Don't Care
  localparam em_alu = 1'd0; // Use ALU output
  localparam em_md  = 1'd1; // Use muldiv output

  // Memory Request Type

  localparam nr = 2'b0; // No request
  localparam ld = 2'd1; // Load
  localparam st = 2'd2; // Store

  // Subword Memop Length

  localparam ml_x  = 2'bx;
  localparam ml_w  = 2'd0;
  localparam ml_b  = 2'd1;
  localparam ml_h  = 2'd2;

  // Memory Response Mux Select

  localparam dmm_x  = 3'bx;
  localparam dmm_w  = 3'd0;
  localparam dmm_b  = 3'd1;
  localparam dmm_bu = 3'd2;
  localparam dmm_h  = 3'd3;
  localparam dmm_hu = 3'd4;

  // Writeback Mux 1

  localparam wm_x   = 1'bx; // Don't care
  localparam wm_alu = 1'd0; // Use ALU output
  localparam wm_mem = 1'd1; // Use data memory response

  //----------------------------------------------------------------------
  // Decode Stage: Logic
  //----------------------------------------------------------------------

  // Is the current stage valid?

  wire inst_val_Dhl = ( !bubble_Dhl && !squash_Dhl );

  // Ship instruction for field parsing to datapath

  assign inst_Dhl = ir_Dhl;

  // Parse instruction fields

  wire   [4:0] inst_rs_Dhl;
  wire   [4:0] inst_rt_Dhl;
  wire   [4:0] inst_rd_Dhl;

  parc_InstMsgFromBits inst_msg_from_bits
  (
    .msg      (ir_Dhl),
    .opcode   (),
    .rs       (inst_rs_Dhl),
    .rt       (inst_rt_Dhl),
    .rd       (inst_rd_Dhl),
    .shamt    (),
    .func     (),
    .imm      (),
    .imm_sign (),
    .target   ()
  );

  // Shorten register specifier name for table

  wire [4:0] rs = inst_rs_Dhl;
  wire [4:0] rt = inst_rt_Dhl;
  wire [4:0] rd = inst_rd_Dhl;

  // Instruction Decode

  localparam cs_sz = 39;
  reg [cs_sz-1:0] cs;

  always @ (*) begin

    cs = {cs_sz{1'bx}}; // Default to invalid instruction

    casez ( ir_Dhl )

      //                               j     br       pc      op0      rs op1      rt alu       md       md md     ex      mem  mem   memresp wb      rf      cp0
      //                           val taken type     muxsel  muxsel   en muxsel   en fn        fn       en muxsel muxsel  rq   len   muxsel  muxsel  wen wa  wen
      `PARC_INST_MSG_NOP     :cs={ y,  n,    br_none, pm_p,   am_x,    n, bm_x,    n, alu_x,    md_x,    n, mdm_x, em_x,   nr,  ml_x, dmm_x,  wm_x,   n,  rx, n   };

      `PARC_INST_MSG_ADDIU   :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_si,   n, alu_add,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rt, n   };
      `PARC_INST_MSG_SLTI    :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_si,   n, alu_lt,   md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rt, n   };
      `PARC_INST_MSG_SLTIU   :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_si,   n, alu_ltu,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rt, n   };
      `PARC_INST_MSG_ANDI    :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_zi,   n, alu_and,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rt, n   };
      `PARC_INST_MSG_ORI     :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_zi,   n, alu_or,   md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rt, n   };
      `PARC_INST_MSG_XORI    :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_zi,   n, alu_xor,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rt, n   };
      `PARC_INST_MSG_LUI     :cs={ y,  n,    br_none, pm_p,   am_16,   n, bm_zi,   n, alu_sll,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rt, n   };

      `PARC_INST_MSG_ADDU    :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_rdat, y, alu_add,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };
      `PARC_INST_MSG_SUBU    :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_rdat, y, alu_sub,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };
      `PARC_INST_MSG_AND     :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_rdat, y, alu_and,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };
      `PARC_INST_MSG_OR      :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_rdat, y, alu_or,   md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };
      `PARC_INST_MSG_XOR     :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_rdat, y, alu_xor,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };
      `PARC_INST_MSG_NOR     :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_rdat, y, alu_nor,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };

      `PARC_INST_MSG_SLL     :cs={ y,  n,    br_none, pm_p,   am_sh,   n, bm_rdat, y, alu_sll,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };
      `PARC_INST_MSG_SRL     :cs={ y,  n,    br_none, pm_p,   am_sh,   n, bm_rdat, y, alu_srl,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };
      `PARC_INST_MSG_SRA     :cs={ y,  n,    br_none, pm_p,   am_sh,   n, bm_rdat, y, alu_sra,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };
      `PARC_INST_MSG_SLLV    :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_rdat, y, alu_sll,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };
      `PARC_INST_MSG_SRLV    :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_rdat, y, alu_srl,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };
      `PARC_INST_MSG_SRAV    :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_rdat, y, alu_sra,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };

      `PARC_INST_MSG_SLT     :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_rdat, y, alu_lt,   md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };
      `PARC_INST_MSG_SLTU    :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_rdat, y, alu_ltu,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };

      `PARC_INST_MSG_MUL     :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_rdat, y, alu_x,    md_mul,  y, mdm_l, em_md,  nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };
      `PARC_INST_MSG_DIV     :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_rdat, y, alu_x,    md_div,  y, mdm_l, em_md,  nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };
      `PARC_INST_MSG_DIVU    :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_rdat, y, alu_x,    md_divu, y, mdm_l, em_md,  nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };
      `PARC_INST_MSG_REM     :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_rdat, y, alu_x,    md_rem,  y, mdm_u, em_md,  nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };
      `PARC_INST_MSG_REMU    :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_rdat, y, alu_x,    md_remu, y, mdm_u, em_md,  nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };

      `PARC_INST_MSG_LW      :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_si,   n, alu_add,  md_x,    n, mdm_x, em_x,   ld,  ml_w, dmm_w,  wm_mem, y,  rt, n   };
      `PARC_INST_MSG_LB      :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_si,   n, alu_add,  md_x,    n, mdm_x, em_x,   ld,  ml_b, dmm_b,  wm_mem, y,  rt, n   };
      `PARC_INST_MSG_LBU     :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_si,   n, alu_add,  md_x,    n, mdm_x, em_x,   ld,  ml_b, dmm_bu, wm_mem, y,  rt, n   };
      `PARC_INST_MSG_LH      :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_si,   n, alu_add,  md_x,    n, mdm_x, em_x,   ld,  ml_h, dmm_h,  wm_mem, y,  rt, n   };
      `PARC_INST_MSG_LHU     :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_si,   n, alu_add,  md_x,    n, mdm_x, em_x,   ld,  ml_h, dmm_hu, wm_mem, y,  rt, n   };
      `PARC_INST_MSG_SW      :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_si,   y, alu_add,  md_x,    n, mdm_x, em_x,   st,  ml_w, dmm_w,  wm_mem, n,  rx, n   };
      `PARC_INST_MSG_SB      :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_si,   y, alu_add,  md_x,    n, mdm_x, em_x,   st,  ml_b, dmm_x,  wm_mem, n,  rx, n   };
      `PARC_INST_MSG_SH      :cs={ y,  n,    br_none, pm_p,   am_rdat, y, bm_si,   y, alu_add,  md_x,    n, mdm_x, em_x,   st,  ml_h, dmm_x,  wm_mem, n,  rx, n   };

      `PARC_INST_MSG_J       :cs={ y,  y,    br_none, pm_j,   am_x,    n, bm_x,    n, alu_x,    md_x,    n, mdm_x, em_x,   nr,  ml_x, dmm_x,  wm_x,   n,  rx, n   };
      `PARC_INST_MSG_JAL     :cs={ y,  y,    br_none, pm_j,   am_0,    n, bm_pc,   n, alu_add,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rL, n   };
      `PARC_INST_MSG_JALR    :cs={ y,  y,    br_none, pm_r,   am_0,    y, bm_pc,   n, alu_add,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, y,  rd, n   };
      `PARC_INST_MSG_JR      :cs={ y,  y,    br_none, pm_r,   am_x,    y, bm_x,    n, alu_x,    md_x,    n, mdm_x, em_x,   nr,  ml_x, dmm_x,  wm_x,   n,  rx, n   };
      `PARC_INST_MSG_BEQ     :cs={ y,  n,    br_beq,  pm_b,   am_rdat, y, bm_rdat, y, alu_xor,  md_x,    n, mdm_x, em_x,   nr,  ml_x, dmm_x,  wm_x,   n,  rx, n   };
      `PARC_INST_MSG_BNE     :cs={ y,  n,    br_bne,  pm_b,   am_rdat, y, bm_rdat, y, alu_xor,  md_x,    n, mdm_x, em_x,   nr,  ml_x, dmm_x,  wm_x,   n,  rx, n   };
      `PARC_INST_MSG_BLEZ    :cs={ y,  n,    br_blez, pm_b,   am_rdat, y, bm_rdat, y, alu_sub,  md_x,    n, mdm_x, em_x,   nr,  ml_x, dmm_x,  wm_x,   n,  rx, n   };
      `PARC_INST_MSG_BGTZ    :cs={ y,  n,    br_bgtz, pm_b,   am_rdat, y, bm_rdat, y, alu_sub,  md_x,    n, mdm_x, em_x,   nr,  ml_x, dmm_x,  wm_x,   n,  rx, n   };
      `PARC_INST_MSG_BLTZ    :cs={ y,  n,    br_bltz, pm_b,   am_rdat, y, bm_rdat, y, alu_sub,  md_x,    n, mdm_x, em_x,   nr,  ml_x, dmm_x,  wm_x,   n,  rx, n   };
      `PARC_INST_MSG_BGEZ    :cs={ y,  n,    br_bgez, pm_b,   am_rdat, y, bm_rdat, y, alu_sub,  md_x,    n, mdm_x, em_x,   nr,  ml_x, dmm_x,  wm_x,   n,  rx, n   };

      `PARC_INST_MSG_MTC0    :cs={ y,  n,    br_none, pm_p,   am_0,    n, bm_rdat, y, alu_add,  md_x,    n, mdm_x, em_alu, nr,  ml_x, dmm_x,  wm_alu, n,  rx, y   };

    endcase

  end

  // Jump and Branch Controls

  wire       brj_taken_Dhl = ( inst_val_Dhl && cs[`PARC_INST_MSG_J_EN] );
  wire [2:0] br_sel_Dhl    = cs[`PARC_INST_MSG_BR_SEL];

  // PC Mux Select

  wire [1:0] pc_mux_sel_Dhl = cs[`PARC_INST_MSG_PC_SEL];

  // Operand Bypassing Logic

  wire       rs_en_Dhl    = cs[`PARC_INST_MSG_RS_EN];
  wire       rt_en_Dhl    = cs[`PARC_INST_MSG_RT_EN];

  // Register Writeback Controls

  wire [4:0] rf_waddr_Dhl = cs[`PARC_INST_MSG_RF_WADDR];
  wire rf_wen_Dhl         = cs[`PARC_INST_MSG_RF_WEN];

  // Operand Mux Select

  assign op0_mux_sel_Dhl = cs[`PARC_INST_MSG_OP0_SEL];
  assign op1_mux_sel_Dhl = cs[`PARC_INST_MSG_OP1_SEL];

  // ALU Function

  wire [3:0] alu_fn_Dhl = cs[`PARC_INST_MSG_ALU_FN];

  // Muldiv Function

  wire [2:0] muldivreq_msg_fn_Dhl = cs[`PARC_INST_MSG_MULDIV_FN];

  // Muldiv Controls

  wire muldivreq_val_Dhl = cs[`PARC_INST_MSG_MULDIV_EN];

  // Muldiv Mux Select

  wire muldiv_mux_sel_Dhl = cs[`PARC_INST_MSG_MULDIV_SEL];

  // Execute Mux Select

  wire execute_mux_sel_Dhl = cs[`PARC_INST_MSG_EX_SEL];

  // Memory Controls

  wire       is_load_Dhl         = ( cs[`PARC_INST_MSG_MEM_REQ] == ld );

  wire       dmemreq_msg_rw_Dhl  = ( cs[`PARC_INST_MSG_MEM_REQ] == st );
  wire [1:0] dmemreq_msg_len_Dhl = cs[`PARC_INST_MSG_MEM_LEN];
  wire       dmemreq_val_Dhl     = ( cs[`PARC_INST_MSG_MEM_REQ] != nr );

  // Memory response mux select

  wire [2:0] dmemresp_mux_sel_Dhl = cs[`PARC_INST_MSG_MEM_SEL];

  // Writeback Mux Select

  wire wb_mux_sel_Dhl = cs[`PARC_INST_MSG_WB_SEL];

  // Coprocessor write enable

  wire cp0_wen_Dhl = cs[`PARC_INST_MSG_CP0_WEN];

  // Coprocessor register specifier

  wire [4:0] cp0_addr_Dhl = inst_rd_Dhl;

  //----------------------------------------------------------------------
  // Scoreboard
  //----------------------------------------------------------------------

  reg [5:0] inst_latency_Dhl;
  always @(*) begin
    inst_latency_Dhl =
      (cs[`PARC_INST_MSG_MULDIV_EN] != n)    ? 6'b100000 :
      (cs[`PARC_INST_MSG_MEM_REQ]   != nr)   ? 6'b001000 :
                                               6'b000100;
  end
    
  reg [2:0] inst_func_unit_Dhl;
  always @(*) begin
    inst_func_unit_Dhl =
      (cs[`PARC_INST_MSG_MULDIV_EN] != n)    ? 3'd3 :
      (cs[`PARC_INST_MSG_MEM_REQ]   != nr)   ? 3'd2 :
                                               3'd1;
  end
    
  wire [5:0] stalls_combined = {
    stall_Ihl,
    stall_Xhl,
    stall_Mhl,
    1'b0,
    1'b0,
    stall_Whl};

  wire       stall_sb_Dhl;
  wire       non_sb_stall_Dhl;
  wire [1:0] wb_mux_sel_Whl;

  wire [3:0] rob_fill_slot_Dhl;

  wire [3:0] op0_byp_rob_slot_Dhl;
  wire [3:0] op1_byp_rob_slot_Dhl;

  parc_CoreScoreboard scoreboard
  (
    .clk                 (clk),
    .reset               (reset),
    .src0                (rs),
    .src0_en             (rs_en_Dhl),
    .src1                (rt),
    .src1_en             (rt_en_Dhl),
    .dst                 (rf_waddr_Dhl),
    .dst_en              (rf_wen_Dhl),
    .latency             (inst_latency_Dhl),
    .func_unit           (inst_func_unit_Dhl), 
    .inst_val_Dhl        (inst_val_Dhl),
    .non_sb_stall_Dhl    (non_sb_stall_Dhl),

    .rob_alloc_slot      (rob_fill_slot_Dhl),
    .rob_commit_slot     (rob_commit_slot_Chl),
    .rob_commit_wen      (rob_commit_wen_Chl),

    .stalls              (stalls_combined),

    .src0_byp_mux_sel    (op0_byp_mux_sel_Dhl),
    .src0_byp_rob_slot   (op0_byp_rob_slot_Dhl),
    

    .src1_byp_mux_sel    (op1_byp_mux_sel_Dhl),
    .src1_byp_rob_slot   (op1_byp_rob_slot_Dhl),

    .stall_hazard        (stall_sb_Dhl),
    .wb_mux_sel          (wb_mux_sel_Whl)
  );

  //----------------------------------------------------------------------
  // Squash and Stall Logic
  //----------------------------------------------------------------------

  // Squash instruction in D if a valid branch in X is taken

  wire squash_Dhl = ( inst_val_Xhl && brj_taken_Xhl );

  // Aggregate Stall Signal

  wire stall_spec_Dhl = inst_val_Ihl && (br_sel_Ihl != br_none);

  assign non_sb_stall_Dhl = ( stall_Ihl ||
                       stall_spec_Dhl ||
                      (inst_val_Dhl && !rob_req_rdy_Dhl));

  assign stall_Dhl = non_sb_stall_Dhl || (inst_val_Dhl && stall_sb_Dhl );

  // Next bubble bit

  wire bubble_sel_Dhl  = ( squash_Dhl || stall_Dhl );
  wire bubble_next_Dhl = ( !bubble_sel_Dhl ) ? bubble_Dhl
                       : ( bubble_sel_Dhl )  ? 1'b1
                       :                       1'bx;

  //----------------------------------------------------------------------
  // I <- D
  //----------------------------------------------------------------------

  reg [31:0] ir_Ihl;
  reg  [2:0] br_sel_Ihl;
  reg  [3:0] alu_fn_Ihl;
  reg  [2:0] muldivreq_msg_fn_Ihl;
  reg        muldivreq_val_Ihl;
  reg        muldiv_mux_sel_Ihl;
  reg        execute_mux_sel_Ihl;
  reg        is_load_Ihl;
  reg        dmemreq_msg_rw_Ihl;
  reg  [1:0] dmemreq_msg_len_Ihl;
  reg        dmemreq_val_Ihl;
  reg  [2:0] dmemresp_mux_sel_Ihl;
  reg        wb_mux_sel_Ihl;
  reg        rf_wen_Ihl;
  reg  [4:0] rf_waddr_Ihl;
  reg  [3:0] rob_fill_slot_Ihl;
  reg        cp0_wen_Ihl;
  reg  [4:0] cp0_addr_Ihl;

  reg        bubble_Ihl;

  // Pipeline Controls

  always @ ( posedge clk ) begin
    if ( reset ) begin
      bubble_Ihl <= 1'b1;
    end
    else if( !stall_Ihl ) begin
      ir_Ihl               <= ir_Dhl;
      br_sel_Ihl           <= br_sel_Dhl;
      alu_fn_Ihl           <= alu_fn_Dhl;
      muldivreq_msg_fn_Ihl <= muldivreq_msg_fn_Dhl;
      muldivreq_val_Ihl    <= muldivreq_val_Dhl;
      muldiv_mux_sel_Ihl   <= muldiv_mux_sel_Dhl;
      execute_mux_sel_Ihl  <= execute_mux_sel_Dhl;
      is_load_Ihl          <= is_load_Dhl;
      dmemreq_msg_rw_Ihl   <= dmemreq_msg_rw_Dhl;
      dmemreq_msg_len_Ihl  <= dmemreq_msg_len_Dhl;
      dmemreq_val_Ihl      <= dmemreq_val_Dhl;
      dmemresp_mux_sel_Ihl <= dmemresp_mux_sel_Dhl;
      wb_mux_sel_Ihl       <= wb_mux_sel_Dhl;
      rf_waddr_Ihl         <= rf_waddr_Dhl;
      rf_wen_Ihl           <= rf_wen_Dhl;
      rob_fill_slot_Ihl    <= rob_fill_slot_Dhl;
      cp0_wen_Ihl          <= cp0_wen_Dhl;
      cp0_addr_Ihl         <= cp0_addr_Dhl;

      bubble_Ihl           <= bubble_next_Dhl;
    end

  end

  // Is the current stage valid?

  wire inst_val_Ihl = ( !bubble_Ihl && !squash_Ihl );

  // Dummy squash signal

  wire squash_Ihl = 1'b0;

  // Stall Signal

  assign stall_Ihl = stall_Xhl;

  // Next bubble bit

  wire bubble_sel_Ihl  = ( squash_Ihl || stall_Ihl );
  wire bubble_next_Ihl = ( !bubble_sel_Ihl ) ? bubble_Ihl
                       : ( bubble_sel_Ihl )  ? 1'b1
                       :                       1'bx;

  //----------------------------------------------------------------------
  // X <- I
  //----------------------------------------------------------------------

  reg [31:0] ir_Xhl;
  reg  [2:0] br_sel_Xhl;
  reg  [3:0] alu_fn_Xhl;
  reg        muldivreq_val_Xhl;
  reg        muldiv_mux_sel_Xhl;
  reg        execute_mux_sel_Xhl;
  reg        is_load_Xhl;
  reg        dmemreq_msg_rw_Xhl;
  reg  [1:0] dmemreq_msg_len_Xhl;
  reg        dmemreq_val_Xhl;
  reg  [2:0] dmemresp_mux_sel_Xhl;
  reg        wb_mux_sel_Xhl;
  reg        rf_wen_Xhl;
  reg  [4:0] rf_waddr_Xhl;
  reg  [3:0] rob_fill_slot_Xhl;
  reg        cp0_wen_Xhl;
  reg  [4:0] cp0_addr_Xhl;

  reg        bubble_Xhl;

  // Pipeline Controls

  always @ ( posedge clk ) begin
    if ( reset ) begin
      bubble_Xhl <= 1'b1;
    end
    else if( !stall_Xhl ) begin
      ir_Xhl               <= ir_Ihl;
      br_sel_Xhl           <= br_sel_Ihl;
      alu_fn_Xhl           <= alu_fn_Ihl;
      muldivreq_val_Xhl    <= muldivreq_val_Ihl;
      muldiv_mux_sel_Xhl   <= muldiv_mux_sel_Ihl;
      execute_mux_sel_Xhl  <= execute_mux_sel_Ihl;
      is_load_Xhl          <= is_load_Ihl;
      dmemreq_msg_rw_Xhl   <= dmemreq_msg_rw_Ihl;
      dmemreq_msg_len_Xhl  <= dmemreq_msg_len_Ihl;
      dmemreq_val_Xhl      <= dmemreq_val_Ihl;
      dmemresp_mux_sel_Xhl <= dmemresp_mux_sel_Ihl;
      wb_mux_sel_Xhl       <= wb_mux_sel_Ihl;
      rf_waddr_Xhl         <= rf_waddr_Ihl;
      rf_wen_Xhl           <= rf_wen_Ihl;
      rob_fill_slot_Xhl    <= rob_fill_slot_Ihl;
      cp0_wen_Xhl          <= cp0_wen_Ihl;
      cp0_addr_Xhl         <= cp0_addr_Ihl;

      bubble_Xhl           <= bubble_next_Ihl;
    end

  end

  //----------------------------------------------------------------------
  // Execute Stage
  //----------------------------------------------------------------------

  // Is the current stage valid?

  wire inst_val_Xhl = ( !bubble_Xhl && !squash_Xhl );

  // Muldiv request

  assign muldivreq_val = muldivreq_val_Ihl && inst_val_Ihl;
  assign muldivresp_rdy = 1'b1;

  // Only send a valid dmem request if not stalled

  assign dmemreq_msg_rw  = dmemreq_msg_rw_Xhl;
  assign dmemreq_msg_len = dmemreq_msg_len_Xhl;
  assign dmemreq_val     = ( inst_val_Xhl && !stall_Xhl && dmemreq_val_Xhl );

  // Branch Conditions

  wire beq_resolve_Xhl  = branch_cond_eq_Xhl;
  wire bne_resolve_Xhl  = ~branch_cond_eq_Xhl;
  wire blez_resolve_Xhl = branch_cond_zero_Xhl | branch_cond_neg_Xhl;
  wire bgtz_resolve_Xhl = ~( branch_cond_zero_Xhl | branch_cond_neg_Xhl );
  wire bltz_resolve_Xhl = branch_cond_neg_Xhl;
  wire bgez_resolve_Xhl = branch_cond_zero_Xhl | ~branch_cond_neg_Xhl;

  // Resolve Branch

  wire beq_taken_Xhl  = ( ( br_sel_Xhl == br_beq ) && beq_resolve_Xhl );
  wire bne_taken_Xhl  = ( ( br_sel_Xhl == br_bne ) && bne_resolve_Xhl );
  wire blez_taken_Xhl = ( ( br_sel_Xhl == br_blez ) && blez_resolve_Xhl );
  wire bgtz_taken_Xhl = ( ( br_sel_Xhl == br_bgtz ) && bgtz_resolve_Xhl );
  wire bltz_taken_Xhl = ( ( br_sel_Xhl == br_bltz ) && bltz_resolve_Xhl );
  wire bgez_taken_Xhl = ( ( br_sel_Xhl == br_bgez ) && bgez_resolve_Xhl );

  wire any_br_taken_Xhl
    = ( beq_taken_Xhl
   ||   bne_taken_Xhl
   ||   blez_taken_Xhl
   ||   bgtz_taken_Xhl
   ||   bltz_taken_Xhl
   ||   bgez_taken_Xhl );

  wire brj_taken_Xhl = ( inst_val_Xhl && any_br_taken_Xhl );

  // Dummy Squash Signal

  wire squash_Xhl = 1'b0;

  // Stall in X if imem is not ready

  wire stall_imem_Xhl = !imemreq_rdy;

  // Stall in X if dmem is not ready and there was a valid request

  wire stall_dmem_Xhl = ( dmemreq_val_Xhl && inst_val_Xhl && !dmemreq_rdy );

  // Aggregate Stall Signal

  assign stall_Xhl = ( stall_Mhl || stall_imem_Xhl || stall_dmem_Xhl );

  // Next bubble bit

  wire bubble_sel_Xhl  = ( squash_Xhl || stall_Xhl );
  wire bubble_next_Xhl = ( !bubble_sel_Xhl ) ? bubble_Xhl
                       : ( bubble_sel_Xhl )  ? 1'b1
                       :                       1'bx;

  //----------------------------------------------------------------------
  // M <- X
  //----------------------------------------------------------------------

  reg [31:0] ir_Mhl;
  reg        is_load_Mhl;
  reg        dmemreq_val_Mhl;
  reg  [2:0] dmemresp_mux_sel_Mhl;
  reg        muldiv_mux_sel_Mhl;
  reg        wb_mux_sel_Mhl;
  reg        rf_wen_Mhl;
  reg  [4:0] rf_waddr_Mhl;
  reg  [3:0] rob_fill_slot_Mhl;
  reg        cp0_wen_Mhl;
  reg  [4:0] cp0_addr_Mhl;

  reg        bubble_Mhl;

  // Pipeline Controls

  always @ ( posedge clk ) begin
    if ( reset ) begin
      dmemreq_val_Mhl <= 1'b0;

      bubble_Mhl <= 1'b1;
    end
    else if( !stall_Mhl ) begin
      ir_Mhl               <= ir_Xhl;
      is_load_Mhl          <= is_load_Xhl;
      dmemreq_val_Mhl      <= dmemreq_val;
      dmemresp_mux_sel_Mhl <= dmemresp_mux_sel_Xhl;
      muldiv_mux_sel_Mhl   <= muldiv_mux_sel_Xhl;
      wb_mux_sel_Mhl       <= wb_mux_sel_Xhl;
      rf_wen_Mhl           <= rf_wen_Xhl;
      rf_waddr_Mhl         <= rf_waddr_Xhl;
      rob_fill_slot_Mhl    <= rob_fill_slot_Xhl;
      cp0_wen_Mhl          <= cp0_wen_Xhl;
      cp0_addr_Mhl         <= cp0_addr_Xhl;

      bubble_Mhl           <= bubble_next_Xhl;
    end
  end

  //----------------------------------------------------------------------
  // Memory Stage
  //----------------------------------------------------------------------

  // Is current stage valid?

  wire inst_val_Mhl = ( !bubble_Mhl && !squash_Mhl );

  // Data memory queue control signals

  assign dmemresp_queue_en_Mhl = ( stall_Mhl && dmemresp_val );
  wire   dmemresp_queue_val_next_Mhl
    = stall_Mhl && ( dmemresp_val || dmemresp_queue_val_Mhl );

  // Dummy Squash Signal

  wire squash_Mhl = 1'b0;

  // Stall in M if memory response is not returned for a valid request

  wire stall_dmem_Mhl
    = ( !reset && dmemreq_val_Mhl && inst_val_Mhl && !dmemresp_val && !dmemresp_queue_val_Mhl );
  wire stall_imem_Mhl
    = ( !reset && imemreq_val_Fhl && inst_val_Fhl && !imemresp_val && !imemresp_queue_val_Fhl );

  // Aggregate Stall Signal

  wire stall_Mhl = ( stall_imem_Mhl || stall_dmem_Mhl );

  // Next bubble bit

  wire bubble_sel_Mhl  = ( squash_Mhl || stall_Mhl );
  wire bubble_next_Mhl = ( !bubble_sel_Mhl ) ? bubble_Mhl
                       : ( bubble_sel_Mhl )  ? 1'b1
                       :                       1'bx;

  //----------------------------------------------------------------------
  // X2 <- M
  //----------------------------------------------------------------------
  
  reg [31:0] ir_X2hl;
  reg        dmemresp_queue_val_X2hl;
  reg        muldiv_mux_sel_X2hl;
  reg        rf_wen_X2hl;
  reg  [4:0] rf_waddr_X2hl;
  reg  [3:0] rob_fill_slot_X2hl;
  reg        cp0_wen_X2hl;
  reg  [4:0] cp0_addr_X2hl;
  reg        bubble_X2hl;

  // Dummy stall signal
  wire squash_X2hl = 1'b0;
  wire stall_X2hl  = 1'b0;

  // Next bubble bit

  wire bubble_sel_X2hl  = ( squash_X2hl || stall_X2hl );
  wire bubble_next_X2hl = ( !bubble_sel_X2hl ) ? bubble_X2hl
                        : ( bubble_sel_X2hl )  ? 1'b1
                        :                        1'bx;

  always @(posedge clk) begin
    if (reset)
      bubble_Whl          <= bubble_next_Mhl;
    else if (!stall_X2hl) begin
      ir_X2hl             <= ir_Mhl;
      muldiv_mux_sel_X2hl <= muldiv_mux_sel_Mhl;
      rf_wen_X2hl         <= rf_wen_Mhl;
      rf_waddr_X2hl       <= rf_waddr_Mhl;
      rob_fill_slot_X2hl  <= rob_fill_slot_Mhl;
      cp0_wen_X2hl        <= cp0_wen_Mhl;
      cp0_addr_X2hl       <= cp0_addr_Mhl;
      bubble_X2hl         <= bubble_next_Mhl;
    end
  end
      
  //----------------------------------------------------------------------
  // X3 <- X2
  //----------------------------------------------------------------------
  
  reg [31:0] ir_X3hl;
  reg        dmemresp_queue_val_X3hl;
  reg        muldiv_mux_sel_X3hl;
  reg        rf_wen_X3hl;
  reg  [4:0] rf_waddr_X3hl;
  reg  [3:0] rob_fill_slot_X3hl;
  reg        cp0_wen_X3hl;
  reg  [4:0] cp0_addr_X3hl;
  reg        bubble_X3hl;

  // Dummy stall signal
  wire squash_X3hl = 1'b0;
  wire stall_X3hl  = 1'b0;

  // Next bubble bit

  wire bubble_sel_X3hl  = ( squash_X3hl || stall_X3hl );
  wire bubble_next_X3hl = ( !bubble_sel_X3hl ) ? bubble_X3hl
                        : ( bubble_sel_X3hl )  ? 1'b1
                        :                        1'bx;

  always @(posedge clk) begin
    if (reset)
      bubble_Whl          <= bubble_next_X2hl;
    else if (!stall_X3hl) begin
      ir_X3hl             <= ir_X2hl;
      muldiv_mux_sel_X3hl <= muldiv_mux_sel_X2hl;
      rf_wen_X3hl         <= rf_wen_X2hl;
      rf_waddr_X3hl       <= rf_waddr_X2hl;
      rob_fill_slot_X3hl  <= rob_fill_slot_X2hl;
      cp0_wen_X3hl        <= cp0_wen_X2hl;
      cp0_addr_X3hl       <= cp0_addr_X2hl;
      bubble_X3hl         <= bubble_next_X2hl;
    end
  end
      
  //----------------------------------------------------------------------
  // W <- *
  //----------------------------------------------------------------------

  reg [31:0] ir_Whl;
  reg        dmemresp_queue_val_Mhl;
  reg        rf_wen_Whl;
  reg  [4:0] rf_waddr_Whl;
  reg  [3:0] rob_fill_slot_Whl;
  reg        cp0_wen_Whl;
  reg  [4:0] cp0_addr_Whl;

  reg        bubble_Whl;

  // Pipeline Controls

  always @(posedge clk) begin
    if (reset) begin
      bubble_Whl   <= 1'b1;
    end else case(wb_mux_sel_Whl)
    `FUNC_UNIT_ALU: begin
      ir_Whl            <= ir_Xhl;
      rf_wen_Whl        <= rf_wen_Xhl;
      rf_waddr_Whl      <= rf_waddr_Xhl;
      rob_fill_slot_Whl <= rob_fill_slot_Xhl;
      cp0_wen_Whl       <= cp0_wen_Xhl;
      cp0_addr_Whl      <= cp0_addr_Xhl;
      bubble_Whl        <= bubble_next_Xhl;
    end
    `FUNC_UNIT_MEM: begin
      ir_Whl            <= ir_Mhl;
      rf_wen_Whl        <= rf_wen_Mhl;
      rf_waddr_Whl      <= rf_waddr_Mhl;
      rob_fill_slot_Whl <= rob_fill_slot_Mhl;
      cp0_wen_Whl       <= cp0_wen_Mhl;
      cp0_addr_Whl      <= cp0_addr_Mhl;
      bubble_Whl        <= bubble_next_Mhl;
    end
    `FUNC_UNIT_MUL: begin
      ir_Whl            <= ir_X3hl;
      rf_wen_Whl        <= rf_wen_X3hl;
      rf_waddr_Whl      <= rf_waddr_X3hl;
      rob_fill_slot_Whl <= rob_fill_slot_X3hl;
      cp0_wen_Whl       <= cp0_wen_X3hl;
      cp0_addr_Whl      <= cp0_addr_X3hl;
      bubble_Whl        <= bubble_next_X3hl;
    end
    default: begin
      ir_Whl            <= 32'b0;
      rf_wen_Whl        <= 1'b0;
      rf_waddr_Whl      <= 5'b0;
      rob_fill_slot_Whl <= 5'b0;
      cp0_wen_Whl       <= 1'b0;
      cp0_addr_Whl      <= 5'b0;
      bubble_Whl        <= 1'b1;
    end
    endcase
    dmemresp_queue_val_Mhl <= dmemresp_queue_val_next_Mhl;
  end

  //----------------------------------------------------------------------
  // Writeback Stage
  //----------------------------------------------------------------------

  // Is current stage valid?

  wire inst_val_Whl = ( !bubble_Whl && !squash_Whl );

  // Only set register file wen if stage is valid

  assign rf_wen_out_Whl = ( inst_val_Whl && !stall_Whl && rf_wen_Whl );

  // Dummy squahs and stall signals

  wire squash_Whl = 1'b0;
  wire stall_Whl  = 1'b0;
  
  //----------------------------------------------------------------------
  // Reorder Buffer
  //----------------------------------------------------------------------

  wire rob_req_val_Dhl = inst_val_Dhl && !stall_Dhl && rf_wen_Dhl;
  wire rob_fill_val = inst_val_Whl && rf_wen_Whl;

  wire rob_req_rdy_Dhl;

  wire       rob_fill_wen_Whl = inst_val_Whl && rf_wen_Whl;

  wire [3:0] rob_commit_slot_Chl;
  wire       rob_commit_wen_Chl;
  wire [4:0] rob_commit_waddr_Chl;

 parc_CoreReorderBuffer rob
  (
    .clk                       (clk),
    .reset                     (reset),
    .rob_alloc_req_val         (rob_req_val_Dhl),
    .rob_alloc_req_rdy         (rob_req_rdy_Dhl),
    .rob_alloc_req_preg        (rf_waddr_Dhl),
    .rob_alloc_resp_slot       (rob_fill_slot_Dhl),
    .is_branch_Dhl             (is_branch_Dhl), 
    .branch_true_Xhl           (brj_taken_Xhl), 
    .rob_fill_val              (rob_fill_wen_Whl),
    .rob_fill_slot             (rob_fill_slot_Whl),
    .rob_commit_slot           (rob_commit_slot_Chl),
    .rob_commit_wen            (rob_commit_wen_Chl),
    .rob_commit_rf_waddr       (rob_commit_waddr_Chl)
  );

  //----------------------------------------------------------------------
  // Debug registers for instruction disassembly
  //----------------------------------------------------------------------

  reg [31:0] ir_debug;
  reg        inst_val_debug;

  always @ ( posedge clk ) begin
    ir_debug       <= ir_Whl;
    inst_val_debug <= inst_val_Whl;
  end

  //----------------------------------------------------------------------
  // Coprocessor 0
  //----------------------------------------------------------------------

  reg  [31:0] cp0_status;
  reg         cp0_stats;

  always @ ( posedge clk ) begin
    if ( cp0_wen_Whl && inst_val_Whl ) begin
      case ( cp0_addr_Whl )
        5'd10 : cp0_stats  <= proc2cop_data_Whl[0];
        5'd21 : cp0_status <= proc2cop_data_Whl;
      endcase
    end
  end

//========================================================================
// Disassemble instructions
//========================================================================

  `ifndef SYNTHESIS

  parc_InstMsgDisasm inst_msg_disasm_D
  (
    .msg ( ir_Dhl )
  );

  parc_InstMsgDisasm inst_msg_disasm_X
  (
    .msg ( ir_Xhl )
  );

  parc_InstMsgDisasm inst_msg_disasm_M
  (
    .msg ( ir_Mhl )
  );

  parc_InstMsgDisasm inst_msg_disasm_W
  (
    .msg ( ir_Whl )
  );

  parc_InstMsgDisasm inst_msg_disasm_debug
  (
    .msg ( ir_debug )
  );

  `endif

//========================================================================
// Assertions
//========================================================================
// Detect illegal instructions and terminate the simulation if multiple
// illegal instructions are detected in succession.

  `ifndef SYNTHESIS

  reg overload = 1'b0;

  always @ ( posedge clk ) begin
    if ( !cs[`PARC_INST_MSG_INST_VAL] && !reset ) begin
      $display(" RTL-ERROR : %m : Illegal instruction!");

      if ( overload == 1'b1 ) begin
        $finish;
      end

      overload = 1'b1;
    end
    else begin
      overload = 1'b0;
    end
  end

  `endif

//========================================================================
// Stats
//========================================================================

  `ifndef SYNTHESIS

  reg [31:0] num_inst    = 32'b0;
  reg [31:0] num_cycles  = 32'b0;
  reg        stats_en    = 1'b0; // Used for enabling stats on asm tests

  always @( posedge clk ) begin
    if ( !reset ) begin

      // Count cycles if stats are enabled

      if ( stats_en || cp0_stats ) begin
        num_cycles = num_cycles + 1;

        // Count instructions for every cycle not squashed or stalled

        if ( inst_val_Dhl && !stall_Dhl ) begin
          num_inst = num_inst + 1;
        end

      end

    end
  end

  `endif

endmodule

`endif

