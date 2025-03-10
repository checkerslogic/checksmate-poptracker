-- this is an example/default implementation for AP autotracking
-- it will use the mappings defined in item_mapping.lua and location_mapping.lua to track items and locations via their ids
-- it will also keep track of the current index of on_item messages in CUR_INDEX
-- addition it will keep track of what items are local items and which one are remote using the globals LOCAL_ITEMS and GLOBAL_ITEMS
-- this is useful since remote items will not reset but local items might
-- if you run into issues when touching A LOT of items/locations here, see the comment about Tracker.AllowDeferredLogicUpdate in autotracking.lua
ScriptHost:LoadScript("scripts/autotracking/item_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/location_mapping.lua")

CUR_INDEX = -1
LOCAL_ITEMS = {}
GLOBAL_ITEMS = {}


GAME_MODE = "ordered_progressive" -- default to ordered progressive mode
DIFFICULTY_SETTING = "daily" -- default to normal
TACTICS = "turns"
PIECE_LOCATIONS = "chaos"
PIECE_TYPES = "stable"

FAIRY_CHESS_PIECES = false
FAIRY_CHESS_PAWNS = "vanilla"
FAIRY_CHESS_PAWNS_MIXED = false
FAIRY_PIECE_CONFIGURE = false
FAIRY_CHESS_PIECES = 1 -- default to FIDE pieces (1 piece type)

-- resets an item to its initial state
function resetItem(item_code, item_type)
	local obj = Tracker:FindObjectForCode(item_code)
	if obj then
		item_type = item_type or obj.Type
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: resetting item %s of type %s", item_code, item_type))
		end
		if item_type == "toggle" or item_type == "toggle_badged" then
			obj.Active = false
		elseif item_type == "progressive" or item_type == "progressive_toggle" then
			obj.CurrentStage = 0
			obj.Active = false
		elseif item_type == "consumable" then
			obj.AcquiredCount = 0
		elseif item_type == "custom" then
			-- your code for your custom lua items goes here
		elseif item_type == "static" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: tried to reset static item %s", item_code))
		elseif item_type == "composite_toggle" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format(
				"resetItem: tried to reset composite_toggle item %s but composite_toggle cannot be accessed via lua." ..
				"Please use the respective left/right toggle item codes instead.", item_code))
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: unknown item type %s for code %s", item_type, item_code))
		end
	elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("resetItem: could not find item object for code %s", item_code))
	end
end

-- advances the state of an item
function incrementItem(item_code, item_type, multiplier)
	local obj = Tracker:FindObjectForCode(item_code)
	if obj then
		item_type = item_type or obj.Type
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: code: %s, type %s", item_code, item_type))
		end
		if item_type == "toggle" or item_type == "toggle_badged" then
			obj.Active = true
		elseif item_type == "progressive" or item_type == "progressive_toggle" then
			if obj.Active then
				obj.CurrentStage = obj.CurrentStage + 1
			else
				obj.Active = true
			end
		elseif item_type == "consumable" then
			obj.AcquiredCount = obj.AcquiredCount + obj.Increment * multiplier
		elseif item_type == "custom" then
			-- your code for your custom lua items goes here
		elseif item_type == "static" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: tried to increment static item %s", item_code))
		elseif item_type == "composite_toggle" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format(
				"incrementItem: tried to increment composite_toggle item %s but composite_toggle cannot be access via lua." ..
				"Please use the respective left/right toggle item codes instead.", item_code))
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: unknown item type %s for code %s", item_type, item_code))
		end
	elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("incrementItem: could not find object for code %s", item_code))
	end
end

