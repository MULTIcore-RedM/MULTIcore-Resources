-- ============================================================
-- MULTIbelt :: client
-- Part of MULTIcore by RINGO (RINGOscripting). GPL v3.
--
-- How it works:
--   1. Every Config.CheckMs this client looks at its own weapons and works out
--      which Config.Items entries should show (carried, and not in a hand unless
--      the entry is `always`). The list of entry numbers goes into the player's
--      state bag `multibelt`, which the server shares with everyone.
--   2. Every client draws its own local copy of the props on every player near
--      it (itself included) from that state bag. Nothing is networked, so no
--      objects are left behind when someone leaves or the resource stops, and a
--      player who joins late sees everyone's props straight away.
-- ============================================================

local STATE_KEY = 'multibelt'

-- ------------------------------------------------------------ config lookup
local entries = {}      -- [n] = { hashes = {...}, model = hash, bone = {...}, pos = {...}, always = bool }

local function vec6(t)
    if type(t) ~= 'table' then return nil end
    return { tonumber(t[1] or t.x) or 0.0, tonumber(t[2] or t.y) or 0.0, tonumber(t[3] or t.z) or 0.0,
             tonumber(t[4] or t.rx or t.pitch) or 0.0, tonumber(t[5] or t.ry or t.roll) or 0.0,
             tonumber(t[6] or t.rz or t.yaw) or 0.0 }
end

for n, item in ipairs(Config.Items or {}) do
    if item.enabled ~= false and item.model then
        local list = type(item.weapons) == 'table' and item.weapons or { item.weapons }
        local hashes = {}
        for _, w in ipairs(list) do
            if type(w) == 'string' then hashes[#hashes + 1] = joaat(w:upper()) end
        end
        local bone = type(item.bone) == 'table' and item.bone or { male = item.bone }
        local pos = type(item.pos) == 'table' and item.pos or {}
        entries[n] = {
            hashes = hashes,
            model = type(item.model) == 'string' and joaat(item.model) or item.model,
            bone = { male = bone.male or 'SKEL_Pelvis', female = bone.female or bone.male or 'SKEL_Pelvis' },
            pos = { male = vec6(pos.male) or { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 } },
            always = item.always == true,
        }
        entries[n].pos.female = vec6(pos.female) or entries[n].pos.male
    end
end

-- ------------------------------------------------------------ 1. own weapons -> state bag
local function inHand(ped)
    local held = {}
    for point = 0, 1 do   -- 0 = right hand, 1 = left hand (the lantern is held left)
        local ok, hash = GetCurrentPedWeapon(ped, true, point, false)
        if ok and hash and hash ~= 0 then held[hash] = true end
    end
    return held
end

local function wantedList(ped)
    local held = inHand(ped)
    local list = {}
    for n, e in pairs(entries) do
        for _, h in ipairs(e.hashes) do
            if HasPedGotWeapon(ped, h, 0, false) and (e.always or not held[h]) then
                list[#list + 1] = n
                break
            end
        end
    end
    table.sort(list)
    return list
end

local function sameList(a, b)
    if type(a) ~= 'table' or type(b) ~= 'table' or #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end

local mine = {}

CreateThread(function()
    LocalPlayer.state:set(STATE_KEY, {}, true)
    while true do
        local ped = PlayerPedId()
        local list = (DoesEntityExist(ped) and not IsEntityDead(ped)) and wantedList(ped) or {}
        if not sameList(list, mine) then
            mine = list
            LocalPlayer.state:set(STATE_KEY, list, true)
        end
        Wait(Config.CheckMs or 300)
    end
end)

-- ------------------------------------------------------------ 2. draw props on players near us
local drawn = {}   -- [serverId] = { ped = ped, objs = { [n] = object } }

local function loadModel(model)
    if HasModelLoaded(model) then return true end
    if not IsModelValid(model) then return false end
    RequestModel(model, false)
    local untilAt = GetGameTimer() + 3000
    while not HasModelLoaded(model) do
        if GetGameTimer() > untilAt then return false end
        Wait(10)
    end
    return true
end

local function makeProp(ped, n)
    local e = entries[n]
    if not e or not loadModel(e.model) then return nil end
    local sex = IsPedMale(ped) and 'male' or 'female'
    local p = e.pos[sex]
    local boneIndex = GetEntityBoneIndexByName(ped, e.bone[sex])
    if boneIndex == -1 then boneIndex = GetEntityBoneIndexByName(ped, e.bone.male) end
    if boneIndex == -1 then boneIndex = 0 end
    local c = GetEntityCoords(ped)
    local obj = CreateObject(e.model, c.x, c.y, c.z - 5.0, false, false, false)
    if not obj or obj == 0 then return nil end
    SetEntityCollision(obj, false, false)
    SetEntityCompletelyDisableCollision(obj, false, false)
    AttachEntityToEntity(obj, ped, boneIndex, p[1], p[2], p[3], p[4], p[5], p[6], true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(e.model)
    return obj
end

local function clearPlayer(sid)
    local d = drawn[sid]
    if not d then return end
    for _, obj in pairs(d.objs) do
        if DoesEntityExist(obj) then DeleteObject(obj) end
    end
    drawn[sid] = nil
end

local function syncPlayer(sid, ped, list)
    local d = drawn[sid]
    if d and d.ped ~= ped then clearPlayer(sid); d = nil end   -- new ped (respawn, model change)
    if not d then d = { ped = ped, objs = {} }; drawn[sid] = d end

    local want = {}
    if type(list) == 'table' then
        for _, n in ipairs(list) do
            n = tonumber(n)
            if n and entries[n] then want[n] = true end
        end
    end

    for n, obj in pairs(d.objs) do
        if not want[n] or not DoesEntityExist(obj) or not IsEntityAttachedToEntity(obj, ped) then
            if DoesEntityExist(obj) then DeleteObject(obj) end
            d.objs[n] = nil
        end
    end
    for n in pairs(want) do
        if not d.objs[n] then d.objs[n] = makeProp(ped, n) end
    end

    if Config.HideWhenInvisible then
        local show = IsEntityVisible(ped)
        for _, obj in pairs(d.objs) do
            if IsEntityVisible(obj) ~= show then SetEntityVisible(obj, show) end
        end
    end
end

CreateThread(function()
    local maxDist = Config.DrawDistance or 80.0
    while true do
        local myPed = PlayerPedId()
        local myPos = GetEntityCoords(myPed)
        local seen = {}
        for _, player in ipairs(GetActivePlayers()) do
            local sid = GetPlayerServerId(player)
            local ped = GetPlayerPed(player)
            if sid and sid > 0 and DoesEntityExist(ped) then
                local list
                if player == PlayerId() then
                    list = mine
                elseif #(GetEntityCoords(ped) - myPos) <= maxDist then
                    list = Player(sid).state[STATE_KEY]
                end
                if list and not IsEntityDead(ped) then
                    seen[sid] = true
                    syncPlayer(sid, ped, list)
                end
            end
        end
        for sid in pairs(drawn) do
            if not seen[sid] then clearPlayer(sid) end
        end
        Wait(250)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for sid in pairs(drawn) do clearPlayer(sid) end
end)
