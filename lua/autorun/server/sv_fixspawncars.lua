hook.Add("OnEntityCreated", "LiazFix", function(ent)
    if ent:IsVehicle() and ent:GetClass() == "gmod_sent_vehicle_fphysics_base" then
        timer.Simple(0.01, function()
            if IsValid(ent) and ent.VehicleName == "sim_fphys_gazelle_cityline" then
                ent:SetAngles(ent:GetAngles()+Angle(0,270,0))
                ent:SetSkin(1)
            end
            if IsValid(ent) and ent.VehicleName == "sim_fphys_skoda_octavia_politia" then
                ent:SetAngles(ent:GetAngles()+Angle(0,270,0))
                ent:SetSkin(2)
            end
        end)
    end
end)