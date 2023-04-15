#!/bin/env bash

# Export all vars from the local systemd env.
# Ignore all comments and empty lines.

for file in ~/.config/environment.d/*.conf; do
    grep -hv "^#" "$file" |
    grep "." |
    while read -r line; do
        eval "export $line"
    done
done