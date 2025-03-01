-- put logic functions here using the Lua API: https://github.com/black-sliver/PopTracker/blob/master/doc/PACKS.md#lua-interface
-- don't be afraid to use custom logic functions. it will make many things a lot easier to maintain, for example by adding logging.
-- to see how this function gets called, check: locations/locations.json

-- Constants for difficulty modifiers
DIFFICULTY_CHAOS_ARMY = 1.05
DIFFICULTY_FAIRY_CHESS_PAWNS = 1.06
DIFFICULTY_FAIRY_CHESS_PAWNS_MIXED = 1.16 --adjusting this value for NEW LOGIC
DIFFICULTY_FAIRY_CHESS_PAWNS_DOUBLE = 1.12 --adjusting this value for NEW LOGIC
DIFFICULTY_FAIRY_CHESS_PAWNS_UNUSUAL = 1.06 --adjusting this value for NEW LOGIC
DIFFICULTY_DAILY = 1.1
DIFFICULTY_BULLET = 1.2
DIFFICULTY_RELAXED = 1.35
SPHERE_ZERO_THRESHOLD = 99

isPawn = 0
isMinor = 0
isMajor = 0
isQueen = 0
isCastle = 0
isChessman = 0
isBig = 0


-- Material values for each item type
MATERIAL_VALUES = {
    ["Play as White"] = 50,
    ["Progressive Pawn"] = 100,
    ["Progressive Minor Piece"] = 300,
    ["Progressive Major Piece"] = 485,
    ["Progressive Major To Queen"] = 415,  -- Additional value when upgrading major to queen
    ["Progressive King Promotion"] = 350,
    ["Progressive Consul"] = 325,
    ["Progressive Pocket"] = 110
}

-- Helper function to calculate current material value
function get_current_material()
    local total = 0
    
    -- Add base material values for each item type
    for item, value in pairs(MATERIAL_VALUES) do
        local count = 0
        
        -- Get count from local and global items
        if LOCAL_ITEMS[item] then
            count = count + LOCAL_ITEMS[item]
        end
        if GLOBAL_ITEMS[item] then
            count = count + GLOBAL_ITEMS[item]
        end
        
        -- Special handling for queen upgrades
        if item == "Progressive Major To Queen" then
            -- For queen upgrades, we need to take the minimum of upgrades and base major pieces
            local major_pieces = (LOCAL_ITEMS["Progressive Major Piece"] or 0) + (GLOBAL_ITEMS["Progressive Major Piece"] or 0)
            count = math.min(count, major_pieces)
        end
        
        total = total + (count * value)
    end
    
    return total
end

-- Helper function to calculate current chessmen count
function get_current_chessmen()
    local total = Tracker:ProviderCountForCode("Progressive Pawn")
    total = 0
    
    -- Add base chessmen (pawns, minors, majors, consuls)
    total = total + (LOCAL_ITEMS["Progressive Pawn"] or 0) + (GLOBAL_ITEMS["Progressive Pawn"] or 0)
    total = total + (LOCAL_ITEMS["Progressive Minor Piece"] or 0) + (GLOBAL_ITEMS["Progressive Minor Piece"] or 0)
    total = total + (LOCAL_ITEMS["Progressive Major Piece"] or 0) + (GLOBAL_ITEMS["Progressive Major Piece"] or 0)
    total = total + (LOCAL_ITEMS["Progressive Consul"] or 0) + (GLOBAL_ITEMS["Progressive Consul"] or 0)
    
    -- Calculate pocket contribution
    local pocket_count = ((LOCAL_ITEMS["Progressive Pocket"] or 0) + (GLOBAL_ITEMS["Progressive Pocket"] or 0))
    if pocket_count > 0 then
        local pocket_limit = tonumber(Tracker:ProviderCountForCode("pocket_limit_by_pocket")) or 4  -- Default to 4 if not set
        if pocket_limit > 0 then
            -- Add chessmen from pockets based on pigeonhole principle
            -- Every pocket_limit items adds 1 chessman
            total = total + math.ceil(pocket_count / pocket_limit)
        end
    end
    
    return total
end


