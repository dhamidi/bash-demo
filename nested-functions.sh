#!/usr/bin/env bash

main() {
  tell-me-more-about-f
  define-f
  f
  tell-me-more-about-f
  export-f
  call-f-in-subshell
}

define-f() {
  f() {
    printf 'function f reporting for duty'
    printf ' (level=%d)\n' "$SHLVL"
  }
}

export-f() {
  declare -fx f
}

call-f-in-subshell() {
  bash -c f
}

tell-me-more-about-f() {
  if f-defined?; then
    echo f is defined
  else
    echo f is not defined
  fi
}

f-defined?() {
  declare -pf f >/dev/null 2>/dev/null
}

main
