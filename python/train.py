import sys
from pathlib import Path

import numpy as np


# =============================================================================
# Project path configuration
# =============================================================================

# Determine the absolute path to the root directory of the Git repository.
#
# Expected repository structure:
#
# fpga-hft-nn/
# ├── config/
# │   └── model_config.py
# ├── data/
# │   ├── raw/
# │   │   └── aapl_1m.csv
# │   └── processed/
# │       └── aapl_features.csv
# ├── build/
# │   ├── models/
# │   ├── parameters/
# │   └── vectors/
# ├── python/
# │   ├── download_data.py
# │   ├── features.py
# │   ├── dataset.py
# │   ├── model.py
# │   └── train.py
# ├── rtl/
# ├── tb/
# └── quartus/
#
# __file__ points to:
#
#     fpga-hft-nn/python/train.py
#
# parents[1] therefore points to:
#
#     fpga-hft-nn/
PROJECT_ROOT = Path(__file__).resolve().parents[1]


# Add the project root to the Python module search path.
#
# This allows imports such as:
#
#     from config.model_config import ...
#
# and:
#
#     from python.dataset import ...
#
# regardless of the directory from which the command is executed.
sys.path.insert(
    0,
    str(PROJECT_ROOT),
)


# =============================================================================
# Project configuration
# =============================================================================

# Import the parameters that control training and artifact generation.
#
# BATCH_SIZE
#     Number of samples processed during each optimizer update.
#
# EPOCHS
#     Number of complete passes through the training dataset.
#
# FLOAT_PARAMETER_FILE
#     NPZ file used to store the trained floating-point weights and biases.
#
# MODEL_DIR
#     Directory containing the saved TensorFlow/Keras model.
#
# MODEL_FILE
#     Complete path of the saved TensorFlow/Keras model.
#
# PARAMETER_DIR
#     Directory containing exported neural-network parameters.
from config.model_config import (
    BATCH_SIZE,
    EPOCHS,
    FLOAT_PARAMETER_FILE,
    MODEL_DIR,
    MODEL_FILE,
    PARAMETER_DIR,
)


# =============================================================================
# Dataset and model imports
# =============================================================================

# load_datasets() performs the chronological dataset partitioning:
#
#     oldest ---------------------------------------------- newest
#
#     +-------------------+-------------+-------------+
#     |     training      | validation  |    test     |
#     +-------------------+-------------+-------------+
#     |       70%         |     15%     |     15%     |
#     +-------------------+-------------+-------------+
#
# It returns NumPy arrays that can be passed directly to TensorFlow.
from python.dataset import load_datasets


# build_model() creates the neural-network topology:
#
#     8 inputs
#        |
#        v
#     Dense 8
#        |
#        v
#      ReLU
#        |
#        v
#     Dense 1
#        |
#        v
# predicted return
#
# compile_model() configures Adam, MSE, and MAE for training.
from python.model import (
    build_model,
    compile_model,
)


# =============================================================================
# Build-directory creation
# =============================================================================

def create_directories():
    """Create directories used to store training artifacts."""

    # Create:
    #
    #     build/models/
    #
    # if it does not already exist.
    #
    # This directory stores the complete trained Keras model.
    MODEL_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    # Create:
    #
    #     build/parameters/
    #
    # if it does not already exist.
    #
    # This directory stores the extracted weights and biases that will later
    # be quantized for the fixed-point reference model and VHDL implementation.
    PARAMETER_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )


# =============================================================================
# Neural-network training
# =============================================================================

def train_model(
    model,
    x_train,
    y_train,
    x_validation,
    y_validation,
):
    """Train the neural network using the chronological training dataset."""

    # Train the model using the oldest portion of the dataset.
    #
    # model.fit() performs:
    #
    #     forward propagation
    #          |
    #          v
    #     predicted return
    #          |
    #          v
    #     loss calculation
    #          |
    #          v
    #     backpropagation
    #          |
    #          v
    #     gradient calculation
    #          |
    #          v
    #     Adam optimizer
    #          |
    #          v
    #     update weights and biases
    #
    # This process is repeated for each batch and for every epoch.
    history = model.fit(
        x_train,
        y_train,

        # The validation dataset is not used to update the model parameters.
        #
        # Instead, TensorFlow evaluates the model on this later chronological
        # portion after each epoch.
        #
        # Comparing training and validation behavior helps identify problems
        # such as overfitting.
        validation_data=(
            x_validation,
            y_validation,
        ),

        # Number of complete passes through x_train and y_train.
        epochs=EPOCHS,

        # Number of training samples processed before one optimizer update.
        batch_size=BATCH_SIZE,

        # Do not randomly reorder the training samples.
        #
        # The project is based on time-series data and preserving temporal
        # ordering keeps the training flow consistent with the chronological
        # dataset construction.
        shuffle=False,
    )

    # Keras returns a History object containing the recorded metrics for each
    # epoch.
    #
    # For the current model, this normally includes:
    #
    #     loss
    #     mae
    #     val_loss
    #     val_mae
    #
    # These values can later be used for training plots or model analysis.
    return history


