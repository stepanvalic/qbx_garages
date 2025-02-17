local VEHICLES = exports.qbx_core:GetVehiclesByName()
local Markers = false
local HouseMarkers = false
local InputIn = false
local InputOut = false
local currentGarage = nil
local currentGarageIndex = nil
local garageZones = {}
local lasthouse = nil
local blipsZonesLoaded = false


--Menus
local function MenuGarage(type, garage, indexgarage)
    local header
    if type == "house" then
        header = Lang:t("menu.header." .. type .. "_car", { value = garage.label })
    else
        header = Lang:t("menu.header." .. type .. "_" .. garage.vehicle, { value = garage.label })
    end
    lib.registerContext({
        id = 'qb_garage_menu',
        title = header,
        options = {
            {
                title = Lang:t("menu.header.vehicles"),
                description = Lang:t("menu.text.vehicles"),
                event = "qb-garages:client:VehicleList",
                args = {
                    type = type,
                    garage = garage,
                    index = indexgarage,
                }
            }
        },
    })
    lib.showContext('qb_garage_menu')
end

local function DestroyZone(type, index)
    if garageZones[type .. "_" .. index] then
        garageZones[type .. "_" .. index].zone:remove()
    end
end

local function CreateZone(type, garage, index)
    local size
    local coords
    local heading

    if type == 'in' then
        size = vec3(4, 4, 4)
        coords = vector3(garage.putVehicle.x, garage.putVehicle.y, garage.putVehicle.z)
        heading = garage.spawnPoint.w
    elseif type == 'out' then
        size = vec3(2, 2, 4)
        coords = vector3(garage.takeVehicle.x, garage.takeVehicle.y, garage.takeVehicle.z)
        heading = garage.spawnPoint.w
    elseif type == 'marker' then
        size = vec3(60, 60, 4)
        coords = vector3(garage.takeVehicle.x, garage.takeVehicle.y, garage.takeVehicle.z)
        heading = garage.spawnPoint.w
    elseif type == 'hmarker' then
        size = vec3(20, 20, 4)
        coords = vector3(garage.takeVehicle.x, garage.takeVehicle.y, garage.takeVehicle.z)
        heading = 0
    elseif type == 'house' then
        size = vec3(2, 2, 4)
        coords = vector3(garage.takeVehicle.x, garage.takeVehicle.y, garage.takeVehicle.z)
        heading = 0
    end

    garageZones[type .. "_" .. index] = {}
    garageZones[type .. "_" .. index].zone = lib.zones.box({
        coords = coords,
        size = size,
        rotation = heading,
        debug = false,
        onEnter = function()
            local text
            if type == "in" then
                if garage.type == "house" then
                    text = Lang:t("info.park_e")
                else
                    text = Lang:t("info.park_e") .. "  \n" .. garage.label
                end
                lib.showTextUI(text, {position = 'left-center'})
                InputIn = true
            elseif type == "out" then
                if garage.type == "house" then
                    text = Lang:t("info.car_e")
                else
                    text = Lang:t("info." .. garage.vehicle .. "_e") .. "  \n" .. garage.label
                end

                lib.showTextUI(text, {position = 'left-center'})
                InputOut = true
            elseif type == "marker" then
                currentGarage = garage
                currentGarageIndex = index
                CreateZone("out", garage, index)
                if garage.type ~= "depot" then
                    CreateZone("in", garage, index)
                    Markers = true
                else
                    HouseMarkers = true
                end
            elseif type == "hmarker" then
                currentGarage = garage
                currentGarage.type = "house"
                currentGarageIndex = index
                CreateZone("house", garage, index)
                HouseMarkers = true
            elseif type == "house" then
                if cache.vehicle then
                    lib.showTextUI(Lang:t("info.park_e"), {position = 'left-center'})
                    InputIn = true
                else
                    lib.showTextUI(Lang:t("info.car_e"), {position = 'left-center'})
                    InputOut = true
                end
            end
        end,
        onExit = function()
            if type == "marker" then
                if currentGarage == garage then
                    if garage.type ~= "depot" then
                        Markers = false
                    else
                        HouseMarkers = false
                    end
                    DestroyZone("in", index)
                    DestroyZone("out", index)
                    currentGarage = nil
                    currentGarageIndex = nil
                end
            elseif type == "hmarker" then
                HouseMarkers = false
                DestroyZone("house", index)
            elseif type == "house" then
                lib.hideTextUI()
                InputIn = false
                InputOut = false
            elseif type == "in" then
                lib.hideTextUI()
                InputIn = false
            elseif type == "out" then
                lib.hideTextUI()
                InputOut = false
            end
        end,
    })
