#!/usr/bin/env bash

ARGS=("$@" --listen --api --listen-port 3001 --api-port 5001 --extensions api --trust-remote-code)

if [[ -f /workspace/text-gen-model ]];
then
  ARGS=("${ARGS[@]}" --model "$(</workspace/text-gen-model)")
fi

VENV_PATH=$(cat /workspace/text-generation-webui/venv_path)
source ${VENV_PATH}/bin/activate
cd /workspace/text-generation-webui
export PYTHONUNBUFFERED=1
export HF_HOME="/workspace"
echo "Starting Oobabooba Text Generation UI: ${ARGS[@]}"
python3 server.py "${ARGS[@]}"
