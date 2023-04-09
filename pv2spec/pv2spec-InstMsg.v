//========================================================================
// PARC Instruction Type
//========================================================================
// Instruction types are similar to message types but are strictly used
// for communication between the control and datapath of a PARC-based
// processor. Instruction "messages" can be unpacked into the various
// fields as defined by the PARC ISA, as well as be constructed from
// specifying each field explicitly. The 32-bit instruction has different
// fields depending on the format of the instruction used. The following
// are the various instruction encoding formats used in the PARC ISA.
//
// Register-Immediate Arithmetic:
//
//   31  26 25  21 20  16 15                 0
//  +------+------+------+--------------------+
//  |  op  |  rs  |  rt  |         imm        |
//  +------+------+------+--------------------+
//
// Register-Register Arithmetic:
//
//   31  26 25  21 20  16 15  11 10   6 5    0
//  +------+------+------+------+------+------+
//  |  op  |  rs  |  rt  |  rd  |   0  | func |
//  +------+------+------+------+------+------+
//
// Logical Shifts:
//
//   31  26 25  21 20  16 15  11 10   6 5    0
//  +------+------+------+------+------+------+
//  |  op  |   0  |  rt  |  rd  |  sa  | func |
//  +------+------+------+------+------+------+
//
// Memory operations:
//
//   31  26 25  21 20  16 15                 0
//  +------+------+------+--------------------+
//  |  op  | base |  rt  |         imm        |
//  +------+------+------+--------------------+
//
// Branches:
//
//   31  26 25  21 20  16 15                 0
//  +------+------+------+--------------------+
//  |  op  |  rs  |  rt  |       offset       |
//  +------+------+------+--------------------+
//
// Jumps:
//
//   31  26 25                               0
//  +------+----------------------------------+
//  |  op  |             target               |
//  +------+----------------------------------+
//
// Jump Register:
//
//   31  26 25  21 20         11 10   6 5    0
//  +------+------+-------------+------+------+
//  |  op  |  rs  |      0      | hint | func |
//  +------+------+-------------+------+------+
//
// The instruction type also defines a list of instruction encodings in
// the PARC ISA, which are used to decode instructions in the control unit.

`ifndef PARC_INST_MSG_V
`define PARC_INST_MSG_V

//------------------------------------------------------------------------
// Instruction fields
//------------------------------------------------------------------------

`define PARC_INST_MSG_OPCODE    31:26
`define PARC_INST_MSG_RS        25:21
`define PARC_INST_MSG_RT        20:16
`define PARC_INST_MSG_RD        15:11
`define PARC_INST_MSG_SHAMT     10:6
`define PARC_INST_MSG_FUNC      5:0
`define PARC_INST_MSG_IMM       15:0
`define PARC_INST_MSG_IMM_SIGN  15
`define PARC_INST_MSG_TARGET    25:0

//------------------------------------------------------------------------
// Field sizes
//------------------------------------------------------------------------

`define PARC_INST_MSG_SZ          32

