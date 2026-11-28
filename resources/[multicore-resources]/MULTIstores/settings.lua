-- ============================================================
-- MULTIstores :: values an admin can change in game (MULTIadmin, Settings page)
-- The values in config.lua are the defaults; a value changed in game is kept by
-- MULTIcore (table multicore_settings) and applied live. Labels: locales/*.lua.
-- ============================================================

-- open store screens show the new prices at once
local function refreshOpen()
    if IsDuplicityVersion() and MS and MS.Sessions then
        for src in pairs(MS.Sessions) do MS.PushState(src) end
    end
end

MCSettings.Register({
    { key = 'MULTIstores.PriceMultiplier', type = 'number', default = Config.PriceMultiplier or 1.0, min = 0.1, max = 10.0, step = 0.05, unit = 'x',
      label = 'set_price_multiplier', category = 'setcat_prices',
      apply = function(v) Config.PriceMultiplier = v refreshOpen() end },
    { key = 'MULTIstores.PayMultiplier', type = 'number', default = Config.Sell.PayMultiplier or 1.0, min = 0.0, max = 10.0, step = 0.05, unit = 'x',
      label = 'set_pay_multiplier', category = 'setcat_prices',
      apply = function(v) Config.Sell.PayMultiplier = v refreshOpen() end },
    { key = 'MULTIstores.SellEnabled', type = 'bool', default = Config.Sell.Enabled == true,
      label = 'set_sell_enabled', category = 'setcat_prices',
      apply = function(v) Config.Sell.Enabled = v refreshOpen() end },
    { key = 'MULTIstores.MaxPerPurchase', type = 'number', integer = true, default = Config.MaxPerPurchase, min = 1, max = 1000, step = 1, client = true,
      label = 'set_max_per_purchase', category = 'setcat_prices',
      apply = function(v) Config.MaxPerPurchase = v end },
    { key = 'MULTIstores.RestockMinutes', type = 'number', integer = true, default = Config.Restock.Minutes, min = 0, max = 1440, step = 5, unit = 'set_unit_min',
      label = 'set_restock_minutes', category = 'setcat_prices',
      apply = function(v) Config.Restock.Minutes = v end },
    { key = 'MULTIstores.HoursEnabled', type = 'bool', default = Config.Hours.Enabled == true, client = true,
      label = 'set_hours_enabled', category = 'setcat_hours',
      apply = function(v) Config.Hours.Enabled = v end },
    { key = 'MULTIstores.HoursOpen', type = 'number', integer = true, default = Config.Hours.Open, min = 0, max = 23, step = 1, client = true,
      label = 'set_hours_open', category = 'setcat_hours',
      apply = function(v) Config.Hours.Open = v end },
    { key = 'MULTIstores.HoursClose', type = 'number', integer = true, default = Config.Hours.Close, min = 0, max = 23, step = 1, client = true,
      label = 'set_hours_close', category = 'setcat_hours',
      apply = function(v) Config.Hours.Close = v end },
})
