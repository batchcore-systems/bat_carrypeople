Config = Config or {}

Config.Debug = false

-- auto | esx | qbcore | ox | standalone
Config.Framework = 'auto'

Config.Features = {
    Command = true,
    TypeSubCommand = true,
    UiPicker = true,
    CancelAlias = true,
    AllowCarriedCancel = true,
    AutoStopOnDeath = true,
    AutoStopOnVehicle = true,
    AutoStopOnRagdoll = false
}

Config.Command = {
    Name = 'carry',
    TypeKeyword = 'type',
    CancelAliases = { 'uncarry' },
    MaxDistance = 2.5,
    CooldownMs = 900
}

Config.DefaultType = 1

Config.Notifications = {
    Enabled = true,
    -- auto | ox | esx | qbcore | native | chat
    System = 'auto',
    Position = 'center-right',
    Duration = 3500
}

Config.Ui = {
    OpenOnCarry = true,
    -- inrange: menu opens only if someone is nearby
    -- everywhere: menu can always open, range check on type selection
    OpenMenu = 'inrange',
    CloseOnEscape = true,
    ShowOnlyEnabledTypes = true,
    RememberLastSelection = true
}

Config.Target = {
    Enabled = true,
    -- auto | ox | qb
    System = 'auto',
    -- menu | direct
    Mode = 'direct',
    Distance = 2.5,
    UncarryDistance = 4.0,
    Icon = 'fa-solid fa-people-carry-box',
    Label = 'Carry',
    UncarryIcon = 'fa-solid fa-link-slash',
    UncarryLabel = 'Uncarry'
}

Config.Admin = {
    Enabled = true,
    Command = 'carryadmin',
    MaxDistance = 2.5,
    Permission = 'admin', -- if using qbcore framework, otherwise this is ignored
    EsxGroups = { 'admin', 'superadmin' }, -- if using esx framework, otherwise this is ignored
    AllowedIdentifiers = { -- standalone & ox framework, otherwise this is ignored. Format: type:id, example:
        -- 'license:123123',
        -- 'discord:123123'
    }
}

Config.Types = {
    [1] = {
        Enabled = true,
        Label = 'Carry',
        Description = 'Classic shoulder carry',
        Image = 'img/carry.png',
        Carrier = {
            dict = 'missfinale_c2mcs_1',
            anim = 'fin_c2_mcs_1_camman',
            flag = 49,
            duration = -1
        },
        Carried = {
            dict = 'nm',
            anim = 'firemans_carry',
            flag = 33,
            duration = -1,
            attach = {
                bone = 0,
                x = 0.27,
                y = 0.15,
                z = 0.63,
                pitch = 0.5,
                roll = 0.5,
                yaw = 180.0
            }
        }
    },
    [2] = {
        Enabled = true,
        Label = 'Arm Sitback',
        Description = 'Side arm sit',
        Image = 'img/arm-sitback.png',
        Carrier = {
            dict = 'anim@heists@box_carry@',
            anim = 'idle',
            flag = 49,
            duration = -1
        },
        Carried = {
            dict = 'amb@code_human_in_car_idles@generic@ps@base',
            anim = 'base',
            flag = 33,
            duration = -1,
            attach = {
                bone = 9816,
                x = 0.015,
                y = 0.38,
                z = 0.11,
                pitch = 0.9,
                roll = 0.3,
                yaw = 90.0
            }
        }
    },
    [3] = {
        Enabled = true,
        Label = 'Piggyback',
        Description = 'Classic piggyback',
        Image = 'img/piggyback.png',
        Carrier = {
            dict = 'anim@arena@celeb@flat@paired@no_props@',
            anim = 'piggyback_c_player_a',
            flag = 49,
            duration = -1
        },
        Carried = {
            dict = 'anim@arena@celeb@flat@paired@no_props@',
            anim = 'piggyback_c_player_b',
            flag = 33,
            duration = -1,
            attach = {
                bone = 0,
                x = 0.0,
                y = -0.07,
                z = 0.45,
                pitch = 0.5,
                roll = 0.5,
                yaw = 0.0
            }
        }
    }
}

Config.Locale = {
    command_disabled = 'This feature is disabled.',
    type_command_disabled = 'The type subcommand is disabled.',
    invalid_type = 'Invalid carry type.',
    type_usage = 'Usage: /carry type 1|2|3',
    no_player_nearby = 'No player nearby.',
    already_busy = 'You are already carrying someone or being carried.',
    target_busy = 'This player is currently busy.',
    target_invalid = 'Invalid target player.',
    too_far_away = 'The player is too far away.',
    carry_started = 'Carry started.',
    carry_stopped = 'Carry stopped.',
    cancel_blocked = 'Only the carrier can stop this carry.',
    ui_no_types = 'No active carry types available.',
    ui_open_requires_range = 'A nearby player is required to open the menu.',
    ui_open_mode_invalid = 'Invalid OpenMenu mode. Use inrange or everywhere.',
    partner_left = 'Carry stopped: partner not available.',
    target_not_available = 'No compatible target system found.',
    cooldown = 'Please wait a moment.',
    carry_locked_admin_only = 'Carry lock is active: only an admin can stop this carry.',
    admin_no_permission = 'You do not have permission for this admin command.',
    admin_usage = 'Usage: /carryadmin [1|2|3] (empty = 1)',
    admin_no_player_nearby = 'No nearby player found for admin carry.',
    admin_target_invalid = 'Invalid player ID.',
    admin_invalid_type = 'Invalid admin carry type.',
    admin_carry_started = 'Admin carry started.',
    admin_carry_stopped = 'Admin carry stopped.',
    admin_force_uncarry_done = 'Carry was stopped by an admin.',
    admin_force_uncarry_none = 'Player is not in a carry state right now.'
}
