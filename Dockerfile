# Stage 1: Base
FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04 as base

ARG OOBABOOGA_COMMIT=3f28925a8d6f04860f09975536c37f6815b0f2b5
ARG TORCH_VERSION=2.1.2

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=on \
    SHELL=/bin/bash

# Install Ubuntu packages
RUN apt update && \
    apt -y upgrade && \
    apt install -y --no-install-recommends \
        software-properties-common \
        python3.10-venv \
        python3-pip \
        python3-dev \
        python3-tk \
        bash \
        dos2unix \
        git \
        git-lfs \
        ncdu \
        nginx  \
        net-tools \
        openssh-server \
        libglib2.0-0 \
        libsm6 \
        libgl1 \
        libxrender1 \
        libxext6 \
        ffmpeg \
        wget \
        curl \
        psmisc \
        rsync \
        vim \
        zip \
        unzip \
        htop \
        pkg-config \
        libcairo2-dev \
        libgoogle-perftools4 libtcmalloc-minimal4 \
        apt-transport-https ca-certificates && \
    update-ca-certificates && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

ENV PATH="/usr/local/cuda/bin:${PATH}"

# Set Python
RUN ln -s /usr/bin/python3.10 /usr/bin/python

# Stage 2: Install Web UI and python modules
FROM base as setup

# Install Torch
RUN python3 -m venv /venv && \
    source /venv/bin/activate && \
    pip3 install --no-cache-dir torch==${TORCH_VERSION} torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 && \
    pip3 install --no-cache-dir xformers && \
    deactivate

# Clone the git repo of Text Generation Web UI and set version
WORKDIR /
RUN git clone https://github.com/oobabooga/text-generation-webui && \
    cd /text-generation-webui && \
    git checkout ${OOBABOOGA_COMMIT}

# Install the dependencies for Text Generation Web UI
# Including all extensions
WORKDIR /text-generation-webui
RUN source /venv/bin/activate && \
    pip3 install -r requirements.txt && \
    bash -c 'for req in extensions/*/requirements.txt ; do pip3 install -r "$req" ; done' && \
    mkdir -p repositories && \
    cd repositories && \
    git clone https://github.com/turboderp/exllama && \
    pip3 install -r exllama/requirements.txt && \
    deactivate

# Install legacy API as an extension \
WORKDIR /text-generation-webui
RUN source /venv/bin/activate && \
    git clone --depth=1 https://github.com/ashleykleynhans/oobabooga-legacy-api-extension.git extensions/api && \
    source /venv/bin/activate && \
    pip3 install -r extensions/api/requirements.txt && \
    deactivate

# Install rclone
RUN curl https://rclone.org/install.sh | bash

# Install runpodctl
RUN wget https://github.com/runpod/runpodctl/releases/download/v1.10.0/runpodctl-linux-amd -O runpodctl && \
    chmod a+x runpodctl && \
    mv runpodctl /usr/local/bin

# Install croc
RUN curl https://getcroc.schollz.com | bash

# Install speedtest CLI
RUN curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash && \
    apt install speedtest

# Install Jupyter
RUN pip3 install -U --no-cache-dir jupyterlab \
        jupyterlab_widgets \
        ipykernel \
        ipywidgets \
        gdown

# NGINX Proxy
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/api.html nginx/502.html /usr/share/nginx/html/
COPY nginx/template-readme.md /usr/share/nginx/html/README.md

# Remove existing SSH host keys
RUN rm -f /etc/ssh/ssh_host_*

# Copy startup script for Oobabooba Web UI
COPY --chmod=755 scripts/start_textgen_server.sh /text-generation-webui/

# Copy scripts to download models
COPY fetch_model.py /text-generation-webui/
COPY download_model.py /text-generation-webui/

WORKDIR /

# Copy the scripts
COPY --chmod=755 scripts/* ./

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
ENTRYPOINT [ "/start.sh" ]