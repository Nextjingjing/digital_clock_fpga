library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Led_Control is
    generic(
        ClockFreq : integer := 10000000 -- Clock frequency
    );
    port(
        Clock     : in  std_logic;
        reset     : in  std_logic;
        seconds   : in  integer;          -- Input seconds
        led_out   : out std_logic         -- LED output (active low)
    );
end entity Led_Control;

architecture Behavioral of Led_Control is
    -- Calculate PulseTime in the architecture body
    constant PulseTime : integer := ClockFreq / 10; -- 0.1 second pulse duration
    signal prev_seconds : integer := 0;    -- Stores previous value of seconds
    signal led_timer    : integer := 0;    -- Timer for 0.1 second pulse
    signal led_active   : std_logic := '0'; -- Internal signal to control LED
begin
    process(Clock)
    begin
        if rising_edge(Clock) then
            if reset = '0' then
                prev_seconds <= 0;
                led_timer    <= 0;
                led_active   <= '0';
                led_out      <= '1';  -- LED off during reset (active low)
            else
                -- Detect change in seconds
                if seconds /= prev_seconds then
                    prev_seconds <= seconds;
                    led_active   <= '1';   -- Activate LED when seconds change
                    led_timer    <= 0;     -- Reset timer
                end if;

                -- Control LED timing (0.1 second pulse)
                if led_active = '1' then
                    if led_timer < PulseTime then
                        led_timer <= led_timer + 1;
                        led_out   <= '0';   -- Turn LED on (active low)
                    else
                        led_active <= '0';  -- Deactivate LED after 0.1 seconds
                        led_out   <= '1';   -- Turn LED off (active low)
                    end if;
                else
                    led_out <= '1';         -- Ensure LED is off when not active (active low)
                end if;
            end if;
        end if;
    end process;
end architecture Behavioral;
