-- terrain: Logic and graphics generation
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;

-- For vgaText library
use work.commonPak.all;
-- Common constants
use work.defender_common.all;

entity terrain is
    port (
        i_clock : in std_logic;
        i_update_pulse : in std_logic;
        i_reset_pulse : in std_logic;

        -- Control Signals
        i_scan_pos : in t_point_2d_onscreen;
        i_draw_en : in std_logic;

        o_color : out integer range 0 to c_max_color;
        o_draw : out std_logic
    );
end entity terrain;

architecture rtl of terrain is

    -- Constants
    constant c_line_thickness : integer := 2;
    constant c_line_color : integer := 16#0F0#;
    constant c_num_lines : integer := 32;
    constant c_line_dx : integer := c_screen_width/c_num_lines;
    constant c_max_shift_frame_rate : integer := 120;

    -- Types
    type t_heightArray is array(natural range <>) of integer range 0 to c_terrain_height;
    signal heightArray : t_heightArray(0 to c_num_lines) := (others => 0); -- n+1 heights for n lines

    -- Signals
    signal w_lfsr_out_slv : std_logic_vector(7 downto 0);
    signal w_lfsr_out_int : integer range 0 to 2**8-1;
    signal w_lfsr_out_signed_int : integer range -2**7 to 2**7-1;
    signal r_shift_frame_rate : integer range 0 to c_max_shift_frame_rate := 0; -- How often should we shift the lines left (in # of frames)
    signal r_shift_update : std_logic := '0'; -- Time to shift lines?
    
begin

    -- Set shift speed
    r_shift_frame_rate <= 60; -- Once per second
    
    -- Set draw output
    process(i_scan_pos)
        variable r_draw_tmp : std_logic := '0';
        variable r_color_tmp : integer range 0 to c_max_color := 0;

    begin

        r_draw_tmp := '0';
        r_color_tmp := 0;

        -- Render each line
        for i in 0 to c_num_lines-1 loop
            if in_range_line(i_scan_pos, (i*c_line_dx, c_terrain_bottom - heightArray(i)), ((i+1)*c_line_dx - 1, c_terrain_bottom - heightArray(i+1)), c_line_thickness) then

                r_draw_tmp := '1';
                r_color_tmp := c_line_color;

            end if;
        end loop;

        -- Override all drawing
        if (i_draw_en = '0') then
            r_draw_tmp := '0';
            r_color_tmp := 0;
        end if;
            
        -- Assign outputs
        o_draw <= r_draw_tmp;
        o_color <= r_color_tmp;
    end process;

    -- Line shift clock
    process(i_clock)
        variable shift_frame_cnt : integer range 0 to c_max_shift_frame_rate := 0;
    begin
        if rising_edge(i_clock) and i_update_pulse = '1' then
            r_shift_update <= '0';

            shift_frame_cnt := shift_frame_cnt+1;
            if shift_frame_cnt >= r_shift_frame_rate then
                shift_frame_cnt := 0;
                r_shift_update <= '1'; -- One cycle pulse
            end if;
        end if;
    end process;
    
    -- Update state
    process(i_clock)
        -- Vars
        variable localHeightArray : t_heightArray(0 to c_num_lines) := (others => 0);
        variable prevHeight, newHeight : integer range -c_terrain_height to c_terrain_height;

    begin
        if (rising_edge(i_clock) and i_update_pulse = '1') then

            -- Capture current state of objects
            localHeightArray := heightArray;


            if (i_reset_pulse = '1') then
            
            -- Time to update state
            else

                -- Time to shift lines left
                if (r_shift_update = '1') then

                    -- Generate new height value
                    prevHeight := heightArray(c_num_lines);
                    newHeight := prevHeight + w_lfsr_out_signed_int;

                    -- Clip the height, if needed
                    if (newHeight > c_terrain_height) then
                        newHeight := c_terrain_height;
                    end if;
                    if (newHeight < 0) then
                        newHeight := 0;
                    end if;

                    -- Shift in new height from the right
                    localHeightArray := localHeightArray(1 to c_num_lines) & newHeight;

                    
                end if;

            end if;




            -- Update objects
            heightArray <= localHeightArray;


            -- Update outputs

        end if;

    end process;

    -- PRNG
    w_lfsr_out_int <= to_integer(unsigned(w_lfsr_out_slv));
    w_lfsr_out_signed_int <= to_integer(signed(w_lfsr_out_slv));

    prng: entity work.lfsr8 port map (
        clock => i_clock,
        reset => '0',
        load => '0',
        cnt_en => '1',
        par_in => (others => '0'),
        value_out => w_lfsr_out_slv
    );
    

end architecture rtl;