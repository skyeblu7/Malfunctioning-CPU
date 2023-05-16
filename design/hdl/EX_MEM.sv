module EX_MEM
import rv32i_types::*;
(
    input clk,
    input rst,
    input load,

    input rv32i_control_word ctrl_i,
    input logic [31:0] exmem_alu_in,
    input logic [31:0] exmem_pc_in,
    input logic [31:0] exmem_rs2_in,
    input logic [4:0] exmem_rd_in,
    input logic  exmem_bren_in, 
    input rv32i_word imm_i_EX_MEM,
    
    output rv32i_control_word ctrl_sig_o_EX,
    output logic [31:0] alu_out_o_EX,
    output logic [31:0] pc_plus4_o_EX,
    output logic [31:0] rs2_o_EX,
    output logic [4:0] rd_o_EX,
    output logic  br_en_o_EX,
    output rv32i_word imm_o_EX_MEM,

    //rvfi
    input rvfi_sigs rvfi_sigs_i_EX_MEM,
    output rvfi_sigs rvfi_sigs_o_EX_MEM

);

rv32i_control_word ctrl_data;
rv32i_word alu_out_data;
rv32i_word pc_plux4_data;
rv32i_word rs2_data;
logic [4:0] rd_idx_data;
logic br_en_data;
rv32i_word imm_data;


//rvfi
rvfi_sigs rvfi_sigs_data;

always_ff @(posedge clk) begin
    if(rst) begin
        ctrl_data <= '0;
        alu_out_data <= '0;
        pc_plux4_data <= '0;
        rs2_data <= '0;
        rd_idx_data <= '0;
        br_en_data <= '0;
        imm_data <= '0;

        rvfi_sigs_data <= '0;
    end

    else if (load) begin
        ctrl_data <= ctrl_i;
        alu_out_data <= exmem_alu_in;
        pc_plux4_data <= exmem_pc_in;
        rs2_data <= exmem_rs2_in;
        rd_idx_data <= exmem_rd_in;
        br_en_data <= exmem_bren_in;
        imm_data <= imm_i_EX_MEM;

        rvfi_sigs_data <= rvfi_sigs_i_EX_MEM;
    end

    else begin
        ctrl_data <= ctrl_data;
        alu_out_data <= alu_out_data;
        pc_plux4_data <= pc_plux4_data;
        rs2_data <= rs2_data;
        rd_idx_data <= rd_idx_data;
        br_en_data <= br_en_data;
        imm_data <= imm_data;

        rvfi_sigs_data <= rvfi_sigs_data;
    end
end


always_comb begin
    ctrl_sig_o_EX = ctrl_data;
    alu_out_o_EX = alu_out_data;
    pc_plus4_o_EX = pc_plux4_data;
    rs2_o_EX = rs2_data;
    rd_o_EX = rd_idx_data;
    br_en_o_EX = br_en_data;
    imm_o_EX_MEM = imm_data;

    rvfi_sigs_o_EX_MEM = rvfi_sigs_data;
end


/*****************************************************************************/
endmodule : EX_MEM
