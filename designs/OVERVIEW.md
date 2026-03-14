**Project:** `hybridai-NVFP4`

 is a Python-based Terminal User Interface (TUI) application designed to seamlessly spin up, manage, and deeply monitor Large Language Models (LLMs) on high-performance Nvidia hardware. It focuses exclusively on the latest Blackwell architecture and NVFP4 (Nvidia 4-bit Floating Point) optimizations.

## 🎯 Primary Use Cases
NFVP4UP is built for high-compute "one-off" tasks that require significant hardware horsepower on demand:
* **Evaluations (Evals):** Running comprehensive benchmark suites against massive models.
* **Profiling:** Deep hardware and inference engine telemetry for performance tuning.
* **Red Teaming:** Automated and manual adversarial testing requiring high-throughput, low-latency generation.

---

## 🛠 Tech Stack & Tools

### Core Environment
* **Language:** Python 3.12
* **Environment Management:** Conda (Environment name: `hybridai-nvfp4`)
* **User Interface:** Textual TUI framework + `textual-plot` for real-time terminal telemetry and graphs.

### Runtime Environment
* **Primary Containerization:** Docker with NVIDIA Container Toolkit (CUDA support).
* **OS/VM:** Ubuntu 24.04 LTS equipped with CUDA drivers, functioning either on bare metal or as a base VM for Docker hosts.
* **Required Secrets:** Hugging Face Read-Only Access Token (for fetching gated/optimized weights).

---

## 🚀 Inference Engines
To maximize performance, parallelization, and context window sizes on Blackwell GPUs, we target engines with native NVFP4 support and advanced continuous batching.

* **sglang:** High-performance serving with strong support for complex prompting and structured outputs.
* **vLLM:** The industry standard for PagedAttention and high-throughput continuous batching.
* **TensorRT-LLM:** Nvidia's native, highly optimized inference engine specifically designed to squeeze maximum FLOPs out of Blackwell architectures.
* **Triton Inference Server:** For scalable, production-grade model serving and dynamic batching.

---

## 🔧 NVFP4 Optimal Configuration Templates

Each inference engine has specific flags and configurations for optimal NVFP4 performance on Blackwell GPUs.

### vLLM

**Key Flags:**
- `--quantization compressed-tensors` - For models quantized with llmcompressor
- `--quantization nvfp4` - For pre-quantized NVFP4 models (if supported)
- `--kv-cache-dtype fp8` - Enable FP8 KV cache
- `--dtype auto` - Automatic dtype selection

**Example Launch:**
```bash
docker run --gpus all vllm/vllm-openai:latest \
  --model nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-NVFP4 \
  --dtype auto \
  --quantization compressed-tensors \
  --max-model-len 131072 \
  --tensor-parallel-size 2
```

