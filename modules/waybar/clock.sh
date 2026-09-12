#!/usr/bin/env bash
# Waybar clock module. Renders either the time or the full date depending on the
# mode written by the AGS control center (~/.cache/waybar-clock-mode), so the bar
# clock flips to "date view" exactly while the sidebar is open — no matter whether
# it was opened by clicking the clock or by the Super+C keybind. AGS pokes this
# module with SIGRTMIN+8 on every open/close for an instant refresh.
set -eu

cache="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-clock-mode"
mode=$(cat "$cache" 2>/dev/null || echo time)

if [ "$mode" = date ]; then
  text="  $(date '+%A, %d %B %Y')"
else
  text="  $(date '+%H:%M')"
fi

# Current month as the tooltip, with newlines escaped for JSON.
tooltip=$(cal | sed 's/$/\\n/' | tr -d '\n')

printf '{"text": "%s", "tooltip": "%s"}\n' "$text" "$tooltip"
