-- ============================================================
-- MULTIcatalog :: what the catalog sells
-- Only everyday goods: food, coffee, tobacco, bandages, simple tools, camp,
-- horse care, bait, seeds. No weapons, no ammunition, no horses, no rare items.
--
--   name      item name (must exist in MULTIinventory; unknown names are left out with a warning)
--   price     dollars with cents for one, paid when ordering
--   category  section of the catalog (locale key cat_<category>)
--
-- The catalog description of each good is the locale line desc_<name>
-- (locales/*.lua); without one the inventory's description is shown, and
-- without that the general line desc_generic.
--
-- Prices are 1899-level and about 25% above the cheapest store's price (the
-- convenience of ordering by post). The catalog only sells, so it can never make
-- money for anyone; still, a line priced below twice the most any store pays for
-- the item is left out at start (no money loops), and a line cheaper than the
-- cheapest store gets a warning. Weapons (weapon_*, ammo_*, type 'weapon') are
-- always refused.
-- ============================================================

Config.Categories = { 'food', 'drink', 'tobacco', 'medicine', 'tools', 'camp', 'horse', 'fishing', 'farming' }

Config.Items = {
    -- food (cheapest store price in the comment; no comment = no store sells it, old catalog price + 25%)
    { name = 'bread',             price = 0.13, category = 'food' },     -- 0.10
    { name = 'bread_sour',        price = 0.19, category = 'food' },     -- 0.15
    { name = 'crackers',          price = 0.10, category = 'food' },
    { name = 'canned_apricots',   price = 0.25, category = 'food' },     -- 0.20
    { name = 'canned_corn',       price = 0.13, category = 'food' },
    { name = 'canned_vegetables', price = 0.15, category = 'food' },
    { name = 'canned_pork',       price = 0.23, category = 'food' },
    { name = 'beef_jerky',        price = 0.19, category = 'food' },
    { name = 'chocolate',         price = 0.06, category = 'food' },
    { name = 'sugarcube',         price = 0.03, category = 'food' },     -- 0.02
    { name = 'flour_wheat',       price = 0.25, category = 'food' },     -- 0.20 (general store buys at 0.08)
    { name = 'salt',              price = 0.06, category = 'food' },
    { name = 'beans',             price = 0.08, category = 'food' },
    -- drink
    { name = 'coffee',            price = 0.06, category = 'drink' },    -- 0.05 (saloon)
    -- tobacco
    { name = 'cigarettes',        price = 0.13, category = 'tobacco' },  -- 0.10
    { name = 'cigar',             price = 0.13, category = 'tobacco' },  -- 0.10
    { name = 'pipe_tobacco',      price = 0.19, category = 'tobacco' },  -- 0.15
    { name = 'chewing_tobacco',   price = 0.13, category = 'tobacco' },  -- 0.10
    { name = 'pipe',              price = 0.63, category = 'tobacco' },  -- 0.50
    -- medicine
    { name = 'bandage',           price = 0.19, category = 'medicine' }, -- 0.15 (doctor)
    -- tools
    { name = 'axe',               price = 1.56, category = 'tools' },    -- 1.25
    { name = 'pickaxe',           price = 1.88, category = 'tools' },    -- 1.50
    { name = 'shovel',            price = 1.13, category = 'tools' },    -- 0.90
    { name = 'bucket',            price = 0.44, category = 'tools' },    -- 0.35
    { name = 'canteen0',          price = 0.94, category = 'tools' },    -- 0.75
    { name = 'goldpan',           price = 0.94, category = 'tools' },    -- 0.75
    -- camp and light
    { name = 'oil',               price = 0.15, category = 'camp' },
    { name = 'campfire',          price = 0.63, category = 'camp' },     -- 0.50
    { name = 'cloth',             price = 0.06, category = 'camp' },     -- 0.05
    -- horse care
    { name = 'horse_brush',       price = 0.63, category = 'horse' },    -- 0.50
    { name = 'haysnack',          price = 0.13, category = 'horse' },    -- 0.10
    { name = 'horse_carrot',      price = 0.06, category = 'horse' },    -- 0.05
    -- fishing
    { name = 'p_baitworm01x',     price = 0.13, category = 'fishing' },  -- 0.10
    -- farming (MULTIfarming registers these a moment after start)
    { name = 'hoe',               price = 0.63, category = 'farming' },  -- 0.50
    { name = 'wateringcan',       price = 0.94, category = 'farming' },  -- 0.75
    { name = 'seed_corn',         price = 0.06, category = 'farming' },  -- 0.05
    { name = 'seed_potato',       price = 0.06, category = 'farming' },  -- 0.05
    { name = 'seed_carrot',       price = 0.06, category = 'farming' },  -- 0.05
    { name = 'seed_wheat',        price = 0.06, category = 'farming' },  -- 0.05
}
