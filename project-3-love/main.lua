local mqtt = require "mqtt-lua/mqtt_library"
local json = require "json-lua/json"
local logger = require "logger"
local node_obj = require "node"

local NUMBER_ARGUMENTS = 1
local MQTT_IP = "34.145.30.230"
local MQTT_PORT = 1883

-- Interface vars
local buttons = {}
local font = nil
local display_info = {}
local button_texts = {}

-- Node/MQTT vars
local node = {}
local mqtt_client = nil
local num_nodes = 0
local distances = {}
local path = {}
local MAX_HOPS = 20

local function new_button(text, ftn)
    return {text = text, ftn = ftn, now = false, last = false}
end

local function isConfigOk(arguments)
    if arguments ~= nil then
        if #arguments ~= NUMBER_ARGUMENTS then
            logger.printLog("check_config", "Número de argumentos inválido.")
            return false
        else
            if type(arguments[1]) ~= "string" then
                return false
            end

            dofile("config/" .. arguments[1])

            if config.numberOfNodes <= 0 then
                return false
            end

            return true, arguments[1]
        end
    end
    logger.printLog("check_config", "Nenhum argumento foi fornecido.")
    return false
end

local function set_config(node_id, number_of_nodes)
    local offset_height = 145
    local screen_width, screen_height = love.window.getDesktopDimensions()
    local window_width = screen_width/(number_of_nodes/2)
    local window_height = (screen_height - offset_height)/2
    local margin_height = 80
    local window_title = "NODE - "..node_id
    love.window.setTitle(window_title)
    love.window.setMode(window_width, window_height, nil)

    if tonumber(node_id) <= math.ceil(number_of_nodes/2) then
        love.window.setPosition((node_id-1)*window_width, 1, 1)
    else
        love.window.setPosition((node_id - number_of_nodes/2 - 1 )*window_width, window_height + margin_height, 1)
    end
end

local function encode_message(new_type, new_sender, new_recipient, new_message, new_hops, new_path)
    local message = {type = new_type, sender = new_sender, recipient =  new_recipient, payload = new_message, hops = new_hops, path = new_path}
    local message_encoded = json.encode(message)
    print(message_encoded)
    return message_encoded
end

local function decode_message(new_encoded_message)
    local decoded_message = json.decode(new_encoded_message)
    return decoded_message
end

