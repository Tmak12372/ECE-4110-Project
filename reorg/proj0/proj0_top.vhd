-- proj0: Base "FPGA Defender" game
-- Authors: Garrett Carter & Tyler McCormick
-- Top level entity
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity proj0_top is
    PORT( 
        KEY                                : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        SW                                 : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        MAX10_CLK1_50                      : IN STD_LOGIC; -- 50 MHz clock input
        LEDR                               : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        ARDUINO_IO                         : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        HEX5, HEX4, HEX3, HEX2, HEX1, HEX0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        -- Accelerometer I/O
        GSENSOR_CS_N          : OUT   STD_LOGIC;
        GSENSOR_SCLK          : OUT   STD_LOGIC;
        GSENSOR_SDI           : INOUT STD_LOGIC;
        GSENSOR_SDO           : INOUT STD_LOGIC;
        
        -- VGA I/O  
        VGA_HS		         :	OUT	 STD_LOGIC;	-- horizontal sync pulse
        VGA_VS		         :	OUT	 STD_LOGIC;	-- vertical sync pulse 
        
        VGA_R                 :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');  -- red magnitude output to DAC
        VGA_G                 :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');  -- green magnitude output to DAC
        VGA_B                 :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0')   -- blue magnitude output to DAC
    );
end proj0_top;

architecture top_level of proj0_top is

    -- Constants

    -- Component declarations
    component vga_pll_25_175 is 
        port(
            inclk0		:	IN  STD_LOGIC := '0';  -- Input clock that gets divided (50 MHz for max10)
            c0			:	OUT STD_LOGIC          -- Output clock for vga timing (25.175 MHz)
        );
    end component;
    
    component vga_controller is 
        port(
            pixel_clk	:	IN	STD_LOGIC;	--pixel clock at frequency of VGA mode being used
            reset_n		:	IN	STD_LOGIC;	--active low asycnchronous reset
            h_sync		:	OUT	STD_LOGIC;	--horiztonal sync pulse
            v_sync		:	OUT	STD_LOGIC;	--vertical sync pulse
            disp_ena	:	OUT	STD_LOGIC;	--display enable ('1' = display time, '0' = blanking time)
            column		:	OUT	INTEGER;	--horizontal pixel coordinate
            row			:	OUT	INTEGER;	--vertical pixel coordinate
            n_blank		:	OUT	STD_LOGIC;	--direct blacking output to DAC
            n_sync		:	OUT	STD_LOGIC   --sync-on-green output to DAC
        );
    end component;
    
    component image_gen is
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
    end component;

    COMPONENT ADXL345_controller IS
        PORT( reset_n     : IN  STD_LOGIC;
              clk         : IN  STD_LOGIC;
              data_valid  : OUT STD_LOGIC;
              data_x      : OUT STD_LOGIC_VECTOR(15 downto 0);
              data_y      : OUT STD_LOGIC_VECTOR(15 downto 0);
              data_z      : OUT STD_LOGIC_VECTOR(15 downto 0);
              SPI_SDI     : OUT STD_LOGIC;
              SPI_SDO     : IN  STD_LOGIC;
              SPI_CSN     : OUT STD_LOGIC;
              SPI_CLK     : OUT STD_LOGIC );
    END COMPONENT;

    COMPONENT accel_proc is
        port (
            -- Raw data from accelerometer
            data_x      : IN STD_LOGIC_VECTOR(15 downto 0);
            data_y      : IN STD_LOGIC_VECTOR(15 downto 0);
            data_valid  : IN STD_LOGIC;
    
            -- Direction of tilt
            -- x+ : left,    x- : right
            -- y+ : forward, y- : backward
            accel_scale_x, accel_scale_y          : OUT integer := 0 -- A scaled version of data
		);
    end COMPONENT;

    component dual_boot is
		port (
			clk_clk       : in std_logic := 'X'; -- clk
			reset_reset_n : in std_logic := 'X'  -- reset_n
		);
	end component;

    component bin2seg7 IS
        PORT ( inData        : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
            blanking      : IN  STD_LOGIC;
            dispHex       : IN  STD_LOGIC;
            dispPoint     : IN  STD_LOGIC;
            dispDash      : IN  STD_LOGIC;

            -- DP, G, F, E, D, C, B, A
            outSegs       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) );
    END component;
    
    -- Signal declarations
    SIGNAL KEY_b         : STD_LOGIC_VECTOR(1 DOWNTO 0);
    signal clk_25_175_MHz, disp_en : STD_LOGIC;
    signal row, column : INTEGER;

    -- Accelerometer
    signal data_x, data_y                   : STD_LOGIC_VECTOR(15 DOWNTO 0);
    signal data_valid : STD_LOGIC;
    signal accel_scale_x, accel_scale_y     : integer;
    
begin

    -- Concurrent assignments
    KEY_b <= NOT KEY;

    -- Instantiation and port mapping

    -- 7Seg Displays
    U1 : bin2seg7  PORT MAP ( inData => data_x(15 downto 12), blanking => '0', dispHex => '1', 
            dispPoint => '0', dispDash => '0', outSegs => HEX5 );
    U2 : bin2seg7  PORT MAP ( inData => data_x(11 downto 8), blanking => '0', dispHex => '1', 
            dispPoint => '0', dispDash => '0', outSegs => HEX4 );
    U3 : bin2seg7  PORT MAP ( inData => data_x(7 downto 4), blanking => '0', dispHex => '1', 
            dispPoint => '0', dispDash => '0', outSegs => HEX3 );
    U4 : bin2seg7  PORT MAP ( inData => data_x(3 downto 0), blanking => '0', dispHex => '1', 
            dispPoint => '0', dispDash => '0', outSegs => HEX2 );
    U5 : bin2seg7  PORT MAP ( inData => "0000", blanking => '1', dispHex => '1', 
            dispPoint => '0', dispDash => '0', outSegs => HEX1 );
    U6 : bin2seg7  PORT MAP ( inData => "0000", blanking => '1', dispHex => '1', 
            dispPoint => '0', dispDash => '0', outSegs => HEX0 );

    -- Dual boot
    U7 : dual_boot port map ( clk_clk => MAX10_CLK1_50, reset_reset_n => '1' );

    -- VGA
    U8	:	vga_pll_25_175 port map (inclk0 => MAX10_CLK1_50, c0 => clk_25_175_MHz);
    U9	:	vga_controller port map (pixel_clk => clk_25_175_MHz, reset_n => '1', h_sync => VGA_HS, v_sync => VGA_VS, disp_ena => disp_en, column => column, row => row, n_blank => open, n_sync => open);

    -- Accel
    U10 : ADXL345_controller PORT MAP (reset_n => '1', clk => MAX10_CLK1_50, data_valid => data_valid, data_x => data_x,  data_y => data_y, data_z => open, SPI_SDI => GSENSOR_SDI, SPI_SDO => GSENSOR_SDO, SPI_CSN => GSENSOR_CS_N, SPI_CLK => GSENSOR_SCLK );
    U11 : accel_proc  PORT MAP ( data_x => data_x, data_y => data_y, data_valid => data_valid, accel_scale_x => accel_scale_x, accel_scale_y => accel_scale_y );
    
    -- Game Logic
    U12	: image_gen port map (
        pixel_clk => clk_25_175_MHz,
        disp_en => disp_en,
        row => row,
        column => column, 
        red => VGA_R, 
        green => VGA_G, 
        blue => VGA_B,

        accel_scale_x => accel_scale_x,
        accel_scale_y => accel_scale_y,
        KEY => KEY,
        SW => SW
    );

end top_level;