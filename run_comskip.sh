#!/bin/bash

filepath="$@"

# example file - '/data/media/dvr/Family Guy/Season 22/Family Guy S22E05 Old World Harm.ts'
stripped=`echo "$filepath" | cut -c 12-`
RELATIVE_PATH="${filepath#/recordings/}"

curl -X POST \
  http://comcutter:9090/comskip \
    -H 'Content-Type: application/json' \
    -d "{\"api\": \"8c7d3496-f743-4303-a9d8-84e10e1fcc90\", \"file\": \"${RELATIVE_PATH}\"}"

