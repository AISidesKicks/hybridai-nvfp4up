# vLLM Deployment Guide

[vLLM](https://docs.vllm.ai/) is a high-throughput and memory-efficient inference engine that supports PagedAttention and continuous batching.

## NVFP4-Specific Configuration

For Nemotron 3 Super in NVFP4 format, use the following flags:

| Flag | Value | Description |
|------|-------|-------------|
| `--quantization` | `compressed-tensors` | For models quantized with llmcompressor (recommended) |
| `--kv-cache-dtype` | `fp8` | Enable FP8 KV cache for reduced memory usage |
| `--dtype` | `auto` | Automatic dtype selection based on model |
| `--model` | `/path/to/Nemotron-3-Super-120B-A12B-NVFP4` | Path to the model directory |

## Example Deployment Commands

### Docker Run (Single Node)
```bash
docker run --gpus all \
  -v ./models:/models \
  vllm/vllm-openai:latest \
  --model /models/Nemotron-3-Super-120B-A12B-NVFP4 \
  --dtype auto \
  --quantization compressed-tensors \
  --max-model-len 131072 \
  --tensor-parallel-size 4 \
  --gpu-memory-utilization 0.95 \
  --kv-cache-dtype fp8 \
  --max-num-seqs 256
```

### Kubernetes Deployment (Example)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nemotron-3-super-vllm
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nemotron-3-super-vllm
  template:
    metadata:
      labels:
        app: nemotron-3-super-vllm
    spec:
      containers:
      - name: vllm
        image: vllm/vllm-openai:latest
        args:
          - --model
          - /models/Nemotron-3-Super-120B-A12B-NVFP4
          - --dtype
          - auto
          - --quantization
          - compressed-tensors
          - --max-model-len
          - "131072"
          - --tensor-parallel-size
          - "4"
          - --gpu-memory-utilization
          - "0.95"
          - --kv-cache-dtype
          - fp8
          - --max-num-seqs
          - "256"
        volumeMounts:
        - name: model-volume
          mountPath: /models
        resources:
          limits:
            nvidia.com/gpu: 4  # Adjust based on tensor parallel size
      volumes:
      - name: model-volume
        persistentVolumeClaim:
          claimName: nemotron-model-pvc  # Pre-populated with model files
```

## Performance Notes

- **Tensor Parallel Size**: Adjust based on available GPU memory. For 120B model:
  - 1x RTX PRO 6000 (96GB): Not sufficient for full model
  - 2x RTX PRO 6000: Use `--tensor-parallel-size 2`
  - 1x B200/B300 (192GB): Can use `--tensor-parallel-size 1` with sufficient memory
- **Context Length**: The model supports up to 131,072 tokens, but longer contexts require more KV cache memory.
- **Memory Utilization**: The `--gpu-memory-utilization` factor (0.0-1.0) controls what fraction of GPU memory is used for model weights and KV cache.

## Verification

After deployment, test the endpoint:
```bash
curl http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nemotron-3-super",
    "prompt": "Hello, my name is",
    "max_tokens": 10
  }'
```

## Troubleshooting

- **Out of Memory**: Reduce `--tensor-parallel-size` or `--gpu-memory-utilization`
- **Slow First Token**: Consider increasing `--max-num-seqs` to better utilize batching
- **Model Loading Errors**: Ensure the model path is correctly mounted and accessible

## References

- [vLLM Documentation](https://docs.vllm.ai/)
- [vLLM Quantization Features](https://docs.vllm.ai/en/latest/features/quantization/)
