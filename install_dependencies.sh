#!/bin/bash
#
# Preparations for automated test
#
# Copyright (C) Henrik Langer <henni19790@googlemail.com>
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

apt-get update
apt-get install -y stress epstool pstoedit octave-common octave octave-signal octave-control octave-audio sox

# Get and compile ALSA test tools (repo sources have to be enabled)
apt-get source libasound2
rm alsa-lib*
patch alsa-lib*/test/latency.c -i patches/latency.patch -o patched-latency.c
mv patched-latency.c alsa-lib*/test/latency.c
patch alsa-lib*/test/pcm.c -i patches/pcm.patch -o patched-pcm.c
mv patched-pcm.c alsa-lib*/test/pcm.c
cd alsa-lib*/
./configure
make
cd test/
make latency
make pcm
cd ../../
