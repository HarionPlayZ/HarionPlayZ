local screenw = ScrW()
local screenh = ScrH()
local Widescreen = (screenw / screenh) > (4 / 3)
local sizex = screenw * (Widescreen and 1 or 1.32)
local sizey = screenh
local xpos = sizex * 0.02
local ypos = sizey * 0.8
local x = xpos * (Widescreen and 43.5 or 32)
local y = ypos * 1.015
local radius = 0.085 * sizex
local startang = 105

local lights_on = Color(107, 211, 55, 150)
local lights_on2 = Color(55, 121, 211, 150)
local lights_off = Color(0, 0, 0, 150)
local lights = Material( "ag_hud/ag_l.png" )
local hbrake_on = Color(250,0,0,250)
local hbrake_off = Color(0, 0, 0, 150)
local hbrake = Material( "ag_hud/ag_p.png" )
local ag_speed = Material("ag_hud/ag_speed.png", "unlitgeneric")
local ag_fuel = Material("ag_hud/ag_fuel.png", "unlitgeneric")
local engine = Material( "vcmod/gui/icons/dashboard/engine.png" , "unlitgeneric")
local ForceSimpleHud = not file.Exists( "materials/simfphys/hud/hud.vmt", "GAME" ) -- lets check if the background material exists, if not we will force the old hud to prevent fps drop
local smHider = 0

local ShowHud = false
local ShowHud_ms = false
local AltHud = false
local AltHudarcs = false
local Hudmph = false
local Hudmpg = false
local Hudreal = false
local isMouseSteer = false
local hasCounterSteerEnabled = false
local slushbox = false
local hudoffset_x = 0
local hudoffset_y = 0

local turnmenu = KEY_COMMA

local ms_sensitivity = 1
local ms_fade = 1
local ms_deadzone = 1.5
local ms_exponent = 2
local ms_key_freelook = KEY_Y

cvars.AddChangeCallback( "cl_simfphys_hud", function( convar, oldValue, newValue ) ShowHud = tonumber( newValue )~=0 end)
cvars.AddChangeCallback( "cl_simfphys_hud_offset_x", function( convar, oldValue, newValue ) hudoffset_x = newValue end)
cvars.AddChangeCallback( "cl_simfphys_hud_offset_y", function( convar, oldValue, newValue ) hudoffset_y = newValue end)
cvars.AddChangeCallback( "cl_simfphys_ms_hud", function( convar, oldValue, newValue ) ShowHud_ms = tonumber( newValue )~=0 end)
cvars.AddChangeCallback( "cl_simfphys_althud", function( convar, oldValue, newValue ) AltHud = tonumber( newValue )~=0 end)
cvars.AddChangeCallback( "cl_simfphys_althud_arcs", function( convar, oldValue, newValue ) AltHudarcs = tonumber( newValue )~=0 end)
cvars.AddChangeCallback( "cl_simfphys_hudmph", function( convar, oldValue, newValue ) Hudmph = tonumber( newValue )~=0 end)
cvars.AddChangeCallback( "cl_simfphys_hudmpg", function( convar, oldValue, newValue ) Hudmpg = tonumber( newValue )~=0 end)
cvars.AddChangeCallback( "cl_simfphys_hudrealspeed", function( convar, oldValue, newValue ) Hudreal = tonumber( newValue )~=0 end)
cvars.AddChangeCallback( "cl_simfphys_mousesteer", function( convar, oldValue, newValue ) isMouseSteer = tonumber( newValue )~=0 end)
cvars.AddChangeCallback( "cl_simfphys_ctenable", function( convar, oldValue, newValue ) hasCounterSteerEnabled = tonumber( newValue )~=0 end)
cvars.AddChangeCallback( "cl_simfphys_auto", function( convar, oldValue, newValue ) slushbox = tonumber( newValue )~=0 end)
cvars.AddChangeCallback( "cl_simfphys_ms_sensitivity", function( convar, oldValue, newValue )  ms_sensitivity = tonumber( newValue ) end)
cvars.AddChangeCallback( "cl_simfphys_ms_return", function( convar, oldValue, newValue )  ms_fade = tonumber( newValue ) end)
cvars.AddChangeCallback( "cl_simfphys_ms_deadzone", function( convar, oldValue, newValue )  ms_deadzone = tonumber( newValue ) end)
cvars.AddChangeCallback( "cl_simfphys_ms_exponent", function( convar, oldValue, newValue ) ms_exponent = tonumber( newValue ) end)
cvars.AddChangeCallback( "cl_simfphys_ms_keyfreelook", function( convar, oldValue, newValue ) ms_key_freelook = tonumber( newValue ) end)
cvars.AddChangeCallback( "cl_simfphys_key_turnmenu", function( convar, oldValue, newValue ) turnmenu = tonumber( newValue ) end)

