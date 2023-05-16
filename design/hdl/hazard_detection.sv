/* This module is responsible for 
* loading, stalling, flushing the stage registers
*/

module hazard_detection
import rv32i_types::*;
(
    input logic dcache_read,
    input logic dcache_write,
    input logic dcache_resp,
    input logic icache_resp,

    input rv32i_opcode opcode,
    pcmux::pcmux_sel_t pcmux_sel,

    //bubble
    input logic is_bubble,

    //m_extension
    input logic m_extension_load,
    input logic m_extension_resp,

    output logic load_IF_ID,
    output logic load_ID_EX,
    output logic load_EX_MEM,
    output logic load_MEM_WB,
    output logic load_pc,
    
    output logic rst_IF_ID,
    output logic rst_ID_EX,
    output logic rst_EX_MEM,

    // to BP
    output logic is_stalling

);

logic [3:0] condition;
logic is_branch;
logic mispredict;

// goes to top.sv
logic is_stall;

function void set_defaults();
    load_IF_ID = 1'b1;
    load_ID_EX = 1'b1;
    load_EX_MEM = 1'b1;
    load_MEM_WB = 1'b1;
    load_pc = 1'b1;
    rst_IF_ID = 1'b0;
    rst_ID_EX = 1'b0;
    rst_EX_MEM = 1'b0;
    is_stall = 1'b0;

endfunction

function void stall_pipeline();
    load_IF_ID = 1'b0;
    load_ID_EX = 1'b0;
    load_EX_MEM = 1'b0;
    load_MEM_WB = 1'b0;
    load_pc = 1'b0;
    is_stall = 1'b1;
endfunction




assign mispredict = pcmux_sel == pcmux::pc_plus4 ? 1'b0 : 1'b1;

assign is_branch = mispredict;
assign condition = {icache_resp, (dcache_read||dcache_write), dcache_resp, is_branch};
assign is_stalling = is_stall;


always_comb begin
    set_defaults();
    if(m_extension_load && !m_extension_resp) stall_pipeline();
    else if(is_bubble && condition != 4'b1100) begin
        load_pc = 1'b0;
        load_IF_ID = 1'b0;
        rst_ID_EX = 1'b1;
    end
    else begin
        case(condition)
            4'b0000: begin
            // waiting for icache, no dcache access, no branch
                stall_pipeline();
            end
            4'b0001: begin
            // waiting for icache, no dcache access, IS branch 
                stall_pipeline();
            end
            4'b0010: ; // impossible case
            4'b0011: ; // impossible case
            4'b0100: begin
            // waiting for dcache , stall the whole pipeline
                stall_pipeline();
            end
            4'b0101: begin
            // waiting for dcache, IS branch
                stall_pipeline();
            end
            4'b0110: begin
                stall_pipeline();
            end
            4'b0111: begin
                stall_pipeline();
            end
            4'b1000: ;
            4'b1001: begin
                rst_IF_ID = 1'b1;
                rst_ID_EX = 1'b1;
            end
            4'b1010: ; //impossible
            4'b1011: ; //impossible
            4'b1100: stall_pipeline();
            4'b1101: begin
                stall_pipeline();
            end
            4'b1110: ;
            4'b1111: begin
                rst_IF_ID = 1'b1;
                rst_ID_EX = 1'b1;
            end

        endcase 
    end
end

endmodule
