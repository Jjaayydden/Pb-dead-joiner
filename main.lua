
-- Roblox Luau | Client-side executor
-- PRACTICAL BASKETBALL ULTIMATE V3

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local PARK_ID = 115491614485922
local PLAZA_ID = 115776365257536

local HOP_AT = 8
local CHECK_INTERVAL = 5

local running = false
local hopping = false
local closed = false

local oldGui = CoreGui:FindFirstChild("PBDeadJoiner")
if oldGui then
    oldGui:Destroy()
end

-- GUI

local Gui = Instance.new("ScreenGui")
Gui.Name = "PBDeadJoiner"
Gui.ResetOnSpawn = false
Gui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.fromOffset(380, 450)
Frame.Position = UDim2.new(0.5, -190, 0.5, -225)
Frame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
Frame.Parent = Gui

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -45, 0, 45)
Title.Position = UDim2.fromOffset(10, 0)
Title.BackgroundTransparency = 1
Title.Text = "PRACTICAL BASKETBALL"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame

-- CLOSE BUTTON

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(32, 32)
Close.Position = UDim2.new(1, -38, 0, 6)
Close.BackgroundColor3 = Color3.fromRGB(190, 55, 65)
Close.Text = "X"
Close.TextColor3 = Color3.new(1, 1, 1)
Close.TextSize = 16
Close.Font = Enum.Font.GothamBold
Close.Parent = Frame

Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 8)

local Status = Instance.new("TextLabel")
Status.Position = UDim2.fromOffset(5, 45)
Status.Size = UDim2.new(1, -10, 0, 28)
Status.BackgroundTransparency = 1
Status.Text = "Ready"
Status.TextColor3 = Color3.fromRGB(100, 220, 140)
Status.TextSize = 12
Status.Font = Enum.Font.Gotham
Status.Parent = Frame

-- TABS

local TabBar = Instance.new("Frame")
TabBar.Position = UDim2.fromOffset(10, 80)
TabBar.Size = UDim2.new(1, -20, 0, 40)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Frame

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.Padding = UDim.new(0, 5)
TabLayout.Parent = TabBar

local Pages = {}
local Tabs = {}

local function createPage(name)
    local Page = Instance.new("Frame")
    Page.Name = name
    Page.Position = UDim2.fromOffset(10, 130)
    Page.Size = UDim2.new(1, -20, 1, -140)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.Parent = Frame

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 9)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = Page

    Pages[name] = Page
end

local function switchTab(name)
    for pageName, Page in pairs(Pages) do
        Page.Visible = pageName == name
    end

    for tabName, Button in pairs(Tabs) do
        Button.BackgroundColor3 =
            tabName == name
            and Color3.fromRGB(45, 100, 190)
            or Color3.fromRGB(42, 44, 55)
    end
end

local function createTab(name)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 65, 1, 0)
    Button.BackgroundColor3 = Color3.fromRGB(42, 44, 55)
    Button.Text = name
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.TextSize = 11
    Button.Font = Enum.Font.GothamBold
    Button.Parent = TabBar

    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 7)

    Tabs[name] = Button
    Button.MouseButton1Click:Connect(function()
        switchTab(name)
    end)
end

for _, name in ipairs({
    "Joiner", "1v1", "2v2", "3v3", "4v4"
}) do
    createPage(name)
    createTab(name)
end

-- BUTTON CREATOR

local function makeButton(pageName, label, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 45)
    Button.BackgroundColor3 = Color3.fromRGB(45, 90, 170)
    Button.Text = label
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.TextSize = 13
    Button.Font = Enum.Font.GothamBold
    Button.Parent = Pages[pageName]

    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)

    Button.MouseButton1Click:Connect(callback)
end

-- COURT JOINER

local function joinCourt(number)
    local courts = workspace:FindFirstChild("Map")
        and workspace.Map:FindFirstChild("Courts")

    if not courts then
        Status.Text = "Court folder not found"
        return
    end

    local court = courts:FindFirstChild("Court" .. number)

    if not court then
        Status.Text = "Court " .. number .. " not found"
        return
    end

    local spots = court:FindFirstChild("Spots")

    if not spots then
        Status.Text = "Court " .. number .. ": Spots missing"
        return
    end

    if typeof(firetouchinterest) ~= "function" then
        Status.Text = "Executor touch support unavailable"
        return
    end

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root then
        Status.Text = "Character not loaded"
        return
    end

    local found = 0
    Status.Text = "Interacting with Court " .. number

    for _, spot in ipairs(spots:GetDescendants()) do
        if spot:IsA("BasePart") then
            found += 1

            pcall(function()
                firetouchinterest(root, spot, 0)
                task.wait(0.1)
                firetouchinterest(root, spot, 1)
            end)

            task.wait(0.15)
        end
    end

    if found == 0 then
        Status.Text = "No parts found in Court " .. number
    else
        Status.Text = "Court " .. number .. " interaction sent"
    end
