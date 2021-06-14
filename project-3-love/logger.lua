local logger = {}

function logger.printLog(name, activity)
    print("[+] " .. name .. ": ", activity)
end

function logger.writeLog(filename, node_id, event)
    local file = nil
    file = assert(io.open("log/" .. filename, "a+"))
    file:write(os.date("%Y-%m-%d %H:%M:%S"), " , ", node_id, " , ", event)
    file:write("\n")
    file:close()
end

return logger