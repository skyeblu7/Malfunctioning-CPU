module WB
import rv32i_types::*;
(
    input rv32i_word mem_rdata,
    input rv32i_word alu_out,
    input logic br_en,
    input rv32i_word imm,
    input rv32i_word pc_plus4,
    input regfilemux::regfilemux_sel_t regfilemux_sel,

    input logic [4:0] rd_i_WB,

    output rv32i_word regfilemux_out,

    //rvfi
    input rvfi_sigs rvfi_sigs_i_WB
);

rv32i_word regfilemux_out_data;

//rvfi
rvfi_sigs rvfi_sigs_data;

assign regfilemux_out = regfilemux_out_data;

//rvfi
always_comb begin: RVFI 
    rvfi_sigs_data = rvfi_sigs_i_WB;
    rvfi_sigs_data.rd_wdata = regfilemux_out_data;
end
 

always_comb begin
    if(rd_i_WB == 5'd0)
        regfilemux_out_data = 32'd0;
    else begin
        case(regfilemux_sel)
            regfilemux::alu_out: regfilemux_out_data = alu_out;
            regfilemux::br_en: regfilemux_out_data = {31'b0,br_en};
            regfilemux::u_imm: regfilemux_out_data = imm;
            regfilemux::lw: regfilemux_out_data = mem_rdata;
            regfilemux::pc_plus4: regfilemux_out_data = pc_plus4;
            regfilemux::lb: begin 
                regfilemux_out_data = { {24{mem_rdata[7]}} ,mem_rdata[7:0]};
            end
            regfilemux::lbu: begin
                regfilemux_out_data = {24'b0,mem_rdata[7:0]};
            end
            regfilemux::lh: begin
                regfilemux_out_data =  { {16{mem_rdata[15]}} ,mem_rdata[15:0]};
            end
            regfilemux::lhu: begin
                regfilemux_out_data =  {16'b0,mem_rdata[15:0]};
            end
        default: regfilemux_out_data = 32'b0;
        endcase
    end
end

/*****************************************************************************/
endmodule : WB  