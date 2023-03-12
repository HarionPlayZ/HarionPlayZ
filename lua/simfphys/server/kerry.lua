local atts = {

    huynya1 = {
        type = 'huynya1',
        ent = "ubs_button",
        cars = {
            sim_fphys_couch = { Vector(26.6, 0, 89.4), Angle(0, -90, 0), 1 },
        },
    },
}
function simfphys.AddAttachment(ent, att)

    local attData = atts[att].cars[ent.VehicleName]
    local attEnt = ents.Create(atts[att].ent)
    if not attData then return end
    attEnt:SetParent(ent)
    attEnt:SetLocalPos(attData[1] or Vector())
    attEnt:SetLocalAngles(attData[2] or Angle())
    attEnt:SetModelScale(attData[3] or 1)
    attEnt:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    attEnt:Spawn()
    attEnt.attClass = att
    ent:DeleteOnRemove(attEnt)
	

    return true

end

concommand.Add( "engine_vehicle", function(ply)  
    if ply:IsDrivingSimfphys() and ply:Alive() then
        local veh = ply:GetVehicle():GetParent()
        if not veh:EngineActive() then
            veh:StartEngine()
        else
            veh:StopEngine()
        end
    end
end)