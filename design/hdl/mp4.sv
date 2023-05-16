
module mp4
import rv32i_types::*;
(
    input logic clk,
    input logic rst,

	// For CP2
    input logic pmem_resp,
    input [63:0] pmem_rdata,

	// To physical memory
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
	
);
	// datapath to/from icache
    logic instr_mem_resp;
    rv32i_word instr_mem_rdata;
    logic instr_read;
	rv32i_word instr_mem_address;

    // datapath to/from dcache
	logic data_mem_resp;
    rv32i_word data_mem_rdata;
    logic data_read;
    logic data_write;
    logic [3:0] data_mbe;
    rv32i_word data_mem_address;
    rv32i_word data_mem_wdata;


    // icache to/from arbiter
    logic pmem_resp_i; 
    logic [255:0] pmem_rdata_i;
    logic [31:0] pmem_address_i;
    logic pmem_read_i;


    // dcache to/from arbiter
    logic pmem_resp_d;
    logic [255:0] pmem_rdata_d;
    logic [31:0] pmem_address_d;
    logic pmem_read_d;
    logic [255:0] pmem_wdata_d;
    logic pmem_write_d;


     // arbiter to/from L2 cache
    logic mem_resp_o_arbiter;
    logic [31:0] mem_address_o_arbiter;
    logic [255:0] mem_rdata_o_arbiter;
    logic [255:0] mem_wdata_o_arbiter;
    logic mem_read_o_arbiter;
    logic mem_write_o_arbiter;


    // L2 to/from cacheline
    logic pmem_resp_o;
    logic [255:0] pmem_rdata_o;
    logic pmem_read_o;
    logic pmem_write_o;
    logic [31:0] pmem_address_o;
    logic [255:0] pmem_wdata_o;



    datapath datapath(
        .clk(clk),
        .rst(rst),

        // to/from icache
        .icache_instr_addr(instr_mem_address),
        .instr_i(instr_mem_rdata),
        .icache_read(instr_read),
        .icache_resp(instr_mem_resp),

        // to/from dcache
        .dcache_resp(data_mem_resp),
        .dcache_rdata(data_mem_rdata), 
        .dcache_read(data_read),
        .dcache_write(data_write),
        .dcache_mbe(data_mbe),
        .dcache_data_addr(data_mem_address),
        .dcache_wdata(data_mem_wdata)
    );



    // instruction cache
    L1_cache icache(
        .clk(clk), 
        .rst(rst), 

        /* Physical memory signals to/from arbiter */
        .pmem_resp(pmem_resp_i), 
        .pmem_rdata(pmem_rdata_i), 
        .pmem_address(pmem_address_i), 
        .pmem_read(pmem_read_i), 

        /* CPU memory signals to/from datapath */
        .mem_read(instr_read), 
        .mem_address(instr_mem_address),
        .mem_resp(instr_mem_resp),
        .mem_rdata_cpu(instr_mem_rdata),


        // not needed for icache
        .pmem_wdata(),
        .pmem_write(), 

        .mem_wdata_cpu(), 
        .mem_write(), 
        .mem_byte_enable_cpu()
    );


    // data cache
    L1_cache dcache(
        .clk(clk), 
        .rst(rst), 

        /* Physical memory signals to/from arbiter */
        .pmem_resp(pmem_resp_d), 
        .pmem_rdata(pmem_rdata_d), 
        .pmem_address(pmem_address_d), 
        .pmem_wdata(pmem_wdata_d), 
        .pmem_read(pmem_read_d), 
        .pmem_write(pmem_write_d), 


        /* CPU memory signals to/from datapath */
        .mem_read(data_read), 
        .mem_write(data_write), 
        .mem_byte_enable_cpu(data_mbe), 
        .mem_address(data_mem_address),
        .mem_wdata_cpu(data_mem_wdata), 
        .mem_resp(data_mem_resp), 
        .mem_rdata_cpu(data_mem_rdata) 
    );

    arbiter arbiter(
        .clk(clk),
        .rst(rst),
	
        /* to/from icache */
        .pmem_resp_i(pmem_resp_i), 
        .pmem_rdata_i(pmem_rdata_i), 
        .pmem_address_i(pmem_address_i), 
        .pmem_read_i(pmem_read_i),


        /* to/from dcache */
        .pmem_resp_d(pmem_resp_d), 
        .pmem_rdata_d(pmem_rdata_d), 
        .pmem_address_d(pmem_address_d), 
        .pmem_read_d(pmem_read_d),
        .pmem_wdata_d(pmem_wdata_d),
        .pmem_write_d(pmem_write_d),


        // to/from L2 cache
        .pmem_resp(mem_resp_o_arbiter),
        .pmem_rdata(mem_rdata_o_arbiter),
        .pmem_read(mem_read_o_arbiter),
        .pmem_write(mem_write_o_arbiter),
        .pmem_address(mem_address_o_arbiter),
        .pmem_wdata(mem_wdata_o_arbiter)
    );


    L2_cache shared_cache(
        .clk(clk),
        .rst(rst),

        /* CPU memory signals (to/from arbiter) */
        .mem_address(mem_address_o_arbiter),
        .mem_rdata(mem_rdata_o_arbiter),
        .mem_wdata(mem_wdata_o_arbiter),
        .mem_read(mem_read_o_arbiter),
        .mem_write(mem_write_o_arbiter),
        //.mem_byte_enable(4'hf),
        .mem_resp(mem_resp_o_arbiter),

        /* Physical memory signals (to/from cacheline adapter) */
        .pmem_resp(pmem_resp_o),
        .pmem_rdata(pmem_rdata_o),
        .pmem_read(pmem_read_o),
        .pmem_write(pmem_write_o),
        .pmem_address(pmem_address_o),
        .pmem_wdata(pmem_wdata_o)
    );

    cacheline_adaptor cacheline(
        .clk(clk),
        .reset_n(~rst),

        // to/from L2 cache
        .line_i(pmem_wdata_o),
        .line_o(pmem_rdata_o),
        .address_i(pmem_address_o),
        .read_i(pmem_read_o),
        .write_i(pmem_write_o),
        .resp_o(pmem_resp_o),

        // to/from memory
        .burst_i(pmem_rdata),
        .burst_o(pmem_wdata),
        .address_o(pmem_address),
        .read_o(pmem_read),
        .write_o(pmem_write),
        .resp_i(pmem_resp)
    );


endmodule : mp4