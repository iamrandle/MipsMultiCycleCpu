
-- Student name: Tyler Bradley
-- Student ID number: 65743950

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;
entity intermediate_reg is --this will be for the outputs of regfile and ALU (multicycle implementation)
    PORT
    (
        clk: in std_logic;
        reg_in: in word;
        reg_out: out word
    );
end intermediate_reg;
architecture intermediate_reg_arch of intermediate_reg is
begin
    PROCESS (clk, reg_in)
    BEGIN
        IF(clk'EVENT AND clk = '1') THEN
            reg_out <= reg_in;--writes into reg on the rising edge
        END IF;
    END PROCESS;
end intermediate_reg_arch;
-- Among the ports below of the datapath
-- rs, rt, rd correspond to  rd_addr_1, rd_addr_2, wr_addr of the Register file
-- d_in corresponds to d_in of the Register file
-- d_out is output from the register ALUout  
LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;
entity rfaludatapath is 
  PORT( clk        : in std_logic;
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
		b_out	:	out word;
        d_out      : out word;
        Zero       : out std_logic
  );
end rfaludatapath;

architecture rfaludatapath_arch of rfaludatapath is
-- component declaration
-- one alu, one reg file, 2 registers connecting the two, one register holding the alu output
COMPONENT RegFile IS 
PORT(
        clk, wr_en                    : in STD_LOGIC;
        rd_addr_1, rd_addr_2, wr_addr : in REG_addr;
        d_in                          : in word; 
        d_out_1, d_out_2              : out word
  );
END COMPONENT;
FOR ALL: RegFile USE ENTITY work.RegFile(RF_arch)
PORT MAP (clk => clk, wr_en => wr_en, rd_addr_1 => rd_addr_1, rd_addr_2 => rd_addr_2, wr_addr => wr_addr, d_in => d_in, d_out_1 => d_out_1, d_out_2 => d_out_2);

COMPONENT ALU IS
PORT( op_code  : in ALU_opcode;
        in0, in1 : in word;	
        C	 : in std_logic_vector(4 downto 0);  -- shift amount	
        ALUout   : out word;
        Zero     : out std_logic
  );
END COMPONENT;
FOR ALL: ALU USE ENTITY work.ALU(ALU_arch)
PORT MAP (op_code => op_code, in0 => in0, in1 => in1, C => C, ALUout => ALUout, Zero => Zero);

COMPONENT intermediate_reg IS 
PORT( clk: in std_logic;
      reg_in: in word;
      reg_out : out word
      );
END COMPONENT;
FOR ALL: intermediate_reg USE ENTITY work.intermediate_reg(intermediate_reg_arch)
PORT MAP (clk => clk, reg_in => reg_in, reg_out => reg_out);
-- signal declaration
--need these signals to connect the two components


SIGNAL d_out_1_s : word;
SIGNAL d_out_2_s : word;
SIGNAL reg_a_s : word;
SIGNAL reg_b_s : word;
SIGNAL reg_aluout_s : word;
SIGNAL alu_a: word;
SIGNAL alu_b: word;
SIGNAL alu_constant: word;
begin

reg_file0: RegFile
PORT MAP(
	clk => clk,
	wr_en => wr_en,
	rd_addr_1 => rs,
	rd_addr_2 => rt,
	wr_addr => rd,
	d_in => d_in,
	--before this point we can directly connect the ports of the datapath entity to the ports of the RegFile entity
	d_out_1 => d_out_1_s , --the outputs need to be sent to a signal because they will connect the RegFile to the ALU
	d_out_2 => d_out_2_s
	);
	
	reg_a: intermediate_reg
    PORT MAP (
        clk => clk, --can connect directly to top level clock because we are not connecting an output to an input
        reg_in => d_out_1_s,
        reg_out => reg_a_s
    );
    
    reg_b: intermediate_reg
    PORT MAP (
        clk => clk,
        reg_in => d_out_2_s,
        reg_out => reg_b_s
    );
	
alu0: ALU
PORT MAP(
	op_code => op_code ,
	in0 => alu_a, --as seen before, the reg signals connect the RegFile to the registers and then to the ALU, the other ports are connected directly
	in1 => alu_b,
	C => C ,
	ALUout => reg_aluout_s,
	Zero => Zero
	);
	
	reg_alu: intermediate_reg
    PORT MAP (
        clk => clk,
        reg_in => reg_aluout_s,
        reg_out => d_out
    );
	alu_result <= reg_aluout_s;
	b_out <= reg_b_s;
	alu_a <= reg_a_s when ALUSrcA = '1' else program_counter;
	alu_constant <= four32 when imm_ctrl = '0' else Imm;
	alu_b <= reg_b_s 	   when ALUSrcB = "00" else 
			 alu_constant 	   when ALUSrcB = "01" else  
			 memory_address when ALUSrcB = "10" else 
			 branch_address;					
	
	
end rfaludatapath_arch;
