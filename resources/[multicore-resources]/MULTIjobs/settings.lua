-- ============================================================
-- MULTIjobs :: values an admin can change in game (MULTIadmin, Settings page)
-- The values in config.lua are the defaults; a value changed in game is kept by
-- MULTIcore (table multicore_settings) and applied live. Labels: locales/*.lua.
-- Wages themselves (pay per grade, paycheck time, wage multiplier) are MULTIcore's.
-- ============================================================

MCSettings.Register({
    { key = 'MULTIjobs.BossPayMin', type = 'number', default = Config.BossMenu.Pay.Min, min = 0, max = 100, step = 0.05,
      label = 'set_boss_pay_min', category = 'setcat_bosspay',
      apply = function(v) Config.BossMenu.Pay.Min = v end },
    { key = 'MULTIjobs.BossPayMax', type = 'number', default = Config.BossMenu.Pay.Max, min = 0, max = 100, step = 0.05,
      label = 'set_boss_pay_max', category = 'setcat_bosspay',
      apply = function(v) Config.BossMenu.Pay.Max = v end },
    { key = 'MULTIjobs.AfkMinutes', type = 'number', integer = true, default = Config.Duty.AfkMinutes, min = 0, max = 240, step = 1, client = true,
      unit = 'set_unit_min', label = 'set_afk_minutes', category = 'setcat_duty',
      apply = function(v) Config.Duty.AfkMinutes = v end },
})
