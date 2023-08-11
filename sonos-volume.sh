#!/bin/bash
#
# MIT License
# 
# Copyright (c) 2023 ArcSoundGuy
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# https://github.com/jishi/node-sonos-http-api
#
# Tue Jul 25 15:55:14 CDT 2023
set -x

if ! lockfile -1 -r 120 -l 200 -s 0 /tmp/sonos-volume.lock
then
        echo Could not acquire lock file, exiting... 2>&1
        exit 1
fi
trap "rm -f /tmp/sonos-volume.lock" EXIT

uri=http://localhost:5005
state=$(curl -s $uri/zones)

# join group if not a member and set speaker to arc volume if it differs
join_and_set()
{
        echo $state | jq '.[].coordinator.roomName' | grep -q "^\"$2\"\$" && \
                curl $(echo $uri/$1/add/$2 | sed 's| |%20|g')
        arc=".[].coordinator | select(.roomName==\"$1\").state"
        [ "$(echo $state | jq "$arc.mute")" = true ] && arc_volume=0 || \
        arc_volume=$(echo $state | jq "$arc.volume")
        speaker=".[].members | .[] | select(.roomName==\"$2\").state"
        [ "$(echo $state | jq "$speaker.volume")" != "$arc_volume" ] && \
                curl $(echo $uri/$2/volume/$arc_volume | sed 's| |%20|g')
}

join_and_set "Bedroom Arc" "Bedroom One 1"
join_and_set "Bedroom Arc" "Bedroom One 2"
join_and_set "Living Room Arc" "Living Room One 1"
join_and_set "Living Room Arc" "Living Room One 2"
join_and_set "Living Room Arc" "Living Room One 3"
join_and_set "Living Room Arc" "Living Room One 4"
