local logger = {}

logger.filename = nil

function logger:setFilename(node_id)
    self.filename = "logNODE-"..node_id..".csv"
end

function logger.printLog(name, activity)
    print("[+] " .. name .. ": ", activity)
end

function logger.writeLog(node_id, event)
    local file = nil
    file = assert(io.open("log/" .. logger.filename, "a+"))
    file:write(os.date("%Y-%m-%d %H:%M:%S"), " , ", node_id, " , ", event)
    file:write("\n")
    file:close()
end

return logger