--!strict

local RunService = game:GetService("RunService")

local Cleanup = require(script.Cleanup)
local Promise = require(script.Promise)

local tracebacksEnabled = false
local captureAddTracebacks = false
local leakWarningsEnabled = true
local profilingEnabled = false
local activeScopeRegistry: any = setmetatable({}, {
	__mode = "k",
})
local activeScopes: { [any]: boolean } = activeScopeRegistry
local DEFAULT_BATCH_SIZE = 50

export type ConnectionLike = {
	Connected: boolean?,
	Disconnect: (self: any) -> (),
}

export type SignalLike = {
	Connect: (self: any, callback: (...any) -> ...any) -> ConnectionLike,
	Once: ((self: any, callback: (...any) -> ...any) -> ConnectionLike)?,
}

export type PromiseLike = {
	getStatus: (self: any) -> string,
	["finally"]: (self: any, callback: (...any) -> ...any) -> any,
	cancel: (self: any) -> (),
}

export type Cancelable = {
	Cancel: (self: any) -> (),
}

export type Constructable<T> = { new: (...any) -> T } | ((...any) -> T)

export type Trackable =
	Instance
| RBXScriptConnection
| ConnectionLike
| PromiseLike
| thread
| ((...any) -> ...any)
| {
	Destroy: (self: any) -> (),
}
| {
	destroy: (self: any) -> (),
}
| {
	Disconnect: (self: any) -> (),
}
| {
	disconnect: (self: any) -> (),
}
| Cancelable
| {
	cancel: (self: any) -> (),
}
| {
	Clean: (self: any) -> (),
}
| {
	clean: (self: any) -> (),
}

type Entry = {
	object: any,
	cleanupMethod: any,
	tag: any?,
	addedTraceback: string?,
}

export type DebugEntry = {
	object: any,
	cleanupMethod: any,
	tag: any?,
	addedTraceback: string?,
}

export type DebugSummaryEntry = {
	objectType: string,
	cleanupMethod: string,
	tag: string,
	addedTraceback: string,
}

export type ScopeDebugSummary = {
	name: string,
	size: number,
	age: number,
	destroyed: boolean,
	cleaning: boolean,
	destroyReason: string,
	cleanupCount: number,
	lastCleanupDuration: number,
	peakCleanupDuration: number,
	lastCleanupError: string,
	lastFailedObjectType: string,
	lastFailedTag: string,
}

export type LifecycleCallback = (reason: any?) -> ()
export type LifecycleDisconnect = () -> ()

export type GarbageMan = {
	GetName: (self: GarbageMan) -> string,
	SetName: (self: GarbageMan, name: string) -> GarbageMan,
	GetDestroyReason: (self: GarbageMan) -> any?,
	Extend: (self: GarbageMan, name: string?) -> GarbageMan,
	Adopt: (self: GarbageMan, child: GarbageMan) -> GarbageMan,
	Copy: <T>(self: GarbageMan, instance: T & Instance) -> T,
	Construct: <T>(self: GarbageMan, class: Constructable<T>, ...any) -> T,
	Connect: (self: GarbageMan, signal: SignalLike | RBXScriptSignal, fn: (...any) -> ...any) -> ConnectionLike,
	Once: (self: GarbageMan, signal: SignalLike | RBXScriptSignal, fn: (...any) -> ...any) -> ConnectionLike,
	DestroyOnSignal: (self: GarbageMan, signal: SignalLike | RBXScriptSignal, reason: any?) -> ConnectionLike,
	ReplaceConnection: (
		self: GarbageMan,
		tag: any,
		signal: SignalLike | RBXScriptSignal,
		fn: (...any) -> ...any
	) -> ConnectionLike,
	Render: (self: GarbageMan, name: string, priority: number, fn: (dt: number) -> ()) -> (),
	AddPromise: <T>(self: GarbageMan, promise: T & PromiseLike) -> T,
	Add: <T>(self: GarbageMan, object: T & Trackable, cleanupMethod: string?, tag: any?) -> T,
	AddTemporary: <T>(
		self: GarbageMan,
		object: T & Trackable,
		seconds: number,
		cleanupMethod: string?,
		tag: any?
	) -> T,
	AddMany: (self: GarbageMan, ...any) -> GarbageMan,
	Replace: <T>(self: GarbageMan, tag: any, object: T & Trackable, cleanupMethod: string?) -> T,
	ReplaceTween: <T>(self: GarbageMan, tag: any, tween: T & Cancelable) -> T,
	Get: (self: GarbageMan, tag: any) -> any?,
	Contains: (self: GarbageMan, object: any) -> boolean,
	ContainsTag: (self: GarbageMan, tag: any) -> boolean,
	Remove: (self: GarbageMan, object: any) -> boolean,
	RemoveTag: (self: GarbageMan, tag: any) -> boolean,
	RemoveTagsWithPrefix: (self: GarbageMan, prefix: string) -> number,
	Drop: (self: GarbageMan, object: any) -> boolean,
	DropTag: (self: GarbageMan, tag: any) -> boolean,
	GetDebugDump: (self: GarbageMan) -> { DebugEntry },
	GetDebugSummary: (self: GarbageMan) -> { DebugSummaryEntry },
	GetLastCleanupError: (self: GarbageMan) -> any?,
	GetLastFailedEntry: (self: GarbageMan) -> DebugEntry?,
	GetTags: (self: GarbageMan) -> { any },
	AssertEmpty: (self: GarbageMan) -> (),
	Size: (self: GarbageMan) -> number,
	IsCleaning: (self: GarbageMan) -> boolean,
	IsDestroyed: (self: GarbageMan) -> boolean,
	WarnIfNotDestroyedAfter: (self: GarbageMan, seconds: number, message: string?) -> LifecycleDisconnect,
	CleanAfter: (self: GarbageMan, seconds: number) -> LifecycleDisconnect,
	DestroyAfter: (self: GarbageMan, seconds: number, reason: any?) -> LifecycleDisconnect,
	Clean: (self: GarbageMan) -> (),
	TryClean: (self: GarbageMan) -> (boolean, any),
	CleanDeferred: (self: GarbageMan) -> (),
	CleanBatched: (self: GarbageMan, batchSize: number?) -> (),
	WrapClean: (self: GarbageMan) -> () -> (),
	BindTo: (self: GarbageMan, instance: Instance) -> RBXScriptConnection,
	BindToAncestry: (self: GarbageMan, instance: Instance) -> RBXScriptConnection,
	OnDestroying: (self: GarbageMan, callback: LifecycleCallback) -> LifecycleDisconnect,
	OnDestroyed: (self: GarbageMan, callback: LifecycleCallback) -> LifecycleDisconnect,
	Destroy: (self: GarbageMan, reason: any?) -> (),
	TryDestroy: (self: GarbageMan, reason: any?) -> (boolean, any),
	DestroyDeferred: (self: GarbageMan, reason: any?) -> (),
	DestroyBatched: (self: GarbageMan, reason: any?, batchSize: number?) -> (),

	_name: string,
	_createdAt: number,
	_entries: { Entry },
	_indices: { [any]: number },
	_tags: { [any]: number },
	_dependents: { [any]: any },
	_parents: { [any]: any },
	_sweeping: boolean,
	_destroyed: boolean,
	_destroyReason: any?,
	_lastCleanupError: any?,
	_lastFailedEntry: DebugEntry?,
	_cleanupCount: number,
	_lastCleanupDuration: number,
	_peakCleanupDuration: number,
	_cleanDeferredQueued: boolean,
	_destroyingCallbacks: { LifecycleCallback },
	_destroyedCallbacks: { LifecycleCallback },
}

