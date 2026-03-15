# NeoClouds Provider Overview

The hybridai-NVFP4 TUI application integrates with specialized GPU cloud providers (Neo-Clouds) via APIs/SDKs to provision transient computing power optimized for NVFP4 workloads on Blackwell architecture GPUs.

These providers offer GPU-optimized infrastructure with flexible pricing models, ideal for the "one-off" high-compute tasks that the hybridai-NVFP4 system is designed to handle.

## Provider Comparison

| Provider | Website | Primary Integration | Best For | Typical GPU Offerings |
|----------|---------|-------------------|----------|----------------------|
| **Modal** | modal.com | SDK/API | Serverless, bursty workloads | H100, A100, L40S, custom GPU tiers |
| **SimplePod** | simplepod.com | Kubernetes pods | Predictable, sustained loads | H100, H200, Blackwell GPUs |
| **Verda** | verda.com | REST API instances | Low-latency, interactive use | H100, HGX H100, custom configurations |
| **Nebius** | nebius.com | Cloud platform | Enterprise, scalable deployments | H100, B200, custom GPU clusters |

## Core Requirements Across All Platforms

To successfully deploy Nemotron 3 Super in NVFP4 format on any NeoCloud provider, ensure the following:

1. **Blackwell GPU Architecture Support** (sm_100 compute capability)
   - Required for native NVFP4 support
   - Look for instances mentioning Blackwell, B200, B300, GB200, GB300, or DGX Spark

2. **CUDA Version 12.9+ or 13.x**
   - Essential for NVFP4 quantization and inference
   - Verify in provider documentation or instance specifications

3. **Docker with NVIDIA Container Toolkit**
   - Required for containerized deployment of inference engines
   - Most GPU-focused providers include this by default

4. **High-Bandwidth Networking & Storage**
   - NVMe storage recommended for model caching (~200GB+)
   - Sufficient network bandwidth for multi-GPU communication if using tensor parallelism

5. **Flexible Instance Lifecycle Management**
   - Ability to start/stop instances on demand
   - Support for spot/preemptible instances for cost optimization
   - API/SDK provisioning for automation

## Cost Optimization Strategies

### Spot/Preemptible Instances
All four providers offer discounted instances with interruption potential:
- **Modal**: Functions can be interrupted but designed for fault tolerance
- **SimplePod**: Spot pods with termination grace periods
- **Verda**: Preemptible instances with warning periods
- **Nebius**: Preemptible VMs with configurable notice

### Right-Sizing Recommendations
For Nemotron 3 Super 120B NVFP4:
- **Minimum**: 2x Blackwell GPUs (e.g., 2x RTX PRO 6000) for tensor parallel size 2
- **Recommended**: 4x Blackwell GPUs for better performance with tensor parallel size 4
- **Maximum**: 8x Blackwell GPUs for maximum throughput (tensor parallel size 8)

### Storage Considerations
- Model storage: ~200GB for Nemotron 3 Super NVFP4 + working space
- Recommended: 500GB+ NVMe for comfortable operation
- For evals/benchmarks: 1TB+ NVMe
- For model development: 2TB+ NVMe+

## Getting Started

Select a provider below for detailed deployment instructions:

- [Modal](./modal.md) - Serverless platform for bursty GPU workloads
- [SimplePod](./simplepod.md) - Kubernetes-based GPU provisioning
- [Verda](./verda.md) - REST API for GPU instance management
- [Nebius](./nebius.md) - Full cloud platform with GPU optimization

## Authentication & Secrets Management

Each provider requires secure handling of credentials:
- **Hugging Face Token**: Read-only access for gated models like Nemotron 3 Super
- **API Keys**: Provider-specific authentication for instance provisioning
- **SSH Keys**: Optional for secure instance access
- **Registry Credentials**: For pulling Docker images from private repositories

Best practices:
- Use provider secret management systems when available
- Rotate tokens regularly
- Limit permissions to minimum required
- Audit access regularly