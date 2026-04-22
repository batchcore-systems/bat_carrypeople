CarryBridge = CarryBridge or {}

local bridgeCache = {
    framework = nil,
    esx = nil,
    qb = nil
}

local function isStarted(resourceName)
    return GetResourceState(resourceName) == 'started'
end

local function detectFramework()
    local forced = (Config.Framework or 'auto'):lower()
    if forced ~= 'auto' then
        return forced
    end

    if isStarted('ox_core') or isStarted('ox_lib') then
        return 'ox'
    end

    if isStarted('qb-core') then
        return 'qbcore'
    end

    if isStarted('es_extended') then
        return 'esx'
    end

    return 'standalone'
end

function CarryBridge.framework()
    if not bridgeCache.framework then
        bridgeCache.framework = detectFramework()
    end

    return bridgeCache.framework
end

function CarryBridge.debug(...)
    if not Config.Debug then
        return
    end

    local chunks = { ... }
    for i = 1, #chunks do
        chunks[i] = tostring(chunks[i])
    end

    print(('[bat_carrypeople] %s'):format(table.concat(chunks, ' ')))
end

if IsDuplicityVersion() then
    function CarryBridge.notify(targetId, message, level)
        if not Config.Notifications.Enabled then
            return
        end

        TriggerClientEvent('bat_carrypeople:client:notify', targetId, message, level or 'info')
    end

    return
end

local function getEsx()
    if bridgeCache.esx then
        return bridgeCache.esx
    end

    local ok, obj = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)

    if ok and obj then
        bridgeCache.esx = obj
    end

    return bridgeCache.esx
end

local function getQb()
    if bridgeCache.qb then
        return bridgeCache.qb
    end

    local ok, obj = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)

    if ok and obj then
        bridgeCache.qb = obj
    end

    return bridgeCache.qb
end

local function nativeNotify(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

local function chatNotify(message)
    TriggerEvent('chat:addMessage', {
        color = { 235, 235, 235 },
        args = { 'Carry', message }
    })
end

local function levelForQb(level)
    if level == 'success' then
        return 'success'
    end

    if level == 'error' then
        return 'error'
    end

    return 'primary'
end

local function levelForOx(level)
    if level == 'success' then
        return 'success'
    end

    if level == 'error' then
        return 'error'
    end

    return 'inform'
end

local function selectNotificationSystem()
    local mode = (Config.Notifications.System or 'auto'):lower()
    if mode ~= 'auto' then
        return mode
    end

    if isStarted('ox_lib') then
        return 'ox'
    end

    local framework = CarryBridge.framework()
    if framework == 'esx' then
        return 'esx'
    end

    if framework == 'qbcore' then
        return 'qbcore'
    end

    return 'native'
end

function CarryBridge.notify(message, level)
    if not Config.Notifications.Enabled then
        return
    end

    local system = selectNotificationSystem()

    if system == 'ox' then
        local ok = pcall(function()
            exports.ox_lib:notify({
                title = 'Carry',
                description = message,
                type = levelForOx(level),
                position = Config.Notifications.Position,
                duration = Config.Notifications.Duration
            })
        end)

        if ok then
            return
        end
    elseif system == 'esx' then
        local esx = getEsx()
        if esx and esx.ShowNotification then
            esx.ShowNotification(message)
            return
        end
    elseif system == 'qbcore' then
        local qb = getQb()
        if qb and qb.Functions and qb.Functions.Notify then
            qb.Functions.Notify(message, levelForQb(level), Config.Notifications.Duration)
            return
        end
    elseif system == 'chat' then
        chatNotify(message)
        return
    end

    nativeNotify(message)
end