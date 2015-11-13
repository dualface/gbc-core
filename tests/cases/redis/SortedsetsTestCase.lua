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

local SortedsetsTestCase = class("SortedsetsTestCase", tests.TestCase)

SortedsetsTestCase.ACCEPTED_REQUEST_TYPE = {"http", "cli"}

function SortedsetsTestCase:setup()
end

function SortedsetsTestCase:teardown()
end

-- ZADD key [NX|XX] [CH] [INCR] score member [score member ...]
-- Add one or more members to a sorted set, or update its score if it already exists
function SortedsetsTestCase:zaddTest()
end

-- ZCARD key
-- Get the number of members in a sorted set
function SortedsetsTestCase:zcardTest()
end

-- ZCOUNT key min max
-- Count the members in a sorted set with scores within the given values
function SortedsetsTestCase:zcountTest()
end

-- ZINCRBY key increment member
-- Increment the score of a member in a sorted set
function SortedsetsTestCase:zincrbyTest()
end

-- ZINTERSTORE destination numkeys key [key ...] [WEIGHTS weight [weight ...]] [AGGREGATE SUM|MIN|MAX]
-- Intersect multiple sorted sets and store the resulting sorted set in a new key
function SortedsetsTestCase:zinterstoreTest()
end

-- ZLEXCOUNT key min max
-- Count the number of members in a sorted set between a given lexicographical range
function SortedsetsTestCase:zlexcountTest()
end

-- ZRANGE key start stop [WITHSCORES]
-- Return a range of members in a sorted set, by index
function SortedsetsTestCase:zrangeTest()
end

-- ZRANGEBYLEX key min max [LIMIT offset count]
-- Return a range of members in a sorted set, by lexicographical range
function SortedsetsTestCase:zrangebylexTest()
end

-- ZREVRANGEBYLEX key max min [LIMIT offset count]
-- Return a range of members in a sorted set, by lexicographical range, ordered from higher to lower strings.
function SortedsetsTestCase:zrevrangebylexTest()
end

-- ZRANGEBYSCORE key min max [WITHSCORES] [LIMIT offset count]
-- Return a range of members in a sorted set, by score
function SortedsetsTestCase:zrangebyscoreTest()
end

-- ZRANK key member
-- Determine the index of a member in a sorted set
function SortedsetsTestCase:zrankTest()
end

-- ZREM key member [member ...]
-- Remove one or more members from a sorted set
function SortedsetsTestCase:zremTest()
end

-- ZREMRANGEBYLEX key min max
-- Remove all members in a sorted set between the given lexicographical range
function SortedsetsTestCase:zremrangebylexTest()
end

-- ZREMRANGEBYRANK key start stop
-- Remove all members in a sorted set within the given indexes
function SortedsetsTestCase:zremrangebyrankTest()
end

-- ZREMRANGEBYSCORE key min max
-- Remove all members in a sorted set within the given scores
function SortedsetsTestCase:zremrangebyscoreTest()
end

-- ZREVRANGE key start stop [WITHSCORES]
-- Return a range of members in a sorted set, by index, with scores ordered from high to low
function SortedsetsTestCase:zrevrangeTest()
end

-- ZREVRANGEBYSCORE key max min [WITHSCORES] [LIMIT offset count]
-- Return a range of members in a sorted set, by score, with scores ordered from high to low
function SortedsetsTestCase:zrevrangebyscoreTest()
end

-- ZREVRANK key member
-- Determine the index of a member in a sorted set, with scores ordered from high to low
function SortedsetsTestCase:zrevrankTest()
end

-- ZSCORE key member
-- Get the score associated with the given member in a sorted set
function SortedsetsTestCase:zscoreTest()
end

-- ZUNIONSTORE destination numkeys key [key ...] [WEIGHTS weight [weight ...]] [AGGREGATE SUM|MIN|MAX]
-- Add multiple sorted sets and store the resulting sorted set in a new key
function SortedsetsTestCase:zunionstoreTest()
end

-- ZSCAN key cursor [MATCH pattern] [COUNT count]
-- Incrementally iterate sorted sets elements and associated scores
function SortedsetsTestCase:zscanTest()
end

return SortedsetsTestCase
