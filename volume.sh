#!/bin/bash

echo $((`pacmd dump | grep -P "^set-sink-volume $(pacmd dump | perl -a -n -e 'print $F[1] if /set-default-sink/')\s+" | perl -p -n -e 's/.+\s(.x.+)$/$1/'` / $((0x10000 / 16))))
