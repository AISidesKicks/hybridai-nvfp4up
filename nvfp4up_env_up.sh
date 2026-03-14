#!/bin/bash

# 1. Check if the environment is already active
if [[ "$CONDA_DEFAULT_ENV" != "hybridai-nvfp4up" ]]; then
    echo "🔄 Activating hybridai-nvfp4up (mini)conda environment..."
    conda activate hybridai-nvfp4up
    
    # Verify activation worked
    if [[ $? -ne 0 ]]; then
        echo "❌ Error: Could not activate 'hybridai-nvfp4up'. Does it conda enviroment exist?"
        exit 1
    fi
else
    echo "✅ hybridai-nvfp4up is already active."
fi

# 2. Define the project root
export NVFP4UP_ROOT=$(pwd)

# 3. Set the "Portable" paths
export NVFP4UP_MODELS="$MINILAB_ROOT/models"
export NVFP4UP_CACHE="$MINILAB_ROOT/.cache"

# 4. Load HF (Read-Only) Token
if [ -f "$NVFP4UP_ROOT/.env" ]; then
    set -a
    source "$NVFP4UP_ROOT/.env"
    set +a
    HF_PROOF=${HF_TOKEN:0:7}
    echo "🔑 Hugging Face Token Loaded as: ${HF_PROOF}XXXXX-XXXXX"
else
    echo "⚠️ Warning: .env file not found at $NVFP4UP_ROOT/.env"
fi
