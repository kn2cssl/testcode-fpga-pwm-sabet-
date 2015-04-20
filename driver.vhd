
	library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.STD_LOGIC_unsigned.ALL;
	use IEEE.STD_LOGIC_arith.ALL;
 --  use ieee.numeric_std.ALL;

	entity drivermotor is
	generic (n:integer range 1 to 11 := 11);
	port( clk:in std_logic;
			HALL1:in std_logic;
			HALL2:in std_logic;
			HALL3:in std_logic;
			M1p:out std_logic;
			M1n:out std_logic;
			M2p:out std_logic;
			M2n:out std_logic;
			M3p:out std_logic;
			M3n:out std_logic;
			HALL_OUT:out std_logic;
			CLK_1MS:out std_logic;
			CHECK_OUT:out std_logic;
			SPEED :in std_logic_vector(15 downto 0);
			M_show:out signed (15 downto 0);
			ERR_M  :out std_logic_vector(15 downto 0);
			kp_M   :in std_logic_vector(19 downto 0);	
		   --HALL_COUNT :in std_logic_vector(4 downto 0);
			LED   :out std_logic_vector(3 downto 0);
			FREE_WHEEL : in std_logic;
			--kp_in      : in std_logic_vector(15 downto 0);
			TEST_KEY   : in std_logic_vector(3 downto 2)
			 );
	end drivermotor;

		
	architecture Behavioral of drivermotor is
   
		
	component PWM is
	generic (n:integer range 1 to 11 := 11);
	port (
		  CLK   : in std_logic;
		  OC_IN : in std_logic_vector (n-1 downto 0);
		  OC_OUT: out std_logic
		  );
   end component;
	
--	component DIVIDER is
--	port (
--			clk: in std_logic;
--			rfd: out std_logic;
--			dividend: in std_logic_vector(31 downto 0);
--			divisor: in std_logic_vector(15 downto 0);
--			quotient: out std_logic_vector(31 downto 0);
--			fractional: out std_logic_vector(15 downto 0)
--	     );
--   end component;
	
		
   signal PWM_S       : std_logic;
	signal CLK_TIMER   : std_logic:='0';
	signal RPM_DIR     : std_logic :='0';
	signal hall_out_s  : std_logic:='0';
   signal STATE1      : std_logic_vector(3 downto 0); 
	signal STATE      : std_logic_vector(3 downto 0);
	signal hall_state  : std_logic_vector(2 downto 0); 
   signal hall_state_past  : std_logic_vector(2 downto 0); 
 
  	signal M_RPM_DIR      : signed(15 DOWNTO 0)  :=(others=>'0'); 
   signal M_RPM_DIR_LAST : signed(15 DOWNTO 0)  :=(others=>'0'); 
	--signal  M_RPMF    : std_logic_vector(15 DOWNTO 0) :=(others=>'0'); 
   	  
   --signal  M_ERR_LAST: signed(15 downto 0);

 
--	signal  RPM_DIFF_LAST   : signed (15 DOWNTO 0)  :=(others=>'0');
	
	constant K_FILTER: signed(10 downto 0) :="00000001111";--0.00595 11 BIT ASHAR
   
	signal TIMER_COUNT : std_logic_vector(16 downto 0):=(others=>'0');
	
	signal HALL_COUNT : std_logic_vector(15 downto 0):=(others=>'0');
--	signal HALL1_COUNT : std_logic_vector(5 downto 0):=(others=>'0');
--	signal HALL2_COUNT : std_logic_vector(5 downto 0):=(others=>'0');
--	signal HALL3_COUNT : std_logic_vector(5 downto 0):=(others=>'0');
 
	
	signal hall1_past  : std_logic;
   --signal hall2_past  : std_logic;
   --signal hall3_past  : std_logic;	
   signal DIR         : std_logic;
	signal M_P_OVERFLOW: std_logic;
	--signal led_S       : std_logic:='0';
	signal CLK_S     : std_logic:='0';
	signal CHECK     : std_logic:='0';
	
	
	signal M_PID       : std_logic_vector(n-1 DOWNTO 0)  :=(others=>'0');	

	signal M_Kp_fp     : signed(19 downto 0):= "00000000011010000000";--(others=>'0'); --10.10 --BIT ALAMAT DARAD!!
	signal M_Kd_fp     : signed(15 downto 0):= "0000000000000000";--12.4  
	--signal KP4_fp      : signed(19 downto 0):= (others=>'0');

	
	constant MAX_PWM             : std_logic_vector(10 downto 0):= "11111111111";  
	