-- apply everything needed from slot_data, called from onClear
function apply_slot_data(slot_data)
	if slot_data then
		-- Game mode setting
		if slot_data["goal"] then
			if slot_data["goal"] == 0 then
				GAME_MODE = "single"
			elseif slot_data["goal"] == 3 then
				GAME_MODE = "super"
			else
				GAME_MODE = "both"	
			end
		end
		
		-- Difficulty setting
		if slot_data["difficulty"] then
			if slot_data["difficulty"] == 0 then
				DIFFICULTY_SETTING = "grandmaster"
			elseif slot_data["difficulty"] == 1 then
				DIFFICULTY_SETTING = "daily"
			elseif slot_data["difficulty"] == 2 then
				DIFFICULTY_SETTING = "bullet"
			elseif slot_data["difficulty"] == 3 then
				DIFFICULTY_SETTING = "relaxed"
			end
		end

		if slot_data["enable_tactics"] then
			if slot_data["enable_tactics"] == 0 then
				TACTICS = "all"
				Tracker:FindObjectForCode("FORKS").Active()
				Tracker:FindObjectForCode("TIMERS").Active()
			elseif slot_data["enable_tactics"] == 1 then
				TACTICS = "turns"
				Tracker:FindObjectForCode("TIMERS").Active()
			elseif slot_data["enable_tactics"] == 2 then
				TACTICS = "none"
			end
		end

		if slot_data["piece_locations"] ~= nil then
			if slot_data["piece_locations"] == 0 then
				PIECE_LOCATIONS = "chaos"
			elseif slot_data["piece_locations"] == 1 then
				PIECE_LOCATIONS = "stable"
			end
		end

		-- Fairy chess settings
		-- if slot_data["fairy_chess_pieces"] ~= nil then
		-- 	if slot_data["fairy_chess_pieces"] == 0 then
		-- 		FAIRY_CHESS_PIECES = 1
		-- 	elseif slot_data["fairy_chess_pieces"] == 1 then
		-- 		FAIRY_CHESS_PIECES = 4
		-- 	elseif slot_data["fairy_chess_pieces"] == 2 then
		-- 		FAIRY_CHESS_PIECES = 6
		-- 	else
		-- 		local piece_configure_count = 0
		-- 		for _ in ipairs(slot_data["fairy_chess_pieces_configure"]) do piece_configure_count = piece_configure_count + 1 end
		-- 		FAIRY_CHESS_PIECES = piece_configure_count
		-- 	end
		-- end

		-- if slot_data["fairy_chess_pieces_configure"] ~= nil then
		-- 	FAIRY_PIECE_CONFIGURE = slot_data["fairy_chess_pieces_configure"]
		-- end

		if slot_data["fairy_chess_pawns"] ~= nil then
			if slot_data["fairy_chess_pawns"] == 0 then
				FAIRY_CHESS_PAWNS = "vanilla"
				FAIRY_CHESS_PAWNS_MIXED = false
			elseif slot_data["fairy_chess_pawns"] == 1 then
				FAIRY_CHESS_PAWNS = "mixed"
				FAIRY_CHESS_PAWNS_MIXED = true
			elseif slot_data["fairy_chess_pawns"] == 2 then
				FAIRY_CHESS_PAWNS = "berolina"
				FAIRY_CHESS_PAWNS_MIXED = false
			elseif slot_data["fairy_chess_pawns"] == 3 then
				FAIRY_CHESS_PAWNS = "checkers"
				FAIRY_CHESS_PAWNS_MIXED = false
			elseif slot_data["fairy_chess_pawns"] == 4 then
				FAIRY_CHESS_PAWNS = "reserved"
				FAIRY_CHESS_PAWNS_MIXED = false
			elseif slot_data["fairy_chess_pawns"] == 5 then
				FAIRY_CHESS_PAWNS = "any_pawn"
				FAIRY_CHESS_PAWNS_MIXED = true
			elseif slot_data["fairy_chess_pawns"] == 6 then
				FAIRY_CHESS_PAWNS = "any_fairy"
				FAIRY_CHESS_PAWNS_MIXED = true
			elseif slot_data["fairy_chess_pawns"] == 7 then
				FAIRY_CHESS_PAWNS = "any_classical"
				FAIRY_CHESS_PAWNS_MIXED = true
			end
		end
		
		if slot_data["fairy_chess_pieces"] ~= nil then
			if slot_data["fairy_chess_pieces"] == 4 then
				-- Check configure array if available
				if slot_data["fairy_chess_pieces_configure"] then
					FAIRY_CHESS_PIECES = #slot_data["fairy_chess_pieces_configure"]
				else
					FAIRY_CHESS_PIECES = 1 -- Default to FIDE
				end
			elseif slot_data["fairy_chess_pieces"] == 0 then
				FAIRY_CHESS_PIECES = 1 -- FIDE
			elseif slot_data["fairy_chess_pieces"] == 1 then
				FAIRY_CHESS_PIECES = 4 -- Betza
			elseif slot_data["fairy_chess_pieces"] == 2 then
				FAIRY_CHESS_PIECES = 6 -- Full
			end
		end
		
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("Game settings - Mode: %s, Difficulty: %s", GAME_MODE, DIFFICULTY_SETTING))
			print(string.format("Fairy chess - Army: , Pawns: %s (Mixed: %s), Pieces: %d", 
				FAIRY_CHESS_PAWNS, FAIRY_CHESS_PAWNS_MIXED, FAIRY_CHESS_PIECES))
		end
	end
end

