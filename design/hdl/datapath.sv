module datapath
import rv32i_types::*;
(
    input logic clk,
    input logic rst,

    // to/from icache
    output logic [31:0] icache_instr_addr,
    output logic icache_read,
    input logic [31:0] instr_i,
    input logic icache_resp,

    // to/from dcache
    input logic	        dcache_resp,
    input rv32i_word 	dcache_rdata, 
    output logic 		dcache_read,
    output logic 		dcache_write,
    output logic [3:0] 	dcache_mbe,
    output rv32i_word 	dcache_data_addr,
    output rv32i_word 	dcache_wdata

);

logic m_extension_load;
logic m_extension_resp;
rv32i_word m_extension_out;

// IF -> IF_ID
IF_O IF_bus;

// IF_ID -> ID and forwarding
IF_ID_O IF_ID_bus;

// ID -> ID_EX
ID_O ID_bus;

// ID_EX -> EX and forwarding
ID_EX_O ID_EX_bus;

// EX -> EX_MEM, hazard and IF
EX_O EX_bus;

// EX_MEM -> MEM and forwarding
EX_MEM_O EX_MEM_bus;

// MEM -> MEM_WB
MEM_O MEM_bus;

// MEM_WB -> WB, ID and forwarding
MEM_WB_O MEM_WB_bus;

// WB -> ID
WB_O WB_bus;


// hazard -> all registers and IF
HAZ_O HAZ_bus;

// forwarding -> EX
FOR_O FOR_bus;

// branch prediction -> IF and EX
BP_O BP_bus;

// branch target buffer -> IF
BTB_O BTB_bus;


btb BTB(
    // top level
    .clk(clk),
    .rst(rst),

    //input logic br_en, <-- unused

    // to update btb, from EX/ID_EX 
    .opcode_EX(EX_bus.ctrl.opcode),
    .pc_from_EX(ID_EX_bus.pc), //pc address of taken branch
    .branch_pc(EX_bus.alu_out),  // alu_out from EXE

    // to find target pc, to/from IF
    .pc_from_IF(IF_bus.pc), //pc address fetched in IF
    .hit(BTB_bus.hit),
    .target_pc(BTB_bus.target)
);

bp BP(
    // top level
    .clk(clk),
    .rst(rst),

    // resolve/update tables and notify mispredict
    // to/from EX, is_stall from hazard
    .br_en_EX(EX_bus.br_en),
    .opcode_EX(EX_bus.ctrl.opcode),
    .is_stall(HAZ_bus.is_stalling),
    .pc_EX(ID_EX_bus.br_pred_sigs.pc_EX),

    // branch prediction, to/from IF
    .pc_IF(IF_bus.pc),
    .br_pred_o(BP_bus.pred)
);


// Instruction Fetch
/******************************** IF **************************************/

IF IF(
    // from top level
    .clk(clk),
    .rst(rst),

    // from icache (top level)
    .instr_i(instr_i),

    // from hazard detection
    .load_pc(HAZ_bus.load_pc),

    // from EX
    .pcmux_sel_EX(EX_bus.ctrl.pcmux_sel),
    .alu_out(EX_bus.alu_out),
    .recover_pc(EX_bus.pc_br_not_taken),

    // from branch predictor & BTB
    .br_pred_i(BP_bus.pred),
    .btb_hit_i(BTB_bus.hit),
    .btb_target(BTB_bus.target),

    // to icache (top level)
    .icache_instr_addr(icache_instr_addr),
    .icache_read(icache_read),

    // to IF_ID reg
    .pc_o(IF_bus.pc),
    .instr_o(IF_bus.inst),
    .br_pred_sigs_o(IF_bus.br_pred_sigs),
    .rvfi_sigs_o_IF(IF_bus.rvfi)
);


