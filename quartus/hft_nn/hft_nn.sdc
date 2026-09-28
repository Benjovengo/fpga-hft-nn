# =============================================================================
# Primary board clock.
#
# The C5G CLOCK_50_B5B input is a 50 MHz oscillator.
#
#     f = 50 MHz
#
# therefore:
#
#     T = 1 / 50 MHz
#       = 20 ns
# =============================================================================

create_clock \
    -name CLOCK_50_B5B \
    -period 20.000 \
    [get_ports {CLOCK_50_B5B}]


# =============================================================================
# Derive PLL clocks automatically when PLL-generated clocks are introduced
# later in the project.
# =============================================================================

derive_pll_clocks


# =============================================================================
# Automatically derive clock uncertainty for TimeQuest analysis.
# =============================================================================

derive_clock_uncertainty