Library ieee;
use ieee.std_logic_1164.all;

entity reg_file is
        port ( Rs_read_address : in std_logic_vector(2 downto 0);
            Rd_read_address : in std_logic_vector(2 downto 0);
            Rs_write_address : in std_logic_vector(2 downto 0);
            Rd_write_address : in std_logic_vector(2 downto 0);
            Write_back_data : in std_logic_vector(31 downto 0);
            Write_back_control_signal : in std_logic_vector(2 downto 0);
            In_port_data : in std_logic_vector(15 downto 0);
            In_port_control_signal : in std_logic;
            Clk : in std_logic;
            Reset : in std_logic;
            Rs_read_data : out std_logic_vector(15 downto 0);
            Rd_read_data : out std_logic_vector(15 downto 0)
    );
end entity reg_file;

Architecture a_reg_file of reg_file is 
    component sixten_bitReg is
        port( a : in std_logic_vector(15 downto 0);
            b : out std_logic_vector (15 downto 0);
            enable : in std_logic;
            reset : in std_logic;
            clck : in std_logic
        );
    end component;

    component tristate is
        generic(n:integer:=16);
            port( in1 : in std_logic_vector(n-1 downto 0);
                choice : in std_logic;
                out1 : out std_logic_vector(n-1 downto 0)
                );
         end component;

    component decoder is 
         port( in1 : in std_logic_vector(2 downto 0);
             enable : in std_logic;
             out1 : out std_logic_vector(7 downto 0)
             );
     end component;
    -- eight regesters with 16-bits size each
    type reg_buffer is array (0 to 7) of std_logic_vector(15 downto 0);
    signal input_R,output_R : reg_buffer;
    -- the two decoders which take the RS_read_address and same for Rd and then select which reg will write  on Rs_data and Rd_data, hence they will control the tristate buffers connected to the databus(rs_data and rd_data)
    signal read_Rs_address_decoder_output , read_Rd_address_decoder_output : std_logic_vector(7 downto 0);
    -- the two decoders which take the RS_write_address and same for Rd and then select which reg will be written on, hence they will control the tristate buffers connected to the registers (rs and rd)
    signal write_Rs_address_decoder_output , write_Rd_address_decoder_output : std_logic_vector(7 downto 0);
    -- signal to control reading data only in the falling edge 
    signal read_Rs_enable , read_Rd_enable : std_logic;
    -- signal to disable writing on register even if rising edge, dueto the WB signal (i.e. Wb_control_signal = "000")
    signal write_Rs_enable  , write_Rd_enable_dueto_WB_control_signal , write_Rs_enable_dueto_WB_control_signal , write_Rd_enable: std_logic;
    -- get the or of the write_Rs_address_decoder_output & write_Rd_address_decoder_output to be as an input enable for each register, in case if we will write on the register as an Rs or as an Rd. NOTE that the register can be written on it onle in the first half cycle (check the 16-bits_reg)
    signal Rs_write_enable_OR_Rd_write_enable  : std_logic_vector(7 downto 0);
    -- two signals to separate rs input data and rd input data
    signal input_Rs , input_Rd  : std_logic_vector(15 downto 0);
    -- two choose wether to write on Rd_write_address or Rd_read_address, needed in case of in.port
    signal Rd_write_address_Rd_read_address : std_logic_vector(2 downto 0);
    -- signal to check if Rd_read_address = Rs_write_address, this will make a conflict during in.port and WB then i should make in.port be done regardless the data in input_Rs
    signal Rd_read_address_equal_Rs_write_address : std_logic_vector(2 downto 0);
