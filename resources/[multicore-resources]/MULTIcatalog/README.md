# MULTIcatalog

A mail-order catalog for MULTIcore servers, like the big general-goods catalogs of the 1890s. Players order everyday goods, pay at once, and collect the parcel at the post office they picked.

GPL v3, like MULTIcore. Part of MULTIcore by RINGO (RINGOscripting).

## What it does

- **Open the catalog** at any post office counter (MULTItarget "Mail-order catalog", or hold `G` without MULTItarget). The counters are the same twelve as MULTItelegram's.
- **A catalog to carry.** The clerk hands out a free catalog (one each). Using it opens the catalog anywhere, and the player can order from it (`Config.CatalogItem`).
- **Only everyday goods**: food, coffee, tobacco, bandages, simple tools, camp goods, horse care, bait, seeds. No weapons, no ammunition, no horses, no rare items.
- **Pay when ordering.** The money is taken at once. The page shows the total and how many items are on the order form.
- **Delivery takes time.** By default one in-game day (48 real minutes). The parcel then waits at the office the player picked.
- **Arrival notice.** An online player is told when the parcel arrives. With MULTItelegram running they also get a telegram. Players who were offline are told on their next login.
- **Collect at the counter.** Goods that do not fit in the satchel stay in the parcel until the player has room.
- **Orders tab.** Parcels on the way (with a rough arrival time), waiting, and the last few collected.
- **Orders are saved** in the `multicore_catalog_orders` table (made on first start). They survive restarts, and delivery time keeps running while the server is off.

## Safety

- The server decides everything: distance to the counter, the price (from config), the limits, the cash (the order is refused when `RemoveMoney` fails), room in the satchel, a cooldown and a spam guard.
- Only goods listed in `config/items.lua` can be ordered. Weapons and ammunition are always refused.
- A parcel is claimed in the database before the goods are handed over, so it can never be collected twice.
- The catalog only sells. At start every price is checked against MULTIstores: a price below twice what any store pays for the item is left out (no money loops), and a price cheaper than the cheapest store prints a warning.

## Setup

1. Put `MULTIcatalog` in `resources/[multicore]/`.
2. In `server.cfg`, after MULTIcore, MULTIinventory, MULTIstores and MULTItelegram:
   ```
   ensure MULTIcatalog
   ```
3. Needs `oxmysql`, `ox_lib`, `MULTIcore`, `MULTIinventory`, `MULTItarget`. MULTItelegram (arrival telegrams) and MULTIstores (price check) are used when they run.

## Config (`config.lua`)

Every option has a comment. The main ones:

- `Delivery.Mode`: `'gameday'` (default) or `'minutes'`.
- `Delivery.GameDays`: in-game days a parcel takes (default 1).
- `Delivery.GameDayMinutes`: real minutes in one in-game day (default 48, the game's own clock speed).
- `Delivery.Minutes`: real minutes a parcel takes in `'minutes'` mode.
- `Limits.MaxUnitsPerOrder` (20), `Limits.MaxLinesPerOrder` (8), `Limits.MaxPerLine` (10), `Limits.MaxOpenOrders` (3).
- `OrderCooldownSeconds`: time between two orders (10).
- `CatalogItem.Enabled`, `CatalogItem.Price` (0 = free), `CatalogItem.OrderAnywhere`.
- `Telegram.Enabled`: send a telegram on arrival when MULTItelegram runs.
- `Interact`, `PromptKey`, `TargetIcon`, `MaxUseDistance`: how the counter is used.
- `KeepCollectedDays`, `ShowCollected`: how long and how many collected orders are kept and shown.

Post offices are in `config/offices.lua`. Never rename an office `id` while parcels wait there.

## Adding goods

Add a line to `Config.Items` in `config/items.lua`:

```lua
{ name = 'canned_pork', price = 0.23, category = 'food' },
```

- `name` must be an item that exists in MULTIinventory.
- `price` is dollars with cents, 1899 level. The shipped prices are about 25% above the cheapest store's price, for the convenience of ordering by post. Keep new goods at or above the cheapest store's price.
- `category` is one of `Config.Categories` (add a new one there and a `cat_<name>` line in the locales).

The item's name and picture come from the inventory. Pictures are read from `MULTIimages/images/`.

Each shipped good has its own short catalog description, the locale line `desc_<item name>` (for example `['desc_canned_pork'] = 'Tender cooked pork in its own juices, ready to eat.'`). For a good you add, put a `desc_<item name>` line in `locales/en.lua` (and the other languages you use). Without one, the inventory's own description is shown, and without that the general line `desc_generic` ("Everyday goods, sent by post.").

The catalog item uses `mail_order_catalog.png`. No picture ships for it, so the inventory shows its placeholder until you add one to `MULTIimages/images/`.

## Exports (server)

| Export | Returns |
|---|---|
| `Order(src, { { name, amount } }, officeId)` | `true, { id, total, office, readyAt }` or `false, err` |
| `Collect(src, orderId)` | `true, { given, left }` or `false, err` |
| `GetOrders(citizenid)` | the Orders tab rows |
| `GetCatalog()` | `{ name, label, desc, image, price, category }` list |
| `DeliverySeconds()` | real seconds a parcel takes |
| `IsReady()` | `true` once the table is made |

Server events: `MULTIcatalog:ordered (src, id, office, total)`, `MULTIcatalog:arrived (citizenid, id, office)`, `MULTIcatalog:collected (src, id, linesLeft)`.

## Languages

English plus the 31 other languages MULTIcore ships (`locales/`).

## Self-test

`test/catalog_selftest` (tag `catalogtest`), run by `tools/test_boot.ps1 -All`.