ShowHud = GetConVar( "cl_simfphys_hud" ):GetBool()
hudoffset_x = GetConVar( "cl_simfphys_hud_offset_x" ):GetFloat()
hudoffset_y = GetConVar( "cl_simfphys_hud_offset_y" ):GetFloat()
ShowHud_ms = GetConVar( "cl_simfphys_ms_hud" ):GetBool()
AltHud = GetConVar( "cl_simfphys_althud" ):GetBool()
AltHudarcs = GetConVar( "cl_simfphys_althud_arcs" ):GetBool()
Hudmph = GetConVar( "cl_simfphys_hudmph" ):GetBool()
Hudmpg = GetConVar( "cl_simfphys_hudmpg" ):GetBool()
Hudreal = GetConVar( "cl_simfphys_hudrealspeed" ):GetBool()
isMouseSteer = GetConVar( "cl_simfphys_mousesteer" ):GetBool()
hasCounterSteerEnabled = GetConVar( "cl_simfphys_ctenable" ):GetBool()
slushbox = GetConVar( "cl_simfphys_auto" ):GetBool()
turnmenu = GetConVar( "cl_simfphys_key_turnmenu" ):GetInt()

ms_sensitivity = GetConVar( "cl_simfphys_ms_sensitivity" ):GetFloat()
ms_fade = GetConVar( "cl_simfphys_ms_return" ):GetFloat()
ms_deadzone = GetConVar( "cl_simfphys_ms_deadzone" ):GetFloat()
ms_exponent = GetConVar( "cl_simfphys_ms_exponent" ):GetFloat()
ms_key_freelook = GetConVar( "cl_simfphys_ms_keyfreelook" ):GetInt()

local ms_pos_x = 0
local sm_throttle = 0

local function DrawCircle( X, Y, radius )
	local segmentdist = 360 / ( 2 * math.pi * radius / 2 )
	
	for a = 0, 360 - segmentdist, segmentdist do
		surface.DrawLine( X + math.cos( math.rad( a ) ) * radius, Y - math.sin( math.rad( a ) ) * radius, X + math.cos( math.rad( a + segmentdist ) ) * radius, Y - math.sin( math.rad( a + segmentdist ) ) * radius )
	end
end

hook.Add( "StartCommand", "simfphysmove", function( ply, cmd )
	if ply ~= LocalPlayer() then return end
	
	local vehicle = ply:GetVehicle()
	if not IsValid(vehicle) then return end
	
	if isMouseSteer then
		local freelook = input.IsButtonDown( ms_key_freelook )
		ply.Freelook = freelook
		if not freelook then 
			local frametime = FrameTime()
			
			local ms_delta_x = cmd:GetMouseX()
			local ms_return = ms_fade * frametime
			
			local Moving = math.abs(ms_delta_x) > 0
			
			ms_pos_x = Moving and math.Clamp(ms_pos_x + ms_delta_x * frametime * 0.05 * ms_sensitivity,-1,1) or (ms_pos_x + math.Clamp(-ms_pos_x,-ms_return,ms_return))
			
			SteerVehicle = ((math.max( math.abs(ms_pos_x) - ms_deadzone / 16, 0) ^ ms_exponent) / (1 - ms_deadzone / 16))  * ((ms_pos_x > 0) and 1 or -1)
			
		end
	else
		SteerVehicle = 0
	end
	
	net.Start( "simfphys_mousesteer" )
		net.WriteEntity( vehicle )
		net.WriteFloat( SteerVehicle )
	net.SendToServer()
end)