begin
    --port mapping the 8 registers in reg file
    loop3:for i in 0 to 7 generate
        R : sixten_bitReg port map (input_R(i) , output_R(i) , Rs_write_enable_OR_Rd_write_enable(i),  Reset , Clk); 
    end generate loop3;
    -- decoders for selecting which register we will read data from
    read_Rs_address_decoder : decoder port map (Rs_read_address , read_Rs_enable , read_Rs_address_decoder_output);
    read_Rd_address_decoder : decoder port map (Rd_read_address , read_Rd_enable , read_Rd_address_decoder_output);
    -- decoders for selecting which register we will write data on
    write_Rs_address_decoder : decoder port map (Rs_write_address , write_Rs_enable , write_Rs_address_decoder_output);
    write_Rd_address_decoder : decoder port map (Rd_write_address_Rd_read_address , write_Rd_enable , write_Rd_address_decoder_output);
    -- using WB control signal to decide which operation will be done in writing
    with (Write_back_control_signal(1 downto 0)) select
    write_Rs_enable_dueto_WB_control_signal <= '0' when "00", --no writing will be done if WB control signal's first two bits equals 00
    '0' when "01", -- only write on rd
    '1' when others; -- otherwise write on rs and rd
    with (Write_back_control_signal(1 downto 0)) select
    write_Rd_enable_dueto_WB_control_signal <= '0' when "00",
    '1' when others;
    -- force the write enable to be 1 even if WB control signal is 00, in case of in.port
    with (In_port_control_signal) select 
    write_Rd_enable <= '1' when '1',
    write_Rd_enable_dueto_WB_control_signal when others;
    -- change the Rd write address to the read one in case of in.port
    with (In_port_control_signal) select
    Rd_write_address_Rd_read_address <= Rd_read_address when '1',
    Rd_write_address when others;
    -- checking if Rd_read_address = Rs_write_address
    Rd_read_address_equal_Rs_write_address <= Rd_read_address and (not Rs_write_address);
    with (Rd_read_address_equal_Rs_write_address) select
    write_Rs_enable <= '0' when "000",
    write_Rs_enable_dueto_WB_control_signal when others;

    -- after this operation for example if Wb control signal was 00 then the two decoders will be disabled thus thier outputs will be 00000000 and 00000000 and OR-ing them will lead to 00000000, hence the enable of all registers will be 0 (no writing)
    -- the value of the OR-ing 
    Rs_write_enable_OR_Rd_write_enable <= (write_Rs_address_decoder_output or write_Rd_address_decoder_output);
    -- eight tristate buffers connecting all regiters to rs data bus
    loop1:for i in 0 to 7 generate
        Rs_data_bus_tristate : tristate generic map (16) port map (output_R(i) , read_Rs_address_decoder_output(i) , Rs_read_data);
    end generate loop1;
    -- eight tristate buffers connecting all regiters to rd data bus
    loop2:for i in 0 to 7 generate
        Rd_data_bus_tristate : tristate generic map (16) port map (output_R(i) , read_Rd_address_decoder_output(i) , Rd_read_data);
    end generate loop2;
    -- prcoess (always block) to enable decocders which enable registers to write data on data bus (reading reg values) only in second half of clock
    process (Clk) is
    begin
        if Clk' event and Clk = '0' then read_Rs_enable <= '1';
        else read_Rs_enable <= '0';
        end if;
    end process;
    process (Clk) is 
    begin
        if Clk' event and Clk = '0' then read_Rd_enable <= '1';
        else read_Rd_enable <= '0';
        end if;
    end process;
    -- to choose which data will be written on rs and rd (write data or inport data ??)
    input_Rs <= Write_back_data(31 downto 16);
    with (In_port_control_signal) select
    input_Rd <= In_port_data when '1',
    Write_back_data(15 downto 0) when others;
    -- 16 tristate buffers, 8 for rs_input and 8 for rd input, to choose which register will take the rs_input and which will take the rd_input
    loop4:for i in 0 to 7 generate
        Rs_input_bus_tristate : tristate generic map (16) port map (input_Rs , write_Rs_address_decoder_output(i) , input_R(i));
    end generate loop4;
    loop5: for i in 0 to 7 generate
        Rd_input_bus_tristate : tristate generic map (16) port map (input_Rd , write_Rd_address_decoder_output(i) , input_R(i));
    end generate loop5;
end architecture;