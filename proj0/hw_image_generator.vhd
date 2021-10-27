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
	score_letter_0_right  : INTEGER := 610;
	MainShipLeftLimit     : INTEGER := 0;
	MainShipRightLimit     : INTEGER := 320;
	MainShipColumnStart : INTEGER := 30;
	MainShipColumnEnd   : INTEGER := 60
	
	
	);  --:)
  PORT(
	 directionx : in std_logic;
	 directiony : in std_logic;
	 enable  : in std_logic;
    SW0    :  IN   STD_LOGIC;
    key      :  IN   STD_LOGIC;
    disp_ena :  IN   STD_LOGIC;  --display enable ('1' = display time, '0' = blanking time)
    row      :  IN   INTEGER;    --row pixel coordinate
    column   :  IN   INTEGER;    --column pixel coordinate
    red      :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --red magnitude OUTput to DAC
    green    :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --green magnitude OUTput to DAC
    blue     :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0'); --blue magnitude OUTput to DAC
	 mainClock:	IN	 STD_LOGIC;
	 data_x      : BUFFER STD_LOGIC_VECTOR(15 DOWNTO 0);
	 data_y      : BUFFER STD_LOGIC_VECTOR(15 DOWNTO 0);
	 data_z      : BUFFER STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END hw_image_generator;

ARCHITECTURE behavior OF hw_image_generator IS


COMPONENT Bin2BCD_6Digits IS
	PORT( binIn : IN std_logic_vector(7 DOWNTO 0);
		  bcd5  : OUT std_logic_vector(3 DOWNTO 0); --left most bit of score
		  bcd4  : OUT std_logic_vector(3 DOWNTO 0); 
		  bcd3  : OUT std_logic_vector(3 DOWNTO 0);
		  bcd2  : OUT std_logic_vector(3 DOWNTO 0);
		  bcd1  : OUT std_logic_vector(3 DOWNTO 0);
		  bcd0  : OUT std_logic_vector(3 DOWNTO 0)); --right most bit of score
END COMPONENT;

	
SIGNAL shipPOS_HOR : INTEGER := 180;
SIGNAL shipPOS_VER : INTEGER := 180;	
SIGNAL Lives : INTEGER := 3;
SIGNAL Score_count : std_logic_vector(7 DOWNTO 0);
SIGNAL bcd_score5, bcd_score4, bcd_score3, bcd_score2, bcd_score1, bcd_score0 : std_logic_vector(3 DOWNTO 0);
SIGNAL Game_Over, Paused : std_logic := '0';
SIGNAL s_char_2       : std_logic_vector(6 DOWNTO 0);
SIGNAL s_score_digit_row 			  : std_logic_vector(3 DOWNTO 0);
SIGNAL s_score_digit_column 		  : std_logic_vector(3 DOWNTO 0);
SIGNAL clockSlow : STD_LOGIC;
SIGNAL ShipMoveSpeed : integer;

BEGIN
	
	PROCESS(disp_ena, row, column, Lives)
	
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
	
	VARIABLE col_val, row_val, redVal, greenVal, blueVal : INTEGER ;
	
	VARIABLE shipLen : INTEGER := 30;
	
	
   BEGIN
	

	
		--Top line display
		if(row >= Top_Line_Top_Row and row < Top_Line_Bottom_Row) then
			redVal := 0;
			greenVal := 0;
			blueVal := 0;
		--Bottom line display  
		elsif(row >= Bottom_Line_Top_Row and row < Bottom_Line_Bottom_Row ) then
			redVal := 0;
			greenVal := 0;
			blueVal := 0;
		  
		--Last Ship Live  
		elsif((row >= leftShipRowTop and row <= (leftShipRowBottom-29)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-29)) and (Lives > 0)) then
		  	redVal := 15;
        	greenVal := 0;
        	blueVal := 0;	
		elsif((row >= (leftShipRowTop+1) and row <= (leftShipRowBottom-28)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-28)) and (Lives > 0)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (leftShipRowTop+2) and row <= (leftShipRowBottom-27)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-27)) and (Lives > 0)) then
		 	redVal := 15;
        	greenVal := 0;
        	blueVal := 0;	
		elsif((row >= (leftShipRowTop+3) and row <= (leftShipRowBottom-26)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-26)) and (Lives > 0)) then
			redVal := 15;
        	greenVal := 0;
        	blueVal := 0;
		elsif((row >= (leftShipRowTop+4) and row <= (leftShipRowBottom-25)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-25)) and (Lives > 0)) then
			redVal := 15;
        	greenVal := 0;
        	blueVal := 0;	
		elsif((row >= (leftShipRowTop+5) and row <= (leftShipRowBottom-24)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-24)) and (Lives > 0)) then
			redVal := 15;
        	greenVal := 0;
        	blueVal := 0;	
		elsif((row >= (leftShipRowTop+6) and row <= (leftShipRowBottom-23)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-23)) and (Lives > 0)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (leftShipRowTop+7) and row <= (leftShipRowBottom-22)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-22)) and (Lives > 0)) then
		    redVal := 15;
        	greenVal := 0;
        	blueVal := 0;	
		elsif((row >= (leftShipRowTop+8) and row <= (leftShipRowBottom-21)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-21)) and (Lives > 0)) then
		    redVal := 15;
        	greenVal := 0;
        	blueVal := 0;	
		elsif((row >= (leftShipRowTop+9) and row <= (leftShipRowBottom-20)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-20)) and (Lives > 0)) then
		    redVal := 15;
        	greenVal := 0;
        	blueVal := 0;		  
		elsif((row >= (leftShipRowTop+10) and row <= (leftShipRowBottom-19)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-19)) and (Lives > 0)) then
		    redVal := 15;
        	greenVal := 0;
        	blueVal := 0;	
		elsif((row >= (leftShipRowTop+11) and row <= (leftShipRowBottom-18)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-18)) and (Lives > 0)) then
			redVal := 15;
        	greenVal := 0;
        	blueVal := 0;	
		elsif((row >= (leftShipRowTop+12) and row <= (leftShipRowBottom-17)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-17)) and (Lives > 0)) then
		    redVal := 15;
        	greenVal := 0;
        	blueVal := 0;
		elsif((row >= (leftShipRowTop+13) and row <= (leftShipRowBottom-16)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-16)) and (Lives > 0)) then
		    redVal := 15;
        	greenVal := 0;
        	blueVal := 0;	
		elsif((row >= (leftShipRowTop+14) and row <= (leftShipRowBottom-15)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-15)) and (Lives > 0)) then
		    redVal := 15;
        	greenVal := 0;
        	blueVal := 0;	
		elsif((row >= (leftShipRowTop+15) and row <= (leftShipRowBottom-14)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-14)) and (Lives > 0)) then
		    redVal := 15;
        	greenVal := 0;
        	blueVal := 0;		  
		elsif((row >= (leftShipRowTop+16) and row <= (leftShipRowBottom-13)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-13)) and (Lives > 0)) then
		    redVal := 15;
        	greenVal := 0;
        	blueVal := 0;	
		elsif((row >= (leftShipRowTop+17) and row <= (leftShipRowBottom-12)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-12)) and (Lives > 0)) then
		    redVal := 15;
        	greenVal := 0;
        	blueVal := 0;	
		elsif((row >= (leftShipRowTop+18) and row <= (leftShipRowBottom-11)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-11)) and (Lives > 0)) then
		    redVal := 15;
        	greenVal := 0;
        	blueVal := 0;
		elsif((row >= (leftShipRowTop+19) and row <= (leftShipRowBottom-10)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-10)) and (Lives > 0)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (leftShipRowTop+20) and row <= (leftShipRowBottom-9)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-9)) and (Lives > 0)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (leftShipRowTop+21) and row <= (leftShipRowBottom-8)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-8)) and (Lives > 0)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (leftShipRowTop+22) and row <= (leftShipRowBottom-7)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-7)) and (Lives > 0)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (leftShipRowTop+23) and row <= (leftShipRowBottom-6)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-6)) and (Lives > 0)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (leftShipRowTop+24) and row <= (leftShipRowBottom-5)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-5)) and (Lives > 0)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (leftShipRowTop+25) and row <= (leftShipRowBottom-4)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-4)) and (Lives > 0)) then
		    redVal := 15;
        	greenVal := 0;
        	blueVal := 0;  
		elsif((row >= (leftShipRowTop+26) and row <= (leftShipRowBottom-3)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-3)) and (Lives > 0)) then
		    redVal := 15;
        	greenVal := 0;
        	blueVal := 0;	
		elsif((row >= (leftShipRowTop+27) and row <= (leftShipRowBottom-2)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-2)) and (Lives > 0)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (leftShipRowTop+28) and row <= (leftShipRowBottom-1)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd-1)) and (Lives > 0)) then
		    redVal := 15;
        	greenVal := 0;
        	blueVal := 0;	
		elsif((row >= (leftShipRowTop+29) and row <= (leftShipRowBottom)) and (column >= leftShipColumnStart and column <= (leftShipColumnEnd)) and (Lives > 0)) then
		    redVal := 15;
        	greenVal := 0;
        	blueVal := 0;		  
		  
		--Middle Ship Live 
		elsif((row >= middleShipRowTop and row <= (middleShipRowBottom-29)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-29)) and (Lives >= 2)) then
		    redVal := 15;
        	greenVal := 0;
        	blueVal := 0;	
		elsif((row >= (middleShipRowTop+1) and row <= (middleShipRowBottom-28)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-28)) and (Lives >= 2)) then
		    redVal := 15;
        	greenVal := 0;
        	blueVal := 0;	
		elsif((row >= (middleShipRowTop+2) and row <= (middleShipRowBottom-27)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-27)) and (Lives >= 2)) then
		    redVal := 15;
        	greenVal := 0;
        	blueVal := 0;	
		elsif((row >= (middleShipRowTop+3) and row <= (middleShipRowBottom-26)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-26)) and (Lives >= 2)) then
		    redVal := 15;
        	greenVal := 0;
        	blueVal := 0;
		elsif((row >= (middleShipRowTop+4) and row <= (middleShipRowBottom-25)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-25)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (middleShipRowTop+5) and row <= (middleShipRowBottom-24)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-24)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (middleShipRowTop+6) and row <= (middleShipRowBottom-23)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-23)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (middleShipRowTop+7) and row <= (middleShipRowBottom-22)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-22)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (middleShipRowTop+8) and row <= (middleShipRowBottom-21)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-21)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (middleShipRowTop+9) and row <= (middleShipRowBottom-20)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-20)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;		  
		elsif((row >= (middleShipRowTop+10) and row <= (middleShipRowBottom-19)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-19)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (middleShipRowTop+11) and row <= (middleShipRowBottom-18)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-18)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (middleShipRowTop+12) and row <= (middleShipRowBottom-17)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-17)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (middleShipRowTop+13) and row <= (middleShipRowBottom-16)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-16)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (middleShipRowTop+14) and row <= (middleShipRowBottom-15)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-15)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (middleShipRowTop+15) and row <= (middleShipRowBottom-14)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-14)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;		  
		elsif((row >= (middleShipRowTop+16) and row <= (middleShipRowBottom-13)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-13)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (middleShipRowTop+17) and row <= (middleShipRowBottom-12)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-12)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (middleShipRowTop+18) and row <= (middleShipRowBottom-11)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-11)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (middleShipRowTop+19) and row <= (middleShipRowBottom-10)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-10)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (middleShipRowTop+20) and row <= (middleShipRowBottom-9)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-9)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (middleShipRowTop+21) and row <= (middleShipRowBottom-8)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-8)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (middleShipRowTop+22) and row <= (middleShipRowBottom-7)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-7)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (middleShipRowTop+23) and row <= (middleShipRowBottom-6)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-6)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (middleShipRowTop+24) and row <= (middleShipRowBottom-5)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-5)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (middleShipRowTop+25) and row <= (middleShipRowBottom-4)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-4)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;  
		elsif((row >= (middleShipRowTop+26) and row <= (middleShipRowBottom-3)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-3)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (middleShipRowTop+27) and row <= (middleShipRowBottom-2)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-2)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (middleShipRowTop+28) and row <= (middleShipRowBottom-1)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd-1)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (middleShipRowTop+29) and row <= (middleShipRowBottom)) and (column >= middleShipColumnStart and column <= (middleShipColumnEnd)) and (Lives >= 2)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		  
		--Full Lives
		elsif((row >= rightShipRowTop and row <= (rightShipRowBottom-29)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-29)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (rightShipRowTop+1) and row <= (rightShipRowBottom-28)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-28)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (rightShipRowTop+2) and row <= (rightShipRowBottom-27)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-27)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (rightShipRowTop+3) and row <= (rightShipRowBottom-26)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-26)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (rightShipRowTop+4) and row <= (rightShipRowBottom-25)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-25)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (rightShipRowTop+5) and row <= (rightShipRowBottom-24)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-24)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (rightShipRowTop+6) and row <= (rightShipRowBottom-23)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-23)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (rightShipRowTop+7) and row <= (rightShipRowBottom-22)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-22)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (rightShipRowTop+8) and row <= (rightShipRowBottom-21)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-21)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (rightShipRowTop+9) and row <= (rightShipRowBottom-20)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-20)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;		  
		elsif((row >= (rightShipRowTop+10) and row <= (rightShipRowBottom-19)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-19)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (rightShipRowTop+11) and row <= (rightShipRowBottom-18)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-18)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (rightShipRowTop+12) and row <= (rightShipRowBottom-17)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-17)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (rightShipRowTop+13) and row <= (rightShipRowBottom-16)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-16)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (rightShipRowTop+14) and row <= (rightShipRowBottom-15)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-15)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (rightShipRowTop+15) and row <= (rightShipRowBottom-14)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-14)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;		  
		elsif((row >= (rightShipRowTop+16) and row <= (rightShipRowBottom-13)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-13)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (rightShipRowTop+17) and row <= (rightShipRowBottom-12)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-12)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (rightShipRowTop+18) and row <= (rightShipRowBottom-11)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-11)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (rightShipRowTop+19) and row <= (rightShipRowBottom-10)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-10)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (rightShipRowTop+20) and row <= (rightShipRowBottom-9)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-9)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (rightShipRowTop+21) and row <= (rightShipRowBottom-8)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-8)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (rightShipRowTop+22) and row <= (rightShipRowBottom-7)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-7)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (rightShipRowTop+23) and row <= (rightShipRowBottom-6)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-6)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (rightShipRowTop+24) and row <= (rightShipRowBottom-5)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-5)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (rightShipRowTop+25) and row <= (rightShipRowBottom-4)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-4)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;  
		elsif((row >= (rightShipRowTop+26) and row <= (rightShipRowBottom-3)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-3)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (rightShipRowTop+27) and row <= (rightShipRowBottom-2)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-2)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (rightShipRowTop+28) and row <= (rightShipRowBottom-1)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd-1)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (rightShipRowTop+29) and row <= (rightShipRowBottom)) and (column >= rightShipColumnStart and column <= (rightShipColumnEnd)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		  
		  
		
		--TNTECH ECE
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= T1topStart and column <= T1topEnd)) then 
		    redVal := 0;
        	greenVal := 0;
        	blueVal := 15;
		--Na	
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= NLtopStart and column <=NLtopEnd)) then
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--Nb
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= NRtopStart and column <= NRtopEnd )) then
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--T2
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= T2topStart and column <= T2topEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--E1
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= E1topStart and column <= E1topEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--C
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= C1topStart and column <= C1topEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--Ha
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= HLtopStart and column <= HLtopEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--Hb
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= HRtopStart and column <= HRtopEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--E2
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= E2topStart and column <= E2topEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--C
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= C2topStart and column <= C2topEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--E3
		elsif((row >= row_A_top and row <= row_A_bot) and (column >= E3topStart and column <= E3topEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
			
		--Row_B -------------------------------------------------------------------------------------------
		--T1
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= T1midStart and column <= T1midEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--Na
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= NLmidStart and column <= NLmidEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--Nmid1
		elsif((row >= row_B_top-3 and row <= row_B_bot-3) and (column >= NLmidEnd and column <= NLmidEnd+3)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--Nmid2
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= NLmidEnd+3 and column <= NLmidEnd+6)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--Nmid3
		elsif((row >= row_B_top+3 and row <= row_B_bot+3) and (column >= NLmidEnd+6 and column <= NLmidEnd+9)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;	
		--Nb
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= NRmidStart and column <= NRmidEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--T2
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= T2midStart and column <= T2midEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--E1
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= E1midStart and column <= E1midStart+9)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--E1mid
		elsif((row > row_B_top and row < row_B_bot) and (column >= E1midStart+9 and column <= E1midEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--C1
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= C1midStart and column <= C1midEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--H
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= HmidStart and column <= HmidEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--E2
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= E2midStart and column <= E2midStart+9)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--E2mid
		elsif((row > row_B_top and row < row_B_bot) and (column >= E2midStart+9 and column <= E2midEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--C2
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= C2midStart and column <= C2midEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--E3
		elsif((row >= row_B_top and row <= row_B_bot) and (column >= E3midStart and column <= E3midStart+9)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--E3mid	
		elsif((row > row_B_top and row < row_B_bot) and (column >= E3midStart+9 and column <= E3midEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;


		-- Row_C -------------------------------------------------------------------------------------------
		--T1
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= T1midStart and column <= T1midEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;	
		--Na
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= NLtopStart and column <= NLtopEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--Nb
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= NRtopStart and column <= NRtopEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--T2
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= T2midStart and column <= T2midEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--E1
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= E1topStart and column <= E1topEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--C1
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= C1topStart and column <= C1topEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;	
		--Ha
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= HLtopStart and column <= HLtopEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--Hb
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= HRtopStart and column <= HRtopEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--E2
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= E2topStart and column <= E2topEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--C2
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= C2topStart and column <= C2topEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;
		--E3
		elsif((row >= row_C_top and row <= row_C_bot) and (column >= E3topStart and column <= E3topEnd)) then 
			redVal := 0;
			greenVal := 0;
			blueVal := 15;	  
			    
				 
		
		elsif((row >= shipPOS_VER and row <= (shipPOS_VER + shipLen -29)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-29)) and (Lives = 3)) then
			redVal := 15;
        	greenVal := 0;
        	blueVal := 0;	
		elsif((row >= (shipPOS_VER+1) and row <= (shipPOS_VER + shipLen -28)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-28) )and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (shipPOS_VER+2) and row <= (shipPOS_VER + shipLen -27)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-27)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (shipPOS_VER+3) and row <= (shipPOS_VER + shipLen -26)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-26)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (shipPOS_VER+4) and row <= (shipPOS_VER + shipLen -25)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-25)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (shipPOS_VER+5) and row <= (shipPOS_VER + shipLen -24)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-24)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (shipPOS_VER+6) and row <= (shipPOS_VER + shipLen -23)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-23)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (shipPOS_VER+7) and row <= (shipPOS_VER + shipLen -22)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-22)) and (Lives = 3)) then
		    redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (shipPOS_VER+8) and row <= (shipPOS_VER + shipLen -21)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-21)) and (Lives = 3)) then
		  	redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (shipPOS_VER+9) and row <= (shipPOS_VER + shipLen -20)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-20)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;		  
		elsif((row >= (shipPOS_VER+10) and row <= (shipPOS_VER + shipLen -19)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-19)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (shipPOS_VER+11) and row <= (shipPOS_VER + shipLen -18)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-18 )) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (shipPOS_VER+12) and row <= (shipPOS_VER + shipLen -17)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-17)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (shipPOS_VER+13) and row <= (shipPOS_VER + shipLen -16)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-16)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (shipPOS_VER+14) and row <= (shipPOS_VER + shipLen -15)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-15)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (shipPOS_VER+15) and row <= (shipPOS_VER + shipLen -14)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-14)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;		  
		elsif((row >= (shipPOS_VER+16) and row <= (shipPOS_VER + shipLen -13)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-13)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (shipPOS_VER+17) and row <= (shipPOS_VER + shipLen -12)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-12)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (shipPOS_VER+18) and row <= (shipPOS_VER + shipLen -11)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-11)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (shipPOS_VER+19) and row <= (shipPOS_VER + shipLen -10)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-10)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (shipPOS_VER+20) and row <= (shipPOS_VER + shipLen -9)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-9)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (shipPOS_VER+21) and row <= (shipPOS_VER + shipLen -8)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-8)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (shipPOS_VER+22) and row <= (shipPOS_VER + shipLen -7)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-7)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (shipPOS_VER+23) and row <= (shipPOS_VER + shipLen -6)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-6)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (shipPOS_VER+24) and row <= (shipPOS_VER + shipLen -5)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-5)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (shipPOS_VER+25) and row <= (shipPOS_VER + shipLen -4)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-4)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;  
		elsif((row >= (shipPOS_VER+26) and row <= (shipPOS_VER + shipLen -3)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-3)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (shipPOS_VER+27) and row <= (shipPOS_VER + shipLen -2)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-2)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;
		elsif((row >= (shipPOS_VER+28) and row <= (shipPOS_VER + shipLen -1)) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen-1)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;	
		elsif((row >= (shipPOS_VER+29) and row <= (shipPOS_VER + shipLen )) and (column >= (shipPOS_HOR) and column <= (shipPOS_HOR + shipLen)) and (Lives = 3)) then
			redVal := 15;
			greenVal := 0;
			blueVal := 0;				 
			 
		else 	 
			redVal := 15;
			greenVal := 15;
			blueVal := 15;
		end if;
	
	
		IF(disp_ena = '1') THEN        --display time
			red <= std_logic_vector(to_unsigned(redVal, red'length));
			green <= std_logic_vector(to_unsigned(greenVal, green'length));
			blue <= std_logic_vector(to_unsigned(blueVal, blue'length));
		ELSE                           --blanking time
			red <= (OTHERS => '0');
			green <= (OTHERS => '0');
			blue <= (OTHERS => '0');
    	END IF;
  END PROCESS;
	
  
  
  --Moves the ship left and right
	process(directionx,mainClock,shipPOS_HOR)
	variable counter : integer := 0;
	variable hor_position : integer := 180;
	begin
		if(Paused = '0' and enable = '1') then
			if(mainClock = '1' and mainClock'event) then
				counter := counter + 1;
				if (counter > 3000000 and Paused = '0') then
					if (clockSlow = '1') then
						clockSlow <= '0';
					else
						clockSlow <= '1';
					end if;
					
					if (directionx = '1') then 
						if ((hor_position + 1) /= 0) then
							hor_position := hor_position - 1;
						end if;
					elsif (directionx = '0') then
						if ((hor_position + 30) /= 320) then
							hor_position := hor_position + 1;
						end if;
					end if;
		
				shipPOS_HOR <= hor_position;
				counter := 0 ;
            end if;
        end if;
	end if;
	end process;
  
  
	--Moves the ship up and down
	process(directiony,mainClock,shipPOS_VER)
	variable dcounter : integer := 0;
	variable ver_position : integer := 180;
	begin
		if(Paused = '0' and enable = '1') then
			if(mainClock = '1' and mainClock'event) then
				dcounter := dcounter + 1;
				if (dcounter > 3000000 and Paused = '0') then
					if (directiony = '1') then 
						if ((ver_position) /= 64) then
							ver_position := ver_position - 1;
						end if;
					elsif (directiony = '0') then
						if ((ver_position+30) /= 421) then
							ver_position := ver_position + 1;
						end if;
					end if;
		
				shipPOS_VER <= ver_position;
				dcounter := 0 ;
            end if;
        end if;
	end if;
	end process;
  
  
  	--Does the pausing logic
	process(mainClock,key,Game_Over,SW0)
	begin
	if(RISING_EDGE(SW0)) then
		case Paused is
			when '1'  => Paused <= '0';
			when '0'  => Paused <= '1';
		end case;
	end if;
	
		--Lives decrement
	if (falling_edge(key) and Game_Over = '0' and Paused = '0') then
		Lives <= Lives - 1;
	elsif (Lives = 0 and falling_edge(key)) then
		Game_Over <= '1';
	elsif(Game_Over = '1' and falling_edge(key)) then
		Lives <= 3;
		Game_Over <= '0';
	else
		Lives <= Lives;
	end if;
	
	end process;
  
END behavior;
