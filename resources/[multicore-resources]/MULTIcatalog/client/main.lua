-- ============================================================
-- MULTIcatalog :: client
-- MULTItarget (or a hold-key prompt) on every post office counter,
-- the catalog item, and the catalog page. The client never changes
-- anything itself: it asks the server and shows the answer.
-- GPL v3, part of MULTIcore by RINGO (RINGOscripting).
-- ============================================================

local isOpen = false
local openedAtCounter = false
local staticSent = false
local zones = {}

local function notify(text, kind)
    exports.MULTIcore:Notify({ text = text, title = _L('title'), type = kind or 'info', duration = Config.NotifyDuration })
end

local function atCounter()
    local pos = GetEntityCoords(cache.ped)
    for _, o in ipairs(Config.Offices) do
        if #(pos - o.coords) <= Config.MaxUseDistance then return true end
    end
    return false
end

local function imagePaths()
    if type(Config.ImagePaths) == 'table' then return Config.ImagePaths end
    if GetResourceState('MULTIinventory') == 'started' then
        local ok, list = pcall(function() return exports.MULTIinventory:GetImagePaths() end)
        if ok and type(list) == 'table' then return list end
    end
    return { 'nui://MULTIimages/images/' }
end

---------------------------------
-- the page
---------------------------------
local function close()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

--- via = 'counter' | 'item'
local function open(via)
    if isOpen then return end
    local ok, state = lib.callback.await('MULTIcatalog:open', false, via)
    if not ok then
        if state then notify(state, 'error') end
        return
    end
    isOpen = true
    openedAtCounter = state.office ~= nil and via ~= 'item'
    if not staticSent then
        staticSent = true
        SendNUIMessage({ action = 'setup', L = _LT(), lang = _LCode(), images = imagePaths() })
    end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', state = state })
end

RegisterNetEvent('MULTIcatalog:client:open', function(via)
    open(via == 'item' and 'item' or 'counter')
end)

RegisterNUICallback('close', function(_, cb)
    close()
    cb({})
end)

RegisterNUICallback('action', function(data, cb)
    if not isOpen or type(data) ~= 'table' then return cb({ ok = false }) end
    local res = lib.callback.await('MULTIcatalog:action', false, data.action, data.data or {})
    if type(res) ~= 'table' then res = { ok = false, msg = _L('err_failed') } end
    cb(res)
    if res.ok and res.msg then notify(res.msg, 'success') end
end)

-- walking away from the counter closes a page that was opened there
CreateThread(function()
    while true do
        Wait(Config.CheckIntervalMs)
        if isOpen and openedAtCounter and not atCounter() then close() end
    end
end)

---------------------------------
-- counters: MULTItarget or hold-key prompt (no markers, no sprites)
---------------------------------
MCI.Run(Config.Interact, function(mode)
    for _, o in ipairs(Config.Offices) do
        if mode == 'target' then
            zones[#zones + 1] = MCI.AddZone({ coords = o.coords, radius = Config.TargetRadius, options = { {
                name = 'multicatalog_' .. o.id, label = _L('prompt_open'), icon = Config.TargetIcon,
                distance = Config.TargetDistance, onSelect = function() open('counter') end,
            } } })
        else
            MCI.AddPrompt('multicatalog_' .. o.id, o.coords, Config.PromptKey, _L('prompt_open'),
                { type = 'client', event = 'MULTIcatalog:client:open', args = { 'counter' } }, Config.PromptDistance)
        end
    end
end, function()
    for _, id in ipairs(zones) do MCI.RemoveZone(id) end
    zones = {}
    for _, o in ipairs(Config.Offices) do MCI.RemovePrompt('multicatalog_' .. o.id) end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if isOpen then SetNuiFocus(false, false) end
    for _, o in ipairs(Config.Offices) do MCI.RemovePrompt('multicatalog_' .. o.id) end
    -- MULTItarget drops this script's zones by itself when it stops
end)
