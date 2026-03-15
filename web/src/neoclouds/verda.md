# Verda Deployment Guide

[Verda](https://verda.com) provides GPU-optimized cloud infrastructure via REST API, focusing on low-latency, high-performance instances ideal for interactive LLM inference workloads.

## Why Verda for Nemotron 3 Super NVFP4?

- **Low-latency instances**: Optimized for interactive workloads with minimal overhead
- **API-driven provisioning**: Full control via REST API for automation
- **Blackwell GPU support**: Access to latest NVIDIA architecture for NVFP4
- **Flexible instance types**: Choose exact GPU/VRAM configurations needed
- **Transparent pricing**: Competitive rates for sustained workloads

## Prerequisites

1. [Verda account](https://verda.com/signup)
2. [Verda API key](https://verda.com/dashboard/api-keys)
3. Hugging Face Read-Only Access Token
4. curl or HTTP client for API calls
5. SSH client for instance access
6. Docker installed locally (for building images if needed)

## Deployment Overview

Verda instances are provisioned via API, then accessed via SSH to deploy your NVFP4 inference engine. The general workflow is:

1. **Provision Instance**: Use Verda API to create a Blackwell GPU instance
2. **Configure Instance**: Install dependencies via SSH
3. **Deploy Model**: Transfer or pull NVFP4-quantized model
4. **Run Inference Engine**: Start vLLM/SGLang/TensorRT-LLM/Triton
5. **Access Endpoint**: Connect to the instance's public IP/DNS

## Step-by-Step Deployment

### Step 1: Provision a Blackwell GPU Instance

Use the Verda API to create an instance with Blackwell GPU support:

```bash
# Export your API key
export VERDA_API_KEY="your_verda_api_key_here"

# List available GPU types (look for Blackwell/B200/H100 etc.)
curl -X GET "https://api.verda.com/v1/gpu-types" \
  -H "Authorization: Bearer $VERDA_API_KEY"

# Create an instance with Blackwell GPU
# Example: Requesting 2x H100 as proxy for Blackwell until specific Blackwell types are listed
INSTANCE_RESPONSE=$(curl -X POST "https://api.verda.com/v1/instances" \
  -H "Authorization: Bearer $VERDA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "nemotron-3-super-nvfp4",
    "gpu_type": "H100",  # Replace with actual Blackwell type when available (e.g., "B200", "DGX-Spark")
    "gpu_count": 2,
    "cpus": 16,
    "memory": 128,  # GB
    "storage": 500,  # GB NVMe
    "os": "ubuntu_24_04",
    "image": "ubuntu-24.04-base",
    "region": "us-east-1"
  }')

# Extract instance ID from response
INSTANCE_ID=$(echo "$INSTANCE_RESPONSE" | jq -r '.id')
echo "Instance ID: $INSTANCE_ID"
```

### Step 2: Wait for Instance to be Ready

```bash
# Wait for instance to reach running state
while true; do
  STATUS=$(curl -X GET "https://api.verda.com/v1/instances/$INSTANCE_ID" \
    -H "Authorization: Bearer $VERDA_API_KEY" | jq -r '.status')
  
  if [ "$STATUS" = "running" ]; then
    echo "Instance is running!"
    break
  fi
  
  echo "Waiting for instance to be ready... (current status: $STATUS)"
  sleep 15
done

# Get connection details
INSTANCE_INFO=$(curl -X GET "https://api.verda.com/v1/instances/$INSTANCE_ID" \
  -H "Authorization: Bearer $VERDA_API_KEY")

IP_ADDRESS=$(echo "$INSTANCE_INFO" | jq -r '.ip_address')
SSH_USER=$(echo "$INSTANCE_INFO" | jq -r '.default_user')
echo "Connect via: ssh $SSH_USER@$IP_ADDRESS"
```

### Step 3: Connect and Configure the Instance

```bash
# SSH into the instance (you may need to add SSH key first via Verda dashboard/API)
ssh $SSH_USER@$IP_ADDRESS

# Once connected, update system and install dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io nvidia-docker2

# Add user to docker group (may require reboot)
sudo usermod -aG docker $USER
newgrp docker  # Activates docker group immediately

# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
   && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - \
   && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
      sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt update
sudo apt install -y nvidia-docker2
sudo systemctl restart docker

# Test Docker with GPU
sudo docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

### Step 4: Deploy Your NVFP4 Inference Engine

Choose your preferred inference engine. Here's an example with vLLM:

#### Option A: Pull Model at Runtime (Simplest)

```bash
# Login to Hugging Face (you'll need your HF token)
huggingface-cli login  # Enter your HF token when prompted

# Create directory for models
mkdir -p ~/models && cd ~/models

# Pull the Nemotron 3 Super NVFP4 model
huggingface-cli download nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-NVFP4 \
  --repo-type model \
  --local-dir Nemotron-3-Super-120B-A12B-NVFP4

# Run vLLM container
docker run --gpus all -it --rm \
  -v $(pwd)/Nemotron-3-Super-120B-A12B-NVFP4:/models/Nemotron-3-Super-120B-A12B-NVFP4 \
  -p 8000:8000 \
  vllm/vllm-openai:latest \
  --model /models/Nemotron-3-Super-120B-A12B-NVFP4 \
  --host 0.0.0.0 \
  --port 8000 \
  --tensor-parallel-size 2 \
  --dtype auto \
  --quantization compressed-tensors \
  --max-model-len 131072 \
  --gpu-memory-utilization 0.95 \
  --kv-cache-dtype fp8
```

#### Option B: Pre-pull Model for Faster Startup

```bash
# Pull model once, then reuse
huggingface-cli download nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-NVFP4 \
  --repo-type model \
  --local-dir ~/models/Nemotron-3-Super-120B-A12B-NVFP4

# Create a reusable container command
alias run-nemotron='docker run --gpus all -it --rm \
  -v $HOME/models/Nemotron-3-Super-120B-A12B-NVFP4:/models/Nemotron-3-Super-120B-A12B-NVFP4 \
  -p 8000:8000 \
  vllm/vllm-openai:latest \
  --model /models/Nemotron-3-Super-120B-A12B-NVFP4 \
  --host 0.0.0.0 \
  --port 8000 \
  --tensor-parallel-size 2 \
  --dtype auto \
  --quantization compressed-tensors \
  --max-model-len 131072 \
  --gpu-memory-utilization 0.95 \
  --kv-cache-dtype fp8'

# Run it
run-nemotron
```

#### Option C: Systemd Service for Persistent Operation

Create a service file for automatic startup:

```bash
# Create the service file
sudo tee /etc/systemd/system/nemotron-3-super.service > /dev/null <<EOF
[Unit]
Description=Nemotron 3 Super NVFP4 Inference Server
After=network-online.target docker.service
Requires=docker.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/models
ExecStart=/usr/bin/docker run --rm \\
  --gpus all \\
  -v $HOME/models/Nemotron-3-Super-120B-A12B-NVFP4:/models/Nemotron-3-Super-120B-A12B-NVFP4 \\
  -p 8000:8000 \\
  vllm/vllm-openai:latest \\
  --model /models/Nemotron-3-Super-120B-A12B-NVFP4 \\
  --host 0.0.0.0 \\
  --port 8000 \\
  --tensor-parallel-size 2 \\
  --dtype auto \\
  --quantization compressed-tensors \\
  --max-model-len 131072 \\
  --gpu-memory-utilization 0.95 \\
  --kv-cache-dtype fp8
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable nemotron-3-super.service
sudo systemctl start nemotron-3-super.service

# Check status
sudo systemctl status nemotron-3-super.service
```

### Step 5: Access Your Inference Endpoint

Once the server is running, access it via:

```
http://$IP_ADDRESS:8000/v1/completions
```

Example test:
```bash
curl http://$IP_ADDRESS:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nemotron-3-super",
    "prompt": "Hello, my name is",
    "max_tokens": 10
  }'
```

## Configuration Options

### GPU Selection
When provisioning via API, specify the GPU type:
```json
{
  "gpu_type": "B200",  // or "H100", "DGX-Spark" etc. when Blackwell types are listed
  "gpu_count": 2
}
```

### Storage Considerations
- **Model Storage**: ~200GB for Nemotron 3 Super NVFP4
- **Recommended**: 500GB+ NVMe for comfortable operation
- **For evals/benchmarks**: 1TB+ NVMe
- **Storage Type**: Verda typically offers NVMe storage for GPU instances

### Networking
- Verda instances typically get a public IP address by default
- Security groups/firewall rules may need to be configured to allow port 8000
- Consider using a reverse proxy or VPN for production access

## Alternative Inference Engines on Verda

### SGLang
```bash
# Install SGLang
pip install sglang[all]

# Launch server
python -m sglang.launch_server \
  --model-path /models/Nemotron-3-Super-120B-A12B-NVFP4 \
  --quantization modelopt_fp4 \
  --trust-remote-code \
  --tp 2 \
  --max-running-requests 256 \
  --host 0.0.0.0 \
  --port 30000
```

### TensorRT-LLM
Follow the [TensorRT-LLM guide](../inference-engines/tensorrt-llm.md) to:
1. Quantize model with `hf_ptq.py --qformat nvfp4`
2. Build engine with `trtllm-build`
3. Deploy via Triton or directly

### Triton Inference Server
1. Prepare TensorRT-LLM engine (as above)
2. Set up model repository
3. Run Triton container:
```bash
docker run --gpus all --rm -p8000:8000 \
  -v $(pwd)/model_repository:/models \
  nvcr.io/nvidia/tritonserver:24.07-py3 \
  tritonserver --model-repository=/models
```

## Cost Optimization Strategies

### 1. Right-Sizing Instances
- Start with smaller configurations for development/testing
- Monitor GPU utilization and adjust instance type/size
- Consider using fractional GPUs if Verda offers them (less likely for LLMs)

### 2. Instance Lifecycle Management
- **Stop when not in use**: Verda likely allows stopping instances (not terminating) to preserve storage while avoiding compute charges
- **Automated shutdown**: Implement idle detection to automatically stop instances
- **Scheduled workloads**: Run instances only during known peak usage times

### 3. Storage Efficiency
- Use snapshots/images to preserve state without running instance
- Compress model backups when storing long-term
- Consider storing model in object storage and pulling to instance on startup

### 4. Resource Monitoring
- Track GPU utilization, memory usage, and throughput
- Identify over-provisioned resources
- Adjust based on actual workload patterns

## Troubleshooting

### Common Issues

1. **Instance Provisioning Failures**
   - Check API response for error messages
   - Verify GPU type and quantity availability in your region
   - Check account limits/quotas

2. **Connection/SSH Issues**
   - Verify instance is in "running" state
   - Check SSH key configuration in Verda dashboard
   - Verify IP address and port (typically 22)
   - Check local firewall settings

3. **Docker/GPU Issues Inside Instance**
   - Verify NVIDIA drivers are installed: `nvidia-smi`
   - Check Docker can access GPU: `docker run --gpus all nvidia/cuda:12.4.1-base nvidia-smi`
   - Ensure user is in docker group

4. **Model Loading Problems**
   - Verify Hugging Face token has read access to the model
   - Check available disk space (>200GB needed)
   - Ensure model was downloaded completely

5. **Inference Engine Errors**
   - Check engine-specific logs
   - Verify command syntax and flags
   - Try reducing tensor parallel size if OOM occurs
   - Ensure sufficient swap space if needed

### Diagnostic Commands

```bash
# Check Verda instance status
curl -X GET "https://api.verda.com/v1/instances/$INSTANCE_ID" \
  -H "Authorization: Bearer $VERDA_API_KEY"

# Test GPU access from within instance
nvidia-smi
docker run --gpus all --rm nvidia/cuda:12.4.1-base nvidia-smi

# Check model files
ls -lh /models/Nemotron-3-Super-120B-A12B-NVFP4/
du -sh /models/Nemotron-3-Super-120B-A12B-NVFP4/

# Test network connectivity
curl -I http://localhost:8000/v1/health  # Adjust endpoint as needed
```

## References

- [Verda Documentation](https://verda.com/docs/)
- [Verda API Reference](https://verda.com/docs/api)
- [Verda GPU Types](https://verda.com/gpu-types)
- [Ubuntu NVIDIA Driver Installation](https://ubuntu.com/tutorials/install-nvidia-drivers-on-ubuntu#1-overview)
- [Hugging Face Model Access](https://huggingface.co/docs/hub/models-downloading)