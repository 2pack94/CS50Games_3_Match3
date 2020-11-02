--[[
    GD50
    Match-3 Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    State in which we can actually play, moving around a grid cursor that
    can swap two tiles; when two tiles make a legal swap (a swap that results
    in a valid match), perform the swap and destroy all matched tiles, adding
    their values to the player's point score. The player can continue playing
    until the time runs out, at which point they are brought back to the
    game over screen.
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()
    -- position in the grid which is highlighted by a rectangle
    -- range: 1 - <number of tiles per board dimension>
    self.board_cursor_x = 1
    self.board_cursor_y = 1

    -- to toggle the highlight cursor's color by a timer
    self.is_cursor_highlighted = false

    -- when calculating/ removing the matches no input shall be processed
    self.allow_input = true

    -- currently highlighted tile
    self.highlighted_tile = nil

    self.score = 0
    self.time_to_play = 180        -- play time in seconds (gets decremented)

    -- an info text should be shown for some seconds on the screen, when there are no more matches to make and the board gets reset
    self.is_no_matches_text = false
    self.no_matches_text_timer = nil

    -- turn cursor highlight on and off
    Timer.every(0.5, function()
        self.is_cursor_highlighted = not self.is_cursor_highlighted
    end)

    -- subtract 1 from self.time_to_play every second
    Timer.every(1, function()
        self.time_to_play = self.time_to_play - 1

        -- play warning sound every second if not much time left to play
        if self.time_to_play <= 5 then
            gSounds['clock']:play()
        end
    end)
end

-- enter from BeginGameState
function PlayState:enter(params)
    -- get the board
    self.board = params.board
end

function PlayState:update(dt)
    if keyboardWasPressed('escape') then
        gSounds['error']:play()
        -- clear all timers (across all states)
        Timer.clear()
        gStateMachine:change('start')
    end

    -- go to Game Over Screen if time runs out
    if self.time_to_play <= 0 then
        -- clear all timers (across all states)
        Timer.clear()

        gSounds['game-over']:play()

        gStateMachine:change('game-over', {
            score = self.score
        })
    end

    -- perform a game action when a key is pressed
    self:processInput()

    Timer.update(dt)
end

function PlayState:processInput()
    -- move cursor around based on bounds of grid, playing sounds
    if keyboardWasPressed('up') then
        self.board_cursor_y = math.max(1, self.board_cursor_y - 1)
        gSounds['select']:play()
    elseif keyboardWasPressed('down') then
        self.board_cursor_y = math.min(self.board.num_tiles_per_dimension, self.board_cursor_y + 1)
        gSounds['select']:play()
    elseif keyboardWasPressed('left') then
        self.board_cursor_x = math.max(1, self.board_cursor_x - 1)
        gSounds['select']:play()
    elseif keyboardWasPressed('right') then
        self.board_cursor_x = math.min(self.board.num_tiles_per_dimension, self.board_cursor_x + 1)
        gSounds['select']:play()
    end

    local mouse = getMouseClick()
    -- if clicked left mouse button, select a tile by moving the cursor to the mouse click location
    if mouse[1] then
        -- if clicked inside the board
        if mouse.x >= self.board.x and mouse.x <= self.board.x + self.board.width and mouse.y >= self.board.y and mouse.y <= self.board.y + self.board.height then
            gSounds['select']:play()
            -- convert mouse coordinates to board grid positions
            self.board_cursor_x = math.floor((mouse.x - self.board.x) / TILE_SIZE + 1)
            self.board_cursor_y = math.floor((mouse.y - self.board.y) / TILE_SIZE + 1)
        end
    end

    -- if clicked right mouse button, remove selection
    if mouse[2] then
        self.highlighted_tile = nil
    end

    -- if pressed enter or left mouse, to select, deselect or swap a tile
    if self.allow_input and (keyboardWasPressed('enter') or keyboardWasPressed('return') or mouse[1]) then
        local selected_tile = self.board.tiles[self.board_cursor_y][self.board_cursor_x]
        if not selected_tile then   -- support for empty spaces (but don't support interaction)
            return
        end

        -- if nothing is highlighted, highlight currently selected tile
        if not self.highlighted_tile then
            self.highlighted_tile = selected_tile
        -- if selecting a tile already highlighted, remove highlight
        elseif self.highlighted_tile == selected_tile then
            self.highlighted_tile = nil
        -- if the distance between the positions (x, y) of the current selected tile
        -- and the previous highlighted is greater 1
        elseif math.abs(self.highlighted_tile.grid_x - self.board_cursor_x) + math.abs(self.highlighted_tile.grid_y - self.board_cursor_y) > 1 then
            -- if playing with mouse, select the tile that was clicked. else deselect the tile
            if not mouse[1] then
                gSounds['error']:play()
                self.highlighted_tile = nil
            else
                self.highlighted_tile = selected_tile
            end
        -- there was a tile previously selected and now a tile that is next to it is selected
        else
            local tile_pos_swap_time = 0.15      -- time to swap the two tiles in seconds
            -- swap grid positions of the tiles
            self.board:swapTilesLogically(selected_tile, self.highlighted_tile)

            -- the following tweens need to finish before this point is entered again
            -- disable input to protect them or else this would result in buggy behavior
            self.allow_input = false

            -- if match occurs after swapping
            if self.board:calculateMatches() then
                -- tween coordinates between the two tiles to swap them visually
                Timer.tween(tile_pos_swap_time, {
                    [self.highlighted_tile] = {x = selected_tile.x, y = selected_tile.y},
                    [selected_tile] = {x = self.highlighted_tile.x, y = self.highlighted_tile.y}
                })
                -- once the swap is finished, falling blocks are tweened as needed after removing the matching tiles
                :finish(function()
                    self:getMatches()
                end)
            -- if no match occurs after swapping
            else
                -- create visual effect: tile moves only halfway to its destination, and goes back again
                local tmp_highlighted_tile_x = self.highlighted_tile.x
                local tmp_highlighted_tile_y = self.highlighted_tile.y
                Timer.tween(tile_pos_swap_time / 2, {
                    [self.highlighted_tile] = {
                        x = selected_tile.x + (self.highlighted_tile.x - selected_tile.x) / 2,
                        y = selected_tile.y + (self.highlighted_tile.y - selected_tile.y) / 2
                    }
                })
                :finish(function()
                    Timer.tween(tile_pos_swap_time / 2, {
                        [self.highlighted_tile] = {x = tmp_highlighted_tile_x, y = tmp_highlighted_tile_y}
                    })
                    :finish(function()
                        self.allow_input = true
                    end)
                end)

                gSounds['error']:play()
                -- swap grid positions of the tiles back again
                self.board:swapTilesLogically(selected_tile, self.highlighted_tile)
            end
        end
    end
end

--[[
    Calculates whether any matches were found on the board and removes tiles from the board that
    have matched. Tweens the floating tiles to their new destinations after the removal.
    New randomized tiles are spawned. Deferring most of this to the Board class.
]]
function PlayState:getMatches()
    self.highlighted_tile = nil

    -- if there are any matches, remove them and tween the resulting falling blocks
    if self.board:calculateMatches() then
        self.allow_input = false

        gSounds['match']:stop()
        gSounds['match']:play()

        -- add the score for each match
        for _, match in pairs(self.board.matches) do
            self.score = self.score + #match * 50
        end

        -- remove any tiles that matched from the board, resulting in empty spaces
        self.board:removeMatches()

        -- gets a table with tween values for tiles that shall now fall
        local tween_tiles_to_fall = self.board:getFallingTiles()

        -- tween tiles that are floating on the board and that spawn from the ceiling to fill in the gaps
        Timer.tween(0.5, tween_tiles_to_fall):finish(function()
            -- recursively call function when finished tweening in case new matches have been created
            -- as a result of falling blocks
            self:getMatches()
        end)
    
    -- if no more matches, continue playing
    else
        -- after all matches were resolved (when all getMatches() calls are over), check if there is still a potential match to make on the board
        -- if no matches available, generate a new board and display an info text
        if not self.board:isPotentialMatch() then
            -- if the board gets reset, display an info text for some seconds
            self.is_no_matches_text = true

            -- remove before setting again. Because when the timer is still running when reaching this point, the timer time should be reset
            if self.no_matches_text_timer then
                self.no_matches_text_timer:remove()
            end
            self.no_matches_text_timer = Timer.after(4, function()
                self.is_no_matches_text = false
            end)
            
            repeat
                self.board:initializeTiles()
            until self.board:isPotentialMatch()
        end

        self.allow_input = true
    end
end

function PlayState:render()
    -- render board with its tiles
    self.board:render()

    -- render highlighted tile if it exists
    if self.highlighted_tile then
        -- The pixel colors of the highlight rect that is drawn over the tile are added to the pixel colors of the tile.
        love.graphics.setBlendMode('add')

        love.graphics.setColor(255/255, 255/255, 255/255, 96/255)
        love.graphics.rectangle('fill',
            (self.highlighted_tile.grid_x - 1) * TILE_SIZE + self.board.x,
            (self.highlighted_tile.grid_y - 1) * TILE_SIZE + self.board.y,
            TILE_SIZE, TILE_SIZE, 4)

        -- reset to alpha blending
        love.graphics.setBlendMode('alpha')
    end

    -- render highlight cursor color based on timer
    if self.is_cursor_highlighted then
        love.graphics.setColor(217/255, 87/255, 99/255, 255/255)
    else
        love.graphics.setColor(172/255, 50/255, 50/255, 255/255)
    end

    -- draw actual cursor (rectangle outline around a tile)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle('line',
        (self.board_cursor_x - 1) * TILE_SIZE + self.board.x,
        (self.board_cursor_y - 1) * TILE_SIZE + self.board.y,
        TILE_SIZE, TILE_SIZE, 4)

    -- GUI text
    love.graphics.setColor(56/255, 56/255, 56/255, 234/255)
    love.graphics.rectangle('fill', 16, 16, 186, 58, 4)

    love.graphics.setColor(99/255, 155/255, 255/255, 255/255)
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Score: ' .. tostring(self.score), 20, 24, 182, 'center')
    love.graphics.printf('Time: ' .. tostring(self.time_to_play), 20, 52, 182, 'center')

    -- if the board gets reset, display an info text for some seconds
    if self.is_no_matches_text then
        love.graphics.setColor(56/255, 56/255, 56/255, 234/255)
        love.graphics.rectangle('fill', 16, 90, 186, 58, 4)

        love.graphics.setColor(99/255, 155/255, 255/255, 255/255)
        love.graphics.setFont(gFonts['medium'])
        love.graphics.printf('No more Matches!', 20, 98, 182, 'center')
        love.graphics.printf('Generate new Board', 20, 126, 182, 'center')
    end
end
