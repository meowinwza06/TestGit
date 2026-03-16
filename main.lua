local socket = require("socket")

local server_ip = "10.254.51.170" 
local server_port = 9546
local client_port = 5555

local udp = socket.udp()
udp:settimeout(0)
udp:setsockname("0.0.0.0", client_port)

local x_center = display.contentCenterX
local y_center = display.contentCenterY

display.setDefault("background", 0.1, 0.2, 0.3)

local label = display.newText({
    text = "Waiting for Server...",
    x = x_center,
    y = y_center - 70,
    font = native.systemFont,
    fontSize = 20
})

local number_text = display.newText({
    text = "---",
    x = x_center,
    y = y_center,
    font = native.systemFontBold,
    fontSize = 80
})
number_text:setFillColor(0, 1, 0.5)

local function poll_udp()
    local data, ip, port = udp:receivefrom()
    if data then
        number_text.text = data
        print("Received: " .. data)
    end
end

local function poll_udp2()
    local last_data = nil
    local data, ip, port
    
    repeat
        data, ip, port = udp:receivefrom()
        if data then
            last_data = data
        end
    until not data

    if last_data then
        number_text.text = last_data
        print("Latest Data Received: " .. last_data)
    end
end

local function register_with_server()
    local msg = "hello"
    local sent, err = udp:sendto(msg, server_ip, server_port)
    
    if sent then
        label.text = "Registered!"
        print("Registration packet sent.")
    else
        label.text = "Error: " .. tostring(err)
    end
end

register_with_server()

timer.performWithDelay(100, poll_udp2, 0)