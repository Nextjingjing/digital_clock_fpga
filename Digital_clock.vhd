library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Digital_clock is
    generic (
        ClockFreq : integer := 10000000  -- 10 MHz clock frequency
    );
    port (
        Clock          : in  std_logic;
        reset          : in  std_logic;
        Seconds        : out integer;
        Minutes        : out integer;
        Hours          : out integer;
        
        Set_Hours      : in  integer := 0;  
        Set_Minutes    : in  integer := 0; 
        Set_Seconds    : in  integer := 0; 
        Set_Enable     : in  std_logic := '0'; 
        
        Min_pin1       : out std_logic_vector(3 downto 0) := "0000";
        Min_pin2       : out std_logic_vector(3 downto 0) := "0000";
        Hur_pin1       : out std_logic_vector(3 downto 0) := "0000";
        Hur_pin2       : out std_logic_vector(3 downto 0) := "0000"
    );
end entity Digital_clock;

architecture behavior of Digital_clock is
    signal counts           : integer := 0;
    signal internal_seconds : integer := 0;
    signal internal_minutes : integer := 0;
    signal internal_hours   : integer := 0;
begin
    -- Assign internal signals to output ports
    Seconds <= internal_seconds;
    Minutes <= internal_minutes;
    Hours   <= internal_hours;

    process(Clock)
    begin
        if rising_edge(Clock) then
            if reset = '0' then
                -- Reset all internal values to 0
                counts            <= 0;
                internal_seconds  <= 0;
                internal_minutes  <= 0;
                internal_hours    <= 0;
                Min_pin1          <= "0000";
                Min_pin2          <= "0000";
                Hur_pin1          <= "0000";
                Hur_pin2          <= "0000";
            elsif Set_Enable = '1' then
                -- Setting Mode: Update internal time based on Set inputs
                internal_hours   <= Set_Hours mod 24;     
                internal_minutes <= Set_Minutes mod 60;   
                internal_seconds <= Set_Seconds mod 60;   
                
                -- Update display pins based on set values
                Min_pin1 <= std_logic_vector(to_unsigned(Set_Minutes mod 10, 4));
                Min_pin2 <= std_logic_vector(to_unsigned(Set_Minutes / 10, 4));
                Hur_pin1 <= std_logic_vector(to_unsigned(Set_Hours mod 10, 4));
                Hur_pin2 <= std_logic_vector(to_unsigned(Set_Hours / 10, 4));
            else
                -- Normal Counting Mode
                if counts = ClockFreq - 1 then
                    counts <= 0;
                    
                    if internal_seconds = 59 then
                        internal_seconds <= 0;
                        
                        if internal_minutes = 59 then
                            internal_minutes <= 0;
									 Min_pin1 <= "0000";
                            Min_pin2 <= "0000";
                            
                            if internal_hours = 23 then
                                internal_hours <= 0;
										  Hur_pin1          <= "0000";
										  Hur_pin2          <= "0000";
                            else
                                internal_hours <= internal_hours + 1;
                                
                                -- Update display pins for hours
                                Hur_pin1 <= std_logic_vector(to_unsigned((internal_hours + 1) mod 10, 4));
                                Hur_pin2 <= std_logic_vector(to_unsigned((internal_hours + 1) / 10, 4));
                            end if;
                        else
                            internal_minutes <= internal_minutes + 1;
                            
                            -- Update display pins for minutes
                            Min_pin1 <= std_logic_vector(to_unsigned((internal_minutes + 1) mod 10, 4));
                            Min_pin2 <= std_logic_vector(to_unsigned((internal_minutes + 1) / 10, 4));
                        end if;
                    else
                        internal_seconds <= internal_seconds + 1;
                    end if;
                else
                    counts <= counts + 1;
                end if;
            end if;
        end if;
    end process;
end architecture behavior;
