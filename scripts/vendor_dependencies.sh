#!/bin/bash
set -e

# Configuration
TERRAFORM_VERSION="1.5.7"
GO_VERSION="1.21.6"
SENTINEL_VERSION="0.19.4"

# Directories
VENDOR_DIR="vendor"
BIN_DIR="$VENDOR_DIR/bin"
PYTHON_DIR="$VENDOR_DIR/python"

mkdir -p "$BIN_DIR"
mkdir -p "$PYTHON_DIR"

echo "=== Vendoring Dependencies for Offline Build ==="

# 1. Download Terraform
if [ ! -f "$BIN_DIR/terraform.zip" ]; then
    echo "Downloading Terraform $TERRAFORM_VERSION..."
    curl -L -o "$BIN_DIR/terraform.zip" "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
else
    echo "Terraform already exists."
fi

# 2. Download Sentinel
if [ ! -f "$BIN_DIR/sentinel.zip" ]; then
    echo "Downloading Sentinel $SENTINEL_VERSION..."
    curl -L -o "$BIN_DIR/sentinel.zip" "https://releases.hashicorp.com/sentinel/${SENTINEL_VERSION}/sentinel_${SENTINEL_VERSION}_linux_amd64.zip"
else
    echo "Sentinel already exists."
fi

# 3. Download Go
if [ ! -f "$BIN_DIR/go.tar.gz" ]; then
    echo "Downloading Go $GO_VERSION..."
    curl -L -o "$BIN_DIR/go.tar.gz" "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
else
    echo "Go already exists."
fi

# 4. Download Python Wheels
echo "Downloading Python wheels..."
pip download -d "$PYTHON_DIR" -r requirements.txt

echo "=== Vendoring Complete ==="
echo "Assets are in $VENDOR_DIR/"
