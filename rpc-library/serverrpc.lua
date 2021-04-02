---------------------------------------------------------------------
-- Server Remote Procedure Call (RPC)
--
-- Objetivo: Criar uma biblioteca de remote procedure call em lua.
--
-- Módulos Utilizados:
---- luarpc
--
-----------------------------------------------------------------------
local librpc = require "luarpc"
local dumper = require "pl.pretty"
-- local idlfile = require()

local natServant = {
   foo =
   function ()
      print("Hello World!")
      return 1 + 2
   end,
}

-- cria servidores:
local serv1 = librpc.createServant(natServant, nil, nil, nil)
if (serv1 == nil) then
  logger("ServerRPC", "Não possível criar um servant.")
  os.exit(1)
else
    -- vai para o estado passivo esperar chamadas:
  librpc.waitIncoming()
end