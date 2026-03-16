local socket = require("socket")
local json = require("json")

local server_ip = "10.254.51.170"
local server_port = 8000
local client_port = 8888
local image_base_url = "https://raw.githubusercontent.com/pepezaza777-cyber/flag/refs/heads/main/"

local udp = socket.udp()
udp:settimeout(0)
udp:setsockname("0.0.0.0", client_port)
print("Client UDP socket at port: " .. client_port)

local right_score = 0
local wrong_score = 0
local missed_score = 0

local score_text = nil
local current_question_data = nil
local current_question_group = nil
local client_ip_text = nil

local x_center = display.contentCenterX
local y_center = display.contentCenterY

-- โหลดเสียงเตรียมไว้ (แนะนำให้ใช้ไฟล์ .mp3 หรือ .wav)
local sound_correct = audio.loadSound("1.mp3")
local sound_wrong = audio.loadSound("5.mp3")

local function update_score_display()
    if score_text then
        score_text:removeSelf()
        score_text = nil
    end
    local display_string = right_score .. " : " .. wrong_score .. " : " .. missed_score
    score_text = display.newText({text = display_string, x = x_center, y = 40, font = native.systemFontBold, fontSize = 30})
    score_text:setFillColor(1, 1, 1)
end

local function clear_current_question()
    if current_question_group then
        current_question_group:removeSelf()
        current_question_group = nil
    end
    current_question_data = nil
end

local function on_answer_tap(event)
    local chosen = event.target.answer
    if not current_question_data then return true end
    
    if chosen == current_question_data.qc then
        right_score = right_score + 1
        print("Correct!")
        audio.play(sound_correct) -- เล่นเสียงเมื่อตอบถูก
    else
        wrong_score = wrong_score + 1
        print("Wrong!")
        audio.play(sound_wrong) -- เล่นเสียงเมื่อตอบผิด
    end
    
    update_score_display()
    clear_current_question()
    return true
end

local function display_question(q_data)
    if not q_data or not q_data.qf then 
        return 
    end

    if current_question_data then
        missed_score = missed_score + 1
        update_score_display()
        clear_current_question()
    end

    current_question_data = q_data
    current_question_group = display.newGroup()
    local flag_url = image_base_url .. q_data.qf .. ".png"

    local function image_listener(event)
        if event.isError or not event.target then
            print("Failed to load flag image: " .. tostring(q_data.qf))
            return
        end
        local flag_image = event.target
        flag_image.x = x_center
        flag_image.y = y_center - 100
        flag_image.width = 200
        flag_image.height = 120
        if current_question_group then
            current_question_group:insert(flag_image)
        end
    end

    display.loadRemoteImage(flag_url, "GET", image_listener, "flagImage.png", system.TemporaryDirectory)
    
    local y_start = y_center + 20
    local spacing = 45

    -- เพิ่มตัวเลือกที่ 4 (q_data.c4) เข้าไปในตาราง
    local options = { q_data.c1, q_data.c2, q_data.c3, q_data.c4 }
    for i = 1, #options do
        if options[i] then
            local opt = display.newText({
                text = options[i], 
                x = x_center, 
                y = y_start + (spacing * (i-1)), 
                fontSize = 20, 
                align = "center"
            })
            opt:setFillColor(0.2, 0.6, 1)
            opt.answer = options[i]
            opt:addEventListener("tap", on_answer_tap)
            current_question_group:insert(opt)
        end
    end
    
    if client_ip_text then
        client_ip_text:removeSelf()
        client_ip_text = nil
    end
    client_ip_text = display.newText({
        text = string.lower((q_data.cip or "unknown") .. ":" .. tostring(client_port)),
        x = x_center,
        y = display.contentHeight - 20,
        fontSize = 14,
        align = "center"
    })    
    client_ip_text:setFillColor(1, 1, 1)
end

local function poll_udp()
    local data, ip, port = udp:receivefrom()
    if data then
        local status, msg = pcall(json.decode, data)
        if status and type(msg) == "table" then
            if msg.type == "registered_ok" then
                print("Server: Registration confirmed!")
            elseif msg.qf then
                print("New Question Received: " .. msg.qf)
                display_question(msg)
            end
        else
            print("Received invalid data: " .. tostring(data))
        end
    end
end

local function register_with_server()
    local reg_message = { type = "register" }
    local msg_str = json.encode(reg_message)
    local bytes_sent, err = udp:sendto(msg_str, server_ip, server_port)
    if bytes_sent then
        print("Registration packet sent to: " .. server_ip)
    else
        print("Registration error: " .. tostring(err))
    end
end

display.setDefault("background", 0.25, 0.25, 0.25)
register_with_server()
update_score_display()
timer.performWithDelay(100, poll_udp, 0)