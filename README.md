<!-- TABLE OF CONTENTS -->
## Table of Contents

* [About the Project](#about-the-project)
  * [Built With](#built-with)
* [Getting Started](#getting-started)
  * [Prerequisites](#prerequisites)
  * [Build](#installation)
  * [Generate Analysis Files](#generate-analysis-files)
* [Details](#details)
  * [icache/dcache](#icachedcache)
  * [Arbiter](#arbiter)
  * [5 Stage Pipeline](#5-stage-pipeline)
  * [L2 Cache](#l2-cache)
  * [Branch Prediction](#branch-prediction)
  * [M-Extension](#m-extension)
  * [Performance Counters](#performance-counters)
  * [Detailed Datapath](#detailed-datapath)
* [Performance Analysis and Design Evolution](#performance-analysis-and-design-evolution)
* [Ranking](#ranking)
* [Improvement Possibilities](#improvement-possibilities)
* [Acknowledgements](#acknowledgements)



<!-- ABOUT THE PROJECT -->
## About The Project

![high-level-diagram](high-level.png)

This is an impementation of a five stage pipelined risc-v 32i+m-extension processor with hazard detection, forwarding and branch prediction. The Memory hierarchy includes a direct mapped i-cache, direct mapped d-cache, an arbiter that coordinates memory accesses and a 4-way set associative L2 cache.


### Built With
SystemVerilog was used for design and testbench files. Synopsys's VCS and Synopsys's Design Compiler were used to compile all the files and generate timing, area and power analysis files. Synopsys's Verdi was used to analyze the waveform.
* [SystemVerilog](https://en.wikipedia.org/wiki/SystemVerilog#:~:text=SystemVerilog%2C%20standardized%20as%20IEEE%201800,of%20the%20same%20IEEE%20standard.)
* [Synopsys VCS](https://www.synopsys.com/verification/simulation/vcs.html)
* [Synopsys Verdi](https://www.synopsys.com/verification/debug/verdi.html)
* [Synopsys Design Compiler](https://www.synopsys.com/implementation-and-signoff/rtl-synthesis-test/dc-ultra.html)


<!-- GETTING STARTED -->
## Getting Started


### Prerequisites

You need:

1. Synopsys VCS
2. Synopsys Verdi
3. Synopsys Design Compiler 

### Installation

Contact Synopsys

### Build

You can build any of the .elf or .s files in the /design/testcode/ directory. Large assembly files exist under the /design/testcode/comp/ folder for greater coverage and coremark files exist under /design/testcode/coremark. comp/comp2_rv32im.elf and coremark/coremark_rv32im.elf include the m-extension, note the 'm' before the '.elf'. None of the other files have an m-extension supported version. You must be in the 'Design' folder to compile any files.

Example:
```
make run ASM=testcode/coremark/coremark_rv32im.elf
```

When the simulation has completed, you will see:

![result](end_of_sim.png)


### Generate Analysis Files

To view timing and area analysis, you need to synthesize the design. They will be placed in the synth/reports folder.

```
make synth
```

the timing report looks like this:

![timing-report](timing-report-1.png)
It shows you the critical path (it's cut off here), the time allowed for the critical path to resolve, and the time it actually took for the critical path to resolve (the difference between what we allow and what happened is the slack).

The area report looks like this:

![area-report](area-report.png)
It shows you the area breakdown in terms of combinational, non-combinational, total and a further breakdown by module (it's cut off here).

To generate the power analysis, you must specify which program you are analyzing the power for:

```
make report_power ASM=testcode/comp/comp2_rv32i.elf
```

The power report will show:

![power-report](power-report.png)
The top and bottom are cutoff to save space. Our design's power is overwhelmingly consumed by the caches, specifically the 4-way shared L2 cache.


# Details:

### icache/dcache

The icache and dcache are both direct mapped with 32 byte cachelines with 16 lines, giving a total size of 512 bytes. The caches are separate which allow simultaneous access by the cpu. The icache is used by the instruction fetch stage and the dcache is used by the memory stage. Both caches are connected to the arbiter which facilitates physical memory accesses and resolves simultaneous memory requests.

### Arbiter

The arbiter connects the icache or dcache to the L2 cache whenever there is a memory request from the cpu. If both the icache and dcache request access to memory at the same time, the arbiter will prioritize the dcache. The choice to prioritize the dcache is arbitrary. Here is the state machine for the arbiter:

![arbiter_states](arbiter_state_machine.png)

### 5 Stage Pipeline

Our pipeline includes an instruction fetch stage [IF], an instruction decode stage [ID], an execute stage [EX], a memory stage [MEM] and a write back stage [WB]. There are four pipeline registers, one between each stage, which store all values passed to the next stage. We also have a hazard detection unit that stalls the pipeline on cache misses or when the multiplier is executing and adds bubbles to the pipeline when there is a read-after-write-from-memory dependency or a branch misprediction. We have a forwarding unit as well to send correct values to the EX stage when instructions have read-after-write-to-register dependencies.

[add picture of pipeline datapath with hazard detection and forwarding]

### L2 Cache

The L2 cache is 4-way set associative using the pLRU replacement policy. Each line is 32 bytes and there are 16 sets, making it 2 KB large. It is a shared cache, storing cachlines for the icache and dcache. the L2 cache connects to the 'cacheline adapter' which itself connects to the main memory. The cacheline adapter accepts 4 bursts of 8 bytes of data, combines them, and sends the resulting 32 bytes of data to the L2 cache. 

[picture of L2 cache]

### Branch Prediction

The branch predictor implemented in this design uses a local branch history table (LBHT), a direction prediction table (DPT) and a branch target buffer (BTB). The LBHT is indexed by bits [6:2] of the PC, which gives us 32 entries in the LBHT. Each entry stores 5 bits of branch history and itself is used to index into the direction prediction table (DPT). This also gives us 32 entries in the DPT. Each entry of the DPT stores a 2-bit saturation counter where 00 = strongly not taken, 01 = weakly not taken, 10 = weakly taken, 11 = strongly taken. The BTB stores the target branch address for each branch instruction the cpu comes accross. Bits [7:2] are used to index into the BTB, giving the BTB 64 entries. When the DPT predicts 'taken' and there is a BTB hit, then we take the target prediction form the BTB as the next instruction address.

![branch-prediction](branch_prediction.png)

The Branch predictor and BTB are separate elements in the datapath. Both are connected to the IF stage, which uses them to predict the next instruction on a branch, and the EX stage, which determines if the prediction was correct or not. If it is correct, the DPT and LBHT are updated. If it is incorrect, the DPT and LBHT are updated but the hazard detection module also clears the instructions in the IF and ID stage. Here is a diagram that shows more clearly the connections in our datapath:

![bp-datapath](bp_datapath.png)

### M-Extension

The M-Extension adds 8 more instructions: MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM and REMU. When either the multiplier or the divider is working, the whole pipeline is stalled until the resp signal from the M_EXT module is recieved. The multiplier is a basic add-shift design, adding a shifted version of the multiplicant for each '1' in the multiplier to the product. Here is a diagram showing how the multiplier is connected:

![m-extension](m_extension.png)

### Performance Counters

To help us measure the performance gains and also ensure that our features are actually working correctly, we added performance counters to the branch prediction, caches and general stalling (through pipeline stalls or bubbles). The following image shows the specific metrics that are tracked:

![performance-counters](performance_counters.png)

### Detailed Datapath

[show block diagram here]

# Performance Analysis and Design Evolution

The performance of the cpu is based on high speeds and low power. The equation used to evaluate this performance is P\*D^2\*(100/fmax)^2 where P is the average power usage, D is the average execution time, and fmax is the maximum frequency.

We tracked speeds between several different versions of the cpu in it's development as shown:

![performance-by-program](performance_by_program.png)

First an L2 cache was added, which was only 2-way and it was compared to the base 5-stage pipeline. It was then changed to be 4-way as the massive increase in performance justified the increase in power. Additional features were added on top of the 4-way L2 cache version. Initially the design included a prefetcher, but it was not implemented correctly and decreased performance. It was a basic prefetcher that requested the next block after a memory request. Since it is a shared L2 cache, it is thought that a lot of pollution was generated in the cache as a result of dcache memory accesses, which are not well predicted by the (i+1)th block of memory. For this reason the prefetcher was removed from the design.
Power was also analyzed, but only against one program:

![power-cp3](power_cp3.png)

Initially the cache sizes only had 8 entries each. But after collecting the performance results shown above, the cache sizes were doubled to the 16 entries each that they are now. The concern was that the increase in power would offset the gain in performance. For this reason, performance results were collected between normal sized caches and double sized caches when optimizing the maximum frequency. These results are shown below:

![fmax-raw](fmax_raw.png)

Curiously, Synopsys's synthesis tools were able to optimize the power usage for the larger caches better than the smaller caches, resulting in lower power usage at higher frequencies for the larger cache design compared to the smaller cache design. The actual scores using the performance metric equation are calculated using the data above and are shown in the following table:

![scores](scores.png)

The lowest number under the score column is the best design under the conditions tested. This is also the design on this repo.

# Ranking

In both the class competition and the coremark competition, this design came in 4th place.

Class Competition:

![class](class.png)

Coremark Competition:

![coremark](coremark.png)

# Improvement Possibilities

1) A victim cache for both the icache and dcache. This fully associative cache will hold all evicted cachelines just in case they are needed again. 
2) Some kind of prefetcher, probably a strided prefetcher. Since there is a shared L2 cache, a strided prefetcher would make prefetching predictions based on the calculated stride from previously used blocks. This could reduce the pollution problems that were encounted from using an i+1 prefetcher.
3) A more advanced multiplier. Instead of the basic add-shift multiplier, a Wallace Tree multiplier would calculate the product more efficiently, reducing the number of stalls caused by the multiplier. 
4) The C-extension. The C-extension allows instructions to be stored in a 16-bit form. This reduction in size allows more instructions to be stored in the caches, thus reducing the total number of cache misses.

<!-- ACKNOWLEDGEMENTS -->
# Acknowledgements
* [Readme Template](https://github.com/othneildrew/Best-README-Template)