end

local function doCarDamage(currentVehicle, veh)
    local engine = veh.engine + 0.0
    local body = veh.body + 0.0
    local data = json.decode(veh.mods)

    if VisuallyDamageCars then
        for k, v in pairs(data.doors) do
            if v then
                SetVehicleDoorBroken(currentVehicle, k, true)
            end
        end
        for k, v in pairs(data.tyres) do
            if v then
                local random = math.random(1, 1000)
                SetVehicleTyreBurst(currentVehicle, k, true, random)
            end
        end
        for k, v in pairs(data.windows) do
            if not v then
                SmashVehicleWindow(currentVehicle, k)
            end
        end
    end
    SetVehicleEngineHealth(currentVehicle, engine)
    SetVehicleBodyHealth(currentVehicle, body)
end

local function CheckPlayers(vehicle, garage)
    for i = -1, 5, 1 do
        local seat = GetPedInVehicleSeat(vehicle, i)
        if seat then
            TaskLeaveVehicle(seat, vehicle, 0)
            if garage then
                SetEntityCoords(seat, garage.takeVehicle.x, garage.takeVehicle.y, garage.takeVehicle.z, false, false, false, true)
            end
        end
    end
    SetVehicleDoorsLocked(vehicle, 2)
    Wait(1500)
    DeleteVehicle(vehicle)
end

-- Functions
RegisterNetEvent("qb-garages:client:VehicleList", function(data)
    local type = data.type
    local garage = data.garage
    local indexgarage = data.index
    local header

    if type == "house" then
        header = Lang:t("menu.header." .. type .. "_car", { value = garage.label })
    else
        header = Lang:t("menu.header." .. type .. "_" .. garage.vehicle, { value = garage.label })
    end

    local result = lib.callback.await('qb-garage:server:GetGarageVehicles', false, indexgarage, type, garage.vehicle)
    if not result then
        exports.qbx_core:Notify(Lang:t("error.no_vehicles"), "error", 5000)
        return
    end

    local registeredMenu = {
        id = 'qb_garage_vehicle_list',
        title = header,
        options = {}
    }

    for _, v in pairs(result) do
        local enginePercent = math.round(v.engine / 10)
        local bodyPercent = math.round(v.body / 10)
        local currentFuel = v.fuel
        local vname = VEHICLES[v.vehicle].name

        if v.state == 0 then
            v.state = Lang:t("status.out")
        elseif v.state == 1 then
            v.state = Lang:t("status.garaged")
        elseif v.state == 2 then
            v.state = Lang:t("status.impound")
        end
        if type == "depot" then
            registeredMenu.options[#registeredMenu.options + 1] = {
                title = Lang:t('menu.header.depot', { value = vname, value2 = v.depotprice }),
                description = '',
                event = 'qb-garages:client:TakeOutDepot',
                args = {
                    vehicle = v,
                    type = type,
                    garage = garage,
                    index = indexgarage,
                    },
                metadata = {
                    {label = 'Plate', value = v.plate .. ' '},
                    {label = 'Engine', value = enginePercent .. ' %'},
                    {label = 'Fuel', value = currentFuel .. ' %'},
                    {label = 'Body', value = bodyPercent .. ' %'},
                },
            }


        else
            registeredMenu.options[#registeredMenu.options + 1] = {
                title = Lang:t('menu.header.garage', { value = vname, value2 = v.plate }),
                description = '',
                event = 'qb-garages:client:takeOutGarage',
                args = {
                    vehicle = v,
                    type = type,
                    garage = garage,
                    index = indexgarage,
                    },
                metadata = {
                    {label = 'State', value = v.state .. ' '},
                    {label = 'Plate', value = v.plate .. ' '},
                    {label = 'Engine', value = enginePercent .. ' %'},
                    {label = 'Fuel', value = currentFuel .. ' %'},
                    {label = 'Body', value = bodyPercent .. ' %'},
                },
            }

        end
    end
    lib.registerContext(registeredMenu)
    lib.showContext('qb_garage_vehicle_list')
end)

