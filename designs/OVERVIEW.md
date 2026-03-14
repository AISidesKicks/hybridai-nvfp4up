**Project:** `hybridai-NVFP4`

Anigravity is a Python-based Terminal User Interface (TUI) application designed to seamlessly spin up, manage, and deeply monitor Large Language Models (LLMs) on high-performance Nvidia hardware. It focuses exclusively on the latest Blackwell architecture and NVFP4 (Nvidia 4-bit Floating Point) optimizations.

## 🎯 Primary Use Cases
Anigravity is built for high-compute "one-off" tasks that require significant hardware horsepower on demand:
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

## 🖥 Hardware Targets (Blackwell Architecture)

### 1. Local Development
* **Target:** Nvidia DGX Station / Blackwell DevKit.
* *Note: Currently inaccessible for initial dev, but architecture paths remain compatible.*

### 2. Primary Hardware (Single GPU)
* **Target:** Nvidia RTX 6000 Ada / Blackwell Generation.
* **Goal:** Validating NVFP4 precision, performace, batching, single-node inference tests, and UI/TUI development.

### 3. Secondary Hardware (Multi-GPU)
* **Target:** Nvidia B200 and B300 Blackwell GPUs.
* **Goal:** Heavy evaluations, massive batching, and distributed inference testing.

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

---

## 📚 Documentation Structure
* `README.md`: Minimal introduction, quickstart guide, and core badges.
* `designs/`: Directory containing architecture diagrams, sequence flows, and technical design documents (TDDs).
* `docs/`: Comprehensive How-Tos, API references, and full project documentation. (Static GitHub web page about this project on domain nvfp4up.hybridai.click)
