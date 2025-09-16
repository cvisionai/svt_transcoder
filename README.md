# Pulling image

```
docker pull cvisionai/svt_encoder
```

# Building image

## Single Architecture (x86_64 only)
```
docker build --pull -t cvisionai/svt_encoder .
```

Add the `--no-cache` flag to force a clean image build.

## Multi-Architecture (x86_64 and ARM64)

First, set up Docker buildx for multiarch builds:
```
./setup-buildx.sh
```
```
docker buildx build --platform linux/amd64,linux/arm64 -t cvisionai/svt_encoder --push .
```
# Running image:

```
docker run --rm -ti --privileged cvisionai/svt_encoder
```

## Testing image

```
$docker> ./test.sh
```

## Version Notes:


| Docker/tag  | Description
------------- |-------------------------------
| v0.0.3      | Stable release
| v0.0.4      | Added https support
| v0.0.5      | Added libaom
| v0.0.6      | Fixed libssl runtime issue
| v0.0.7      | Add VP9 support
| v0.0.8      | Update path to libsvtav1
| v0.0.9      | Lock ffmpeg to n5.1.2, add Bento4 exes
| v0.0.10     | Pins versions of ffmpeg and all plugins, updates ffmpeg to n6.0 and libsvt to 1.5.0
| v0.0.11     | Updates base image to Ubuntu 22.04
| v0.0.12     | Update ffmpeg to n6.1, Update libsvt to 1.6.0, Drop libsvtvp9
| v0.0.13     | Update ffmpeg to n7.0, Update libsvt to 2.1.0
| v0.0.14     | Add libdav1d for faster AV1 decodes
| v0.0.15     | Upgrade svtav1 to 2.2.1 and ffmpeg to 7.1
| v0.0.16     | Add multiarch support (x86_64 and ARM64), upgrade SVT-AV1 to 3.1.2, upgrade FFmpeg to 8.0, remove deprecated SVT-HEVC
