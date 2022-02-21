--!strict

type userdata = typeof(newproxy())
type table = {[any]: any}
type array = {[number]: any}

local undefined: userdata = newproxy(true)
local draftRefKey: userdata = newproxy(false)
local draftValuesKey = newproxy(false)

-- lazy init functions
local draftProxy
local draftHasChanges
local mergeDraft

---

local isDraft = function(v: any): boolean
    if (type(v) ~= "table") then return false end
    
    return (v[draftRefKey] ~= nil) and (v[draftValuesKey] ~= nil)
end

local isDraftable = function(v: any): boolean
    if (type(v) ~= "table") then return false end
    if (isDraft(v)) then return false end
    
    return (getmetatable(v) == nil)
end

local evaluateValue = function(refValue: any, draftValue: any): any
    if (draftValue ~= nil) then
        if (draftValue == undefined) then
            return nil
        else
            return draftValue
        end
    else
        return refValue
    end
end

local iterNext = function(t: table, lastKey: any?): (any?, any?)
    if (not isDraft(t)) then
        return next(t, lastKey)
    else
        local refValues: table = t[draftRefKey]
        local draftValues: table = t[draftValuesKey]
        local keys: table = {}

        for k in pairs(refValues) do
            keys[k] = true
        end

        for k in pairs(draftValues) do
            keys[k] = true
        end

        local nextKey: any
        local nextValue: any

        repeat
            nextKey = next(keys, lastKey)

            if (nextKey ~= nil) then
                lastKey = nextKey
                nextValue = t[nextKey]
            end
        until (nextValue ~= nil) or (nextKey == nil)

        if (nextKey ~= nil) then
            return nextKey, nextValue
        else
            return
        end
    end
end

local iterNum = function(t: array, i: number): (number?, any?)
    i = i + 1

    local value: any = t[i]

    if (value ~= nil) then
        return i, value
    else
        return
    end
end

local draftProxyMetatable = {
    __index = function(t: table, k: any): any?
        local refValue: any = t[draftRefKey][k]
        local draftValue: any = t[draftValuesKey][k]

        if (draftValue ~= nil) then
            if (draftValue == undefined) then
                return nil
            else
                return draftValue
            end
        else
            if (not isDraftable(refValue)) then
                return refValue
            else
                local newDraft: table = draftProxy(refValue)
                t[draftValuesKey][k] = newDraft

                return newDraft
            end
        end
    end,

    __newindex = function(t: table, k: any, v: any)
        local draftValues: table = t[draftValuesKey]

        if (v == nil) then
            draftValues[k] = undefined
        elseif (v == undefined) then
            draftValues[k] = nil
        else
            draftValues[k] = v
        end
    end,
}

--

draftHasChanges = function(draft: table): boolean
    local refValues: table = draft[draftRefKey]
    local draftValues: table = draft[draftValuesKey]

    for key, draftValue in pairs(draftValues) do
        local refValue: any = refValues[key]

        if ((refValue == nil) and (draftValue ~= undefined)) then
            return true
        elseif (isDraft(draftValue)) then
            local innerDraftHasChanges: boolean = draftHasChanges(draftValue)

            if (innerDraftHasChanges) then
                return true
            else
                if (draftValue[draftRefKey] ~= refValues[key]) then
                    return true
                end
            end
        else
            local changed: boolean = (draft[key] ~= refValue)

            if (changed) then
                return true
            end
        end
    end

    return false
end

mergeDraft = function(base: table, draft: table): table
    if (not draftHasChanges(draft)) then return base end

    local draftValues: table = draft[draftValuesKey]
    local newState: table = {}

    -- merge modified keys
    for key, baseValue in pairs(base) do
        local draftValue: any = draftValues[key]

        if (not isDraft(draftValue)) then
            if ((draftValue == nil) or (draftValue == baseValue)) then
                newState[key] = baseValue
            elseif (draftValue == undefined) then
                newState[key] = nil
            else
                newState[key] = draftValue
            end
        else
            newState[key] = mergeDraft(draftValue[draftRefKey], draftValue)
        end
    end

    -- merge new keys
    for key, draftValue in pairs(draftValues) do
        local newStateValue: any = newState[key]

        if ((newStateValue == nil) and (draftValue ~= undefined)) then
            if (isDraft(draftValue)) then
                newState[key] = mergeDraft(draftValue[draftRefKey], draftValue)
            else
                newState[key] = evaluateValue(nil, draftValue)
            end
        end      
    end

    -- enforce immutability
    return table.freeze(newState)
end

draftProxy = function(ref: table)
    local draft: table = {
        [draftRefKey] = ref,
        [draftValuesKey] = {}
    }

    setmetatable(draft, draftProxyMetatable)
    return draft
end

getmetatable(undefined).__tostring = function(): string
    return "<undefined>"
end

---

local state = {}

state.undefined = undefined
state.draft = {}
state.table = {}
state.iter = {}

--- state.draft functions

-- returns if the passed value is a draft
state.draft.isDraft = isDraft

-- returns the reference table of a draft
state.draft.getRef = function(draft: table): table?
    assert(isDraft(draft), "value is not a draft")

    return draft[draftRefKey]
end

--- state.iter functions

-- use in place of pairs
state.iter.pairs = function(t: table): ((table, any?) -> (any?, any?), table, any)
    return iterNext, t, nil
end

-- use in place of ipairs
state.iter.ipairs = function(t: array): ((array, number) -> (number?, any?), array, number)
    return iterNum, t, 0
end

--- state.table functions

--[[
    use in place in table.getn or #

    NOTE: The length operator's behaviour is undefined for tables with holes,
    which makes this function non-equivalent, along with any other functions
    that use it
]]
state.table.getn = function(t: table): number
    if (not isDraft(t)) then return #t end

    local length: number = 0

    for _ in state.iter.ipairs(t) do
        length = length + 1
    end

    return length
end

-- use in place of 3 argument table.insert (use table.append for 2 arguments)
state.table.insert = function(t: array, i: number, v: any)
    if (not isDraft(t)) then
        table.insert(t, i, v)
        return
    end

    local refValues: table = t[draftRefKey]
    local draftValues: table = t[draftValuesKey]
    local length: number = state.table.getn(t)

    for j = length, i, -1 do
        local refValue: any = refValues[j]
        local draftValue: any = draftValues[j]
        local value: any

        if (draftValue == nil) then
            value = refValue
        else
            value = draftValue
        end

        t[j + 1] = value
    end

    t[i] = v
end

-- use in place of 2-argument table.insert
state.table.append = function(t: array, v: any)
    state.table.insert(t, state.table.getn(t) + 1, v)
end

-- use in place of table.remove
state.table.remove = function(t: array, optionalI: number?): any
    if (not isDraft(t)) then
        return table.remove(t, optionalI)
    end

    local length: number = state.table.getn(t)
    local i: number = optionalI or length
    local removedValue: any = t[i]

    for j = i, length, 1 do
        t[j] = t[j + 1]
    end

    t[length] = nil
    return removedValue
end

--- main functions

-- produce a new state
state.produce = function(baseState: table, recipe: (table) -> any?): table
    if (not isDraftable(baseState)) then
        error("The base state is not a draftable table")
    end

    local draftState = draftProxy(baseState)
    recipe(draftState)

    return mergeDraft(baseState, draftState)
end

---

return state