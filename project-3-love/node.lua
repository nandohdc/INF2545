-- esqueleto do objeto nó
local node = {
    id = nil,
    neighborList = {},
    eventTable = {},

    broadCastHelloPacket = function(self)
        -- packet message with self.id
    end,
}

return node