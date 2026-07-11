#!/bin/sh
set -eu

readonly KABE_SOURCE_URL="${KABE_SOURCE_URL:-https://raw.githubusercontent.com/takumi3488/kabe/main/kabe}"

usage() {
  cat <<'USAGE'
Usage: installer.sh [--prefix DIRECTORY]

Install kabe into DIRECTORY/kabe. The default directory is /usr/local/bin.

Examples:
  ./installer.sh
  sudo ./installer.sh
  ./installer.sh --prefix "$HOME/.local/bin"
USAGE
}

fail() {
  printf '%s\n' "installer.sh: $*" >&2
  exit 1
}

resolve_source() {
  script_dir=''
  source_file=''


  case "$0" in
    */*)
      script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
      ;;
  esac

  if [ -n "$script_dir" ] && [ -f "$script_dir/kabe" ]; then
    source_file="$script_dir/kabe"
    return 0
  fi

  command -v curl >/dev/null 2>&1 || fail 'curl is required when installing from standard input'

  temporary_dir=$(mktemp -d "${TMPDIR:-/tmp}/kabe.XXXXXX") || fail 'could not create a temporary directory'
  trap 'rm -rf "$temporary_dir"' EXIT HUP INT TERM
  curl -fsSL "$KABE_SOURCE_URL" -o "$temporary_dir/kabe" ||
    fail "could not download kabe from $KABE_SOURCE_URL"
  [ -s "$temporary_dir/kabe" ] || fail 'downloaded kabe is empty'
  source_file="$temporary_dir/kabe"
}

main() {
  destination_dir='/usr/local/bin'

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --prefix)
        [ "$#" -ge 2 ] || fail '--prefix requires a directory'
        destination_dir="$2"
        shift 2
        ;;
      --help|-h)
        usage
        return 0
        ;;
      *)
        printf '%s\n' "installer.sh: unknown argument: $1" >&2
        usage >&2
        return 2
        ;;
    esac
  done

  command -v macos-wp >/dev/null 2>&1 ||
    fail 'macos-wp is required; install it first with: brew install marek-vybiral/macos-wp/macos-wp'
  command -v desktoppr >/dev/null 2>&1 ||
    fail 'desktoppr is required; install it first with: brew install --cask desktoppr'

  resolve_source
  mkdir -p -- "$destination_dir"
  install -m 755 -- "$source_file" "$destination_dir/kabe"

  printf '%s\n' "Installed kabe to $destination_dir/kabe"
}

main "$@"
