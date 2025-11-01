#!/bin/bash
if pip list | grep -q "sage-attention"; then
    echo "sage-attention is already installed."
else
    pip install sage-attention
fi