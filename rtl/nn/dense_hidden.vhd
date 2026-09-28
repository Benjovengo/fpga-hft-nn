library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;


-- =============================================================================
-- Eight-neuron hidden Dense layer
-- =============================================================================
--
-- This entity instantiates eight independent hidden_neuron blocks.
--
-- All eight neurons receive the same input vector:
--
--                     input_data
--                         |
--          +--------------+--------------+
--          |              |              |
--          v              v              v
--       neuron 0       neuron 1        ...
--          |              |              |
--          v              v              v
--      hidden[0]      hidden[1]     hidden[7]
--
-- Each neuron uses a different row of the trained weight matrix.
--
-- The neurons operate in parallel.
--
-- No pipeline register is implemented here.
-- =============================================================================

entity dense_hidden is
    port (
        -- Eight input features.
        input_data : in t_data_array(
            0 to C_INPUT_SIZE - 1
        );

        -- Eight hidden-layer outputs after ReLU.
        hidden_data : out t_data_array(
            0 to C_HIDDEN_SIZE - 1
        )
    );
end entity;


architecture rtl of dense_hidden is
begin

    -- =========================================================================
    -- Hidden-neuron generation
    -- =========================================================================
    --
    -- Unlike the previous nested arithmetic loop, this generate statement
    -- creates eight independent hierarchy instances.
    --
    -- Each instance is separately visible to Quartus as:
    --
    --     hidden_neuron[0]
    --     hidden_neuron[1]
    --     ...
    --     hidden_neuron[7]
    --
    -- This substantially simplifies the elaboration structure.
    -- =========================================================================

    gen_hidden_neurons :
        for neuron in
            0 to C_HIDDEN_SIZE - 1
        generate

            u_hidden_neuron : entity work.hidden_neuron
                generic map (
                    G_NEURON_INDEX => neuron
                )
                port map (
                    input_data => input_data,
                    neuron_out => hidden_data(neuron)
                );

        end generate;

end architecture;