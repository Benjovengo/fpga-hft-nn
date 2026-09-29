library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;
use std.env.all;

use work.nn_types_pkg.all;


-- =============================================================================
-- Self-checking testbench for nn_core
-- =============================================================================
--
-- This testbench verifies the current fixed-point neural-network core.
--
-- The neural-network topology is:
--
--     8 inputs
--         |
--         v
--     Dense 8
--         |
--         v
--       ReLU
--         |
--         v
--     Dense 1
--         |
--         v
-- predicted return
--
--
-- The current demonstration weights implement approximately:
--
--     hidden[0] = ReLU(input[0])
--     hidden[1] = ReLU(input[1])
--     hidden[2] = ReLU(input[2])
--     ...
--     hidden[7] = ReLU(input[7])
--
-- because each hidden neuron has one weight equal to:
--
--     1.0
--
-- represented in Q12 as:
--
--     4096
--
-- while all other hidden-layer weights and biases are zero.
--
--
-- The output layer uses:
--
--     weight = 0.125
--
-- for all eight hidden-neuron outputs.
--
-- In Q12:
--
--     0.125 * 4096 = 512
--
--
-- The test vector is:
--
--     input[0] = +0.25000
--     input[1] = +0.12500
--     input[2] = -0.06250
--     input[3] = +0.50000
--     input[4] = +0.03125
--     input[5] = -0.03125
--     input[6] = +1.00000
--     input[7] = +0.06250
--
-- represented as:
--
--     1024
--      512
--     -256
--     2048
--      128
--     -128
--     4096
--      256
--
--
-- After ReLU:
--
--     +0.25000
--     +0.12500
--      0
--     +0.50000
--     +0.03125
--      0
--     +1.00000
--     +0.06250
--
-- The sum is:
--
--     1.96875
--
-- The output weights are all 0.125:
--
--     1.96875 * 0.125
--     =
--     0.24609375
--
-- In Q12:
--
--     0.24609375 * 4096
--     =
--     1008
--
-- Therefore the expected fixed-point output is:
--
--     1008
--
--
-- The current pipeline latency is:
--
--     input accepted
--          |
--          v
--     input register
--          |
--          | Dense 8 + ReLU
--          v
--     hidden register
--          |
--          | Dense 1
--          v
--     output register
--
-- resulting in:
--
--     2 clock cycles
--
-- from input acceptance to output_valid.
--
-- =============================================================================

entity nn_core_tb is
end entity;


architecture simulation of nn_core_tb is

    -- =========================================================================
    -- Simulation configuration
    -- =========================================================================

    -- Simulation clock period.
    --
    -- A 5 ns period corresponds to 200 MHz.
    --
    -- This simulation frequency does not prove that the physical FPGA can
    -- operate at 200 MHz.
    --
    -- The physical maximum frequency must be verified later with TimeQuest.
    constant C_CLOCK_PERIOD :
        time := 5 ns;


    -- Expected architectural latency of the current NN pipeline.
    constant C_EXPECTED_LATENCY_CYCLES :
        natural := 2;


    -- =========================================================================
    -- Test-vector CSV
    -- =========================================================================
    --
    -- Quartus launches Questa from:
    --
    --     quartus/hft_nn/simulation/questa/
    --
    -- Therefore four ".." levels return to the repository root:
    --
    --     ../../../../
    --
    -- and the generated vector file is:
    --
    --     build/vectors/nn_test_vectors.csv
    --
    constant C_VECTOR_FILE :
        string :=
        "../../../../build/vectors/nn_test_vectors.csv";

    -- Expected output for the deterministic demonstration vector.
    --
    -- Q12:
    --
    --     1008 / 4096
    --     =
    --     0.24609375
    constant C_EXPECTED_OUTPUT :
        integer := 1008;


    -- =========================================================================
    -- DUT signals
    -- =========================================================================

    -- Simulation clock.
    signal clk :
        std_logic := '0';


    -- Active-high synchronous reset.
    signal rst :
        std_logic := '1';


    -- Indicates that a new input vector is valid.
    signal input_valid :
        std_logic := '0';


    -- Complete eight-feature fixed-point input vector.
    signal input_data :
        t_input_vector :=
        (
            others => (
                others => '0'
            )
        );


    -- Indicates that output_data contains a valid NN result.
    signal output_valid :
        std_logic;


    -- Fixed-point NN output.
    signal output_data :
        t_data;


    -- Hardware-measured NN latency.
    signal latency_cycles :
        unsigned(
            C_TIMESTAMP_WIDTH - 1 downto 0
        );


    -- =========================================================================
    -- Testbench debug signals
    -- =========================================================================
    --
    -- These signals are not part of the DUT.
    --
    -- They exist specifically so the progress of the complete test partition
    -- can be inspected graphically in Questa.
    -- =========================================================================

    -- Current CSV test-vector number.
    signal vector_index :
        natural := 0;


    -- Number of vectors that matched the Python reference result.
    signal pass_count_signal :
        natural := 0;


    -- Number of vectors that did not match the Python reference result.
    signal fail_count_signal :
        natural := 0;


