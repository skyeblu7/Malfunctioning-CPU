module IF_ID
import rv32i_types::*;
(
    input clk,
    input rst,
    input load,


    input rv32i_word pc_i_IF_ID,
    input rv32i_word instruction_i_IF_ID,

    input rvfi_sigs rvfi_sigs_i_IF_ID,
    output rvfi_sigs rvfi_sigs_o_IF_ID,

    input br_pred_sigs br_pred_sigs_i,
    output br_pred_sigs br_pred_sigs_o,

    output rv32i_word pc_o_IF_ID,
    output logic [2:0] funct3_o_IF_ID,
    output logic [6:0] funct7_o_IF_ID,
    output rv32i_opcode opcode_o_IF_ID,
    output logic [31:0] i_imm_o_IF_ID,
    output logic [31:0] s_imm_o_IF_ID,
    output logic [31:0] b_imm_o_IF_ID,
    output logic [31:0] u_imm_o_IF_ID,
    output logic [31:0] j_imm_o_IF_ID,
    output logic [4:0] rs1_o_IF_ID,
    output logic [4:0] rs2_o_IF_ID,
    output logic [4:0] rd_o_IF_ID
);

logic [31:0] data;
rv32i_word pc_data;
rvfi_sigs rvfi_sigs_data;

br_pred_sigs br_pred_sigs_data;

assign pc_o_IF_ID = pc_data;
assign funct3_o_IF_ID = data[14:12];
assign funct7_o_IF_ID = data[31:25];
assign opcode_o_IF_ID = rv32i_opcode'(data[6:0]);
assign i_imm_o_IF_ID = {{21{data[31]}}, data[30:20]};
assign s_imm_o_IF_ID = {{21{data[31]}}, data[30:25], data[11:7]};
assign b_imm_o_IF_ID = {{20{data[31]}}, data[7], data[30:25], data[11:8], 1'b0};
assign u_imm_o_IF_ID = {data[31:12], 12'h000};
assign j_imm_o_IF_ID = {{12{data[31]}}, data[19:12], data[20], data[30:21], 1'b0};
//assign rs1_o_IF_ID = data[19:15];
//assign rs2_o_IF_ID = data[24:20];
//assign rd_o_IF_ID = data[11:7];

// rvfi
assign rvfi_sigs_o_IF_ID = rvfi_sigs_data;

always_comb begin
    if(opcode_o_IF_ID == rv32i_types::op_imm || 
       opcode_o_IF_ID == rv32i_types::op_load ||
       opcode_o_IF_ID == rv32i_types::op_lui ||
       opcode_o_IF_ID == rv32i_types::op_auipc ||
       opcode_o_IF_ID == rv32i_types::op_jal ||
       opcode_o_IF_ID == rv32i_types::op_jalr)
        rs2_o_IF_ID = '0;
    else
        rs2_o_IF_ID = data[24:20];


    if(opcode_o_IF_ID == rv32i_types::op_br || 
       opcode_o_IF_ID == rv32i_types::op_store)
        rd_o_IF_ID = '0;
    else
        rd_o_IF_ID = data[11:7];

    if(opcode_o_IF_ID == rv32i_types::op_lui || 
       opcode_o_IF_ID == rv32i_types::op_auipc || 
       opcode_o_IF_ID == rv32i_types::op_jal)
        rs1_o_IF_ID = '0;
    else
        rs1_o_IF_ID = data[19:15];

    br_pred_sigs_o = br_pred_sigs_data;
end


//why "=" instead of "<="
always_ff @(posedge clk)
begin
    if (rst)
    begin
        data <= '0;
        pc_data <= '0;
        rvfi_sigs_data <= '0;
        br_pred_sigs_data <= '0;
    end
    else if (load == 1)
    begin
        data <= instruction_i_IF_ID;
        pc_data <= pc_i_IF_ID;
        rvfi_sigs_data <= rvfi_sigs_i_IF_ID;
        br_pred_sigs_data <= br_pred_sigs_i;
    end
    else
    begin
        data <= data;
        pc_data <= pc_data;
        rvfi_sigs_data <= rvfi_sigs_data;
        br_pred_sigs_data <= br_pred_sigs_data;
    end
end


/*****************************************************************************/
endmodule : IF_ID