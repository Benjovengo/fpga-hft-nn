library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;


-- =============================================================================
-- Cyclone V GX Starter Kit board-level neural-network bring-up wrapper.
--
-- The final HFT architecture will receive feature vectors from:
--
--     Ethernet
--        |
--        v
--     packet parser
--        |
--        v
--     feature engine
--        |
--        v
--     nn_core
--
-- At this development stage, the Ethernet and feature-engine blocks do not yet
-- exist.
--
-- A fixed feature vector is therefore injected into nn_core whenever KEY1 is
-- pressed.
--
-- Board controls:
--
--     KEY0
--         Active-low reset.
--
--     KEY1
--         Active-low inference trigger.
--
--     LEDG0
--         Latched indication that at least one inference completed.
--
--     LEDR3:0
--         Low four bits of the measured NN latency in clock cycles.
--
-- The expected initial latency is:
--
--     2 cycles
--
-- which appears on the LEDs as:
--
--     LEDR3 LEDR2 LEDR1 LEDR0
--        0     0     1     0
--
-- =============================================================================

entity hft_nn_top is
    port (
        -- 50 MHz oscillator available on the C5G board.
        CLOCK_50_B5B : in std_logic;

        -- Active-low push buttons.
        KEY0 : in std_logic;
        KEY1 : in std_logic;

        -- Green completion LED.
        LEDG0 : out std_logic;

        -- Red LEDs displaying the measured latency.
        LEDR0 : out std_logic;
        LEDR1 : out std_logic;
        LEDR2 : out std_logic;
        LEDR3 : out std_logic
    );
end entity;


architecture rtl of hft_nn_top is

    -- =========================================================================
    -- Demonstration input vector
    -- =========================================================================

    -- This vector is constant for the board bring-up test.
    --
    -- It is therefore declared as a constant instead of a signal.
    --
    -- The previous implementation declared this as:
    --
    --     signal input_data : ... := (...)
    --
    -- but never assigned another value to the signal.
    --
    -- Quartus consequently generated:
    --
    --     Warning (10540):
    --     used explicit default value for signal "input_data"
    --     because signal was never assigned a value
    --
    -- Using a constant accurately expresses the intended hardware behavior and
    -- eliminates that warning.
    --
    -- The values use the configured Q12 representation:
    --
    --     integer value / 4096 = real value
    --
    -- For example:
    --
    --     1024 / 4096 = +0.2500
    --
    constant C_TEST_INPUT : t_data_array(0 to C_INPUT_SIZE - 1) := (
        0 => to_signed( 1024, C_DATA_WIDTH), -- +0.25000
        1 => to_signed(  512, C_DATA_WIDTH), -- +0.12500
        2 => to_signed( -256, C_DATA_WIDTH), -- -0.06250
        3 => to_signed( 2048, C_DATA_WIDTH), -- +0.50000
        4 => to_signed(  128, C_DATA_WIDTH), -- +0.03125
        5 => to_signed( -128, C_DATA_WIDTH), -- -0.03125
        6 => to_signed( 4096, C_DATA_WIDTH), -- +1.00000
        7 => to_signed(  256, C_DATA_WIDTH)  -- +0.06250
    );


    -- =========================================================================
    -- Reset
    -- =========================================================================

    -- Internal active-high synchronous reset.
    --
    -- KEY0 is active-low on the board:
    --
    --     KEY0 = '0' -> button pressed
    --
    -- therefore:
    --
    --     rst = '1'
    signal rst : std_logic;


    -- =========================================================================
    -- KEY1 edge detection
    -- =========================================================================

    -- Previous KEY1 state.
    --
    -- The button is active-low, so its released state is '1'.
    signal key1_d : std_logic := '1';

    -- One-clock pulse indicating that a new NN inference must start.
    signal input_valid : std_logic := '0';


    -- =========================================================================
    -- NN output control
    -- =========================================================================

    -- Valid pulse generated when the NN result reaches its output stage.
    signal output_valid : std_logic;

    -- Number of clocks measured between input acceptance and output validity.
    signal latency_cycles :
        unsigned(C_TIMESTAMP_WIDTH - 1 downto 0);

    -- Sticky flag used to keep LEDG0 illuminated after output_valid returns
    -- low.
    signal done_latched : std_logic := '0';

begin

    -- =========================================================================
    -- Reset conversion
    -- =========================================================================

    -- Convert the board's active-low reset button into the core's active-high
    -- reset.
    rst <= not KEY0;


    -- =========================================================================
    -- KEY1 falling-edge detector
    -- =========================================================================

    process(CLOCK_50_B5B)
    begin
        if rising_edge(CLOCK_50_B5B) then

            if rst = '1' then

                -- Restore the expected released button state.
                key1_d <= '1';

                -- Do not launch an inference while reset is active.
                input_valid <= '0';

            else

                -- Detect:
                --
                --     previous KEY1 = '1'
                --     current  KEY1 = '0'
                --
                -- which represents a button press.
                --
                -- input_valid remains high for exactly one clock.
                input_valid <= key1_d and (not KEY1);

                -- Save the current button state for the next clock.
                key1_d <= KEY1;

            end if;

        end if;
    end process;


    -- =========================================================================
    -- Neural-network inference core
    -- =========================================================================

    u_nn_core : entity work.nn_core
        port map (
            -- NN clock.
            clk => CLOCK_50_B5B,

            -- Synchronous reset.
            rst => rst,

            -- One-clock input handshake.
            input_valid => input_valid,

            -- Constant demonstration vector.
            input_data => C_TEST_INPUT,

            -- One-clock output handshake.
            output_valid => output_valid,

            -- The current board test does not need the actual prediction value.
            --
            -- An output port may therefore be intentionally left open.
            --
            -- The previous implementation connected output_data to a local
            -- signal that was never read, causing Quartus warning 10936.
            output_data => open,

            -- Hardware-measured pipeline latency.
            latency_cycles => latency_cycles
        );


    -- =========================================================================
    -- Completion indication
    -- =========================================================================

    process(CLOCK_50_B5B)
    begin
        if rising_edge(CLOCK_50_B5B) then

            if rst = '1' then

                -- Clear the completion indicator during reset.
                done_latched <= '0';

            elsif output_valid = '1' then

                -- Keep the LED illuminated after an inference has completed.
                done_latched <= '1';

            end if;

        end if;
    end process;


    -- =========================================================================
    -- Board outputs
    -- =========================================================================

    -- Indicate that at least one inference completed successfully.
    LEDG0 <= done_latched;

    -- Display the low four bits of the measured latency.
    --
    -- For the current two-cycle NN pipeline:
    --
    --     decimal 2 = binary 0010
    --
    -- therefore:
    --
    --     LEDR3 = 0
    --     LEDR2 = 0
    --     LEDR1 = 1
    --     LEDR0 = 0
    LEDR0 <= latency_cycles(0);
    LEDR1 <= latency_cycles(1);
    LEDR2 <= latency_cycles(2);
    LEDR3 <= latency_cycles(3);

end architecture;