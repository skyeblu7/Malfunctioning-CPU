module EX
import rv32i_types::*;
(
    input logic [31:0] alumux1_i_EX,
    input logic [31:0] alumux2_i_EX,    
    input logic [31:0] pc_i_EX,
    input logic [31:0] rs2_i_EX,
    input logic [31:0] rs1_i_EX,
    input logic [4:0] rd_i_EX,
    input logic [31:0] cmpmux_out_i_EX,
    input rv32i_control_word ctrl_sig_i_EX,
    input rv32i_word imm_i_EX,
    input br_pred_sigs br_pred_sigs_i,
    output rv32i_word pc_br_not_taken_o,

    // outputs
    output rv32i_control_word ctrl_sig_o_EX,
    output logic [31:0] alu_out_o_EX,
    output logic [31:0] pc_plus4_o_EX,
    output logic [31:0] rs2_o_EX,
    output logic [4:0] rd_o_EX,
    output logic  br_en_o_EX,
    output rv32i_word imm_o_EX,
    output logic btb_hit_o_EX,
    output logic br_pred_o_EX,


    // forwarding
    input rv32i_word EX_MEM_forwarding_alumux1,
    input rv32i_word EX_MEM_forwarding_alumux2,
    input rv32i_word EX_MEM_forwarding_cmpmux1,
    input rv32i_word EX_MEM_forwarding_cmpmux2,

    input rv32i_word MEM_WB_forwarding_alumux1,
    input rv32i_word MEM_WB_forwarding_alumux2,
    input rv32i_word MEM_WB_forwarding_cmpmux1,
    input rv32i_word MEM_WB_forwarding_cmpmux2,

    input logic [1:0] FW_alumux1_sel,
    input logic [1:0] FW_alumux2_sel,
    input logic [1:0] FW_cmpmux1_sel,
    input logic [1:0] FW_cmpmux2_sel,

    //rvfi
    input rvfi_sigs rvfi_sigs_i_EX,
    output rvfi_sigs rvfi_sigs_o_EX,

    //rs2 forwarding
    input logic EX_MEM_rs2_forwarding_sel,
    input rv32i_word EX_MEM_rs2_forwarding_data,

    //send to m-extension
    output rv32i_word alumux1_out,
    output rv32i_word alumux2_out
    
);

logic [31:0] alu_out;

rv32i_word ALU_mux1_out;
rv32i_word ALU_mux2_out;
rv32i_word CMP_mux1_out;
rv32i_word CMP_mux2_out;

rv32i_word rs2_with_forwarding;

//m_ext
assign alumux1_out = ALU_mux1_out;
assign alumux2_out = ALU_mux2_out;

//signals for ex stage
logic  br_en;
assign alu_out_o_EX = alu_out;
assign pc_plus4_o_EX = pc_i_EX + 32'd4;
assign rd_o_EX = rd_i_EX;
assign br_en_o_EX = br_en;
assign rs2_with_forwarding = (EX_MEM_rs2_forwarding_sel) ? EX_MEM_rs2_forwarding_data : rs2_i_EX;
assign rs2_o_EX = rs2_with_forwarding;
assign imm_o_EX = imm_i_EX;
assign btb_hit_o_EX = br_pred_sigs_i.btb_hit;
assign br_pred_o_EX = br_pred_sigs_i.br_pred;

//rvfi 
rvfi_sigs rvfi_sigs_data;
assign rvfi_sigs_o_EX = rvfi_sigs_data;



/******************************* ALU and CMP *********************************/
alu ALU(
    .aluop(ctrl_sig_o_EX.aluop),
    .a(ALU_mux1_out),
    .b(ALU_mux2_out),
    .f(alu_out)
);
	
cmp CMP(
    .cmpop(ctrl_sig_o_EX.cmpop),
    .in1(CMP_mux1_out),
    .in2(CMP_mux2_out),
    .br_en(br_en)
);


// performance counters
logic btb_miss;
logic bp_mispredict_no_take;
logic bp_mispredict_take;



// help simplify branch conditions
logic pred_take_AND_btb_hit;

always_comb 
begin
    //performance counters
    btb_miss = 1'b0;
    bp_mispredict_no_take = 1'b0;
    bp_mispredict_take = 1'b0;



    // set ctrl sigs
    

    ctrl_sig_o_EX = ctrl_sig_i_EX; 
    pc_br_not_taken_o = br_pred_sigs_i.pc_br_not_taken;







    // simplify branch conditions
    pred_take_AND_btb_hit = br_pred_sigs_i.br_pred && br_pred_sigs_i.btb_hit;

    // if bubble
    if(ctrl_sig_i_EX.opcode == rv32i_types::op_bubble) begin
        ctrl_sig_o_EX.pcmux_sel = pcmux::pc_plus4;
    end

    // if we didn't branch but should have
    else if(br_en && ~pred_take_AND_btb_hit && (ctrl_sig_i_EX.opcode == rv32i_types::op_br)) begin
        ctrl_sig_o_EX.pcmux_sel = pcmux::alu_out;
        bp_mispredict_no_take = 1'b1; // performance counter
    end
    else if(~pred_take_AND_btb_hit && (ctrl_sig_i_EX.opcode == rv32i_types::op_jal) ||
    ~pred_take_AND_btb_hit && (ctrl_sig_i_EX.opcode == rv32i_types::op_jalr)) begin
        ctrl_sig_o_EX.pcmux_sel = pcmux::alu_mod2;
        bp_mispredict_no_take = 1'b1; // performance counter
    end

    // if we did branch but shouldn't have
    else if(ctrl_sig_i_EX.opcode != rv32i_types::op_jal && ctrl_sig_i_EX.opcode != rv32i_types::op_jalr && 
            (ctrl_sig_i_EX.opcode != rv32i_types::op_br || ctrl_sig_i_EX.opcode == rv32i_types::op_br && ~br_en)) begin
        if(br_pred_sigs_i.br_pred && br_pred_sigs_i.btb_hit) begin
            ctrl_sig_o_EX.pcmux_sel = pcmux::recover; 
            bp_mispredict_take = 1'b1; // performance counter
        end
    end

    // if we did branch (and we should branch) but btb target was incorrect
    else if(br_en && (ctrl_sig_i_EX.opcode == rv32i_types::op_br)) begin
        if((br_pred_sigs_i.br_pred && br_pred_sigs_i.btb_hit) & (br_pred_sigs_i.btb_target != alu_out)) begin
            ctrl_sig_o_EX.pcmux_sel = pcmux::recover; 
            btb_miss = 1'b1; // performance counter
        end
    end
    else if(ctrl_sig_i_EX.opcode == rv32i_types::op_jal || ctrl_sig_i_EX.opcode == rv32i_types::op_jalr) begin
        if((br_pred_sigs_i.br_pred && br_pred_sigs_i.btb_hit) & (br_pred_sigs_i.btb_target != alu_out)) begin
            pc_br_not_taken_o = alu_out;
            ctrl_sig_o_EX.pcmux_sel = pcmux::recover; 
            btb_miss = 1'b1; // performance counter
        end
    end
    

    // correct taken prediction
    else begin
        ctrl_sig_o_EX.pcmux_sel = pcmux::pc_plus4;    
    end    
