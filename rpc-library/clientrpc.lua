---------------------------------------------------------------------
-- Client Remote Procedure Call (RPC)
--
-- Objetivo: Criar um cliente que utiliza a biblioteca luarpc para interagir com o servidor.
--
-- Módulos Utilizados:
---- luarpc
--
-----------------------------------------------------------------------
local librpc = require("luarpc")

local idlfile = require()

local p1 = librpc.createproxy (IP, porta1, idlfile)
local p2 = librpc.createproxy (IP, porta2, idlfile)

local r, s = p1:foo(3, "alo", {nome = "Aaa", idade = 20, peso = 55.0})
print("p1: r="..r.." s="..s)

local t, p = p2:boo(10)
print("p2: t="..r.." p="..s)