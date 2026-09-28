library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;
use work.nn_weights_pkg.all;


-- =============================================================================
-- Hidden-layer neuron
-- =============================================================================
--
-- This entity implements one neuron from the hidden Dense layer.
--
-- The neuron index is selected using G_NEURON_INDEX.
--
-- The mathematical operation is:
--
--                        7
--                       ---
--                       \
--     z = bias +          > x[i] * w[i]
--                       /
--                       ---
--                       i=0
--
-- followed by:
--
--     output = ReLU(z)
--
-- The implementation is explicitly divided into:
--
--     8 parallel multipliers
--              |
--              v
--       balanced adder tree
--              |
--              v
--            bias
--              |
--              v
--       fixed-point scaling
--              |
--              v
--            ReLU
--
-- No registers are implemented inside this entity.
--
-- Pipeline registers remain in nn_core so that latency boundaries remain easy
-- to identify and measure.
-- =============================================================================

entity hidden_neuron is
    generic (
        -- Select which row of C_HIDDEN_WEIGHTS and which hidden bias belong to
        -- this neuron instance.
        G_NEURON_INDEX : natural := 0
    );

    port (
        -- Complete eight-element neural-network input vector.
        input_data : in t_data_array(
            0 to C_INPUT_SIZE - 1
        );

        -- Fixed-point neuron result after ReLU.
        neuron_out : out t_data
    );
end entity;


architecture rtl of hidden_neuron is

    -- =========================================================================
    -- Multiplier outputs
    -- =========================================================================

    -- Each multiplication is kept as a separate signal.
    --
    -- This deliberately avoids the nested-loop arithmetic structure that
    -- previously caused problems during Quartus elaboration.
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
    -- Accumulation and fixed-point scaling
    -- =========================================================================

    -- Sum of all eight input-weight products.
    signal product_sum :
        t_acc;

    -- Bias shifted from Q12 into the Q24 product domain.
    signal bias_scaled :
        t_acc;

    -- Product sum plus aligned bias.
    signal accumulator :
        t_acc;

    -- Accumulator shifted back to the configured Q12 scale.
    signal scaled_value :
        t_acc;

begin

    -- =========================================================================
    -- Eight parallel multipliers
    -- =========================================================================

    u_mul0 : entity work.fixed_mul
        port map (
            a => input_data(0),
            b => C_HIDDEN_WEIGHTS(G_NEURON_INDEX, 0),
            product => product0
        );

    u_mul1 : entity work.fixed_mul
        port map (
            a => input_data(1),
            b => C_HIDDEN_WEIGHTS(G_NEURON_INDEX, 1),
            product => product1
        );

    u_mul2 : entity work.fixed_mul
        port map (
            a => input_data(2),
            b => C_HIDDEN_WEIGHTS(G_NEURON_INDEX, 2),
            product => product2
        );

    u_mul3 : entity work.fixed_mul
        port map (
            a => input_data(3),
            b => C_HIDDEN_WEIGHTS(G_NEURON_INDEX, 3),
            product => product3
        );

    u_mul4 : entity work.fixed_mul
        port map (
            a => input_data(4),
            b => C_HIDDEN_WEIGHTS(G_NEURON_INDEX, 4),
            product => product4
        );

    u_mul5 : entity work.fixed_mul
        port map (
            a => input_data(5),
            b => C_HIDDEN_WEIGHTS(G_NEURON_INDEX, 5),
            product => product5
        );

    u_mul6 : entity work.fixed_mul
        port map (
            a => input_data(6),
            b => C_HIDDEN_WEIGHTS(G_NEURON_INDEX, 6),
            product => product6
        );

    u_mul7 : entity work.fixed_mul
        port map (
            a => input_data(7),
            b => C_HIDDEN_WEIGHTS(G_NEURON_INDEX, 7),
            product => product7
        );


    -- =========================================================================
    -- Balanced product accumulation
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
    -- Bias alignment
    -- =========================================================================

    -- The stored bias has C_FRACTION_BITS fractional bits.
    --
    -- The multiplier results contain twice that amount.
    --
    -- Shift the bias left so both values use the same binary-point position.
    bias_scaled <=
        shift_left(
            resize(
                C_HIDDEN_BIAS(
                    G_NEURON_INDEX
                ),
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

    -- Convert the accumulated Q24-like intermediate value back to the neural
    -- network's configured Q12-like representation.
    scaled_value <=
        shift_right(
            accumulator,
            C_FRACTION_BITS
        );


    -- =========================================================================
    -- ReLU and output saturation
    -- =========================================================================

    -- relu_to_data() performs:
    --
    --     negative value -> 0
    --
    -- and otherwise saturates the positive result into t_data.
    neuron_out <=
        relu_to_data(
            scaled_value
        );

end architecture;