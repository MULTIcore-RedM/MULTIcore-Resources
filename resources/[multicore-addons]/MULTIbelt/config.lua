-- ============================================================
-- MULTIbelt :: settings
-- Part of MULTIcore by RINGO (RINGOscripting). GPL v3.
--
-- Each entry puts one prop on the body while the player carries one of
-- its weapons and is not holding it.
--
--   weapons = weapon names that show this prop (one or more)
--   model   = the prop drawn on the body
--   bone    = where it hangs: { male = 'bone', female = 'bone' or nil (same as male) }
--   pos     = { male = { x, y, z, rx, ry, rz }, female = {...} or nil (same as male) }
--             x/y/z move it from the bone in metres, rx/ry/rz turn it in degrees.
--             Move in small steps (0.01 - 0.05) and turn in 5 - 10 degree steps.
--   always  = true: keep showing it even while the weapon is in the hand
--             (the quiver stays on the back while you hold the bow)
--   enabled = false to switch one entry off without deleting it
--
-- Bone names: SKEL_L_Thigh / SKEL_R_Thigh (hips), PH_Lantern (lantern hook),
-- CP_Back (back), SKEL_Spine3 (upper back), SKEL_Pelvis.
-- ============================================================

Config = {}

-- How often (ms) a player's own weapons are checked. Lower = quicker, a little more work.
Config.CheckMs = 300

-- Props are drawn on other players within this many metres.
Config.DrawDistance = 80.0

-- Hide a player's belt props while that player is invisible (admin noclip / spectate).
Config.HideWhenInvisible = true

Config.Items = {
    -- Lanterns hang on the lantern hook at the hip
    {
        weapons = { 'WEAPON_MELEE_LANTERN' },
        model = 's_interact_lantern01x',
        bone = { male = 'PH_Lantern' },
        pos = { male = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 } },
    },
    {
        weapons = { 'WEAPON_MELEE_DAVY_LANTERN' },
        model = 's_interact_lantern02x',
        bone = { male = 'PH_Lantern' },
        pos = { male = { -0.05, 0.0, 0.0, 0.0, 0.0, 0.0 } },
    },
    {
        weapons = { 'WEAPON_KIT_METAL_DETECTOR' },
        model = 'mp005_s_interact_detectorm01x',
        bone = { male = 'PH_Lantern' },
        pos = { male = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 } },
    },

    -- Lasso coiled on the left hip
    {
        weapons = { 'WEAPON_LASSO', 'WEAPON_LASSO_REINFORCED' },
        model = 'p_cs_melee_lasso01',
        bone = { male = 'SKEL_L_Thigh', female = 'skel_l_thigh' },
        pos = { male = { 0.0, 0.0, -0.11, -83.0, 0.0, 80.0 } },
    },

    -- Machete on the left hip
    {
        weapons = { 'WEAPON_MELEE_MACHETE' },
        model = 'p_machete01x',
        bone = { male = 'SKEL_L_Thigh', female = 'skel_l_thigh' },
        pos = { male = { 0.0, 0.0, -0.11, 0.0, 0.0, 120.0 } },
    },

    -- Arrow bundle on the back for any bow
    {
        weapons = { 'WEAPON_BOW', 'WEAPON_BOW_IMPROVED' },
        model = 'p_arrowbundle01x',
        bone = { male = 'CP_Back', female = 'CP_Back' },
        pos = { male = { -0.30, 0.0, 0.0, 0.0, -10.0, 100.0 } },
        always = true,
    },
}
