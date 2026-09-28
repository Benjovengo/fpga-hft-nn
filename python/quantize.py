import numpy as np

from config.model_config import (
    FIXED_SCALE,
    FIXED_WIDTH,
)


# =============================================================================
# Fixed-point representation
# =============================================================================

# The FPGA implementation will not use TensorFlow floating-point values
# directly.
#
# Instead, neural-network parameters and input features are represented using
# signed fixed-point integers.
#
# The current project configuration uses:
#
#     FIXED_WIDTH   = 16
#     FRACTION_BITS = 12
#     FIXED_SCALE   = 2^12 = 4096
#
# Conceptually, a real number x is converted to a fixed-point integer using:
#
#     q = round(x * FIXED_SCALE)
#
# For the current configuration:
#
#     q = round(x * 4096)
#
# Examples:
#
#     floating point        fixed-point integer
#
#         1.0000      ->          4096
#         0.5000      ->          2048
#         0.2500      ->          1024
#         0.0000      ->             0
#        -0.5000      ->         -2048
#        -1.0000      ->         -4096
#
# The integer does not itself contain a decimal point.
#
# The position of the binary point is implied by FRACTION_BITS:
#
#                     fixed_integer
#     real_value = ----------------------
#                     FIXED_SCALE
#
# Therefore:
#
#                     fixed_integer
#     real_value = ----------------------
#                         4096
#
# for the current Q-format.
#
# This representation can later be implemented directly using signed integer
# arithmetic in VHDL.


# =============================================================================
# Minimum representable fixed-point integer
# =============================================================================

def fixed_min():
    """Return the minimum signed integer representable by FIXED_WIDTH bits."""

    # A signed two's-complement integer with W bits has the range:
    #
    #     -2^(W-1)
    #
    # through:
    #
    #     2^(W-1) - 1
    #
    # Therefore, for:
    #
    #     FIXED_WIDTH = 16
    #
    # the minimum integer is:
    #
    #     -2^15
    #     =
    #     -32768
    #
    # The left shift:
    #
    #     1 << (FIXED_WIDTH - 1)
    #
    # calculates:
    #
    #     2^(FIXED_WIDTH - 1)
    #
    # Negating the result gives the minimum signed value.
    return -(
        1
        <<
        (
            FIXED_WIDTH
            -
            1
        )
    )


# =============================================================================
# Maximum representable fixed-point integer
# =============================================================================

def fixed_max():
    """Return the maximum signed integer representable by FIXED_WIDTH bits."""

    # The maximum signed two's-complement integer for W bits is:
    #
    #     2^(W-1) - 1
    #
    # For:
    #
    #     FIXED_WIDTH = 16
    #
    # this becomes:
    #
    #     2^15 - 1
    #     =
    #     32767
    return (
        1
        <<
        (
            FIXED_WIDTH
            -
            1
        )
    ) - 1


# =============================================================================
# Scalar quantization
# =============================================================================

def quantize_scalar(value):
    """Convert one floating-point value to the configured fixed-point format."""

    # Quantization consists of three main operations:
    #
    #     floating-point value
    #             |
    #             v
    #          scaling
    #             |
    #             v
    #          rounding
    #             |
    #             v
    #         saturation
    #             |
    #             v
    #     fixed-point integer


    # -------------------------------------------------------------------------
    # Step 1: scaling and rounding
    # -------------------------------------------------------------------------

    # Multiply the floating-point value by the fixed-point scale.
    #
    # With:
    #
    #     FRACTION_BITS = 12
    #
    # the scale is:
    #
    #     FIXED_SCALE = 4096
    #
    # For example:
    #
    #     value = 0.5
    #
    # produces:
    #
    #     0.5 * 4096
    #     =
    #     2048
    #
    # np.round() selects the nearest integer representation.
    #
    # A value that cannot be represented exactly is therefore mapped to the
    # closest available fixed-point step.
    scaled = np.round(
        value
        *
        FIXED_SCALE
    )


    # -------------------------------------------------------------------------
    # Step 2: saturation
    # -------------------------------------------------------------------------

    # Restrict the scaled integer to the range representable by FIXED_WIDTH.
    #
    # For a signed 16-bit representation:
    #
    #     minimum = -32768
    #     maximum =  32767
    #
    # If:
    #
    #     scaled > 32767
    #
    # the result becomes:
    #
    #     32767
    #
    # If:
    #
    #     scaled < -32768
    #
    # the result becomes:
    #
    #     -32768
    #
    # This behavior is called saturation.
    #
    # Saturation is preferable to silently allowing integer overflow because
    # overflow could wrap a large positive number into a negative number or a
    # large negative number into a positive number.
    clipped = np.clip(
        scaled,
        fixed_min(),
        fixed_max(),
    )


    # -------------------------------------------------------------------------
    # Step 3: integer conversion
    # -------------------------------------------------------------------------

    # Convert the NumPy numerical value to a standard Python integer.
    #
    # The returned integer is the bit-level numerical value that will later
    # be exported for use by the fixed-point reference model and VHDL.
    return int(
        clipped
    )


