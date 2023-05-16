module arbiter
import rv32i_types::*;
(
    input logic clk,
    input logic rst,
	
	/* to/from icache */
    output logic pmem_resp_i, 
    output logic [255:0] pmem_rdata_i, 
    input rv32i_word pmem_address_i, 
    input logic pmem_read_i,

    /* to/from dcache */
    output logic pmem_resp_d, 
    output logic [255:0] pmem_rdata_d, 
    input rv32i_word pmem_address_d, 
    input logic pmem_read_d,
    input logic [255:0] pmem_wdata_d,
    input logic pmem_write_d,


    // to/from L2 cache
    input logic             pmem_resp,
    input logic [255:0]     pmem_rdata,

    output logic            pmem_read,
    output logic            pmem_write,
    output rv32i_word       pmem_address,
    output logic [255:0]    pmem_wdata
);

enum {IDLE, DATA, INSTR} 
            cur_state, next_state;

logic [2:0] requests;


always_ff @(posedge clk) begin

    if(rst)
        cur_state <= IDLE;
    else
        cur_state <= next_state;

end


always_comb begin
    requests = {pmem_read_i, pmem_read_d, pmem_write_d};


    case(cur_state)
        IDLE: begin
            // to icache
            pmem_resp_i = 1'b0;
            pmem_rdata_i = 256'd0; 

            // to dcache
            pmem_resp_d = 1'b0;
            pmem_rdata_d = 256'd0;

            // to L2
            pmem_read = 1'b0;
            pmem_write = 1'b0;
            pmem_address = 32'd0;
            pmem_wdata = 256'd0;

            // next state
            case(requests)
                // normal requests
                3'b000:
                    next_state = IDLE;
                3'b001:
                    next_state = DATA; // for writing
                3'b010:
                    next_state = DATA; // for reading
                3'b100:
                    next_state = INSTR;

                // conflict requests
                3'b101:
                    next_state = DATA; // Prioritize dcache
                3'b110:
                    next_state = DATA; // Prioritize dcache
                
                // impossible states
                3'b011,
                3'b111:
                    next_state = IDLE;
                    // $display("ERROR: IMPOSSIBLE CACHE REQUEST: dcache_read and dcache_write");

                default: 
                    next_state = IDLE;
                
            endcase
        end

        // data cache, reading or writing
        DATA: begin
            // to icache
            pmem_resp_i = 1'b0;
            pmem_rdata_i = 256'd0; 

            // to dcache
            pmem_resp_d = pmem_resp;
            pmem_rdata_d = pmem_rdata;

            // to cacheline adapter
            pmem_read = pmem_read_d;
            pmem_write = pmem_write_d;
            pmem_address = pmem_address_d;
            pmem_wdata = pmem_wdata_d;

            // next state
            if(pmem_read_i & pmem_resp_d) 
                next_state = INSTR;
            else if(pmem_resp_d)
                next_state = IDLE;
            else
                next_state = DATA;
        end


        // instruction cache, only reading
        INSTR: begin
            // to icache
            pmem_resp_i = pmem_resp;
            pmem_rdata_i = pmem_rdata; 

            // to dcache
            pmem_resp_d = 1'b0;
            pmem_rdata_d = 256'd0;

            // to cacheline adapter
            pmem_read = pmem_read_i;
            pmem_write = 1'b0;
            pmem_address = pmem_address_i;
            pmem_wdata = 256'd0;


            // next state
            if((pmem_read_d || pmem_write_d) && pmem_resp_i) 
                next_state = DATA;
            else if(pmem_resp_i)
                next_state = IDLE;
            else
                next_state = INSTR;

        end

        default: begin
            // to icache
            pmem_resp_i = 1'b0;
            pmem_rdata_i = 256'd0; 

            // to dcache
            pmem_resp_d = 1'b0;
            pmem_rdata_d = 256'd0;

            // to cacheline adapter
            pmem_read = 1'b0;
            pmem_write = 1'b0;
            pmem_address = 32'd0;
            pmem_wdata = 256'd0;

            // next state
            next_state = IDLE;

        end
    endcase
end

endmodule
