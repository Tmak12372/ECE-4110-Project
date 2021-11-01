-- image_gen: Render frames "just-in-time" and handle game logic
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;
library work;

-- For vgaText library
use work.commonPak.all;
-- Common constants
use work.defender_common.all;

ENTITY image_gen IS
    generic (

        -- RGB, 4 bits each
        g_bg_color : integer := 16#FFF#;
        g_text_color : integer := 16#000#;

        g_screen_width : integer := 640;
        g_screen_height : integer := 480;

        g_max_lives : integer := 5;
        g_initial_lives : integer := 3;

        g_max_score : integer := 999999

    );
    port(
        -- Control and pixel clock
        pixel_clk:  IN  STD_LOGIC;

        -- VGA controller inputs
        disp_en  :  IN  STD_LOGIC;  --display enable ('1' = display time, '0' = blanking time)
        row      :  IN  INTEGER;    --row pixel coordinate
        column   :  IN  INTEGER;    --column pixel coordinate

        -- Color outputs to VGA
        red      :  OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');  --red magnitude output to DAC
        green    :  OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');  --green magnitude output to DAC
        blue     :  OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');  --blue magnitude output to DAC

        -- HMI Inputs
        accel_scale_x, accel_scale_y : integer;
        KEY                          : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        SW                           : IN STD_LOGIC_VECTOR(9 DOWNTO 0)
    );
END image_gen;

ARCHITECTURE behavior OF image_gen IS
    -- Components

    -- Constants
    
    -- Types
    type t_state is (ST_START, ST_NEW_GAME, ST_PLAY, ST_PAUSE, ST_GAME_OVER);

    -- Signals
    SIGNAL KEY_b       : STD_LOGIC_VECTOR(1 DOWNTO 0);
    signal r_disp_en_d : std_logic := '0';   -- Registered disp_en input
    signal r_disp_en_fe : std_logic;         -- Falling edge of disp_en input
    signal r_logic_update : std_logic := '0'; -- Pulse
    signal r_key_d : std_logic_vector(1 downto 0);
    signal r_key_fe : std_logic_vector(1 downto 0); -- Pulse

    signal w_playShipDraw : std_logic;
    signal w_playShipColor: integer range 0 to 4095;

    signal w_hudDraw : std_logic;
    signal w_hudColor: integer range 0 to 4095;

    signal w_overlaysDraw : std_logic;
    signal w_overlaysColor: integer range 0 to 4095;

    signal r_num_lives : integer range 0 to g_max_lives := g_initial_lives;
    signal r_score : integer range 0 to g_max_score := 0;

    signal r_game_state : t_state := ST_START;
    signal r_game_paused : std_logic := '0';
    signal r_game_wait_start : std_logic := '0';
    signal r_game_over : std_logic := '0';
    signal r_game_active : std_logic := '0';

    signal r_obj_update : std_logic := '0';
    signal r_obj_reset : std_logic := '0';
    
    -- vgaText
    signal inArbiterPortArray: type_inArbiterPortArray(0 to c_num_text_elems-1) := (others => init_type_inArbiterPort);
    signal outArbiterPortArray: type_outArbiterPortArray(0 to c_num_text_elems-1) := (others => init_type_outArbiterPort);
    signal drawElementArray: type_drawElementArray(0 to c_num_text_elems-1) := (others => init_type_drawElement);
    

