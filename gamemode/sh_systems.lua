if SERVER then AddCSLuaFile("sh_systems.lua") end

permission = {}
permission.NONE 	= 0
permission.ACCESS	= 1
permission.SYSTEM 	= 2
permission.SECURITY = 3

if not sys then
	sys = {}
	sys._dict = {}
else return end

local _mt = {}
_mt.__index = _mt

_mt._nwdata = nil

_mt.Name = "unnamed"
_mt.Room = nil
_mt.Ship = nil
_mt.Powered = false

_mt.SGUIName = "page"

function FindIncrement(current, target, increment)
	if target < current then
		return math.max(target - current, -increment)
	else
		return math.min(target - current, increment)
	end
end

function CalculatePowerCost(current, target, increment, powerPerUnit)
	return powerPerUnit * math.abs(FindIncrement(current, target, increment))
end

function CalculateNextValue(current, target, increment, ratio)
	local inc = FindIncrement(current, target, increment)

	if ratio > 0 then
		return current + inc * ratio
	else
		return current
	end
end

function _mt:Initialize()
	return
end

function _mt:GetShip()
	return self.Room:GetShip()
end

if SERVER then
	resource.AddFile("materials/systems/noicon.png")

	_mt._nwtablename = nil

	_mt._power = 0
	_mt._needed = 0

	function _mt:StartControlling(screen, ply)
		return
	end
	
	function _mt:StopControlling(screen, ply)
		return
	end
	
	function _mt:CalculatePowerNeeded()
		return 0
	end

	function _mt:SetPower(value)
		self._power = value

		if math.abs(self._power - (self._nwdata.power or 0)) >= 0.01 then
			self._nwdata.power = value
			self:_UpdateNWData()
		end
	end

	function _mt:GetPower()
		return self._power
	end

	function _mt:SetPowerNeeded(value)
		self._needed = value

		if math.abs(self._needed - (self._nwdata.needed or 0)) >= 0.01 then
			self._nwdata.needed = value
	        self:_UpdateNWData()
	    end
	end

	function _mt:GetPowerNeeded()
		return self._needed
	end

	function _mt:GetScreens()
		return self.Room:GetScreens()
	end
	
	function _mt:Think(dt)
		return
	end

	function _mt:_UpdateNWData()
		SetGlobalTable(self._nwtablename, self._nwdata)
	end
elseif CLIENT then
	function _mt:GetPower()
		return self._nwdata.power or 0
	end

	function _mt:GetPowerNeeded()
		return self._nwdata.needed or 0
	end

	function _mt:Remove()
		ForgetGlobalTable(self._nwtablename)
	end

	_mt.Icon = Material("systems/noicon.png", "smooth")
end

MsgN("Loading systems...")
local files = file.Find("finalfrontier/gamemode/systems/*.lua", "LUA")
for i, file in ipairs(files) do	
	local name = string.sub(file, 0, string.len(file) - 4)
	MsgN("  Loading system " .. name)

	if SERVER then AddCSLuaFile("systems/" .. file) end
	
	SYS = setmetatable({ Name = name }, _mt)
	SYS.__index = SYS
	include("systems/" .. file)
	
	sys._dict[name] = SYS
	SYS = nil
end

function sys.GetAll()
	return sys._dict
end

function sys.Create(name, room)
	if string.len(name) == 0 then return nil end
	if sys._dict[name] then
		local system = {
			Room = room,
			Ship = room:GetShip(),
			Base = _mt,
			_nwtablename = room:GetName() .. "_sys"
		}
		setmetatable(system, sys._dict[name])
		if SERVER then
			system._nwdata = {}
			system:SetPower(0)
		elseif CLIENT then
			system._nwdata = GetGlobalTable(system._nwtablename)
		end
		system:Initialize()
		if SERVER then system:_UpdateNWData() end
		return system
	end
	return nil
end
