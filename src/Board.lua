--[[
    GD50
    Match-3 Remake

    -- Board Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The Board is our arrangement of Tiles on with which we must try to find matching
    sets of a certain number horizontally or vertically.
]]

Board = Class{}

function Board:init(x, y)
    self.x = x or 0
    self.y = y or 0
    self.num_tiles_per_dimension = 8    -- the length of the edges of the board in tiles
    self.width = self.num_tiles_per_dimension * TILE_SIZE
    self.height = self.num_tiles_per_dimension * TILE_SIZE
    self.tiles_to_match = 3             -- number of same colored tiles to align horizontally or vertically to be considered as a match
    self.num_tile_colors = 7            -- restrict the number of different tile colors that are used on the board to lower the difficulty
    self.tile_colors = {}               -- table that holds all tile colors that are chosen for this board (colors are represented by a value between 1 and TILE_NUM_COLORS)
    -- fill the self.tile_colors table with unique tile colors. the table indices (keys) will range from 1 to self.num_tile_colors
    local tile_color = 0
    for _ = 1, self.num_tile_colors do
        repeat
            tile_color = math.random(TILE_NUM_COLORS)
        until not table.contains(self.tile_colors, tile_color)
        table.insert(self.tile_colors, tile_color)
    end
    -- table that holds all tiles that form a match on the current board.
    -- The tile objects that belong to a match are stored in a sub-table inside this table.
    -- the same tile can be present two times in this table when it is involved in a horizontal and vertical match at the same time
    self.matches = {}

    -- specify if new tiles should spawn from the top when tiles are removed as a result of a match
    self.do_fill_spaces = true

    -- generate the tiles for the board
    -- check if there is a potential match to make on the board
    -- if no matches possible, generate a new board
    repeat
        self:initializeTiles()
    until self:isPotentialMatch()
end

