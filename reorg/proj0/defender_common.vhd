-- defender_common: Package containing common code for FPGA defender
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package defender_common is

    -- Constants
    constant c_num_text_elems: integer := 8;
    constant c_screen_width : integer := 640;
    constant c_screen_height : integer := 480;
    constant c_bar_height : integer := 3;
    constant c_bar_offset : integer := 30;
    constant c_upper_bar_pos : integer := c_bar_offset - c_bar_height;
    constant c_lower_bar_pos : integer := c_screen_height - c_bar_offset;

    constant c_ship_width : integer := 30;
    constant c_ship_height : integer := 20;

    -- Types
    type t_point_2d is
    record
        x : integer;
        y : integer;
    end record;

    type t_size_2d is
    record
        w : integer;
        h : integer;
    end record;

    type t_speed_2d is
    record
        x : integer;
        y : integer;
    end record;
    
    -- Functions
    function darken(color : integer; shift_val : integer) return integer;

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

end defender_common;
