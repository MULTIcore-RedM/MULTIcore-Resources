-- ============================================================
-- MULTIbelt :: server
-- Part of MULTIcore by RINGO (RINGOscripting). GPL v3.
--
-- Players write their own `multibelt` state bag (a short list of Config.Items
-- numbers). The server only throws away anything that isn't such a list, so a
-- modified client can't push junk to everyone else.
-- ============================================================

local STATE_KEY = 'multibelt'
local maxEntry = #(Config.Items or {})

local function clean(value)
    if type(value) ~= 'table' or #value > maxEntry then return {} end
    local out, seen = {}, {}
    for _, n in ipairs(value) do
        n = math.tointeger(tonumber(n))
        if n and n >= 1 and n <= maxEntry and not seen[n] then
            seen[n] = true
            out[#out + 1] = n
        end
    end
    return out
end

local function sameList(a, b)
    if type(a) ~= 'table' or #a ~= #b then return false end
    for i = 1, #b do if a[i] ~= b[i] then return false end end
    return true
end

AddStateBagChangeHandler(STATE_KEY, nil, function(bagName, _, value, _, replicated)
    if not replicated then return end
    local src = GetPlayerFromStateBagName(bagName)
    if not src or src == 0 then return end
    local fixed = clean(value)
    if not sameList(value, fixed) then
        Player(src).state:set(STATE_KEY, fixed, true)
    end
end)
