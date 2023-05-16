module control_rom
import rv32i_types::*;
(
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,

    output rv32i_control_word ctrl
);

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign branch_funct3 = branch_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign arith_funct3 = arith_funct3_t'(funct3);

function void loadRegfile(regfilemux::regfilemux_sel_t regfilemux_sel);
    ctrl.load_regfile = 1'b1;
    ctrl.regfilemux_sel = regfilemux_sel;
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t cmpmux_sel, branch_funct3_t op);
    ctrl.cmpop = op;
    ctrl.cmpmux_sel = cmpmux_sel;
endfunction


always_comb begin
    /*Default Assignments*/
    ctrl.opcode = opcode; 
    ctrl.load_pc = 1'b0;
    ctrl.load_regfile = 1'b0;
    ctrl.aluop = alu_ops'(funct3);
    ctrl.cmpop = branch_funct3;
    ctrl.mem_read = 1'b0;
    ctrl.mem_write =1'b0;
    ctrl.mem_byte_enable = 4'b1111;
    ctrl.regfilemux_sel = regfilemux::alu_out;
    ctrl.pcmux_sel = pcmux::pc_plus4;
    ctrl.immmux_sel = immmux::i_imm;
    ctrl.alumux1_sel = alumux::rs1_out;
    ctrl.alumux2_sel = alumux::imm;
    ctrl.cmpmux_sel = cmpmux::rs2_out;
    ctrl.store_funct3 = store_funct3;
    ctrl.funct7 = funct7;
    ctrl.funct3 = funct3;
    /*Assign control signals based on opcode*/
    case(opcode)
        op_lui: begin
            ctrl.load_pc = 1'b1;
            loadRegfile(regfilemux::u_imm);
            ctrl.immmux_sel = immmux::u_imm;
        end
        op_auipc: begin
            ctrl.load_pc = 1'b1; //????????????????????????
            loadRegfile(regfilemux::alu_out);
            ctrl.aluop = alu_add;
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::imm;
            ctrl.immmux_sel = immmux::u_imm;
        end
        op_jal: begin
            //ctrl.pcmux_sel = pcmux::alu_mod2;
            loadRegfile(regfilemux::pc_plus4);
            ctrl.load_pc = 1'b1;
            ctrl.aluop = alu_add;
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::imm;
            ctrl.immmux_sel = immmux::j_imm;
        end
        op_jalr: begin
            //ctrl.pcmux_sel = pcmux::alu_mod2;
            ctrl.aluop = alu_add;
            loadRegfile(regfilemux::pc_plus4);
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::imm;
            ctrl.immmux_sel = immmux::i_imm;
        end
        op_br: begin
            //ctrl.pcmux_sel = pcmux::pcmux_sel_t'(br_en);/////
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.cmpmux_sel = cmpmux::rs2_out;
            ctrl.alumux2_sel = alumux::imm;
            ctrl.immmux_sel = immmux::b_imm;
            ctrl.aluop = alu_add;
        end
        op_load: begin
            ctrl.aluop = alu_add;
            ctrl.mem_read = 1'b1;
            case(load_funct3)
                lb:loadRegfile(regfilemux::lb);
                lh:loadRegfile(regfilemux::lh);
                lw:loadRegfile(regfilemux::lw);
                lbu:loadRegfile(regfilemux::lbu);
                lhu:loadRegfile(regfilemux::lhu);
                default: loadRegfile(regfilemux::lw);
            endcase
        end
        op_store: begin
            ctrl.mem_write = 1'b1;
            ctrl.aluop = alu_add;
            ctrl.store_funct3 = store_funct3;
            ctrl.alumux2_sel = alumux::imm;
            ctrl.immmux_sel = immmux::s_imm;
        end
        op_imm: begin
            case(arith_funct3)
                slt:begin
                    loadRegfile(regfilemux::br_en);
                    setCMP(cmpmux::imm,blt);
                end
                sltu:begin
                    loadRegfile(regfilemux::br_en);
                    setCMP(cmpmux::imm,bltu);
                end
                sr:begin
                    loadRegfile(regfilemux::alu_out);
                    ctrl.aluop = funct7 ? alu_sra: alu_srl;
                end
                default: begin
                    loadRegfile(regfilemux::alu_out);
                    ctrl.aluop = alu_ops'(funct3);
                end
            endcase
        end
        op_reg:begin
            // if(funct7 == 7'd1) loadRegfile(regfilemux::alu_out);
            // else begin
                case(arith_funct3)
                slt:begin
                    loadRegfile(regfilemux::br_en);
                    setCMP(cmpmux::rs2_out,blt);
                end
                sltu:begin
                    loadRegfile(regfilemux::br_en);
                    setCMP(cmpmux::rs2_out,bltu);
                end
                sr:begin
                    loadRegfile(regfilemux::alu_out);
                    ctrl.alumux2_sel = alumux::rs2_out;
                    ctrl.aluop = funct7 ? alu_sra : alu_srl;
                end
                default: begin
                    loadRegfile(regfilemux::alu_out);
                    if(arith_funct3 == add)
                        ctrl.aluop = funct7 ? alu_sub:alu_add;
                    else
                        ctrl.aluop = alu_ops'(funct3);
                    ctrl.alumux2_sel = alumux::rs2_out;
                end
                
                endcase
            //end
        end
        default: begin
            ctrl = '0;  /*Unknown opcode, set control word to zero*/
        end
    endcase
end
endmodule: control_rom