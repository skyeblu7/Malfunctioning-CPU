module forwarding
import rv32i_types::*;
(
    input logic [4:0] rs1_idx_o_ID_EX,
    input logic [4:0] rs2_idx_o_ID_EX,

    input logic [4:0] rd_idx_o_MEM_WB,
    input logic [4:0] rd_idx_o_EX_MEM,

    input logic [4:0] rs1_idx_o_IF_ID,
    input logic [4:0] rs2_idx_o_IF_ID,
    input logic [4:0] rd_idx_o_ID_EX,

    //for bubble
    input rv32i_opcode opcode_o_EX_MEM, //EX_MEM_ctrl_o.opcode
    output logic is_bubble,

    input rv32i_opcode opcode_o_ID_EX,
    input rv32i_opcode opcode_o_MEM_WB,

    input logic load_regfile_o_EX_MEM,
    input logic load_regfile_o_MEM_WB,

    input logic br_en_o_EX_MEM,
    input logic br_en_o_MEM_WB,

    input rv32i_word mem_rdata_o_MEM_WB,

    input rv32i_word alu_out_o_EX_MEM,
    input rv32i_word alu_out_o_MEM_WB,

    input rv32i_word imm_EX_MEM,
    input rv32i_word imm_MEM_WB,

    input rv32i_word pc_plus4_EX_MEM,
    input rv32i_word pc_plus4_MEM_WB,

    input logic [3:0] regfilemux_sel_o_EX_MEM,
    input logic [3:0] regfilemux_sel_o_MEM_WB,

    output rv32i_word EX_MEM_forwarding_alumux1,
    output rv32i_word EX_MEM_forwarding_alumux2,
    output rv32i_word EX_MEM_forwarding_cmpmux1,
    output rv32i_word EX_MEM_forwarding_cmpmux2,

    output rv32i_word MEM_WB_forwarding_alumux1,
    output rv32i_word MEM_WB_forwarding_alumux2,
    output rv32i_word MEM_WB_forwarding_cmpmux1,
    output rv32i_word MEM_WB_forwarding_cmpmux2,

    output logic [1:0] FW_alumux1_sel,
    output logic [1:0] FW_alumux2_sel,
    output logic [1:0] FW_cmpmux1_sel,
    output logic [1:0] FW_cmpmux2_sel,

    //rs2 forwarding
    output logic EX_MEM_rs2_forwarding_sel,
    output rv32i_word EX_MEM_rs2_forwarding_data
     
);


function void set_alu_defaults();
    EX_MEM_forwarding_alumux1 = 32'd0;
    EX_MEM_forwarding_alumux2 = 32'd0;
    MEM_WB_forwarding_alumux1 = 32'd0;
    MEM_WB_forwarding_alumux2 = 32'd0;
    FW_alumux1_sel = 2'b00;
    FW_alumux2_sel = 2'b00;
endfunction

function void set_cmp_defaults();
    EX_MEM_forwarding_cmpmux1 = 32'd0;
    EX_MEM_forwarding_cmpmux2 = 32'd0;
    MEM_WB_forwarding_cmpmux1 = 32'd0;
    MEM_WB_forwarding_cmpmux2 = 32'd0;
    FW_cmpmux1_sel = 2'b00;
    FW_cmpmux2_sel = 2'b00;
endfunction

function void set_rs2_forwarding_defaults();
    EX_MEM_rs2_forwarding_sel = 1'b0;
    EX_MEM_rs2_forwarding_data = 32'd0;
endfunction

always_comb begin : bubble
    if(opcode_o_ID_EX == rv32i_types::op_load && ((rd_idx_o_ID_EX == rs1_idx_o_IF_ID) || (rd_idx_o_ID_EX == rs2_idx_o_IF_ID))) is_bubble = 1'b1; 
    else is_bubble = 1'b0;
end

logic is_jump;
assign is_jump = opcode_o_ID_EX == rv32i_types::op_br; 


