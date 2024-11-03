library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Mode_setter is
    port (
        Clock           : in  std_logic;
        reset           : in  std_logic;
        Set             : in  std_logic;     
        Adjust          : in  std_logic;  -- ปุ่มเดียวสำหรับปรับค่า (เพิ่ม/ลด)
        Up_Down         : in  std_logic;  -- สวิตช์เลื่อนเพื่อกำหนดทิศทางเพิ่ม/ลด

        Current_Minutes : in  integer;  
        Current_Hours   : in  integer;    
        setter_minutes  : out integer;  
        setter_hours    : out integer;    
        Mode            : out integer             
    );
end entity Mode_setter;

architecture behavior of Mode_setter is
    -- Define the possible states
    type state_type is (normal, set_minutes, set_hours);
    signal state             : state_type := normal;   
    signal internal_minutes  : integer := 0;  
    signal internal_hours    : integer := 0;    

    -- Signals for edge detection of Set button
    signal Set_prev          : std_logic := '1'; 
    signal Set_pulse         : std_logic := '0'; 

    -- Signals for edge detection of Adjust button
    signal Adjust_prev       : std_logic := '1'; 
    signal Adjust_pulse      : std_logic := '0'; 

    -- Debounce signals and counters
    constant DEBOUNCE_LIMIT : integer := 200000; -- สำหรับ Clock 10 MHz, 200000 เท่ากับ 20 ms
    signal Set_debounce_cnt : integer := 0;
    signal Set_debounced    : std_logic := '1'; -- เริ่มต้นเป็น '1' (ไม่ถูกกด)
    signal Adjust_debounce_cnt : integer := 0;
    signal Adjust_debounced    : std_logic := '1'; -- เริ่มต้นเป็น '1' (ไม่ถูกกด)

begin

    -- Debounce process for Set button
    debounce_set: process(Clock)
    begin
        if rising_edge(Clock) then
            if reset = '0' then
                Set_debounce_cnt <= 0;
                Set_debounced    <= '1';
            else
                if Set = Set_debounced then
                    -- ไม่มีการเปลี่ยนแปลง, รีเซ็ตตัวนับ
                    Set_debounce_cnt <= 0;
                else
                    -- เพิ่มตัวนับ
                    if Set_debounce_cnt < DEBOUNCE_LIMIT then
                        Set_debounce_cnt <= Set_debounce_cnt + 1;
                    else
                        -- เมื่อถึงขีดจำกัดแล้ว ให้เปลี่ยนสถานะ
                        Set_debounced <= Set;
                        Set_debounce_cnt <= 0;
                    end if;
                end if;
            end if;
        end if;
    end process debounce_set;

    -- Debounce process for Adjust button
    debounce_adjust: process(Clock)
    begin
        if rising_edge(Clock) then
            if reset = '0' then
                Adjust_debounce_cnt <= 0;
                Adjust_debounced    <= '1';
            else
                if Adjust = Adjust_debounced then
                    -- ไม่มีการเปลี่ยนแปลง, รีเซ็ตตัวนับ
                    Adjust_debounce_cnt <= 0;
                else
                    -- เพิ่มตัวนับ
                    if Adjust_debounce_cnt < DEBOUNCE_LIMIT then
                        Adjust_debounce_cnt <= Adjust_debounce_cnt + 1;
                    else
                        -- เมื่อถึงขีดจำกัดแล้ว ให้เปลี่ยนสถานะ
                        Adjust_debounced <= Adjust;
                        Adjust_debounce_cnt <= 0;
                    end if;
                end if;
            end if;
        end if;
    end process debounce_adjust;

    -- Process to detect falling edge of Set button and generate a one-cycle pulse
    edge_detection_set: process(Clock)
    begin
        if rising_edge(Clock) then
            if reset = '0' then
                Set_prev  <= '1';
                Set_pulse <= '0';
            else
                -- Detect falling edge: Set_debounced goes from '1' to '0'
                if (Set_prev = '1' and Set_debounced = '0') then
                    Set_pulse <= '1'; -- Generate a pulse
                else
                    Set_pulse <= '0';
                end if;
                -- Update previous Set state
                Set_prev <= Set_debounced;
            end if;
        end if;
    end process edge_detection_set;

    -- Process to detect falling edge of Adjust button and generate a one-cycle pulse
    edge_detection_adjust: process(Clock)
    begin
        if rising_edge(Clock) then
            if reset = '0' then
                Adjust_prev  <= '1';
                Adjust_pulse <= '0';
            else
                -- Detect falling edge: Adjust_debounced goes from '1' to '0'
                if (Adjust_prev = '1' and Adjust_debounced = '0') then
                    Adjust_pulse <= '1'; -- Generate a pulse
                else
                    Adjust_pulse <= '0';
                end if;
                -- Update previous Adjust state
                Adjust_prev <= Adjust_debounced;
            end if;
        end if;
    end process edge_detection_adjust;

    -- Main process to handle state transitions and settings
    state_machine: process(Clock)
    begin
        if rising_edge(Clock) then
            if reset = '0' then
                -- Reset all signals
                state             <= normal;
                internal_minutes  <= 0;
                internal_hours    <= 0;
                setter_minutes    <= 0;
                setter_hours      <= 0;
                Mode              <= 0;
            else
                -- Change state only on Set_pulse
                if Set_pulse = '1' then
                    case state is
                        when normal =>
                            state <= set_minutes;   
                            Mode  <= 1;
                        when set_minutes =>
                            state <= set_hours;     
                            Mode  <= 2;
                        when set_hours =>
                            state <= normal;        
                            Mode  <= 0;
                        when others =>
                            null;  -- No action
                    end case;
                end if;

                -- Handle settings when not in normal state
                if state /= normal then
                    if Adjust_pulse = '1' then
                        case state is
                            when set_minutes =>
                                if Up_Down = '1' then
                                    internal_minutes <= (internal_minutes + 1) mod 60; 
                                else
                                    if internal_minutes = 0 then
                                        internal_minutes <= 59; 
                                    else
                                        internal_minutes <= internal_minutes - 1;
                                    end if;
                                end if;
                                setter_minutes <= internal_minutes;

                            when set_hours =>
                                if Up_Down = '1' then
                                    internal_hours <= (internal_hours + 1) mod 24; 
                                else
                                    if internal_hours = 0 then
                                        internal_hours <= 23; 
                                    else
                                        internal_hours <= internal_hours - 1;
                                    end if;
                                end if;
                                setter_hours <= internal_hours;

                            when others =>
                                null;  -- No action for other states
                        end case;
                    end if;
                end if;
            end if;
        end if;
    end process state_machine;

end architecture behavior;
