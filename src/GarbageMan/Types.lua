--!strict

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

export type Destroyable = {
	Destroy: (self: any) -> (),
}

export type DestroyableLowercase = {
	destroy: (self: any) -> (),
}

export type Disconnectable = {
	Disconnect: (self: any) -> (),
}

export type DisconnectableLowercase = {
	disconnect: (self: any) -> (),
}

export type Cancelable = {
	Cancel: (self: any) -> (),
}

export type CancelableLowercase = {
	cancel: (self: any) -> (),
}

export type Cleanable = {
	Clean: (self: any) -> (),
}

export type CleanableLowercase = {
	clean: (self: any) -> (),
}

export type Trackable =
	Instance
| RBXScriptConnection
| ConnectionLike
| PromiseLike
| thread
| ((...any) -> ...any)
| Destroyable
| DestroyableLowercase
| Disconnectable
| DisconnectableLowercase
| Cancelable
| CancelableLowercase
| Cleanable
| CleanableLowercase

export type Constructable<T> = { new: (...any) -> T } | ((...any) -> T)

export type Entry = {
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
	Render: (self: GarbageMan, name: string, priority: number, fn: (dt: number) -> ()) -> (),
	AddPromise: <T>(self: GarbageMan, promise: T & PromiseLike) -> T,
	Add: <T>(self: GarbageMan, object: T & Trackable, cleanupMethod: string?, tag: any?) -> T,
	Replace: <T>(self: GarbageMan, tag: any, object: T & Trackable, cleanupMethod: string?) -> T,
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
	Clean: (self: GarbageMan) -> (),
	TryClean: (self: GarbageMan) -> (boolean, any),
	CleanDeferred: (self: GarbageMan) -> (),
	WrapClean: (self: GarbageMan) -> () -> (),
	BindTo: (self: GarbageMan, instance: Instance) -> RBXScriptConnection,
	BindToAncestry: (self: GarbageMan, instance: Instance) -> RBXScriptConnection,
	OnDestroying: (self: GarbageMan, callback: LifecycleCallback) -> LifecycleDisconnect,
	OnDestroyed: (self: GarbageMan, callback: LifecycleCallback) -> LifecycleDisconnect,
	Destroy: (self: GarbageMan, reason: any?) -> (),
	TryDestroy: (self: GarbageMan, reason: any?) -> (boolean, any),
	DestroyDeferred: (self: GarbageMan, reason: any?) -> (),

	_name: string,
	_createdAt: number,
	_entries: { Entry },
	_indices: { [any]: number },
	_tags: { [any]: number },
	_dependents: { [any]: any },
	_parents: { [any]: any },
	_sweeping: boolean,
	_destroyed: boolean,
	_cleanDeferredQueued: boolean,
	_destroyReason: any?,
	_lastCleanupError: any?,
	_lastFailedEntry: DebugEntry?,
	_destroyingCallbacks: { LifecycleCallback },
	_destroyedCallbacks: { LifecycleCallback },
}

export type ErrorHandler = (message: any, scope: GarbageMan) -> ()

export type Config = {
	tracebacks: boolean?,
	captureAddTracebacks: boolean?,
	leakWarnings: boolean?,
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

return {}
