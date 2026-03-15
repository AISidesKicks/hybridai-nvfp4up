# Modal Deployment Guide

[Modal](https://modal.com) is a serverless platform that allows you to run containerized workloads in the cloud with per-second billing. It's particularly well-suited for bursty GPU workloads like LLM inference.

## Why Modal for Nemotron 3 Super NVFP4?

- **Per-second billing**: Only pay for actual GPU compute time
- **Automatic scaling**: Scale from zero to hundreds of GPUs instantly
- **Simple Python API**: Define functions and deploy with minimal configuration
- **Built-in secrets management**: Securely handle Hugging Face tokens and API keys
- **Container customization**: Full control over your Docker environment

## Prerequisites

1. [Modal account](https://modal.com/signup)
2. [Modal CLI installed](https://modal.com/docs/guide/cli)
3. Hugging Face Read-Only Access Token (for accessing gated models)
4. Docker installed locally (for building custom images if needed)

## Deployment Options

### Option 1: Using Modal's Official Images (Recommended for Quick Start)

For rapid deployment without custom image building, use Modal's base images with NVIDIA drivers:

```python
# deploy_modal.py
import modal
import os

# Create a Modal app
app = modal.App("nemotron-3-super-nvfp4")

# Define the image with necessary dependencies
image = (
    modal.Image.from_registry("nvcr.io/nvidia/pytorch:24.05-py3")
    .apt_install("git")  # Add any system dependencies needed
    .pip_install(
        "vllm",  # or "sglang", "triton", etc.
        "huggingface_hub",
        "torch",
        "transformers"
    )
    .env({
        "HF_TOKEN": os.environ["HF_TOKEN"],  # Set via modal secret
    })
)

# Mount your model volume (if using persistent storage)
# model_volume = modal.Volume.from_name("nemotron-model", create_if_missing=True)

@app.function(
    image=image,
    gpu="H100:2",  # Request 2 H100 GPUs (adjust based on your needs)
    # volumes={"/models": model_volume},  # Uncomment if using persistent volume
    secrets=[modal.Secret.from_name("hf-token")],  # Reference your secret
    timeout=3600,  # 1 hour timeout
)
@modal.web_server(8000, startup_timeout=60)
def serve():
    import subprocess
    import os
    
    # Example: Launch vLLM server
    cmd = [
        "vllm", "serve",
        "/models/Nemotron-3-Super-120B-A12B-NVFP4",
        "--host", "0.0.0.0",
        "--port", "8000",
        "--tensor-parallel-size", "2",
        "--dtype", "auto",
        "--quantization", "compressed-tensors",
        "--max-model-len", "131072",
        "--gpu-memory-utilization", "0.95",
        "--kv-cache-dtype", "fp8"
    ]
    
    # Adjust model path if using volume mount
    # cmd[3] = "/models/Nemotron-3-Super-120B-A12B-NVFP4"
    
    subprocess.Popen(cmd)
    
    # Keep the function running
    import signal
    signal.pause()

# Local testing function
@app.function(
    image=image,
    gpu="H100:2",
    secrets=[modal.Secret.from_name("hf-token")],
    timeout=300,
)
def test_inference():
    import subprocess
    import time
    
    # Start server in background
    server_process = subprocess.Popen([
        "vllm", "serve",
        "/models/Nemotron-3-Super-120B-A12B-NVFP4",
        "--host", "0.0.0.0",
        "--port", "8000",
        "--tensor-parallel-size", "2",
        "--dtype", "auto",
        "--quantization", "compressed-tensors",
        "--max-model-len", "131072",
        "--gpu-memory-utilization", "0.95",
        "--kv-cache-dtype", "fp8"
    ])
    
    # Wait for server to start
    time.sleep(30)
    
    # Test inference
    import requests
    response = requests.post(
        "http://localhost:8000/v1/completions",
        json={
            "model": "nemotron-3-super",
            "prompt": "Hello, my name is",
            "max_tokens": 10
        }
    )
    print(response.json())
    
    # Clean up
    server_process.terminate()
```

### Option 2: Custom Docker Image (For Full Control)

If you need specific dependencies or want to optimize the image:

```dockerfile
# Dockerfile
FROM nvcr.io/nvidia/pytorch:24.05-py3

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Set environment variables
ENV HF_TOKEN=${HF_TOKEN}

# Create non-root user (optional but recommended)
RUN useradd -m appuser
WORKDIR /home/appuser
USER appuser

# Default command (can be overridden)
CMD ["bash"]
```

```python
# deploy_custom_modal.py
import modal
import os

app = modal.App("nemotron-3-super-custom")

# Build custom image from Dockerfile
image = modal.Image.from_dockerfile("Dockerfile")

@app.function(
    image=image,
    gpu="H100:2",
    secrets=[modal.Secret.from_name("hf-token")],
    timeout=3600,
)
@modal.web_server(8000)
def serve():
    import subprocess
    subprocess.Popen([
        "vllm", "serve",
        "/models/Nemotron-3-Super-120B-A12B-NVFP4",
        "--host", "0.0.0.0",
        "--port", "8000",
        "--tensor-parallel-size", "2",
        "--dtype", "auto",
        "--quantization", "compressed-tensors",
        "--max-model-len", "131072",
        "--gpu-memory-utilization", "0.95",
        "--kv-cache-dtype", "fp8"
    ])
    import signal
    signal.pause()
```

## Deployment Steps

### 1. Set Up Secrets
```bash
# Store your Hugging Face token securely
modal secret create hf-token HF_TOKEN="your_hf_token_here"
```

### 2. Deploy the Application
```bash
# For the quick start version
python deploy_modal.py deploy

# For the custom image version
python deploy_custom_modal.py deploy
```

### 3. Access Your Endpoint
After deployment, Modal will provide a URL like:
```
https://your-workspace--nemotron-3-super-nvfp4-serve.modal.run
```

Use this URL in your hybridai-NVFP4 TUI or any client application.

## Configuration Options

### GPU Types
Modal offers various GPU options. For Blackwell/NVFP4 optimization:
- `"H100:2"` - 2x H100 GPUs (good starting point)
- `"B200:1"` - 1x B200 GPU (when available)
- `"L40S:4"` - 4x L40S GPUs (alternative)

Adjust based on your tensor parallelism needs and budget.

### Scaling Behavior
By default, Modal web functions scale to zero when idle. You can adjust:
```python
@modal.web_server(8000, 
                  scaledown_window=300,  # Scale down after 5 min of no requests
                  min_containers=1)      # Keep at least 1 container warm
```

### Volume Persistence
For persistent model storage (avoids re-downloading on each deployment):
```python
# Create volume first
modal volume create nemotron-model

# Then use in function
model_volume = modal.Volume.from_name("nemotron-model")
# volumes={"/models": model_volume}
```

## Cost Optimization Tips

### 1. Right-Size GPU Selection
- Start with smaller configurations for testing
- Monitor utilization and adjust GPU count/type
- Consider temporal parallelism if your workload allows

### 2. Use Efficient Quantization
- NVFP4 provides best memory efficiency for this model
- FP8 KV cache further reduces memory footprint
- Avoid over-provisioning due to inefficient configurations

### 3. Implement Smart Scaling
- Set appropriate `scaledown_window` to balance cost vs cold start latency
- Consider `min_containers=0` for truly intermittent workloads
- Use batch processing when possible to maximize GPU utilization

### 4. Monitor and Optimize
- Use Modal's monitoring tools to track GPU utilization
- Log inference metrics to identify bottlenecks
- Adjust parameters based on actual usage patterns

## Troubleshooting

### Common Issues

1. **Container Start Failures**
   - Check build logs for dependency issues
   - Verify GPU availability in your selected region
   - Ensure model path is correct

2. **Out of Memory Errors**
   - Reduce tensor parallel size
   - Lower `--gpu-memory-utilization`
   - Check if model is properly quantized

3. **Connection Problems**
   - Verify the port in `@modal.web_server()` matches your server
   - Check firewall settings (though Modal handles this)
   - Ensure server is binding to `0.0.0.0`

4. **Slow Cold Starts**
   - Optimize Docker image size
   - Consider keeping minimum containers warm
   - Pre-download model during image build if feasible

## References

- [Modal Documentation](https://modal.com/docs/)
- [Modal GPU Guide](https://modal.com/docs/guide/gpu)
- [Modal Secrets Management](https://modal.com/docs/guide/secrets)
- [Modal Web Servers](https://modal.com/docs/guide/webhooks)
- [vLLM Modal Example](https://docs.vllm.ai/en/latest/getting_started/quickstart.html#modal)