-- ============================================================
-- MULTIbank :: values an admin can change in game (MULTIadmin, Settings page)
-- The values in config.lua are the defaults; a value changed in game is kept by
-- MULTIcore (table multicore_settings) and applied live. Labels: locales/*.lua.
-- ============================================================

MCSettings.Register({
    { key = 'MULTIbank.WithdrawFeePercent', type = 'number', default = Config.WithdrawFeePercent or 0, min = 0, max = 50, step = 0.5, unit = '%',
      label = 'set_withdraw_fee', category = 'setcat_fees',
      apply = function(v) Config.WithdrawFeePercent = v end },
    { key = 'MULTIbank.TransferFeePercent', type = 'number', default = Config.TransferFeePercent or 0, min = 0, max = 50, step = 0.5, unit = '%',
      label = 'set_transfer_fee', category = 'setcat_fees',
      apply = function(v) Config.TransferFeePercent = v end },
})
