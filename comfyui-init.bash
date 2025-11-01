#!/bin/bash

echo "Starting ComfyUI initialization..."

# if the file main.py not exists we will clone and run python setup
# if [ ! -f "main.py" ]; then
# echo "Cloning ComfyUI repository..."
# pyenv virtualenv comfy
# pyenv local comfy
# pip install -r requirements.txt

# if pip list | grep -q "sageattention"; then
#   echo "sage-attention is already installed... moving on."
# else
#   echo "Installing additional sage attention..."
#   # Install sage attention
#   pip install --no-cache-dir sageattention==2.2.0 --no-build-isolation
#
# fi
#
# fi

python3 main.py --use-sage-attention --listen "0.0.0.0"
