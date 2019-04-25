Library ieee;
use ieee.std_logic_1164.all;

Entity SPReg is
PORT(
d:IN std_logic_vector(31 downto 0);
clk,rst,enable: IN std_logic; 
q: out std_logic_vector(31 downto 0));
end entity;

Architecture mySPReg of SPReg is begin

Process(clk,rst,enable) begin
if rst='1' then 
q<=x"000FFFFF";
elsif rising_edge(clk) and enable='1' then
q<=d;
end if;
end process;

end Architecture;
