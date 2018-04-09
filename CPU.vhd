-- Student name: Tyler Bradley
-- Student ID number: 65743950

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity CPU is
  
  port (
    clk     : in std_logic;
    reset_N : in std_logic);            -- active-low signal for reset

end CPU;

architecture CPU_arch of CPU is
-- component declaration
	
	-- Datapath (from Lab 5)
	component datapath is
  
  port (
    clk        : in  std_logic;
    reset_N    : in  std_logic;
    
    PCUpdate   : in  std_logic;         -- write_enable of PC

    IorD       : in  std_logic;         -- Address selection for memory (PC vs. store address)
    MemRead    : in  std_logic;		-- read_enable for memory
    MemWrite   : in  std_logic;		-- write_enable for memory

    IRWrite    : in  std_logic;         -- write_enable for Instruction Register
    MemtoReg   : in  std_logic_vector(1 downto 0);  -- selects ALU or MEMORY or PC to write to register file.
    RegDst     : in  std_logic_vector(1 downto 0);  -- selects rt, rd, or "31" as destination of operation
    RegWrite   : in  std_logic;         -- Register File write-enable
    ALUSrcA    : in  std_logic;         -- selects source of A port of ALU
    ALUSrcB    : in  std_logic_vector(1 downto 0);  -- selects source of B port of ALU
    
    ALUControl : in  ALU_opcode;	-- receives ALU opcode from the controller
    PCSource   : in  std_logic_vector(1 downto 0);  -- selects source of PC

    opcode_out : out opcode;		-- send opcode to controller
    func_out   : out opcode;		-- send func field to controller
    zero       : out std_logic);	-- send zero to controller (cond. branch)

end component;
FOR ALL: datapath USE ENTITY work.datapath(datapath_arch)
PORT MAP (clk => clk, reset_N => reset_N, PCUpdate => PCUpdate, IorD => IorD, MemRead => MemRead, MemWrite => MemWrite,
IRWrite => IRWrite, MemtoReg => MemtoReg, RegDst => RegDst, RegWrite => RegWrite, ALUSrcA => ALUSrcA, ALUSrcB => ALUSrcB,
ALUControl => ALUControl, PCSource => PCSource, opcode_out => opcode_out, func_out => func_out, zero => zero);
	-- Controller (you just built)
component control is 
   port(
        clk   	    : IN STD_LOGIC; 
        reset_N	    : IN STD_LOGIC; 
        
        opcodee      : IN opcode;     -- declare type for the 6 most significant bits of IR
        funct       : IN opcode;     -- declare type for the 6 least significant bits of IR 
     	zero        : IN STD_LOGIC;
        
     	PCUpdate    : OUT STD_LOGIC; -- this signal controls whether PC is updated or not
     	IorD        : OUT STD_LOGIC;
     	MemRead     : OUT STD_LOGIC;
     	MemWrite    : OUT STD_LOGIC;

     	IRWrite     : OUT STD_LOGIC;
     	MemtoReg    : OUT STD_LOGIC_VECTOR (1 downto 0); -- the extra bit is for JAL
     	RegDst      : OUT STD_LOGIC_VECTOR (1 downto 0); -- the extra bit is for JAL
     	RegWrite    : OUT STD_LOGIC;
     	ALUSrcA     : OUT STD_LOGIC;
     	ALUSrcB     : OUT STD_LOGIC_VECTOR (1 downto 0);
     	ALUcontrol  : OUT ALU_opcode;
     	PCSource    : OUT STD_LOGIC_VECTOR (1 downto 0)
	);
end component;
FOR ALL: control USE ENTITY work.control(control_arch)
PORT MAP (clk => clk, reset_N => reset_N, opcodee => opcodee, funct => funct, zero => zero, PCUpdate => PCUpdate,
IorD => IorD, MemRead => MemRead, MemWrite => MemWrite, IRWrite => IRWrite, MemtoReg => MemtoReg,
RegDst => RegDst, RegWrite => RegWrite, ALUSrcA => ALUSrcA, ALUSrcB => ALUSrcB, ALUControl => ALUControl, PCSource => PCSource);
-- component specification

-- signal declaration
--these signals allow us to connect the output of one entity to the input of the other. 
signal PCUpdate_s   :   std_logic;      

signal IorD_s       :   std_logic;         
signal MemRead_s    :   std_logic;       
signal MemWrite_s   :   std_logic;        

signal IRWrite_s    :   std_logic;        
signal MemtoReg_s   :   std_logic_vector(1 downto 0); 
signal RegDst_s     :   std_logic_vector(1 downto 0); 
signal RegWrite_s   :   std_logic;         
signal ALUSrcA_s    :   std_logic;        
signal ALUSrcB_s    :   std_logic_vector(1 downto 0);  

signal ALUControl_s :  ALU_opcode;    
signal PCSource_s   :  std_logic_vector(1 downto 0);  

signal opcode_out_s :  opcode;  
signal func_out_s   :  opcode; 
signal zero_s       :  std_logic;

begin
--here we create a datapath and a controller and use the signals above to connect the two together
datapath_0: datapath
port map (
    clk => clk,   
    reset_N => reset_N,  
    
    PCUpdate => PCUpdate_s, 

    IorD => IorD_s,
    MemRead => MemRead_s,  
    MemWrite  => MemWrite_s,

    IRWrite  =>IRWrite_s ,
    MemtoReg  => MemtoReg_s,
    RegDst => RegDst_s,
    RegWrite => RegWrite_s,
    ALUSrcA  => ALUSrcA_s,
    ALUSrcB => ALUSrcB_s,
    
    ALUControl => ALUControl_s,
    PCSource => PCSource_s,

    opcode_out => opcode_out_s,
    func_out  => func_out_s,
    zero => zero_s
);

control_0: control
port map (
        clk => clk,
        reset_N	=> reset_N, 
        
        opcodee  => opcode_out_s ,   
        funct   => func_out_s,     
     	zero   => zero_s,     
        
     	PCUpdate    => PCUpdate_s,
     	IorD    => IorD_s,   
     	MemRead   => MemRead_s,  
     	MemWrite   => MemWrite_s, 

     	IRWrite   => IRWrite_s,  
     	MemtoReg   => MemtoReg_s,  
     	RegDst   => RegDst_s,  
     	RegWrite   => RegWrite_s, 
     	ALUSrcA   => ALUSrcA_s,  
     	ALUSrcB   => ALUSrcB_s,  
     	ALUcontrol   => ALUControl_s,
     	PCSource   =>  PCSource_s 
);
end CPU_arch;
