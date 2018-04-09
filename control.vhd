-- Student name: Tyler Bradley
-- Student ID number: 65743950

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity control is 
   port(
        clk   	    : IN STD_LOGIC; 
        reset_N	    : IN STD_LOGIC; 
        
        opcodee      : IN opcode;     -- declare type for the 6 most significant bits of IR
        funct       : IN opcode;     -- declare type for the 6 least significant bits of IR 
     	zero        : IN STD_LOGIC; -- used for branches
        
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
end control;

architecture control_arch of control is

type cpu_state is --these are the states of our finite state machine, they match our specification which is a copy of the mips fsm drawing from cs152 (and i think this class as well)
	(fetch, decode, mem_addr_comp, mem_access_ld, mem_access_st, write_back, exec, r_type_completion, branch_completion, jump_completiton);

--our fsm produces outputs based on our current state and a next state.
signal cur_cpu_state, nxt_cpu_state : 	cpu_state;	
-- each state will determine which state we go to next  along with the appropriate control signals as seen below
signal nxt_PCUpdate    :  STD_LOGIC;
signal nxt_IorD        :  STD_LOGIC;
signal nxt_MemRead     :  STD_LOGIC;
signal nxt_MemWrite    :  STD_LOGIC;

signal nxt_IRWrite     :  STD_LOGIC;
signal nxt_MemtoReg    : STD_LOGIC_VECTOR (1 downto 0); 
signal nxt_RegDst      :  STD_LOGIC_VECTOR (1 downto 0); 
signal nxt_RegWrite    :  STD_LOGIC;
signal nxt_ALUSrcA     :  STD_LOGIC;
signal nxt_ALUSrcB     :  STD_LOGIC_VECTOR (1 downto 0);
signal nxt_ALUcontrol  :  ALU_opcode;
signal nxt_PCSource    :  STD_LOGIC_VECTOR (1 downto 0);


begin
process (clk, reset_N, zero, opcodee, funct)
begin

	if (reset_N = '0') then
	--we start in any state where the next state is fetch so that our timings align. This means the first clock cycle we do nothing
	cur_cpu_state <= jump_completiton;
    nxt_cpu_state <= fetch;
       
	elsif (clk'EVENT and clk = '1') then
	--the way this is set up is like this: at the rising edge of the clock, the current state and the current signals are updated, initiating the 
	--calculation the need to occur during this state. Meanwhile the control unit generates the signals and state needed for the next clock
	--cycle as seen in the case statement below
		cur_cpu_state <= nxt_cpu_state;
		PCUpdate <= nxt_PCUpdate;
		IorD <= nxt_IorD;
		MemRead <= nxt_MemRead;
		MemWrite <= nxt_MemWrite;
		IRWrite <= nxt_IRWrite;
		MemtoReg <= nxt_MemtoReg;
		RegDst <= nxt_RegDst;
		RegWrite <= nxt_RegWrite;
		ALUSrcA <= nxt_ALUSrcA;
		ALUSrcB <= nxt_ALUSrcB;
		ALUcontrol <= nxt_ALUcontrol;
		PCSource <= nxt_PCSource;
    end if;
	
	case cur_cpu_state is 
	when fetch => 	nxt_cpu_state <= decode;--fetch and decode are common to all instructions; this transition is unconditional
							nxt_IRWrite <= '0'; --IR disabled, MDR enabled
							nxt_PCUpdate <= '0'; -- PC off
							nxt_MemRead <= '0'; -- MemRead off
							nxt_ALUSrcB <= "11";--bracnh address
							nxt_ALUSrcA <= '0'; -- program counter
	when decode =>	case opcodee is 
								when "000000" => nxt_cpu_state <= exec;--R-Type instruction
															nxt_ALUSrcB <= "00"; -- register b
															nxt_ALUSrcA <= '1'; --reg a
															case funct is --this chooses the alu operation
															when "000000" => nxt_ALUControl <= "010";--sll
															when "000010" => nxt_ALUControl <= "011";--srl
															when "100000" => nxt_ALUControl <= "000";--add
															when "100010" => nxt_ALUControl <= "001";--subtract
															when "100100" => nxt_ALUControl <= "100";--and 
															when others => nxt_ALUControl <= "101";--or
															end case;
								when "000010" => nxt_cpu_state <= jump_completiton;--Jump instruction
																						nxt_PCSource <= "10";--jump address
																						nxt_PCUpdate <= '1';
																						nxt_IorD <= '0';--next mem address comes from PC
								when "000100"|"000101" => nxt_cpu_state <= branch_completion;--be or bne (branch) instruction
																			nxt_ALUControl <= "001";--alu subtract
																			nxt_ALUSrcB <= "00"; -- register b
																			nxt_ALUSrcA <= '1'; --reg a												
																			nxt_PCSource <= "01";--alu_out
                                                                            nxt_IorD <= '1';--next mem address comes from alu
								when "100011"|"101011" => nxt_cpu_state <= mem_addr_comp; --Load or Store instruction
																		   nxt_ALUSrcB <= "10"; -- 16 bit sign extended to 32
																		   nxt_ALUSrcA <= '1'; --reg a
								when others => nxt_cpu_state <= exec; -- Immediate instruction; r type exec state is recycled with a single change and that src b is immediate not reg b
															nxt_ALUSrcB <= "01"; -- immediate value
															nxt_ALUSrcA <= '1'; --reg a
															case opcodee is --chooses the alu operation for the immediate instructions
															when "001100" => nxt_ALUControl <= "100"; --andi
															when "001101" => nxt_ALUControl <= "101"; --ori
															when others => nxt_ALUControl <= "000"; --addi
															end case;
								end case;
	when mem_addr_comp =>	if(opcodee = "100011") then--either we are doing a load (read) or a store (write)
											nxt_cpu_state <= mem_access_ld;
											nxt_IorD <= '1';
											nxt_MemRead <= '1';
											else
											nxt_cpu_state <= mem_access_st;
											nxt_IorD <= '1';
											nxt_MemWrite <= '1';
											end if;
	when mem_access_ld =>	nxt_cpu_state <= write_back;
											nxt_RegDst <= "00"; --rt
											nxt_MemtoReg <= "01";-- mdr
											nxt_RegWrite <='1';--reg write on
											nxt_IorD <= '0'; 
											nxt_MemRead <= '0';
	when mem_access_st =>	--here we prepare for the next fetch, these signal assignments will be common to every last state of an instruction.
										nxt_MemRead <= '1';--read instruction from pc										
										nxt_MemWrite <= '0';
										nxt_IorD <= '0';--mem address from pc
										nxt_MemtoReg <= "00"; --reg file d_in = alu_out
										nxt_RegWrite <= '0';
										nxt_PCUpdate <= '1'; --PC+4
										nxt_IRWrite <= '1';--write next instruction
										nxt_ALUcontrol <="000";--alu add
										nxt_PCSource <= "00";--alu
										nxt_ALUSrcB <= "01";-- constant 4 
										nxt_ALUSrcA <= '0'; -- program counter
										nxt_cpu_state <= fetch;
	when write_back =>	
									nxt_MemWrite <= '0';
									nxt_IorD <= '0';
									nxt_MemtoReg <= "00";
									nxt_MemRead <= '1';
									nxt_RegWrite <= '0';
									nxt_PCUpdate <= '1';
									nxt_IRWrite <= '1';
									nxt_ALUcontrol <="000";
									nxt_PCSource <= "00";
									nxt_ALUSrcB <= "01";-- constant 4 
									nxt_ALUSrcA <= '0'; -- program counter
									nxt_cpu_state <= fetch;
	when exec =>	nxt_MemtoReg <= "00";
							nxt_RegWrite <= '1'; 
							nxt_MemRead <= '1'; 
							if (opcodee /= "000000") then --immediate destination reg is rt and r type is rd
							nxt_RegDst <= "00";--rt 
							else
							nxt_RegDst <= "01"; --rd
							end if;
							nxt_cpu_state <= r_type_completion;

	when r_type_completion =>	
												nxt_MemWrite <= '0';
												nxt_IorD <= '0';
												nxt_MemtoReg <= "00";
												nxt_MemRead <= '1';
												nxt_RegWrite <= '0';
												nxt_PCUpdate <= '1';
												nxt_IRWrite <= '1';
												nxt_ALUcontrol <="000";
												nxt_PCSource <= "00";
												nxt_ALUSrcB <= "01";-- constant 4 
												nxt_ALUSrcA <= '0'; -- program counter
												nxt_cpu_state <= fetch;
												
	when branch_completion =>	if ((opcodee ="000100" AND zero = '1') or (opcodee = "000101" AND zero = '0')) then											
												PCUpdate <= '1';	--we must immediately update the pc if we are branching
												end if;												
												nxt_IorD <= '0';
												nxt_PCSource <= "00";
												nxt_MemWrite <= '0';
												nxt_MemtoReg <= "00";												
												nxt_MemRead <= '1';
												nxt_RegWrite <= '0';
												nxt_PCUpdate <= '1';
												nxt_IRWrite <= '1';
												nxt_ALUcontrol <="000";
												nxt_ALUSrcB <= "01";-- constant 4 
												nxt_ALUSrcA <= '0'; -- program counter
												nxt_cpu_state <= fetch;

	when jump_completiton =>											
												nxt_MemWrite <= '0';
												nxt_IorD <= '0';
												nxt_MemtoReg <= "00";
												nxt_MemRead <= '1';
												nxt_RegWrite <= '0';
												nxt_PCUpdate <= '1';
												nxt_IRWrite <= '1';
												nxt_ALUcontrol <="000";
												nxt_PCSource <= "00";
												nxt_ALUSrcB <= "01";-- constant 4 
												nxt_ALUSrcA <= '0'; -- program counter
												nxt_cpu_state <= fetch;
	
												
	end case;
end process;

end control_arch;
