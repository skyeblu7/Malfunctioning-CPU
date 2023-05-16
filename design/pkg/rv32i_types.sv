package rv32i_types;
// Mux types are in their own packages to prevent identiier collisions
// e.g. pcmux::pc_plus4 and regfilemux::pc_plus4 are seperate identifiers
// for seperate enumerated types
import pcmux::*;
import marmux::*;
import cmpmux::*;
import alumux::*;
import regfilemux::*;

import immmux::*;

typedef logic [31:0] rv32i_word;
typedef logic [4:0] rv32i_reg;
typedef logic [3:0] rv32i_mem_wmask;

typedef enum bit [6:0] {
    op_lui   = 7'b0110111, //load upper immediate (U type)
    op_auipc = 7'b0010111, //add upper immediate PC (U type)
    op_jal   = 7'b1101111, //jump and link (J type)
    op_jalr  = 7'b1100111, //jump and link register (I type)
    op_br    = 7'b1100011, //branch (B type)
    op_load  = 7'b0000011, //load (I type)
    op_store = 7'b0100011, //store (S type)
    op_imm   = 7'b0010011, //arith ops with register/immediate operands (I type)
    op_reg   = 7'b0110011, //arith ops with register operands (R type)
    op_csr   = 7'b1110011,  //control and status register (I type)
    op_bubble = 7'd0
} rv32i_opcode;

typedef enum bit [2:0] {
    beq  = 3'b000,
    bne  = 3'b001,
    blt  = 3'b100,
    bge  = 3'b101,
    bltu = 3'b110,
    bgeu = 3'b111
} branch_funct3_t;

typedef enum bit [2:0] {
    lb  = 3'b000,
    lh  = 3'b001,
    lw  = 3'b010,
    lbu = 3'b100,
    lhu = 3'b101
} load_funct3_t;

typedef enum bit [2:0] {
    sb = 3'b000,
    sh = 3'b001,
    sw = 3'b010
} store_funct3_t;

typedef enum bit [2:0] {
    add  = 3'b000, //check bit30 for sub if op_reg opcode
    sll  = 3'b001,
    slt  = 3'b010,
    sltu = 3'b011,
    axor = 3'b100,
    sr   = 3'b101, //check bit30 for logical/arithmetic
    aor  = 3'b110,
    aand = 3'b111
} arith_funct3_t;

typedef enum bit [2:0] {
    alu_add = 3'b000,
    alu_sll = 3'b001,
    alu_sra = 3'b010,
    alu_sub = 3'b011,
    alu_xor = 3'b100,
    alu_srl = 3'b101,
    alu_or  = 3'b110,
    alu_and = 3'b111
} alu_ops;


typedef struct packed{
    rv32i_opcode opcode;

    logic mem_read, mem_write;
    logic [3:0] mem_byte_enable;

    logic load_regfile;
    logic load_pc;

    regfilemux::regfilemux_sel_t regfilemux_sel;
    pcmux::pcmux_sel_t pcmux_sel;
    immmux::immmux_sel_t immmux_sel;
    alumux::alumux1_sel_t alumux1_sel;
    alumux::alumux2_sel_t alumux2_sel;
    cmpmux::cmpmux_sel_t cmpmux_sel;

    branch_funct3_t cmpop;
    store_funct3_t store_funct3;
    alu_ops aluop;

    logic [6:0] funct7;
    logic [2:0] funct3;

} rv32i_control_word;

typedef struct packed{
// Regfile:
    logic [4:0] rs1_addr;// rs1 idx 
    logic [4:0] rs2_addr; // rs2 idx  
    rv32i_word rs1_rdata; // data in rs1  
    rv32i_word rs2_rdata; // data in rs2  
    logic load_regfile; // load_regfile 
    logic [4:0] rd_addr; // rd idx    
    rv32i_word rd_wdata; // data in rd 

// instr:
    rv32i_word inst; // the decoded instruction

// PC:
    rv32i_word pc_rdata; // current pc
    rv32i_word pc_wdata; // next pc

// Memory (dcache):
    rv32i_word mem_addr; // mem_addr
    logic [3:0] mem_rmask; // bytes reading from
    logic [3:0] mem_wmask; // butes writing to
    rv32i_word mem_rdata; // data read from cache
    rv32i_word mem_wdata; // data writing to cache

// opcode
    rv32i_opcode opcode;
} rvfi_sigs;





typedef struct packed{
    // from IF to EX
    logic br_pred;
    logic btb_hit;
    rv32i_word btb_target;
    rv32i_word pc_br_not_taken;
    rv32i_word pc_EX;
} br_pred_sigs;

// DATAPATH BUSES

typedef struct packed{
    // to IF_ID reg
    rv32i_word inst;
    rvfi_sigs rvfi;
    br_pred_sigs br_pred_sigs;

    // to IF_ID reg, BTB and BP
    rv32i_word pc;
} IF_O;

