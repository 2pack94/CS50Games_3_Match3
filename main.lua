--[[
    GD50
    Match-3 Remake

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Match-3 has taken several forms over the years, with its roots in games
    like Tetris in the 80s. Bejeweled, in 2001, is probably the most recognized
    version of this game, as well as Candy Crush from 2012, though all these
    games owe Shariki, a DOS game from 1994, for their inspiration.

    The goal of the game is to match any three tiles of the same variety by
    swapping any two adjacent tiles; when three or more tiles match in a line,
    those tiles add to the player's score and are removed from play, with new
    tiles coming from the ceiling to replace them.

    As per previous projects, we'll be adopting a retro, NES-quality aesthetic.

    Credit for graphics (amazing work!):
    https://opengameart.org/users/buch

    Credit for music (awesome track):
    http://freemusicarchive.org/music/RoccoW/

    Cool texture generator, used for background:
    http://cpetry.github.io/TextureGenerator-Online/
]]

-- keep all requires and assets in Dependencies.lua file
require 'src/Dependencies'

-- physical screen dimensions
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- virtual resolution dimensions
VIRTUAL_WIDTH = 512
VIRTUAL_HEIGHT = 288

-- speed at which the background texture will scroll (negative because its scrolled to the left)
local BACKGROUND_SCROLL_SPEED = -20
-- when this x coordinate is reached, reset it to 0 (picture gets shifted to the starting point)
-- background.png is drawn in a way that it repeats periodic with BACKGROUND_LOOPING_POINT. Its width is more than abs(BACKGROUND_LOOPING_POINT) + VIRTUAL_WIDTH
local BACKGROUND_LOOPING_POINT = -52

-- keep track of scrolling background on the X axis
local background_x = 0

-- initialize input table
local keys_pressed = {}
-- initialize mouse input table
local buttons_pressed = {}

function love.load()
    -- initialize the nearest-neighbor filter
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- set the application title bar
    love.window.setTitle('Match 3')

    -- seed the RNG
    math.randomseed(os.time())

    -- initialize the virtual resolution
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        vsync = true,
        fullscreen = false,
        resizable = true,
    })

    -- set music to loop and start
    gSounds['music']:setLooping(true)
    gSounds['music']:setVolume(0.8)
    gSounds['music']:play()

    -- initialize state machine with all state-returning functions
    gStateMachine = StateMachine {
        ['start'] = function() return StartState() end,
        ['begin-game'] = function() return BeginGameState() end,
        ['play'] = function() return PlayState() end,
        ['game-over'] = function() return GameOverState() end
    }
    gStateMachine:change('start')
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.keypressed(key)
    -- toggle fullscreen mode by pressing left alt + enter
    if love.keyboard.isDown('lalt') and (key == 'enter' or key == 'return') then
        push:switchFullscreen()
        return      -- don't use this keypress for the game logic
    end
    -- add to the table of keys pressed this frame
    keys_pressed[key] = true
end

-- callback for mouse buttons. gives the x and y of the mouse, as well as the button.
function love.mousepressed(x, y, button)
    buttons_pressed[button] = true
    -- convert to virtual resolution coordinates
    x, y = push:toGame(x, y)
    buttons_pressed['x'] = x
    buttons_pressed['y'] = y
end

function keyboardWasPressed(key)
    if keys_pressed[key] then
        return true
    end
    return false
end

function getMouseClick()
    return buttons_pressed
end

function love.update(dt)
    -- if the games freezes (e.g. when the window gets moved), dt gets accumulated and will be applied in the next update.
    -- prevent the glitches caused by that by limiting dt to 0.07 (about 1/15) seconds.
    dt = math.min(dt, 0.07)
    
    -- scroll background, used across all states. if background scrolled to BACKGROUND_LOOPING_POINT, reset its position to 0
    background_x = (background_x + BACKGROUND_SCROLL_SPEED * dt) % BACKGROUND_LOOPING_POINT

    gStateMachine:update(dt)

    keys_pressed = {}
    buttons_pressed = {}
end

function love.draw()
    push:start()

    -- background should be drawn regardless of state
    love.graphics.draw(gTextures['background'], background_x, 0)
    
    gStateMachine:render()
    push:finish()
end
