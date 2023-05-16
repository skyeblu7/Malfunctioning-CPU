/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module L2_cache_control (
    input logic clk,
    input logic rst,

    // to/from cachline adptr
    input logic mem_resp,
    output logic mem_read,
    output logic mem_write,

    // to/from cpu
    output logic cache_resp,
    input logic cpu_read,
    input logic cpu_write,


    // control/datapath signals
    output logic [2:0] MRU_i,
    output logic load_MRU,
    output logic [3:0] data_i_sel,
    output logic [3:0] load_tag,
    output logic [3:0] dirty_i,
    output logic [3:0] valid_i,
    output logic load_dirty,
    output logic load_valid,
    output logic [1:0] cacheline_o_sel,
    output logic [3:0] write_en_sel,
    output logic mm_address_sel,

    input logic [2:0] MRU_o,
    input logic [3:0] hit,
    input logic [3:0] dirty_o,
    input logic [3:0] valid_o
);



enum {IDLE, SEARCH, WRITE_BACK, NEW_BLOCK}
        cur_state, next_state;


logic hit_inc;
logic miss_inc;
logic rdwr_inc;


function void set_defaults();
    MRU_i = MRU_o;
    load_MRU = 1'd0;
    data_i_sel = 4'd0;
    cacheline_o_sel = 2'd0;
    load_tag = 4'd0;
    dirty_i = dirty_o;
    valid_i = valid_o;
    load_dirty = 1'd0;
    load_valid = 1'd0;
    cache_resp = 1'd0;
    write_en_sel = 4'd0;
    mm_address_sel = 1'd0;
    mem_read = 1'd0;
    mem_write = 1'd0;


    // performance counters
    hit_inc = 1'b0;
    miss_inc = 1'b0;
    rdwr_inc = 1'b0;
endfunction

always_ff @(posedge clk) begin

    if(rst)
        cur_state <= IDLE;
    else
        cur_state <= next_state;

end

