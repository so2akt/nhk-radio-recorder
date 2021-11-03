#!/bin/bash

DATE=`date '+%Y%m%d_%H%M'`
TMPDIR="/tmp"

if [ $# -eq 4 ]; then
  CHANNEL="$1"
  DURATION=`expr $2 \* 60`
  OUTDIRLOCAL="$3"
  OUTDIR="$4"
else
  echo "usage : $0 channel_name(r1|r2|fm) duration(minuites)"
  exit 1
fi

case $CHANNEL in
    r1) PLAYPATH='https://nhkradioakr1-i.akamaihd.net/hls/live/511633/1-r1/1-r1-01.m3u8' ;;
    r2) PLAYPATH='https://nhkradioakr2-i.akamaihd.net/hls/live/511929/1-r2/1-r2-01.m3u8' ;;
    fm) PLAYPATH='https://nhkradioakfm-i.akamaihd.net/hls/live/512290/1-fm/1-fm-01.m3u8' ;;
    *) exit 1 ;;
esac

avconv -i "${PLAYPATH}" \
       -t "${DURATION}" \
       -y \
       -c copy "${TMPDIR}/${CHANNEL}_${DATE}.m4a"

mv "${TMPDIR}/${CHANNEL}_${DATE}.m4a" "${OUTDIRLOCAL}/"
mv "${OUTDIRLOCAL}/${CHANNEL}_${DATE}.m4a" "${OUTDIR}/"