export type ErrorHandler = (message: any, scope: GarbageMan) -> ()

local errorHandler: ErrorHandler? = nil

export type Config = {
	tracebacks: boolean?,
	captureAddTracebacks: boolean?,
	leakWarnings: boolean?,
	profiling: boolean?,
	errorHandler: (ErrorHandler | false)?,
}

export type DebugModule = {
	getScopes: () -> { GarbageMan },
	getSummary: () -> { ScopeDebugSummary },
}

export type GarbageManModule = {
	new: (name: string?) -> GarbageMan,
	from: (instance: Instance, name: string?) -> GarbageMan,
	configure: (options: Config) -> (),
	getConfig: () -> Config,
	Debug: DebugModule,
}

type GarbageManInternal = GarbageMan & {
	_sweepObject: (self: GarbageManInternal, object: any, shouldRun: boolean) -> boolean,
	_sweepAt: (self: GarbageManInternal, index: number, shouldRun: boolean) -> boolean,
}

type CleanupFinishedCallback = (finished: boolean, message: any) -> ()

local GarbageManClass = {}
GarbageManClass.__index = GarbageManClass

local function normalizeName(name: string?): string
	if name == nil then
		return "GarbageMan"
	end

	if typeof(name) ~= "string" then
		error("GarbageMan name must be a string", 3)
	end

	if name == "" then
		return "GarbageMan"
	end

	return name
end

local function formatScopeLabel(self: GarbageManInternal): string
	if self._name == "GarbageMan" then
		return "GarbageMan"
	end

	return `GarbageMan "{self._name}"`
end

local function captureAddTraceback(): string?
	if not captureAddTracebacks then
		return nil
	end

	local traceback = debug.traceback("GarbageMan resource added here", 3)
	return traceback
end

local function describeObject(object: any): string
	local objectType = typeof(object)

	if objectType == "Instance" then
		local instance: Instance = object
		return `{instance.ClassName} "{instance.Name}"`
	end

	return objectType
end

local function createDebugEntry(entry: Entry): DebugEntry
	return {
		object = entry.object,
		cleanupMethod = entry.cleanupMethod,
		tag = entry.tag,
		addedTraceback = entry.addedTraceback,
	}
end

local function copyDebugEntry(entry: DebugEntry): DebugEntry
	return {
		object = entry.object,
		cleanupMethod = entry.cleanupMethod,
		tag = entry.tag,
		addedTraceback = entry.addedTraceback,
	}
end

local function registerScope(self: GarbageManInternal)
	activeScopes[self] = true
end

local function unregisterScope(self: GarbageManInternal)
	activeScopes[self] = nil
end

local function formatError(message: any): any
	if tracebacksEnabled then
		local traceback = debug.traceback(tostring(message), 2)
		return traceback
	end

	return message
end

local function reportAsyncError(self: GarbageManInternal, message: any)
	if errorHandler ~= nil then
		local handler = errorHandler
		local ok: boolean
		local handlerMessage: any

		ok, handlerMessage = xpcall(handler, formatError, message, self)

		if not ok then
			warn(handlerMessage)
		end

		return
	end

	error(message, 2)
end

local function assertMutable(self: GarbageManInternal, methodName: string)
	if self._destroyed then
		error(`cannot call GarbageMan:{methodName}() after Destroy`, 3)
	end

	if self._sweeping then
		error(`cannot call GarbageMan:{methodName}() while cleaning`, 3)
	end
end

