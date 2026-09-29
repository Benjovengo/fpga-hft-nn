library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;
use work.nn_weights_pkg.all;


-- =============================================================================
-- Fixed-point 8 -> 8 -> 1 neural-network inference core
-- =============================================================================
--
-- The network architecture is:
--
--     8 input features
--          |
--          v
--     input register
--          |
--          v
--     Dense 8
--          |
--          v
--       ReLU
--          |
--          v
--     hidden register
--          |
--          v
--     Dense 1
--          |
--          v
--     output register
--          |
--          v
-- predicted return
--
-- The eight hidden neurons are instantiated explicitly.
--
-- This intentionally avoids:
--
--     generate loops
--     generic neuron indexes
--     native multidimensional weight arrays
--
-- because the previous hierarchy caused Quartus Prime 25.1 Lite to crash
-- during VHDL elaboration.
--
-- The arithmetic pipeline has two registered clock intervals between input
-- acceptance and output validity.
-- =============================================================================

entity nn_core is
    port (
        -- Neural-network processing clock.
        clk : in std_logic;

        -- Active-high synchronous reset.
        rst : in std_logic;

        -- Asserted for one clock when input_data contains a new feature vector.
        input_valid : in std_logic;

        -- Complete eight-feature input vector.
        input_data : in t_input_vector;

        -- Asserted when output_data contains the corresponding prediction.
        output_valid : out std_logic;

        -- Signed fixed-point predicted return.
        output_data : out t_data;

        -- Hardware-measured input-to-output latency in NN clock cycles.
        latency_cycles : out unsigned(
            C_TIMESTAMP_WIDTH - 1 downto 0
        )
    );
end entity;


architecture rtl of nn_core is

    -- =========================================================================
    -- Input pipeline register
    -- =========================================================================

    signal input_reg :
        t_input_vector :=
        (
            others => (
                others => '0'
            )
        );


    -- =========================================================================
    -- Individual combinational hidden-neuron outputs
    -- =========================================================================

    signal neuron0_comb : t_data;
    signal neuron1_comb : t_data;
    signal neuron2_comb : t_data;
    signal neuron3_comb : t_data;
    signal neuron4_comb : t_data;
    signal neuron5_comb : t_data;
    signal neuron6_comb : t_data;
    signal neuron7_comb : t_data;


    -- =========================================================================
    -- Complete hidden-layer vectors
    -- =========================================================================

    signal hidden_comb :
        t_hidden_vector;

    signal hidden_reg :
        t_hidden_vector :=
        (
            others => (
                others => '0'
            )
        );


    -- =========================================================================
    -- Final output-neuron result
    -- =========================================================================

    signal output_comb :
        t_data;


    -- =========================================================================
    -- Valid pipeline
    -- =========================================================================

    signal valid_stage0 :
        std_logic := '0';

    signal valid_stage1 :
        std_logic := '0';


    -- =========================================================================
    -- Latency instrumentation
    -- =========================================================================

    signal cycle_counter :
        unsigned(
            C_TIMESTAMP_WIDTH - 1 downto 0
        ) :=
        (
            others => '0'
        );

    signal timestamp_stage0 :
        unsigned(
            C_TIMESTAMP_WIDTH - 1 downto 0
        ) :=
        (
            others => '0'
        );

    signal timestamp_stage1 :
        unsigned(
            C_TIMESTAMP_WIDTH - 1 downto 0
        ) :=
        (
            others => '0'
        );

