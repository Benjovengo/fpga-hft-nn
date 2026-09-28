library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;


-- =============================================================================
-- Eight-input adder tree
-- =============================================================================
--
-- This block adds eight full-precision multiplication results.
--
-- Instead of writing:
--
--     p0 + p1 + p2 + p3 + p4 + p5 + p6 + p7
--
-- as one long arithmetic expression, the additions are organized as a
-- balanced tree:
--
--     p0 ---\
--            +--- sum01 ---\
--     p1 ---/              |
--                          +--- sum0123 ---\
--     p2 ---\              |               |
--            +--- sum23 ---/                |
--     p3 ---/                              |
--                                         +---- sum
--     p4 ---\                              |
--            +--- sum45 ---\                |
--     p5 ---/              |               |
--                          +--- sum4567 ---/
--     p6 ---\              |
--            +--- sum67 ---/
--     p7 ---/
--
-- This structure reduces combinational depth compared with a serial chain of
-- seven additions.
--
-- The accumulator width is defined by C_ACC_WIDTH in nn_types_pkg.
--
-- Each product is extended to the accumulator width before addition.
-- =============================================================================

entity adder_tree_8 is
    port (
        -- Eight full-precision multiplication results.
        p0 : in signed((2 * C_DATA_WIDTH) - 1 downto 0);
        p1 : in signed((2 * C_DATA_WIDTH) - 1 downto 0);
        p2 : in signed((2 * C_DATA_WIDTH) - 1 downto 0);
        p3 : in signed((2 * C_DATA_WIDTH) - 1 downto 0);
        p4 : in signed((2 * C_DATA_WIDTH) - 1 downto 0);
        p5 : in signed((2 * C_DATA_WIDTH) - 1 downto 0);
        p6 : in signed((2 * C_DATA_WIDTH) - 1 downto 0);
        p7 : in signed((2 * C_DATA_WIDTH) - 1 downto 0);

        -- Sum of all eight multiplication results.
        sum_out : out t_acc
    );
end entity;


architecture rtl of adder_tree_8 is

    -- =========================================================================
    -- First adder-tree level
    -- =========================================================================

    signal sum01 : t_acc;
    signal sum23 : t_acc;
    signal sum45 : t_acc;
    signal sum67 : t_acc;


    -- =========================================================================
    -- Second adder-tree level
    -- =========================================================================

    signal sum0123 : t_acc;
    signal sum4567 : t_acc;

begin

    -- =========================================================================
    -- Level 1
    -- =========================================================================

    -- Extend every multiplication result to accumulator width before adding.
    sum01 <=
        resize(p0, C_ACC_WIDTH)
        +
        resize(p1, C_ACC_WIDTH);

    sum23 <=
        resize(p2, C_ACC_WIDTH)
        +
        resize(p3, C_ACC_WIDTH);

    sum45 <=
        resize(p4, C_ACC_WIDTH)
        +
        resize(p5, C_ACC_WIDTH);

    sum67 <=
        resize(p6, C_ACC_WIDTH)
        +
        resize(p7, C_ACC_WIDTH);


    -- =========================================================================
    -- Level 2
    -- =========================================================================

    sum0123 <=
        sum01
        +
        sum23;

    sum4567 <=
        sum45
        +
        sum67;


    -- =========================================================================
    -- Level 3
    -- =========================================================================

    -- Produce the sum of all eight products.
    sum_out <=
        sum0123
        +
        sum4567;

end architecture;