end

/******************************MUXES********************************/

always_comb begin : MUXES 

    // 00 = no forwarding
    // 01 = EX_MEM forwarding
    // 10 = MEM_WB forwarding
    // 11 = not used (default no forwarding)

    // ALU mux1
    case(FW_alumux1_sel)
        2'b00: ALU_mux1_out = alumux1_i_EX;
        2'b01: ALU_mux1_out = EX_MEM_forwarding_alumux1;
        2'b10: ALU_mux1_out = MEM_WB_forwarding_alumux1;

        // not used
        2'b11: ALU_mux1_out = alumux1_i_EX;
    endcase

    // ALU mux2
    case(FW_alumux2_sel) 
        2'b00: ALU_mux2_out = alumux2_i_EX;
        2'b01: ALU_mux2_out = EX_MEM_forwarding_alumux2;
        2'b10: ALU_mux2_out = MEM_WB_forwarding_alumux2;

        // not used
        2'b11: ALU_mux2_out = alumux2_i_EX;
    endcase

    // CMP mux1
    case(FW_cmpmux1_sel)
        2'b00: CMP_mux1_out = rs1_i_EX;
        2'b01: CMP_mux1_out = EX_MEM_forwarding_cmpmux1;
        2'b10: CMP_mux1_out = MEM_WB_forwarding_cmpmux1;

        // not used
        2'b11: CMP_mux1_out = rs1_i_EX;
    endcase

    // CMP mux2
    case(FW_cmpmux2_sel)
        2'b00: CMP_mux2_out = cmpmux_out_i_EX;
        2'b01: CMP_mux2_out = EX_MEM_forwarding_cmpmux2;
        2'b10: CMP_mux2_out = MEM_WB_forwarding_cmpmux2;

        // not used
        2'b11: CMP_mux2_out = cmpmux_out_i_EX;
    endcase

end


always_comb begin : RVFI

    // set defaults
    rvfi_sigs_data = rvfi_sigs_i_EX;
    case(ctrl_sig_o_EX.pcmux_sel)
        pcmux::pc_plus4: rvfi_sigs_data.pc_wdata = rvfi_sigs_i_EX.pc_wdata;
        pcmux::alu_out: rvfi_sigs_data.pc_wdata = alu_out;
        pcmux::alu_mod2: rvfi_sigs_data.pc_wdata = {alu_out[31:2],2'b0};
        pcmux::recover: rvfi_sigs_data.pc_wdata = pc_br_not_taken_o;
    endcase

        


    // if store
    if(ctrl_sig_i_EX.opcode == rv32i_types::op_store) begin
        rvfi_sigs_data.rs1_rdata = ALU_mux1_out;
        rvfi_sigs_data.rs2_rdata = rs2_o_EX;
    end
    // on branch
    else if(ctrl_sig_i_EX.opcode == rv32i_types::op_br) begin
        rvfi_sigs_data.rs1_rdata = CMP_mux1_out;
        rvfi_sigs_data.rs2_rdata = CMP_mux2_out;
    end
    // on sltu/slt/slti/sltui
    else if((rvfi_sigs_data.opcode == rv32i_types::op_reg && rvfi_sigs_data.inst[14:12] == rv32i_types::slt) ||
            (rvfi_sigs_data.opcode == rv32i_types::op_reg && rvfi_sigs_data.inst[14:12] == rv32i_types::sltu) ||
            (rvfi_sigs_data.opcode == rv32i_types::op_imm && rvfi_sigs_data.inst[14:12] == rv32i_types::slt) ||
            (rvfi_sigs_data.opcode == rv32i_types::op_imm && rvfi_sigs_data.inst[14:12] == rv32i_types::sltu)) 
    begin 
        rvfi_sigs_data.rs1_rdata = CMP_mux1_out;
        rvfi_sigs_data.rs2_rdata = CMP_mux2_out;
    end
    // on non-branch
    else
    begin
        rvfi_sigs_data.rs1_rdata = ALU_mux1_out;
        rvfi_sigs_data.rs2_rdata = ALU_mux2_out;
    end
end


/*****************************************************************************/
endmodule : EX




