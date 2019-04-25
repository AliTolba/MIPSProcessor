Library ieee;
use ieee.std_logic_1164.all;

Entity OneBitReg is
PORT(
d:IN std_logic;
clk,rst,enable: IN std_logic; 
q: out std_logic);
end entity;

Architecture myOneBitReg of OneBitReg is begin

Process(clk,rst,enable) begin
if rst='1' then 
q<='0';
elsif rising_edge(clk) and enable='1' then
q<=d;
end if;
end process;

end Architecture;
