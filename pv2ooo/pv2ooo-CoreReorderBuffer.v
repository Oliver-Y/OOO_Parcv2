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
  
  output [ 3:0] rob_alloc_resp_slot, //we output where we allocated

  input         rob_fill_val,        // we are filling 
  input  [ 3:0] rob_fill_slot,       //pending bit goes low 

  output        rob_commit_wen,      //tied to !pending && valid on head ptr?
  output [ 3:0] rob_commit_slot,     //tied to head ptr
  output [ 4:0] rob_commit_rf_waddr  //tied to dest register on head ptr
);

  wire rob_alloc_req_rdy   = 1'b1;
  wire rob_alloc_resp_slot = 4'b0;
  wire rob_commit_wen      = 1'b0;
  wire rob_commit_rf_waddr = 1'b0;
  wire rob_commit_slot     = 4'b0;

  reg [4:0] head_ptr = 0;
  reg [4:0] tail_ptr = 0;  

  reg rob_alloc_req_rdy_reg;

  reg [3:0] rob_alloc_resp_slot_reg;

  reg rob_commit_wen_reg;
  reg [ 3:0] rob_commit_slot_reg;
  reg [ 4:0] rob_commit_rf_waddr_reg;


  reg [6:0] rob [0:15];
  integer i;
  initial begin
    for(i = 0; i < 16; i+=1) begin
        rob[i] = {1'b0, 1'b0, 5'b0};
    end
  end


  assign rob_alloc_req_rdy = rob_alloc_req_rdy_reg;
  assign rob_alloc_resp_slot = rob_alloc_resp_slot_reg;

  assign rob_commit_wen = rob_commit_wen_reg;
  assign rob_commit_slot = rob_commit_slot_reg;
  assign rob_commit_rf_waddr = rob_commit_rf_waddr_reg;

  reg [5:0] alloc_count = 0;

  always @(posedge clk)begin


    //begin allocation
    if(rob_alloc_req_val && alloc_count < 16)begin
      rob[tail_ptr][0] = 1; //valid
      rob[tail_ptr][1] = 1; //pending
      rob[tail_ptr][6:2] <= rob_alloc_req_preg;
      rob_alloc_resp_slot_reg <= tail_ptr;
      alloc_count += 1;

      //then move tail pointer to next open spot
      while(rob[tail_ptr][0])begin 
        tail_ptr += 1;
        tail_ptr %= 16;
      end

    end
    //end allocation

    //begin fill
    if(rob_fill_val)begin
      rob[rob_fill_slot][1] = 0; //turn off pending when data is filled
    end
    //end fill

    //begin commit
    rob_commit_wen_reg <= rob[head_ptr][0] && !rob[head_ptr][1]; //if slot is valid and no longer pending we commit
    rob_commit_slot_reg <= head_ptr;
    rob_commit_rf_waddr_reg <= rob[head_ptr][6:2];

    if(rob_commit_wen_reg)begin
      rob[head_ptr][0] = 0;
      rob[head_ptr][6:2] = 0;
      alloc_count -= 1;
    end

    head_ptr += 1;
    head_ptr %= 16;

    if(alloc_count >= 16)begin
      rob_alloc_req_rdy_reg <= 0;
    end else begin
      rob_alloc_req_rdy_reg <= 1;
    end
  

    //end commit

  end


endmodule

`endif