--	constant MAX                 : std_logic_vector(31 downto 0):="00000000001000010011110000000000";-- "00000000000111111111110000000000";  
	
	constant MAX_P               : integer range 0 to 2047 := 2047; 
	constant MAX_P_MINUS         : integer range -2047 to 0:= -2047;
	
	--constant MAX_D               : integer range 0 to 2400 := 2400;
	--constant MAX_D_MINUS         : integer range -2400 to 0:= -2400;
	
	--constant MAX_PD              : integer range 0 to 2047 := 2047;
	--constant MAX_PD_MINUS        : integer range -2047 to 0:= -2047;
	
	constant T_1MS     : std_logic_vector(15 downto 0):= "1100001101010000";  
	constant T_500US   : std_logic_vector(15 downto 0):= "0110000110101000"; 
	--constant T_2MS     : std_logic_vector(16 downto 0):= "11000011010100000";
	--constant T_20MS    : std_logic_vector(16 downto 0):= "11000011010100000";
	--constant T_1S      : std_logic_vector(31 downto 0):= "10110010110100000101111000000000";--1S --timer count bayad ziad beshe age 1s khastin!!
	
	 constant lim500 : signed(15 DOWNTO 0) := "0000000111110100";--500 
	 constant lim300 : signed(15 DOWNTO 0) := "0000000100101100";--300 
	 constant lim20  : signed(15 DOWNTO 0) := "0000000000010100";--20
	 constant lim200 : signed(15 DOWNTO 0) := "0000000011001000";--200  
	 constant lim50  : signed(15 DOWNTO 0) := "0000000000110010";--50
	 constant lim0   : signed(15 DOWNTO 0) := "0000000000000000";--0   
	 constant lim499 : signed(15 DOWNTO 0) := "0000000111110011";--499 
	 constant lim400 : signed(15 DOWNTO 0) := "0000000110010000";--400  	
	 constant lim10  : signed(15 DOWNTO 0) := "0000000000001010";--10  
	 constant lim15  : signed(15 DOWNTO 0) := "0000000000001111";--15  
	 constant lim100 : signed(15 DOWNTO 0) := "0000000001100100";--100
	 constant lim40  : signed(15 DOWNTO 0) := "0000000000101000";--40
	 constant lim1250: std_logic_vector(15 DOWNTO 0) := "0000010011100010";--1250
	 constant lim150 : signed(15 DOWNTO 0) := "0000000010010110";--150
	 constant lim5   : signed(15 DOWNTO 0) := "0000000000000101";--5
    constant lim1   : signed(15 DOWNTO 0) := "0000000000000001";--1	
	 constant lim_minus15: signed(15 DOWNTO 0) := "1111111111110001";-- -15
	 
	-- constant lims1: signed(26 DOWNTO 0) := "000000000000000100000000000";-- 1 for speed
	 
	 constant KP1_fp         : signed(19 DOWNTO 0):= "00000000011010000000";--10.10 --1.625
	 constant KP2_fp         : signed(19 DOWNTO 0):= "00000010000000000000";--10.10 --8
	 constant KP3_fp         : signed(19 DOWNTO 0):= "00000000000001010000";--10.10 --0.078
    --constant KP5_fp         : signed(19 DOWNTO 0):= "00000110100000000000";--10.10	 
	 constant KP_50         : signed(19 DOWNTO 0):= "00001100100000000000";--10.10
	  
	  
	 --constant lim_KP1_fp     : signed(19 DOWNTO 0):= "00000101001100000000";--10.10 --20.75
	 --constant lim_KP2_fp     : signed(19 DOWNTO 0):= "00000110011010000000";--7.10 --25.625
	
  	 constant KP1_PLUS_fp    : signed(19 DOWNTO 0):= "00000000000000001000";--10.10 --0.0078
    constant KP2_PLUS_fp    : signed(19 DOWNTO 0):= "00000000000100000000";--10.10 --0.025
    constant KP1_MINUS_fp   : signed(19 DOWNTO 0):= "00000000000000111000";--10.10 --0.054
    constant KP2_MINUS_fp   : signed(19 DOWNTO 0):= "00000000000000000001";--10.10 --.00097

    constant KD_0   : signed(15 DOWNTO 0) := "0000000000000000";--0   --12.4 --BIT ALAMAT DARAD!!
	 constant KD_400 : signed(15 DOWNTO 0) := "0001100100000000";--400 --12.4 
	 constant KD_16  : signed(15 DOWNTO 0) := "0000000100000000";--16  --12.4 
	 constant KD_8   : signed(15 DOWNTO 0) := "0000000010000000";--8   --12.4 
	 
