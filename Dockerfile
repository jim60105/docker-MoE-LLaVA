# syntax=docker/dockerfile:1
ARG UID=1001
ARG VERSION=EDGE
ARG RELEASE=0
ARG LOW_VRAM=

ARG CACHE_HOME=/.cache
ARG TORCH_HOME=${CACHE_HOME}/torch
ARG HF_HOME=${CACHE_HOME}/huggingface

########################################
# Build stage
########################################
FROM python:3.10 as build

# RUN mount cache for multi-arch: https://github.com/docker/buildx/issues/549#issuecomment-1788297892
ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /source

# Install under /root/.local
ARG PIP_USER="true"
ARG PIP_NO_WARN_SCRIPT_LOCATION=0
ARG PIP_ROOT_USER_ACTION="ignore"
ARG PIP_NO_COMPILE="true"
ARG PIP_DISABLE_PIP_VERSION_CHECK="true"

# Add build time dependencies
RUN --mount=type=cache,id=apt-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=aptlists-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/lib/apt/lists \
    apt-get update && apt-get install -y --no-install-recommends \
    libopenmpi-dev

# Install large requirements
RUN --mount=type=cache,id=pip-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    pip install -U --force-reinstall pip==23.3 setuptools==69.5.1 wheel && \
    pip install -U --extra-index-url https://download.pytorch.org/whl/cu118 \
    torch==2.0.1 torchvision==0.15.2

# Install requirements
RUN --mount=type=cache,id=pip-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    --mount=source=MoE-LLaVA-hf/requirements.txt,target=requirements.txt \
    pip install -r requirements.txt \
    dghs-imgutils[gpu] imgutils mpi4py

# Install MoE-LLaVA
RUN --mount=type=cache,id=pip-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    --mount=source=MoE-LLaVA-hf,target=.,rw \
    pip install . && \
    # Cleanup
    find "/root/.local" -name '*.pyc' -print0 | xargs -0 rm -f || true ; \
    find "/root/.local" -type d -name '__pycache__' -print0 | xargs -0 rm -rf || true ;

# Replace pillow with pillow-simd (Only for x86)
ARG TARGETPLATFORM
RUN --mount=type=cache,id=apt-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=aptlists-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/lib/apt/lists \
    if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
    pip uninstall -y pillow && \
    CC="cc -mavx2" pip install -U --force-reinstall pillow-simd; \
    fi

########################################
# Final stage for no_model
########################################
FROM python:3.10-slim as no_model

# NVIDIA Environment before installing CUDA
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility

ENV CUDA_VERSION=11.8.0
ENV NV_CUDA_CUDART_VERSION=11.8.89-1
ENV NVIDIA_REQUIRE_CUDA=cuda>=11.8

# RUN mount cache for multi-arch: https://github.com/docker/buildx/issues/549#issuecomment-1788297892
ARG TARGETARCH
ARG TARGETVARIANT

# Install CUDA partially
ADD https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64/cuda-keyring_1.0-1_all.deb .
RUN --mount=type=cache,id=apt-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=aptlists-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/lib/apt/lists \
    dpkg -i cuda-keyring_1.0-1_all.deb && \
    rm cuda-keyring_1.0-1_all.deb && \
    sed -i 's/^Components: main$/& contrib/' /etc/apt/sources.list.d/debian.sources && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    # Installing the whole CUDA typically increases the image size by approximately **8GB**.
    # To decrease the image size, we opt to install only the necessary libraries.
    # Here is the package list for your reference: https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64
    #! If you experience any related issues, replace the following line with `cuda-11-8` to obtain the complete CUDA package.
    cuda-cudart-11-8=${NV_CUDA_CUDART_VERSION} libcusparse-11-8 libcurand-11-8 libcufft-11-8 cuda-nvrtc-11-8

# Install runtime dependencies
RUN --mount=type=cache,id=apt-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=aptlists-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/lib/apt/lists \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    libjpeg62 libopenjp2-7 libtiff6 libpng16-16 libwebp7 libwebpmux3 \
    libgoogle-perftools-dev openmpi-bin

# Fix missing libnvrtc.so
RUN ln -s /usr/local/cuda/lib64/libnvrtc.so.11.2 /usr/local/cuda/lib64/libnvrtc.so

# Create user
ARG UID
RUN groupadd -g $UID $UID && \
    useradd -l -u $UID -g $UID -m -s /bin/sh -N $UID

# pip install under user home
# Because the script uses pip so I left it in the final image.
# In fact, all dependencies have been installed in the Dockerfile and pip should not be used.
ENV PIP_USER="true"
ENV PIP_NO_WARN_SCRIPT_LOCATION=0
ENV PIP_DISABLE_PIP_VERSION_CHECK="true"

ARG CACHE_HOME
ARG TORCH_HOME
ARG HF_HOME
ENV XDG_CACHE_HOME=${CACHE_HOME}
ENV TORCH_HOME=${TORCH_HOME}
ENV HF_HOME=${HF_HOME}

