library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;


-- =============================================================================
-- Neural-network quantized weights and biases
-- =============================================================================
--
-- This package contains the fixed-point parameters used by the synthesizable
-- neural-network implementation.
--
-- Current topology:
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
-- The parameters in this file are currently deterministic bring-up values.
--
-- Later, this file should be generated automatically from:
--
--     build/parameters/weights_q.csv
--
--
-- IMPORTANT ARRAY ORGANIZATION
-- ----------------------------
--
-- The hidden-layer weights are represented as an array of 1-D vectors rather
-- than as a native VHDL two-dimensional array.
--
-- Therefore:
--
--     C_HIDDEN_WEIGHTS(0)
--
-- selects the complete weight vector for hidden neuron 0.
--
-- Then:
--
--     C_HIDDEN_WEIGHTS(0)(3)
--
-- selects the weight connecting input feature 3 to hidden neuron 0.
--
-- This avoids native multidimensional array slicing, which has caused
-- problems with the Quartus Prime Standard/Lite VHDL elaborator.
--
-- =============================================================================

package nn_weights_pkg is

    -- =========================================================================
    -- Hidden-layer weight matrix type
    -- =========================================================================
    --
    -- Each array element represents one complete hidden-neuron weight vector.
    --
    -- Structure:
    --
    --     t_hidden_weight_matrix
    --         |
    --         +--> neuron 0 -> 8 weights
    --         +--> neuron 1 -> 8 weights
    --         +--> ...
    --         +--> neuron 7 -> 8 weights
    --
    -- Each row uses t_input_vector, which is already constrained to eight
    -- t_data elements by nn_types_pkg.
    -- =========================================================================

    type t_hidden_weight_matrix is
        array (
            0 to C_HIDDEN_SIZE - 1
        ) of t_input_vector;


    -- =========================================================================
    -- Hidden-layer bias vector
    -- =========================================================================
    --
    -- One signed fixed-point bias is associated with every hidden neuron.
    -- =========================================================================

    type t_hidden_bias_vector is
        array (
            0 to C_HIDDEN_SIZE - 1
        ) of t_data;


    -- =========================================================================
    -- Output-layer weight vector
    -- =========================================================================
    --
    -- The single output neuron receives all eight hidden-layer outputs.
    --
    -- Therefore it requires exactly eight output weights.
    -- =========================================================================

    type t_output_weight_vector is
        array (
            0 to C_HIDDEN_SIZE - 1
        ) of t_data;


    -- =========================================================================
    -- Hidden-layer weights
    -- =========================================================================
    --
    -- The initial bring-up configuration uses an identity-style mapping:
    --
    --     hidden neuron 0 <- input 0
    --     hidden neuron 1 <- input 1
    --     hidden neuron 2 <- input 2
    --     ...
    --     hidden neuron 7 <- input 7
    --
    -- The active connection uses:
    --
    --     1.0
    --
    -- With Q12:
    --
    --     1.0 * 4096 = 4096
    --
    -- All other weights are zero.
    -- =========================================================================

    constant C_HIDDEN_WEIGHTS :
        t_hidden_weight_matrix := (

        -- Hidden neuron 0.
        0 => (
            0 => to_signed(4096, C_DATA_WIDTH),
            1 => to_signed(0,    C_DATA_WIDTH),
            2 => to_signed(0,    C_DATA_WIDTH),
            3 => to_signed(0,    C_DATA_WIDTH),
            4 => to_signed(0,    C_DATA_WIDTH),
            5 => to_signed(0,    C_DATA_WIDTH),
            6 => to_signed(0,    C_DATA_WIDTH),
            7 => to_signed(0,    C_DATA_WIDTH)
        ),

        -- Hidden neuron 1.
        1 => (
            0 => to_signed(0,    C_DATA_WIDTH),
            1 => to_signed(4096, C_DATA_WIDTH),
            2 => to_signed(0,    C_DATA_WIDTH),
            3 => to_signed(0,    C_DATA_WIDTH),
            4 => to_signed(0,    C_DATA_WIDTH),
            5 => to_signed(0,    C_DATA_WIDTH),
            6 => to_signed(0,    C_DATA_WIDTH),
            7 => to_signed(0,    C_DATA_WIDTH)
        ),

        -- Hidden neuron 2.
        2 => (
            0 => to_signed(0,    C_DATA_WIDTH),
            1 => to_signed(0,    C_DATA_WIDTH),
            2 => to_signed(4096, C_DATA_WIDTH),
            3 => to_signed(0,    C_DATA_WIDTH),
            4 => to_signed(0,    C_DATA_WIDTH),
            5 => to_signed(0,    C_DATA_WIDTH),
            6 => to_signed(0,    C_DATA_WIDTH),
            7 => to_signed(0,    C_DATA_WIDTH)
        ),

        -- Hidden neuron 3.
        3 => (
            0 => to_signed(0,    C_DATA_WIDTH),
            1 => to_signed(0,    C_DATA_WIDTH),
            2 => to_signed(0,    C_DATA_WIDTH),
            3 => to_signed(4096, C_DATA_WIDTH),
            4 => to_signed(0,    C_DATA_WIDTH),
            5 => to_signed(0,    C_DATA_WIDTH),
            6 => to_signed(0,    C_DATA_WIDTH),
            7 => to_signed(0,    C_DATA_WIDTH)
        ),

        -- Hidden neuron 4.
        4 => (
            0 => to_signed(0,    C_DATA_WIDTH),
            1 => to_signed(0,    C_DATA_WIDTH),
            2 => to_signed(0,    C_DATA_WIDTH),
            3 => to_signed(0,    C_DATA_WIDTH),
            4 => to_signed(4096, C_DATA_WIDTH),
            5 => to_signed(0,    C_DATA_WIDTH),
            6 => to_signed(0,    C_DATA_WIDTH),
            7 => to_signed(0,    C_DATA_WIDTH)
        ),

        -- Hidden neuron 5.
        5 => (
            0 => to_signed(0,    C_DATA_WIDTH),
            1 => to_signed(0,    C_DATA_WIDTH),
            2 => to_signed(0,    C_DATA_WIDTH),
            3 => to_signed(0,    C_DATA_WIDTH),
            4 => to_signed(0,    C_DATA_WIDTH),
            5 => to_signed(4096, C_DATA_WIDTH),
            6 => to_signed(0,    C_DATA_WIDTH),
            7 => to_signed(0,    C_DATA_WIDTH)
        ),

        -- Hidden neuron 6.
        6 => (
            0 => to_signed(0,    C_DATA_WIDTH),
            1 => to_signed(0,    C_DATA_WIDTH),
            2 => to_signed(0,    C_DATA_WIDTH),
            3 => to_signed(0,    C_DATA_WIDTH),
            4 => to_signed(0,    C_DATA_WIDTH),
            5 => to_signed(0,    C_DATA_WIDTH),
            6 => to_signed(4096, C_DATA_WIDTH),
            7 => to_signed(0,    C_DATA_WIDTH)
        ),

        -- Hidden neuron 7.
        7 => (
            0 => to_signed(0,    C_DATA_WIDTH),
            1 => to_signed(0,    C_DATA_WIDTH),
            2 => to_signed(0,    C_DATA_WIDTH),
            3 => to_signed(0,    C_DATA_WIDTH),
            4 => to_signed(0,    C_DATA_WIDTH),
            5 => to_signed(0,    C_DATA_WIDTH),
            6 => to_signed(0,    C_DATA_WIDTH),
            7 => to_signed(4096, C_DATA_WIDTH)
        )
    );


    -- =========================================================================
    -- Hidden-layer biases
    -- =========================================================================
    --
    -- The bring-up model uses zero bias for every hidden neuron.
    -- =========================================================================

    constant C_HIDDEN_BIAS :
        t_hidden_bias_vector := (
            0 => to_signed(0, C_DATA_WIDTH),
            1 => to_signed(0, C_DATA_WIDTH),
            2 => to_signed(0, C_DATA_WIDTH),
            3 => to_signed(0, C_DATA_WIDTH),
            4 => to_signed(0, C_DATA_WIDTH),
            5 => to_signed(0, C_DATA_WIDTH),
            6 => to_signed(0, C_DATA_WIDTH),
            7 => to_signed(0, C_DATA_WIDTH)
        );


    -- =========================================================================
    -- Output-layer weights
    -- =========================================================================
    --
    -- All output weights use:
    --
    --     0.125
    --
    -- With Q12:
    --
    --     0.125 * 4096
    --     =
    --     512
    --
    -- Therefore the demonstration output approximately averages the positive
    -- hidden-layer values.
    -- =========================================================================

    constant C_OUTPUT_WEIGHTS :
        t_output_weight_vector := (
            0 => to_signed(512, C_DATA_WIDTH),
            1 => to_signed(512, C_DATA_WIDTH),
            2 => to_signed(512, C_DATA_WIDTH),
            3 => to_signed(512, C_DATA_WIDTH),
            4 => to_signed(512, C_DATA_WIDTH),
            5 => to_signed(512, C_DATA_WIDTH),
            6 => to_signed(512, C_DATA_WIDTH),
            7 => to_signed(512, C_DATA_WIDTH)
        );


    -- =========================================================================
    -- Output-layer bias
    -- =========================================================================
    --
    -- The demonstration network uses a zero output bias.
    -- =========================================================================

    constant C_OUTPUT_BIAS :
        t_data :=
        to_signed(
            0,
            C_DATA_WIDTH
        );

end package nn_weights_pkg;