/******************************** IF_ID REG **************************************/
IF_ID Reg1(
    // from top level
    .clk(clk),

    // from hazard detection
    .rst(HAZ_bus.rst_IF_ID || rst), // rst from top level
    .load(HAZ_bus.load_IF_ID),

    // from IF
    .pc_i_IF_ID(IF_bus.pc),
    .instruction_i_IF_ID(IF_bus.inst),
    .br_pred_sigs_i(IF_bus.br_pred_sigs),
    .rvfi_sigs_i_IF_ID(IF_bus.rvfi),

    // to ID
    .br_pred_sigs_o(IF_ID_bus.br_pred_sigs),
    .pc_o_IF_ID(IF_ID_bus.pc),
    .funct3_o_IF_ID(IF_ID_bus.funct3),
    .funct7_o_IF_ID(IF_ID_bus.funct7),
    .opcode_o_IF_ID(IF_ID_bus.opcode),
    .i_imm_o_IF_ID(IF_ID_bus.i_imm),
    .s_imm_o_IF_ID(IF_ID_bus.s_imm),
    .b_imm_o_IF_ID(IF_ID_bus.b_imm),
    .u_imm_o_IF_ID(IF_ID_bus.u_imm),
    .j_imm_o_IF_ID(IF_ID_bus.j_imm),
    .rd_o_IF_ID(IF_ID_bus.rd_idx),
    .rvfi_sigs_o_IF_ID(IF_ID_bus.rvfi),

    // to ID, forwarding and ID_EX
    .rs1_o_IF_ID(IF_ID_bus.rs1),
    .rs2_o_IF_ID(IF_ID_bus.rs2)
);


// Instruction Decode
/******************************** ID **************************************/
ID ID(
    // from top level
    .clk(clk),
    .rst(rst),

    // from IF_ID
    .pc_i_ID(IF_ID_bus.pc),
    .funct3_i_ID(IF_ID_bus.funct3),
    .funct7_i_ID(IF_ID_bus.funct7),
    .opcode_i_ID(IF_ID_bus.opcode),
    .i_imm_i_ID(IF_ID_bus.i_imm),
    .s_imm_i_ID(IF_ID_bus.s_imm),
    .b_imm_i_ID(IF_ID_bus.b_imm),
    .u_imm_i_ID(IF_ID_bus.u_imm),
    .j_imm_i_ID(IF_ID_bus.j_imm),
    .rd_i_ID(IF_ID_bus.rd_idx),
    .rvfi_sigs_i_ID(IF_ID_bus.rvfi),
    .rs1_i_ID(IF_ID_bus.rs1),
    .rs2_i_ID(IF_ID_bus.rs2),
    .br_pred_sigs_i(IF_ID_bus.br_pred_sigs),

    // from WB
    .regfilemux_out_From_WB(WB_bus.regfilemux_out), 

    // from MEM_WB
    .rd_i_From_MEM_WB(MEM_WB_bus.rd_idx),
    .load_regfile_i_From_MEM_WB(MEM_WB_bus.ctrl.load_regfile),
    
    
    // to ID_EX
    .br_pred_sigs_o(ID_bus.br_pred_sigs),
    .ctrl_o_ID(ID_bus.ctrl),
    .rd_o_ID(ID_bus.rd_idx),
    .pc_o_ID(ID_bus.pc),
    .rs1_o_ID(ID_bus.rs1_data),
    .rs2_o_ID(ID_bus.rs2_data),
    .alumux1_out_o_ID(ID_bus.alumux1_out),
    .alumux2_out_o_ID(ID_bus.alumux2_out),
    .cmpmux_out_o_ID(ID_bus.cmpmux_out),
    .imm_o_ID(ID_bus.imm),
    .rvfi_sigs_o_ID(ID_bus.rvfi)
);