local function drawsimfphysHUD(vehicle,SeatCount)
	if isMouseSteer and ShowHud_ms then
		local MousePos = ms_pos_x
		local m_size = sizex * 0.15
		
		draw.SimpleText( "V", "DarkRPHUD1", sizex * 0.5 + MousePos * m_size - 1, sizey * 0.45, Color( 240, 230, 200, 255 ), 1, 1 )
		draw.SimpleText( "[", "DarkRPHUD1", sizex * 0.5 - m_size * 1.05, sizey * 0.45, Color( 240, 230, 200, 180 ), 1, 1 )
		draw.SimpleText( "]", "DarkRPHUD1", sizex * 0.5 + m_size * 1.05, sizey * 0.45, Color( 240, 230, 200, 180 ), 1, 1 )
		
		if (ms_deadzone > 0) then
			draw.SimpleText( "^", "DarkRPHUD1", sizex * 0.5 - (ms_deadzone / 16) * m_size, sizey * 0.453, Color( 240, 230, 200, 180 ), 1, 2 )
			draw.SimpleText( "^", "DarkRPHUD1", sizex * 0.5 + (ms_deadzone / 16) * m_size, sizey * 0.453, Color( 240, 230, 200, 180 ), 1, 2 )
		else
			draw.SimpleText( "^", "DarkRPHUD1", sizex * 0.5, sizey * 0.453, Color( 240, 230, 200, 180 ), 1, 2 )
		end
	end
	
	if not ShowHud then return end
	
	if vehicle:GetNWBool( "simfphys_NoHud", false ) then return end
	
	local maxrpm = vehicle:GetLimitRPM()
	local rpm = vehicle:GetRPM()
	local throttle = math.Round(vehicle:GetThrottle() * 100,0)
	local revlimiter = vehicle:GetRevlimiter() and (maxrpm > 2500) and (throttle > 0)
	
	local SimpleHudIsForced = vehicle:GetNWBool( "simfphys_NoRacingHud", false )
	
	local powerbandend = math.min(vehicle:GetPowerBandEnd(), maxrpm)
	local redline = math.max(rpm - powerbandend,0) / (maxrpm - powerbandend)
	
	local Active = vehicle:GetActive() and "" or "!"
	local speed = vehicle:GetVelocity():Length()
	local mph = math.Round(speed * 0.0568182,0)
	local kmh = math.Round(speed * 0.09144,0)
	local wiremph = math.Round(speed * 0.0568182 * 0.75,0)
	local wirekmh = math.Round(speed * 0.09144 * 0.75,0)
	local cruisecontrol = vehicle:GetIsCruiseModeOn()
	local gear = vehicle:GetGear()
	local DrawGear = not slushbox and (gear == 1 and "R" or gear == 2 and "N" or (gear - 2)) or (gear == 1 and "R" or gear == 2 and "N" or "(".. (gear - 2)..")")
	
	local o_x = hudoffset_x * screenw
	local o_y = hudoffset_y * screenh
	
	local fuel = vehicle:GetFuel() / vehicle:GetMaxFuel()
	local fueltype = vehicle:GetFuelType()
	local fueltype_color = Color(0,127,255,150)
	if fueltype == 1 then
		fueltype_color = Color(240,200,0,150)
	elseif fueltype == 2 then
		fueltype_color = Color(255,60,0,150)
	end
	
	if AltHud and not ForceSimpleHud and not SimpleHudIsForced then
		o_x = o_x - smHider * 300 - (SeatCount > 0 and 45 or 0)
		
		local LightsOn = vehicle:GetLightsEnabled()
		local LampsOn = vehicle:GetLampsEnabled()
		local FogLightsOn = vehicle:GetFogLightsEnabled()
		local HandBrakeOn = vehicle:GetHandBrakeEnabled()
		
		s_smoothrpm = s_smoothrpm or 0
		s_smoothrpm = math.Clamp(s_smoothrpm + (rpm - s_smoothrpm) * 0.3,0,maxrpm)
		
		local endang = startang + math.Round( (s_smoothrpm/maxrpm) * 255, 0)
		local c_ang = math.cos( math.rad(endang) )
		local s_ang = math.sin( math.rad(endang) )
		
		local ang_pend = startang + math.Round( (powerbandend / maxrpm) * 255, 0)
		local r_rpm = math.floor(maxrpm / 1000) * 1000
		local in_red = s_smoothrpm < powerbandend
		local r = math.Round( radius, 0)

		local Carspeed = (ScrH()*0.005) + (r*fuel)/120 * (ScrW()*0.05)
		draw.RoundedBox(0, 0, ScrH() - 35, 90, 35, Color(0, 0, 0, 200))
		draw.RoundedBox(0, 91, ScrH() - 35, 20, 35, Color(0, 0, 0, 200))
		draw.RoundedBox(0, 112, ScrH() - 35, 40, 35, Color(0, 0, 0, 200))
		
		local base_hud_car = {
			{ x = 152, y = ScrH() - 35 },
			{ x = 200, y = ScrH() - 0 },
			{ x = 152, y = ScrH() - 0 }
			}
		surface.SetDrawColor( 0, 0, 0, 200 )
		draw.NoTexture()
		surface.DrawPoly( base_hud_car )
	
		surface.SetDrawColor(255, 255, 255, 200)
		surface.SetMaterial( ag_speed )
		surface.DrawTexturedRect(5, ScrH() - 30, 25, 25)
	
		surface.SetDrawColor(0, 0, 0, 150)
		surface.SetMaterial( ag_fuel )
		surface.DrawTexturedRect(120, ScrH() - 28 , 24, 24 )
		
		render.SetScissorRect( 120, ScrH() - 28*(fuel), 120 + 24, ScrH() - 28 + 24, true )
			surface.SetDrawColor(197, 155, 43, 200)
			surface.SetMaterial( ag_fuel )
			surface.DrawTexturedRect( 120, ScrH() - 28 , 24, 24 )
		render.SetScissorRect( 0, 0, 0, 0, false )

		local center_ncol = in_red and Color(0,254,235,200) or Color( 255, 0, 0, 255 )
		local printspeed = Hudmph and (Hudreal and mph or wiremph) or (Hudreal and kmh or wirekmh)
		
		local digit_1  =  printspeed % 10
		local digit_2 =  (printspeed - digit_1) % 100
		local digit_3  = (printspeed - digit_1 - digit_2) % 1000
		
		local col_on = Color(150,150,150,50)
		local col_off = Color(255,255,255,150)
		local col1 = (printspeed > 0) and col_off or col_on
		local col2 = (printspeed >= 10) and col_off or col_on
		local col3 = (printspeed >= 100) and col_off or col_on
		
		draw.SimpleText( digit_1, "DarkRPHUD1",75, ScrH() - 17, Color(200,200,200,250), 1, 1 )
		draw.SimpleText( digit_2/ 10, "DarkRPHUD1", 62, ScrH() - 17, Color(200,200,200,250), 1, 1 )
		draw.SimpleText( digit_3 / 100, "DarkRPHUD1", 48, ScrH() - 17, Color(200,200,200,250), 1, 1 )
		draw.SimpleText( ( (gear == 1 and "R" or gear == 2 and "N" or (gear - 2))), "DarkRPHUD1", 100, ScrH() - 17, Color(200,200,200,250), 1, 1 )

		local Color_l = LightsOn and (LampsOn and lights_on2 or lights_on) or lights_off
		surface.SetDrawColor( Color_l )
		surface.SetMaterial( lights )
		surface.DrawTexturedRect(  5, ScrH() - 90, 24, 24  )

		
		local Color_m = HandBrakeOn and hbrake_on or hbrake_off
		surface.SetDrawColor( Color_m )
		surface.SetMaterial( hbrake )
		surface.DrawTexturedRect( 5, ScrH() - 60, 24, 20 )

		
		local fueluse = vehicle:GetFuelUse()
		if fueluse == -1 then return end
		
		local r = math.Round( radius, 0)
		surface.SetDrawColor( Color(150,150,150,50) )
		
		--surface.SetDrawColor( fueltype_color )
		--surface.DrawRect(32, ScrH() - 20, r * fuel, 14 )

		if fueltype ~= 1 and fueltype ~= 2 then return end
		
		local ecospeed = (Hudreal and kmh or wirekmh)
		if Hudmpg then
			calc_fueluse = 235.214 / calc_fueluse
		end
		return
	end
	
	local s_xpos = xpos
	local s_ypos = ypos
	
	if SimpleHudIsForced then
		o_x = 0
		o_y = 0
		s_xpos = screenw * 0.5 - sizex * 0.115 - sizex * 0.032
		s_ypos = screenh - sizey * 0.092 - sizey * 0.02
	else
		draw.RoundedBox( 8, s_xpos + o_x, s_ypos + o_y, sizex * 0.118, sizey * 0.075, Color( 0, 0, 0, 80 ) )
	end
	
	if cruisecontrol then
		draw.SimpleText( "cruise", "DarkRPHUD1", s_xpos + sizex * 0.115 + o_x, s_ypos + sizey * 0.035 + o_y, Color( 255, 127, 0, 255 ), 2, 1 )
	end

	draw.SimpleText( "Throttle: "..throttle.." %", "DarkRPHUD1", s_xpos + sizex * 0.005 + o_x, s_ypos + sizey * 0.035 + o_y, Color( 255, 235, 0, 255 ), 0, 1)
	
	draw.SimpleText( "RPM: "..math.Round(rpm,0)..Active, "DarkRPHUD1", s_xpos + sizex * 0.005 + o_x, s_ypos + sizey * 0.012 + o_y, Color( 255, 235 * (1 - redline), 0, 255 ), 0, 1 )
	
	draw.SimpleText( "GEAR:", "DarkRPHUD1", s_xpos + sizex * 0.062 + o_x, s_ypos + sizey * 0.012 + o_y, Color( 255, 235, 0, 255 ), 0, 1 )
	draw.SimpleText( DrawGear, "DarkRPHUD1", s_xpos + sizex * 0.11 + o_x, s_ypos + sizey * 0.012 + o_y, Color( 255, 235, 0, 255 ), 2, 1 )
	
	draw.SimpleText( (Hudreal and mph or wiremph).." mph", "DarkRPHUD1", s_xpos + sizex * 0.005 + o_x, s_ypos + sizey * 0.062 + o_y, Color( 255, 235, 0, 255 ), 0, 1 )
	
	draw.SimpleText( (Hudreal and kmh or wirekmh).." kmh", "DarkRPHUD1", s_xpos + sizex * 0.11 + o_x, s_ypos + sizey * 0.062 + o_y, Color( 255, 235, 0, 255 ), 2, 1 )
	
	
	local fueluse = vehicle:GetFuelUse()
	if fueluse == -1 then return end

	local r = math.Round(sizey * 0.075,0)
	surface.SetDrawColor( Color(0,0,0,80) )
	surface.DrawRect( s_xpos + o_x - sizex * 0.007, s_ypos + o_y, sizex * 0.0025, r * (1 - fuel) )
	surface.SetDrawColor( fueltype_color )
	surface.DrawRect( s_xpos + o_x - sizex * 0.007, s_ypos + o_y + r * (1 - fuel), sizex * 0.0025, r * fuel )