--  signal dividend   : std_logic_vector(31 downto 0):=(others=>'0');
--	 signal divisor    : std_logic_vector(15 downto 0):=(others=>'0');
--	 signal quotient   : std_logic_vector(31 downto 0):=(others=>'0');	 
--	 signal fractional : std_logic_vector(15 downto 0):=(others=>'0');
--	 signal rfd        : std_logic:='0';
		
		signal  M_ERROR   : signed(15 DOWNTO 0) :=(others=>'0'); --for show
--	   signal  LIM       : signed(15 DOWNTO 0) :=(others=>'0'); --for show
--	   signal  M_PD_S    : signed(30 DOWNTO 0)  :=(others=>'0'); --for show28+20
    signal  RPM_DIFF_show   : signed (15 DOWNTO 0)  :=(others=>'0');  --for show
--    signal  RPM_h_show   : signed (15 DOWNTO 0)  :=(others=>'0');  --for show
	 		
--			signal  test1_u   : std_logic_vector(15 DOWNTO 0) :=(others=>'0'); --for show
--	 	   signal  test1     : signed(15 DOWNTO 0) :=(others=>'0'); --for show	 
--		   signal  test2     : signed(15 DOWNTO 0) :="0000000000101000";--40
--	 		signal  test2_u   : std_logic_vector(15 DOWNTO 0) :="0000000000101000"; --40
--			signal  test     : signed(15 DOWNTO 0) :="0000000000110010";--(others=>'0'); --50
--	 		signal  test_u   : std_logic_vector(15 DOWNTO 0) :="0000000000110010";--50
--			signal  t    : signed(15 DOWNTO 0) :="1111110011100000";
--		   signal  test3     : signed(15 DOWNTO 0) :=(others=>'0'); 
--			signal  test3_u   : std_logic_vector(15 DOWNTO 0) :=(others=>'0');
--			signal  test_sefr  : std_logic_vector(15 DOWNTO 0) :=(others=>'0');
--			
	begin
	
	PWM_1:PWM port map (OC_IN =>M_PID ,CLK =>CLK  ,OC_OUT=>PWM_S  );
	--DIVIDE:DIVIDER port map (clk => clk,rfd => rfd,dividend => dividend,divisor => divisor,quotient => quotient,fractional => fractional);
	
	

    read_sensors:process(clk,HALL1,HALL2,HALL3,DIR)
					  begin
					  if rising_edge (clk)then
					  hall_state <= (HALL3 & HALL2 & HALL1);
					  if(hall_state /= hall_state_past) then
					  hall_count <= hall_count+1;
					  hall_out_S<= not hall_out_s;
					  end if;
					  
					 
					  
					  if(clk_timer='1')then
					  --if(rising_edge (clk_s))then
					  --M_SHOW <= signed(hall_count);
					  hall_count <= (others=>'0');
					  end if;
					  
--					  if(FREE_WHEEL='1')then
--               --  STATE1 <= "0111";	
--					  elsif(FREE_WHEEL='0')then
					  STATE1 <=(DIR & hall_state) ;
--					  end if;
					  
		           LED(3 downto 1) <=hall_state;
					  hall_state_past <= hall_state;
					  end if;	  
					  end process;
					  
--					  process(clk,hall1,hall2,hall3,dir)
--					  begin
--					  if(FREE_WHEEL='1')then
--               STATE1 <= "0111";	
--					  elsif(FREE_WHEEL='0')then
--					  STATE1 <=(DIR & hall3&hall2&hall1) ;
--					  end if;
--					  end process;
					 