--[[
    instantiate all tile objects for this board and put them into the self.tiles table
    The algorithm used creates a matchless board at the start.
    After each tile is placed, check if any matches occur. If yes, retry.
]]
function Board:initializeTiles()
    -- table that holds all Tile Objects on the Board.
    -- tiles are generated from left to right and from top to bottom and put into the table in this order
    -- consists of self.num_tiles_per_dimension sub-tables where each sub-table holds the tiles for one row
    self.tiles = {}
    -- subset of self.tile_colors for each board position. If for the current position a tile color is chosen that would result in a match, remove the color from this table and try again with another color
    local tile_colors_avail = nil
    -- index is randomly chosen for the tile_colors_avail table
    local tile_color_ind = 0
    -- set flag if a match occurred on the board after placing a tile
    local is_match = false

    for tile_y = 1, self.num_tiles_per_dimension do         -- all rows of the board
        -- insert empty table that will serve as a new row (initializing needed before next loop to be compatible with self:calculateMatches())
        self.tiles[tile_y] = {}
    end

    for tile_y = 1, self.num_tiles_per_dimension do         -- all rows of the board
        for tile_x = 1, self.num_tiles_per_dimension do     -- all tiles per row
            tile_colors_avail = deepcopy(self.tile_colors)  -- deepcopy needed to not modify self.tile_colors
            repeat
                is_match = false
                -- choose a random index from the tile_colors_avail table
                tile_color_ind = math.random(#tile_colors_avail)
                
                -- create a new tile at x, y with a random color and variety. insert it in the sub-table for the current row
                self.tiles[tile_y][tile_x] = Tile(tile_x, tile_y, tile_colors_avail[tile_color_ind], math.random(TILE_NUM_VARIETIES))

                if self:calculateMatches() then -- if a match occurred
                    is_match = true
                    -- remove this color from the table of available colors. shifts all elements above the removed element down
                    table.remove(tile_colors_avail, tile_color_ind)
                    -- if all available colors lead to a match.
                    -- This only happens, if the board is restricted to 2 colors and the current tile is surrounded by one color on the top and the other color on the left
                    if not next(tile_colors_avail) then
                        -- recursively initialize board
                        self:initializeTiles()
                        return
                    end
                end
            until not is_match
        end
    end

    -- alternative way (suboptimal):
    -- first place all tiles on the board and then check for matches. recursively initialize board if matches occur.
    -- This can lead to a stack overflow due to indefinite recursion when only few colors are available. Because the probability to create a matchless board is small in that case.
end

--[[
    -- swaps the grid position of two tiles on the board, but does not swap their coordinates (x, y)
    -- tile_1, tile_2: input + output. tile objects
    -- return: true if the tiles were swapped, false otherwise (if a tile is nil)
    --
    -- explanation of the swapping procedure with an example:
    -- first the two objects to swap are assigned to variables, then their position in the objects table is swapped
    obj1 = objects[1]               -- objects[1] points to an object 1 (objects[2] points to an object 2). obj1 points to the object in objects[1]
    objects[1] = objects[2]         -- objects[1] points to the object in objects[2] now, but obj1 still points to the object that was in objects[1]
    objects[2] = obj1               -- objects[2] points to the object in objects[1] now
    -- if an assignment of an object to a variable is made, then only the variable that got assigned is affected (only a pointer to the object is assigned).
    -- if a member of an object is modified, then every variable that points to that object is affected and will reflect that change
    -- if an object has no references to it any more, it will automatically get cleaned up by the Lua Garbage collection
    -- modifying an object passed as a parameter to a function follows the same logic as in python (call by object reference): when modifying object members, the outer variable will be affected. When assigning something else to the variable inside the function will not affect the outer variable.
]]
function Board:swapTilesLogically(tile_1, tile_2)
    if not tile_1 or not tile_2 then    -- don't support interaction with empty spaces
        return false
    end

    -- swap grid positions of tiles
    local tmp_tile_1_grid_x = tile_1.grid_x
    local tmp_tile_1_grid_y = tile_1.grid_y

    tile_1.grid_x = tile_2.grid_x
    tile_1.grid_y = tile_2.grid_y
    tile_2.grid_x = tmp_tile_1_grid_x
    tile_2.grid_y = tmp_tile_1_grid_y

    -- if all members of the tile object (or the whole tile object) would be swapped, than the swapped object would be the same as the original object and nothing would change!

    -- swap tiles in the tiles table
    self.tiles[tile_1.grid_y][tile_1.grid_x] = tile_1
    self.tiles[tile_2.grid_y][tile_2.grid_x] = tile_2

    return true
end

--[[
    Goes left to right, top to bottom in the board, calculating matches by counting consecutive
    tiles of the same color.
    return: true if matches or false if no matches found
]]
function Board:calculateMatches()
    local match_num = 0         -- number of consecutive same colored tiles found
    local cur_color = 0         -- color of the current tile
    local prev_color = 0        -- color of the previous tile
    self.matches = {}           -- reset matches table

    -- horizontal matches
    for y = 1, self.num_tiles_per_dimension do          -- all rows
        prev_color = 0
        match_num = 0
        for x = 1, self.num_tiles_per_dimension do      -- every tile in a row
            -- support for empty tiles: if the element at self.tiles[y][x] is nil, set cur_color to 0, else set to the color of the tile
            -- if a table is indexed by an out of range index, nil is returned implicitly
            cur_color = self.tiles[y][x] and self.tiles[y][x].color or 0
            if cur_color ~= 0 then      -- if not an empty tile
                -- for the first tile in the row (or after empty tile)
                if prev_color == 0 then
                    match_num = 1
                    prev_color = cur_color
                    goto continue_x
                end
                -- if the current tile has the same color as the previous
                if cur_color == prev_color then
                    match_num = match_num + 1
                end
            end
            -- match streak ends: if current tile doesn't match color of last tile or if empty tile or if at the end of the row (all three can be true at once)
            if cur_color ~= prev_color or cur_color == 0 or x == self.num_tiles_per_dimension then
                -- if a match occured, store the tiles that belong to the match in a table
                if match_num >= self.tiles_to_match then
                    -- table that holds every tile of the current match
                    local match = {}
                    local match_end = 0
                    -- go from where the match started to where it ended
                    if cur_color ~= prev_color or cur_color == 0 then   -- previous tile is the tile where the match ended
                        match_end = x - 1
                    else                                                -- current tile is the tile where the match ends
                        match_end = x
                    end
                    for match_x = match_end - match_num + 1, match_end do
                        table.insert(match, self.tiles[y][match_x])
                    end
                    table.insert(self.matches, match)
                end
                -- if there cannot be another match in this row
                if x > self.num_tiles_per_dimension - self.tiles_to_match + 1 then
                    break
                end
                prev_color = cur_color
                match_num = 1
            end
            ::continue_x::
        end
    end

    -- vertical matches
    for x = 1, self.num_tiles_per_dimension do          -- all columns
        prev_color = 0
        match_num = 0
        for y = 1, self.num_tiles_per_dimension do      -- every tile in a column
            cur_color = self.tiles[y][x] and self.tiles[y][x].color or 0     -- support for empty tiles: if nil set cur_color to 0
            if cur_color ~= 0 then      -- if not an empty tile
                -- for the first tile in the column (or after empty tile)
                if prev_color == 0 then
                    match_num = 1
                    prev_color = cur_color
                    goto continue_x
                end
                -- if the current tile has the same color as the previous
                if cur_color == prev_color then
                    match_num = match_num + 1
                end
            end
            -- match streak ends: if current tile doesn't match color of last tile or if empty tile or if at the end of the column (all three can be true at once)
            if cur_color ~= prev_color or cur_color == 0 or y == self.num_tiles_per_dimension then
                -- if a match occured, store the tiles that belong to the match in a table
                if match_num >= self.tiles_to_match then
                    -- table that holds every tile of the current match
                    local match = {}
                    local match_end = 0
                    -- go from where the match started to where it ended
                    if cur_color ~= prev_color or cur_color == 0 then   -- previous tile is the tile where the match ended
                        match_end = y - 1
                    else                                                -- current tile is the tile where the match ends
                        match_end = y
                    end
                    for match_y = match_end - match_num + 1, match_end do
                        table.insert(match, self.tiles[match_y][x])
                    end
                    table.insert(self.matches, match)
                end
                -- if there cannot be another match in this column
                if y > self.num_tiles_per_dimension - self.tiles_to_match + 1 then
                    break
                end
                prev_color = cur_color
                match_num = 1
            end
            ::continue_x::
        end
    end

    -- return true if number of matches > 0
    return #self.matches > 0 and true or false
end

--[[
    Remove the matches from the Board by setting the Tile objects in the Tile table to nil.
    Sets also self.matches to nil.
]]
function Board:removeMatches()
    for _, match in pairs(self.matches) do      -- for all matches (every match is a table of tile objects)
        for _, tile in pairs(match) do
            self.tiles[tile.grid_y][tile.grid_x] = nil
        end
    end
    self.matches = nil
end

--[[
    Shifts down all of the tiles that have spaces below them after removing matches.
    Fills the empty spaces above the fallen tiles with more tiles.
    returns a table that contains tweening information for all tiles that need to move.
]]
function Board:getFallingTiles()
    -- tween table
    -- table keys: tiles that need to fall down
    -- table values: destination y position of the tiles
    local tweens = {}
    local tile = nil    -- current tile

    -- move down all floating tiles
    -- for each column, go up tile by tile until a space is found
    for x = 1, self.num_tiles_per_dimension do
        local is_space = false          -- indicates if current position is empty or if there is a tile
        local space_y_start = 0         -- first space in this column from the bottom. the next tile will fall into that position.
        -- for all tiles/ sapces in the column from bottom to top
        for y = self.num_tiles_per_dimension, 1, -1 do
            tile = self.tiles[y][x]
            -- if space
            if not tile then
                is_space = true
                if space_y_start == 0 then      -- if not set yet
                    space_y_start = y
                end
            -- if previous location was a space and the current location is a tile
            elseif is_space then
                -- put the tile in the correct spot to fill out the space in the board and update its grid positions
                self.tiles[space_y_start][x] = tile
                tile.grid_y = space_y_start

                -- set the tiles prior position to nil (space)
                self.tiles[y][x] = nil

                -- this tiles y position needs to be tweened. The resulting "tweens" table can be supplied to Timer.tween()
                tweens[tile] = {
                    y = (tile.grid_y - 1) * TILE_SIZE       -- destination y position
                }

                -- the current tile was moved down to space_y_start, so the space is now 1 position above
                space_y_start = space_y_start - 1

                -- after moving down the tile, the current position is a space, so leave the value of is_space
            end
        end
    end

    -- return here if in a game mode where no new tiles get spawned
    if not self.do_fill_spaces then
        return tweens
    end

    -- create replacement tiles at the top of the screen
    local num_new_tiles_in_col = 0      -- number of new tiles that need to be added for the current column
    for x = 1, self.num_tiles_per_dimension do              -- for every column
        num_new_tiles_in_col = 0
        for y = self.num_tiles_per_dimension, 1, -1 do      -- for every tile in the column from bottom to top
            tile = self.tiles[y][x]

            -- if the tile is nil, a new one needs to be added
            if not tile then
                num_new_tiles_in_col = num_new_tiles_in_col + 1
                -- create new tile object with random color and variety
                tile = Tile(x, y, self.tile_colors[math.random(self.num_tile_colors)], math.random(TILE_NUM_VARIETIES))
                -- starting y position (above the screen).
                -- stack the the new tiles for each column on top of each other, so every tile will have the same falling velocity during the tweening (because they all have to travel the same distance)
                tile.y = -TILE_SIZE * num_new_tiles_in_col
                self.tiles[y][x] = tile     -- store the tile to its destined position on the board

                -- add a new tween for this tile
                tweens[tile] = {
                    y = (tile.grid_y - 1) * TILE_SIZE
                }
            end
        end
    end

    return tweens
end

--[[
    check if there is a potential match that can be made by swapping two tiles on the board
    performs all possible tile swaps and checks if a match occurred after each swap.
    when traversing self.tiles, the current tile only needs to be swapped with its right and bottom neighbour to make all possible swap combinations
    return: true if there is a potential match, false otherwise
]]
function Board:isPotentialMatch()
    local cur_tile = nil                -- current tile object
    local right_tile = nil              -- tile to the right of cur_tile
    local bottom_tile = nil             -- tile to the bottom of cur_tile
    local is_potential_match = false    -- gets set to true if there is a potential match

    for y = 1, self.num_tiles_per_dimension do          -- all rows
        for x = 1, self.num_tiles_per_dimension do      -- every tile in a row
            cur_tile = self.tiles[y][x]
            right_tile = self.tiles[y][x + 1]       -- will be nil if index is out of range or if actual element is nil (space on the board)
            bottom_tile = nil
            if self.tiles[y + 1] then       -- if row exists, it can be indexed without an error
                bottom_tile = self.tiles[y + 1][x]
            end
            -- swap with right and bottom tile. if any is nil, the swap fails
            if self:swapTilesLogically(cur_tile, right_tile) then
                if self:calculateMatches() then       -- check for match
                    is_potential_match = true
                end
                -- swap back again
                self:swapTilesLogically(cur_tile, right_tile)
            end
            if self:swapTilesLogically(cur_tile, bottom_tile) then
                if self:calculateMatches() then       -- check for match
                    is_potential_match = true
                end
                -- swap back again
                self:swapTilesLogically(cur_tile, bottom_tile)
            end
            if is_potential_match then
                return true
            end
        end
    end

    return false
end

function Board:render()
    for _, tile_row in pairs(self.tiles) do     -- for all rows of tiles
        for _, tile in pairs(tile_row) do       -- for all tiles in a row
            if tile then                        -- support for empty tiles (nil)
                tile:render(self.x, self.y)
            end
        end
    end
end