end

local turnmode = 0
local turnmenu_wasopen = false

local function drawTurnMenu( vehicle )
	
	if input.IsKeyDown( GetConVar( "cl_simfphys_keyforward" ):GetInt() ) or  input.IsKeyDown( GetConVar( "cl_simfphys_key_air_forward" ):GetInt() ) then
		turnmode = 0
	end
	
	if input.IsKeyDown( GetConVar( "cl_simfphys_keyleft" ):GetInt() ) or input.IsKeyDown( GetConVar( "cl_simfphys_key_air_left" ):GetInt() ) then
		turnmode = 2
	end
	
	if input.IsKeyDown( GetConVar( "cl_simfphys_keyright" ):GetInt() ) or input.IsKeyDown( GetConVar( "cl_simfphys_key_air_right" ):GetInt() ) then
		turnmode = 3
	end
	
	if input.IsKeyDown( GetConVar( "cl_simfphys_keyreverse" ):GetInt() ) or input.IsKeyDown( GetConVar( "cl_simfphys_key_air_reverse" ):GetInt() ) then
		turnmode = 1
	end
	
	local cX = ScrW() / 2
	local cY = ScrH() / 2
	
	local sx = sizex * 0.065
	local sy = sizex * 0.065
	
	local selectorX = (turnmode == 2 and (-sx - 1) or 0) + (turnmode == 3 and (sx + 1) or 0)
	local selectorY = (turnmode == 0 and (-sy - 1) or 0)
	
	draw.RoundedBox( 8, cX - sx * 0.5 - 1 + selectorX, cY - sy * 0.5 - 1 + selectorY, sx + 2, sy + 2, Color( 240, 200, 0, 255 ) )
	draw.RoundedBox( 8, cX - sx * 0.5 + selectorX, cY - sy * 0.5 + selectorY, sx, sy, Color( 50, 50, 50, 255 ) )
	
	draw.RoundedBox( 8, cX - sx * 0.5, cY - sy * 0.5, sx, sy, Color( 0, 0, 0, 100 ) )
	draw.RoundedBox( 8, cX - sx * 0.5, cY - sy * 1.5 - 1, sx, sy, Color( 0, 0, 0, 100 ) )
	draw.RoundedBox( 8, cX - sx * 1.5 - 1, cY - sy * 0.5, sx, sy, Color( 0, 0, 0, 100 ) )
	draw.RoundedBox( 8, cX + sx * 0.5 + 1, cY - sy * 0.5, sx, sy, Color( 0, 0, 0, 100 ) )
	
	surface.SetDrawColor( 240, 200, 0, 100 ) 
	--X
	if turnmode == 0 then
		surface.SetDrawColor( 240, 200, 0, 255 ) 
	end
	surface.DrawLine( cX - sx * 0.3, cY - sy - sy * 0.3, cX + sx * 0.3, cY - sy + sy * 0.3 )
	surface.DrawLine( cX + sx * 0.3, cY - sy - sy * 0.3, cX - sx * 0.3, cY - sy + sy * 0.3 )
	surface.SetDrawColor( 240, 200, 0, 100 ) 
	
	-- <=
	if turnmode == 2 then
		surface.SetDrawColor( 240, 200, 0, 255 ) 
	end
	surface.DrawLine( cX - sx + sx * 0.3, cY - sy * 0.15, cX - sx + sx * 0.3, cY + sy * 0.15 )
	surface.DrawLine( cX - sx + sx * 0.3, cY + sy * 0.15, cX - sx, cY + sy * 0.15 )
	surface.DrawLine( cX - sx + sx * 0.3, cY - sy * 0.15, cX - sx, cY - sy * 0.15 )
	surface.DrawLine( cX - sx, cY - sy * 0.3, cX - sx, cY - sy * 0.15 )
	surface.DrawLine( cX - sx, cY + sy * 0.3, cX - sx, cY + sy * 0.15 )
	surface.DrawLine( cX - sx, cY + sy * 0.3, cX - sx - sx * 0.3, cY )
	surface.DrawLine( cX - sx, cY - sy * 0.3, cX - sx - sx * 0.3, cY )
	surface.SetDrawColor( 240, 200, 0, 100 ) 
	
	-- =>
	if turnmode == 3 then
		surface.SetDrawColor( 240, 200, 0, 255 ) 
	end
	surface.DrawLine( cX + sx - sx * 0.3, cY - sy * 0.15, cX + sx - sx * 0.3, cY + sy * 0.15 )
	surface.DrawLine( cX + sx - sx * 0.3, cY + sy * 0.15, cX + sx, cY + sy * 0.15 )
	surface.DrawLine( cX + sx - sx * 0.3, cY - sy * 0.15, cX + sx, cY - sy * 0.15 )
	surface.DrawLine( cX + sx, cY - sy * 0.3, cX + sx, cY - sy * 0.15 )
	surface.DrawLine( cX + sx, cY + sy * 0.3, cX + sx, cY + sy * 0.15 )
	surface.DrawLine( cX + sx, cY + sy * 0.3, cX + sx + sx * 0.3, cY )
	surface.DrawLine( cX + sx, cY - sy * 0.3, cX + sx + sx * 0.3, cY )
	surface.SetDrawColor( 240, 200, 0, 100 ) 
	
	-- ^
	if turnmode == 1 then
		surface.SetDrawColor( 240, 200, 0, 255 ) 
	end
	surface.DrawLine( cX, cY - sy * 0.4, cX + sx * 0.4, cY + sy * 0.3 )
	surface.DrawLine( cX, cY - sy * 0.4, cX - sx * 0.4, cY + sy * 0.3 )
	surface.DrawLine( cX + sx * 0.4, cY + sy * 0.3, cX - sx * 0.4, cY + sy * 0.3 )
	surface.DrawLine( cX, cY - sy * 0.26, cX + sx * 0.3, cY + sy * 0.24 )
	surface.DrawLine( cX, cY - sy * 0.26, cX - sx * 0.3, cY + sy * 0.24 )
	surface.DrawLine( cX + sx * 0.3, cY + sy * 0.24, cX - sx * 0.3, cY + sy * 0.24 )
	
	surface.SetDrawColor( 255, 255, 255, 255 ) 
