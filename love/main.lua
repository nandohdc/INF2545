NUMBER_ARGUMENTS = 4

local configs = {}
local buttons = {}
local font = nil


function logger(name, activity)
    print("[+] " .. name .. ": ", activity)
end


function new_button(text, ftn)
    return {
        text = text,
        ftn = ftn
    }
end

function check_config(arguments)
    if arguments ~= nil then
        if #arguments == NUMBER_ARGUMENTS then
            
        end
        logger("check_config", "Número de argumentos inválido.")
        return false
    end
    logger("check_config", "Nenhum argumento foi fornecido.")
    return false
end

function logging(filename, message)
    local file = nil
    file = assert(io.open(filename, "a+"))
    file:write(os.date("%Y-%m-%d %H:%M:%S"), " - ", message)
    file:write("\n")
    file:close()
end

function love.load(arg)
    local filename = "log"..os.date("%Y-%m-%d %H:%M:%S")..".txt"
    logging(filename, "Oi")
    if check_config(arg) then
        font = love.graphics.newFont(32)

        table.insert(buttons, new_button(
            "Text",
            function ()
                print("Ok")
            end
        ))

        table.insert(buttons, new_button(
            "Exit",
            function ()
                love.event.quit()
            end
        ))
    else
        love.event.quit()
    end
end

function love.update(dt)
end

function love.draw()
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    local button_height = 64
    local button_width = window_width * (1/3)
    local margin = 16
    local total_height = (button_height + 16) * #buttons

    local cursor_y = 0

    for i, button in ipairs(buttons) do
        local x = ((window_width * 0.5) - button_width * 0.5)
        local y = (window_height* 0.5) - (total_height * 0.5) + cursor_y
        love.graphics.setColor(0.4, 0.4, 0.5, 1.0)
        love.graphics.rectangle("fill",
        x,
        y,
        button_width,
        button_height
        )

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(
            button.text,
            font,
            bx,
            by
        )
        cursor_y = cursor_y + (button_height + margin)
    end
end