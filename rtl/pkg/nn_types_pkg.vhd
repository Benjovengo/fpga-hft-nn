library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- =============================================================================
-- Neural-network common types and fixed-point helper functions
-- =============================================================================
--
-- This package centralizes:
--
--     neural-network dimensions
--     fixed-point widths
--     array types
--     constrained vector subtypes
--     accumulator type
--     saturation
--     ReLU
--
-- The current network topology is:
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
-- The fixed-point representation currently uses:
--
--     C_DATA_WIDTH     = 16 bits
--     C_FRACTION_BITS  = 12 bits
--
-- Therefore:
--
--     integer 4096
--
-- represents:
--
--     4096 / 2^12
--     =
--     1.0
--
-- Examples:
--
--        real value      stored integer
--
--           1.0000            4096
--           0.5000            2048
--           0.2500            1024
--           0.0000               0
--          -0.5000           -2048
--          -1.0000           -4096
--
-- =============================================================================

package nn_types_pkg is

    -- =========================================================================
    -- Neural-network dimensions
    -- =========================================================================

    -- Number of neural-network input features.
    --
    -- The software feature order is:
    --
    --     0 -> return_1
    --     1 -> return_2
    --     2 -> return_4
    --     3 -> momentum_8
    --     4 -> range_1
    --     5 -> volume_delta_1
    --     6 -> volume_ratio_4
    --     7 -> volatility_8
    constant C_INPUT_SIZE :
        positive := 8;


    -- Number of neurons in the hidden Dense layer.
    constant C_HIDDEN_SIZE :
        positive := 8;


    -- Number of output neurons.
    --
    -- The current network performs regression and produces one predicted
    -- return.
    constant C_OUTPUT_SIZE :
        positive := 1;


    -- =========================================================================
    -- Fixed-point representation
    -- =========================================================================

    -- Number of bits used by:
    --
    --     NN input features
    --     NN weights
    --     NN biases
    --     hidden outputs
    --     final prediction
    constant C_DATA_WIDTH :
        positive := 16;


    -- Number of implied fractional bits.
    --
    -- The binary scale is:
    --
    --     2^12 = 4096
    constant C_FRACTION_BITS :
        natural := 12;


    -- Integer representation of 1.0.
    --
    -- This corresponds to:
    --
    --     1 << C_FRACTION_BITS
    constant C_FIXED_SCALE :
        integer :=
        2 ** C_FRACTION_BITS;


    -- =========================================================================
    -- Intermediate arithmetic widths
    -- =========================================================================

    -- Width of a full signed multiplication result.
    --
    -- A signed multiplication between:
    --
    --     16-bit input
    --
    -- and:
    --
    --     16-bit weight
    --
    -- produces:
    --
    --     32-bit product
    constant C_PRODUCT_WIDTH :
        positive :=
        2 * C_DATA_WIDTH;


    -- Width of the Dense-layer accumulator.
    --
    -- The accumulator is deliberately wider than the 32-bit multiplication
    -- result because up to eight products plus a bias are accumulated.
    --
    -- Forty bits gives substantial headroom for the current 8-input network.
    constant C_ACC_WIDTH :
        positive := 40;


    -- Width of the free-running timestamp counter used for latency
    -- instrumentation.
    --
    -- 32 bits is much larger than required for a two-cycle pipeline but keeps
    -- the instrumentation reusable when more pipeline stages are added later.
    constant C_TIMESTAMP_WIDTH :
        positive := 32;


    -- =========================================================================
    -- Basic fixed-point data type
    -- =========================================================================

    -- Signed fixed-point value used throughout the neural network.
    --
    -- The binary point is implied rather than stored explicitly.
    subtype t_data is
        signed(
            C_DATA_WIDTH - 1 downto 0
        );


    -- =========================================================================
    -- Generic data array
    -- =========================================================================

    -- Generic array of fixed-point neural-network values.
    --
    -- This type remains unconstrained so it can be reused inside packages and
    -- local signals.
    --
    -- However, entity ports should preferably use the constrained subtypes
    -- declared below when compiling with Quartus Prime Lite/Standard.
    type t_data_array is
        array (
            natural range <>
        ) of t_data;


    -- =========================================================================
    -- Explicitly constrained vector subtypes
    -- =========================================================================
    --
    -- These fixed-size subtypes are deliberately provided because Quartus
    -- Prime Standard/Lite can be more reliable when entity ports do not carry
    -- unconstrained composite array types.
    --
    -- They also make the NN interface explicit:
    --
    --     t_input_vector
    --         exactly 8 feature values
    --
    --     t_hidden_vector
    --         exactly 8 hidden-neuron values
    --
    -- =========================================================================

    -- Complete NN input vector.
    subtype t_input_vector is
        t_data_array(
            0 to C_INPUT_SIZE - 1
        );


    -- Complete hidden-layer vector.
    subtype t_hidden_vector is
        t_data_array(
            0 to C_HIDDEN_SIZE - 1
        );


    -- =========================================================================
    -- Accumulator type
    -- =========================================================================

    -- Wide signed arithmetic value used by:
    --
    --     adder trees
    --     Dense-layer accumulators
    --     bias alignment
    --     fixed-point rescaling
    subtype t_acc is
        signed(
            C_ACC_WIDTH - 1 downto 0
        );


    -- =========================================================================
    -- Fixed-point helper function declarations
    -- =========================================================================

    -- Saturate a wide signed value into the configured t_data range.
    --
    -- Values larger than the maximum representable t_data value are clipped
    -- to:
    --
    --     +32767
    --
    -- for a 16-bit signed representation.
    --
    -- Values smaller than the minimum are clipped to:
    --
    --     -32768
    function saturate_to_data(
        value : t_acc
    ) return t_data;


    -- Apply ReLU and then saturate to t_data.
    --
    -- ReLU is:
    --
    --     ReLU(x) = max(0, x)
    --
    -- Therefore:
    --
    --     negative value -> 0
    --     positive value -> saturated positive result
    function relu_to_data(
        value : t_acc
    ) return t_data;

