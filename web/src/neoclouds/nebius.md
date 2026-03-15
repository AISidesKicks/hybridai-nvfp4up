# Nebius Deployment Guide

[Nebius](https://nebius.com) is a cloud platform specializing in AI/ML workloads with GPU-optimized infrastructure, offering scalable instances ideal for deploying Nemotron 3 Super in NVFP4 format.

## Why Nebius for Nemotron 3 Super NVFP4?

- **AI-Optimized Infrastructure**: Purpose-built for machine learning workloads
- **Blackwell GPU Access**: Direct access to latest NVIDIA architecture for NVFP4
- **API-Driven Provisioning**: Full automation via REST API and SDKs
- **Enterprise-Grade Features**: Security, compliance, and monitoring tools
- **Flexible Scaling**: From single instances to large GPU clusters
- **Integrated Storage**: High-performance NVMe and object storage options

## Prerequisites

1. [Nebius account](https://nebius.com/signup)
2. [Nebius API credentials](https://nebius.com/docs/iam/api-keys/)
3. Hugging Face Read-Only Access Token
4. `nebius` CLI or HTTP client for API calls
5. SSH client for instance access
6. Docker installed locally (for building images if needed)

## Deployment Options

Nebius offers multiple deployment approaches:
- **Virtual Machines**: Fully configurable VMs with GPU passthrough
- **Managed Kubernetes**: Nebius Elastic Container Service for Kubernetes
- **Serverless Functions**: For event-driven inference (if available)
- **Bare Metal**: Direct hardware access for maximum performance

This guide focuses on VM deployment as it provides the best balance of control, performance, and ease of use for LLM inference.

## Step-by-Step VM Deployment

### Step 1: Set Up Nebius CLI

```bash
# Install Nebius CLI (if not already installed)
curl -sSf https://nebius.com/cli/install.sh | sh

# Configure CLI with your credentials
nebius config set api-key "your_api_key_here"
nebius config set api-secret "your_api_secret_here"
nebius config set region "eu-central-1"  # or your preferred region

# Verify configuration
nebius config list
```

### Step 2: Check Available GPU Types

```bash
# List available GPU types in your region
nebius compute gpu-types list --region eu-central-1

# Look for Blackwell architecture GPUs (B200, B300, etc.)
# Example output might include:
# NAME        MEMORY  ARCHITECTURE  AVAILABLE
# B200        192GB   Blackwell     true
# H100        80GB    Hopper        true
# L40S        48GB    Ada           true
```

### Step 3: Create SSH Key Pair (if needed)

```bash
# Generate SSH key pair for instance access
ssh-keygen -t ed25519 -f ~/.ssh/nebius-nemotron -N ""

# Optional: Upload public key to Nebius for automatic instance setup
nebius iam ssh-keys create \
  --public-key "$(cat ~/.ssh/nebius-nemotron.pub)" \
  --name "nemotron-access-key"
```

### Step 4: Create the Instance

```bash
# Create an instance with Blackwell GPU
nebius compute instance create \
  --name "nemotron-3-super-nvfp4" \
  --platform "standard-v3" \
  --zone "eu-central-1a" \
  --image-id "ubuntu-2404-lts" \  # or latest Ubuntu LTS with CUDA drivers
  --instance-type "g2-standard-24" \  # Example: adjust based on GPU type
  --gpu-count 2 \  # Number of GPUs (adjust based on tensor parallel needs)
  --gpu-type "nvidia-b200" \  # Replace with actual Blackwell GPU type from listing
  --boot-disk-size 100 \  # GB for OS
  --secondary-disk-size 500 \  # GB NVMe for model storage
  --ssh-key "nebius-nemotron" \  # Name of uploaded SSH key
  --user-data-file cloud-init.yaml  # Optional: for automated setup
```

### Alternative: Using Instance Template (Recommended for Reusability)

First create a template:
```bash
nebius compute instance-templates create \
  --name "nemotron-3-super-template" \
  --platform "standard-v3" \
  --zone "eu-central-1a" \
  --image-id "ubuntu-2404-lts" \
  --instance-type "g2-standard-24" \
  --gpu-count 2 \
  --gpu-type "nvidia-b200" \
  --boot-disk-size 100 \
  --secondary-disk-size 500 \
  --ssh-key "nebius-nemotron" \
  --user-data-file cloud-init.yaml
```

Then create instances from the template:
```bash
nebius compute instance create \
  --name "nemotron-3-super-nvfp4-01" \
  --template-id "nemotron-3-super-template"
```

### Step 5: Cloud-Init for Automated Setup (Optional but Recommended)

Create `cloud-init.yaml` to automate dependency installation:

```yaml
# cloud-init.yaml
#cloud-config
package_update: true
package_upgrade: true
packages:
  - docker.io
  - nvidia-docker2
  - python3-pip
  - git
  - curl
runcmd:
  # Add user to docker group
  - usermod -aG docker ubuntu
  # Install NVIDIA Container Toolkit
  - distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - \
      && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
         sudo tee /etc/apt/sources.list.d/nvidia-docker.list
  - sudo apt update
  - sudo apt install -y nvidia-docker2
  - sudo systemctl restart docker
  # Test GPU access
  - docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
  # Create directories for model storage
  - mkdir -p /models
  - chown ubuntu:ubuntu /models
```

### Step 6: Wait for Instance to be Ready and Connect

```bash
# Wait for instance to reach running state
INSTANCE_ID=$(nebius compute instance list --name nemotron-3-super-nvfp4 --format json | jq -r '.[0].id')

while true; do
  STATUS=$(nebius compute instance get $INSTANCE_ID --format json | jq -r '.status')
  if [ "$STATUS" = "RUNNING" ]; then
    echo "Instance is running!"
    break
  fi
  echo "Waiting for instance to be ready... (current status: $STATUS)"
  sleep 15
done

# Get connection details
INSTANCE_INFO=$(nebius compute instance get $INSTANCE_ID --format json)
IP_ADDRESS=$(echo "$INSTANCE_INFO" | jq -r '.networkInterfaces[0].primaryV4Address.address')
echo "Connect via: ssh ubuntu@$IP_ADDRESS"
```

### Step 7: Connect and Deploy Inference Engine

```bash
# SSH into the instance
ssh -i ~/.ssh/nebius-nemotron ubuntu@$IP_ADDRESS

# Once connected, verify GPU access
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi

# Login to Hugging Face (you'll need your HF token)
huggingface-cli login  # Enter your HF token when prompted

# Create directory for models
mkdir -p ~/models && cd ~/models

# Pull the Nemotron 3 Super NVFP4 model
huggingface-cli download nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-NVFP4 \
  --repo-type model \
  --local-dir Nemotron-3-Super-120B-A12B-NVFP4

# Run your preferred inference engine
# Example: vLLM
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

## Alternative Deployment Approaches

### Option 1: Pre-baked Custom Image

Create a custom image with your inference engine pre-configured:

```bash
# 1. Create a temporary instance to build the image
nebius compute instance create \
  --name "nemotron-image-builder" \
  --platform "standard-v3" \
  --zone "eu-central-1a" \
  --image-id "ubuntu-2404-lts" \
  --instance-type "g2-standard-24" \
  --gpu-count 1 \
  --gpu-type "nvidia-b200" \
  --ssh-key "nebius-nemotron"

# 2. Connect and build your custom Docker image
# (Follow similar steps as above to install dependencies, pull model, etc.)

# 3. Commit the container as an image
docker commit <container-id> your-registry/nemotron-3-super:v1.0

# 4. Push to registry
docker push your-registry/nemotron-3-super:v1.0

# 5. Terminate builder instance
nebius compute instance delete nemotron-image-builder

# 6. Use the image in new instances
# (In user-data or manually run: docker run your-registry/nemotron-3-super:v1.0)
```

### Option 2: Nebius Elastic Container Service (ECS) for Kubernetes

If you prefer Kubernetes management:

```bash
# 1. Create a Kubernetes cluster
nebius cds cluster create \
  --name "nemotron-k8s" \
  --region eu-central-1 \
  --zone eu-central-1a \
  --network "default" \
  --subnet "default" \
  --node-count 3 \
  --node-type "g2-standard-24" \
  --gpu-count-per-node 2 \
  --gpu-type "nvidia-b200"

# 2. Configure kubectl
nebius cds cluster get-kubeconfig --name nemotron-k8s > ~/.kube/nebius-nemotron
export KUBECONFIG=~/.kube/nebius-nemotron

# 3. Deploy using Kubernetes manifests (similar to SimplePod guide)
# Create PVC, secrets, deployments, services as needed
```

## Configuration Options

### Instance Types and GPU Configuration
Nebius offers various GPU instance types. For Nemotron 3 Super NVFP4:
- **GPU Type**: Look for Blackwell architecture (B200, B300, etc.) when available
- **GPU Count**: 
  - Minimum: 2 GPUs for tensor parallel size 2
  - Recommended: 4 GPUs for tensor parallel size 4 (better performance)
  - Maximum: 8+ GPUs for maximum throughput
- **Instance Type**: Match GPU count to appropriate CPU/RAM (e.g., g2-standard-24 for 2 GPUs)

### Storage Recommendations
- **Boot Disk**: 100GB SSD for OS and basic tools
- **Secondary Disk**: 500GB+ NVMe for model storage (~200GB needed for Nemotron 3 Super NVFP4)
- **Optional**: Tertiary disk for logs, checkpoints, or additional model versions

### Networking
- Nebius provides private networking by default
- Public IP assigned automatically (can be reserved for consistency)
- Consider using placement groups for low-latency multi-instance communication
- Configure security groups to restrict access to needed ports only

## Cost Optimization Strategies

### 1. Right-Sizing Resources
- Start with smaller configurations for development/testing
- Monitor utilization via Nebius metrics or cloud monitoring tools
- Adjust instance type, GPU count, and storage based on actual usage
- Consider using heterogeneous instance pools for different workload types

### 2. Preemptible/Spot Instances
Nebius offers preemptible instances at significant discounts:
```bash
# Add to instance creation command
--preemptible true
```
- Ideal for fault-tolerant workloads and batch processing
- Implement checkpointing for long inference jobs
- Configure automatic restart handling in your application

### 3. Reserved Instances / Commitments
For predictable, sustained workloads:
- Nebius may offer committed use discounts
- Reserve instances for 1-3 years for lower hourly rates
- Best for production deployments with stable baseline usage

### 4. Storage Optimization
- Use appropriate storage tiers (performance vs capacity)
- Implement lifecycle policies for automatic data tiering
- Regularly cleanup unused snapshots and temporary volumes
- Consider compressing model backups for long-term storage

### 5. Scheduling and Autoscaling
- Use Nebius scheduling tools to start/stop instances based on demand
- Implement custom autoscaling based on queue depth or API request rates
- Consider zero-to-scaling strategies for intermittent workloads

## Monitoring and Logging

### Built-in Nebius Monitoring
- GPU utilization, memory usage, and temperature
- CPU, memory, disk, and network metrics
- Custom metrics via agent if needed
- Alerting policies for threshold violations

### Logging Options
- System logs accessible via Nebius console or CLI
- Application logs in `/var/log/` or application-specific locations
- Integration with external logging services (ELK, Splunk, etc.)
- Audit logs for security and compliance

### Recommended Monitoring Setup
```bash
# Install monitoring agent if needed (example using Prometheus node-exporter)
docker run -d \
  --net="host" \
  --pid="host" \
  -v "/:/hostfs:ro" \
  prom/node-exporter \
  --path.rootfs=/hostfs

# Then configure Nebius to scrape the metrics endpoint
```

## Troubleshooting

### Common Issues

1. **Instance Creation Failures**
   - Check API response for specific error codes
   - Verify GPU type and quantity availability in selected zone
   - Check account quotas and limits
   - Validate image ID and instance type compatibility

2. **Connection/SSH Issues**
   - Verify instance is in "RUNNING" state
   - Check SSH key configuration (both local and uploaded to Nebius)
   - Verify IP address and security group rules
   - Check local firewall and VPN settings if applicable

3. **GPU/Driver Issues Inside Instance**
   - Verify NVIDIA drivers are loaded: `lsmod | grep nvidia`
   - Check nvidia-smi output
   - Ensure Docker is configured for GPU access
   - Confirm user is in docker group

4. **Model Loading Problems**
   - Verify Hugging Face token has access to the model
   - Check available disk space on secondary volume (>200GB needed)
   - Ensure network connectivity to huggingface.co
   - Verify model was downloaded completely (check file sizes)

5. **Inference Engine Errors**
   - Check engine-specific stdout/stderr logs
   - Verify command syntax matches engine documentation
   - Try reducing tensor parallel size if experiencing OOM
   - Ensure sufficient swap space configured if needed
   - Verify CUDA version compatibility (12.9+ required for NVFP4)

### Diagnostic Commands

```bash
# Check Nebius instance status
nebius compute instance get $INSTANCE_ID --format json

# List instances with filtering
nebius compute instance list --name nemotron-3-super --format json

# Test GPU access from within instance
nvidia-smi
docker run --gpus all --rm nvidia/cuda:12.4.1-base nvidia-smi

# Check model files and space
ls -lh /models/Nemotron-3-Super-120B-A12B-NVFP4/
du -sh /models/Nemotron-3-Super-120B-A12B-NVFP4/
df -h /models

# Check Docker images and containers
docker images
docker ps -a

# Review system logs
journalctl -u docker --since "1 hour ago"
```

## References

- [Nebius Documentation](https://nebius.com/docs/)
- [Nebius CLI Reference](https://nebius.com/docs/cli/)
- [Nebius GPU Instances](https://nebius.com/docs/compute/gpu-instances/)
- [Nebius Images and Storage](https://nebius.com/docs/compute/images/)
- [Nebius Networking and Security](https://nebius.com/docs/network/vpc/)
- [Nebius Monitoring and Logging](https://nebius.com/docs/monitoring/)
