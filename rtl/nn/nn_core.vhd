library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;


-- =============================================================================
-- Diagnostic neural-network core
-- =============================================================================
--
-- This temporary version does not implement the neural-network arithmetic.
--
-- Its purpose is to verify that:
--
--     Quartus project configuration
--     VHDL package visibility
--     top-level instantiation
--     reset handling
--     valid-signal pipeline
--     latency measurement
--
-- are all working before reintroducing the Dense/ReLU arithmetic.
--
-- The interface is intentionally identical to the real nn_core interface so
-- that hft_nn_top.vhd does not need to change.
--
-- The diagnostic pipeline has two registered valid stages:
--
--     input_valid
--         |
--         v
--     valid_stage0
--         |
--         v
--     valid_stage1
--         |
--         v
--     output_valid
--
-- The reported latency is therefore two clock cycles.
--
-- =============================================================================

entity nn_core is
    port (
        -- Neural-network clock.
        clk : in std_logic;

        -- Active-high synchronous reset.
        rst : in std_logic;

        -- One-clock pulse indicating that input_data contains a new feature
        -- vector that must be accepted by the core.
        input_valid : in std_logic;

        -- Neural-network input feature vector.
        --
        -- The array type and width are defined in nn_types_pkg.
        --
        -- The diagnostic implementation does not currently use these values,
        -- but the port is retained so that the interface remains identical to
        -- the final implementation.
        input_data : in t_data_array(
            0 to C_INPUT_SIZE - 1
        );

        -- One-clock pulse indicating that output_data is valid.
        output_valid : out std_logic;

        -- Neural-network prediction output.
        --
        -- The diagnostic implementation always drives zero.
        output_data : out t_data;

        -- Number of clock cycles between accepted input and valid output.
        latency_cycles : out unsigned(
            C_TIMESTAMP_WIDTH - 1 downto 0
        )
    );
end entity;


architecture rtl of nn_core is

    -- =========================================================================
    -- Valid-signal pipeline
    -- =========================================================================

    -- First registered valid stage.
    --
    -- This captures input_valid on one rising clock edge.
    signal valid_stage0 : std_logic := '0';

    -- Second registered valid stage.
    --
    -- This captures valid_stage0 on the following rising clock edge.
    signal valid_stage1 : std_logic := '0';

begin

    -- =========================================================================
    -- Diagnostic pipeline process
    -- =========================================================================
    --
    -- This process intentionally performs no neural-network arithmetic.
    --
    -- It verifies the control and latency path only.
    --
    -- Signal progression:
    --
    --     cycle N:
    --         input_valid = 1
    --
    --     cycle N+1:
    --         valid_stage0 = 1
    --
    --     cycle N+2:
    --         valid_stage1 = 1
    --         output_valid = 1
    --
    -- Therefore:
    --
    --     latency = 2 clock cycles
    --
    process(clk)
    begin

        if rising_edge(clk) then

            -- -----------------------------------------------------------------
            -- Synchronous reset
            -- -----------------------------------------------------------------

            if rst = '1' then

                -- Clear both valid pipeline stages.
                valid_stage0 <= '0';
                valid_stage1 <= '0';

                -- No output is valid during reset.
                output_valid <= '0';

                -- Drive the diagnostic prediction to zero.
                output_data <= (
                    others => '0'
                );

                -- Clear the latency measurement.
                latency_cycles <= (
                    others => '0'
                );


            -- -----------------------------------------------------------------
            -- Normal operation
            -- -----------------------------------------------------------------

            else

                -- Capture a new input transaction into the first pipeline
                -- stage.
                valid_stage0 <= input_valid;

                -- Advance the valid bit into the second pipeline stage.
                valid_stage1 <= valid_stage0;

                -- output_valid is asserted when the transaction reaches the
                -- second stage.
                output_valid <= valid_stage1;

                -- The diagnostic core always produces zero.
                --
                -- This keeps the output deterministic while testing the
                -- project and control structure.
                output_data <= (
                    others => '0'
                );

                -- Report the expected diagnostic latency.
                --
                -- When valid_stage1 becomes high, the corresponding input was
                -- accepted two clock cycles earlier.
                if valid_stage1 = '1' then

                    latency_cycles <= to_unsigned(
                        2,
                        C_TIMESTAMP_WIDTH
                    );

                end if;

            end if;

        end if;

    end process;

end architecture;