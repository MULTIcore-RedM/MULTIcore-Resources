# Changelog

*MULTIcore was founded and created by RINGO (RINGOscripting).*

## 2026-11-28
- **MULTIcatalog** added (free): a mail-order catalog at every post office counter. Order everyday goods (food, coffee, tobacco, bandages, simple tools, camp goods, horse care, bait and seeds) and pay at once. The parcel waits at the post office you picked after one in-game day (or a set number of real minutes). Goods that do not fit stay in the parcel until you have room. The clerk hands out a free catalog you can carry and order from anywhere. Prices are about a quarter above the general store. 32 languages; classic, parchment and modern looks. Add `ensure MULTIcatalog` after `ensure MULTItelegram`.
- **In-game settings:** MULTIstores (price and pay-out multipliers, selling, most per purchase, restock, opening hours), MULTIjobs (boss pay limits, idle off-duty minutes), MULTIbank (fees) and MULTImedic (respawn timer) can be changed from MULTIadmin's Settings page while the server runs. Needs the MULTIcore and MULTIadmin of 2026-11-28 from MULTIcore-Server.

## 2026-11-27 (the MULTI scripts move here from MULTIcore-Server)
- **`resources/[multicore-resources]`**: 25 MULTI scripts and the item pictures (MULTIimages) moved here from MULTIcore-Server, unchanged: MULTIbank, MULTIbathing, MULTIcamps, MULTIconsumables, MULTIcoroner, MULTIcrafting, MULTIdoors, MULTIemotes, MULTIfarming, MULTIgathering, MULTIhelpers, MULTIhorses, MULTIhotel, MULTIhouses, MULTIhunting, MULTIimages, MULTIjobs, MULTIlaw, MULTImedic, MULTIradial, MULTIrobberies, MULTIstores, MULTItailor, MULTItelegram, MULTIvendor and MULTIwagons.
  - MULTIcore-Server now holds only the base server. Two smaller downloads let txAdmin's recipe install MULTIcore again on slower connections. The recipe installs both, and MULTIcore-Server.zip still has everything.
- `resources/[multicore-addons]` stays optional and is not installed by the recipe.

## 2026-11-25
- **MULTIbelt** added: a lantern, Davy lantern, metal detector, lasso or machete you carry shows on your belt while it is not in your hand, and an arrow bundle sits on your back while you carry a bow. Everyone near you sees it. Needs no database or items.

## 2026-11-22
- MULTIcore Resources started: the home for MULTIcore's optional extra scripts.
