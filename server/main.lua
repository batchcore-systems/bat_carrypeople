local carrying = {}
local carried = {}
local lockedCarriedPlayers = {}

local frameworkCache = {
    esx = nil,
    qb = nil
}

local function getEsx()
    if frameworkCache.esx then
        return frameworkCache.esx
    end

    local ok, obj = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)

    if ok and obj then
        frameworkCache.esx = obj
    end

    return frameworkCache.esx
end

local function getQb()
    if frameworkCache.qb then
        return frameworkCache.qb
    end

    local ok, obj = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)

    if ok and obj then
        frameworkCache.qb = obj
    end

    return frameworkCache.qb
end

local function normalizeIdentifier(identifier)
    return string.lower(tostring(identifier or ''))
end

local function hasAllowedIdentifier(sourceId)
    local allowed = Config.Admin and Config.Admin.AllowedIdentifiers or {}
    if #allowed == 0 then
        return false
    end

    local active = {}
    for _, identifier in ipairs(GetPlayerIdentifiers(sourceId)) do
        active[normalizeIdentifier(identifier)] = true
    end

    for _, identifier in ipairs(allowed) do
        if active[normalizeIdentifier(identifier)] then
            return true
        end
    end

    return false
end

local function containsValue(items, value)
    for _, item in ipairs(items) do
        if item == value then
            return true
        end
    end

    return false
end

local function hasAdminPermission(sourceId)
    if sourceId == 0 then
        return true
    end

    if not Config.Admin or not Config.Admin.Enabled then
        return false
    end

    if GetResourceState('qb-core') == 'started' then
        local qb = getQb()
        if qb and qb.Functions and qb.Functions.HasPermission then
            if qb.Functions.HasPermission(sourceId, Config.Admin.Permission or 'admin') then
                return true
            end
        end
    end

    if GetResourceState('es_extended') == 'started' then
        local esx = getEsx()
        if esx and esx.GetPlayerFromId then
            local xPlayer = esx.GetPlayerFromId(sourceId)
            if xPlayer and xPlayer.getGroup then
                local group = xPlayer.getGroup()
                local allowedGroups = Config.Admin.EsxGroups or { 'admin', 'superadmin' }
                if containsValue(allowedGroups, group) then
                    return true
                end
            end
        end
    end

    return hasAllowedIdentifier(sourceId)
end

local function notify(sourceId, message, level)
    if sourceId == 0 then
        print(('[bat_carrypeople] %s'):format(message))
        return
    end

    CarryBridge.notify(sourceId, message, level)
end

local function isTypeEnabled(typeId)
    local typeDef = Config.Types[typeId]
    return typeDef and typeDef.Enabled == true
end

local function isBusy(playerId)
    return carrying[playerId] ~= nil or carried[playerId] ~= nil
end

local function clearPair(carrierId, carriedId)
    carrying[carrierId] = nil
    carried[carriedId] = nil
    lockedCarriedPlayers[carriedId] = nil
end

local function playerExists(playerId)
    return playerId and playerId > 0 and GetPlayerName(playerId) ~= nil
end

local function playersWithinDistance(sourceId, targetId, maxDistance)
    local sourcePed = GetPlayerPed(sourceId)
    local targetPed = GetPlayerPed(targetId)

    if sourcePed <= 0 or targetPed <= 0 then
        return false
    end

    local sourceCoords = GetEntityCoords(sourcePed)
    local targetCoords = GetEntityCoords(targetPed)

    return #(sourceCoords - targetCoords) <= maxDistance
end

local function getClosestPlayer(sourceId, maxDistance)
    local sourcePed = GetPlayerPed(sourceId)
    if sourcePed <= 0 then
        return nil
    end

    local sourceCoords = GetEntityCoords(sourcePed)
    local closestId = nil
    local closestDistance = maxDistance + 0.001

    for _, rawId in ipairs(GetPlayers()) do
        local playerId = tonumber(rawId)
        if playerId and playerId ~= sourceId then
            local targetPed = GetPlayerPed(playerId)
            if targetPed > 0 then
                local distance = #(GetEntityCoords(targetPed) - sourceCoords)
                if distance < closestDistance then
                    closestDistance = distance
                    closestId = playerId
                end
            end
        end
    end

    return closestId
end

local function stopPairForParticipant(playerId, reason)
    local carriedId = carrying[playerId]
    if carriedId then
        clearPair(playerId, carriedId)
        TriggerClientEvent('bat_carrypeople:client:stop', playerId, reason)
        TriggerClientEvent('bat_carrypeople:client:stop', carriedId, reason)
        return true
    end

    local carrierId = carried[playerId]
    if carrierId then
        clearPair(carrierId, playerId)
        TriggerClientEvent('bat_carrypeople:client:stop', carrierId, reason)
        TriggerClientEvent('bat_carrypeople:client:stop', playerId, reason)
        return true
    end

    return false
end

local function getPairFromPlayer(playerId)
    local carriedId = carrying[playerId]
    if carriedId then
        return playerId, carriedId
    end

    local carrierId = carried[playerId]
    if carrierId then
        return carrierId, playerId
    end

    return nil, nil
end

