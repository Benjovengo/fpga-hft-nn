library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;


-- =============================================================================
-- Fixed-point multiplier
-- =============================================================================
--
-- This block performs one signed fixed-point multiplication.
--
-- Both operands use the neural-network data format defined by nn_types_pkg.
--
-- With the current configuration:
--
--     input width  = 16 bits
--     weight width = 16 bits
--
-- therefore the complete multiplication result requires:
--
--     16 + 16 = 32 bits
--
-- No scaling is performed inside this block.
--
-- If both operands contain C_FRACTION_BITS fractional bits:
--
--     input  = Q12
--     weight = Q12
--
-- then:
--
--     product = Q24
--
-- The later neuron logic is responsible for shifting the accumulated result
-- back by C_FRACTION_BITS.
--
-- Keeping the multiplier as a separate entity also gives Quartus a simple,
-- explicit arithmetic structure from which DSP resources can be inferred.
-- =============================================================================

entity fixed_mul is
    port (
        -- Signed fixed-point input value.
        a : in t_data;

        -- Signed fixed-point weight.
        b : in t_data;

        -- Full-precision signed multiplication result.
        product : out signed(
            (2 * C_DATA_WIDTH) - 1 downto 0
        )
    );
end entity;


architecture rtl of fixed_mul is
begin

    -- Perform the signed multiplication.
    --
    -- numeric_std defines multiplication between signed vectors and returns
    -- the complete result width.
    --
    -- No register is inserted here.
    --
    -- This block is therefore combinational and will eventually be located
    -- between pipeline registers belonging to nn_core.
    product <= a * b;

end architecture;