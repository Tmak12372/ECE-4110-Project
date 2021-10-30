-- image_gen: Render frames "just-in-time" and handle game logic
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;

ENTITY image_gen IS
    generic (

        -- RGB, 4 bits each
        g_bg_color : integer := 16#FFF#;

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
    component player_ship is
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
    end component;

    component hud is
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
    end component;

    -- Constants

    -- Signals
    SIGNAL KEY_b       : STD_LOGIC_VECTOR(1 DOWNTO 0);
    signal r_disp_en_d : std_logic := '0';   -- Registered disp_en input
    signal r_disp_en_fe : std_logic;         -- Falling edge of disp_en input
    signal r_logic_update : std_logic := '0'; -- Pulse

    signal w_playShipDraw : std_logic;
    signal w_playShipColor: integer range 0 to 4095;

    signal w_hudDraw : std_logic;
    signal w_hudColor: integer range 0 to 4095;

    signal r_num_lives : integer range 0 to g_max_lives := g_initial_lives;
    signal r_score : integer range 0 to g_max_score := 0;

BEGIN

    -- Concurrent assignments
    KEY_b <= NOT KEY;

    -- disp_en falling edge
    r_disp_en_d <= disp_en when rising_edge(pixel_clk); -- DFF
    r_disp_en_fe <= r_disp_en_d and not disp_en;   -- One-cycle strobe

    -- Debug Logic
    process(KEY, SW)
    begin
        if (falling_edge(KEY(0))) then
            if (r_num_lives = g_max_lives) then
                r_num_lives <= 0;
            else
                r_num_lives <= r_num_lives+1;
            end if;
        end if;

        r_score <= to_integer(unsigned(SW));
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

            -- Just finished drawing frame, command all game objects to update
            if (r_disp_en_fe = '1' AND row >= g_screen_height-1 AND column >= g_screen_width-1) then
                r_logic_update <= '1';
            else
                r_logic_update <= '0';
            end if;

        end if;
    end process;


    -- Game objects
    U1: player_ship port map(
        i_clock => pixel_clk,
        i_update_pulse => r_logic_update,

        accel_scale_x => accel_scale_x, accel_scale_y => accel_scale_y,

        i_row => row,
        i_column => column, 

        o_color => w_playShipColor,
        o_draw => w_playShipDraw
    );

    U2: hud port map(
        i_clock => pixel_clk,
        i_update_pulse => r_logic_update,
        i_row => row,
        i_column => column,
        i_num_lives => r_num_lives,
        i_score => r_score,
        o_color => w_hudColor,
        o_draw => w_hudDraw
    );

    

END behavior;
