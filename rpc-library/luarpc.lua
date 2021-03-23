---------------------------------------------------------------------
-- Biblioteca de Remote Procedure Call (RPC)
--
-- Objetivo: Criar uma biblioteca de remote procedure call em lua.
--
-- Módulos Utilizados:
---- socket
---- 
---- 
--
-----------------------------------------------------------------------
local socket = require("socket")




---------------------------------------------------------------------
-- Função Pública: createServant()
--
-- Objetivo: Cria um proxy client-side.
--
-- Parâmetros:
---- servobj: objeto contendo as informações a serem utilizada pelo Servant
---- idlfile: caminho para o arquivo da interface
---- 
--
-- Retorno: um stub que representa a definição na interface (idlfile)
-----------------------------------------------------------------------
function createServant(servobj, idlfile)

end

---------------------------------------------------------------------
-- Função Pública: waitIncoming()
--
-- Objetivo: O servidor entra em loop para aguardar novas conexões ou atendimentos de clientes.
--
-- Parâmetros:
---- 
---- 
---- 
--
-----------------------------------------------------------------------
function waitIncoming()

end

---------------------------------------------------------------------
-- Função Pública: createProxy()
--
-- Objetivo: Cria um proxy client-side.
--
-- Parâmetros:
---- hostname: Endereço do Servidor
---- port: número da porta que irá se conectar no Servidor
---- idlfile: caminho para o arquivo da interface
--
-- Retorno: um stub que representa a definição na interface (idlfile)
-----------------------------------------------------------------------
function createProxy(hostname, port, idlfile)
    local functions = {}
    local prototypes = parser(idlfile)

    for name,sig in pairs(prototypes) do
        functions[name] = function(...) 
            -- !!! -- validating params
            local params = {...}
            local values = {name}
            local types = sig.input 
            for i=1,#types do
                if (#params >= i) then 
                values[#values+1] = params[i]
                if (type(params[i])~="number") then
                    values[#values] = "\"" .. values[#values] .. "\""
                end
                end
            end
            -- creating request
            local request = pack(values)

            -- creating socket
            local client = socket.tcp()
    
            local conn = client:connect(hostname, port)

            -- local result = client:send(request .. ’\n’)

        end
    end

    return functions;

end