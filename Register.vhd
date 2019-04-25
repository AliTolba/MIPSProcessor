Library ieee;
use ieee.std_logic_1164.all;

Entity Reg 
is generic(n: integer:=16);
PORT(
d:IN std_logic_vector(n-1 downto 0);
clk,rst,enable: IN std_logic; 
q: out std_logic_vector(n-1 downto 0));
end entity;

Architecture myReg of Reg is begin

Process(clk,rst,enable) begin
if rst='1' then 
q<=(others=>'0');
elsif rising_edge(clk) and enable='1' then
q<=d;
end if;
end process;

end Architecture;