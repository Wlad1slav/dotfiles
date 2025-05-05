#!/usr/bin/env bash

init() {
  local mon_id pics_dir
  declare -g mon_name screenshot_dir

  # ID й ім’я активного монітора
  mon_id=$(hyprctl activewindow -j | jq -r '.monitor')
  mon_name=$(hyprctl monitors -j \
    | jq -r --arg id "$mon_id" '.[] | select(.id == ($id|tonumber)) | .name'
  )

  # Спроба 1: прочитати XDG-папку для картинок з user-dirs.dirs
  if [ -r "$HOME/.config/user-dirs.dirs" ]; then
    pics_dir=$(grep '^XDG_PICTURES_DIR' "$HOME/.config/user-dirs.dirs" \
      | cut -d= -f2 | tr -d '"' \
      | sed "s|\$HOME|$HOME|")
  fi

  # Спроба 2: xdg-user-dir (якщо нічого не вийшло)
  if [ -z "$pics_dir" ] && command -v xdg-user-dir >/dev/null 2>&1; then
    pics_dir=$(xdg-user-dir PICTURES)
  fi

  # Фолбеки: ~/Pictures, потім ~/Картинки
  if [ -z "$pics_dir" ] || [ ! -d "$pics_dir" ]; then
    if [ -d "$HOME/Pictures" ]; then
      pics_dir="$HOME/Pictures"
    else
      pics_dir="$HOME/Картинки"
    fi
  fi

  # Створює підпапку для скріншотів
  screenshot_dir="$pics_dir/Screenshots"
  mkdir -p "$screenshot_dir"
}

_copy_to_clipboard() {
  local file="$1"

  if command -v wl-copy >/dev/null 2>&1; then
    wl-copy < "$file"
  elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard -t image/png -i "$file"
  else
    return 1
  fi

}

monitor() {
  local filename
  filename="$(date +%F_%H-%M-%S)_${mon_name}.png"
  grim -o "$mon_name" "$screenshot_dir/$filename"

  _copy_to_clipboard "$screenshot_dir/$filename"
  exit 0
}

area() {
  local filename
  filename="$(date +%F_%H-%M-%S).png"
  grim -g "$(slurp)" "$screenshot_dir/$filename"

  _copy_to_clipboard "$screenshot_dir/$filename"
  exit 0
}

full() {
  local filename
  filename="$(date +%F_%H-%M-%S)-full.png"
  grim "$screenshot_dir/$filename"
  
  _copy_to_clipboard "$screenshot_dir/$filename"

  exit 0
}

init
