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
| 0.0.4       | Stable release                  |
*-------------*---------------------------------*
| 0.0.5       | Added libaom                    |
*-------------*---------------------------------*


