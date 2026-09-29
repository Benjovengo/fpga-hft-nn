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
    
    -- Combinational output from hidden neuron 2.
    signal neuron2_comb :
        t_data;

    -- Combinational output from hidden neuron 3.
    signal neuron3_comb :
        t_data;

    -- Combinational output from hidden neuron 4.
    signal neuron4_comb :
        t_data;

    -- Combinational output from hidden neuron 5.
    signal neuron5_comb :
        t_data;

    -- Combinational output from hidden neuron 6.
    signal neuron6_comb :
        t_data;

    -- Combinational output from hidden neuron 7.
    signal neuron7_comb :
        t_data;

    -- =========================================================================
    -- Complete hidden-layer combinational vector
    -- =========================================================================
    --
    -- The eight individually instantiated hidden neurons are collected into one
    -- fixed-size vector.
    --
    -- No generate statement or multidimensional array is involved.
    --
    -- This vector later becomes the input to the hidden-layer pipeline register.
    signal hidden_comb :
        t_hidden_vector;

    -- =========================================================================
    -- Registered hidden-layer vector
    -- =========================================================================
    --
    -- This register forms the pipeline boundary between:
    --
    --     Dense 8 + ReLU
    --
    -- and:
    --
    --     Dense 1
    --
    -- All eight hidden-neuron values are captured simultaneously.
    signal hidden_reg :
        t_hidden_vector :=
        (
            others => (
                others => '0'
            )
        );

    -- =========================================================================
    -- Output Dense-layer combinational result
    -- =========================================================================
    --
    -- output_neuron computes:
    --
    --     Dense 8 -> 1
    --
    -- using the registered hidden-layer vector.
    --
    -- This result is captured into output_data on the next valid clock edge.
    signal output_comb :
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
    -- Hidden neuron 2
    -- =========================================================================

    u_hidden_neuron2 : entity work.hidden_neuron
        port map (
            input_data => input_reg,

            weight0 => C_HIDDEN_WEIGHTS(2)(0),
            weight1 => C_HIDDEN_WEIGHTS(2)(1),
            weight2 => C_HIDDEN_WEIGHTS(2)(2),
            weight3 => C_HIDDEN_WEIGHTS(2)(3),
            weight4 => C_HIDDEN_WEIGHTS(2)(4),
            weight5 => C_HIDDEN_WEIGHTS(2)(5),
            weight6 => C_HIDDEN_WEIGHTS(2)(6),
            weight7 => C_HIDDEN_WEIGHTS(2)(7),

            bias => C_HIDDEN_BIAS(2),

            neuron_out => neuron2_comb
        );
    
    -- =========================================================================
    -- Hidden neuron 3
    -- =========================================================================

    u_hidden_neuron3 : entity work.hidden_neuron
        port map (
            input_data => input_reg,

            weight0 => C_HIDDEN_WEIGHTS(3)(0),
            weight1 => C_HIDDEN_WEIGHTS(3)(1),
            weight2 => C_HIDDEN_WEIGHTS(3)(2),
            weight3 => C_HIDDEN_WEIGHTS(3)(3),
            weight4 => C_HIDDEN_WEIGHTS(3)(4),
            weight5 => C_HIDDEN_WEIGHTS(3)(5),
            weight6 => C_HIDDEN_WEIGHTS(3)(6),
            weight7 => C_HIDDEN_WEIGHTS(3)(7),

            bias => C_HIDDEN_BIAS(3),

            neuron_out => neuron3_comb
        );

    -- =========================================================================
    -- Hidden neuron 4
    -- =========================================================================

    u_hidden_neuron4 : entity work.hidden_neuron
        port map (
            input_data => input_reg,

            weight0 => C_HIDDEN_WEIGHTS(4)(0),
            weight1 => C_HIDDEN_WEIGHTS(4)(1),
            weight2 => C_HIDDEN_WEIGHTS(4)(2),
            weight3 => C_HIDDEN_WEIGHTS(4)(3),
            weight4 => C_HIDDEN_WEIGHTS(4)(4),
            weight5 => C_HIDDEN_WEIGHTS(4)(5),
            weight6 => C_HIDDEN_WEIGHTS(4)(6),
            weight7 => C_HIDDEN_WEIGHTS(4)(7),

            bias => C_HIDDEN_BIAS(4),

            neuron_out => neuron4_comb
        );

    -- =========================================================================
    -- Hidden neuron 5
    -- =========================================================================

    u_hidden_neuron5 : entity work.hidden_neuron
        port map (
            input_data => input_reg,

            weight0 => C_HIDDEN_WEIGHTS(5)(0),
            weight1 => C_HIDDEN_WEIGHTS(5)(1),
            weight2 => C_HIDDEN_WEIGHTS(5)(2),
            weight3 => C_HIDDEN_WEIGHTS(5)(3),
            weight4 => C_HIDDEN_WEIGHTS(5)(4),
            weight5 => C_HIDDEN_WEIGHTS(5)(5),
            weight6 => C_HIDDEN_WEIGHTS(5)(6),
            weight7 => C_HIDDEN_WEIGHTS(5)(7),

            bias => C_HIDDEN_BIAS(5),

            neuron_out => neuron5_comb
        );
    
    -- =========================================================================
    -- Hidden neuron 6
    -- =========================================================================

    u_hidden_neuron6 : entity work.hidden_neuron
        port map (
            input_data => input_reg,

            weight0 => C_HIDDEN_WEIGHTS(6)(0),
            weight1 => C_HIDDEN_WEIGHTS(6)(1),
            weight2 => C_HIDDEN_WEIGHTS(6)(2),
            weight3 => C_HIDDEN_WEIGHTS(6)(3),
            weight4 => C_HIDDEN_WEIGHTS(6)(4),
            weight5 => C_HIDDEN_WEIGHTS(6)(5),
            weight6 => C_HIDDEN_WEIGHTS(6)(6),
            weight7 => C_HIDDEN_WEIGHTS(6)(7),

            bias => C_HIDDEN_BIAS(6),

            neuron_out => neuron6_comb
        );

    -- =========================================================================
    -- Hidden neuron 7
    -- =========================================================================

    u_hidden_neuron7 : entity work.hidden_neuron
        port map (
            input_data => input_reg,

            weight0 => C_HIDDEN_WEIGHTS(7)(0),
            weight1 => C_HIDDEN_WEIGHTS(7)(1),
            weight2 => C_HIDDEN_WEIGHTS(7)(2),
            weight3 => C_HIDDEN_WEIGHTS(7)(3),
            weight4 => C_HIDDEN_WEIGHTS(7)(4),
            weight5 => C_HIDDEN_WEIGHTS(7)(5),
            weight6 => C_HIDDEN_WEIGHTS(7)(6),
            weight7 => C_HIDDEN_WEIGHTS(7)(7),

            bias => C_HIDDEN_BIAS(7),

            neuron_out => neuron7_comb
        );

        -- =========================================================================
    -- Assemble the hidden-layer vector
    -- =========================================================================
    --
    -- Each neuron remains an explicitly instantiated entity.
    --
    -- These assignments simply collect their individual outputs into the
    -- constrained t_hidden_vector representation.
    -- =========================================================================

    hidden_comb(0) <= neuron0_comb;
    hidden_comb(1) <= neuron1_comb;
    hidden_comb(2) <= neuron2_comb;
    hidden_comb(3) <= neuron3_comb;
    hidden_comb(4) <= neuron4_comb;
    hidden_comb(5) <= neuron5_comb;
    hidden_comb(6) <= neuron6_comb;
    hidden_comb(7) <= neuron7_comb;


    -- =========================================================================
    -- Output Dense neuron
    -- =========================================================================
    --
    -- The output neuron receives the registered hidden-layer vector.
    --
    -- It performs:
    --
    --     8 parallel multiplications
    --              |
    --              v
    --       balanced adder tree
    --              |
    --              v
    --        output bias
    --              |
    --              v
    --      fixed-point rescaling
    --              |
    --              v
    --         saturation
    --
    -- There is intentionally no ReLU at the final output because the predicted
    -- return must be able to represent both positive and negative values.
    -- =========================================================================

    u_output_neuron : entity work.output_neuron
        port map (
            hidden_data => hidden_reg,
            prediction  => output_comb
        );

    -- =========================================================================
    -- Known-good diagnostic pipeline
    -- =========================================================================

    process(clk)
    begin

        if rising_edge(clk) then

            if rst = '1' then

                -- Clear the complete hidden-layer pipeline register.
                hidden_reg <= (
                    others => (
                        others => '0'
                    )
                );

                input_reg <= (
                    others => (
                        others => '0'
                    )
                );

                valid_stage0 <= '0';
                valid_stage1 <= valid_stage0;

                -- Capture the complete hidden-layer result one clock after the input vector
                -- was registered.
                --
                -- hidden_comb is purely combinational.
                --
                -- hidden_reg therefore establishes the first arithmetic pipeline boundary.
                if valid_stage0 = '1' then

                    hidden_reg <=
                        hidden_comb;

                end if;

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

                    -- Register the actual output Dense-layer prediction.
                    output_data <=
                        output_comb;

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