--					 STATE1 <= "0111" when free_wheel='1' else --TARTIB HALL HA MOHEME! 
--					            (DIR & hall3&hall2&hall1) ; 
--					 
					  
					   
					   HALL_OUT <= HALL_OUT_S;--FOR TEST
					  
	motor_update :process(clk,HALL1,HALL2,HALL3,DIR,SPEED,STATE1,PWM_S)
					  begin
					  
					  case STATE1 is 
					  
					  when "0001" --(1|0x00)
													 =>  M2p<='0'; M1p<='0'; M2n<='0';	  M3n<='0';   M3p<='1'; M1n<= PWM_S;
					  when "1110" --(6|0x08)
													 =>  M2p<='0'; M1p<='0'; M2n<='0';	  M3n<='0';   M3p<='1'; M1n<= PWM_S;
					  when "0010" --(2|0x00) 
													 =>  M2p<='1'; M1p<='0'; M2n<='0';	  M3n<=PWM_S; M3p<='0'; M1n<='0';
					  when "1101" --(5|0x08) 
				 									 =>  M2p<='1'; M1p<='0'; M2n<='0';	  M3n<=PWM_S; M3p<='0'; M1n<='0';
					  when "0011" --(3|0x00) 
													 =>  M2p<='1'; M1p<='0'; M2n<='0';	  M3n<='0';   M3p<='0';  M1n<=PWM_S;
					  when "1100" --(4|0x08) 
													 =>  M2p<='1'; M1p<='0'; M2n<='0';	  M3n<='0';   M3p<='0';  M1n<=PWM_S;
					  when "0100" --(4|0x00) 
													 =>  M2p<='0'; M1p<='1'; M2n<=PWM_S;  M3n<='0';   M3p<='0';   M1n<= '0';
					  when "1011" --(3|0x08) 
													 =>  M2p<='0'; M1p<='1'; M2n<=PWM_S;  M3n<='0';   M3p<='0';   M1n<= '0';
					  when "0101" --(5|0x00) 
													 =>  M2p<='0'; M1p<='0'; M2n<= PWM_S;	  M3n<='0';   M3p<='1';   M1n<='0' ;
					  when "1010" --(2|0x08) 
													 =>  M2p<='0'; M1p<='0'; M2n<= PWM_S;	  M3n<='0';   M3p<='1';   M1n<= '0';
					  when "0110" --(6|0x00) 
													 =>  M2p<='0'; M1p<='1'; M2n<='0';	  M3n<=PWM_S;   M3p<='0'; M1n<= '0';
					  when "1001" --(1|0x08) 
													 =>  M2p<='0'; M1p<='1'; M2n<='0';	  M3n<=PWM_S;   M3p<='0'; M1n<= '0';
					  when "0111" --(7|0x08) 
													 =>  M2p<='0'; M1p<='0'; M2n<='0';	  M3n<='0';   M3p<='0';   M1n<='0';
					  when others            =>  M2p<='0'; M1p<='0'; M2n<='0';	  M3n<='0';   M3p<='0';   M1n<='0';							 
					  end case;								 
					  end process;				  

		 
SPEED_DIRECTION:	process(clk)
					begin
					if rising_edge(clk) then
					if hall1='1'  and hall1_past='0' then
					RPM_DIR <= HALL2;
					end if; 
					
					hall1_past <= hall1;
					end if;
					end process;

					
          					
				   	

--TIMER:			process(clk)  
--					begin	
--					if rising_edge (clk) then 
--					TIMER_COUNT <=  TIMER_COUNT+'1';
--					CLK_TIMER <= '0';
----					if(TIMER_COUNT >= T_1MS) then
--               if(TIMER_COUNT >= T_500US) then
----					CLK_TIMER <= '1';
----					elsif(TIMER_COUNT >= T_1_1MS)then
----					CLK_TIMER <= '0';
--					CLK_S<=NOT CLK_S;
--					TIMER_COUNT <= (others=>'0');
--					CLK_TIMER <= '1';
--					end if;	
--					end if;				 
--					end process;

				   clk_1ms <= CLK_S;--TIMER;
					
--TIMER:			process(clk)  
--					begin	
--					if rising_edge (clk) then 
--					TIMER_COUNT <=  TIMER_COUNT+'1';
--					CLK_TIMER <= '0'; --oon yeki
--					if(TIMER_COUNT >= T_1MS) then
----               if(TIMER_COUNT >= T_500US) then
--					CLK_TIMER <= '1';
----					elsif(TIMER_COUNT >= T_1_1MS)then
----					CLK_TIMER <= '0';
----					CLK_S<=NOT CLK_S;
--		         else
--					CLK_TIMER <= '0';
--		         TIMER_COUNT <= (others=>'0');
----					CLK_TIMER <= '1'; --oon yeki
--					end if;	
--					end if;				 
--					end process;

TIMER:			process(clk)  
					begin	
					if rising_edge (clk) then 
					TIMER_COUNT <=  TIMER_COUNT+'1';
					if(TIMER_COUNT = T_1MS) then
					CLK_TIMER <= '1';
					TIMER_COUNT <= (others=>'0');
					else
					CLK_TIMER <= '0';
					end if;	
					end if;				 
					end process;
			
			