begin

    -- =========================================================================
    -- Simulation clock generation
    -- =========================================================================
    --
    -- Toggle the clock every half period:
    --
    --     0 ns     clk = 0
    --     2.5 ns   clk = 1
    --     5 ns     clk = 0
    --     ...
    --
    -- This produces a complete period of 5 ns.
    -- =========================================================================

    clk <=
        not clk
        after C_CLOCK_PERIOD / 2;


    -- =========================================================================
    -- Device under test
    -- =========================================================================

    dut : entity work.nn_core
        port map (
            -- NN processing clock.
            clk => clk,

            -- Active-high synchronous reset.
            rst => rst,

            -- Input transaction valid pulse.
            input_valid => input_valid,

            -- Eight-feature fixed-point input vector.
            input_data => input_data,

            -- Output transaction valid pulse.
            output_valid => output_valid,

            -- Fixed-point network prediction.
            output_data => output_data,

            -- Hardware-measured pipeline latency.
            latency_cycles => latency_cycles
        );


    -- =========================================================================
    -- Stimulus and self-checking process
    -- =========================================================================

        -- =========================================================================
    -- CSV-driven stimulus and self-checking process
    -- =========================================================================
    --
    -- This process reads every vector from:
    --
    --     nn_test_vectors.csv
    --
    -- Each CSV row contains:
    --
    --     x0,x1,x2,x3,x4,x5,x6,x7,expected
    --
    -- For every row:
    --
    --     1. Read all eight quantized inputs.
    --     2. Read the expected Python fixed-point result.
    --     3. Apply the input vector to nn_core.
    --     4. Pulse input_valid for one clock.
    --     5. Wait for output_valid.
    --     6. Verify the two-cycle latency.
    --     7. Compare output_data with expected.
    --     8. Update pass/fail counters.
    --
    -- The process stops only after the complete CSV file has been processed.
    -- =========================================================================

    stimulus : process

        -- ---------------------------------------------------------------------
        -- CSV file
        -- ---------------------------------------------------------------------

        file vector_file :
            text open read_mode is C_VECTOR_FILE;


        -- ---------------------------------------------------------------------
        -- Current CSV line
        -- ---------------------------------------------------------------------

        variable line_in :
            line;


        -- ---------------------------------------------------------------------
        -- CSV parsing variables
        -- ---------------------------------------------------------------------

        -- Temporary integer used when reading x0..x7.
        variable value_int :
            integer;

        -- Expected fixed-point NN output generated by Python.
        variable expected_int :
            integer;

        -- Character separating CSV columns.
        variable comma :
            character;


        -- ---------------------------------------------------------------------
        -- Test statistics
        -- ---------------------------------------------------------------------

        variable vector_count :
            natural := 0;

        variable pass_count :
            natural := 0;

        variable fail_count :
            natural := 0;


        -- ---------------------------------------------------------------------
        -- Latency measurement
        -- ---------------------------------------------------------------------

        variable observed_cycles :
            natural := 0;

    begin

        -- =====================================================================
        -- Step 1: initialize and reset DUT
        -- =====================================================================

        rst <= '1';

        input_valid <= '0';

        input_data <= (
            others => (
                others => '0'
            )
        );


        -- Keep synchronous reset asserted for four rising edges.
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- Allow registered signals to settle.
        wait for 1 ps;


        -- =====================================================================
        -- Step 2: verify reset behavior
        -- =====================================================================

        assert output_valid = '0'
            report
                "output_valid is not low during reset"
            severity failure;

        assert to_integer(output_data) = 0
            report
                "output_data is not zero during reset"
            severity failure;

        assert to_integer(latency_cycles) = 0
            report
                "latency_cycles is not zero during reset"
            severity failure;


        -- =====================================================================
        -- Step 3: release reset
        -- =====================================================================

        rst <= '0';

        wait until rising_edge(clk);
        wait for 1 ps;


        -- =====================================================================
        -- Step 4: skip the CSV header
        -- =====================================================================
        --
        -- First line:
        --
        --     x0,x1,x2,x3,x4,x5,x6,x7,expected
        -- =====================================================================

        if not endfile(vector_file) then

            readline(
                vector_file,
                line_in
            );

        end if;


        -- =====================================================================
        -- Step 5: process every test vector
        -- =====================================================================

        while not endfile(vector_file) loop

            -- -----------------------------------------------------------------
            -- Read one complete CSV row
            -- -----------------------------------------------------------------

            readline(
                vector_file,
                line_in
            );


            -- -----------------------------------------------------------------
            -- Read x0
            -- -----------------------------------------------------------------

            read(
                line_in,
                value_int
            );

            input_data(0) <=
                to_signed(
                    value_int,
                    C_DATA_WIDTH
                );

            read(
                line_in,
                comma
            );


            -- -----------------------------------------------------------------
            -- Read x1
            -- -----------------------------------------------------------------

            read(
                line_in,
                value_int
            );

            input_data(1) <=
                to_signed(
                    value_int,
                    C_DATA_WIDTH
                );

            read(
                line_in,
                comma
            );


            -- -----------------------------------------------------------------
            -- Read x2
            -- -----------------------------------------------------------------

            read(
                line_in,
                value_int
            );

            input_data(2) <=
                to_signed(
                    value_int,
                    C_DATA_WIDTH
                );

            read(
                line_in,
                comma
            );


            -- -----------------------------------------------------------------
            -- Read x3
            -- -----------------------------------------------------------------

            read(
                line_in,
                value_int
            );

            input_data(3) <=
                to_signed(
                    value_int,
                    C_DATA_WIDTH
                );

            read(
                line_in,
                comma
            );


            -- -----------------------------------------------------------------
            -- Read x4
            -- -----------------------------------------------------------------

            read(
                line_in,
                value_int
            );

            input_data(4) <=
                to_signed(
                    value_int,
                    C_DATA_WIDTH
                );

            read(
                line_in,
                comma
            );


            -- -----------------------------------------------------------------
            -- Read x5
            -- -----------------------------------------------------------------

            read(
                line_in,
                value_int
            );

            input_data(5) <=
                to_signed(
                    value_int,
                    C_DATA_WIDTH
                );

            read(
                line_in,
                comma
            );


            -- -----------------------------------------------------------------
            -- Read x6
            -- -----------------------------------------------------------------

            read(
                line_in,
                value_int
            );

            input_data(6) <=
                to_signed(
                    value_int,
                    C_DATA_WIDTH
                );

            read(
                line_in,
                comma
            );


            -- -----------------------------------------------------------------
            -- Read x7
            -- -----------------------------------------------------------------

            read(
                line_in,
                value_int
            );

            input_data(7) <=
                to_signed(
                    value_int,
                    C_DATA_WIDTH
                );

            read(
                line_in,
                comma
            );


            -- -----------------------------------------------------------------
            -- Read expected output
            -- -----------------------------------------------------------------

            read(
                line_in,
                expected_int
            );


            -- =================================================================
            -- Step 6: update vector counter
            -- =================================================================

            vector_count :=
                vector_count + 1;

            vector_index <=
                vector_count;


            -- =================================================================
            -- Step 7: launch one NN inference
            -- =================================================================

            -- Assert input_valid before the next rising edge.
            input_valid <= '1';

            -- The DUT accepts input_data on this edge.
            wait until rising_edge(clk);

            -- End the one-cycle input transaction.
            input_valid <= '0';

            -- Allow registered signals to settle.
            wait for 1 ps;


            -- =================================================================
            -- Step 8: wait for NN output and measure latency
            -- =================================================================

            observed_cycles := 0;

            while output_valid = '0' loop

                wait until rising_edge(clk);

                wait for 1 ps;

                observed_cycles :=
                    observed_cycles + 1;

            end loop;


            -- =================================================================
            -- Step 9: verify external pipeline latency
            -- =================================================================

            assert observed_cycles =
                   C_EXPECTED_LATENCY_CYCLES
                report
                    "Unexpected latency at vector "
                    &
                    integer'image(
                        vector_count
                    )
                    &
                    ". Expected "
                    &
                    integer'image(
                        C_EXPECTED_LATENCY_CYCLES
                    )
                    &
                    " cycles but measured "
                    &
                    integer'image(
                        observed_cycles
                    )
                severity failure;


            -- =================================================================
            -- Step 10: verify internal latency instrumentation
            -- =================================================================

            assert to_integer(
                latency_cycles
            ) =
            C_EXPECTED_LATENCY_CYCLES
                report
                    "Internal latency counter mismatch at vector "
                    &
                    integer'image(
                        vector_count
                    )
                severity failure;


            -- =================================================================
            -- Step 11: compare VHDL output with Python reference output
            -- =================================================================

            if to_integer(
                output_data
            ) =
            expected_int then

                -- -------------------------------------------------------------
                -- PASS
                -- -------------------------------------------------------------

                pass_count :=
                    pass_count + 1;

                pass_count_signal <=
                    pass_count;

            else

                -- -------------------------------------------------------------
                -- FAIL
                -- -------------------------------------------------------------

                fail_count :=
                    fail_count + 1;

                fail_count_signal <=
                    fail_count;

                report
                    "Mismatch at vector "
                    &
                    integer'image(
                        vector_count
                    )
                    &
                    ": expected "
                    &
                    integer'image(
                        expected_int
                    )
                    &
                    ", received "
                    &
                    integer'image(
                        to_integer(
                            output_data
                        )
                    )
                    severity error;

            end if;


            -- =================================================================
            -- Step 12: wait until output_valid returns low
            -- =================================================================
            --
            -- This keeps each transaction independent during the first
            -- full-dataset verification.
            --
            -- Later, this restriction can be removed to test one new input
            -- every clock cycle and verify maximum pipeline throughput.
            -- =================================================================

            wait until rising_edge(clk);
            wait for 1 ps;

            assert output_valid = '0'
                report
                    "output_valid remained high longer than one clock"
                severity failure;

        end loop;


        -- =====================================================================
        -- Step 13: publish final counters to Questa
        -- =====================================================================

        vector_index <=
            vector_count;

        pass_count_signal <=
            pass_count;

        fail_count_signal <=
            fail_count;

        wait for 1 ps;


        -- =====================================================================
        -- Step 14: print final verification summary
        -- =====================================================================

        report
            "============================================"
            severity note;

        report
            "NN RTL verification complete"
            severity note;

        report
            "Total vectors  = "
            &
            integer'image(
                vector_count
            )
            severity note;

        report
            "Passed vectors = "
            &
            integer'image(
                pass_count
            )
            severity note;

        report
            "Failed vectors = "
            &
            integer'image(
                fail_count
            )
            severity note;

        report
            "Expected latency = "
            &
            integer'image(
                C_EXPECTED_LATENCY_CYCLES
            )
            &
            " cycles"
            severity note;

        report
            "============================================"
            severity note;


        -- =====================================================================
        -- Step 15: fail the simulation if any vector mismatched
        -- =====================================================================

        assert fail_count = 0
            report
                "One or more NN RTL verification vectors failed"
            severity failure;


        -- =====================================================================
        -- Step 16: successful completion
        -- =====================================================================

        report
            "All NN test vectors completed successfully"
            severity note;


        -- Stop only after the complete CSV test partition has been processed.
        stop;

        wait;

    end process;

end architecture;