# =============================================================================
# Array quantization
# =============================================================================

def quantize_array(values):
    """Quantize an array of floating-point values."""

    # Neural-network weights and biases are stored as arrays rather than
    # individual scalar values.
    #
    # NumPy allows the complete array to be quantized using vectorized
    # arithmetic instead of calling quantize_scalar() for every element.
    #
    # The processing is mathematically identical:
    #
    #     floating-point array
    #             |
    #             v
    #      multiply by scale
    #             |
    #             v
    #           round
    #             |
    #             v
    #          saturate
    #             |
    #             v
    #       integer array


    # -------------------------------------------------------------------------
    # Step 1: scaling and rounding
    # -------------------------------------------------------------------------

    # Multiply every array element by FIXED_SCALE and round each result to the
    # nearest integer.
    #
    # For example:
    #
    #     values =
    #
    #         [0.50, -0.25, 1.00]
    #
    # becomes approximately:
    #
    #         [2048, -1024, 4096]
    #
    # for FIXED_SCALE = 4096.
    scaled = np.round(
        values
        *
        FIXED_SCALE
    )


    # -------------------------------------------------------------------------
    # Step 2: saturation
    # -------------------------------------------------------------------------

    # Saturate every element to the configured signed integer range.
    clipped = np.clip(
        scaled,
        fixed_min(),
        fixed_max(),
    )


    # -------------------------------------------------------------------------
    # Step 3: integer-array conversion
    # -------------------------------------------------------------------------

    # Convert the result to signed 64-bit NumPy integers.
    #
    # int64 is used here as a convenient software container.
    #
    # This does NOT mean that the FPGA representation is 64 bits wide.
    #
    # The valid numerical values have already been restricted to the range
    # defined by FIXED_WIDTH.
    #
    # With FIXED_WIDTH = 16:
    #
    #     -32768 <= value <= 32767
    #
    # The later CSV export records FIXED_WIDTH explicitly so the VHDL side
    # knows the intended hardware representation.
    return clipped.astype(
        np.int64
    )


# =============================================================================
# Scalar dequantization
# =============================================================================

def dequantize_scalar(value):
    """Convert one fixed-point integer back to floating point."""

    # Dequantization performs the inverse scaling operation:
    #
    #                     fixed_integer
    #     real_value = ----------------------
    #                     FIXED_SCALE
    #
    # For example:
    #
    #     fixed integer = 2048
    #     FIXED_SCALE   = 4096
    #
    # gives:
    #
    #     2048 / 4096
    #     =
    #     0.5
    #
    # This function is useful when comparing:
    #
    #     TensorFlow floating-point values
    #
    # against:
    #
    #     quantized fixed-point values
    #
    # during verification and debugging.
    return (
        float(value)
        /
        FIXED_SCALE
    )


# =============================================================================
# Quantization flow
# =============================================================================

# This module provides the numerical conversion used between TensorFlow
# training and the eventual FPGA implementation.
#
# The complete parameter flow is:
#
# python/train.py
#       |
#       v
# floating-point NN
#       |
#       v
# weights_float.npz
#       |
#       v
# +-----------------------------+
# |     python/quantize.py      |
# |                             |
# | floating-point value        |
# |          |                  |
# |          v                  |
# | multiply by FIXED_SCALE     |
# |          |                  |
# |          v                  |
# |        round                |
# |          |                  |
# |          v                  |
# |       saturate              |
# |          |                  |
# |          v                  |
# | signed fixed-point integer  |
# +-----------------------------+
#       |
#       v
# python/export_weights.py
#       |
#       v
# weights_q.csv
#       |
#       +----------------------+
#       |                      |
#       v                      v
# Python fixed-point         VHDL
# reference model          NN core


# =============================================================================
# Fixed-point multiplication
# =============================================================================

