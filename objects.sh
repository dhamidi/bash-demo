#!/usr/bin/env bash

declare -a classes=()
declare -A instances=()

defclass() {
  local name="$1"
  local -a fields=("${@:2}")

  register-class "$name"
  for field in "${fields[@]}"; do
    add-field-to-class "$name" "$field"
  done
}

register-class() {
  local name="$1"
  local class
  for class in "${classes[@]}"; do
    if [ "$class" == "$name" ]; then
      return
    fi
  done

  classes+=("$name")
  declare -ga "${name}_fields"
}

add-field-to-class() {
  local class="$1"
  local field="$2"
  local -n class_fields=${class}_fields
  class_fields+=("$field")
}

new() {
  local class="$1"
  local instance_name="$2"
  local -a fields=("${@:3}")
  local -i id=${instances[$class]}+1
  instances[$class]+=1
  local -n instance_var=${instance_name}
  instance_var=$(printf "call-method %s %i " "$class" "$id")

  local -n class_fields=${class}_fields
  local -i current_field=0
  for field in "${class_fields[@]}"; do
    set-instance-variable "${fields[current_field]}"
    current_field+=1
  done
}

set-instance-variable() {
  local -n ivar=${class}_${id}_${field}
  ivar="$1"
}

get-instance-variable() {
  local -n ivar=${class}_${id}_${field}
  printf "%s" "$ivar"
}

call-method() {
  local class="$1"
  local -i id="$2"
  local method="$3"
  local -a args=("${@:4}")
  local this="call-method ${class} ${id} "
  $class::$method "${args[@]}"
}

this() {
  local field="$1"
  if [ "$field" = "class" ]; then
    printf %s "$class"
  fi
  get-instance-variable
}
