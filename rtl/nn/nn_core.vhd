library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;
use work.nn_weights_pkg.all;


-- =============================================================================
-- Neural-network core - incremental implementation step 6.2A
-- =============================================================================
--
-- This version introduces exactly ONE real hidden neuron.
--
-- The previous implementation introduced the complete dense_hidden hierarchy:
--
--     generate 8 neurons
--         x
--     8 multipliers each
--
-- in one elaboration step.
--
-- Quartus Prime 25.1 Lite crashed while elaborating that hierarchy.
--
-- This version therefore keeps the known-good diagnostic pipeline and adds
-- only hidden neuron 0.
--
-- There is:
--
--     no generate loop
--     no dense_hidden instance
--     no generic neuron index
--
-- The weights and bias are connected explicitly.
--
-- Pipeline:
--
--     input_data
--         |
--         v
--     input_reg
--         |
--         v
--     hidden_neuron 0
--         |
--         v
--     neuron0_comb
--         |
--         v
--     output_data
--
-- =============================================================================

entity nn_core is
    port (
        -- NN processing clock.
        clk : in std_logic;

        -- Active-high synchronous reset.
        rst : in std_logic;

        -- Indicates that input_data contains a new valid feature vector.
        input_valid : in std_logic;

        -- Eight fixed-point input features.
        input_data : in t_input_vector;

        -- Indicates that output_data is valid.
        output_valid : out std_logic;

        -- Temporary diagnostic output.
        --
        -- For this step it carries the output of hidden neuron 0.
        output_data : out t_data;

        -- Temporary diagnostic latency.
        latency_cycles : out unsigned(
            C_TIMESTAMP_WIDTH - 1 downto 0
        )
    );
end entity;


architecture rtl of nn_core is

    -- =========================================================================
    -- Registered input vector
    -- =========================================================================

    signal input_reg :
        t_input_vector :=
        (
            others => (
                others => '0'
            )
        );


    -- =========================================================================
    -- One real hidden-neuron result
    -- =========================================================================

    signal neuron0_comb :
        t_data;


    -- =========================================================================
    -- Hidden neuron 1 result
    -- =========================================================================
    --
    -- This signal carries the combinational output of hidden neuron 1.
    --
    -- At this stage there is still no hidden-layer register.
    -- The purpose is only to verify that Quartus can elaborate two complete
    -- hidden-neuron arithmetic hierarchies simultaneously.
    signal neuron1_comb :
        t_data;


    -- =========================================================================
    -- Valid pipeline
    -- =========================================================================

    signal valid_stage0 :
        std_logic := '0';

    signal valid_stage1 :
        std_logic := '0';

begin

    -- =============================================================================
    -- Hidden neuron 0
    -- =============================================================================
    --
    -- The weight matrix is represented as an array of t_input_vector objects.
    --
    -- Therefore:
    --
    --     C_HIDDEN_WEIGHTS(0)
    --
    -- selects the complete weight vector belonging to hidden neuron 0.
    --
    -- The second index:
    --
    --     (0) ... (7)
    --
    -- selects the individual feature weight from that vector.
    -- =============================================================================

    u_hidden_neuron0 : entity work.hidden_neuron
        port map (
            -- Registered input feature vector.
            input_data => input_reg,

            -- Eight weights belonging to hidden neuron 0.
            weight0 => C_HIDDEN_WEIGHTS(0)(0),
            weight1 => C_HIDDEN_WEIGHTS(0)(1),
            weight2 => C_HIDDEN_WEIGHTS(0)(2),
            weight3 => C_HIDDEN_WEIGHTS(0)(3),
            weight4 => C_HIDDEN_WEIGHTS(0)(4),
            weight5 => C_HIDDEN_WEIGHTS(0)(5),
            weight6 => C_HIDDEN_WEIGHTS(0)(6),
            weight7 => C_HIDDEN_WEIGHTS(0)(7),

            -- Bias belonging to hidden neuron 0.
            bias => C_HIDDEN_BIAS(0),

            -- Combinational hidden-neuron result.
            neuron_out => neuron0_comb
        );
    
    -- =========================================================================
    -- Hidden neuron 1
    -- =========================================================================
    --
    -- This is the second explicit hidden-neuron instance.
    --
    -- No generate statement is used.
    --
    -- The eight trained/bring-up weights are connected individually from row 1
    -- of C_HIDDEN_WEIGHTS.
    --
    -- Weight indexing uses:
    --
    --     C_HIDDEN_WEIGHTS(neuron)(feature)
    --
    -- rather than a native two-dimensional VHDL array.
    -- =========================================================================

    u_hidden_neuron1 : entity work.hidden_neuron
        port map (
            -- Registered feature vector shared by all hidden neurons.
            input_data => input_reg,

            -- Weights belonging specifically to hidden neuron 1.
            weight0 => C_HIDDEN_WEIGHTS(1)(0),
            weight1 => C_HIDDEN_WEIGHTS(1)(1),
            weight2 => C_HIDDEN_WEIGHTS(1)(2),
            weight3 => C_HIDDEN_WEIGHTS(1)(3),
            weight4 => C_HIDDEN_WEIGHTS(1)(4),
            weight5 => C_HIDDEN_WEIGHTS(1)(5),
            weight6 => C_HIDDEN_WEIGHTS(1)(6),
            weight7 => C_HIDDEN_WEIGHTS(1)(7),

            -- Bias belonging specifically to hidden neuron 1.
            bias => C_HIDDEN_BIAS(1),

            -- Combinational ReLU result.
            neuron_out => neuron1_comb
        );


    -- =========================================================================
    -- Known-good diagnostic pipeline
    -- =========================================================================

    process(clk)
    begin

        if rising_edge(clk) then

            if rst = '1' then

                input_reg <= (
                    others => (
                        others => '0'
                    )
                );

                valid_stage0 <= '0';
                valid_stage1 <= '0';

                output_valid <= '0';

                output_data <= (
                    others => '0'
                );

                latency_cycles <= (
                    others => '0'
                );

            else

                -- -------------------------------------------------------------
                -- Input stage
                -- -------------------------------------------------------------

                valid_stage0 <=
                    input_valid;

                if input_valid = '1' then

                    input_reg <=
                        input_data;

                end if;


                -- -------------------------------------------------------------
                -- Temporary result stage
                -- -------------------------------------------------------------

                valid_stage1 <=
                    valid_stage0;

                output_valid <=
                    valid_stage1;

                if valid_stage1 = '1' then

                    -- Expose the real result of hidden neuron 0.
                    output_data <=
                        neuron0_comb;

                    -- Keep latency hard-coded during arithmetic integration.
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