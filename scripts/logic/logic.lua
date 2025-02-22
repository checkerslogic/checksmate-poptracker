-- put logic functions here using the Lua API: https://github.com/black-sliver/PopTracker/blob/master/doc/PACKS.md#lua-interface
-- don't be afraid to use custom logic functions. it will make many things a lot easier to maintain, for example by adding logging.
-- to see how this function gets called, check: locations/locations.json

-- Constants for difficulty modifiers
DIFFICULTY_FAIRY_CHESS_ARMY = 1.05
DIFFICULTY_FAIRY_CHESS_PAWNS = 1.06
DIFFICULTY_FAIRY_CHESS_PAWNS_MIXED = 1.16 --adjusting this value for NEW LOGIC
DIFFICULTY_FAIRY_CHESS_PAWNS_DOUBLE = 1.12 --adjusting this value for NEW LOGIC
DIFFICULTY_FAIRY_CHESS_PAWNS_UNUSUAL = 1.06 --adjusting this value for NEW LOGIC
DIFFICULTY_DAILY = 1.1
DIFFICULTY_BULLET = 1.2
DIFFICULTY_RELAXED = 1.35
SPHERE_ZERO_THRESHOLD = 99

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
    
    if ENABLE_DEBUG_LOG then
        print(string.format("Current material value: %d", total))
        -- Debug each item's contribution
        for item, value in pairs(MATERIAL_VALUES) do
            local count = 0
            if LOCAL_ITEMS[item] then
                count = count + LOCAL_ITEMS[item]
            end
            if GLOBAL_ITEMS[item] then
                count = count + GLOBAL_ITEMS[item]
            end
            if item == "Progressive Major To Queen" then
                local major_pieces = (LOCAL_ITEMS["Progressive Major Piece"] or 0) + (GLOBAL_ITEMS["Progressive Major Piece"] or 0)
                count = math.min(count, major_pieces)
            end
            print(string.format("  %s: count=%d, value=%d, total=%d", item, count, value, count * value))
        end
    end
    
    return total
end

-- Helper function to calculate current chessmen count
function get_current_chessmen()
    local total = 0
    
    -- Add base chessmen (pawns, minors, majors, consuls)
    total = total + Tracker:ProviderCountForCode("Progressive Pawn")
    total = total + Tracker:ProviderCountForCode("Progressive Minor Piece")
    total = total + Tracker:ProviderCountForCode("Progressive Major Piece")
    total = total + Tracker:ProviderCountForCode("Progressive Consul")
    
    -- Calculate pocket contribution
    local pocket_count = Tracker:ProviderCountForCode("Progressive Pocket")
    if pocket_count > 0 then
        local pocket_limit = tonumber(Tracker:ProviderCountForCode("pocket_limit_by_pocket")) or 4  -- Default to 4 if not set
        if pocket_limit > 0 then
            -- Add chessmen from pockets based on pigeonhole principle
            -- Every pocket_limit items adds 1 chessman
            total = total + math.ceil(pocket_count / pocket_limit)
        end
    end
    
    if ENABLE_DEBUG_LOG then
        print(string.format("Current chessmen count: %d", total))
    end
    
    return total
end

