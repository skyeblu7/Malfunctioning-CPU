module ID
import rv32i_types::*;
(
    input logic clk,
    input logic rst,

    /*from IF_ID*/
    input rv32i_word pc_i_ID,
    input logic [2:0] funct3_i_ID,
    input logic [6:0] funct7_i_ID,
    input rv32i_opcode opcode_i_ID,
    input logic [31:0] i_imm_i_ID,
    input logic [31:0] s_imm_i_ID,
    input logic [31:0] b_imm_i_ID,
    input logic [31:0] u_imm_i_ID,
    input logic [31:0] j_imm_i_ID,
    input logic [4:0] rs1_i_ID,
    input logic [4:0] rs2_i_ID,
    input logic [4:0] rd_i_ID,
    input br_pred_sigs br_pred_sigs_i,

    /*from WB*/
    input rv32i_word regfilemux_out_From_WB,
    
    /*from MEM_WB*/
    input logic [4:0] rd_i_From_MEM_WB,
    input logic load_regfile_i_From_MEM_WB,

    output br_pred_sigs br_pred_sigs_o,
    output rv32i_control_word ctrl_o_ID,
    output logic [4:0] rd_o_ID,
    output rv32i_word pc_o_ID,
    output logic [31:0] rs1_o_ID,
    output logic [31:0] rs2_o_ID,
    output rv32i_word alumux1_out_o_ID,
    output rv32i_word alumux2_out_o_ID,
    output rv32i_word cmpmux_out_o_ID,
    // pass imm to WB
    output [31:0] imm_o_ID,

    //rvfi
    input rvfi_sigs rvfi_sigs_i_ID,
    output rvfi_sigs rvfi_sigs_o_ID
);

logic [31:0] immmux_out;
rv32i_word alumux1_out;
rv32i_word alumux2_out;
logic [31:0] rs1_out;
logic [31:0] rs2_out;
rv32i_word cmpmux_out;
rv32i_control_word ctrl_out;

//rvfi
rvfi_sigs rvfi_sigs_data; 

immmux::immmux_sel_t immmux_sel;
alumux::alumux1_sel_t alumux1_sel;
alumux::alumux2_sel_t alumux2_sel;
cmpmux::cmpmux_sel_t cmpmux_sel;

assign immmux_sel = ctrl_out.immmux_sel;
assign alumux1_sel = ctrl_out.alumux1_sel;
assign alumux2_sel = ctrl_out.alumux2_sel;
assign cmpmux_sel = ctrl_out.cmpmux_sel;

assign imm_o_ID = immmux_out;

// branch prediction
assign br_pred_sigs_o = br_pred_sigs_i;

//rvfi
assign rvfi_sigs_o_ID = rvfi_sigs_data;

always_comb begin: MUXES
    case(immmux_sel)
        immmux::i_imm: immmux_out = i_imm_i_ID;
        immmux::s_imm: immmux_out = s_imm_i_ID;
        immmux::b_imm: immmux_out = b_imm_i_ID;
        immmux::u_imm: immmux_out = u_imm_i_ID;
        immmux::j_imm: immmux_out = j_imm_i_ID;
        default: immmux_out = i_imm_i_ID;
    endcase

    case(alumux1_sel)
        alumux::pc_out: alumux1_out = pc_i_ID;
        alumux::rs1_out: alumux1_out = rs1_out;
        default:alumux1_out = pc_i_ID;
    endcase

    case(alumux2_sel)
        alumux::imm: alumux2_out = immmux_out;
        alumux::rs2_out: alumux2_out = rs2_out;
        default: alumux2_out = immmux_out;
    endcase

    case(cmpmux_sel)
        cmpmux::imm: cmpmux_out = immmux_out;
        cmpmux::rs2_out: cmpmux_out = rs2_out;
    endcase
end


always_comb begin: RVFI
    rvfi_sigs_data = rvfi_sigs_i_ID;
    rvfi_sigs_data.rs1_rdata = rs1_out;
    rvfi_sigs_data.rs2_rdata = rs2_out;
    rvfi_sigs_data.load_regfile = ctrl_out.load_regfile;
    if(rvfi_sigs_data.load_regfile == '0)
        rvfi_sigs_data.rd_wdata = '0;

    rvfi_sigs_data.rs1_addr = rs1_i_ID;
    rvfi_sigs_data.rs2_addr = rs2_i_ID;
    rvfi_sigs_data.rd_addr = rd_i_ID;
    rvfi_sigs_data.opcode = opcode_i_ID;
end

control_rom control_rom(
    .opcode(opcode_i_ID),
    .funct3(funct3_i_ID),
    .funct7(funct7_i_ID),
    .ctrl(ctrl_out)
);

regfile regfile(
    .clk(clk),
    .rst(rst),
    .load(load_regfile_i_From_MEM_WB), 
    .in(regfilemux_out_From_WB),   
    .src_a(rs1_i_ID),
    .src_b(rs2_i_ID),
    .dest(rd_i_From_MEM_WB),
    .reg_a(rs1_out),
    .reg_b(rs2_out)
);

//output assignment
always_comb begin
    ctrl_o_ID = ctrl_out;
    rd_o_ID = rd_i_ID;
    pc_o_ID = pc_i_ID;
    rs1_o_ID = rs1_out;
    rs2_o_ID = rs2_out;
    alumux1_out_o_ID = alumux1_out;
    alumux2_out_o_ID = alumux2_out;
    cmpmux_out_o_ID = cmpmux_out;
end


/*****************************************************************************/
endmodule : ID