--!strict

local Cleanup = {}

local FUNCTION_MARKER = table.freeze({ kind = "function" })
local THREAD_MARKER = table.freeze({ kind = "thread" })

local GENERIC_CLEANUP_METHODS = table.freeze({
	"Destroy",
	"Disconnect",
	"destroy",
	"disconnect",
	"Cancel",
	"cancel",
	"Clean",
	"clean",
})

export type CleanupMethod = string | typeof(FUNCTION_MARKER) | typeof(THREAD_MARKER)

local function readMethod(object: any, methodName: string): any
	local ok: boolean
	local method: any

	ok, method = pcall(function()
		return object[methodName]
	end)

	if ok then
		return method
	end

	return nil
end

function Cleanup.Resolve(object: any, cleanupMethod: string?): CleanupMethod
	if object == nil then
		error("GarbageMan cannot track nil", 3)
	end

	local objectType = typeof(object)

	if cleanupMethod ~= nil then
		if typeof(cleanupMethod) ~= "string" or cleanupMethod == "" then
			error("cleanupMethod must be a non-empty string", 3)
		end

		if typeof(readMethod(object, cleanupMethod)) ~= "function" then
			error(`cleanup method "{cleanupMethod}" is missing for object type {objectType}`, 3)
		end

		return cleanupMethod
	end

	if objectType == "function" then
		return FUNCTION_MARKER
	elseif objectType == "thread" then
		return THREAD_MARKER
	elseif objectType == "Instance" then
		return "Destroy"
	elseif objectType == "RBXScriptConnection" then
		return "Disconnect"
	elseif objectType == "table" then
		for _, methodName in GENERIC_CLEANUP_METHODS do
			if typeof(object[methodName]) == "function" then
				return methodName
			end
		end
	end

	error(`failed to resolve cleanup method for object type {objectType}: {object}`, 3)
end

function Cleanup.Run(object: any, cleanupMethod: CleanupMethod)
	if cleanupMethod == FUNCTION_MARKER then
		object()
		return
	end

	if cleanupMethod == THREAD_MARKER then
		local runningThread: any = coroutine.running()

		if object == runningThread then
			return
		end

		local ok: boolean
		local message: any

		ok, message = pcall(task.cancel, object)

		if not ok and coroutine.status(object) ~= "dead" then
			error(message, 2)
		end

		return
	end

	if cleanupMethod == "Disconnect" and object.Connected == false then
		return
	end

	object[cleanupMethod](object)
end

return Cleanup
