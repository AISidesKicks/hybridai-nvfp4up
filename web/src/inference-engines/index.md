# Inference Engines Overview

To maximize performance, parallelization, and context window sizes on Blackwell GPUs, Nemotron 3 Super is optimized for four primary inference engines with native NVFP4 support.

Each engine has specific flags and configurations for optimal NVFP4 performance. Choose the engine that best fits your use case:

## Engine Comparison

| Engine | NVFP4 Flag | KV Cache | Best For |
|--------|-----------|----------|----------|
| **vLLM** | `--quantization compressed-tensors` | `--kv-cache-dtype fp8` | High-throughput serving, OpenAI API compatibility |
| **SGLang** | `--quantization modelopt_fp4` | Auto | Complex prompting, structured outputs |
| **TensorRT-LLM** | Build with `--qformat nvfp4` | `--kv_cache_mode fp8` | Maximum performance, NVIDIA-native optimization |
| **Triton** | TensorRT-LLM backend | Via backend | Scalable production deployments, dynamic batching |

## Getting Started

Select an engine below for detailed setup instructions:

- [vLLM](./vllm.md) - Industry standard for PagedAttention and continuous batching
- [SGLang](./sglang.md) - High-performance serving with strong structured output support
- [TensorRT-LLM](./tensorrt-llm.md) - NVIDIA's native optimized inference engine
- [Triton](./triton.md) - Scalable production-grade model serving

## Hardware Requirements

All engines require:
- Blackwell Architecture GPU (RTX PRO 6000, B200/B300, GB200/GB300, DGX Spark)
- CUDA 12.9+ or 13.x for native NVFP4 support
- Docker with NVIDIA Container Toolkit
- ~200GB+ NVMe storage for model + working space

