Library ieee;
use ieee.std_logic_1164.all;

entity tristate is
generic(n:integer:=16);
	port( in1 : in std_logic_vector(n-1 downto 0);
		choice : in std_logic;
		out1 : out std_logic_vector(n-1 downto 0)
		);

end entity;

Architecture a_tristate of tristate is
begin
	out1<= in1 when choice = '1'
	else (others=>'Z');
	
end Architecture;
