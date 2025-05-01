#!/bin/bash
set -euo pipefail

# Join all arguments preserving spaces and special characters
REMOTE_CMD="$*"
if [ $# -eq 0 ]; then
    echo "Usage: $0 command"
    exit 1
fi

# shellcheck disable=SC2029
ssh jetson "bash -lc 'sudo -S pwd <~/.mypassword && cd ~/jetson_nano_kvm && source .venv/bin/activate && eval \"$REMOTE_CMD\"'"
