#!/usr/bin/env bash

set -k

log() {
  local to=${to:=/dev/stderr}
  printf "%s: %s\n" "$level" "$message" >"$to"
}

log level=info message="Hello" 
