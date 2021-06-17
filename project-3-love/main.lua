local mqtt = require "mqtt-lua/mqtt_library"
local json = require "json-lua/json"
local logger = require "logger"
local node_obj = require "node"

-- name of the config file of the node
NUMBER_ARGUMENTS = 1
MQTT_IP = "34.145.30.230"

local node = {}
local buttons = {}
local mqtt_client = nil
local font = nil
local display_info = {}
local button_texts = {}
local num_nodes = 0

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

local function encode_message(new_sender, new_recipient, new_message, new_hops)
    local message = {sender = new_sender, recipient =  new_recipient, payload = new_message, hops = new_hops}
    local message_encoded = json.encode(message)
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
    if tonumber(decoded_message.recipient) == tonumber(node.id) then
        table.insert(display_info, message)
        print(message)
        local hops = tonumber(decoded_message.hops)
        if hops > 0  then
            local encoded_message = encode_message(node.id, node.id, "Chegou ao destino!", 0)
            if decoded_message.payload == button_texts[1] then
                print(encoded_message) -- print no terminal
                logger.writeLog("NODE"..node.id, encoded_message) -- salva em arquivo
                table.insert(display_info, encoded_message)
            elseif decoded_message.payload == button_texts[2]  then
                print(encoded_message) -- print no terminal
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

                encoded_message = encode_message(node.id, neighborList_cpy[neighbor], decoded_message.payload, hops - 1)
                mqtt_client:publish(node.topic, encoded_message)
                logger.writeLog("NODE"..node.id, encoded_message) -- salva em arquivo
                table.insert(display_info, encoded_message)
            end
        end
    end
end

function love.load(arg)
    local isOk, config_file = isConfigOk(arg)

    if isOk then
        dofile("config/" .. config_file)

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
        -- Depois de verificar as configuracoes e todas estarem corretas, vem o mqtt
        mqtt_client = mqtt.client.create(MQTT_IP, 1883, mqttcb)
        mqtt_client:connect(node_id)
        
        -- Se inscreve nos tópicos de interesse
        for _, subscription in pairs(node.subscriptions) do
            mqtt_client:subscribe({subscription})
        end
        
        -- Config Interface
        num_nodes = config.numberOfNodes
        set_config(node.id, num_nodes) --funcao de configuracao das janelas

        font = love.graphics.newFont(24)

        local messages = {}
        local j = 2*num_nodes

        for i = 1, num_nodes, 1 do
            messages[i] = {j, j - 1}
            j = j - 2
        end

        -- for index, value in ipairs(messages) do
        --     for i, v in ipairs(value) do
        --         print(i, v)
        --     end
        -- end


        node_id = tonumber(node_id)
        table.insert(button_texts, "Evento "..node_id)
        table.insert(button_texts, "Evento "..(node_id+num_nodes))
        table.insert(button_texts, "Consulta "..(node_id))
        table.insert(button_texts, "Consulta "..(node_id+num_nodes))
        
        table.insert(buttons, new_button(
            button_texts[1],
            function ()
                local message = "Evento "..messages[node_id][1]
                local neighborhood = node:getNeighborList()
                local neighbor = getRandomItemFromList(neighborhood)

                local encoded_message = encode_message(node_id, neighborhood[neighbor], message, 20)
                print(encoded_message) -- print no terminal
                logger.writeLog("NODE"..node_id, encoded_message) -- salva em arquivo
                mqtt_client:publish(node.topic, encoded_message) -- envia msg via mqtt
                table.insert(display_info, encoded_message)
            end
        ))

        table.insert(buttons, new_button(
            button_texts[2],
            function ()
                local message = "Evento "..messages[node_id][2]
                local neighborhood = node:getNeighborList()
                local neighbor = getRandomItemFromList(neighborhood)

                local encoded_message = encode_message(node_id, neighborhood[neighbor], message, 20)
                print(encoded_message) -- print no terminal
                logger.writeLog("NODE"..node_id, encoded_message) -- salva em arquivo
                mqtt_client:publish(node.topic, encoded_message) -- envia msg via mqtt
                table.insert(display_info, encoded_message)
            end
        ))

        table.insert(buttons, new_button(
            button_texts[3],
            function ()
                local message = button_texts[3]
                print(message)
                logger.writeLog("NODE"..node_id, message)
            end
        ))

        table.insert(buttons, new_button(
            button_texts[4],
            function ()
                local message = button_texts[4]
                print(message)
                logger.writeLog("NODE"..node_id, message)
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

    if next(display_info) ~= nil then
        for i = display_numbers_info, 1, -1 do
            if display_info[i] ~= nil then
                local scale = window_width / font:getWidth(display_info[i]) 
                if scale > 1 then
                    love.graphics.printf(display_info[i], tx, ty + (i)*40, window_width - 10, "left", nil, nil, nil, nil, nil, nil, nil)
                else
                    love.graphics.printf(display_info[i], tx, ty + ((i)*scale)*20, window_width - 10, "left", nil, nil, nil, nil, nil, nil, nil)
                end
            end
        end
    end  
end

-- Loop para tratar os eventos
function love.update(dt)
    mqtt_client:handler()
end