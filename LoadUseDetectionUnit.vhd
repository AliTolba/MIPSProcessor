Library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;

ENTITY LoadUseDetectionUnit is
	PORT(
		RsDSig: IN  std_logic_vector(2 DOWNTO 0); --S4
		RdDsig: IN std_logic_vector (2 downto 0); --S5
		RdEsig: IN std_logic_vector (2 downto 0); --S20
		MemWriteESig: In std_logic; --S14
		FDBufferEnable: out std_logic); --S7
END ENTITY LoadUseDetectionUnit;

Architecture myLoadUseDetectionUnit of LoadUseDetectionUnit is 
begin

FDBufferEnable<='0' when MemWriteESig='1' and (RsDSig=RdEsig or RdDsig=RdEsig) 
		else '1';

end architecture;
