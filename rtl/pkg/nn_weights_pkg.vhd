library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;

-- =============================================================================
-- Compile-time neural-network parameters.
--
-- IMPORTANT:
-- The constants in this file are demonstration values only so the RTL can be
-- compiled before the Python CSV-to-VHDL generator is added.
--
-- The production flow should generate this package from:
--
--     build/parameters/weights_q.csv
--
-- and the generated package must remain consistent with the CSV indexing:
--
--     weight(neuron, input)
--
-- For the compile-ready example below, the hidden layer is an identity-style
-- mapping and the output averages the positive hidden activations.
-- =============================================================================
package nn_weights_pkg is

    -- Q12 representation of 1.0.
    constant C_Q_ONE : integer := 2 ** C_FRACTION_BITS;

    -- Q12 representation of 0.125.
    constant C_Q_ONE_EIGHTH : integer := 2 ** (C_FRACTION_BITS - 3);

    -- Hidden-layer weights.
    -- Each hidden neuron receives one input with gain 1.0 and all other
    -- weights are zero. This is only a deterministic bring-up parameter set.
    constant C_HIDDEN_WEIGHTS :
        t_weight_matrix(0 to C_HIDDEN_SIZE - 1, 0 to C_INPUT_SIZE - 1) := (
        0 => (to_signed(C_Q_ONE, C_DATA_WIDTH), to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH)),
        1 => (to_signed(0, C_DATA_WIDTH),     to_signed(C_Q_ONE, C_DATA_WIDTH), to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH)),
        2 => (to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(C_Q_ONE, C_DATA_WIDTH), to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH)),
        3 => (to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(C_Q_ONE, C_DATA_WIDTH), to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH)),
        4 => (to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(C_Q_ONE, C_DATA_WIDTH), to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH)),
        5 => (to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(C_Q_ONE, C_DATA_WIDTH), to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH)),
        6 => (to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(C_Q_ONE, C_DATA_WIDTH), to_signed(0, C_DATA_WIDTH)),
        7 => (to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(0, C_DATA_WIDTH),     to_signed(C_Q_ONE, C_DATA_WIDTH))
    );

    -- Hidden-layer biases are zero for the compile-ready demonstration model.
    constant C_HIDDEN_BIAS : t_data_array(0 to C_HIDDEN_SIZE - 1) := (
        others => to_signed(0, C_DATA_WIDTH)
    );

    -- Output-layer weights average the eight positive hidden activations.
    constant C_OUTPUT_WEIGHTS : t_data_array(0 to C_HIDDEN_SIZE - 1) := (
        others => to_signed(C_Q_ONE_EIGHTH, C_DATA_WIDTH)
    );

    -- Output-layer bias is zero for the compile-ready demonstration model.
    constant C_OUTPUT_BIAS : t_data := to_signed(0, C_DATA_WIDTH);

end package;

package body nn_weights_pkg is
end package body;
