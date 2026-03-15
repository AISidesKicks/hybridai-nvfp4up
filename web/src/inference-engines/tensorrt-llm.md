# TensorRT-LLM Deployment Guide

[TensorRT-LLM](https://github.com/NVIDIA/TensorRT-LLM) is NVIDIA's highly optimized inference engine for LLMs, designed to maximize performance on Blackwell architecture GPUs with features like PagedAttention, continuous batching, and FP8 precision.

## NVFP4 Deployment Process

Deploying Nemotron 3 Super with TensorRT-LLM involves two main steps:
1. **Quantization**: Convert the PyTorch model to NVFP4 format using TensorRT Model Optimizer
2. **Engine Build**: Compile the quantized model into an optimized TensorRT engine

## Step 1: Quantization with TensorRT Model Optimizer

First, quantize the model to NVFP4 format:

```bash
python hf_ptq.py \
  --pyt_ckpt_path /models/Nemotron-3-Super-120B-A12B-NVFP4 \
  --qformat nvfp4 \
  --export_fmt tensorrt_llm \
  --output_dir ./nemotron-3-super-120b-nvfp4
```

### Quantization Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `--pyt_ckpt_path` | `/path/to/model` | Path to the original PyTorch model |
| `--qformat` | `nvfp4` | Specify NVFP4 quantization format |
| `--export_fmt` | `tensorrt_llm` | Export format for TensorRT-LLM |
| `--output_dir` | `./nemotron-3-super-120b-nvfp4` | Directory to save quantized model |

## Step 2: Building the TensorRT Engine

Next, build the optimized inference engine:

```bash
trtllm-build \
  --checkpoint_dir ./nemotron-3-super-120b-nvfp4 \
  --engine_dir ./nemotron-3-super-120b-nvfp4-engine \
  --gpt_attention_plugin fp8 \
  --kv_cache_mode fp8 \
  --max_batch_size 8 \
  --max_input_len 1024 \
  --max_output_len 1024
```

### Key Build Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `--checkpoint_dir` | `./nemotron-3-super-120b-nvfp4` | Directory with quantized model |
| `--engine_dir` | `./nemotron-3-super-120b-nvfp4-engine` | Output directory for engine |
| `--gpt_attention_plugin` | `fp8` | Use FP8 for attention plugin |
| `--kv_cache_mode` | `fp8` | Enable FP8 KV cache |
| `--max_batch_size` | `8` | Maximum batch size (adjust based on use case) |
| `--max_input_len` | `1024` | Maximum input sequence length |
| `--max_output_len` | `1024` | Maximum output sequence length |

## Deployment with Triton Inference Server (Recommended for Production)

For scalable deployment, use TensorRT-LLM backend with Triton Inference Server:

### 1. Prepare Model Repository

```
model_repository/
└── nemotron_3_super/
    ├── config.pbtxt
    └── 1/
        ├── model.engine
        └── model.json
```

### 2. Example `config.pbtxt`

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

### 3. Run Triton Server

```bash
docker run --gpus all --rm -p8000:8000 -p8001:8001 -p8002:8002 \
  -v $(pwd)/model_repository:/models \
  nvcr.io/nvidia/tritonserver:24.07-py3 \
  tritonserver --model-repository=/models
```

## Performance Optimization Tips

### Quantization Considerations
- **NVFP4 Format**: Provides 4x memory reduction vs FP16 with minimal accuracy loss for many tasks
- **Calibration**: The quantization process uses a calibration dataset (if provided) to optimize scaling factors
- **Validation**: Always validate quantized model accuracy for your specific use case

### Engine Build Tuning
- **Batch Size**: Adjust `--max_batch_size` based on your latency/throughput requirements
- **Sequence Lengths**: Set `--max_input_len` and `--max_output_len` to match your application needs
- **Plugin Selection**: FP8 plugins provide best performance on Blackwell GPUs

### Resource Allocation
- **GPU Memory**: TensorRT-LLM engines are typically smaller than the original model due to quantization
- **Concurrent Requests**: Use Triton's dynamic batching to maximize GPU utilization
- **Memory Pool**: Adjust tensorrt memory pool size if needed for very long contexts

## Verification

After deployment with Triton, test the endpoint:
```bash
curl -X POST localhost:8000/v2/models/nemotron_3_super/infer \
  -H "Content-Type: application/json" \
  -d '{
    "inputs": [
      {
        "name": "input_ids",
        "shape": [1, 5],
        "datatype": "INT32",
        "data": [[128006, 29892, 29958, 29947, 29915]]
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

## Troubleshooting

- **Quantization Errors**: Ensure you have the latest TensorRT Model Optimizer and that the model is supported
- **Engine Build Failures**: Check GPU memory availability and try reducing batch size or sequence lengths
- **Triton Connection Issues**: Verify the model repository structure and config.pbtxt syntax
- **Performance Issues**: Profile with `nvtx` ranges and TensorBoard to identify bottlenecks

## References

- [TensorRT-LLM GitHub Repository](https://github.com/NVIDIA/TensorRT-LLM)
- [TensorRT Model Optimizer](https://github.com/NVIDIA/TensorRT-Model-Optimizer)
- [Triton Inference Server](https://github.com/triton-inference-server/server)
- [TensorRT-LLM Backend for Triton](https://github.com/triton-inference-server/tensorrtllm_backend)
