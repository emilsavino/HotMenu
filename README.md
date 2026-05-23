# HotMenu

A personal macOS menu bar app that displays live CPU temperature and fan speed.

Forked from [angristan/MacThrottle](https://github.com/angristan/MacThrottle) (MIT). See `LICENSE`.

## Install

Releases ship as unsigned `.zip` and `.dmg` artifacts, so macOS will quarantine the app on first launch. To install:

1. Drag `HotMenu.app` from the DMG (or extracted ZIP) into `/Applications`.
2. Remove the quarantine attribute so Gatekeeper lets it run:
   ```sh
   xattr -r -d com.apple.quarantine /Applications/HotMenu.app
   ```
3. Launch from `/Applications`.

## Build

```sh
make build
open .build/Build/Products/Debug/HotMenu.app
```

## Release

Push a `v*.*.*` tag to trigger the release workflow, which builds an unsigned `.zip` and `.dmg` and attaches them to a GitHub release with auto-generated notes:

```sh
git tag v0.2.0
git push origin v0.2.0
```
