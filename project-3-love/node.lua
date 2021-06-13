local node = {}

-------------------------------------------------------------------------------
-- Attributes
-------------------------------------------------------------------------------
node.id = nil
node.topic = nil
node.subscriptions = nil
node.neighborList = {} -- The neighbor list can be actively created and maintained
    -- by actively broadcasting a request, or passively, through listening
    -- for other node broadcasts

node.eventTable = {}

-------------------------------------------------------------------------------
-- Getters and Setters
-------------------------------------------------------------------------------
node.setId = function(self, id) 
    self.id = id
end

node.setTopic = function(self, topic)
    self.topic = topic
end

node.setSubscriptions = function (self, subscriptions)
    self.subscriptions = subscriptions
end

-------------------------------------------------------------------------------
-- Routing functions
-------------------------------------------------------------------------------
node.broadCastHelloPacket = function(self)
        -- packet message with self.id
end

node.witnessEvent = function(self)
        -- When a node witnesses an event, it adds it to its event table, with a distance of zero to the event. It also probabilistically
        -- generates an agent. The probability of generating an agent is an
        -- algorithm parameter, and is explored in the experiment section.
end

return node