local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GarbageMan: any = require(ReplicatedStorage:WaitForChild("GarbageMan"))

local RUNS = 7
local COUNT = 10000
local CONNECTION_COUNT = 5000
local REPLACE_COUNT = 10000
local TRACEBACK_COUNT = 1000

type BenchmarkScope = any
type Adapter = {
	name: string,
	new: () -> BenchmarkScope,
	add: (scope: BenchmarkScope, object: any, cleanupMethod: string?) -> (),
	connect: (scope: BenchmarkScope, signal: any, callback: (...any) -> ()) -> any,
	clean: (scope: BenchmarkScope) -> (),
	replace: ((scope: BenchmarkScope, tag: any, object: any, cleanupMethod: string?) -> ())?,
}

local function round(value: number, decimals: number): number
	local scale = 10 ^ decimals
	local rounded = math.floor(value * scale + 0.5) / scale
	return rounded
end

local function readMemoryKb(): number
	local ok: boolean
	local value: any

	ok, value = pcall(gcinfo)

	if not ok or typeof(value) ~= "number" then
		return 0
	end

	return value
end

local function getMedian(values: { number }): number
	table.sort(values)

	local middle = math.ceil(#values / 2)
	local value = values[middle]

	if value == nil then
		return 0
	end

	return value
end

local function getBest(values: { number }): number
	local best = math.huge

	for _, value in values do
		if value < best then
			best = value
		end
	end

	if best == math.huge then
		return 0
	end

	return best
end

local function cleanupObject(object: any, cleanupMethod: string?)
	if cleanupMethod ~= nil then
		object[cleanupMethod](object)
		return
	end

	local objectType = typeof(object)

	if objectType == "function" then
		object()
	elseif objectType == "RBXScriptConnection" then
		if object.Connected ~= false then
			object:Disconnect()
		end
	elseif objectType == "Instance" then
		object:Destroy()
	elseif objectType == "table" then
		if typeof(object.Destroy) == "function" then
			object:Destroy()
		elseif typeof(object.Disconnect) == "function" then
			object:Disconnect()
		elseif typeof(object.destroy) == "function" then
			object:destroy()
		elseif typeof(object.disconnect) == "function" then
			object:disconnect()
		elseif typeof(object.Cancel) == "function" then
			object:Cancel()
		elseif typeof(object.cancel) == "function" then
			object:cancel()
		elseif typeof(object.Clean) == "function" then
			object:Clean()
		elseif typeof(object.clean) == "function" then
			object:clean()
		else
			error(`RawArray cannot clean table object: {object}`, 3)
		end
	else
		error(`RawArray cannot clean object type {objectType}`, 3)
	end
end

local function makeDestroyable(): any
	local object: any = {
		destroyed = false,
	}

	function object:Destroy()
		self.destroyed = true
	end

	return object
end

local function makeRawAdapter(): Adapter
	local adapter: Adapter = {
		name = "RawArray",
		new = function(): BenchmarkScope
			return {
				entries = {},
			}
		end,
		add = function(scope: BenchmarkScope, object: any, cleanupMethod: string?)
			local entries = scope.entries
			entries[#entries + 1] = {
				object = object,
				cleanupMethod = cleanupMethod,
			}
		end,
		connect = function(scope: BenchmarkScope, signal: any, callback: (...any) -> ()): any
			local connection = signal:Connect(callback)
			local entries = scope.entries

			entries[#entries + 1] = {
				object = connection,
				cleanupMethod = nil,
			}

			return connection
		end,
		clean = function(scope: BenchmarkScope)
			local entries = scope.entries

			for index = #entries, 1, -1 do
				local entry = entries[index]
				cleanupObject(entry.object, entry.cleanupMethod)
				entries[index] = nil
			end
		end,
		replace = nil,
	}

	return adapter
end

local function makeGarbageManAdapter(): Adapter
	local adapter: Adapter = {
		name = "GarbageMan",
		new = function(): BenchmarkScope
			return GarbageMan.new("Benchmark")
		end,
		add = function(scope: BenchmarkScope, object: any, cleanupMethod: string?)
			scope:Add(object, cleanupMethod)
		end,
		connect = function(scope: BenchmarkScope, signal: any, callback: (...any) -> ()): any
			local connection = scope:Connect(signal, callback)
			return connection
		end,
		clean = function(scope: BenchmarkScope)
			scope:Clean()
		end,
		replace = function(scope: BenchmarkScope, tag: any, object: any, cleanupMethod: string?)
			scope:Replace(tag, object, cleanupMethod)
		end,
	}

	return adapter
end

local function tryRequireModule(moduleName: string): any?
	local child = ReplicatedStorage:FindFirstChild(moduleName)

	if child == nil or not child:IsA("ModuleScript") then
		return nil
	end

	local ok: boolean
	local result: any

	ok, result = pcall(require, child)

	if not ok then
		warn(`[GarbageManBenchmark] failed to require {moduleName}: {result}`)
		return nil
	end

	return result
end

local function makeTroveAdapter(): Adapter?
	local Trove = tryRequireModule("Trove")

	if Trove == nil or typeof(Trove.new) ~= "function" then
		return nil
	end

	local adapter: Adapter = {
		name = "Trove",
		new = function(): BenchmarkScope
			return Trove.new()
		end,
		add = function(scope: BenchmarkScope, object: any, cleanupMethod: string?)
			if cleanupMethod ~= nil then
				scope:Add(object, cleanupMethod)
				return
			end

			scope:Add(object)
		end,
		connect = function(scope: BenchmarkScope, signal: any, callback: (...any) -> ()): any
			local connection = scope:Connect(signal, callback)
			return connection
		end,
		clean = function(scope: BenchmarkScope)
			if typeof(scope.Clean) == "function" then
				scope:Clean()
				return
			end

			scope:Destroy()
		end,
		replace = nil,
	}

	return adapter
end

local function makeMaidAdapter(): Adapter?
	local Maid = tryRequireModule("Maid")

	if Maid == nil or typeof(Maid.new) ~= "function" then
		return nil
	end

	local adapter: Adapter = {
		name = "Maid",
		new = function(): BenchmarkScope
			return Maid.new()
		end,
		add = function(scope: BenchmarkScope, object: any, cleanupMethod: string?)
			if typeof(scope.Add) == "function" then
				if cleanupMethod ~= nil then
					scope:Add(object, cleanupMethod)
					return
				end

				scope:Add(object)
				return
			end

			scope:GiveTask(object)
		end,
		connect = function(scope: BenchmarkScope, signal: any, callback: (...any) -> ()): any
			local connection = signal:Connect(callback)

			if typeof(scope.Add) == "function" then
				scope:Add(connection)
			else
				scope:GiveTask(connection)
			end

			return connection
		end,
		clean = function(scope: BenchmarkScope)
			if typeof(scope.Clean) == "function" then
				scope:Clean()
			elseif typeof(scope.DoCleaning) == "function" then
				scope:DoCleaning()
			else
				scope:Destroy()
			end
		end,
		replace = nil,
	}

	return adapter
end

local function addAdapter(adapters: { Adapter }, adapter: Adapter?)
	if adapter == nil then
		return
	end

	table.insert(adapters, adapter)
end

local function runMeasured(callback: () -> ()): number
	local startedAt = os.clock()
	callback()

	local elapsed = os.clock() - startedAt
	return elapsed
end

local function printResult(
	adapterName: string,
	caseName: string,
	count: number,
	times: { number },
	memoryDeltas: { number }
)
	local median = getMedian(times)
	local best = getBest(times)
	local medianMs = median * 1000
	local bestMs = best * 1000
	local opsPerSecond = 0

	if median > 0 then
		opsPerSecond = count / median
	end

	local memoryMedian = getMedian(memoryDeltas)

	print(
		string.format(
			"[GarbageManBenchmark] %-10s | %-28s | n=%6d | median=%8.3f ms | best=%8.3f ms | ops/s=%10.0f | mem=%8.1f KB",
			adapterName,
			caseName,
			count,
			round(medianMs, 3),
			round(bestMs, 3),
			opsPerSecond,
			round(memoryMedian, 1)
		)
	)
end

local function runCase(
	adapter: Adapter,
	caseName: string,
	count: number,
	callback: (adapter: Adapter, count: number) -> ()
)
	callback(adapter, math.min(count, 100))
	task.wait()

	local times: { number } = {}
	local memoryDeltas: { number } = {}

	for runIndex = 1, RUNS do
		local beforeMemory = readMemoryKb()
		local elapsed = runMeasured(function()
			callback(adapter, count)
		end)
		local afterMemory = readMemoryKb()

		times[runIndex] = elapsed
		memoryDeltas[runIndex] = afterMemory - beforeMemory

		task.wait()
	end

	printResult(adapter.name, caseName, count, times, memoryDeltas)
end

local function caseAddFunctions(adapter: Adapter, count: number)
	local scope = adapter.new()

	for _ = 1, count do
		adapter.add(scope, function() end, nil)
	end

	adapter.clean(scope)
end

local function caseAddDestroyableTables(adapter: Adapter, count: number)
	local scope = adapter.new()

	for _ = 1, count do
		adapter.add(scope, makeDestroyable(), nil)
	end

	adapter.clean(scope)
end

local function caseConnections(adapter: Adapter, count: number)
	local event = Instance.new("BindableEvent")
	local scope = adapter.new()

	for _ = 1, count do
		adapter.connect(scope, event.Event, function() end)
	end

	adapter.clean(scope)
	event:Destroy()
end

local function caseTaggedReplace(adapter: Adapter, count: number)
	local replace = adapter.replace

	if replace == nil then
		return
	end

	local scope = adapter.new()

	for _ = 1, count do
		replace(scope, "Current", makeDestroyable(), "Destroy")
	end

	adapter.clean(scope)
end

local function caseTracebackCapture(_adapter: Adapter, count: number)
	GarbageMan.configure({
		captureAddTracebacks = true,
	})

	local scope = GarbageMan.new("TracebackBenchmark")

	for _ = 1, count do
		scope:Add(function() end)
	end

	scope:Clean()

	GarbageMan.configure({
		captureAddTracebacks = false,
	})
end

GarbageMan.configure({
	tracebacks = false,
	captureAddTracebacks = false,
	leakWarnings = false,
	profiling = false,
})

local adapters: { Adapter } = {}
addAdapter(adapters, makeRawAdapter())
addAdapter(adapters, makeGarbageManAdapter())
addAdapter(adapters, makeTroveAdapter())
addAdapter(adapters, makeMaidAdapter())

print("[GarbageManBenchmark] start")
print(`[GarbageManBenchmark] runs={RUNS} count={COUNT} connectionCount={CONNECTION_COUNT}`)
print("[GarbageManBenchmark] lower median is better; RawArray is a simple baseline, not a feature-equivalent library")

for _, adapter in adapters do
	runCase(adapter, "Add function + Clean", COUNT, caseAddFunctions)
	runCase(adapter, "Add Destroy table + Clean", COUNT, caseAddDestroyableTables)
	runCase(adapter, "Connect + Clean", CONNECTION_COUNT, caseConnections)

	if adapter.replace ~= nil then
		runCase(adapter, "Replace tag", REPLACE_COUNT, caseTaggedReplace)
	end
end

local garbageManAdapter = makeGarbageManAdapter()
runCase(garbageManAdapter, "Add traceback capture", TRACEBACK_COUNT, caseTracebackCapture)

GarbageMan.configure({
	tracebacks = false,
	captureAddTracebacks = false,
	leakWarnings = true,
	profiling = false,
})

print("[GarbageManBenchmark] done")
