# Docker image for PSn00bSDK development

[![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/jaczekanski/psn00bsdk.svg)](https://cloud.docker.com/repository/docker/jaczekanski/psn00bsdk/builds)
[![Docker Pulls](https://img.shields.io/docker/pulls/jaczekanski/psn00bsdk.svg)](https://cloud.docker.com/u/root670/repository/docker/jaczekanski/psn00bsdk)

SDK version: [72b7d4](https://github.com/Lameguy64/PSn00bSDK/tree/72b7d4168afc63db572539d41623c3ab0f09ddf4)

## Usage

```bash
docker run -it -v $(pwd):/build jaczekanski/psn00bsdk make
```

Current directory will be shared with Docker container containing MIPS GCC and prebuilt PSn00bSDK.

## Author

Jakub Czekański

Based on [docker-psxsdk](https://github.com/root670/docker-psxsdk) by [root670](https://github.com/root670).
