#!/usr/bin/env zsh
set -eu

repo_dir="${0:a:h:h}"
[[ -x "$repo_dir/kabe" ]] || {
  print -u2 -- 'FAIL: kabe is not executable'
  exit 1
}
[[ -x "$repo_dir/installer.sh" ]] || {
  print -u2 -- 'FAIL: installer.sh is not executable'
  exit 1
}

temp_dir="$(mktemp -d)"
trap 'rm -rf -- "$temp_dir"' EXIT

home_dir="$temp_dir/home"
wallpaper_dir="$home_dir/.kabe"
bin_dir="$temp_dir/bin"
macos_wp_call_file="$temp_dir/macos-wp-image"
desktoppr_call_file="$temp_dir/desktoppr-image"
install_dir="$temp_dir/install"
macos_only_bin="$temp_dir/macos-only-bin"

mkdir -p -- "$wallpaper_dir" "$bin_dir" "$macos_only_bin"
touch "$wallpaper_dir/001.jpg" "$wallpaper_dir/002.png"

cat > "$bin_dir/macos-wp" <<'MACOS_WP'
#!/usr/bin/env zsh
set -eu

[[ $# == 2 && "$1" == set ]] || {
  print -u2 -- "unexpected macos-wp invocation: $*"
  exit 1
}
if [[ "${KABE_MACOS_WP_FAIL:-}" == 1 ]]; then
  exit 23
fi

print -r -- "$2" > "$KABE_MACOS_WP_IMAGE"
MACOS_WP
chmod +x "$bin_dir/macos-wp"
ln -s "$bin_dir/macos-wp" "$macos_only_bin/macos-wp"

cat > "$bin_dir/desktoppr" <<'DESKTOPPR'
#!/usr/bin/env zsh
set -eu

[[ $# == 1 ]] || {
  print -u2 -- "unexpected desktoppr invocation: $*"
  exit 1
}
if [[ "${KABE_DESKTOPPR_FAIL:-}" == 1 ]]; then
  exit 29
fi

print -r -- "$1" > "$KABE_DESKTOPPR_IMAGE"
DESKTOPPR
chmod +x "$bin_dir/desktoppr"


first_image="$wallpaper_dir/001.jpg"
second_image="$wallpaper_dir/002.png"

output="$(env HOME="$home_dir" PATH="$bin_dir:$PATH" KABE_DESKTOPPR_IMAGE="$desktoppr_call_file" KABE_MACOS_WP_IMAGE="$macos_wp_call_file" "$repo_dir/kabe")"
[[ "$output" == 'Wallpaper changed on all Spaces: none -> 001.jpg' ]] || {
  print -u2 -- "FAIL: unexpected first-run output: $output"
  exit 1
}
[[ "$(<"$macos_wp_call_file")" == "$first_image" ]] || {
  print -u2 -- 'FAIL: macos-wp did not receive the first image'
  exit 1
}
[[ "$(<"$desktoppr_call_file")" == "$first_image" ]] || {
  print -u2 -- 'FAIL: desktoppr did not receive the first image'
  exit 1
}
[[ "$(<"$wallpaper_dir/.last-wallpaper")" == "$first_image" ]] || {
  print -u2 -- 'FAIL: kabe did not persist the selected image'
  exit 1
}

output="$(env HOME="$home_dir" PATH="$bin_dir:$PATH" KABE_DESKTOPPR_IMAGE="$desktoppr_call_file" KABE_MACOS_WP_IMAGE="$macos_wp_call_file" "$repo_dir/kabe")"
[[ "$output" == 'Wallpaper changed on all Spaces: 001.jpg -> 002.png' ]] || {
  print -u2 -- "FAIL: unexpected rotation output: $output"
  exit 1
}
[[ "$(<"$macos_wp_call_file")" == "$second_image" ]] || {
  print -u2 -- 'FAIL: macos-wp did not receive the next image'
  exit 1
}
[[ "$(<"$desktoppr_call_file")" == "$second_image" ]] || {
  print -u2 -- 'FAIL: desktoppr did not receive the next image'
  exit 1
}
if output="$(env HOME="$home_dir" PATH="$bin_dir:$PATH" KABE_DESKTOPPR_IMAGE="$desktoppr_call_file" KABE_MACOS_WP_FAIL=1 KABE_MACOS_WP_IMAGE="$macos_wp_call_file" "$repo_dir/kabe" 2>&1)"; then
  print -u2 -- 'FAIL: kabe succeeded after macos-wp failed'
  exit 1
fi
[[ "$(<"$wallpaper_dir/.last-wallpaper")" == "$second_image" ]] || {
  print -u2 -- 'FAIL: kabe advanced its state after macos-wp failed'
  exit 1
}
if output="$(env HOME="$home_dir" PATH="$bin_dir:$PATH" KABE_DESKTOPPR_FAIL=1 KABE_DESKTOPPR_IMAGE="$desktoppr_call_file" KABE_MACOS_WP_IMAGE="$macos_wp_call_file" "$repo_dir/kabe" 2>&1)"; then
  print -u2 -- 'FAIL: kabe succeeded after desktoppr failed'
  exit 1
fi
[[ "$(<"$wallpaper_dir/.last-wallpaper")" == "$second_image" ]] || {
  print -u2 -- 'FAIL: kabe advanced its state after desktoppr failed'
  exit 1
}



empty_home="$temp_dir/empty-home"
mkdir -p -- "$empty_home"
if output="$(env HOME="$empty_home" PATH="$bin_dir:$PATH" KABE_DESKTOPPR_IMAGE="$desktoppr_call_file" KABE_MACOS_WP_IMAGE="$macos_wp_call_file" "$repo_dir/kabe" 2>&1)"; then
  print -u2 -- 'FAIL: kabe succeeded without a wallpaper directory'
  exit 1
fi
[[ "$output" == "kabe: wallpaper directory does not exist: $empty_home/.kabe" ]] || {
  print -u2 -- "FAIL: unexpected missing-directory error: $output"
  exit 1
}

output="$(env PATH="$bin_dir:$PATH" "$repo_dir/installer.sh" --prefix "$install_dir")"
[[ "$output" == "Installed kabe to $install_dir/kabe" ]] || {
  print -u2 -- "FAIL: unexpected installer output: $output"
  exit 1
}
[[ -x "$install_dir/kabe" ]] || {
  print -u2 -- 'FAIL: installer did not create an executable'
  exit 1
}
cmp -- "$repo_dir/kabe" "$install_dir/kabe"
remote_install_dir="$temp_dir/remote-install"
output="$(env PATH="$bin_dir:$PATH" KABE_SOURCE_URL="file://$repo_dir/kabe" sh -s -- --prefix "$remote_install_dir" < "$repo_dir/installer.sh")"
[[ "$output" == "Installed kabe to $remote_install_dir/kabe" ]] || {
  print -u2 -- "FAIL: unexpected piped-installer output: $output"
  exit 1
}
[[ -x "$remote_install_dir/kabe" ]] || {
  print -u2 -- 'FAIL: piped installer did not create an executable'
  exit 1
}
cmp -- "$repo_dir/kabe" "$remote_install_dir/kabe"


missing_install_dir="$temp_dir/missing-install"
if output="$(env PATH='/usr/bin:/bin' "$repo_dir/installer.sh" --prefix "$missing_install_dir" 2>&1)"; then
  print -u2 -- 'FAIL: installer succeeded without macos-wp'
  exit 1
fi
[[ "$output" == *'installer.sh: macos-wp is required'* && ! -e "$missing_install_dir/kabe" ]] || {
  print -u2 -- "FAIL: installer did not fail cleanly without macos-wp: $output"
  exit 1
}
missing_desktoppr_install_dir="$temp_dir/missing-desktoppr-install"
if output="$(env PATH="$macos_only_bin:/usr/bin:/bin" "$repo_dir/installer.sh" --prefix "$missing_desktoppr_install_dir" 2>&1)"; then
  print -u2 -- 'FAIL: installer succeeded without desktoppr'
  exit 1
fi
[[ "$output" == *'installer.sh: desktoppr is required'* && ! -e "$missing_desktoppr_install_dir/kabe" ]] || {
  print -u2 -- "FAIL: installer did not fail cleanly without desktoppr: $output"
  exit 1
}

print -- 'PASS: main_test.zsh'
