
-- Roblox Luau | Client-side executor environment

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local PARK_ID = 115491614485922
local PLAZA_ID = 115776365257536

local MIN_PLAYERS = 1
local MAX_DEAD_PLAYERS = 2
local HOP_THRESHOLD = 8
local CHECK_INTERVAL = 5

local running = false
local hopping = false
local generation = 0

pcall(function()
    CoreGui:FindFirstChild("PBDeadJoiner"):Destroy()
end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "PBDeadJoiner"
Gui.ResetOnSpawn = false
Gui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.fromOffset(310, 390)
Frame.Position = UDim2.new(0.5, -155, 0.5, -195)
Frame.BackgroundColor3 = Color3.fromRGB(22, 22, 29)
Frame.Parent = Gui

Instance.new("UICorner", Frame).CornerRadius =
    UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.BackgroundTransparency = 1
Title.Text = "PRACTICAL BASKETBALL"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame

local Status = Instance.new("TextLabel")
Status.Position = UDim2.fromOffset(10, 48)
Status.Size = UDim2.new(1, -20, 0, 30)
Status.BackgroundTransparency = 1
Status.Text = "Ready"
Status.TextColor3 = Color3.fromRGB(180, 180, 190)
Status.TextSize = 12
Status.Parent = Frame

local function makeButton(label, y, callback)
    local Button = Instance.new("TextButton")
    Button.Position = UDim2.fromOffset(20, y)
    Button.Size = UDim2.new(1, -40, 0, 42)
    Button.BackgroundColor3 = Color3.fromRGB(45, 90, 170)
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.Text = label
    Button.TextSize = 14
    Button.Font = Enum.Font.GothamBold
    Button.Parent = Frame

    Instance.new("UICorner", Button).CornerRadius =
        UDim.new(0, 8)

    Button.MouseButton1Click:Connect(callback)
end

local function getRequest()
    return request or http_request or
        (syn and syn.request)
end

local function getDeadServer()
    local req = getRequest()

    if not req then
        Status.Text = "HTTP unavailable"
        return nil
    end

    local url = "https://games.roblox.com/v1/games/"
        .. PARK_ID
        .. "/servers/Public?sortOrder=Asc&limit=100"

    local success, response = pcall(function()
        return req({
            Url = url,
            Method = "GET"
        })
    end)

    if not success or not response
        or response.StatusCode ~= 200 then
        Status.Text = "Server search failed"
        return nil
    end

    local decoded

    local ok = pcall(function()
        decoded = HttpService:JSONDecode(response.Body)
    end)

    if not ok or not decoded.data then
        Status.Text = "Invalid server data"
        return nil
    end

    local servers = {}

    for _, server in ipairs(decoded.data) do
        if server.id ~= game.JobId
            and server.playing >= MIN_PLAYERS
            and server.playing <= MAX_DEAD_PLAYERS
            and server.playing < server.maxPlayers then

            table.insert(servers, server)
        end
    end

    table.sort(servers, function(a, b)
        return a.playing < b.playing
    end)

    return servers[1]
end

local function hopToDeadPark()
    if hopping or not running then
        return
    end

    hopping = true
    Status.Text = "Finding another dead Park..."

    local server = getDeadServer()

    if not server then
        hopping = false
        Status.Text = "No dead Park found. Retrying..."
        return
    end

    Status.Text = "Joining Park: "
        .. server.playing .. " players"

    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(
            PARK_ID,
            server.id,
            LocalPlayer
        )
    end)

    if not success then
        hopping = false
        Status.Text = "Teleport error: " .. tostring(err)
    end
end

local function startDeadPark()
    running = true
    hopping = false
    generation += 1

    local currentGeneration = generation

    task.spawn(function()
        while running and generation == currentGeneration do

            local playerCount = #Players:GetPlayers()

            if playerCount >= HOP_THRESHOLD then
                Status.Text = "8 players reached! Hopping..."
                hopToDeadPark()
                task.wait(10)
            elseif playerCount <= MAX_DEAD_PLAYERS then
                Status.Text = "Dead Park active: "
                    .. playerCount .. " players"
                task.wait(CHECK_INTERVAL)
            else
                Status.Text = "Monitoring: "
                    .. playerCount .. " players"
                task.wait(CHECK_INTERVAL)
            end
        end
    end)

    hopToDeadPark()
end

local function stopAuto()
    running = false
    hopping = false
    generation += 1
    Status.Text = "Auto hopper stopped"
end

makeButton("START AUTO DEAD PARK", 90, startDeadPark)

makeButton("JOIN PLAZA", 142, function()
    stopAuto()
    TeleportService:Teleport(PLAZA_ID, LocalPlayer)
end)

makeButton("AUTO JOIN 1V1", 194, function()
    Status.Text = "Park destination selected"
end)

makeButton("AUTO JOIN 2V2", 246, function()
    Status.Text = "Park destination selected"
end)

makeButton("AUTO JOIN 3V3", 298, function()
    Status.Text = "Park destination selected"
end)

makeButton("STOP AUTO", 350, stopAuto)

print("Practical Basketball Dead Park Hopper loaded!")