end

local LockText = Material( "lfs_locked.png" )
local function PaintSeatSwitcher( ent, pSeats, SeatCount )
	if not ShowHud then return end

	local X = ScrW()
	local Y = ScrH()

	local me = LocalPlayer()
	
	if SeatCount <= 0 then return end
	
	pSeats[0] = ent:GetDriverSeat()
	
	draw.NoTexture() 
	
	local MySeat = me:GetVehicle():GetNWInt( "pPodIndex", -1 )
	
	local Passengers = {}
	for _, ply in pairs( player.GetAll() ) do
		if ply:GetSimfphys() == ent then
			local Pod = ply:GetVehicle()
			Passengers[ Pod:GetNWInt( "pPodIndex", -1 ) ] = ply:GetName()
		end
	end
	
	me.SwitcherTime = me.SwitcherTime or 0
	me.oldPassengersmf = me.oldPassengersmf or {}
	
	local Time = CurTime()
	for k, v in pairs( Passengers ) do
		if me.oldPassengersmf[k] ~= v then
			me.oldPassengersmf[k] = v
			me.SwitcherTime = Time + 2
		end
	end
	
	for k, v in pairs( me.oldPassengersmf ) do
		if not Passengers[k] then
			me.oldPassengersmf[k] = nil
			me.SwitcherTime = Time + 2
		end
	end
	
	for _, v in pairs( simfphys.pSwitchKeysInv ) do
		if input.IsKeyDown(v) then
			me.SwitcherTime = Time + 2
		end
	end
