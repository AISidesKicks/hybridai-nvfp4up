import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Nemotron 3 Super NVFP4 Guide',
  description: 'Deployment guide for NVIDIA Nemotron 3 Super in NVFP4 format',
  // Output directly to the docs directory (which is two levels up from web/)
  outDir: '../../docs',
  srcDir: 'src',
  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Inference Engines', link: '/inference-engines/' },
      { text: 'NeoClouds', link: '/neoclouds/' }
    ],
    sidebar: {
      '/inference-engines/': [
        { text: 'Overview', link: '/' },
        { text: 'vLLM', link: '/vllm' },
        { text: 'SGLang', link: '/sglang' },
        { text: 'TensorRT-LLM', link: '/tensorrt-llm' },
        { text: 'Triton', link: '/triton' }
      ],
      '/neoclouds/': [
        { text: 'Overview', link: '/' },
        { text: 'Modal', link: '/modal' },
        { text: 'SimplePod', link: '/simplepod' },
        { text: 'Verda', link: '/verda' },
        { text: 'Nebius', link: '/nebius' }
      ]
    },
    // Optional: customize the appearance
    socialLinks: [
      { icon: 'github', link: 'https://github.com/your-org/hybridai-nvfp4up' }
    ]
  },
  // Ignore dead links that occur due to the build process
  // These links will work correctly when deployed to GitHub Pages
  ignoreDeadLinks: true,
  lastUpdated: true,
  cleanUrls: true
})