local function isPairAdminLocked(playerId)
    local _, carriedId = getPairFromPlayer(playerId)
    if not carriedId then
        return false
    end

    return lockedCarriedPlayers[carriedId] == true
end

RegisterNetEvent('bat_carrypeople:server:requestStart', function(targetId, typeId)
    local sourceId = source
    local target = tonumber(targetId)
    local selectedType = tonumber(typeId)

    if not Config.Features.Command then
        CarryBridge.notify(sourceId, Config.Locale.command_disabled, 'error')
        return
    end

    if not selectedType or not isTypeEnabled(selectedType) then
        CarryBridge.notify(sourceId, Config.Locale.invalid_type, 'error')
        return
    end

    if not target or target == sourceId or not playerExists(target) then
        CarryBridge.notify(sourceId, Config.Locale.target_invalid, 'error')
        return
    end

    if isBusy(sourceId) then
        CarryBridge.notify(sourceId, Config.Locale.already_busy, 'error')
        return
    end

    if isBusy(target) then
        CarryBridge.notify(sourceId, Config.Locale.target_busy, 'error')
        return
    end

    if not playersWithinDistance(sourceId, target, Config.Command.MaxDistance or 2.5) then
        CarryBridge.notify(sourceId, Config.Locale.too_far_away, 'error')
        return
    end

    carrying[sourceId] = target
    carried[target] = sourceId

    TriggerClientEvent('bat_carrypeople:client:start', sourceId, target, selectedType, 'carrier')
    TriggerClientEvent('bat_carrypeople:client:start', target, sourceId, selectedType, 'carried')
end)

RegisterNetEvent('bat_carrypeople:server:requestStop', function()
    local sourceId = source

    if isPairAdminLocked(sourceId) then
        CarryBridge.notify(sourceId, Config.Locale.carry_locked_admin_only, 'error')
        return
    end

    if carried[sourceId] and not Config.Features.AllowCarriedCancel then
        CarryBridge.notify(sourceId, Config.Locale.cancel_blocked, 'error')
        return
    end

    stopPairForParticipant(sourceId, Config.Locale.carry_stopped)
end)

RegisterNetEvent('bat_carrypeople:server:requestForceStop', function()
    local sourceId = source

    if isPairAdminLocked(sourceId) then
        CarryBridge.notify(sourceId, Config.Locale.carry_locked_admin_only, 'error')
        return
    end

    stopPairForParticipant(sourceId, Config.Locale.carry_stopped)
end)

RegisterCommand((Config.Admin and Config.Admin.Command) or 'carryadmin', function(sourceId, args)
    if not (Config.Admin and Config.Admin.Enabled) then
        return
    end

    if not hasAdminPermission(sourceId) then
        notify(sourceId, Config.Locale.admin_no_permission, 'error')
        return
    end

    local selectedType = tonumber(args[1] or '') or 1
    selectedType = math.floor(selectedType)

    if not isTypeEnabled(selectedType) then
        notify(sourceId, Config.Locale.admin_invalid_type, 'error')
        return
    end

    if isBusy(sourceId) then
        if isPairAdminLocked(sourceId) then
            stopPairForParticipant(sourceId, Config.Locale.admin_carry_stopped)
            notify(sourceId, Config.Locale.admin_carry_stopped, 'success')
            return
        end

        notify(sourceId, Config.Locale.already_busy, 'error')
        return
    end

    local maxDistance = (Config.Admin.MaxDistance or Config.Command.MaxDistance or 2.5)
    local targetId = getClosestPlayer(sourceId, maxDistance)
    if not targetId then
        notify(sourceId, Config.Locale.admin_no_player_nearby, 'error')
        return
    end

    if isBusy(targetId) then
        notify(sourceId, Config.Locale.target_busy, 'error')
        return
    end

    if not playersWithinDistance(sourceId, targetId, maxDistance) then
        notify(sourceId, Config.Locale.too_far_away, 'error')
        return
    end

    carrying[sourceId] = targetId
    carried[targetId] = sourceId
    lockedCarriedPlayers[targetId] = true

    TriggerClientEvent('bat_carrypeople:client:start', sourceId, targetId, selectedType, 'carrier')
    TriggerClientEvent('bat_carrypeople:client:start', targetId, sourceId, selectedType, 'carried')

    notify(sourceId, Config.Locale.admin_carry_started, 'success')
    notify(targetId, Config.Locale.carry_locked_admin_only, 'info')
end, false)

AddEventHandler('playerDropped', function()
    local sourceId = source
    lockedCarriedPlayers[sourceId] = nil

    local carriedId = carrying[sourceId]
    if carriedId then
        clearPair(sourceId, carriedId)
        TriggerClientEvent('bat_carrypeople:client:stop', carriedId, Config.Locale.partner_left)
        return
    end

    local carrierId = carried[sourceId]
    if carrierId then
        clearPair(carrierId, sourceId)
        TriggerClientEvent('bat_carrypeople:client:stop', carrierId, Config.Locale.partner_left)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    for carrierId, carriedId in pairs(carrying) do
        TriggerClientEvent('bat_carrypeople:client:stop', carrierId, Config.Locale.carry_stopped)
        TriggerClientEvent('bat_carrypeople:client:stop', carriedId, Config.Locale.carry_stopped)
    end
end)