end

hook.Add( "HUDPaint", "simfphys_HUD", function()
	local ply = LocalPlayer()
	local turnmenu_isopen = false
	
	if not IsValid( ply ) or not ply:Alive() then turnmenu_wasopen = false return end

	local vehicle = ply:GetVehicle()
	local vehiclebase = ply:GetSimfphys()
	
	if not IsValid( vehicle ) or not IsValid( vehiclebase ) then 
		ply.oldPassengersmf = {}
		
		turnmenu_wasopen = false
		smHider = 0
		return
	end
	
	local pSeats = vehiclebase:GetPassengerSeats()
	local SeatCount = table.Count( pSeats )
	
	PaintSeatSwitcher( vehiclebase, pSeats, SeatCount )
	
	if not ply:IsDrivingSimfphys() then turnmenu_wasopen = false return end
	
	drawsimfphysHUD( vehiclebase, SeatCount )
	
	if vehiclebase.HasTurnSignals and input.IsKeyDown( turnmenu ) then
		turnmenu_isopen = true
		
		drawTurnMenu( vehiclebase )
	end
	
	if turnmenu_isopen ~= turnmenu_wasopen then
		turnmenu_wasopen = turnmenu_isopen
		
		if turnmenu_isopen then
			turnmode = 0
		else			
			net.Start( "simfphys_turnsignal" )
				net.WriteEntity( vehiclebase )
				net.WriteInt( turnmode, 32 )
			net.SendToServer()
			
			if turnmode == 1 or turnmode == 2 or turnmode == 3 then
				vehiclebase:EmitSound( "simulated_vehicles/sfx/turnsignal_start.ogg" )
			else
				vehiclebase:EmitSound( "simulated_vehicles/sfx/turnsignal_end.ogg" )
			end
		end
	end
end)

