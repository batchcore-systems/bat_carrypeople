local State = {
    active = false,
    role = nil,
    partnerServerId = nil,
    typeId = nil,
    uiOpen = false,
    pendingTargetServerId = nil,
    stopRequested = false,
    lastCommandAt = 0,
    lastSelectedType = Config.DefaultType,
    targetSystem = nil
}

local function getSortedTypeIds()
    local ids = {}
    for typeId in pairs(Config.Types) do
        ids[#ids + 1] = typeId
    end

    table.sort(ids)
    return ids
end

local function resolveType(typeId, allowDisabled)
    local numericType = tonumber(typeId)
    if not numericType then
        return nil
    end

    numericType = math.floor(numericType)

    local typeDef = Config.Types[numericType]
    if not typeDef then
        return nil
    end

    if not allowDisabled and not typeDef.Enabled then
        return nil
    end

    return numericType, typeDef
end

local function isOnCooldown()
    local cooldown = Config.Command.CooldownMs or 0
    if cooldown <= 0 then
        return false
    end

    local now = GetGameTimer()
    if now - State.lastCommandAt < cooldown then
        return true
    end

    State.lastCommandAt = now
    return false
end

local function getOpenMenuMode()
    local mode = (Config.Ui.OpenMenu or 'inrange'):lower()
    if mode ~= 'inrange' and mode ~= 'everywhere' then
        CarryBridge.notify(Config.Locale.ui_open_mode_invalid, 'error')
        return 'inrange'
    end

    return mode
end

local function getClosestPlayerServerId(maxDistance)
    local selfPed = PlayerPedId()
    local selfCoords = GetEntityCoords(selfPed)

    local closestDistance = maxDistance + 0.001
    local closestServerId = nil

    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local targetPed = GetPlayerPed(player)
            if DoesEntityExist(targetPed) then
                local distance = #(GetEntityCoords(targetPed) - selfCoords)
                if distance < closestDistance then
                    closestDistance = distance
                    closestServerId = GetPlayerServerId(player)
                end
            end
        end
    end

    return closestServerId
end

local function getServerIdFromPed(entity)
    if not entity or entity == 0 then
        return nil
    end

    local player = NetworkGetPlayerIndexFromPed(entity)
    if player == -1 then
        return nil
    end

    return GetPlayerServerId(player)
end

local function canInteractWithTarget(entity, distance)
    if not entity or entity == PlayerPedId() then
        return false
    end

    if distance and distance > (Config.Target.Distance or Config.Command.MaxDistance or 2.5) then
        return false
    end

    if State.active and State.role == 'carried' and not Config.Features.AllowCarriedCancel then
        return false
    end

    return getServerIdFromPed(entity) ~= nil
end

local function getTargetSystem()
    local requested = (Config.Target.System or 'auto'):lower()
    if requested ~= 'auto' then
        return requested
    end

    return 'auto'
end

local function getPartnerPed()
    if not State.partnerServerId then
        return nil
    end

    local player = GetPlayerFromServerId(State.partnerServerId)
    if player == -1 then
        return nil
    end

    local ped = GetPlayerPed(player)
    if ped <= 0 or not DoesEntityExist(ped) then
        return nil
    end

    return ped
end

local function requestAnimDict(animDict)
    if HasAnimDictLoaded(animDict) then
        return
    end

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(0)
    end
end

local function closeTypePicker()
    if not State.uiOpen then
        return
    end

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    State.uiOpen = false
    State.pendingTargetServerId = nil
end

local function stopLocalCarry()
    closeTypePicker()

    if State.active then
        ClearPedSecondaryTask(PlayerPedId())
        DetachEntity(PlayerPedId(), true, false)
    end

    State.active = false
    State.role = nil
    State.partnerServerId = nil
    State.typeId = nil
    State.stopRequested = false
end

local function requestStop(forceStop)
    if not State.active or State.stopRequested then
        return
    end

    State.stopRequested = true
    TriggerServerEvent(forceStop and 'bat_carrypeople:server:requestForceStop' or 'bat_carrypeople:server:requestStop')
end

local function ensureCarryAnimation()
    if not State.active then
        return
    end

    local typeDef = Config.Types[State.typeId]
    if not typeDef then
        requestStop(true)
        return
    end

    local roleDef = State.role == 'carrier' and typeDef.Carrier or typeDef.Carried
    if not roleDef then
        requestStop(true)
        return
    end

    local selfPed = PlayerPedId()

    if State.role == 'carried' then
        local partnerPed = getPartnerPed()
        if not partnerPed then
            requestStop(true)
            return
        end

        local attach = roleDef.attach or {}
        if not IsEntityAttachedToEntity(selfPed, partnerPed) then
            AttachEntityToEntity(
                selfPed,
                partnerPed,
                attach.bone or 0,
                attach.x or 0.0,
                attach.y or 0.0,
                attach.z or 0.0,
                attach.pitch or 0.0,
                attach.roll or 0.0,
                attach.yaw or 0.0,
                false,
                false,
                false,
                false,
                2,
                false
            )
        end
    end

    requestAnimDict(roleDef.dict)
    if not IsEntityPlayingAnim(selfPed, roleDef.dict, roleDef.anim, 3) then
        TaskPlayAnim(
            selfPed,
            roleDef.dict,
            roleDef.anim,
            8.0,
            -8.0,
            roleDef.duration or -1,
            roleDef.flag or 49,
            0.0,
            false,
            false,
            false
        )
    end
end

local function startCarryWithType(typeId, forcedTargetServerId)
    local numericType = resolveType(typeId)
    if not numericType then
        CarryBridge.notify(Config.Locale.invalid_type, 'error')
        return
    end

    local targetServerId = tonumber(forcedTargetServerId) or getClosestPlayerServerId(Config.Command.MaxDistance)
    if not targetServerId then
        CarryBridge.notify(Config.Locale.no_player_nearby, 'error')
        return
    end

    if Config.Ui.RememberLastSelection then
        State.lastSelectedType = numericType
    end

    TriggerServerEvent('bat_carrypeople:server:requestStart', targetServerId, numericType)
end

local function openTypePicker(forcedTargetServerId)
    local uiTypes = {}

    for _, typeId in ipairs(getSortedTypeIds()) do
        local typeDef = Config.Types[typeId]

        if not Config.Ui.ShowOnlyEnabledTypes or typeDef.Enabled then
            uiTypes[#uiTypes + 1] = {
                id = typeId,
                enabled = typeDef.Enabled,
                label = typeDef.Label,
                description = typeDef.Description,
                image = typeDef.Image
            }
        end
    end

    if #uiTypes == 0 then
        CarryBridge.notify(Config.Locale.ui_no_types, 'error')
        return false
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        selectedType = State.lastSelectedType or Config.DefaultType,
        allowEscapeClose = Config.Ui.CloseOnEscape,
        types = uiTypes
    })

    State.uiOpen = true
    State.pendingTargetServerId = tonumber(forcedTargetServerId)
    return true
