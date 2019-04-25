LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;

ENTITY InstructionDataMemory IS
	PORT(
		clk : IN std_logic;
		reset: IN std_logic;
		Interupt: IN std_logic;
		address : IN  std_logic_vector(31 DOWNTO 0);
		datain  : IN  std_logic_vector(31 DOWNTO 0);
		dataout : OUT std_logic_vector(31 DOWNTO 0);
		spIN:  IN  std_logic_vector(31 DOWNTO 0);
		spOut: Out  std_logic_vector(31 DOWNTO 0);
		MemoryControl: IN std_logic_vector (3 downto 0));
END ENTITY InstructionDataMemory;

ARCHITECTURE myInstructionDataMemory OF InstructionDataMemory IS

	TYPE ram_type IS ARRAY(0 TO (2**20)-1) OF std_logic_vector(15 DOWNTO 0);
	SIGNAL ram : ram_type ;
	Signal newSP: std_logic_vector(31 DOWNTO 0);
	
	BEGIN
		PROCESS(clk) IS
			BEGIN
				IF rising_edge(clk) and reset='0' THEN 
					IF Interupt='1' then				--Interupt
						ram(to_integer(unsigned(spIN))) <= datain(15 downto 0);
						ram(to_integer(unsigned(spIN))-1) <= datain(31 downto 16);
						
					ELSIF MemoryControl = "0100" THEN 	--Normal Store
						ram(to_integer(unsigned(address))) <= datain(15 downto 0);
					ELSIF MemoryControl="0101"  THEN	--Push
						ram(to_integer(unsigned(spIN))) <= datain(15 downto 0);
					ELSIF MemoryControl="0111"  THEN	--Call
						ram(to_integer(unsigned(spIN))) <= newSP(15 downto 0);
						ram(to_integer(unsigned(spIN)-1)) <= newSP(31 downto 16);
					END IF;
					
				END IF;
		END PROCESS;
	dataout <= ram(0) & ram(1) when reset='1'	--Reset
	else x"0000" & ram(to_integer(unsigned(address))) when MemoryControl="1000" 		--Load
	else x"0000" & ram(to_integer(unsigned(SPIN)+1)) when MemoryControl="1001"	--Pop
	else ram(to_integer(unsigned(SPIN)+1)) & ram(to_integer(unsigned(SPIN)+2)) when MemoryControl="1011"	--RET/RETI
	else ram(2) & ram (3) when Interupt='1'	--INT
	else ram(to_integer(unsigned(address)))& ram(to_integer(unsigned(address)+1));			--Instruction out
	
	spout<= SPIN when reset='1'
	else std_logic_vector(unsigned(spIN)-2) when Interupt='1' or MemoryControl="0111"	--Interupt
	else std_logic_vector(unsigned(spIN)-1) when MemoryControl="0101"	--Push
	else std_logic_vector(unsigned(SPIN)+1) when MemoryControl="1001" --Pop
	else std_logic_vector(unsigned(SPIN)+2) when MemoryControl="1011" --RET/RETI
	else SpIN;	--For all other cases

	newSP<=std_logic_vector(unsigned(datain)+1);
END myInstructionDataMemory;

