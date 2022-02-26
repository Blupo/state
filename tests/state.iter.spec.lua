local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local state = require(ReplicatedStorage:FindFirstChild("state"))

---

return function()
    it("should have a public API", function()
        expect(state.iter.pairs).to.be.a("function")
        expect(state.iter.ipairs).to.be.a("function")
    end)

    describe("state.iter.pairs", function()
        it("should be an iterator for kv-pairs", function()
            local c = Color3.new()

            local baseState = {
                A = 1,
                B = 2,
                C = 3,
                [c] = 4,
            }

            state.produce(baseState, function(draftState)
                local t = {}

                for k, v in state.iter.pairs(draftState) do
                    t[k] = v
                end

                for k, v in pairs(t) do
                    expect(baseState[k]).to.equal(v)
                end

                expect(draftState.A).to.equal(1)
                expect(draftState.B).to.equal(2)
                expect(draftState.C).to.equal(3)
                expect(draftState[c]).to.equal(4)
            end)
        end)

        it("should interpret state.undefined correctly", function()
            local userdata  = newproxy(false)

            local baseState = {
                A = 1,
                B = 2,
                C = 3,
                [userdata] = 4,
            }

            state.produce(baseState, function(draftState)
                draftState.B = nil

                local t = {}

                for k, v in state.iter.pairs(draftState) do
                    t[k] = v
                end

                for k, v in pairs(t) do
                    expect(k).to.never.equal("B")
                    expect(baseState[k]).to.equal(v)
                end

                expect(draftState.A).to.equal(1)
                expect(draftState.B).to.equal(nil)
                expect(draftState.C).to.equal(3)
                expect(draftState[userdata]).to.equal(4)
            end)
        end)

        it("should work equivalent to pairs for non-draft tables", function()
            local baseState = {
                A = "A",
                B = 2,
                C = {},
            }

            baseState.D = math.random()
            baseState.E = math.random(0, 255)

            baseState.D = nil

            local t1 = {}
            local t2 = {}

            for k, v in pairs(baseState) do
                t1[k] = v
            end

            for k, v in state.iter.pairs(baseState) do
                t2[k] = v
            end

            for k, v in pairs(t1) do
                expect(t2[k]).to.equal(v)
            end
        end)

        it("should handle setting values to nil correctly", function()
            local t = {
                A = 1,
                B = 2,
                C = 3,
                D = 4,
            }

            t.E = 5
            t.F = 7

            for k in state.iter.pairs(t) do
                t[k] = nil
            end

            expect(t.A).to.equal(nil)
            expect(t.B).to.equal(nil)
            expect(t.C).to.equal(nil)
            expect(t.D).to.equal(nil)
            expect(t.E).to.equal(nil)
            expect(t.F).to.equal(nil)
        end)
    end)

    describe("state.iter.ipairs", function()
        it("should be an iterator for iv-pairs", function()
            local baseState = {
                {1, 2, 3},
                {4, 5, 6},
                {7, 8, 9}
            }

            state.produce(baseState, function(draftState)
                local lastRowN = 0

                for rowN, row in state.iter.ipairs(draftState) do
                    expect(rowN).to.be.a("number")
                    expect(rowN - 1).to.equal(lastRowN)
                    expect(state.table.getn(row)).to.equal(3)

                    local lastColumnN = 0
                    lastRowN = rowN

                    for columnN, n in state.iter.ipairs(row) do
                        expect(columnN).to.be.a("number")
                        expect(columnN - 1).to.equal(lastColumnN)
                        expect(n).to.be.a("number")
                        
                        lastColumnN = columnN
                    end
                end
            end)
        end)

        it("should interpret state.undefined correctly", function()
            local baseState = {
                { 1,  2,  3,  4},
                { 5,  6,  7,  8},
                { 9, 10, 11, 12},
                {13, 14, 15, 16},
            }

            state.produce(baseState, function(draftState)
                draftState[2][2] = nil
                draftState[3] = nil

                for i in state.iter.ipairs(draftState[2]) do
                    expect(i).to.never.equal(2)
                    expect(i).to.never.equal(3)
                    expect(i).to.never.equal(4)
                end

                for i in state.iter.ipairs(draftState) do
                    expect(i).to.never.equal(3)
                    expect(i).to.never.equal(4)
                end
            end)
        end)

        it("should work equivalent to ipairs for non-draft tables", function()
            local baseState = {
                {1, 2, 3},
                {4, 5, 6},
                {7, 8, 9}
            }

            local t1 = 0
            local t2 = 0

            for _, u in ipairs(baseState) do
                for _, v in ipairs(u) do
                    t1 = t1 + v
                end
            end

            for _, u in ipairs(baseState) do
                for _, v in ipairs(u) do
                    t2 = t2 + v
                end
            end

            expect(t2).to.equal(t1)
            expect(t2).to.equal(45)
        end)
    end)
end