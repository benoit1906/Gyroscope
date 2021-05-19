library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
USE ieee.math_real.ALL;
 use ieee.std_logic_arith.all;

	ENTITY Bloc IS
		port(
			CLOCK_50 : in std_logic;
			 rst_n : in std_logic;
		   REG1 : out std_logic_vector(15 downto 0);
		   REG2 : out std_logic_vector(15 downto 0);
		   REG3 : out std_logic_vector(15 downto 0);
		   REG_out : out std_logic_vector(7 downto 0);
		   CL : inout std_logic;
		   SDA : inout std_logic
			);

	END ENTITY;


	ARCHITECTURE RTL OF Bloc IS

	constant INPUT_CLK_KHZ 			: integer := 50;
	constant BUS_CLK_MHZ 			: integer := 400;
	constant INPUT_CLK_MULTIPLIER : integer := 100;
	constant BUS_CLK_MULTIPLIER 	: integer := 1;
	constant DATA_WITH	: integer := 8;

									--latch in command
	signal i2c_m_ena			: std_logic:= '0';
									--address of target slave
	signal i2c_m_addr_wr		: std_logic_vector(7 downto 0):= (others=> '0');
									--'0' is write, '1' is read
	signal i2c_m_rw			: std_logic:= '1'; -- we only read
									--data to write to slave
	signal i2c_m_data_wr		: std_logic_vector(7 downto 0):= (others=> '0');
									--ready send the register
	signal i2c_m_reg_rdy				: std_logic :='0';
									--ready send value of the register
	signal i2c_m_val_rdy				: std_logic :='0';
									--indicates transaction in progress
	signal i2c_m_busy			: std_logic :='0';
									--data read from slave
	signal i2c_m_data_rd		: std_logic_vector(7 downto 0):= (others => '0');
									--flag if improper acknowledge from slave
	signal ack_error			: std_logic:= '0';

	-- I2C SLAVE RX

	constant WR 		         : std_logic:='0';
								-- L3GD20 device address (address bit = 1)
	constant DEVICE		       : std_logic_vector(6 downto 0):= "1101011";
								-- address of the register to write 0x20 CTRL_REG1
	constant CTRL_REG1_ADDR  : std_logic_vector(7 downto 0):= "00100000";
	                                                        -- data to write for test (no signification)
	constant CTRL_REG1_VAL   : std_logic_vector(7 downto 0):= "01001111";
                                                                -- addresse registre a lire
	constant OUT_X_L_ADDR    : std_logic_vector(7 downto 0):= "00101000";

        -- valeurs des accelerations lues low byte et high byte
	signal out_x_l_val : std_logic_vector(7 downto 0) := (others => '0');
	signal out_x_h_val : std_logic_vector(7 downto 0) := (others => '0');
	signal out_y_l_val : std_logic_vector(7 downto 0) := (others => '0');
	signal out_y_h_val : std_logic_vector(7 downto 0) := (others => '0');
	signal out_z_l_val : std_logic_vector(7 downto 0) := (others => '0');
	signal out_z_h_val : std_logic_vector(7 downto 0) := (others => '0');


	signal i2c_s_rx_data			: std_logic_vector(7 downto 0);
	signal i2c_s_rx_data_rdy	: std_logic;

	-- Build an enumerated type for the state machine
	type state_type is (s0, s1, s2, s3, s4, s5,s5bis ,  s6, s6bis,s7, s7bis,s8,s8bis, s9, s9bis, s10, s10bis, s11,s11bis);
	-- Register to hold the current state
	signal state : state_type;

	signal data_error: boolean := false;

	component I2C_M is
		generic (
										--input clock speed from user logic in KHz
			 input_clk				: integer := INPUT_CLK_KHZ;
										--speed the I2C_M bus (scl) will run at in MHz
			 bus_clk					: integer := BUS_CLK_MHZ;
										--input clock speed from user logic in KHz
			 input_clk_multiplier: integer := INPUT_CLK_MULTIPLIER;
			 bus_clk_multiplier	: integer := BUS_CLK_MULTIPLIER
		);
		 port(
			 clk       : in     std_logic;                    --system clock
			 reset_n   : in     std_logic;                    --active low reset
			 ena       : in     std_logic;                    --latch in command
			 addr      : in     std_logic_vector(7 downto 0); --address of target slave
			 rw        : in     std_logic;                    --'0' is write, '1' is read
			 data_wr   : in     std_logic_vector(7 downto 0); --data to write to slave
			 reg_rdy	 : out	  std_logic :='0';				  --ready send the register
			 val_rdy	 : out	  std_logic :='0';				  --ready send value of the register
			 busy      : out    std_logic :='0';              --indicates transaction in progress
			 data_rd   : out    std_logic_vector(7 downto 0); --data read from slave
			 ack_error : out 	  std_logic;                    --flag if improper acknowledge from slave
			 sda       : inout  std_logic;                    --serial data output of I2C_M bus
			 --sda       : buffer  std_logic;                    --serial data output of I2C_M bus
			 --scl       : inout  std_logic  --serial clock output of I2C_M bus
			 scl       : inout  std_logic  --serial clock output of I2C_M bus
		);
	end component;

	BEGIN

	UUT : I2C_M
	port map (
		clk 		  	=> CLOCK_50,
		reset_n 		=> rst_n,
		ena 			  => i2c_m_ena,
		addr 			  => i2c_m_addr_wr,
		rw 			    => i2c_m_rw,
		data_wr 		=> i2c_m_data_wr,
		reg_rdy 		=> i2c_m_reg_rdy,
		val_rdy 		=> i2c_m_val_rdy,
		busy 			  => i2c_m_busy,
		data_rd 		=> i2c_m_data_rd,
		ack_error 	=> ack_error,
		sda 			  => SDA,
		scl 			  => CL
	);





	P_i2c_m_write : process(rst_n,CLOCK_50)
	variable data_wr: natural range 0 to 2**DATA_WITH-1;
	begin
		if rst_n = '0' then
			data_error <= false;
			data_wr := 0;
			i2c_m_addr_wr	<= (others => '1');
			i2c_m_data_wr <= (others => '1');
			i2c_m_ena <= '0';
			i2c_m_rw <= '0';
		elsif rising_edge(CLOCK_50) then
			case state is

				when s0 =>
					if i2c_m_busy = '0' then
						state <= s1;
						i2c_m_addr_wr <= DEVICE & '0';   -- command word device adresse + WE (W=0)
						i2c_m_rw <= '0';                 -- demande a la state machine de faire une ecriture
						i2c_m_data_wr <= CTRL_REG1_ADDR; -- adresse du registre dans lequel on veut ecrire
					end if;

				when s1 =>   -- envoi du premier byte de commande
					i2c_m_ena <= '1';
					if i2c_m_reg_rdy = '1' then
						state <= s2;
						i2c_m_data_wr <= CTRL_REG1_VAL; -- valeur a ecrire dans CTRL_REG_1 (mode normal)
					end if;

				when s2 =>   -- envoi de l'adresse du registre
					if i2c_m_val_rdy = '1' then
						i2c_m_ena <= '0';   -- prochain byte fin de transaction
						state <= s3;
					end if;

				when s3 => -- quand busy passe a 0 la transaction en ecriture est terminee
					if i2c_m_busy = '0' then
						state <= s4;      -- on va lancer une operation de lecture
                              -- d'abord ecrire l adresse du registre a partir duquel on veut lire
						i2c_m_addr_wr <= DEVICE & '0';
						i2c_m_rw <= '0';
						--data to be written: addresse du registre a lire
						i2c_m_data_wr <= OUT_X_L_ADDR;
					end if;

				when s4 =>
					i2c_m_ena <= '1';
					if i2c_m_reg_rdy = '1' then
						state <= s5;
            i2c_m_addr_wr <= DEVICE & '1'; -- commande de lecture reele
						i2c_m_rw <= '1';	             -- pour generer le repeated start � la fin du byte suivant
					end if;

				when s5 => -- on est occupe a envoyer la commande de lecture
					if i2c_m_val_rdy = '1' then
                                                --i2c_m_data_wr <= OUT_X_L_ADDR;
					state <= s5bis;
					end if;

				when s5bis => -- on est occupe a envoyer la commande de lecture
					if i2c_m_val_rdy = '0' then
                                                --i2c_m_data_wr <= OUT_X_L_ADDR;
						state <= s6;
					end if;

        when s6 => -- lecture du premier byte X-L
					if i2c_m_val_rdy = '1' then
             state <= s6bis;
        end if;

        when s6bis => -- fin de lecture du premier byte
					if i2c_m_val_rdy = '0' then
					out_x_l_val <= i2c_m_data_rd; -- sauvegarde premiere valeur lue
					
            state <= s7;
          end if;

        when s7 => -- lecture du deuxieme byte
					if i2c_m_val_rdy = '1' then
             state <= s7bis;
         end if;

				when s7bis => -- fin lecture du deuxieme byte
					if i2c_m_val_rdy = '0' then
						out_x_h_val <= i2c_m_data_rd;
						REG1(15 downto 8) <= i2c_m_data_rd;
						REG1(7 downto 0) <=  out_x_l_val;				
            state <= s8;
          end if;

        when s8 => -- lecture du troisieme byte
					if i2c_m_val_rdy  = '1' then
             state <= s8bis;
          end if;

				when s8bis => --fin  lecture du troisieme byte
					if i2c_m_val_rdy = '0' then
             out_y_l_val <= i2c_m_data_rd;
             state <= s9;
          end if;

         when s9 => -- lecture du quatrieme byte
					if i2c_m_val_rdy  = '1' then
             state <= s9bis;
          end if;

          when s9bis => -- fin lecture du quatrieme byte
					if i2c_m_val_rdy  = '0' then
             out_y_h_val <= i2c_m_data_rd;
						REG2(15 downto 8) <= i2c_m_data_rd;
						REG2(7 downto 0) <=  out_y_l_val;	
             state <= s10;
           end if;

          when s10 => -- lecture du cinquieme byte
					if i2c_m_val_rdy  = '1' then
             state <= s10bis;
          end if;

          when s10bis => -- fin lecture du cinquieme byte
					if i2c_m_val_rdy  = '0' then
             out_z_l_val <= i2c_m_data_rd;
             i2c_m_ena <= '0'; -- generer un stop bit le byte suivant
             state <= s11;
          end if;

          when s11 => -- lecture du sixieme byte
					if i2c_m_val_rdy = '1' then
             state <= s11bis;
          end if;

          when s11bis => -- fin lecture du sixieme byte
					if i2c_m_val_rdy  = '0' then
            out_z_h_val <= i2c_m_data_rd;
						REG3(15 downto 8) <= i2c_m_data_rd;
						REG3(7 downto 0) <=  out_z_l_val;	
            state <= s0;
          end if;

				when OTHERS =>
					state <= s0;
			end case;
		end if;
	end process;



--	process(rst_n,CLOCK_50)
--	begin
--	REG_out <= VALRD;
--	end process;


	END ARCHITECTURE RTL;
