# GarbageMan Benchmarks

These benchmarks were run in Roblox Studio on the server runtime. Each case was run 7 times and the median result is used as the main comparison point.

`RawArray` is included only as a very small baseline that stores cleanup entries in a plain array and cleans them in reverse order. It is not feature-equivalent with GarbageMan.

## How to Run

1. If you use Rojo, open the benchmark project with `rojo serve benchmark.project.json`.
2. If you run it manually, keep the `GarbageMan` module under `ReplicatedStorage.GarbageMan`.
3. Run `benchmarks/GarbageManBenchmark.server.lua` as a `Script` inside `ServerScriptService`.
4. Copy the `[GarbageManBenchmark]` lines from the Studio Output.

For optional comparison, if `ReplicatedStorage.Trove` or `ReplicatedStorage.Maid` exists as a ModuleScript, the benchmark will try to include it automatically.

## Results

| Adapter | Case | Count | Median | Best | Ops/sec |
|---|---|---:|---:|---:|---:|
| RawArray | Add function + Clean | 10,000 | 1.544 ms | 1.294 ms | 6,474,587 |
| RawArray | Add Destroy table + Clean | 10,000 | 3.206 ms | 2.249 ms | 3,119,249 |
| RawArray | Connect + Clean | 5,000 | 9.350 ms | 8.911 ms | 534,742 |
| GarbageMan | Add function + Clean | 10,000 | 1.659 ms | 1.431 ms | 6,026,638 |
| GarbageMan | Add Destroy table + Clean | 10,000 | 8.001 ms | 6.923 ms | 1,249,766 |
| GarbageMan | Connect + Clean | 5,000 | 12.296 ms | 11.485 ms | 406,620 |
| GarbageMan | Replace tag | 10,000 | 9.083 ms | 6.748 ms | 1,101,006 |
| GarbageMan | Add traceback capture | 1,000 | 0.388 ms | 0.309 ms | 2,580,645 |

## Notes

- `Add function + Clean` is very close to the raw array baseline: 1.659 ms vs 1.544 ms for 10,000 tasks.
- `Add Destroy table + Clean` is heavier because GarbageMan resolves cleanup methods, tracks object indices/tags, stores debug state and wraps cleanup with error handling.
- `Connect + Clean` includes real `BindableEvent` connection creation and disconnection.
- `Replace tag` measures repeated replacement of a tagged resource. This is one of GarbageMan's core convenience features.
- `Add traceback capture` is measured separately because traceback capture is a debug feature and should normally stay disabled in production.

## Benchmark Settings

```text
RUNS = 7
COUNT = 10000
CONNECTION_COUNT = 5000
REPLACE_COUNT = 10000
TRACEBACK_COUNT = 1000
Runtime = Roblox Studio server