/******************************** ID_EX REG **************************************/
ID_EX Reg2(
    // from top level
    .clk(clk),

    // from hazard
    .rst(HAZ_bus.rst_ID_EX || rst), // rst from top level
    .load(HAZ_bus.load_ID_EX),

    // from ID
    .br_pred_sigs_i(ID_bus.br_pred_sigs),
    .ctrl_i_ID_EX(ID_bus.ctrl), 
    .rd_i_ID_EX(ID_bus.rd_idx),
    .pc_i_ID_EX(ID_bus.pc),
    .rs1_i_ID_EX(ID_bus.rs1_data),
    .rs2_i_ID_EX(ID_bus.rs2_data),
    .alumux1_out_i_ID_EX(ID_bus.alumux1_out),
    .alumux2_out_i_ID_EX(ID_bus.alumux2_out),
    .cmpmux_out_i_ID_EX(ID_bus.cmpmux_out),
    .imm_i_ID_EX(ID_bus.imm),
    .rvfi_sigs_i_ID_EX(ID_bus.rvfi),

    // from IF_ID
    .rs1_idx_i_ID_EX(IF_ID_bus.rs1),
    .rs2_idx_i_ID_EX(IF_ID_bus.rs2),

    // to EX
    .ctrl_o_ID_EX(ID_EX_bus.ctrl),
    .pc_o_ID_EX(ID_EX_bus.pc),
    .rs1_o_ID_EX(ID_EX_bus.rs1_data),
    .rs2_o_ID_EX(ID_EX_bus.rs2_data),
    .alumux1_out_o_ID_EX(ID_EX_bus.alumux1_out),
    .alumux2_out_o_ID_EX(ID_EX_bus.alumux2_out),
    .cmpmux_out_o_ID_EX(ID_EX_bus.cmpmux_out),
    .imm_o_ID_EX(ID_EX_bus.imm),
    .rvfi_sigs_o_ID_EX(ID_EX_bus.rvfi),

    // to EX but...
    // pc_EX to BP
    .br_pred_sigs_o(ID_EX_bus.br_pred_sigs),

    // to forwarding
    .rs1_idx_o_ID_EX(ID_EX_bus.rs1_idx),
    .rs2_idx_o_ID_EX(ID_EX_bus.rs2_idx),
    
    // to EX and forwarding
    .rd_o_ID_EX(ID_EX_bus.rd_idx)
);

rv32i_word alumux1_out, alumux2_out;
// Execute
/******************************** EX **************************************/
EX EX(

    // from ID_EX
    .ctrl_sig_i_EX(ID_EX_bus.ctrl),
    .pc_i_EX(ID_EX_bus.pc),
    .rs1_i_EX(ID_EX_bus.rs1_data),
    .rs2_i_EX(ID_EX_bus.rs2_data),
    .alumux1_i_EX(ID_EX_bus.alumux1_out),
    .alumux2_i_EX(ID_EX_bus.alumux2_out),
    .cmpmux_out_i_EX(ID_EX_bus.cmpmux_out),    
    .rd_i_EX(ID_EX_bus.rd_idx),
    .imm_i_EX(ID_EX_bus.imm),
    .rvfi_sigs_i_EX(ID_EX_bus.rvfi),
    .br_pred_sigs_i(ID_EX_bus.br_pred_sigs),

    // from forwarding
    .EX_MEM_forwarding_alumux1(FOR_bus.EX_MEM_alumux1),
    .EX_MEM_forwarding_alumux2(FOR_bus.EX_MEM_alumux2),
    .EX_MEM_forwarding_cmpmux1(FOR_bus.EX_MEM_cmpmux1),
    .EX_MEM_forwarding_cmpmux2(FOR_bus.EX_MEM_cmpmux2),

    .MEM_WB_forwarding_alumux1(FOR_bus.MEM_WB_alumux1),
    .MEM_WB_forwarding_alumux2(FOR_bus.MEM_WB_alumux2),
    .MEM_WB_forwarding_cmpmux1(FOR_bus.MEM_WB_cmpmux1),
    .MEM_WB_forwarding_cmpmux2(FOR_bus.MEM_WB_cmpmux2),

    .EX_MEM_rs2_forwarding_sel(FOR_bus.rs2_sel),
    .EX_MEM_rs2_forwarding_data(FOR_bus.EX_MEM_rs2),

    .FW_alumux1_sel(FOR_bus.alumux1_sel),
    .FW_alumux2_sel(FOR_bus.alumux2_sel),
    .FW_cmpmux1_sel(FOR_bus.cmpmux1_sel),
    .FW_cmpmux2_sel(FOR_bus.cmpmux2_sel),

    // to EX_MEM
    .ctrl_sig_o_EX(EX_bus.ctrl),
    .pc_plus4_o_EX(EX_bus.pc_plus4),
    .rs2_o_EX(EX_bus.rs2_data),
    .rd_o_EX(EX_bus.rd_idx),
    .imm_o_EX(EX_bus.imm),
    .rvfi_sigs_o_EX(EX_bus.rvfi),

    // to EX_MEM and BP
    .br_en_o_EX(EX_bus.br_en),

    // to EX_MEM and IF
    .alu_out_o_EX(EX_bus.alu_out), 

    // to IF
    .pc_br_not_taken_o(EX_bus.pc_br_not_taken),


    // to M_EXT
    .alumux1_out(alumux1_out),
    .alumux2_out(alumux2_out)
);

