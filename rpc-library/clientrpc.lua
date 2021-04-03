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
local port = 5555

local p1 = librpc.createProxy(ip, port, "interface.idl")
local r, s= p1:foo(0.0,'c',{age = 60, name = "Fernando"},1)
print(r, s)
local p= p1:boo()
print(p)

-- local r, s = p1:foo(3, "alo", {nome = "Aaa", idade = 20, peso = 55.0})
-- print("p1: r="..r.." s="..s)
