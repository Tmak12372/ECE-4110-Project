-- hud (heads-up display): Logic and graphics generation
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity hud is
    generic (
        g_screen_width : integer := 640;
        g_screen_height : integer := 480;

        -- Colors
        g_bar_color : integer := 16#000#;
        g_ship_color : integer := 16#F00#;
        g_score_color : integer := 16#000#;
        g_logo_color : integer := 16#00F#;

        

        g_ship_width : integer := 30;
        g_ship_height : integer := 20;

        g_max_score : integer := 999999
        

    );
    port (
        i_clock : in std_logic;
        i_update_pulse : in std_logic;

        i_row : in integer;
        i_column : in integer;

        -- Game status
        i_num_lives : integer range 0 to 5;
        i_score : integer;

        o_color : out integer range 0 to 4095;
        o_draw : out std_logic
    );
end entity hud;

architecture rtl of hud is
    -- Constants

    -- Position and size of elements
    constant c_bar_height : integer := 3;
    constant c_upper_bar_pos : integer := 30 - c_bar_height;
    constant c_lower_bar_pos : integer := g_screen_height - 30;
	 
    constant c_ship_spacing_x : integer := 10;
    constant c_ship_pos_y   : integer := c_upper_bar_pos/2 - g_ship_height/2;
    constant c_ship_pos_x1  : integer := 20;
    constant c_ship_pos_x2  : integer := c_ship_pos_x1 + 1*(g_ship_width + c_ship_spacing_x);
    constant c_ship_pos_x3  : integer := c_ship_pos_x1 + 2*(g_ship_width + c_ship_spacing_x);
    constant c_ship_pos_x4  : integer := c_ship_pos_x1 + 3*(g_ship_width + c_ship_spacing_x);
    constant c_ship_pos_x5  : integer := c_ship_pos_x1 + 4*(g_ship_width + c_ship_spacing_x);

    constant c_char_width   : integer := 8;
    constant c_char_height  : integer := 16;
    constant c_char_spacing : integer := 0;
    constant c_score_pos_x1 : integer := g_screen_width - 6*(c_char_width + c_char_spacing) - 5;
    constant c_score_pos_x2 : integer := c_score_pos_x1 + 1*(c_char_width + c_char_spacing);
    constant c_score_pos_x3 : integer := c_score_pos_x1 + 2*(c_char_width + c_char_spacing);
    constant c_score_pos_x4 : integer := c_score_pos_x1 + 3*(c_char_width + c_char_spacing);
    constant c_score_pos_x5 : integer := c_score_pos_x1 + 4*(c_char_width + c_char_spacing);
    constant c_score_pos_x6 : integer := c_score_pos_x1 + 5*(c_char_width + c_char_spacing);
    constant c_score_pos_y  : integer := c_upper_bar_pos/2 - c_char_height/2;

	 constant c_logo_pos_x1 : integer := g_screen_width - 6*(c_char_width + c_char_spacing) - 5;
    constant c_logo_pos_x2 : integer := c_logo_pos_x1 + 1*(c_char_width + c_char_spacing);
    constant c_logo_pos_x3 : integer := c_logo_pos_x1 + 2*(c_char_width + c_char_spacing);
    constant c_logo_pos_x4 : integer := c_logo_pos_x1 + 3*(c_char_width + c_char_spacing);
    constant c_logo_pos_x5 : integer := c_logo_pos_x1 + 4*(c_char_width + c_char_spacing);
    constant c_logo_pos_x6 : integer := c_logo_pos_x1 + 5*(c_char_width + c_char_spacing);
    constant c_logo_pos_y  : integer := c_upper_bar_pos/2 - c_char_height/2;
	 
	 
	 
    -- Components
    component triangle is
        port (
            i_row : in integer;
            i_column : in integer;
            i_xPos : in integer;
            i_yPos : in integer;
    
            o_draw : out std_logic
        );
    end component;
    component font is
        port (
            -- Value of the char
            i_value : in integer;
    
            -- Pixel index for the character
            i_row : in integer; -- 0 to 14
            i_column : in integer; -- 0 to 9
    
            o_draw : out std_logic
        );
    end component;
    component binary_to_bcd IS
        GENERIC(
            bits   : INTEGER := 10;  --size of the binary input numbers in bits
            digits : INTEGER := 3   --number of BCD digits to convert to
        );  
        PORT(
            clk     : IN    STD_LOGIC;                             --system clock
            reset_n : IN    STD_LOGIC;                             --active low asynchronus reset
            ena     : IN    STD_LOGIC;                             --latches in new binary number and starts conversion
            binary  : IN    STD_LOGIC_VECTOR(bits-1 DOWNTO 0);     --binary number to convert
            busy    : OUT  STD_LOGIC;                              --indicates conversion in progress
            bcd     : OUT  STD_LOGIC_VECTOR(digits*4-1 DOWNTO 0)   --resulting BCD number
        );
    END component;

	 
	 component alphabetical_font is
    port (
        -- Value of the char
        i_value : in integer;

        -- Pixel index for the character
        i_row : in integer; -- 0 to height-1
        i_column : in integer; -- 0 to width-1

        o_draw : out std_logic
    );
	end component;
	
    -- Signals
    signal w_ship1_draw : std_logic;
    signal w_ship2_draw : std_logic;
    signal w_ship3_draw : std_logic;
    signal w_ship4_draw : std_logic;
    signal w_ship5_draw : std_logic;

    signal w_font_draw : std_logic;
    signal r_font_row : integer := 0;
    signal r_font_column : integer := 0;

    signal r_score_slv : std_logic_vector(19 downto 0) := (others => '0');
    signal w_score_bcd : std_logic_vector(23 downto 0);
    signal r_start_bcd_conv : std_logic := '0';

    signal r_curr_score_digit : integer := 0;
    signal r_font_val : integer := 0;
	 
	 signal w_alphabetical_font_draw : std_logic;
	 signal r_curr_logo_digit : integer := 0;
	 signal r_alphabetical_font_val : integer := 0;
    signal r_alphabetical_font_row : integer := 0;
    signal r_alphabetical_font_column : integer := 0;
