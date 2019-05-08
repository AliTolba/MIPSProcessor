Library ieee;
use ieee.std_logic_1164.all;

entity sixten_bitReg is
		port( a : in std_logic_vector(15 downto 0);
			b : out std_logic_vector (15 downto 0);
			enable : in std_logic;
			reset : in std_logic;
			clck : in std_logic
			);
end entity;

Architecture a_16bitReg of sixten_bitReg is
begin
	process(clck,reset)
	begin
		if reset = '1' then
		b<=(others=>'0');
		elsif clck = '1' and enable = '1' then
		b<=a;
		end if;
	end process;
end Architecture;