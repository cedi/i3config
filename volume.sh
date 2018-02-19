#!/bin/bash

echo "$(amixer sget Master | grep 'Front Left: Playback' | awk '{print $5}')"
#echo $((`pacmd dump | grep -P "^set-sink-volume $(pacmd dump | perl -a -n -e 'print $F[1] if /set-default-sink/')\s+" | perl -p -n -e 's/.+\s(.x.+)$/$1/'` / $((0x10000 / 16))))

#SINK=$( pactl list short sinks | sed -e 's,^\([0-9][0-9]*\)[^0-9].*,\1,' | head -n 1 )
#NOW=$( pactl list sinks | grep '^[[:space:]]Volume:' | head -n $(( $SINK + 1 )) | tail -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,' )
#echo $NOW
