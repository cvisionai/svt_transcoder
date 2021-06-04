#!/bin/bash

apt-get update && apt-get install -y wget
mkdir /scratch
cd /scratch
wget http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4
ffmpeg -i ForBiggerBlazes.mp4 -c:v libsvt_hevc -crf 23 svt_hevc.mp4
ffmpeg -i ForBiggerBlazes.mp4 -c:v libsvtav1 -crf 23 av1.mp4
ffmpeg -i ForBiggerBlazes.mp4 -c:v libx264 -crf 23 libx264.mp4
ffmpeg -i ForBiggerBlazes.mp4 -c:v libx265 -crf 23 libx265.mp4

wget -O av1_input.mp4 https://github.com/SPBTV/video_av1_samples/blob/master/spbtv_sample_bipbop_av1_960x540_25fps.mp4?raw=true

ffmpeg -i av1_input.mp4 -c:v libsvt_hevc -crf 23 2_svt_hevc.mp4
ffmpeg -i av1_input.mp4 -c:v libsvtav1 -crf 23 2_svt_av1.mp4
ffmpeg -i av1_input.mp4 -c:v libx264 -crf 23 2_libx264.mp4

echo "Video files are in '/scratch'"
du -hs /scratch/*.mp4
