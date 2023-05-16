module IF
import rv32i_types::*;
(
    input logic clk, 
    input logic rst,
    input logic load_pc,

    // to/from icache
    output logic [31:0] icache_instr_addr,
    output logic icache_read,
    input logic [31:0] instr_i,


    // to next IF_ID reg
    output rv32i_word instr_o,
    output rv32i_word pc_o,
    output logic br_pred_o,
    output logic btb_hit_o,
    output br_pred_sigs br_pred_sigs_o,

    // from EX
    input logic [2:0] pcmux_sel_EX,
    input logic [31:0] alu_out,
    input rv32i_word recover_pc,

    // from branch predictor & BTB
    input logic btb_hit_i,
    input logic br_pred_i,
    input rv32i_word btb_target,

    // rvfi sigs
    output rvfi_sigs rvfi_sigs_o_IF
);

rv32i_word pcmux_out;
rv32i_word pc_out;
logic [2:0] pcmux_sel;

rv32i_word pc_br_not_taken;


rvfi_sigs rvfi_sigs_data;
assign rvfi_sigs_o_IF = rvfi_sigs_data;

assign icache_read = 1'b1;
assign icache_instr_addr = pc_out;
assign pc_o = pc_out;
assign instr_o = instr_i;

assign br_pred_o = br_pred_i;
assign btb_hit_o = btb_hit_i;
assign pc_br_not_taken = pc_out + 4;



// program counter
pc_register PC(
    .clk(clk),
    .rst(rst),
    .load(load_pc),
    .in(pcmux_out),
    .out(pc_out)
);


function void rvfi_defaults();
// Regfile:
rvfi_sigs_data.rs1_addr = '0;
rvfi_sigs_data.rs2_addr = '0;
rvfi_sigs_data.rs1_rdata = '0;
rvfi_sigs_data.rs2_rdata = '0;
rvfi_sigs_data.load_regfile = '0;
rvfi_sigs_data.rd_addr = '0;
rvfi_sigs_data.rd_wdata = '0;
// pc:
rvfi_sigs_data.pc_rdata = '0;
rvfi_sigs_data.pc_wdata = '0;
// memory
rvfi_sigs_data.mem_addr = '0;
rvfi_sigs_data.mem_rmask = '0;
rvfi_sigs_data.mem_wmask = '0;
rvfi_sigs_data.mem_rdata = '0;
rvfi_sigs_data.mem_wdata = '0;

// instr
rvfi_sigs_data.inst = '0;

//opcode
rvfi_sigs_data.opcode = rv32i_types::op_auipc;

endfunction


always_comb begin : MUXES

    br_pred_sigs_o.br_pred = br_pred_i;
    br_pred_sigs_o.btb_hit = btb_hit_i;
    br_pred_sigs_o.btb_target = btb_target;
    br_pred_sigs_o.pc_br_not_taken = pc_br_not_taken;
    br_pred_sigs_o.pc_EX = pc_out;

    if(pcmux_sel_EX == pcmux::pc_plus4)
        pcmux_sel = (btb_hit_i & br_pred_i) ? 3'b011 : pcmux::pc_plus4;
    else
        pcmux_sel = pcmux_sel_EX;

    // PC mux, determines next instruction (branch or +4 or JALR)
    unique case (pcmux_sel)
        pcmux::pc_plus4: pcmux_out = pc_out + 4; // pcmux_sel = 000
        pcmux::alu_out: pcmux_out = alu_out; // pcmux_sel = 001
        pcmux::alu_mod2: pcmux_out = {alu_out[31:2], 2'b0}; // pcmux_sel = 010
        pcmux::br_pred: pcmux_out = btb_target; // pcmux_sel = 011
        pcmux::recover: pcmux_out = recover_pc; // pcmux_sel = 100

        default:
            pcmux_out = pc_out; // should not be reached
    endcase


    rvfi_defaults();
    rvfi_sigs_data.inst = instr_i;
    rvfi_sigs_data.pc_rdata = pc_out;
    if(pcmux_sel == 3'b011)
        rvfi_sigs_data.pc_wdata = btb_target;
    else
        rvfi_sigs_data.pc_wdata = pc_out+4'd4;

end

/*****************************************************************************/
endmodule : IF