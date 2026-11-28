# MULTIcore Resources

**MULTIcore was founded and created by RINGO (RINGOscripting).**

The MULTI scripts for a **MULTIcore** server, and the item pictures. The base server (the core, login, character creator, inventory, HUD, target, chat, voice, weather and admin) is at https://github.com/MULTIcore-RedM/MULTIcore-Server.

The base server and these scripts are kept in two repositories so each download is small. That way txAdmin's recipe can install them on slower connections too.

## Installing

You don't need to download this repository yourself:
- **txAdmin recipe:** installs the base server and `resources/[multicore-resources]` together.
- **MULTIcore-Server.zip** from the base server's Releases page: has both already.

See the base server's README for both ways. Its `server.cfg.example` already starts every script below.

To add these by hand to a server you set up yourself: copy `resources/[multicore-resources]` into your server's `resources` folder, and copy the `ensure` lines from the base server's `server.cfg.example`.

## resources/[multicore-resources]

| Script | What it does |
|---|---|
| MULTIimages | The item picture folder: 1,033 pictures for MULTIinventory, MULTIstores and the inventory stand-ins. Add your own `.png` files in `MULTIimages/images/` |
| MULTIhelpers | Stands in for the small menu, input, progress bar and notification resources (vorp_menu, vorp_inputs, rsg-input, rsg-menu, progressbar and more) |
| MULTIstores | General stores, gunsmiths, butchers, trappers, doctors and saloons |
| MULTItailor | Clothing as items, with a tailor job (answers as rsg-wardrobe) |
| MULTIconsumables | Food, drink, tobacco and medicine, with drunkenness and addictions |
| MULTIbank | Banks: deposit, withdraw, transfer, gold exchange, passbook |
| MULTIjobs | Job centres, several jobs per character, boss and gang menus, duty |
| MULTImedic | Death, respawn and medics (answers as rsg-medic) |
| MULTIcoroner | Coroner inquests |
| MULTIcamps | Player camps |
| MULTIcrafting | Crafting |
| MULTIdoors | Door locks for every door in the game |
| MULTIemotes | Emote menu, walk styles (F5) |
| MULTIgathering | Herbs, lumber and mining |
| MULTIfarming | Farming |
| MULTIhorses | Horses and stables (answers as rsg-horses) |
| MULTIhunting | Hunting |
| MULTIlaw | Lawmen, jail and prison (answers as rsg-lawman and rsg-prison) |
| MULTIradial | The quick menu (F6) |
| MULTItelegram | Telegrams and parcels at the post office |
| MULTIcatalog | Mail-order catalog: order everyday goods, collect the parcel at the post office |
| MULTIhouses | Houses: buy, pay off, land tax, guest keys, stash, wardrobe |
| MULTIhotel | Hotel rooms |
| MULTIbathing | Bath houses |
| MULTIvendor | Vendor NPCs who buy goods from your satchel |
| MULTIwagons | Owned wagons |
| MULTIrobberies | Store tills and bank vaults: lockpick, pipe charge, safes |

## resources/[multicore-addons]

Optional extra scripts, **not** installed by the recipe. Pick the ones you want:
1. Copy the script's folder from `resources/[multicore-addons]` into your server's `resources` folder.
2. Add `ensure <ScriptName>` to `server.cfg`, **below** the MULTI scripts.
3. Restart the server. Each script makes its own database tables on the first start. Its README lists anything else it needs.

| Script | What it does |
|---|---|
| [MULTIbelt](resources/%5Bmulticore-addons%5D/MULTIbelt) | Carried tools (lantern, lasso, machete, metal detector, arrows) show on the belt and back while they are not in your hand. |

## Licence and credits

GPL-3.0 (see `LICENSE`). If you share a changed copy, keep the credits and licence notices. Copyright (C) 2026 RINGO (RINGOscripting).

These scripts were written for MULTIcore by RINGO, with these exceptions:
- **MULTIcoroner** is based on **phils-coroner by Phil**.
- **MULTIhorses** is based on **rsg-horses by Phil**.
- **MULTIwagons** is based on **rsg-wagons by Phil**, with wagon work by **Mack**.
- **MULTIvendor** is by **Mack**.

All four are renamed and fitted to MULTIcore with permission. Each script's `CREDITS.md` names any RSG v2 code it builds on.

The **item pictures** in MULTIimages are by **Tankie** (The Icon Library Project, https://github.com/TankieTwitch/FREE-RedM-Image-Library). They are free to use, and Tankie keeps the rights to them.
