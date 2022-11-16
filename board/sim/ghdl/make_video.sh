#!/usr/bin/env bash

parallel ./upscale_frame.sh {} ::: "$1"/frame_*.bmp
exec ffmpeg -r 59.96 -pattern_type glob -i "$1"/'big_*.bmp' -i "$1"/audio.au -c:v libx264rgb -c:a aac -ar 48000 -ac 1 -shortest "$2"
