from pathlib import Path


# =============================================================================
# Project paths
# =============================================================================

# Absolute path to the root directory of the Git repository.
#
# Expected repository structure:
#
# fpga-hft-nn/
# ├── config/
# ├── data/
# ├── build/
# ├── python/
# ├── rtl/
# ├── tb/
# └── quartus/
PROJECT_ROOT = Path(__file__).resolve().parents[1]


# Directory containing input and processed market data.
DATA_DIR = PROJECT_ROOT / "data"

# Raw data downloaded from the market-data provider.
RAW_DATA_DIR = DATA_DIR / "raw"

# Data after feature extraction and preprocessing.
PROCESSED_DATA_DIR = DATA_DIR / "processed"


# Directory containing generated artifacts.
BUILD_DIR = PROJECT_ROOT / "build"

# Trained TensorFlow/Keras models.
MODEL_DIR = BUILD_DIR / "models"

# Floating-point and quantized neural-network parameters.
PARAMETER_DIR = BUILD_DIR / "parameters"

# Input/output vectors used to verify the VHDL implementation.
VECTOR_DIR = BUILD_DIR / "vectors"


# =============================================================================
# Market-data configuration
# =============================================================================

# Stock ticker used for the initial training example.
#
# AAPL is used only as a reproducible example.
# The FPGA architecture is not dependent on a specific financial instrument.
TICKER = "AAPL"

# Amount of historical market data requested from the data provider.
DATA_PERIOD = "30d"

# Sampling interval used for the initial training dataset.
#
# This is not representative of a real production HFT feed.
# A later FPGA implementation will process individual market-data events
# received directly from the Ethernet interface.
DATA_INTERVAL = "1m"


# =============================================================================
# Neural-network input features
# =============================================================================

# Features presented to the neural network.
#
# These features were deliberately selected so that equivalent calculations
# can later be implemented efficiently as streaming FPGA logic.
#
# Each feature becomes one NN input.
INPUT_FEATURES = [
    "return_1",
    "return_2",
    "return_4",
    "momentum_8",
    "range_1",
    "volume_delta_1",
    "volume_ratio_4",
    "volatility_8",
]

# Number of neural-network inputs.
#
# Because INPUT_FEATURES currently contains eight entries:
#
# INPUT_SIZE = 8
INPUT_SIZE = len(INPUT_FEATURES)


# =============================================================================
# Neural-network architecture
# =============================================================================

# The minimum neural network used by the project is:
#
#     8 inputs
#         |
#         v
#     Dense 8
#         |
#         v
#       ReLU
#         |
#         v
#     Dense 1
#         |
#         v
# predicted return
#
# In mathematical form:
#
#     x[0..7]
#        |
#        v
#     Dense(8)
#        |
#        v
#       ReLU
#        |
#        v
#     Dense(1)
#        |
#        v
# predicted short-horizon return
#
# The hidden layer therefore contains:
#
#     8 inputs x 8 neurons = 64 weights
#
# The output layer contains:
#
#     8 inputs x 1 neuron = 8 weights
#
# Total multiplications per inference:
#
#     64 + 8 = 72
#
# This small network is intentionally selected so that the FPGA version can
# implement a highly parallel MAC architecture with low and deterministic
# inference latency.


# Number of neurons in the hidden Dense layer.
HIDDEN_SIZE = 8

# Number of neural-network outputs.
#
# The single output represents the predicted normalized short-horizon return.
OUTPUT_SIZE = 1


# =============================================================================
# Dataset partitioning
# =============================================================================

# The dataset is split chronologically rather than randomly.
#
# This is important for time-series data because randomly mixing future and
# past samples between the training and test datasets can introduce temporal
# information leakage.
#
# Dataset organization:
#
# oldest ---------------------------------------------------------- newest
#
# +-------------------------+---------------+---------------+
# |         training        |  validation   |     test      |
# +-------------------------+---------------+---------------+
# |           70%           |      15%      |      15%      |
# +-------------------------+---------------+---------------+
TRAIN_RATIO = 0.70

VALIDATION_RATIO = 0.15

TEST_RATIO = 0.15


# =============================================================================
# Training configuration
# =============================================================================

# Number of complete passes through the training dataset.
#
# This affects model training only and has no effect on FPGA inference
# latency or FPGA resource usage.
EPOCHS = 50

# Number of samples used for each TensorFlow training update.
#
# Batch size affects software training performance but does not affect the
# FPGA inference architecture because FPGA inference processes one feature
# vector at a time.
BATCH_SIZE = 64

# Learning rate used by the Adam optimizer.
LEARNING_RATE = 0.001


# =============================================================================
# Fixed-point configuration
# =============================================================================

# Total width of each quantized NN parameter and input value.
#
# The initial implementation uses signed 16-bit values.
FIXED_WIDTH = 16

# Number of fractional bits used by the fixed-point representation.
#
# With 12 fractional bits:
#
#     scale = 2^12 = 4096
#
# Examples:
#
#      1.0000 ->  4096
#      0.5000 ->  2048
#      0.2500 ->  1024
#      0.0000 ->     0
#     -0.5000 -> -2048
#
# Multiplication therefore produces twice as many fractional bits and the
# result must be shifted right by FRACTION_BITS after accumulation.
FRACTION_BITS = 12

# Scaling factor used when converting between floating-point and fixed-point
# representations.
#
# This is equivalent to:
#
#     2 ** FRACTION_BITS
#
# A left shift is used because the value is known at configuration time and
# maps directly to the representation that will later be used in VHDL.
FIXED_SCALE = 1 << FRACTION_BITS


# =============================================================================
# Generated and intermediate files
# =============================================================================

# Raw market data downloaded by python/download_data.py.
RAW_DATA_FILE = RAW_DATA_DIR / "aapl_1m.csv"

# Market data after feature extraction by python/features.py.
PROCESSED_DATA_FILE = (
    PROCESSED_DATA_DIR / "aapl_features.csv"
)

# Floating-point TensorFlow/Keras model produced by python/train.py.
MODEL_FILE = (
    MODEL_DIR / "hft_nn.keras"
)

# Floating-point weights and biases extracted from the trained Keras model.
#
# This file is an intermediate representation used before quantization.
FLOAT_PARAMETER_FILE = (
    PARAMETER_DIR / "weights_float.npz"
)

# Quantized NN parameters exported as text CSV.
#
# This file is the primary software/hardware parameter interface:
#
# TensorFlow/Keras
#       |
#       v
# weights_float.npz
#       |
#       v
# quantization
#       |
#       v
# weights_q.csv
#       |
#       +--------------------+
#       |                    |
#       v                    v
# Python reference       FPGA/VHDL
#     model                build
#
# Keeping the parameters in a text CSV makes them human-readable and allows
# the same parameter set to be consumed by simulation and FPGA build tools.
QUANTIZED_PARAMETER_FILE = (
    PARAMETER_DIR / "weights_q.csv"
)

# Fixed-point input and expected-output vectors used to compare the Python
# reference implementation against the VHDL implementation in Questa.
TEST_VECTOR_FILE = (
    VECTOR_DIR / "nn_test_vectors.csv"
)
