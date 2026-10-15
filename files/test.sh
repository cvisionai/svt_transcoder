#!/bin/bash
# Smoke test for the encoder image. Generates its own sources and exercises the encoder options
# tator-py's transcodes use. Exits non-zero on the first failure.
set -euo pipefail

WORK=${1:-/scratch}
mkdir -p "$WORK"
cd "$WORK"
export SVT_LOG=2

fail() { echo "FAIL: $*" >&2; exit 1; }

# Runs ffmpeg at -loglevel warning and fails if an option was ignored or a param didn't parse.
run_ffmpeg() {
    local log
    log=$(mktemp)
    if ! ffmpeg -hide_banner -y -loglevel warning "$@" 2>"$log"; then
        cat "$log" >&2
        fail "ffmpeg $*"
    fi
    if grep -E "has not been used|Error parsing option" "$log"; then
        fail "ignored encoder options"
    fi
    rm -f "$log"
}

probe() { ffprobe -v error -select_streams v -show_entries "$2" -of csv=p=0 "$1"; }

expect() {
    [ "$2" = "$3" ] || fail "$1: expected '$3', got '$2'"
    echo "ok: $1 = $3"
}

FRAG="frag_keyframe+empty_moov+default_base_moof"
SRC="testsrc2=s=1280x720:r=30"

echo "== Generate sources"
run_ffmpeg -f lavfi -i "$SRC" -t 4 -c:v libx264 -pix_fmt yuv420p src8.mp4
run_ffmpeg -f lavfi -i "$SRC" -t 2 -c:v libx265 -pix_fmt yuv420p10le \
    -x265-params log-level=error src10.mp4
run_ffmpeg -display_rotation 90 -i src8.mp4 -c copy rotated.mp4

echo "== Multi-output streaming transcode (AV1 + H.264)"
run_ffmpeg -i src8.mp4 -filter_complex_threads 1 -filter_complex \
    "[0:v:0]bwdif=mode=send_frame:deint=interlaced,setsar=1,fps=30[v];[v]split=2[a][b];[a]scale=-2:720,pad=ceil(iw/2)*2:ceil(ih/2)*2[o0];[b]scale=-2:360,pad=ceil(iw/2)*2:ceil(ih/2)*2[o1]" \
    -map "[o0]" -an -g 25 -max_muxing_queue_size 9999 -movflags "$FRAG" \
        -c:v libsvtav1 -preset 8 -crf 34 -svtav1-params irefresh-type=2:fast-decode=1 \
        -pix_fmt yuv420p -write_tmcd 0 av1_720.mp4 \
    -map "[o1]" -an -g 25 -max_muxing_queue_size 9999 -movflags "$FRAG" \
        -c:v libx264 -preset fast -tune fastdecode -crf 23 -pix_fmt yuv420p -write_tmcd 0 h264_360.mp4
expect "av1_720 codec" "$(probe av1_720.mp4 stream=codec_name,pix_fmt)" "av1,yuv420p"
expect "h264_360 codec" "$(probe h264_360.mp4 stream=codec_name,pix_fmt)" "h264,yuv420p"
keys=$(ffprobe -v error -select_streams v -show_entries packet=flags -of csv=p=0 av1_720.mp4 \
    | grep -n '^K' | cut -d: -f1 | head -4 | tr '\n' ' ')
expect "av1_720 key frames (1-based packet index)" "$keys" "1 26 51 76 "

echo "== 10-bit source to 10-bit AV1"
run_ffmpeg -i src10.mp4 -an -g 25 -movflags "$FRAG" -c:v libsvtav1 -preset 8 -crf 34 \
    -svtav1-params irefresh-type=2 -pix_fmt yuv420p10le av1_10bit.mp4
expect "av1_10bit pix_fmt" "$(probe av1_10bit.mp4 stream=pix_fmt)" "yuv420p10le"

echo "== Rotated source is autorotated"
run_ffmpeg -i rotated.mp4 -an -g 25 -movflags "$FRAG" -vf scale=-2:360 -c:v libsvtav1 -preset 8 \
    -crf 34 -svtav1-params irefresh-type=2 -pix_fmt yuv420p rotated_360.mp4
expect "rotated_360 size" "$(probe rotated_360.mp4 stream=width,height)" "202,360"
expect "rotated_360 display matrix" \
    "$(ffprobe -v error -select_streams v -show_entries stream_side_data=rotation -of csv=p=0 rotated_360.mp4)" ""

echo "== Archival HEVC"
run_ffmpeg -i src8.mp4 -vf bwdif=mode=send_frame:deint=interlaced -c:v libx265 -preset fast \
    -crf 23 -pix_fmt yuv420p -x265-params log-level=error -tag:v hvc1 archival.mp4
expect "archival codec" "$(probe archival.mp4 stream=codec_name,codec_tag_string)" "hevc,hvc1"

echo "== Decode AV1 with dav1d"
run_ffmpeg -c:v libdav1d -i av1_10bit.mp4 -f null -

echo "== Bento4 tools"
mp4dump --format json av1_720.mp4 | grep -q '"moof"' || fail "mp4dump found no moof boxes"
mp4info av1_720.mp4 >/dev/null || fail "mp4info"
echo "ok: mp4dump and mp4info"

echo "All checks passed. Outputs are in $WORK"
