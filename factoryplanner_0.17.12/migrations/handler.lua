--require("migration_0_17_0")
require("migration_0_17_9")

-- This code handles the general migration process of the mod's global table
-- It decides whether and which migrations should be applied, in appropriate order

-- Returns a table containing all existing migrations in order
-- The appropriate migration file needs to be required at the top
function migration_masterlist()
    return {
        --[0] = {version="0.17.0"},
        [1] = {version="0.17.9"}
    }
end

-- Applies any appropriate migrations to the global table
function attempt_global_migration()
    local migrations = determine_migrations(global.mod_version)
    
    apply_migrations(migrations, "global", nil, nil)
    global.mod_version = game.active_mods["factoryplanner"]
end

-- Applies any appropriate migrations to the given factory
function attempt_player_table_migration(player)
    local player_table = get_table(player)
    if player_table ~= nil then  -- don't apply migrations to new players
        local migrations = determine_migrations(player_table.mod_version)
        
        -- General migrations
        apply_migrations(migrations, "player_table", player, player_table)

        -- Factory migrations
        for _, subfactory in pairs(Factory.get_in_order(player_table.factory, "Subfactory")) do
            attempt_subfactory_migration(player, subfactory, migrations)
        end

        player_table.mod_version = global.mod_version
    end
end

-- Applies any appropriate migrations to the given subfactory
function attempt_subfactory_migration(player, subfactory, migrations)
    -- if migrations~=nil, it forgoes re-checking itself to avoid repeated checks
    local migrations = migrations or determine_migrations(subfactory.mod_version)

    apply_migrations(migrations, "subfactory", player, subfactory)
    subfactory.mod_version = global.mod_version
end

-- Determines whether a migration needs to take place, and if so, returns the appropriate range of the 
-- migration_masterlist. If the version changed, but no migrations apply, it returns an empty array.
function determine_migrations(previous_version)
    local migrations = {}
    
    local found = false
    for _, migration in ipairs(migration_masterlist()) do
        if compare_versions(previous_version, migration.version) then found = true end
        if found then table.insert(migrations, migration.version) end
    end

    return migrations
end

-- Applies given migrations to the object
function apply_migrations(migrations, name, player, object)
    for _, migration in ipairs(migrations) do
        local internal_version = migration:gsub("%.", "_")
        local f = _G["migration_" .. internal_version][name]
        if f ~= nil then f(player, object) end
    end
end

-- Compares two mod versions, returns true if v1 is an earlier version than v2 (v1 < v2)
-- Version numbers have to be of the same structure: same amount of numbers, separated by a '.'
function compare_versions(v1, v2)
    local split_v1 = ui_util.split(v1, ".")
    local split_v2 = ui_util.split(v2, ".")

    for i = 1, #split_v1 do
        if split_v1[i] == split_v2[i] then
            -- continue
        elseif split_v1[i] < split_v2[i] then
            return true
        else
            return false
        end
    end
    return false  -- return false if both versions are the same
end