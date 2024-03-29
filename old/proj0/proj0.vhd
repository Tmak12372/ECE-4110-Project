library   ieee;
use       ieee.std_logic_1164.all;



entity proj0 is
	
	port(
	
		-- Inputs for image generation
		key            :  IN STD_LOGIC;
		SW0            :  IN STD_LOGIC;
		pixel_clk_m		:	IN	STD_LOGIC;     -- pixel clock for VGA mode being used 
		reset_n_m		:	IN	STD_LOGIC; --active low asycnchronous reset
		
		-- Outputs for image generation 
		
		h_sync_m		:	OUT	STD_LOGIC;	--horiztonal sync pulse
		v_sync_m		:	OUT	STD_LOGIC;	--vertical sync pulse 
		
		
		dFix         : OUT STD_LOGIC_VECTOR(5 downto 0) := "111111";
		ledFix       : OUT STD_LOGIC_VECTOR(9 downto 0) := "0000000000";
		
		GSENSOR_CS_N : OUT	STD_LOGIC;
		GSENSOR_SCLK : OUT	STD_LOGIC;
		GSENSOR_SDI  : INOUT	STD_LOGIC;
		GSENSOR_SDO  : INOUT	STD_LOGIC;		
		
		hex5         : OUT STD_LOGIC_VECTOR(6 downto 0) := "1111111";
		hex4         : OUT STD_LOGIC_VECTOR(6 downto 0) := "1111111";
		
		hex3         : OUT STD_LOGIC_VECTOR(6 downto 0) := "1111111";
		
		hex2         : OUT STD_LOGIC_VECTOR(6 downto 0) := "1111111";
		hex1         : OUT STD_LOGIC_VECTOR(6 downto 0) := "1111111";
		hex0         : OUT STD_LOGIC_VECTOR(6 downto 0) := "1111111";
		
		data_x      : BUFFER STD_LOGIC_VECTOR(15 downto 0);
		data_y      : BUFFER STD_LOGIC_VECTOR(15 downto 0);
		data_z      : BUFFER STD_LOGIC_VECTOR(15 downto 0);
		
		red_m      :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --red magnitude output to DAC
		green_m    :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --green magnitude output to DAC
		blue_m     :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0') --blue magnitude output to DAC
	
	);
	
end proj0;


Architecture arch of proj0 is


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
	
	component hw_image_generator is
	
		port(
			directionx : in std_logic;
			directiony : in std_logic;
			enable  : in std_logic;
			SW0         : IN  STD_LOGIC;
		   key         : IN  STD_LOGIC;
			disp_ena    : IN  STD_LOGIC;  --display enable ('1' = display time, '0' = blanking time)
			row         : IN  INTEGER;    --row pixel coordinate
			column      : IN  INTEGER;    --column pixel coordinate
			red         : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --red magnitude output to DAC
			green       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --green magnitude output to DAC
			blue        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');   --blue magnitude output to DAC
			mainClock   : IN	 STD_LOGIC
			
		);
		
	end component;

component accelerometer_top is 

	port(
	
		max10_clk      :    IN STD_LOGIC;
		GSENSOR_CS_N : OUT	STD_LOGIC;
		GSENSOR_SCLK : OUT	STD_LOGIC;
		GSENSOR_SDI  : INOUT	STD_LOGIC;
		GSENSOR_SDO  : INOUT	STD_LOGIC;	
		data_x      : BUFFER STD_LOGIC_VECTOR(15 downto 0);
		data_y      : BUFFER STD_LOGIC_VECTOR(15 downto 0);
		data_z      : BUFFER STD_LOGIC_VECTOR(15 downto 0)
		
	);
end component;


	Signal directionx,signed_bitx,enable,directiony,signed_bity : std_logic;
	signal pll_OUT_to_vga_controller_IN, dispEn : STD_LOGIC;
	signal rowSignal, colSignal : INTEGER;
begin

-- Just need 3 components for VGA system 
	U1	:	vga_pll_25_175 port map(pixel_clk_m, pll_OUT_to_vga_controller_IN);
	U2	:	vga_controller port map(pll_OUT_to_vga_controller_IN, reset_n_m, h_sync_m, v_sync_m, dispEn, colSignal, rowSignal, open, open);
	U3	:	hw_image_generator port map(directionx,directiony,enable,SW0,key,dispEn, rowSignal, colSignal, red_m, green_m, blue_m,pixel_clk_m);
	U4  : accelerometer_top port map(pixel_clk_m,GSENSOR_CS_N,GSENSOR_SCLK,GSENSOR_SDI,GSENSOR_SDO,data_x,data_y,data_z);
	
	
	dx : process(data_x,data_y)
	Begin
		signed_bitx <= data_x(15);
		signed_bity <= data_y(15);
		if((data_x(11 downto 4) = "11111111") and (data_y(11 downto 4) = "11111111")) then
			enable <= '0';
		else
			enable <= '1';
		end if;
		IF ((signed_bitx = '0')) then
			directionx <= '1';
		else
			directionx <= '0';
		end if;
		IF ((signed_bity = '0')) then
			directiony <= '0';
		else
			directiony <= '1';
		end if;
		
	end process;
	
	
end arch;





















