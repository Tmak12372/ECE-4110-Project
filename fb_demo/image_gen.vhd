-- image_gen: 4096 color test pattern generator with color inhibit
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;

ENTITY image_gen IS
    GENERIC(
        disp_width : integer := 640;
        disp_height: integer := 480
    );  
    PORT(
        disp_en     :  IN   STD_LOGIC;  --display enable ('1' = display time, '0' = blanking time)
        row      :  IN   INTEGER;    --row pixel coordinate (0 to 479)
        column   :  IN   INTEGER;    --column pixel coordinate (0 to 639)
        red      :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');  --red magnitude output to DAC
        green    :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');  --green magnitude output to DAC
        blue     :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0'); --blue magnitude output to DAC

        o_ram_read_req : out std_logic;
        o_ram_addr : out std_logic_vector(25 downto 0);
        i_ram_data : in std_logic_vector(15 downto 0);
        i_fb_start_addr : in integer
    );
END image_gen;

ARCHITECTURE behavior OF image_gen IS

    -- Signals

BEGIN

    -- Concurrent assignments
    o_ram_read_req <= disp_en; -- Request RAM read during display time, always
    
    PROCESS(disp_en, row, column, i_ram_data, i_fb_start_addr)

        -- Variables
        VARIABLE red_tmp     : STD_LOGIC_VECTOR(3 DOWNTO 0);
        VARIABLE green_tmp   : STD_LOGIC_VECTOR(3 DOWNTO 0);
        VARIABLE blue_tmp    : STD_LOGIC_VECTOR(3 DOWNTO 0);
        variable pixel : integer;
        variable read_addr_int : integer; -- 32 bits default

    BEGIN

        -- Display time
        IF(disp_en = '1') THEN

            -- Calculate RAM address
            pixel := column + disp_width*row;
            read_addr_int := i_fb_start_addr + 2*pixel;

            -- Read color from RAM data
            red_tmp := i_ram_data(11 DOWNTO 8);
            green_tmp := i_ram_data(7 DOWNTO 4);
            blue_tmp := i_ram_data(3 downto 0);

        -- Blanking time
        ELSE                           
            red_tmp   := (OTHERS => '0');
            green_tmp := (OTHERS => '0');
            blue_tmp  := (OTHERS => '0');
        END IF;

        -- Assign from variables into real signals
        red <= red_tmp;
        green <= green_tmp;
        blue <= blue_tmp;

        o_ram_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(read_addr_int, o_ram_addr'LENGTH));

        
    END PROCESS;
END behavior;
