/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module L2_cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,
    input rst,

    /* CPU memory signals (to/from arbiter) */
    input   logic [31:0]    mem_address,
    output  logic [255:0]    mem_rdata,
    input   logic [255:0]    mem_wdata,
    input   logic           mem_read,
    input   logic           mem_write,
    output  logic           mem_resp,

    /* Physical memory signals (to/from cacheline adapter) */
    output  logic [31:0]    pmem_address,
    input   logic [255:0]   pmem_rdata,
    output  logic [255:0]   pmem_wdata,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic           pmem_resp
);

// control <---> datapath logic
logic [2:0] MRU_i;
logic load_MRU;
logic [3:0] data_i_sel;
logic [3:0] load_tag;
logic [3:0] dirty_i;
logic [3:0] valid_i;
logic load_dirty;
logic load_valid;
logic [3:0] dirty_o;
logic [3:0] valid_o;
logic [3:0] hit;
logic [2:0] MRU_o;
logic [3:0] write_en_sel;
logic [1:0] cacheline_o_sel;
logic mm_address_sel;


// cache <---> cachline adapter
logic [255:0] cacheline_o; // read cacheline

// cpu <---> bus adapter
logic [255:0] array_wdata;




// buffer signals to break combinational loop
// inputs
logic [31:0]    mem_address_buff;
logic [255:0]   mem_wdata_buff;
logic           mem_read_buff;
logic           mem_write_buff;
logic [255:0]   pmem_rdata_buff;
logic           pmem_resp_buff;
// outputs
logic [255:0]   mem_rdata_buff;
logic           mem_resp_buff;
logic [31:0]    pmem_address_buff;
logic [255:0]   pmem_wdata_buff;
logic           pmem_read_buff;
logic           pmem_write_buff;


// buffer to break combinational loops
always_ff @(negedge clk) begin 
    // cpu input buffer signals
    mem_address_buff <= mem_address;
    mem_wdata_buff <= mem_wdata;
    mem_read_buff <= mem_read;
    mem_write_buff <= mem_write;

    // physical memory input buffer signals
    pmem_rdata_buff <= pmem_rdata;
    pmem_resp_buff <= pmem_resp;

    // cpu output buffer signals
    mem_rdata <= mem_rdata_buff;
    mem_resp <= mem_resp_buff;

    // physical memory output buffer signals
    pmem_address <= pmem_address_buff;
    pmem_wdata <= pmem_wdata_buff;
    pmem_read <= pmem_read_buff;
    pmem_write <= pmem_write_buff;
end


assign pmem_wdata_buff = cacheline_o; // write cacheline to mem
assign array_wdata = mem_wdata_buff; // write cacheline from cpu
assign mem_rdata_buff = cacheline_o; // read cacheline to cpu

L2_cache_control control
(
    .clk(clk),
    .rst(rst),

    // to/from cacheline adptr
    .mem_resp(pmem_resp_buff),
    .mem_read(pmem_read_buff),
    .mem_write(pmem_write_buff),
    

    // to/from cpu
    .cache_resp(mem_resp_buff), 
    .cpu_read(mem_read_buff),
    .cpu_write(mem_write_buff),

    // control + datapath signals
    // to datapath
    .MRU_i(MRU_i),
    .load_MRU(load_MRU),
    .data_i_sel(data_i_sel),
    .load_tag(load_tag),
    .dirty_i(dirty_i),
    .valid_i(valid_i),
    .load_dirty(load_dirty),
    .load_valid(load_valid),
    .cacheline_o_sel(cacheline_o_sel),
    .write_en_sel(write_en_sel),
    .mm_address_sel(mm_address_sel),

    // from datapath
    .MRU_o(MRU_o),
    .hit(hit),
    .dirty_o(dirty_o),
    .valid_o(valid_o)
);

L2_cache_datapath datapath
(
    .clk(clk),
    .rst(rst),
    .address(mem_address_buff),
    .cpu_wdata(array_wdata),
    .mm_wdata(pmem_rdata_buff),
    .cacheline_o(cacheline_o),
    .mm_address(pmem_address_buff),

    // control + datapath signals
    // to control
    .MRU_i(MRU_i),
    .load_MRU(load_MRU),
    .data_i_sel(data_i_sel), 
    .load_tag(load_tag), 
    .dirty_i(dirty_i), 
    .valid_i(valid_i), 
    .load_dirty(load_dirty),
    .load_valid(load_valid),
    .write_en_sel(write_en_sel), 
    .cacheline_o_sel(cacheline_o_sel), 
    .mm_address_sel(mm_address_sel),

    // from control
    .dirty_o(dirty_o), 
    .valid_o(valid_o), 
    .hit(hit), 
    .MRU_o(MRU_o)
);



endmodule : L2_cache