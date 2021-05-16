local luarpc = require "luarpc"
---------------------------------------------------------------------
-- Server Remote Procedure Call (RPC)
--
-- Objetivo: Criar uma biblioteca de remote procedure call em lua.
--
-- Módulos Utilizados:
---- luarpc
--
-----------------------------------------------------------------------
local librpc = require("luarpc")
local replica = require("replica")
local json = require("json-lua/json")
local dumper = require("penlight-lua/pretty")
local counter = require("penlight-lua/tablex")

local function readAll(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

local function checkIPv4(ip)
    if ip == nil then
        librpc.logger("checkIPv4", "Nenhum Internet Protocol foi fornecido")
        local new_ip = "127.0.0.1"
        librpc.logger("checkIPv4", "Adotando o Internet Protocol de Local Host - IP: " .. new_ip)
        return new_ip
    end

    if type(ip) ~= "string" then
        librpc.logger("checkIPv4", "Tipo de Variável Inválido")
        return false
    end

    local octs = {ip:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")}
    if (#octs == 4) then
        for _, v in pairs(octs) do
            if (tonumber(v) < 0 or tonumber(v) > 255) then
                librpc.logger("checkIPv4", "Formato IPv4 Inválido - Valor Fornecido: " .. ip)
                return false
            end
        end
        librpc.logger("checkIPv4", "Internet Protocol fornecido - IP: " .. ip)
        return ip
    else
        librpc.logger("checkIPv4", "Formato IPv4 Inválido - Valor Fornecido: " .. ip)
        return false
    end
end

local function checkPort(port)
    if port == nil or port == "" then
        librpc.logger("checkPort", "Nenhuma Porta foi fornecida.")
        return false
    end
    if (tonumber(port) > 65535) then
        librpc.logger("checkPort", "Porta Inválida - Valor Máximo: 65535")
        return false
    elseif (tonumber(port) < 1) then
        librpc.logger("checkPort", "Porta Inválida - Valor Mínimo: 1")
        return false
    end
    return port
end

local function checkHASHID(new_hash_id, list_hash_id)
    for index, value in ipairs(list_hash_id) do
        if new_hash_id == list_hash_id[index] then
            return true
        end
    end
    return false
end

local function checkConfigs(configs, new_hash_id)
    local hash_id_list = {}
    local servers = {}
    local server_config = {}
    local instances = configs["Instances"]
    local filepath = configs["Interface"]
    if counter.size(configs["Servers"]) ~= instances then
        librpc.logger("checkConfigs", "Número de Replicas diferente de Servidores.")
        librpc.logger("checkConfigs", "Finalizando o Programa.")
        return false
    end

    for index, value in ipairs(configs["Servers"]) do
        table.insert(hash_id_list, index, configs["Servers"][index][1])
        if (counter.size(configs["Servers"][index]) ~= 3) then
            librpc.logger("checkConfigs", "Quantidade de Parâmetros de Configuração Inválidos.")
            librpc.logger("checkConfigs", "Finalizando o Programa.")
            return false
        end
    end

    for index, value in ipairs(configs["Servers"]) do
        if (not checkHASHID(new_hash_id, hash_id_list)) then
            librpc.logger("checkConfigs", "Hash ID Inválido.")
            librpc.logger("checkConfigs", "Finalizando o Programa.")
            return false
        else
            if (not checkIPv4(configs["Servers"][index][2])) then
                librpc.logger("checkConfigs", "Parâmetro IP de Configuração Inválido.")
                librpc.logger("checkConfigs", "Finalizando o Programa.")
                return false
            elseif (not checkPort(configs["Servers"][index][3])) then
                librpc.logger("checkConfigs", "Parâmetro Porta de Configuração Inválido.")
                librpc.logger("checkConfigs", "Finalizando o Programa.")
                return false
            end
            if (new_hash_id ~= configs["Servers"][index][1]) then
                table.insert(
                    servers,
                    {
                        HASHID = configs["Servers"][index][1],
                        IP = configs["Servers"][index][2],
                        PORT = configs["Servers"][index][3]
                    }
                )
            else
                table.insert(
                    server_config,
                    {
                        HASHID = configs["Servers"][index][1],
                        IP = configs["Servers"][index][2],
                        PORT = configs["Servers"][index][3]
                    }
                )
            end
        end
    end
    return servers, server_config, instances, filepath
end

local function display_info (local_server_config, local_myconfig)
  print("ID: " .. local_myconfig[1]["HASHID"], "IP: " .. local_myconfig[1]["IP"], "PORT: " .. local_myconfig[1]["PORT"], "*")
  for index, value in ipairs(local_server_config) do
    print("ID: " .. value["HASHID"], "IP: " .. value["IP"], "PORT: " .. value["PORT"])  
  end
end

local function createStubs(local_replica_obj, local_my_configs, local_servers, local_timeout)
    local self_stubs = {}

    self_stubs.requestVotes = function (candidate_hash_id, candidate_term)
      local canVote = "NO"

      if (tonumber(candidate_term) > tonumber(local_replica_obj.get_term())) then
        canVote = "YES"
        local_replica_obj.set_term(candidate_term)
        local_replica_obj.set_heartbeat()

        if (not local_replica_obj.check_follower()) then
          local_replica_obj.set_votes(0)
          local_replica_obj.set_state("FOLLOWER")
        end
      end

      local file = assert(io.open("log"..local_replica_obj.get_id()..".txt", "a+"))
      file:write(os.date("%Y-%m-%d %H:%M:%S"),",", local_replica_obj.get_id(),",","REQUEST VOTE", ",", "REPLICA_ID: "..local_replica_obj.get_id(), ",","CANIDATE_ID: "..candidate_hash_id, ",", "REPLICA_TERM: "..local_replica_obj.get_term(), ",", "CANDIDATE_TERM: "..candidate_term, ",", "RESULT: "..canVote)
      file:write("\n")
      file:close()
      -- print("OK3")
      return local_replica_obj.get_term(), canVote
    end

    self_stubs.appendEntries = function (leader_id, leader_term)
      local beat = "NO"

      local file = assert(io.open("log"..local_replica_obj.get_id()..".txt", "a+"))
      file:write(os.date("%Y-%m-%d %H:%M:%S"),",", local_replica_obj.get_id(),",","HEARTBEAT RECEIVED", ",", "REPLICA_ID: "..local_replica_obj.get_id(), ",","LEADER_ID: "..leader_id, ",", "REPLICA_TERM: "..local_replica_obj.get_term(), ",", "LEADER_TERM:"..leader_term, ",", "RESULT: "..beat)
      file:write("\n")
      file:close()

      if(tonumber(leader_term) >= tonumber(local_replica_obj.get_term())) then
        beat = "YES"
        local_replica_obj.set_heartbeat()

        if (not local_replica_obj.check_follower()) then
          local_replica_obj.set_votes(0)
          local_replica_obj.set_state("FOLLOWER")
        end

        if (tonumber(leader_term) > tonumber(local_replica_obj.get_term())) then
          local_replica_obj.set_term(leader_term)
        end
      end
      return local_replica_obj.get_term(), beat
    end

    self_stubs.execute = function (interface_path)
      local proxies_connection = {}
      local new_heartbeat = nil
      
      if (tonumber(local_timeout) ~= nil) then
        new_heartbeat = local_timeout
      else
        new_heartbeat = local_replica_obj.generateRandomHeartbeat()
      end

      local_replica_obj.set_heartbeat()

      librpc.logger("Execute", string.format("Creating Proxy - IP: %s , Port: %s %s" , local_my_configs[1]["IP"], local_my_configs[1]["PORT"], "*"))

      librpc.createProxy(local_my_configs[1]["IP"], local_my_configs[1]["PORT"], interface_path)
      
      for index, value in ipairs(local_servers) do
        librpc.logger("Execute", string.format("Creating Proxy - IP: %s , Port: %s" , local_servers[index]["IP"], local_servers[index]["PORT"]))
        table.insert(proxies_connection, librpc.createProxy(local_servers[index]["IP"], local_servers[index]["PORT"], interface_path))
      end

      while true do
        if (local_replica_obj.check_leader()) then
          local file = assert(io.open("log"..local_replica_obj.get_id()..".txt", "a+"))
          file:write(os.date("%Y-%m-%d %H:%M:%S"),",", local_replica_obj.get_id(),",","REQUEST HEARTBEAT", ",","REPLICA_ID: ".. local_replica_obj.get_id(), ",", "REPLICA_TERM: "..local_replica_obj.get_term())
          file:write("\n")
          file:close()
          
          for index, value in ipairs(proxies_connection) do
            local instance = proxies_connection[index]
            -- print(local_replica_obj.get_id(), local_replica_obj.get_term())
            local acknowledge, beat = instance.appendEntries(local_replica_obj.get_id(), local_replica_obj.get_term())

            if (acknowledge == "__ERROR_CONN") then
              librpc.logger("Execute","Connection Problem. Removing Replica - ID:"..local_replica_obj.get_id())
              file:write(os.date("%Y-%m-%d %H:%M:%S"),",", local_replica_obj.get_id(),","," REMOVING REPLICA")
              file:write("\n")
              file:close()
              table.remove(proxies_connection, index)
              local_replica_obj.set_replicas(local_replica_obj.get_replicas() - 1)

            else
              file = assert(io.open("log"..local_replica_obj.get_id()..".txt", "a+"))
              file:write(os.date("%Y-%m-%d %H:%M:%S"),",", local_replica_obj.get_id(),",","RECEIVED HEARTBEAT", "REPLICA_ID: ".. local_replica_obj.get_id(), ",", "REPLICA_TERM: "..local_replica_obj.get_term())
              file:write("\n")
              file:close()

              if (tonumber(acknowledge) > tonumber(local_replica_obj.get_term())) then
                local_replica_obj.set_term(acknowledge)
                local_replica_obj.set_votes(0)
                local_replica_obj.set_state("FOLLOWER")
                local_replica_obj.set_heartbeat()
              end
            end
          end
          if (counter.size(proxies_connection) + 1 == local_replica_obj.get_replicas()) then
            file = assert(io.open("log"..local_replica_obj.get_id()..".txt", "a+"))
            file:write(os.date("%Y-%m-%d %H:%M:%S"),",", local_replica_obj.get_id(),",","HEARTBEAT SUCCEED! TOTAL RECEIVED: ", counter.size(proxies_connection))
            file:write("\n")
            file:close()
          else
            file = assert(io.open("log"..local_replica_obj.get_id()..".txt", "a+"))
            file:write(os.date("%Y-%m-%d %H:%M:%S"),",", local_replica_obj.get_id(),",","HEARTBEAT MISSED! TOTAL RECEIVED: ", counter.size(proxies_connection))
            file:write("\n")
            file:close()
          end
        end
        
        if local_replica_obj.check_leader() then
          local new_time = local_replica_obj.generateRandomWait()
          librpc.wait(new_time)
        else
          librpc.wait(local_replica_obj.generateRandomHeartbeat())
        end

        if (not local_replica_obj.check_leader()) then
           local heartbeat_expired = local_replica_obj.get_heartbeat() + new_heartbeat
          if (local_replica_obj.get_time() > heartbeat_expired) then
            new_heartbeat = local_replica_obj.generateRandomHeartbeat()
            local_replica_obj.set_state("CANDIDATE")
            local_replica_obj.set_votes(0)
            local_replica_obj.set_term(local_replica_obj.get_term() + 1)
            local_replica_obj.set_votes(local_replica_obj.get_votes() + 1)

            local file = assert(io.open("log"..local_replica_obj.get_id()..".txt", "a+"))
            file:write(os.date("%Y-%m-%d %H:%M:%S"),",", local_replica_obj.get_id(),",","BEGIN ELECTION", ",", ",", "REPLICA_ID: "..local_replica_obj.get_id(), ",", "REPLICA_TERM: "..local_replica_obj.get_term())
            file:write("\n")
            file:close()

            for index, value in ipairs(proxies_connection) do
              local instance = proxies_connection[index]
              -- dumper.dump(proxies_connection[index])
              local acknowledge, vote = instance.requestVotes(local_replica_obj.get_id(), local_replica_obj.get_term())
          
              if acknowledge == "__ERROR_CONN" then
                librpc.logger("Execute","Connection Problem. Removing Replica - ID:"..local_replica_obj.get_id())
                file = assert(io.open("log"..local_replica_obj.get_id()..".txt", "a+"))
                file:write(os.date("%Y-%m-%d %H:%M:%S"),",", local_replica_obj.get_id(),",","REMOVING REPLICA")
                file:write("\n")
                file:close()
              else
                if vote == "YES" then
                  local countVote = local_replica_obj.get_votes(local_replica_obj.set_votes(local_replica_obj.get_votes() + 1))
                  file = assert(io.open("log"..local_replica_obj.get_id()..".txt", "a+"))
                  file:write(os.date("%Y-%m-%d %H:%M:%S"),",", local_replica_obj.get_id(),",","RECEIVED VOTE. TOTAL VOTES: "..local_replica_obj.get_votes())
                  file:write("\n")
                  file:close()
                  if (countVote >= local_replica_obj.get_majority()) then
                    librpc.logger("Execute", "SRV"..local_replica_obj.get_id().." ELECTED AS LEADER.".."Total Votes:"..local_replica_obj.get_votes())
                    file = assert(io.open("log"..local_replica_obj.get_id()..".txt", "a+"))
                    file:write(os.date("%Y-%m-%d %H:%M:%S"),",", local_replica_obj.get_id(),",","ELECTED AS LEADER: "..local_replica_obj.get_id(),",","TOTAL VOTES: "..local_replica_obj.get_votes())
                    file:write("\n")
                    file:close()
                    local_replica_obj.set_state("LEADER")
                    break
                  end
                end
                if (acknowledge > local_replica_obj.get_term()) then
                  local_replica_obj.set_term(acknowledge)
                  local_replica_obj.set_votes(0)
                  local_replica_obj.set_state("FOLLOWER")
                  break
                end
              end

              if (not local_replica_obj.check_candidate()) then
                file = assert(io.open("log"..local_replica_obj.get_id()..".txt", "a+"))
                file:write(os.date("%Y-%m-%d %H:%M:%S"),",", local_replica_obj.get_id(),",","RECEIVED HEARTBEAT WAKE UP. CANCELLING ELECTION.")
                file:write("\n")
                file:close()
                break
              end
            end
            local_replica_obj.set_heartbeat()
          end
        end
      end
    end

    return self_stubs
end

function Main()
  local configsFile = "config.json"
  local hash_id = arg[1]
  local configs = json.decode(readAll(configsFile))
  local servers = {}
  local myconfig = {}
  local replica_obj = {}
  local instances = nil
  local interface_path = nil
  local timeout = nil
  servers, myconfig, instances, interface_path = checkConfigs(configs, hash_id)

  if servers == nil then
      return false
  end

  if myconfig == nil then
      return false
  end

  if instances == nil then
    return false
  end

  if interface_path == nil then
    return false
  end

  display_info(servers, myconfig)

  replica_obj = replica.new(hash_id, instances, myconfig[1]["PORT"]*17)
  replica_obj.display_info()

  if replica_obj == nil then
    librpc.logger("Main", "Não foi possível criar uma replica.")
    return false
  end

  local file = assert(io.open("log"..myconfig[1]["HASHID"]..".txt", "w"))
  file:write("\n")
  file:close()

  librpc.createServant(createStubs(replica_obj, myconfig, servers, math.random(1,10)), interface_path, myconfig[1]["PORT"])
  librpc.waitIncoming()
end

Main()