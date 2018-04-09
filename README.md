# MipsMultiCycleCpu
An implementation of the Mips Multi Cycle Cpu in VHDL


The top level entity is the CPU and the structure goes as follows:
CPU -> Datapath; Control;
Datapath -> Mem; rfaludatapath;
rfaludatapath -> ALU; RegFile;

This implementation can be expanded on, for example the immediate functions are limited.
This code should be cleaned up to ensure it as readable as possible.
There may be redudancies that can be simplified (ie intermediate reg entity in rfaludatapath.
The images show different types of instructions executing properly; These instruction are found in Mem.vhd