--         	   process(clk,clk_s)  
--					begin	
--					if rising_edge (clk_s) and clk='1' then 
----					TIMER_COUNT <=  TIMER_COUNT+'1';
----					if(TIMER_COUNT >= T_1MS) then
----               if(TIMER_COUNT >= T_500US) then
--					CLK_TIMER <= '1';
----					elsif(TIMER_COUNT >= T_1_1MS)then
----					CLK_TIMER <= '1';
----					CLK_S<=NOT CLK_S;
----					TIMER_COUNT <= (others=>'0');
--					else
--					CLK_TIMER <= '0';
----					end if;	
--					end if;				 
--					end process;
--         
CALCULATE_SPEED:process(clk,CLK_TIMER)

					 
	   variable RPM_s     : signed (37 DOWNTO 0) :=(others=>'0');
	   variable RPM_LAST  : signed (26 downto 0) :=(others=>'0');--16.11
	   variable RPM_H     : std_logic_vector (26 downto 0) :=(others=>'0');
		variable RPM_HS    : signed (26 downto 0) :=(others=>'0');
	   variable RPM_F     : signed (26 downto 0) :=(others=>'0');
	   variable RPM_ABS   : std_logic_vector (26 downto 0) :=(others=>'0');
		--variable HALL_COUNT: std_logic_vector(5 downto 0);
		variable M_RPMF    : signed (15 DOWNTO 0) :=(others=>'0'); 
      --variable M_RPMF    : signed(15 DOWNTO 0) :=(others=>'0'); 		
		
					  begin
               if rising_edge (clk) then
                if CLK_TIMER ='1' then
					-- if rising_edge (clk_s) then
               --HALL_COUNT := HALL1_COUNT + HALL2_COUNT + HALL3_COUNT;		
                  -- CHECK <= NOT CHECK;
                  -- CHECK_OUT <= CHECK;
						M_RPM_DIR_LAST  <= RPM_F(26 DOWNTO 11);
						RPM_LAST := RPM_F;
						RPM_H    := ((HALL_COUNT * lim1250)& "00000000000");
						
						if(RPM_DIR='1')then
						RPM_HS   :=signed('0'-RPM_H);
						elsif(RPM_DIR='0')then
						RPM_HS   :=signed(RPM_H);
						end if;
						
						RPM_S    :=(K_FILTER*(RPM_HS - RPM_LAST));--0.11 * 16.11
					   RPM_F    := RPM_LAST + RPM_S(37 downto 11 );-- + lims1;-- signed("0000000000000000100000000000");
                  
						  --M_RPMF   := RPM_F(26 DOWNTO 11);
						
----				     -- RPM_ABS  := ABS (RPM_F);
						
----					  -- M_RPMF   := RPM_F(23 DOWNTO 8);
----					  -- m_show <= signed (m_rpmf);
----						
----					  --RPM_ABS  := ABS (RPM_F);
----					  --M_RPMF   := RPM_ABS(26 DOWNTO 11);
						
						
						--M_RPM_DIR_LAST  <= M_RPM_DIR;
					   --M_RPM_DIR  <= M_RPMF;
						
					   M_RPM_DIR  <= RPM_F(26 DOWNTO 11) + '1';
						
                  						
------						if(RPM_DIR='1')then
------						M_RPM_DIR <= signed('0'- M_RPMF) ;
------						--M_RPM_DIR <= '0'- M_RPMF ;
------                  elsif(RPM_DIR='0')then						
------						M_RPM_DIR <= signed(M_RPMF);
------						--M_RPM_DIR <= M_RPMF;
------						end if;
----						
						
						
					   
					---	rpm_h_show <= rpm_h(23 downto 8); --for show 
						
						end if;
				      end if;
					end process;
					
--					  M_RPM_DIR  <= 
--					             signed("0000000000000000"- M_RPMF)           when RPM_DIR ='1' else
--									 signed(M_RPMF)                when RPM_DIR ='0' ;
--                            
          									 


	KD_TUNINIG:		process(clk)
					 
					 	 variable BRIDGE  : std_logic:='0';
						 variable MISS    : std_logic:='0';
						 variable CHANGE  : std_logic:='0';	
						 variable TRACK   : std_logic:='0';
						 variable SETPOINT_LAST  : signed (15 DOWNTO 0)  :=(others=>'0');
				       variable SETPOINT       : signed (15 DOWNTO 0)  :=(others=>'0');
						 variable RPM_DIFF_LAST  : signed (15 DOWNTO 0)  :=(others=>'0');
				       variable RPM_DIFF       : signed (15 DOWNTO 0)  :=(others=>'0');
				       variable M_ERR          : signed (15 DOWNTO 0)  :=(others=>'0');
	                
                begin
                if rising_edge (clk) then
					 if CLK_TIMER ='1'  then
					 --if rising_edge (clk_s) then
				    SETPOINT := signed(SPEED);
