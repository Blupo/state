# state

The purpose of this library is similar to [immer](https://github.com/immerjs/immer): to create the next state by modifying the current one. This module was specifically created to reduce the need to repeatedly deep-copy Rodux state for making changes.

Due to the numerous compromises needed to make table operations work correctly when using draft states (see [state.table](#statetable) and [state.iter](#stateiter)), this module isn't fit for widespread use. You're free to use it, though, if it suits your needs and you're willing to deal with the compromises.

## Example

```lua
local baseState = {
    activeQuests = {
        [147] = {
            checkpoint = 3,
            quality = 0.98,
        },

        [628] = {
            checkpoint = 0,
            quality = 1,
        }
    },

    completedQuests = {
        [54] = 1,
        [29] = 1,
        [124] = 5,
    }

    currency = {
        Coins = 1390,
        CrystalShards = 58,
        WoodenToken = 2,
    },

    inventory = {
        {
            id = 58,
            level = 2,
            customName = "Alpenglow Bow",
        }
    }
}

state.produce(baseState, function(draftState)
    draftState.currency.Coins = draftState.currency.Coins + 100
    draftState.activeQuests[147] = state.none
    draftState.completedQuests[147] = 1

    state.table.append(draftState.inventory, {
        id = 76,
        level = 1,
        customName = "Ravenspire Bow",
    })
end)
```

# API

## state.undefined

```
state.undefined: userdata
```

This value is used to remove changes made to a draft. Setting a key's value to `nil` will explictly remove the key from the produced state.

For example,

```lua
local baseState = { 1, 2, 3, 4, 5 }

state.produce(baseState, function(draftState)
    draftState[1] = nil
end)
```

results in `{ nil, 2, 3, 4, 5 }`, however

```lua
local baseState = { 1, 2, 3, 4, 5 }

state.produce(baseState, function(draftState)
    draftState[1] = nil
    draftState[1] = state.undefined
end)
```

results in `{ 1, 2, 3, 4, 5 }` (which is equal to `baseState`).

## state.table

```
state.table: table
```

Provides table functions that work with draft tables. Due to the way drafts work, many table operations (besides indexing and setting) do not work correctly.

These functions will also work with non-draft tables, and replicate their original behaviour.

## state.iter

```
state.iter: table
```

Provides iterator functions that work with draft tables (as well as non-draft tables). Due to the way drafts work, iterations do not work correctly with the default iterators.

## state.produce

```
state.produce(baseState: table, recipe: (draftState: Draft) -> any): table
```

Produces a new state. If there are changes, the new state will be fully immutable (or deep-frozen, if that makes more sense), otherwise `baseState` will be returned, which is not guaranteed to be fully immutable.

# state.table

## state.table.append

```
state.table.append(t: table | Draft, v: any)
```

Similar to the 2-arugment `table.insert` function. Use [`state.table.insert`](#statetableinsert) for the 3-argument function.

## state.table.getn

```
state.table.getn(t: table | Draft): number
```

Similar to `table.getn` or the length operator (`#`). There is a (probably-not-important) caveat to how this function work versus the normal `table.getn` or `#` operator.

<details>
<summary>Caveat</summary>

The length operator and `table.getn` have undefined behaviour for tables with holes, however `state.table.getn` will return the length of the table before the first hole.

This is similar to how the length would be calculated if you used `ipairs` to iterate over the list and returned the last index.

```
local t = { 1, 2, nil, 4 }

print(#t) --> 4, probably

state.produce(t, function(draftState))
    print(state.table.getn(draftState)) --> 2
end

print(state.table.getn(t)) --> 4 (t is not a draft table)
```

As such, this makes `state.table.insert`, `state.table.append`, and `state.table.remove` non-equivalent to their `table` counterparts.
</details>

## state.table.insert

```
state.table.insert(t: table | Draft, i: number, v: any)
```

Similar to the 3-argument `table.insert` function. Use [`state.table.append`](#statetableappend) for the 2-argument function.

## state.table.remove

```
state.table.remove(t: table | Draft, i: number?): any
```

Similar to `table.remove`.

# state.iter

## state.iter.pairs

```
state.iter.pairs(t: table | Draft): ((table | Draft, any?) -> (any?, any?), table | Draft, any)
```

Equivalent to `pairs`.

## state.iter.ipairs

```
state.iter.ipairs(t: array | Draft): ((array | Draft, number) -> (number?, any?), array | Draft, number)
```

Equivalent to `ipairs`.