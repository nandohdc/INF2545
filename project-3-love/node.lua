local node = {}

-------------------------------------------------------------------------------
-- Attributes
-------------------------------------------------------------------------------
node.id = nil
node.topic = nil
node.subscriptions = nil
node.neighborList = {}
node.routes = { Events = {}, Dist = {}, Dir = {} }

-------------------------------------------------------------------------------
-- Methods
-------------------------------------------------------------------------------
function node:setId(id)
    self.id = id
end

function node:setTopic(topic)
    self.topic = topic
end

function node:setSubscriptions(subscriptions)
    self.subscriptions = subscriptions
end

function node:getId()
    return self.id
end

function node:getSubscriptions()
    return self.subscriptions
end

function node:getNeighborList()
    local t2 = {}
    for pos, v in pairs(self.neighborList) do 
        t2[pos] = v
    end
    return t2
end

function node:createNeighborList()
    for _, subscription in pairs(node.subscriptions) do
       table.insert(node.neighborList, tonumber(string.sub(subscription, 8)))
    end
end

return node