# =============================================================================
# Final model evaluation
# =============================================================================

def evaluate_model(
    model,
    x_test,
    y_test,
):
    """Evaluate the trained model using the independent test dataset."""

    # The test dataset contains the newest samples and was not used for:
    #
    #     weight updates
    #
    # or:
    #
    #     per-epoch validation
    #
    # It therefore provides a final evaluation after training has completed.
    test_mse, test_mae = model.evaluate(
        x_test,
        y_test,

        # Disable the Keras progress bar for the final evaluation.
        verbose=0,
    )

    # Report Mean Squared Error.
    #
    # MSE is also the loss function used during training:
    #
    #                   N
    #                  ---
    #               1  \
    #     MSE =     -   > (y[i] - y_hat[i])^2
    #               N  /
    #                  ---
    #                  i=1
    print(
        f"Test MSE: {test_mse:.8f}"
    )

    # Report Mean Absolute Error:
    #
    #                   N
    #                  ---
    #               1  \
    #     MAE =     -   > |y[i] - y_hat[i]|
    #               N  /
    #                  ---
    #                  i=1
    #
    # MAE expresses the average absolute prediction error in the same units as
    # target_return.
    print(
        f"Test MAE: {test_mae:.8f}"
    )

    return test_mse, test_mae


# =============================================================================
# Trained-model storage
# =============================================================================

def save_model(model):
    """Save the complete trained TensorFlow/Keras model."""

    # Store the complete model in Keras format.
    #
    # The file contains information such as:
    #
    #     model topology
    #     trained weights
    #     trained biases
    #     optimizer configuration
    #
    # This file is useful for software-side model inspection and validation.
    #
    # The FPGA does NOT load this file.
    #
    # The FPGA will instead use the quantized parameters exported by later
    # stages of the Python flow.
    model.save(
        MODEL_FILE
    )

    print(
        "Saved trained model to:"
    )

    print(
        MODEL_FILE
    )


# =============================================================================
# Floating-point parameter extraction
# =============================================================================

def save_parameters(model):
    """Extract and save the trained floating-point weights and biases."""

    # Retrieve the hidden Dense layer by its explicit name.
    #
    # model.py creates this layer using:
    #
    #     name="hidden"
    hidden_layer = model.get_layer(
        "hidden"
    )

    # Retrieve the output Dense layer by its explicit name.
    #
    # model.py creates this layer using:
    #
    #     name="prediction"
    output_layer = model.get_layer(
        "prediction"
    )

    # Extract the hidden-layer weights and biases.
    #
    # For a Keras Dense layer:
    #
    #     get_weights()[0] = weight matrix
    #     get_weights()[1] = bias vector
    #
    # With:
    #
    #     INPUT_SIZE  = 8
    #     HIDDEN_SIZE = 8
    #
    # hidden_weights has shape:
    #
    #     (8, 8)
    #
    # Keras stores this matrix as:
    #
    #     hidden_weights[input][neuron]
    #
    # hidden_bias has shape:
    #
    #     (8,)
    hidden_weights, hidden_bias = (
        hidden_layer.get_weights()
    )

    # Extract the output-layer weights and bias.
    #
    # With eight hidden neurons and one output:
    #
    #     output_weights.shape = (8, 1)
    #
    # and:
    #
    #     output_bias.shape = (1,)
    output_weights, output_bias = (
        output_layer.get_weights()
    )

    # Save the floating-point arrays in NumPy's NPZ format.
    #
    # This file is an intermediate representation:
    #
    # TensorFlow training
    #        |
    #        v
    # floating-point parameters
    #        |
    #        v
    # weights_float.npz
    #        |
    #        v
    # quantization
    #        |
    #        v
    # fixed-point parameters
    #
    # Keeping this intermediate artifact separates training from quantization.
    #
    # The model can therefore be trained once and different fixed-point
    # representations can later be evaluated without retraining it.
    np.savez(
        FLOAT_PARAMETER_FILE,
        hidden_weights=hidden_weights,
        hidden_bias=hidden_bias,
        output_weights=output_weights,
        output_bias=output_bias,
    )

    # Report the dimensions of the extracted parameters.
    #
    # For the current network, the expected values are:
    #
    #     hidden_weights: (8, 8)
    #     hidden_bias:    (8,)
    #     output_weights: (8, 1)
    #     output_bias:    (1,)
    print(
        "Hidden weights shape:",
        hidden_weights.shape,
    )

    print(
        "Hidden bias shape:",
        hidden_bias.shape,
    )

    print(
        "Output weights shape:",
        output_weights.shape,
    )

    print(
        "Output bias shape:",
        output_bias.shape,
    )

    print(
        "Saved floating-point parameters to:"
    )

    print(
        FLOAT_PARAMETER_FILE
    )


