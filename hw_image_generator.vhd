--------------------------------------------------------------------------------
--
--   FileName:         hw_image_generator.vhd
--   Dependencies:     none
--   Design Software:  Quartus II 64-bit Version 12.1 Build 177 SJ Full Version
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 05/10/2013 Scott Larson
--     Initial Public Release
--    
--------------------------------------------------------------------------------
--
-- Altered 10/13/19 - Tyler McCormick 
-- Test pattern is now 8 equally spaced 
-- different color vertical bars, from black (left) to white (right)


LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY hw_image_generator IS
  GENERIC(
    
	topBar : INTEGER := 60;
	Top_Line_Top_Row  : INTEGER := 61;
	Top_Line_Bottom_Row  : INTEGER := 64;
	Bottom_Line_Top_Row  : INTEGER := 421;
	Bottom_Line_Bottom_Row  : INTEGER := 424;
	playField : INTEGER := 420;
	bottomBar : INTEGER := 480;
	
	leftShipRowTop : INTEGER := 20;
	middleShipRowTop : INTEGER := 20;
	rightShipRowTop : INTEGER := 20;

	leftShipRowBottom : INTEGER := 50;
	middleShipRowBottom : INTEGER := 50;
	rightShipRowBottom : INTEGER := 50;
	
	
	leftShipColumnStart : INTEGER := 30;
	leftShipColumnEnd   : INTEGER := 60;
	middleShipColumnStart : INTEGER := 70;
	middleShipColumnEnd   : INTEGER := 100;
	rightShipColumnStart : INTEGER := 110;
	rightShipColumnEnd   : INTEGER := 140;
	
	score_letter_5_left  : INTEGER := 380;
	score_letter_5_right  : INTEGER := 410;
	score_letter_4_left  : INTEGER := 420;
	score_letter_4_right  : INTEGER := 450;
	score_letter_3_left  : INTEGER := 460;
	score_letter_3_right  : INTEGER := 490;
	score_letter_2_left  : INTEGER := 500;
	score_letter_2_right  : INTEGER := 530;
	score_letter_1_left  : INTEGER := 540;
	score_letter_1_right  : INTEGER := 570;
	score_letter_0_left  : INTEGER := 580;
	score_letter_0_right  : INTEGER := 610
	

	);  --:)
  PORT(
    SW0    :  IN   STD_LOGIC;
    key      :  IN   STD_LOGIC;
    disp_ena :  IN   STD_LOGIC;  --display enable ('1' = display time, '0' = blanking time)
    row      :  IN   INTEGER;    --row pixel coordinate
    column   :  IN   INTEGER;    --column pixel coordinate
    red      :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --red magnitude output to DAC
    green    :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --green magnitude output to DAC
    blue     :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0')); --blue magnitude output to DAC
END hw_image_generator;

ARCHITECTURE behavior OF hw_image_generator IS


COMPONENT Bin2BCD_6Digits IS
	PORT(binIn : in std_logic_vector(7 downto 0);
		  bcd5  : out std_logic_vector(3 downto 0); --left most bit of score
		  bcd4  : out std_logic_vector(3 downto 0); 
		  bcd3  : out std_logic_vector(3 downto 0);
		  bcd2  : out std_logic_vector(3 downto 0);
		  bcd1  : out std_logic_vector(3 downto 0);
		  bcd0  : out std_logic_vector(3 downto 0)); --right most bit of score
END COMPONENT;



SIGNAL Lives : INTEGER := 3;
SIGNAL Score_count : std_logic_vector(7 downto 0);
SIGNAL bcd_score5, bcd_score4, bcd_score3, bcd_score2, bcd_score1, bcd_score0 : std_logic_vector(3 downto 0);
SIGNAL Game_Over, Paused : std_logic := '0';




--CONSTANT SHIP_SIZE : INTEGER := 30; 
---- ship left and right boundary
--SIGNAL ship_x_l, ship_x_r : unsigned(9 downto 0);
---- ship up and down boundary
--SIGNAL ship_y_t, ship_y_b : unsigned(9 downto 0);
---- ship image ROM
--TYPE rom_type is array(0 to 29) of std_logic_vector(0 to 29);
--CONSTANT SHIP_ROM : rom_type := (
--	"100000000000000000000000000000", --0
--	"110000000000000000000000000000", --1
--	"111000000000000000000000000000", --2
--	"111100000000000000000000000000", --3
--	"111110000000000000000000000000", --4
--	"111111000000000000000000000000", --5
--	"111111100000000000000000000000", --6
--	"111111110000000000000000000000", --7
--	"111111111000000000000000000000", --8
--	"111111111100000000000000000000", --9
--	"111111111110000000000000000000", --10
--	"111111111111000000000000000000", --11
--	"111111111111100000000000000000", --12
--	"111111111111110000000000000000", --13
--	"111111111111111000000000000000", --14
--	"111111111111111100000000000000", --15
--	"111111111111111110000000000000", --16
--	"111111111111111111000000000000", --17
--	"111111111111111111100000000000", --18
--	"111111111111111111110000000000", --19
--	"111111111111111111111000000000", --20
--	"111111111111111111111100000000", --21
--	"111111111111111111111110000000", --22
--	"111111111111111111111111000000", --23
--	"111111111111111111111111100000", --24
--	"111111111111111111111111110000", --25
--	"111111111111111111111111111000", --26
--	"111111111111111111111111111100", --27
--	"111111111111111111111111111110", --28
--	"111111111111111111111111111111"); --29
--
--SIGNAL rom_addr, rom_col: unsigned(4 downto 0);
--SIGNAL rom_data: std_logic_vector(29 downto 0);
--SIGNAL rom_bit : std_logic;
-- --signal to indicate if scan coord is within ship
--SIGNAL rd_ship_on : std_logic;




signal s_char_2       : std_logic_vector(6 downto 0);
signal s_score_digit_row 			  : std_logic_vector(3 downto 0);
signal s_score_digit_column 		  : std_logic_vector(3 downto 0);



BEGIN
	
	--U1 : Bin2BCD_6Digits PORT MAP(Score_Count, bcd_score5, bcd_score4, bcd_score3, bcd_score2, bcd_score1, bcd_score0);
	
	PROCESS(disp_ena, row, column)
	
	VARIABLE startWord : INTEGER := 190;
	VARIABLE rowHeight : INTEGER := 9; -- will have 3 rows
	VARIABLE colLength : INTEGER := 9; -- will have 3 col
	VARIABLE row_A_top : INTEGER := playField+5;
	VARIABLE row_A_bot : INTEGER := row_A_top+8;  
	VARIABLE row_B_top : INTEGER := row_A_bot+1;
	VARIABLE row_B_bot : INTEGER := row_B_top+8;  
	VARIABLE row_C_top : INTEGER := row_B_bot+1;
	VARIABLE row_C_bot : INTEGER := row_C_top+8;

	-- Letter Tops
	VARIABLE T1topStart : INTEGER := startWord;
	VARIABLE T1topEnd : INTEGER := T1topStart + 3*colLength;
	VARIABLE NLtopStart : INTEGER := T1topEnd+3; -- N may be a bit complicated
	VARIABLE NLtopEnd : INTEGER := NLtopStart+colLength;
	VARIABLE NRtopStart: INTEGER := NLtopEnd+colLength;
	VARIABLE NRtopEnd : INTEGER := NRtopStart+colLength;
	VARIABLE T2topStart : INTEGER := NRtopEnd+3;
	VARIABLE T2topEnd : INTEGER := T2topStart + 3*colLength;
	VARIABLE E1topStart : INTEGER := T2topEnd+3;
	VARIABLE E1topEnd : INTEGER := E1topStart + 3*colLength;
	VARIABLE C1topStart : INTEGER := E1topEnd+3;
	VARIABLE C1topEnd : INTEGER := C1topStart + 3*colLength;
	VARIABLE HLtopStart : INTEGER := C1topEnd+3;
	VARIABLE HLtopEnd : INTEGER := HLtopStart + colLength;
	VARIABLE HRtopStart : INTEGER := HLtopEnd+colLength;
	VARIABLE HRtopEnd : INTEGER := HRtopStart+colLength;
	VARIABLE E2topStart : INTEGER := HRtopEnd+15;
	VARIABLE E2topEnd : INTEGER := E2topStart+3*colLength;
	VARIABLE C2topStart : INTEGER := E2topEnd+3;
	VARIABLE C2topEnd : INTEGER := C2topStart+3*colLength;
	VARIABLE E3topStart : INTEGER := C2topEnd+3;
	VARIABLE E3topEnd : INTEGER := E3topStart+3*colLength;

	-- Letter Mids
	VARIABLE T1midStart : INTEGER := startWord+colLength;
	VARIABLE T1midEnd: INTEGER := T1midStart+colLength;
	VARIABLE NLmidStart: INTEGER := T1midEnd+3+colLength;
	VARIABLE NLmidEnd: INTEGER := NLmidStart+colLength;
	VARIABLE NRmidStart: INTEGER := NLmidEnd+colLength;
	VARIABLE NRmidEnd: INTEGER := NRmidStart+colLength;
	-- N's 
	VARIABLE T2midStart : INTEGER := NRmidEnd+3+colLength;
	VARIABLE T2midEnd: INTEGER := T2midStart+colLength;
	VARIABLE E1midStart: INTEGER := T2midEnd+3+colLength;
	VARIABLE E1midEnd: INTEGER := E1midStart+2*colLength;
	VARIABLE C1midStart: INTEGER := E1midEnd+3+colLength;
	VARIABLE C1midEnd: INTEGER := C1midStart+colLength; 
	VARIABLE HmidStart: INTEGER := C1midEnd+3+2*colLength;
	VARIABLE HmidEnd: INTEGER := HmidStart+3*colLength;
	VARIABLE E2midStart: INTEGER := HmidEnd+15;
	VARIABLE E2midEnd: INTEGER := E2midStart+2*colLength;
	VARIABLE C2midStart: INTEGER := E2midEnd+3+colLength;
	VARIABLE C2midEnd: INTEGER := C2midStart+colLength;
	VARIABLE E3midStart: INTEGER := C2midEnd+3+2*colLength;
	VARIABLE E3midEnd: INTEGER := E3midStart+2*colLength;
	
	
   BEGIN
	IF(disp_ena = '1') THEN        --display time
	
		--Top line display
		if(row >= Top_Line_Top_Row and row < Top_Line_Bottom_Row) then
        red <= (OTHERS => '0');
        green  <= (OTHERS => '1');
        blue <= (OTHERS => '0');
		  
		--Bottom line display  
		elsif(row >= Bottom_Line_Top_Row and row < Bottom_Line_Bottom_Row ) then
		  red <= (OTHERS => '0');
        green  <= (OTHERS => '1');
        blue <= (OTHERS => '0');
		  
		  
		
		


			
		--Last Ship Live  
		elsif((row >= leftShipRowTop and row <= leftShipRowBottom) and (column >= leftShipColumnStart and column <= leftShipColumnEnd) and (Lives > 0)) then
		  red <= (OTHERS => '0');
        green  <= (OTHERS => '0');
        blue <= (OTHERS => '1');
		--Middle Ship Live 
		elsif((row >= middleShipRowTop and row <= middleShipRowBottom) and (column >= middleShipColumnStart and column <= middleShipColumnEnd) and (Lives > 1)) then
		  red <= (OTHERS => '0');
        green  <= (OTHERS => '0');
        blue <= (OTHERS => '1');
		--3 Lives
		elsif((row >= rightShipRowTop and row <= rightShipRowBottom) and (column >= rightShipColumnStart and column <= rightShipColumnEnd) and (Lives > 2)) then
		  red <= (OTHERS => '0');
        green  <= (OTHERS => '0');
        blue <= (OTHERS => '1');
		  
		  
		 
		  
		  
		--Score section  
		
		elsif((row >= rightShipRowTop and row <= rightShipRowBottom) and (column >= score_letter_5_left and column <= score_letter_5_right) and Game_Over = '0') then
		  red <= (OTHERS => '0');
        green  <= (OTHERS => '0');
        blue <= (OTHERS => '1');
		 
		elsif((row >= rightShipRowTop and row <= rightShipRowBottom) and (column >= score_letter_4_left and column <= score_letter_4_right) and Game_Over = '0') then
		  red <= (OTHERS => '0');
        green  <= (OTHERS => '0');
        blue <= (OTHERS => '1');
		
		
		elsif((row >= rightShipRowTop and row <= rightShipRowBottom) and (column >= score_letter_3_left and column <= score_letter_3_right) and Game_Over = '0') then
		  red <= (OTHERS => '0');
        green  <= (OTHERS => '0');
        blue <= (OTHERS => '1');
		 
		elsif((row >= rightShipRowTop and row <= rightShipRowBottom) and (column >= score_letter_2_left and column <= score_letter_2_right) and Game_Over = '0') then
		  red <= (OTHERS => '0');
        green  <= (OTHERS => '0');
        blue <= (OTHERS => '1');
		
	
		elsif((row >= rightShipRowTop and row <= rightShipRowBottom) and (column >= score_letter_1_left and column <= score_letter_1_right) and Game_Over = '0') then
		  red <= (OTHERS => '0');
        green  <= (OTHERS => '0');
        blue <= (OTHERS => '1');
	
		elsif((row >= rightShipRowTop and row <= rightShipRowBottom) and (column >= score_letter_0_left and column <= score_letter_0_right) and Game_Over = '0' ) then
		  red <= (OTHERS => '0');
        green  <= (OTHERS => '0');
        blue <= (OTHERS => '1');
	
	
	
		--TNTECH ECE
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= T1topStart and column <= T1topEnd)) then 
		  red <= (OTHERS => '0');
        green  <= (OTHERS => '0');
        blue <= (OTHERS => '1');
		--Na	
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= NLtopStart and column <=NLtopEnd)) then
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--Nb
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= NRtopStart and column <= NRtopEnd )) then
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--T2
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= T2topStart and column <= T2topEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--E1
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= E1topStart and column <= E1topEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--C
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= C1topStart and column <= C1topEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--Ha
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= HLtopStart and column <= HLtopEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--Hb
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= HRtopStart and column <= HRtopEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--E2
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= E2topStart and column <= E2topEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--C
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= C2topStart and column <= C2topEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--E3
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= E3topStart and column <= E3topEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
			
		--Row_B -------------------------------------------------------------------------------------------
		--T1
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= T1midStart and column <= T1midEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--Na
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= NLmidStart and column <= NLmidEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--Nmid1
		elsif((row >= row_B_top-3 and row <= row_B_bot-3) and (column >= NLmidEnd and column <= NLmidEnd+3)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--Nmid2
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= NLmidEnd+3 and column <= NLmidEnd+6)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--Nmid3
		elsif((row >= row_B_top+3 and row <= row_B_bot+3) and (column >= NLmidEnd+6 and column <= NLmidEnd+9)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');	
		--Nb
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= NRmidStart and column <= NRmidEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--T2
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= T2midStart and column <= T2midEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--E1
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= E1midStart and column <= E1midStart+9)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--E1mid
		elsif((row > row_B_top and row < row_B_bot) and (column >= E1midStart+9 and column <= E1midEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--C1
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= C1midStart and column <= C1midEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--H
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= HmidStart and column <= HmidEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--E2
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= E2midStart and column <= E2midStart+9)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--E2mid
		elsif((row > row_B_top and row < row_B_bot) and (column >= E2midStart+9 and column <= E2midEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--C2
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= C2midStart and column <= C2midEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--E3
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= E3midStart and column <= E3midStart+9)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--E3mid	
		elsif((row > row_B_top and row < row_B_bot) and (column >= E3midStart+9 and column <= E3midEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');


		-- Row_C -------------------------------------------------------------------------------------------
		--T1
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= T1midStart and column <= T1midEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');	
		--Na
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= NLtopStart and column <= NLtopEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--Nb
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= NRtopStart and column <= NRtopEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--T2
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= T2midStart and column <= T2midEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--E1
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= E1topStart and column <= E1topEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--C1
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= C1topStart and column <= C1topEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');	
		--Ha
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= HLtopStart and column <= HLtopEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--Hb
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= HRtopStart and column <= HRtopEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--E2
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= E2topStart and column <= E2topEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--C2
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= C2topStart and column <= C2topEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
		--E3
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= E3topStart and column <= E3topEnd)) then 
			  red <= (OTHERS => '0');
			  green  <= (OTHERS => '0');
			  blue <= (OTHERS => '1');
	
	
	
	
	
	
	
	
	
	
	
	
		else
        red <= (OTHERS => '0');
        green  <= (OTHERS => '0');
        blue <= (OTHERS => '0');
		end if;
		
	
	
	
	
	
	
		--Lives decrement
	 	if (falling_edge(key) and Game_Over = '0') then
			Lives <= Lives - 1;
		elsif (Lives = 0 and falling_edge(key)) then
			Game_Over <= '1';
		elsif(Game_Over = '1' and falling_edge(key)) then
			Lives <= 3;
			Game_Over <= '0';
		else
			Lives <= Lives;
		end if;
	 
	 --Paused?
		if(SW0 = '1') then
			Paused <= '1';
		else 
			Paused <= '0';
		end if;
	 
	 
    ELSE                           --blanking time
      red <= (OTHERS => '0');
      green <= (OTHERS => '0');
      blue <= (OTHERS => '0');
    END IF;
  END PROCESS;
  
  
END behavior;
