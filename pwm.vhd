library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;
use IEEE.STD_LOGIC_arith.ALL;

entity pwm is
	generic (n:integer range 1 to 11 := 11);
	port (oc_in: in std_logic_vector (n-1 downto 0);
			oc_out: out std_logic;
			clk: in std_logic);
end pwm;

architecture Behavioral of pwm is
	signal Cnt, Cnt_1, Cnt_2: std_logic_vector(n-1 downto 0):=(others=>'0');
	--signal oc_ins : std_logic_vector(n-1 downto 0);
begin
  -- oc_ins (7 downto 1) <= oc_in (6 downto 0);
   --oc_ins (0) <= '0';	
	
	process(Clk)
   begin
	
		if rising_edge(Clk) then
--		cnt_clk <= cnt_clk + 1;
--		
--	if(cnt_clk="00001011") then
--	 cnt_clk <="00000000";
			oc_out <='1';
			if(Cnt >= oc_in) then
				oc_out <='0';
			end if;
		end if;
--		end if;
	end process;
	process(Clk)
   begin
		if rising_edge(Clk) then
			Cnt_1 <= Cnt_1+1;
		end if;
	end process;
	process(Clk)
   begin
		if falling_edge(Clk) then
			Cnt_2 <= Cnt_2+1;
		end if;
	end process;
	
	Cnt <= Cnt_1;-- + Cnt_2;-- 
------------------------     cnt<=cnt+'1';
------------------------    if  (cnt = "00001011") then
------------------------	     cnt <= "00000000";
------------------------		  Cnt_1 <= Cnt_1+1;
------------------------	     oc_out <='1';
------------------------		  if(Cnt_1 >= oc_in) then
------------------------		   oc_out <='0';
------------------------			 end if;
------------------------		    end if;
------------------------          end process;		
          end Behavioral;