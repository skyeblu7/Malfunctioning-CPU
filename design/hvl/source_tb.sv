`ifndef SOURCE_TB
`define SOURCE_TB

`define MAGIC_MEM 0
`define PARAM_MEM 1
`define MEMORY `PARAM_MEM

// Set these to 1 to enable the feature for CP2
`define USE_SHADOW_MEMORY 1
`define USE_RVFI_MONITOR 1

`include "tb_itf.sv"

module source_tb(
    tb_itf.magic_mem magic_mem_itf,
    tb_itf.mem mem_itf,
    tb_itf.sm sm_itf,
    tb_itf.tb tb_itf,
    rvfi_itf rvfi
);

initial begin
    $display("Compilation Successful");
    tb_itf.path_mb.put("memory.lst");
    tb_itf.rst = 1'b1;
    repeat (5) @(posedge tb_itf.clk);
    tb_itf.rst = 1'b0;
end

/**************************** Halting Conditions *****************************/
int timeout = 100000000;


// performance counters
/* piplines #stalls (in clock cycles) and types (pipeline stalls vs bubbles) */
int num_stall = 0;
int num_bubble = 0;
int num_cycles = 0;

/* icache hits and misses */
int num_icache_hit = 0;
int num_icache_miss = 0;
int num_icache_rdwr = 0;

/* dcache hits and misses */
int num_dcache_hit = 0;
int num_dcache_miss = 0;
int num_dcache_rdwr = 0;

/* shared cache hits and misses */
//int num_L2_cache_prefetch = 0;
int num_L2_cache_hit = 0;
int num_L2_cache_miss = 0;
int num_L2_cache_rdwr = 0;

/* branch predictor #branches, mispredictions, types */
real num_br = 0;
int num_br_correction = 0;
int num_btb_miss = 0;
int num_btb_incorrect = 0;
int num_br_mispredict_no_take = 0;
int num_br_mispredict_take = 0;
int num_br_not_taken_miss = 0;




always @(posedge tb_itf.clk) begin


/* piplines #stalls (in clock cycles) and types (pipeline stalls vs bubbles) */
    if(itf.is_stall)
        num_stall += 1;
    if(itf.is_bubble)
        num_bubble += 1;
    if(itf.clk_cycle)
        num_cycles += 1;

/* icache hits and misses */
    if(itf.L1_i_hit_inc)
        num_icache_hit += 1;
    if(itf.L1_i_miss_inc)
        num_icache_miss += 1;
    if(itf.L1_i_rdwr_inc)
        num_icache_rdwr += 1;

/* dcache hits and misses */
    if(itf.L1_d_hit_inc)
        num_dcache_hit += 1;
    if(itf.L1_d_miss_inc)
        num_dcache_miss += 1;
    if(itf.L1_d_rdwr_inc)
        num_dcache_rdwr += 1;

/* shared cache hits and misses */
    if(itf.L2_hit_inc)
        num_L2_cache_hit += 1;
    if(itf.L2_miss_inc)
        num_L2_cache_miss += 1;
    // if(itf.L2_prefetch_inc)
    //     num_L2_cache_prefetch += 1;
    if(itf.L2_rdwr_inc)
        num_L2_cache_rdwr += 1;



/* branch predictor #branches, mispredictions, types */
    if(itf.is_br_inst)
        num_br += 1;
    if(itf.br_correction)
        num_br_correction += 1;
    if(itf.btb_miss)
        num_btb_miss += 1;
    if(itf.btb_incorrect)
        num_btb_incorrect += 1;
    if(itf.bp_mispredict_no_take)
        num_br_mispredict_no_take += 1;
    if(itf.bp_mispredict_take)
        num_br_mispredict_take += 1;
    if(itf.mispredict_btb_and_bp)
        num_br_not_taken_miss += 1;
    









    if (rvfi.halt) begin
        // performance counters
        /* piplines #stalls (in clock cycles) and types (pipeline stalls vs bubbles) */
        $display("total cycles:\t\t\t\t\t%d\nnumber of cycles where pipeline is stalling:\t%d\nnumber of bubbles inserted:\t\t\t%d",num_cycles,num_stall,num_bubble);


        /* icache hits and misses */
        $display("num icache hit:\t\t\t%d\nnum icache miss:\t\t%d\nnum icache rdwr:\t\t%d",num_icache_hit, num_icache_miss, num_icache_rdwr);
        /* dcache hits and misses */
        $display("num dcache hit:\t\t\t%d\nnum dcache miss:\t\t%d\nnum dcache rdwr:\t\t%d",num_dcache_hit, num_dcache_miss, num_dcache_rdwr);
        /* shared cache hits and misses */
        $display("num L2 cache hit:\t\t%d\nnum L2 cache miss:\t\t%d\nnum L2 cache rdwr:\t\t%d",num_L2_cache_hit, num_L2_cache_miss, num_L2_cache_rdwr);


        /* branch predictor #branches, mispredictions, types */
        $display("num branches:\t\t\t%d\nnum br corrections:\t\t%d\nnum correct pred, btb miss:\t\t%d\nnum correct pred, incorrect btb target: %d\nnum incorrect 'not taken' pred, btb hit: %d\nnum incorrect 'taken' pred, btb hit:\t%d\nnum incorrect 'not taken' pred, btb miss: %d",num_br,num_br_correction,num_btb_miss,num_btb_incorrect,num_br_mispredict_no_take,num_br_mispredict_take,num_br_not_taken_miss);
        $display("accuracy [1-corrections/num_br]: \t\t%0.3f", (1.0-num_br_correction/num_br)*100.0);
        $display("accuracy excluding incorrect target: \t\t%0.3f", (1.0-(num_br_correction-num_btb_incorrect)/num_br)*100.0);

        $finish;
    end
    if (timeout == 0) begin
        $display("TOP: Timed out");
        $finish;
    end
    timeout <= timeout - 1;
end

always @(rvfi.errcode iff (rvfi.errcode != 0)) begin
    repeat(5) @(posedge itf.clk);
    $display("TOP: Errcode: %0d", rvfi.errcode);
    $finish;
end

/************************** End Halting Conditions ***************************/
`define PARAM_RESPONSE_NS 50 * 10
`define PARAM_RESPONSE_CYCLES $ceil(`PARAM_RESPONSE_NS / `PERIOD_NS)
`define PAGE_RESPONSE_CYCLES $ceil(`PARAM_RESPONSE_CYCLES / 2.0)

generate
    if (`MEMORY == `MAGIC_MEM) begin : memory
        magic_memory_dp mem(magic_mem_itf);
    end
    else if (`MEMORY == `PARAM_MEM) begin : memory
        ParamMemory #(`PARAM_RESPONSE_CYCLES, `PAGE_RESPONSE_CYCLES, 4, 256, 512) mem(mem_itf);
    end
endgenerate

generate
    if (`USE_SHADOW_MEMORY) begin
        shadow_memory sm(sm_itf);
    end

    if (`USE_RVFI_MONITOR) begin
        /* Instantiate RVFI Monitor */
        riscv_formal_monitor_rv32imc monitor(
            .clock(rvfi.clk),
            .reset(rvfi.rst),
            .rvfi_valid(rvfi.commit),
            .rvfi_order(rvfi.order),
            .rvfi_insn(rvfi.inst),
            .rvfi_trap(rvfi.trap),
            .rvfi_halt(rvfi.halt),
            .rvfi_intr(1'b0),
            .rvfi_mode(2'b00),
            .rvfi_rs1_addr(rvfi.rs1_addr),
            .rvfi_rs2_addr(rvfi.rs2_addr),
            .rvfi_rs1_rdata(rvfi.rs1_addr ? rvfi.rs1_rdata : 0),
            .rvfi_rs2_rdata(rvfi.rs2_addr ? rvfi.rs2_rdata : 0),
            .rvfi_rd_addr(rvfi.load_regfile ? rvfi.rd_addr : 0),
            .rvfi_rd_wdata(rvfi.load_regfile ? rvfi.rd_wdata : 0),
            .rvfi_pc_rdata(rvfi.pc_rdata),
            .rvfi_pc_wdata(rvfi.pc_wdata),
            .rvfi_mem_addr({rvfi.mem_addr[31:2], 2'b0}),
            .rvfi_mem_rmask(rvfi.mem_rmask),
            .rvfi_mem_wmask(rvfi.mem_wmask),
            .rvfi_mem_rdata(rvfi.mem_rdata),
            .rvfi_mem_wdata(rvfi.mem_wdata),
            .rvfi_mem_extamo(1'b0),
            .errcode(rvfi.errcode)
        );
    end
endgenerate

endmodule

`endif