end package;


-- =============================================================================
-- Package body
-- =============================================================================

package body nn_types_pkg is

    -- =========================================================================
    -- Saturation helper
    -- =========================================================================

    function saturate_to_data(
        value : t_acc
    ) return t_data is

        -- ---------------------------------------------------------------------
        -- Maximum representable t_data value
        -- ---------------------------------------------------------------------
        --
        -- For a signed C_DATA_WIDTH-bit value:
        --
        --     maximum = 2^(C_DATA_WIDTH - 1) - 1
        --
        -- With C_DATA_WIDTH = 16:
        --
        --     maximum = 32767
        constant C_DATA_MAX :
            integer :=
            (2 ** (C_DATA_WIDTH - 1)) - 1;


        -- ---------------------------------------------------------------------
        -- Minimum representable t_data value
        -- ---------------------------------------------------------------------
        --
        -- For a signed C_DATA_WIDTH-bit value:
        --
        --     minimum = -2^(C_DATA_WIDTH - 1)
        --
        -- With C_DATA_WIDTH = 16:
        --
        --     minimum = -32768
        constant C_DATA_MIN :
            integer :=
            -(2 ** (C_DATA_WIDTH - 1));


        -- Wide accumulator-domain representation of the positive limit.
        constant C_MAX_ACC :
            t_acc :=
            to_signed(
                C_DATA_MAX,
                C_ACC_WIDTH
            );


        -- Wide accumulator-domain representation of the negative limit.
        constant C_MIN_ACC :
            t_acc :=
            to_signed(
                C_DATA_MIN,
                C_ACC_WIDTH
            );

    begin

        -- ---------------------------------------------------------------------
        -- Positive saturation
        -- ---------------------------------------------------------------------

        if value > C_MAX_ACC then

            return to_signed(
                C_DATA_MAX,
                C_DATA_WIDTH
            );


        -- ---------------------------------------------------------------------
        -- Negative saturation
        -- ---------------------------------------------------------------------

        elsif value < C_MIN_ACC then

            return to_signed(
                C_DATA_MIN,
                C_DATA_WIDTH
            );


        -- ---------------------------------------------------------------------
        -- Value already fits
        -- ---------------------------------------------------------------------

        else

            -- Resize preserves the signed two's-complement value because the
            -- range check above has already guaranteed that no information is
            -- lost.
            return resize(
                value,
                C_DATA_WIDTH
            );

        end if;

    end function;


    -- =========================================================================
    -- ReLU helper
    -- =========================================================================

    function relu_to_data(
        value : t_acc
    ) return t_data is
    begin

        -- The MSB of a signed two's-complement value is the sign bit.
        --
        -- If it is high, the value is negative and ReLU returns zero.
        if value(
            value'high
        ) = '1' then

            return to_signed(
                0,
                C_DATA_WIDTH
            );

        else

            -- Positive values are passed through the normal saturation
            -- function.
            --
            -- This protects against the case where a positive accumulator is
            -- larger than can be represented by t_data.
            return saturate_to_data(
                value
            );

        end if;

    end function;

end package body;