end

local function handleTargetAction(targetServerId)
    if not targetServerId then
        return
    end

    if State.active then
        if State.role == 'carried' and not Config.Features.AllowCarriedCancel then
            CarryBridge.notify(Config.Locale.cancel_blocked, 'error')
            return
        end

        requestStop(false)
        return
    end

    local targetMode = (Config.Target.Mode or 'menu'):lower()
    if targetMode == 'menu' and Config.Features.UiPicker and Config.Ui.OpenOnCarry then
        if openTypePicker(targetServerId) then
            return
        end
    end

    startCarryWithType(State.lastSelectedType or Config.DefaultType, targetServerId)
end

local function canUseTargetUncarry(distance)
    if not State.active then
        return false
    end

    local uncarryDistance = Config.Target.UncarryDistance or Config.Target.Distance or Config.Command.MaxDistance or 2.5
    if distance and distance > uncarryDistance then
        return false
    end

    if State.role == 'carried' and not Config.Features.AllowCarriedCancel then
        return false
    end

    return true
end

local function registerOxTarget()
    local ok = pcall(function()
        exports.ox_target:addGlobalPlayer({
            {
                name = 'bat_carrypeople_target_start',
                icon = Config.Target.Icon,
                label = Config.Target.Label,
                distance = Config.Target.Distance or Config.Command.MaxDistance,
                canInteract = function(entity, distance)
                    return (not State.active) and canInteractWithTarget(entity, distance)
                end,
                onSelect = function(data)
                    handleTargetAction(getServerIdFromPed(data and data.entity))
                end
            },
            {
                name = 'bat_carrypeople_target_stop',
                icon = Config.Target.UncarryIcon or 'fa-solid fa-link-slash',
                label = Config.Target.UncarryLabel or 'Uncarry',
                distance = Config.Target.UncarryDistance or Config.Target.Distance or Config.Command.MaxDistance,
                canInteract = function(_, distance)
                    return canUseTargetUncarry(distance)
                end,
                onSelect = function()
                    requestStop(false)
                end
            }
        })
    end)

    if ok then
        State.targetSystem = 'ox'
        return true
    end

    return false
