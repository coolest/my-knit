-- ClientRemoteSignal
-- Stephen Leitnick
-- January 07, 2021

--[[

	remoteSignal = ClientRemoteSignal.new(remoteEvent: RemoteEvent)

	remoteSignal:Connect(handler: (...args: any)): Connection
	remoteSignal:Fire(...args: any): void
	remoteSignal:Wait(): (...any)
	remoteSignal:Destroy(): void

--]]


local IS_SERVER = game:GetService("RunService"):IsServer()
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet2 = require(ReplicatedStorage.BridgeNet2)

--------------------------------------------------------------
-- Connection

-- this entire object is pointless and just adds to the complication of this file............ good job dude

--[[
local Connection = {}
Connection.__index = Connection

function Connection.new(event, connection)
	local self = setmetatable({
		_conn = connection;
		_event = event;
		Connected = true;
	}, Connection)
	return self
end

function Connection:IsConnected()
	if (self._conn) then
		return self._conn.Connected
	end
	return false
end

function Connection:Disconnect()
	if (self._conn) then
		self._conn:Disconnect()
		self._conn = nil
	end
	if (not self._event) then return end
	self.Connected = false
	local connections = self._event._connections
	for i,c in ipairs(connections) do
		if (c == self) then
			connections[i] = connections[#connections]
			connections[#connections] = nil
			break
		end
	end
	self._event = nil
end

Connection.Destroy = Connection.Disconnect
]]

local function attemptToDisconnect(connection)
	local isAConnection = connection and typeof(connection) == "RBXScriptConnection"
	if not isAConnection then
		return;
	end

	if connection.Connected then
		connection:Disconnect();
	end
end

-- End Connection
--------------------------------------------------------------
-- ClientRemoteSignal

local ClientRemoteSignal = {}
ClientRemoteSignal.__index = ClientRemoteSignal

function ClientRemoteSignal.Is(object)
	return (type(object) == "table" and getmetatable(object) == ClientRemoteSignal)
end


function ClientRemoteSignal.new(identifier)
	assert(not IS_SERVER, "ClientRemoteSignal can only be created on the client")
	assert(identifier and typeof(identifier) == "string", "Argument #1 (identifier) expected string; got " .. typeof(identifier))

	local bridge = BridgeNet2.ClientBridge(identifier)
	return setmetatable({_bridge = bridge, _connections = {}, _active = true;}, ClientRemoteSignal)
end


function ClientRemoteSignal:Fire(...)
	if not self._active then
		return
	end;

	self._bridge:Fire(table.pack(...))
end


function ClientRemoteSignal:Wait()
	if not self._active then
		return
	end;

	return table.unpack(self._bridge:Wait())
end

function ClientRemoteSignal:Connect(handler)
	if not self._active then
		return
	end;

	local connection = self._bridge:Connect(function(...)
		handler(table.unpack(...))
	end)

	table.insert(self._connections, connection)

	return connection
end

function ClientRemoteSignal:Destroy()
	if not self._active then
		return
	end;

	for _, conn in ipairs(self._connections) do
		attemptToDisconnect(conn)
	end

	self._connections = nil
	self._bridge = nil;
	self._active = false;
end

return ClientRemoteSignal

--[[
function ClientRemoteSignal.Is(object)
	return (type(object) == "table" and getmetatable(object) == ClientRemoteSignal)
end


function ClientRemoteSignal.new(remoteEvent)
	assert(not IS_SERVER, "ClientRemoteSignal can only be created on the client")
	assert(typeof(remoteEvent) == "Instance", "Argument #1 (RemoteEvent) expected Instance; got " .. typeof(remoteEvent))
	assert(remoteEvent:IsA("RemoteEvent"), "Argument #1 (RemoteEvent) expected RemoteEvent; got" .. remoteEvent.ClassName)
	local self = setmetatable({
		_remote = remoteEvent;
		_connections = {};
	}, ClientRemoteSignal)
	return self
end


function ClientRemoteSignal:Fire(...)
	self._remote:FireServer(Ser.SerializeArgsAndUnpack(...))
end


function ClientRemoteSignal:Wait()
	return Ser.DeserializeArgsAndUnpack(self._remote.OnClientEvent:Wait())
end


function ClientRemoteSignal:Connect(handler)
	local connection = Connection.new(self, self._remote.OnClientEvent:Connect(function(...)
		handler(Ser.DeserializeArgsAndUnpack(...))
	end))
	table.insert(self._connections, connection)
	return connection
end


function ClientRemoteSignal:Destroy()
	for _,c in ipairs(self._connections) do
		if (c._conn) then
			c._conn:Disconnect()
		end
	end
	self._connections = nil
	self._remote = nil
end


return ClientRemoteSignal
]]