BEGIN

    -- Concurrent assignments
    KEY_b <= NOT KEY;

    -- disp_en falling edge
    r_disp_en_d <= disp_en when rising_edge(pixel_clk); -- DFF
    r_disp_en_fe <= r_disp_en_d and not disp_en;   -- One-cycle strobe

    -- KEY falling edge
    r_key_d <= KEY when rising_edge(pixel_clk) and r_logic_update='1'; -- DFF
    r_key_fe <= r_key_d and not KEY;   -- One-cycle strobe

    -- Main game FSM
    process(pixel_clk)
    begin
        if rising_edge(pixel_clk) and r_logic_update = '1' then

            -- Debug Logic
            if (r_key_fe(0) = '1' and r_game_active = '1') then
                r_num_lives <= r_num_lives-1;
            end if;

            if (r_key_fe(1) = '1' and r_game_active = '1') then
                r_score <= r_score+500;
            end if;

            case r_game_state is
                when ST_START =>
                    if KEY_b(0) = '1' then
                        r_game_state <= ST_NEW_GAME;
                    else
                        r_game_state <= ST_START;
                    end if;
                when ST_NEW_GAME => 
                    -- Prepare for new game
                    r_score <= 0;
                    r_num_lives <= g_initial_lives;
                    r_obj_reset <= '1';
                    r_game_state <= ST_PLAY;
                when ST_PLAY => 
                    r_obj_reset <= '0';
                    if r_key_fe(1) = '1' then
                        r_game_state <= ST_PAUSE;
                    elsif (r_num_lives = 0) then
                        r_game_state <= ST_GAME_OVER;
                    else
                        r_game_state <= ST_PLAY;
                    end if;
                when ST_PAUSE => 
                    if r_key_fe(1) = '1' then
                        r_game_state <= ST_PLAY;
                    else
                        r_game_state <= ST_PAUSE;
                    end if;
                when ST_GAME_OVER => 
                    if r_key_fe(0) = '1' then
                        r_game_state <= ST_NEW_GAME;
                    else
                        r_game_state <= ST_GAME_OVER;
                    end if;
                when others =>
                    r_game_state <= ST_START;
            
            end case;
        end if;
    end process;

    -- FSM outputs
    process(r_game_state)
    begin
        if r_game_state = ST_PAUSE then
            r_game_paused <= '1';
        else
            r_game_paused <= '0';
        end if;

        if r_game_state = ST_START then
            r_game_wait_start <= '1';
        else
            r_game_wait_start <= '0';
        end if;

        if r_game_state = ST_GAME_OVER then
            r_game_over <= '1';
        else
            r_game_over <= '0';
        end if;

        if (r_game_state /= ST_START) then
            r_game_active <= '1';
        else
            r_game_active <= '0';
        end if;
    end process;

    -- Combi-Logic, draw each pixel for current frame
    PROCESS(disp_en, row, column)

        -- Variables
        variable pix_color_tmp  : integer range 0 to 4095 := 0;
        variable pix_color_slv  : std_logic_vector(11 downto 0) := (others => '0');

    BEGIN

        -- Display time
        IF(disp_en = '1') THEN

            -- Background
            pix_color_tmp := g_bg_color;

            -- Render each object
            if (w_playShipDraw = '1') then
                pix_color_tmp := w_playShipColor;
            end if;
            if (w_hudDraw = '1') then
                pix_color_tmp := w_hudColor;
            end if;
            if (r_game_paused = '1' or r_game_over = '1') then
                pix_color_tmp := darken(pix_color_tmp, 5);
            end if;
            if (w_overlaysDraw = '1') then
                pix_color_tmp := w_overlaysColor;
            end if;


        -- Blanking time
        ELSE                           
            pix_color_tmp := 0;
        END IF;

        -- Assign from variables into real signals
        pix_color_slv := STD_LOGIC_VECTOR(TO_UNSIGNED(pix_color_tmp, pix_color_slv'LENGTH));
        red <= pix_color_slv(11 downto 8);
        green <= pix_color_slv(7 downto 4);
        blue <= pix_color_slv(3 downto 0);
        
    END PROCESS;

    -- Update game state at end of each frame
    process(pixel_clk)

    begin
        if (rising_edge(pixel_clk)) then

            -- Just finished drawing frame, command a logical update
            if (r_disp_en_fe = '1' AND row >= g_screen_height-1 AND column >= g_screen_width-1) then
                r_logic_update <= '1';
            else
                r_logic_update <= '0';
            end if;

        end if;
    end process;

    -- Object update signals
    r_obj_update <= r_logic_update and not r_game_paused and not r_game_over;

    -- Game objects
    U1: entity work.player_ship port map(
        i_clock => pixel_clk,
        i_update_pulse => r_obj_update,
        i_reset_pulse => r_obj_reset,

        accel_scale_x => accel_scale_x, accel_scale_y => accel_scale_y,

        i_row => row,
        i_column => column, 
        i_draw_en => r_game_active,

        o_color => w_playShipColor,
        o_draw => w_playShipDraw
    );

    U2: entity work.hud port map(
        i_clock => pixel_clk,
        i_update_pulse => r_obj_update,
        i_row => row,
        i_column => column,
        i_draw_en => r_game_active,
        i_num_lives => r_num_lives,
        i_score => r_score,
        o_color => w_hudColor,
        o_draw => w_hudDraw,
        inArbiterPortArray => inArbiterPortArray,
        outArbiterPortArray => outArbiterPortArray,
        drawElementArray => drawElementArray
    );

    U3: entity work.overlays port map(
        i_clock => pixel_clk,
        i_update_pulse => r_logic_update,
        i_row => row,
        i_column => column,
        i_draw_en => '1',
        i_score => r_score,
        i_start_screen => r_game_wait_start,
        i_pause_screen => r_game_paused,
        i_game_over_screen => r_game_over,
        o_color => w_overlaysColor,
        o_draw => w_overlaysDraw,
        inArbiterPortArray => inArbiterPortArray,
        outArbiterPortArray => outArbiterPortArray,
        drawElementArray => drawElementArray
    
    );

    -- vgaText
    fontLibraryArbiter: entity work.blockRamArbiter
	generic map(
		numPorts => c_num_text_elems
	)
	port map(
		clk => pixel_clk,
		reset => '0',
		inPortArray => inArbiterPortArray,
		outPortArray => outArbiterPortArray
	);

END behavior;