logic [31:0] exmem_alu_in;
assign exmem_alu_in = m_extension_load ? m_extension_out : EX_bus.alu_out;

/******************************** EX_MEM **************************************/
EX_MEM Reg3(
    // from top level
    .clk(clk),

    // from hazard
    .rst(HAZ_bus.rst_EX_MEM || rst), // rst from top level
    .load(HAZ_bus.load_EX_MEM),

    // from EX
    .ctrl_i(EX_bus.ctrl),
    .exmem_pc_in(EX_bus.pc_plus4),
    .exmem_rs2_in(EX_bus.rs2_data),
    .exmem_rd_in(EX_bus.rd_idx),
    .exmem_bren_in(EX_bus.br_en), 
    .exmem_alu_in(exmem_alu_in), // M_EXT
    .imm_i_EX_MEM(EX_bus.imm),
    .rvfi_sigs_i_EX_MEM(EX_bus.rvfi),

    // to MEM
    .pc_plus4_o_EX(EX_MEM_bus.pc_plus4),
    .rs2_o_EX(EX_MEM_bus.rs2_data),
    .imm_o_EX_MEM(EX_MEM_bus.imm),
    .rvfi_sigs_o_EX_MEM(EX_MEM_bus.rvfi),

    // to MEM but...
    // load_regfile, regfilemux_sel, opcode to forwarding
    .ctrl_sig_o_EX(EX_MEM_bus.ctrl),

    // to MEM and forwarding
    .rd_o_EX(EX_MEM_bus.rd_idx),
    .br_en_o_EX(EX_MEM_bus.br_en),
    .alu_out_o_EX(EX_MEM_bus.alu_out)
);


// Memory
/******************************** MEM **************************************/
MEM MEM(
    // from EX_MEM 
    .ctrl(EX_MEM_bus.ctrl),
    .alu_out_i(EX_MEM_bus.alu_out), 
    .pc_plus_4(EX_MEM_bus.pc_plus4), 
    .rs2_out(EX_MEM_bus.rs2_data), 
    .rd(EX_MEM_bus.rd_idx), 
    .br_en(EX_MEM_bus.br_en), 
    .imm_i_MEM(EX_MEM_bus.imm),
    .rvfi_sigs_i_MEM(EX_MEM_bus.rvfi),

     // from dcache (top level)
    .mem_rdata(dcache_rdata),

    // to dcache (top level)
    .mem_address_o(dcache_data_addr),
    .mem_wdata(dcache_wdata),
    .mem_byte_en(dcache_mbe),

    // to dcache (top level) and hazard
    .mem_read(dcache_read),
    .mem_write(dcache_write),
    

    // to MEM_WB
    .ctrl_o(MEM_bus.ctrl),
    .data_o(MEM_bus.mem_rdata),
    .alu_out_o(MEM_bus.alu_out),
    .rd_o(MEM_bus.rd_idx), 
    .br_en_o(MEM_bus.br_en), 
    .pc_plus_4_o(MEM_bus.pc_plus4),
    .imm_o_MEM(MEM_bus.imm),
    .rvfi_sigs_o_MEM(MEM_bus.rvfi)
);



