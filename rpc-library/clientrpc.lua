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
local dumper = require "pl.pretty"
-- local idlfile = require()

local ip = "127.0.0.1"
local port = 15979

local p1 = librpc.createProxy(ip, port, "interface.idl")
local r = p1:foo('c',0,0,0)
print(r)

-- local r, s = p1:foo(3, "alo", {nome = "Aaa", idade = 20, peso = 55.0})
-- print("p1: r="..r.." s="..s)
