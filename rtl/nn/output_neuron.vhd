library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;
use work.nn_weights_pkg.all;


-- =============================================================================
-- Neural-network output neuron
-- =============================================================================
--
-- This entity implements:
--
--                      7
--                     ---
--                     \
--     y = bias +        > hidden[i] * weight[i]
--                     /
--                     ---
--                     i=0
--
-- Unlike the hidden neurons, no ReLU is applied here.
--
-- The output must remain signed because a predicted return may be:
--
--     positive
--     zero
--     negative
--
-- The structure is:
--
--     8 parallel multipliers
--              |
--              v
--       balanced adder tree
--              |
--              v
--        output bias
--              |
--              v
--      fixed-point scaling
--              |
--              v
--         saturation
-- =============================================================================

entity output_neuron is
    port (
        -- Eight registered hidden-layer values.
        hidden_data : in t_data_array(
            0 to C_HIDDEN_SIZE - 1
        );

        -- Final fixed-point prediction.
        prediction : out t_data
    );
end entity;


architecture rtl of output_neuron is

    -- Full-precision multiplication results.
    signal product0 :
        signed((2 * C_DATA_WIDTH) - 1 downto 0);

    signal product1 :
        signed((2 * C_DATA_WIDTH) - 1 downto 0);

    signal product2 :
        signed((2 * C_DATA_WIDTH) - 1 downto 0);

    signal product3 :
        signed((2 * C_DATA_WIDTH) - 1 downto 0);

    signal product4 :
        signed((2 * C_DATA_WIDTH) - 1 downto 0);

    signal product5 :
        signed((2 * C_DATA_WIDTH) - 1 downto 0);

    signal product6 :
        signed((2 * C_DATA_WIDTH) - 1 downto 0);

    signal product7 :
        signed((2 * C_DATA_WIDTH) - 1 downto 0);

    -- Sum of all eight products.
    signal product_sum :
        t_acc;

    -- Output bias aligned with multiplication precision.
    signal bias_scaled :
        t_acc;

    -- Product sum plus bias.
    signal accumulator :
        t_acc;

    -- Scaled result before final saturation.
    signal scaled_value :
        t_acc;

begin

    -- =========================================================================
    -- Parallel output multipliers
    -- =========================================================================

    u_mul0 : entity work.fixed_mul
        port map (
            a => hidden_data(0),
            b => C_OUTPUT_WEIGHTS(0),
            product => product0
        );

    u_mul1 : entity work.fixed_mul
        port map (
            a => hidden_data(1),
            b => C_OUTPUT_WEIGHTS(1),
            product => product1
        );

    u_mul2 : entity work.fixed_mul
        port map (
            a => hidden_data(2),
            b => C_OUTPUT_WEIGHTS(2),
            product => product2
        );

    u_mul3 : entity work.fixed_mul
        port map (
            a => hidden_data(3),
            b => C_OUTPUT_WEIGHTS(3),
            product => product3
        );

    u_mul4 : entity work.fixed_mul
        port map (
            a => hidden_data(4),
            b => C_OUTPUT_WEIGHTS(4),
            product => product4
        );

    u_mul5 : entity work.fixed_mul
        port map (
            a => hidden_data(5),
            b => C_OUTPUT_WEIGHTS(5),
            product => product5
        );

    u_mul6 : entity work.fixed_mul
        port map (
            a => hidden_data(6),
            b => C_OUTPUT_WEIGHTS(6),
            product => product6
        );

    u_mul7 : entity work.fixed_mul
        port map (
            a => hidden_data(7),
            b => C_OUTPUT_WEIGHTS(7),
            product => product7
        );


    -- =========================================================================
    -- Product accumulation
    -- =========================================================================

    u_adder_tree : entity work.adder_tree_8
        port map (
            p0 => product0,
            p1 => product1,
            p2 => product2,
            p3 => product3,
            p4 => product4,
            p5 => product5,
            p6 => product6,
            p7 => product7,
            sum_out => product_sum
        );


    -- =========================================================================
    -- Output bias alignment
    -- =========================================================================

    bias_scaled <=
        shift_left(
            resize(
                C_OUTPUT_BIAS,
                C_ACC_WIDTH
            ),
            C_FRACTION_BITS
        );


    -- =========================================================================
    -- Bias addition
    -- =========================================================================

    accumulator <=
        product_sum
        +
        bias_scaled;


    -- =========================================================================
    -- Restore the configured fixed-point scale
    -- =========================================================================

    scaled_value <=
        shift_right(
            accumulator,
            C_FRACTION_BITS
        );


    -- =========================================================================
    -- Final signed saturation
    -- =========================================================================

    -- No ReLU is applied.
    --
    -- saturate_to_data() retains both positive and negative predictions while
    -- limiting the value to the t_data range.
    prediction <=
        saturate_to_data(
            scaled_value
        );

end architecture;