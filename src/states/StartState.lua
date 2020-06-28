--[[
    GD50
    Match-3 Remake

    -- StartState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state the game is in when we've just started; should
    simply display "Match-3" in large text, as well as an option to start the game.
]]

StartState = Class{__includes = BaseState}

-- enter from main, GameOverState or from PlayState (if pressed esc)
function StartState:init()
    -- currently selected menu item
    self.current_menu_item = 0

    -- colors we'll use to change the title text
    self.letter_colors = {
        [1] = {217/255, 87/255, 99/255, 255/255},   -- red
        [2] = {95/255, 205/255, 228/255, 255/255},  -- blue
        [3] = {251/255, 242/255, 54/255, 255/255},  -- yellow
        [4] = {118/255, 66/255, 138/255, 255/255},  -- purple
        [5] = {153/255, 229/255, 80/255, 255/255},  -- green
        [6] = {223/255, 113/255, 38/255, 255/255}   -- orange
    }

    -- letters of MATCH 3 and their spacing relative to the center (stored separately to apply a different color to each of them)
    -- this is the same letter spacing as when the whole string is displayed with printf()
    self.letter_table = {
        {'M', -108},
        {'A', -64},
        {'T', -28},
        {'C', 2},
        {'H', 40},
        {'3', 112}
    }

    self.num_letters = #self.letter_table   -- number of table elements

    -- initialize a timer which calls a function every time interval
    -- change the color for every letter
    self.letter_color_timer = Timer.every(0.075,   -- time interval
        function()      -- anonymous function (equivalent to python lambda function) that gets called every interval
            -- shift every color to the next. set the last to first afterwards
            for i = self.num_letters, 1, -1 do
                self.letter_colors[i + 1] = self.letter_colors[i]
            end
            self.letter_colors[1] = self.letter_colors[self.num_letters + 1]
        end
    )

    -- generate a full board with tiles just for display
    self.board = Board()
    self.board.x = VIRTUAL_WIDTH / 2 - self.board.width / 2
    self.board.y = VIRTUAL_HEIGHT / 2 - self.board.height / 2

    -- used to animate the full-screen transition rect after pressing Start
    self.transition_alpha = 0

    -- if we've selected Start, we need to pause input while we animate the transition to the game screen
    self.is_pause_input = false
end

function StartState:update(dt)
    if keyboardWasPressed('escape') then
        love.event.quit()
    end

    -- update all Timers
    Timer.update(dt)

    if self.is_pause_input then
        return
    end
        
    -- change menu selection (only 2 options)
    if keyboardWasPressed('up') or keyboardWasPressed('down') then
        self.current_menu_item = (self.current_menu_item + 1) % 2
        gSounds['select']:play()
    end

    -- switch to another state with one of the menu options
    if keyboardWasPressed('enter') or keyboardWasPressed('return') then
        if self.current_menu_item == 0 then     -- start game
            -- tween (interpolate a value over a period of time), using Timer (in knife/timer.lua).
            -- transition rect's alpha to 1, then transition to the BeginGame state after the animation is over
            Timer.tween(1, {    -- duration
                -- tween self.transition_alpha to 1 over the duration. equivalent: variable = end_value * (timer / duration)
                [self] = {transition_alpha = 255/255}
            }):finish(
                function()        -- finish function gets called once the tween is finished
                    gStateMachine:change('begin-game')
                end
            )
            -- remove from Timer. Otherwise it would continue updating across all states
            self.letter_color_timer:remove()
        elseif self.current_menu_item == 1 then
            love.event.quit()
        end

        -- turn off input during transition
        self.is_pause_input = true
    end
end

function StartState:render()
    -- render the board in the background
    self.board:render()

    -- keep the background and board a little darker than normal
    -- draw a black rectangle with 50% transparency over everything
    love.graphics.setColor(0/255, 0/255, 0/255, 128/255)
    love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)

    self:drawMatch3Text()
    self:drawOptions()

    -- draw our transition rect; is normally fully transparent, unless we're moving to the next state
    love.graphics.setColor(255/255, 255/255, 255/255, self.transition_alpha)
    love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
end

-- Draw the centered MATCH-3 text with background rect.
function StartState:drawMatch3Text()
    local text_y = VIRTUAL_HEIGHT / 2 - 60

    -- draw semi-transparent rect with rounded corners behind MATCH 3
    love.graphics.setColor(255/255, 255/255, 255/255, 128/255)
    love.graphics.rectangle('fill', VIRTUAL_WIDTH / 2 - 76, text_y - 11, 150, 58, 6)

    -- draw MATCH 3 text shadows
    love.graphics.setFont(gFonts['large'])
    self:drawTextShadow('MATCH 3', text_y)

    -- print MATCH 3 letters in their current colors
    for i = 1, self.num_letters do
        love.graphics.setColor(self.letter_colors[i])
        love.graphics.printf(self.letter_table[i][1], 0, 
            text_y, VIRTUAL_WIDTH + self.letter_table[i][2],    -- y position, x position relative to the center
            'center'
        )
    end
end

-- Draw "Start" and "Quit Game" text over semi-transparent rectangles.
function StartState:drawOptions()
    local option_y = VIRTUAL_HEIGHT / 2 + 12
    
    -- draw semi-transparent rect with rounded corners behind start and quit game text
    love.graphics.setColor(255/255, 255/255, 255/255, 128/255)
    love.graphics.rectangle('fill', VIRTUAL_WIDTH / 2 - 76, option_y, 150, 58, 6)

    love.graphics.setFont(gFonts['medium'])
    -- draw Start text
    option_y = option_y + 8
    self:drawTextShadow('Start', option_y)
    
    if self.current_menu_item == 0 then
        love.graphics.setColor(99/255, 155/255, 255/255, 255/255)
    else
        love.graphics.setColor(48/255, 96/255, 130/255, 255/255)
    end
    
    love.graphics.printf('Start', 0, option_y, VIRTUAL_WIDTH, 'center')

    -- draw Quit Game text
    option_y = option_y + 25
    self:drawTextShadow('Quit Game', option_y)
    
    if self.current_menu_item == 1 then
        love.graphics.setColor(99/255, 155/255, 255/255, 255/255)
    else
        love.graphics.setColor(48/255, 96/255, 130/255, 255/255)
    end
    
    love.graphics.printf('Quit Game', 0, option_y, VIRTUAL_WIDTH, 'center')
end

--[[
    Helper function for drawing text backgrounds; draws several layers of the same text, in
    black, on top of one another for a thicker shadow.
]]
function StartState:drawTextShadow(text, y)
    love.graphics.setColor(34/255, 32/255, 52/255, 255/255)
    -- the shadow text is centered. the shadow text is drawn with several small positive x and y offsets to the original text
    love.graphics.printf(text, 2, y + 1, VIRTUAL_WIDTH, 'center')
    love.graphics.printf(text, 1, y + 1, VIRTUAL_WIDTH, 'center')
    love.graphics.printf(text, 0, y + 1, VIRTUAL_WIDTH, 'center')
    love.graphics.printf(text, 1, y + 2, VIRTUAL_WIDTH, 'center')
end