always_comb begin
    set_defaults();

    case(cur_state) 
    
        IDLE: begin

            // set nextstate
            if(cpu_read || cpu_write)
                next_state = SEARCH;
            else
                next_state = IDLE;
        end

        SEARCH: begin

            rdwr_inc = 1'b1;

            // hit 
            if(hit[0] & cpu_read) begin 
                load_MRU = 1'd1;
                MRU_i = {2'b00, MRU_o[0]}; 
                cacheline_o_sel = 2'd0;
                next_state = IDLE;
                cache_resp = 1'd1;

                hit_inc = 1'b1;
            end
            else if(hit[1] & cpu_read) begin 
                load_MRU = 1'd1;
                MRU_i = {2'b01, MRU_o[0]}; 
                cacheline_o_sel = 2'd1;
                next_state = IDLE;
                cache_resp = 1'd1;

                hit_inc = 1'b1;
            end
            else if(hit[2] & cpu_read) begin 
                load_MRU = 1'd1;
                MRU_i = {1'b1, MRU_o[1], 1'b0}; 
                cacheline_o_sel = 2'd2;
                next_state = IDLE;
                cache_resp = 1'd1;

                hit_inc = 1'b1;
            end
            else if(hit[3] & cpu_read) begin 
                load_MRU = 1'd1;
                MRU_i = {1'b1, MRU_o[1], 1'b1}; 
                cacheline_o_sel = 2'd3;
                next_state = IDLE;
                cache_resp = 1'd1;

                hit_inc = 1'b1;
            end
            else if(hit[0] & cpu_write) begin 

                // set MRU
                load_MRU = 1'd1;
                MRU_i = {2'b00, MRU_o[0]};

                // set and write data in
                data_i_sel[0] = 1'd0;
                write_en_sel[0] = 1'd1;

                // set and write tag in
                load_tag[0] = 1'd1;

                // set dirty
                dirty_i[0] = 1'd1;
                load_dirty = 1'd1;

                // set output
                cacheline_o_sel = 2'd0;

                // next state
                next_state = IDLE;

                // send resp
                cache_resp = 1'd1;

                // performance counter
                hit_inc = 1'b1;
            end
            else if(hit[1] & cpu_write) begin 

                // set MRU
                load_MRU = 1'd1;
                MRU_i = {2'b01, MRU_o[0]};

                // set and write data in
                data_i_sel[1] = 1'd0;
                write_en_sel[1] = 1'd1;

                // set and write tag in
                load_tag[1] = 1'd1;

                // set dirty
                dirty_i[1] = 1'd1;
                load_dirty = 1'd1;

                // set output
                cacheline_o_sel = 2'd1;

                // next state
                next_state = IDLE;

                // send resp
                cache_resp = 1'd1;

                // performance counter
                hit_inc = 1'b1;
            end
            else if(hit[2] & cpu_write) begin 

                // set MRU
                load_MRU = 1'd1;
                MRU_i = {1'b1, MRU_o[1], 1'b0};

                // set and write data in
                data_i_sel[2] = 1'd0;
                write_en_sel[2] = 1'd1;

                // set and write tag in
                load_tag[2] = 1'd1;

                // set dirty
                dirty_i[2] = 1'd1;
                load_dirty = 1'd1;

                // set output
                cacheline_o_sel = 2'd2;

                // next state
                next_state = IDLE;

                // send resp
                cache_resp = 1'd1;

                // performance counter
                hit_inc = 1'b1;
            end
            else if(hit[3] & cpu_write) begin 

                // set MRU
                load_MRU = 1'd1;
                MRU_i = {1'b1, MRU_o[1], 1'b1};

                // set and write data in
                data_i_sel[3] = 1'd0;
                write_en_sel[3] = 1'd1;

                // set and write tag in
                load_tag[3] = 1'd1;

                // set dirty
                dirty_i[3] = 1'd1;
                load_dirty = 1'd1;

                // set output
                cacheline_o_sel = 2'd3;

                // next state
                next_state = IDLE;

                // send resp
                cache_resp = 1'd1;

                // performance counter
                hit_inc = 1'b1;
            end

            // miss

            // if evict way0 and way0 is dirty or
            // if evict way1 and way1 is dirty
            // if evict way2 and way2 is dirty
            // if evict way3 and way3 is dirty
            else if(MRU_o[2] & MRU_o[1] & dirty_o[0] || 
                    MRU_o[2] & ~MRU_o[1] & dirty_o[1] ||  
                    ~MRU_o[2] & MRU_o[0] & dirty_o[2] ||  
                    ~MRU_o[2] & ~MRU_o[0] & dirty_o[3] ) begin
                next_state = WRITE_BACK;

                miss_inc = 1'b1;
            end
            // if evict way1 and way1 is not dirty or
            // if evict way2 and way2 is not dirty
            else if(MRU_o[2] & MRU_o[1] & ~dirty_o[0] || 
                    MRU_o[2] & ~MRU_o[1] & ~dirty_o[1] ||  
                    ~MRU_o[2] & MRU_o[0] & ~dirty_o[2] ||  
                    ~MRU_o[2] & ~MRU_o[0] & ~dirty_o[3] ) begin
                next_state = NEW_BLOCK;

                miss_inc = 1'b1;
            end
            else begin // ?? unexpected?
                next_state = IDLE;
                $display("UNEXPECTED IN SEARCH!");
            end
        end

        WRITE_BACK: begin

            // write enable to memory
            mem_write = 1'd1;

            // sets address to be read as the old tag
            mm_address_sel = 1'd1;

            // set currect cacheline to write out to memory
            if(MRU_o[2] & MRU_o[1] & dirty_o[0]) // way0 is dirty
                cacheline_o_sel = 2'd0;
            else if(MRU_o[2] & ~MRU_o[1] & dirty_o[1]) // way1 is dirty
                cacheline_o_sel = 2'd1;
            else if(~MRU_o[2] & MRU_o[0] & dirty_o[2]) // way2 is dirty
                cacheline_o_sel = 2'd2;
            else if(~MRU_o[2] & ~MRU_o[0] & dirty_o[3]) // way3 is dirty
                cacheline_o_sel = 2'd3;
        
            // set nextstate
            if(mem_resp == 0)
                next_state = WRITE_BACK;
            else
                next_state = NEW_BLOCK;
        end

        NEW_BLOCK: begin
            if(MRU_o[2] & MRU_o[1]) begin // if way0 is LRU
                // set read 
                mem_read = 1'd1;

                // write new data 
                write_en_sel[0] = 1'd1;
                data_i_sel[0] = 1'd1;

                // update tag
                load_tag[0] = 1'd1;

                // set valid
                valid_i[0] = 1'd1;
                load_valid = 1'd1;

                // set dirty
                dirty_i[0] = 1'd0;
                load_dirty = 1'd1;

            end
            else if(MRU_o[2] & ~MRU_o[1]) begin // if way1 is LRU
                // set read 
                mem_read = 1'd1;

                // write new data
                write_en_sel[1] = 1'd1;
                data_i_sel[1] = 1'd1;

                // update tag
                load_tag[1] = 1'd1;

                // set valid
                valid_i[1] = 1'd1;
                load_valid = 1'd1;

                // set dirty
                dirty_i[1] = 1'd0;
                load_dirty = 1'd1;

            end
            else if(~MRU_o[2] & MRU_o[0]) begin // if way2 is LRU
                // set read 
                mem_read = 1'd1;

                // write new data
                write_en_sel[2] = 1'd1;
                data_i_sel[2] = 1'd1;

                // update tag
                load_tag[2] = 1'd1;

                // set valid
                valid_i[2] = 1'd1;
                load_valid = 1'd1;

                // set dirty
                dirty_i[2] = 1'd0;
                load_dirty = 1'd1;

            end
            else if(~MRU_o[2] & ~MRU_o[0]) begin // if way3 is LRU
                // set read 
                mem_read = 1'd1;

                // write new data
                write_en_sel[3] = 1'd1;
                data_i_sel[3] = 1'd1;

                // update tag
                load_tag[3] = 1'd1;

                // set valid
                valid_i[3] = 1'd1;
                load_valid = 1'd1;

                // set dirty
                dirty_i[3] = 1'd0;
                load_dirty = 1'd1;

            end
            else // unexpected
                $display("UNEXPECTED MRU in NEW_BLOCK STATE");

            // set nextstate
            if(mem_resp == 0) begin
                next_state = NEW_BLOCK;
            end
            else
                next_state = SEARCH;
        end

        default: begin
            // set nextstate
            next_state = IDLE;
        end
    endcase
end


endmodule : L2_cache_control