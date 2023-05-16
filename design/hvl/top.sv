
module mp4_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

// Dump signals
initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, mp4_tb, "+all");
end
/****************************** End do not touch *****************************/



/***************************** Spike Log Printer *****************************/
// Can be enabled for debugging
spike_log_printer printer(.itf(itf), .rvfi(rvfi));
/*************************** End Spike Log Printer ***************************/


/************************ Signals necessary for monitor **********************/
// This section not required until CP2

assign rvfi.commit = ~dut.datapath.hazard_detection.is_stall && dut.datapath.WB.rvfi_sigs_data.opcode != rv32i_types::op_bubble; // && (dut.datapath.WB.rvfi_sigs_data.opcode != rv32i_types::op_store); // Set high when a valid instruction is modifying regfile or PC
assign rvfi.halt = rvfi.commit & (dut.datapath.WB.rvfi_sigs_data.pc_rdata == dut.datapath.WB.rvfi_sigs_data.pc_wdata); // Set high when target PC == Current PC for a branch
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO


// Instruction and trap:
assign rvfi.inst = dut.datapath.WB.rvfi_sigs_data.inst;
assign rvfi.trap = '0;

// Regfile:
assign rvfi.rs1_addr = dut.datapath.WB.rvfi_sigs_data.rs1_addr;
assign rvfi.rs2_addr = dut.datapath.WB.rvfi_sigs_data.rs2_addr;
assign rvfi.rs1_rdata = dut.datapath.WB.rvfi_sigs_data.rs1_rdata;
assign rvfi.rs2_rdata = dut.datapath.WB.rvfi_sigs_data.rs2_rdata;
assign rvfi.load_regfile = dut.datapath.WB.rvfi_sigs_data.load_regfile;
assign rvfi.rd_addr = dut.datapath.WB.rvfi_sigs_data.rd_addr;
assign rvfi.rd_wdata = dut.datapath.WB.rvfi_sigs_data.rd_wdata;

// PC:
assign rvfi.pc_rdata = dut.datapath.WB.rvfi_sigs_data.pc_rdata;
assign rvfi.pc_wdata = dut.datapath.WB.rvfi_sigs_data.pc_wdata;

// Memory:
assign rvfi.mem_addr = dut.datapath.WB.rvfi_sigs_data.mem_addr;
assign rvfi.mem_rmask = dut.datapath.WB.rvfi_sigs_data.mem_rmask;
assign rvfi.mem_wmask = dut.datapath.WB.rvfi_sigs_data.mem_wmask;
assign rvfi.mem_rdata = dut.datapath.WB.rvfi_sigs_data.mem_rdata;
assign rvfi.mem_wdata = dut.datapath.WB.rvfi_sigs_data.mem_wdata;

//Please refer to rvfi_itf.sv for more information.


/**************************** End RVFIMON signals ****************************/



/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2

// The following signals need to be set:
// icache signals:
assign itf.inst_read = dut.icache.mem_read;
assign itf.inst_addr = dut.icache.mem_address;
assign itf.inst_resp = dut.icache.mem_resp;
assign itf.inst_rdata = dut.icache.mem_rdata_cpu;

// dcache signals:
assign itf.data_read = dut.dcache.mem_read;
assign itf.data_write = dut.dcache.mem_write;
assign itf.data_mbe = dut.dcache.mem_byte_enable_cpu;
assign itf.data_addr = dut.dcache.mem_address;
assign itf.data_wdata = dut.dcache.mem_wdata_cpu;
assign itf.data_resp = dut.dcache.mem_resp;
assign itf.data_rdata = dut.dcache.mem_rdata_cpu;

// Please refer to tb_itf.sv for more information.


/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = dut.datapath.ID.regfile.data;

/*********************** Instantiate your design here ************************/


// performance counters
/* piplines #stalls (in clock cycles) and types (pipeline stalls vs bubbles) */
assign itf.is_stall = dut.datapath.hazard_detection.is_stalling;
assign itf.is_bubble = dut.datapath.Reg4.ctrl.opcode == rv32i_types::op_bubble;
assign itf.clk_cycle = dut.clk;

/* icache hits and misses */
assign itf.L1_i_hit_inc = dut.icache.control.hit_inc;
assign itf.L1_i_miss_inc = dut.icache.control.miss_inc;
assign itf.L1_i_rdwr_inc = dut.icache.control.rdwr_inc;

/* dcache hits and misses */
assign itf.L1_d_hit_inc = dut.dcache.control.hit_inc;
assign itf.L1_d_miss_inc = dut.dcache.control.miss_inc;
assign itf.L1_d_rdwr_inc = dut.dcache.control.rdwr_inc;

/* shared cache hits and misses */
assign itf.L2_hit_inc = dut.shared_cache.control.hit_inc;
assign itf.L2_miss_inc = dut.shared_cache.control.miss_inc;
//assign itf.L2_prefetch_inc = dut.shared_cache.control.prefetch_inc;
assign itf.L2_rdwr_inc = dut.shared_cache.control.rdwr_inc;




/* branch predictor #branches, mispredictions, types */
// total br instructions executed
assign itf.is_br_inst = ((dut.datapath.WB.rvfi_sigs_data.opcode == rv32i_types::op_jal) ||
(dut.datapath.WB.rvfi_sigs_data.opcode == rv32i_types::op_jalr) ||
(dut.datapath.WB.rvfi_sigs_data.opcode == rv32i_types::op_br)) && ~dut.datapath.hazard_detection.is_stalling;

// times hazard has to correct bad prediction
assign itf.br_correction = dut.datapath.hazard_detection.mispredict && 
~dut.datapath.hazard_detection.is_stalling && 
~dut.datapath.hazard_detection.is_bubble;

// BTB stats
assign itf.btb_miss = dut.datapath.EX.bp_mispredict_no_take && ~dut.datapath.EX.br_pred_sigs_i.btb_hit && dut.datapath.EX.br_pred_sigs_i.br_pred && ~dut.datapath.hazard_detection.is_stalling;

assign itf.btb_incorrect = dut.datapath.EX.btb_miss && ~dut.datapath.hazard_detection.is_stalling;

// BP stats
assign itf.bp_mispredict_no_take = dut.datapath.EX.bp_mispredict_no_take && dut.datapath.EX.br_pred_sigs_i.btb_hit && ~dut.datapath.EX.br_pred_sigs_i.br_pred && ~dut.datapath.hazard_detection.is_stalling;

assign itf.bp_mispredict_take = dut.datapath.EX.bp_mispredict_take && ~dut.datapath.hazard_detection.is_stalling;

// btb and bp
assign mispredict_btb_and_bp = dut.datapath.EX.bp_mispredict_no_take && ~dut.datapath.EX.br_pred_sigs_i.btb_hit && ~dut.datapath.EX.br_pred_sigs_i.br_pred && ~dut.datapath.hazard_detection.is_stalling;






mp4 dut(
    .clk(itf.clk),
    .rst(itf.rst),



    // Use for CP2 onwards
    .pmem_read(itf.mem_read),
    .pmem_write(itf.mem_write),
    .pmem_wdata(itf.mem_wdata),
    .pmem_rdata(itf.mem_rdata),
    .pmem_address(itf.mem_addr),
    .pmem_resp(itf.mem_resp)
    
);
/***************************** End Instantiation *****************************/

endmodule