-- draw.arc function by bobbleheadbob
-- https://dl.dropboxusercontent.com/u/104427432/Scripts/drawarc.lua
-- https://facepunch.com/showthread.php?t=1438016&p=46536353&viewfull=1#post46536353

function surface.PrecacheArc(cx,cy,radius,thickness,startang,endang,roughness,bClockwise)
	local triarc = {}
	local deg2rad = math.pi / 180
	
	-- Correct start/end ang
	local startang,endang = startang or 0, endang or 0
	if bClockwise and (startang < endang) then
		local temp = startang
		startang = endang
		endang = temp
		temp = nil
	elseif (startang > endang) then 
		local temp = startang
		startang = endang
		endang = temp
		temp = nil
	end
	
	
	-- Define step
	local roughness = math.max(roughness or 1, 1)
	local step = roughness
	if bClockwise then
		step = math.abs(roughness) * -1
	end
	
	
	-- Create the inner circle's points.
	local inner = {}
	local r = radius - thickness
	for deg=startang, endang, step do
		local rad = deg2rad * deg
		table.insert(inner, {
			x=cx+(math.cos(rad)*r),
			y=cy+(math.sin(rad)*r)
		})
	end
	
	
	-- Create the outer circle's points.
	local outer = {}
	for deg=startang, endang, step do
		local rad = deg2rad * deg
		table.insert(outer, {
			x=cx+(math.cos(rad)*radius),
			y=cy+(math.sin(rad)*radius)
		})
	end
	
	
	-- Triangulize the points.
	for tri=1,#inner*2 do -- twice as many triangles as there are degrees.
		local p1,p2,p3
		p1 = outer[math.floor(tri/2)+1]
		p3 = inner[math.floor((tri+1)/2)+1]
		if tri%2 == 0 then --if the number is even use outer.
			p2 = outer[math.floor((tri+1)/2)]
		else
			p2 = inner[math.floor((tri+1)/2)]
		end
	
		table.insert(triarc, {p1,p2,p3})
	end
	
	-- Return a table of triangles to draw.
	return triarc
	
