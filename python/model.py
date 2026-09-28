import tensorflow as tf

from config.model_config import (
    HIDDEN_SIZE,
    INPUT_SIZE,
    LEARNING_RATE,
)


# =============================================================================
# Neural-network model construction
# =============================================================================

def build_model():
    """Build the floating-point neural network used for training."""

    # Create a sequential neural network.
    #
    # Sequential is appropriate because the current architecture is a simple
    # feed-forward network in which every layer feeds directly into the next:
    #
    #     input features
    #          |
    #          v
    #       Dense 8
    #          |
    #          v
    #         ReLU
    #          |
    #          v
    #       Dense 1
    #          |
    #          v
    # predicted return
    #
    # There are no branches, recurrent connections, or skip connections in
    # this architecture.
    model = tf.keras.Sequential(
        [
            # -----------------------------------------------------------------
            # Input layer
            # -----------------------------------------------------------------

            # Define the shape of one neural-network input vector.
            #
            # INPUT_SIZE is derived from INPUT_FEATURES in model_config.py.
            #
            # With the current configuration:
            #
            #     INPUT_SIZE = 8
            #
            # and the input vector is:
            #
            #     x[0] = return_1
            #     x[1] = return_2
            #     x[2] = return_4
            #     x[3] = momentum_8
            #     x[4] = range_1
            #     x[5] = volume_delta_1
            #     x[6] = volume_ratio_4
            #     x[7] = volatility_8
            #
            # TensorFlow adds the batch dimension automatically.
            #
            # Therefore, during training:
            #
            #     input shape = (batch_size, INPUT_SIZE)
            #
            # For example, with BATCH_SIZE = 64:
            #
            #     input shape = (64, 8)
            tf.keras.layers.Input(
                shape=(INPUT_SIZE,),
                name="features",
            ),


            # -----------------------------------------------------------------
            # Hidden Dense layer
            # -----------------------------------------------------------------

            # Create the hidden fully connected layer.
            #
            # HIDDEN_SIZE specifies the number of neurons.
            #
            # With:
            #
            #     INPUT_SIZE  = 8
            #     HIDDEN_SIZE = 8
            #
            # every hidden neuron receives all eight input features:
            #
            #     x0 --\
            #     x1 ---\
            #     x2 ----\
            #     x3 -----+--> hidden neuron
            #     x4 ----/
            #     x5 ---/
            #     x6 --/
            #     x7 -/
            #
            # This is repeated for all eight hidden neurons.
            #
            # Each hidden neuron calculates:
            #
            #              7
            #              ---
            #              \
            #     z[j] =    >   x[i] * W[i,j] + b[j]
            #              /
            #              ---
            #              i=0
            #
            # where:
            #
            #     x[i]
            #         Input feature i.
            #
            #     W[i,j]
            #         Weight connecting input i to hidden neuron j.
            #
            #     b[j]
            #         Bias of hidden neuron j.
            #
            # The hidden layer therefore contains:
            #
            #     8 inputs x 8 neurons = 64 weights
            #
            # plus:
            #
            #     8 biases
            #
            # for a total of:
            #
            #     72 trainable parameters
            #
            # activation="relu" applies:
            #
            #     y = max(0, z)
            #
            # after the multiply-accumulate operation.
            #
            # ReLU is particularly attractive for the later FPGA
            # implementation because it can be implemented as a sign test
            # rather than requiring a complex nonlinear arithmetic unit.
            tf.keras.layers.Dense(
                HIDDEN_SIZE,
                activation="relu",
                name="hidden",
            ),


            # -----------------------------------------------------------------
            # Output Dense layer
            # -----------------------------------------------------------------

            # Create the single output neuron.
            #
            # The output neuron receives the eight outputs produced by the
            # hidden layer.
            #
            # It calculates:
            #
            #                   7
            #                   ---
            #                   \
            #     prediction =   >   h[i] * Wout[i] + bout
            #                   /
            #                   ---
            #                   i=0
            #
            # where:
            #
            #     h[i]
            #         Output of hidden neuron i after ReLU.
            #
            #     Wout[i]
            #         Weight connecting hidden neuron i to the output.
            #
            #     bout
            #         Output-layer bias.
            #
            # The output layer therefore contains:
            #
            #     8 weights
            #
            # and:
            #
            #     1 bias
            #
            # activation=None means that no additional nonlinear activation
            # function is applied to the final result.
            #
            # This is required because the predicted return may be:
            #
            #     positive
            #     zero
            #     negative
            #
            # Using ReLU here, for example, would prevent the network from
            # predicting negative returns.
            tf.keras.layers.Dense(
                1,
                activation=None,
                name="prediction",
            ),
        ]
    )

    # The complete model therefore contains:
    #
    # Hidden layer:
    #
    #     64 weights
    #      8 biases
    #
    # Output layer:
    #
    #      8 weights
    #      1 bias
    #
    # Total:
    #
    #     64 + 8 + 8 + 1
    #     =
    #     81 trainable parameters
    #
    # Multiplications required for one inference:
    #
    #     hidden layer = 8 x 8 = 64
    #     output layer = 8 x 1 = 8
    #
    #     total = 72 multiplications
    #
    # This deliberately small architecture is useful for the later FPGA
    # implementation because the MAC operations can be highly parallelized to
    # reduce inference latency.

    return model


