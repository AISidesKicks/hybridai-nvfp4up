# nvfp4up (hybridai-nfvp4up) [nvfp4.hybridai.click](nvfp4.hybridai.click)

nvfp4up is a Python-based Terminal User Interface (TUI) designed to provision, manage, and deeply monitor NVFP4-optimized Large Language Models (LLMs) across local and cloud-based Nvidia Blackwell hardware.

For a full breakdown of the architecture, hardware targets, and supported models (like Nemotron-3-Super), see our [OVERVIEW.md](OVERVIEW.md).

## 🚀 Quickstart

### 1. Prerequisites
* **Python:** 3.12
* **Environment:** Conda (recommended)
* **Runtime:** Linux with Docker

### 2. Setup Local Environment
Clone the repository and set up your Conda environment:

```bash
# Clone the repo
git clone [https://github.com/your-org/hybridai-nvfp4.git](https://github.com/your-org/hybridai-nvfp4up.git)
cd hybridai-nvfp4up

# Create and activate the conda environment
conda create -n hybridai-nvfp4 python=3.12 -y
conda activate hybridai-nvfp4

# Install TUI dependencies
pip install textual textual-plotext

