Library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;

ENTITY BranchControlUnit is
	PORT(
		OpCodeExecuteSig: IN  std_logic_vector(4 DOWNTO 0); --S12
		FlagRegisterSig: IN std_logic_vector (2 downto 0); --S26
		BranchControlOutSig: out std_logic); --S25
END ENTITY BranchControlUnit;

Architecture myBranchControlUnit of BranchControlUnit is 
begin

BranchControlOutSig<= '1' when OpCodeExecuteSig="11000" or OpCodeExecuteSig="11001" or (OpCodeExecuteSig="10101" and FlagRegisterSig(0) ='1') 
or (OpCodeExecuteSig="10110" and FlagRegisterSig(0) ='1') or (OpCodeExecuteSig="10111" and FlagRegisterSig(0) ='1') else '0';

end architecture;
