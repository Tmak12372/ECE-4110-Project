-- enemies: Logic and graphics generation
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;

-- For vgaText library
use work.commonPak.all;
-- Common constants
use work.defender_common.all;

entity enemies is
    port (
        i_clock : in std_logic;
        i_update_pulse : in std_logic;
        i_reset_pulse : in std_logic;

        -- Control Signals
        i_row : in integer;
        i_column : in integer;
        i_draw_en : in std_logic;

        -- Game state
        i_score : in integer;
        i_ship_pos_x : in integer;
        i_ship_pos_y : in integer;

        o_ship_collide : out std_logic;
        o_cannon_collide : out std_logic;
        o_score_inc : out integer;

        o_color : out integer range 0 to 4095;
        o_draw : out std_logic
    );
end entity enemies;

architecture rtl of enemies is

    -- Types
    type t_sizeArray is array(0 to 2) of integer;
    type t_colorArray is array(0 to 7) of integer;

    -- Constants
    constant c_max_num_enemies : integer := 20;
    constant c_spawn_frame_rate : integer := 30;

    constant c_enemy_size : t_sizeArray := (20, 40, 60);

    constant c_enemy_color : t_colorArray := (16#F90#, 16#0F0#, 16#00F#, 16#FF0#, 16#F0F#, 16#0FF#, 16#880#, 16#808#);

    constant c_spawn_ylim_upper : integer := c_upper_bar_pos + c_bar_height;
    constant c_spawn_ylim_lower : integer := c_lower_bar_pos;
    constant c_spawn_range : integer := c_spawn_ylim_lower - c_spawn_ylim_upper;

    -- Types
    type t_enemy is
    record
        alive: boolean;
        pos: t_point_2d;
        speed: t_speed_2d;
        size: t_size_2d;
        color: integer;
    end record;
    constant init_t_enemy: t_enemy := (alive => false, pos => (0,0), speed => (0,0), size => (0,0), color => 0);
    type t_enemyArray is array(natural range <>) of t_enemy;

    -- Signals
    signal enemyArray : t_enemyArray(0 to c_max_num_enemies-1) := (others => init_t_enemy);
    signal r_stage : integer := 0; -- Which stage (difficulty level) are we on?
    signal r_num_enemy_target : integer := 0; -- How many enemies should we have on screen?
    signal r_new_enemy_speed : integer := 0; -- How fast should new enemies go?
    signal w_lfsr_out_slv : std_logic_vector(7 downto 0);
    signal w_lfsr_out_int : integer;

begin

    -- Set stage from score
    process(i_score)
    begin
        if i_score >= 0 and i_score < 500 then
            r_stage <= 1;
        elsif i_score >= 500 and i_score < 1000 then
            r_stage <= 2;
        elsif i_score >= 1000 and i_score < 1500 then
            r_stage <= 3;
        elsif i_score >= 1500 and i_score < 2000 then
            r_stage <= 4;
        elsif i_score >= 2000 then
            r_stage <= 5;
        else
            r_stage <= 0;
        end if;
    end process;

    -- Set enemy count target from stage
    process(r_stage)
    begin
        case r_stage is
            when 1 =>
                r_num_enemy_target <= 3;
            when 2 => 
                r_num_enemy_target <= 6;
            when 3 => 
                r_num_enemy_target <= 8;
            when 4 => 
                r_num_enemy_target <= 12;
            when 5 => 
                r_num_enemy_target <= 16;
            when others =>
                r_num_enemy_target <= 0;
        end case;
    end process;

    -- Set enemy speed from stage
    process(r_stage)
    begin
        case r_stage is
            when 1 =>
                r_new_enemy_speed <= 1;
            when 2 => 
                r_new_enemy_speed <= 2;
            when 3 => 
                r_new_enemy_speed <= 3;
            when 4 => 
                r_new_enemy_speed <= 4;
            when 5 => 
                r_new_enemy_speed <= 5;
            when others =>
                r_new_enemy_speed <= 0;
        end case;
    end process;
    
    -- Set draw output
    process(i_row, i_column)
        variable r_draw_tmp : std_logic := '0';
        variable r_color_tmp : integer range 0 to 4095 := 0;

    begin

        r_draw_tmp := '0';
        r_color_tmp := 0;

        -- Scan each enemy and render (using rectangle shape)
        for i in 0 to c_max_num_enemies-1 loop
            if (i_column >= enemyArray(i).pos.x and i_column < enemyArray(i).pos.x + enemyArray(i).size.w) and -- Inside X
               (i_row >= enemyArray(i).pos.y and i_row < enemyArray(i).pos.y + enemyArray(i).size.h) and       -- Inside Y
               (enemyArray(i).alive) then

                r_draw_tmp := '1';
                r_color_tmp := enemyArray(i).color;

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


    -- Update state
    process(i_clock)
        -- Vars
        variable localEnemyArray : t_enemyArray(0 to c_max_num_enemies-1) := (others => init_t_enemy);
        variable x : integer := 0;
        variable y : integer := 0;
        variable w : integer := 0;
        variable h : integer := 0;
        variable num_alive : integer := 0;
        variable rand_pos : t_point_2d := (0,0);
        variable rand_pos_y : integer := 0;
        variable rand_speed : t_speed_2d := (0,0);
        variable rand_size : t_size_2d := (0,0);
        variable rand_size_int : integer := 0;
        variable rand_color : integer := 0;
        variable spawn_frame_cnt : integer := 0;
        variable open_enemy_slot : integer := 0;

    begin
        if (rising_edge(i_clock)) then

            -- Capture current enemy state
            localEnemyArray := enemyArray;

            if (i_reset_pulse = '1') then

                -- Clear enemy data
                for i in 0 to c_max_num_enemies-1 loop
                    localEnemyArray(i).alive := false;
                end loop;
            
            -- Time to update state
            elsif (i_update_pulse = '1') then

                -- Handle collision with ship
                -- for i in 0 to c_max_num_enemies-1 loop
                --     if (x+w-1 < 0) or (x > c_screen_width-1) or (y+h-1 < 0) or (y > c_screen_height-1) then
                --         localEnemyArray(i).alive := false;
                --     end if;
                -- end loop;

                -- Handle collision with cannon
                
                -- Update position
                for i in 0 to c_max_num_enemies-1 loop
                    if localEnemyArray(i).alive then
                        localEnemyArray(i).pos.x := localEnemyArray(i).pos.x + localEnemyArray(i).speed.x;
                        localEnemyArray(i).pos.y := localEnemyArray(i).pos.y + localEnemyArray(i).speed.y;
                    end if;
                end loop;

                -- Update alive status
                for i in 0 to c_max_num_enemies-1 loop
                    x := localEnemyArray(i).pos.x;
                    y := localEnemyArray(i).pos.y;
                    w := localEnemyArray(i).size.w;
                    h := localEnemyArray(i).size.h;

                    -- Is the enemy off screen?
                    if (x+w-1 < 0) or (x > c_screen_width-1) or (y+h-1 < 0) or (y > c_screen_height-1) then
                        localEnemyArray(i).alive := false;
                    end if;
                end loop;

                -- Count alive enemies
                num_alive := 0;
                for i in 0 to c_max_num_enemies-1 loop
                    if localEnemyArray(i).alive then
                        num_alive := num_alive+1;
                    else
                        open_enemy_slot := i;
                    end if;
                end loop;

                -- Spawn
                spawn_frame_cnt := spawn_frame_cnt+1;
                if spawn_frame_cnt = c_spawn_frame_rate then
                    spawn_frame_cnt := 0;

                    -- Should we spawn a new enemy?
                    if num_alive < r_num_enemy_target then
                        
                        -- 2 bits to pick size
                        rand_size_int := c_enemy_size(to_integer(unsigned(w_lfsr_out_slv(7 downto 6))));
                        rand_size := (rand_size_int, rand_size_int);
                        -- 3 bits to pick color
                        rand_color := c_enemy_color(to_integer(unsigned(w_lfsr_out_slv(5 downto 3))));

                        -- Pick y pos
                        rand_pos_y := w_lfsr_out_int * c_spawn_range / 255; -- Scale to spawn range
                        rand_pos_y := rand_pos_y + c_spawn_ylim_upper;
                        -- Too low? Fix if so
                        if rand_pos_y+rand_size_int > c_spawn_ylim_lower then
                            rand_pos_y := rand_pos_y - ((rand_pos_y+rand_size_int)-c_spawn_ylim_lower); -- Subtract the out of bounds difference
                        end if;
                        rand_pos := (c_screen_width, rand_pos_y); -- Just outside of view on right side

                        -- Speed set by stage level
                        rand_speed := (-r_new_enemy_speed, 0); -- Moving left


                        localEnemyArray(open_enemy_slot).alive := true;
                        localEnemyArray(open_enemy_slot).size := rand_size;
                        localEnemyArray(open_enemy_slot).color := rand_color;
                        localEnemyArray(open_enemy_slot).pos := rand_pos;
                        localEnemyArray(open_enemy_slot).speed := rand_speed;

                    end if;
                end if;
                
                

            end if;

            -- Update enemies
            enemyArray <= localEnemyArray;
        end if;

    end process;

    -- Concurrent assignments
    w_lfsr_out_int <= to_integer(unsigned(w_lfsr_out_slv));
    
    -- Instantiation
    prng: entity work.lfsr8 port map (
        clock => i_clock,
        reset => '0',
        load => '0',
        par_in => (others => '0'),
        value_out => w_lfsr_out_slv
    );
end architecture rtl;