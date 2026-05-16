--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GarbageMan = require(ReplicatedStorage:WaitForChild("GarbageMan"))

type TestCallback = () -> ()
type TestNode = (name: string, callback: TestCallback) -> ()
type Expectation = {
	to: {
		equal: (expected: any) -> (),
	},
}
type Expect = (actual: any) -> Expectation

local env: any = getfenv()
local describe: TestNode = env.describe
local it: TestNode = env.it
local expect: Expect = env.expect

return function()
	describe("GarbageMan API helpers", function()
		it("supports Add, Replace, and Get helpers", function()
			local garbageMan = GarbageMan.new()
			local first: any = {
				cleaned = false,
				Destroy = function(self: any)
					self.cleaned = true
				end,
			}
			local second: any = {
				cleaned = false,
				Destroy = function(self: any)
					self.cleaned = true
				end,
			}

			garbageMan:Add(first, "Destroy", "Current")

			garbageMan:Replace("Current", second, "Destroy")

			expect(first.cleaned).to.equal(true)
			expect(garbageMan:Get("Current")).to.equal(second)

			garbageMan:Clean()

			expect(second.cleaned).to.equal(true)
		end)

		it("constructs resources through constructor helpers", function()
			local garbageMan = GarbageMan.new()

			local function makeObject(name: any): any
				return {
					name = name,
					destroyed = false,
					Destroy = function(self: any)
						self.destroyed = true
					end,
				}
			end

			local constructed: any = garbageMan:Construct(makeObject, "Tool")

			expect(constructed.name).to.equal("Tool")

			garbageMan:Destroy()

			expect(constructed.destroyed).to.equal(true)
		end)

		it("adds many resources with default cleanup", function()
			local garbageMan = GarbageMan.new()
			local cleaned = 0

			local function firstCleanup()
				cleaned += 1
			end

			local function secondCleanup()
				cleaned += 1
			end

			local function thirdCleanup()
				cleaned += 1
			end

			expect(garbageMan:AddMany(firstCleanup, secondCleanup, thirdCleanup)).to.equal(garbageMan)
			expect(garbageMan:Size()).to.equal(3)

			garbageMan:Clean()

			expect(cleaned).to.equal(3)
		end)

		it("cleans temporary resources after their delay", function()
			local garbageMan = GarbageMan.new("TemporaryResource")
			local cleaned = false

			local function cleanupTemporary()
				cleaned = true
			end

			local temporary = garbageMan:AddTemporary(cleanupTemporary, 0, nil, "Trail")

			expect(garbageMan:Contains(temporary)).to.equal(true)
			expect(garbageMan:ContainsTag("Trail")).to.equal(true)

			task.wait()

			expect(cleaned).to.equal(true)
			expect(garbageMan:IsDestroyed()).to.equal(false)
			expect(garbageMan:Size()).to.equal(0)
			expect(garbageMan:ContainsTag("Trail")).to.equal(false)

			garbageMan:Destroy()
		end)

		it("does not remove replacement resources after a temporary tag is reused", function()
			local garbageMan = GarbageMan.new("TemporaryReplacement")
			local firstCleaned = false
			local secondCleaned = false

			local function cleanupFirst()
				firstCleaned = true
			end

			local function cleanupSecond()
				secondCleaned = true
			end

			garbageMan:AddTemporary(cleanupFirst, 0, nil, "Effect")
			garbageMan:Replace("Effect", cleanupSecond)

			expect(firstCleaned).to.equal(true)
			expect(secondCleaned).to.equal(false)
			expect(garbageMan:ContainsTag("Effect")).to.equal(true)

			task.wait()

			expect(secondCleaned).to.equal(false)
			expect(garbageMan:Size()).to.equal(1)

			garbageMan:Destroy()

			expect(secondCleaned).to.equal(true)
		end)

		it("does not run temporary cleanup twice after destroy", function()
			local garbageMan = GarbageMan.new("DestroyedTemporary")
			local cleanedCount = 0

			local function cleanupTemporary()
				cleanedCount += 1
			end

			garbageMan:AddTemporary(cleanupTemporary, 0)
			garbageMan:Destroy()

			task.wait()

			expect(cleanedCount).to.equal(1)
			expect(garbageMan:Size()).to.equal(0)
		end)

		it("connects signals and supports one-shot fallback connections", function()
			local garbageMan = GarbageMan.new()
			local callbacks: { any } = {}
			local disconnects = 0
			local signal: any = {}

			function signal:Connect(callback)
				table.insert(callbacks, callback)

				local connection: any = {
					Connected = true,
				}

				function connection:Disconnect()
					self.Connected = false
					disconnects += 1
				end

				return connection
			end

			local connectedCount = 0
			local onceCount = 0

			local function onConnected()
				connectedCount += 1
			end

			local connection = garbageMan:Connect(signal, onConnected)

			callbacks[1]()

			expect(connectedCount).to.equal(1)
			expect(connection.Connected).to.equal(true)

			local onceConnection = garbageMan:Once(signal, function()
				onceCount += 1
			end)

			callbacks[2]()

			expect(onceCount).to.equal(1)
			expect(onceConnection.Connected).to.equal(false)
			expect(garbageMan:Contains(onceConnection)).to.equal(false)

			garbageMan:Clean()

			expect(connection.Connected).to.equal(false)
			expect(disconnects).to.equal(2)
		end)

		it("destroys when a signal fires", function()
			local garbageMan = GarbageMan.new()
			local callbacks: { any } = {}
			local signal: any = {}

			function signal:Connect(callback)
				table.insert(callbacks, callback)

				local connection: any = {
					Connected = true,
				}

				function connection:Disconnect()
					self.Connected = false
				end

				return connection
			end

			local connection = garbageMan:DestroyOnSignal(signal, "signal fired")

			callbacks[1]()

			expect(connection.Connected).to.equal(false)
			expect(garbageMan:IsDestroyed()).to.equal(true)
			expect(garbageMan:GetDestroyReason()).to.equal("signal fired")
		end)

		it("replaces tagged signal connections", function()
			local garbageMan = GarbageMan.new()
			local callbacks: { any } = {}
			local signal: any = {}
			local fired = 0

			function signal:Connect(callback)
				table.insert(callbacks, callback)

				local connection: any = {
					Connected = true,
				}

				function connection:Disconnect()
					self.Connected = false
				end

				return connection
			end

			local function onFirst()
				fired += 1
			end

			local function onSecond()
				fired += 10
			end

			local firstConnection = garbageMan:ReplaceConnection("Input", signal, onFirst)
			local secondConnection = garbageMan:ReplaceConnection("Input", signal, onSecond)

			expect(firstConnection.Connected).to.equal(false)
			expect(secondConnection.Connected).to.equal(true)
			expect(garbageMan:Get("Input")).to.equal(secondConnection)

			callbacks[2]()

			expect(fired).to.equal(10)

			garbageMan:Clean()

			expect(secondConnection.Connected).to.equal(false)
		end)

		it("replaces tweens with Cancel cleanup", function()
			local garbageMan = GarbageMan.new()
			local firstTween: any = {
				cancelled = false,
				Cancel = function(self: any)
					self.cancelled = true
				end,
			}
			local secondTween: any = {
				cancelled = false,
				Cancel = function(self: any)
					self.cancelled = true
				end,
			}

			expect(garbageMan:ReplaceTween("Tween:Open", firstTween)).to.equal(firstTween)
			expect(garbageMan:ReplaceTween("Tween:Open", secondTween)).to.equal(secondTween)
			expect(firstTween.cancelled).to.equal(true)

			garbageMan:Destroy()

			expect(secondTween.cancelled).to.equal(true)
		end)

		it("removes a tagged resource", function()
			local garbageMan = GarbageMan.new()
			local swept = 0

			garbageMan:Replace("Current", function()
				swept += 1
			end)

			expect(garbageMan:RemoveTag("Current")).to.equal(true)
			expect(swept).to.equal(1)
			expect(garbageMan:ContainsTag("Current")).to.equal(false)
		end)

		it("adopts child scopes", function()
			local parent = GarbageMan.new()
			local child = GarbageMan.new()
			local cleaned = false

			child:Add(function()
				cleaned = true
			end)

			expect(parent:Adopt(child)).to.equal(child)

			parent:Destroy()

			expect(child:IsDestroyed()).to.equal(true)
			expect(cleaned).to.equal(true)
		end)

		it("extends child scopes with explicit parent ownership", function()
			local parent = GarbageMan.new("Parent")
			local child = parent:Extend("Weapon")
			local defaultChild = parent:Extend()
			local cleaned = false

			expect(child:GetName()).to.equal("Parent:Weapon")
			expect(defaultChild:GetName()).to.equal("Parent:Child")

			child:Add(function()
				cleaned = true
			end)

			parent:Destroy()

			expect(child:IsDestroyed()).to.equal(true)
			expect(cleaned).to.equal(true)
		end)

		it("creates scopes from instances", function()
			local instance = Instance.new("Folder")
			local garbageMan = GarbageMan.from(instance)

			expect(garbageMan:IsDestroyed()).to.equal(false)

			instance:Destroy()
			task.wait()

			expect(garbageMan:IsDestroyed()).to.equal(true)
		end)

		it("supports named scopes and active debug registry", function()
			local garbageMan = GarbageMan.new("InventoryUI")
			local summaryFound = false
			local activeFound = false
			local activeAfterDestroy = false

			expect(garbageMan:GetName()).to.equal("InventoryUI")
			expect(garbageMan:SetName("InventoryUI:Open")).to.equal(garbageMan)
			expect(garbageMan:GetName()).to.equal("InventoryUI:Open")

			for _, summary in GarbageMan.Debug.getSummary() do
				if summary.name == "InventoryUI:Open" then
					summaryFound = true
					expect(summary.size).to.equal(0)
					expect(summary.destroyed).to.equal(false)
					expect(typeof(summary.age)).to.equal("number")
				end
			end

			for _, scope in GarbageMan.Debug.getScopes() do
				if scope == garbageMan then
					activeFound = true
				end
			end

			garbageMan:Destroy("screen changed")

			for _, scope in GarbageMan.Debug.getScopes() do
				if scope == garbageMan then
					activeAfterDestroy = true
				end
			end

			expect(summaryFound).to.equal(true)
			expect(activeFound).to.equal(true)
			expect(activeAfterDestroy).to.equal(false)
			expect(garbageMan:GetDestroyReason()).to.equal("screen changed")
		end)

		it("normalizes empty scope names", function()
			local garbageMan = GarbageMan.new("")

			expect(garbageMan:GetName()).to.equal("GarbageMan")
			expect(garbageMan:SetName("")).to.equal(garbageMan)
			expect(garbageMan:GetName()).to.equal("GarbageMan")

			garbageMan:Destroy()
		end)

		it("reports destroyed state and try-destroy errors", function()
			local garbageMan = GarbageMan.new()
			local ok: boolean
			local message: any

			garbageMan:Add(function()
				error("destroy failed")
			end)

			expect(garbageMan:IsDestroyed()).to.equal(false)

			ok, message = garbageMan:TryDestroy()

			expect(ok).to.equal(false)
			expect(message ~= nil).to.equal(true)
			expect(garbageMan:IsDestroyed()).to.equal(true)
			expect(garbageMan:Size()).to.equal(0)
		end)

		it("returns clean errors without throwing from TryClean", function()
			local garbageMan = GarbageMan.new()
			local ok: boolean
			local message: any

			garbageMan:Add(function()
				error("clean failed")
			end)

			ok, message = garbageMan:TryClean()

			expect(ok).to.equal(false)
			expect(message ~= nil).to.equal(true)
			expect(garbageMan:Size()).to.equal(0)
		end)

		it("runs reusable clean once on the next scheduler step", function()
			local garbageMan = GarbageMan.new()
			local cleaned = 0

			garbageMan:Add(function()
				cleaned += 1
			end)

			garbageMan:CleanDeferred()
			garbageMan:CleanDeferred()
			garbageMan:CleanDeferred()

			expect(cleaned).to.equal(0)

			task.wait()

			expect(cleaned).to.equal(1)
			expect(garbageMan:IsDestroyed()).to.equal(false)
		end)

		it("runs destroy lifecycle hooks around cleanup with a reason", function()
			local garbageMan = GarbageMan.new()
			local order: { string } = {}

			garbageMan:OnDestroying(function(reason)
				table.insert(order, `destroying:{tostring(reason)}`)
			end)

			garbageMan:Add(function()
				table.insert(order, "cleanup")
			end)

			garbageMan:OnDestroyed(function(reason)
				table.insert(order, `destroyed:{tostring(reason)}`)
			end)

			garbageMan:OnDestroyed(function(reason)
				table.insert(order, `destroyed-second:{tostring(reason)}`)
			end)

			garbageMan:Destroy("player left")

			expect(table.concat(order, ",")).to.equal(
				"destroying:player left,cleanup,destroyed:player left,destroyed-second:player left"
			)
			expect(garbageMan:GetDestroyReason()).to.equal("player left")
		end)

		it("disconnects destroy lifecycle hooks", function()
			local garbageMan = GarbageMan.new()
			local count = 0
			local disconnect = garbageMan:OnDestroyed(function()
				count += 1
			end)

			disconnect()
			disconnect()

			garbageMan:Destroy()

			expect(count).to.equal(0)
		end)

		it("does not run destroy lifecycle hooks on reusable clean", function()
			local garbageMan = GarbageMan.new()
			local count = 0

			garbageMan:OnDestroyed(function()
				count += 1
			end)

			garbageMan:Clean()

			expect(count).to.equal(0)

			garbageMan:Destroy()

			expect(count).to.equal(1)
		end)

		it("continues cleanup when destroy lifecycle hooks fail", function()
			local garbageMan = GarbageMan.new()
			local cleaned = false
			local ok: boolean
			local message: any

			garbageMan:OnDestroying(function()
				error("destroying failed")
			end)

			garbageMan:Add(function()
				cleaned = true
			end)

			ok, message = garbageMan:TryDestroy()

			expect(ok).to.equal(false)
			expect(message ~= nil).to.equal(true)
			expect(cleaned).to.equal(true)
			expect(garbageMan:IsDestroyed()).to.equal(true)
		end)

		it("runs destroyed hooks after cleanup errors", function()
			local garbageMan = GarbageMan.new()
			local destroyed = false
			local ok: boolean
			local message: any

			garbageMan:Add(function()
				error("cleanup failed")
			end)

			garbageMan:OnDestroyed(function()
				destroyed = true
			end)

			ok, message = garbageMan:TryDestroy()

			expect(ok).to.equal(false)
			expect(message ~= nil).to.equal(true)
			expect(destroyed).to.equal(true)
		end)

		it("keeps a snapshot of the first failed cleanup entry", function()
			local garbageMan = GarbageMan.new("CleanupSnapshot")
			local object: any = {
				Destroy = function()
					error("cleanup snapshot failed")
				end,
			}
			local ok: boolean
			local message: any
			local summaryFound = false

			garbageMan:Replace("BadResource", object, "Destroy")

			ok, message = garbageMan:TryClean()

			expect(ok).to.equal(false)
			expect(message ~= nil).to.equal(true)
			expect(garbageMan:GetLastCleanupError() ~= nil).to.equal(true)

			local failedEntry = garbageMan:GetLastFailedEntry()

			expect(failedEntry ~= nil).to.equal(true)

			if failedEntry ~= nil then
				expect(failedEntry.object).to.equal(object)
				expect(failedEntry.tag).to.equal("BadResource")
			end

			for _, summary in GarbageMan.Debug.getSummary() do
				if summary.name == "CleanupSnapshot" then
					summaryFound = true
					expect(summary.lastCleanupError ~= "").to.equal(true)
					expect(summary.lastFailedObjectType).to.equal("table")
					expect(summary.lastFailedTag).to.equal("BadResource")
				end
			end

			expect(summaryFound).to.equal(true)

			garbageMan:Destroy()
		end)

		it("captures add tracebacks only when enabled", function()
			GarbageMan.configure({
				captureAddTracebacks = false,
			})

			local first = GarbageMan.new("TracebacksOff")

			first:Add(function() end)

			expect(first:GetDebugSummary()[1].addedTraceback).to.equal("")

			first:Destroy()

			GarbageMan.configure({
				captureAddTracebacks = true,
			})

			local second = GarbageMan.new("TracebacksOn")

			second:Add(function() end)

			local addedTraceback = second:GetDebugSummary()[1].addedTraceback
			local hasTraceback = string.find(addedTraceback, "GarbageMan resource added here") ~= nil

			expect(hasTraceback).to.equal(true)

			second:Destroy()
			GarbageMan.configure({
				captureAddTracebacks = false,
			})
		end)

		it("toggles leak warning setting", function()
			GarbageMan.configure({
				leakWarnings = false,
			})
			expect(GarbageMan.getConfig().leakWarnings).to.equal(false)

			GarbageMan.configure({
				leakWarnings = true,
			})
			expect(GarbageMan.getConfig().leakWarnings).to.equal(true)

			local garbageMan = GarbageMan.new("LeakWarning")
			local cancelWarning = garbageMan:WarnIfNotDestroyedAfter(0, "LeakWarning should be destroyed")

			expect(typeof(cancelWarning)).to.equal("function")

			cancelWarning()
			garbageMan:Destroy()
		end)

		it("allows Clean after Destroy as a no-op", function()
			local garbageMan = GarbageMan.new()

			garbageMan:Destroy()
			garbageMan:Clean()

			expect(garbageMan:IsDestroyed()).to.equal(true)
			expect(garbageMan:Size()).to.equal(0)
		end)

		it("cleans after a delay and supports cancellation", function()
			local delayed = GarbageMan.new("DelayedClean")
			local cancelled = GarbageMan.new("CancelledClean")
			local cleaned = false
			local cancelledCleaned = false

			delayed:Add(function()
				cleaned = true
			end)

			cancelled:Add(function()
				cancelledCleaned = true
			end)

			local cancelClean = cancelled:CleanAfter(0)
			cancelClean()

			delayed:CleanAfter(0)

			task.wait()

			expect(delayed:IsDestroyed()).to.equal(false)
			expect(delayed:Size()).to.equal(0)
			expect(cleaned).to.equal(true)
			expect(cancelledCleaned).to.equal(false)

			delayed:Destroy()
			cancelled:Destroy()
		end)

		it("destroys after a delay and supports cancellation", function()
			local delayed = GarbageMan.new("DelayedDestroy")
			local cancelled = GarbageMan.new("CancelledDestroy")
			local cleaned = false

			delayed:Add(function()
				cleaned = true
			end)

			local cancelDestroy = cancelled:DestroyAfter(0, "cancelled")
			cancelDestroy()

			delayed:DestroyAfter(0, "timeout")

			task.wait()

			expect(delayed:IsDestroyed()).to.equal(true)
			expect(delayed:GetDestroyReason()).to.equal("timeout")
			expect(cleaned).to.equal(true)
			expect(cancelled:IsDestroyed()).to.equal(false)

			cancelled:Destroy()
		end)

		it("routes delayed destroy cleanup errors through the configured error handler", function()
			local garbageMan = GarbageMan.new("DelayedError")
			local handled = false
			local handledScope: any = nil

			GarbageMan.configure({
				errorHandler = function(message, scope)
					handled = message ~= nil
					handledScope = scope
				end,
			})

			garbageMan:Add(function()
				error("delayed cleanup failed")
			end)

			garbageMan:DestroyAfter(0, "delayed")

			task.wait()

			expect(handled).to.equal(true)
			expect(handledScope).to.equal(garbageMan)
			expect(garbageMan:GetDestroyReason()).to.equal("delayed")

			GarbageMan.configure({
				errorHandler = false,
			})
		end)

		it("counts cleanups even when profiling is disabled", function()
			GarbageMan.configure({
				profiling = false,
			})

			local garbageMan = GarbageMan.new("CleanupCount")
			local summaryFound = false

			garbageMan:Add(function() end)
			garbageMan:Clean()

			for _, summary in GarbageMan.Debug.getSummary() do
				if summary.name == "CleanupCount" then
					summaryFound = true
					expect(summary.cleanupCount).to.equal(1)
					expect(summary.lastCleanupDuration).to.equal(0)
					expect(summary.peakCleanupDuration).to.equal(0)
				end
			end

			expect(summaryFound).to.equal(true)

			garbageMan:Destroy()
		end)

		it("tracks cleanup profiling when enabled", function()
			GarbageMan.configure({
				profiling = true,
			})

			local garbageMan = GarbageMan.new("ProfiledScope")
			local summaryFound = false

			garbageMan:Add(function() end)
			garbageMan:Clean()

			for _, summary in GarbageMan.Debug.getSummary() do
				if summary.name == "ProfiledScope" then
					summaryFound = true
					expect(summary.cleanupCount).to.equal(1)
					expect(typeof(summary.lastCleanupDuration)).to.equal("number")
					expect(typeof(summary.peakCleanupDuration)).to.equal("number")
				end
			end

			expect(summaryFound).to.equal(true)

			garbageMan:Destroy()

			GarbageMan.configure({
				profiling = false,
			})
		end)

		it("cleans resources in batches", function()
			local garbageMan = GarbageMan.new()
			local cleaned = 0

			garbageMan:Add(function()
				cleaned += 1
			end)

			garbageMan:Add(function()
				cleaned += 1
			end)

			garbageMan:Add(function()
				cleaned += 1
			end)

			garbageMan:CleanBatched(2)

			expect(cleaned).to.equal(0)

			task.wait()
			task.wait()

			expect(cleaned).to.equal(3)
			expect(garbageMan:Size()).to.equal(0)

			garbageMan:Destroy()
		end)

		it("destroys resources in batches", function()
			local garbageMan = GarbageMan.new("BatchedDestroy")
			local cleaned = 0

			garbageMan:Add(function()
				cleaned += 1
			end)

			garbageMan:Add(function()
				cleaned += 1
			end)

			garbageMan:DestroyBatched("batched", 1)

			expect(garbageMan:IsDestroyed()).to.equal(true)
			expect(garbageMan:GetDestroyReason()).to.equal("batched")

			task.wait()
			task.wait()

			expect(cleaned).to.equal(2)
		end)

		it("rejects invalid delay and batch numbers", function()
			local garbageMan = GarbageMan.new()
			local nan = 0 / 0
			local delayOk = pcall(function()
				garbageMan:DestroyAfter(math.huge)
			end)
			local nanDelayOk = pcall(function()
				garbageMan:WarnIfNotDestroyedAfter(nan)
			end)
			local batchOk = pcall(function()
				garbageMan:CleanBatched(math.huge)
			end)
			local nanBatchOk = pcall(function()
				garbageMan:DestroyBatched(nil, nan)
			end)

			expect(delayOk).to.equal(false)
			expect(nanDelayOk).to.equal(false)
			expect(batchOk).to.equal(false)
			expect(nanBatchOk).to.equal(false)

			garbageMan:Destroy()
		end)

		it("keeps scopes registered while destroy cleanup is running", function()
			local garbageMan = GarbageMan.new("DestroyDebug")
			local seenDuringCleanup = false
			local ok: boolean
			local message: any

			garbageMan:Add(function()
				for _, scope in GarbageMan.Debug.getScopes() do
					if scope == garbageMan then
						seenDuringCleanup = true
					end
				end

				error("cleanup failed")
			end)

			ok, message = garbageMan:TryDestroy()

			expect(ok).to.equal(false)
			expect(message ~= nil).to.equal(true)
			expect(seenDuringCleanup).to.equal(true)
		end)

		it("routes deferred destroy cleanup errors through the configured error handler", function()
			local garbageMan = GarbageMan.new("DeferredError")
			local handled = false
			local handledScope: any = nil

			GarbageMan.configure({
				errorHandler = function(message, scope)
					handled = message ~= nil
					handledScope = scope
				end,
			})

			garbageMan:Add(function()
				error("deferred cleanup failed")
			end)

			garbageMan:DestroyDeferred("deferred")
			task.wait()

			expect(handled).to.equal(true)
			expect(handledScope).to.equal(garbageMan)
			expect(garbageMan:GetDestroyReason()).to.equal("deferred")

			GarbageMan.configure({
				errorHandler = false,
			})
		end)

		it("returns tags and debug dump entries", function()
			local garbageMan = GarbageMan.new()
			local object: any = {
				Destroy = function() end,
			}

			garbageMan:Replace("Debug:Object", object, "Destroy")

			local tags = garbageMan:GetTags()
			local dump = garbageMan:GetDebugDump()
			local summary = garbageMan:GetDebugSummary()

			expect(#tags).to.equal(1)
			expect(tags[1]).to.equal("Debug:Object")
			expect(#dump).to.equal(1)
			expect(dump[1].object).to.equal(object)
			expect(dump[1].tag).to.equal("Debug:Object")
			expect(#summary).to.equal(1)
			expect(summary[1].objectType).to.equal("table")
			expect(summary[1].tag).to.equal("Debug:Object")
		end)

		it("describes instances with class and name in debug summaries", function()
			local garbageMan = GarbageMan.new()
			local part = Instance.new("Part")

			part.Name = "Hitbox"

			garbageMan:Add(part)

			local summary = garbageMan:GetDebugSummary()

			expect(summary[1].objectType).to.equal('Part "Hitbox"')

			garbageMan:Destroy()
		end)

		it("removes tags by prefix", function()
			local garbageMan = GarbageMan.new()
			local swept = 0

			garbageMan:Replace("Tween:Open", function()
				swept += 1
			end)

			garbageMan:Replace("Tween:Close", function()
				swept += 1
			end)

			garbageMan:Replace("Connection:Health", function()
				swept += 10
			end)

			expect(garbageMan:RemoveTagsWithPrefix("Tween:")).to.equal(2)
			expect(swept).to.equal(2)
			expect(garbageMan:ContainsTag("Connection:Health")).to.equal(true)
		end)

		it("asserts when entries remain", function()
			local garbageMan = GarbageMan.new()

			garbageMan:Add(function() end)

			local ok = pcall(function()
				garbageMan:AssertEmpty()
			end)

			expect(ok).to.equal(false)

			garbageMan:Clean()
			garbageMan:AssertEmpty()
		end)
	end)
end
