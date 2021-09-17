# Pulling image

docker pull cvisionai/svt_encoder

# Building image

docker build -t cvisionai/svt_encoder .

# Running image:

docker run --rm -ti cvisionai/svt_encoder

## Testing image
$docker> ./test.sh

## Version Notes:

*-------------*---------------------------------*
| Docker/tag  | Description                     |
*-------------*---------------------------------*
| v0.0.3      | Stable release                  |
*-------------*---------------------------------*
| v0.0.4      | Added https support             |
*-------------*---------------------------------*
| v0.0.5      | Added libaom                    |
*-------------*---------------------------------*
| v0.0.6      | Fixed libssl runtime issue      |
*-------------*---------------------------------*

