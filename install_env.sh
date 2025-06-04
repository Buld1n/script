#!/bin/bash

set -e
LOGFILE="install.log"
exec > >(tee -i "$LOGFILE") 2>&1

echo "===== SimStack QE Environment Setup ====="

# === Ensure micromamba is available ===
export PATH="$HOME/.local/bin:$PATH"

if ! command -v micromamba &> /dev/null; then
    echo "[ERROR] Micromamba is not in PATH. Please install it first:"
    echo '    "${SHELL}" <(curl -L micro.mamba.pm/install.sh)'
    exit 1
fi

# === Initialize micromamba shell ===
echo "[INFO] Initializing micromamba shell environment..."
eval "$(micromamba shell hook --shell=bash)"

# === Create environment 'qe' with required packages ===
echo "[INFO] Creating micromamba environment 'qe'..."
micromamba create -n qe -c conda-forge python=3.11 pip "numpy<2.0" pyyaml qe -y

# === Activate environment ===
echo "[INFO] Activating environment 'qe'..."
micromamba activate qe

# === Install system-level dependencies ===
echo "[INFO] Installing system packages (requires sudo)..."
sudo apt update
sudo apt install -y \
    python3-dev \
    gfortran \
    liblapack-dev \
    meson \
    build-essential \
    make \
    gcc \
    g++ \
    python3-numpy

# === Install pwtools from GitHub (with extensions) ===
echo "[INFO] Installing pwtools from GitHub (with C extensions)..."
pip install git+https://github.com/elcorto/pwtools

# === Install Python packages: ase and PyYAML ===
echo "[INFO] Installing ase and PyYAML (explicitly)..."
pip install ase PyYAML

# === Post-installation checks ===
echo "[INFO] Performing post-installation checks..."

echo -n "[CHECK] pw.x availability... "
if command -v pw.x &> /dev/null; then
    echo "OK"
else
    echo "FAIL"
    echo "[ERROR] Quantum ESPRESSO 'pw.x' not found in PATH."
fi

echo -n "[CHECK] Python import: pwtools... "
if python -c "import pwtools" &> /dev/null; then
    echo "OK"
else
    echo "FAIL"
    echo "[ERROR] Python cannot import 'pwtools'."
fi

echo -n "[CHECK] Python import: ase... "
if python -c "import ase" &> /dev/null; then
    echo "OK"
else
    echo "FAIL"
    echo "[ERROR] Python cannot import 'ase'."
fi

echo -n "[CHECK] Python import: yaml... "
if python -c "import yaml" &> /dev/null; then
    echo "OK"
else
    echo "FAIL"
    echo "[ERROR] Python cannot import 'yaml' (PyYAML)."
fi

echo
echo "[SUCCESS] Installation complete."
echo "To activate the environment later, run:"
echo "    micromamba activate qe"