logic [1:0] forwarding_condition;
assign forwarding_condition = ~is_jump ? 
                            {load_regfile_o_EX_MEM,load_regfile_o_MEM_WB} : 2'b00;



// ALU FORWARDING****************
always_comb begin
    set_alu_defaults();
    unique case(forwarding_condition)
        2'b00: ;
        2'b01: begin
            if(rd_idx_o_MEM_WB == rs1_idx_o_ID_EX && rd_idx_o_MEM_WB != 5'd0) begin
                FW_alumux1_sel = 2'b10;
                if(rs1_idx_o_ID_EX == 5'd0) 
                    MEM_WB_forwarding_alumux1 = 32'd0;
                else if(regfilemux_sel_o_MEM_WB == regfilemux::br_en)
                    MEM_WB_forwarding_alumux1 = {31'd0, br_en_o_MEM_WB};
                else if(regfilemux_sel_o_MEM_WB == regfilemux::u_imm)
                    MEM_WB_forwarding_alumux1 = imm_MEM_WB;
                else if(regfilemux_sel_o_MEM_WB == regfilemux::pc_plus4)
                    MEM_WB_forwarding_alumux1 = pc_plus4_MEM_WB;
                else
                    MEM_WB_forwarding_alumux1 = (opcode_o_MEM_WB == rv32i_types::op_load) ? mem_rdata_o_MEM_WB : alu_out_o_MEM_WB;
            end
            if(rd_idx_o_MEM_WB == rs2_idx_o_ID_EX && rd_idx_o_MEM_WB != 5'd0) begin
                FW_alumux2_sel = 2'b10;
                if(rs2_idx_o_ID_EX == 5'd0) 
                    MEM_WB_forwarding_alumux2 = 32'd0;
                else if(regfilemux_sel_o_MEM_WB == regfilemux::br_en) 
                    MEM_WB_forwarding_alumux2 = {31'd0, br_en_o_MEM_WB};
                else if(regfilemux_sel_o_MEM_WB == regfilemux::u_imm)
                    MEM_WB_forwarding_alumux2 = imm_MEM_WB;
                else if(regfilemux_sel_o_MEM_WB == regfilemux::pc_plus4)
                    MEM_WB_forwarding_alumux2 = pc_plus4_MEM_WB;
                else MEM_WB_forwarding_alumux2 = (opcode_o_MEM_WB == rv32i_types::op_load) ? mem_rdata_o_MEM_WB : alu_out_o_MEM_WB;
            end
        end
        2'b10: begin
            if(rd_idx_o_EX_MEM == rs1_idx_o_ID_EX && rd_idx_o_EX_MEM != 5'd0) begin
                FW_alumux1_sel = 2'b01;
                if(rs1_idx_o_ID_EX == 5'd0) 
                    EX_MEM_forwarding_alumux1 = 32'd0;
                else if(regfilemux_sel_o_EX_MEM == regfilemux::br_en)
                    EX_MEM_forwarding_alumux1 = {31'd0, br_en_o_EX_MEM};
                else if(regfilemux_sel_o_EX_MEM == regfilemux::u_imm)
                    EX_MEM_forwarding_alumux1 = imm_EX_MEM;
                else if(regfilemux_sel_o_EX_MEM == regfilemux::pc_plus4)
                    EX_MEM_forwarding_alumux1 = pc_plus4_EX_MEM;
                else
                    EX_MEM_forwarding_alumux1 = alu_out_o_EX_MEM; 
            end

            if(rd_idx_o_EX_MEM == rs2_idx_o_ID_EX && rd_idx_o_EX_MEM != 5'd0) begin
                FW_alumux2_sel = 2'b01;
                if(rs2_idx_o_ID_EX == 5'd0) 
                    EX_MEM_forwarding_alumux2 = 32'd0;
                else if(regfilemux_sel_o_EX_MEM == regfilemux::br_en)
                    EX_MEM_forwarding_alumux2 = {31'd0, br_en_o_EX_MEM};
                else if(regfilemux_sel_o_EX_MEM == regfilemux::u_imm)
                    EX_MEM_forwarding_alumux2 = imm_EX_MEM;
                else if(regfilemux_sel_o_EX_MEM == regfilemux::pc_plus4)
                    EX_MEM_forwarding_alumux2 = pc_plus4_EX_MEM;
                else
                    EX_MEM_forwarding_alumux2 = alu_out_o_EX_MEM;
            end
        end

        2'b11: begin
            if(rd_idx_o_EX_MEM == rd_idx_o_MEM_WB && rd_idx_o_MEM_WB != 5'd0) begin
                if(rd_idx_o_EX_MEM == rs1_idx_o_ID_EX) begin
                    FW_alumux1_sel = 2'b01;
                    if(rs1_idx_o_ID_EX == 5'd0) 
                        EX_MEM_forwarding_alumux1 = 32'd0;
                    else if(regfilemux_sel_o_EX_MEM == regfilemux::br_en)
                        EX_MEM_forwarding_alumux1 = {31'd0, br_en_o_EX_MEM};
                    else if(regfilemux_sel_o_EX_MEM == regfilemux::u_imm)
                        EX_MEM_forwarding_alumux1 = imm_EX_MEM;
                    else if(regfilemux_sel_o_EX_MEM == regfilemux::pc_plus4)
                        EX_MEM_forwarding_alumux1 = pc_plus4_EX_MEM;
                    else
                        EX_MEM_forwarding_alumux1 = alu_out_o_EX_MEM;
                end
                if(rd_idx_o_EX_MEM == rs2_idx_o_ID_EX) begin
                    FW_alumux2_sel = 2'b01;
                    if(rs2_idx_o_ID_EX == 5'd0) 
                        EX_MEM_forwarding_alumux2 = 32'd0;
                    else if(regfilemux_sel_o_EX_MEM == regfilemux::br_en)
                        EX_MEM_forwarding_alumux2 = {31'd0, br_en_o_EX_MEM};
                    else if(regfilemux_sel_o_EX_MEM == regfilemux::u_imm)
                        EX_MEM_forwarding_alumux2 = imm_EX_MEM;
                    else if(regfilemux_sel_o_EX_MEM == regfilemux::pc_plus4)
                        EX_MEM_forwarding_alumux2 = pc_plus4_EX_MEM;
                    else
                        EX_MEM_forwarding_alumux2 = alu_out_o_EX_MEM;
                end
            end
            else begin
                if(rd_idx_o_EX_MEM == rs1_idx_o_ID_EX && rd_idx_o_EX_MEM != 5'd0) begin
                    FW_alumux1_sel = 2'b01;
                    if(rs1_idx_o_ID_EX == 5'd0) 
                        EX_MEM_forwarding_alumux1 = 32'd0;
                    else if(regfilemux_sel_o_EX_MEM == regfilemux::br_en)
                        EX_MEM_forwarding_alumux1 = {31'd0, br_en_o_EX_MEM};
                    else if(regfilemux_sel_o_EX_MEM == regfilemux::u_imm)
                        EX_MEM_forwarding_alumux1 = imm_EX_MEM;
                    else if(regfilemux_sel_o_EX_MEM == regfilemux::pc_plus4)
                        EX_MEM_forwarding_alumux1 = pc_plus4_EX_MEM;
                    else
                        EX_MEM_forwarding_alumux1 = alu_out_o_EX_MEM;
                end
                else if(rd_idx_o_MEM_WB == rs1_idx_o_ID_EX && rd_idx_o_MEM_WB != 5'd0) begin
                    FW_alumux1_sel = 2'b10;
                    if(rs1_idx_o_ID_EX == 5'd0) 
                        MEM_WB_forwarding_alumux1 = 32'd0;
                    else if(regfilemux_sel_o_MEM_WB == regfilemux::br_en)
                        MEM_WB_forwarding_alumux1 = {31'd0, br_en_o_MEM_WB};
                    else if(regfilemux_sel_o_MEM_WB == regfilemux::u_imm)
                        MEM_WB_forwarding_alumux1 = imm_MEM_WB;
                    else if(regfilemux_sel_o_MEM_WB == regfilemux::pc_plus4)
                        MEM_WB_forwarding_alumux1 = pc_plus4_MEM_WB;
                    else
                        MEM_WB_forwarding_alumux1 = (opcode_o_MEM_WB == rv32i_types::op_load) ? mem_rdata_o_MEM_WB : alu_out_o_MEM_WB;
                end
                if(rd_idx_o_EX_MEM == rs2_idx_o_ID_EX && rd_idx_o_EX_MEM != 5'd0) begin
                    FW_alumux2_sel = 2'b01;
                    if(rs2_idx_o_ID_EX == 5'd0) 
                        EX_MEM_forwarding_alumux2 = 32'd0;
                    else if(regfilemux_sel_o_EX_MEM == regfilemux::br_en)
                        EX_MEM_forwarding_alumux2 = {31'd0, br_en_o_EX_MEM};
                    else if(regfilemux_sel_o_EX_MEM == regfilemux::u_imm)
                        EX_MEM_forwarding_alumux2 = imm_EX_MEM;
                    else if(regfilemux_sel_o_EX_MEM == regfilemux::pc_plus4)
                        EX_MEM_forwarding_alumux2 = pc_plus4_EX_MEM;
                    else
                        EX_MEM_forwarding_alumux2 = alu_out_o_EX_MEM;
                end
                else if(rd_idx_o_MEM_WB == rs2_idx_o_ID_EX && rd_idx_o_MEM_WB != 5'd0) begin
                    FW_alumux2_sel = 2'b10;
                    if(rs2_idx_o_ID_EX == 5'd0) 
                        MEM_WB_forwarding_alumux2 = 32'd0;
                    else if(regfilemux_sel_o_MEM_WB == regfilemux::br_en) 
                        MEM_WB_forwarding_alumux2 = {31'd0, br_en_o_MEM_WB};
                    else if(regfilemux_sel_o_MEM_WB == regfilemux::u_imm)
                        MEM_WB_forwarding_alumux2 = imm_MEM_WB;
                    else if(regfilemux_sel_o_MEM_WB == regfilemux::pc_plus4)
                        MEM_WB_forwarding_alumux2 = pc_plus4_MEM_WB;
                    else MEM_WB_forwarding_alumux2 = (opcode_o_MEM_WB == rv32i_types::op_load) ? mem_rdata_o_MEM_WB : alu_out_o_MEM_WB;
                end
            end
        end

        default: ;

    endcase

    if(opcode_o_ID_EX == rv32i_types::op_store)
        FW_alumux2_sel = 2'b00;
end


/***************CMP FORWARDING***************/
always_comb begin
    set_cmp_defaults();


    if(rs1_idx_o_ID_EX == rd_idx_o_EX_MEM && rd_idx_o_EX_MEM != 5'd0) begin
        // 01 for EX_MEM forwarding
        FW_cmpmux1_sel = 2'b01;
        // check if it is r0
        if(rs1_idx_o_ID_EX == 5'd0) begin
            EX_MEM_forwarding_cmpmux1 = 32'd0;
        end
        else if (regfilemux_sel_o_EX_MEM == regfilemux::br_en) begin
            EX_MEM_forwarding_cmpmux1 = {31'd0, br_en_o_EX_MEM};
        end
        else if(regfilemux_sel_o_EX_MEM == regfilemux::u_imm)
            EX_MEM_forwarding_cmpmux1 = imm_EX_MEM;
        else if(regfilemux_sel_o_EX_MEM == regfilemux::pc_plus4)
            EX_MEM_forwarding_cmpmux1 = pc_plus4_EX_MEM;
        else EX_MEM_forwarding_cmpmux1 = alu_out_o_EX_MEM;
    end
    else if(rs1_idx_o_ID_EX == rd_idx_o_MEM_WB && rd_idx_o_MEM_WB != 5'd0) begin
        // 10 for MEM_WB_forwarding
        FW_cmpmux1_sel = 2'b10; 
        // check if it is r0
        if(rs1_idx_o_ID_EX == 5'd0) begin
            MEM_WB_forwarding_cmpmux1 = 32'd0;
        end
        else if(regfilemux_sel_o_MEM_WB == regfilemux::br_en) begin
            MEM_WB_forwarding_cmpmux1 = {31'd0, br_en_o_MEM_WB};
        end   
        else if(regfilemux_sel_o_MEM_WB == regfilemux::u_imm)
            MEM_WB_forwarding_cmpmux1 = imm_MEM_WB;
        else if(regfilemux_sel_o_MEM_WB == regfilemux::pc_plus4)
            MEM_WB_forwarding_cmpmux1 = pc_plus4_MEM_WB;
        else MEM_WB_forwarding_cmpmux1 = (opcode_o_MEM_WB == rv32i_types::op_load) ? mem_rdata_o_MEM_WB : alu_out_o_MEM_WB;
    end



    if(rs2_idx_o_ID_EX == rd_idx_o_EX_MEM && rd_idx_o_EX_MEM != 5'd0) begin
        // 01 for EX_MEM forwarding
        FW_cmpmux2_sel = 2'b01;
        // check if it is r0
        if(rs2_idx_o_ID_EX == 5'd0) begin
            EX_MEM_forwarding_cmpmux2 = 32'd0;
        end
        else if (regfilemux_sel_o_EX_MEM == regfilemux::br_en) begin
            EX_MEM_forwarding_cmpmux2 = {31'd0, br_en_o_EX_MEM};
        end
        else if(regfilemux_sel_o_EX_MEM == regfilemux::u_imm)
            EX_MEM_forwarding_cmpmux2 = imm_EX_MEM;
        else if(regfilemux_sel_o_EX_MEM == regfilemux::pc_plus4)
            EX_MEM_forwarding_cmpmux2 = pc_plus4_EX_MEM;
        else EX_MEM_forwarding_cmpmux2 = alu_out_o_EX_MEM;
    end

    else if(rs2_idx_o_ID_EX == rd_idx_o_MEM_WB && rd_idx_o_MEM_WB != 5'd0) begin
        // 10 for MEM_WB_forwarding
        FW_cmpmux2_sel = 2'b10; 
        // check if it is r0
        if(rs2_idx_o_ID_EX == 5'd0) begin
            MEM_WB_forwarding_cmpmux2 = 32'd0;
        end
        else if(regfilemux_sel_o_MEM_WB == regfilemux::br_en) begin
            MEM_WB_forwarding_cmpmux2 = {31'd0, br_en_o_MEM_WB};
        end   
        else if(regfilemux_sel_o_MEM_WB == regfilemux::u_imm)
            MEM_WB_forwarding_cmpmux2 = imm_MEM_WB;
        else if(regfilemux_sel_o_MEM_WB == regfilemux::pc_plus4)
            MEM_WB_forwarding_cmpmux2 = pc_plus4_MEM_WB;
        else MEM_WB_forwarding_cmpmux2 = (opcode_o_MEM_WB == rv32i_types::op_load) ? mem_rdata_o_MEM_WB : alu_out_o_MEM_WB;
    end
end


//rs2 forwarding logic
always_comb begin
   set_rs2_forwarding_defaults();
   if(opcode_o_ID_EX == rv32i_types::op_store) begin
        unique case(forwarding_condition) 
            2'b00: ;
            2'b01: begin
                if(rd_idx_o_MEM_WB == rs2_idx_o_ID_EX && rd_idx_o_MEM_WB != 5'd0) begin
                    EX_MEM_rs2_forwarding_sel = 1'b1;
                    if(rs2_idx_o_ID_EX == 5'd0) EX_MEM_rs2_forwarding_data = 32'd0;
                    else if(regfilemux_sel_o_MEM_WB == regfilemux::u_imm)
                        EX_MEM_rs2_forwarding_data = imm_MEM_WB;
                    else if(regfilemux_sel_o_MEM_WB == regfilemux::pc_plus4)
                        EX_MEM_rs2_forwarding_data = pc_plus4_MEM_WB;
                    else EX_MEM_rs2_forwarding_data = (opcode_o_MEM_WB == rv32i_types::op_load) ? mem_rdata_o_MEM_WB : alu_out_o_MEM_WB; 
                end
            end
            2'b10: begin
                if(rd_idx_o_EX_MEM == rs2_idx_o_ID_EX && rd_idx_o_EX_MEM != 5'd0) begin
                    EX_MEM_rs2_forwarding_sel = 1'b1;
                    if(rs2_idx_o_ID_EX == 5'd0) EX_MEM_rs2_forwarding_data = 32'd0;
                    else if(regfilemux_sel_o_EX_MEM == regfilemux::u_imm)
                        EX_MEM_rs2_forwarding_data = imm_EX_MEM;
                    else if(regfilemux_sel_o_EX_MEM == regfilemux::pc_plus4)
                        EX_MEM_rs2_forwarding_data = pc_plus4_EX_MEM;
                    else EX_MEM_rs2_forwarding_data = alu_out_o_EX_MEM; 
                end
            end
            2'b11: begin
                if(rd_idx_o_EX_MEM == rd_idx_o_MEM_WB && rd_idx_o_MEM_WB != 5'd0) begin
                    if(rd_idx_o_EX_MEM == rs2_idx_o_ID_EX) begin
                        EX_MEM_rs2_forwarding_sel = 1'b1;
                        if(rs2_idx_o_ID_EX == 5'd0) EX_MEM_rs2_forwarding_data = 32'd0;
                        else if(regfilemux_sel_o_EX_MEM == regfilemux::u_imm)
                            EX_MEM_rs2_forwarding_data = imm_EX_MEM;
                        else if(regfilemux_sel_o_EX_MEM == regfilemux::pc_plus4)
                            EX_MEM_rs2_forwarding_data = pc_plus4_EX_MEM;
                        else EX_MEM_rs2_forwarding_data = alu_out_o_EX_MEM; 
                    end
                end
                else if(rd_idx_o_MEM_WB == rs2_idx_o_ID_EX && rd_idx_o_MEM_WB != 5'd0) begin
                    EX_MEM_rs2_forwarding_sel = 1'b1;
                    if(rs2_idx_o_ID_EX == 5'd0) EX_MEM_rs2_forwarding_data = 32'd0;
                    else if(regfilemux_sel_o_MEM_WB == regfilemux::u_imm)
                        EX_MEM_rs2_forwarding_data = imm_MEM_WB;
                    else if(regfilemux_sel_o_MEM_WB == regfilemux::pc_plus4)
                            EX_MEM_rs2_forwarding_data = pc_plus4_MEM_WB;
                    else EX_MEM_rs2_forwarding_data = (opcode_o_MEM_WB == rv32i_types::op_load) ? mem_rdata_o_MEM_WB : alu_out_o_MEM_WB; 
                end
                else if (rd_idx_o_EX_MEM == rs2_idx_o_ID_EX && rd_idx_o_EX_MEM != 5'd0) begin
                    EX_MEM_rs2_forwarding_sel = 1'b1;
                    if(rs2_idx_o_ID_EX == 5'd0) EX_MEM_rs2_forwarding_data = 32'd0;
                    else if(regfilemux_sel_o_EX_MEM == regfilemux::u_imm)
                        EX_MEM_rs2_forwarding_data = imm_EX_MEM;
                    else if(regfilemux_sel_o_EX_MEM == regfilemux::pc_plus4)
                            EX_MEM_rs2_forwarding_data = pc_plus4_EX_MEM;
                    else EX_MEM_rs2_forwarding_data = alu_out_o_EX_MEM;
                end
            end
            default:;
        endcase
   end
end


endmodule