begin

    -- =========================================================================
    -- Hidden neuron 0
    -- =========================================================================

    u_hidden_neuron0 : entity work.hidden_neuron
        port map (
            input_data => input_reg,

            weight0 => C_HIDDEN_WEIGHTS(0)(0),
            weight1 => C_HIDDEN_WEIGHTS(0)(1),
            weight2 => C_HIDDEN_WEIGHTS(0)(2),
            weight3 => C_HIDDEN_WEIGHTS(0)(3),
            weight4 => C_HIDDEN_WEIGHTS(0)(4),
            weight5 => C_HIDDEN_WEIGHTS(0)(5),
            weight6 => C_HIDDEN_WEIGHTS(0)(6),
            weight7 => C_HIDDEN_WEIGHTS(0)(7),

            bias => C_HIDDEN_BIAS(0),

            neuron_out => neuron0_comb
        );


    -- =========================================================================
    -- Hidden neuron 1
    -- =========================================================================

    u_hidden_neuron1 : entity work.hidden_neuron
        port map (
            input_data => input_reg,

            weight0 => C_HIDDEN_WEIGHTS(1)(0),
            weight1 => C_HIDDEN_WEIGHTS(1)(1),
            weight2 => C_HIDDEN_WEIGHTS(1)(2),
            weight3 => C_HIDDEN_WEIGHTS(1)(3),
            weight4 => C_HIDDEN_WEIGHTS(1)(4),
            weight5 => C_HIDDEN_WEIGHTS(1)(5),
            weight6 => C_HIDDEN_WEIGHTS(1)(6),
            weight7 => C_HIDDEN_WEIGHTS(1)(7),

            bias => C_HIDDEN_BIAS(1),

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
    -- Assemble complete hidden-layer vector
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

    u_output_neuron : entity work.output_neuron
        port map (
            hidden_data => hidden_reg,
            prediction  => output_comb
        );


    -- =========================================================================
    -- Pipeline and latency instrumentation
    -- =========================================================================

    process(clk)
    begin

        if rising_edge(clk) then

            -- Advance the free-running hardware timestamp.
            cycle_counter <=
                cycle_counter + 1;

            if rst = '1' then

                -- -------------------------------------------------------------
                -- Reset input stage
                -- -------------------------------------------------------------

                input_reg <= (
                    others => (
                        others => '0'
                    )
                );


                -- -------------------------------------------------------------
                -- Reset hidden stage
                -- -------------------------------------------------------------

                hidden_reg <= (
                    others => (
                        others => '0'
                    )
                );


                -- -------------------------------------------------------------
                -- Reset control pipeline
                -- -------------------------------------------------------------

                valid_stage0 <= '0';
                valid_stage1 <= '0';

                output_valid <= '0';


                -- -------------------------------------------------------------
                -- Reset output
                -- -------------------------------------------------------------

                output_data <= (
                    others => '0'
                );


                -- -------------------------------------------------------------
                -- Reset latency instrumentation
                -- -------------------------------------------------------------

                latency_cycles <= (
                    others => '0'
                );

                cycle_counter <= (
                    others => '0'
                );

                timestamp_stage0 <= (
                    others => '0'
                );

                timestamp_stage1 <= (
                    others => '0'
                );

            else

                -- =============================================================
                -- Pipeline stage 0
                -- Accept a new input vector
                -- =============================================================

                valid_stage0 <=
                    input_valid;

                if input_valid = '1' then

                    -- Capture all eight feature values simultaneously.
                    input_reg <=
                        input_data;

                    -- Capture the cycle when this transaction entered the NN.
                    timestamp_stage0 <=
                        cycle_counter;

                end if;


                -- =============================================================
                -- Pipeline stage 1
                -- Register Dense 8 + ReLU
                -- =============================================================

                valid_stage1 <=
                    valid_stage0;

                if valid_stage0 = '1' then

                    -- Capture all eight hidden-neuron outputs.
                    hidden_reg <=
                        hidden_comb;

                    -- Carry the matching input timestamp with the transaction.
                    timestamp_stage1 <=
                        timestamp_stage0;

                end if;


                -- =============================================================
                -- Pipeline stage 2
                -- Register Dense 1
                -- =============================================================

                output_valid <=
                    valid_stage1;

                if valid_stage1 = '1' then

                    -- Register the signed final prediction.
                    output_data <=
                        output_comb;

                    -- Measure deterministic input-to-output latency.
                    latency_cycles <=
                        cycle_counter
                        -
                        timestamp_stage1;

                end if;

            end if;

        end if;

    end process;

end architecture;