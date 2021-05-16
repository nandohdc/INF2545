---------------------------------------------------------------------
-- Client Remote Procedure Call (RPC)
--
-- Objetivo: Criar um cliente que utiliza a biblioteca luarpc para interagir com o servidor.
--
-- Módulos Utilizados:
---- luarpc
--
-----------------------------------------------------------------------
local librpc = require "luarpc"

local ip = arg[1]
local port = arg[2]

local p1 = librpc.createProxy(ip, port, "interface.lua", true)
local r, s = p1.execute("interface.lua")