# The quantized values use an implied fractional scale.
#
# Consider two real values:
#
#     a
#     b
#
# Their quantized representations are:
#
#     A = round(a * FIXED_SCALE)
#
# and:
#
#     B = round(b * FIXED_SCALE)
#
# Multiplication produces:
#
#     A * B
#
# which approximately represents:
#
#     a * b * FIXED_SCALE^2
#
# Therefore, the multiplication result contains twice as many implied
# fractional bits.
#
# With FRACTION_BITS = 12:
#
#     input
#         Q12
#
#     weight
#         Q12
#
#     multiplication
#         Q24
#
# To return to Q12 after the MAC operation, the result must eventually be
# divided by:
#
#     2^12
#
# which is equivalent to a right shift by:
#
#     FRACTION_BITS
#
# in integer arithmetic.
#
# Conceptually:
#
#     input Q12
#        |
#        |\
#        | \
#        |  X weight Q12
#        | /
#        |/
#        v
#     product Q24
#        |
#        v
#     accumulator
#        |
#        v
#     >> FRACTION_BITS
#        |
#        v
#      result Q12


# =============================================================================
# Bias scaling
# =============================================================================

# Biases require special attention during the multiply-accumulate operation.
#
# A quantized bias is initially represented in the same Q format as the
# inputs and weights:
#
#     bias = Q12
#
# However, the products produced by:
#
#     input * weight
#
# contain:
#
#     12 + 12 = 24 fractional bits
#
# Therefore, if accumulation is performed at product precision, the bias must
# be aligned with the Q24 product before addition.
#
# One approach is:
#
#     accumulator = bias << FRACTION_BITS
#
# followed by:
#
#     accumulator += input * weight
#
# for each MAC operation.
#
# Finally:
#
#     result = accumulator >> FRACTION_BITS
#
# This is the approach that the Python fixed-point reference model and VHDL
# implementation should reproduce consistently.


# =============================================================================
# Rounding and saturation requirements for VHDL
# =============================================================================

# Bit-accurate FPGA verification requires Python and VHDL to implement exactly
# the same numerical rules.
#
# The important rules include:
#
#     input width
#     weight width
#     bias width
#     accumulator width
#     number of fractional bits
#     multiplication width
#     rounding behavior
#     saturation behavior
#     right-shift behavior
#
# This file currently defines parameter quantization as:
#
#     scale
#       |
#       v
#     np.round()
#       |
#       v
#     np.clip()
#
# The eventual RTL implementation must use compatible behavior wherever the
# same numerical conversion occurs.
#
# In particular, the accumulator should normally be wider than FIXED_WIDTH.
#
# Using only FIXED_WIDTH bits for an accumulator could overflow while adding
# multiple products even when the final neural-network output would fit into
# FIXED_WIDTH bits.
#
# The exact accumulator width should therefore be defined explicitly before
# freezing the VHDL arithmetic architecture.


# =============================================================================
# Important distinction: storage width versus calculation width
# =============================================================================

# FIXED_WIDTH currently describes the representation used for quantized
# parameters and NN interface values.
#
# It does NOT imply that every intermediate FPGA signal should also have
# FIXED_WIDTH bits.
#
# For example:
#
#     16-bit input
#          X
#     16-bit weight
#          |
#          v
#     32-bit product
#          |
#          v
#     wider accumulator
#          |
#          v
#     scaling / rounding / saturation
#          |
#          v
#     16-bit result
#
# Maintaining wider intermediate values avoids unnecessary precision loss and
# reduces the risk of arithmetic overflow.


# =============================================================================
# Relationship to the FPGA implementation
# =============================================================================

# TensorFlow performs training using floating-point arithmetic.
#
# The FPGA performs inference using fixed-point arithmetic.
#
# Therefore:
#
#                     SOFTWARE
#
# TensorFlow model
#       |
#       v
# floating-point weights
#       |
#       v
# quantization
#       |
#       v
# fixed-point integers
#
# ------------------------------------------------------------
#
#                      HARDWARE
#
# fixed-point integers
#       |
#       v
# VHDL signed signals
#       |
#       v
# multipliers
#       |
#       v
# accumulators
#       |
#       v
# scaling
#       |
#       v
# saturation
#       |
#       v
# NN output
#
# The purpose of this module is therefore not simply to reduce numerical
# precision.
#
# It establishes part of the arithmetic contract between:
#
#     Python training
#     Python fixed-point verification
#     exported NN parameters
#     VHDL simulation
#     synthesized FPGA hardware
#
# All of these stages must agree on the numerical representation for
# bit-accurate verification.
