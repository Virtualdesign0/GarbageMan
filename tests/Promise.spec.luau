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

type PromiseMock = {
	status: string,
	cancelled: boolean,
	finallyCallback: (() -> ())?,
	cleanupPromise: PromiseMock?,
	getStatus: (self: PromiseMock) -> string,
	["finally"]: (self: PromiseMock, callback: () -> ()) -> PromiseMock,
	cancel: (self: PromiseMock) -> (),
	resolve: (self: PromiseMock) -> (),
}

local function asPromiseMock(value: any): PromiseMock
	local result: PromiseMock = value
	return result
end

local function createPromise(status: string): PromiseMock
	local promise: any = {
		status = status,
		cancelled = false,
		finallyCallback = nil,
		cleanupPromise = nil,
		getStatus = function(self: PromiseMock): string
			return self.status
		end,
		["finally"] = function(self: PromiseMock, callback: () -> ()): PromiseMock
			local cleanupPromise = createPromise("Started")

			self.finallyCallback = callback
			self.cleanupPromise = cleanupPromise

			if self.status ~= "Started" then
				callback()
				cleanupPromise.status = "Resolved"
			end

			local result = asPromiseMock(cleanupPromise)
			return result
		end,
		cancel = function(self: PromiseMock)
			self.cancelled = true
			self.status = "Cancelled"

			if self.finallyCallback ~= nil then
				self.finallyCallback()
			end

			if self.cleanupPromise ~= nil then
				self.cleanupPromise.status = "Cancelled"
			end
		end,
		resolve = function(self: PromiseMock)
			self.status = "Resolved"

			if self.finallyCallback ~= nil then
				self.finallyCallback()
			end

			if self.cleanupPromise ~= nil then
				self.cleanupPromise.status = "Resolved"
			end
		end,
	}

	local result = asPromiseMock(promise)
	return result
end

return function()
	describe("AddPromise", function()
		it("does not retain already resolved promises", function()
			local garbageMan = GarbageMan.new()
			local promise = createPromise("Resolved")

			garbageMan:AddPromise(promise)

			expect(garbageMan:Size()).to.equal(0)
		end)

		it("tracks started promises and their finally promise", function()
			local garbageMan = GarbageMan.new()
			local promise = createPromise("Started")

			garbageMan:AddPromise(promise)

			expect(garbageMan:Size()).to.equal(2)
			expect(garbageMan:Contains(promise)).to.equal(true)

			local cleanupPromise = promise.cleanupPromise
			assert(cleanupPromise ~= nil, "expected cleanupPromise")

			expect(garbageMan:Contains(cleanupPromise)).to.equal(true)
		end)

		it("cancels started promises and drops the finally promise on destroy", function()
			local garbageMan = GarbageMan.new()
			local promise = createPromise("Started")

			garbageMan:AddPromise(promise)

			local cleanupPromise = promise.cleanupPromise
			assert(cleanupPromise ~= nil, "expected cleanupPromise")

			garbageMan:Destroy()

			expect(promise.cancelled).to.equal(true)
			expect(cleanupPromise.cancelled).to.equal(true)
			expect(garbageMan:Size()).to.equal(0)
		end)

		it("removes dependent links when the finally promise is dropped first", function()
			local garbageMan = GarbageMan.new()
			local promise = createPromise("Started")

			garbageMan:AddPromise(promise)

			local cleanupPromise = promise.cleanupPromise
			assert(cleanupPromise ~= nil, "expected cleanupPromise")

			expect(garbageMan:Drop(cleanupPromise)).to.equal(true)
			expect(garbageMan:Size()).to.equal(1)

			garbageMan:Destroy()

			expect(promise.cancelled).to.equal(true)
			expect(garbageMan:Size()).to.equal(0)
		end)
	end)
end