--					 M_ERR    := signed(SPEED)- M_RPM_DIR ;
                 if(SETPOINT(15)='0')then
					   M_ERR     :=  SETPOINT -  M_RPM_DIR + lim20 ;
                 elsif(SETPOINT(15)='1')then
                  M_ERR     :=  SETPOINT -  M_RPM_DIR - lim20 ; 					  
					  end if;
					  
					 RPM_DIFF_LAST   := RPM_DIFF;
					 RPM_DIFF        := M_RPM_DIR - M_RPM_DIR_LAST;
                

						
              if (CHANGE ='1' and  abs(M_ERR) > lim300 ) then  
                  BRIDGE := '1';
				  end if;
					 
				  if (BRIDGE ='1' and abs (M_ERR )< lim300 )then
					BRIDGE := '0';
					MISS   := '1';
				  end if;
					 
					 
				 if (MISS  ='1' and RPM_DIFF(15)/= RPM_DIFF_LAST(15))then
					MISS  := '0';
					TRACK := '1';
				 end if;
					 
					 
					 
					 if(BRIDGE ='1') then
					   M_Kd_fp <= KD_0;
					 end if;
					 
					 if(MISS ='1') then
					   M_Kd_fp  <= KD_400;
					 end if;
					 
					 if(TRACK ='1') then
					   M_Kd_fp <= KD_16;
					 if( abs(SETPOINT) < lim500) then  
					   M_Kd_fp <= KD_8;
					 end if;
					 end if;
					 
					 CHANGE :='0';
					 if(SETPOINT_LAST /=  SETPOINT ) then 		 		 
					
						CHANGE :='1';
						TRACK  :='0';
					 end if;
					 
					 SETPOINT_LAST  :=  SETPOINT;
				    end if;
					 end if;
					 end process;
					

 KP_TUNING:process(clk)
	            
				  variable M_ERR          : signed (15 DOWNTO 0)  :=(others=>'0');
	           --variable M_ERR_KP       : signed (15 DOWNTO 0)  :=(others=>'0');
				  variable M_ERR_LAST     : signed (15 DOWNTO 0)  :=(others=>'0');
				  variable SETPOINT_LAST  : signed (15 DOWNTO 0)  :=(others=>'0');
				  variable SETPOINT       : signed (15 DOWNTO 0)  :=(others=>'0');
				 -- variable SETPOINT_KP    : signed (15 DOWNTO 0)  :=(others=>'0');
				  variable SETPOINT_DIFF  : signed (15 DOWNTO 0)  :=(others=>'0');
				  variable  RPM_DIFF      : signed (15 DOWNTO 0)  :=(others=>'0');
	           variable  RPM_DIFF_LAST : signed (15 DOWNTO 0)  :=(others=>'0');
				  variable LIMIT_KP_fp    : signed (35 DOWNTO 0)  :=(others=>'0');
				  variable LIMIT_KP       : signed (24 DOWNTO 0)  :=(others=>'0');
				  
				  begin
				  if rising_edge (clk) then
				  if CLK_TIMER ='1'  then
				 --  if rising_edge (clk_s) then
				--  led(1) <= led_s;--FOR TEST
				  
				    SETPOINT        :=  signed( SPEED);
--   			    M_ERR           :=  SIGNED(SPEED) -  M_RPM_DIR ;
                if(SETPOINT(15)='0')then
					   M_ERR     :=  SETPOINT -  M_RPM_DIR + lim20 ;
                elsif(SETPOINT(15)='1')then
                  M_ERR     :=  SETPOINT -  M_RPM_DIR - lim20 ; 					  
					 end if;
					  
					 --RPM_DIFF_LAST  := RPM_DIFF;
					 RPM_DIFF       := M_RPM_DIR - M_RPM_DIR_LAST;
                SETPOINT_DIFF  := setpoint - setpoint_last;
					 LIMIT_KP_fp    := M_KP_fp*M_ERR; --10.10 * 16.0 = 22.10  (31 DOWNTO 10)  BIT HAYE SAHIH
					 LIMIT_KP       := LIMIT_KP_fp(34 DOWNTO 10);
					 --LIM            <= LIMIT_KP(15 DOWNTO 0);--FOR SHOW
			

         if (M_p_overflow = '0')	then
	
			if( abs(RPM_DIFF)<lim15 and abs(M_ERR)>lim400 and abs(M_RPM_DIR)>lim10 ) then --and abs(limit_kp) > conv_std_logic_vector(MAX_P,12 )) then--and abs(LIMIT_KP)<MAX_PWM) then
			M_KP_fp <= M_KP_fp + KP2_PLUS_fp;
			--led_s <= not led_s; --FOR TEST
			--LED(1) <= LED_S; --for test
			end if;
			
		   if( abs(RPM_DIFF)<lim15 and abs(M_ERR)< lim400 and abs(M_RPM_DIR)>lim10 )then -- and abs(M_ERR)>lim15 and abs(limit_kp) > conv_std_logic_vector(MAX_P,12 ) ) then -- and abs(LIMIT_KP)<MAX_PWM ) then
			M_KP_fp <= M_KP_fp + KP1_PLUS_fp;
			end if; 

			end if;
			
         if (abs(M_RPM_DIR) > abs(SETPOINT)) then
		
		   if (abs(RPM_DIFF) < lim10 and abs(M_ERR) < lim400 and abs(M_ERR)  > lim10 and abs(M_RPM_DIR)>lim10  and abs(SETPOINT) > lim499 ) then
			M_KP_fp <= M_KP_fp - KP1_MINUS_fp;
			end if;
			
			if (abs(RPM_DIFF) < lim10 and abs(M_Err) < lim400 and abs(M_Err) > lim10 and abs(SETPOINT) < lim499 ) then
			M_KP_fp <= M_KP_fp - KP2_MINUS_fp;
			end if;
			
			if (M_KP_fp < KP1_fp   ) then
			M_KP_fp <= KP1_fp ;
			end if;
			
         end if;	
			
			if (M_KP_fp > KP_50  ) then
			M_KP_fp <= KP_50 ;
			end if;
			
           
