#!/bin/bash

# ===== settings =====
DATE=$(date '+%Y%m%d_%H%M')
XML_URL="https://www.nhk.or.jp/radio/config/config_web.xml"

# ===== area setting =====
AREA="tokyo"   # tokyo, if other area, please refer to https://www.nhk.or.jp/radio/config/config_web.xml

# ===== argument check =====
if [ $# -ne 4 ]; then
  echo "usage: $0 channel(r1|fm) duration(min) localdir remotedir"
  exit 1
fi

CHANNEL="$1"
DURATION=$(($2 * 60))
OUTDIRLOCAL="$3"
OUTDIR="$4"

# ===== get XML =====
XML=$(curl -s "$XML_URL")

extract_url() {
  echo "$1" | sed -E 's/.*CDATA\[([^]]+)\].*/\1/'
}

# ===== extract area block =====
AREA_BLOCK=$(echo "$XML" | tr -d '\n' | sed 's#</area>#</area>\n#g' | grep "<area>${AREA}</area>")

if [ -z "$AREA_BLOCK" ]; then
  echo "failed to find area block (area=${AREA})"
  exit 1
fi

# ===== select channel =====
case "$CHANNEL" in
  r1)
    LINE=$(echo "$AREA_BLOCK" | grep 'r1hls' | head -n1)
    ;;
# r2 is stopped since 2026-03-30
#  r2)
#    LINE=$(echo "$AREA_BLOCK" | grep 'r2hls' | head -n1)
#    ;;
  fm)
    LINE=$(echo "$AREA_BLOCK" | grep 'fmhls' | head -n1)
    ;;
  *)
    echo "invalid channel"
    exit 1
    ;;
esac

PLAYPATH=$(extract_url "$LINE")

if [ -z "$PLAYPATH" ]; then
  echo "failed to get m3u8 (area=${AREA})"
  exit 1
fi

echo "AREA: $AREA"
echo "M3U8: $PLAYPATH"

# ===== output =====
OUTFILE="${CHANNEL}_${DATE}.m4a"
mkdir -p "$OUTDIRLOCAL"

# ===== recording =====
ffmpeg -loglevel error \
  -headers "User-Agent: Mozilla/5.0" \
  -i "$PLAYPATH" \
  -t "$DURATION" \
  -vn \
  -acodec copy \
  -y \
  "$OUTDIRLOCAL/$OUTFILE"

# ===== confirm recording =====
if [ ! -f "$OUTDIRLOCAL/$OUTFILE" ]; then
  echo "record failed"
  exit 1
fi

# ===== move to remote directory =====
cp "$OUTDIRLOCAL/$OUTFILE" "$OUTDIR/" && rm "$OUTDIRLOCAL/$OUTFILE"

echo "done: $OUTFILE"
