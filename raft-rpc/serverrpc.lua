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
local json = require("json-lua/json")
local dumper = require "penlight-lua/pretty"
-- local replica = require("replica")

local configsFile = "config.json"
local services = {}

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
    for _,v in pairs(octs) do
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

local configs = json.decode(readAll(configsFile))
local stubs = nil

if #configs["IPs"] ~= configs["nReplicas"] then
  librpc.logger("Main","Número de Replicas diferente de IPs.")
  return false
end

if #configs["Ports"] ~= configs["nReplicas"] then
  librpc.logger("Main","Número de Replicas diferente de Portas.")
  return false
end

if #configs["Ports"] ~= #configs["IPs"] then
  librpc.logger("Main","Número de Portas diferente de IPs.")
  return false
end

for index, value in ipairs(configs["IPs"]) do
  if(not checkIPv4(value)) then
    librpc.logger("Main","Parâmetro IP de Configuração Inválido.")
    librpc.logger("Main","Finalizando o Programa.")
    return false
  elseif (not checkPort(configs["Ports"][index])) then
    librpc.logger("Main","Parâmetro Porta de Configuração Inválido.")
    librpc.logger("Main","Finalizando o Programa.")
    return false
  end
  table.insert(services, index, {IP = value, PORT = configs["Ports"][index]})
end

dumper.dump(services)


-- librpc.createServant(stubs, arg[1], arg[2])
-- librpc.waitIncoming()

-- -- cria servidores:
-- local serv1 = 
-- if (serv1 == nil) then
--   librpc.logger("ServerRPC", "Não foi possível criar um servant.")
--   os.exit(1)
-- else
--     -- vai para o estado passivo esperar chamadas:
--   
-- end