# =============================================================================
# Main training flow
# =============================================================================

def main():
    """Execute the complete floating-point neural-network training flow."""

    # The complete training pipeline is:
    #
    # data/processed/aapl_features.csv
    #               |
    #               v
    #        load_datasets()
    #               |
    #       +-------+-------+
    #       |       |       |
    #       v       v       v
    #     train validation test
    #       |       |       |
    #       +---+---+       |
    #           |           |
    #           v           |
    #      build_model()    |
    #           |           |
    #           v           |
    #     compile_model()   |
    #           |           |
    #           v           |
    #      train_model()    |
    #           |           |
    #           v           |
    #      trained model    |
    #           |           |
    #           +-----------+
    #           |
    #           v
    #     evaluate_model()
    #           |
    #           v
    #      test MSE / MAE
    #           |
    #       +---+---+
    #       |       |
    #       v       v
    # save_model() save_parameters()
    #       |       |
    #       v       v
    # hft_nn.keras weights_float.npz
    #                   |
    #                   v
    #          python/quantize.py

    # Ensure that the output directories exist before training artifacts are
    # generated.
    create_directories()

    # Load the processed dataset and split it chronologically.
    #
    # The returned arrays are:
    #
    #     x_train
    #         Input features used to update the model parameters.
    #
    #     y_train
    #         Expected returns corresponding to x_train.
    #
    #     x_validation
    #         Input features used for validation after each epoch.
    #
    #     y_validation
    #         Expected returns corresponding to x_validation.
    #
    #     x_test
    #         Independent input features used only after training.
    #
    #     y_test
    #         Expected returns corresponding to x_test.
    (
        x_train,
        y_train,
        x_validation,
        y_validation,
        x_test,
        y_test,
    ) = load_datasets()

    # Display the dataset dimensions before training.
    #
    # With eight configured input features:
    #
    #     x_train.shape[1] = 8
    #
    # and equivalent dimensionality is expected for validation and test data.
    print(
        "Training inputs:",
        x_train.shape,
    )

    print(
        "Validation inputs:",
        x_validation.shape,
    )

    print(
        "Test inputs:",
        x_test.shape,
    )

    # Construct the floating-point TensorFlow neural network.
    model = build_model()

    # Configure the optimizer, loss function, and evaluation metric.
    compile_model(
        model
    )

    # Display the TensorFlow model structure.
    #
    # For the current architecture this also provides a useful verification
    # that the expected 81 trainable parameters are present.
    model.summary()

    # Train the model using the training partition while evaluating the
    # validation partition after every epoch.
    train_model(
        model,
        x_train,
        y_train,
        x_validation,
        y_validation,
    )

    # Perform the final evaluation using samples that were not used for model
    # training or per-epoch validation.
    evaluate_model(
        model,
        x_test,
        y_test,
    )

    # Save the complete TensorFlow/Keras model.
    save_model(
        model
    )

    # Extract the trained Dense-layer parameters and save them independently
    # from TensorFlow.
    #
    # This artifact is the input to the quantization stage.
    save_parameters(
        model
    )


# =============================================================================
# Script entry point
# =============================================================================

# Execute main() when this file is run as a Python module:
#
#     python -m python.train
#
# Importing functions from train.py does not automatically start training.
if __name__ == "__main__":
    main()
    