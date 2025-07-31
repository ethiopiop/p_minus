import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/sprites"
import "player"
import "tiles"

-- WHAT I HAVE VS WHAT I WANT

--[[
movement 
    I like it. dont love it currently but im seeing the vision
    any major changes at this point are probably a bad idea
    minor changes should stop once I start making final levels
        (maybe there could be special levels with wacky/legacy physics or something idk)

levels
    having only square tiles and nothing else on a pretty small canvas isnt too inspiring
    half slabs and spikes will help a lot, but hopefully there will be other fun things in the future

    long term goal:
        several map packs
        not just 'easy' 'medium' 'hard' but actual themed packs
            maybe visual themes
            maybe gameplay style themes
            maybe unique physics themes
            maybe a story pack
            maybe restricted entity pallete
        and people should be able to use the level editor to make their own maps too!
            its just a love2d program after all
        so many cool ideas here

level editor
    holy jank
    BUT IT WORKS!!!! YOOOOO
    plain text is slow to load but its fine since that just happens once per level
    having to double implement every entity to be visible in game and in the editor will be annoying
    
    i dont think ill ever make it pretty, but just functional is good enough 
    i DO want to figure out how to give that program writing access to the actual folders with the levels in them
    so i dont have to copy paste all the time
]]


---TODO
--[[
stuff to do in order to do em
fix collision detection
    "there shouldnt be math in if statements"
    make general functions that return true or false if a collision is happening 
        (then have them be able to take offsets for half slabs)
    maybe it was a bad idea to ONLY be checking the tiles in front of you

menu
    be able to choose different levels out of a menu
    be able to finish a level
    be able to die/reset (fall/impact damage?)
        (press up to retry? misinputs could be annoying but there could be an option to turn it off)
    thats all for menus really
    
new entities! (in order of relevance, it looks like a lot, but just put them in one at a time
                                                 or when you have a bright idea of one that isnt on the list)
    
    entities should be numbered in groups of FOUR for level editor functionality
    mines (offgrid? smaller grid?)
    extra bouncy tiles
    one way walls (should be easy to implement with modular hit detection)
    45 degree slopes??? 
        (whole mess of stuff i would have to deal with to put those in the game, but would add SO much depth)
    thwompish guys (should be simple enough, and a good test of moving objects)
    player followers (I have no idea how computation intensive this is or how to implement it, but i want it)
    touch switches/doors (will have to think about how to have any amount of switches open any amount of doors)
    dream blocks? ehh
    dash refills (never refresh)
    walljump refills? ehh
    
cosmetic

    think of a neat way to display the amount of walljumps you have
    how the hecc will i be able to draw anything in a level that isnt static
    how the hecc will i be able to draw/have collision with anything offgrid (actually this shouldnt be too bad?)
    
]]

local pd <const> = playdate
local gfx <const> = pd.graphics
local vect <const> = pd.geometry.vector2D.new

pd.display.setRefreshRate(50)
local screenHeight = 240
local screenWidth = 400
local tileSize = 10

--------------    Tile Code   ---------------





---------------  Player Code  ---------------



-- OLD FUNCTION WITH INEFFICENT LEVEL STORAGE BELOW (im kepping this because that looping function might be useful to look at later)

--grid = {{1,1,1},{1,12,23},{1,5,20},{1,25,15}} --list of all elements and their locations in the 20x24 grid, for now there is only one element 1=box
                                                -- in the future making these arrays will be automated
--[[
function gridDraw(grid) -- takes a table of level data, makes a single image to print out of all the shapes
    --gfx.setColor(gfx.kColorWhite)
    --gfx.fillRect(0,0,400,240)
    gfx.setColor(gfx.kColorBlack)
    local backgroundImage = gfx.image.new(400,240)
	gfx.pushContext(backgroundImage)
    for _, g in ipairs(grid)do --reads the second two numbers in each entry, 
                               -- can read first number for item type later
        gfx.fillRect(g[2]*tileSize, g[3]*tileSize, tileSize, tileSize)
    
    end
    gfx.popContext()
	return backgroundImage

end
]]




--TESTING FILE READING
-- idk how to do json and it looks like i would need to code in C to do anything more fancy 
-- so txt files it is!
-- at least playdate got built in save functionality, but level reading/writing will have to be kinda janky
-- plan is to make the level editor in love2D (or HTML? that seems less fun)
-- LEVEL DATA THAT IS NEEDED:
--[[
1. coordinate pairs of all onscreen blocks
2. coordinate pairs of all entities/other objects (ex: player start pos and level finish location)
3. level name
4. level 'location' (file structure)
5. other stuff ill think of later
]]

