# TODO

This is a small list of things I want to improve or revisit in GarbageMan over time.

Some of these are confirmed improvements, some are just ideas I want to test first. I do not want to add features just for the sake of making the module look bigger. The goal is still to keep GarbageMan simple, typed and easy to use in real Roblox projects.

---

## Documentation

- [ ] Add more real examples
- [ ] Add a basic tool / weapon cleanup example
- [ ] Add a UI cleanup example
- [ ] Add an NPC controller cleanup example
- [ ] Add a projectile or hitbox cleanup example
- [ ] Add a short guide for using GarbageMan with Rojo
- [ ] Add a short guide for using GarbageMan without Rojo
- [ ] Add Wally installation steps once the package setup is ready
- [ ] Add a small section for common mistakes
- [ ] Add a short section explaining when GarbageMan is not needed

---

## API

- [ ] Review the public API and keep it as small as possible
- [ ] Make sure method names are clear
- [ ] Document aliases better, if they stay
- [ ] Improve error messages for invalid cleanup objects
- [ ] Improve validation around unsupported cleanup values
- [ ] Review how custom cleanup methods are handled
- [ ] Review how promise-like objects are handled
- [ ] Keep the API predictable instead of adding too many shortcuts

---

## Cleanup Behavior

- [ ] Add more tests for repeated cleanup calls
- [ ] Add tests for cleaning an already cleaned scope
- [ ] Add tests for resources added during cleanup
- [ ] Add tests for nested cleanup objects
- [ ] Add tests for cleanup order
- [ ] Add tests for failed cleanup callbacks
- [ ] Decide how cleanup errors should be handled long-term

---

## Types

- [ ] Improve exported Luau types
- [ ] Add more type examples
- [ ] Review the types for connections
- [ ] Review the types for Instances
- [ ] Review the types for functions
- [ ] Review the types for promise-like objects
- [ ] Keep the types useful without making them annoying to work with

---

## Tests

- [ ] Add more TestEZ specs
- [ ] Test Instance cleanup
- [ ] Test custom cleanup method support
- [ ] Test repeated cleanup calls
- [ ] Test invalid cleanup inputs

---

## Benchmarks

- [ ] Add more benchmark cases
- [ ] Add a benchmark for many small scopes
- [ ] Add a benchmark for one large scope
- [ ] Add a benchmark for connection-heavy cleanup
- [ ] Add a benchmark for Instance cleanup
- [ ] Add a benchmark for callback cleanup
- [ ] Add clearer instructions for running benchmarks in Roblox Studio
- [ ] Add sample benchmark output
- [ ] Keep benchmarks realistic and easy to reproduce

---

## Possible Ideas

These are not confirmed features. They are just things I may test later.

- [ ] Cleanup priorities
- [ ] Cleanup batching
- [ ] Better debug labels
- [ ] Optional active scope tracking
- [ ] Optional warnings for scopes that were never cleaned
- [ ] Simple leak-detection helpers for development
- [ ] Studio-only debug tools
- [ ] More detailed benchmark reporting

---

## Release / Package

- [ ] Keep the RBXM download available in releases
- [ ] Add proper release notes for new versions

---

## Things I Want To Avoid

- [ ] Do not turn GarbageMan into a full framework
- [ ] Do not add features that make the basic use case harder
- [ ] Do not add too many aliases
- [ ] Do not hide cleanup mistakes too much
- [ ] Do not make benchmarks misleading
- [ ] Do not add debug tools that affect normal runtime performance

---

## Main Goal

GarbageMan should stay small, typed and predictable.

It should be simple enough to use in small systems but still reliable enough for larger systems like weapons, NPC controllers, UI flows, projectiles, tools, round systems other temporary runtime logic.
