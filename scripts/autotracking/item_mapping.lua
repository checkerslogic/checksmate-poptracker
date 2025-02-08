-- use this file to map the AP item ids to your items
-- first value is the code of the target item and the second is the item type override. The third value is an optional increment multiplier for consumables. (feel free to expand the table with any other values you might need (i.e. special initial values, etc.)!)
-- here are the SM items as an example: https://github.com/Cyb3RGER/sm_ap_tracker/blob/main/scripts/autotracking/item_mapping.lua
BASE_ITEM_ID = 4901000
ITEM_MAPPING = {
	[BASE_ITEM_ID + 0] = { { "Play as White", "toggle" } },
	[BASE_ITEM_ID + 1] = { { "Progressive Engine ELO Lobotomy", "progressive" } },
	[BASE_ITEM_ID + 2] = { { "Progressive Pawn", "progressive" } },
	[BASE_ITEM_ID + 3] = { { "Progressive Pawn Forwardness", "progressive" } },
	[BASE_ITEM_ID + 4] = { { "Progressive Minor Piece", "progressive" } },
	[BASE_ITEM_ID + 5] = { { "Progressive Major Piece", "progressive" } },
	[BASE_ITEM_ID + 6] = { { "Progressive Major To Queen", "progressive" } },
	[BASE_ITEM_ID + 9] = { { "Victory", "toggle" } },
	[BASE_ITEM_ID + 10] = { { "Super-Size Me", "toggle" } },
	[BASE_ITEM_ID + 20] = { { "Progressive Pocket", "progressive" } },
	[BASE_ITEM_ID + 23] = { { "Progressive Pocket Gems", "progressive" } },
	[BASE_ITEM_ID + 24] = { { "Progressive Pocket Range", "progressive" } },
	[BASE_ITEM_ID + 25] = { { "Progressive King Promotion", "progressive" } },
	[BASE_ITEM_ID + 26] = { { "Progressive Consul", "progressive" } }
}
