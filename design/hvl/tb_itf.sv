`ifndef TB_ITF_SV
`define TB_ITF_SV

// Change frequency for accurate timing
`define FREQUENCY_MHZ 373.134328
`define FREQUENCY (`FREQUENCY_MHZ * 1000000)
`define PERIOD_NS (1000000000/`FREQUENCY)
`define PERIOD_CLK (`PERIOD_NS / 2)

`timescale 1ns/1ps

interface tb_itf();

    /* Generate Clock */
    bit clk, rst;
    always #(`PERIOD_CLK) clk = clk === 1'b0;

    /* Needed to validate correctness */
    logic [31:0] registers[32];

    /* Error Reporting */
    logic inst_sm_error = 1'b0;
    logic data_sm_error = 1'b0;
    logic sm_error;
    assign sm_error = inst_sm_error | data_sm_error;
    logic pmem_error = 1'b0;

    /* I Cache Ports */
    logic inst_read;
    logic [31:0] inst_addr;
    logic inst_resp;
    logic [31:0] inst_rdata;

    /* D Cache Ports */
    logic data_read;
    logic data_write;
    logic [3:0] data_mbe;
    logic [31:0] data_addr;
    logic [31:0] data_wdata;
    logic data_resp;
    logic [31:0] data_rdata;


    /* piplines #stalls (in clock cycles) and types (pipeline stalls vs bubbles) */
    logic is_stall;
    logic is_bubble;
    logic clk_cycle;


    /* icache hits and misses */
    logic L1_i_hit_inc;
    logic L1_i_miss_inc;
    logic L1_i_rdwr_inc;
    /* dcache hits and misses */
    logic L1_d_hit_inc;
    logic L1_d_miss_inc;
    logic L1_d_rdwr_inc;
    /* shared cache hits and misses */
    logic L2_hit_inc;
    logic L2_miss_inc;
    //logic L2_prefetch_inc;
    logic L2_rdwr_inc; 

    /* branch predictor #branches, mispredictions, types */
    // from bp, used to count total branches
    logic is_br_inst;
    logic br_correction;

    // BTB
    logic btb_incorrect;
    logic btb_miss;

    // BP
    logic bp_mispredict_no_take;
    logic bp_mispredict_take;

    logic mispredict_btb_and_bp;






    /* Burst Memory Ports */
    logic mem_read;
    logic mem_write;
    logic [31:0] mem_addr;
    logic [63:0] mem_wdata;
    logic mem_resp;
    logic [63:0] mem_rdata;

    /* Mailbox for memory path */
    mailbox #(string) path_mb;
    initial path_mb = new();

    /* Burst Memory */
    clocking mcb @(posedge clk);
        input read = mem_read, write = mem_write, addr = mem_addr,
              wdata = mem_wdata, rst = rst;
        output resp = mem_resp, rdata = mem_rdata, error = pmem_error;
    endclocking

    /* Shadow Memory */
    clocking smcb @(posedge clk);
        input read_a = inst_read, address_a = inst_addr, rdata_a = inst_rdata,
              resp_a = inst_resp, read_b = data_read, write = data_write,
              address_b = data_addr, rdata_b = data_rdata, wdata = data_wdata,
              resp_b = data_resp, mbe = data_mbe;
        output inst_sm_error, data_sm_error;
    endclocking

    /* Magic Memory */
    clocking mmcb @(negedge clk);
        input read_a = inst_read, address_a = inst_addr, read_b = data_read,
              write = data_write, wmask = data_mbe, address_b = data_addr,
              wdata = data_wdata;
        output resp_a = inst_resp, rdata_a = inst_rdata, resp_b = data_resp,
               rdata_b = data_rdata;
    endclocking

    modport mem(clocking mcb, ref path_mb);
    modport magic_mem(clocking mmcb, ref path_mb);
    modport sm(clocking smcb, ref path_mb);
    modport tb(input clk, registers, output rst, ref path_mb);

endinterface
`endif