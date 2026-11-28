-- ============================================================
-- MULTIcatalog :: server
-- Mail-order catalog. A player orders everyday goods at a post office
-- counter (or anywhere with a catalog in the satchel), pays at once, and
-- collects the parcel at the office they picked once the delivery time
-- has passed. Orders live in `multicore_catalog_orders`, so they survive
-- restarts. Everything is decided here; the client only asks.
-- GPL v3, part of MULTIcore by RINGO (RINGOscripting).
-- ============================================================

MCat = {}
MCat.SELFTEST = GetConvar('multicore_selftest', 'false') == 'true'

local ready = false
local calls = {}            -- [src] = { timestamps } spam guard
local lastOrder = {}        -- [src] = GetGameTimer() of the last order
local officeOverride = {}   -- [src] = office index | false (self-test only)
local warned = {}           -- warning text -> true (each warning once)

MCat.Catalog = {}           -- { name, label, desc, image, price, category } in config order
MCat.ByName = {}            -- name -> entry

local function dbg(...)
    if Config.Debug then print('^5[MULTIcatalog]^7', ...) end
end
local function warnOnce(msg)
    if warned[msg] then return end
    warned[msg] = true
    print('^3[MULTIcatalog] ' .. msg .. '^7')
end

local function round2(n) return math.floor((tonumber(n) or 0) * 100 + 0.5) / 100 end
local function money(n) return ('%.2f'):format(round2(n)) end

local function notify(src, text, kind)
    exports.MULTIcore:Notify(src, { text = text, title = _L('title'), type = kind or 'info', duration = Config.NotifyDuration })
end

local function citizenOf(src)
    local c = MC.GetCharacter(src)
    return c and c.citizenid or nil, c
end

