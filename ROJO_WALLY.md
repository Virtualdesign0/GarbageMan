# Rojo and Wally Guide

This package can be mounted directly with Rojo and includes a Wally manifest.

## Rojo

`default.project.json` mounts the module as `ReplicatedStorage.GarbageMan`:

```json
{
  "name": "GarbageMan",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "GarbageMan": {
        "$path": "src/GarbageMan"
      }
    }
  }
}
```

Usage inside Studio:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GarbageMan = require(ReplicatedStorage.GarbageMan)
```

Spec files are kept in the `tests` folder. If you use TestEZ, you can mount this folder separately in your own test project file.

## Rokit

`rokit.toml` pins the development tools used by this project:

- `rojo`
- `selene`
- `run-in-roblox`

To install the tools, run:

```bash
rokit install
```

## Wally

The Wally manifest file is `wally.toml`.

Package configuration used in this repository:

```toml
[package]
name = "virtualdesign0/garbageman"
version = "0.1.3"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"
```

Before publishing, replace the namespace in the `name` field with your own Wally namespace.

To use this package as a dependency in another project:

```toml
[dependencies]
GarbageMan = "virtualdesign0/garbageman@0.1.3"
```

Then run:

```bash
wally install
```

In the consumer Rojo project file, mount the `Packages` folder:

```json
{
  "name": "Game",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "Packages": {
        "$path": "Packages"
      }
    }
  }
}
```

Usage with Wally:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GarbageMan = require(ReplicatedStorage.Packages.GarbageMan)
```

## Publishing Flow

1. Update the `name` field in `wally.toml` with your own namespace.
2. Increase the `version` value using semantic versioning.
3. Make sure the README and API examples are up to date.
4. Publish the package with `wally publish`.
