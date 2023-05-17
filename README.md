<!-- TABLE OF CONTENTS -->
## Table of Contents

* [About the Project](#about-the-project)
  * [Built With](#built-with)
* [Getting Started](#getting-started)
  * [Prerequisites](#prerequisites)
  * [Build](#installation)
  * [Generate Analysis Files](#generate-analysis-files)
  * [Design](#design)
* [Acknowledgements](#acknowledgements)



<!-- ABOUT THE PROJECT -->
## About The Project

![high-level](high-level%20block%20diagram.png)


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

You can build any of the .elf or .s files in the /design/testcode/ directory. Large assembly files exist under the /design/testcode/comp/ folder for greater coverage and coremark files exist under /design/testcode/coremark. comp/comp2_rv32im.elf and coremark/coremark_rv32im.elf include the m-extension, note the 'm' before the '.elf'. You must be in the 'Design' folder to compile any files.

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

[show timing analysis report]

[show area analysis report]

To generate the power analysis, you must specify which program you are analyzing the power for:

```
make report_power ASM=testcode/comp/comp2_rv32i.elf
```

[show power analysis report]


### Details:
* i-cache/d-cache
* arbiter
* 5 stage pipeline
* L2 cache
* branch prediction
* M-extension
* Performance metrics




In-depth Block Diagram:


[show block diagram here]


### Performance analysis and design evolution:



### Improvement Possibilities



<!-- ACKNOWLEDGEMENTS -->
## Acknowledgements
* [Readme Template](https://github.com/othneildrew/Best-README-Template)