---------------------------------
-- tables
---------------------------------
local function makeTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `multicore_catalog_orders` (
          `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
          `citizenid` VARCHAR(50) NOT NULL,
          `office` VARCHAR(50) NOT NULL,
          `items` LONGTEXT NOT NULL,
          `ordered` LONGTEXT NOT NULL,
          `total` DECIMAL(10,2) NOT NULL DEFAULT 0,
          `created` INT UNSIGNED NOT NULL,
          `ready_at` INT UNSIGNED NOT NULL,
          `status` VARCHAR(16) NOT NULL DEFAULT 'transit',
          `collected_at` INT UNSIGNED DEFAULT NULL,
          PRIMARY KEY (`id`),
          KEY `citizenid` (`citizenid`),
          KEY `status_ready` (`status`, `ready_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    -- a collection cut short by a crash: the parcel waits again
    MySQL.update.await("UPDATE `multicore_catalog_orders` SET `status` = 'arrived' WHERE `status` = 'collecting'")
end

local function cleanup()
    local days = tonumber(Config.KeepCollectedDays) or 0
    if days <= 0 then return end
    MySQL.update.await("DELETE FROM `multicore_catalog_orders` WHERE `status` = 'collected' AND `collected_at` < ?",
        { os.time() - days * 86400 })
end

---------------------------------
-- the catalog: config lines checked against the item list and the stores
---------------------------------
local function forbiddenName(name)
    return name:find('^weapon_') ~= nil or name:find('^ammo_') ~= nil
end

--- Lowest price and highest pay-out of every item in MULTIstores, or nil when the stores are not up.
local function storePrices()
    if GetResourceState('MULTIstores') ~= 'started' then return nil end
    local ok, isReady = pcall(function() return exports.MULTIstores:IsReady() end)
    if not ok or not isReady then return nil end
    local out = {}
    local okList, list = pcall(function() return exports.MULTIstores:GetStores() end)
    if not okList or type(list) ~= 'table' then return nil end
    for _, s in ipairs(list) do
        local okS, store = pcall(function() return exports.MULTIstores:GetStore(s.name) end)
        if okS and type(store) == 'table' then
            for _, it in ipairs(store.items or {}) do
                local n = tostring(it.name or ''):lower()
                local e = out[n] or {}
                local p, b = tonumber(it.price), tonumber(it.buyPrice)
                if p and p > 0 and (not e.sell or p < e.sell) then e.sell = p end
                if b and b > 0 and (not e.buy or b > e.buy) then e.buy = b end
                out[n] = e
            end
        end
    end
    return out
end

--- Builds MCat.Catalog from Config.Items. final = also warn about items still missing.
--- Returns how many items were not in the item list yet, and whether store prices were compared.
local function buildCatalog(final)
    local MI = exports.MULTIinventory
    local stores = storePrices()
    local list, byName, missing = {}, {}, 0
    for _, it in ipairs(Config.Items or {}) do
        local name = tostring(it.name or ''):lower()
        local price = tonumber(it.price)
        if name == '' or byName[name] then
            -- empty or listed twice: the first line wins
        elseif forbiddenName(name) then
            warnOnce(('item "%s" is a weapon or ammunition and is never sold by the catalog'):format(name))
        elseif not price or price <= 0 then
            warnOnce(('item "%s" has no price, left out'):format(name))
        else
            local okD, def = pcall(function() return MI:GetItemDef(name) end)
            def = okD and def or nil
            if not def then
                missing = missing + 1
                if final then warnOnce(('item "%s" is not in the item list, left out'):format(name)) end
            elseif def.type == 'weapon' then
                warnOnce(('item "%s" is a weapon and is never sold by the catalog'):format(name))
            else
                local s = stores and stores[name]
                if s and s.buy and round2(price) < round2(s.buy * 2) then
                    warnOnce(('item "%s": price %s is below twice what a store pays (%s), left out (no money loops)')
                        :format(name, money(price), money(s.buy)))
                else
                    if s and s.sell and round2(price) < round2(s.sell) then
                        warnOnce(('item "%s": price %s is cheaper than the cheapest store (%s)'):format(name, money(price), money(s.sell)))
                    end
                    -- catalog line desc_<name>, else the inventory's description, else the general line
                    local key = 'desc_' .. name
                    local desc = _L(key)
                    if desc == key then desc = def.description or def.desc or '' end
                    if desc == '' then desc = _L('desc_generic') end
                    local e = {
                        name = name,
                        label = def.label or name,
                        desc = desc,
                        image = def.image or (name .. '.png'),
                        price = round2(price),
                        category = it.category or 'goods',
                    }
                    list[#list + 1] = e
                    byName[name] = e
                end
            end
        end
    end
    MCat.Catalog, MCat.ByName = list, byName
    return missing, stores ~= nil
end

---------------------------------
-- places and timing
---------------------------------
--- Index of the office counter the player stands at, or nil.
function MCat.OfficeAt(src)
    src = tonumber(src)
    if officeOverride[src] ~= nil then return officeOverride[src] or nil end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local pos = GetEntityCoords(ped)
    local best, bestDist
    for i, o in ipairs(Config.Offices) do
        local d = #(pos - o.coords)
        if d <= Config.MaxUseDistance and (not bestDist or d < bestDist) then best, bestDist = i, d end
    end
    return best
end

local function officeById(id)
    for i, o in ipairs(Config.Offices) do
        if o.id == id then return o, i end
    end
end
local function officeLabel(id)
    local o = officeById(id)
    return o and _L(o.label) or tostring(id)
end

local function hasCatalog(src)
    return Config.CatalogItem.Enabled and MC.HasItem(src, Config.CatalogItem.Name, 1) or false
end

--- true when the player may order right now: at a counter, or anywhere with a catalog.
local function canOrderHere(src)
    if MCat.OfficeAt(src) then return true end
    return Config.CatalogItem.OrderAnywhere == true and hasCatalog(src)
end

--- Real seconds a parcel takes.
function MCat.DeliverySeconds()
    local d = Config.Delivery
    if d.Mode == 'minutes' then
        return math.max(0, math.floor((tonumber(d.Minutes) or 0) * 60 + 0.5))
    end
    return math.max(0, math.floor((tonumber(d.GameDays) or 1) * (tonumber(d.GameDayMinutes) or 48) * 60 + 0.5))
end

--- "how long" text for the order page.
local function deliveryText()
    local d = Config.Delivery
    if d.Mode == 'minutes' then return _L('delivery_minutes', math.max(1, math.ceil(tonumber(d.Minutes) or 0))) end
    local days = tonumber(d.GameDays) or 1
    if days == 1 then return _L('delivery_day') end
    return _L('delivery_days', days)
end

--- "arrives in about ..." for one order still on the way.
local function etaText(secondsLeft)
    if secondsLeft <= 60 then return _L('eta_soon') end
    local d = Config.Delivery
    if d.Mode == 'minutes' then return _L('eta_minutes', math.ceil(secondsLeft / 60)) end
    local dayLen = (tonumber(d.GameDayMinutes) or 48) * 60
    local hours = math.ceil(secondsLeft / dayLen * 24)
    return _L('eta_hours', math.max(1, hours))
end

---------------------------------
-- spam guard
---------------------------------
local function limited(src)
    local now = GetGameTimer()
    local keep = {}
    for _, t in ipairs(calls[src] or {}) do
        if now - t < Config.RateLimit.WindowMs then keep[#keep + 1] = t end
    end
    if #keep >= Config.RateLimit.Calls then
        calls[src] = keep
        return true
    end
    keep[#keep + 1] = now
    calls[src] = keep
    return false
end

---------------------------------
-- orders
---------------------------------
local function decode(s)
    local ok, t = pcall(json.decode, s or '[]')
    return ok and type(t) == 'table' and t or {}
end

local function lineView(l)
    local e = MCat.ByName[l.name]
    local label, image = e and e.label, e and e.image
    if not label then
        local ok, def = pcall(function() return exports.MULTIinventory:GetItemDef(l.name) end)
        if ok and def then label, image = def.label, def.image end
    end
    return { name = l.name, label = label or l.name, image = image or (l.name .. '.png'), amount = tonumber(l.amount) or 0 }
end

--- Orders not yet collected count against MaxOpenOrders.
local function openCount(citizenid)
    return tonumber(MySQL.scalar.await("SELECT COUNT(*) FROM `multicore_catalog_orders` WHERE `citizenid` = ? AND `status` <> 'collected'",
        { citizenid })) or 0
end

--- The character's orders for the Orders tab (open ones, then the newest collected ones).
function MCat.Orders(citizenid, hereIdx)
    local now = os.time()
    local rows = MySQL.query.await([[SELECT `id`, `office`, `items`, `ordered`, `total`, `created`, `ready_at`, `status`, `collected_at`
        FROM `multicore_catalog_orders` WHERE `citizenid` = ? AND `status` <> 'collected' ORDER BY `id` DESC]], { citizenid }) or {}
    local done = MySQL.query.await([[SELECT `id`, `office`, `items`, `ordered`, `total`, `created`, `ready_at`, `status`, `collected_at`
        FROM `multicore_catalog_orders` WHERE `citizenid` = ? AND `status` = 'collected' ORDER BY `collected_at` DESC, `id` DESC LIMIT ?]],
        { citizenid, math.max(0, tonumber(Config.ShowCollected) or 0) }) or {}
    for _, r in ipairs(done) do rows[#rows + 1] = r end
    local here = hereIdx and Config.Offices[hereIdx] and Config.Offices[hereIdx].id or nil
    local out = {}
    for _, r in ipairs(rows) do
        local readyAt = tonumber(r.ready_at) or 0
        local status = r.status
        if status ~= 'collected' then status = readyAt <= now and 'arrived' or 'transit' end
        local lines, ordered = {}, {}
        for _, l in ipairs(decode(r.items)) do lines[#lines + 1] = lineView(l) end
        for _, l in ipairs(decode(r.ordered)) do ordered[#ordered + 1] = lineView(l) end
        out[#out + 1] = {
            id = tonumber(r.id),
            office = r.office,
            officeLabel = officeLabel(r.office),
            lines = status == 'collected' and ordered or lines,
            partial = status ~= 'collected' and #lines < #ordered,
            total = tonumber(r.total) or 0,
            status = status,
            eta = status == 'transit' and etaText(readyAt - now) or nil,
            date = os.date('%d.%m.%Y', tonumber(r.created) or now),
            canCollect = status == 'arrived' and here ~= nil and here == r.office,
        }
    end
    return out
end

--- A player orders. lines = { { name, amount }, ... }, officeId = where the parcel goes.
--- Returns true, { id, total, office, readyAt } or false, err.
function MCat.Order(src, lines, officeId)
    src = tonumber(src)
    if not ready then return false, 'not_ready' end
    local citizenid = citizenOf(src)
    if not citizenid then return false, 'failed' end
    if limited(src) then return false, 'slow_down' end
    if not canOrderHere(src) then return false, 'not_at_office' end

    local cd = (tonumber(Config.OrderCooldownSeconds) or 0)
    if lastOrder[src] and GetGameTimer() - lastOrder[src] < cd * 1000 then return false, 'wait' end

    local office = type(officeId) == 'string' and officeById(officeId) or nil
    if not office then return false, 'bad_office' end

    if type(lines) ~= 'table' then return false, 'empty' end
    local L = Config.Limits
    local merged, order, units, total = {}, {}, 0, 0
    local scanned = 0
    for _, l in pairs(lines) do
        scanned = scanned + 1
        if scanned > 100 then return false, 'too_many_lines' end
        if type(l) ~= 'table' then return false, 'failed' end
        local name = type(l.name) == 'string' and l.name:lower() or ''
        local amount = tonumber(l.amount)
        if not amount or amount ~= math.floor(amount) or amount < 1 then return false, 'bad_amount' end
        local e = MCat.ByName[name]
        if not e then return false, 'not_sold' end
        if not merged[name] then
            merged[name] = 0
            order[#order + 1] = name
        end
        merged[name] = merged[name] + amount
    end
    if #order == 0 then return false, 'empty' end
    if #order > L.MaxLinesPerOrder then return false, 'too_many_lines' end
    local out = {}
    for _, name in ipairs(order) do
        local amount = merged[name]
        if amount > L.MaxPerLine then return false, 'too_many_each' end
        units = units + amount
        total = total + MCat.ByName[name].price * amount
        out[#out + 1] = { name = name, amount = amount }
    end
    if units > L.MaxUnitsPerOrder then return false, 'too_many_units' end
    total = round2(total)

    if openCount(citizenid) >= L.MaxOpenOrders then return false, 'too_many_orders' end

    if total > 0 and not MC.RemoveMoney(src, total, Config.Currency, 'catalog order') then return false, 'no_cash' end

    local now = os.time()
    local readyAt = now + MCat.DeliverySeconds()
    local itemsJson = json.encode(out)
    local id = MySQL.insert.await([[INSERT INTO `multicore_catalog_orders`
        (`citizenid`, `office`, `items`, `ordered`, `total`, `created`, `ready_at`, `status`) VALUES (?, ?, ?, ?, ?, ?, ?, 'transit')]],
        { citizenid, office.id, itemsJson, itemsJson, total, now, readyAt })
    if not id then
        if total > 0 then MC.AddMoney(src, total, Config.Currency, 'catalog order refund') end
        return false, 'failed'
    end
    lastOrder[src] = GetGameTimer()
    dbg(('order #%d by %s: %s to %s, $%s'):format(id, citizenid, itemsJson, office.id, money(total)))
    TriggerEvent('MULTIcatalog:ordered', src, id, office.id, total)
    return true, { id = id, total = total, office = office.id, readyAt = readyAt }
end

--- Collects a parcel at the counter the player stands at. Goods that do not fit stay in the parcel.
--- Returns true, { given = { {name,label,amount} }, left = n } or false, err, extra.
function MCat.Collect(src, id)
    src = tonumber(src)
    id = tonumber(id)
    if not ready then return false, 'not_ready' end
    local citizenid = citizenOf(src)
    if not citizenid or not id then return false, 'failed' end
    if limited(src) then return false, 'slow_down' end
    local idx = MCat.OfficeAt(src)
    if not idx then return false, 'not_at_office' end
    local here = Config.Offices[idx]

    local row = MySQL.single.await('SELECT `id`, `office`, `items`, `ready_at`, `status` FROM `multicore_catalog_orders` WHERE `id` = ? AND `citizenid` = ?',
        { id, citizenid })
    if not row or row.status == 'collected' then return false, 'not_found' end
    if row.status == 'collecting' then return false, 'slow_down' end
    if (tonumber(row.ready_at) or 0) > os.time() then return false, 'not_arrived' end
    if row.office ~= here.id then return false, 'wrong_office', officeLabel(row.office) end

    -- claim the parcel first, so it can never be handed out twice
    local claimed = MySQL.update.await([[UPDATE `multicore_catalog_orders` SET `status` = 'collecting'
        WHERE `id` = ? AND `citizenid` = ? AND `status` IN ('transit', 'arrived')]], { id, citizenid })
    if claimed ~= 1 then return false, 'slow_down' end

    local given, left = {}, {}
    for _, l in ipairs(decode(row.items)) do
        local amount = tonumber(l.amount) or 0
        if amount > 0 and MC.CanCarry(src, l.name, amount) and MC.GiveItem(src, l.name, amount) then
            local v = lineView(l)
            given[#given + 1] = v
        elseif amount > 0 then
            left[#left + 1] = { name = l.name, amount = amount }
        end
    end

    if #left == 0 then
        MySQL.update.await("UPDATE `multicore_catalog_orders` SET `status` = 'collected', `items` = '[]', `collected_at` = ? WHERE `id` = ?",
            { os.time(), id })
    else
        MySQL.update.await("UPDATE `multicore_catalog_orders` SET `status` = 'arrived', `items` = ? WHERE `id` = ?",
            { json.encode(left), id })
    end
    if #given == 0 then return false, 'no_space' end
    dbg(('order #%d collected by %s at %s, %d lines left'):format(id, citizenid, here.id, #left))
    TriggerEvent('MULTIcatalog:collected', src, id, #left)
    return true, { given = given, left = #left }
end

--- The clerk hands out a catalog to carry (one per player).
function MCat.TakeCatalog(src)
    src = tonumber(src)
    local CI = Config.CatalogItem
    if not CI.Enabled then return false, 'failed' end
    if not citizenOf(src) then return false, 'failed' end
    if limited(src) then return false, 'slow_down' end
    if not MCat.OfficeAt(src) then return false, 'not_at_office' end
    if hasCatalog(src) then return false, 'have_catalog' end
    if not MC.CanCarry(src, CI.Name, 1) then return false, 'no_space' end
    local price = round2(tonumber(CI.Price) or 0)
    if price > 0 and not MC.RemoveMoney(src, price, Config.Currency, 'catalog copy') then return false, 'no_cash' end
    if not MC.GiveItem(src, CI.Name, 1) then
        if price > 0 then MC.AddMoney(src, price, Config.Currency, 'catalog copy refund') end
        return false, 'no_space'
    end
    return true
end

---------------------------------
-- arrivals
---------------------------------
local function announce(citizenid, id, officeId)
    local label = officeLabel(officeId)
    local src = MC.GetSourceByCitizenId(citizenid)
    if src then notify(src, _L('notice_arrived', id, label), 'success') end
    if Config.Telegram.Enabled and GetResourceState('MULTItelegram') == 'started' then
        pcall(function()
            exports.MULTItelegram:SendTelegram(citizenid, _L('telegram_from'), _L('telegram_subject', id), _L('telegram_text', id, label), 'system')
        end)
    end
    TriggerEvent('MULTIcatalog:arrived', citizenid, id, officeId)
end

--- Marks parcels whose time has come as arrived and tells their owners. Returns how many.
function MCat.Tick()
    if not ready then return 0 end
    local rows = MySQL.query.await("SELECT `id`, `citizenid`, `office` FROM `multicore_catalog_orders` WHERE `status` = 'transit' AND `ready_at` <= ?",
        { os.time() }) or {}
    local n = 0
    for _, r in ipairs(rows) do
        local changed = MySQL.update.await("UPDATE `multicore_catalog_orders` SET `status` = 'arrived' WHERE `id` = ? AND `status` = 'transit'", { r.id })
        if changed == 1 then
            n = n + 1
            dbg(('order #%d arrived at %s'):format(r.id, r.office))
            announce(r.citizenid, tonumber(r.id), r.office)
        end
    end
    return n
end

---------------------------------
-- start
---------------------------------
CreateThread(function()
    while GetResourceState('MULTIinventory') ~= 'started' or not exports.MULTIinventory:IsReady() do Wait(250) end
    makeTables()
    cleanup()

    local CI = Config.CatalogItem
    if CI.Enabled then
        MC.RegisterItem({ name = CI.Name, label = _L('item_label'), weight = CI.Weight, description = _L('item_desc'),
            image = CI.Image, stack = true, useable = true })
        MC.RegisterUsableItem(CI.Name, function(src)
            TriggerClientEvent('MULTIcatalog:client:open', src, 'item')
        end)
    end

    local started = os.time()
    local missing, priced = buildCatalog(false)
    ready = true
    print(('[MULTIcatalog] ready: %d goods, %d post offices'):format(#MCat.Catalog, #Config.Offices))
    -- items other scripts register a little later, and the stores' prices once MULTIstores is up
    while (missing > 0 or (not priced and GetResourceState('MULTIstores') ~= 'missing')) and os.time() - started < (tonumber(Config.LateItemSeconds) or 60) do
        Wait(5000)
        missing, priced = buildCatalog(false)
    end
    buildCatalog(true)
    dbg(('%d goods in the catalog'):format(#MCat.Catalog))
end)

CreateThread(function()
    while not ready do Wait(500) end
    local lastClean = os.time()
    while true do
        MCat.Tick()
        if os.time() - lastClean > 3600 then
            cleanup()
            lastClean = os.time()
        end
        Wait(math.max(5, tonumber(Config.Delivery.CheckSeconds) or 30) * 1000)
    end
end)

-- after a character loads: say when parcels wait
MC.OnCharacterLoaded(function(src, citizenid)
    SetTimeout(tonumber(Config.LoginNoticeDelayMs) or 10000, function()
        if not ready or not citizenid then return end
        local cid = citizenOf(src)
        if cid ~= citizenid then return end
        local n = tonumber(MySQL.scalar.await("SELECT COUNT(*) FROM `multicore_catalog_orders` WHERE `citizenid` = ? AND `status` <> 'collected' AND `ready_at` <= ?",
            { citizenid, os.time() })) or 0
        if n > 0 then notify(src, _L('notice_waiting', n), 'info') end
    end)
end)

---------------------------------
-- the page
---------------------------------
function MCat.State(src)
    local citizenid = citizenOf(src)
    if not citizenid then return nil end
    local idx = MCat.OfficeAt(src)
    local offices = {}
    for _, o in ipairs(Config.Offices) do offices[#offices + 1] = { id = o.id, label = _L(o.label) } end
    local cats, seen = {}, {}
    for _, c in ipairs(Config.Categories or {}) do
        for _, e in ipairs(MCat.Catalog) do
            if e.category == c and not seen[c] then seen[c] = true cats[#cats + 1] = c end
        end
    end
    for _, e in ipairs(MCat.Catalog) do
        if not seen[e.category] then seen[e.category] = true cats[#cats + 1] = e.category end
    end
    local CI = Config.CatalogItem
    return {
        cash = MC.GetMoney(src, Config.Currency),
        sign = Config.CurrencySign,
        office = idx and { id = Config.Offices[idx].id, label = _L(Config.Offices[idx].label) } or nil,
        canOrder = canOrderHere(src),
        offices = offices,
        catalog = MCat.Catalog,
        categories = cats,
        orders = MCat.Orders(citizenid, idx),
        openCount = openCount(citizenid),
        limits = Config.Limits,
        delivery = deliveryText(),
        offerCatalog = (CI.Enabled and idx ~= nil and not hasCatalog(src)) and { price = round2(tonumber(CI.Price) or 0) } or nil,
    }
end

local function errText(err, extra)
    if err == 'wrong_office' then return _L('err_wrong_office', extra or '?') end
    if err == 'too_many_lines' then return _L('err_too_many_lines', Config.Limits.MaxLinesPerOrder) end
    if err == 'too_many_each' then return _L('err_too_many_each', Config.Limits.MaxPerLine) end
    if err == 'too_many_units' then return _L('err_too_many_units', Config.Limits.MaxUnitsPerOrder) end
    if err == 'too_many_orders' then return _L('err_too_many_orders', Config.Limits.MaxOpenOrders) end
    return _L('err_' .. tostring(err or 'failed'))
end
MCat.ErrText = errText

lib.callback.register('MULTIcatalog:open', function(src)
    if not ready then return false, errText('not_ready') end
    if not citizenOf(src) then return false end
    if not MCat.OfficeAt(src) and not hasCatalog(src) then return false, errText('not_at_office') end
    return true, MCat.State(src)
end)

lib.callback.register('MULTIcatalog:action', function(src, action, data)
    if type(data) ~= 'table' then data = {} end
    local ok, res, extra
    if action == 'order' then
        ok, res = MCat.Order(src, data.lines, data.office)
        if ok then res = _L('ordered', res.id, money(res.total), officeLabel(res.office)) end
    elseif action == 'collect' then
        ok, res, extra = MCat.Collect(src, data.id)
        if ok then
            local parts = {}
            for _, g in ipairs(res.given) do parts[#parts + 1] = ('%dx %s'):format(g.amount, g.label) end
            res = _L(res.left > 0 and 'collected_part' or 'collected', table.concat(parts, ', '))
        end
    elseif action == 'take_catalog' then
        ok, res = MCat.TakeCatalog(src)
        if ok then res = _L('took_catalog') end
    elseif action == 'refresh' then
        ok = true
    else
        return { ok = false, msg = errText('failed') }
    end
    local out = { ok = ok == true, state = MCat.State(src) }
    if ok then
        out.msg = type(res) == 'string' and res or nil
    else
        out.msg = errText(res, extra)
    end
    return out
end)

---------------------------------
-- clean-up
---------------------------------
local function forget(src)
    calls[src], lastOrder[src], officeOverride[src] = nil, nil, nil
end
AddEventHandler('playerDropped', function() forget(source) end)

AddEventHandler('MULTIcore:characterDeleted', function(_, citizenid)
    if type(citizenid) ~= 'string' then return end
    MySQL.update('DELETE FROM `multicore_catalog_orders` WHERE `citizenid` = ?', { citizenid })
end)

---------------------------------
-- exports (server)
---------------------------------
exports('IsReady', function() return ready end)
exports('GetCatalog', function() return MCat.Catalog end)                    -- { name, label, desc, image, price, category }
exports('GetOrders', function(citizenid) return MCat.Orders(citizenid) end)  -- the Orders tab rows
exports('Order', MCat.Order)                                                 -- (src, { {name, amount} }, officeId) -> ok, { id, total, office, readyAt } | err
exports('Collect', MCat.Collect)                                             -- (src, orderId) -> ok, { given, left } | err, extra
exports('DeliverySeconds', MCat.DeliverySeconds)

---------------------------------
-- self-test hooks (only with  setr multicore_selftest true)
---------------------------------
if MCat.SELFTEST then
    --- Pretend the player stands at office `idx` (false = nowhere, nil = use the real position).
    exports('_TestSetOffice', function(src, idx) officeOverride[tonumber(src)] = idx; return true end)
    --- Changes one config value ('Delivery.Minutes' style paths reach into tables).
    exports('_TestConfig', function(key, value)
        local t, last = Config, nil
        for part in tostring(key):gmatch('[^%.]+') do
            if last then t = t[last] end
            last = part
        end
        t[last] = value
        return true
    end)
    --- Clears the spam guard and order cooldown of one pretend player.
    exports('_TestReset', function(src) calls[tonumber(src)], lastOrder[tonumber(src)] = nil, nil; return true end)
    exports('_TestTick', function() return MCat.Tick() end)
    exports('_TestState', function(src) return MCat.State(src) end)
    exports('_TestTakeCatalog', function(src) calls[tonumber(src)] = nil; return MCat.TakeCatalog(src) end)
    exports('_TestRebuild', function() return buildCatalog(true) end)
end
