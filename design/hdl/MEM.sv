module MEM
import rv32i_types::*;
(
    input rv32i_control_word ctrl,

    // from EX_MEM reg
    input logic [4:0] rd, 
    input rv32i_word alu_out_i, 
    input logic br_en, 
    input rv32i_word pc_plus_4, 
    input logic [31:0] rs2_out, // this is mem_wdata
    input rv32i_word imm_i_MEM,

    // to dcache
    output rv32i_word mem_address_o,
    output rv32i_word mem_wdata, // sends rs2_out to dcache
    output logic mem_read,
    output logic [3:0] mem_byte_en,
    output logic mem_write,

    // from dcache
    input rv32i_word mem_rdata,
    //input logic mem_resp, // NOT BEING USED RN

    // to MEM_WB
    output rv32i_word data_o,
    output rv32i_word alu_out_o, 
    output logic [4:0] rd_o, 
    output rv32i_word mem_addr_o, 
    output logic br_en_o, 
    output rv32i_word pc_plus_4_o,
    output rv32i_control_word ctrl_o,
    output rv32i_word imm_o_MEM,

    //rvfi
    input rvfi_sigs rvfi_sigs_i_MEM,
    output rvfi_sigs rvfi_sigs_o_MEM
);

    //rvfi
    rvfi_sigs rvfi_sigs_data;
    assign rvfi_sigs_o_MEM = rvfi_sigs_data;

    rv32i_word mem_address;
    assign mem_address_o = {mem_address[31:2], 2'd0};

    //byte enable
    logic [3:0] mem_byte_en_data;
    assign mem_byte_en = mem_byte_en_data;

    // Other signals to WB
    assign rd_o = rd;
    assign mem_addr_o = alu_out_i;
    assign alu_out_o = alu_out_i;
    assign br_en_o = br_en;
    assign pc_plus_4_o = pc_plus_4;
    assign ctrl_o = ctrl;
    assign imm_o_MEM = imm_i_MEM;


    always_comb begin: RVFI
        rvfi_sigs_data = rvfi_sigs_i_MEM;
        rvfi_sigs_data.mem_addr = mem_address_o;
        if(ctrl.opcode == op_load) begin
            rvfi_sigs_data.mem_rmask = mem_byte_en_data;
            rvfi_sigs_data.mem_wmask = 4'b0000; 
        end
        else if (ctrl.opcode == op_store) begin
            rvfi_sigs_data.mem_rmask = 4'b0000;
            rvfi_sigs_data.mem_wmask = mem_byte_en_data;
        end
        else begin
            rvfi_sigs_data.mem_rmask = 4'b0000;
            rvfi_sigs_data.mem_wmask = 4'b0000;
        end
        
        
        rvfi_sigs_data.mem_rdata = mem_rdata;
        rvfi_sigs_data.mem_wdata = mem_wdata;
    end

    // cache stuff
    always_comb begin 
        mem_address = alu_out_i;
        mem_wdata = (rs2_out << (mem_address[1:0] * 8));
        mem_read = ctrl.mem_read;
        mem_write = ctrl.mem_write;


        //if(ctrl.opcode == op_store) begin
        case (ctrl.store_funct3) 
                // sw = 4'd3
            rv32i_types::sw: mem_byte_en_data = 4'b1111;

            // sh = 4'd7
            rv32i_types::sh: begin 
                if(mem_address[1:0] == 2'b00) 
                    mem_byte_en_data = 4'b0011;
                else
                    mem_byte_en_data = 4'b1100;
            end 

            // sb = 4'd5
            rv32i_types::sb: begin 
                case(mem_address[1:0]) 
                    2'b00: mem_byte_en_data = 4'b0001;
                    2'b01: mem_byte_en_data = 4'b0010;
                    2'b10: mem_byte_en_data = 4'b0100;
                    2'b11: mem_byte_en_data = 4'b1000;
                endcase
            end 

            default: mem_byte_en_data = 4'b1111;
        endcase

        // reading from memory correctly 
        if(ctrl.opcode == op_load) begin
            case (ctrl.store_funct3) 
                rv32i_types::lw: data_o = mem_rdata; 
                rv32i_types::lhu: data_o = mem_address[1:0] == 2'b00 ? { {16{1'b0}} , mem_rdata[15:0] } : { {16{1'b0}} , mem_rdata[31:16] }; 
                rv32i_types::lh: data_o = mem_address[1:0] == 2'b00 ? { {16{mem_rdata[15]}} , mem_rdata[15:0] } : { {16{mem_rdata[31]}} , mem_rdata[31:16] };

                rv32i_types::lbu: begin 
                    case(mem_address[1:0]) 
                        2'b00: data_o = { {24{1'b0}} , mem_rdata[7:0] }; 
                        2'b01: data_o = { {24{1'b0}} , mem_rdata[15:8] }; 
                        2'b10: data_o = { {24{1'b0}} , mem_rdata[23:16] }; 
                        2'b11: data_o = { {24{1'b0}} , mem_rdata[31:24] }; 
                        default: data_o = { {24{1'b0}} , mem_rdata[7:0] }; 
                    endcase
                end 

                rv32i_types::lb: begin 
                    case(mem_address[1:0]) 
                        2'b00: data_o = { {24{mem_rdata[7]}} , mem_rdata[7:0] }; 
                        2'b01: data_o = { {24{mem_rdata[15]}} , mem_rdata[15:8] }; 
                        2'b10: data_o = { {24{mem_rdata[23]}} , mem_rdata[23:16] }; 
                        2'b11: data_o = { {24{mem_rdata[31]}} , mem_rdata[31:24] }; 
                        default: data_o = { {24{mem_rdata[7]}} , mem_rdata[7:0] }; 
                    endcase
                end 

                default: data_o = mem_rdata; 
            endcase
        end
        else
            data_o = mem_rdata;
    end



/*****************************************************************************/
endmodule : MEM