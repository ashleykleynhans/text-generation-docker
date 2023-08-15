#!/usr/bin/env bash
export PYTHONUNBUFFERED=1

echo "Container is running"

# Sync venv to workspace to support Network volumes
echo "Syncing venv to workspace, please wait..."
rsync -au /venv/ /workspace/venv/

# Sync text-generation-webui to workspace to support Network volumes
echo "Syncing text-generation-webui to workspace, please wait..."
rsync -au /text-generation-webui/ /workspace/text-generation-webui/

# Fix the venv to make it work from /workspace
echo "Fixing venv..."
/fix_venv.sh /venv /workspace/venv

if [[ ${MODEL} ]];
then
  /workspace/text-generation-webui/
fi

if [[ ${DISABLE_AUTOLAUNCH} ]];
then
    echo "Auto launching is disabled so the application will not be started automatically"
    echo "You can launch it manually:"
    echo ""
    echo "   cd /workspace/text-generation-webui"
    echo "   deactivate && source /workspace/venv/bin/activate"
    echo "   ./start_textgen_server.sh"
else
    mkdir -p /workspace/logs
    echo "Starting Oobabooga Text Generation Web UI"
    source /workspace/venv/bin/activate
    cd /workspace/text-generation-webui && nohup ./start_textgen_server.sh > /workspace/logs/textgen.log 2>&1 &
    echo "Oobabooga Text Generation Web UI started"
    echo "Log file: /workspace/logs/textgen.log"
    deactivate
fi

echo "All services have been started"