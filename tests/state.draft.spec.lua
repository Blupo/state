local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local state = require(ReplicatedStorage:FindFirstChild("state"))

---

return function()
    it("should have a public API", function()
        expect(state.draft.getRef).to.be.a("function")
    end)

    describe("state.draft.isDraft", function()
        it("should determine if a table is a draft", function()
            local nonDraftTable = {}

            state.produce(nonDraftTable, function(draftTable)
                expect(state.draft.isDraft(draftTable)).to.equal(true)
            end)

            expect(state.draft.isDraft(nonDraftTable)).to.equal(false)
        end)
    end)

    describe("state.draft.getRef", function()
        it("should return a draft table's reference", function()
            local baseState = {
                A = {
                    B = {
                        C = {}
                    }
                }
            }

            state.produce(baseState, function(draftState)
                expect(state.draft.getRef(draftState.A.B.C)).to.equal(baseState.A.B.C)
            end)
        end)

        it("should error if the value is not a draft table", function()
            local t = {}

            state.produce(t, function(dT)
                expect(function()
                    state.draft.getRef(dT)
                end).to.never.throw()
            end)

            expect(function()
                state.draft.getRef(t)
            end).to.throw()
        end)
    end)

    describe("state.draft.getState", function()
        it("should error if the value is not a draft table", function()
            local t = {}

            state.produce(t, function(dT)
                expect(function()
                    state.draft.getState(dT)
                end).to.never.throw()
            end)

            expect(function()
                state.draft.getState(t)
            end).to.throw()
        end)

        it("should return the current state of a draft", function()
            local baseState = { 1, 2, 3, 4 }
            local currentState

            local newState = state.produce(baseState, function(draftState)
                state.table.append(draftState, 5)
                currentState = state.draft.getState(draftState)
                state.table.append(draftState, 6)
            end)

            expect(currentState).to.never.equal(baseState)
            expect(currentState).to.never.equal(newState)
            expect(state.draft.isDraft(currentState)).to.equal(false)
            expect(currentState[5]).to.equal(5)
        end)

        it("should return the base state if no changes were made", function()
            local baseState = { 1, 2, 3, 4 }
            local currentState

            state.produce(baseState, function(draftState)
                currentState = state.draft.getState(draftState)
            end)

            expect(currentState).to.equal(baseState)
        end)

        it("should not return immutable state unless the base state was immutable", function()
            local baseState = table.freeze({ 1, 2, 3, 4 })
            local baseState2 = table.freeze({ 1, 2, 3, 4 })

            local currentState
            local currentState2

            state.produce(baseState, function(draftState)
                currentState = state.draft.getState(draftState)
            end)

            state.produce(baseState2, function(draftState)
                state.table.append(draftState, 5)
                currentState2 = state.draft.getState(draftState)
            end)

            expect(currentState).to.equal(baseState)
            expect(currentState2).to.never.equal(baseState2)

            expect(table.isfrozen(currentState)).to.equal(true)
            expect(table.isfrozen(currentState2)).to.equal(false)
        end)
    end)
end