-- called right after an AP slot is connected
function onClear(slot_data)
	-- use bulk update to pause logic updates until we are done resetting all items/locations
	Tracker.BulkUpdate = true	
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onClear, slot_data:\n%s", dump_table(slot_data)))
	end
	CUR_INDEX = -1
	-- reset locations
	for _, mapping_entry in pairs(LOCATION_MAPPING) do
		for _, location_table in ipairs(mapping_entry) do
			if location_table then
				local location_code = location_table[1]
				if location_code then
					if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
						print(string.format("onClear: clearing location %s", location_code))
					end
					if location_code:sub(1, 1) == "@" then
						local obj = Tracker:FindObjectForCode(location_code)
						if obj then
							obj.AvailableChestCount = obj.ChestCount
						elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
							print(string.format("onClear: could not find location object for code %s", location_code))
						end
					else
						-- reset hosted item
						local item_type = location_table[2]
						resetItem(location_code, item_type)
					end
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onClear: skipping location_table with no location_code"))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping empty location_table"))
			end
		end
	end
	-- reset items
	for _, mapping_entry in pairs(ITEM_MAPPING) do
		for _, item_table in ipairs(mapping_entry) do
			if item_table then
				local item_code = item_table[1]
				local item_type = item_table[2]
				if item_code then
					resetItem(item_code, item_type)
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onClear: skipping item_table with no item_code"))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping empty item_table"))
			end
		end
	end
	apply_slot_data(slot_data)
	LOCAL_ITEMS = {}
	GLOBAL_ITEMS = {}
	-- manually run snes interface functions after onClear in case we need to update them (i.e. because they need slot_data)
	if PopVersion < "0.20.1" or AutoTracker:GetConnectionState("SNES") == 3 then
		-- add snes interface functions here
	end
	Tracker.BulkUpdate = false
end

-- called when an item gets collected
function onItem(index, item_id, item_name, player_number)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onItem: %s, %s, %s, %s, %s", index, item_id, item_name, player_number, CUR_INDEX))
	end
	if not AUTOTRACKER_ENABLE_ITEM_TRACKING then
		return
	end
	if index <= CUR_INDEX then
		return
	end
	local is_local = player_number == Archipelago.PlayerNumber
	CUR_INDEX = index;
	local mapping_entry = ITEM_MAPPING[item_id]
	if not mapping_entry then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onItem: could not find item mapping for id %s", item_id))
		end
		return
	end
	
	for _, item_table in pairs(mapping_entry) do
		if item_table then
			local item_code = item_table[1]
			local item_type = item_table[2]
			local multiplier = item_table[3] or 1
			if item_code then
				incrementItem(item_code, item_type, multiplier)
				-- keep track which items we touch are local and which are global
				if is_local then
					if LOCAL_ITEMS[item_code] then
						LOCAL_ITEMS[item_code] = LOCAL_ITEMS[item_code] + 1
					else
						LOCAL_ITEMS[item_code] = 1
					end
				else
					if GLOBAL_ITEMS[item_code] then
						GLOBAL_ITEMS[item_code] = GLOBAL_ITEMS[item_code] + 1
					else
						GLOBAL_ITEMS[item_code] = 1
					end
				end
			end
		end
	end
	
	-- Force location accessibility recalculation
	if ENABLE_DEBUG_LOG_VERBOSE then
		print("Forcing location accessibility recalculation after item update")
	end
	
	-- Trigger accessibility check for all locations
	for _, mapping_entry in pairs(LOCATION_MAPPING) do
		for _, location_table in ipairs(mapping_entry) do
			if location_table and location_table[1] then
				local obj = Tracker:FindObjectForCode(location_table[1])
				if obj then
					-- Access the AccessibilityLevel to force a recalculation
					local _ = obj.AccessibilityLevel
				end
			end
		end
	end
	
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("local items: %s", dump_table(LOCAL_ITEMS)))
		print(string.format("global items: %s", dump_table(GLOBAL_ITEMS)))
	end
end

-- called when a location gets cleared
function onLocation(location_id, location_name)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onLocation: %s, %s", location_id, location_name))
	end
	if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
		return
	end
	local mapping_entry = LOCATION_MAPPING[location_id]
	if not mapping_entry then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onLocation: could not find location mapping for id %s", location_id))
		end
		return
	end
	for _, location_table in pairs(mapping_entry) do
		if location_table then
			local location_code = location_table[1]
			if location_code then
				local obj = Tracker:FindObjectForCode(location_code)
				if obj then
					if location_code:sub(1, 1) == "@" then
						obj.AvailableChestCount = obj.AvailableChestCount - 1
					else
						-- increment hosted item
						local item_type = location_table[2]
						incrementItem(location_code, item_type)
					end
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onLocation: could not find object for code %s", location_code))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onLocation: skipping location_table with no location_code"))
			end
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onLocation: skipping empty location_table"))
		end
	end
end

-- called when a locations is scouted
function onScout(location_id, location_name, item_id, item_name, item_player)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onScout: %s, %s, %s, %s, %s", location_id, location_name, item_id, item_name,
			item_player))
	end
	-- not implemented yet :(
end

-- called when a bounce message is received
function onBounce(json)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onBounce: %s", dump_table(json)))
	end
	-- your code goes here
end

-- add AP callbacks
-- un-/comment as needed
Archipelago:AddClearHandler("clear handler", onClear)
if AUTOTRACKER_ENABLE_ITEM_TRACKING then
	Archipelago:AddItemHandler("item handler", onItem)
end
if AUTOTRACKER_ENABLE_LOCATION_TRACKING then
	Archipelago:AddLocationHandler("location handler", onLocation)
end
-- Archipelago:AddScoutHandler("scout handler", onScout)
-- Archipelago:AddBouncedHandler("bounce handler", onBounce)
