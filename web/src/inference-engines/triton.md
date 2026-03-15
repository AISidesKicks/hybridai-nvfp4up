# Triton Inference Server Deployment Guide

[Triton Inference Server](https://github.com/triton-inference-server/server) is a cloud and edge inferencing solution optimized for CPU and GPU execution, providing a scalable inference service for deploying Nemotron 3 Super with NVFP4 quantization.

## NVFP4 Deployment Approach

Triton doesn't perform quantization itself but serves as a deployment platform for already-quantized models. For NVFP4 deployment with Triton:

1. **Quantize Model**: Use TensorRT-LLM or another tool to create an NVFP4-optimized model
2. **Deploy via Backend**: Use Triton's TensorRT-LLM backend to serve the quantized engine
3. **Configure Model Repository**: Set up the proper directory structure and configuration

## Deployment Workflow

### Step 1: Prepare NVFP4 Model (Using TensorRT-LLM)
First, create an NVFP4-optimized TensorRT-LLM engine (see [TensorRT-LLM Guide](./tensorrt-llm.md) for details):

```bash
# Quantization
python hf_ptq.py \
  --pyt_ckpt_path /models/Nemotron-3-Super-120B-A12B-NVFP4 \
  --qformat nvfp4 \
  --export_fmt tensorrt_llm \
  --output_dir ./nemotron-3-super-120b-nvfp4

# Engine Build
trtllm-build \
  --checkpoint_dir ./nemotron-3-super-120b-nvfp4 \
  --engine_dir ./nemotron-3-super-120b-nvfp4-engine \
  --gpt_attention_plugin fp8 \
  --kv_cache_mode fp8
```

### Step 2: Set Up Triton Model Repository

Create the following directory structure:

```
model_repository/
└── nemotron_3_super/
    ├── config.pbtxt
    ├── 1/
    │   ├── model.engine
    │   └── model.json
    └── 2/          # Optional: for multiple versions
        ├── model.engine
        └── model.json
```

### Step 3: Configure `config.pbtxt` for TensorRT-LLM Backend

```protobuf
name: "nemotron_3_super"
platform: "tensorrt_llm_plan"
max_batch_size: 8
input [
  {
    name: "input_ids"
    data_type: TYPE_INT32
    dims: [ -1 ]
  },
  {
    name: "request_output_len"
    data_type: TYPE_UINT32
    dims: [ 1 ]
  },
  {
    name: "runtime_top_k"
    data_type: TYPE_UINT32
    dims: [ 1 ]
  },
  {
    name: "runtime_top_p"
    data_type: TYPE_FP32
    dims: [ 1 ]
  },
  {
    name: "temperature"
    data_type: TYPE_FP32
    dims: [ 1 ]
  }
]
output [
  {
    name: "output_ids"
    data_type: TYPE_INT32
    dims: [ -1 ]
  },
  {
    name: "sequence_length"
    data_type: TYPE_UINT32
    dims: [ 1 ]
  },
  {
    name: "cum_log_probs"
    data_type: TYPE_FP32
    dims: [ -1 ]
  },
  {
    name: "log_probs"
    data_type: TYPE_FP32
    dims: [ -1 ]
  }
]
parameters: {
  key: "model_engine_dir"
  value: {
    string_value: "/models/nemotron-3-super-120b-nvfp4-engine"
  }
}
```

### Step 4: Deploy with Docker

```bash
docker run --gpus all --rm -p8000:8000 -p8001:8001 -p8002:8002 \
  -v $(pwd)/model_repository:/models \
  nvcr.io/nvidia/tritonserver:24.07-py3 \
  tritonserver --model-repository=/models \
    --log-verbose=1
```

## Key Configuration Options

### Essential Parameters in config.pbtxt

| Parameter | Description |
|-----------|-------------|
| `platform` | Must be `"tensorrt_llm_plan"` for TensorRT-LLM backend |
| `max_batch_size` | Maximum batch size for dynamic batching |
| `input`/`output` | Tensor definitions matching the model's interface |
| `parameters.model_engine_dir` | Path to the TensorRT-LLM engine directory |

### Triton Server Flags

| Flag | Description |
|------|-------------|
| `--model-repository` | Path to the model repository |
| `--log-verbose` | Enable detailed logging (useful for debugging) |
| `--exit-on-error` | Exit if any model fails to load |
| `--strict-model-config` | Enforce strict model config validation |
| `--allow-http`/`--allow-grpc` | Enable specific protocols (both enabled by default) |

## Performance Features

### Dynamic Batching
Triton's dynamic batching automatically combines multiple inference requests to improve GPU utilization:
- Configure max batch size in `config.pbtxt`
- Triton will batch up to that number of requests
- Particularly effective for variable-length LLM generation

### Concurrent Model Execution
- Load multiple versions of the model (e.g., different quantization levels)
- Use model versioning for A/B testing or gradual rollouts
- Each version uses GPU memory proportionally

### Memory Management
- TensorRT-LLM engines are memory-efficient due to NVFP4 quantization
- KV cache uses FP8 precision as specified in engine build
- Triton manages GPU memory allocation across models

## Verification

### HTTP Endpoint Test
```bash
curl -X POST localhost:8000/v2/models/nemotron_3_super/infer \
  -H "Content-Type: application/json" \
  -d '{
    "inputs": [
      {
        "name": "input_ids",
        "shape": [1, 5],
        "datatype": "INT32",
        "data": [[128006, 29892, 29958, 29947, 29915]]  // "Hello, my name is"
      },
      {
        "name": "request_output_len",
        "shape": [1],
        "datatype": "UINT32",
        "data": [10]
      }
    ]
  }'
```

### Using OpenAI-Compatible Endpoint (if configured)
Triton can be configured with an OpenAI-compatible HTTP proxy service:
```bash
curl http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nemotron-3-super",
    "prompt": "Hello, my name is",
    "max_tokens": 10,
    "temperature": 0.7
  }'
```

## Troubleshooting

### Common Issues

1. **Model Load Failures**
   - Check Triton logs for specific error messages
   - Verify `config.pbtxt` syntax and paths
   - Ensure the engine directory contains valid `.engine` file

2. **GPU Memory Errors**
   - Reduce `max_batch_size` in config.pbtxt
   - Verify engine was built with correct GPU architecture
   - Check for other processes consuming GPU memory

3. **Slow Response Times**
   - Enable logging to identify bottlenecks
   - Check if dynamic batching is working effectively
   - Consider increasing max_batch_size if GPU utilization is low

4. **Connection Issues**
   - Verify port mapping in docker run command
   - Check firewall settings
   - Ensure Triton server process is running

### Diagnostic Commands

```bash
# Check server status
curl localhost:8000/v2/health/ready

# List available models
curl localhost:8000/v2/models

# Get model metadata
curl localhost:8000/v2/models/nemotron_3_super

# Get model configuration
curl localhost:8000/v2/models/nemotron_3_super/config
```

## References

- [Triton Inference Server Documentation](https://docs.nvidia.com/deeplearning/triton-inference-server/user-guide/docs/)
- [TensorRT-LLM Backend for Triton](https://github.com/triton-inference-server/tensorrtllm_backend)
- [Model Repository Structure](https://docs.nvidia.com/deeplearning/triton-inference-server/user-guide/docs/model_repository.html)