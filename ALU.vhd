-- Student name: Tyler Bradley
-- Student ID number: 65743950

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity ALU is 
  PORT( op_code  : in ALU_opcode;
        in0, in1 : in word;	
        C	 : in std_logic_vector(4 downto 0);  -- shift amount	
        ALUout   : out word;
        Zero     : out std_logic
  );
end ALU;

architecture ALU_arch of ALU is
-- signal declaration
--below are signals for the mux to select for its output
SIGNAL add : word;
SIGNAL sub : word;
SIGNAL shifted_left: word;
SIGNAL shifted_right: word;
SIGNAL anded: word;
SIGNAL ored: word;
SIGNAL xored: word;
SIGNAL nored: word;
SIGNAL output: word;

begin
--below is the comb. logic for each part of the ALU; one is selected based on the opcode
anded <= in0 AND in1;
ored <= in0 OR in1;
xored <= in0 XOR in1;
nored <= in0 NOR in1;
add <= in0 + in1;
sub <= in0 + (NOT in1) + 1;
shifted_left <= shl(in1,C);--from std_logic_usigned.all
shifted_right <= shr(in1, C);--from std_logic_usigned.all
PROCESS (op_code, output, anded, ored, xored, nored, add, sub, shifted_left, shifted_right)
	BEGIN
        -- essentially a 8 to 1 mux
		CASE op_code IS
		WHEN "000" => output <= add;
		WHEN "001" => output <= sub;
		WHEN "010" => output <= shifted_left;
		WHEN "011" => output <= shifted_right;
		WHEN "100" => output <= anded;
		WHEN "101" => output <= ored;
		WHEN "110" => output <= xored;
		WHEN "111" => output <= nored;
		WHEN OTHERS => output <= add; --the tool said I needed an others clause so i defaulted it to add
		
		END CASE;
		IF(output = zero32) THEN --zero32 defined in glob_dcls
                    Zero <= '1'; --alu == zero
                ELSE
                    Zero <= '0';
                END IF;
	
END PROCESS;

ALUout <= output; --set ALUout
end ALU_arch;
