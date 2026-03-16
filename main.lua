local socket = require("socket")
local json = require("json")

local server_ip = "10.250.49.149"
local server_port = 9999
local client_port = 8888
local udp = socket.udp()

local function register_with_server()
    local registration_message = { type = "register" }
    local msg_str = json.encode(registration_message)
    local bytes_sent, err = udp:sendto(msg_str, server_ip, server_port)
    if bytes_sent then
        print("Registered successfully: " .. msg_str)
    else
        print("Registration error: " .. tostring(err))
    end
end

local function poll_udp()
    local data, ip, port = udp:receivefrom()
    if data then
        local status, message = pcall(json.decode, data)
        if status and message then
            print(data)
        else
            print("Failed to decode JSON: " .. data)
        end
    end
end

udp:settimeout(0)
udp:setsockname("0.0.0.0", client_port)
print("Client UDP socket bind at port: " .. client_port)
print("Server IP: " .. server_ip)
register_with_server()
timer.performWithDelay(100, poll_udp, 0)