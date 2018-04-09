-- Student name: Tyler Bradley
-- Student ID number: 65743950

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity CPU_tb is
end CPU_tb;

architecture CPU_test of CPU_tb is
-- component declaration
	-- CPU (you just built)
	component CPU IS
	port	(
				clk     : in std_logic;
				reset_N : in std_logic
			);
	end component;

-- component specification
FOR ALL: CPU USE ENTITY work.CPU(CPU_arch)
PORT MAP (clk => clk, reset_N => reset_N);
-- signal declaration
	-- You'll need clock and reset.
	signal clk       :   std_logic := '1'; 
	signal reset_N    :   std_logic := '0';
begin
comp_to_test: CPU port map (clk => clk, reset_N => reset_N);
clk <= NOT clk after 20 ns;
process
begin
wait for 80 ns;
reset_N <= '1';--all there is to do is turn on and off reset and let the program run
wait;
end process;
end CPU_test;
