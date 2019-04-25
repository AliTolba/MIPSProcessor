Library ieee;
use ieee.std_logic_1164.all;
USE IEEE.numeric_std.all;


Entity ProcessorI9 is
PORT(
Clk,Reset,Intr: IN std_logic; 
InPort: In std_logic_vector(15 downto 0);
OutPort: Out std_logic_vector(15 downto 0));
end entity;


Architecture myProcessorI9 of ProcessorI9 is


--Declaration of components
component Reg is 
generic(n: integer:=16);
PORT(
d:IN std_logic_vector(n-1 downto 0);
clk,rst,enable: IN std_logic; 
q: out std_logic_vector(n-1 downto 0));
end component;

component OneBitReg is
PORT(
d:IN std_logic;
clk,rst,enable: IN std_logic; 
q: out std_logic);
end component;

component SPReg is
PORT(
d:IN std_logic_vector(31 downto 0);
clk,rst,enable: IN std_logic; 
q: out std_logic_vector(31 downto 0));
end component;

component InstructionDataMemory IS
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
END component;

component ForwardingUnit is
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
END component;

component LoadUseDetectionUnit is
	PORT(
		RsDSig: IN  std_logic_vector(2 DOWNTO 0); --S4
		RdDsig: IN std_logic_vector (2 downto 0); --S5
		RdEsig: IN std_logic_vector (2 downto 0); --S20
		MemWriteESig: In std_logic; --S14
		FDBufferEnable: out std_logic); --S7
END component;

component BranchControlUnit is
	PORT(
		OpCodeExecuteSig: IN  std_logic_vector(4 DOWNTO 0); --S12
		FlagRegisterSig: IN std_logic_vector (2 downto 0); --S26
		BranchControlOutSig: out std_logic); --S25
END component;

--Start of Signals---

--Reset Signals --Used in flushing

signal ResetOpCodeFDSig: std_logic; --S23 --Clear the op code only becuase it has special case with the interupt
signal ResetControlSignalsDESig: std_logic; --S60 --Clear the exec,mem and write back registers in speacial way code only becuase it has special case with the interupt


--Input and Output Ports
signal InPortData: std_logic_vector(15 downto 0); --S63
signal OutPortData: std_logic_vector(15 downto 0); --S64

signal InPortControl: std_logic; --S65


--Fetch Signals

signal PCMuxSig : std_logic_vector(31 downto 0);		--S0
signal PCValSig : std_logic_vector(31 downto 0);		--S1
signal MemoryOutDataSig : std_logic_vector(31 downto 0); --S2  The Signal that carries the data out of the Instructions and Data Memory

signal InteruptSig: std_logic; --S44
signal OpCodeMuxOutSig: std_logic_vector(4 downto 0); --S45
signal PCControlOutSig: std_logic_vector(31 downto 0); --S46
signal NewPcValSig: std_logic_vector(31 downto 0);	--S47

signal MemAddressSig: std_logic_vector(31 downto 0);  --S66


--Decode Signals
signal OpCodeDSig : std_logic_vector(4 downto 0); --S3
signal RsDSig : std_logic_vector(2 downto 0);	  --S4
signal RdDSig : std_logic_vector(2 downto 0);	  --S5
signal ImmEaDSig : std_logic_vector(19 downto 0);  --S6
signal EnableFDSig: std_logic;			  --S7
signal CUoutSig:std_logic_vector(11 downto 0); --Output of the control unit S8
signal CUMuxSig:std_logic_vector(11 downto 0); --Actual control signal to be written on the registers S9
signal RsDataSig:std_logic_vector(15 downto 0); --S10
signal RdDataSig:std_logic_vector(15 downto 0);  --S11
signal ControlMuxSelectSig: std_logic;  --S22
signal PCValDSig : std_logic_vector(31 downto 0);		--S24
signal InteruptDSig: std_logic; --S48

--Execute Signals
signal OpCodeESig : std_logic_vector(4 downto 0); --S12
signal ExecControlEsig: std_logic_vector(2 downto 0); --S13
signal MemControlEsig: std_logic_vector(3 downto 0); --S14
signal WBControlEsig: std_logic_vector(4 downto 0); --S15
signal RsDataESig: std_logic_vector(15 downto 0);   --S16
signal RdDataESig: std_logic_vector(15 downto 0);    --S17
signal ImmEaESig : std_logic_vector(19 downto 0);  --S18
signal PCValEsig: std_logic_vector(31 downto 0);    --S19
signal RsEsig: std_logic_vector(2 downto 0);	   --S20
signal RdEsig: std_logic_vector(2 downto 0);	  --S21


signal ForwardOp1sig: std_logic_vector(2 downto 0); --S32   --Selectors for ALU OP1
signal ForwardOp2sig: std_logic_vector(2 downto 0); --S33   --Selectors for ALU OP2
signal AluOp1sig: std_logic_vector(15 downto 0); --S34
signal AluOp2sig: std_logic_vector(15 downto 0); --S35
signal AluOutsig: std_logic_vector(31 downto 0); --S36
signal AluFlagsOut:std_logic_vector(2 downto 0); --S37


