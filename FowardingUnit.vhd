Library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;

ENTITY ForwardingUnit is
	PORT(
		MulMem: IN std_logic;	--S31
		MulWB: IN std_logic;	--S58
		RsExec : IN  std_logic_vector(2 DOWNTO 0); --S20
		RdExec  : IN  std_logic_vector(2 DOWNTO 0); --S21
		RsMem : IN std_logic_vector(2 DOWNTO 0);  --S29
		RdMem:  IN  std_logic_vector(2 DOWNTO 0); --S30
		RsWB:  IN  std_logic_vector(2 DOWNTO 0); --S56
		RdWB:  IN  std_logic_vector(2 DOWNTO 0); --S57
		WBControlMem: IN  std_logic_vector(4 DOWNTO 0); --S39
		WBControlWB: IN std_logic_vector (4 downto 0); --S53
		ForwardOP1Signal: out std_logic_vector(2 downto 0); --S32
		ForwardOP2Signal: out std_logic_vector(2 downto 0)); --S33
END ENTITY ForwardingUnit;

Architecture myForwardingUnit of ForwardingUnit is 
begin
ForwardOP1Signal<= "001" when RsExec=RdMem and (WBControlMem(4)='1' or WBControlMem(3)='1')
else "010" when RsExec=RsMem and MulMem='1' and (WBControlMem(4)='1' or WBControlMem(3)='1')
else "011" when RsExec=RdWB and (WBControlWB(4)='1' or WBControlWB(3)='1')
else "100" when RsExec=RsWB and MulWB='1' and (WBControlWB(4)='1' or WBControlWB(3)='1')
else "000";

ForwardOP2Signal<= "001" when RdExec=RdMem and (WBControlMem(4)='1' or WBControlMem(3)='1')
else "010" when RdExec=RsMem and MulMem='1' and (WBControlMem(4)='1' or WBControlMem(3)='1')
else "011" when RdExec=RdWB and (WBControlWB(4)='1' or WBControlWB(3)='1')
else "100" when RdExec=RsWB and MulWB='1' and (WBControlWB(4)='1' or WBControlWB(3)='1')
else "000";



end architecture;