end

function surface.DrawArc(arc)
	for k,v in ipairs(arc) do
		surface.DrawPoly(v)
	end
end

function draw.Arc(cx,cy,radius,thickness,startang,endang,roughness,color,bClockwise)
	surface.SetDrawColor(color)
	surface.DrawArc(surface.PrecacheArc(cx,cy,radius,thickness,startang,endang,roughness,bClockwise))
end


local TipColor = Color( 0, 127, 255, 255 )
hook.Add("HUDPaint", "simfphys_vehicleditorinfo", function()
	local ply = LocalPlayer()
	
	if ply:InVehicle() then return end
	
	local wep = ply:GetActiveWeapon()
	if not IsValid( wep ) or wep:GetClass() ~= "gmod_tool" or ply:GetInfo("gmod_toolmode") ~= "simfphyseditor" then return end

	local trace = ply:GetEyeTrace()
	
	local Ent = trace.Entity
	
	if not simfphys.IsCar( Ent ) then return end
	
	local vInfo = Ent:GetVehicleInfo()
	
	if not istable( vInfo ) or not vInfo["maxspeed"] or not vInfo["horsepower"] or not vInfo["weight"] or not vInfo["torque"] then return end
	
	local SpeedMul = Hudmph and (Hudreal and 0.0568182 or 0.0568182 * 0.75) or (Hudreal and 0.09144 or 0.09144 * 0.75)
	local SpeedSuffix = Hudmph and "mph" or "km/h"
	local toSize = Hudreal and (1/0.75) or 1
	local nameSize = Hudreal and "\n\nNote: values are based on playersize" or ""
	local TopSpeed = math.Round( vInfo["maxspeed"] * SpeedMul )
	local HP = math.Round( vInfo["horsepower"] * toSize )
	local Weight = math.Round( vInfo["weight"] )
	local PowerToWeight = math.Round(Weight / HP,1)
	local PeakTorque = math.Round( vInfo["torque"] * toSize )
	
	local text = "Peak Power: "..HP.." HP".."\nPeak Torque: "..PeakTorque.." Nm\nTop Speed: "..tostring( TopSpeed )..SpeedSuffix.." (theoretical max)".."\nWeight: "..Weight.." kg ("..PowerToWeight.." kg / HP)"..nameSize

	local pos = Ent:LocalToWorld( Ent:OBBCenter() ):ToScreen()
	
	local black = Color( 255, 255, 255, 255 )
	local tipcol = Color( TipColor.r, TipColor.g, TipColor.b, 255 )
	
	local x = 0
	local y = 0
	local padding = 10
	local offset = 50
	
	surface.SetFont( "simfphysworldtip" )
	local w, h = surface.GetTextSize( text )
	
	x = pos.x - w 
	y = pos.y - h 
	
	x = x - offset
	y = y - offset

	draw.RoundedBox( 8, x-padding-2, y-padding-2, w+padding*2+4, h+padding*2+4, black )
	
	
	local verts = {}
	verts[1] = { x=x+w/1.5-2, y=y+h+2 }
	verts[2] = { x=x+w+2, y=y+h/2-1 }
	verts[3] = { x=pos.x-offset/2+2, y=pos.y-offset/2+2 }
	
	draw.NoTexture()
	surface.SetDrawColor( 255, 255, 255, tipcol.a )
	surface.DrawPoly( verts )
	
	
	draw.RoundedBox( 8, x-padding, y-padding, w+padding*2, h+padding*2, tipcol )
	
	local verts = {}
	verts[1] = { x=x+w/1.5, y=y+h }
	verts[2] = { x=x+w, y=y+h/2 }
	verts[3] = { x=pos.x-offset/2, y=pos.y-offset/2 }
	
	draw.NoTexture()
	surface.SetDrawColor( tipcol.r, tipcol.g, tipcol.b, tipcol.a )
	surface.DrawPoly( verts )
	
	
	draw.DrawText( text, "simfphysworldtip", x + w/2, y, black, TEXT_ALIGN_CENTER )
end)