# =============================================================================
# Neural-network compilation
# =============================================================================

def compile_model(model):
    """Configure the model for floating-point software training."""

    # Create the Adam optimizer.
    #
    # Adam updates the weights and biases during software training based on
    # the gradients calculated by TensorFlow.
    #
    # LEARNING_RATE controls the magnitude of each optimization update.
    #
    # The current project configuration uses:
    #
    #     LEARNING_RATE = 0.001
    #
    # This optimizer exists only in the training environment.
    #
    # It will NOT be implemented in the FPGA because the FPGA performs
    # inference using already-trained and quantized parameters.
    optimizer = tf.keras.optimizers.Adam(
        learning_rate=LEARNING_RATE
    )

    # Configure the model for training.
    model.compile(
        # Adam is responsible for modifying weights and biases during
        # backpropagation.
        optimizer=optimizer,

        # Mean Squared Error is used as the regression loss:
        #
        #                   N
        #                  ---
        #               1  \
        #     MSE =     -   > (y[i] - y_hat[i])^2
        #               N  /
        #                  ---
        #                  i=1
        #
        # where:
        #
        #     y[i]
        #         Actual target return.
        #
        #     y_hat[i]
        #         Return predicted by the neural network.
        #
        # The training process attempts to minimize this value.
        loss="mse",

        # Mean Absolute Error is reported as an additional training and
        # validation metric:
        #
        #                   N
        #                  ---
        #               1  \
        #     MAE =     -   > |y[i] - y_hat[i]|
        #               N  /
        #                  ---
        #                  i=1
        #
        # MAE is useful for interpreting the average magnitude of the
        # prediction error without squaring large errors.
        metrics=["mae"],
    )


# =============================================================================
# Model relationship to the FPGA implementation
# =============================================================================

# The software model created by this file defines the neural-network topology
# that will later be reproduced in VHDL.
#
# The complete processing chain is:
#
# market data
#     |
#     v
# python/features.py
#     |
#     v
# 8 features
#     |
#     v
# python/dataset.py
#     |
#     v
# training vectors
#     |
#     v
# +-------------------------------+
# |       TensorFlow model        |
# |                               |
# | x[0..7]                       |
# |     |                         |
# |     v                         |
# | Dense(8)                      |
# |     |                         |
# |     v                         |
# | ReLU                          |
# |     |                         |
# |     v                         |
# | Dense(1)                      |
# |     |                         |
# |     v                         |
# | predicted return              |
# +-------------------------------+
#     |
#     v
# python/train.py
#     |
#     v
# floating-point weights
#     |
#     v
# python/quantize.py
#     |
#     v
# fixed-point weights
#     |
#     +---------------------------+
#     |                           |
#     v                           v
# Python reference             VHDL
# model                       nn_core
#     |                           |
#     +-------------+-------------+
#                   |
#                   v
#             bit-accurate
#              comparison
#
# TensorFlow is therefore used to determine the trained parameter values.
#
# The FPGA does not execute TensorFlow.
#
# Instead, the VHDL implementation reproduces only the inference equations
# using fixed-point arithmetic, multipliers, adders, registers, and ReLU
# logic.


# =============================================================================
# Expected FPGA arithmetic structure
# =============================================================================

# For each hidden neuron, TensorFlow conceptually evaluates:
#
#     accumulator = bias
#
#     for input_index in range(8):
#         accumulator += input[input_index] * weight[input_index]
#
#     output = max(0, accumulator)
#
# A straightforward FPGA implementation could therefore use:
#
#     input[0] * weight[0] --\
#     input[1] * weight[1] ---\
#     input[2] * weight[2] ----\
#     input[3] * weight[3] -----+
#     input[4] * weight[4] -----+--> adder tree --> bias --> ReLU
#     input[5] * weight[5] ----/
#     input[6] * weight[6] ---/
#     input[7] * weight[7] --/
#
# Because low and deterministic latency is the primary FPGA objective, the
# later RTL can evaluate multiple multiplications in parallel instead of
# sharing a single multiplier across all inputs.
#
# The degree of parallelism will determine the tradeoff between:
#
#     inference latency
#     throughput
#     DSP usage
#     register usage
#     routing complexity
#     achievable clock frequency
#
# Those decisions belong to the RTL microarchitecture and do not need to
# change the trained mathematical model.
