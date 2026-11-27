
-- PRACTICAL BASKETBALL DEAD SERVER JOINER
-- Corrected Plaza and Park destinations

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- CORRECTED DESTINATION IDs
local MODES = {
    Plaza = 115776365257536,
    Park = 115491614485922
}

-- Remove previous menu
pcall(function()
    game:GetService("CoreGui"):FindFirstChild("PBDeadJoiner"):Destroy()
end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "PBDeadJoiner"
Gui.ResetOnSpawn = false
Gui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.fromOffset(300, 240)
Frame.Position = UDim2.new(0.5, -150, 0.5, -120)
Frame.BackgroundColor3 = Color3.fromRGB(22, 22, 29)
Frame.Parent = Gui

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 12)

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
Status.Text = "Select a destination"
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

    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)
    Button.MouseButton1Click:Connect(callback)

    return Button
end

local function getRequest()
    return request or http_request or
        (syn and syn.request)
end

local function findServer(placeId)
    Status.Text = "Searching public servers..."

    local req = getRequest()

    if not req then
        Status.Text = "Executor HTTP unavailable"
        return
    end

    local url = "https://games.roblox.com/v1/games/"
        .. placeId
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
        return
    end

    local decoded

    local ok = pcall(function()
        decoded = HttpService:JSONDecode(response.Body)
    end)

    if not ok or not decoded.data then
        Status.Text = "Could not read server list"
        return
    end

    local available = {}

    for _, server in ipairs(decoded.data) do
        if server.id ~= game.JobId
            and server.playing < server.maxPlayers then
            table.insert(available, server)
        end
    end

    table.sort(available, function(a, b)
        return a.playing < b.playing
    end)

    if #available == 0 then
        Status.Text = "No available servers found"
        return
    end

    local target = available[1]

    Status.Text = "Joining: "
        .. target.playing .. " players"

    local teleported, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(
            placeId,
            target.id,
            LocalPlayer
        )
    end)

    if not teleported then
        Status.Text = "Teleport failed: " .. tostring(err)
    end
end

makeButton("JOIN DEAD PLAZA", 90, function()
    findServer(MODES.Plaza)
end)

makeButton("JOIN DEAD PARK", 142, function()
    findServer(MODES.Park)
end)

makeButton("CLOSE MENU", 194, function()
    Gui:Destroy()
end)

print("Practical Basketball Joiner loaded!")
