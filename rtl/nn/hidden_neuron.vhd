library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;


-- =============================================================================
-- Hidden-layer neural-network neuron
-- =============================================================================
--
-- This entity implements exactly one hidden neuron.
--
-- It deliberately does NOT know which hidden neuron number it represents.
--
-- Instead of using:
--
--     G_NEURON_INDEX
--
-- to index a global two-dimensional weight constant, this version receives
-- the eight weights and one bias explicitly.
--
-- This makes the entity simpler for Quartus to elaborate and also makes the
-- hierarchy more explicit.
--
-- Mathematical function:
--
--     z =
--         x0*w0 +
--         x1*w1 +
--         x2*w2 +
--         x3*w3 +
--         x4*w4 +
--         x5*w5 +
--         x6*w6 +
--         x7*w7 +
--         bias
--
-- followed by:
--
--     output = ReLU(z)
--
-- All multipliers operate in parallel.
--
-- No registers are implemented in this entity.
-- Pipeline registers remain in nn_core.
-- =============================================================================

entity hidden_neuron is
    port (
        -- Complete fixed-size NN input vector.
        input_data : in t_input_vector;

        -- Explicit weight for input feature 0.
        weight0 : in t_data;

        -- Explicit weight for input feature 1.
        weight1 : in t_data;

        -- Explicit weight for input feature 2.
        weight2 : in t_data;

        -- Explicit weight for input feature 3.
        weight3 : in t_data;

        -- Explicit weight for input feature 4.
        weight4 : in t_data;

        -- Explicit weight for input feature 5.
        weight5 : in t_data;

        -- Explicit weight for input feature 6.
        weight6 : in t_data;

        -- Explicit weight for input feature 7.
        weight7 : in t_data;

        -- Quantized neuron bias.
        bias : in t_data;

        -- Fixed-point neuron result after ReLU.
        neuron_out : out t_data
    );
end entity;


architecture rtl of hidden_neuron is

    -- =========================================================================
    -- Full-precision multiplier results
    -- =========================================================================

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


    -- =========================================================================
    -- Accumulator signals
    -- =========================================================================

    -- Sum of all eight products.
    signal product_sum :
        t_acc;

    -- Bias shifted into the same binary-point domain as the products.
    signal bias_scaled :
        t_acc;

    -- Complete MAC result before fixed-point rescaling.
    signal accumulator :
        t_acc;

    -- Result after restoring the configured number of fractional bits.
    signal scaled_value :
        t_acc;

begin

    -- =========================================================================
    -- Eight independent multipliers
    -- =========================================================================

    u_mul0 : entity work.fixed_mul
        port map (
            a       => input_data(0),
            b       => weight0,
            product => product0
        );

    u_mul1 : entity work.fixed_mul
        port map (
            a       => input_data(1),
            b       => weight1,
            product => product1
        );

    u_mul2 : entity work.fixed_mul
        port map (
            a       => input_data(2),
            b       => weight2,
            product => product2
        );

    u_mul3 : entity work.fixed_mul
        port map (
            a       => input_data(3),
            b       => weight3,
            product => product3
        );

    u_mul4 : entity work.fixed_mul
        port map (
            a       => input_data(4),
            b       => weight4,
            product => product4
        );

    u_mul5 : entity work.fixed_mul
        port map (
            a       => input_data(5),
            b       => weight5,
            product => product5
        );

    u_mul6 : entity work.fixed_mul
        port map (
            a       => input_data(6),
            b       => weight6,
            product => product6
        );

    u_mul7 : entity work.fixed_mul
        port map (
            a       => input_data(7),
            b       => weight7,
            product => product7
        );


    -- =========================================================================
    -- Balanced eight-product adder tree
    -- =========================================================================

    u_adder_tree : entity work.adder_tree_8
        port map (
            p0      => product0,
            p1      => product1,
            p2      => product2,
            p3      => product3,
            p4      => product4,
            p5      => product5,
            p6      => product6,
            p7      => product7,
            sum_out => product_sum
        );


    -- =========================================================================
    -- Bias alignment
    -- =========================================================================
    --
    -- input Q12 x weight Q12 produces a Q24-style product.
    --
    -- The bias is stored in Q12, so shift it left by C_FRACTION_BITS before
    -- adding it to the products.
    -- =========================================================================

    bias_scaled <=
        shift_left(
            resize(
                bias,
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
    -- Fixed-point rescaling
    -- =========================================================================

    scaled_value <=
        shift_right(
            accumulator,
            C_FRACTION_BITS
        );


    -- =========================================================================
    -- ReLU and output saturation
    -- =========================================================================

    neuron_out <=
        relu_to_data(
            scaled_value
        );

end architecture;