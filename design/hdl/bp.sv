// branch predictor. Uses Local Branch History Table

module bp 
import rv32i_types::*;
#(
    parameter pc_num_bits = 5,
    parameter pc_bit_offset  = 2,
    parameter bht_width = 5,
    parameter bht_entries = 2**pc_num_bits,
    parameter dpt_entries   = 2**bht_width
)
(
    // top level
    input logic clk,
    input logic rst,

    // resolve/update tables and notify mispredict
    input logic br_en_EX,
    input rv32i_opcode opcode_EX,
    input logic is_stall,
    input rv32i_word pc_EX,

    // branch prediction
    input rv32i_word pc_IF,
    output logic br_pred_o // 1 for taken, 0 for not taken
);

// branch history table
logic [bht_width-1:0] bht [0:bht_entries-1];

// direction prediction table
logic [1:0] dpt [0:dpt_entries-1];

// index for search
logic [pc_num_bits+pc_bit_offset-1:pc_bit_offset] pc_bht_idx_IF;
assign pc_bht_idx_IF = pc_IF[pc_num_bits+pc_bit_offset-1:pc_bit_offset];

// index for resolve
logic [pc_num_bits+pc_bit_offset-1:pc_bit_offset] pc_bht_idx_EX;
assign pc_bht_idx_EX = pc_EX[pc_num_bits+pc_bit_offset-1:pc_bit_offset];

logic is_br_inst;
assign is_br_inst = (opcode_EX == rv32i_types::op_br ||
                     opcode_EX == rv32i_types::op_jal ||
                     opcode_EX == rv32i_types::op_jalr);

logic is_br_taken;
assign is_br_taken = ((opcode_EX == rv32i_types::op_br && br_en_EX) ||
                     opcode_EX == rv32i_types::op_jal ||
                     opcode_EX == rv32i_types::op_jalr);


// get prediction from direction prediction table
assign br_pred_o = dpt[bht[pc_bht_idx_IF]][1];


always_ff @(posedge clk) begin 

    if(rst) begin
        for(int j=0; j < bht_entries; j++)
            bht[j] <= 5'b00000;

        for(int i = 0; i < dpt_entries; i++)
            dpt[i] <= 2'b10; // initialize to weakly taken
    end
    else if(~is_stall && is_br_inst) begin // resolve prediction
        // update branch history table
        bht[pc_bht_idx_EX] <= (bht[pc_bht_idx_EX] << 1'b1) + is_br_taken;

        // update direction prediction table
        if(dpt[bht[pc_bht_idx_EX]] == 2'b11)
            dpt[bht[pc_bht_idx_EX]] <= is_br_taken == 1'd1 ? 2'b11 : dpt[bht[pc_bht_idx_EX]] - 2'd1;
        else if(dpt[bht[pc_bht_idx_EX]] == 2'b00)
            dpt[bht[pc_bht_idx_EX]] <= is_br_taken == 1'd1 ? dpt[bht[pc_bht_idx_EX]] + 2'd1 : 2'b00;
        else
            dpt[bht[pc_bht_idx_EX]] <= is_br_taken == 1'd1 ? dpt[bht[pc_bht_idx_EX]] + 2'd1 : dpt[bht[pc_bht_idx_EX]] - 2'd1;
    end
    else begin // either not a branch instruction or is stalling
        for(int j=0; j < bht_entries; j++)
            bht[j] <= bht[j];

        for(int i = 0; i < dpt_entries; i++)
            dpt[i] <= dpt[i]; // initialize to weakly taken
    end
end


endmodule