RegisterNetEvent('qb-garages:client:takeOutGarage', function(data)
    local type = data.type
    local vehicle = data.vehicle
    local garage = data.garage
    local index = data.index
    local spawn = lib.callback.await('qb-garage:server:IsSpawnOk', false, vehicle.plate, type)
    if not spawn then
        exports.qbx_core:Notify(Lang:t("error.not_impound"), "error", 5000)
        return
    end

    local netId, properties = lib.callback.await('qb-garage:server:spawnvehicle', false, vehicle, type == "house" and garage.takeVehicle or garage.spawnPoint, true)
    local timeout = 100
    while not NetworkDoesEntityExistWithNetworkId(netId) and timeout > 0 do
        Wait(10)
        timeout -= 1
    end
    local veh = NetToVeh(netId)
    if veh == 0 then
        exports.qbx_core:Notify('Something went wrong spawning the vehicle', 'error')
        return
    end
    SetVehicleFuelLevel(veh, vehicle.fuel)
    doCarDamage(veh, vehicle)
    TriggerServerEvent('qb-garage:server:updateVehicleState', 0, vehicle.plate, index)
    TriggerEvent("vehiclekeys:client:SetOwner", GetPlate(veh))
    SetVehicleEngineOn(veh, true, true, false)
    Wait(500)
    lib.setVehicleProperties(veh, properties)

    if type ~= "house" then return end
    lib.showTextUI(Lang:t("info.park_e"), {position = 'left-center'})
    InputOut = false
    InputIn = true
end)

local function enterVehicle(veh, indexgarage, type, garage)
    local plate = GetPlate(veh)
    if GetVehicleNumberOfPassengers(veh) ~= 1 then
        local owned = lib.callback.await('qb-garage:server:checkOwnership', false, plate, type, indexgarage, QBX.PlayerData.gang.name)
        if not owned then
            exports.qbx_core:Notify(Lang:t("error.not_owned"), "error", 5000)
            return
        end

        local bodyDamage = math.ceil(GetVehicleBodyHealth(veh))
        local engineDamage = math.ceil(GetVehicleEngineHealth(veh))
        local totalFuel = GetVehicleFuelLevel(veh)
        TriggerServerEvent("qb-vehicletuning:server:SaveVehicleProps", lib.getVehicleProperties(veh))
        TriggerServerEvent('qb-garage:server:updateVehicle', 1, totalFuel, engineDamage, bodyDamage, plate, indexgarage, type, QBX.PlayerData.gang.name)
        CheckPlayers(veh, garage)
        if type == "house" then
            lib.showTextUI(Lang:t("info.car_e"), {position = 'left-center'})
            InputOut = true
            InputIn = false
        end

        if plate then
            TriggerServerEvent('qb-garages:server:UpdateOutsideVehicle', plate, nil)
        end
        exports.qbx_core:Notify(Lang:t("success.vehicle_parked"), "primary", 4500)
    else
        exports.qbx_core:Notify(Lang:t("error.vehicle_occupied"), "error", 3500)
    end
end

local function CreateBlipsZones()
    if blipsZonesLoaded then return end

    for index, garage in pairs(Garages) do
        if garage.showBlip then
            local Garage = AddBlipForCoord(garage.takeVehicle.x, garage.takeVehicle.y, garage.takeVehicle.z)
            SetBlipSprite(Garage, garage.blipNumber)
            SetBlipDisplay(Garage, 4)
            SetBlipScale(Garage, 0.60)
            SetBlipAsShortRange(Garage, true)
            SetBlipColour(Garage, 3)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(garage.blipName)
            EndTextCommandSetBlipName(Garage)
        end
        if garage.type == "job" then
            if QBX.PlayerData.job.name == garage.job then
                CreateZone("marker", garage, index)
            end
        elseif garage.type == "gang" then
            if QBX.PlayerData.gang.name == garage.job then
                CreateZone("marker", garage, index)
            end
        else
            CreateZone("marker", garage, index)
        end
    end
    blipsZonesLoaded = true
end

RegisterNetEvent('qb-garages:client:setHouseGarage', function(house, hasKey)
    if HouseGarages[house] then
        if lasthouse ~= house then
            if lasthouse then
                DestroyZone("hmarker", lasthouse)
            end
            if hasKey and HouseGarages[house].takeVehicle.x then
                CreateZone("hmarker", HouseGarages[house], house)
                lasthouse = house
            end
        end
    end
end)

RegisterNetEvent('qb-garages:client:houseGarageConfig', function(garageConfig)
    HouseGarages = garageConfig
end)

RegisterNetEvent('qb-garages:client:addHouseGarage', function(house, garageInfo)
    HouseGarages[house] = garageInfo
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    CreateBlipsZones()
end)

