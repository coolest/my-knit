-- RemoteSignal
-- Stephen Leitnick (L bozo u suck)
-- January 07, 2021

--[[

	remoteSignal = RemoteSignal.new()

	remoteSignal:Connect(handler: (player: Player, ...args: any) -> void): RBXScriptConnection
	remoteSignal:Fire(player: Player, ...args: any): void
	remoteSignal:FireAll(...args: any): void
	remoteSignal:FireExcept(player: Player, ...args: any): void
	remoteSignal:Wait(): (...any)
	remoteSignal:Destroy(): void

--]]


local IS_SERVER = game:GetService("RunService"):IsServer()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)

local function VerifyPlayer(player)
	if not player then 
		return false
	end

	local isTypePlayer = player:IsA("Player")
	if not isTypePlayer then
		return Players:GetPlayerFromCharacter(player)
	end

	return player;
end

local RemoteSignal = {_GLOBAL_COUNT = 0;}
RemoteSignal.__index = RemoteSignal

function RemoteSignal.Is(object)
	return (type(object) == "table" and getmetatable(object) == RemoteSignal)
end

function RemoteSignal.new(identifier)
	assert(IS_SERVER, "RemoteSignal can only be created on the server")
	assert(identifier and type(identifier) == "string", debug.traceback(2) .. "\nIdentifier of type string needs to be provided")

	RemoteSignal._GLOBAL_COUNT += 1;

	local bridge = BridgeNet2.ServerBridge(identifier)
	--[[
	if not (identifier == "UpdateMouse") then
		bridge.Logging = true;
	end
	]]

	return setmetatable({_bridge = bridge, _active = true; _id = identifier}, RemoteSignal)
end

function RemoteSignal:Fire(player, ...)
	if not self._active then
		return;
	end

	player = VerifyPlayer(player)

	if player then
		self._bridge:Fire(player, table.pack(...))
	end
end

function RemoteSignal:FireAll(...)
	if not self._active then
		return;
	end

	self._bridge:Fire(BridgeNet2.AllPlayers(), table.pack(...))
end

function RemoteSignal:FireAllWithinRangeOf(playerOrCharacter, distance, ...)
	local char;
	if playerOrCharacter:IsA("Player") then
		char = playerOrCharacter.playerOrCharacter
	else
		char = playerOrCharacter
	end

	assert(char, debug.traceback(2) .. "\nCould not find character from (1st) argument provided.")

	local root1 = char:FindFirstChild("HumanoidRootPart")
	assert(root1, debug.traceback(2) .. "\nCould not find root of character provided.")

	local players = {}
	for _, plrToFire in ipairs(Players:GetPlayers()) do
		local charToFire = plrToFire.Character
		local root2 = charToFire and charToFire:FindFirstChild("HumanoidRootPart")
		if root2 and (root1.Position - root2.Position).Magnitude < distance and not table.find(players, plrToFire) then
			table.insert(players, plrToFire)

			local dwPlrName = charToFire:GetAttribute("DreamwalkingPlr")
			if dwPlrName then
				local dwPlr = Players:FindFirstChild(dwPlrName)
				if dwPlr and not table.find(players, dwPlr) then
					table.insert(players, dwPlr)
				end
			end
		end
	end

	self._bridge:Fire(BridgeNet2.Players(players), table.pack(...))

	return players
end

function RemoteSignal:FirePlayers(players, ...)
	assert(players and type(players) == "table", debug.traceback(2) .. "\nNeed to provide an array of players.")

	self._bridge:Fire(BridgeNet2.Players(players), table.pack(...))
end

function RemoteSignal:FireExcept(player, ...)
	if not self._active then
		return;
	end

	player = VerifyPlayer(player)

	if player then
		self._bridge:Fire(BridgeNet2.PlayersExcept({ player }), table.pack(...))
	end
end

function RemoteSignal:Wait()
	if not self._active then
		return;
	end

	return self._bridge:Wait()
end

function RemoteSignal:Connect(handler)
	if not self._active then
		return;
	end

	return self._bridge:Connect(function(player, argTable)
		handler(player, table.unpack(argTable))
	end)
end

function RemoteSignal:Destroy()
	self._active = false;
end

return RemoteSignal

--[[
function RemoteSignal.Is(object)
	return (type(object) == "table" and getmetatable(object) == RemoteSignal)
end


function RemoteSignal.new()
	assert(IS_SERVER, "RemoteSignal can only be created on the server")
	local self = setmetatable({
		_remote = Instance.new("RemoteEvent");
	}, RemoteSignal)
	return self
end


function RemoteSignal:Fire(player, ...)
	if not player then return end
	player = player:IsA("Player") and player or game.Players:GetPlayerFromCharacter(player)
	if player then
		self._remote:FireClient(player, Ser.SerializeArgsAndUnpack(...))
	end
end


function RemoteSignal:FireAll(...)
	self._remote:FireAllClients(Ser.SerializeArgsAndUnpack(...))
end


function RemoteSignal:FireExcept(player, ...)
	local args = Ser.SerializeArgs(...)
	for _,plr in ipairs(Players:GetPlayers()) do
		if (plr ~= player) then
			self._remote:FireClient(plr, Ser.UnpackArgs(args))
		end
	end
end


function RemoteSignal:Wait()
	return self._remote.OnServerEvent:Wait()
end


function RemoteSignal:Connect(handler)
	return self._remote.OnServerEvent:Connect(function(player, ...)
		handler(player, Ser.DeserializeArgsAndUnpack(...))
	end)
end


function RemoteSignal:Destroy()
	self._remote:Destroy()
	self._remote = nil
end


return RemoteSignal
]]