/******************************** MEM_WB REG **************************************/
MEM_WB Reg4(
    // from top level
    .clk(clk),
    .rst(rst),

    // from hazard
    .load(HAZ_bus.load_MEM_WB),

    // from MEM
    .ctrl(MEM_bus.ctrl), 
    .mem_rdata_i_MEM_WB(MEM_bus.mem_rdata),
    .alu_out_i_MEM_WB(MEM_bus.alu_out),
    .rd_i_MEM_WB(MEM_bus.rd_idx),
    .br_en_i_MEM_WB(MEM_bus.br_en),
    .pc_plus4_i_MEM_WB(MEM_bus.pc_plus4),
    .imm_i_MEM_WB(MEM_bus.imm), // NOT CONNECTED YET
    .rvfi_sigs_i_MEM_WB(MEM_bus.rvfi),


    // to WB
    .mem_rdata_o_MEM_WB(MEM_WB_bus.mem_rdata),
    .alu_out_o_MEM_WB(MEM_WB_bus.alu_out),
    .br_en_o_MEM_WB(MEM_WB_bus.br_en),
    .imm_o_MEM_WB(MEM_WB_bus.imm),
    .pc_plus4_o_MEM_WB(MEM_WB_bus.pc_plus4),
    .rvfi_sigs_o_MEM_WB(MEM_WB_bus.rvfi),

    // to WB and ID
    .rd_o(MEM_WB_bus.rd_idx),

    // to nowhere but...
    // regfilemux_sel to WB and forwarding
    // load_regfile to ID and forwarding
    .ctrl_to_WB(MEM_WB_bus.ctrl)
);



// Write Back
/******************************** WB **************************************/
WB WB(
    // from MEM_WB
    .mem_rdata(MEM_WB_bus.mem_rdata),
    .alu_out(MEM_WB_bus.alu_out),
    .br_en(MEM_WB_bus.br_en),
    .imm(MEM_WB_bus.imm),
    .pc_plus4(MEM_WB_bus.pc_plus4),
    .regfilemux_sel(MEM_WB_bus.ctrl.regfilemux_sel),
    .rvfi_sigs_i_WB(MEM_WB_bus.rvfi),
    .rd_i_WB(MEM_WB_bus.rd_idx),

    // to ID
    .regfilemux_out(WB_bus.regfilemux_out)
);

 

// hazard detection
hazard_detection hazard_detection(
    // from MEM
    .dcache_read(dcache_read),
    .dcache_write(dcache_write),

    // from icache and dcache (top level)
    .dcache_resp(dcache_resp),
    .icache_resp(icache_resp),

    // from EX
    .opcode(EX_bus.ctrl.opcode),
    .pcmux_sel(EX_bus.ctrl.pcmux_sel),
    

    // to registers
    .load_IF_ID(HAZ_bus.load_IF_ID),
    .load_ID_EX(HAZ_bus.load_ID_EX),
    .load_EX_MEM(HAZ_bus.load_EX_MEM),
    .load_MEM_WB(HAZ_bus.load_MEM_WB),

    .rst_IF_ID(HAZ_bus.rst_IF_ID),
    .rst_ID_EX(HAZ_bus.rst_ID_EX),
    .rst_EX_MEM(HAZ_bus.rst_EX_MEM),

    // to BR
    .is_stalling(HAZ_bus.is_stalling),

    // to IF
    .load_pc(HAZ_bus.load_pc),

    // to forwarding
    .is_bubble(HAZ_bus.is_bubble),

    //m_ext
    .m_extension_load(m_extension_load),
    .m_extension_resp(m_extension_resp)
);