--			  	if (abs(limit_kp) > conv_std_logic_vector(MAX_P,12 ))then-- and rfd='1' ) then   
--		--	----   M_KP_fp <= (CONV_INTEGER(MAX_P )+ LIM10) / M_Err ;
--				
--------				dividend  <= max ;
--------				divisor   <= abs (M_ERR);
--------				M_KP_fp   <= signed ( quotient(19 downto 0)) ; 
----			   
--                
--
----				ERR_M     <= abs (M_ERR);
----				M_KP_fp   <= SIGNED(KP_M) ; 
----			   
--			   
--				end if;
				
				if(abs (M_RPM_DIR) <lim50) then
 			
				if (abs(SETPOINT) > lim499) then
				 M_KP_fp <= KP1_fp;
				else
				 M_KP_fp <= KP2_fp;--signed (kp_in & "0000");--
				end if;
				
			   end if;	
			
			
			if (abs(SETPOINT)<lim500) then
			  M_KP_fp <= KP2_fp;--signed (kp_in & "0000");--
		   end if;
			
			if (abs(SETPOINT_DIFF) > abs(RPM_DIFF) and  abs(M_Err) > lim200) then
			 M_KP_fp <= M_KP_fp + abs(SETPOINT_DIFF - RPM_DIFF)* KP3_fp;
			end if;			
				 
			
				SETPOINT_LAST  :=  SETPOINT;
				
				
				   end if;
				   end if;
					
					 RPM_DIFF_show<= RPM_DIFF; 
				  end process;
   
               
 PD_CONTROLLER: 	 process(clk)
					   
				       variable M_SETPOINT  : signed (15 DOWNTO 0)  :=(others=>'0');								    
						 variable M_ERR       : signed (15 DOWNTO 0)  :=(others=>'0');	
						 variable M_ERR_fp    : signed (16 DOWNTO 0)  :=(others=>'0');	--16.1
						 
						 variable M_P_fp      : signed (35 DOWNTO 0)  :=(others=>'0');	--26.11  --HASEL 16.0 * 10.10
						 variable M_P         : signed (25 DOWNTO 0)  :=(others=>'0');
						-- variable M_P_ABS     : std_logic_vector(20 DOWNTO 0)  :=(others=>'0');
						 
						 variable M_D_fp      : signed (31 DOWNTO 0)  :=(others=>'0');--28.12   --HASEL 16.8 * 12.4
						 variable M_D         : signed (27 DOWNTO 0)  :=(others=>'0');
						 
						 variable M_PD        : signed (30 DOWNTO 0)  :=(others=>'0'); --28+20		
						 variable M_PD_ABS    : std_logic_vector (30 DOWNTO 0)  :=(others=>'0');	--20.11
						 variable M_PD_ABS_DIV    : std_logic_vector (10 DOWNTO 0)  :=(others=>'0');	
						 
                   variable  RPM_DIFF   : signed (15 DOWNTO 0)  :=(others=>'0');						 
					   					   

					  begin 
					  if rising_edge (clk) then
					  if CLK_TIMER ='1' 	then
					 -- if rising_edge (clk_s) then
					  M_SETPOINT :=  signed( SPEED );
   				  RPM_DIFF   := M_RPM_DIR - M_RPM_DIR_LAST;
