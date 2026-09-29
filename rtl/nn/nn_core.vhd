library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;


-- =============================================================================
-- Neural-network core - incremental implementation step 6.1
-- =============================================================================
--
-- This version adds only the input register to the already verified diagnostic
-- pipeline.
--
-- No neural-network arithmetic is instantiated yet.
--
-- Purpose:
--
--     Verify that Quartus can elaborate and synthesize the complete
--     t_data_array input register before any Dense-layer hierarchy is added.
--
-- Pipeline:
--
--     input_data
--         |
--         v
--     input_reg
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
-- The prediction remains zero.
-- =============================================================================

entity nn_core is
    port (
        -- Processing clock.
        clk : in std_logic;

        -- Active-high synchronous reset.
        rst : in std_logic;

        -- Asserted for one clock when input_data contains a valid vector.
        input_valid : in std_logic;

        -- Eight fixed-point neural-network input features.
        input_data : in t_data_array(
            0 to C_INPUT_SIZE - 1
        );

        -- Asserted when the diagnostic output is valid.
        output_valid : out std_logic;

        -- Diagnostic output value.
        output_data : out t_data;

        -- Diagnostic pipeline latency.
        latency_cycles : out unsigned(
            C_TIMESTAMP_WIDTH - 1 downto 0
        )
    );
end entity;


architecture rtl of nn_core is

    -- =========================================================================
    -- Input feature register
    -- =========================================================================

    -- Capture the complete input vector when input_valid is asserted.
    signal input_reg :
        t_data_array(
            0 to C_INPUT_SIZE - 1
        ) :=
        (
            others => (
                others => '0'
            )
        );


    -- =========================================================================
    -- Valid pipeline
    -- =========================================================================

    signal valid_stage0 : std_logic := '0';
    signal valid_stage1 : std_logic := '0';

begin

    process(clk)
    begin

        if rising_edge(clk) then

            if rst = '1' then

                -- Clear all input feature registers.
                input_reg <= (
                    others => (
                        others => '0'
                    )
                );

                -- Clear the valid pipeline.
                valid_stage0 <= '0';
                valid_stage1 <= '0';

                -- Clear diagnostic outputs.
                output_valid <= '0';

                output_data <= (
                    others => '0'
                );

                latency_cycles <= (
                    others => '0'
                );

            else

                -- Advance the valid pipeline.
                valid_stage0 <= input_valid;
                valid_stage1 <= valid_stage0;

                -- Capture a complete feature vector.
                if input_valid = '1' then

                    input_reg <=
                        input_data;

                end if;

                -- Produce the diagnostic valid signal.
                output_valid <=
                    valid_stage1;

                -- The NN arithmetic is not implemented yet.
                output_data <= (
                    others => '0'
                );

                -- Preserve the known two-cycle diagnostic latency.
                if valid_stage1 = '1' then

                    latency_cycles <=
                        to_unsigned(
                            2,
                            C_TIMESTAMP_WIDTH
                        );

                end if;

            end if;

        end if;

    end process;

end architecture;