Library ieee;
use ieee.std_logic_1164.all;

entity decoder is 
	port( in1 : in std_logic_vector(2 downto 0);
		enable : in std_logic;
		out1 : out std_logic_vector(7 downto 0)
		);
end entity;

Architecture a_decoder of decoder is
	signal concatination : std_logic_vector(3 downto 0);
begin
	concatination <= (enable & in1 );
	with (concatination) select
		out1<= "00000001" when "1000", 
			"00000010" when "1001",
			"00000100" when "1010",
            "00001000" when "1011",
            "00010000" when "1100",
            "00100000" when "1101",
            "01000000" when "1110",
            "10000000" when "1111",
			"00000000" when others;
end Architecture;