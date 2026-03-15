# SGLang Deployment Guide

[SGLang](https://sglang.ai/) is a high-performance serving framework designed for complex prompting and structured outputs, with strong support for ModelOpt quantization.

## NVFP4-Specific Configuration

For Nemotron 3 Super in NVFP4 format, use the following flags:

| Flag | Value | Description |
|------|-------|-------------|
| `--quantization` | `modelopt_fp4` | For ModelOpt FP4 quantized models (recommended) |
| `--trust-remote-code` | `true` | Required for custom architectures like Nemotron 3 Super's Mamba-Transformer MoE |
| `--tp` | `2` (example) | Tensor parallelism size |
| `--max-running-requests` | `256` (example) | Maximum number of concurrent requests |

## Example Deployment Command

```bash
python -m sglang.launch_server \
  --model-path /models/Nemotron-3-Super-120B-A12B-NVFP4 \
  --quantization modelopt_fp4 \
  --trust-remote-code \
  --tp 2 \
  --max-running-requests 256 \
  --port 30000 \
  --host 0.0.0.0
```

### Docker Deployment Example

```bash
docker run --gpus all -it --rm \
  -v /path/to/models:/models \
  -p 30000:30000 \
  lmsys/sglang:latest \
  python -m sglang.launch_server \
    --model-path /models/Nemotron-3-Super-120B-A12B-NVFP4 \
    --quantization modelopt_fp4 \
    --trust-remote-code \
    --tp 2 \
    --max-running-requests 256
```

## Performance Notes

- **Tensor Parallelism (`--tp`)**: Adjust based on available GPU memory. For the 120B model:
  - 1x RTX PRO 6000 (96GB): May require `--tp 4` or higher (check memory constraints)
  - 2x RTX PRO 6000: Use `--tp 2`
  - 1x B200/B300 (192GB): Can use `--tp 1` or `2` depending on other workload
- **Memory Usage**: SGLang uses paged attention similar to vLLM, enabling efficient memory usage for long contexts.
- **Running Requests**: The `--max-running-requests` parameter controls how many requests can be processed concurrently. Adjust based on your latency and throughput requirements.

## Verification

After deployment, test the endpoint:
```bash
curl http://localhost:30000/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nemotron-3-super",
    "prompt": "Hello, my name is",
    "max_new_tokens": 10,
    "sampling_params": {
      "temperature": 0.7,
      "top_p": 0.9
    }
  }'
```

## Troubleshooting

- **Out of Memory**: Reduce `--tp` or decrease `--max-running-requests`
- **Slow Initialization**: Ensure the model is properly quantized and accessible
- **Connection Issues**: Check firewall settings and verify the host/port configuration

## References

- [SGLang Documentation](https://sglang.ai/doc/)
- [ModelOpt Quantization Integration](https://lmsys.org/blog/2025-12-02-modelopt-quantization/)
- [SGLang Launch Server Arguments](https://sglang.ai/doc/server/launch.html)