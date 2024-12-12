#!/usr/bin/env bash
declare -i x y
declare -i player_x=3 player_y=3
declare -i goblin_x=1 goblin_y=1
declare -i gold=0

declare game_over
declare last_message=''
declare -a level_map=(
  '########'
  '#......#'
  '#......#'
  '#......#'
  '#......#'
  '########'
)

declare -a objects=(
  '$ 4 4:add_gold'
)

declare -a monsters=(goblin)

add_gold() {
  last_message="Picked up 5 gold"
  gold+=5
}

monster_at() {
  local -i x y
  local monster
  x="$1"
  y="$2"
  for monster in "${monsters[@]}"; do
    local -n mx=${monster}_x
    local -n my=${monster}_y
    if [[ mx -eq x && my -eq y ]]; then
      printf "%s" "$monster"
      return
    fi
  done
}

tile_at() {
  local -i x y
  local v
  local tile
  x="$1"
  y="$2"

  if [[ y -gt ${#level_map} || y -lt 0 ]]; then
    return 1
  fi

  if [[ x -gt ${#level_map[0]} || x -lt 0 ]]; then
    return 2
  fi

  tile=${level_map[y]}
  tile=${tile:x:1}
  printf "%s" "$tile"
}

move() {
  local -i dx dy
  local direction="$1"
  local entity="${2:-player}"
  local -n entity_x=${entity}_x
  local -n entity_y=${entity}_y
  case "$1" in
  up)
    dx=0
    dy=-1
    ;;
  down)
    dx=0
    dy=1
    ;;
  left)
    dx=-1
    dy=0
    ;;
  right)
    dx=1
    dy=0
    ;;
  esac
  if [ $(tile_at entity_x+dx entity_y+dy) = \# ]; then
    if [ "$entity" = player ]; then
      last_message="it's blocked"
    fi
  else
    entity_x=entity_x+dx
    entity_y=entity_y+dy
  fi
}

update_state() {
  move_creatures
  process_events
  redraw
}

move_creatures() {
  move right goblin
}
process_events() {
  local object handler
  local ox oy
  local -i i=0
  for object in "${objects[@]}"; do
    read -d ':' symbol ox oy <<<"$object"
    handler=${object##*:}
    if [[ ox -eq player_x && oy -eq player_y ]]; then
      $handler
      objects[$i]=". $ox $oy:true"
    fi
  done

  if [ -n "$(monster_at player_x player_y)" ]; then
    last_message='You die'
    game_over='true'
  fi
}

init_state() {
  get_cursor_position
  hide_cursor
  player_x=3
  player_y=3
  redraw
}

redraw() {
  erase_display
  draw_title
  draw_map
  draw_objects
  if [ "$game_over" = true ]; then
    erase_display 2
    insert_at 0 4 "  GAME OVER  "
    for key in h j k l; do
      bind -x $(printf '"%s":exit' "$key")
    done
  else
    insert_at goblin_x+1 goblin_y+2 'g'
    insert_at player_x+1 player_y+2 '@'
  fi
}

draw_title() {
  local xpos=$(printf '% 3d' $player_x)
  local ypos=$(printf '% 3d' $player_y)
  local left=$(tile_at player_x-1 player_y)
  local right=$(tile_at player_x+1 player_y)
  local up=$(tile_at player_x player_y-1)
  local down=$(tile_at player_x player_y+1)
  insert_at 0 0 "x=$xpos y=$ypos \$:$gold | l:$left r:$right u:$up d:$down | $last_message"
  last_message=''
}

draw_map() {
  local line
  local -i offset=2
  for line in "${level_map[@]}"; do
    insert_at 0 offset "$line"
    offset=offset+1
  done
}

draw_objects() {
  local object
  local x y
  for object in "${objects[@]}"; do
    read -d ':' symbol x y <<<"$object"
    insert_at "$((x + 1))" "$((y + 2))" "$symbol"
  done
}

insert_at() {
  local -i x y
  local c
  x="$1"
  y="$2"
  c="$3"
  set_cursor_position $x $y
  printf '%s' "$c"
  set_cursor_position $((x - 1)) $y
}

erase_display() {
  local -i param=${1:-1}
  printf '\033[%dJ' "$param"
}

hide_cursor() {
  tput civis
}

get_cursor_position() {
  printf "\033[6n"
  read -s -d\[ _
  read -s -d R y_and_x
  x=${y_and_x#*;}
  y=${y_and_x%;*}
}

set_cursor_position() {
  local -i x y
  x="$1"
  y="$2"
  printf "\033[%d;%dH" "$y" "$x"
}

on_press_h() {
  move left player
  update_state
}

on_press_l() {
  move right player
  update_state
}

on_press_j() {
  move down player
  update_state
}

on_press_k() {
  move up player
  update_state
}

bind_movements() {
  bind -x '"h":on_press_h'
  bind -x '"l":on_press_l'
  bind -x '"j":on_press_j'
  bind -x '"k":on_press_k'
  bind -x '"q":exit'
}

trap reset EXIT ERR
if [[ "$0" == "-bash" ]]; then
  printf "Loaded.\n" >&2
else
  PS1=''
  exec 3>game.log
  BASH_XTRACEFD=3
  set -x
  enable_alternate_screen_buffer
  init_state
  bind_movements
fi
