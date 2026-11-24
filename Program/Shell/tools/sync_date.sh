#!/bin/sh
echo '[ROOT] Updating clock (sudo hwclock --hctosys)'
sudo hwclock -s
sudo ntpdate time.windows.com
