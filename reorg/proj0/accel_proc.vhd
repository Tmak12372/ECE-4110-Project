-- accel_proc: Accelerometer data processing
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;

entity accel_proc is
    port (
        -- Raw data from accelerometer
        data_x      : IN STD_LOGIC_VECTOR(15 downto 0);
        data_y      : IN STD_LOGIC_VECTOR(15 downto 0);
        data_valid  : IN STD_LOGIC;

        -- Direction of tilt
        -- x_dir = '0' : left,    x_dir = '1' : right
        -- y_dir = '0' : forward, y_dir = '1' : backward
        accel_x_dir, accel_y_dir    : OUT STD_LOGIC := '0';
        accel_scale_x, accel_scale_y          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := (others => '0') -- A low-res scaled version of data
    );
end accel_proc;

ARCHITECTURE behavior OF accel_proc IS

    -- Component declarations

    -- Signal declarations

BEGIN

    -- Processes
    process(data_x, data_y, data_valid)
        -- Variables
        variable data_x_abs, data_y_abs   : STD_LOGIC_VECTOR(15 downto 0);
        variable scale_x_tmp, scale_y_tmp : STD_LOGIC_VECTOR(3 downto 0);
    begin
        -- Get absolute value
        if (data_x(15) = '1') then
            data_x_abs := STD_LOGIC_VECTOR(-SIGNED(data_x));
        else
            data_x_abs := data_x;
        end if;
        if (data_y(15) = '1') then
            data_y_abs := STD_LOGIC_VECTOR(-SIGNED(data_y));
        else
            data_y_abs := data_y;
        end if;
        
        -- A nice number in the range 0-7
        IF ((data_x_abs(8 DOWNTO 5) > "0111")) THEN
            scale_x_tmp := "0111";
        ELSE
            scale_x_tmp := data_x_abs(8 DOWNTO 5);
        END IF;
        IF ((data_y_abs(8 DOWNTO 5) > "0111")) THEN
            scale_y_tmp := "0111";
        ELSE
            scale_y_tmp := data_y_abs(8 DOWNTO 5);
        END IF;

        -- Sample new data if it's valid, or hold old data
        if (data_valid = '1') then
            accel_x_dir <= data_x(15);
            accel_x_dir <= data_y(15);
            accel_scale_x <= scale_x_tmp;
            accel_scale_y <= scale_y_tmp;
        end if;

    end process;

    

    -- Instantiation and port mapping

    -- Concurrent assignments
    
    

END behavior;

