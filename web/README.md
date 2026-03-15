# Web Documentation Site

This directory contains the VitePress-powered documentation site for the NVFP4 project.

## 📁 Directory Structure
```
web/
├── src/                  # Source documentation files (.md)
│   ├── index.md          # Home page
│   ├── inference-engines/# Inference engine docs
│   ├── neoclouds/        # Neocloud provider docs
│   └── nemotron3/        # Nemotron 3 specific docs
├── assets/               # Static assets (images, styles)
├── vitepress.config.js   # VitePress configuration
├── preserve-and-copy.sh  # Build script with CNAME preservation
├── package.json          # npm dependencies and scripts
└── README.md             # This file
```

## 🛠️ Development & Building

### Prerequisites
- Node.js (v18+ recommended)
- npm or yarn

### Installation
```bash
cd ./web
npm install
```

### Available Scripts
- `npm run dev` - Start local development server
- `npm run build` - Build production site (outputs to ../docs/)
- `./preserve-and-copy.sh` - Alternative build script that preserves CNAME

### Deployment
The site is configured to build directly to the `docs/` directory for GitHub Pages deployment via the `outDir` setting in `vitepress.config.js`.

## 🎯 Purpose
This site serves as the public-facing documentation for:
- NVFP4-optimized LLMs deployment guides
- Inference engine integrations (vLLM, SGLang, Triton, TensorRT-LLM)
- Neocloud provider instructions (Modal, SimplePod, Verda, Nebius)
- Nemotron 3 Super specific features and configurations