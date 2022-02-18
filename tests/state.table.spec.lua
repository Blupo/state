local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local state = require(ReplicatedStorage:FindFirstChild("state"))

---

return function()
    it("should have a public API", function()
        expect(state.table.append).to.be.a("function")
        expect(state.table.getn).to.be.a("function")
        expect(state.table.insert).to.be.a("function")
        expect(state.table.remove).to.be.a("function")
    end)

    describe("state.table.getn", function()
        it("should correctly determine the length of a drafted table", function()
            local baseState = {
                test = {"A", { 1 }, 3, 4}
            }

            state.produce(baseState, function(draftState)
                expect(#draftState.test).to.never.equal(#baseState.test)
                expect(state.table.getn(draftState.test)).to.equal(#baseState.test)
            end)
        end)

        it("should interpret state.undefined correctly", function()
            local baseState = {
                test = {"A", { 1 }, 3, 4}
            }

            state.produce(baseState, function(draftState)
                draftState.test[3] = nil

                expect(#draftState.test).to.never.equal(#baseState.test)
                expect(state.table.getn(draftState.test)).to.equal(2)
            end)
        end)

        it("should be equivalent to table.getn for non-draft tables", function()
            local t = {"A", { 1 }, nil , 4}

            expect(state.table.getn(t)).to.equal(#t)
        end)
    end)

    describe("state.table.insert", function()
        it("should correctly insert values into a drafted table", function()
            local baseState = {
                test = {1, 2, 3, 4}
            }

            state.produce(baseState, function(draftState)
                state.table.insert(draftState.test, 1, 0)

                expect(draftState.test[1]).to.equal(0)
            end)
        end)

        it("should interpret state.undefined correctly", function()
            local baseState = {
                test = {1, 2, 3, 4}
            }

            state.produce(baseState, function(draftState)
                draftState.test[3] = nil
                state.table.insert(draftState.test, state.table.getn(draftState.test) + 1, 0)

                expect(draftState.test[3]).to.equal(0)
            end)
        end)

        it("should work equivalent to table.insert for non-draft tables", function()
            local t1 = {1, 2, nil, 4}
            local t2 = {1, 2, nil, 4}

            state.table.insert(t1, 3, 0)
            table.insert(t2, 3, 0)

            expect(t1[3]).to.equal(t2[3])
            expect(t1[3]).to.equal(0)
            expect(t2[3]).to.equal(0)
        end)
    end)

    describe("state.table.append", function()
        it("should correctly append values onto a drafted table", function()
            local baseState = {
                test = {1, 2, 3, 4}
            }

            state.produce(baseState, function(draftState)
                state.table.append(draftState.test, 5)

                expect(draftState.test[5]).to.equal(5)
            end)
        end)

        it("should interpret state.undefined correctly", function()
            local baseState = {
                test = {1, 2, 3, 4}
            }

            state.produce(baseState, function(draftState)
                draftState.test[4] = nil
                state.table.append(draftState.test, 5)

                expect(draftState.test[4]).to.equal(5)
            end)
        end)

        it("should work equivalent to table.insert for non-draft tables", function()
            local t1 = {1, 2, 3}
            local t2 = {1, 2, 3}

            state.table.append(t1, 4)
            table.insert(t2, 4)

            expect(t1[4]).to.equal(t2[4])
            expect(t1[4]).to.equal(4)
            expect(t2[4]).to.equal(4)
        end)
    end)

    describe("state.table.remove", function()
        it("should correctly remove values from a drafted table", function()
            local baseState = {
                test = {1, 2, 3, 4}
            }

            state.produce(baseState, function(draftState)
                state.table.remove(draftState.test, 1)
                expect(draftState.test[1]).to.equal(2)

                state.table.remove(draftState.test)
                expect(draftState.test[3]).to.equal(nil)
                expect(draftState.test[4]).to.equal(nil)
            end)
        end)

        it("should work equivalent to table.remove for non-draft tables", function()
            local t1 = {1, 2, 3, 4}
            local t2 = {1, 2, 3, 4}

            state.table.remove(t1, 3)
            table.remove(t2, 3)
            
            expect(t1[3]).to.equal(t2[3])
            expect(t1[3]).to.equal(4)
        end)
    end)
end