# Build the image
Make sure you have the docker runtime as default. And isntalled nvidia docker toolkit.

The file `/etc/docker/daemon.json`

```json
{
  default-runtime": "nvidia",
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "args": []
    }
  }
}
```


```bash
DOCKER_BUILDKIT=0 docker build -t comfyui-sage:local .
```

