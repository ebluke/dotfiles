#!/usr/bin/env sh

# Terminate already running bar instances
killall -q polybar

# Wait until the proccesses have been shut down
while pgrep -x polybar >/dev/null; do sleep 1; done

# Launch polybar HDMI
polybar example &
# Launch polybar DP
polybar example2 &
