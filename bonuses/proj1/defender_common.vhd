-- defender_common: Package containing common code for FPGA defender
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

package defender_common is

    -- Convert decimal number to number of bits needed
    function ceil_log2(val : positive) return natural;
    
    -- Constants
    constant c_num_text_elems: integer := 8;
    constant c_screen_width : integer := 640;
    constant c_screen_height : integer := 480;
    constant c_bar_height : integer := 3;
    constant c_bar_offset : integer := 30;
    constant c_upper_bar_pos : integer := c_bar_offset - c_bar_height;
    constant c_lower_bar_pos : integer := c_screen_height - c_bar_offset;
    constant c_lower_bar_draw_en : boolean := false;
    constant c_vga_color_bits : integer := 12;

    constant c_ship_width : integer := 30;
    constant c_ship_height : integer := 20;

    -- Sprite data
    constant c_spr_data_slots : integer := 32;       -- Max slots available
    constant c_spr_data_slots_used : integer := 6;   -- Number of slots in use
    constant c_spr_data_width_pix : integer := 15;   -- Max sprite width
    constant c_spr_data_height_pix : integer := 8;   -- Max sprite height
    constant c_spr_data_bits_per_pix : integer := 4; -- 4 bits of color data per pixel
    
    constant c_spr_data_width_bits : integer := c_spr_data_width_pix*c_spr_data_bits_per_pix; -- Width of each line of data
    constant c_spr_data_depth : integer := c_spr_data_slots*c_spr_data_height_pix; -- Depth of the sprite ROM. One location per line.
    constant c_spr_addr_bits : integer := ceil_log2(c_spr_data_depth); -- Number of bits in the sprite ROM address.
    
    constant c_spr_max_scale_x : integer := 8; -- The largest sprite scale factor we will allow
    constant c_spr_max_scale_y : integer := 8;

    
    constant c_palette_size : integer := 16; -- Number of colors in the main palette
    constant c_transp_color : integer := 16#515#;
    constant c_transp_color_pal : integer := 16#1#;
    
    constant c_spr_arb_slots : integer := 20; -- Number of sprite ROM arbitration slots
    
    type t_spr_size is
    record
        w : integer range 0 to c_spr_data_width_pix;
        h : integer range 0 to c_spr_data_height_pix;
    end record;
    type t_spr_size_array is array(0 to c_spr_data_slots_used-1) of t_spr_size;

    constant c_spr_sizes : t_spr_size_array := ((15,6), (10,4), (9,8), (9,8), (11,4), (8,8)); -- (w, h) of all sprites in memory

    -- Initial conditions
    constant c_initial_lives : integer := 3;

    -- Game parameters
    constant c_extra_life_score_mult : integer := 500; -- After how many points should we award an extra life?

    -- Integer ranges
    constant c_max_color : integer := 4095;
    constant c_max_speed : integer := 20;
    constant c_max_size  : integer := 100;
    constant c_min_x : integer := -c_max_size;
    constant c_max_x : integer := c_screen_width+c_max_size;
    constant c_min_y : integer := -c_max_size;
    constant c_max_y : integer := c_screen_height+c_max_size;
    constant c_max_score : integer := 999999;
    constant c_max_lives : integer := 5;

    -- Sounds
    constant c_sound_game_start : std_logic_vector(2 downto 0) := "000";
    constant c_sound_player_fire : std_logic_vector(2 downto 0) := "001";
    constant c_sound_enemy_fire : std_logic_vector(2 downto 0) := "010";
    constant c_sound_enemy_destroy : std_logic_vector(2 downto 0) := "011";
    constant c_sound_player_hit : std_logic_vector(2 downto 0) := "011";
    constant c_sound_game_over : std_logic_vector(2 downto 0) := "100";

    -- Terrain
    constant c_terrain_height : integer := 75;
    constant c_terrain_top : integer := c_screen_height-c_terrain_height-1;
    constant c_terrain_bottom : integer := c_screen_height-1;


    -- Types
    subtype t_onscreen_x is integer range 0 to c_screen_width-1;
    subtype t_onscreen_y is integer range 0 to c_screen_height-1;

    type t_point_2d is
    record
        x : integer range c_min_x to c_max_x;
        y : integer range c_min_y to c_max_y;
    end record;

    type t_point_2d_onscreen is
    record
        x : integer range 0 to c_screen_width-1;
        y : integer range 0 to c_screen_height-1;
    end record;

    type t_size_2d is
    record
        w : integer range 0 to c_max_size;
        h : integer range 0 to c_max_size;
    end record;

    type t_speed_2d is
    record
        x : integer range -c_max_speed to c_max_speed;
        y : integer range -c_max_speed to c_max_speed;
    end record;

    -- Arbitration
    type t_arb_port_in is
    record
        dataRequest: boolean;
        addr: std_logic_vector(c_spr_addr_bits-1 downto 0);
        writeRequest: boolean;
        writeData: std_logic_vector(c_spr_data_width_bits-1 downto 0);
    end record;
    constant init_t_arb_port_in: t_arb_port_in := (dataRequest => false, addr => (others => '0'), writeRequest => false, writeData  => (others => '0'));
    type t_arb_port_in_array is array(natural range <>) of t_arb_port_in;
    
    
    type t_arb_port_out is
    record
        dataWaiting: boolean;
        data: std_logic_vector(c_spr_data_width_bits-1 downto 0);
        dataWritten: boolean;
    end record;
    constant init_t_arb_port_out: t_arb_port_out := (dataWaiting => false, data => (others => '0'), dataWritten => false);
    type t_arb_port_out_array is array(natural range <>) of t_arb_port_out;

    -- Sprite draw element
    type t_spr_draw_elem is
    record
        draw: boolean;
        color: integer range 0 to c_max_color;
    end record;
    constant init_t_spr_draw_elem: t_spr_draw_elem := (draw => false, color => 0);
    type t_spr_draw_elem_array is array(natural range <>) of t_spr_draw_elem; 
    
    -- Functions
    function darken(color : integer; shift_val : integer) return integer;

    -- Is the current scan position in range of the rectangle? Provide one point and a size
    function in_range_rect(scan_pos : t_point_2d; obj_pos : t_point_2d; obj_size : t_size_2d) return boolean;
    -- Provide two points
    function in_range_rect_2pt(scan_pos : t_point_2d; top_left : t_point_2d; bott_right : t_point_2d) return boolean;

    -- Draw line between two points
    function in_range_line(scan_pos : t_point_2d_onscreen; p1 : t_point_2d_onscreen; p2 : t_point_2d_onscreen; thick : integer) return boolean;

    -- Are the two rectangles intersecting? o1 should be smaller than o2
    function collide_rect(o1_pos : t_point_2d; o1_size : t_size_2d; o2_pos : t_point_2d; o2_size : t_size_2d) return boolean;
    -- Is the rectangle off screen?
    function off_screen_rect(o1_pos : t_point_2d; o1_size : t_size_2d) return boolean;

