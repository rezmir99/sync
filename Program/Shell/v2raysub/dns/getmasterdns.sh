#!/bin/bash
clipboard -v | grep 'Accepted' | grep -o -E '([0-9]{1,3}\.){3}[0-9]{1,3}'| sort -u -V | clipboard -c
