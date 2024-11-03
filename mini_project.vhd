library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mini_project is
    port (
        Clock           : in  std_logic;                       -- System clock input
        reset           : in  std_logic;                       -- Reset input (active low)
        Set             : in  std_logic;                       -- Mode Set signal
        Adjust          : in  std_logic;                       -- Adjust button signal
        Up_Down         : in  std_logic;                       -- Up/Down signal for mode setter
        Slide_switch    : in  std_logic_vector(1 downto 0);    -- Slide switch input for Alarm
        led_out         : out std_logic;                       -- LED output
        Buzzer          : out std_logic;                       -- Buzzer output from Alarm
        seven_seg_min1  : out std_logic_vector (6 downto 0);   -- 7-segment for Minutes (first digit)
        seven_seg_min2  : out std_logic_vector (6 downto 0);   -- 7-segment for Minutes (second digit)
        seven_seg_hur1  : out std_logic_vector (6 downto 0);   -- 7-segment for Hours (first digit)
        seven_seg_hur2  : out std_logic_vector (6 downto 0)    -- 7-segment for Hours (second digit)
    );
end entity mini_project;

architecture Behavioral of mini_project is
    -- Internal signals
    signal Seconds        : integer := 0;
    signal Minutes        : integer := 0;
    signal Hours          : integer := 0;
    signal Min_pin1       : std_logic_vector(3 downto 0) := "0000";
    signal Min_pin2       : std_logic_vector(3 downto 0) := "0000";
    signal Hur_pin1       : std_logic_vector(3 downto 0) := "0000";
    signal Hur_pin2       : std_logic_vector(3 downto 0) := "0000";
    signal setter_minutes : integer := 0;  -- Minutes set by Mode_setter
    signal setter_hours   : integer := 0;  -- Hours set by Mode_setter
    signal Mode           : integer := 0;  -- Mode state (0: normal, 1: set minutes, 2: set hours)

    -- Additional signal for Set_Enable
    signal set_enable_signal : std_logic := '0'; -- Initialized to '0'

    -- Constants
    constant ClockFreq : integer := 10000000; -- 10 MHz clock frequency

    -- Additional signals for Alarm module
    signal current_hour : std_logic_vector(4 downto 0);
    signal current_min  : std_logic_vector(5 downto 0);
    signal current_sec  : std_logic_vector(5 downto 0);
begin
    -- Convert Hours, Minutes, and Seconds to std_logic_vector for Alarm module
    current_hour <= std_logic_vector(to_unsigned(Hours, 5));
    current_min  <= std_logic_vector(to_unsigned(Minutes, 6));
    current_sec  <= std_logic_vector(to_unsigned(Seconds, 6));

    -- Concurrent signal assignment to compute Set_Enable
    set_enable_signal <= '1' when (Mode /= 0) else '0';

    -- Instance of Mode_setter with Adjust and Debounce
    mode_setter_inst: entity work.Mode_setter
        port map (
            Clock           => Clock,
            reset           => reset,
            Set             => Set,
            Adjust          => Adjust,
            Up_Down         => Up_Down,
            Current_Minutes => Minutes,
            Current_Hours   => Hours,
            setter_minutes  => setter_minutes,
            setter_hours    => setter_hours,
            Mode            => Mode
        );

    -- Instance of Digital_clock
    digital_clock_inst: entity work.Digital_clock
        generic map (
            ClockFreq => ClockFreq
        )
        port map (
            Clock       => Clock,
            reset       => reset,
            Seconds     => Seconds,
            Minutes     => Minutes,
            Hours       => Hours,
            Set_Hours   => setter_hours,
            Set_Minutes => setter_minutes,
            Set_Seconds => 0,                       -- Not using second setting from Mode_setter
            Set_Enable  => set_enable_signal,       -- Use the precomputed signal
            Min_pin1    => Min_pin1,
            Min_pin2    => Min_pin2,
            Hur_pin1    => Hur_pin1,
            Hur_pin2    => Hur_pin2
        );

    -- Instance of Led_Control
    led_control_inst: entity work.Led_Control
        generic map (
            ClockFreq => ClockFreq
        )
        port map (
            Clock    => Clock,
            reset    => reset,
            seconds  => Seconds,        -- Read-only input
            led_out  => led_out
        );

    -- Instance of BDC_to_7_segmen for Minutes (first digit)
    bdc_to_7seg_min1: entity work.BDC_to_7_segmen
        port map (
            BCD_i     => Min_pin1,          -- Already std_logic_vector
            clk_i     => Clock,
            seven_seg => seven_seg_min1
        );

    -- Instance of BDC_to_7_segmen for Minutes (second digit)
    bdc_to_7seg_min2: entity work.BDC_to_7_segmen
        port map (
            BCD_i     => Min_pin2,
            clk_i     => Clock,
            seven_seg => seven_seg_min2
        );

    -- Instance of BDC_to_7_segmen for Hours (first digit)
    bdc_to_7seg_hur1: entity work.BDC_to_7_segmen
        port map (
            BCD_i     => Hur_pin1,
            clk_i     => Clock,
            seven_seg => seven_seg_hur1
        );

    -- Instance of BDC_to_7_segmen for Hours (second digit)
    bdc_to_7seg_hur2: entity work.BDC_to_7_segmen
        port map (
            BCD_i     => Hur_pin2,
            clk_i     => Clock,
            seven_seg => seven_seg_hur2
        );

    -- Instance of Alarm module
    alarm_inst: entity work.Alarm
        port map (
            Clock        => Clock,
            Reset        => reset,           -- Active-low reset
            Slide_switch => Slide_switch,
            Hour         => current_hour,
            Mins         => current_min,
            Seconds      => current_sec,     -- Pass the current seconds
            Buzzer       => Buzzer
        );
end architecture Behavioral;