end defender_common;

package body defender_common is

	function darken(color : integer; shift_val : integer) return integer is
        variable red : integer := 0;
        variable green : integer := 0;
        variable blue : integer := 0;
        variable color_uns : unsigned(11 downto 0);
        variable color_out : integer;
	begin
        color_uns := to_unsigned(color, color_uns'LENGTH);
        red := to_integer(color_uns(11 downto 8));
        green := to_integer(color_uns(7 downto 4));
        blue := to_integer(color_uns(3 downto 0));

        red := red - shift_val;
        green := green - shift_val;
        blue := blue - shift_val;

        if (red < 0) then
            red := 0;
        end if;
        if (green < 0) then
            green := 0;
        end if;
        if (blue < 0) then
            blue := 0;
        end if;

        color_uns := (to_unsigned(red, 4) & to_unsigned(green, 4) & to_unsigned(blue, 4));
        color_out := to_integer(color_uns);

        return color_out;
	end function;

    function in_range_rect(scan_pos : t_point_2d; obj_pos : t_point_2d; obj_size : t_size_2d) return boolean is
    begin
        if (scan_pos.x >= obj_pos.x and scan_pos.x < obj_pos.x + obj_size.w) and  -- Inside X
           (scan_pos.y >= obj_pos.y and scan_pos.y < obj_pos.y + obj_size.h) then -- Inside Y

            return true;
        else
            return false;
        end if;
    end function;

    function in_range_rect_2pt(scan_pos : t_point_2d; top_left : t_point_2d; bott_right : t_point_2d) return boolean is
    begin
        if (scan_pos.x >= top_left.x and scan_pos.x < bott_right.x) and  -- Inside X
           (scan_pos.y >= top_left.y and scan_pos.y < bott_right.y) then -- Inside Y

            return true;
        else
            return false;
        end if;
    end function;


    function collide_rect(o1_pos : t_point_2d; o1_size : t_size_2d; o2_pos : t_point_2d; o2_size : t_size_2d) return boolean is
    begin
        if ( ((o1_pos.x >= o2_pos.x and o1_pos.x <= o2_pos.x + o2_size.w - 1) or (o1_pos.x + o1_size.w - 1 >= o2_pos.x and o1_pos.x + o1_size.w - 1 <= o2_pos.x + o2_size.w - 1)) and
             ((o1_pos.y >= o2_pos.y and o1_pos.y <= o2_pos.y + o2_size.h - 1) or (o1_pos.y + o1_size.h - 1 >= o2_pos.y and o1_pos.y + o1_size.h - 1 <= o2_pos.y + o2_size.h - 1)) ) then

            return true;
        else
            return false;
        end if;
    end function;

    function off_screen_rect(o1_pos : t_point_2d; o1_size : t_size_2d) return boolean is
    begin
        if (o1_pos.x + o1_size.w - 1 < 0) or (o1_pos.x > c_screen_width - 1) or (o1_pos.y + o1_size.h - 1 < 0) or (o1_pos.y > c_screen_height - 1) then
            return true;
        else
            return false;
        end if;
    end function;


    function in_range_line(scan_pos : t_point_2d_onscreen; p1 : t_point_2d_onscreen; p2 : t_point_2d_onscreen; thick : integer) return boolean is
        variable line_mid : t_point_2d := (0,0);
    begin
        line_mid.y := ((scan_pos.x - p1.x) * (p2.y-p1.y) / (p2.x-p1.x) ) + p1.y; -- Calculate line eqn

        if (scan_pos.x >= p1.x and scan_pos.x <= p2.x) and                                 -- Inside X range
        --    (scan_pos.y >= line_mid.y and scan_pos.y <= line_mid.y + thick) then -- Inside Y range
           (scan_pos.y = line_mid.y) then -- Inside Y range

            return true;
        else
            return false;
        end if;
    end function;

    function ceil_log2(val : positive) return natural is
	begin
		return integer(ceil(log2(real(val))));
	end function;

end defender_common;
