-- font: Renders a 10x15 bitmap font stored in ROM
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity alphabetical_font is
    generic(
        g_num_chars : integer := 26;
        g_width : integer := 8;
        g_height : integer := 16

    );
    port (
        -- Value of the char
        i_value : in integer;

        -- Pixel index for the character
        i_row : in integer; -- 0 to height-1
        i_column : in integer; -- 0 to width-1

        o_draw : out std_logic
    );
end entity alphabetical_font;

architecture rtl of alphabetical_font is
    -- Types
    type t_rom is array (0 to g_num_chars*g_height - 1) of std_logic_vector(0 to g_width-1);

    -- Signals

    -- Source: https://github.com/MadLittleMods/FP-V-GA-Text/blob/master/vgaText/fontROM.vhd
    constant r_font : t_rom := (
      -- A: code x41
		"00000000", -- 0
		"00000000", -- 1
		"00010000", -- 2    *
		"00111000", -- 3   ***
		"01101100", -- 4  ** **
		"11000110", -- 5 **   **
		"11000110", -- 6 **   **
		"11111110", -- 7 *******
		"11000110", -- 8 **   **
		"11000110", -- 9 **   **
		"11000110", -- a **   **
		"11000110", -- b **   **
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- B: code x42
		"00000000", -- 0
		"00000000", -- 1
		"11111100", -- 2 ******
		"01100110", -- 3  **  **
		"01100110", -- 4  **  **
		"01100110", -- 5  **  **
		"01111100", -- 6  *****
		"01100110", -- 7  **  **
		"01100110", -- 8  **  **
		"01100110", -- 9  **  **
		"01100110", -- a  **  **
		"11111100", -- b ******
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- C: code x43
		"00000000", -- 0
		"00000000", -- 1
		"00111100", -- 2   ****
		"01100110", -- 3  **  **
		"11000010", -- 4 **    *
		"11000000", -- 5 **
		"11000000", -- 6 **
		"11000000", -- 7 **
		"11000000", -- 8 **
		"11000010", -- 9 **    *
		"01100110", -- a  **  **
		"00111100", -- b   ****
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- D: code x44
		"00000000", -- 0
		"00000000", -- 1
		"11111000", -- 2 *****
		"01101100", -- 3  ** **
		"01100110", -- 4  **  **
		"01100110", -- 5  **  **
		"01100110", -- 6  **  **
		"01100110", -- 7  **  **
		"01100110", -- 8  **  **
		"01100110", -- 9  **  **
		"01101100", -- a  ** **
		"11111000", -- b *****
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- code x45
		"00000000", -- 0
		"00000000", -- 1
		"11111110", -- 2 *******
		"01100110", -- 3  **  **
		"01100010", -- 4  **   *
		"01101000", -- 5  ** *
		"01111000", -- 6  ****
		"01101000", -- 7  ** *
		"01100000", -- 8  **
		"01100010", -- 9  **   *
		"01100110", -- a  **  **
		"11111110", -- b *******
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- code x46
		"00000000", -- 0
		"00000000", -- 1
		"11111110", -- 2 *******
		"01100110", -- 3  **  **
		"01100010", -- 4  **   *
		"01101000", -- 5  ** *
		"01111000", -- 6  ****
		"01101000", -- 7  ** *
		"01100000", -- 8  **
		"01100000", -- 9  **
		"01100000", -- a  **
		"11110000", -- b ****
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- code x47
		"00000000", -- 0
		"00000000", -- 1
		"00111100", -- 2   ****
		"01100110", -- 3  **  **
		"11000010", -- 4 **    *
		"11000000", -- 5 **
		"11000000", -- 6 **
		"11011110", -- 7 ** ****
		"11000110", -- 8 **   **
		"11000110", -- 9 **   **
		"01100110", -- a  **  **
		"00111010", -- b   *** *
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- H: code x48
		"00000000", -- 0
		"00000000", -- 1
		"11000110", -- 2 **   **
		"11000110", -- 3 **   **
		"11000110", -- 4 **   **
		"11000110", -- 5 **   **
		"11111110", -- 6 *******
		"11000110", -- 7 **   **
		"11000110", -- 8 **   **
		"11000110", -- 9 **   **
		"11000110", -- a **   **
		"11000110", -- b **   **
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- I: code x49
		"00000000", -- 0
		"00000000", -- 1
		"00111100", -- 2   ****
		"00011000", -- 3    **
		"00011000", -- 4    **
		"00011000", -- 5    **
		"00011000", -- 6    **
		"00011000", -- 7    **
		"00011000", -- 8    **
		"00011000", -- 9    **
		"00011000", -- a    **
		"00111100", -- b   ****
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- J: code x4a
		"00000000", -- 0
		"00000000", -- 1
		"00011110", -- 2    ****
		"00001100", -- 3     **
		"00001100", -- 4     **
		"00001100", -- 5     **
		"00001100", -- 6     **
		"00001100", -- 7     **
		"11001100", -- 8 **  **
		"11001100", -- 9 **  **
		"11001100", -- a **  **
		"01111000", -- b  ****
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- K: code x4b
		"00000000", -- 0
		"00000000", -- 1
		"11100110", -- 2 ***  **
		"01100110", -- 3  **  **
		"01100110", -- 4  **  **
		"01101100", -- 5  ** **
		"01111000", -- 6  ****
		"01111000", -- 7  ****
		"01101100", -- 8  ** **
		"01100110", -- 9  **  **
		"01100110", -- a  **  **
		"11100110", -- b ***  **
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- L: code x4c
		"00000000", -- 0
		"00000000", -- 1
		"11110000", -- 2 ****
		"01100000", -- 3  **
		"01100000", -- 4  **
		"01100000", -- 5  **
		"01100000", -- 6  **
		"01100000", -- 7  **
		"01100000", -- 8  **
		"01100010", -- 9  **   *
		"01100110", -- a  **  **
		"11111110", -- b *******
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- M: code x4d
		"00000000", -- 0
		"00000000", -- 1
		"11000011", -- 2 **    **
		"11100111", -- 3 ***  ***
		"11111111", -- 4 ********
		"11111111", -- 5 ********
		"11011011", -- 6 ** ** **
		"11000011", -- 7 **    **
		"11000011", -- 8 **    **
		"11000011", -- 9 **    **
		"11000011", -- a **    **
		"11000011", -- b **    **
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- N: code x4e
		"00000000", -- 0
		"00000000", -- 1
		"11000110", -- 2 **   **
		"11100110", -- 3 ***  **
		"11110110", -- 4 **** **
		"11111110", -- 5 *******
		"11011110", -- 6 ** ****
		"11001110", -- 7 **  ***
		"11000110", -- 8 **   **
		"11000110", -- 9 **   **
		"11000110", -- a **   **
		"11000110", -- b **   **
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- O: code x4f
		"00000000", -- 0
		"00000000", -- 1
		"01111100", -- 2  *****
		"11000110", -- 3 **   **
		"11000110", -- 4 **   **
		"11000110", -- 5 **   **
		"11000110", -- 6 **   **
		"11000110", -- 7 **   **
		"11000110", -- 8 **   **
		"11000110", -- 9 **   **
		"11000110", -- a **   **
		"01111100", -- b  *****
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- P: code x50
		"00000000", -- 0
		"00000000", -- 1
		"11111100", -- 2 ******
		"01100110", -- 3  **  **
		"01100110", -- 4  **  **
		"01100110", -- 5  **  **
		"01111100", -- 6  *****
		"01100000", -- 7  **
		"01100000", -- 8  **
		"01100000", -- 9  **
		"01100000", -- a  **
		"11110000", -- b ****
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- Q: code x510
		"00000000", -- 0
		"00000000", -- 1
		"01111100", -- 2  *****
		"11000110", -- 3 **   **
		"11000110", -- 4 **   **
		"11000110", -- 5 **   **
		"11000110", -- 6 **   **
		"11000110", -- 7 **   **
		"11000110", -- 8 **   **
		"11010110", -- 9 ** * **
		"11011110", -- a ** ****
		"01111100", -- b  *****
		"00001100", -- c     **
		"00001110", -- d     ***
		"00000000", -- e
		"00000000", -- f
		-- code x52
		"00000000", -- 0
		"00000000", -- 1
		"11111100", -- 2 ******
		"01100110", -- 3  **  **
		"01100110", -- 4  **  **
		"01100110", -- 5  **  **
		"01111100", -- 6  *****
		"01101100", -- 7  ** **
		"01100110", -- 8  **  **
		"01100110", -- 9  **  **
		"01100110", -- a  **  **
		"11100110", -- b ***  **
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- code x53
		"00000000", -- 0
		"00000000", -- 1
		"01111100", -- 2  *****
		"11000110", -- 3 **   **
		"11000110", -- 4 **   **
		"01100000", -- 5  **
		"00111000", -- 6   ***
		"00001100", -- 7     **
		"00000110", -- 8      **
		"11000110", -- 9 **   **
		"11000110", -- a **   **
		"01111100", -- b  *****
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- code x54
		"00000000", -- 0
		"00000000", -- 1
		"11111111", -- 2 ********
		"11011011", -- 3 ** ** **
		"10011001", -- 4 *  **  *
		"00011000", -- 5    **
		"00011000", -- 6    **
		"00011000", -- 7    **
		"00011000", -- 8    **
		"00011000", -- 9    **
		"00011000", -- a    **
		"00111100", -- b   ****
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- code x55
		"00000000", -- 0
		"00000000", -- 1
		"11000110", -- 2 **   **
		"11000110", -- 3 **   **
		"11000110", -- 4 **   **
		"11000110", -- 5 **   **
		"11000110", -- 6 **   **
		"11000110", -- 7 **   **
		"11000110", -- 8 **   **
		"11000110", -- 9 **   **
		"11000110", -- a **   **
		"01111100", -- b  *****
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- code x56
		"00000000", -- 0
		"00000000", -- 1
		"11000011", -- 2 **    **
		"11000011", -- 3 **    **
		"11000011", -- 4 **    **
		"11000011", -- 5 **    **
		"11000011", -- 6 **    **
		"11000011", -- 7 **    **
		"11000011", -- 8 **    **
		"01100110", -- 9  **  **
		"00111100", -- a   ****
		"00011000", -- b    **
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- code x57
		"00000000", -- 0
		"00000000", -- 1
		"11000011", -- 2 **    **
		"11000011", -- 3 **    **
		"11000011", -- 4 **    **
		"11000011", -- 5 **    **
		"11000011", -- 6 **    **
		"11011011", -- 7 ** ** **
		"11011011", -- 8 ** ** **
		"11111111", -- 9 ********
		"01100110", -- a  **  **
		"01100110", -- b  **  **
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f

		-- code x58
		"00000000", -- 0
		"00000000", -- 1
		"11000011", -- 2 **    **
		"11000011", -- 3 **    **
		"01100110", -- 4  **  **
		"00111100", -- 5   ****
		"00011000", -- 6    **
		"00011000", -- 7    **
		"00111100", -- 8   ****
		"01100110", -- 9  **  **
		"11000011", -- a **    **
		"11000011", -- b **    **
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- code x59
		"00000000", -- 0
		"00000000", -- 1
		"11000011", -- 2 **    **
		"11000011", -- 3 **    **
		"11000011", -- 4 **    **
		"01100110", -- 5  **  **
		"00111100", -- 6   ****
		"00011000", -- 7    **
		"00011000", -- 8    **
		"00011000", -- 9    **
		"00011000", -- a    **
		"00111100", -- b   ****
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000", -- f
		-- code x5a
		"00000000", -- 0
		"00000000", -- 1
		"11111111", -- 2 ********
		"11000011", -- 3 **    **
		"10000110", -- 4 *    **
		"00001100", -- 5     **
		"00011000", -- 6    **
		"00110000", -- 7   **
		"01100000", -- 8  **
		"11000001", -- 9 **     *
		"11000011", -- a **    **
		"11111111", -- b ********
		"00000000", -- c
		"00000000", -- d
		"00000000", -- e
		"00000000" -- f
    );
begin
    
    -- Lookup the requested bit
    o_draw <= r_font(i_value*g_height + i_row)(i_column);
    
end architecture rtl;