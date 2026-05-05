#!/bin/bash

# ===== 設定 =====
DATE=$(date '+%Y%m%d_%H%M')
XML_URL="https://www.nhk.or.jp/radio/config/config_web.xml"

# ===== 引数チェック =====
if [ $# -ne 4 ]; then
  echo "usage: $0 channel(r1|r2|fm) duration(min) localdir remotedir"
  exit 1
fi

CHANNEL="$1"
DURATION=$(($2 * 60))
OUTDIRLOCAL="$3"
OUTDIR="$4"

# ===== XML取得 =====
XML=$(curl -s "$XML_URL")

extract_url() {
  echo "$1" | sed -E 's/.*CDATA\[([^]]+)\].*/\1/'
}

case "$CHANNEL" in
  r1)
    LINE=$(echo "$XML" | grep 'r1hls' | head -n1)
    ;;
  r2)
    LINE=$(echo "$XML" | grep 'r2hls' | head -n1)
    ;;
  fm)
    LINE=$(echo "$XML" | grep 'fmhls' | head -n1)
    ;;
  *)
    echo "invalid channel"
    exit 1
    ;;
esac

PLAYPATH=$(extract_url "$LINE")

if [ -z "$PLAYPATH" ]; then
  echo "failed to get m3u8"
  exit 1
fi

echo "M3U8: $PLAYPATH"

# ===== 出力 =====
OUTFILE="${CHANNEL}_${DATE}.m4a"
mkdir -p "$OUTDIRLOCAL"

# ===== 録音（これが本命） =====
ffmpeg -loglevel error \
  -headers "User-Agent: Mozilla/5.0" \
  -i "$PLAYPATH" \
  -t "$DURATION" \
  -vn \
  -acodec copy \
  -y \
  "$OUTDIRLOCAL/$OUTFILE"

# ===== 録音確認 =====
if [ ! -f "$OUTDIRLOCAL/$OUTFILE" ]; then
  echo "record failed"
  exit 1
fi

# ===== NAS転送 =====
cp "$OUTDIRLOCAL/$OUTFILE" "$OUTDIR/"

echo "done: $OUTFILE"