`define PARC_INST_MSG_OPCODE_SZ   6
`define PARC_INST_MSG_RS_SZ       5
`define PARC_INST_MSG_RT_SZ       5
`define PARC_INST_MSG_RD_SZ       5
`define PARC_INST_MSG_SHAMT_SZ    5
`define PARC_INST_MSG_FUNC_SZ     6
`define PARC_INST_MSG_IMM_SZ      16
`define PARC_INST_MSG_IMM_SIGN_SZ 1
`define PARC_INST_MSG_TARGET_SZ   26

//------------------------------------------------------------------------
// Instruction opcodes
//------------------------------------------------------------------------

`define PARC_INST_MSG_NOP     32'b000000_00000_00000_00000_00000_000000
`define PARC_INST_MSG_SYSCALL 32'b000000_?????_?????_?????_?????_001100
`define PARC_INST_MSG_ERET    32'b010000_10000_00000_00000_00000_011000
`define PARC_INST_MSG_ADDIU   32'b001001_?????_?????_?????_?????_??????
`define PARC_INST_MSG_SLTI    32'b001010_?????_?????_?????_?????_??????
`define PARC_INST_MSG_SLTIU   32'b001011_?????_?????_?????_?????_??????
`define PARC_INST_MSG_ANDI    32'b001100_?????_?????_?????_?????_??????
`define PARC_INST_MSG_ORI     32'b001101_?????_?????_?????_?????_??????
`define PARC_INST_MSG_XORI    32'b001110_?????_?????_?????_?????_??????
`define PARC_INST_MSG_LUI     32'b001111_00000_?????_?????_?????_??????
`define PARC_INST_MSG_SLL     32'b000000_00000_?????_?????_?????_000000
`define PARC_INST_MSG_SRL     32'b000000_00000_?????_?????_?????_000010
`define PARC_INST_MSG_SRA     32'b000000_00000_?????_?????_?????_000011
`define PARC_INST_MSG_SLLV    32'b000000_?????_?????_?????_00000_000100
`define PARC_INST_MSG_SRLV    32'b000000_?????_?????_?????_00000_000110
`define PARC_INST_MSG_SRAV    32'b000000_?????_?????_?????_00000_000111
`define PARC_INST_MSG_ADDU    32'b000000_?????_?????_?????_00000_100001
`define PARC_INST_MSG_SUBU    32'b000000_?????_?????_?????_00000_100011
`define PARC_INST_MSG_AND     32'b000000_?????_?????_?????_00000_100100
`define PARC_INST_MSG_OR      32'b000000_?????_?????_?????_00000_100101
`define PARC_INST_MSG_XOR     32'b000000_?????_?????_?????_00000_100110
`define PARC_INST_MSG_NOR     32'b000000_?????_?????_?????_00000_100111
`define PARC_INST_MSG_SLT     32'b000000_?????_?????_?????_00000_101010
`define PARC_INST_MSG_SLTU    32'b000000_?????_?????_?????_00000_101011
`define PARC_INST_MSG_MUL     32'b011100_?????_?????_?????_00000_000010
`define PARC_INST_MSG_DIV     32'b100111_?????_?????_?????_00000_000101
`define PARC_INST_MSG_DIVU    32'b100111_?????_?????_?????_00000_000111
`define PARC_INST_MSG_REM     32'b100111_?????_?????_?????_00000_000110
`define PARC_INST_MSG_REMU    32'b100111_?????_?????_?????_00000_001000
`define PARC_INST_MSG_LW      32'b100011_?????_?????_?????_?????_??????
`define PARC_INST_MSG_LH      32'b100001_?????_?????_?????_?????_??????
`define PARC_INST_MSG_LHU     32'b100101_?????_?????_?????_?????_??????
`define PARC_INST_MSG_LB      32'b100000_?????_?????_?????_?????_??????
`define PARC_INST_MSG_LBU     32'b100100_?????_?????_?????_?????_??????
`define PARC_INST_MSG_SW      32'b101011_?????_?????_?????_?????_??????
`define PARC_INST_MSG_SH      32'b101001_?????_?????_?????_?????_??????
`define PARC_INST_MSG_SB      32'b101000_?????_?????_?????_?????_??????
`define PARC_INST_MSG_J       32'b000010_?????_?????_?????_?????_??????
`define PARC_INST_MSG_JAL     32'b000011_?????_?????_?????_?????_??????
`define PARC_INST_MSG_JR      32'b000000_?????_00000_00000_00000_001000
`define PARC_INST_MSG_JALR    32'b000000_?????_00000_?????_00000_001001
`define PARC_INST_MSG_BEQ     32'b000100_?????_?????_?????_?????_??????
`define PARC_INST_MSG_BNE     32'b000101_?????_?????_?????_?????_??????
`define PARC_INST_MSG_BLEZ    32'b000110_?????_00000_?????_?????_??????
`define PARC_INST_MSG_BGTZ    32'b000111_?????_00000_?????_?????_??????
`define PARC_INST_MSG_BLTZ    32'b000001_?????_00000_?????_?????_??????
`define PARC_INST_MSG_BGEZ    32'b000001_?????_00001_?????_?????_??????
`define PARC_INST_MSG_MFC0    32'b010000_00000_?????_?????_00000_000000
`define PARC_INST_MSG_MTC0    32'b010000_00100_?????_?????_00000_000000

//------------------------------------------------------------------------
// Control bundle
//------------------------------------------------------------------------

