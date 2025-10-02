import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/sprites"
local pd <const> = playdate
local gfx <const> = pd.graphics
local vect <const> = pd.geometry.vector2D.new
local pSize <const> = 5

class('Tile').extends()

function Tile:init(x, y)
    self.tileType = 1
    self.x = (x-1)*10
    self.y = (y-1)*10
    self.offsetXleft = 0    -- placeholders for inhereted functions
    self.offsetXright = 0
    self.offsetYtop = 0
    self.offsetYbot = 0
end

function Tile:draw()
    gfx.fillRect(self.x, self.y, 10,10)
end

-- things to remember for collision math:
-- TILE X Y  is the TOP LEFT CORNER (i think)
-- PLAYER X Y  is the CENTER POINT

function Tile:isColliding( tileLocation, playerX, playerY) -- returns boolean collision and distance from x and amount of overlap in y
                                                            -- will also return tiletype (not all return values need to be used every time)
                                                            -- amount of overlap only matters for corner detection
                                                            -- POSITIVE NUMBER MEANS OVERLAP
    local yDiff = -10  --starting calues that will alwyas be 'out of the way'
    local xDiff = -10
    --[[
    tile location: 0 is the player
    A B C
    D 0 E
    F G H
    ]]
    if tileLocation == 'A' then     
        yDiff = self.y+(3*pSize) - playerY
        xDiff = self.x+(3*pSize) - playerX + .15 --add a bit to avoid rounding issues (just needed to be more than .14)
        if (xDiff > 0 and yDiff > 0)then
            return true, xDiff, yDiff, self.tileType
        end
    elseif tileLocation == 'B' then -- add xDiff when dealing with offsets
        yDiff = self.y+(3*pSize) - playerY
        if (yDiff >= 0) then
            return true, xDiff, yDiff, self.tileType
        end
    elseif tileLocation == 'C' then
        yDiff = self.y+(3*pSize) - playerY
        xDiff = playerX - self.x+pSize
        if (xDiff > 0 and yDiff > 0)then
            return true, xDiff, yDiff, self.tileType
        end
    elseif tileLocation == 'D' then --add yDiff when dealing with offsets
        xDiff = self.x+(3*pSize) - playerX + .15 --add a bit to avoid rounding issues
        if (xDiff >= 0)then 
            return true, xDiff, yDiff, self.tileType
        end
    elseif tileLocation == 'E' then --add yDiff when dealing with offsets
        xDiff = playerX - self.x+pSize
        if (xDiff > 0) then
            return true, xDiff, yDiff, self.tileType
        end
    elseif tileLocation == 'F' then 
        yDiff = playerY - self.y+pSize 
        xDiff = self.x+(3*pSize) - playerX - .9
        if (xDiff > 0 and yDiff > 0) then
            return true, xDiff, yDiff, self.tileType
        end
    elseif tileLocation == 'G' then -- add xDiff when dealing with offsets
        yDiff = playerY - self.y+pSize
        if(yDiff > 0)then
            return true, xDiff, yDiff, self.tileType
        end
    elseif tileLocation == 'H' then
        yDiff = playerY - self.y+pSize
        xDiff = playerX - self.x+pSize-1
        if (xDiff > 0 and yDiff > 0) then
            return true, xDiff, yDiff, self.tileType
        end
    else
        return false, xDiff, yDiff, self.tileType
    end
    return false, xDiff, yDiff, self.tileType
end


---------------- END TILE CODE -----------------
-------------- START EMPTY CODE ----------------

class('Empty').extends(Tile)

function Empty:init()
    Empty.super.init(self) --dont think any of this needs to change
    self.tileType = 0
end

function Empty:draw()
    --dont draw anything
end

function Empty:isColliding( tileLocation, playerX, playerY)
    return false, -10, -10, self.tileType --nothing to collide with, always false
end

---------------- END EMPTY CODE ----------------
------------- START HALF SLABS CODE ------------

--[[
shapes needed:
    XX  .X  ..  X.    <-- to be done with offsets
    ..  .X  XX  X. 
    2   3   4   5

    X.  .X  ..  ..    <-- to be done with offsets
    ..  ..  .X  X.
    6   7   8   9

    .X  X.            <-- may need custom collision code (can put these off, but should reserve some numbers for them)
    X.  .X
    10  11
]]


------------ END HALF SLABS CODE -------------
----------- START ONE WAY TILES CODE----------
--these pretty much should work the same as regular tiles, but ignore collisions from all sides exept one







----------- END ONE WAY TILES CODE -----------