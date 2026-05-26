local QBCore = nil
if Config.Framework == "qb" then
    QBCore = exports['qb-core']:GetCoreObject()
end

local stageStrippers = {
    { model = "csb_stripper_01", coords = vector4(103.9, -1294.28, 29.26, 284.21), animDict = "mini@strip_club@pole_dance@pole_dance1", anim = "pd_dance_01" },
    { model = "csb_stripper_02", coords = vector4(102.3, -1290.79, 29.46, 149.76), animDict = "mini@strip_club@pole_dance@pole_dance2", anim = "pd_dance_02" },
    { model = "s_f_y_stripper_01", coords = vector4(112.26, -1286.9, 28.46, 245.2), animDict = "mini@strip_club@pole_dance@pole_dance3", anim = "pd_dance_03" }
}

local roamingStrippers = {
    { model = "s_f_y_stripper_02", coords = vector4(117.35, -1282.08, 28.27, 180.0) },
    { model = "s_f_y_stripperlite", coords = vector4(111.18, -1290.74, 28.26, 270.0) },
    { model = "s_f_y_stripper_01", coords = vector4(110.05, -1285.40, 28.26, 100.0) },
}

local spawnedRoamers = {}
local isDancing = false

-- Notification Wrapper
local function Notify(msg, type)
    if Config.Framework == "qbox" then
        exports.qbx_core:Notify(msg, type)
    else
        QBCore.Functions.Notify(msg, type)
    end
end

-- Target Interaction Helper
local function AddTargetToPed(ped, options)
    if Config.Target == "ox_target" then
        local oxOptions = {}
        for _, opt in ipairs(options) do
            table.insert(oxOptions, {
                name = opt.label,
                icon = opt.icon,
                label = opt.label,
                onSelect = function()
                    opt.action()
                end
            })
        end
        exports.ox_target:addLocalEntity(ped, oxOptions)
    else
        exports['qb-target']:AddTargetEntity(ped, {
            options = options,
            distance = 2.5
        })
    end
end

