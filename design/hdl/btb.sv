module btb 
import rv32i_types::*;
#(
    parameter s_index = 6,
    parameter start_idx = 7
)
(
    input logic clk,
    input logic rst,
    //input logic br_en,

    // to update btb
    input rv32i_opcode opcode_EX,
    input logic [31:0] pc_from_EX, //pc address of taken branch
    input logic [31:0] branch_pc,  //branch target address, computed from alu_out from EXE

    // to find target pc
    input logic [31:0] pc_from_IF, //pc address fetched in IF
    output logic hit,
    output logic [31:0] target_pc
);

// btb structure, use all PC bits as tags
logic [31:0] addr_data [2**s_index];
logic [31:0] tag_data [2**s_index];

logic prediction_hit;
assign hit = prediction_hit;

logic [s_index-1:0] idx_from_IF;
logic [s_index-1:0] idx_from_EX;

assign idx_from_IF = pc_from_IF[start_idx:start_idx-s_index+1]; 
assign idx_from_EX = pc_from_EX[start_idx:start_idx-s_index+1];

// check whether to use the prediction addr or not
always_comb begin
    prediction_hit = (pc_from_IF == tag_data[idx_from_IF]); 
    target_pc = addr_data[idx_from_IF];
end

// reset and load the BTB
always_ff @(posedge clk) begin
    if(rst) begin
        for (int i=0; i<2**s_index; i++) begin
            addr_data[i] <= '0;
            tag_data[i] <= '0;
        end
    end
    // loading btb
    else if (opcode_EX == rv32i_types::op_jal ||
            opcode_EX == rv32i_types::op_jalr ||
            opcode_EX == rv32i_types::op_br  ) begin
        addr_data[idx_from_EX] <= branch_pc; 
        tag_data[idx_from_EX] <= pc_from_EX;
    end
end

endmodule