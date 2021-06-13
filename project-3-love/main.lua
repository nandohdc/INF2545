local mqtt = require "mqtt_library"
local json = require "json-lua/json"
local logger = require "logger"
local node_obj = require "node"

-- name of the config file of the node
NUMBER_ARGUMENTS = 1

local node = {}
local buttons = {}
local mqtt_client = nil
local font = nil

local function new_button(text, ftn)
    return {
        text = text,
        ftn = ftn,
        now = false,
        last = false
    }
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
    love.window.setTitle("NODE - "..node_id)
    love.window.setMode(window_width, window_height, nil)

    if tonumber(node_id) <= math.ceil(number_of_nodes/2) then
        love.window.setPosition((node_id-1)*window_width, 1, 1)
    else
        love.window.setPosition((node_id - number_of_nodes/2 - 1 )*window_width, window_height + margin_height, 1)
    end
end

local function encode_message(new_sender, new_recipient, new_message)
    local message = {sender = new_sender, recipient =  new_recipient, payload = new_message}
    local message_encoded = json.encode(message)
    return message_encoded
end

local function decode_message(new_encoded_message)
    local decoded_message = json.decode(new_encoded_message)
    return decoded_message
end

local function mqttcb(topic, message)
   print("Received: " .. topic .. ": " .. message)
   local message = decode_message(message)
   print(message.sender)
end

function love.load(arg)
    local isOk, config_file = isConfigOk(arg)

    if isOk then
        dofile("config/" .. config_file)

        node = node_obj
        node:setId(config.id)
        node:setTopic(config.topic)
        node:setSubscriptions(config.subscribedTo)

        local num_nodes = config.numberOfNodes
        local node_id = tostring(config.id)
        local filename = "logNODE-"..node_id..".csv"

        -- Depois de verificar as configuracoes e todas estarem corretas, vem o mqtt
        mqtt_client = mqtt.client.create("34.145.30.230", 1883, mqttcb)
        mqtt_client:connect(node_id)

        -- Se inscreve nos tópicos de interesse
        for _, subscription in ipairs(node.subscriptions) do
            mqtt_client:subscribe({subscription})
        end

        logger.writeLog(filename, "NODE"..node_id, encode_message(node_id, "broadcast", node_id)) -- salva em arquivo
        mqtt_client:publish(node.topic, encode_message(node_id, "broadcast", node_id)) -- envia msg via mqtt

        set_config(node.id, num_nodes) --funcao de configuracao das janelas

        font = love.graphics.newFont(24)

        table.insert(buttons, new_button(
            "Evento 1",
            function ()
                local message = "Temperatura alta"
                print(encode_message(node_id, num_nodes, message)) -- print no terminal
                logger.writeLog(filename, "NODE"..node_id, encode_message(node_id, num_nodes, message)) -- salva em arquivo
                mqtt_client:publish(node.topic, encode_message(node_id, num_nodes, message)) -- envia msg via mqtt
            end
        ))

        table.insert(buttons, new_button(
            "Evento 2",
            function ()
                local message = "Umidade Alta"
                print(message)
                logger.writeLog(filename, "NODE"..node_id, message)
            end
        ))


        table.insert(buttons, new_button(
            "Consulta 1",
            function ()
                local message = "Temperatura alta"
                print(message)
                logger.writeLog(filename, "NODE"..node_id, message)
            end
        ))

        table.insert(buttons, new_button(
            "Consulta 2",
            function ()
                local message = "Umidade Alta"
                print(message)
                logger.writeLog(filename, "NODE"..node_id, message)
            end
        ))

        table.insert(buttons, new_button(
            "Sair",
            function ()
                logger.writeLog(filename, "NODE"..node_id, "Encerrando o programa")
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

    love.graphics.printf("OI.OI.OI.OI.OI.OI.OI.OI.OI.OI.", tx, ty, window_height - 10, "left", nil, nil, nil, nil, nil, nil, nil)
end

-- Loop para tratar os eventos
function love.update(dt)
    mqtt_client:handler()
end