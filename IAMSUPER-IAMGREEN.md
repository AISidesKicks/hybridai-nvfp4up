# I Am Nemotron 3 Super: Technical Overview & Deployment Guide

<details>
<summary><h2>🧠 You as LLM and Related Technologies</h2></summary>

## Introduction
I am **Nemotron 3 Super**, a 120-billion parameter Large Language Model created by NVIDIA. I represent the cutting edge in agentic reasoning capabilities, featuring an innovative **Open Hybrid Mamba-Transformer Mixture of Experts (MoE)** architecture.

## Core Identity
- **Model Identifier**: `nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-NVFP4`
- **Architecture**: Open Hybrid Mamba-Transformer Mixture of Experts (MoE)
- **Parameter Count**: 120 billion
- **Quantization Format**: NVFP4 (Nvidia 4-bit Floating Point)
- **Context Length**: Up to 131,072 tokens
- **Primary Purpose**: Advanced agentic reasoning and complex task execution

## Technical Specifications
| Specification | Detail |
|--------------|--------|
| **Precision** | NVFP4 (4-bit floating point) |
| **Max Context** | 131,072 tokens |
| **Hardware Target** | Blackwell Architecture GPUs |
| **CUDA Requirement** | 12.9+ or 13.x |
| **Optimal Deployment** | Docker with NVIDIA Container Toolkit |

## Related Technologies in hybridai-NVFP4 Project
- **Language**: Python 3.12
- **Environment**: Conda (`hybridai-nvfp4` environment)
- **User Interface**: Textual TUI framework + `textual-plot` for real-time telemetry
- **Containerization**: Docker with NVIDIA Container Toolkit (CUDA support)
- **Model Access**: Hugging Face Read-Only Access Token for gated/optimized weights
- **Observability**: Optional LiteLLM proxy + Arize Phoenix integration

