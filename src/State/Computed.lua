--!strict
--!nolint LocalShadow

--[[
	Constructs and returns objects which can be used to model derived reactive
	state.
]]

local Package = script.Parent.Parent
local Types = require(Package.Types)
local InternalTypes = require(Package.InternalTypes)
-- Logging
local logError = require(Package.Logging.logError)
local logErrorNonFatal = require(Package.Logging.logErrorNonFatal)
local logWarn = require(Package.Logging.logWarn)
local parseError = require(Package.Logging.parseError)
-- Utility
local isSimilar = require(Package.Utility.isSimilar)
-- State
local isState = require(Package.State.isState)
-- Memory
local doCleanup = require(Package.Memory.doCleanup)
local deriveScope = require(Package.Memory.deriveScope)
local whichLivesLonger = require(Package.Memory.whichLivesLonger)

local class = {}

local CLASS_METATABLE = {__index = class}

--[[
	Called when a dependency changes value.
	Recalculates this Computed's cached value and dependencies.
	Returns true if it changed, or false if it's identical.
]]
function class:update(): boolean
	local self = self :: InternalTypes.Computed<unknown, unknown>
	if self.scope == nil then
		return false
	end
	local outerScope = self.scope :: Types.Scope<unknown>

	-- remove this object from its dependencies' dependent sets
	for dependency in pairs(self.dependencySet) do
		dependency.dependentSet[self] = nil
	end

	-- we need to create a new, empty dependency set to capture dependencies
	-- into, but in case there's an error, we want to restore our old set of
	-- dependencies. by using this table-swapping solution, we can avoid the
	-- overhead of allocating new tables each update.
	self._oldDependencySet, self.dependencySet = self.dependencySet, self._oldDependencySet
	table.clear(self.dependencySet)

	local innerScope = deriveScope(outerScope)
	local function use<T>(target: Types.CanBeState<T>): T
		if isState(target) then
			local target = target :: Types.StateObject<T>
			if target.scope == nil then
				logError("useAfterDestroy", nil, `The {target.kind} object`, "the Computed that is use()-ing it")
			elseif whichLivesLonger(outerScope, self, target.scope, target) == "definitely-a" then
				logWarn("possiblyOutlives", `The {target.kind} object`, "the Computed that is use()-ing it")
			end		
			self.dependencySet[target] = true
			return (target :: InternalTypes.StateObject<T>):_peek()
		else
			return target :: T
		end
	end
	local ok, newValue = xpcall(self._processor, parseError, use, innerScope)

	if ok then
		local oldValue = self._value
		local similar = isSimilar(oldValue, newValue)
		if self._innerScope ~= nil then
			doCleanup(self._innerScope)
		end
		self._value = newValue
		self._innerScope = innerScope

		-- add this object to the dependencies' dependent sets
		for dependency in pairs(self.dependencySet) do
			dependency.dependentSet[self] = true
		end

		return not similar
	else
		local errorObj = (newValue :: any) :: InternalTypes.Error
		-- this needs to be non-fatal, because otherwise it'd disrupt the
		-- update process
		logErrorNonFatal("callbackError", errorObj)

		doCleanup(innerScope)

		-- restore old dependencies, because the new dependencies may be corrupt
		self._oldDependencySet, self.dependencySet = self.dependencySet, self._oldDependencySet

		-- restore this object in the dependencies' dependent sets
		for dependency in pairs(self.dependencySet) do
			dependency.dependentSet[self] = true
		end

		return false
	end
end

--[[
	Returns the interior value of this state object.
]]
function class:_peek(): unknown
	local self = self :: InternalTypes.Computed<unknown, unknown>
	return self._value
end

function class:get()
	logError("stateGetWasRemoved")
end

function class:destroy()
	local self = self :: InternalTypes.Computed<unknown, unknown>
	if self.scope == nil then
		logError("destroyedTwice", nil, "Computed")
	end
	self.scope = nil
	for dependency in pairs(self.dependencySet) do
		dependency.dependentSet[self] = nil
	end
	if self._innerScope ~= nil then
		doCleanup(self._innerScope)
	end
end

local function Computed<T, S>(
	scope: Types.Scope<S>,
	processor: (Types.Use, Types.Scope<S>) -> T,
	destructor: unknown?
): Types.Computed<T>
	if typeof(scope) == "function" then
		logError("scopeMissing", nil, "Computeds", "myScope:Computed(function(use, scope) ... end)")
	elseif destructor ~= nil then
		logWarn("destructorRedundant", "Computed")
	end
	local self = setmetatable({
		type = "State",
		kind = "Computed",
		scope = scope,
		dependencySet = {},
		dependentSet = {},
		_oldDependencySet = {},
		_processor = processor,
		_value = nil,
		_innerScope = nil
	}, CLASS_METATABLE)
	local self = (self :: any) :: InternalTypes.Computed<T, S>

	table.insert(scope, self)
	self:update()
	
	return self
end

return Computed