-- DIFFICULTY_CHAOS_ARMY = 1.05
-- DIFFICULTY_FAIRY_CHESS_PAWNS = 1.06
-- DIFFICULTY_FAIRY_CHESS_PAWNS_MIXED = 1.16 --adjusting this value for NEW LOGIC
-- DIFFICULTY_FAIRY_CHESS_PAWNS_DOUBLE = 1.12 --adjusting this value for NEW LOGIC
-- DIFFICULTY_FAIRY_CHESS_PAWNS_UNUSUAL = 1.06 --adjusting this value for NEW LOGIC
-- DIFFICULTY_DAILY = 1.1
-- DIFFICULTY_BULLET = 1.2
-- DIFFICULTY_RELAXED = 1.35
-- Helper function to calculate difficulty modifier
function get_difficulty_modifier()
    local difficulty = 1.0
    -- Fairy chess army modifier
    if PIECE_LOCATIONS == "stable" then
        difficulty = difficulty * DIFFICULTY_CHAOS_ARMY
    end
    -- Fairy chess pawns modifier
    if FAIRY_CHESS_PAWNS ~= "vanilla" then
        difficulty = difficulty * DIFFICULTY_FAIRY_CHESS_PAWNS
        if FAIRY_CHESS_PAWNS_MIXED then
            difficulty = difficulty * DIFFICULTY_FAIRY_CHESS_PAWNS_MIXED
        end
        if FAIRY_CHESS_PAWNS == "any_pawn" or FAIRY_CHESS_PAWNS == "any_fairy" or FAIRY_CHESS_PAWNS == "any_classical" then
            difficulty = difficulty * DIFFICULTY_FAIRY_CHESS_PAWNS_DOUBLE
        end
        if FAIRY_CHESS_PAWNS == "berolina" or FAIRY_CHESS_PAWNS == "checkers" then
            difficulty = difficulty * DIFFICULTY_FAIRY_CHESS_PAWNS_UNUSUAL
        end
    end
    
    -- Fairy pieces modifier
    local pieces_modifier = 0.99 + (0.01 * FAIRY_CHESS_PIECES)
    difficulty = difficulty * pieces_modifier
    
    -- Game difficulty modifiers
    if DIFFICULTY_SETTING == "daily" then
        difficulty = difficulty * DIFFICULTY_DAILY
    elseif DIFFICULTY_SETTING == "bullet" then
        difficulty = difficulty * DIFFICULTY_BULLET
    elseif DIFFICULTY_SETTING == "relaxed" then
        difficulty = difficulty * DIFFICULTY_RELAXED
    end
    
    return difficulty
end

function get_relaxation()
    local angy = 0 --no angy if game easy
    if DIFFICULTY_SETTING == "bullet" then
        angy = angy + 120 -- bullet make angy
    end
    if DIFFICULTY_SETTING == "relaxed" then
        angy = angy + 240 -- relax make very angy!?
    end
    if FAIRY_CHESS_PAWNS ~= "vanilla" then
        angy = angy +120 -- alternate pawns? you better believe make angy
    end
    if ENABLE_DEBUG_LOG then
        print("get relaxation ran. angy is: "..tostring(angy))
    end
    return angy
end

-- Helper function to check material requirements
function needs_material(material_cost, grand_cost, name)
    -- Get current material from tracker
    local current_material = get_current_material()
    
    -- Handle -1 material cost cases
    if GAME_MODE == "single" and material_cost == -1 then
        -- Location requires super-size mode
        return false
    end
    
    -- Calculate difficulty modifier
    local difficulty = get_difficulty_modifier()

    -- Calculate relaxation offset
    local relaxation = get_relaxation()

    -- Calculate target based on mode
    local target
    if GAME_MODE == "super" then
        target = grand_cost * difficulty + relaxation
    elseif tonumber(material_cost) == -1 then
        target = grand_cost * difficulty + relaxation
    elseif GAME_MODE == "both" then
        if tonumber(material_cost) <= SPHERE_ZERO_THRESHOLD then
            target = material_cost * difficulty
        else
            target = material_cost * difficulty + relaxation
        end
    else -- single mode
        if tonumber(material_cost) <= SPHERE_ZERO_THRESHOLD then
            target = material_cost * difficulty
        else
            target = material_cost * difficulty + relaxation
        end
    end
    if ENABLE_DEBUG_LOG then
        if type(name) ~= "string" then
            name = tostring(name)
        end
        print("needs_material for: ".. name)
        print(string.format("  material/grand_cost: %.0f, %.0f; difficulty: %.2f; relaxation: %.0f; target: %.0f, material: %.0f", 
                                material_cost, grand_cost, difficulty, relaxation, target, current_material))
        print("  material state: "..tostring(current_material > target))
    end
    if current_material >= target then
        return true
    else
        return false
    end
