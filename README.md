# HotMenu

HotMenu is a fork of [MacThrottle](https://github.com/angristan/MacThrottle) by angristan. This project builds on the original app and keeps credit to the upstream project while evolving the menu bar experience in its own direction.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-15+-blue)](https://github.com/emilsavino/HotMenu)
[![Swift](https://img.shields.io/badge/Swift-6-orange)](https://swift.org)

A lightweight macOS menu bar app for monitoring thermal pressure, CPU temperature, and fan activity without requiring admin privileges.

![screenshot](./assets/screenshot.png)

## Features

- Text-based menu bar display with temperature and optional fan RPM
- Thermal pressure monitoring with nominal, moderate, heavy, and critical states
- CPU/GPU temperature readings via SMC, with IOHID fallback
- Fan RPM monitoring on Macs with fans
- History graph for thermal pressure, temperature, and fan activity
- Time breakdown by thermal state
- Configurable notifications for heavy pressure, critical pressure, and recovery
- Manual update check from the HotMenu fork releases
- Launch at Login support

## Installation

### Build Locally

Building locally is the primary installation path for HotMenu right now.

```bash
git clone https://github.com/emilsavino/HotMenu.git
cd HotMenu

xcodebuild -project HotMenu.xcodeproj \
  -scheme HotMenu \
  -configuration Release \
  -derivedDataPath build

open build/Build/Products/Release/HotMenu.app
```

You can also open `HotMenu.xcodeproj` in Xcode and press `Cmd+R`.

### Manual Install

If you build or download HotMenu manually, macOS may quarantine it on first launch.

1. Place `HotMenu.app` in `/Applications`
2. Remove the quarantine attribute:
   `xattr -r -d com.apple.quarantine /Applications/HotMenu.app`
3. Open the app

## How It Works

### Thermal Pressure

HotMenu reads thermal pressure from the Darwin notification system using `com.apple.system.thermalpressurelevel`. This gives more granularity than `ProcessInfo.thermalState`, which merges `moderate` and `heavy` into the same public `fair` bucket.

### Temperature

Temperature is read from the SMC first and falls back to IOHIDEventSystem if needed. The displayed value is the highest valid reading from the available CPU/GPU temperature sensors.

### Fan Monitoring

On Macs with fans, HotMenu reads fan data from the SMC and shows average fan RPM in the menu bar. The history graph continues to visualize fan activity alongside temperature and thermal pressure.

## Requirements

- macOS 15.0+
