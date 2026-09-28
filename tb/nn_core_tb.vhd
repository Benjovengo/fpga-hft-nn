library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;

-- =============================================================================
-- Self-checking latency-oriented testbench for nn_core.
--
-- This testbench verifies that:
--
-- 1. An input vector can be accepted using input_valid.
-- 2. output_valid appears deterministically after the expected pipeline delay.
-- 3. The hardware latency counter reports the same number of cycles.
--
-- Later, this testbench should be extended to read nn_test_vectors.csv and
-- compare output_data against the Python fixed-point reference results.
-- =============================================================================
entity nn_core_tb is
end entity;

architecture simulation of nn_core_tb is

    -- 200 MHz simulation clock period. This is intentionally faster than the
    -- C5G's raw 50 MHz board oscillator because the final design can later use
    -- a PLL-generated internal NN clock after timing closure is evaluated.
    constant C_CLOCK_PERIOD : time := 5 ns;

    -- Current core pipeline is expected to take two clock cycles from accepted
    -- input to registered output.
    constant C_EXPECTED_LATENCY_CYCLES : natural := 2;

    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal input_valid : std_logic := '0';

    signal input_data : t_data_array(0 to C_INPUT_SIZE - 1) :=
        (others => (others => '0'));

    signal output_valid : std_logic;
    signal output_data : t_data;
    signal latency_cycles : unsigned(C_TIMESTAMP_WIDTH - 1 downto 0);

begin

    -- Free-running simulation clock.
    clk <= not clk after C_CLOCK_PERIOD / 2;

    -- Instantiate the device under test.
    dut : entity work.nn_core
        port map (
            clk => clk,
            rst => rst,
            input_valid => input_valid,
            input_data => input_data,
            output_valid => output_valid,
            output_data => output_data,
            latency_cycles => latency_cycles
        );

    stimulus : process
        variable observed_cycles : natural := 0;
    begin
        -- Hold reset active for several clocks.
        rst <= '1';
        wait for 4 * C_CLOCK_PERIOD;
        wait until rising_edge(clk);
        rst <= '0';

        -- Load a deterministic Q12 input vector.
        input_data(0) <= to_signed(1024, C_DATA_WIDTH);
        input_data(1) <= to_signed(512, C_DATA_WIDTH);
        input_data(2) <= to_signed(-256, C_DATA_WIDTH);
        input_data(3) <= to_signed(2048, C_DATA_WIDTH);
        input_data(4) <= to_signed(128, C_DATA_WIDTH);
        input_data(5) <= to_signed(-128, C_DATA_WIDTH);
        input_data(6) <= to_signed(4096, C_DATA_WIDTH);
        input_data(7) <= to_signed(256, C_DATA_WIDTH);

        -- Present the vector for one valid clock.
        wait until rising_edge(clk);
        input_valid <= '1';

        wait until rising_edge(clk);
        input_valid <= '0';

        -- Count subsequent rising edges until output_valid becomes asserted.
        -- The small delta-cycle wait allows registered outputs from the same
        -- edge to update before they are sampled by the testbench.
        observed_cycles := 0;

        loop
            wait until rising_edge(clk);
            wait for 0 ns;
            observed_cycles := observed_cycles + 1;
            exit when output_valid = '1';
        end loop;

        -- Verify the externally observed pipeline delay.
        assert observed_cycles = C_EXPECTED_LATENCY_CYCLES
            report "Unexpected externally observed NN latency"
            severity failure;

        -- Verify the core's internal timestamp-based measurement.
        assert to_integer(latency_cycles) = C_EXPECTED_LATENCY_CYCLES
            report "Internal NN latency counter does not match expected latency"
            severity failure;

        -- Report useful values in the simulator transcript.
        report "NN latency cycles = " & integer'image(to_integer(latency_cycles));
        report "NN latency time   = " & time'image(C_EXPECTED_LATENCY_CYCLES * C_CLOCK_PERIOD);
        report "NN output integer = " & integer'image(to_integer(output_data));

        -- End the self-checking simulation cleanly.
        report "nn_core_tb completed successfully" severity note;
        wait;
    end process;

end architecture;