signal BranchEnableSig: std_logic; --S25
signal FlagsValSig: std_logic_vector(2 downto 0); --S26

signal InteruptESig: std_logic; --S49

signal BranchForFlushSig: std_logic; --S61

--Memory Signals
signal Result1MSig: std_logic_vector(15 downto 0); --S27
signal Result2MSig: std_logic_vector(15 downto 0); --S28
signal RsMSig: std_logic_vector(2 downto 0); --S29
signal RdMSig: std_logic_vector(2 downto 0); --S30
signal MultMsig: std_logic; --S31
signal MemControlMsig: std_logic_vector(3 downto 0); --S38 
signal WBControlMSig: std_logic_vector(4 downto 0); --S39
signal ImmEaMSig : std_logic_vector(19 downto 0);  --S40 
signal SPinMsig: std_logic_vector(31 downto 0); --S41
signal SPoutMsig: std_logic_vector(31 downto 0); --S42
signal PCValMsig: std_logic_vector(31 downto 0);   --S43
signal InteruptMSig: std_logic; --S50
signal LoadedDataMuxSig: std_logic_vector(15 downto 0); --S51
signal MemDatainSig: std_logic_vector(31 downto 0);  --S67



--Write Back Signals
signal Result1WBSig: std_logic_vector(15 downto 0); --S52
signal LoadedDataOutsig: std_logic_vector(15 downto 0); --S53
signal WBControlWBSig: std_logic_vector(4 downto 0); --S54
signal Result2WBSig: std_logic_vector(15 downto 0); --S55
signal RsWBSig: std_logic_vector(2 downto 0); --S56
signal RdWBSig: std_logic_vector(2 downto 0); --S57
signal MultWBSig: std_logic; --S58
signal WriteBackDataSig:std_logic_vector(31 downto 0); --S59
signal Result1DataWBsig:std_logic_vector(15 downto 0); --S62


--End of Signals

begin 
--Registers declaration
--General Registers
PCReg: Reg generic map(32) port map(PCMuxSig,Clk,Reset,EnableFDSig,PCValSig);

--Assigning Signals 
InteruptSig<=Intr;
InPortData<=InPort;
OutPort<=OutPortData;
BranchForFlushSig<=ExecControlEsig(0) and BranchEnableSig;

--Assigning Reset Signals
ResetOpCodeFDSig <= ((BranchForFlushSig or MemControlMsig(3) or MemControlMsig(2) or WBControlMSig(2)) and not(InteruptSig)) or Reset;
ResetControlSignalsDESig<= ((WBControlMSig(2) or InteruptMSig)and not(InteruptESig)) or Reset;
--F/D Registers

--MemoryOutDataSig(4 downto 0)
OPCodeFDReg: Reg generic map(5) port map(OpCodeMuxOutSig,Clk,ResetOpCodeFDSig,EnableFDSig,OpCodeDSig);
RsFDReg: Reg generic map(3) port map(MemoryOutDataSig(7 downto 5),Clk,Reset,EnableFDSig,RsDSig);
RdFDReg: Reg generic map(3) port map(MemoryOutDataSig(10 downto 8),Clk,Reset,EnableFDSig,RdDSig);
ImmEaFDReg: Reg generic map(20) port map(MemoryOutDataSig(30 downto 11),Clk,Reset,EnableFDSig,ImmEaDSig);
PCFDReg: Reg generic map(32) port map(PCValSig,Clk,Reset,EnableFDSig,PCValDSig);
IntFDReg:OneBitReg port map(InteruptSig,Clk,Reset,'1',InteruptDSig);



--D/E Registers
OPCodeDEReg: Reg generic map(5) port map(OpCodeDSig,Clk,ResetControlSignalsDESig,'1',OpCodeESig);
RsDEReg: Reg generic map(3) port map(RsDSig,Clk,Reset,'1',RsESig);
RdDEReg: Reg generic map(3) port map(RdDSig,Clk,Reset,'1',RdESig);
ExceControlDEReg: Reg generic map(3) port map(CUMuxSig(11 downto 8),Clk,ResetControlSignalsDESig,'1',ExecControlEsig);
MemControlDEReg: Reg generic map(4) port map(CUMuxSig(7 downto 4),Clk,ResetControlSignalsDESig,'1',MemControlEsig);
WBControlDEReg: Reg generic map(5) port map(CUMuxSig(3 downto 0),Clk,ResetControlSignalsDESig,'1',WBControlEsig);
RsDataDEReg: Reg generic map(16) port map(RsDataSig,Clk,Reset,'1',RsDataESig);
RdDataDEReg: Reg generic map(16) port map(RdDataSig,Clk,Reset,'1',RdDataESig);
ImmEaDEReg: Reg generic map(20) port map(ImmEaDSig,Clk,Reset,'1',ImmEaEsig);
PCDEReg: Reg generic map(32) port map(PCValDSig,Clk,Reset,'1',PCValEsig);
IntDEReg:OneBitReg port map(InteruptDSig,Clk,Reset,'1',InteruptESig);

