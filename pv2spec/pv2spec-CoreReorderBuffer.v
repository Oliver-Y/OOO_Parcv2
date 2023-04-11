//=========================================================================
// 5-Stage PARC Scoreboard
//=========================================================================

`ifndef PARC_CORE_REORDERBUFFER_V
`define PARC_CORE_REORDERBUFFER_V

module parc_CoreReorderBuffer
(
  input         clk,
  input         reset,

  input         rob_alloc_req_val,  //is alloc request valid?
  output        rob_alloc_req_rdy,  //we signal that we are ready to allocate
  input  [ 4:0] rob_alloc_req_preg, //tells us how to set destination reg
  input is_branch_Dhl, 
  // //Have a speculation register in the Decode stage that tells us whether or not the next instruciton is speculative
  // //Basically if a branch is seen in DHL this should be true.  
  // //Have feedback, if the curr Xhl instruciton is a branch, then mark the previous speculative instruction as invalid
  input branch_true_Xhl, 
  output [ 3:0] rob_alloc_resp_slot, //we output where we allocated, should be tied to when we signal we are ready to allocate. 

  input         rob_fill_val,        // we are filling 
  input  [ 3:0] rob_fill_slot,       //pending bit goes low 

  output        rob_commit_wen,      //tied to !pending && valid on head ptr?
  output [ 3:0] rob_commit_slot,     //tied to head ptr
  output [ 4:0] rob_commit_rf_waddr  //tied to dest register on head ptr 
);


  reg [4:0] head_ptr = 0;
  reg [4:0] tail_ptr = 0;  
  
  //Turn this on when we begin to speculate
  reg spec = 0; 
  reg branch_true = 0; 

  reg rob_alloc_req_rdy_reg;

  reg [3:0] rob_alloc_resp_slot_reg;

  reg rob_commit_wen_reg;
  reg [ 3:0] rob_commit_slot_reg;
  reg [ 4:0] rob_commit_rf_waddr_reg;

  localparam VALID = 0; 
  localparam PENDING = 1; 
  localparam SPEC = 2; 

  reg [7:0] rob [0:15];

  integer i;
  initial begin
    for(i = 0; i < 16; i+=1) begin
        rob[i] <= {1'b0, 1'b0, 1'b0, 5'b0};
    end
  end

  //Debug Wires 
  wire[7:0] rob_0 ={rob[0][VALID],rob[0][PENDING],rob[0][SPEC], rob[0][7:3]};
  wire[7:0] rob_1 ={rob[1][VALID],rob[1][PENDING],rob[1][SPEC], rob[1][7:3]};
  wire[7:0] rob_2 ={rob[2][VALID],rob[2][PENDING],rob[2][SPEC], rob[2][7:3]};
  wire[7:0] rob_3 ={rob[3][VALID],rob[3][PENDING],rob[3][SPEC], rob[3][7:3]};
  wire[7:0] rob_4 ={rob[4][VALID],rob[4][PENDING],rob[4][SPEC], rob[4][7:3]};
  wire[7:0] rob_5 ={rob[5][VALID],rob[5][PENDING],rob[5][SPEC], rob[5][7:3]};
  wire[7:0] rob_6 ={rob[6][VALID],rob[6][PENDING],rob[6][SPEC], rob[6][7:3]};
  wire[7:0] rob_7 ={rob[7][VALID],rob[7][PENDING],rob[7][SPEC], rob[7][7:3]};
  wire[7:0] rob_8 ={rob[8][VALID],rob[8][PENDING],rob[8][SPEC], rob[8][7:3]};
  wire[7:0] rob_9 ={rob[9][VALID],rob[9][PENDING],rob[9][SPEC], rob[9][7:3]};
  wire[7:0] rob_10 ={rob[10][VALID],rob[10][PENDING],rob[10][SPEC], rob[10][7:3]};
  wire[7:0] rob_11 ={rob[11][VALID],rob[11][PENDING],rob[11][SPEC], rob[11][7:3]};
  wire[7:0] rob_12 ={rob[12][VALID],rob[12][PENDING],rob[12][SPEC], rob[12][7:3]};
  wire[7:0] rob_13 ={rob[13][VALID],rob[13][PENDING],rob[13][SPEC], rob[13][7:3]};
  wire[7:0] rob_14 ={rob[14][VALID],rob[14][PENDING],rob[14][SPEC], rob[14][7:3]};
  wire[7:0] rob_15 ={rob[15][VALID],rob[15][PENDING],rob[15][SPEC], rob[15][7:3]};


  //These will also potentially be late by one cycle?
  //Placeholder wire 
  //Oh we need this to start out as 1 or else it wo'nt k now that we're ready?
  wire is_full = alloc_count >= 16 ? 1 : 0; 
  assign rob_alloc_req_rdy = !is_full; 
  assign rob_alloc_resp_slot = tail_ptr; 
  assign rob_commit_wen = rob[head_ptr][VALID] && !rob[head_ptr][PENDING];
  assign rob_commit_slot = head_ptr; //TODO: shouldn't this just be tied to the head ptr?
  assign rob_commit_rf_waddr = rob[head_ptr][7:3]; //No need for reg as well should just be tied to head ptr. 
  wire [4:0] prev = (tail_ptr -1) % 16; 

  reg [5:0] alloc_count = 0;

  always @(posedge clk)begin
    //begin allocation. Always allocate 
    if(rob_alloc_req_val && alloc_count < 16)begin
      rob[tail_ptr][VALID] <= 1; //valid
      rob[tail_ptr][PENDING] <= 1; //pending
      rob[tail_ptr][SPEC] <= spec; 
      rob[tail_ptr][7:3] <= rob_alloc_req_preg;
      rob_alloc_resp_slot_reg <= tail_ptr;
      alloc_count += 1;
      tail_ptr += 1; 
      tail_ptr %= 16; 
    end
    //end allocation

    //Flip Speculation, so the next instruction is speculating. 
    if(is_branch_Dhl) begin 
      spec <= 1; 
    end 
    //Only speculate one level, unless back to back "valid" branch instructions
    if(spec) begin 
      //We should check right here whether we want to invalidate or not? 
      if(!is_branch_Dhl && !branch_true_Xhl) begin 
        spec <= 0; 
      end 
    end
    //Branches don't get put into the ROB. 
    //Set it to 0, unless the curr DHL is another branch. Also look to either 1. invalidate or 2. 
    if(branch_true_Xhl) begin 
      //Note: Previous instruciton was not necessarily a write therefore was not necessarily a speculation instruction. 
      //Invalidate it in this case
      branch_true <= 1; 
    end
    if(rob[prev][SPEC] == 1) 
    begin
      if(branch_true) begin 
        //invalid 
        rob[prev][VALID] <= 0; 
        rob[prev][PENDING] <= 0; 
        rob[prev][SPEC] <= 0; 
        rob[prev][7:3] <= 0; 
        alloc_count -= 1;
      end 
      else begin 
        //valid 
        rob[prev][SPEC] <= 0; 
      end  
    end  
    
    if(branch_true) begin 
      //Only ever speculate for one level so flip this off after one cycle 
      branch_true <= 0; 
    end 

    //begin fill
    if(rob_fill_val) begin
      rob[rob_fill_slot][PENDING] <= 0; //turn off pending when data is filled
    end
    //end fill
    if(rob_commit_wen)begin
      rob[head_ptr][VALID] <= 0;
      rob[head_ptr][7:3] <= 0;
      alloc_count -= 1;
      head_ptr += 1; 
      head_ptr %= 16; 
    end
    
    if(alloc_count >= 16)begin
      rob_alloc_req_rdy_reg <= 0;
    end else begin
      rob_alloc_req_rdy_reg <= 1;
    end
  

    //end commit

  end


endmodule

`endif