begin
    -- Concurrent assignments
    r_font_row <= i_row - c_score_pos_y;
    r_score_slv <= std_logic_vector(to_unsigned(i_score, r_score_slv'length));
	 r_alphabetical_font_row <= i_row - c_logo_pos_y;
    

    -- Which digit of score?
    process(i_row, i_column)
    begin
        if (i_row >= c_score_pos_y and i_row < c_score_pos_y + c_char_height) then

            if (i_column >= c_score_pos_x1 and i_column < c_score_pos_x1 + c_char_width) then
                r_curr_score_digit <= 1;
            elsif (i_column >= c_score_pos_x2 and i_column < c_score_pos_x2 + c_char_width) then
                r_curr_score_digit <= 2;
            elsif (i_column >= c_score_pos_x3 and i_column < c_score_pos_x3 + c_char_width) then
                r_curr_score_digit <= 3;
            elsif (i_column >= c_score_pos_x4 and i_column < c_score_pos_x4 + c_char_width) then
                r_curr_score_digit <= 4;
            elsif (i_column >= c_score_pos_x5 and i_column < c_score_pos_x5 + c_char_width) then
                r_curr_score_digit <= 5;
            elsif (i_column >= c_score_pos_x6 and i_column < c_score_pos_x6 + c_char_width) then
                r_curr_score_digit <= 6;
            else
                r_curr_score_digit <= 0;
            end if;

        else
            r_curr_score_digit <= 0;
        end if;
    end process;

    -- Pick out the correct BCD value and font column for the digit currently being displayed
    process(r_curr_score_digit, w_score_bcd, i_column)
    begin
        case r_curr_score_digit is
            when 1 =>
                r_font_val <= to_integer(unsigned(w_score_bcd(23 downto 20)));
                r_font_column <= i_column - c_score_pos_x1;
            when 2 => 
                r_font_val <= to_integer(unsigned(w_score_bcd(19 downto 16)));
                r_font_column <= i_column - c_score_pos_x2;
            when 3 => 
                r_font_val <= to_integer(unsigned(w_score_bcd(15 downto 12)));
                r_font_column <= i_column - c_score_pos_x3;
            when 4 => 
                r_font_val <= to_integer(unsigned(w_score_bcd(11 downto 8)));
                r_font_column <= i_column - c_score_pos_x4;
            when 5 => 
                r_font_val <= to_integer(unsigned(w_score_bcd(7 downto 4)));
                r_font_column <= i_column - c_score_pos_x5;
            when 6 => 
                r_font_val <= to_integer(unsigned(w_score_bcd(4 downto 0)));
                r_font_column <= i_column - c_score_pos_x6;
            when others =>
                r_font_val <= 0;
                r_font_column <= 0;
        end case;
    end process;
    
	 
	 -- Which digit of logo?
    process(i_row, i_column)
    begin
        if (i_row >= c_logo_pos_y and i_row < c_logo_pos_y + c_char_height) then

            if (i_column >= c_logo_pos_x1 and i_column < c_logo_pos_x1 + c_char_width) then
                r_curr_logo_digit <= 1;
            elsif (i_column >= c_logo_pos_x2 and i_column < c_logo_pos_x2 + c_char_width) then
                r_curr_logo_digit <= 2;
            elsif (i_column >= c_logo_pos_x3 and i_column < c_logo_pos_x3 + c_char_width) then
                r_curr_logo_digit <= 3;
            elsif (i_column >= c_logo_pos_x4 and i_column < c_logo_pos_x4 + c_char_width) then
                r_curr_logo_digit <= 4;
            elsif (i_column >= c_logo_pos_x5 and i_column < c_logo_pos_x5 + c_char_width) then
                r_curr_logo_digit <= 5;
            elsif (i_column >= c_logo_pos_x6 and i_column < c_logo_pos_x6 + c_char_width) then
                r_curr_logo_digit <= 6;
            else
                r_curr_logo_digit <= 0;
            end if;

        else
            r_curr_logo_digit <= 0;
        end if;
    end process;
	 
	     -- Pick out the correct alphabetic value to display from ROM
    process(r_curr_logo_digit,i_column)
    begin
        case r_curr_score_digit is
            when 1 =>
                r_alphabetical_font_val <= 19; --T
                r_alphabetical_font_column <= i_column - c_logo_pos_x1;
            when 2 => 
                r_alphabetical_font_val <= 13; --N
                r_alphabetical_font_column <= i_column - c_logo_pos_x2;
            when 3 => 
                r_alphabetical_font_val <= 19; --T
                r_alphabetical_font_column <= i_column - c_logo_pos_x3;
            when 4 => 
                r_alphabetical_font_val <= 4; --E
                r_alphabetical_font_column <= i_column - c_logo_pos_x4;
            when 5 => 
                r_alphabetical_font_val <= 2;  --C
                r_alphabetical_font_column <= i_column - c_logo_pos_x5;
            when 6 => 
                r_alphabetical_font_val <= 7;  --H
                r_alphabetical_font_column <= i_column - c_logo_pos_x6;
            when others =>
                r_alphabetical_font_val <= 0;
                r_alphabetical_font_column <= 0;
        end case;
    end process;
	 
	 
    -- Set draw output
    process(i_row, i_column, w_font_draw, w_alphabetical_font_draw)
        variable r_draw_tmp : std_logic := '0';
        variable r_color_tmp : integer range 0 to 4095 := 0;
    begin

        r_draw_tmp := '0';
        r_color_tmp := 0;

        -- Bars
        if (i_row > c_upper_bar_pos and i_row < c_upper_bar_pos + c_bar_height) or
           (i_row > c_lower_bar_pos and i_row < c_lower_bar_pos + c_bar_height) then

            r_draw_tmp := '1';
            r_color_tmp := g_bar_color;
        end if;

        -- Lives
        if (i_num_lives >= 1 and w_ship1_draw='1') or (i_num_lives >= 2 and w_ship2_draw='1') or (i_num_lives >= 3 and w_ship3_draw='1') or (i_num_lives >= 4 and w_ship4_draw='1') or (i_num_lives >= 5 and w_ship5_draw='1') then
            r_draw_tmp := '1';
            r_color_tmp := g_ship_color;
        end if;

        -- Score
        if (r_curr_score_digit /= 0 and w_font_draw = '1') then
            r_draw_tmp := '1';
            r_color_tmp := g_score_color;
        end if;

        -- Logo
        if (r_curr_logo_digit /= 0 and w_alphabetical_font_draw = '1') then
		      r_draw_tmp := '1';
            r_color_tmp := g_logo_color;
        end if;
		  
        -- Assign outputs
        o_draw <= r_draw_tmp;
        o_color <= r_color_tmp;
    end process;

    -- Update for next frame
    process(i_clock)
        -- Vars
    begin
        if (rising_edge(i_clock)) then

            -- Time to update state
            if (i_update_pulse = '1') then
                r_start_bcd_conv <= '1';
            else
                r_start_bcd_conv <= '0';
            end if;
        end if;

    end process;

    -- Instantiation
    ship1 : triangle port map (i_row => i_row, i_column => i_column, i_xPos => c_ship_pos_x1, i_yPos => c_ship_pos_y, o_draw => w_ship1_draw);
    ship2 : triangle port map (i_row => i_row, i_column => i_column, i_xPos => c_ship_pos_x2, i_yPos => c_ship_pos_y, o_draw => w_ship2_draw);
    ship3 : triangle port map (i_row => i_row, i_column => i_column, i_xPos => c_ship_pos_x3, i_yPos => c_ship_pos_y, o_draw => w_ship3_draw);
    ship4 : triangle port map (i_row => i_row, i_column => i_column, i_xPos => c_ship_pos_x4, i_yPos => c_ship_pos_y, o_draw => w_ship4_draw);
    ship5 : triangle port map (i_row => i_row, i_column => i_column, i_xPos => c_ship_pos_x5, i_yPos => c_ship_pos_y, o_draw => w_ship5_draw);

    digits_font : font port map (i_value => r_font_val, i_row => r_font_row, i_column => r_font_column, o_draw => w_font_draw);
	 
	 alpha_font  : alphabetical_font port map (i_value => r_alphabetical_font_val, i_row => r_alphabetical_font_row, i_column => r_alphabetical_font_column, o_draw => w_alphabetical_font_draw);
    
	 bcdconv : binary_to_bcd generic map(
            bits => 20,
            digits => 6
        )
        port map (
            clk  => i_clock,
            reset_n => '1',
            ena  => r_start_bcd_conv,
            binary => r_score_slv,
            busy => open,
            
            bcd => w_score_bcd -- result is latched here when done with conversion
        );
    
end architecture rtl;