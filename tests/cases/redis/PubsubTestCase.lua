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

local PubsubTestCase = class("PubsubTestCase", tests.TestCase)

PubsubTestCase.ACCEPTED_REQUEST_TYPE = {"http", "cli"}

function PubsubTestCase:setup()
end

function PubsubTestCase:teardown()
end

-- PSUBSCRIBE pattern [pattern ...]
-- Listen for messages published to channels matching the given patterns
function PubsubTestCase:psubscribeTest()
end

-- PUBSUB subcommand [argument [argument ...]]
-- Inspect the state of the Pub/Sub subsystem
function PubsubTestCase:pubsubTest()
end

-- PUBLISH channel message
-- Post a message to a channel
function PubsubTestCase:publishTest()
end

-- PUNSUBSCRIBE [pattern [pattern ...]]
-- Stop listening for messages posted to channels matching the given patterns
function PubsubTestCase:punsubscribeTest()
end

-- SUBSCRIBE channel [channel ...]
-- Listen for messages published to the given channels
function PubsubTestCase:subscribeTest()
end

-- UNSUBSCRIBE [channel [channel ...]]
-- Stop listening for messages posted to the given channels
function PubsubTestCase:unsubscribeTest()
end

return PubsubTestCase
