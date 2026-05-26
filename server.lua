local QBCore = nil
if Config.Framework == "qb" then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- Universal Notify Helper
local function ServerNotify(src, msg, type)
    if Config.Framework == "qbox" then
        TriggerClientEvent("qbx_core:Notify", src, msg, type)
    else
        TriggerClientEvent("QBCore:Notify", src, msg, type)
    end
end

RegisterNetEvent("vu_strippers:payForDance", function(pedNet)
    local src = source
    local cost = Config.DancePrice
    local hasMoney = false

    if Config.Framework == "qbox" then
        local player = exports.qbx_core:GetPlayer(src)
        if player then
            -- Qbox / ox_inventory compatible check
            if player.Functions.RemoveMoney("cash", cost, "private-dance") then
                hasMoney = true
            end
        end
    else
        local player = QBCore.Functions.GetPlayer(src)
        if player and player.Functions.RemoveMoney("cash", cost, "private-dance") then
            hasMoney = true
        end
    end

    if hasMoney then
        ServerNotify(src, "You paid $"..cost.." for a private dance.", "success")
        TriggerClientEvent("vu_strippers:startDance", src, NetToPed(pedNet))
    else
        ServerNotify(src, "You don’t have enough cash!", "error")
    end
end)