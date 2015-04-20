			library IEEE;
			use IEEE.STD_LOGIC_1164.ALL;
			use IEEE.STD_LOGIC_unsigned.ALL;
			use IEEE.STD_LOGIC_arith.ALL;



		entity m is
		generic (n:integer range 1 to 11 := 11);
		  port(  clk:in std_logic;
				--MOTOR1
					HALL11:in std_logic;
					HALL21:in std_logic;
					HALL31:in std_logic;
					
					M1p1:out std_logic;
					M1n1:out std_logic;
					M2p1:out std_logic;
					M2n1:out std_logic;
					M3p1:out std_logic;
					M3n1:out std_logic;
					HALL_OUT:out std_logic;
					CLK_1MS:out std_logic;
					CHECK_OUT:out std_logic;
					
					HALL1_COUNT :in std_logic_vector(4 downto 0);
					HALL2_COUNT :in std_logic_vector(4 downto 0);
					HALL3_COUNT :in std_logic_vector(4 downto 0);
					HALL4_COUNT :in std_logic_vector(4 downto 0);
				
					--MOTOR2	
					HALL12:in std_logic;
					HALL22:in std_logic;
					HALL32:in std_logic;
					
					M1p2:out std_logic;
					M1n2:out std_logic;
					M2p2:out std_logic;
					M2n2:out std_logic;
					M3p2:out std_logic;
					M3n2:out std_logic;
					
			
				--MOTOR3	
					HALL13:in std_logic;
					HALL23:in std_logic;
					HALL33:in std_logic;
				
					M1p3:out std_logic;
					M1n3:out std_logic;
					M2p3:out std_logic;
					M2n3:out std_logic;
					M3p3:out std_logic;
					M3n3:out std_logic;
				
				
				--MOTOR4	
					HALL14:in std_logic;
					HALL24:in std_logic;
					HALL34:in std_logic;
					
					M1p4:out std_logic;
					M1n4:out std_logic;
					M2p4:out std_logic;
					M2n4:out std_logic;
					M3p4:out std_logic;
					M3n4:out std_logic;	
--			 
				 --FT245  	
					DATA_USB	 :	out std_logic_vector(7 downto 0);
					USB_WR 	 : out std_logic;	
					TXE		 : in  std_logic;	
		--		 micro_com
					RPM_IN    : in std_logic_vector(7 downto 0);
					CLK_PAR   : in std_logic;
					PARITY_IN : in std_logic;
					MOTOR_NUM : in std_logic_vector(1 downto 0);
				 --LED
					LED:out std_logic_vector(3 downto 0);
				--MEUNE
					TEST_KEY   : in std_logic_vector(3 downto 0)
					
					--M1: out std_logic_vector
					
					 );
		end m;

		architecture Behavioral of m is

		component drivermotor is
				port( 
					CLK:in std_logic;
					HALL1:in std_logic;
					HALL2:in std_logic;
					HALL3:in std_logic;
					M1p:out std_logic;
					M1n:out std_logic;
					M2p:out std_logic;
					M2n:out std_logic;
					M3p:out std_logic;
					M3n:out std_logic;
					CLK_1MS:out std_logic;
					HALL_OUT:out std_logic;
					CHECK_OUT:out std_logic;
					
		         ERR_M  :out std_logic_vector(15 downto 0);
			      kp_M   :in std_logic_vector(19 downto 0);	
					SPEED:in std_logic_vector(15 downto 0);
					M_show:out std_logic_vector(15 downto 0);
					--HALL_COUNT :in std_logic_vector(4 downto 0);
					LED:out std_logic_vector(3 downto 0);
					FREE_WHEEL : in std_logic ;
					--CLK_200    :in std_logic;
					--kp_in      : in std_logic_vector(15 downto 0);
					TEST_KEY   : in std_logic_vector(3 downto 2)
					
					 );
			
			end component;
			
			component  Write_to_USB is
				port (
						DATA1_IN   : in std_logic_vector(15 downto 0);
						--DATA2_IN   : in std_logic_vector(7 downto 0);
						DATA_USB	 :	out std_logic_vector(7 downto 0);
						USB_WR 	 : out std_logic;
						TXE		 : in  std_logic;
						CLK_USB   :	in  std_logic
						);
			 end component;
			 
			 component micro_com2 is
				port (
						CLK : in std_logic;
						RPM_IN : in std_logic_vector(7 downto 0);
						CLK_PAR : in std_logic;
						PARITY_IN : in std_logic;
						MOTOR_NUM : in std_logic_vector(1 downto 0);
						RPM1 : out std_logic_vector(15 downto 0);
						RPM2 : out std_logic_vector(15 downto 0);
						RPM3 : out std_logic_vector(15 downto 0);
						RPM4 : out std_logic_vector(15 downto 0);
						FREE_WHEELS : out std_logic 
						--LED  : out std_logic_vector(3 downto 0)
						);
				end component;
				
				component DIVIDER is
			port (
					clk: in std_logic;
					rfd: out std_logic;
					dividend: in std_logic_vector(31 downto 0);
					divisor: in std_logic_vector(15 downto 0);
					quotient: out std_logic_vector(31 downto 0);
					fractional: out std_logic_vector(15 downto 0)
				  );
			END COMPONENT; 
			
			 COMPONENT clk_200M
			PORT(
				CLKIN_IN : IN std_logic;
				RST_IN : IN std_logic;          
				CLKFX_OUT : OUT std_logic;
			--	CLKIN_IBUFG_OUT : OUT std_logic;
				CLK0_OUT : OUT std_logic
				);
			END COMPONENT;


			

			signal SPEED1 : std_logic_vector(15 downto 0):=(others=>'0'); --"1111111000001100";--;--"1111011000111100";--"0000111110100000";--(others=>'0'); 
			signal SPEED2 : std_logic_vector(15 downto 0):=(others=>'0'); --"0000111110100000";--
			signal SPEED3 : std_logic_vector(15 downto 0):=(others=>'0'); --"0001000110010100";----"0000001111100100"; 
			signal SPEED4 : std_logic_vector(15 downto 0):=(others=>'0'); --"1111110000011000";--
			
			signal MS_show: std_logic_vector(15 downto 0):=(others=>'0');
			signal M1_show: std_logic_vector(15 downto 0):=(others=>'0'); 
		   signal M2_show: std_logic_vector(15 downto 0):=(others=>'0'); 
			signal M3_show: std_logic_vector(15 downto 0):=(others=>'0'); 
			signal M4_show: std_logic_vector(15 downto 0):=(others=>'0'); 
			signal FREE_WHEELS_S: std_logic := '0'; 
			
			signal LED1: std_logic_vector(3 downto 0);
			signal LED2: std_logic_vector(3 downto 0);
			signal LED3: std_logic_vector(3 downto 0);
			signal LED4: std_logic_vector(3 downto 0); 
			
			signal CLK_280: std_logic;
			signal RST_IN         : std_logic:='0';
			signal CLKFX_OUT      : std_logic:='0';
			signal CLK0_OUT       : std_logic:='0';
		
			
			 signal dividend1   : std_logic_vector(31 downto 0):= "00000000001000010011110000000000";--(others=>'0');
			 signal divisor1    : std_logic_vector(15 downto 0):=(others=>'0');
			 signal quotient1   : std_logic_vector(31 downto 0):=(others=>'0');	 
			 signal fractional1 : std_logic_vector(15 downto 0):=(others=>'0');
			 signal rfd1        : std_logic:='0';
			 
			 signal time_count:  std_logic_vector(15 downto 0):="0000000000000000";
	
			constant T_20ns :  std_logic_vector(15 downto 0):="0000000000000001";
			constant T_200ns:  std_logic_vector(15 downto 0):="0000000000001010";
			constant T_400ns:  std_logic_vector(15 downto 0):="0000000000010100";
			constant T_600ns:  std_logic_vector(15 downto 0):="0000000000011110";
			constant T_800ns:  std_logic_vector(15 downto 0):="0000000000101000";
   

			signal ERR_M1   : std_logic_vector(15 downto 0):=(others=>'0');
			signal  kp_M1   : std_logic_vector(19 downto 0):=(others=>'0');	
			signal ERR_M2   : std_logic_vector(15 downto 0):=(others=>'0');
			signal  kp_M2   : std_logic_vector(19 downto 0):=(others=>'0');
			signal ERR_M3   : std_logic_vector(15 downto 0):=(others=>'0');
			signal  kp_M3   : std_logic_vector(19 downto 0):=(others=>'0');
			signal ERR_M4   : std_logic_vector(15 downto 0):=(others=>'0');
			signal  kp_M4   : std_logic_vector(19 downto 0):=(others=>'0');

		begin
		
		
		
		 
			--M1		
				driver1:drivermotor port map(HALL1=>HALL11,HALL2=>HALL21,HALL3=>HALL31,CLK=>CLK,hall_OUT=>hall_OUT,CHECK_OUT=> CHECK_OUT,
				M1P=>M1P1,M1N=>M1N1,M2P=>M2P1,M2N=>M2N1,M3P=>M3P1,M3N=>M3N1,SPEED=>SPEED1,FREE_WHEEL => FREE_WHEELS_S,TEST_KEY => TEST_KEY(3 downto 2),ERR_M=>ERR_M1,kp_M=>kp_M1 , CLK_1MS=>CLK_1MS,M_show=>M1_show, LED=>LED1);--, kp_in => speed2);
			--M2	
				driver2:drivermotor port map(HALL1=>HALL12,HALL2=>HALL22,HALL3=>HALL32,CLK=>CLK,-- kp_in => speed2,
				M1P=>M1P2,M1N=>M1N2,M2P=>M2P2,M2N=>M2N2,M3P=>M3P2,M3N=>M3N2,SPEED=>SPEED2,FREE_WHEEL => FREE_WHEELS_S,ERR_M=>ERR_M2,kp_M=>kp_M2,TEST_KEY => TEST_KEY(3 downto 2),M_show=>M2_show, LED=>LED2);	
			--M3	
				driver3:drivermotor port map(HALL1=>HALL13,HALL2=>HALL23,HALL3=>HALL33,CLK=>CLK,-- kp_in => speed2,
				M1P=>M1P3,M1N=>M1N3,M2P=>M2P3,M2N=>M2N3,M3P=>M3P3,M3N=>M3N3,SPEED=>SPEED3,FREE_WHEEL => FREE_WHEELS_S,ERR_M=>ERR_M3,kp_M=>kp_M3,TEST_KEY => TEST_KEY(3 downto 2),M_show=>M3_show, LED=>LED3);
			--M4	
				driver4:drivermotor port map(HALL1=>HALL14,HALL2=>HALL24,HALL3=>HALL34,CLK=>CLK, --kp_in => speed2,
				M1P=>M1P4,M1N=>M1N4,M2P=>M2P4,M2N=>M2N4,M3P=>M3P4,M3N=>M3N4,SPEED=>SPEED4,FREE_WHEEL => FREE_WHEELS_S,ERR_M=>ERR_M4,kp_M=>kp_M4,TEST_KEY => TEST_KEY(3 downto 2),M_show=>M4_show, LED=>LED4);

		--	--FT245
			  FT245:Write_to_USB port map(DATA1_IN =>MS_SHOW,DATA_USB=>DATA_USB,USB_WR=>USB_WR,TXE=>TXE,CLK_USB=>CLK);		 

			--micro_com2
			  prl_com:micro_com2 port map(CLK=>CLK,RPM_IN=>RPM_IN,CLK_PAR=>CLK_PAR,PARITY_IN=>PARITY_IN,MOTOR_NUM=>MOTOR_NUM,FREE_WHEELS => FREE_WHEELS_S,
				 RPM1(15 downto 0)=>SPEED1,
				 RPM2(15 downto 0)=>SPEED2,
				 RPM3(15 downto 0)=>SPEED3,
				 RPM4(15 downto 0)=>SPEED4
				);
				
