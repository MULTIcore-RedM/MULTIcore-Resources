-- ============================================================
-- MULTIcatalog settings (part of MULTIcore by RINGO (RINGOscripting), GPL v3)
-- What the catalog sells is in config/items.lua, the post offices in
-- config/offices.lua. One line of explanation per setting.
-- ============================================================
Config = {}

Config.Locale = ''                  -- default '' (language for this script; empty = MULTIcore's language (MULTIConfig.Language), else English)
Config.Debug = false                -- default false (prints every order, arrival and collection to the server console)
Config.NotifyDuration = 6000        -- default 6000 (how long catalog notifications stay on screen, ms)

---------------------------------
-- money
---------------------------------
Config.Currency = 'cash'            -- default 'cash' (MULTIcore money type players pay with)
Config.CurrencySign = '$'           -- default '$' (money sign on the catalog page)

---------------------------------
-- delivery
---------------------------------
-- The parcel is paid for at once and waits at the post office the player picked,
-- once the delivery time has passed. Times run on the real clock, so they also run
-- while the server is off.
Config.Delivery = {
    Mode = 'gameday',               -- default 'gameday' ('gameday' = GameDays in-game days; 'minutes' = Minutes real minutes)
    GameDays = 1,                   -- default 1 (in-game days a parcel takes, 'gameday' mode)
    GameDayMinutes = 48,            -- default 48 (real minutes in one in-game day; 48 = the game's own clock speed, MULTIweather Time.MinuteSeconds 2.0)
    Minutes = 30,                   -- default 30 (real minutes a parcel takes, 'minutes' mode)
    CheckSeconds = 30,              -- default 30 (how often the server looks for parcels that have arrived)
}

---------------------------------
-- limits
---------------------------------
Config.Limits = {
    MaxUnitsPerOrder = 20,          -- default 20 (most items in one order, all lines together)
    MaxLinesPerOrder = 8,           -- default 8 (most different goods in one order)
    MaxPerLine = 10,                -- default 10 (most of one good in one order)
    MaxOpenOrders = 3,              -- default 3 (orders a character may have on the way or waiting at the same time)
}
Config.OrderCooldownSeconds = 10    -- default 10 (time between two orders by the same player)
Config.KeepCollectedDays = 7        -- default 7 (collected orders are kept this many days for the Orders tab, then deleted; 0 = keep)
Config.ShowCollected = 5            -- default 5 (newest collected orders shown on the Orders tab)

---------------------------------
-- the catalog item (a copy of the catalog the player can carry)
---------------------------------
Config.CatalogItem = {
    Enabled = true,                 -- default true (the clerk hands out a catalog; using it opens the catalog anywhere)
    Name = 'mail_order_catalog',    -- default 'mail_order_catalog' (item name, registered at start, no SQL needed)
    Weight = 300,                   -- default 300 (grams)
    Image = 'mail_order_catalog.png', -- default 'mail_order_catalog.png' (picture in MULTIimages/images; without one the inventory shows its placeholder)
    Price = 0.0,                    -- default 0.0 (cash for a copy; 0 = free, as the big catalogs of the day were)
    OrderAnywhere = true,           -- default true (with the catalog in the satchel a player may order anywhere; false = only browse, order at a counter)
}

---------------------------------
-- telegram on arrival
---------------------------------
Config.Telegram = {
    Enabled = true,                 -- default true (when MULTItelegram runs, the owner gets a telegram when the parcel arrives)
}
Config.LoginNoticeDelayMs = 10000   -- default 10000 (after a character loads, wait this long, then tell them about parcels waiting)

---------------------------------
-- how players open the catalog at a post office
---------------------------------
Config.Interact = 'auto'            -- default 'auto' ('auto' = MULTItarget when it runs, else hold-key prompt; 'target' = MULTItarget; 'prompt' = hold-key prompt)
Config.PromptKey = 'G'              -- default 'G' (key name from MULTIcore's shared/keybinds.lua; prompt mode only; J is MULTItelegram's at the same counter)
Config.PromptDistance = 2.0         -- default 2.0 (metres; prompt mode only)
Config.TargetIcon = 'fas fa-book-open' -- default 'fas fa-book-open' (MULTItarget icon; target mode only)
Config.TargetRadius = 1.2           -- default 1.2 (size of the MULTItarget sphere on the counter; target mode only)
Config.TargetDistance = 2.0         -- default 2.0 (metres; target mode only)
Config.MaxUseDistance = 6.0         -- default 6.0 (the server refuses counter actions further than this from a counter, metres; needs OneSync)
Config.CheckIntervalMs = 1000       -- default 1000 (how often the client checks that the player is still at the counter, ms)

---------------------------------
-- spam guard
---------------------------------
Config.RateLimit = {
    Calls = 8,                      -- default 8 (at most this many catalog actions ...)
    WindowMs = 4000,                -- default 4000 (... in this many ms, per player)
}

---------------------------------
-- item pictures
---------------------------------
Config.ImagePaths = nil             -- default nil (nil = MULTIinventory's picture folders; or a list of nui:// folders)

---------------------------------
-- start-up
---------------------------------
Config.LateItemSeconds = 60         -- default 60 (items other MULTI scripts register a moment after start are looked for this long)
