# kabe

`kabe` rotates macOS wallpapers through the images in `~/.kabe` on every display
and every Mission Control Space.

It selects images in lexical filename order and persists the last successful choice
in `~/.kabe/.last-wallpaper`, so the rotation remains deterministic even when a
different Space is active.

## Requirements

- macOS 26 Tahoe
- `zsh` (included with macOS)
- [`macos-wp`](https://github.com/marek-vybiral/homebrew-macos-wp)
- [`desktoppr`](https://github.com/scriptingosx/desktoppr)

Install both backends as your normal user. Do this before running the installer;
Homebrew must not run under `sudo`.

```sh
brew install marek-vybiral/macos-wp/macos-wp
brew install --cask desktoppr
```

## Install
Install directly from the default branch:

```sh
curl -fsSL https://raw.githubusercontent.com/takumi3488/kabe/main/installer.sh | sh
```

The default destination is `/usr/local/bin/kabe`. To install into a directory you
own instead, pass the prefix through `sh`:

```sh
curl -fsSL https://raw.githubusercontent.com/takumi3488/kabe/main/installer.sh \
  | sh -s -- --prefix "$HOME/.local/bin"
```

The installer downloads `kabe` from the same repository, verifies both wallpaper
backends before writing anything, and then installs an executable. After cloning,
the equivalent local command is:

```sh
./installer.sh --prefix "$HOME/.local/bin"
```

## Use

Put supported images directly in `~/.kabe`:

```sh
mkdir -p ~/.kabe
cp ~/Pictures/wallpapers/* ~/.kabe/
kabe
```

Supported extensions: `jpg`, `jpeg`, `png`, `gif`, `webp`, and `heic`.

The first invocation selects the first image. Each later invocation selects the
next image and wraps at the end. Remove `~/.kabe/.last-wallpaper` to reset the
rotation to the first image.

## Displays and Mission Control Spaces

`kabe` uses two complementary application steps:

1. `macos-wp` writes `Displays.<DisplayUUID>` for future Spaces and
   `Spaces.<SpaceUUID>.Displays.<DisplayUUID>` for existing Spaces. It atomically
   updates the wallpaper store, keeps
   `~/Library/Application Support/com.apple.wallpaper/Store/Index.plist.bak`, and
   restarts `WallpaperAgent`.
2. `desktoppr` immediately applies the same image to every currently connected
   physical display. This forces the active external display to refresh instead of
   continuing to render a cached or system-default wallpaper.

## Test

```sh
zsh scripts/test.zsh
```

The test suite uses a fake `macos-wp`; it does not change your wallpaper.

## Uninstall

```sh
rm /usr/local/bin/kabe
rm -f ~/.kabe/.last-wallpaper
```

## License

Licensed under the [Apache License 2.0](LICENSE).
