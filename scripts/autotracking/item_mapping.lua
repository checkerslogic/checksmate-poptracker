-- use this file to map the AP item ids to your items
-- first value is the code of the target item and the second is the item type override. The third value is an optional increment multiplier for consumables. (feel free to expand the table with any other values you might need (i.e. special initial values, etc.)!)
-- here are the SM items as an example: https://github.com/Cyb3RGER/sm_ap_tracker/blob/main/scripts/autotracking/item_mapping.lua
BASE_ITEM_ID = 4901000
ITEM_MAPPING = {
	[BASE_ITEM_ID + 000] = { { "white", "toggle" } },
	[BASE_ITEM_ID + 001] = { { "elo", "progressive" } },
	[BASE_ITEM_ID + 002] = { { "pawncount", "progressive" } },
	[BASE_ITEM_ID + 003] = { { "pawnforward", "progressive" } },
	[BASE_ITEM_ID + 004] = { { "progminor", "progressive" } },
	[BASE_ITEM_ID + 005] = { { "progmajor", "progressive" } },
	[BASE_ITEM_ID + 006] = { { "progqueen", "progressive" } },
	[BASE_ITEM_ID + 009] = { { "vict", "toggle" } },
	[BASE_ITEM_ID + 010] = { { "super", "toggle" } },
	[BASE_ITEM_ID + 020] = { { "progpocket", "progressive" } },
	[BASE_ITEM_ID + 023] = { { "proggems", "progressive" } },
	[BASE_ITEM_ID + 024] = { { "progpocketrange", "progressive" } },
	[BASE_ITEM_ID + 025] = { { "progking", "progressive" } },
	[BASE_ITEM_ID + 026] = { { "progconsul", "progressive" } },
}
