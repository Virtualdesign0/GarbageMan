# GarbageMan

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Release: v0.1.0](https://img.shields.io/badge/release-v0.1.0-blue.svg)](https://github.com/Virtualdesign0/GarbageMan/releases/tag/v0.1.0)

A small typed cleanup manager for Roblox Luau.

`GarbageMan` helps you keep temporary resources in one place and clean them up safely when a system is done. It is useful for connections, instances, promises, render step bindings, threads, functions, tweens, custom objects, UI controllers, tools, NPCs, hitboxes, projectiles and other runtime objects that should not live forever.

The idea is simple: create a scope, add the things that belong to that scope, then clean or destroy the scope when you are done.

---

## Features

- Typed Luau API
- Tracks Roblox instances, connections, functions, threads, promises and custom cleanup objects
- Supports custom cleanup methods like `"Destroy"`, `"Disconnect"`, `"Cancel"` or `"Clean"`
- Tagged resources with `Replace()` and `Get()`
- Object cleanup with `Remove()`
- Tag cleanup with `RemoveTag()`
- Ownership release with `Drop()` and `DropTag()`
- Child scopes with `Extend()` and `Adopt()`
- Signal helpers with `Connect()` and `Once()`
- RenderStep cleanup with `Render()`
- Promise cleanup with `AddPromise()`
- Instance lifecycle binding with `BindTo()` and `BindToAncestry()`
- Deferred cleanup with `CleanDeferred()` and `DestroyDeferred()`
- Lifecycle hooks with `OnDestroying()` and `OnDestroyed()`
- Debug summaries, leak warnings, failed cleanup tracking and optional add tracebacks

---

## Installation

You can use `GarbageMan` with Rojo, Wally or by downloading the `.rbxm` file from GitHub Releases.

### Rojo

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

The source files are stored like this:

```text
src/
  GarbageMan/
    init.lua
    Cleanup.lua
    Promise.lua
    Types.lua
```

When mounted with Rojo, the module appears in Studio like this:

```text
ReplicatedStorage
  GarbageMan
    Cleanup
    Promise
    Types
```

`init.lua` is the main module file. Rojo treats it as the module for the `GarbageMan` folder, so you can require the folder directly.

### RBXM

If you do not use Rojo or Wally, you can download the prebuilt `GarbageMan.rbxm` file from GitHub Releases.

Recommended release asset name:

```text
GarbageMan.rbxm
```

Latest release download link:

```text
https://github.com/Virtualdesign0/GarbageMan/releases/latest/download/GarbageMan.rbxm
```

After downloading the file, drag it into `ReplicatedStorage` in Roblox Studio.

The Studio structure should look like this:

```text
ReplicatedStorage
  GarbageMan
    Cleanup
    Promise
    Types
```

Usage:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GarbageMan = require(ReplicatedStorage.GarbageMan)
```

This option is mainly for users who want to use the module directly in Studio without setting up Rojo or Wally.

### Wally

The Wally manifest file is `wally.toml`.

Package configuration used in this repository:

```toml
[package]
name = "virtualdesign0/garbageman"
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"
```

The `registry` field is not your GitHub repository link. It should point to the Wally registry index.

To use this package as a dependency in another project:

```toml
[dependencies]
GarbageMan = "virtualdesign0/garbageman@0.1.0"
```

Then install the package:

```bash
wally install
```

In the consumer project's Rojo file, mount the `Packages` folder:

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

---

## Development Tools

`rokit.toml` pins the development tools used by this project.

The toolchain can include:

- `rojo`
- `selene`
- `run-in-roblox`

To install the tools:

```bash
rokit install
```

---

## Quick Start

```lua
local GarbageMan = require(path.to.GarbageMan)

local scope = GarbageMan.new("ExampleScope")

scope:Add(workspace.ChildAdded:Connect(function(child)
	print(child.Name)
end))

scope:Add(function()
	print("Cleaned up")
end)

-- Cleans the current resources but the scope can still be used again.
scope:Clean()

-- Final cleanup. The scope cannot be used after this.
scope:Destroy("Example finished")
```

---

## Most Used Methods

| Method | Use it for |
|---|---|
| `Add()` | Track a resource |
| `AddPromise()` | Track a started promise |
| `Replace()` | Keep one resource for a tag |
| `Get()` | Get a tagged resource |
| `Remove()` | Remove and clean a resource |
| `RemoveTag()` | Remove and clean a tagged resource |
| `Drop()` | Remove ownership without cleaning |
| `Clean()` | Reset a reusable scope |
| `Destroy()` | Final cleanup |
| `Extend()` | Create a child scope |
| `Connect()` | Connect and track a signal |
| `Once()` | Connect once and track the connection |

---

## Basic Example

```lua
local GarbageMan = require(path.to.GarbageMan)

local scope = GarbageMan.new("PartExample")

local part = scope:Construct(Instance, "Part")
part.Name = "TemporaryPart"
part.Parent = workspace

scope:Connect(part.Touched, function(hit)
	print("Touched by", hit.Name)
end)

scope:Add(function()
	print("PartExample cleaned")
end)

task.delay(5, function()
	scope:Destroy("No longer needed")
end)
```

---

## Why Use GarbageMan?

Roblox systems usually create resources that need to be cleaned later:

- `RBXScriptConnection`
- `Instance`
- spawned threads
- promises
- tweens
- render step bindings
- temporary effects
- UI objects
- tools
- weapons
- hitboxes
- projectiles
- character controllers
- NPC controllers

You can clean these manually but it gets messy once the system grows.

`GarbageMan` gives each system a clear ownership scope. If a resource belongs to a scope, add it to that scope. When the system ends, clean the scope.

---

## Compared to Maid or Trove

GarbageMan follows the same cleanup-scope idea as Maid and Trove-style utilities.

The main difference is that GarbageMan also includes tagged resources, final destroy semantics, child scopes, lifecycle hooks, leak warnings, failed cleanup tracking and debug summaries for larger systems.

It is still meant to stay small enough to use in normal gameplay code.

---

## Core Idea

A `GarbageMan` scope owns the resources added to it.

```lua
local scope = GarbageMan.new("InventoryUI")

scope:Add(connection)
scope:Add(frame)
scope:Add(function()
	print("Inventory closed")
end)

scope:Clean()
```

`Clean()` removes and cleans everything currently tracked by the scope.

`Destroy()` does the same cleanup but also permanently closes the scope.

---

## Clean vs Destroy

### Clean

`Clean()` clears all current resources but the scope can still be reused.

```lua
local scope = GarbageMan.new("RoundScope")

scope:Add(connection)
scope:Clean()

scope:Add(newConnection) -- valid
```

Use `Clean()` when you want to reset a reusable scope.

Good examples:

- refreshing a UI
- restarting a round
- clearing temporary effects
- resetting a controller without deleting the controller itself

### Destroy

`Destroy()` is final.

After calling `Destroy()`, mutating methods such as `Add()`, `Replace()`, `Connect()` or `Extend()` will throw.

```lua
local scope = GarbageMan.new("WeaponScope")

scope:Add(connection)
scope:Destroy("Weapon unequipped")

scope:Add(otherConnection) -- error
```

Use `Destroy()` when the scope is finished for good.

Good examples:

- player left
- character removed
- UI screen closed permanently
- NPC despawned
- weapon unequipped
- projectile expired

---

## Adding Resources

Use `Add()` to track a resource.

```lua
local connection = part.Touched:Connect(function(hit)
	print(hit.Name)
end)

scope:Add(connection)
```

You can also pass a cleanup method manually:

```lua
scope:Add(tween, "Cancel")
scope:Add(controller, "Destroy")
scope:Add(childScope, "Destroy")
scope:Add(function()
	print("cleanup")
end)
```

Supported resources include:

- `Instance`
- `RBXScriptConnection`
- connection-like objects with `Disconnect()`
- functions
- threads
- promise-like objects
- tables with `Destroy()`
- tables with `destroy()`
- tables with `Disconnect()`
- tables with `disconnect()`
- tables with `Cancel()`
- tables with `cancel()`
- tables with `Clean()`
- tables with `clean()`

---

## Custom Cleanup Methods

Sometimes a resource should not be destroyed. For example, tweens are usually cancelled.

```lua
local tween = TweenService:Create(part, tweenInfo, goal)

scope:Add(tween, "Cancel")

tween:Play()
```

When the scope is cleaned, GarbageMan calls:

```lua
tween:Cancel()
```

You can use the same pattern for your own objects:

```lua
scope:Add(controller, "Shutdown")
scope:Add(cache, "Clear")
scope:Add(session, "Close")
```

---

## Tagged Resources

Tags are useful when only one resource of a certain kind should exist at a time.

For example, keeping only one active tween:

```lua
local tween = TweenService:Create(frame, tweenInfo, goal)

scope:Replace("Tween:Current", tween, "Cancel")
tween:Play()
```

If the same tag is replaced later, the old resource is cleaned first.

```lua
local nextTween = TweenService:Create(frame, tweenInfo, nextGoal)

scope:Replace("Tween:Current", nextTween, "Cancel")
nextTween:Play()
```

You can get the current tagged resource with `Get()`:

```lua
local currentTween = scope:Get("Tween:Current")
```

You can clean a tag with `RemoveTag()`:

```lua
scope:RemoveTag("Tween:Current")
```

You can remove a tag without cleaning its object with `DropTag()`:

```lua
scope:DropTag("Tween:Current")
```

For normal usage, prefer `Replace()` when you want to work with tags.

---

## Remove vs Drop

### Remove

`Remove()` removes a resource from the scope and runs its cleanup.

```lua
scope:Remove(connection)
```

For tags:

```lua
scope:RemoveTag("Tween:Current")
```

### Drop

`Drop()` removes a resource from the scope without cleaning it.

```lua
scope:Drop(part)
```

For tags:

```lua
scope:DropTag("SharedObject")
```

This is useful when ownership is being moved somewhere else.

```lua
local object = scope:Get("SharedObject")

scope:DropTag("SharedObject")
otherScope:Add(object)
```

---

## Removing Tags by Prefix

If your tags follow a pattern, you can remove a group of them.

```lua
scope:Replace("Tween:Open", openTween, "Cancel")
scope:Replace("Tween:Close", closeTween, "Cancel")
scope:Replace("Tween:Hover", hoverTween, "Cancel")

scope:RemoveTagsWithPrefix("Tween:")
```

`RemoveTagsWithPrefix()` scans the current tag set. It is useful for grouped cleanup but it should not be used every frame.

---

## Signals

### Connect

`Connect()` connects to a signal and tracks the connection.

```lua
scope:Connect(part.Touched, function(hit)
	print(hit.Name)
end)
```

This is the same idea as:

```lua
local connection = part.Touched:Connect(function(hit)
	print(hit.Name)
end)

scope:Add(connection)
```

### Once

`Once()` connects to a signal once and then cleans the connection.

```lua
scope:Once(part.Destroying, function()
	print("Part destroyed")
end)
```

If the signal supports `Once`, GarbageMan uses it. Otherwise, it falls back to a normal connection and disconnects after the first call.

---

## RenderStep

`Render()` binds a callback with `RunService:BindToRenderStep`.

```lua
scope:Render("CameraBob", Enum.RenderPriority.Camera.Value + 1, function(dt)
	-- camera update
end)
```

When the scope is cleaned, GarbageMan calls:

```lua
RunService:UnbindFromRenderStep("CameraBob")
```

`Render()` can only be used on the client. Calling it on the server will throw.

---

## Promises

Use `AddPromise()` for started promise-like objects.

```lua
local promise = SomeAsyncOperation()

scope:AddPromise(promise)
```

If the scope is cleaned or destroyed while the promise is still running, the promise is cancelled.

GarbageMan only tracks promises that are still in the `Started` state. Already completed promises are ignored.

A promise-like object should provide:

```lua
{
	getStatus = function() end,
	finally = function() end,
	cancel = function() end,
}
```

---

## Constructing Objects

`Construct()` creates an object and adds it to the scope.

It supports constructors shaped like tables with `.new()`:

```lua
local controller = scope:Construct(Controller, player)
```

It also supports constructor functions:

```lua
local object = scope:Construct(function()
	return SomeClass.new()
end)
```

You can use it with Roblox instances:

```lua
local part = scope:Construct(Instance, "Part")
part.Parent = workspace
```

---

## Copying Instances

`Copy()` clones an instance and tracks the clone.

```lua
local clonedFrame = scope:Copy(templateFrame)
clonedFrame.Parent = playerGui
```

When the scope is cleaned, the clone is destroyed.

---

## Child Scopes

### Extend

`Extend()` creates a child `GarbageMan` scope and tracks it under the parent.

```lua
local parent = GarbageMan.new("Character")
local weaponScope = parent:Extend("Weapon")

weaponScope:Add(connection)

parent:Destroy("Character removed")
```

Destroying the parent also destroys the child.

If you pass a name, it is appended to the parent scope name.

```lua
local scope = GarbageMan.new("Player")
local uiScope = scope:Extend("Inventory")

print(uiScope:GetName()) -- Player:Inventory
```

### Adopt

`Adopt()` attaches an existing scope to another scope.

```lua
local parent = GarbageMan.new("Player")
local child = GarbageMan.new("Pet")

parent:Adopt(child)

parent:Destroy("Player left")
```

When the parent is destroyed, the adopted child is destroyed too.

---

## Binding to Instances

### BindTo

`BindTo(instance)` destroys the scope when the instance fires `Destroying`.

```lua
local model = Instance.new("Model")
local scope = GarbageMan.new("ModelScope")

scope:BindTo(model)

scope:Add(function()
	print("Model scope destroyed")
end)

model:Destroy()
```

The instance does not need to already be parented under `game`.

### from

`GarbageMan.from(instance, name?)` creates a new scope and binds it to the instance.

```lua
local model = Instance.new("Model")

local scope = GarbageMan.from(model)
scope:Add(function()
	print("Model destroyed")
end)
```

You can pass a custom name:

```lua
local scope = GarbageMan.from(model, "EnemyModel")
```

### BindToAncestry

`BindToAncestry(instance)` destroys the scope when the instance parent becomes `nil`.

```lua
scope:BindToAncestry(part)
```

This is separate from `BindTo()` because a parent change does not always mean the instance was truly destroyed.

---

## Lifecycle Hooks

GarbageMan supports hooks for final destruction.

### OnDestroying

Runs before final cleanup starts.

```lua
scope:OnDestroying(function(reason)
	print("Destroy started:", reason)
end)
```

### OnDestroyed

Runs after the final cleanup attempt.

```lua
scope:OnDestroyed(function(reason)
	print("Destroy finished:", reason)
end)
```

Lifecycle hooks only run for:

```lua
scope:Destroy()
scope:DestroyDeferred()
```

They do not run for reusable cleanup:

```lua
scope:Clean()
```

A lifecycle hook returns a disconnect function:

```lua
local disconnect = scope:OnDestroyed(function()
	print("Destroyed")
end)

disconnect()
```

If a lifecycle hook errors, GarbageMan still tries to continue the destroy flow and reports the first error afterwards.

---

## Destroy Reasons

`Destroy()` and `DestroyDeferred()` accept an optional reason.

```lua
scope:Destroy("Player left")
```

You can read it later with:

```lua
print(scope:GetDestroyReason())
```

Lifecycle hooks receive the same reason:

```lua
scope:OnDestroyed(function(reason)
	print("Destroyed because:", reason)
end)

scope:Destroy("Screen closed")
```

This is mostly useful for debugging larger systems.

---

## Deferred Cleanup

### CleanDeferred

`CleanDeferred()` schedules cleanup for the next scheduler step.

```lua
scope:CleanDeferred()
```

Multiple calls in the same scheduler step are merged into one cleanup.

```lua
scope:CleanDeferred()
scope:CleanDeferred()
scope:CleanDeferred()
```

Only one deferred clean will run.

### DestroyDeferred

`DestroyDeferred()` marks the scope as destroyed immediately, then runs cleanup later through `task.defer`.

```lua
scope:DestroyDeferred("Delayed cleanup")
```

Behavior:

- The scope is marked as destroyed immediately.
- `OnDestroying` runs immediately.
- Cleanup runs later.
- `OnDestroyed` runs after the deferred cleanup attempt.

If deferred destroy cleanup fails, GarbageMan reports the error through the configured error handler if one exists.

---

## TryClean and TryDestroy

Use `TryClean()` or `TryDestroy()` when you want errors as return values instead of thrown errors.

```lua
local ok, message = scope:TryClean()

if not ok then
	warn(message)

	local failed = scope:GetLastFailedEntry()
	if failed then
		warn("Failed tag:", failed.tag)
		warn("Cleanup method:", failed.cleanupMethod)
	end
end
```

`TryDestroy()` behaves the same way but the scope is still considered destroyed even if cleanup fails.

```lua
local ok, message = scope:TryDestroy("Shutdown")

if not ok then
	warn(message)
end
```

---

## Debugging

### Size

```lua
print(scope:Size())
```

### Tags

```lua
for _, tag in scope:GetTags() do
	print(tag)
end
```

### Debug Summary

`GetDebugSummary()` returns a safer summary without direct object references.

```lua
for _, entry in scope:GetDebugSummary() do
	print(entry.objectType, entry.cleanupMethod, entry.tag)
end
```

For instances, `objectType` includes the class name and instance name.

Example:

```text
Part "Hitbox"
Frame "InventoryPanel"
Model "Enemy"
```

### Debug Dump

`GetDebugDump()` returns real object references.

```lua
for _, entry in scope:GetDebugDump() do
	print(entry.object, entry.cleanupMethod, entry.tag)
end
```

This is useful while developing but it should not be used for constant production logging.

### Failed Cleanup Info

If cleanup fails, GarbageMan stores the last cleanup error and the entry that failed.

```lua
local ok, message = scope:TryClean()

if not ok then
	warn(scope:GetLastCleanupError())

	local failed = scope:GetLastFailedEntry()

	if failed then
		warn("Tag:", failed.tag)
		warn("Cleanup method:", failed.cleanupMethod)
		warn("Added at:", failed.addedTraceback)
	end
end
```

### AssertEmpty

`AssertEmpty()` throws if the scope still has tracked resources.

```lua
scope:Clean()
scope:AssertEmpty()
```

If tagged resources are still present, the error message includes a short tag preview.

---

## Leak Warnings

`WarnIfNotDestroyedAfter()` warns if the scope is still alive after a given number of seconds.

```lua
scope:WarnIfNotDestroyedAfter(60)
```

You can pass a custom message:

```lua
scope:WarnIfNotDestroyedAfter(60, "InventoryUI was not destroyed after 60 seconds")
```

It returns a function that cancels the warning.

```lua
local cancelWarning = scope:WarnIfNotDestroyedAfter(60)

cancelWarning()
```

Leak warnings can be disabled globally with `GarbageMan.configure()`.

---

## Global Debug Tools

GarbageMan keeps a weak registry of active scopes. This is mainly useful while debugging.

```lua
for _, summary in GarbageMan.Debug.getSummary() do
	print(summary.name, summary.size, summary.age)
end
```

A summary contains:

```lua
{
	name = "InventoryUI",
	size = 5,
	age = 12.4,
	destroyed = false,
	cleaning = false,
	destroyReason = "",
	lastCleanupError = "",
	lastFailedObjectType = "",
	lastFailedTag = "",
}
```

You can also get the active scope objects directly:

```lua
for _, scope in GarbageMan.Debug.getScopes() do
	print(scope:GetName(), scope:Size())
end
```

`Debug.getScopes()` returns real scope objects. Prefer `Debug.getSummary()` for logging or debug panels.

---

## Configuration

Use `GarbageMan.configure()` to change module-level debug behavior.

```lua
GarbageMan.configure({
	tracebacks = true,
	captureAddTracebacks = true,
	leakWarnings = true,
	errorHandler = function(message, scope)
		warn("GarbageMan error in", scope:GetName(), message)
	end,
})
```

Available options:

| Option | Description |
|---|---|
| `tracebacks` | Adds tracebacks to cleanup errors |
| `captureAddTracebacks` | Stores where each resource was added |
| `leakWarnings` | Enables or disables leak warning output |
| `errorHandler` | Handles async cleanup errors from deferred destroy |

To remove the error handler:

```lua
GarbageMan.configure({
	errorHandler = false,
})
```

To read the current config:

```lua
local config = GarbageMan.getConfig()

print(config.tracebacks)
print(config.captureAddTracebacks)
print(config.leakWarnings)
```

Traceback capture is disabled by default because it has extra cost. It is best used during development.

---

## Behavior Notes

A few important details:

- `Clean()` cleans current resources and keeps the scope reusable.
- `Destroy()` is final and prevents future mutation.
- `Remove()` cleans an object and removes it from the scope.
- `Drop()` removes an object without cleaning it.
- `Replace()` cleans the old tagged resource before storing the new one.
- `RemoveTag()` cleans a tagged resource.
- `DropTag()` removes a tag without cleaning its object.
- `RemoveTagsWithPrefix()` scans the current tag set.
- Cleanup runs in reverse insertion order.
- `DestroyDeferred()` marks the scope as destroyed immediately.
- `AddPromise()` only tracks started promises.
- Debug tracebacks are optional and disabled by default.
- `GetDebugDump()` returns real object references.
- `GetDebugSummary()` is safer for logs.

---

## Performance Notes

GarbageMan is meant for lifecycle cleanup, not per-frame resource churn.

A good rule is to create one scope for one clear lifetime.

Good examples:

- one UI screen
- one character controller
- one weapon
- one NPC
- one hitbox
- one projectile
- one temporary effect
- one round
- one player session object

```lua
local inventoryScope = GarbageMan.new("InventoryUI")
local weaponScope = GarbageMan.new("Weapon")
local npcScope = GarbageMan.new("NPC:Strawberry")
local projectileScope = GarbageMan.new("Projectile")
```

Avoid using expensive debug features in hot paths:

- Do not call `RemoveTagsWithPrefix()` every frame.
- Do not spam `GetDebugDump()` in production logs.
- Keep `captureAddTracebacks` disabled unless you are debugging leaks.
- Prefer `GetDebugSummary()` over `GetDebugDump()` for debug panels.

---

## What Not To Do

GarbageMan is meant to manage lifetimes. It should not be used as a per-frame container or as a replacement for normal state management.

### Do not create a new scope every frame

Bad:

```lua
RunService.Heartbeat:Connect(function()
	local scope = GarbageMan.new("FrameScope")
	scope:Add(something)
	scope:Clean()
end)
```

Create a scope for a real lifetime instead, such as a UI screen, weapon, NPC, projectile, character or temporary effect.

Good:

```lua
local scope = GarbageMan.new("Weapon")

scope:Connect(tool.Activated, function()
	print("Activated")
end)

scope:Destroy("Weapon unequipped")
```

### Do not use `RemoveTagsWithPrefix()` every frame

`RemoveTagsWithPrefix()` scans the current tag set.

Bad:

```lua
RunService.Heartbeat:Connect(function()
	scope:RemoveTagsWithPrefix("Tween:")
end)
```

Use it for grouped cleanup, mode changes, UI resets or debugging.

Good:

```lua
scope:RemoveTagsWithPrefix("Tween:")
```

### Do not use `GetDebugDump()` for constant production logging

`GetDebugDump()` returns real object references. It is useful while debugging but it should not be spammed in production logs.

Bad:

```lua
while true do
	task.wait(1)

	for _, entry in scope:GetDebugDump() do
		print(entry.object)
	end
end
```

Use `GetDebugSummary()` for safer logs or debug panels.

Good:

```lua
for _, entry in scope:GetDebugSummary() do
	print(entry.objectType, entry.cleanupMethod, entry.tag)
end
```

### Do not keep `captureAddTracebacks` enabled all the time

`captureAddTracebacks` is useful when tracking leaks but it has extra cost because it stores where each resource was added.

Use it during development:

```lua
GarbageMan.configure({
	captureAddTracebacks = true,
})
```

Turn it off when you no longer need it:

```lua
GarbageMan.configure({
	captureAddTracebacks = false,
})
```

### Do not call mutating methods after `Destroy()`

`Destroy()` is final. After a scope is destroyed, you should not add or replace resources.

Bad:

```lua
scope:Destroy("Closed")

scope:Add(connection) -- error
```

Create a new scope instead.

Good:

```lua
scope:Destroy("Closed")

scope = GarbageMan.new("NewScope")
scope:Add(connection)
```

### Do not confuse `Remove()` and `Drop()`

`Remove()` cleans the resource.

```lua
scope:Remove(part) -- calls cleanup
```

`Drop()` only removes ownership. It does not clean the resource.

```lua
scope:Drop(part) -- does not destroy part
```

Use `Drop()` only when another system will take ownership.

Good:

```lua
local sharedPart = scope:Get("SharedPart")

scope:DropTag("SharedPart")
otherScope:Add(sharedPart)
```

### Do not use the same RenderStep name from multiple systems

`Render()` uses `RunService:BindToRenderStep`. RenderStep names should be unique.

Bad:

```lua
cameraScope:Render("Update", priority, updateCamera)
weaponScope:Render("Update", priority, updateWeapon)
```

Use clear names:

```lua
cameraScope:Render("Camera:Bob", priority, updateCamera)
weaponScope:Render("Weapon:Sway", priority, updateWeapon)
```

### Do not rely on `Clean()` for final shutdown

`Clean()` keeps the scope reusable. Use `Destroy()` when the scope is finished for good.

Bad:

```lua
scope:Clean()
-- scope is still reusable
```

Good:

```lua
scope:Destroy("Player left")
```

### Do not ignore failed cleanup results

If you use `TryClean()` or `TryDestroy()`, check the result.

Bad:

```lua
scope:TryClean()
```

Good:

```lua
local ok, message = scope:TryClean()

if not ok then
	warn(message)

	local failed = scope:GetLastFailedEntry()
	if failed then
		warn("Failed tag:", failed.tag)
		warn("Cleanup method:", failed.cleanupMethod)
	end
end
```

### Do not store unrelated systems in one large scope

A scope should represent a clear lifetime.

Bad:

```lua
local scope = GarbageMan.new("Everything")

scope:Add(inventoryConnection)
scope:Add(weaponConnection)
scope:Add(npcConnection)
scope:Add(projectilePart)
```

Use smaller scopes with clear ownership.

Good:

```lua
local inventoryScope = GarbageMan.new("InventoryUI")
local weaponScope = GarbageMan.new("Weapon")
local npcScope = GarbageMan.new("NPC")
local projectileScope = GarbageMan.new("Projectile")
```

### Do not use tags as a replacement for normal data structures

Tags are for ownership and cleanup, not for storing all gameplay state.

Bad:

```lua
scope:Replace("PlayerLevel", levelValue)
scope:Replace("PlayerCoins", coinsValue)
scope:Replace("CurrentQuest", questData)
```

Use normal tables for gameplay state. Use GarbageMan for resources that need cleanup.

Good:

```lua
local state = {
	level = 10,
	coins = 250,
	currentQuest = "FindFruit",
}

scope:Replace("Tween:Current", tween, "Cancel")
```

### Do not assume `BindToAncestry()` means the instance was destroyed

`BindToAncestry()` destroys the scope when the instance parent becomes `nil`.

That does not always mean the instance was permanently destroyed. It may have been temporarily unparented.

Use `BindTo()` when you specifically want to follow the instance's `Destroying` event.

```lua
scope:BindTo(instance)
```

Use `BindToAncestry()` only when parent removal should end the scope.

```lua
scope:BindToAncestry(instance)
```

---

## API Reference

### Module

```lua
GarbageMan.new(name: string?) -> GarbageMan
GarbageMan.from(instance: Instance, name: string?) -> GarbageMan

GarbageMan.configure(options: Config)
GarbageMan.getConfig() -> Config

GarbageMan.Debug.getSummary() -> { ScopeDebugSummary }
GarbageMan.Debug.getScopes() -> { GarbageMan }
```

### Scope Info

```lua
scope:GetName() -> string
scope:SetName(name: string) -> GarbageMan
scope:GetDestroyReason() -> any?

scope:Size() -> number
scope:IsCleaning() -> boolean
scope:IsDestroyed() -> boolean
```

### Adding Resources

```lua
scope:Add(object, cleanupMethod?) -> object
scope:AddPromise(promise) -> promise
scope:Construct(classOrFunction, ...) -> object
scope:Copy(instance) -> Instance
```

`Add()` can also be used with an internal tag argument but for normal tagged resources, prefer `Replace()`.

### Tagged Resources

```lua
scope:Replace(tag, object, cleanupMethod?) -> object
scope:Get(tag) -> any?

scope:Contains(object) -> boolean
scope:ContainsTag(tag) -> boolean
```

### Removing Resources

```lua
scope:Remove(object) -> boolean
scope:RemoveTag(tag) -> boolean
scope:RemoveTagsWithPrefix(prefix: string) -> number

scope:Drop(object) -> boolean
scope:DropTag(tag) -> boolean
```

### Signals and RenderStep

```lua
scope:Connect(signal, callback) -> connection
scope:Once(signal, callback) -> connection
scope:Render(name, priority, callback)
```

### Scope Composition

```lua
scope:Extend(name?) -> GarbageMan
scope:Adopt(childScope) -> GarbageMan
```

### Instance Binding

```lua
scope:BindTo(instance) -> RBXScriptConnection
scope:BindToAncestry(instance) -> RBXScriptConnection
```

### Cleanup

```lua
scope:Clean()
scope:TryClean() -> (boolean, any)
scope:CleanDeferred()
scope:WrapClean() -> () -> ()

scope:Destroy(reason?)
scope:TryDestroy(reason?) -> (boolean, any)
scope:DestroyDeferred(reason?)
```

### Lifecycle Hooks

```lua
scope:OnDestroying(callback) -> disconnect
scope:OnDestroyed(callback) -> disconnect
```

### Debug

```lua
scope:GetDebugSummary() -> { DebugSummaryEntry }
scope:GetDebugDump() -> { DebugEntry }

scope:GetLastCleanupError() -> any?
scope:GetLastFailedEntry() -> DebugEntry?

scope:GetTags() -> { any }
scope:AssertEmpty()

scope:WarnIfNotDestroyedAfter(seconds, message?) -> disconnect
```

---

## Project Layout

In Roblox Studio:

```text
GarbageMan
  Cleanup
  Promise
  Types
  GarbageMan.spec
  Promise.spec
```

If exported to the filesystem, the same structure may look like this:

```text
src/
  GarbageMan/
    init.lua
    Cleanup.lua
    Promise.lua
    Types.lua

tests/
  GarbageMan.spec.lua
  Promise.spec.lua
```

---

## Tests

This repository includes two spec files:

```text
GarbageMan.spec
Promise.spec
```

`GarbageMan.spec` covers the main scope behavior, including:

- `Add()` and `Clean()`
- `Destroy()` final behavior
- `Replace()` tag replacement
- `Remove()` and `RemoveTag()`
- `Drop()` and `DropTag()`
- `Extend()` and `Adopt()`
- `Connect()` and `Once()`
- `BindTo()` and `BindToAncestry()`
- `CleanDeferred()` queue merging
- `DestroyDeferred()` behavior
- lifecycle hooks
- debug summary
- failed cleanup tracking

`Promise.spec` covers promise-like validation and promise cleanup behavior, including:

- promise-like validation
- started promise tracking
- cleanup cancellation
- completed promise ignoring
- promise removal after `finally`
- invalid promise errors

---

## Example: UI Scope

```lua
local scope = GarbageMan.new("InventoryUI")

local frame = scope:Copy(InventoryTemplate)
frame.Parent = playerGui

scope:Connect(closeButton.Activated, function()
	scope:Destroy("Inventory closed")
end)

scope:Replace("Tween:Open", TweenService:Create(frame, tweenInfo, {
	Position = UDim2.fromScale(0.5, 0.5),
}), "Cancel")

local tween = scope:Get("Tween:Open")
if tween then
	tween:Play()
end
```

---

## Example: NPC Scope

```lua
local npcScope = GarbageMan.new("NPC:Strawberry")

npcScope:WarnIfNotDestroyedAfter(120)

npcScope:BindTo(npcModel)

npcScope:Connect(npcModel.Destroying, function()
	print("NPC model destroyed")
end)

npcScope:OnDestroyed(function(reason)
	print("NPC scope destroyed:", reason)
end)

npcScope:Add(function()
	print("Cleaning NPC state")
end)
```

---

## Example: Debug Panel

```lua
for _, summary in GarbageMan.Debug.getSummary() do
	print(
		summary.name,
		summary.size,
		math.floor(summary.age),
		summary.lastCleanupError
	)
end
```

---

## Publishing

Before publishing a new version:

1. Make sure the package name in `wally.toml` is correct.
2. Increase the `version` value using semantic versioning.
3. Check that the README and API examples are still accurate.
4. Run:

```bash
wally publish
```

After publishing, other projects can install the package using the dependency name and version from `wally.toml`.

---

## License

MIT License.
