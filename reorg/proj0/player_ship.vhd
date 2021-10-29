-- player_ship: Logic and graphics generation
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity player_ship is
    generic (
        g_screen_width : integer := 640;
        g_screen_height : integer := 480;
        g_ship_color : integer := 16#F00#;

        -- Play area limits
        g_left_bound : integer := 0;
        g_right_bound : integer := 640 / 2;
        g_upper_bound : integer := 30;
        g_lower_bound : integer := 480 - 30;

        -- Bounding box
        g_bb_width : integer := 30;
        g_bb_height : integer := 20;

        -- Update position every 1 frames
        g_frame_update_cnt : integer := 1; -- Defines "smoothness" of animation
        g_speed_scale_x : integer := 10; -- Defines the speed range for the tilt, higher value = faster ship movement for same tilt
        g_speed_scale_y : integer := 25;
        g_hystr_div : integer := 7; -- Defines the amount of hysteresis on x and y tilts, higher value = less hysteresis
        g_accel_in_max : integer := 2**8 -- Max input value from accelerometer (absolute value)
    );
    port (
        i_clock : in std_logic;
        i_update_pulse : in std_logic;

        -- HMI Inputs
        accel_scale_x, accel_scale_y : in integer;

        i_row : in integer;
        i_column : in integer;

        o_color : out integer range 0 to 4095;
        o_draw : out std_logic
    );
end entity player_ship;

 
architecture rtl of player_ship is
    -- Constants
    
    -- Types

    -- Signals


    -- coords of top left of object
    signal r_xPos : integer range 0 to g_screen_width-1 := (g_right_bound - g_left_bound)/2;
    signal r_yPos : integer range 0 to g_screen_height-1 := (g_lower_bound - g_upper_bound)/2;

    -- Pixels per update. Update in # of frames is set by g_frame_update_cnt
    signal r_xSpeed : integer := 0;
    signal r_ySpeed : integer := 0;
    
begin
    
    -- Set draw output
    process(i_row, i_column, r_xPos, r_yPos)
    begin

        -- is current pixel coordinate inside our box?
        if (i_column >= r_xPos and i_column <= r_xPos+g_bb_width and i_row >= r_yPos and i_row <= r_yPos+g_bb_height) and -- Inside Rectangle
           (i_row > ((i_column - r_xPos) * g_bb_height / g_bb_width) + r_yPos) then                                       -- Below hypotenuse of triangle
            
            o_draw <= '1';
            o_color <= g_ship_color;
        else
            o_draw <= '0';
            o_color <= 0;
        end if;
    end process;

    process(i_clock)
        -- Vars
        variable r_xPos_new : integer;
        variable r_yPos_new : integer;
        variable r_frame_cnt : integer range 0 to g_frame_update_cnt := 0;
    begin
        if (rising_edge(i_clock)) then

            -- Time to update state
            if (i_update_pulse = '1') then

                r_frame_cnt := r_frame_cnt + 1;
                -- Limit position update rate
                if (r_frame_cnt = g_frame_update_cnt) then
                    r_frame_cnt := 0;

                    r_xPos_new := r_xPos + r_xSpeed;
                    r_yPos_new := r_yPos + r_ySpeed;

                    -- Check bounds and clip

                    -- X bounds
                    if (r_xPos_new + g_bb_width > g_right_bound) then
                        r_xPos_new := g_right_bound - g_bb_width;
                    end if;
                    if (r_xPos_new < g_left_bound) then
                        r_xPos_new := g_left_bound;
                    end if;

                    -- Y bounds
                    if (r_yPos_new + g_bb_height > g_lower_bound) then
                        r_yPos_new := g_lower_bound - g_bb_height;
                    end if;
                    if (r_yPos_new < g_upper_bound) then
                        r_yPos_new := g_upper_bound;
                    end if;

                    -- Assign new values
                    r_xPos <= r_xPos_new;
                    r_yPos <= r_yPos_new;

                end if;
            end if;
        end if;
    end process;

    -- Set ship speed from user input
    process(accel_scale_x, accel_scale_y)
        -- Vars
        variable r_xSpeed_new : integer;
        variable r_ySpeed_new : integer;
    begin

        -- Scaled 0 to g_speed_scale
        r_xSpeed_new := abs(accel_scale_x) * g_speed_scale_x / g_accel_in_max;
        r_ySpeed_new := abs(accel_scale_y) * g_speed_scale_y / g_accel_in_max;

        -- Hysteresis, require a tilt of a certain steepness before any movement occurs
        if (r_xSpeed_new < g_speed_scale_x / g_hystr_div) then
            r_xSpeed_new := 0;
        end if;
        if (r_ySpeed_new < g_speed_scale_y / g_hystr_div) then
            r_ySpeed_new := 0;
        end if;

        -- Direction of tilt
        -- x+ : left,    x- : right
        -- y+ : forward, y- : backward

        -- Negative speed means LEFT or UP
        if (accel_scale_x > 0) then
            r_xSpeed_new := -r_xSpeed_new;
        end if;
        if (accel_scale_y < 0) then
            r_ySpeed_new := -r_ySpeed_new;
        end if;

        -- Assign new values
        r_xSpeed <= r_xSpeed_new;
        r_ySpeed <= r_ySpeed_new;
    end process;
    
end architecture rtl;