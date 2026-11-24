#!/bin/sh
dedup=$(mktemp)
awk '!x[$0]++' "$1" >"$dedup" && mv "$dedup" "$1"
