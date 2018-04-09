-- Student name: Tyler Bradley
-- Student ID number: 65743950

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity datapath is
  
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

end datapath;


architecture datapath_arch of datapath is
-- component declaration

-- component specification
COMPONENT rfaludatapath IS --lab 4 datapath + extra ports to "open up" this component
PORT(
	clk        : in std_logic;
    op_code    : in ALU_opcode;
    wr_en      : in std_logic;
    rs, rt, rd : in REG_addr;   
    d_in       : in word;
    Imm	   : in word;
	C	   : in std_logic_vector(4 downto 0);
	imm_ctrl: in std_logic;
	branch_address : in word;
	memory_address : in word;
	program_counter: in word;
	ALUSrcA    : in  std_logic;         -- selects source of A port of ALU
	ALUSrcB    : in  std_logic_vector(1 downto 0);  -- selects source of B port of ALU
	alu_result: out word;
	b_out : out word;
    d_out      : out word;
    Zero       : out std_logic

  );
END COMPONENT;
FOR ALL: rfaludatapath USE ENTITY work.rfaludatapath(rfaludatapath_arch)
PORT MAP (clk => clk, op_code => op_code, wr_en => wr_en, rs => rs, rt => rt, rd => rd, d_in => d_in, Imm => Imm, C => C, imm_ctrl => imm_ctrl, branch_address => branch_address,
memory_address => memory_address, program_counter => program_counter, ALUSrcA => ALUSrcA, ALUSrcB => ALUSrcB, alu_result => alu_result, b_out => b_out, d_out => d_out, Zero => Zero);

COMPONENT mem IS
   PORT (
	 MemRead	: IN std_logic;
	 MemWrite	: IN std_logic;
	 d_in		: IN   word;		 
	 address	: IN   word;
	 d_out		: OUT  word 
	 );
END COMPONENT;
FOR ALL: mem USE ENTITY work.mem(mem_arch)
PORT MAP (MemRead => MemRead, MemWrite => MemWrite, d_in => d_in, address => address, d_out => d_out);
-- signal declaration
SIGNAL branch_address_s : word; --((sign-extend (IR[15-0]) << 2))
SIGNAL memory_address_s : word; --sign-extend (IR[15-0])
signal jump_address_s: word; --(PC[31-28] && IR[25-0]<<2 (now 28 bits ))
signal alu_result_s: word;
signal alu_out_s: word;
signal instruction_register: word;
signal memory_data_register: word;
signal program_counter: word;
signal memory_out: word;--carrys data from memory after mem read
signal reg_b_out: word;
signal regfile_d_in: word;
signal regfile_wr_dest: REG_addr;
signal next_address: word;--
signal Imm_s: word;
signal imm_ctrl_s: std_logic;

begin

mem_0: mem
port map (
	MemRead => MemRead,
	MemWrite => MemWrite,
	d_in => reg_b_out,-- from register b 
	address => next_address,
	d_out => memory_out
	
	);

rfaludatapath_0: rfaludatapath
port map (
	clk => clk,
	op_code => ALUControl ,
	wr_en => RegWrite,
	rs => instruction_register(25 downto 21),
	rt => instruction_register(20 downto 16),
	rd => regfile_wr_dest,
	d_in => regfile_d_in,
	Imm => Imm_s,
	C => instruction_register(10 downto 6), --both immediate and shift amount are part of the instruction
	imm_ctrl => imm_ctrl_s,
	branch_address => branch_address_s,
	memory_address => memory_address_s,
	program_counter => program_counter,
	ALUSrcA => ALUSrcA,         -- selects source of A port of ALU
	ALUSrcB => ALUSrcB,  -- selects source of B port of ALU
	alu_result => alu_result_s,
	b_out => reg_b_out,--maybe change
	d_out => alu_out_s,--maybe change
	Zero => zero 
	
	);

process (clk, reset_N, memory_out, alu_result_s, alu_out_s, jump_address_s, IRWrite, PCUpdate, PCSource)
begin
	if (reset_N = '0') then
	program_counter <= Zero_word;
	instruction_register <= Zero_word;
	memory_data_register <= Zero_word;
	
	elsif (clk'EVENT and clk = '1') then
	
	if(PCUpdate = '1')then
	   	--program_counter <= alu_out_s;
         case PCSource is 
         when "00" => program_counter <= alu_result_s; 
         when "01" => program_counter <= alu_out_s;
         when others => program_counter <= jump_address_s;
         end case;

	end if;
	
	if(IRWrite = '1')then 
	instruction_register <= memory_out;
	else
	memory_data_register <= memory_out;
	end if;
	
	
	end if;
	
end process;
regfile_d_in <= alu_out_s when MemtoReg = "00" else
				memory_data_register when MemtoReg = "01" else
				program_counter	;
			
regfile_wr_dest <=  instruction_register(20 downto 16) when RegDst = "00" else
					instruction_register(15 downto 11) when RegDst = "01" else 
					"11111";
next_address <= program_counter when IorD = '0' else alu_out_s;
memory_address_s <= std_logic_vector(resize(signed(instruction_register(15 downto 0)), memory_address_s'length));
branch_address_s <= shl(std_logic_vector(resize(signed(instruction_register(15 downto 0)), branch_address_s'length)), "10");
jump_address_s <= program_counter(31 downto 28) & instruction_register(25 downto 0) & "00";
func_out <= instruction_register(5 downto 0);--op_code and funcion code are found in the instruction
opcode_out <= instruction_register(31 downto 26);
Imm_s <= "0000000000000000" & instruction_register(15 downto 0);
imm_ctrl_s <= (not instruction_register(31) and not instruction_register(30) and instruction_register(29) and not instruction_register(28) and not instruction_register(27) and not instruction_register(26) and not PCUpdate) or
	(not instruction_register(31) and not instruction_register(30) and instruction_register(29) and instruction_register(28) and not instruction_register(27) and not instruction_register(26)and not PCUpdate) or
	(not instruction_register(31) and not instruction_register(30) and instruction_register(29) and instruction_register(28) and not instruction_register(27) and instruction_register(26)and not PCUpdate);
  
end datapath_arch;




