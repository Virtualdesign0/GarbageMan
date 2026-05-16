--!strict

local Promise = {}

function Promise.IsLike(object: any): boolean
	return typeof(object) == "table"
		and typeof(object.getStatus) == "function"
		and typeof(object["finally"]) == "function"
		and typeof(object.cancel) == "function"
end

function Promise.AssertLike(object: any)
	if not Promise.IsLike(object) then
		error("did not receive a promise-like object", 3)
	end
end

function Promise.IsStarted(object: any): boolean
	return object:getStatus() == "Started"
end

return Promise
