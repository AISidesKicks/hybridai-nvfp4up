# Status Bar Documentation

## Overview

The status bar displays real-time GPU monitoring and system information in the header. It provides at-a-glance visibility into GPU health, memory usage, and performance metrics.

## Layout

### Right Side (GPU Status)
Fixed-width values prevent layout shifts during updates.

### Fixed Width Values

| Metric | Width | Example Max Value |
|--------|-------|-------------------|
| GPU Name | `min-w-[60px]` | RTX 4090 (8 chars, filtered) |
| VRAM | `min-w-[95px]` | 99.9 / 99.9 GB |
| Temperature | `min-w-[35px]` | 100°C |
| Fan % | `min-w-[35px]` | 100% |
| Fan RPM | `min-w-[65px]` | 9999 RPM |
| Power | `min-w-[60px]` | 500/600W |


## Components

### 2. GPU Name

| Icon | Format | Example |
|------|--------|---------|
| 🖥️ | `🖥️ {gpu_name}` | `🖥️ RTX 4090` |

Displays the NVIDIA GPU device name.

#### GPU Name Filtering

GPU names are filtered to remove redundant branding for cleaner display:

**Filter Rules:**
1. Remove "NVIDIA" (case-insensitive, always)
2. Remove "GeForce" (case-insensitive, if present)
3. Collapse multiple spaces and trim

**Transformation Examples:**

| Original | Filtered |
|----------|----------|
| `NVIDIA GeForce RTX 4070` | `RTX 4070` |
| `NVIDIA RTX 3090` | `RTX 3090` |
| `GeForce GTX 1080` | `GTX 1080` |
| `NVIDIA GeForce GTX 1660 Ti` | `GTX 1660 Ti` |


### 3. VRAM Usage

| Icon | Format | Example |
|------|--------|---------|
| 🔵🟢🟡🟠🔴 | `{icon} VRAM {used} / {total} GB` | `🟢 VRAM 12.5 / 24.0 GB` |

#### VRAM Indicator Colors

| Usage Range | Level | Icon | Color | Description |
|-------------|-------|------|-------|-------------|
| 0-20% | very_low | 🔵 | Blue | Low memory usage |
| 20-70% | good | 🟢 | Green | Healthy usage |
| 70-85% | warning | 🟡 | Yellow | Elevated usage |
| 85-95% | critical | 🟠 | Orange | High usage |
| 95%+ | danger | 🔴 | Red | Critical usage |
| Unknown | unknown | ⚪ | White | Unable to determine |

**Note:** Warning text messages were removed - the colored indicator replaces them to prevent layout shifts.

### 4. Temperature

| Icon | Format | Example |
|------|--------|---------|
| 🌡️ | `🌡️ {temp}°C` | `🌡️ 65°C` |

GPU core temperature in Celsius.

### 5. Fan Speed Percentage

| Icon | Format | Example |
|------|--------|---------|
| 💨 | `💨 {percent}%` | `💨 45%` |

Fan speed as percentage of maximum.

### 6. Fan Speed RPM

| Icon | Format | Example |
|------|--------|---------|
| 🌀 | `🌀 {rpm} RPM` | `🌀 1200 RPM` |

Fan speed in revolutions per minute.

### 7. Power Draw

| Icon | Format | Example |
|------|--------|---------|
| ⚡ | `⚡ {current}/{max}W` | `⚡ 250/350W` |

Current power draw vs. maximum power limit in watts.

