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
        g_ship_height : integer := 20
        

    );
    port (
        i_clock : in std_logic;
        i_update_pulse : in std_logic;

        i_row : in integer;
        i_column : in integer;

        -- Game status
        i_num_lives : integer range 0 to 5;

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
    constant c_ship_pos_y : integer := c_upper_bar_pos/2 - g_ship_height/2;
    constant c_ship_pos_x1 : integer := 20;
    constant c_ship_pos_x2 : integer := c_ship_pos_x1 + 1*(g_ship_width + c_ship_spacing_x);
    constant c_ship_pos_x3 : integer := c_ship_pos_x1 + 2*(g_ship_width + c_ship_spacing_x);
    constant c_ship_pos_x4 : integer := c_ship_pos_x1 + 3*(g_ship_width + c_ship_spacing_x);
    constant c_ship_pos_x5 : integer := c_ship_pos_x1 + 4*(g_ship_width + c_ship_spacing_x);

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

    -- Signals
    signal w_ship1_draw : std_logic;
    signal w_ship2_draw : std_logic;
    signal w_ship3_draw : std_logic;
    signal w_ship4_draw : std_logic;
    signal w_ship5_draw : std_logic;

    
begin
    
    -- Set draw output
    process(i_row, i_column)
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

        -- Logo
        
        -- Assign outputs
        o_draw <= r_draw_tmp;
        o_color <= r_color_tmp;
    end process;

    -- Instantiation
    ship1 : triangle port map (i_row => i_row, i_column => i_column, i_xPos => c_ship_pos_x1, i_yPos => c_ship_pos_y, o_draw => w_ship1_draw);
    ship2 : triangle port map (i_row => i_row, i_column => i_column, i_xPos => c_ship_pos_x2, i_yPos => c_ship_pos_y, o_draw => w_ship2_draw);
    ship3 : triangle port map (i_row => i_row, i_column => i_column, i_xPos => c_ship_pos_x3, i_yPos => c_ship_pos_y, o_draw => w_ship3_draw);
    ship4 : triangle port map (i_row => i_row, i_column => i_column, i_xPos => c_ship_pos_x4, i_yPos => c_ship_pos_y, o_draw => w_ship4_draw);
    ship5 : triangle port map (i_row => i_row, i_column => i_column, i_xPos => c_ship_pos_x5, i_yPos => c_ship_pos_y, o_draw => w_ship5_draw);
    
end architecture rtl;