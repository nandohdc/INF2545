local json = require "json-lua/json"

local message = {}

-------------------------------------------------------------------------------
-- Attributes
-------------------------------------------------------------------------------
message.type = nil
message.recentNodes = {}
message.TTL = nil
message.agentTable = {
    event = {},
    distance = {}
}

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------
function message:getEncoded()
    return json.encode({TTL = self.TTL, recentNodes = self.recentNodes})
end

function message:Decode(serial_msg)
    local decoded_msg = json.decode(serial_msg)
    self.TTL = decoded_msg.TTL
    self.recentNodes = decoded_msg.recentNodes
end

function message:setTTL(val)
    self.TTL = val
end

function message:addNewNode(new_node)
    table.insert(self.recentNodes, new_node)
end

function message:isALive()
    if self.TTL == 0 then return false end
    return true
end

function message:reduceTTL()
    self.TTL = self.TTL - 1
end

function message:getRecentNodes()
    return self.recentNodes
end

return message