**Reference:** [vLLM Quantization Docs](https://docs.vllm.ai/en/latest/features/quantization/)

---

### SGLang

**Key Flags:**
- `--quantization modelopt_fp4` - For ModelOpt FP4 quantized models
- `--quantization modelopt` - For general ModelOpt quantized models
- `--trust-remote-code` - Required for custom architectures

**Example Launch:**
```bash
python -m sglang.launch_server \
  --model-path nvidia/Llama-3.3-70B-Instruct-FP4 \
  --quantization modelopt_fp4 \
  --trust-remote-code \
  --tp 2 \
  --max-running-requests 256
```

**Reference:** [SGLang ModelOpt Integration](https://lmsys.org/blog/2025-12-02-modelopt-quantization/)

---

### TensorRT-LLM

**Quantization (requires TensorRT Model Optimizer):**
```bash
python hf_ptq.py \
  --pyt_ckpt_path meta-llama/Llama-3.3-70B-Instruct \
  --qformat nvfp4 \
  --export_fmt tensorrt_llm \
  --output_dir ./llama-3.3-70b-nvfp4
```

**Engine Build:**
```bash
trtllm-build \
  --checkpoint_dir ./llama-3.3-70b-nvfp4 \
  --engine_dir ./llama-3.3-70b-nvfp4-engine \
  --gpt_attention_plugin fp8 \
  --kv_cache_mode fp8
```

**Reference:** [TensorRT Model Optimizer](https://github.com/NVIDIA/TensorRT-Model-Optimizer)

---

### Triton Inference Server

**Configuration:** Use TensorRT-LLM backend with NVFP4 engine. TRS handles batching and deployment.

**Reference:** [Triton TensorRT-LLM Backend](https://github.com/triton-inference-server/tensorrtllm_backend)

---

### Quick Reference Matrix

| Engine | NVFP4 Flag | KV Cache | GPU Units for ~180GB VRAM |
|--------|-----------|----------|---------------------------|
| vLLM | `--quantization compressed-tensors` | `--kv-cache-dtype fp8` | RTX PRO 6000: 2 / DGX Spark: 2 / B100+: 1 |
| SGLang | `--quantization modelopt_fp4` | Auto | RTX PRO 6000: 2 / DGX Spark: 2 / B100+: 1 |
| TensorRT-LLM | Build with `--qformat nvfp4` | `--kv_cache_mode fp8` | RTX PRO 6000: 2 / DGX Spark: 2 / B100+: 1 |
| Triton | TensorRT-LLM backend | Via backend | RTX PRO 6000: 2 / DGX Spark: 2 / B100+: 1 |

---

## 🖥 Hardware Targets (Blackwell Architecture)

### GPU Types with CUDA Compute Compatibility

| GPU Type | Code Name | VRAM | Units for ~190GB | Compute Capability (sm) | NVFP4 Support | Notes |
|----------|-----------|------|------------------|------------------------|----------------|-------|
| RTX PRO 6000 Blackwell | Blackwell | 96GB GDDR7 | 2 (192GB) | sm_100 | ✅ | Professional workstation PCIe card |
| B200 | Blackwell | 192GB | 1 | sm_100 | ✅ | Data center |
| B300 | Blackwell | 192GB | 1 | sm_100 | ✅ | Data center |
| GB200 | Blackwell | 192GB | 1 | sm_100 | ✅ | Grace CPU + Blackwell GPU |
| GB300 | Blackwell | 192GB | 1 | sm_100 | ✅ | Grace CPU + Blackwell GPU |
| DGX Spark | Blackwell | 128GB unified | 2 (200GB) | sm_100 | ✅ | Desktop DevKit, 1-4TB NVMe (2 units stacked with CABLEs) |

### CPU Configurations for GB200/GB300

| System | CPU Type | Notes |
|--------|----------|-------|
| GB200 | NVIDIA Grace (72 cores) | High-bandwidth CPU-GPU interconnect |
| GB300 | NVIDIA Grace (72 cores) | Enhanced for inference workloads |

### CUDA Requirements

- **Minimum CUDA:** 12.9+ or 13.x (for native NVFP4 support)
- **Container:** Use NVIDIA NGC `nvcr.io/nvidia/*` containers for best compatibility

---

## ⚙️ Core LLM Parameters

### Per-Model Configuration

| Parameter | Flag | Description | Example |
|-----------|------|-------------|---------|
| Max Context Length | `--max-model-len` | Maximum tokens in context window | `131072` |
| Tensor Parallelism | `--tensor-parallel-size` / `--tp` | GPU shards for model | `2`, `4`, `8` |
| Hardware Units | `--num-gpus` | Number of GPU units for VRAM scaling | `2` (for RTX PRO 6000) |
| KV Cache Quantization | `--kv-cache-dtype` | KV cache precision | `fp8`, `fp8_e5m2` |
| Max Sequences | `--max-num-seqs` | Maximum concurrent sequences | `256` |
| Memory Utilization | `--gpu-memory-utilization` | VRAM allocation per GPU (0.0-1.0) | `0.95` |

### Example: Complete vLLM Launch

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

---

## 💾 Disk Space Requirements

### Model Storage

| Model | Quantization | Storage Required | Notes |
|-------|-------------|------------------|-------|
| Nemotron-3-Super-120B-A12B-NVFP4 | NVFP4 + working | ~200GB recommended | Model + KV cache + logs (~16 X 5GB safetensor NVFP4 files) |

### Minimum Disk Space Recommendations

| Use Case | Minimum | Recommended |
|----------|---------|-------------|
| Single model inference | 200GB NVMe | 500GB+ NVMe |
| Evals/Benchmarks | 500GB NVMe | 1TB+ NVMe |
| Model development/fine-tuning | 1TB NVMe | 2TB+ NVMe |

**Note:** DGX Spark includes 1TB or 4TB NVMe storage. For production workloads, 4TB recommended.

---

## ☁️ Cloud Providers (Neo-Clouds)
Anigravity interacts with specialized GPU cloud providers via APIs/SDKs to provision transient computing power. 

**Core Cloud Requirements:**
* Query real-time pricing (Regular vs. Spot instances).
* Handle Spot Instance lifecycles (Start, Stop, Sleep, Resume).
* Ability to specify precise IAM/access rights for spawned instances.

**Target Providers:**
* **Modal** (`modal.com`) - SDK/API integration.
* **SimplePod** (`simplepod.com`) - SDK/API integration.
* **Verda** (`verda.com`) - SDK/API integration.
* **Nebius** (`nebius.com`) - SDK/API integration.

---

## 🧠 Supported Models
Focusing heavily on cutting-edge architectures optimized for agentic reasoning and NVFP4 precision.

* **NVIDIA Nemotron-3-Super (120B-A12B-NVFP4)**
    * *Architecture:* Open Hybrid Mamba-Transformer Mixture of Experts (MoE).
    * *Links:* * [Developer Blog](https://developer.nvidia.com/blog/introducing-nemotron-3-super-an-open-hybrid-mamba-transformer-moe-for-agentic-reasoning/)
        * [HF Collection](https://huggingface.co/collections/nvidia/nvidia-nemotron-v3)
        * [Model Card](https://huggingface.co/nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-NVFP4)

---

## 🌐 Networking & Tunneling
* **Tunnel:** Automated SSH port redirection to bind remote inference engine APIs securely to `localhost` for seamless local TUI interaction.

---

## 📊 Observability & Proxy (Optional but Recommended)

* **Proxy (LiteLLM):** Deploy LiteLLM via Docker to act as a unified proxy.
    * Generates custom, per-session provider IDs.
    * Standardizes API requests across different inference engines.
* **Observability (Phoenix):** Deploy Arize Phoenix via Docker.
    * Integrates with LiteLLM for deep request/response tracing, token counting, and evaluation observability.

See also [status-bar.md](status=bar.md) - I will like to see what is happening with HW in remote docker container.

---

## 📚 Documentation Structure
* `README.md`: Minimal introduction, quickstart guide, and core badges.
* `designs/`: Directory containing architecture diagrams, sequence flows, and technical design documents (TDDs).
* `docs/`: Comprehensive How-Tos, API references, and full project documentation. (Static GitHub web page about this project on domain nvfp4up.hybridai.click)
