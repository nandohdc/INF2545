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

local struct_servant = {
   foo =
   function (number_one, character, struct_person, number_two)
    dumper.dump(struct_person)
    for index = 1, 5 do
      number_one = number_one + 1.1
    end
    return number_one, number_two
   end,
   boo =
   function (teste)
    return nil
  end
}

-- cria servidores:
local serv1 = librpc.createServant(struct_servant, nil, nil, nil)
if (serv1 == nil) then
  logger("ServerRPC", "Não possível criar um servant.")
  os.exit(1)
else
    -- vai para o estado passivo esperar chamadas:
  librpc.waitIncoming()
end