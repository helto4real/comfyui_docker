# The ComfyUI docker image with Sage integration

This repository contains a Dockerfile to build a ComfyUI image with Sage integration for ComfyUI.

# Build the image
Make sure you have the docker runtime as default. And installed nvidia docker toolkit.

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

If you need to install all the optional dependencies. In custom nodes folder do:

```bash
find . -name "requirements.txt" -exec pip install -r {} \;
```
```

## if I screw up
```
docker cp <containerId>:/app/ComfyUI/ComfyUI.py ./ComfyUI.py
```
