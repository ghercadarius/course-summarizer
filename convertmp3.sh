#!/bin/bash

for f in *.mp4; do
    base="${f%.mp4}"
    ffmpeg -i "$f" -vn -acodec libmp3lame -q:a 2 "${base}.mp3"
done