--				
--		 --DIVIDER
--			 DIVIDER1:DIVIDER port map (clk => clk_280,rfd => rfd1,dividend => dividend1,divisor => divisor1,quotient => quotient1,fractional => fractional1);
--		 
--			
--			
--		--CLK_200M
--			Inst_clk_200M: clk_200M port map(CLKIN_IN =>clk ,RST_IN => RST_IN ,CLKFX_OUT =>CLKFX_OUT ,CLK0_OUT =>CLK0_OUT  );
--		
--		
--
-- 
-- TIMER:			process(clk)  
--					begin	
--					if rising_edge (clk) then 
--					TIME_COUNT <=  TIME_COUNT+'1';
--					if(TIME_COUNT = T_20ns) then
--					
--					divisor1  <=  ERR_M1;
--					
--					elsif(TIME_COUNT = T_200ns) then
--					kp_M1 <= quotient1(19 downto 0); 
--					divisor1  <=  ERR_M2;
--					
--					elsif(TIME_COUNT = T_400ns) then
--					kp_M2 <= quotient1(19 downto 0);  
--					divisor1  <=   ERR_M3;
--					
--					elsif(TIME_COUNT = T_600ns) then
--					kp_M3 <= quotient1(19 downto 0); 
--					divisor1  <=   ERR_M4;
--					
--					elsif(TIME_COUNT = T_800ns) then
--				   kp_M4 <= quotient1(19 downto 0);    
--               TIME_COUNT <= (others=>'0');
--					end if;	
--					end if;				 
--					end process;		
		 -- M1 <= '0';
		 
		 LED <= LED2;
--			       LED1  when TEST_KEY(1 DOWNTO 0) ="00" else
--					 LED2  when TEST_KEY(1 DOWNTO 0) ="01" else
--					 LED3  when TEST_KEY(1 DOWNTO 0) ="10" else
--					 LED4  when TEST_KEY(1 DOWNTO 0) ="11" ;
					 
		  MS_SHOW <= 
					  M1_SHOW  when TEST_KEY(1 DOWNTO 0) ="00" else
					  M2_SHOW  when TEST_KEY(1 DOWNTO 0) ="01" else
					  M3_SHOW  when TEST_KEY(1 DOWNTO 0) ="10" else
					  M4_SHOW  when TEST_KEY(1 DOWNTO 0) ="11" ;
			
		  end Behavioral;

