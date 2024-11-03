library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Alarm is
    Port (
        Clock        : in std_logic;
        Reset        : in std_logic;  -- Active-low reset signal
        Slide_switch : in std_logic_vector(1 downto 0);
        Hour         : in std_logic_vector(4 downto 0);
        Mins         : in std_logic_vector(5 downto 0);
        Seconds      : in std_logic_vector(5 downto 0);  -- New input for seconds
        Buzzer       : out std_logic
    );
end Alarm;

<<<<<<< HEAD

=======
>>>>>>> 479147f (init)
architecture Behavioral of Alarm is
    signal current_hour     : integer range 0 to 23;
    signal current_min      : integer range 0 to 59;
    signal current_sec      : integer range 0 to 59;

    signal memorized_hour   : integer range 0 to 23 := 0;
    signal memorized_min    : integer range 0 to 59 := 0;

    signal alarm_hour       : integer range 0 to 23 := 0;
    signal alarm_min        : integer range 0 to 59 := 0;

    signal Buzzer_sig       : std_logic := '0';

    signal prev_slide_switch : std_logic_vector(1 downto 0) := "00";

    signal alarm_set        : std_logic := '0';
    signal buzzer_on        : std_logic := '0';

begin
    Buzzer <= Buzzer_sig;

    process(Clock, Reset)
    begin
        if Reset = '0' then  -- Active-low reset
            -- Reset all signals and flags
            Buzzer_sig         <= '0';
            alarm_hour         <= 0;
            alarm_min          <= 0;
            memorized_hour     <= 0;
            memorized_min      <= 0;
            alarm_set          <= '0';
            prev_slide_switch  <= "00";
            buzzer_on          <= '0';
        elsif rising_edge(Clock) then
            -- Convert inputs to integers
            current_hour <= to_integer(unsigned(Hour));
            current_min  <= to_integer(unsigned(Mins));
            current_sec  <= to_integer(unsigned(Seconds));

            -- Detect changes in Slide_switch
            if Slide_switch /= prev_slide_switch then
                -- If Slide_switch changed, reset the alarm_set flag
                alarm_set <= '0';
                buzzer_on  <= '0';
                Buzzer_sig <= '0';
            end if;

            case Slide_switch is
                when "00" | "11" =>  -- Memorize current time
                    Buzzer_sig        <= '0';
                    buzzer_on         <= '0';
                    memorized_hour    <= current_hour;
                    memorized_min     <= current_min;
                    alarm_set         <= '0';  -- Reset alarm_set when in this state

                when "01" =>  -- Trigger every 15 minutes
                    if alarm_set = '0' then
                        -- Initialize alarm time based on memorized time
                        alarm_hour <= (memorized_hour + ((memorized_min + 15) / 60)) mod 24;
                        alarm_min  <= (memorized_min + 15) mod 60;
                        alarm_set  <= '1';
                    end if;

                    -- Check if current time matches alarm time
                    if (current_hour = alarm_hour) and (current_min = alarm_min) then
                        buzzer_on <= '1';
                        -- Schedule next alarm
                        alarm_hour <= (alarm_hour + ((alarm_min + 15) / 60)) mod 24;
                        alarm_min  <= (alarm_min + 15) mod 60;
                    end if;

                when "10" =>  -- Trigger every 1 hour
                    if alarm_set = '0' then
                        -- Initialize alarm time based on memorized time
                        alarm_hour <= (memorized_hour + 1) mod 24;
                        alarm_min  <= memorized_min;
                        alarm_set  <= '1';
                    end if;

                    -- Check if current time matches alarm time
                    if (current_hour = alarm_hour) and (current_min = alarm_min) then
                        buzzer_on <= '1';
                        -- Schedule next alarm
                        alarm_hour <= (alarm_hour + 1) mod 24;
                        -- alarm_min remains the same
                    end if;

                when others =>
                    Buzzer_sig <= '0';
                    buzzer_on  <= '0';
            end case;

            -- Handle buzzer activation based on Seconds input
            if buzzer_on = '1' then
                if current_sec < 3 then
                    Buzzer_sig <= '1';
                else
                    Buzzer_sig <= '0';
                    buzzer_on  <= '0';  -- Stop the buzzer after 3 seconds
                end if;
            else
                Buzzer_sig <= '0';
            end if;

            -- Update prev_slide_switch
            prev_slide_switch <= Slide_switch;
        end if;
    end process;
end Behavioral;