end

-- SERVER SEARCH

local function getRequest()
    return request or http_request or (syn and syn.request)
end

local function findDeadServer()
    local req = getRequest()

    if not req then
        Status.Text = "HTTP unavailable"
        return nil
    end

    local cursor = ""

    for page = 1, 5 do
        local url =
            "https://games.roblox.com/v1/games/"
            .. PARK_ID
            .. "/servers/Public?sortOrder=Asc&limit=100"

        if cursor ~= "" then
            url = url .. "&cursor=" ..
                HttpService:UrlEncode(cursor)
        end

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

        local data
        local ok = pcall(function()
            data = HttpService:JSONDecode(response.Body)
        end)

        if not ok or not data.data then
            return nil
        end

        local servers = {}

        for _, server in ipairs(data.data) do
            if server.id ~= game.JobId
                and server.playing >= 1
                and server.playing <= 2
                and server.playing < server.maxPlayers then
                table.insert(servers, server)
            end
        end

        if #servers > 0 then
            table.sort(servers, function(a, b)
                return a.playing < b.playing
            end)

            return servers[1]
        end

        cursor = data.nextPageCursor or ""

        if cursor == "" then
            break
        end
    end

    return nil
end

-- DEAD PARK HOPPER

local function hopDeadPark()
    if hopping or closed then
        return
    end

    hopping = true
    Status.Text = "Searching for dead Park..."

    local server = findDeadServer()

    if not server then
        hopping = false
        Status.Text = "No dead Park found"
        return
    end

    Status.Text = "Joining server: "
        .. server.playing .. " players"

    local success = pcall(function()
        TeleportService:TeleportToPlaceInstance(
            PARK_ID,
            server.id,
            LocalPlayer
        )
    end)

    if not success then
        hopping = false
        Status.Text = "Teleport failed"
    end
end

local function startHopper()
    if running then
        Status.Text = "Hopper already running"
        return
    end

    running = true

    task.spawn(function()
        while running and not closed do
            local count = #Players:GetPlayers()

            if count >= HOP_AT then
                Status.Text = "8 players reached! Hopping..."
                hopDeadPark()
                task.wait(10)
            else
                Status.Text = "Park players: " .. count
                task.wait(CHECK_INTERVAL)
            end
        end
    end)

    hopDeadPark()
end

local function stopHopper()
    running = false
    hopping = false
    Status.Text = "Hopper stopped"
end

-- JOINER TAB

makeButton("Joiner", "START DEAD PARK HOPPER", startHopper)

makeButton("Joiner", "JOIN DEAD PARK (1-2 PLAYERS)", function()
    hopDeadPark()
end)

makeButton("Joiner", "JOIN PLAZA", function()
    TeleportService:Teleport(PLAZA_ID, LocalPlayer)
end)

makeButton("Joiner", "STOP AUTO", stopHopper)

-- 1V1

makeButton("1v1", "AUTO JOIN COURT 1 (GREEN)", function()
    joinCourt(1)
end)

makeButton("1v1", "AUTO JOIN COURT 2 (PURPLE)", function()
    joinCourt(2)
end)

-- 2V2

for _, number in ipairs({3, 4, 5, 6}) do
    makeButton("2v2", "AUTO JOIN COURT " .. number, function()
        joinCourt(number)
    end)
end

-- 3V3

for _, number in ipairs({7, 8, 9}) do
    makeButton("3v3", "AUTO JOIN COURT " .. number, function()
        joinCourt(number)
    end)
end

-- 4V4

makeButton("4v4", "AUTO JOIN COURT 10", function()
    joinCourt(10)
end)

-- TELEPORT FAILURE HANDLER

TeleportService.TeleportInitFailed:Connect(function(player, result)
    if player == LocalPlayer then
        hopping = false
        Status.Text = "Teleport failed: " .. tostring(result)
    end
end)

-- CLOSE GUI

Close.MouseButton1Click:Connect(function()
    closed = true
    running = false
    hopping = false
    Gui:Destroy()
end)

-- STARTUP

switchTab("Joiner")

print("PRACTICAL BASKETBALL ULTIMATE V3 LOADED")
