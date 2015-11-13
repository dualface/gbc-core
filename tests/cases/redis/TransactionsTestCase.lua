--[[
z
Copyright (c) 2015 gameboxcloud.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

local tests = cc.load("tests")
local check = tests.Check

local TransactionsTestCase = class("TransactionsTestCase", tests.TestCase)

TransactionsTestCase.ACCEPTED_REQUEST_TYPE = {"http", "cli"}

function TransactionsTestCase:setup()
end

function TransactionsTestCase:teardown()
end

-- DISCARD
-- Discard all commands issued after MULTI
function TransactionsTestCase:discardTest()
end

-- EXEC
-- Execute all commands issued after MULTI
function TransactionsTestCase:execTest()
end

-- MULTI
-- Mark the start of a transaction block
function TransactionsTestCase:multiTest()
end

-- UNWATCH
-- Forget about all watched keys
function TransactionsTestCase:unwatchTest()
end

-- WATCH key [key ...]
-- Watch the given keys to determine execution of the MULTI/EXEC block
function TransactionsTestCase:watchTest()
end

return TransactionsTestCase
