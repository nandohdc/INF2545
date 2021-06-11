-- local mqtt = require("mqtt_library")

package.path = "json.lua/?.lua;" .. package.path
local json = require("json")

print(json.encode({}))

NUMBER_ARGUMENTS = 1

local configs = {}
local buttons = {}
local font = nil

local function logger(name, activity)
    print("[+] " .. name .. ": ", activity)
end

local function new_button(text, ftn)
    return {
        text = text,
        ftn = ftn,
        now = false,
        last = false
    }
end

local function check_config(arguments)
    if arguments ~= nil then
        if #arguments ~= NUMBER_ARGUMENTS then
            logger("check_config", "Número de argumentos inválido.")
            return false
        else
            return true
        end
    end
    logger("check_config", "Nenhum argumento foi fornecido.")
    return false
end

local function logging(filename, node_id, event)
    local file = nil
    file = assert(io.open(filename, "a+"))
    file:write(os.date("%Y-%m-%d %H:%M:%S"), " , ", node_id, " , ", event)
    file:write("\n")
    file:close()
end

function love.load(arg)

    local filename = "log"..os.date("%Y-%m-%d %H:%M:%S")..".csv"
    -- logging(filename, "HASH1", "Oi")

    if check_config(arg) then
        font = love.graphics.newFont(32)

        table.insert(buttons, new_button(
            "Evento 1",
            function ()
                print("Temperatura alta")
            end
        ))

        table.insert(buttons, new_button(
            "Evento 2",
            function ()
                print("Umidade Alta")
            end
        ))


        table.insert(buttons, new_button(
            "Consulta 1",
            function ()
                print("Temperatura alta")
            end
        ))

        table.insert(buttons, new_button(
            "Consulta 2",
            function ()
                print("Umidade alta")
            end
        ))

        table.insert(buttons, new_button(
            "Sair",
            function ()
                love.event.quit()
            end
        ))
    else
        love.event.quit()
    end

    -- Aqui que se inscreve nos tópicos do MQTT
end

function love.draw()
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    local button_height = 64
    local button_width = window_width * (1/3)
    local margin = 16
    local total_height = (button_height + 16) * #buttons
    local cursor_y = 0
                          
    for _, button in ipairs(buttons) do

        button.last = button.now

        local x = ((window_width * 0.5) -  button_width)
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
        local fx = ((window_width * 0.5)  -  0.5 * button_width) - textW * 0.5
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
    
    local tx = ((window_width * 0.5) - button_width * 0.5) + 1.5*button_width
    local ty = (window_height* 0.5) - (total_height * 0.5)
    love.graphics.rectangle("line",
        tx,
        ty,
        button_width * 3.5,
        button_height * 3.5
    )
    
    love.graphics.printf("OI.OI.OI.OI.OI.OI.OI.OI.OI.OI.", 
        ((window_width * 0.5) - button_width * 0.5) + 1.5*button_width, 
        (window_height* 0.5) - (total_height * 0.5), button_width * 3.5
    )
end

-- Loop para tratar os eventos
function love.update(dt)
end