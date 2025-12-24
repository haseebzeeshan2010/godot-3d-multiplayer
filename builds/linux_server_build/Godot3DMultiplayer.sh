#!/bin/sh
printf '\033c\033]0;%s\a' Godot3DMultiplayer
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Godot3DMultiplayer.x86_64" "$@"