local function runCleanup(entry: Entry): (boolean, any)
	local ok: boolean
	local message: any

	ok, message = xpcall(Cleanup.Run, formatError, entry.object, entry.cleanupMethod)

	return ok, message
end

local function storeCleanupFailure(self: GarbageManInternal, entry: Entry, message: any)
	self._lastCleanupError = message
	self._lastFailedEntry = createDebugEntry(entry)
end

local function beginCleanupProfile(): number
	if not profilingEnabled then
		return 0
	end

	local startedAt = os.clock()
	return startedAt
end

local function finishCleanupProfile(self: GarbageManInternal, startedAt: number)
	self._cleanupCount += 1

	if not profilingEnabled then
		return
	end

	local duration = os.clock() - startedAt

	self._lastCleanupDuration = duration

	if duration > self._peakCleanupDuration then
		self._peakCleanupDuration = duration
	end
end

local function detachEntries(self: GarbageManInternal): { Entry }
	local entries = self._entries

	self._entries = {}
	self._indices = {}
	self._tags = {}
	self._dependents = {}
	self._parents = {}

	return entries
end

local function sweepEntries(entries: { Entry }): (boolean, any, Entry?)
	local failed = false
	local firstError: any = nil
	local firstFailedEntry: Entry? = nil

	for index = #entries, 1, -1 do
		local entry = entries[index]

		if entry ~= nil then
			local ok: boolean
			local message: any

			ok, message = runCleanup(entry)

			if not ok and not failed then
				failed = true
				firstError = message
				firstFailedEntry = entry
			end
		end
	end

	return failed, firstError, firstFailedEntry
end