end

local function registerQbTarget()
    local ok = pcall(function()
        local startDistance = Config.Target.Distance or Config.Command.MaxDistance or 2.5
        local stopDistance = Config.Target.UncarryDistance or startDistance

        exports['qb-target']:AddGlobalPlayer({
            options = {
                {
                    icon = Config.Target.Icon,
                    label = Config.Target.Label,
                    action = function(entity)
                        handleTargetAction(getServerIdFromPed(entity))
                    end,
                    canInteract = function(entity, distance)
                        return (not State.active) and canInteractWithTarget(entity, distance)
                    end
                },
                {
                    icon = Config.Target.UncarryIcon or 'fa-solid fa-link-slash',
                    label = Config.Target.UncarryLabel or 'Uncarry',
                    action = function()
                        requestStop(false)
                    end,
                    canInteract = function(_, distance)
                        return canUseTargetUncarry(distance)
                    end
                }
            },
            distance = math.max(startDistance, stopDistance)
        })
    end)

    if ok then
        State.targetSystem = 'qb'
        return true
    end

    return false
end

local function registerTargetIntegration()
    if not Config.Target.Enabled then
        return
    end

    local system = getTargetSystem()

    if system == 'ox' then
        if registerOxTarget() then
            return
        end

        CarryBridge.notify(Config.Locale.target_not_available, 'error')
        return
    end

    if system == 'qb' then
        if registerQbTarget() then
            return
        end

        CarryBridge.notify(Config.Locale.target_not_available, 'error')
        return
    end

    if GetResourceState('ox_target') == 'started' and registerOxTarget() then
        return
    end

    if GetResourceState('qb-target') == 'started' and registerQbTarget() then
        return
    end

    CarryBridge.notify(Config.Locale.target_not_available, 'error')
end

RegisterNUICallback('pickType', function(data, cb)
    local menuTargetServerId = State.pendingTargetServerId
    closeTypePicker()

    local selectedType = tonumber(data and data.typeId)
    if selectedType then
        startCarryWithType(selectedType, menuTargetServerId)
    end

    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    closeTypePicker()
    cb({ ok = true })
end)

