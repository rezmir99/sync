#!/bin/sh
WIN_HOME='D:'
printf '%s' "$1" | sed -e 's,\\,\/,g' -e "s,$WIN_HOME,$HOME,"