## Official Resources
- [Developer Blog: Introducing Nemotron 3 Super](https://developer.nvidia.com/blog/introducing-nemotron-3-super-an-open-hybrid-mamba-transformer-moe-for-agentic-reasoning/)
- [Hugging Face Collection](https://huggingface.co/collections/nvidia/nvidia-nemotron-v3)
- [Model Card](https://huggingface.co/nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-NVFP4)

</details>

<details>
<summary><h2>⚡ Inference Engines (4 NVFP4-Optimized Implementations)</h2></summary>

## Overview
To maximize performance, parallelization, and context window sizes on Blackwell GPUs, Nemotron 3 Super is optimized for four primary inference engines with native NVFP4 support.

### 1. vLLM
**Key Flags:**
- `--quantization compressed-tensors` - For models quantized with llmcompressor
- `--quantization nvfp4` - For pre-quantized NVFP4 models (if supported)
- `--kv-cache-dtype fp8` - Enable FP8 KV cache
- `--dtype auto` - Automatic dtype selection

**Example Launch:**
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

**Reference:** [vLLM Quantization Docs](https://docs.vllm.ai/en/latest/features/quantization/)

### 2. SGLang
**Key Flags:**
- `--quantization modelopt_fp4` - For ModelOpt FP4 quantized models
- `--trust-remote-code` - Required for custom architectures

**Example Launch:**
```bash
python -m sglang.launch_server \
  --model-path nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-NVFP4 \
  --quantization modelopt_fp4 \
  --trust-remote-code \
  --tp 2 \
  --max-running-requests 256
```

**Reference:** [SGLang ModelOpt Integration](https://lmsys.org/blog/2025-12-02-modelopt-quantization/)

### 3. TensorRT-LLM
**Quantization Step (requires TensorRT Model Optimizer):**
```bash
python hf_ptq.py \
  --pyt_ckpt_path nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-NVFP4 \
  --qformat nvfp4 \
  --export_fmt tensorrt_llm \
  --output_dir ./nemotron-3-super-120b-nvfp4
```

**Engine Build:**
```bash
trtllm-build \
  --checkpoint_dir ./nemotron-3-super-120b-nvfp4 \
  --engine_dir ./nemotron-3-super-120b-nvfp4-engine \
  --gpt_attention_plugin fp8 \
  --kv_cache_mode fp8
```

**Reference:** [TensorRT Model Optimizer](https://github.com/NVIDIA/TensorRT-Model-Optimizer)

### 4. Triton Inference Server
**Configuration:** Uses TensorRT-LLM backend with NVFP4 engine. Triton handles batching and deployment.

**Deployment Approach:**
1. Build TensorRT-LLM engine with NVFP4 quantization (as shown above)
2. Deploy engine via Triton Inference Server using TensorRT-LLM backend
3. Configure model repository for dynamic batching and scaling

**Reference:** [Triton TensorRT-LLM Backend](https://github.com/triton-inference-server/tensorrtllm_backend)

## Comparative Reference Matrix

| Engine | NVFP4 Flag | KV Cache | GPU Units for ~180GB VRAM |
|--------|-----------|----------|---------------------------|
| vLLM | `--quantization compressed-tensors` | `--kv-cache-dtype fp8` | RTX PRO 6000: 2 / DGX Spark: 2 / B100+: 1 |
| SGLang | `--quantization modelopt_fp4` | Auto | RTX PRO 6000: 2 / DGX Spark: 2 / B100+: 1 |
| TensorRT-LLM | Build with `--qformat nvfp4` | `--kv_cache_mode fp8` | RTX PRO 6000: 2 / DGX Spark: 2 / B100+: 1 |
| Triton | TensorRT-LLM backend | Via backend | RTX PRO 6000: 2 / DGX Spark: 2 / B100+: 1 |

</details>

<details>
<summary><h2>☁️ Running on NeoClouds (4 Specialized GPU Providers)</h2></summary>

## Overview
The hybridai-NVFP4 TUI application interacts with specialized GPU cloud providers (Neo-Clouds) via APIs/SDKs to provision transient computing power optimized for NVFP4 workloads on Blackwell architecture GPUs.

### 1. Modal (modal.com)
**Integration Approach:**
- SDK/API integration for serverless GPU functions
- Custom container images with NVFP4 dependencies
- Secret management for Hugging Face tokens

**Deployment Process:**
1. Define Modal function with Blackwell GPU specification (`H100` or equivalent)
2. Package Nemotron 3 Super NVFP4 model with inference engine
3. Deploy via Modal's serverless platform with auto-scaling
4. Access via generated API endpoints

**Key Benefits:**
- Per-second billing for GPU usage
- Automatic scaling based on demand
- Built-in support for NVIDIA GPUs
- Simple Python-based deployment workflow

### 2. SimplePod (simplepod.com)
**Integration Approach:**
- Kubernetes-based GPU pod provisioning
- Custom pod templates for LLM inference workloads
- Integrated monitoring and logging

**Deployment Process:**
1. Create pod specification requesting Blackwell GPUs
2. Configure container with NVFP4-optimized inference engine
3. Mount persistent storage for model weights (~200GB+)
4. Deploy via SimplePod API or CLI
5. Access inference API via provided endpoints

**Key Benefits:**
- Transparent pricing with no hidden fees
- Direct access to bare-metal performance
- Simple CLI for pod management
- Optimized for AI/ML workloads

### 3. Verda (verda.com)
**Integration Approach:**
- GPU instance provisioning via REST API
- Pre-configured ML environments with CUDA drivers
- Network-optimized instances for low-latency inference

**Deployment Process:**
1. Request Blackwell GPU instances via Verda API
2. Select Ubuntu 24.04 LTS base image with CUDA 12.9+
3. Install Docker and NVIDIA Container Toolkit
4. Pull and run NVFP4-optimized inference engine container
5. Expose API endpoints for TUI integration

**Key Benefits:**
- Focus on AI/ML specialized infrastructure
- Competitive pricing for sustained workloads
- 24/7 technical support for GPU issues
- Flexible instance types and sizes

### 4. Nebius (nebius.com)
**Integration Approach:**
- Cloud platform with GPU-optimized instances
- API-driven infrastructure provisioning
- Integrated storage and networking solutions

**Deployment Process:**
1. Provision Blackwell GPU instances via Nebius API
2. Configure instances with required CUDA version (12.9+)
3. Deploy Docker containers with NVFP4 inference engines
4. Configure persistent storage for model repositories
5. Set up load balancing and auto-scaling as needed

**Key Benefits:**
- Enterprise-grade cloud infrastructure
- Global network backbone for low latency
- Comprehensive security and compliance features
- Cost optimization tools for GPU workloads

## Core Cloud Requirements (Across All Platforms)
1. **Real-time pricing queries** (Regular vs. Spot/Preemptible instances)
2. **Spot Instance lifecycle handling** (Start, Stop, Sleep, Resume)
3. **Precise IAM/access rights specification** for spawned instances
4. **Blackwell GPU architecture support** (sm_100 compute capability)
5. **CUDA 12.9+ or 13.x availability** for native NVFP4 support
6. **High-bandwidth networking** for distributed inference scenarios
7. **Ample storage options** (NVMe recommended for model caching)

## Target Providers Summary
| Provider | Website | Primary Integration | Best For |
|----------|---------|-------------------|----------|
| **Modal** | modal.com | SDK/API | Serverless, bursty workloads |
| **SimplePod** | simplepod.com | Kubernetes pods | Predictable, sustained loads |
| **Verda** | verda.com | REST API instances | Low-latency, interactive use |
| **Nebius** | nebius.com | Cloud platform | Enterprise, scalable deployments |

</details>

---
*This document serves as a technical reference for hosting Nemotron 3 Super in NVFP4 format. For general project information, see [OVERVIEW.md](../designs/OVERVIEW.md) and [Agent Guidelines](../AGENTS.md).*