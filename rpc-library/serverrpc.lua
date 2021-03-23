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

local idlfile = require()

myobj1 = { foo = 
             function (a, s, st, n)
               return a*2, string.len(s) + st.idade + n
             end,
          boo = 
             function (n)
               return n, { nome = "Bia", idade = 30, peso = 61.0}
             end
        }
myobj2 = { foo = 
             function (a, s, st, n)
               return 0.0, 1
             end,
          boo = 
             function (n)
               return 1, { nome = "Teo", idade = 60, peso = 73.0}
             end
        }

-- cria servidores:
serv1 = librpc.createServant (myobj1, idlfile)
serv2 = librpc.createServant (myobj2, idlfile)

-- usa as infos retornadas em serv1 e serv2 para divulgar contato 
-- (IP e porta) dos servidores


-- vai para o estado passivo esperar chamadas:
luarpc.waitIncoming()