local function getRandomItemFromList(list)
    math.randomseed(os.time())
    math.random(); math.random(); math.random()
    return math.random(1, #list)
end

local function mqttcb(topic, message)
   local decoded_message = decode_message(message)

    if decoded_message.type == "evento" then
        if tonumber(decoded_message.sender) == tonumber(node.id) then
            table.insert(distances, tonumber(node.id), {
                distance = 0,
                origin = node.id,
                event = decoded_message.payload
            })
        end

        if tonumber(decoded_message.recipient) == tonumber(node.id) then
            table.insert(distances, tonumber(node.id), {
                distance = 1,
                origin = node.id,
                event = decoded_message.payload
            })
        end

    elseif decoded_message.type == "consulta"  then
        if tonumber(decoded_message.recipient) == tonumber(node.id) then
            table.insert(display_info, message)
            local hops = tonumber(decoded_message.hops)
            if hops > 0  then
                if decoded_message.path == '' or  decoded_message.path == nil then
                    if decoded_message.payload == "Chegou ao destino!" then
                        local encoded_message = encode_message(
                            "consulta",
                            node.id,
                            node.id,
                            "Volta Completa!",
                            0,
                            decoded_message.path
                        )
                        logger.writeLog("NODE"..node.id, encoded_message) -- salva em arquivos
                        table.insert(display_info, encoded_message)
                    end
                else
                    if decoded_message.payload == "Chegou ao destino!" then
                        local encoded_message = encode_message(
                            "consulta",
                            node.id,
                            string.sub(decoded_message.path, #decoded_message.path),
                            "Chegou ao destino!",
                            hops - 1,
                            string.sub(decoded_message.path, 0, #decoded_message.path - 1)
                        )
                        print(encoded_message) -- print no terminal
                        mqtt_client:publish(node.topic, encoded_message)
                        logger.writeLog("NODE"..node.id, encoded_message) -- salva em arquivos
                        table.insert(display_info, encoded_message)

                    elseif decoded_message.payload == button_texts[3] then
                        local encoded_message = encode_message(
                            "consulta",
                            node.id,
                            string.sub(decoded_message.path, #decoded_message.path),
                            "Chegou ao destino!",
                            hops - 1,
                            string.sub(decoded_message.path, 0, #decoded_message.path - 1)
                        )
                        print(encoded_message) -- print no terminal
                        mqtt_client:publish(node.topic, encoded_message)
                        logger.writeLog("NODE"..node.id, encoded_message) -- salva em arquivo
                        table.insert(display_info, encoded_message)
                    elseif decoded_message.payload == button_texts[4]  then
                        local encoded_message = encode_message(
                            "consulta",
                            node.id,
                            string.sub(decoded_message.path, #decoded_message.path),
                            "Chegou ao destino!",
                            hops - 1,
                            string.sub(decoded_message.path, 0, #decoded_message.path - 1)
                        )
                        print(encoded_message) -- print no terminal
                        mqtt_client:publish(node.topic, encoded_message)
                        logger.writeLog("NODE"..node.id, encoded_message) -- salva em arquivos
                        table.insert(display_info, encoded_message)
                    else
                        local neighborList_cpy = node:getNeighborList()

                        -- faz busca linear pra achar posicao do vizinho que mandou a msg
                        local sender_position = nil
                        for pos, v in pairs(neighborList_cpy) do
                            if v == tonumber(decoded_message.sender) then
                                sender_position = pos
                                break
                            end
                        end

                        table.remove(neighborList_cpy, sender_position)
                        local neighbor = getRandomItemFromList(neighborList_cpy)

                        local encoded_message = encode_message(
                            "consulta",
                            node.id,
                            neighborList_cpy[neighbor],
                            decoded_message.payload,
                            hops - 1,
                            decoded_message.path..tostring(node.id)
                        )
                        mqtt_client:publish(node.topic, encoded_message)
                        logger.writeLog("NODE"..node.id, encoded_message) -- salva em arquivo
                        table.insert(display_info, encoded_message)
                    end
                end
            end
        end
    else
      --erro: tipo invalido
    end
end

function love.load(arg)
    local isOk, config_file = isConfigOk(arg)

    if isOk then
        dofile("config/" .. config_file)

        for i = 1, config.numberOfNodes, 1 do
            local distance = {}
            table.insert(distances, i, distance)
        end

        -- Config do nó
        node = node_obj
        node:setId(config.id)
        node:setTopic(config.topic)
        node:setSubscriptions(config.subscribedTo)
        node:createNeighborList()

        -- Config do logger
        local node_id = tostring(config.id)
        logger:setFilename(node_id)

        -- Config do mqtt
        mqtt_client = mqtt.client.create(MQTT_IP, MQTT_PORT, mqttcb)
        mqtt_client:connect(node_id)

        -- Se inscreve nos tópicos de interesse
        for _, subscription in pairs(node.subscriptions) do
            mqtt_client:subscribe({subscription})
        end

        -- Config Interface
        num_nodes = config.numberOfNodes
        set_config(node.id, num_nodes) --funcao de configuracao das janelas

        font = love.graphics.newFont(24)

        -- Calcula quais eventos um determinado nó tem interesse em consultar
        local messages = {}
        local j = 2*num_nodes

        for i = 1, num_nodes, 1 do
            messages[i] = {j, j - 1}
            j = j - 2
        end

        node_id = tonumber(node_id)
        table.insert(button_texts, "Evento "..node_id)
        table.insert(button_texts, "Evento "..(node_id+num_nodes))
        table.insert(button_texts, "Consulta "..(messages[node_id][1]))
        table.insert(button_texts, "Consulta "..(messages[node_id][2]))

        table.insert(buttons, new_button(
            button_texts[1],
            function ()
                local message = "Evento "..node_id
                local neighborhood = node:getNeighborList()
                local neighbor = getRandomItemFromList(neighborhood)

                local encoded_message = encode_message("evento", node_id, neighborhood[neighbor], message, MAX_HOPS)
                print(encoded_message) -- print no terminal
                logger.writeLog("NODE"..node_id, encoded_message) -- salva em arquivo
                mqtt_client:publish(node.topic, encoded_message) -- envia msg via mqtt
                table.insert(display_info, encoded_message)
            end
        ))

        table.insert(buttons, new_button(
            button_texts[2],
            function ()
                local message = "Evento "..node_id+num_nodes
                local neighborhood = node:getNeighborList()
                local neighbor = getRandomItemFromList(neighborhood)

                local encoded_message = encode_message("evento", node_id, neighborhood[neighbor], message, MAX_HOPS)
                print(encoded_message) -- print no terminal
                logger.writeLog("NODE"..node_id, encoded_message) -- salva em arquivo
                mqtt_client:publish(node.topic, encoded_message) -- envia msg via mqtt
                table.insert(display_info, encoded_message)
            end
        ))

        table.insert(buttons, new_button(
            button_texts[3],
            function ()
                local message = "Consulta "..messages[node_id][1]
                local neighborhood = node:getNeighborList()
                local neighbor = getRandomItemFromList(neighborhood)

                local encoded_message = encode_message(
                    "consulta",
                    node_id,
                    neighborhood[neighbor],
                    message, MAX_HOPS,
                    tostring(node_id)
                )
                print(encoded_message) -- print no terminal
                logger.writeLog("NODE"..node_id, encoded_message) -- salva em arquivo
                mqtt_client:publish(node.topic, encoded_message) -- envia msg via mqtt
                table.insert(display_info, encoded_message)
            end
        ))

        table.insert(buttons, new_button(
            button_texts[4],
            function ()
                local message =  "Consulta "..messages[node_id][2]
                local neighborhood = node:getNeighborList()
                local neighbor = getRandomItemFromList(neighborhood)

                local encoded_message = encode_message(
                    "consulta",
                    node_id,
                    neighborhood[neighbor],
                    message, MAX_HOPS,
                    tostring(node_id)
                )
                print(encoded_message) -- print no terminal
                logger.writeLog("NODE"..node_id, encoded_message) -- salva em arquivo
                mqtt_client:publish(node.topic, encoded_message) -- envia msg via mqtt
                table.insert(display_info, encoded_message)
            end
        ))

        table.insert(buttons, new_button(
            "Sair",
            function ()
                logger.writeLog("NODE"..node_id, "Encerrando o programa")
                love.event.quit()
            end
        ))
    else
        love.event.quit()
    end
end

function love.draw()
    love.graphics.clear()
    local window_width, window_height = love.window.getMode()
    local button_height = 64
    local button_width = window_width * (1/4)
    local margin = 16
    local total_height = (button_height + 16) * #buttons
    local cursor_y = 0

    for _, button in ipairs(buttons) do

        button.last = button.now

        local x = ((window_width * 0.5) -  (window_width * 0.45))
        local y = (window_height* 0.5) - (total_height * 0.5) + cursor_y

        local color = {0.4, 0.4, 0.5, 1.0}

        local mx, my = love.mouse.getPosition()

        local hover_position =  mx > x and mx < x + button_width and my > y and my < y + button_height

        if hover_position then
            color = {0.8, 0.8, 0.9, 1.0}
        end

        button.now =  love.mouse.isDown(1)

        if button.now and not button.last and hover_position then
            button.ftn()
        end

        love.graphics.setColor(unpack(color))
        love.graphics.rectangle("fill",
            x,
            y,
            button_width,
            button_height
        )
        love.graphics.setColor(0, 0, 0, 1)
        local textW = font:getWidth(button.text)
        local textH = font:getHeight(button.text)
        local fx = ((window_width * 0.5)  -  0.725*(window_width * 0.45) - 0.5*textW)
        local fy = y + textH * 0.5
        love.graphics.print(
            button.text,
            font,
            fx,
            fy
        )

        cursor_y = cursor_y + (button_height + margin)

        color = {1, 1, 1, 1}

        love.graphics.setColor(unpack(color))


    end

    local tx = ((window_width * 0.5) -  (window_width * 0.45) + button_width) + 10
    local ty = (window_height* 0.5) - (total_height * 0.5) + 16
    love.graphics.rectangle("line",
        tx,
        ty,
        window_width - ((window_width * 0.5) -  (window_width * 0.45) + button_width) - 15,
        window_height - 10
    )
    local display_numbers_info = math.floor((window_height - 10) / font:getHeight("OI"))
    local last_number_of_lines = 0
    if next(display_info) ~= nil then
        for i = #display_info, 1, -1 do
            local widthd, wrappedtext = font:getWrap(display_info[i],window_width - 100)
            for index, value in ipairs(wrappedtext) do
                ty = ty + 15
                love.graphics.printf(value, tx, ty, widthd, "left", nil, nil, nil, nil, nil, nil, nil)
            end
            last_number_of_lines = #wrappedtext
        end
    end
end

-- Loop para tratar os eventos
function love.update(dt)
    mqtt_client:handler()
end