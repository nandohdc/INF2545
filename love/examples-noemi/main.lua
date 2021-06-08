local mqtt = require("mqtt_library")
  
function mqttcb(topic, message)
   print("Received: " .. topic .. ": " .. message)
   if message == "a" then controle = not controle end
end

function love.keypressed(key)
    print("pressionou tecla!")
    mqtt_client:publish("controle", key)
end

function love.load()
  controle = false
  mqtt_client = mqtt.client.create("mosquitto.inf.puc-rio.br", 1883, mqttcb)
  mqtt_client:connect("cliente love")
  mqtt_client:subscribe({"controle"})
end

function love.draw()
   if controle then
     love.graphics.rectangle("line", 10, 10, 200, 150)
   end
end

function love.update(dt)
  mqtt_client:handler()
end

