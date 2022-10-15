-- | Variables

local Players = game:GetService("Players")
local MessagingService : MessagingService = game:GetService("MessagingService")
local DatastoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- | Configuration

local ModerationDatastore = DatastoreService:GetDataStore("ModerationService_Data") -- Changing this will erase all data!!
local DefaultReasonKick = "[ModerationService] You were removed from this running game instance. Rejoining is granted."
local DefaultReasonBan = "[ModerationService] You were banned from this running game instance. Rejoining is denied."
local DefaultReasonWarn = "[ModerationService] Reason unspecified."

-- | Code @ DO NOT TOUCH UNLESS YOU KNOW WHAT YOU ARE DOING

if not RunService:IsServer() then return error("ModerationService can only be required from server") end

local service = {}

function service:viewWarnings(UserId)
	if UserId == nil or not UserId then return error("Parameter UserId is nil") end
	
	local DataValue
	local success, result = pcall(function()
		DataValue = ModerationDatastore:GetAsync("-Warn"..UserId)
	end)
	if not success then
		warn("[ModerationService] Failed to Get DataStore Value for "..UserId..".\nError:",result)
		return
	else
		if DataValue == nil then
			return nil
		else
			return DataValue
		end
	end
end

function service:addWarning(UserId, Reason)
	if UserId == nil then return error("Parameter UserId is nil") end
	if Reason == nil then Reason = DefaultReasonWarn end
	
	local Warnings = service:viewWarnings(UserId)
	local success, result = pcall(function()
		if typeof(Warnings) ~= "table" then
			ModerationDatastore:SetAsync("-Warn"..UserId,{Reason})
		else
			table.insert(Warnings, Reason)
			ModerationDatastore:SetAsync("-Warn"..UserId,Warnings)
		end
	end)
	if not success then
		warn("[ModerationService] Failed to Set DataStore Value for "..UserId..".\nError:",result)
		return
	end
end

function service:Kick(UserId, Reason)
	if UserId == nil then return error("Parameter UserId is nil") end
	if Reason == nil then Reason = DefaultReasonKick end
	if not RunService:IsStudio() then
		MessagingService:PublishAsync("ModerationService_CreateAction",{UserId, Reason})
	else
		local Player = Players:GetPlayerByUserId(UserId)
		if not Player then return end
		Player:Kick(Reason)
	end
end

function service:Ban(UserId, Reason, Moderator)
	if UserId == nil then return error("Parameter UserId is nil") end
	if Reason == nil then Reason = DefaultReasonBan end
	
	if not RunService:IsStudio() then
		MessagingService:PublishAsync("ModerationService_CreateAction",{UserId, Reason})
	else
		local Player = Players:GetPlayerByUserId(UserId)
		if not Player then return end
		Player:Kick(Reason)
	end
	
	local Key = "-Ban"..UserId
	local success, result = pcall(function()
		ModerationDatastore:SetAsync(Key,{Reason, Moderator})
	end)
	if not success then
		warn("[ModerationService] Failed to Set DataStore Value for "..UserId..".\nError:",result)
		return
	end
end

function service:CheckBan(UserId)
	if UserId == nil then return error("Parameter UserId is nil") end
	local Key = "-Ban"..UserId
	local DataValue
	local success, result = pcall(function()
		DataValue = ModerationDatastore:GetAsync(Key)
	end)
	if not success then
		warn("[ModerationService] Failed to Get DataStore Value for "..UserId..".\nError:",result)
		return {false,false}
	else
		if DataValue == nil then
			return {false,false}
		else
			return {true,DataValue[1]}
		end
	end
end

function service:Unban(UserId)
	local BanData = service:CheckBan(UserId)
	if typeof(BanData) ~= "table" then return end
	local IsBanned = BanData[1]
	if IsBanned then
		local Key = "-Ban"..UserId
		local success, result = pcall(function()
			ModerationDatastore:RemoveAsync(Key)
		end)
		if not success then
			warn("[ModerationService] Failed to Remove Data Value\nError:",result)
			return
		end
	end
end

return service
