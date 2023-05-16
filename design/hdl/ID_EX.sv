module ID_EX
import rv32i_types::*;
(
    input clk,
    input rst,
    input load,
    //***************************** 
    input rv32i_control_word ctrl_i_ID_EX, //could contain less signals
    //*****************************
    input logic [4:0] rd_i_ID_EX,
    input rv32i_word pc_i_ID_EX,
    input logic [31:0] rs1_i_ID_EX,
    input logic [31:0] rs2_i_ID_EX,
    input rv32i_word alumux1_out_i_ID_EX,
    input rv32i_word alumux2_out_i_ID_EX,
    input rv32i_word cmpmux_out_i_ID_EX,
    input logic [4:0] rs1_idx_i_ID_EX,
    input logic [4:0] rs2_idx_i_ID_EX,
    input rv32i_word imm_i_ID_EX,
    
    
    input br_pred_sigs br_pred_sigs_i,
    output br_pred_sigs br_pred_sigs_o,


    output rv32i_control_word ctrl_o_ID_EX,
    output logic [4:0] rd_o_ID_EX,
    output rv32i_word pc_o_ID_EX,
    output logic [31:0] rs1_o_ID_EX,
    output logic [31:0] rs2_o_ID_EX,
    output logic [4:0] rs1_idx_o_ID_EX,
    output logic [4:0] rs2_idx_o_ID_EX,
    output rv32i_word alumux1_out_o_ID_EX,
    output rv32i_word alumux2_out_o_ID_EX,
    output rv32i_word cmpmux_out_o_ID_EX,
    output rv32i_word imm_o_ID_EX,

    //rvfi
    input rvfi_sigs rvfi_sigs_i_ID_EX,
    output rvfi_sigs rvfi_sigs_o_ID_EX
);

rv32i_control_word ctrl_data;
logic [4:0] rd_data;
rv32i_word pc_data;
logic [31:0] rs1_data;
logic [31:0] rs2_data;
rv32i_word alumux1_out_data;
rv32i_word alumux2_out_data;
rv32i_word cmpmux_out_data;
rv32i_word imm_data;
br_pred_sigs br_pred_sigs_data;

logic [4:0] rs1_idx_data;
logic [4:0] rs2_idx_data;

//rvfi
rvfi_sigs rvfi_sigs_data;
assign rvfi_sigs_o_ID_EX = rvfi_sigs_data;

always_ff @(posedge clk) begin
    if(rst) begin
        ctrl_data <= '0;
        rd_data <= '0;
        pc_data <= '0;
        rs1_data <= '0;
        rs2_data <= '0;
        alumux1_out_data <= '0;
        alumux2_out_data <= '0;
        cmpmux_out_data <= '0;
        imm_data <= '0;
        br_pred_sigs_data <= '0;

        rvfi_sigs_data <= '0;
        rs1_idx_data <= '0;
        rs2_idx_data <= '0;
    end

    else if (load) begin
        ctrl_data <= ctrl_i_ID_EX;
        rd_data <= rd_i_ID_EX;
        pc_data <= pc_i_ID_EX;
        rs1_data <= rs1_i_ID_EX;
        rs2_data <= rs2_i_ID_EX;
        alumux1_out_data <= alumux1_out_i_ID_EX;
        alumux2_out_data <= alumux2_out_i_ID_EX;
        cmpmux_out_data <= cmpmux_out_i_ID_EX;
        imm_data <= imm_i_ID_EX;
        br_pred_sigs_data <= br_pred_sigs_i;

        rvfi_sigs_data <= rvfi_sigs_i_ID_EX;
        rs1_idx_data <= rs1_idx_i_ID_EX;
        rs2_idx_data <= rs2_idx_i_ID_EX;
    end

    else begin
        ctrl_data <= ctrl_data;
        rd_data <= rd_data;
        pc_data <= pc_data;
        rs1_data <= rs1_data;
        rs2_data <= rs2_data;
        alumux1_out_data <= alumux1_out_data;
        alumux2_out_data <= alumux2_out_data;
        cmpmux_out_data <= cmpmux_out_data;
        imm_data <= imm_data;
        br_pred_sigs_data <= br_pred_sigs_data;

        rvfi_sigs_data <= rvfi_sigs_data;
        rs1_idx_data <= rs1_idx_data;
        rs2_idx_data <= rs2_idx_data;
    end
end

always_comb begin
    ctrl_o_ID_EX = ctrl_data;
    rd_o_ID_EX = rd_data;
    pc_o_ID_EX = pc_data;
    rs1_o_ID_EX = rs1_data;
    rs2_o_ID_EX = rs2_data;
    alumux1_out_o_ID_EX = alumux1_out_data;
    alumux2_out_o_ID_EX = alumux2_out_data;
    cmpmux_out_o_ID_EX = cmpmux_out_data;
    rs1_idx_o_ID_EX = rs1_idx_data;
    rs2_idx_o_ID_EX = rs2_idx_data;
    imm_o_ID_EX = imm_data;
    br_pred_sigs_o = br_pred_sigs_data;
end


/*****************************************************************************/
endmodule : ID_EX  