`define PARC_INST_MSG_INST_VAL   38
`define PARC_INST_MSG_J_EN       37
`define PARC_INST_MSG_BR_SEL     36:34
`define PARC_INST_MSG_PC_SEL     33:32
`define PARC_INST_MSG_OP0_SEL    31:30
`define PARC_INST_MSG_RS_EN      29
`define PARC_INST_MSG_OP1_SEL    28:26
`define PARC_INST_MSG_RT_EN      25
`define PARC_INST_MSG_ALU_FN     24:21
`define PARC_INST_MSG_MULDIV_FN  20:18
`define PARC_INST_MSG_MULDIV_EN  17
`define PARC_INST_MSG_MULDIV_SEL 16
`define PARC_INST_MSG_EX_SEL     15
`define PARC_INST_MSG_MEM_REQ    14:13
`define PARC_INST_MSG_MEM_LEN    12:11
`define PARC_INST_MSG_MEM_SEL    10:8
`define PARC_INST_MSG_WB_SEL     7
`define PARC_INST_MSG_RF_WEN     6
`define PARC_INST_MSG_RF_WADDR   5:1
`define PARC_INST_MSG_CP0_WEN    0

//------------------------------------------------------------------------
// Convert message to bits
//------------------------------------------------------------------------

module parc_RegRegInstMsgToBits
(
  // Input message

  input [`PARC_INST_MSG_OPCODE_SZ-1:0] opcode,
  input [    `PARC_INST_MSG_RS_SZ-1:0] rs,
  input [    `PARC_INST_MSG_RT_SZ-1:0] rt,
  input [    `PARC_INST_MSG_RD_SZ-1:0] rd,
  input [ `PARC_INST_MSG_SHAMT_SZ-1:0] shamt,
  input [  `PARC_INST_MSG_FUNC_SZ-1:0] func,

  // Output message

  output [`PARC_INST_MSG_SZ-1:0] msg
);

  assign msg[`PARC_INST_MSG_OPCODE] = opcode;
  assign msg[    `PARC_INST_MSG_RS] = rs;
  assign msg[    `PARC_INST_MSG_RT] = rt;
  assign msg[    `PARC_INST_MSG_RD] = rd;
  assign msg[ `PARC_INST_MSG_SHAMT] = shamt;
  assign msg[  `PARC_INST_MSG_FUNC] = func;

endmodule

module parc_RegImmInstMsgToBits
(
  // Input message

  input [`PARC_INST_MSG_OPCODE_SZ-1:0] opcode,
  input [    `PARC_INST_MSG_RS_SZ-1:0] rs,
  input [    `PARC_INST_MSG_RT_SZ-1:0] rt,
  input [   `PARC_INST_MSG_IMM_SZ-1:0] imm,

  // Output message

  output [`PARC_INST_MSG_SZ-1:0] msg
);

  assign msg[`PARC_INST_MSG_OPCODE] = opcode;
  assign msg[    `PARC_INST_MSG_RS] = rs;
  assign msg[    `PARC_INST_MSG_RT] = rt;
  assign msg[   `PARC_INST_MSG_IMM] = imm;

endmodule

