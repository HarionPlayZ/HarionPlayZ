sound.Add( {
	name = "tbogt_apc_fire1",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 110,
	pitch = 100,
	sound = "gta4/vehicles/apc_fire1.wav"
} )

sound.Add( {
	name = "tbogt_apc_fire2",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 110,
	pitch = 100,
	sound = "gta4/vehicles/apc_fire2.wav"
} )

sound.Add( {
	name = "tbogt_apc_fire3",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 110,
	pitch = 100,
	sound = "gta4/vehicles/apc_fire3.wav"
} )

sound.Add( {
	name = "tbogt_apc_fire4",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 110,
	pitch = 100,
	sound = "gta4/vehicles/apc_fire4.wav"
} )

local function mg_fire(ply,vehicle,shootOrigin,shootDirection)

	vehicle:EmitSound("tbogt_apc_fire"..math.random(1,4))
	
	local projectile = {}
		projectile.filter = vehicle.VehicleData["filter"]
		projectile.shootOrigin = shootOrigin
		projectile.shootDirection = shootDirection
		projectile.attacker = ply
		projectile.attackingent = vehicle
		projectile.Damage = 100
		projectile.Force = 50
		projectile.Size = 3
		projectile.BlastRadius = 50
		projectile.BlastDamage = 50
		projectile.DeflectAng = 40
		projectile.BlastEffect = "simfphys_tankweapon_explosion_micro"
	
	simfphys.FirePhysProjectile( projectile )
end

function simfphys.weapon:ValidClasses()
	
	local classes = {
		"sim_fphys_tbogt_apc"
	}
	
	return classes
end

function simfphys.weapon:Initialize( vehicle )
	local data = {}
	data.Attachment = "cannon.muzzle"
	data.Direction = Vector(1,0,0)
	data.Type = 3

	vehicle.MaxMag = 30
	vehicle:SetNWString( "WeaponMode", tostring( vehicle.MaxMag ) )
	
	simfphys.RegisterCrosshair( vehicle:GetDriverSeat(), data )
	simfphys.RegisterCamera( vehicle:GetDriverSeat(), Vector(0,0,60), Vector(0,0,60), true )
end

function simfphys.weapon:AimWeapon( ply, vehicle, pod )	
	local Aimang = pod:WorldToLocalAngles( ply:EyeAngles() )
	local AimRate = 125
	
	local Angles = vehicle:WorldToLocalAngles( Aimang ) - Angle(0,0,0)
	
	vehicle.sm_pp_yaw = vehicle.sm_pp_yaw and math.ApproachAngle( vehicle.sm_pp_yaw, Angles.y, AimRate * FrameTime() ) or 0
	vehicle.sm_pp_pitch = vehicle.sm_pp_pitch and math.ApproachAngle( vehicle.sm_pp_pitch, Angles.p, AimRate * FrameTime() ) or 0
	
	local TargetAng = Angle(vehicle.sm_pp_pitch,vehicle.sm_pp_yaw,0)
	TargetAng:Normalize() 
	
	vehicle:SetPoseParameter("cannon_yaw", -TargetAng.y)
	vehicle:SetPoseParameter("cannon_pitch", -TargetAng.p )
end

function simfphys.weapon:Think( vehicle )
	local pod = vehicle:GetDriverSeat()
	if not IsValid( pod ) then return end
	
	local ply = pod:GetDriver()
	
	local curtime = CurTime()
	
	if not IsValid( ply ) then 
		if vehicle.wpn then
			vehicle.wpn:Stop()
			vehicle.wpn = nil
		end
		
		return
	end
	
	self:AimWeapon( ply, vehicle, pod )
	
	local fire = ply:KeyDown( IN_ATTACK )
	local reload = ply:KeyDown( IN_RELOAD )
	
	if fire then
		self:PrimaryAttack( vehicle, ply, shootOrigin )
	end
	
	if reload then
		self:ReloadPrimary( vehicle )
	end
end

function simfphys.weapon:ReloadPrimary( vehicle )
	if not IsValid( vehicle ) then return end
	if vehicle.CurMag == vehicle.MaxMag then return end
	
	vehicle.CurMag = vehicle.MaxMag
	
	vehicle:EmitSound("simulated_vehicles/weapons/apc_reload.wav")
	
	self:SetNextPrimaryFire( vehicle, CurTime() + 2 )
	
	vehicle:SetNWString( "WeaponMode", tostring( vehicle.CurMag ) )
	
	vehicle:SetIsCruiseModeOn( false )
end

function simfphys.weapon:TakePrimaryAmmo( vehicle )
	vehicle.CurMag = isnumber( vehicle.CurMag ) and vehicle.CurMag - 1 or vehicle.MaxMag
	
	vehicle:SetNWString( "WeaponMode", tostring( vehicle.CurMag ) )
end

function simfphys.weapon:CanPrimaryAttack( vehicle )
	vehicle.CurMag = isnumber( vehicle.CurMag ) and vehicle.CurMag or vehicle.MaxMag
	
	if vehicle.CurMag <= 0 then
		self:ReloadPrimary( vehicle )
		return false
	end
	
	vehicle.NextShoot = vehicle.NextShoot or 0
	return vehicle.NextShoot < CurTime()
end

function simfphys.weapon:SetNextPrimaryFire( vehicle, time )
	vehicle.NextShoot = time
end

function simfphys.weapon:PrimaryAttack( vehicle, ply )
	if not self:CanPrimaryAttack( vehicle ) then return end
	
	vehicle.wOldPos = vehicle.wOldPos or vehicle:GetPos()
	local deltapos = vehicle:GetPos() - vehicle.wOldPos
	vehicle.wOldPos = vehicle:GetPos()
	
	local AttachmentID = vehicle:LookupAttachment( "cannon.muzzle" )
	local Attachment = vehicle:GetAttachment( AttachmentID )
	
	local shootOrigin = Attachment.Pos + deltapos * engine.TickInterval()
	local shootDirection = Attachment.Ang:Forward()
	
	local effectdata = EffectData()
		effectdata:SetOrigin( shootOrigin )
		effectdata:SetAngles( Attachment.Ang )
		effectdata:SetEntity( vehicle )
		effectdata:SetAttachment( AttachmentID )
		effectdata:SetScale( 4 )
	util.Effect( "CS_MuzzleFlash", effectdata, true, true )
	
	mg_fire( ply, vehicle, shootOrigin, shootDirection )
	
	self:TakePrimaryAmmo( vehicle )
	
	self:SetNextPrimaryFire( vehicle, CurTime() + 0.3 )
end