// forwarding
forwarding forwarding(

    // from IF_ID
    .rs1_idx_o_IF_ID(IF_ID_bus.rs1),
    .rs2_idx_o_IF_ID(IF_ID_bus.rs2),

    // from ID_EX
    .opcode_o_ID_EX(ID_EX_bus.ctrl.opcode),
    .rs1_idx_o_ID_EX(ID_EX_bus.rs1_idx),
    .rs2_idx_o_ID_EX(ID_EX_bus.rs2_idx),
    .rd_idx_o_ID_EX(ID_EX_bus.rd_idx),

    // from EX_MEM
    .rd_idx_o_EX_MEM(EX_MEM_bus.rd_idx),
    .br_en_o_EX_MEM(EX_MEM_bus.br_en),
    .alu_out_o_EX_MEM(EX_MEM_bus.alu_out),
    .load_regfile_o_EX_MEM(EX_MEM_bus.ctrl.load_regfile),
    .regfilemux_sel_o_EX_MEM(EX_MEM_bus.ctrl.regfilemux_sel),
    .opcode_o_EX_MEM(EX_MEM_bus.ctrl.opcode),
    .imm_EX_MEM(EX_MEM_bus.imm),
    .pc_plus4_EX_MEM(EX_MEM_bus.pc_plus4),

    // from MEM_WB
    .rd_idx_o_MEM_WB(MEM_WB_bus.rd_idx),
    .br_en_o_MEM_WB(MEM_WB_bus.br_en),
    .mem_rdata_o_MEM_WB(MEM_WB_bus.mem_rdata),
    .alu_out_o_MEM_WB(MEM_WB_bus.alu_out),
    .opcode_o_MEM_WB(MEM_WB_bus.ctrl.opcode),
    .load_regfile_o_MEM_WB(MEM_WB_bus.ctrl.load_regfile),
    .regfilemux_sel_o_MEM_WB(MEM_WB_bus.ctrl.regfilemux_sel),
    .imm_MEM_WB(MEM_WB_bus.imm),
    .pc_plus4_MEM_WB(MEM_WB_bus.pc_plus4),

    // to hazard
    .is_bubble(HAZ_bus.is_bubble),
    
    // to EX
    .EX_MEM_forwarding_alumux1(FOR_bus.EX_MEM_alumux1),
    .EX_MEM_forwarding_alumux2(FOR_bus.EX_MEM_alumux2),
    .EX_MEM_forwarding_cmpmux1(FOR_bus.EX_MEM_cmpmux1),
    .EX_MEM_forwarding_cmpmux2(FOR_bus.EX_MEM_cmpmux2),

    .MEM_WB_forwarding_alumux1(FOR_bus.MEM_WB_alumux1),
    .MEM_WB_forwarding_alumux2(FOR_bus.MEM_WB_alumux2),
    .MEM_WB_forwarding_cmpmux1(FOR_bus.MEM_WB_cmpmux1),
    .MEM_WB_forwarding_cmpmux2(FOR_bus.MEM_WB_cmpmux2),

    .EX_MEM_rs2_forwarding_sel(FOR_bus.rs2_sel),
    .EX_MEM_rs2_forwarding_data(FOR_bus.EX_MEM_rs2),

    .FW_alumux1_sel(FOR_bus.alumux1_sel),
    .FW_alumux2_sel(FOR_bus.alumux2_sel),
    .FW_cmpmux1_sel(FOR_bus.cmpmux1_sel),
    .FW_cmpmux2_sel(FOR_bus.cmpmux2_sel)
);

//m_extension
assign m_extension_load = ((ID_EX_bus.ctrl.opcode == rv32i_types::op_reg)&&(ID_EX_bus.ctrl.funct7 == 7'd1));
m_extension m_ext(
    .clk(clk), 
    .rst(HAZ_bus.rst_ID_EX), 
    .a(alumux1_out), 
    .b(alumux2_out), 
    .m_extension_load(m_extension_load), 
    .funct3(ID_EX_bus.ctrl.funct3), 
    .m_extension_out(m_extension_out),
    .m_extension_resp(m_extension_resp)
);


/*****************************************************************************/
endmodule : datapath