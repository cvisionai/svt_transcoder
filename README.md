# Pulling image

```
docker pull cvisionai/svt_encoder
```

# Building image

```
docker build --pull -t cvisionai/svt_encoder .
```

Add the `--no-cache` flag to force a clean image build.

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
| v0.1.0      | Pins versions of ffmpeg and all plugins
