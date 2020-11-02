--[[
    GD50
    Match-3 Remake

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Helper functions for writing Match-3.
]]

--[[
    Given an "atlas" (a texture with multiple sprites/ spritesheet), generate all of the
    quads for the different tiles therein, divided into tables for each set
    of tiles, since each color has TILE_NUM_VARIETIES varieties.
]]
function GenerateTileQuads(atlas)
    local tiles = {}    -- table of all tile quads

    local x = 0     -- x coordinate of the tile in the spritesheet
    local y = 0     -- y coordinate of the tile in the spritesheet

    local counter = 1

    -- rows of tiles in the spritesheet
    for row = 1, TILE_NUM_COLORS / 2 do
        -- there are 2 times TILE_NUM_COLORS / 2 rows next to each other in the spritesheet
        for i = 1, 2 do
            tiles[counter] = {}
            -- the columns hold the different tile varieties of the tile colors
            for col = 1, TILE_NUM_VARIETIES do
                table.insert(tiles[counter], 
                    love.graphics.newQuad(x, y, TILE_SIZE, TILE_SIZE, atlas:getDimensions())
                )
                x = x + TILE_SIZE
            end
            counter = counter + 1
        end
        y = y + TILE_SIZE
        x = 0
    end

    return tiles
end