# Create directories with correct permissions
RUN install -d -m 775 -o $UID -g 0 /licenses && \
    install -d -m 775 -o $UID -g 0 ${CACHE_HOME} \
    install -d -m 775 -o $UID -g 0 ${CACHE_HOME}/huggingface/hub \
    install -d -m 775 -o $UID -g 0 /app

# The script also uses ./cache_dir for huggingface cache
RUN ln -s ${CACHE_HOME}/huggingface/hub /app/cache_dir

# dumb-init
COPY --link --chown=$UID:0 --chmod=775 --from=ghcr.io/jim60105/static-ffmpeg-upx:7.0-1 /dumb-init /usr/local/bin/

# Copy licenses (OpenShift Policy)
COPY --link --chown=$UID:0 --chmod=775 LICENSE /licenses/Dockerfile.LICENSE
COPY --link --chown=$UID:0 --chmod=775 MoE-LLaVA-hf/LICENSE /licenses/MoE-LLaVA.LICENSE

# Copy dependencies and code (and support arbitrary uid for OpenShift best practice)
# https://docs.openshift.com/container-platform/4.14/openshift_images/create-images.html#use-uid_create-images
COPY --link --chown=$UID:0 --chmod=775 --from=build /root/.local /home/$UID/.local
COPY --link --chown=$UID:0 --chmod=775 MoE-LLaVA-hf/predict.py /app/predict.py
COPY --link --chown=$UID:0 --chmod=775 MoE-LLaVA-hf/moellava/serve /app/serve

ENV PATH="/home/$UID/.local/bin:$PATH"
ENV PYTHONPATH="/home/$UID/.local/lib/python3.10/site-packages"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64"
ENV LD_PRELOAD=libtcmalloc.so

WORKDIR /app

VOLUME [ "/dataset" ]

USER $UID

STOPSIGNAL SIGINT

ENTRYPOINT [ "dumb-init", "--", "/bin/sh", "-c", "python3 predict.py /dataset \"$@\"" ]

ARG VERSION
ARG RELEASE
LABEL name="jim60105/docker-MoE-LLaVA" \
    # Authors for MoE-LLaVA and the script
    vendor="Lin, Bin and Tang, Zhenyu and Ye, Yang and Cui, Jiaxi and Zhu, Bin and Jin, Peng and Zhang, Junwu and Ning, Munan and Yuan, Li, camenduru, gesen2egee" \
    # Maintainer for this docker image
    maintainer="jim60105" \
    # Dockerfile source repository
    url="https://github.com/jim60105/docker-MoE-LLaVA" \
    version=${VERSION} \
    # This should be a number, incremented with each change
    release=${RELEASE} \
    io.k8s.display-name="MoE-LLaVA" \
    summary="MoE-LLaVA: Mixture of Experts for Large Vision-Language Models" \
    description="This is the docker image for [gesen2egee/MoE-LLaVA-hf](https://github.com/gesen2egee/MoE-LLaVA-hf), a script that uses [MoE-LLaVA](https://github.com/PKU-YuanGroup/MoE-LLaVA) technology to predict descriptions for images. For more information about this tool, please visit the following website: https://github.com/gesen2egee/MoE-LLaVA-hf."

########################################
# load_model stage
#! These are very large models! Blows up the image size to 40GB
########################################
FROM python:3.10 as load_model

# RUN mount cache for multi-arch: https://github.com/docker/buildx/issues/549#issuecomment-1788297892
ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /source

# Install under /root/.local
ARG PIP_USER="true"
ARG PIP_NO_WARN_SCRIPT_LOCATION=0
ARG PIP_ROOT_USER_ACTION="ignore"
ARG PIP_NO_COMPILE="true"
ARG PIP_DISABLE_PIP_VERSION_CHECK="true"

# Enable HF Transfer
# This library is a power user tool, to go beyond ~500MB/s on very high bandwidth network, where Python cannot cap out the available bandwidth.
# https://github.com/huggingface/hf_transfer
ARG UID
RUN --mount=type=cache,id=pip-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/home/$UID/.cache/pip \
    pip install -U --force-reinstall pip==23.3 setuptools==69.5.1 wheel && \
    pip install -U \
    huggingface_hub[hf_transfer]
ARG HF_HUB_ENABLE_HF_TRANSFER=1

ARG PYTHONUNBUFFERED=1

# Preload model
ARG HF_HOME
ARG LOW_VRAM
RUN --mount=source=load_model.py,target=load_model.py \
    python3 load_model.py

########################################
# Final stage with model
########################################
FROM no_model as prepare_final

FROM no_model as prepare_final_low_vram

# Change the entrypoint to use --low_vram
ENTRYPOINT [ "dumb-init", "--", "/bin/sh", "-c", "python3 predict.py /dataset --low_vram \"$@\"" ]

FROM prepare_final${LOW_VRAM:+_low_vram} as final

ARG UID

# Copy the model
ARG CACHE_HOME
COPY --link --chown=$UID:0 --chmod=775 --from=load_model ${CACHE_HOME} ${CACHE_HOME}

ARG VERSION
ARG RELEASE
LABEL version=${VERSION} \
    release=${RELEASE}

########################################
# Place it at the end to serve as the default final stage
########################################
FROM no_model as final_no_model