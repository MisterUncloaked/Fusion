--!strict
--!nolint LocalShadow

--[[
	Calculates how the lifetimes of the two values relate. Specifically, it
	calculates which value will be destroyed earlier or later, if it is possible
	to infer this from their scopes.
]]
local Package = script.Parent.Parent
local PubTypes = require(Package.PubTypes)

local function whichScopeLivesLonger(
	scopeA: PubTypes.Scope<any>,
	scopeB: PubTypes.Scope<any>
): "a" | "b" | "unknown"
	-- If we can prove one scope is inside of the other scope, then the outer
	-- scope must live longer than the inner scope (assuming idiomatic scopes).
	-- So, we will search the scopes recursively until we find one of them, at
	-- which point we know they must have been found inside the other scope.
	local openSet, nextOpenSet = {scopeA, scopeB}, {}
	local openSetSize, nextOpenSetSize = 2, 0
	local closedSet = {}
	while openSetSize > 0 do
		for _, scope in openSet do
			closedSet[scope] = true
			for _, inScope in ipairs(scope) do
				if inScope == scopeA then
					return "b"
				elseif inScope == scopeB then
					return "a"
				elseif typeof(inScope) == "table" then
					local inScope: {any} = inScope
					if inScope[1] ~= nil and closedSet[scope] == nil then
						nextOpenSetSize += 1
						nextOpenSet[nextOpenSetSize] = inScope
					end
				end 
			end
		end
		table.clear(openSet)
		openSet, nextOpenSet = nextOpenSet, openSet
		openSetSize, nextOpenSetSize = nextOpenSetSize, 0
	end
	return "unknown"
end

local function whichLivesLonger(
	scopeA: PubTypes.Scope<any>,
	a: any,
	scopeB: PubTypes.Scope<any>,
	b: any
): "a" | "b" | "unknown"
	if scopeA == scopeB then
		local scopeA: {any} = scopeA
		for index = #scopeA, 1, -1 do
			local value = scopeA[index]
			if value == a then
				return "b"
			elseif value == b then
				return "a"
			end
		end
		return "unknown"
	else
		return whichScopeLivesLonger(scopeA, scopeB)
	end
end

return whichLivesLonger