-- Scripts/tests/run_test.lua
-- Lightweight test runner for injectable tests
-- Usage: local T = dofile(_G.SCRIPTS_PATH .. "\\tests\\run_test.lua")
--        T.run("test name", function() ... end)

local T = {}
T._passed = 0
T._failed = 0
T._errors = {}

function T.run(name, test_fn)
	local ok, err = pcall(test_fn)
	if ok then
		T._passed = T._passed + 1
		print("PASS: " .. name)
	else
		T._failed = T._failed + 1
		T._errors[#T._errors + 1] = { name = name, err = tostring(err) }
		print("FAIL: " .. name .. " -- " .. tostring(err))
	end
	return ok
end

function T.assert_eq(actual, expected, label)
	label = label or ""
	if actual ~= expected then
		error(label .. " expected [" .. tostring(expected) .. "] got [" .. tostring(actual) .. "]")
	end
end

function T.assert_true(val, label)
	if not val then
		error((label or "") .. " expected true, got " .. tostring(val))
	end
end

function T.assert_false(val, label)
	if val then
		error((label or "") .. " expected false, got " .. tostring(val))
	end
end

function T.assert_nil(val, label)
	if val ~= nil then
		error((label or "") .. " expected nil, got " .. tostring(val))
	end
end

function T.assert_not_nil(val, label)
	if val == nil then
		error((label or "") .. " expected non-nil")
	end
end

function T.assert_type(val, expected_type, label)
	if type(val) ~= expected_type then
		error((label or "") .. " expected type " .. expected_type .. ", got " .. type(val))
	end
end

function T.summary()
	print(string.format("\n=== RESULTS: %d passed, %d failed ===", T._passed, T._failed))
	if #T._errors > 0 then
		print("Failures:")
		for _, e in ipairs(T._errors) do
			print("  - " .. e.name .. ": " .. e.err)
		end
	end
	return T._failed == 0
end

function T.reset()
	T._passed = 0
	T._failed = 0
	T._errors = {}
end

return T
