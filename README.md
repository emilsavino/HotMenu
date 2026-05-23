# HotMenu

A personal macOS menu bar app that displays live CPU temperature and fan speed.

Forked from [angristan/MacThrottle](https://github.com/angristan/MacThrottle) (MIT). See `LICENSE`.

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
