local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local state = require(ReplicatedStorage:FindFirstChild("state"))

---

return function()
    it("should have a public API", function()
        expect(state.draft.getRef).to.be.a("function")
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
            local baseState = {
                A = {
                    B = {
                        C = {
                            D = 1
                        }
                    }
                }
            }

            expect(function()
                state.draft.getRef(baseState.A)
            end).to.throw()

            expect(function()
                state.draft.getRef(baseState.A.B.C.D)
            end).to.throw()
        end)
    end)
end