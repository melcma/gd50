--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)
    local lock = {
        keyX = math.random(10, 49),
        lockX = math.random(50, 90),
        pattern = math.random(4),
        keyCollected = false,
        lockUnlocked = false
    }

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        
        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        if x == lock.keyX then
            tileID = TILE_ID_GROUND

            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            local key = GameObject {
                texture = 'keys',
                x = (x - 1) * TILE_SIZE,
                y = (blockHeight - 1) * TILE_SIZE,
                width = 16,
                height = 16,

                frame = lock.pattern,
                collidable = true,
                solid = false,
                consumable = true,
                onConsume = function()
                    lock.keyCollected = true
                    gSounds['powerup-reveal']:play()
                end
            }

            table.insert(objects, key)

        elseif x == lock.lockX then
            tileID = TILE_ID_GROUND

            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            local keyID = #objects
            local lock = GameObject {
                texture = 'keys',
                x = (x - 1) * TILE_SIZE,
                y = (blockHeight - 1) * TILE_SIZE,
                width = 16,
                height = 16,

                frame = lock.pattern + 4,
                collidable = true,
                solid = true,
                onCollide = function()
                    lock.lockUnlocked = true
                    table.remove(objects, keyID)

                    local segments = math.random(3, 5)
                    local pattern = math.random(3, 6)
                    local flagX = width - 1

                    gSounds['powerup-reveal']:play()

                    for f = 1, segments do
                        -- top
                        if f == 1 then
                            table.insert(objects, GameObject {
                                texture = 'flags',
                                x = flagX * TILE_SIZE,
                                y = (6 - segments) * TILE_SIZE,
                                width = 16,
                                height = 16,

                                frame = pattern,
                                collidable = false,
                                solid = false,
                                consumable = false
                            })
                        -- stand
                        elseif f == segments then
                            table.insert(objects, GameObject {
                                texture = 'flags',
                                x = flagX * TILE_SIZE,
                                y = (5) * TILE_SIZE,
                                width = 16,
                                height = 16,

                                frame = pattern + 18,
                                collidable = false,
                                solid = false,
                                consumable = false
                            })
                        else
                            -- middle segments
                            table.insert(objects, GameObject {
                                texture = 'flags',
                                x = flagX * TILE_SIZE,
                                y = (5 - segments + f) * TILE_SIZE,
                                width = 16,
                                height = 16,

                                frame = pattern + 9,
                                collidable = false,
                                solid = false,
                                consumable = false
                            })

                            -- banners
                            table.insert(objects, GameObject {
                                texture = 'flags',
                                x = flagX * TILE_SIZE - 8,
                                y = (5 - segments + f) * TILE_SIZE - TILE_SIZE / 2,
                                width = 16,
                                height = 16,

                                frame = pattern * 9 - 2 - 18,
                                collidable = false,
                                solid = false,
                                direction = 'left',
                                consumable = true,
                                onConsume = function(player)
                                    gStateMachine:change('play', {
                                        score = player.score,
                                        width = width + 50
                                    })
                                end
                            })
                        end
                    end
                end
            }

            table.insert(objects, lock)

        -- chance to just be emptiness
        elseif math.random(7) == 1 and x < width - 1 then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            if math.random(8) == 1 and x < width - 1 then
                blockHeight = 2
                
                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            -- chance to spawn a block
            if math.random(10) == 1 and x < width - 1 then
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then

                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }
                                    
                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )
            end
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles
    
    return GameLevel(entities, objects, map, lock)
end