end

function needs_chessmen(count)
    if type(count) == "string" then
        count = tonumber(count)
    end
    local chessmen_count = get_current_chessmen()
    if ENABLE_DEBUG_LOG then
        print("  but how about those chessmen?")
        print(string.format("  needed_chessmen: %d; get_current_chessmen: %d; ", count, chessmen_count))
        print("  chessmen state: "..tostring(chessmen_count >= count))
    end
    if chessmen_count >= count then
        return true
    else
        return false
    end
end

function needs_pin()
    -- if minor or major
    local pin = (((LOCAL_ITEMS["Progressive Minor Piece"] or 0) + (GLOBAL_ITEMS["Progressive Minor Piece"] or 0)) > 0 or 
    ((LOCAL_ITEMS["Progressive Major Piece"] or 0) + (GLOBAL_ITEMS["Progressive Major Piece"] or 0)) > 0)
    if ENABLE_DEBUG_LOG then
        print("hows the pin?: "..tostring(pin))
    end
    return pin
end

-- Helper function to check if super-size mode is available
function has_super_size()
    local big = ((LOCAL_ITEMS["Super-Size Me"] or 0) or (GLOBAL_ITEMS["Super-Size Me"] or 0) or 0) > 0
    if ENABLE_DEBUG_LOG then
        print("hows the super size?: "..tostring(big))
    end
    return big
end

function needs_castle()
    local twocastle = ((LOCAL_ITEMS["Progressive Major Piece"] or 0) + (GLOBAL_ITEMS["Progressive Major Piece"] or 0)) 
    >
    ((LOCAL_ITEMS["Progressive Major To Queen"] or 0) + (GLOBAL_ITEMS["Progressive Major To Queen"] or 0) + 1)
    if ENABLE_DEBUG_LOG then
        print("ah, but do you have two castles?: "..tostring(twocastle))
    end
    return twocastle
end

--[[ function is_tactic_available(tactic_type)
    local enable_tactics = Tracker:ProviderCountForCode("enable_tactics")
    if enable_tactics == 0 then
        return 0
    end
    
    -- If tactics are set to "turns only", only allow turn-based tactics
    if enable_tactics == 1 then -- assuming 1 is "turns only"
        return tactic_type == "turns" and 1 or 0
    end
    
    -- All tactics enabled
    return 1
end ]]

function can_checkmate_minima()
    return needs_material(4020, 4020, "checkmate_minima")
end

function can_checkmate_maxima()
    -- Only available in super/both modes and requires super-size
    if GAME_MODE == "single" then
        return false
    end
    return needs_material(-1, 6020, "checkmate_maxima") and has_super_size()
end

function can_capture_everything()
    if GAME_MODE == "single" then
        return needs_material(4020, 4020, "capture_everything") and needs_chessmen(14)
    else
        return needs_material(-1, 6020, "capture_everything") and needs_chessmen(18) and has_super_size()
    end
end

function pawnChanged()
    if ENABLE_DEBUG_LOG then
        print("pawnChanged updated!")
    end
    isPawn = Tracker:ProviderCountForCode("Progressive Pawn")
    isMinor = Tracker:ProviderCountForCode("Progressive Minor Piece")
    isMajor = Tracker:ProviderCountForCode("Progressive Major Piece")
    isQueen = Tracker:ProviderCountForCode("Progressive Major To Queen")
    isPocket = math.ceil(Tracker:ProviderCountForCode("Progressive Pocket") / Tracker:ProviderCountForCode("pocket_limit_by_pocket"))
    isCastle = isMajor - isQueen
    isChessman = isPawn + isMinor + isMajor
end

ScriptHost.AddWatchForCode("pawnChangedLogic", "*", pawnChanged)