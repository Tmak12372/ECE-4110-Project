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
use ieee.numeric_std.all;

ENTITY hw_image_generator IS
  GENERIC(
    
	topBar : INTEGER := 60;
	line1  : INTEGER := 61;
	line2  : INTEGER := 64;
	line3  : INTEGER := 421;
	line4  : INTEGER := 424;
	playField : INTEGER := 420;
	bottomBar : INTEGER := 480;
	
	leftShipRowTop : INTEGER := 30;
	middleShipRowTop : INTEGER := 30;
	rightShipRowTop : INTEGER := 30;

	leftShipRowBottom : INTEGER := 50;
	middleShipRowBottom : INTEGER := 50;
	rightShipRowBottom : INTEGER := 50;
	
	
	leftShipColumnStart : INTEGER := 30;
	leftShipColumnEnd   : INTEGER := 60;
	middleShipColumnStart : INTEGER := 70;
	middleShipColumnEnd   : INTEGER := 100;
	rightShipColumnStart : INTEGER := 110;
	rightShipColumnEnd   : INTEGER := 140
	
	
	

	);  --:)
  PORT(
    disp_ena :  IN   STD_LOGIC;  --display enable ('1' = display time, '0' = blanking time)
    row      :  IN   INTEGER;    --row pixel coordinate
    column   :  IN   INTEGER;    --column pixel coordinate
    red      :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --red magnitude output to DAC
    green    :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --green magnitude output to DAC
    blue     :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0')); --blue magnitude output to DAC
END hw_image_generator;

ARCHITECTURE behavior OF hw_image_generator IS







Signal ShipLength : INTEGER := 50;






BEGIN
	PROCESS(disp_ena, row, column)
   BEGIN
	IF(disp_ena = '1') THEN        --display time

	 
	 
	 
		--Bottom and top line display
	 	if(row < leftShipRowTop and row > leftShipRowBottom) then
        red <= (OTHERS => '0');
        green  <= (OTHERS => '0');
        blue <= (OTHERS => '0');
		   
		elsif(row >= line1 and row < line2) then
        red <= (OTHERS => '0');
        green  <= (OTHERS => '1');
        blue <= (OTHERS => '0');
		  
		  
		elsif(row >= line3 and row < line4) then
		  red <= (OTHERS => '0');
        green  <= (OTHERS => '1');
        blue <= (OTHERS => '0');
		elsif(row >= playField and row < bottomBar) then
        red <= (OTHERS => '0');
        green  <= (OTHERS => '0');
        blue <= (OTHERS => '0');
		  
		  
		elsif((row >= leftShipRowTop and row <= leftShipRowBottom) and (column >= leftShipColumnStart and column <= leftShipColumnEnd)) then
		  red <= (OTHERS => '0');
        green  <= (OTHERS => '0');
        blue <= (OTHERS => '1');
		
		elsif((row >= middleShipRowTop and row <= middleShipRowBottom) and (column >= middleShipColumnStart and column <= middleShipColumnEnd)) then
		  red <= (OTHERS => '0');
        green  <= (OTHERS => '0');
        blue <= (OTHERS => '1');
		
		elsif((row >= rightShipRowTop and row <= rightShipRowBottom) and (column >= rightShipColumnStart and column <= rightShipColumnEnd)) then
		  red <= (OTHERS => '0');
        green  <= (OTHERS => '0');
        blue <= (OTHERS => '1');
		
		else
        red <= (OTHERS => '0');
        green  <= (OTHERS => '0');
        blue <= (OTHERS => '0');
		end if;
	 
	 
	 
	 
	 
	 
	 
	 
    ELSE                           --blanking time
      red <= (OTHERS => '0');
      green <= (OTHERS => '0');
      blue <= (OTHERS => '0');
    END IF;
  END PROCESS;
END behavior;
