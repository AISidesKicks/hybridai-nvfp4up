HybridMoE: Nemotron 3 family of models utilize a hybrid Mamba-Transformer MoE architecture to provide best-in-class throughput while having better or on-par accuracy than standard Transformers.
LatentMoE: Super and Ultra utilize Latent MoE, a novel hardware-aware expert design for improved accuracy.
MTP: (Multi-Token Prediction) Super and Ultra incorporate MTP layers for improved long-form text generation efficiency and better model quality.
NVFP4: Super and Ultra are trained with NVFP4 + Blackwell HW (Rubin in future)
LongContext: Nemotron 3 models support context length up to 1M tokens.
Reasonig: Granular Reasoning Budget Control at Inference Time: Nemotron 3 models are trained to work with inference-time budget control.