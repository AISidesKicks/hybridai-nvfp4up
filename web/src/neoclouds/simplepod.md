# SimplePod Deployment Guide

[SimplePod](https://simplepod.com) provides Kubernetes-based GPU pod provisioning with transparent pricing and direct access to bare-metal performance. It's ideal for predictable, sustained LLM workloads.

## Why SimplePod for Nemotron 3 Super NVFP4?

- **Bare-metal performance**: No virtualization overhead
- **Transparent pricing**: Per-second billing with no hidden fees
- **Kubernetes-native**: Familiar deployment workflow for containerized workloads
- **Direct GPU access**: Full utilization of Blackwell GPU capabilities
- **Simple CLI**: Easy pod management and monitoring

## Prerequisites

1. [SimplePod account](https://simplepod.com/signup)
2. [SimplePod CLI installed](https://simplepod.com/docs/cli)
3. Hugging Face Read-Only Access Token
4. kubectl configured (SimplePod provides kubeconfig)
5. Docker installed (for building custom images if needed)

## Deployment Options

### Option 1: Using Official Images with Environment Variables

Create a pod specification that uses official inference engine images with configuration via environment variables:

```yaml
# nemotron-simplepod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nemotron-3-super-vllm
  labels:
    app: nemotron-3-super
spec:
  restartPolicy: Never
  containers:
  - name: vllm-server
    image: vllm/vllm-openai:latest
    args:
      - --model
      - /models/Nemotron-3-Super-120B-A12B-NVFP4
      - --host
      - "0.0.0.0"
      - --port
      - "8000"
      - --tensor-parallel-size
      - "2"
      - --dtype
      - "auto"
      - --quantization
      - "compressed-tensors"
      - --max-model-len
      - "131072"
      - --gpu-memory-utilization
      - "0.95"
      - --kv-cache-dtype
      - "fp8"
    env:
    - name: HF_TOKEN
      valueFrom:
        secretKeyRef:
          name: hf-secret
          key: token
    resources:
      limits:
        nvidia.com/gpu: 2  # Request 2 GPUs for tensor parallel size 2
    volumeMounts:
    - name: model-storage
      mountPath: /models
    ports:
    - containerPort: 8000
  volumes:
  - name: model-storage
    persistentVolumeClaim:
      claimName: nemotron-model-pvc  # Pre-created PVC with model data
---
# Optional: Service for easier access
apiVersion: v1
kind: Service
metadata:
  name: nemotron-3-super-service
spec:
  selector:
    app: nemotron-3-super
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8000
  type: LoadBalancer
```

### Option 2: Custom Image with Pre-loaded Model

For faster startup times, bake the model into a custom image:

```dockerfile
# Dockerfile.nemotron
FROM vllm/vllm-openai:latest

# Set environment variables for Hugging Face access
ARG HF_TOKEN
ENV HF_TOKEN=${HF_TOKEN}

# Create model directory
RUN mkdir -p /models

# Download model during build (requires build-time secret)
# NOTE: For security, consider using volume mounts instead in production
RUN huggingface-cli download nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-NVFP4 \
    --repo-type model \
    --local-dir /models/Nemotron-3-Super-120B-A12B-NVFP4 \
    --token $HF_TOKEN

# Expose the port
EXPOSE 8000

# Default command
CMD ["vllm", "serve", \
     "/models/Nemotron-3-Super-120B-A12B-NVFP4", \
     "--host", "0.0.0.0", \
     "--port", "8000", \
     "--tensor-parallel-size", "2", \
     "--dtype", "auto", \
     "--quantization", "compressed-tensors", \
     "--max-model-len", "131072", \
     "--gpu-memory-utilization", "0.95", \
     "--kv-cache-dtype", "fp8"]
```

Then reference it in your pod spec:
```yaml
containers:
- name: vllm-server
  image: your-registry/nemotron-3-super:v1.0
  # ... rest same as above
```

### Option 3: Using Persistent Volume for Model Storage

Recommended approach for balancing startup time and flexibility:

```yaml
# nemotron-simplepod-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nemotron-model-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Gi  # Adjust based on your needs
  storageClassName: simplepod-standard  # or your preferred storage class
---
apiVersion: v1
kind: Pod
metadata:
  name: nemotron-3-super-pvc
spec:
  restartPolicy: Never
  containers:
  - name: vllm-server
    image: vllm/vllm-openai:latest
    args:
      - --model
      - /models/Nemotron-3-Super-120B-A12B-NVFP4
      - --host
      - "0.0.0.0"
      - --port
      - "8000"
      - --tensor-parallel-size
      - "2"
      - --dtype
      - "auto"
      - --quantization
      - "compressed-tensors"
      - --max-model-len
      - "131072"
      - --gpu-memory-utilization
      - "0.95"
      - --kv-cache-dtype
      - "fp8"
    env:
    - name: HF_TOKEN
      valueFrom:
        secretKeyRef:
          name: hf-secret
          key: token
    resources:
      limits:
        nvidia.com/gpu: 2
    volumeMounts:
    - name: model-storage
      mountPath: /models
  volumes:
  - name: model-storage
    persistentVolumeClaim:
      claimName: nemotron-model-pvc
```

## Deployment Steps

### 1. Prepare Hugging Face Secret
```bash
# Create a secret for your HF token
kubectl create secret generic hf-secret \
  --from-literal=token="your_hf_token_here"
```

### 2. Create Persistent Volume Claim (if using PVC approach)
```bash
kubectl apply -f nemotron-simplepod-pvc.yaml
```

### 3. Upload Model to Storage (if using PVC)
You'll need to initially populate the PVC with your model files. This can be done via:
- A temporary pod that copies data to the PVC
- SimplePod's file transfer mechanisms
- Pre-signed URLs if your storage provider supports them

### 4. Deploy the Pod
```bash
kubectl apply -f nemotron-simplepod.yaml
```

### 5. Access the Service
If you created the LoadBalancer service:
```bash
# Get the external IP
kubectl get service nemotron-3-super-service

# Then access via http://<EXTERNAL-IP>
```

## Configuration Options

### GPU Resource Requests
Adjust based on your tensor parallelism needs:
```yaml
resources:
  limits:
    nvidia.com/gpu: 2  # For tensor parallel size 2
```
For tensor parallel size 4: `nvidia.com/gpu: 4`
For tensor parallel size 1: `nvidia.com/gpu: 1` (requires sufficient single GPU memory)

### Model Path Adjustments
If your model is stored in a different location within the volume:
```yaml
args:
  - --model
  - /mnt/models/Nemotron-3-Super-120B-A12B-NVFP4  # Adjust path
  # ... rest of args
```

### Alternative Inference Engines
Simply change the image and args:
- **SGLang**: `lmsys/sglang:latest` with appropriate launch command
- **TensorRT-LLM**: Custom image with pre-built engine
- **Triton**: `nvcr.io/nvidia/tritonserver:24.07-py3` with model repository

## Scaling Options

### Single Pod (For Development/Test)
As shown above - good for testing and low-traffic scenarios.

### Deployment for High Availability
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nemotron-3-super-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nemotron-3-super
  template:
    metadata:
      labels:
        app: nemotron-3-super
    spec:
      containers:
      - name: vllm-server
        # ... same container spec as in pod
      # Add pod anti-affinity for better distribution
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - nemotron-3-super
            topologyKey: "kubernetes.io/hostname"
```

### Horizontal Pod Autoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nemotron-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nemotron-3-super-deployment
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: gpu
      target:
        type: Utilization
        averageUtilization: 80
```

## Cost Optimization Strategies

### 1. Right-Sizing Instances
- Start with minimal GPU allocation for testing
- Monitor utilization via SimplePod dashboard or kubectl top
- Adjust based on actual workload patterns
- Consider using heterogeneous node pools if available

### 2. Spot Instances / Preemptible Nodes
SimplePod may offer spot instances - check their documentation:
- Significantly lower cost
- Suitable for fault-tolerant workloads
- Implement checkpointing for long-running inference jobs

### 3. Efficient Resource Utilization
- Use tensor parallelism to distribute model across multiple GPUs
- Adjust batch size and max_num_seqs based on latency requirements
- Monitor GPU memory usage and adjust utilization factor

### 4. Storage Optimization
- Use appropriate storage class for your access pattern
- Consider caching frequently accessed model layers
- Archive older model versions if doing frequent updates

## Monitoring and Logging

### Basic Monitoring
```bash
# View pod logs
kubectl logs -f nemotron-3-super-vllm

# Describe pod for events and resource usage
kubectl describe pod nemotron-3-super-vllm

# Top command for resource usage
kubectl top pod nemotron-3-super-vllm
```

### Advanced Monitoring
SimplePod may integrate with:
- Prometheus/Grafana for metrics
- ELK stack for logs
- Custom monitoring solutions

Check SimplePod documentation for available observability features.

## Troubleshooting

### Common Issues

1. **Pod Pending State**
   - Check events: `kubectl describe pod <name>`
   - Common causes: insufficient GPU quota, PVC binding issues
   - Solution: Check quota with SimplePod dashboard or support

2. **Container Crashing**
   - Check logs: `kubectl logs <pod-name>`
   - Common causes: missing HF token, incorrect model path, OOM
   - Solution: Fix configuration and redeploy

3. **Out of Memory (OOM)**
   - Look for OOMKilled in pod status
   - Solutions:
     - Reduce `--tensor-parallel-size`
     - Lower `--gpu-memory-utilization` (e.g., 0.9 → 0.8)
     - Check if model is properly quantized
     - Increase GPU allocation if possible

4. **Connection Issues**
   - Verify service type and ports
   - Check if LoadBalancer has external IP assigned
   - Test port forwarding: `kubectl port-forward pod/nemotron-3-super-vllm 8000:8000`

### Diagnostic Commands
```bash
# Check PVC status
kubectl get pvc nemotron-model-pvc

# Check node GPU allocation
kubectl describe nodes | grep -A 10 -B 5 "nvidia.com/gpu"

# Check events for namespace
kubectl get events --sort-by='.lastTimestamp'
```

## References

- [SimplePod Documentation](https://simplepod.com/docs/)
- [SimplePod CLI Reference](https://simplepod.com/docs/cli)
- [Kubernetes GPU Documentation](https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/)
- [Persistent Volumes in Kubernetes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [SimplePod Pricing Model](https://simplepod.com/pricing)