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

Sparkle update metadata is published to [`appcast.xml`](appcast.xml). Set up its signing key once on a Mac after Xcode has resolved the Sparkle package:

```sh
GENERATE_KEYS="$(find ~/Library/Developer/Xcode/DerivedData -path '*artifacts/sparkle*/bin/generate_keys' -print -quit)"
cd "$(dirname "$GENERATE_KEYS")"
./generate_keys
./generate_keys -x sparkle_private_key.txt
```

Copy the public key printed by `generate_keys` into `SUPublicEDKey` in `HotMenu/Info.plist`. Store the full contents of `sparkle_private_key.txt` as the GitHub Actions secret `SPARKLE_PRIVATE_KEY`, then delete the exported file if it is no longer needed. Never commit the private key.

Push a `v*.*.*` tag to trigger the release workflow, which bumps the app version from the tag, builds and signs the update ZIP, attaches the `.zip` and `.dmg` to a GitHub release, and opens a pull request containing the new appcast item for `main`. Merge that pull request to publish the update feed:

```sh
git tag v0.2.0
git push origin v0.2.0
```

The same workflow can be run manually from GitHub Actions by entering an existing release tag, which is useful for retrying a failed appcast publication.
