module MEM_WB
import rv32i_types::*;
(
    input clk,
    input rst,
    input load,

    input rv32i_word pc_plus4_i_MEM_WB,
    input logic [4:0] rd_i_MEM_WB,
    input rv32i_word alu_out_i_MEM_WB,
    input logic br_en_i_MEM_WB,
    input rv32i_word mem_rdata_i_MEM_WB,
    input rv32i_word imm_i_MEM_WB,
    input rv32i_word addr_i_MEM_WB,
    input rv32i_control_word ctrl,


    output rv32i_control_word ctrl_to_WB,
    output rv32i_word pc_plus4_o_MEM_WB,
    output rv32i_word alu_out_o_MEM_WB,
    output logic br_en_o_MEM_WB,
    output rv32i_word mem_rdata_o_MEM_WB,
    output rv32i_word imm_o_MEM_WB,
    output rv32i_word addr_o_MEM_WB,
    output regfilemux::regfilemux_sel_t regfilemux_sel_to_WB,
    // send to decode
    output logic load_regfile_o,
    output logic [4:0] rd_o,
    //rvfi
    input rvfi_sigs rvfi_sigs_i_MEM_WB,
    output rvfi_sigs rvfi_sigs_o_MEM_WB
);

    rv32i_word pc_plus4_data;
    logic [4:0] rd_data;
    rv32i_word alu_out_data;
    logic br_en_data;
    rv32i_word mem_rdata_data;
    rv32i_word imm_data;
    rv32i_word addr_data;
    regfilemux::regfilemux_sel_t regfilemux_sel_data;
    rv32i_control_word ctrl_data;
    
    //rvfi
    rvfi_sigs rvfi_sigs_data;
    assign rvfi_sigs_o_MEM_WB = rvfi_sigs_data;

always_ff @(posedge clk) begin
    if(rst) begin
        pc_plus4_data <= '0;
        rd_data <= '0;
        alu_out_data <= '0;
        br_en_data <= '0;
        mem_rdata_data <= '0;
        imm_data <= '0;
        addr_data <= '0;
        regfilemux_sel_data <= regfilemux::alu_out; // 4'b0000, give illegal assignment error if don't use enum defined values
        ctrl_data <= '0;

        rvfi_sigs_data <= '0;
    end

    else if (load) begin
        pc_plus4_data <= pc_plus4_i_MEM_WB;
        rd_data <= rd_i_MEM_WB;
        alu_out_data <= alu_out_i_MEM_WB;
        br_en_data <= br_en_i_MEM_WB;
        mem_rdata_data <= mem_rdata_i_MEM_WB;
        imm_data <= imm_i_MEM_WB;
        addr_data <= addr_i_MEM_WB;
        regfilemux_sel_data <= ctrl.regfilemux_sel;
        ctrl_data <= ctrl;

        rvfi_sigs_data <= rvfi_sigs_i_MEM_WB;
    end

    else begin
        pc_plus4_data <= pc_plus4_data;
        rd_data <= rd_data;
        alu_out_data <= alu_out_data;
        br_en_data <= br_en_data;
        mem_rdata_data <= mem_rdata_data;
        imm_data <= imm_data;
        addr_data <= addr_data;
        regfilemux_sel_data <= regfilemux_sel_data;
        ctrl_data <= ctrl_data;

        rvfi_sigs_data <= rvfi_sigs_data;
    end

end

always_comb begin
     pc_plus4_o_MEM_WB = pc_plus4_data;
     rd_o = rd_data;
     alu_out_o_MEM_WB = alu_out_data;
     br_en_o_MEM_WB = br_en_data;
     mem_rdata_o_MEM_WB = mem_rdata_data;
     imm_o_MEM_WB = imm_data;
     addr_o_MEM_WB = addr_data;
     regfilemux_sel_to_WB = regfilemux_sel_data;
     load_regfile_o = ctrl_data.load_regfile;
     ctrl_to_WB = ctrl_data;
end

/*****************************************************************************/
endmodule : MEM_WB