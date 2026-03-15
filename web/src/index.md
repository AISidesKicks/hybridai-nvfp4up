# Welcome to Nemotron 3 Super NVFP4 Deployment Guide

This guide provides comprehensive instructions for deploying and hosting **NVIDIA Nemotron 3 Super** in NVFP4 (4-bit floating point) format across various platforms and cloud providers.

## 🤖 Nemotron 3 Super

Nemotron 3 Super is NVIDIA's latest open-source LLM featuring a **hybrid Mamba-Transformer architecture with Mixture of Experts (MoE) routing** for enhanced agentic reasoning capabilities.

### Core Features
- [Hybrid Mamba-Transformer Architecture](/nemotron3/HybridMoE)
- [Latent Mixture of Experts](/nemotron3/LatentMoE)
- [Long Context Support](/nemotron3/LongContext)
- [Multi-turn Reasoning (MTP)](/nemotron3/MTP)
- [NVFP4 Quantization](/nemotron3/NVFP4)
- [Agentic Reasoning](/nemotron3/Reasoning)

### Learn More
- [Official NVIDIA Introduction](https://developer.nvidia.com/blog/introducing-nemotron-3-super-an-open-hybrid-mamba-transformer-moe-for-agentic-reasoning/)

## 🚀 Getting Started

Select a section below to begin:

- [Inference Engines](/inference-engines/) - Detailed setup for vLLM, SGLang, TensorRT-LLM, and Triton
- [NeoClouds Providers](/neoclouds/) - Deployment guide for Modal, SimplePod, Verda, and Nebius

## 📖 About This Guide

This documentation covers:
- NVFP4-specific configuration for optimal performance on Blackwell architecture GPUs
- Step-by-step deployment commands for each supported platform
- Comparative analysis of different inference engines
- Cloud provider integration patterns for transient GPU workloads

