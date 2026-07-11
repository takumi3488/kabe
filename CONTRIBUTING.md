# Contributing

## Development

- Keep `kabe` compatible with the `zsh` shipped by macOS 26.
- Preserve the backend boundary: `kabe` selects and persists an image, `macos-wp` updates every Space, and `desktoppr` refreshes every connected display.
- Do not add a second wallpaper-store implementation, UI automation, or direct database edits.

## Before opening a pull request

Run the focused test suite:

```sh
zsh scripts/test.zsh
```

Add or update a behavioral test in `tests/` when changing image selection,
installation, or error handling.

## Reporting issues

Include the macOS, `macos-wp`, and `desktoppr` versions, exact command output, and a
minimal description of the `~/.kabe` directory layout. Do not attach private
wallpaper images unless necessary to reproduce the issue.
