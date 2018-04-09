-- Student name: Tyler Bradley
-- Student ID number: 6574390

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity RegFile is 
  port(
        clk, wr_en                    : in STD_LOGIC;
        rd_addr_1, rd_addr_2, wr_addr : in REG_addr;
        d_in                          : in word; 
        d_out_1, d_out_2              : out word
  );
end RegFile;

architecture RF_arch of RegFile is
-- component declaration
-- signal declaration
type RFile_type is array (REG_range) of word;
signal reg_f : RFile_type;

begin
PROCESS (clk, wr_en, wr_addr, rd_addr_1, rd_addr_2, d_in)
	BEGIN
		IF(clk'EVENT AND clk = '1') THEN
			IF(wr_en = '1') THEN 
			    if(wr_addr = "00000") then
			    reg_f(0) <= zero32;
			    else
                reg_f(to_integer(unsigned(wr_addr))) <= d_in;
                end if;

			END IF;
		END IF;
			
END PROCESS;

d_out_1 <= zero32 when rd_addr_1 = "00000" else reg_f(to_integer(unsigned(rd_addr_1)));
d_out_2 <= zero32 when rd_addr_2 = "00000" else reg_f(to_integer(unsigned(rd_addr_2)));

end RF_arch;
