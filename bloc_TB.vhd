
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
USE ieee.math_real.ALL;

entity bloc_TB is
end bloc_TB;

architecture behavior of bloc_TB is

	constant clk_period	: time := 10 ns;
	constant DATA_WITH	: integer := 8;

	-- IC2 MASTER
	constant INPUT_CLK_KHZ 	   : integer := 50;
	constant BUS_CLK_MHZ 	   : integer := 400;
	constant INPUT_CLK_MULTIPLIER : integer := 100; --100
	constant BUS_CLK_MULTIPLIER 	: integer := 1; --1

									--system clock
	signal clk_50		      : std_logic:= '0';
									--active low reset
	signal rst_n		      : std_logic:= '0';
        
	signal 	  REG1 :  std_logic_vector(15 downto 0);
	signal     REG2 :  std_logic_vector(15 downto 0);
   signal     REG3 :  std_logic_vector(15 downto 0);
	signal     REG_out : std_logic_vector(7 downto 0);
   signal     CL :  std_logic;
	signal     SDA :  std_logic;


component Bloc is
port(
			CLOCK_50 : in std_logic;
			 rst_n : in std_logic;
		   REG1 : out std_logic_vector(15 downto 0);
		   REG2 : out std_logic_vector(15 downto 0);
		   REG3 : out std_logic_vector(15 downto 0);
		   REG_out : out std_logic_vector(7 downto 0);
		   CL : out std_logic;
		   SDA : inout std_logic
			);
end component;

begin	

	P_CLK: process
	begin
		clk_50 <= '1';
		wait for clk_period/2;
		clk_50 <= '0';
		wait for clk_period/2;
	end process;

	P_RST_N: process
	begin
		rst_n <= '0';
		wait for clk_period*2;
		rst_n <= '1';
		wait;
	end process;


	UUT : Bloc
	port map ( 
	CLOCK_50 => clk_50,
		   rst_n => rst_n, 
		   REG1 => REG1 ,
		   REG2 => REG2 ,
		   REG3 => REG3,
		   REG_out => REG_out,
		   CL => CL, 
		   SDA => SDA);

end behavior;