AddEventHandler("onResourceStart", function(res)
    if res ~= GetCurrentResourceName() then return end
    CreateBlipsZones()
end)

RegisterNetEvent('qb-garages:client:TakeOutDepot', function(data)
    local vehicle = data.vehicle

    if vehicle.depotprice ~= 0 then
        TriggerServerEvent("qb-garage:server:PayDepotPrice", data)
    else
        TriggerEvent("qb-garages:client:takeOutGarage", data)
    end
end)

-- Threads
CreateThread(function()
    local sleep
    while true do
        sleep = 2000
        if Markers then
            DrawMarker(2, currentGarage.putVehicle.x, currentGarage.putVehicle.y, currentGarage.putVehicle.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 255, 255, 255, 255, false, false, 0, true, false, false, false)
            DrawMarker(2, currentGarage.takeVehicle.x, currentGarage.takeVehicle.y, currentGarage.takeVehicle.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 200, 0, 0, 222, false, false, 0, true, false, false, false)
            sleep = 0
        elseif HouseMarkers then
            DrawMarker(2, currentGarage.takeVehicle.x, currentGarage.takeVehicle.y, currentGarage.takeVehicle.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 200, 0, 0, 222, false, false, 0, true, false, false, false)
            sleep = 0
        end
        if InputIn or InputOut then
            if IsControlJustReleased(0, 38) then
                if InputIn then
                    local curVeh = cache.vehicle
                    local vehClass = GetVehicleClass(curVeh)
                    --Check vehicle type for garage
                    if currentGarage.vehicle == "car" or not currentGarage.vehicle then
                        if vehClass ~= 14 and vehClass ~= 15 and vehClass ~= 16 then
                            if currentGarage.type == "job" then
                                if QBX.PlayerData.job.name == currentGarage.job then
                                    enterVehicle(curVeh, currentGarageIndex, currentGarage.type)
                                end
                            elseif currentGarage.type == "gang" then
                                if QBX.PlayerData.gang.name == currentGarage.job then
                                    enterVehicle(curVeh, currentGarageIndex, currentGarage.type)
                                end
                            else
                                enterVehicle(curVeh, currentGarageIndex, currentGarage.type)
                            end
                        else
                            exports.qbx_core:Notify(Lang:t("error.not_correct_type"), "error", 3500)
                        end
                    elseif currentGarage.vehicle == "air" then
                        if vehClass == 15 or vehClass == 16 then
                            if currentGarage.type == "job" then
                                if QBX.PlayerData.job.name == currentGarage.job then
                                    enterVehicle(curVeh, currentGarageIndex, currentGarage.type)
                                end
                            elseif currentGarage.type == "gang" then
                                if QBX.PlayerData.gang.name == currentGarage.job then
                                    enterVehicle(curVeh, currentGarageIndex, currentGarage.type)
                                end
                            else
                                enterVehicle(curVeh, currentGarageIndex, currentGarage.type)
                            end
                        else
                            exports.qbx_core:Notify(Lang:t("error.not_correct_type"), "error", 3500)
                        end
                    elseif currentGarage.vehicle == "sea" then
                        if vehClass == 14 then
                            if currentGarage.type == "job" then
                                if QBX.PlayerData.job.name == currentGarage.job then
                                    enterVehicle(curVeh, currentGarageIndex, currentGarage.type, currentGarage)
                                end
                            elseif currentGarage.type == "gang" then
                                if QBX.PlayerData.gang.name == currentGarage.job then
                                    enterVehicle(curVeh, currentGarageIndex, currentGarage.type, currentGarage)
                                end
                            else
                                enterVehicle(curVeh, currentGarageIndex, currentGarage.type, currentGarage)
                            end
                        else
                            exports.qbx_core:Notify(Lang:t("error.not_correct_type"), "error", 3500)
                        end
                    end
                elseif InputOut then
                    if currentGarage.type == "job" then
                        if QBX.PlayerData.job.name == currentGarage.job then
                            MenuGarage(currentGarage.type, currentGarage, currentGarageIndex)
                        end
                    elseif currentGarage.type == "gang" then
                        if QBX.PlayerData.gang.name == currentGarage.job then
                            MenuGarage(currentGarage.type, currentGarage, currentGarageIndex)
                        end
                    else
                        MenuGarage(currentGarage.type, currentGarage, currentGarageIndex)
                    end
                end
            end
            sleep = 0
        end
        Wait(sleep)
    end
end)
