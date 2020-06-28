--[[
    GD50
    Match-3 Remake

    -- BeginGameState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state the game is in right before we start playing;
    should fade in, display a drop-down message, then transition
    to the PlayState, where we can finally use player input.
]]

BeginGameState = Class{__includes = BaseState}

function BeginGameState:init()
    -- start transition alpha at 1, to fade in
    self.transition_alpha = 255/255

    -- spawn a board and place it toward the right
    self.board = Board()
    self.board.y = VIRTUAL_HEIGHT / 2 - self.board.height / 2
    self.board.x = VIRTUAL_WIDTH - self.board.width - self.board.y      -- same distance from the left border as from the top border

    -- start the label above the screen
    self.label_y = -64
end

-- enter from StartState
function BeginGameState:enter(params)
    --
    -- animate the white screen fade-in, then animate a drop-down banner with text
    --

    -- over a period of 1 second, tween transition_alpha to 0 (transparent)
    Timer.tween(1, {
        [self] = {transition_alpha = 0}
    })
    -- once that's finished, move the text label to
    -- the center of the screen in 0.25 seconds
    :finish(function()
        Timer.tween(0.25, {
            [self] = {label_y = VIRTUAL_HEIGHT / 2 - 8}
        })
        -- after that, pause for one second with Timer.after
        :finish(function()
            Timer.after(1, function()
                -- then, animate the label going down past the bottom edge
                Timer.tween(0.25, {
                    [self] = {label_y = VIRTUAL_HEIGHT + 30}
                })
                -- once that's complete, we're ready to play!
                :finish(function()
                    gStateMachine:change('play', {
                        board = self.board
                    })
                end)
            end)
        end)
    end)
end

function BeginGameState:update(dt)
    -- update all timers
    Timer.update(dt)
end

function BeginGameState:render()
    -- render board of tiles
    self.board:render()

    -- render label and background rect (banner)
    love.graphics.setColor(95/255, 205/255, 228/255, 200/255)
    love.graphics.rectangle('fill', 0, self.label_y - 8, VIRTUAL_WIDTH, 48)
    love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
    love.graphics.setFont(gFonts['large'])
    love.graphics.printf('Get Ready',
        0, self.label_y, VIRTUAL_WIDTH, 'center')

    -- render transition foreground rectangle
    love.graphics.setColor(255/255, 255/255, 255/255, self.transition_alpha)
    love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
end