local function gridDraw(grid)
    gfx.setColor(gfx.kColorBlack)
    local backgroundImage = gfx.image.new(400,240)
	gfx.pushContext(backgroundImage)
    for x = 1,40,1 do  --dont need to draw out of bounds squares (full range is 0-41 and 0-25)
        for y =1,24,1 do
            if grid[x][y] ~= 0 then
                 gfx.fillRect((x-1)*tileSize, (y-1)*tileSize, tileSize, tileSize)
                 --grid[x][y].draw() --i think this should just work?
            end
        end
    end
    gfx.popContext()
	return backgroundImage
end

local function levelRead(levelPath) --takes path to level file, returns array(s) of all data
    local grid = table.create(42,0)    
    local itemType = 0
    for i = 0,41,1 do
        grid[i] = table.create(26,0)
    end
    for x = 0,41,1 do
        for y =0,25,1 do
            if (x == 0 or y == 0 or x == 41 or y == 25)then -- fill in the borders
                --grid[x][y] = 1 -- border walls 
                grid[x][y] = Tile(x,y)
            else
                grid[x][y] = itemType -- empty space
            end
        end
    end
    local levelInfo = pd.file.open(levelPath, pd.file.kFileRead)
    local infoX = levelInfo:readline() -- do this once to get the levelname out of the way
          infoX = levelInfo:readline()
    local infoY = levelInfo:readline()
    local pX, pY = infoX*10 - 5, infoY*10 -6

    while infoX ~= nil do
        local itemType = tonumber(levelInfo:readline())
        print("item: ", itemType)
        if itemType == nil then
           break
        end
        while (infoX == infoY ~= 0) do
            infoX = tonumber(levelInfo:readline())
            infoY = tonumber(levelInfo:readline())
            if infoX == nil or infoY == nil then break end
            if infoX ~= 0 then  
                print("coord: ", infoX, infoY)
                --grid[infoX][infoY] = itemType
                grid[infoX][infoY] = Tile(infoX, infoY)
            end
        end
    end
    return pX,pY, grid
end


local function levelLoad(levelPath) --takes a constructed level grid, makes the player and returns a drawable image
    local playerPosX, playerPosY, levelGrid = levelRead(levelPath)
    local player = Player(playerPosX, playerPosY, levelGrid)
    local backgroundImage = gridDraw(levelGrid)
	return player, backgroundImage
    
end

local function levelExit() --changes game state back to menu (won't code until i have a menu)

end

local function levelNext() --goes right to the next level 
--(tbd if this is actually nessisary or if i can just do a level load again)
end

local player, levelTerrain = levelLoad("./levels/test/gridTest.txt")
--local levelTerrain = levelLoad(levelTest)
player:add()  -- these should be handled by level load



function pd.update()
    --gfx.setColor(gfx.kColorWhite)
    --gfx.fillRect(0,0,400,240)
    gfx.sprite.update()
    pd.drawFPS(0, 0)
    levelTerrain:draw(0,0)
    local gridX = player:getX() 
    --local gridY = player:getY()
    --print(gridX,gridY)
    --gfx.setColor(gfx.kColorXOR)
    --gfx.drawRect((gridX)*10, (gridY)*10, 10,10) -- H
    --gfx.drawRect((gridX)*10, (gridY-1)*10, 10,10) -- E
    --gfx.drawRect((gridX)*10, (gridY-2)*10, 10,10) -- C
    --gfx.drawRect((gridX-1)*10, (gridY-2)*10, 10,10) -- B
    --gfx.drawRect((gridX-1)*10, (gridY)*10, 10,10) -- G
    --gfx.drawRect((gridX-2)*10, (gridY)*10, 10,10) -- F
    --gfx.drawRect((gridX-2)*10, (gridY-2)*10, 10,10) -- A
    --gfx.drawRect((gridX-2)*10, (gridY-1)*10, 10,10) -- D]]

    --if player:getDir() then
    --   gfx.drawRect((gridX-2)*10, (gridY-1)*10, 10,10)
    --else
    --   gfx.drawRect((gridX)*10, (gridY-1)*10, 10,10)
    --end

end

function Player:getX()
    return math.floor(((player.position.dx)/10)+1)
end

function Player:getY()
    return math.floor(((player.position.dy)/10)+1)
end

function Player:getDir()
    return player.dir
end