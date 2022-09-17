local Peds, Vehs, FollowPlayerPeds = {}, {}, {}
QBCore = exports['qb-core']:GetCoreObject()

local animations = {}
for i,v in pairs(Config.Animations) do
    table.insert(animations, {
        text = v.value,
        value = tostring(i)
    })
end

RegisterCommand("createped", function()
    QBCore.Functions.TriggerCallback("qb-admin:server:getrank", function(result)
        if result then
            local coords = GetEntityCoords(PlayerPedId())

            local inputArgs = exports['qb-input']:ShowInput({
                header = "Create a ped",
                submitText = "Spawn",
                inputs = {
                    {
                        text = "Ped model",
                        name = "model",
                        type = "text",
                        isRequired = true
                    },
                    {
                        text = "Weapon name",
                        name = "weapon",
                        type = "text",
                        isRequired = false
                    },
                    {
                        text = "Vehicle model (not needed)",
                        name = "vehmodel",
                        type = "text",
                        isRequired = false
                    },
                    {
                        text = "Vehicle Seat Number (not needed)",
                        name = "vehseat",
                        type = "text",
                        isRequired = false
                    },
                    {
                        text = "Animation",
                        name = "anim",
                        type = "select",
                        options = animations,
                        isRequired = false
                    },
                    {
                        text = "Extra Attributes",
                        name = "attributes",
                        type = "checkbox",
                        options = {
                            {
                                text = "Freeze Position",
                                value = "freezepos"
                            },
                            {
                                text = "Invincible",
                                value = "invincible"
                            },
                            {
                                text = "Follow Player",
                                value = "followplr"
                            }
                        },
                        isRequired = false
                    }
                }
            })
        
            if inputArgs ~= nil and inputArgs.model then
                local hash = GetHashKey(tostring(inputArgs.model))

                local loadIdx = 0
                RequestModel(hash)
                while not HasModelLoaded(hash) do 
                    Wait(100) 
                    loadIdx = loadIdx + 1
                    if loadIdx > 20 then
                        QBCore.Functions.Notify("Couldn't load / find the ped model", "error")
                        return
                    end
                end

                local ped = CreatePed(4, hash, coords.x, coords.y, coords.z - 1, 0.0, true, true)

                SetEntityHeading(ped, GetEntityHeading(PlayerPedId()))

                if inputArgs.anim and Config.Animations[tonumber(inputArgs.anim)] and Config.Animations[tonumber(inputArgs.anim)].scenario  and (inputArgs.vehmodel == nil or inputArgs.vehmodel == "")then
                    TaskStartScenarioInPlace(ped, Config.Animations[tonumber(inputArgs.anim)].scenario, 0, 1)
                end

                if inputArgs.invincible == "true" then
                    SetBlockingOfNonTemporaryEvents(ped, true)
                    SetPedDiesWhenInjured(ped, false)
                    SetPedCanPlayAmbientAnims(ped, true)
                    SetPedCanRagdollFromPlayerImpact(ped, false)
                    SetEntityInvincible(ped, true)
                end

                if inputArgs.freezepos == "true" and (inputArgs.vehmodel == nil or inputArgs.vehmodel == "") then
                    FreezeEntityPosition(ped, true)
                end

                if inputArgs.followplr == "true" then
                    if inputArgs.vehmodel == nil or inputArgs.vehmodel == "" then
                        SetPedAsGroupMember(ped, GetPedGroupIndex(PlayerPedId()))
                    else
                        SetDriveTaskDrivingStyle(ped, 786468)
                        SetDriverAbility(ped, 1.0)
                        table.insert(FollowPlayerPeds, ped)
                    end
                end

                if (inputArgs.vehmodel == nil or inputArgs.vehmodel == "") and IsPedInAnyVehicle(PlayerPedId(), false) and inputArgs.vehseat and inputArgs.vehseat ~= "" then
                    SetPedIntoVehicle(ped, GetVehiclePedIsIn(PlayerPedId()), tonumber(inputArgs.vehseat))
                end

                if inputArgs.weapon and inputArgs.weapon ~= "" then
                    local hash = GetHashKey(string.upper(tostring(inputArgs.weapon)))
                    GiveWeaponToPed(ped, hash, 9999, 0,0)
                    SetCurrentPedWeapon(ped, hash, true)
                end

                table.insert(Peds, ped)

                if inputArgs.vehmodel and inputArgs.vehmodel ~= "" then
                    QBCore.Functions.SpawnVehicle(inputArgs.vehmodel, function(veh)
                        if inputArgs.vehseat == "" or inputArgs.vehseat == nil then inputArgs.vehseat = "-1" end
                        SetPedIntoVehicle(ped, veh, tonumber(inputArgs.vehseat))
                        SetVehicleEngineOn(veh, true, false, true)
                        Vehs[#Peds] = veh
                    end, coords, true)
                end

                QBCore.Functions.Notify("Created ped, the ped index is: " .. tostring(#Peds))
            end
        else
            QBCore.Functions.Notify("You dont have access to this", "error")
        end
    end)
end)
TriggerEvent('chat:addSuggestion', '/createped', "Creates a ped", {})

RegisterCommand("removeped", function(source, args)
    QBCore.Functions.TriggerCallback("qb-admin:server:getrank", function(result)
        if Peds[tonumber(args[1])] then
            DeletePed(Peds[tonumber(args[1])])
            Peds[tonumber(args[1])] = nil
        end
        if Vehs[tonumber(args[1])] then
            DeleteEntity(Vehs[tonumber(args[1])])
            Vehs[tonumber(args[1])] = nil
        end
	end)
end)	
TriggerEvent('chat:addSuggestion', '/removeped', "Removes a created ped", {
    {
        name = "index",
        help = "The ped index"
    }
})

RegisterCommand("clearpeds", function(source)
    QBCore.Functions.TriggerCallback("qb-admin:server:getrank", function(result)
        for i,v in pairs(Peds) do
            DeletePed(v)
        end
        for i,v in pairs(Vehs) do
            DeleteEntity(v)
        end
        Vehs = {}
        Peds = {}
	end)
end)	
TriggerEvent('chat:addSuggestion', '/clearpeds', "Removes all the created ped", {})

RegisterNetEvent("onResourceStop")
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for i, v in pairs(Peds) do 
            DeletePed(v)
        end
        for i,v in pairs(Vehs) do
            DeleteEntity(v)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        if #FollowPlayerPeds ~= 0 then
            local PlayerPos = GetEntityCoords(PlayerPedId())
            for i,ped in pairs(FollowPlayerPeds) do
                local veh = GetVehiclePedIsIn(ped, false)
                TaskVehicleDriveToCoord(ped, veh, PlayerPos.x,PlayerPos.y,PlayerPos.z, 20.0, 6.0, GetHashKey(veh), 1,0,10.0)
            end
        end
        Citizen.Wait(1000)
    end
end)