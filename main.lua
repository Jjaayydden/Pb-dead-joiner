
-- JAY CLONE PB | SERVER
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteFolder = ReplicatedStorage:FindFirstChild("JayClonePBRemotes")

if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "JayClonePBRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local joinRemote = remoteFolder:FindFirstChild("JoinCourt")
if not joinRemote then
	joinRemote = Instance.new("RemoteEvent")
	joinRemote.Name = "JoinCourt"
	joinRemote.Parent = remoteFolder
end

local statusRemote = remoteFolder:FindFirstChild("Status")
if not statusRemote then
	statusRemote = Instance.new("RemoteEvent")
	statusRemote.Name = "Status"
	statusRemote.Parent = remoteFolder
end

local courtQueues = {}

local function getCourtSize(courtNumber)
	if courtNumber <= 2 then
		return 2 -- 1v1
	elseif courtNumber <= 6 then
		return 4 -- 2v2
	elseif courtNumber <= 9 then
		return 6 -- 3v3
	else
		return 8 -- 4v4
	end
end

local function getCourt(courtNumber)
	local map = workspace:FindFirstChild("Map")
	local courts = map and map:FindFirstChild("Courts")

	return courts and courts:FindFirstChild("Court" .. courtNumber)
end

local function findNearestSpot(player, spots)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root then
		return nil
	end

	local nearest
	local nearestDistance = math.huge

	for _, object in ipairs(spots:GetDescendants()) do
		if object:IsA("BasePart") then
			local distance = (root.Position - object.Position).Magnitude

			if distance < nearestDistance then
				nearestDistance = distance
				nearest = object
			end
		end
	end

	if nearest and nearestDistance <= 12 then
		return nearest
	end

	return nil
end

joinRemote.OnServerEvent:Connect(function(player, courtNumber)
	if typeof(courtNumber) ~= "number"
		or courtNumber % 1 ~= 0
		or courtNumber < 1
		or courtNumber > 10 then
		statusRemote:FireClient(player, "Invalid court")
		return
	end

	local court = getCourt(courtNumber)
	local spots = court and court:FindFirstChild("Spots")

	if not spots then
		statusRemote:FireClient(player, "Court or Spots folder not found")
		return
	end

	if not findNearestSpot(player, spots) then
		statusRemote:FireClient(player, "Move closer to a court spot")
		return
	end

	courtQueues[courtNumber] = courtQueues[courtNumber] or {}

	local queue = courtQueues[courtNumber]
	local capacity = getCourtSize(courtNumber)

	-- Prevent duplicate entries
	for _, queuedPlayer in ipairs(queue) do
		if queuedPlayer == player then
			statusRemote:FireClient(player, "Already queued")
			return
		end
	end

	if #queue >= capacity then
		statusRemote:FireClient(player, "Court queue is full")
		return
	end

	table.insert(queue, player)

	statusRemote:FireClient(
		player,
		"Queued for Court " .. courtNumber
			.. " (" .. #queue .. "/" .. capacity .. ")"
	)

	print(player.Name .. " queued for Court " .. courtNumber)
end)

Players.PlayerRemoving:Connect(function(player)
	for courtNumber, queue in pairs(courtQueues) do
		for index = #queue, 1, -1 do
			if queue[index] == player then
				table.remove(queue, index)
			end
		end
	end
end)

print("JAY CLONE PB SERVER READY")
