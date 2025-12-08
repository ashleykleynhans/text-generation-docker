#!/usr/bin/env bash
set -e

# Install torch
python3 -m venv --system-site-packages /venv
source /venv/bin/activate
pip3 install --upgrade pip
pip3 install torch==${TORCH_VERSION} --index-url ${INDEX_URL}

# Clone the git repo of Text Generation Web UI and set version
git clone https://github.com/oobabooga/text-generation-webui
cd /text-generation-webui
git checkout ${OOBABOOGA_VERSION}

# Install the dependencies for Text Generation Web UI
# Including all extensions
pip3 install --upgrade setuptools
pip3 install -r requirements/full/requirements.txt
bash -c 'for req in extensions/*/requirements.txt ; do pip3 install -r "$req" ; done'
#    mkdir -p repositories
#    cd repositories
#    git clone https://github.com/turboderp/exllamav2
#    cd exllamav2
#    pip3 install -r requirements.txt
#    pip3 install .

# Fix numpy and pandas incompatibility issue
pip3 install --force-reinstall numpy==2.2.* pandas
