//=========================================================================
// 5-Stage PARC Scoreboard
//=========================================================================

`ifndef PARC_CORE_SCOREBOARD_V
`define PARC_CORE_SCOREBOARD_V

`define FUNC_UNIT_ALU 1
`define FUNC_UNIT_MEM 2
`define FUNC_UNIT_MUL 3

module parc_CoreScoreboard
(
  input         clk,
  input         reset,
  input  [ 4:0] src0,             // Source register 0
  input         src0_en,          // Use source register 0
  input  [ 4:0] src1,             // Source register 1
  input         src1_en,          // Use source register 1
  input  [ 4:0] dst,              // Destination register
  input         dst_en,           // Write to destination register
  input  [ 2:0] func_unit,        // Functional Unit
  input  [ 5:0] latency,          // Instruction latency (one-hot)
  input         inst_val_Dhl,     // Instruction valid
  input         non_sb_stall_Dhl, // Decode stall

  input  [ 3:0] rob_alloc_slot,   // ROB slot allocated to dst reg
  input  [ 3:0] rob_commit_slot,  // ROB slot emptied during commit
  input         rob_commit_wen,   // ROB slot emptied during commit

  input  [ 5:0] stalls,           // Input stall signals

  output [ 2:0] src0_byp_mux_sel, // Source reg 0 byp mux
  output [ 3:0] src0_byp_rob_slot,// Source reg 0 ROB slot
  output [ 2:0] src1_byp_mux_sel, // Source reg 1 byp mux
  output [ 3:0] src1_byp_rob_slot,// Source reg 1 ROB slot

  output        stall_hazard,     // Destination register ready
  output [ 1:0] wb_mux_sel,        // Writeback mux sel out

  input is_branch_Ihl, 
  // //Have a speculation register in the Decode stage that tells us whether or not the next instruciton is speculative
  // //Basically if a branch is seen in DHL this should be true.  
  // //Have feedback, if the curr Xhl instruciton is a branch, then mark the previous speculative instruction as invalid
  input branch_true_Xhl
);

  reg       pending          [31:0];
  reg [2:0] functional_unit  [31:0];
  reg [5:0] reg_latency      [31:0];
  reg [3:0] reg_rob_slot     [31:0];

  reg [5:0] wb_alu_latency;
  reg [5:0] wb_mem_latency;
  reg [5:0] wb_mul_latency;

  //BEGIN CODE FOR BYPASS SQUASHING :)_0000A0DWA
  reg       speculative          [31:0];
  reg       spec;
  reg       branch_true;
  reg  [ 4:0] prev;   
  integer i;
  always @(posedge clk)begin

    //if branch is taken, squash spec instruction
    if(branch_true_Xhl && speculative[prev] == 1'b1)begin

        reg_latency[prev]     <= 6'b0;
        pending[prev]         <= 1'b0;
        functional_unit[prev] <= 3'b0; 
        speculative[prev] <= 1'b0; 

    end else begin
      speculative[prev] <= 1'b0;
      prev <= 5'b0;
    end
    
    //if next instruction is a branch, tag curr as spec instruciton
    if(is_branch_Ihl)begin
      speculative[dst] <= 1'b1;
      prev <= dst;
    end

  end



  //END

  // Store ROB slots (for bypassing)

  always @(posedge clk) begin
    if( accept ) begin
      reg_rob_slot[dst] <= rob_alloc_slot;
    end
  end

  wire src0_byp_rob_slot = reg_rob_slot[src0];
  wire src1_byp_rob_slot = reg_rob_slot[src1];

  // Check if src registers are ready

  wire src0_can_byp = pending[src0] && (reg_latency[src0] < 6'b000100);
  wire src1_can_byp = pending[src1] && (reg_latency[src1] < 6'b000100);

  wire src0_ok = !pending[src0] || src0_can_byp || !src0_en;
  wire src1_ok = !pending[src1] || src1_can_byp || !src1_en;

  reg [2:0] src0_byp_mux_sel;
  reg [2:0] src1_byp_mux_sel;

  always @(*) begin
    if (!pending[src0] || src0 == 6'b0)
      src0_byp_mux_sel = 3'b0;
    else if (reg_latency[src0] == 6'b000001)
      src0_byp_mux_sel = 3'd4;
    else if (reg_latency[src0] == 6'b000000)
      src0_byp_mux_sel = 3'd5; // UNCOMMENT THIS WHEN YOUR ROB IS READY!
      //src0_byp_mux_sel = 3'd0;   // DELETE THIS WHEN YOUR ROB IS READY!
    else
      src0_byp_mux_sel = functional_unit[src0];
  end

  always @(*) begin
    if (!pending[src1] || src1 == 6'b0)
      src1_byp_mux_sel = 3'b0;
    else if (reg_latency[src1] == 6'b000001)
      src1_byp_mux_sel = 3'd4;
    else if (reg_latency[src1] == 6'b000000)
      src1_byp_mux_sel = 3'd5; // UNCOMMENT THIS WHEN YOUR ROB IS READY!
      //src1_byp_mux_sel = 3'd0;   // DELETE THIS WHEN YOUR ROB IS READY!
    else
      src1_byp_mux_sel = functional_unit[src1];
  end

  // Check for hazards

  wire stall_wb_hazard =
    ((wb_alu_latency >> 1) & latency) > 6'b0 ? 1'b1 :
    ((wb_mem_latency >> 1) & latency) > 6'b0 ? 1'b1 :
    ((wb_mul_latency >> 1) & latency) > 6'b0 ? 1'b1 : 1'b0;

  wire accept =
    src0_ok && src1_ok && !stall_wb_hazard && inst_val_Dhl && !non_sb_stall_Dhl;

  wire stall_hazard = ~accept;
  
  // Advance one cycle
  
  genvar r;
  generate
  for( r = 0; r < 32; r = r + 1)
  begin: sb_entry
    always @(posedge clk) begin
      if (reset) begin
        reg_latency[r]     <= 6'b0;
        pending[r]         <= 1'b0;
        functional_unit[r] <= 3'b0; 
      end else if ( accept && (r == dst) ) begin
        reg_latency[r]     <= latency;
        pending[r]         <= 1'b1;
        functional_unit[r] <= func_unit;
      end else begin
        reg_latency[r]     <= 
          (reg_latency[r] & stalls) | 
          ((reg_latency[r] & ~stalls) >> 1);
        pending[r]         <= pending[r] &&
          !(rob_commit_wen && rob_commit_slot == reg_rob_slot[r]);
      end
    end
  end
  endgenerate

  // ALU Latency 

  always @(posedge clk) begin
    if (reset) begin
      wb_alu_latency <= 6'b0;
    end else if (accept && (func_unit == 2'd1)) begin
      wb_alu_latency <= 
        (wb_alu_latency & stalls) |
        ((wb_alu_latency & ~stalls) >> 1) |
        latency;
    end else begin
      wb_alu_latency <= 
        (wb_alu_latency & stalls) |
        ((wb_alu_latency & ~stalls) >> 1);
    end
  end

  // MEM Latency 

  always @(posedge clk) begin
    if (reset) begin
      wb_mem_latency <= 6'b0;
    end else if (accept && (func_unit == 2'd2)) begin
      wb_mem_latency <= 
        (wb_mem_latency & stalls) |
        ((wb_mem_latency & ~stalls) >> 1) |
        latency;
    end else begin
      wb_mem_latency <= 
        (wb_mem_latency & stalls) |
        ((wb_mem_latency & ~stalls) >> 1);
    end
  end

  // MUL Latency 

  always @(posedge clk) begin
    if (reset) begin
      wb_mul_latency <= 6'b0;
    end else if (accept && (func_unit == 2'd3)) begin
      wb_mul_latency <= 
        (wb_mul_latency & stalls) |
        ((wb_mul_latency & ~stalls) >> 1) |
        latency;
    end else begin
      wb_mul_latency <= 
        (wb_mul_latency & stalls) |
        ((wb_mul_latency & ~stalls) >> 1);
    end
  end

  wire wb_mux_sel = (wb_alu_latency & 6'b10) ? 2'd1 :
                    (wb_mem_latency & 6'b10) ? 2'd2 :
                    (wb_mul_latency & 6'b10) ? 2'd3 : 2'd0;

endmodule

`endif