-- Throw Money logic separated for readability
local function ThrowMoneyAction(ped)
    local player = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local playerCoords = GetEntityCoords(player)

    -- Spawn cash prop
    local prop = "prop_cash_pile_01"
    RequestModel(GetHashKey(prop))
    while not HasModelLoaded(GetHashKey(prop)) do Wait(10) end
    local propObj = CreateObject(GetHashKey(prop), playerCoords.x, playerCoords.y, playerCoords.z + 0.8, true, true, true)
    AttachEntityToEntity(propObj, player, GetPedBoneIndex(player, 60309), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

    -- Prop flies in an arc
    local throwTime = 500
    local start = GetGameTimer()
    local startCoords = playerCoords + vector3(0.0, 0.0, 0.8)
    local endCoords = pedCoords + vector3(0.0, 0.0, 1.0)
    local height = Config.ThrowMoneyHeight

    Citizen.CreateThread(function()
        while GetGameTimer() - start < throwTime do
            local t = (GetGameTimer() - start) / throwTime
            local x = startCoords.x + (endCoords.x - startCoords.x) * t
            local y = startCoords.y + (endCoords.y - startCoords.y) * t
            local z = startCoords.z + (endCoords.z - startCoords.z) * t + math.sin(t * math.pi) * height
            SetEntityCoords(propObj, x, y, z, true, true, true, true)
            Wait(0)
        end

        DetachEntity(propObj, true, true)
        PlaceObjectOnGroundProperly(propObj)

        TriggerServerEvent("InteractSound_SV:PlayOnSource", "cash_throw", 0.5)

        Citizen.SetTimeout(2000, function()
            DeleteObject(propObj)
        end)
    end)

    -- Player throw animation
    RequestAnimDict("mp_common")
    while not HasAnimDictLoaded("mp_common") do Wait(10) end
    TaskPlayAnim(player, "mp_common", "givetake1_a", 8.0, -8.0, 1000, 1, 0, false, false, false)

    -- Stripper receive animation
    RequestAnimDict("anim@mp_player_intuppersalute")
    while not HasAnimDictLoaded("anim@mp_player_intuppersalute") do Wait(10) end
    TaskPlayAnim(ped, "anim@mp_player_intuppersalute", "idle_a", 8.0, -8.0, 1000, 1, 0, false, false, false)

    -- Stripper reaction animation
    Citizen.SetTimeout(500, function()
        RequestAnimDict("anim@mp_player_intupperwave")
        while not HasAnimDictLoaded("anim@mp_player_intupperwave") do Wait(10) end
        TaskPlayAnim(ped, "anim@mp_player_intupperwave", "idle_a", 8.0, -8.0, 1200, 1, 0, false, false, false)
    end)

    Notify("You threw money!", "success")
end

-- Spawn stage strippers
local function spawnStageStrippers()
    for _, s in pairs(stageStrippers) do
        RequestModel(GetHashKey(s.model))
        while not HasModelLoaded(GetHashKey(s.model)) do Wait(10) end

        local ped = CreatePed(4, GetHashKey(s.model), s.coords.x, s.coords.y, s.coords.z - 1.0, s.coords.w, false, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)

        RequestAnimDict(s.animDict)
        while not HasAnimDictLoaded(s.animDict) do Wait(10) end
        TaskPlayAnim(ped, s.animDict, s.anim, 8.0, -8.0, -1, 1, 0, false, false, false)

        AddTargetToPed(ped, {
            {
                icon = "fas fa-money-bill-wave",
                label = "Throw Money",
                action = function()
                    ThrowMoneyAction(ped)
                    -- Return to dance loop smoothly
                    Citizen.SetTimeout(1900, function()
                        RequestAnimDict(s.animDict)
                        while not HasAnimDictLoaded(s.animDict) do Wait(10) end
                        TaskPlayAnim(ped, s.animDict, s.anim, 8.0, -8.0, -1, 1, 1, false, false, false)
                    end)
                end
            }
        })
    end
end

-- Spawn roaming strippers
local function spawnRoamingStrippers()
    for _, s in pairs(roamingStrippers) do
        RequestModel(GetHashKey(s.model))
        while not HasModelLoaded(GetHashKey(s.model)) do Wait(10) end

        local ped = CreatePed(4, GetHashKey(s.model), s.coords.x, s.coords.y, s.coords.z - 1.0, s.coords.w, false, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        TaskWanderStandard(ped, 10.0, 10)
        table.insert(spawnedRoamers, ped)

        AddTargetToPed(ped, {
            {
                icon = "fas fa-dollar-sign",
                label = "TIP ($"..Config.DancePrice..")",
                action = function()
                    TriggerServerEvent("vu_strippers:payForDance", PedToNet(ped))
                end
            }
        })
    end
end

-- Start lap dance
RegisterNetEvent("vu_strippers:startDance", function(ped)
    if isDancing then return end
    isDancing = true

    local player = PlayerPedId()
    local coords = GetEntityCoords(player)
    local forward = GetEntityForwardVector(player)
    local spot = coords + forward * 0.5

    TaskGoStraightToCoord(ped, spot.x, spot.y, spot.z, 1.0, -1, GetEntityHeading(player), 0.0)
    Wait(2000)

    ClearPedTasks(ped)

    RequestAnimDict("mini@strip_club@lap_dance@ld_girl_a_song_a_p1")
    while not HasAnimDictLoaded("mini@strip_club@lap_dance@ld_girl_a_song_a_p1") do Wait(10) end
    TaskPlayAnim(ped, "mini@strip_club@lap_dance@ld_girl_a_song_a_p1", "ld_girl_a_p1_f", 8.0, -8.0, 20000, 1, 1, false, false, false)
    TaskPlayAnim(player, "mini@strip_club@lap_dance@ld_girl_a_song_a_p1", "ld_girl_a_p1_sit", 8.0, -8.0, 20000, 1, 1, false, false, false)

    Citizen.SetTimeout(20000, function()
        ClearPedTasks(ped)
        TaskWanderStandard(ped, 10.0, 10)
        isDancing = false
    end)
end)

Citizen.CreateThread(function()
    spawnStageStrippers()
    spawnRoamingStrippers()
end)