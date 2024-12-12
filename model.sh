#!/usr/bin/env bash
##
# This file demonstrates how to use Bash to easily define custom domain-specific languages.
#
# The idea is the following:
#
# * your DSL code is bash, but resides in a separate script file
# * this file serves as the "interpreter", providing implementation of the DSL
#
#
# Functions with underscores (like `fatal_error`) are meant to be used by the interpreter.
#
# Functions with dashes in them (like `add-model`) are to be used in the DSL.
##

valid-types() {
  local type
  local -a new_types
  mapfile -t new_types
  for type in "${new_types[@]}"; do
    if ! _type_is_valid "$type"; then
      valid_types+=("$type")
    fi
  done
}

_type_is_valid() {
  local t
  for t in "${valid_types[@]}"; do
    if [ "$t" = "$1" ]; then
      return 0
    fi
  done
  return 1
}

model() {
  local model_name="$1"
  current_model="$model_name"
  declare -gn current_model_fields="${current_model}_fields"
  models+=("$current_model")
  valid_types+=("$current_model")
}

field() {
  local name="$1"
  local type="$2"
  if ! _type_is_valid "$type"; then
    fatal_error "$current_model: invalid type for $name: $type"
  fi
  declare -g -A "${current_model}_fields"
  current_model_fields["$name"]="$type"
}

emit() {
  for current_model in "${models[@]}"; do
    declare -gn current_model_fields="${current_model}_fields"
    emit_model
    emit_typebox_schema
  done
}

fatal_error() {
  printf "error: $1\n" "${*:2}" >&2
  exit 1
}

with() {
  local macro_name="$1"
  case "$macro_name" in
  timestamps)
    field createdAt Date
    field updatedAt Date
    ;;
  *)
    fatal_error "$current_model: unknown macro %q" "$macro_name"
    ;;
  esac
}

emit_model() {
  printf "export interface %s {\n" "$current_model"
  for current_field in "${!current_model_fields[@]}"; do
    printf "  %s: %s\n" "${current_field}" "${current_model_fields[$current_field]}"
  done
  printf "}\n"
}

emit_typebox_schema() {
  printf "export const %sModel = Type.Object({\n" "${current_model,}"
  for current_field in "${!current_model_fields[@]}"; do
    printf "  %s: Type.%s(),\n" "${current_field}" "${current_model_fields[$current_field]^}"
  done
  printf "})\n"
}

compile() {
  local oldpath="$PATH"
  PATH=/dev/null
  source "$1"
  PATH="$oldpath"

  emit
}

main() {
  local current_model current_field
  local -a valid_types
  local -a models=()

  if [ "$0" = -bash ]; then
    export PS1='shjs> '
    printf "DSL active\n"
  elif [[ -z "$1" && $0 != bash ]]; then
    export PS1='shjs> '
    bash --init-file "$0" -i
  elif [[ -n "$1" ]]; then
    local -f command_not_found_handle >/dev/null 2>/dev/null
    command_not_found_handle() {
      fatal_error "$1 is not allowed here"
      return 127
    }

    trap 'exit 2' ERR
    compile "$1"
  fi
}
main "$@"