--					  M_ERR           :=  SIGNED(SPEED) -  M_RPM_DIR ;  
					  
					  if(M_SETPOINT(15)='0')then
					   M_ERR     := (M_SETPOINT -  M_RPM_DIR) + lim20 ;
                elsif(M_SETPOINT(15)='1')then
                  M_ERR     := (M_SETPOINT -  M_RPM_DIR) - lim20 ; 					  
					  end if;
					  
  					  M_P_fp  := (M_ERR * M_KP_fp) ; --16.0 * 10.10 =26.10 
                 M_P     := M_P_fp(35 downto 10);
					  
					   M_p_overflow <= '0';
					  if(M_P>=MAX_P)then
					  M_P := SIGNED( conv_std_logic_vector (MAX_P,22));
					  M_p_overflow <= '1';
					  elsif(M_P<= MAX_P_MINUS)then
				     M_P := SIGNED(conv_std_logic_vector (MAX_P_MINUS,22));
					  M_p_overflow <= '1';
					  end if;
				  
--					if (RPM_DIFF>= MAX_D) then 
--					RPM_DIFF := SIGNED( conv_std_logic_vector (MAX_D,16));
--					elsif(RPM_DIFF<MAX_D_MINUS) then                                    ---az m_d eshbae nagereftim 
--					RPM_DIFF := SIGNED(conv_std_logic_vector (MAX_D_MINUS,16));         --to code asli az rpm_diff eshba gerefte!
--					end if;
					  
					  M_D_fp := RPM_DIFF * M_KD_fp;
                 M_D    := M_D_fp (31 downto 4);					  
					 
							
--			         if (M_D>= MAX_D) then 
--					   M_D := SIGNED( conv_std_logic_vector (MAX_D,28));
--						elsif(M_D<MAX_D_MINUS) then                                    ---az m_d eshbae nagereftim 
--						M_D := SIGNED(conv_std_logic_vector (MAX_D_MINUS,28));         --to code asli az rpm_diff eshba gerefte!
--                  end if;

                 
                  
						M_PD := M_P - M_D;
						
--						if (M_PD>= MAX_PD) then 
--					   M_PD := SIGNED( conv_std_logic_vector (MAX_PD,31));
--						elsif(M_PD<MAX_PD_MINUS) then
--					 	M_PD := SIGNED(conv_std_logic_vector (MAX_PD_MINUS,31));
--                  end if;
						
					  if(M_PD(30)='1')then
					 -- DIR<='1'; 
					  else
					 -- DIR<='0'; 
					  end if;
                 
					 -- if((abs (m_setpoint)<lim100) ) then--and (abs(m_rpm_dir) < lim100 )
                if(( m_setpoint=lim0) and (abs(m_rpm_dir) <lim10) and  m_rpm_dir(15)='0')then--((m_rpm_dir) >lim0)) then
              
--					  DIR <= '0';
--					  M_PID  <= "00000000000";
					  elsif((m_setpoint=lim0) and (abs(m_rpm_dir) <lim10) and m_rpm_dir(15)='1')then--((m_rpm_dir) <lim0)) then				 
					  
--					  DIR <= '1';
--					  M_PID  <= "00000000000";
					  else
					  M_PD_ABS := ABS(M_PD);
					  M_PD_ABS_div := '0'& M_PD_ABS(10 DOWNTO 1);-- & '0'; 
					 -- M_PID  <=  M_PD_ABS_div;--(10 downto 0); 
					  end if;
					  
					 M_PID <= "01111110000";
					 DIR <= '1';
					 M_ERROR <= M_ERR;  --for show
					 -- M_PD_S <= M_PD; 
					 
--					 test1_u <=  '0'-test_sefr;
--					 
--					 --test1 <=( not (test)) + signed('1');
--					  
--					 test3_u <=  not test_u+'1';
--					 
--					 test3 <= test-test2;
--					 
--					 test4 <= not t;
--					 test4_u <= not t;
					 
					  end if;
					  end if;					  
					  end process;
					  
 		 
                M_SHOW  <=
										     M_RPM_DIR                               when TEST_KEY="00" else                              
										     signed("0000"& M_KD_fp(15 downto 4))     when TEST_KEY="01" else              
										     signed(speed)                           when TEST_KEY="10" else 
                 				        signed("000000"& M_KP_fp(19 DOWNTO 10)) when TEST_KEY="11" ;								  -- t     
										
										 										 
										 
					
				
			 end Behavioral;

				
        