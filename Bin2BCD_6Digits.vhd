LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Bin2BCD_6Digits is
	PORT(binIn : in std_logic_vector(7 downto 0);
		  bcd5  : out std_logic_vector(3 downto 0); --left most bit of score
		  bcd4  : out std_logic_vector(3 downto 0); 
		  bcd3  : out std_logic_vector(3 downto 0);
		  bcd2  : out std_logic_vector(3 downto 0);
		  bcd1  : out std_logic_vector(3 downto 0);
		  bcd0  : out std_logic_vector(3 downto 0)); --right most bit of score
END Bin2BCD_6Digits;

ARCHITECTURE BEHAVIOURAL OF Bin2BCD_6Digits IS

SIGNAL  s_bcd5, s_bcd4, s_bcd3, s_bcd2, s_bcd1, s_bcd0  :  std_logic_vector(7 downto 0);


BEGIN

	s_bcd5 <= std_logic_vector(unsigned(binIn(7 downto 0))/100000);
	s_bcd4<= std_logic_vector((unsigned(binIn(7 downto 0))rem 1000000)/100000);
	s_bcd3 <= std_logic_vector(unsigned(binIn(7 downto 0))rem 100000/1000);
	s_bcd2 <= std_logic_vector(unsigned(binIn(7 downto 0))rem 1000/100);
	s_bcd1 <= std_logic_vector(unsigned(binIn(7 downto 0))rem 100/10);
	s_bcd0 <= std_logic_vector(unsigned(binIn(7 downto 0))rem 10);
	
	
	bcd5 <= s_bcd5(3 downto 0);
	bcd4 <= s_bcd4(3 downto 0);
	bcd3 <= s_bcd3(3 downto 0);
	bcd2 <= s_bcd2(3 downto 0);
	bcd1 <= s_bcd1(3 downto 0);
	bcd0 <= s_bcd0(3 downto 0);
	
END BEHAVIOURAL;