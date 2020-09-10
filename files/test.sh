#!/bin/bash

apt-get update && apt-get install -y wget
mkdir /scratch
cd /scratch
wget http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4
ffmpeg -i ForBiggerBlazes.mp4 -c:v libsvt_hevc hevc.mp4
ffmpeg -i ForBiggerBlazes.mp4 -c:v libsvtav1 av1.mp4

echo "Video files are in '/scratch'"
