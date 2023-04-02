//========================================================================
// Unit Tests: Instruction Type
//========================================================================

`include "pv2ooo-InstMsg.v"
`include "vc-Test.v"

module tester;
  `VC_TEST_SUITE_BEGIN( "parc-InstMsg" )

  //----------------------------------------------------------------------
  // TestRegRegInstMsg
  //----------------------------------------------------------------------

  reg [`PARC_INST_MSG_SZ-1:0] t1_msg_test;
  reg [`PARC_INST_MSG_SZ-1:0] t1_msg_ref;

  parc_InstMsgDisasm t1_inst_msg_disasm( t1_msg_test );

  task t1_do_test
  (
    input [`PARC_INST_MSG_OPCODE_SZ-1:0] opcode,
    input [    `PARC_INST_MSG_RS_SZ-1:0] rs,
    input [    `PARC_INST_MSG_RT_SZ-1:0] rt,
    input [    `PARC_INST_MSG_RD_SZ-1:0] rd,
    input [ `PARC_INST_MSG_SHAMT_SZ-1:0] shamt,
    input [  `PARC_INST_MSG_FUNC_SZ-1:0] func
  );
  begin

    // Create a wire and set msg fields using `defines

    t1_msg_test[`PARC_INST_MSG_OPCODE] = opcode;
    t1_msg_test[    `PARC_INST_MSG_RS] = rs;
    t1_msg_test[    `PARC_INST_MSG_RT] = rt;
    t1_msg_test[    `PARC_INST_MSG_RD] = rd;
    t1_msg_test[ `PARC_INST_MSG_SHAMT] = shamt;
    t1_msg_test[  `PARC_INST_MSG_FUNC] = func;

    // Create a wire and set msg fields using concatentation

    t1_msg_ref = { opcode, rs, rt, rd, shamt, func };

    // Check that both msgs are the same

    #1;
    `VC_TEST_EQ( t1_inst_msg_disasm.dasm, t1_msg_test, t1_msg_ref )
    #9;
  end
  endtask

  `VC_TEST_CASE_BEGIN( 1, "TestRegRegInstMsg" )
  begin

    t1_do_test( 6'b000000, 5'd2,  5'd3,  5'd4,  5'd0,  6'b100001 ); // ADDU
    t1_do_test( 6'b000000, 5'd0,  5'd9,  5'd20, 5'd16, 6'b000000 ); // SLL
    t1_do_test( 6'b011100, 5'd30, 5'd12, 5'd1,  5'd0,  6'b000010 ); // MUL
    t1_do_test( 6'b000000, 5'd31, 5'd0,  5'd0,  5'd0,  6'b001000 ); // JR

  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // TestRegImmInstMsg
  //----------------------------------------------------------------------

  reg [`PARC_INST_MSG_SZ-1:0] t2_msg_test;
  reg [`PARC_INST_MSG_SZ-1:0] t2_msg_ref;

  parc_InstMsgDisasm t2_inst_msg_disasm( t2_msg_test );

  task t2_do_test
  (
    input [`PARC_INST_MSG_OPCODE_SZ-1:0] opcode,
    input [    `PARC_INST_MSG_RS_SZ-1:0] rs,
    input [    `PARC_INST_MSG_RT_SZ-1:0] rt,
    input [   `PARC_INST_MSG_IMM_SZ-1:0] imm
  );
  begin

    // Create a wire and set msg fields using `defines

    t2_msg_test[`PARC_INST_MSG_OPCODE] = opcode;
    t2_msg_test[    `PARC_INST_MSG_RS] = rs;
    t2_msg_test[    `PARC_INST_MSG_RT] = rt;
    t2_msg_test[   `PARC_INST_MSG_IMM] = imm;

    // Create a wire and set msg fields using concatentation

    t2_msg_ref = { opcode, rs, rt, imm };

    // Check that both msgs are the same

    #1;
    `VC_TEST_EQ( t2_inst_msg_disasm.dasm, t2_msg_test, t2_msg_ref )
    #9;
  end
  endtask

  `VC_TEST_CASE_BEGIN( 2, "TestRegImmInstMsg" )
  begin

    t2_do_test( 6'b001001, 5'd19, 5'd15, 16'h0010 ); // ADDIU
    t2_do_test( 6'b001010, 5'd3,  5'd2,  16'h0a83 ); // SLTI
    t2_do_test( 6'b100001, 5'd30, 5'd12, 16'hffff ); // LH
    t2_do_test( 6'b000101, 5'd10, 5'd28, 16'h0004 ); // BNE

  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // TestTargInstMsg
  //----------------------------------------------------------------------

  reg [`PARC_INST_MSG_SZ-1:0] t3_msg_test;
  reg [`PARC_INST_MSG_SZ-1:0] t3_msg_ref;

  parc_InstMsgDisasm t3_inst_msg_disasm( t3_msg_test );

  task t3_do_test
  (
    input [`PARC_INST_MSG_OPCODE_SZ-1:0] opcode,
    input [`PARC_INST_MSG_TARGET_SZ-1:0] target
  );
  begin

    // Create a wire and set msg fields using `defines

    t3_msg_test[`PARC_INST_MSG_OPCODE] = opcode;
    t3_msg_test[`PARC_INST_MSG_TARGET] = target;

    // Create a wire and set msg fields using concatentation

    t3_msg_ref = { opcode, target };

    // Check that both msgs are the same

    #1;
    `VC_TEST_EQ( t3_inst_msg_disasm.dasm, t3_msg_test, t3_msg_ref )
    #9;
  end
  endtask

  `VC_TEST_CASE_BEGIN( 3, "TestTargInstMsg" )
  begin

    t3_do_test( 6'b000010, 26'h08040fc ); // J
    t3_do_test( 6'b000011, 26'h3fffff0 ); // JAL

  end
  `VC_TEST_CASE_END

  `VC_TEST_SUITE_END( 3 )
endmodule

