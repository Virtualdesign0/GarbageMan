# GarbageMan Benchmarks

This benchmark file produces repeatable Studio server measurements for a DevForum post.

## How to Run

1. If you use Rojo, open the benchmark project with `rojo serve benchmark.project.json`.
2. If you run it manually, keep the `GarbageMan` module under `ReplicatedStorage.GarbageMan`.
3. Run `benchmarks/GarbageManBenchmark.server.lua` as a `Script` inside `ServerScriptService`.
4. Copy the `[GarbageManBenchmark]` lines from the Studio Output.

For optional comparison, if `ReplicatedStorage.Trove` or `ReplicatedStorage.Maid` exists as a ModuleScript, the benchmark will try to include it automatically.

## Measured Scenarios

- `Add function + Clean`: adds function cleanup tasks and cleans them.
- `Add Destroy table + Clean`: adds tables with a `Destroy()` method and cleans them.
- `Connect + Clean`: adds `BindableEvent.Event` connections and disconnects them during cleanup.
- `Replace tag`: only runs on adapters that support tagged replace behavior, such as GarbageMan.
- `Add traceback capture`: measures the cost of capturing add tracebacks in GarbageMan.

## Note for DevForum

When sharing results, include:

- Studio version
- Client or server: this script runs on the server.
- Run count: `RUNS` in the benchmark script
- Operation count: `COUNT`, `CONNECTION_COUNT`, and `REPLACE_COUNT` in the script
- Use the `median` value as the main comparison point.

`RawArray` is not a feature-equivalent library baseline. It is only included to show the lower bound of a very simple array cleanup loop.

## Example Output Format

```text
[GarbageManBenchmark] RawArray   | Add function + Clean         | n= 10000 | median=...
[GarbageManBenchmark] GarbageMan | Add function + Clean         | n= 10000 | median=...
[GarbageManBenchmark] GarbageMan | Replace tag                  | n= 10000 | median=...
```
