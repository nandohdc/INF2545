
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
local dumper = require "pl.pretty"
local json = require "json-lua/json"

local librpc = {}

local servers = {}
Servants = {}
Result = {}
Stubs = {}

---------------------------------------------------------------------
-- Função Pública: createServant()
--
-- Objetivo: Cria um proxy client-side.
--
-- Parâmetros:
---- servobj: objeto contendo as informações a serem utilizada pelo Servant
---- idlfile: caminho para o arquivo da interface
---- IP: endereço de conexão
--
-- Retorno: um stub que representa a definição na interface (idlfile)
-----------------------------------------------------------------------
function librpc.createServant(servobj, idlfile, ip, port)
    local servant = {}
    local local_ip = ip
    local local_port = port

    -- valida o IP passado como parametro para a funcao
    if (local_ip == nil) then
        logger("createServant", "Nenhum Internet Protocol foi fornecido")
        local_ip = socket.dns.toip(socket.dns.gethostname())
        logger("createServant", "Adotando o Internet Protocol de Local Host - IP: " .. local_ip)
    else
        logger("createServant", "Internet Protocol fornecido - IP: " .. local_ip)
    end

    if (local_port == nil) then
        logger("createServant", "Nenhuma Porta foi fornecida. Gerando Porta para o Serviço...")
        math.randomseed(os.time())
        math.random()
        math.random()
        math.random()
        local_port = math.random(12000, 65535)
        logger("createServant", "A Porta gerada para o serviço foi: " .. local_port)
    else
        logger("createServant", "A Porta fonercida - Porta: " .. local_port)
    end

    servant.conn = socket.try(socket.bind(local_ip, local_port))

    -- Associa servant a object
    setmetatable(servant, servobj)
    servobj.__index = servobj

    -- Adiciona servant ao array de Servants
    Servants[#Servants + 1] = servant
    Servants[tostring(local_port)] = servant

    -- Adiciona conexao ao array de conexoes para ser consultado por waitIncomingRPC
    servers[#servers + 1] = servant.conn

    logger("createServant", "Aguardando conexões - " .. local_ip .. ":" .. local_port)

    return servant
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
function librpc.waitIncoming()
    -- Faz com que o servidor aguarde até algum dos Servants terem algo para ler;
    while (true) do
        logger("waitIncoming", "Aguardando requisições.")

        --[[
            Espera que vários soquetes mudem de status.
            O tempo limite é o tempo máximo (em segundos) de espera por uma mudança no status.
            Um valor de tempo limite nulo, negativo ou omitido permite que a função bloqueie indefinidamente.
            Valores não soquete (ou valores com índices não numéricos) nas matrizes serão ignorados.
        ]]
        local ready_servers = socket.select(servers)

        for index, server in ipairs(ready_servers) do
            local client = {}
            local message_received = {}
            local error_message = {}
            --[[
                Na documentação do LuaSocket recomenda-se chamar select com um soquete de servidor no parâmetro 
                de recebimento antes que uma chamada para aceitar não garanta que aceite retornará imediatamente.
                Use o método settimeout ou aceitar pode bloquear para sempre.
            ]]
            server:settimeout(1.0)

            --[[
                Espera por uma conexão remota no objeto de servidor e retorna um objeto de cliente que representa essa conexão.
                Se uma conexão for iniciada com sucesso, um objeto cliente será retornado. Se uma condição de tempo limite for atendida, 
                o método retorna nil seguido pela string de erro 'timeout'. Outros erros são relatados por nil seguido por uma mensagem descrevendo o erro.
            ]]
            client, error_message = server:accept()

            if (client == nil) then
                if (error_message == "timeout") then
                    logger("waitIncoming", "Aceept - Tempo de Conexão Excedido.")
                    os.exit(1)
                else
                    logger("waitIncoming", "Accept - Erro de conexão.")
                    os.exit(1)
                end
            end

            message_received = receiveMessageRPC(client)
            if (message_received == nil) then
                logger("waitIncoming", "___ERRORPC: falha no recebimento da mensagem.")
                os.exit(1)
            end
            executeMessageRPC(client, message_received)
        end
    end
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
function librpc.createProxy(ip, port, idlFile)
    local client = nil
    local local_ip = ip
    local local_port = port
    local msg = nil
    local result = nil
    local error = nil
    local request = nil

    --carrega arquivo de interfaces
    dofile(idlFile)

    if (local_ip == nil) then
        logger("createProxy", "Nenhum Internet Protocol foi fornecido")
        local_ip = socket.dns.toip(socket.dns.gethostname())
        logger("createProxy", "Conectando ao Internet Protocol de Local Host - IP: " .. local_ip)
    else
        logger("createProxy", "Conectando ao Internet Protocol fornecido - IP: " .. local_ip)
    end

    if (local_port == nil) then
        logger("createProxy", "Nenhuma Porta foi fornecida. Encerrando o programa")
        os.exit(1)
    else
        logger("createProxy", "A Porta fonercida - Porta: " .. local_port)
    end

    while client == nil do
        logger("createProxy", "Conectando ao Servidor - IP: " .. local_ip .. " - Porta: " .. local_port)
        client = socket.connect(local_ip, port)
    end

    -- construindo requisicao
    msg = {type = "REQUEST", func = "foo", parameters = {"0","0","0"}}
    request = encodeMSG(msg)

    -- envia requisicao
    error = socket.skip(1, client:send(request..'\n'))

    if error then
        logger("createProxy", "___ERRORPC: falha ao enviar a requisição. " .. error)
        os.exit(1)
    end

    result, error = client:receive('*l')

    --[[
        Mensagem de Erro no recebimento da mensagem por parte do cliente:
        -- Closed: O servidor finalizou a conexão com client.
        -- Timeout: Excedeu o tempo limite de conexão.
    ]]
    if error == "closed" then
        client = nil

        for attempts = 1, 5 do
            logger("createProxy", "Reconectando - Tentativa " .. attempts .. " de 5")
            client = socket.connect(local_ip, local_port)
        end

        if (client == nil) then
            logger("createProxy", "Número máximo de tentativas excedido. Finalizando o programa...")
        end

        error = socket.skip(1, client:send(msg..'\n'))

        if error then
            logger("createProxy", "___ERRORPC: falha ao enviar a requisição. " .. error)
            os.exit(1)
        end

        result, error = client:receive('*l')

        if error then
            print("Erro no recebimento do resultado: " .. error)
            os.exit(1)
        end
    else
        if error then
            print("Erro no recebimento do resultado: " .. error)
            os.exit(1)
        end
    end

    local response = decodeMSG(result)

    logger("createProxy", "Fechando a conexão com o servidor.")
    client:close()

    return Result
end

function struct(...)
    for lixo, i in ipairs {...} do
        -- print(i.name)
    end
end

function interface(...)
    for _, key in ipairs {...} do
        for x, methods in pairs(key.methods) do
            Result[x] = function(...)
                local parameters = select("#", ...)
                parameters = parameters - 1
                if (parameters ~= #methods.args) then
                    --erro
                    logger("interface", "Numero de parametros nao esta de acordo com a IDL.")
                    os.exit(1)
                end
                local args = {...}
                table.remove(args, 1)
                for index=1, #methods.args do
                    if (methods.args[index].type == "int") then
                        if (math.type(args[index]) ~= "integer") then
                            logger("interface", "Tipo de parametro nao esta de acordo com a IDL.")
                            os.exit(1)
                        end
                        table.insert(Stubs,args[index])
                    elseif (methods.args[index].type == "double") then
                        if (math.type(args[index]) ~= "float") then
                            logger("interface", "Tipo de parametro nao esta de acordo com a IDL.")
                            os.exit(1)
                        end
                        table.insert(Stubs,args[index])
                    elseif (methods.args[index].type == "char") then
                        if (type(args[index]) ~= "string") then
                            logger("interface", "Tipo de parametro nao esta de acordo com a IDL.")
                            os.exit(1)
                        else
                            local length = tostring(args[index])
                            length = string.len(length)
                            if (length > 1) then
                                logger("interface", "Tipo de parametro nao esta de acordo com a IDL.")
                                os.exit(1)
                            end
                            table.insert(Stubs,args[index])
                        end
                    elseif (methods.args[index].type == "string") then
                        if (type(args[index]) ~= "string") then
                            logger("interface", "Tipo de parametro nao esta de acordo com a IDL.")
                            os.exit(1)
                        end
                        table.insert(Stubs,args[index])
                    end
                end
                logger("interface", "Todos os parametros estão corretos.")
                
                return "Hello World!"
            end
        end
    end
end

function logger(name, activity)
    print("[+] " .. name .. ": ", activity)
end

function receiveMessageRPC(client)
    local message, error = client:receive("*l")
    local objMessage = nil

    if (error == "closed") then
        if (message == nil) then
            logger("receiveMessageRPC", "Erro - O conteúdo da mensagem é nil e a conexão foi finalizada.")
        end
        return nil
    elseif (error == "timeout") then
        logger("receiveMessageRPC", "Erro - O tempo de conexão foi excedido.")
        return nil
    end
    -- converter de json para lua
    objMessage = decodeMSG(message)
    return objMessage
end

function executeMessageRPC(client, message)
    --[[
        Retorna as informações de endereço local associadas ao objeto. 
        O método retorna uma string com o endereço IP local e um número com a porta. 
        Em caso de erro, o método retorna nulo.
    ]]
    local ip, server = client:getsockname()
    print("executeMessageRPC", "Executando Mensagem Recebida de "..ip)

    if (ip == nil) then
        logger("executeMessageRPC", "Erro - O Endereço de Internet Protocol do Cliente é nil.")
        os.exit(1)
    end
    local func_string = "return Servants[\""..server.."\"]."..message["func"].."()"
    local func = load(func_string)
    local ret = func()
    local msg = {type = "RESPONSE", func = message["func"], retur = ret}
    local response = encodeMSG(msg)
    --[[
        Se for bem-sucedido, o método retorna o índice do último byte dentro de [i, j] que foi enviado.
        Observe que, se i for 1 ou ausente, esse é efetivamente o número total de bytes enviados. Em caso de erro, o método retorna nil, seguido por uma mensagem de erro, seguido pelo índice do último byte dentro de [i, j] que foi enviado.
        Você pode querer tentar novamente a partir do byte seguinte. A mensagem de erro pode ser 'closed' caso a conexão tenha sido fechada antes que a transmissão fosse concluída ou a string 'timeout' caso tenha ocorrido um tempo limite durante a operação.
    ]]
    local error = socket.skip(1, client:send(response..'\n'))
    if error then
        logger("executeMessageRPC", "___ERRORPC: falha ao enviar a resposta.")
        print(error)
        os.exit(1)
    end
    logger("executeMessageRPC", "Mensagem Enviada: "..response)
end

function encodeMSG(object)
    local message = nil
    if (object == nil) then
        logger("encodeMSG", "Nao possivel codificar uma msg, pois nao existe valor.")
        os.exit(1)
    end
    message = json.encode(object)
    logger("encodeMSG", "Messagem codificada.")
    print(message)
    return message
end

function decodeMSG(JSONobject)
    local object = nil
    if (JSONobject == nil) then
        logger("decodeMSG", "Nao possivel decodificar a msg, pois nao existe valor.")
        os.exit(1)
    end
    object = json.decode(JSONobject)
    logger("decodeMSG", "Messagem decodificada.")
    dumper.dump(object)
    return object
end

return librpc
