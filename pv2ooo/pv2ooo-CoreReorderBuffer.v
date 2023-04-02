//=========================================================================
// 5-Stage PARC Scoreboard
//=========================================================================

`ifndef PARC_CORE_REORDERBUFFER_V
`define PARC_CORE_REORDERBUFFER_V

module parc_CoreReorderBuffer
(
  input         clk,
  input         reset,

  input         rob_alloc_req_val,
  output        rob_alloc_req_rdy,
  input  [ 4:0] rob_alloc_req_preg,
  
  output [ 3:0] rob_alloc_resp_slot,

  input         rob_fill_val,
  input  [ 3:0] rob_fill_slot,

  output        rob_commit_wen,
  output [ 3:0] rob_commit_slot,
  output [ 4:0] rob_commit_rf_waddr
);

  wire rob_alloc_req_rdy   = 1'b1;
  wire rob_alloc_resp_slot = 4'b0;
  wire rob_commit_wen      = 1'b0;
  wire rob_commit_rf_waddr = 1'b0;
  wire rob_commit_slot     = 4'b0;
  
endmodule

`endif

