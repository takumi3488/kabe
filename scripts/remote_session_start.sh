#!/bin/bash

# Run only in remote environment
if [ "$CLAUDE_CODE_REMOTE" != "true" ]; then
  exit 0
fi

# Install zsh if not available
if ! command -v zsh >/dev/null 2>&1; then
  if ! (sudo apt-get update && sudo apt-get install -y zsh); then
    echo "Failed to install zsh" >&2
    exit 1
  fi
fi
exit 0
