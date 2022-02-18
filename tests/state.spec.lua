local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local state = require(ReplicatedStorage:FindFirstChild("state"))

---

return function()
    it("should have a public API", function()
        expect(state.produce).to.be.a("function")
        expect(state.table).to.be.a("table")
        expect(state.iter).to.be.a("table")
        expect(state.undefined).to.be.a("userdata")
    end)

    describe("state.produce", function()
        it("should produce immutable states", function()
            local baseState = {}
            local newState

            newState = state.produce(baseState, function(draftState)
                state.table.append(draftState, 1)
            end)

            expect(table.isfrozen(newState)).to.equal(true)
        end)

        it("should persist unchanged values", function()
            local baseState = {
                A = true,
                B = false,
                C = { 1 },
                D = { { 2 } }
            }

            local newState = state.produce(baseState, function(draftState)
                draftState.C[1] = 3
                
                state.table.append(draftState.D, { 3 })
            end)

            expect(newState).to.never.equal(baseState)
            expect(newState.A).to.equal(baseState.A)
            expect(newState.B).to.equal(baseState.B)
            expect(newState.C).to.never.equal(baseState.C)
            expect(newState.D).to.never.equal(baseState.D)
            expect(newState.D[1]).to.equal(baseState.D[1])
        end)
    end)

    describe("state.undefined", function()
        it("should be used internally when setting a value to nil", function()
            local baseState = {
                test = true
            }

            local newState = state.produce(baseState, function(draftState)
                draftState.test = nil
            end)

            expect(newState).to.never.equal(baseState)
            expect(newState.test).to.equal(nil)
        end)

        it("should be used to unset changes", function()
            local baseState = {
                test = 1
            }

            local newState = state.produce(baseState, function(draftState)
                draftState.test = 5
                expect(draftState.test).to.equal(5)

                draftState.test = state.undefined
            end)

            expect(newState).to.equal(baseState)
            expect(newState.test).to.equal(1)
        end)

        it("should not render changes if the base value was already nil", function()
            local baseState = {}
            local newState

            newState = state.produce(baseState, function(draftState)
                draftState.test = nil
            end)

            expect(newState).to.equal(baseState)
        end)
    end)
end