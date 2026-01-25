# Use Nvidia CUDA base image with cuDNN to make it compatible with GPU acceleration
FROM nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04
ARG BASE_DOCKER_FROM=nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04

# WORKDIR /opt

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Stockholm

RUN apt-get update -y --fix-missing\
  && apt-get install -y \
  apt-utils \
  locales \
  ca-certificates \
  && apt-get upgrade -y \
  && apt-get install -y \
  build-essential \
  python3-dev \
  unzip \
  curl \
  wget \
  zip \
  zlib1g \
  zlib1g-dev \
  gnupg \
  rsync \
  python3-pip \
  python3-venv \
  git \
  sudo \
  libglib2.0-0 \
  socat \
  pkg-config \
  libcairo2-dev \
  libpango1.0-dev \
  libjpeg-dev \
  libpng-dev \
  libffi-dev \
  libsm6 \
  libxext6 \
  libxrender1 \
  && apt-get clean



# Add libEGL ICD loaders and libraries + Vulkan ICD loaders and libraries
# Per https://github.com/mmartial/ComfyUI-Nvidia-Docker/issues/26
# RUN apt install -y libglvnd0 libglvnd-dev libegl1-mesa-dev libvulkan1 libvulkan-dev ffmpeg \
#   && apt-get clean \
#   && rm -rf /var/lib/apt/lists/* \
#   && mkdir -p /usr/share/glvnd/egl_vendor.d \
#   && echo '{"file_format_version":"1.0.0","ICD":{"library_path":"libEGL_nvidia.so.0"}}' > /usr/share/glvnd/egl_vendor.d/10_nvidia.json \
#   && mkdir -p /usr/share/vulkan/icd.d \
#   && echo '{"file_format_version":"1.0.0","ICD":{"library_path":"libGLX_nvidia.so.0","api_version":"1.3"}}' > /usr/share/vulkan/icd.d/nvidia_icd.json \
#   && apt-get clean \
#   && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt install -y \
  libglvnd0 \
  libglvnd-dev \
  libegl1-mesa-dev \
  libvulkan1 \
  libvulkan-dev \
  ffmpeg \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
ENV MESA_D3D12_DEFAULT_ADAPTER_NAME="NVIDIA"

ENV BUILD_FILE="/etc/image_base.txt"
ARG BASE_DOCKER_FROM
RUN echo "DOCKER_FROM: ${BASE_DOCKER_FROM}" | tee ${BUILD_FILE}
RUN echo "CUDNN: ${NV_CUDNN_PACKAGE_NAME} (${NV_CUDNN_VERSION})" | tee -a ${BUILD_FILE}

ARG BUILD_BASE="unknown"
LABEL comfyui-nvidia-docker-build-from=${BUILD_BASE}
RUN it="/etc/build_base.txt"; echo ${BUILD_BASE} > $it && chmod 555 $it


##### ComfyUI preparation
# Every sudo group user does not need a password
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN adduser ubuntu sudo

ENV NVIDIA_DRIVER_CAPABILITIES="all"
ENV NVIDIA_VISIBLE_DEVICES=all

EXPOSE 8188

ARG COMFYUI_NVIDIA_DOCKER_VERSION="unknown"
LABEL comfyui-nvidia-docker-build=${COMFYUI_NVIDIA_DOCKER_VERSION}
RUN echo "COMFYUI_NVIDIA_DOCKER_VERSION: ${COMFYUI_NVIDIA_DOCKER_VERSION}" | tee -a ${BUILD_FILE}

# We start as comfytoo and will switch to the comfy user AFTER the container is up
# and after having altered the comfy details to match the requested UID/GID
USER ubuntu

# Install pyenv
RUN curl https://pyenv.run | bash

ENV PYENV_ROOT /home/ubuntu/.pyenv
ENV PATH $PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH

# For shell init
RUN echo 'eval "$(pyenv init -)"' >> /home/ubuntu/.bashrc
RUN eval "$(pyenv init -)"


# make ~/.local/bin available on the PATH so scripts like tqdm, torchrun, etc. are found
# ENV PATH=/home/appuser/.local/bin:$PATH
WORKDIR /opt/app

RUN sudo mkdir -p /opt/app && sudo chown ubuntu /opt/app && cd /opt/app
RUN git clone https://github.com/comfyanonymous/ComfyUI.git
WORKDIR /opt/app/ComfyUI

RUN pyenv virtualenv comfy \
  && pyenv local comfy

# installation of python packages
RUN pip install --no-cache-dir -r requirements.txt

# RUN pip install --no-cache-dir triton --no-build-isolation
# RUN pip install --no-cache-dir sageattention==2.2.0 --no-build-isolation

# (Optional) Clean up pip cache to reduce image size
# RUN pip cache purge
RUN git clone https://github.com/thu-ml/SageAttention.git \
  && cd SageAttention \
  && export EXT_PARALLEL=4 NVCC_APPEND_FLAGS="--threads 8" MAX_JOBS=32 \
  && python setup.py install  # or pip install -e . \
  && cd ..

# Copy the comfyui-init.bash script
COPY comfyui-init.bash /comfyui-init.bash
RUN sudo chown ubuntu /comfyui-init.bash && chmod +x /comfyui-init.bash

# Expose the port that ComfyUI will use
EXPOSE 8188

ENTRYPOINT [ "/comfyui-init.bash" ]
