local Package = game:GetService("ReplicatedStorage").Fusion
local childAppearsLater = require(Package.Memory.childAppearsLater)

return function()
	it("allows correct order in flat arrays", function()
		expect(childAppearsLater({"p", "c"}, "p", "c")).to.equal(true)
		expect(childAppearsLater({1, 2, 3, "p", "c", 4, 5, 6}, "p", "c")).to.equal(true)
		expect(childAppearsLater({1, "p", 2, 3, 4, "c", 5, 6}, "p", "c")).to.equal(true)
		expect(childAppearsLater({"p", 1, 2, 3, 4, 5, 6, "c"}, "p", "c")).to.equal(true)
		expect(childAppearsLater({"p", "c", 1, 2, 3, 4, 5, 6}, "p", "c")).to.equal(true)
		expect(childAppearsLater({1, 2, 3, 4, 5, 6, "p", "c"}, "p", "c")).to.equal(true)
	end)
	it("disallows incorrect order in flat arrays", function()
		expect(childAppearsLater({"c", "p"}, "p", "c")).to.equal(false)
		expect(childAppearsLater({1, 2, 3, "c", "p", 4, 5, 6}, "p", "c")).to.equal(false)
		expect(childAppearsLater({1, "c", 2, 3, 4, "p", 5, 6}, "p", "c")).to.equal(false)
		expect(childAppearsLater({"c", 1, 2, 3, 4, 5, 6, "p"}, "p", "c")).to.equal(false)
		expect(childAppearsLater({"c", "p", 1, 2, 3, 4, 5, 6}, "p", "c")).to.equal(false)
		expect(childAppearsLater({1, 2, 3, 4, 5, 6, "c", "p"}, "p", "c")).to.equal(false)
	end)
	it("disallows absent children in flat arrays", function()
		expect(childAppearsLater({"p"}, "p", "c")).to.equal(false)
		expect(childAppearsLater({1, 2, 3, "p", 4, 5, 6}, "p", "c")).to.equal(false)
		expect(childAppearsLater({"p", 1, 2, 3, 4, 5, 6}, "p", "c")).to.equal(false)
		expect(childAppearsLater({1, 2, 3, 4, 5, 6, "p"}, "p", "c")).to.equal(false)
	end)
	it("allows correct order in nested arrays", function()
		expect(childAppearsLater({{"p"}, {"c"}}, "p", "c")).to.equal(true)
		expect(childAppearsLater({1, {2, 3, "p"}, "c", 4, 5, 6}, "p", "c")).to.equal(true)
		expect(childAppearsLater({{1, {"p"}}, 2, {3, 4}, {"c", 5, 6}}, "p", "c")).to.equal(true)
		expect(childAppearsLater({"p", 1, 2, 3, {4, 5, 6, "c"}}, "p", "c")).to.equal(true)
		expect(childAppearsLater({"p", {"c", 1, 2, 3, 4}, 5, 6}, "p", "c")).to.equal(true)
		expect(childAppearsLater({1, {{2, 3}, 4, 5, 6, "p"}, "c"}, "p", "c")).to.equal(true)
	end)
	it("disallows incorrect order in nested arrays", function()
		expect(childAppearsLater({{"c"}, {"p"}}, "p", "c")).to.equal(false)
		expect(childAppearsLater({1, {2, 3, "c"}, "p", 4, 5, 6}, "p", "c")).to.equal(false)
		expect(childAppearsLater({{1, {"c"}}, 2, {3, 4}, {"p", 5, 6}}, "p", "c")).to.equal(false)
		expect(childAppearsLater({"c", 1, 2, 3, {4, 5, 6, "p"}}, "p", "c")).to.equal(false)
		expect(childAppearsLater({"c", {"p", 1, 2, 3, 4}, 5, 6}, "p", "c")).to.equal(false)
		expect(childAppearsLater({1, {{2, 3}, 4, 5, 6, "c"}, "p"}, "p", "c")).to.equal(false)
	end)
	it("disallows absent children in nested arrays", function()
		expect(childAppearsLater({{"p"}}, "p", "c")).to.equal(false)
		expect(childAppearsLater({1, {2, 3, "p"}, 4, 5, 6}, "p", "c")).to.equal(false)
		expect(childAppearsLater({"p", 1, 2, 3, {4, 5, 6}}, "p", "c")).to.equal(false)
		expect(childAppearsLater({1, {{2, 3}, 4, 5, 6}, "p"}, "p", "c")).to.equal(false)
	end)
end