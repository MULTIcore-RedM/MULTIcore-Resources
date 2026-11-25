# MULTIbelt

Part of MULTIcore by RINGO (RINGOscripting).

Carried tools show on the body while they are not in your hand:
- the lantern, Davy lantern and metal detector hang on the hip hook;
- the lasso and the machete sit on the left hip;
- an arrow bundle sits on the back whenever you carry a bow, even while you hold it.

When you take the item in your hand, the one on your belt goes away, and it comes back when you put the item away. Everyone near you sees the same.

## Install
1. Put `MULTIbelt` in your resources folder.
2. Add `ensure MULTIbelt` to `server.cfg`, after `MULTIcore` and `MULTIinventory`.

It needs no database and no items. It works with any inventory, because it looks at the weapons the character carries.

## Settings (`config.lua`)
| Setting | What it does |
|---|---|
| `Config.CheckMs` | How often (ms) your own weapons are checked. Default 300. |
| `Config.DrawDistance` | Belt props are drawn on players within this many metres. Default 80. |
| `Config.HideWhenInvisible` | Hide a player's belt props while that player is invisible (admin noclip). |
| `Config.Items` | One entry per prop. See below. |

### Adding a prop
Add an entry to `Config.Items`:

```lua
{
    weapons = { 'WEAPON_MELEE_KNIFE' },           -- one or more weapon names
    model = 'w_melee_knife02',                    -- the prop to draw
    bone = { male = 'SKEL_R_Thigh' },             -- female = nil uses the male bone
    pos = { male = { 0.0, 0.0, -0.11, -83.0, 0.0, 80.0 } }, -- x, y, z, turn x, y, z
    always = false,                               -- true = show it even in the hand
},
```

- `pos.female` and `bone.female` are optional; leave them out to use the male values.
- `enabled = false` switches an entry off without deleting it.
- Move the prop in small steps (0.01 to 0.05) and turn it 5 to 10 degrees at a time. Check it on a male and a female character, standing, walking and riding.

Useful bones: `SKEL_L_Thigh` / `SKEL_R_Thigh` (hips), `PH_Lantern` (lantern hook), `CP_Back` (back), `SKEL_Spine3` (upper back), `SKEL_Pelvis`.

## How it syncs
Each player's client works out which props it should show and puts that short list in its player state. Every client draws its own copy of the props on the players near it. No objects are networked, so nothing is left floating when a player leaves or the resource restarts, and players who join later see everyone's props straight away.

## Licence
GPL v3, as part of MULTIcore.