--E/M Regsiters 
FlagsReg: Reg generic map(3) port map(AluFlagsOut,Clk,Reset,ExecControlEsig(1),FlagsValSig);		--Enable will be edited later 
Result1EMReg:Reg generic map(16) port map(AluOutsig(15 downto 0),Clk,Reset,'1',Result1MSig);
Result2EMReg:Reg generic map(16) port map(AluOutsig(31 downto 16),Clk,Reset,'1',Result2MSig);
MemControlEMReg: Reg generic map(4) port map(MemControlEsig,Clk,Reset,'1',MemControlMsig);
WBControlEMReg: Reg generic map(5) port map(WBControlEsig,Clk,Reset,'1',WBControlMSig);
StackPointerReg:SPReg port map(SPoutMsig,Clk,Reset,'1',SPinMsig);
ImmEaEMReg: Reg generic map(20) port map(ImmEaEsig,Clk,Reset,'1',ImmEaMSig);
PCEMReg: Reg generic map(32) port map(PCValEsig,Clk,Reset,'1',PCValMsig);
RsEMReg: Reg generic map(3) port map(RsESig,Clk,Reset,'1',RsMSig);
RdEMReg: Reg generic map(3) port map(RdESig,Clk,Reset,'1',RdMSig);
MultiControlEMReg:OneBitReg port map(ExecControlEsig(2),Clk,Reset,'1',MultMsig);
IntEMReg:OneBitReg port map(InteruptESig,Clk,Reset,'1',InteruptMSig);

--M/WB Resgisters

Result1MWBReg:Reg generic map(16) port map(Result1MSig,Clk,Reset,'1',Result1WBSig);
Result2MWBReg:Reg generic map(16) port map(Result2MSig,Clk,Reset,'1',Result2WBSig);
WBControlMWBReg: Reg generic map(5) port map(WBControlMSig,Clk,Reset,'1',WBControlWBSig);
LoadedDataMWBREG:Reg generic map(16) port map(LoadedDataMuxSig(15 downto 0),Clk,Reset,'1',LoadedDataOutsig);
RsMWBReg: Reg generic map(3) port map(RsMSig,Clk,Reset,'1',RsWBSig);
RdMWBReg: Reg generic map(3) port map(RdMSig,Clk,Reset,'1',RdWBSig);
MultiControlMWBReg:OneBitReg port map(MultMsig,Clk,Reset,'1',MultWBSig);

--Fetch Stage Components
PCMuxSig<=NewPcValSig when BranchForFlushSig='0' and WBControlMSig(1)='0' and InteruptMSig='0' and reset='0'
else x"0000" & AluOp1sig when BranchForFlushSig='1' and WBControlMSig(1)='0' and InteruptMSig='0' and reset='0'
else MemoryOutDataSig when WBControlMSig(1)='1' or InteruptMSig='1' or reset='1'
else x"00000000";

OpCodeMuxOutSig<=MemoryOutDataSig(4 downto 0) when Intr='0'
else "11100";

--Decode Stage Components
CUMuxSig<= CUoutSig when ControlMuxSelectSig='0' 
else x"000";

LoadDetection: LoadUseDetectionUnit port map(RsDSig,RdDSig,RsEsig,MemControlEsig(2),EnableFDSig);

--Execute Stage Components
AluOp1sig<=RsDataESig when ForwardOp1sig="000" 
else Result1MSig when ForwardOp1sig="001"
else Result2MSig when ForwardOp1sig="010"
else Result1WBSig when ForwardOp1sig="011"
else Result2WBSig;

AluOp2sig<=RsDataESig when ForwardOp2sig="000" 
else Result1MSig when ForwardOp2sig="001"
else Result2MSig when ForwardOp2sig="010"
else Result1WBSig when ForwardOp2sig="011"
else Result2WBSig;

ForwadingUnitControl: ForwardingUnit port map(MultMsig,MultWBSig,RsEsig,RdEsig,RsMSig,RdMSig,RsWBSig,RdWBSig,WBControlMSig,WBControlWBSig,ForwardOp1sig,ForwardOp2sig);

BranchControl: BranchControlUnit port map(OpCodeESig,FlagsValSig,BranchEnableSig);

--Memroy Stage Components
Memory: InstructionDataMemory port map(clk,reset,InteruptMSig,MemAddressSig,MemDatainSig,MemoryOutDataSig,SPinMsig,SPoutMsig,MemControlMsig);

MemAddressSig<= PCValSig when MemControlMsig(3)='0' and MemControlMsig(2)='0'
else x"000" & ImmEaMSig;

MemDatainSig<= x"0000"& Result1MSig when MemControlMsig(1)='0'
else PCValMsig;

LoadedDataMuxSig<=MemoryOutDataSig(15 downto 0) when MemControlMsig(3)='1'
else ImmEaMSig(15 downto 0);

--WB Stage Components
Result1DataWBsig<=LoadedDataOutsig when WBControlWBSig(2)='0'
else Result1WBSig;

WriteBackDataSig<= Result1DataWBsig & Result2WBSig;

OutPort<= Result1DataWBsig when WBControlWBSig(0)='1' 
else (others=>'0');


end architecture;