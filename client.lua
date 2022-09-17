local Peds = {}
QBCore = exports['qb-core']:GetCoreObject()

local animations = {}
for i,v in pairs(Config.Animations) do
    table.insert(animations, {
        text = v.value,
        value = tostring(i)
    })
end

RegisterCommand("createped", function(source, commandArgs)
    QBCore.Functions.TriggerCallback("qb-admin:server:getrank", function(result)
        if result then
            local coords = GetEntityCoords(PlayerPedId())

            if not commandArgs or not commandArgs[1] then
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
                            text = "Vehicle Seat Number",
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
                                }
                            },
                            isRequired = false
                        }
                    }
                })
            
                if inputArgs ~= nil then
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

                    if inputArgs.anim and Config.Animations[tonumber(inputArgs.anim)] and Config.Animations[tonumber(inputArgs.anim)].scenario then
                        TaskStartScenarioInPlace(ped, Config.Animations[tonumber(inputArgs.anim)].scenario, 0, 1)
                    end

                    if inputArgs.invincible then
                        SetBlockingOfNonTemporaryEvents(ped, true)
                        SetPedDiesWhenInjured(ped, false)
                        SetPedCanPlayAmbientAnims(ped, true)
                        SetPedCanRagdollFromPlayerImpact(ped, false)
                        SetEntityInvincible(ped, true)
                    end

                    if inputArgs.freezepos then
                        FreezeEntityPosition(ped, true)
                    end

                    if IsPedInAnyVehicle(PlayerPedId(), false) and inputArgs.vehseat and inputArgs.vehseat ~= "" then
                        SetPedIntoVehicle(ped, GetVehiclePedIsIn(PlayerPedId()), tonumber(inputArgs.vehseat))
                    end

                    table.insert(Peds, ped)
                    QBCore.Functions.Notify("Created ped, the ped index is: " .. tostring(#Peds))
                end
            else
                local hash = GetHashKey(tostring(commandArgs[1]))

                RequestModel(hash)
                while not HasModelLoaded(hash) do Wait(100) end

                local ped = CreatePed(4, hash, coords.x, coords.y, coords.z - 1, 0.0, true, true)

                SetEntityHeading(ped, GetEntityHeading(PlayerPedId()))

                if IsPedInAnyVehicle(PlayerPedId(), false) and commandArgs[2] then
                    SetPedIntoVehicle(ped, GetVehiclePedIsIn(PlayerPedId()), tonumber(commandArgs[2]))
                end

                local scenario = nil

                for i,v in pairs (Config.Animations) do
                    if commandArgs[3] == v.value then
                        scenario = v.scenario
                    end
                end

                if scenario then
                    TaskStartScenarioInPlace(ped, scenario, 0, 1)
                end

                if commandArgs[4] == "true" then
                    SetBlockingOfNonTemporaryEvents(ped, true)
                    SetPedDiesWhenInjured(ped, false)
                    SetPedCanPlayAmbientAnims(ped, true)
                    SetPedCanRagdollFromPlayerImpact(ped, false)
                    SetEntityInvincible(ped, true)
                end

                if commandArgs[5] == "true" then
                    FreezeEntityPosition(ped, true)
                end

                table.insert(Peds, ped)
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
    end
end)