module parc_TargInstMsgToBits
(
  // Input message

  input [`PARC_INST_MSG_OPCODE_SZ-1:0] opcode,
  input [`PARC_INST_MSG_TARGET_SZ-1:0] target,

  // Output message

  output [`PARC_INST_MSG_SZ-1:0] msg
);

  assign msg[`PARC_INST_MSG_OPCODE] = opcode;
  assign msg[`PARC_INST_MSG_TARGET] = target;

endmodule

//------------------------------------------------------------------------
// Convert message from bits
//------------------------------------------------------------------------

module parc_InstMsgFromBits
(
  // Input message

  input [`PARC_INST_MSG_SZ-1:0] msg,

  // Output message

  output [  `PARC_INST_MSG_OPCODE_SZ-1:0] opcode,
  output [      `PARC_INST_MSG_RS_SZ-1:0] rs,
  output [      `PARC_INST_MSG_RT_SZ-1:0] rt,
  output [      `PARC_INST_MSG_RD_SZ-1:0] rd,
  output [   `PARC_INST_MSG_SHAMT_SZ-1:0] shamt,
  output [    `PARC_INST_MSG_FUNC_SZ-1:0] func,
  output [     `PARC_INST_MSG_IMM_SZ-1:0] imm,
  output [`PARC_INST_MSG_IMM_SIGN_SZ-1:0] imm_sign,
  output [  `PARC_INST_MSG_TARGET_SZ-1:0] target

);

  assign opcode   = msg[  `PARC_INST_MSG_OPCODE];
  assign rs       = msg[      `PARC_INST_MSG_RS];
  assign rt       = msg[      `PARC_INST_MSG_RT];
  assign rd       = msg[      `PARC_INST_MSG_RD];
  assign shamt    = msg[   `PARC_INST_MSG_SHAMT];
  assign func     = msg[    `PARC_INST_MSG_FUNC];
  assign imm      = msg[     `PARC_INST_MSG_IMM];
  assign imm_sign = msg[`PARC_INST_MSG_IMM_SIGN];
  assign target   = msg[  `PARC_INST_MSG_TARGET];

endmodule

//------------------------------------------------------------------------
// Instruction disassembly
//------------------------------------------------------------------------

`ifndef SYNTHESIS
module parc_InstMsgDisasm
(
  input [`PARC_INST_MSG_SZ-1:0] msg
);

  // Extract fields

  wire [`PARC_INST_MSG_OPCODE_SZ-1:0] opcode;
  wire [    `PARC_INST_MSG_RS_SZ-1:0] rs;
  wire [    `PARC_INST_MSG_RT_SZ-1:0] rt;
  wire [    `PARC_INST_MSG_RD_SZ-1:0] rd;
  wire [ `PARC_INST_MSG_SHAMT_SZ-1:0] shamt;
  wire [  `PARC_INST_MSG_FUNC_SZ-1:0] func;
  wire [   `PARC_INST_MSG_IMM_SZ-1:0] imm;
  wire [`PARC_INST_MSG_TARGET_SZ-1:0] target;

  parc_InstMsgFromBits inst_msg_from_bits
  (
    .msg    (msg),
    .opcode (opcode),
    .rs     (rs),
    .rt     (rt),
    .rd     (rd),
    .shamt  (shamt),
    .func   (func),
    .imm    (imm),
    .target (target)
  );

  reg [167:0] dasm;

  always @ ( * ) begin

    if ( msg === 32'bx ) begin
      $sformat( dasm, "x                    " );
    end
    else begin

      casez ( msg )
        `PARC_INST_MSG_NOP     : $sformat( dasm, "nop                  "                 );
        `PARC_INST_MSG_SYSCALL : $sformat( dasm, "syscall              "                 );
        `PARC_INST_MSG_ERET    : $sformat( dasm, "eret                 "                 );
        `PARC_INST_MSG_ADDIU   : $sformat( dasm, "addiu r%d, r%d, %x ",   rt, rs,  imm   );
        `PARC_INST_MSG_SLTI    : $sformat( dasm, "slti  r%d, r%d, %x ",   rt, rs,  imm   );
        `PARC_INST_MSG_SLTIU   : $sformat( dasm, "sltiu r%d, r%d, %x ",   rt, rs,  imm   );
        `PARC_INST_MSG_ANDI    : $sformat( dasm, "andi  r%d, r%d, %x ",   rt, rs,  imm   );
        `PARC_INST_MSG_ORI     : $sformat( dasm, "ori   r%d, r%d, %x ",   rt, rs,  imm   );
        `PARC_INST_MSG_XORI    : $sformat( dasm, "xori  r%d, r%d, %x ",   rt, rs,  imm   );
        `PARC_INST_MSG_LUI     : $sformat( dasm, "lui   r%d, %x      ",   rt, imm        );
        `PARC_INST_MSG_SLL     : $sformat( dasm, "sll   r%d, r%d, %x   ", rt, rt,  shamt );
        `PARC_INST_MSG_SRL     : $sformat( dasm, "srl   r%d, r%d, %x   ", rd, rt,  shamt );
        `PARC_INST_MSG_SRA     : $sformat( dasm, "sra   r%d, r%d, %x   ", rd, rt,  shamt );
        `PARC_INST_MSG_SLLV    : $sformat( dasm, "sllv  r%d, r%d, r%d  ", rd, rt,  rs    );
        `PARC_INST_MSG_SRLV    : $sformat( dasm, "srlv  r%d, r%d, r%d  ", rd, rt,  rs    );
        `PARC_INST_MSG_SRAV    : $sformat( dasm, "srav  r%d, r%d, r%d  ", rd, rt,  rs    );
        `PARC_INST_MSG_ADDU    : $sformat( dasm, "addu  r%d, r%d, r%d  ", rd, rt,  rs    );
        `PARC_INST_MSG_SUBU    : $sformat( dasm, "subu  r%d, r%d, r%d  ", rd, rt,  rs    );
        `PARC_INST_MSG_AND     : $sformat( dasm, "and   r%d, r%d, r%d  ", rd, rt,  rs    );
        `PARC_INST_MSG_OR      : $sformat( dasm, "or    r%d, r%d, r%d  ", rd, rt,  rs    );
        `PARC_INST_MSG_XOR     : $sformat( dasm, "xor   r%d, r%d, r%d  ", rd, rt,  rs    );
        `PARC_INST_MSG_NOR     : $sformat( dasm, "nor   r%d, r%d, r%d  ", rd, rt,  rs    );
        `PARC_INST_MSG_SLT     : $sformat( dasm, "slt   r%d, r%d, r%d  ", rd, rt,  rs    );
        `PARC_INST_MSG_SLTU    : $sformat( dasm, "sltu  r%d, r%d, r%d  ", rd, rt,  rs    );
        `PARC_INST_MSG_MUL     : $sformat( dasm, "mul   r%d, r%d, r%d  ", rd, rt,  rs    );
        `PARC_INST_MSG_DIV     : $sformat( dasm, "div   r%d, r%d, r%d  ", rd, rt,  rs    );
        `PARC_INST_MSG_DIVU    : $sformat( dasm, "divu  r%d, r%d, r%d  ", rd, rt,  rs    );
        `PARC_INST_MSG_REM     : $sformat( dasm, "rem   r%d, r%d, r%d  ", rd, rt,  rs    );
        `PARC_INST_MSG_REMU    : $sformat( dasm, "remu  r%d, r%d, r%d  ", rd, rt,  rs    );
        `PARC_INST_MSG_LW      : $sformat( dasm, "lw    r%d, %x(r%d) ",   rt, imm, rs    );
        `PARC_INST_MSG_LH      : $sformat( dasm, "lh    r%d, %x(r%d) ",   rt, imm, rs    );
        `PARC_INST_MSG_LHU     : $sformat( dasm, "lhu   r%d, %x(r%d) ",   rt, imm, rs    );
        `PARC_INST_MSG_LB      : $sformat( dasm, "lb    r%d, %x(r%d) ",   rt, imm, rs    );
        `PARC_INST_MSG_LBU     : $sformat( dasm, "lbu   r%d, %x(r%d) ",   rt, imm, rs    );
        `PARC_INST_MSG_SW      : $sformat( dasm, "sw    r%d, %x(r%d) ",   rt, imm, rs    );
        `PARC_INST_MSG_SH      : $sformat( dasm, "sh    r%d, %x(r%d) ",   rt, imm, rs    );
        `PARC_INST_MSG_SB      : $sformat( dasm, "sb    r%d, %x(r%d) ",   rt, imm, rs    );
        `PARC_INST_MSG_J       : $sformat( dasm, "j     %x        ",      target         );
        `PARC_INST_MSG_JAL     : $sformat( dasm, "jal   %x        ",      target         );
        `PARC_INST_MSG_JR      : $sformat( dasm, "jr    r%d            ", rs             );
        `PARC_INST_MSG_JALR    : $sformat( dasm, "jalr  r%d, r%d       ", rd, rs         );
        `PARC_INST_MSG_BEQ     : $sformat( dasm, "beq   r%d, r%d, %x ",   rs, rt,  imm   );
        `PARC_INST_MSG_BNE     : $sformat( dasm, "bne   r%d, r%d, %x ",   rs, rt,  imm   );
        `PARC_INST_MSG_BLEZ    : $sformat( dasm, "blez  r%d, %x      ",   rs, imm        );
        `PARC_INST_MSG_BGTZ    : $sformat( dasm, "bgtz  r%d, %x      ",   rs, imm        );
        `PARC_INST_MSG_BLTZ    : $sformat( dasm, "bltz  r%d, %x      ",   rs, imm        );
        `PARC_INST_MSG_BGEZ    : $sformat( dasm, "bgez  r%d, %x      ",   rs, imm        );
        `PARC_INST_MSG_MFC0    : $sformat( dasm, "mfc0  r%d, r%d       ", rt, rd         );
        `PARC_INST_MSG_MTC0    : $sformat( dasm, "mtc0  r%d, r%d       ", rt, rd         );
        default                : $sformat( dasm, "undefined inst       " );
      endcase

    end

  end

  reg [40:0] minidasm;

  always @ ( * )
  begin

    if ( msg === 32'bx )
      $sformat( minidasm, "x    " );
    else
    begin

      casez ( msg )
        `PARC_INST_MSG_NOP     : $sformat( minidasm, "nop  ");
        `PARC_INST_MSG_SYSCALL : $sformat( minidasm, "syscl");
        `PARC_INST_MSG_ERET    : $sformat( minidasm, "eret ");
        `PARC_INST_MSG_ADDIU   : $sformat( minidasm, "addiu");
        `PARC_INST_MSG_SLTI    : $sformat( minidasm, "slti ");
        `PARC_INST_MSG_SLTIU   : $sformat( minidasm, "sltiu");
        `PARC_INST_MSG_ANDI    : $sformat( minidasm, "andi ");
        `PARC_INST_MSG_ORI     : $sformat( minidasm, "ori  ");
        `PARC_INST_MSG_XORI    : $sformat( minidasm, "xori ");
        `PARC_INST_MSG_LUI     : $sformat( minidasm, "lui  ");
        `PARC_INST_MSG_SLL     : $sformat( minidasm, "sll  ");
        `PARC_INST_MSG_SRL     : $sformat( minidasm, "srl  ");
        `PARC_INST_MSG_SRA     : $sformat( minidasm, "sra  ");
        `PARC_INST_MSG_SLLV    : $sformat( minidasm, "sllv ");
        `PARC_INST_MSG_SRLV    : $sformat( minidasm, "srlv ");
        `PARC_INST_MSG_SRAV    : $sformat( minidasm, "srav ");
        `PARC_INST_MSG_ADDU    : $sformat( minidasm, "addu ");
        `PARC_INST_MSG_SUBU    : $sformat( minidasm, "subu ");
        `PARC_INST_MSG_AND     : $sformat( minidasm, "and  ");
        `PARC_INST_MSG_OR      : $sformat( minidasm, "or   ");
        `PARC_INST_MSG_XOR     : $sformat( minidasm, "xor  ");
        `PARC_INST_MSG_NOR     : $sformat( minidasm, "nor  ");
        `PARC_INST_MSG_SLT     : $sformat( minidasm, "slt  ");
        `PARC_INST_MSG_SLTU    : $sformat( minidasm, "sltu ");
        `PARC_INST_MSG_MUL     : $sformat( minidasm, "mul  ");
        `PARC_INST_MSG_DIV     : $sformat( minidasm, "div  ");
        `PARC_INST_MSG_DIVU    : $sformat( minidasm, "divu ");
        `PARC_INST_MSG_REM     : $sformat( minidasm, "rem  ");
        `PARC_INST_MSG_REMU    : $sformat( minidasm, "remu ");
        `PARC_INST_MSG_LW      : $sformat( minidasm, "lw   ");
        `PARC_INST_MSG_LH      : $sformat( minidasm, "lh   ");
        `PARC_INST_MSG_LHU     : $sformat( minidasm, "lhu  ");
        `PARC_INST_MSG_LB      : $sformat( minidasm, "lb   ");
        `PARC_INST_MSG_LBU     : $sformat( minidasm, "lbu  ");
        `PARC_INST_MSG_SW      : $sformat( minidasm, "sw   ");
        `PARC_INST_MSG_SH      : $sformat( minidasm, "sh   ");
        `PARC_INST_MSG_SB      : $sformat( minidasm, "sb   ");
        `PARC_INST_MSG_J       : $sformat( minidasm, "j    ");
        `PARC_INST_MSG_JAL     : $sformat( minidasm, "jal  ");
        `PARC_INST_MSG_JR      : $sformat( minidasm, "jr   ");
        `PARC_INST_MSG_JALR    : $sformat( minidasm, "jalr ");
        `PARC_INST_MSG_BEQ     : $sformat( minidasm, "beq  ");
        `PARC_INST_MSG_BNE     : $sformat( minidasm, "bne  ");
        `PARC_INST_MSG_BLEZ    : $sformat( minidasm, "blez ");
        `PARC_INST_MSG_BGTZ    : $sformat( minidasm, "bgtz ");
        `PARC_INST_MSG_BLTZ    : $sformat( minidasm, "bltz ");
        `PARC_INST_MSG_BGEZ    : $sformat( minidasm, "bgez ");
        `PARC_INST_MSG_MFC0    : $sformat( minidasm, "mfc0 ");
        `PARC_INST_MSG_MTC0    : $sformat( minidasm, "mtc0 ");
        default                : $sformat( minidasm, "undef");
      endcase

    end

  end

endmodule
`endif

`endif

