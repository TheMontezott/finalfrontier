local TEMPERATURE_LOSS_RATE = 0.00000382

ENT.Type = "brush"
ENT.Base = "base_brush"

ENT.Ship = nil
ENT.ShipName = nil
ENT.System = nil
ENT.Volume = 1000
ENT.SurfaceArea = 60

ENT.Screens = nil
ENT.DoorNames = nil
ENT.Doors = nil

ENT._lastupdate = 0

ENT._temperature = 298
ENT._pressure = 100000
ENT._maxshield = 20

function ENT:KeyValue( key, value )
	if key == "ship" then
		self.ShipName = tostring( value )
	elseif key == "system" then
		self.System = tostring( value )
	elseif key == "volume" then
		self.Volume = tonumber( value )
		self.SurfaceArea = math.sqrt( self.Volume ) * 6
	elseif string.find( key, "^door%d*" ) then
		self.DoorNames = self.DoorNames or {}
		table.insert( self.DoorNames, tostring( value ) )
	end
end

function ENT:InitPostEntity()
	self.Doors = {}
	self.Screens = {}
	
	if not self.DoorNames then
		MsgN( self:GetName() .. " has no doors!" )
	end
	
	self.DoorNames = self.DoorNames or {}

	if self.ShipName then
		self.Ship = Ships.FindByName( self.ShipName )
		if self.Ship then
			self.Ship:AddRoom( self )
		end
	end
	
	if not self.Ship then
		Error( "Room at " .. tostring( self:GetPos() ) .. " (" .. self:GetName() .. ") has no ship!\n" )
		return
	end
	
	for _, name in ipairs( self.DoorNames ) do
		local doors = ents.FindByName( name )
		if #doors > 0 then
			local door = doors[ 1 ]
			door:AddRoom( self )
			self:AddDoor( door )
		end
	end
	
	self._pressure = math.random() * 100000 + 50000
	self._lastupdate = CurTime()
end

function ENT:Think()
	local curTime = CurTime()
	local dt = curTime - self._lastupdate
	self._lastupdate = curTime

	self._temperature = self._temperature * ( 1 - TEMPERATURE_LOSS_RATE * self.SurfaceArea * dt )
end

function ENT:AddDoor( door )
	table.insert( self.Doors, door )
end

function ENT:AddScreen( screen )
	table.insert( self.Screens, screen )
end

function ENT:GetTemperature()
	return self._temperature
end

function ENT:GetPressure()
	return self._pressure
end

function ENT:TransmitPressure( room, delta )
	if delta < 0 then room:TransmitPressure( self, delta ) return end

	delta = delta / self.Volume
	if delta > self._pressure then delta = self_pressure end
	self._pressure = self._pressure - delta
	room._pressure = room._pressure + delta
end

function ENT:GetMaxShield()
	return self._maxshield
end
