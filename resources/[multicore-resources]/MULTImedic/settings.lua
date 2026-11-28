-- ============================================================
-- MULTImedic :: values an admin can change in game (MULTIadmin, Settings page)
-- The values in config.lua are the defaults; a value changed in game is kept by
-- MULTIcore (table multicore_settings) and applied live. Labels: locales/*.lua.
-- ============================================================

MCSettings.Register({
    { key = 'MULTImedic.RespawnTimer', type = 'number', integer = true, default = Config.RespawnTimer, min = 10, max = 3600, step = 10, client = true,
      unit = 'set_unit_sec', label = 'set_respawn_timer', category = 'setcat_death',
      apply = function(v) Config.RespawnTimer = v end },
})