RegisterCommand(Config.Command.Name, function(_, args)
    if not Config.Features.Command then
        CarryBridge.notify(Config.Locale.command_disabled, 'error')
        return
    end

    if State.active then
        if State.role == 'carried' and not Config.Features.AllowCarriedCancel then
            CarryBridge.notify(Config.Locale.cancel_blocked, 'error')
            return
        end

        requestStop(false)
        return
    end

    if isOnCooldown() then
        CarryBridge.notify(Config.Locale.cooldown, 'info')
        return
    end

    local firstArg = args[1] and args[1]:lower() or nil
    local typeKeyword = (Config.Command.TypeKeyword or 'type'):lower()

    if firstArg == typeKeyword then
        if not Config.Features.TypeSubCommand then
            CarryBridge.notify(Config.Locale.type_command_disabled, 'error')
            return
        end

        local requestedType = tonumber(args[2] or '')
        if not requestedType then
            CarryBridge.notify(Config.Locale.type_usage, 'info')
            return
        end

        startCarryWithType(requestedType)
        return
    end

    if firstArg and tonumber(firstArg) and Config.Features.TypeSubCommand then
        startCarryWithType(tonumber(firstArg))
        return
    end

    if Config.Features.UiPicker and Config.Ui.OpenOnCarry then
        local openMode = getOpenMenuMode()
        local nearestTargetId = nil

        if openMode == 'inrange' then
            nearestTargetId = getClosestPlayerServerId(Config.Command.MaxDistance)
            if not nearestTargetId then
                CarryBridge.notify(Config.Locale.ui_open_requires_range, 'error')
                return
            end
        end

        if openTypePicker(nearestTargetId) then
            return
        end
    end

    startCarryWithType(State.lastSelectedType or Config.DefaultType)
end, false)

if Config.Features.CancelAlias then
    for _, alias in ipairs(Config.Command.CancelAliases or {}) do
        RegisterCommand(alias, function()
            if not State.active then
                return
            end

            if State.role == 'carried' and not Config.Features.AllowCarriedCancel then
                CarryBridge.notify(Config.Locale.cancel_blocked, 'error')
                return
            end

            requestStop(false)
        end, false)
    end
end

RegisterNetEvent('bat_carrypeople:client:start', function(partnerServerId, typeId, role)
    local numericType = tonumber(typeId)
    if not numericType or not Config.Types[numericType] then
        return
    end

    stopLocalCarry()

    State.active = true
    State.role = role
    State.partnerServerId = tonumber(partnerServerId)
    State.typeId = numericType
    State.stopRequested = false

    if Config.Ui.RememberLastSelection then
        State.lastSelectedType = numericType
    end

    ensureCarryAnimation()

    if role == 'carrier' then
        CarryBridge.notify(Config.Locale.carry_started, 'success')
    end
end)

RegisterNetEvent('bat_carrypeople:client:stop', function(reason)
    local wasActive = State.active
    stopLocalCarry()

    if wasActive then
        CarryBridge.notify(reason or Config.Locale.carry_stopped, 'info')
    end
end)

RegisterNetEvent('bat_carrypeople:client:notify', function(message, level)
    CarryBridge.notify(message, level)
end)

CreateThread(function()
    registerTargetIntegration()
end)

CreateThread(function()
    while true do
        if State.active then
            ensureCarryAnimation()
            Wait(150)
        else
            Wait(600)
        end
    end
end)

CreateThread(function()
    while true do
        if State.active then
            local ped = PlayerPedId()
            local shouldStop = false

            if Config.Features.AutoStopOnDeath and IsEntityDead(ped) then
                shouldStop = true
            elseif Config.Features.AutoStopOnVehicle and IsPedInAnyVehicle(ped, false) then
                shouldStop = true
            elseif Config.Features.AutoStopOnRagdoll and IsPedRagdoll(ped) then
                shouldStop = true
            end

            if shouldStop then
                requestStop(true)
            end

            Wait(250)
        else
            Wait(900)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    if State.targetSystem == 'ox' then
        pcall(function()
            exports.ox_target:removeGlobalPlayer('bat_carrypeople_target_start')
            exports.ox_target:removeGlobalPlayer('bat_carrypeople_target_stop')
        end)
    end

    stopLocalCarry()
end)