typedef struct packed{
    // to ID
    br_pred_sigs br_pred_sigs;
    rv32i_word pc;
    logic [2:0] funct3;
    logic [6:0] funct7;
    rv32i_opcode opcode;
    logic [31:0] i_imm;
    logic [31:0] s_imm;
    logic [31:0] b_imm;
    logic [31:0] u_imm;
    logic [31:0] j_imm;
    logic [4:0] rd_idx;
    rvfi_sigs rvfi;

    // to ID, forwarding and ID_EX
    logic [4:0] rs1;
    logic [4:0] rs2;
} IF_ID_O;

typedef struct packed{
    // to ID_EX
    rv32i_control_word ctrl; // opcode to forwarding
    logic [4:0] rd_idx;
    rv32i_word pc;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    rv32i_word alumux1_out;
    rv32i_word alumux2_out;
    rv32i_word cmpmux_out;
    rv32i_word imm; 
    br_pred_sigs br_pred_sigs;
    rvfi_sigs rvfi;
} ID_O;

typedef struct packed{
    // to EX
    rv32i_control_word ctrl;
    rv32i_word rs1_data;
    rv32i_word rs2_data;
    rv32i_word alumux1_out;
    rv32i_word alumux2_out;
    rv32i_word cmpmux_out;
    rv32i_word imm;
    rvfi_sigs rvfi;

    // to EX but...
    // br_pred to BP
    // pc_EX to BP
    br_pred_sigs br_pred_sigs;

    // to EX and BTB
    rv32i_word pc;

    // to forwarding
    logic [4:0] rs1_idx;
    logic [4:0] rs2_idx;

    // to EX and forwarding
    logic [4:0] rd_idx;

} ID_EX_O;

typedef struct packed{

    // to EX_MEM
    rv32i_word pc_plus4;
    rv32i_word rs2_data;
    logic [4:0] rd_idx;
    rv32i_word imm;
    rvfi_sigs rvfi;

    // to EX_MEM but...
    // opcode to hazard, BTB and BP
    // pcmux_sel to IF, hazard
    rv32i_control_word ctrl; 

    // to EX_MEM, IF and BTB
    rv32i_word alu_out;

    // to IF
    rv32i_word pc_br_not_taken;

    // to EX_MEM, BP
    logic br_en;

} EX_O;

typedef struct packed{
    // to MEM
    rv32i_word pc_plus4;
    rv32i_word rs2_data;
    rvfi_sigs rvfi;

    // to MEM but...
    // load_regfile, regfilemux_sel, opcode to forwarding
    rv32i_control_word ctrl;
    
    // to MEM and forwarding
    logic [4:0] rd_idx;
    logic br_en;
    rv32i_word alu_out;
    rv32i_word imm;
} EX_MEM_O;

typedef struct packed{
    // to MEM_WB
    rv32i_control_word ctrl;
    rv32i_word mem_rdata;
    rv32i_word alu_out;
    logic [4:0] rd_idx;
    logic br_en;
    rv32i_word pc_plus4;
    rv32i_word imm; 
    rvfi_sigs rvfi;

    // to hazard and top level
    // dcache_read
    // dcache_write
} MEM_O;

typedef struct packed{
    // to WB
    rv32i_word pc_plus4;
    rvfi_sigs rvfi;

    // to WB, ID and forwarding
    rv32i_word mem_rdata;
    rv32i_word alu_out;
    logic [4:0] rd_idx;
    logic br_en;
    rv32i_word imm;

    // nowhere but...
    // regfilemux_sel to WB and forwarding
    // load_regfile to ID and forwarding
    // opcode to forwarding
    rv32i_control_word ctrl;
} MEM_WB_O;

typedef struct packed{
    // to ID
    rv32i_word regfilemux_out;
} WB_O;

typedef struct packed{
    // load signals
    logic load_IF_ID;
    logic load_ID_EX;
    logic load_EX_MEM;
    logic load_MEM_WB;

    // rst signals
    logic rst_IF_ID;
    logic rst_ID_EX;
    logic rst_EX_MEM;

    // to BP
    logic is_stalling;

    // to IF
    logic load_pc;

    // to forwarding 
    logic is_bubble;
} HAZ_O;

typedef struct packed{
    // to EX
    rv32i_word EX_MEM_alumux1;
    rv32i_word EX_MEM_alumux2;
    rv32i_word EX_MEM_cmpmux1;
    rv32i_word EX_MEM_cmpmux2;

    rv32i_word MEM_WB_alumux1;
    rv32i_word MEM_WB_alumux2;
    rv32i_word MEM_WB_cmpmux1;
    rv32i_word MEM_WB_cmpmux2;

    logic [1:0] alumux1_sel;
    logic [1:0] alumux2_sel;
    logic [1:0] cmpmux1_sel;
    logic [1:0] cmpmux2_sel;

    logic rs2_sel;
    rv32i_word EX_MEM_rs2;
} FOR_O;

typedef struct packed{
    // to IF
    logic pred;
} BP_O;

typedef struct packed{
    // to IF
    rv32i_word target;

    // to IF
    logic hit;
} BTB_O;


endpackage : rv32i_types