local function formatTagPreview(tags: { any }, limit: number): string
	local tagNames: { string } = {}
	local count = math.min(#tags, limit)

	for index = 1, count do
		table.insert(tagNames, tostring(tags[index]))
	end

	if #tags > limit then
		table.insert(tagNames, `+{#tags - limit} more`)
	end

	return table.concat(tagNames, ", ")
end

local function removeLifecycleCallback(callbacks: { LifecycleCallback }, callback: LifecycleCallback): boolean
	for index = 1, #callbacks do
		if callbacks[index] == callback then
			table.remove(callbacks, index)
			return true
		end
	end

	return false
end

local function createLifecycleDisconnect(
	callbacks: { LifecycleCallback },
	callback: LifecycleCallback
): LifecycleDisconnect
	local connected = true

	return function()
		if not connected then
			return
		end

		connected = false
		removeLifecycleCallback(callbacks, callback)
	end
end

local function runLifecycleCallbacks(callbacks: { LifecycleCallback }, reason: any?): (boolean, any)
	local pending: { LifecycleCallback } = {}
	local callbackCount = #callbacks

	for index = 1, callbackCount do
		pending[index] = callbacks[index]
		callbacks[index] = nil
	end

	local failed = false
	local firstError: any = nil

	for index = 1, callbackCount do
		local callback = pending[index]

		if callback ~= nil then
			local ok: boolean
			local message: any

			ok, message = xpcall(callback, formatError, reason)

			if not ok and not failed then
				failed = true
				firstError = message
			end
		end
	end

	return failed, firstError
end

local function addLifecycleCallback(
	self: GarbageManInternal,
	methodName: string,
	callbacks: { LifecycleCallback },
	callback: LifecycleCallback
): LifecycleDisconnect
	assertMutable(self, methodName)

	if typeof(callback) ~= "function" then
		error("GarbageMan lifecycle callback must be a function", 3)
	end

	table.insert(callbacks, callback)

	local disconnect = createLifecycleDisconnect(callbacks, callback)
	return disconnect
end

local function readBatchSize(batchSize: number?): number
	if batchSize == nil then
		return DEFAULT_BATCH_SIZE
	end

	if typeof(batchSize) ~= "number" or batchSize < 1 or batchSize ~= batchSize or batchSize == math.huge then
		error("batchSize must be a positive finite number", 3)
	end

	local normalized = math.floor(batchSize)
	return normalized
end

local function readDelaySeconds(seconds: number): number
	if typeof(seconds) ~= "number" or seconds < 0 or seconds ~= seconds or seconds == math.huge then
		error("seconds must be a non-negative finite number", 3)
	end

	return seconds
end

local function runBatchedCleanup(
	self: GarbageManInternal,
	entries: { Entry },
	batchSize: number,
	onFinished: CleanupFinishedCallback
)
	local startedAt = beginCleanupProfile()
	local index = #entries
	local failed = false
	local firstError: any = nil
	local firstFailedEntry: Entry? = nil

	local function complete()
		self._sweeping = false
		finishCleanupProfile(self, startedAt)

		if failed then
			if firstFailedEntry ~= nil then
				storeCleanupFailure(self, firstFailedEntry, firstError)
			else
				self._lastCleanupError = firstError
			end

			onFinished(false, firstError)
			return
		end

		onFinished(true, nil)
	end

	local function runBatch()
		local processed = 0

		while index >= 1 and processed < batchSize do
			local entry = entries[index]
			index -= 1
			processed += 1

			if entry ~= nil then
				local ok: boolean
				local message: any

				ok, message = runCleanup(entry)

				if not ok and not failed then
					failed = true
					firstError = message
					firstFailedEntry = entry
				end
			end
		end

		if index >= 1 then
			task.defer(runBatch)
			return
		end

		complete()
	end

	task.defer(runBatch)
end

local function sweepAllInternal(self: GarbageManInternal): (boolean, any)
	if self._sweeping then
		return true, nil
	end

	self._sweeping = true
	self._lastCleanupError = nil
	self._lastFailedEntry = nil

	local startedAt = beginCleanupProfile()
	local entries = detachEntries(self)

	local function runSweep(): (boolean, any, Entry?)
		return sweepEntries(entries)
	end

	local ok: boolean
	local failed: any
	local message: any
	local failedEntry: Entry?

	ok, failed, message, failedEntry = xpcall(runSweep, formatError)
	self._sweeping = false
	finishCleanupProfile(self, startedAt)

	if not ok then
		self._lastCleanupError = failed
		return false, failed
	end

	if failed then
		if failedEntry ~= nil then
			storeCleanupFailure(self, failedEntry, message)
		else
			self._lastCleanupError = message
		end

		return false, message
	end

	return true, nil
end

local function finishDestroy(self: GarbageManInternal): (boolean, any)
	local ok: boolean
	local message: any

	ok, message = sweepAllInternal(self)

	local destroyedFailed: boolean
	local destroyedMessage: any

	destroyedFailed, destroyedMessage = runLifecycleCallbacks(self._destroyedCallbacks, self._destroyReason)

	if not ok then
		return false, message
	end

	if destroyedFailed then
		return false, destroyedMessage
	end

	return true, nil
end

local function cleanTarget(self: GarbageManInternal)
	self:Clean()
end

local function destroyTarget(self: GarbageManInternal, reason: any?)
	self:Destroy(reason)
end

function GarbageManClass.new(name: string?): GarbageMan
	local self = setmetatable({
		_name = normalizeName(name),
		_createdAt = os.clock(),
		_entries = {},
		_indices = {},
		_tags = {},
		_dependents = {},
		_parents = {},
		_sweeping = false,
		_destroyed = false,
		_destroyReason = nil,
		_lastCleanupError = nil,
		_lastFailedEntry = nil,
		_cleanupCount = 0,
		_lastCleanupDuration = 0,
		_peakCleanupDuration = 0,
		_cleanDeferredQueued = false,
		_destroyingCallbacks = {},
		_destroyedCallbacks = {},
	}, GarbageManClass)

	local garbageMan: any = self
	registerScope(garbageMan)
	return garbageMan
end

function GarbageManClass._sweepAt(self: GarbageManInternal, index: number, shouldRun: boolean): boolean
	local entries = self._entries
	local entry = entries[index]

	if entry == nil then
		return false
	end

	local lastIndex = #entries
	local lastEntry = entries[lastIndex]

	entries[index] = lastEntry
	entries[lastIndex] = nil

	self._indices[entry.object] = nil

	if entry.tag ~= nil then
		self._tags[entry.tag] = nil
	end

	if index ~= lastIndex and lastEntry ~= nil then
		self._indices[lastEntry.object] = index

		if lastEntry.tag ~= nil then
			self._tags[lastEntry.tag] = index
		end
	end

	local dependent = self._dependents[entry.object]

	if dependent ~= nil then
		self._dependents[entry.object] = nil
		self._parents[dependent] = nil

		local dependentIndex = self._indices[dependent]

		if dependentIndex ~= nil then
			self:_sweepAt(dependentIndex, false)
		end
	end

	local parent = self._parents[entry.object]

	if parent ~= nil then
		self._parents[entry.object] = nil

		if self._dependents[parent] == entry.object then
			self._dependents[parent] = nil
		end
	end

	if shouldRun then
		self._lastCleanupError = nil
		self._lastFailedEntry = nil

		local ok: boolean
		local message: any

		ok, message = runCleanup(entry)

		if not ok then
			storeCleanupFailure(self, entry, message)
			error(message, 3)
		end
	end

	return true
end

function GarbageManClass._sweepObject(self: GarbageManInternal, object: any, shouldRun: boolean): boolean
	local index = self._indices[object]

	if index == nil then
		return false
	end

	return self:_sweepAt(index, shouldRun)
end

function GarbageManClass.GetName(self: GarbageManInternal): string
	local name = self._name
	return name
end

function GarbageManClass.SetName(self: GarbageManInternal, name: string): GarbageMan
	assertMutable(self, "SetName")

	self._name = normalizeName(name)

	local scope: any = self
	return scope
end

function GarbageManClass.GetDestroyReason(self: GarbageManInternal): any?
	local reason = self._destroyReason
	return reason
end

local function collect<T>(
	self: GarbageManInternal,
	object: T & Trackable,
	cleanupMethod: string?,
	tag: any?
): T
	local cleanup = Cleanup.Resolve(object, cleanupMethod)
	local objectIndex = self._indices[object]
	local addedTraceback = captureAddTraceback()

	if tag ~= nil then
		local tagIndex = self._tags[tag]

		if tagIndex ~= nil and tagIndex ~= objectIndex then
			self:_sweepAt(tagIndex, true)
			objectIndex = self._indices[object]
		end
	end

	if objectIndex ~= nil then
		local entry = self._entries[objectIndex]

		if entry.tag ~= nil then
			self._tags[entry.tag] = nil
		end

		entry.cleanupMethod = cleanup
		entry.tag = tag
		entry.addedTraceback = addedTraceback

		if tag ~= nil then
			self._tags[tag] = objectIndex
		end

		return object
	end

	local index = #self._entries + 1
	self._entries[index] = {
		object = object,
		cleanupMethod = cleanup,
		tag = tag,
		addedTraceback = addedTraceback,
	}

	self._indices[object] = index

	if tag ~= nil then
		self._tags[tag] = index
	end

	return object
end

function GarbageManClass.Add<T>(
	self: GarbageManInternal,
	object: T & Trackable,
	cleanupMethod: string?,
	tag: any?
): T
	assertMutable(self, "Add")

	local added = collect(self, object, cleanupMethod, tag)
	return added
end

function GarbageManClass.AddTemporary<T>(
	self: GarbageManInternal,
	object: T & Trackable,
	seconds: number,
	cleanupMethod: string?,
	tag: any?
): T
	assertMutable(self, "AddTemporary")

	local delaySeconds = readDelaySeconds(seconds)
	local added = collect(self, object, cleanupMethod, tag)

	local function removeTemporary()
		if self._destroyed or self._sweeping then
			return
		end

		local ok: boolean
		local message: any

		ok, message = xpcall(function()
			self:Remove(added)
		end, formatError)

		if not ok then
			reportAsyncError(self, message)
		end
	end

	task.delay(delaySeconds, removeTemporary)

	return added
end

function GarbageManClass.AddMany(self: GarbageManInternal, ...: any): GarbageMan
	assertMutable(self, "AddMany")

	local count = select("#", ...)

	for index = 1, count do
		local object = select(index, ...)
		collect(self, object, nil, nil)
	end

	local scope: any = self
	return scope
end

function GarbageManClass.Replace<T>(
	self: GarbageManInternal,
	tag: any,
	object: T & Trackable,
	cleanupMethod: string?
): T
	assert(tag ~= nil, "GarbageMan tag cannot be nil")
	assertMutable(self, "Replace")

	local replaced = collect(self, object, cleanupMethod, tag)
	return replaced
end

function GarbageManClass.ReplaceTween<T>(self: GarbageManInternal, tag: any, tween: T & Cancelable): T
	assert(tag ~= nil, "GarbageMan tag cannot be nil")
	assertMutable(self, "ReplaceTween")

	local replaced = collect(self, tween, "Cancel", tag)
	return replaced
end

function GarbageManClass.Get(self: GarbageManInternal, tag: any): any?
	local index = self._tags[tag]
	local entry = if index ~= nil then self._entries[index] else nil

	if entry ~= nil then
		return entry.object
	end

	return nil
end

function GarbageManClass.Contains(self: GarbageManInternal, object: any): boolean
	local contains = self._indices[object] ~= nil
	return contains
end

function GarbageManClass.ContainsTag(self: GarbageManInternal, tag: any): boolean
	local contains = self._tags[tag] ~= nil
	return contains
end

function GarbageManClass.Remove(self: GarbageManInternal, object: any): boolean
	assertMutable(self, "Remove")
	local didRemove = self:_sweepObject(object, true)
	return didRemove
end

function GarbageManClass.RemoveTag(self: GarbageManInternal, tag: any): boolean
	assertMutable(self, "RemoveTag")

	local index = self._tags[tag]

	if index == nil then
		return false
	end

	local didRemove = self:_sweepAt(index, true)
	return didRemove
end

function GarbageManClass.RemoveTagsWithPrefix(self: GarbageManInternal, prefix: string): number
	assertMutable(self, "RemoveTagsWithPrefix")

	local tags: { any } = {}

	for tag in self._tags do
		if typeof(tag) == "string" and string.sub(tag, 1, #prefix) == prefix then
			table.insert(tags, tag)
		end
	end

	local removed = 0

	for _, tag in tags do
		if self:RemoveTag(tag) then
			removed += 1
		end
	end

	return removed
end

function GarbageManClass.Drop(self: GarbageManInternal, object: any): boolean
	assertMutable(self, "Drop")
	local didDrop = self:_sweepObject(object, false)
	return didDrop
end

function GarbageManClass.DropTag(self: GarbageManInternal, tag: any): boolean
	assertMutable(self, "DropTag")

	local index = self._tags[tag]

	if index == nil then
		return false
	end

	local didDrop = self:_sweepAt(index, false)
	return didDrop
end

function GarbageManClass.GetDebugDump(self: GarbageManInternal): { DebugEntry }
	local dump: { DebugEntry } = {}

	for index, entry in self._entries do
		dump[index] = createDebugEntry(entry)
	end

	return dump
end

function GarbageManClass.GetDebugSummary(self: GarbageManInternal): { DebugSummaryEntry }
	local summary: { DebugSummaryEntry } = {}

	for index, entry in self._entries do
		summary[index] = {
			objectType = describeObject(entry.object),
			cleanupMethod = tostring(entry.cleanupMethod),
			tag = if entry.tag ~= nil then tostring(entry.tag) else "",
			addedTraceback = entry.addedTraceback or "",
		}
	end

	return summary
end

function GarbageManClass.GetLastCleanupError(self: GarbageManInternal): any?
	local cleanupError = self._lastCleanupError
	return cleanupError
end

function GarbageManClass.GetLastFailedEntry(self: GarbageManInternal): DebugEntry?
	local failedEntry = self._lastFailedEntry

	if failedEntry == nil then
		return nil
	end

	local entry = copyDebugEntry(failedEntry)
	return entry
end

function GarbageManClass.GetTags(self: GarbageManInternal): { any }
	local tags: { any } = {}

	for tag in self._tags do
		table.insert(tags, tag)
	end

	return tags
end

function GarbageManClass.AssertEmpty(self: GarbageManInternal)
	local size = #self._entries

	if size == 0 then
		return
	end

	local tags = self:GetTags()
	local tagCount = #tags
	local scopeLabel = formatScopeLabel(self)

	if tagCount == 0 then
		error(`{scopeLabel} still has {size} entries`, 2)
	end

	local tagPreview = formatTagPreview(tags, 5)
	error(`{scopeLabel} still has {size} entries. Tags: {tagPreview}`, 2)
end

function GarbageManClass.Size(self: GarbageManInternal): number
	return #self._entries
end

function GarbageManClass.IsCleaning(self: GarbageManInternal): boolean
	local cleaning = self._sweeping
	return cleaning
end

function GarbageManClass.IsDestroyed(self: GarbageManInternal): boolean
	local destroyed = self._destroyed
	return destroyed
end

function GarbageManClass.WarnIfNotDestroyedAfter(
	self: GarbageManInternal,
	seconds: number,
	message: string?
): LifecycleDisconnect
	local delaySeconds = readDelaySeconds(seconds)

	if message ~= nil and typeof(message) ~= "string" then
		error("message must be a string", 2)
	end

	local cancelled = false

	local function runLeakWarning()
		if cancelled or self._destroyed or not leakWarningsEnabled then
			return
		end

		local warningMessage = message

		if warningMessage == nil then
			local scopeLabel = formatScopeLabel(self)
			warningMessage = `{scopeLabel} leak warning: still alive after {seconds} seconds with {#self._entries} resources`
		end

		warn(warningMessage)
	end

	task.delay(delaySeconds, runLeakWarning)

	return function()
		cancelled = true
	end
end

function GarbageManClass.CleanAfter(self: GarbageManInternal, seconds: number): LifecycleDisconnect
	local delaySeconds = readDelaySeconds(seconds)
	local cancelled = false

	local function runDelayedClean()
		if cancelled or self._destroyed then
			return
		end

		local ok: boolean
		local message: any

		ok, message = self:TryClean()

		if not ok then
			reportAsyncError(self, message)
		end
	end

	task.delay(delaySeconds, runDelayedClean)

	return function()
		cancelled = true
	end
end

function GarbageManClass.DestroyAfter(
	self: GarbageManInternal,
	seconds: number,
	reason: any?
): LifecycleDisconnect
	local delaySeconds = readDelaySeconds(seconds)
	local cancelled = false

	local function runDelayedDestroy()
		if cancelled or self._destroyed then
			return
		end

		local ok: boolean
		local message: any

		ok, message = self:TryDestroy(reason)

		if not ok then
			reportAsyncError(self, message)
		end
	end

	task.delay(delaySeconds, runDelayedDestroy)

	return function()
		cancelled = true
	end
end

function GarbageManClass.Copy<T>(self: GarbageManInternal, instance: T & Instance): T
	assertMutable(self, "Copy")
	local clone = instance:Clone()
	local collected = collect(self, clone, nil, nil)
	local copied: any = collected
	return copied
end

function GarbageManClass.Construct<T>(
	self: GarbageManInternal,
	class: Constructable<T>,
	...: any
): T
	assertMutable(self, "Construct")

	local classType = typeof(class)
	local object

	if classType == "table" then
		local classAny: any = class
		object = classAny.new(...)
	elseif classType == "function" then
		local constructor: any = class
		object = constructor(...)
	else
		error(`cannot construct from type {classType}`, 2)
	end

	local collected = collect(self, object, nil, nil)
	return collected
end

function GarbageManClass.Extend(self: GarbageManInternal, name: string?): GarbageMan
	assertMutable(self, "Extend")

	local childSegment = if name ~= nil then normalizeName(name) else "Child"
	local childName = `{self._name}:{childSegment}`
	local child = GarbageManClass.new(childName)
	local trackable: any = child

	self:Add(trackable, "Destroy")

	return child
end

function GarbageManClass.Adopt(self: GarbageManInternal, child: GarbageMan): GarbageMan
	assertMutable(self, "Adopt")

	local trackable: any = child
	collect(self, trackable, "Destroy", nil)

	return child
end

function GarbageManClass.Connect(
	self: GarbageManInternal,
	signal: SignalLike | RBXScriptSignal,
	fn: (...any) -> ...any
): any
	assertMutable(self, "Connect")

	local signalAny: any = signal
	local connection = signalAny:Connect(fn)
	local collected = collect(self, connection, nil, nil)
	return collected
end

function GarbageManClass.Once(
	self: GarbageManInternal,
	signal: SignalLike | RBXScriptSignal,
	fn: (...any) -> ...any
): any
	assertMutable(self, "Once")

	local signalAny: any = signal
	local once = signalAny.Once

	if typeof(once) == "function" then
		local connection = signalAny:Once(fn)
		local collected = collect(self, connection, nil, nil)
		return collected
	end

	local connection: any = nil
	connection = signalAny:Connect(function(...)
		if connection ~= nil then
			local current = connection
			connection = nil

			if self._destroyed or self._sweeping then
				current:Disconnect()
			else
				self:Remove(current)
			end
		end

		fn(...)
	end)

	local collected = collect(self, connection, nil, nil)
	return collected
end

function GarbageManClass.DestroyOnSignal(
	self: GarbageManInternal,
	signal: SignalLike | RBXScriptSignal,
	reason: any?
): any
	assertMutable(self, "DestroyOnSignal")

	local function onSignal()
		local ok: boolean
		local message: any

		ok, message = self:TryDestroy(reason)

		if not ok then
			reportAsyncError(self, message)
		end
	end

	local connection = self:Once(signal, onSignal)
	return connection
end

function GarbageManClass.ReplaceConnection(
	self: GarbageManInternal,
	tag: any,
	signal: SignalLike | RBXScriptSignal,
	fn: (...any) -> ...any
): any
	assert(tag ~= nil, "GarbageMan tag cannot be nil")
	assertMutable(self, "ReplaceConnection")

	local signalAny: any = signal
	local connection = signalAny:Connect(fn)
	local collected = collect(self, connection, nil, tag)
	return collected
end

function GarbageManClass.Render(
	self: GarbageManInternal,
	name: string,
	priority: number,
	fn: (dt: number) -> ()
)
	assertMutable(self, "Render")

	if not RunService:IsClient() then
		error("GarbageMan:Render() can only be used on the client", 2)
	end

	local tag = `RenderStep:{name}`
	self:RemoveTag(tag)
	RunService:BindToRenderStep(name, priority, fn)

	collect(self, function()
		RunService:UnbindFromRenderStep(name)
	end, nil, tag)
end

function GarbageManClass.AddPromise<T>(self: GarbageManInternal, promise: T & PromiseLike): T
	assertMutable(self, "AddPromise")
	Promise.AssertLike(promise)

	if Promise.IsStarted(promise) then
		collect(self, promise, "cancel", nil)

		local promiseAny: any = promise
		local cleanupPromise: any = nil

		cleanupPromise = promiseAny["finally"](promiseAny, function()
			if self._sweeping then
				return
			end

			self:_sweepObject(promise, false)

			if cleanupPromise ~= nil then
				self:_sweepObject(cleanupPromise, false)
			end
		end)

		if cleanupPromise ~= nil and cleanupPromise ~= promise and Promise.IsLike(cleanupPromise) then
			if Promise.IsStarted(cleanupPromise) then
				collect(self, cleanupPromise, "cancel", nil)
				self._dependents[promise] = cleanupPromise
				self._parents[cleanupPromise] = promise
			end
		end
	end

	local result: T = promise
	return result
end

function GarbageManClass.BindTo(self: GarbageManInternal, instance: Instance): RBXScriptConnection
	assertMutable(self, "BindTo")

	local function onDestroying()
		self:Destroy()
	end

	local connection = instance.Destroying:Connect(onDestroying)
	collect(self, connection, nil, nil)

	return connection
end

function GarbageManClass.BindToAncestry(self: GarbageManInternal, instance: Instance): RBXScriptConnection
	assertMutable(self, "BindToAncestry")

	local function onAncestryChanged(_child: Instance, parent: Instance?)
		if parent == nil then
			self:Destroy()
		end
	end

	local connection = instance.AncestryChanged:Connect(onAncestryChanged)
	collect(self, connection, nil, nil)

	return connection
end

local function cleanScope(self: GarbageManInternal)
	local ok: boolean
	local message: any

	ok, message = sweepAllInternal(self)

	if not ok then
		error(message, 2)
	end
end

function GarbageManClass.Clean(self: GarbageManInternal)
	if self._destroyed then
		return
	end

	cleanScope(self)
end

function GarbageManClass.TryClean(self: GarbageManInternal): (boolean, any)
	local ok: boolean
	local message: any

	ok, message = xpcall(cleanTarget, formatError, self)

	return ok, message
end

function GarbageManClass.CleanDeferred(self: GarbageManInternal)
	if self._destroyed or self._sweeping or self._cleanDeferredQueued then
		return
	end

	self._cleanDeferredQueued = true

	local function runDeferredClean()
		self._cleanDeferredQueued = false

		if self._destroyed or self._sweeping then
			return
		end

		self:Clean()
	end

	task.defer(runDeferredClean)
end

function GarbageManClass.CleanBatched(self: GarbageManInternal, batchSize: number?)
	if self._destroyed or self._sweeping then
		return
	end

	local size = readBatchSize(batchSize)

	self._sweeping = true
	self._lastCleanupError = nil
	self._lastFailedEntry = nil

	local entries = detachEntries(self)

	local function onFinished(finished: boolean, message: any)
		if finished then
			return
		end

		reportAsyncError(self, message)
	end

	runBatchedCleanup(self, entries, size, onFinished)
end

function GarbageManClass.WrapClean(self: GarbageManInternal): () -> ()
	return function()
		self:Clean()
	end
end

function GarbageManClass.OnDestroying(
	self: GarbageManInternal,
	callback: LifecycleCallback
): LifecycleDisconnect
	local disconnect = addLifecycleCallback(self, "OnDestroying", self._destroyingCallbacks, callback)
	return disconnect
end

function GarbageManClass.OnDestroyed(
	self: GarbageManInternal,
	callback: LifecycleCallback
): LifecycleDisconnect
	local disconnect = addLifecycleCallback(self, "OnDestroyed", self._destroyedCallbacks, callback)
	return disconnect
end

function GarbageManClass.Destroy(self: GarbageManInternal, reason: any?)
	if self._destroyed then
		return
	end

	self._destroyed = true
	self._destroyReason = reason

	local destroyingFailed: boolean
	local destroyingMessage: any

	destroyingFailed, destroyingMessage = runLifecycleCallbacks(self._destroyingCallbacks, reason)

	local finished: boolean
	local finishMessage: any

	finished, finishMessage = finishDestroy(self)
	unregisterScope(self)

	if destroyingFailed then
		error(destroyingMessage, 2)
	end

	if not finished then
		error(finishMessage, 2)
	end
end

function GarbageManClass.TryDestroy(self: GarbageManInternal, reason: any?): (boolean, any)
	local ok: boolean
	local message: any

	ok, message = xpcall(destroyTarget, formatError, self, reason)

	return ok, message
end

function GarbageManClass.DestroyDeferred(self: GarbageManInternal, reason: any?)
	if self._destroyed then
		return
	end

	self._destroyed = true
	self._destroyReason = reason

	local destroyingFailed: boolean
	local destroyingMessage: any

	destroyingFailed, destroyingMessage = runLifecycleCallbacks(self._destroyingCallbacks, reason)

	local function runDeferredDestroy()
		local finished: boolean
		local finishMessage: any

		finished, finishMessage = finishDestroy(self)
		unregisterScope(self)

		if not finished then
			reportAsyncError(self, finishMessage)
		end
	end

	task.defer(runDeferredDestroy)

	if destroyingFailed then
		error(destroyingMessage, 2)
	end
end

function GarbageManClass.DestroyBatched(self: GarbageManInternal, reason: any?, batchSize: number?)
	if self._destroyed then
		return
	end

	if self._sweeping then
		error("cannot call GarbageMan:DestroyBatched() while cleaning", 2)
	end

	local size = readBatchSize(batchSize)

	self._destroyed = true
	self._destroyReason = reason

	local destroyingFailed: boolean
	local destroyingMessage: any

	destroyingFailed, destroyingMessage = runLifecycleCallbacks(self._destroyingCallbacks, reason)

	self._sweeping = true
	self._lastCleanupError = nil
	self._lastFailedEntry = nil

	local entries = detachEntries(self)

	local function onFinished(finished: boolean, message: any)
		local destroyedFailed: boolean
		local destroyedMessage: any

		destroyedFailed, destroyedMessage = runLifecycleCallbacks(self._destroyedCallbacks, self._destroyReason)
		unregisterScope(self)

		if not finished then
			reportAsyncError(self, message)
		end

		if destroyedFailed then
			reportAsyncError(self, destroyedMessage)
		end
	end

	runBatchedCleanup(self, entries, size, onFinished)

	if destroyingFailed then
		error(destroyingMessage, 2)
	end
end

local function fromInstance(instance: Instance, name: string?): GarbageMan
	local scopeName = if name ~= nil then name else instance.Name
	local garbageMan = GarbageManClass.new(scopeName)
	garbageMan:BindTo(instance)
	return garbageMan
end

local Debug = {}

function Debug.getScopes(): { GarbageMan }
	local scopes: { GarbageMan } = {}

	for scope in activeScopes do
		table.insert(scopes, scope)
	end

	return scopes
end

function Debug.getSummary(): { ScopeDebugSummary }
	local summary: { ScopeDebugSummary } = {}

	for scope in activeScopes do
		local scopeInternal: GarbageManInternal = scope
		local age = os.clock() - scopeInternal._createdAt
		local lastCleanupError = ""
		local lastFailedEntry = scopeInternal._lastFailedEntry
		local lastFailedObjectType = ""
		local lastFailedTag = ""

		if scopeInternal._lastCleanupError ~= nil then
			lastCleanupError = tostring(scopeInternal._lastCleanupError)
		end

		if lastFailedEntry ~= nil then
			lastFailedObjectType = describeObject(lastFailedEntry.object)

			if lastFailedEntry.tag ~= nil then
				lastFailedTag = tostring(lastFailedEntry.tag)
			end
		end

		table.insert(summary, {
			name = scopeInternal._name,
			size = #scopeInternal._entries,
			age = age,
			destroyed = scopeInternal._destroyed,
			cleaning = scopeInternal._sweeping,
			destroyReason = if scopeInternal._destroyReason ~= nil then tostring(scopeInternal._destroyReason) else "",
			cleanupCount = scopeInternal._cleanupCount,
			lastCleanupDuration = scopeInternal._lastCleanupDuration,
			peakCleanupDuration = scopeInternal._peakCleanupDuration,
			lastCleanupError = lastCleanupError,
			lastFailedObjectType = lastFailedObjectType,
			lastFailedTag = lastFailedTag,
		})
	end

	return summary
end

local function readConfigBoolean(value: any, key: string): boolean
	if typeof(value) ~= "boolean" then
		error(`GarbageMan config.{key} must be a boolean`, 3)
	end

	return value
end

local function asConfig(value: any): Config
	local result: Config = value
	return result
end

local function asErrorHandler(value: any): ErrorHandler
	local result: ErrorHandler = value
	return result
end

local module = {
	new = GarbageManClass.new,
	from = fromInstance,
	Debug = Debug,
}

function module.configure(options: Config)
	if typeof(options) ~= "table" then
		error("GarbageMan config must be a table", 2)
	end

	local tracebacks = options.tracebacks
	local shouldCaptureAddTracebacks = options.captureAddTracebacks
	local shouldWarnLeaks = options.leakWarnings
	local shouldProfile = options.profiling
	local handler = options.errorHandler

	if tracebacks ~= nil then
		tracebacksEnabled = readConfigBoolean(tracebacks, "tracebacks")
	end

	if shouldCaptureAddTracebacks ~= nil then
		captureAddTracebacks = readConfigBoolean(shouldCaptureAddTracebacks, "captureAddTracebacks")
	end

	if shouldWarnLeaks ~= nil then
		leakWarningsEnabled = readConfigBoolean(shouldWarnLeaks, "leakWarnings")
	end

	if shouldProfile ~= nil then
		profilingEnabled = readConfigBoolean(shouldProfile, "profiling")
	end

	if handler ~= nil then
		if handler == false then
			errorHandler = nil
		elseif typeof(handler) == "function" then
			local nextHandler = asErrorHandler(handler)
			errorHandler = nextHandler
		else
			error("GarbageMan config.errorHandler must be a function or false", 2)
		end
	end
end

function module.getConfig(): Config
	local currentConfig = {
		tracebacks = tracebacksEnabled,
		captureAddTracebacks = captureAddTracebacks,
		leakWarnings = leakWarningsEnabled,
		profiling = profilingEnabled,
		errorHandler = errorHandler,
	}

	return asConfig(currentConfig)
end

local exported: GarbageManModule = module
return exported
