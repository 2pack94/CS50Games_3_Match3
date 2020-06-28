--[[
    GD50
    Match-3 Remake

    -- Tile Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The individual tiles that make up our game board. Each Tile can have a
    color and a variety, with the varietes adding extra points to the matches.
]]

Tile = Class{}

TILE_SIZE = 32
TILE_NUM_COLORS = 18        -- number of different tile colors in the spritesheet
TILE_NUM_VARIETIES = 6      -- every tile color has 6 varieties

function Tile:init(grid_x, grid_y, color, variety)
    -- board positions (range: 1 - <number of tiles per board dimension>)
    -- this represents the position in the table of all tiles in the board class
    self.grid_x = grid_x
    self.grid_y = grid_y

    -- coordinate positions inside the board (not absolute coordinates on the screen)
    self.x = (self.grid_x - 1) * TILE_SIZE
    self.y = (self.grid_y - 1) * TILE_SIZE

    -- tile appearance
    self.color = color          -- range: 1 - TILE_NUM_COLORS
    self.variety = variety      -- range: 1 - TILE_NUM_VARIETIES
end

--[[
    board_x, board_y: input. x, y coordinates (top left corner) of the board that holds the tiles
]]
function Tile:render(board_x, board_y)
    -- draw shadow
    local shadow_offset_xy = 2
    love.graphics.setColor(34/255, 32/255, 52/255, 255/255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + board_x + shadow_offset_xy, self.y + board_y + shadow_offset_xy)

    -- draw tile itself
    love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + board_x, self.y + board_y)
end