-- Helper function to calculate difficulty modifier
function get_difficulty_modifier()
    local difficulty = 1.0
    
    -- Fairy chess army modifier
    if FAIRY_CHESS_ARMY then
        difficulty = difficulty * DIFFICULTY_FAIRY_CHESS_ARMY
        if ENABLE_DEBUG_LOG then
            print(string.format("  Applying fairy chess army modifier: %.2f -> %.2f", 
                DIFFICULTY_FAIRY_CHESS_ARMY, difficulty))
        end
    end
    
    -- Fairy chess pawns modifier
    if FAIRY_CHESS_PAWNS ~= "vanilla" then
        difficulty = difficulty * DIFFICULTY_FAIRY_CHESS_PAWNS
        if ENABLE_DEBUG_LOG then
            print(string.format("  Applying fairy chess pawns modifier: %.2f -> %.2f", 
                DIFFICULTY_FAIRY_CHESS_PAWNS, difficulty))
        end
        if FAIRY_CHESS_PAWNS_MIXED then
            difficulty = difficulty * DIFFICULTY_FAIRY_CHESS_PAWNS_MIXED
            if ENABLE_DEBUG_LOG then
                print(string.format("  Applying fairy chess pawns mixed modifier: %.2f -> %.2f", 
                    DIFFICULTY_FAIRY_CHESS_PAWNS_MIXED, difficulty))
            end
        end
        if FAIRY_CHESS_PAWNS == "any_pawn" or FAIRY_CHESS_PAWNS == "any_fairy" or FAIRY_CHESS_PAWNS == "any_classical" then
            difficulty = difficulty * DIFFICULTY_FAIRY_CHESS_PAWNS_DOUBLE
            if ENABLE_DEBUG_LOG then
                print(string.format("  Applying any chess pawns mixed modifier: %.2f -> %.2f", 
                    DIFFICULTY_FAIRY_CHESS_PAWNS_DOUBLE, difficulty)) 
            end
        end
        if FAIRY_CHESS_PAWNS == "berolina" or FAIRY_CHESS_PAWNS == "checkers" then
            difficulty = difficulty * DIFFICULTY_FAIRY_CHESS_PAWNS_UNUSUAL
            if ENABLE_DEBUG_LOG then
                print(string.format("  Applying unusual chess pawns mixed modifier: %.2f -> %.2f", 
                DIFFICULTY_FAIRY_CHESS_PAWNS_UNUSUAL, difficulty)) 
            end
        end

    end
    
    -- Fairy pieces modifier
    local pieces_modifier = 0.99 + (0.01 * FAIRY_CHESS_PIECES)
    difficulty = difficulty * pieces_modifier
    if ENABLE_DEBUG_LOG then
        print(string.format("  Applying fairy pieces modifier (count=%d): %.2f -> %.2f", 
            FAIRY_CHESS_PIECES, pieces_modifier, difficulty))
    end
    
    -- Game difficulty modifiers
    if DIFFICULTY_SETTING == "daily" then
        difficulty = difficulty * DIFFICULTY_DAILY
        if ENABLE_DEBUG_LOG then
            print(string.format("  Applying daily difficulty modifier: %.2f -> %.2f", 
                DIFFICULTY_DAILY, difficulty))
        end
    elseif DIFFICULTY_SETTING == "bullet" then
        difficulty = difficulty * DIFFICULTY_BULLET
        if ENABLE_DEBUG_LOG then
            print(string.format("  Applying bullet difficulty modifier: %.2f -> %.2f", 
                DIFFICULTY_BULLET, difficulty))
        end
    elseif DIFFICULTY_SETTING == "relaxed" then
        difficulty = difficulty * DIFFICULTY_RELAXED
        if ENABLE_DEBUG_LOG then
            print(string.format("  Applying relaxed difficulty modifier: %.2f -> %.2f", 
                DIFFICULTY_RELAXED, difficulty))
        end
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
    return angy
end

-- Helper function to check material requirements
function needs_material(material_cost, grand_cost)
    -- Get current material from tracker
    local current_material = get_current_material()
    
    -- Handle -1 material cost cases
    if GAME_MODE == "single" and material_cost == -1 then
        -- Location requires super-size mode
        return 0
    end
    
    -- Calculate difficulty modifier
    local difficulty = get_difficulty_modifier()

    -- Calculate relaxation offset
    local relaxation = get_relaxation()

    -- Calculate target based on mode
    local target
    if GAME_MODE == "super" or material_cost == -1 then
        target = grand_cost * difficulty + relaxation
    elseif GAME_MODE == "both" then
        target = math.min(material_cost, grand_cost) * difficulty + relaxation
    else -- single mode
        if tonumber(material_cost) <= SPHERE_ZERO_THRESHOLD then
            target = material_cost * difficulty
        else
            target = material_cost * difficulty + relaxation
        end
    end
    
    if ENABLE_DEBUG_LOG then
        print(string.format("Material check: current=%.0f, target=%.0f, mode=%s", current_material, target, GAME_MODE))
        print(string.format("  Base cost: %d, Grand cost: %d", material_cost, grand_cost))
        print(string.format("  Final difficulty modifier: %.2f", difficulty))
    end
    
    return current_material >= target and 1 or 0
end

function needs_chessmen(count)
    if type(count) == "string" then
        count = tonumber(count)
    end
    if not count then return 0 end
    
    local chessmen_count = get_current_chessmen()
    if ENABLE_DEBUG_LOG then
        print(string.format("Chessmen check: current=%d, required=%d", chessmen_count, count))
    end
    return chessmen_count >= count and 1 or 0
end

function needs_pin()
    return (Tracker:ProviderCountForCode("Progressive Minor Piece") > 0 or 
            Tracker:ProviderCountForCode("Progressive Major Piece") > 0) and 1 or 0
end

-- Helper function to check if super-size mode is available
function has_super_size()
    return Tracker:ProviderCountForCode("Super-Size Me") > 0 and 1 or 0
end

function needs_castle()
    local major_pieces = Tracker:ProviderCountForCode("Progressive Major Piece")
    local major_to_queen = Tracker:ProviderCountForCode("Progressive Major To Queen")
    -- Need 2 more major pieces than queen upgrades
    return major_pieces >= (2 + major_to_queen) and 1 or 0
end

function is_tactic_available(tactic_type)
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
end

function can_checkmate_minima()
    return needs_material(4020, 4020)
end

function can_checkmate_maxima()
    -- Only available in super/both modes and requires super-size
    if GAME_MODE == "single" then
        return 0
    end
    return needs_material(-1, 6020) and has_super_size()
end

function can_capture_everything()
    if GAME_MODE == "single" then
        return needs_material(4020, 4020) and needs_chessmen(14)
    else
        return needs_material(-1, 6020) and needs_chessmen(18) and has_super_size()
    end
end
