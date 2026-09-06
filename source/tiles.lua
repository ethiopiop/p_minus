import("CoreLibs/graphics")
import("CoreLibs/object")
import("CoreLibs/sprites")
local pd = playdate
local gfx = pd.graphics
local vect = pd.geometry.vector2D.new
class("Tile").extends()

function Tile:init(x, y)
	self.tileType = 1
	self.x = (x - 1) * 10
	self.y = (y - 1) * 10
	self.offsetXleft = 0
	self.offsetXright = 0
	self.offsetYtop = 0
	self.offsetYbot = 0
	self.solid = true
end

function Tile:getTileType()
	return self.tileType
end

function Tile:isSolid()
	return self.solid
end

function Tile:draw()
	gfx.fillRect(self.x, self.y, 10, 10)
end

function Tile:isColliding(tileLocation, playerX, playerY)
	local yDiff = -10
	local xDiff = -10
	if tileLocation == "S" then
			return true, 0, 0, self.tileType
	elseif tileLocation == "A" then
		yDiff = self.y + 15 - playerY
		xDiff = self.x + 15 - playerX + 0.15
		if xDiff > 0 and yDiff > 0 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "B" then
		yDiff = self.y + 15 - playerY
		if yDiff >= 0 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "C" then
		yDiff = self.y + 15 - playerY
		xDiff = playerX - self.x + 5
		if xDiff > 0 and yDiff > 0 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "D" then
		xDiff = self.x + 15 - playerX + 0.15
		if xDiff >= 0 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "E" then
		xDiff = playerX - self.x + 5
		if xDiff > 0 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "F" then
		yDiff = playerY - self.y + 5
		xDiff = self.x + 15 - playerX - 0.9
		if xDiff > 0 and yDiff >= 0 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "G" then
		yDiff = playerY - self.y + 5
		if yDiff > 0 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "H" then
		yDiff = playerY - self.y + 5
		xDiff = playerX - self.x + 5 - 1
		if xDiff > 0 and yDiff >= 0 then
			return true, xDiff, yDiff, self.tileType
		end
	else
		return false, xDiff, yDiff, self.tileType
	end
	return false, xDiff, yDiff, self.tileType
end

class("Empty").extends(Tile)

function Empty:init(x, y)
	Empty.super:init(x, y)
	self.tileType = 0
	self.solid = false
end

function Empty:draw()
end

function Empty:isColliding(tileLocation, playerX, playerY)
	return false, -10, -10, self.tileType
end

class("Goal").extends(Tile)

function Goal:init(x, y)
	Goal.super.init(self, x, y)
	self.tileType = 999
end

function Goal:draw()
	gfx.fillRect(self.x - 4, self.y - 4, 18, 18)
	gfx.setColor(gfx.kColorWhite)
	gfx.fillRect(self.x - 1, self.y - 1, 12, 12)
	gfx.setColor(gfx.kColorBlack)
	gfx.fillRect(self.x + 2, self.y + 2, 6, 6)
end

function Goal:isColliding()
	print("level finished!")
	return true, 0, 0, self.tileType
end

class("SpikeU").extends(Tile)

function SpikeU:init(x, y)
	SpikeU.super.init(self, x, y)
	self.tileType = 5
	self.solid = false
end

function SpikeU:draw()
	local im = gfx.image.new("assets/05.png")
	im:draw(self.x, self.y)
end

function SpikeU:isColliding(tileLocation, playerX, playerY)
	if tileLocation == "S" then
		yDiff = self.y + 10 - playerY
		if yDiff < 6 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "A" then
		yDiff = self.y + 15 - playerY
		xDiff = self.x + 15 - playerX
		if xDiff > 1 and yDiff > 0 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "B" then
		yDiff = self.y + 15 - playerY
		if yDiff >= 0 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "C" then
		yDiff = self.y + 15 - playerY
		xDiff = playerX - self.x + 5
		if xDiff > 1 and yDiff > 0 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "D" then
		xDiff = self.x + 15 - playerX + 0.15
		yDiff = self.y + 10 - playerY
		if xDiff >= 1 and yDiff < 7 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "E" then
		xDiff = playerX - self.x + 5
		yDiff = self.y + 10 - playerY
		if xDiff > 1 and yDiff < 7 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "F" then
		yDiff = playerY - self.y + 5
		xDiff = self.x + 15 - playerX - 0.9
		if xDiff > 0 and yDiff > 6 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "G" then
		yDiff = playerY - self.y + 5
		if yDiff > 6 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "H" then
		yDiff = playerY - self.y + 5
		xDiff = playerX - self.x + 5 - 1
		if xDiff > 0 and yDiff > 6 then
			return true, xDiff, yDiff, self.tileType
		end
	else
		return false, xDiff, yDiff, self.tileType
	end
	return false, xDiff, yDiff, self.tileType
end

class("SpikeR").extends(Tile)

function SpikeR:init(x, y)
	SpikeR.super.init(self, x, y)
	self.tileType = 6
	self.solid = false
end

function SpikeR:draw()
	local im = gfx.image.new("assets/06.png")
	im:draw(self.x, self.y)
end

function SpikeR:isColliding(tileLocation, playerX, playerY)
	if tileLocation == "S" then
		xDiff = self.x + 10 - playerX
		if xDiff >= 2 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "A" then
		yDiff = self.y + 15 - playerY
		xDiff = self.x + 15 - playerX + 0.15
		if xDiff > 6 and yDiff > 0.5 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "B" then
		yDiff = self.y + 15 - playerY
		xDiff = self.x + 10 - playerX
		if yDiff >= 0.5 and xDiff >= 2 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "C" then
		yDiff = self.y + 15 - playerY
		xDiff = playerX - self.x + 5
		if xDiff > 0 and yDiff > 0.5 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "D" then
		xDiff = self.x + 15 - playerX + 0.15
		if xDiff >= 6 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "E" then
		xDiff = playerX - self.x + 5
		if xDiff > 0 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "F" then
		yDiff = playerY - self.y + 5
		xDiff = self.x + 15 - playerX - 0.9
		if xDiff > 6 and yDiff > 0 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "G" then
		yDiff = playerY - self.y + 5
		xDiff = self.x + 10 - playerX
		if yDiff > 2 and xDiff >= 2 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "H" then
		yDiff = playerY - self.y + 5
		xDiff = playerX - self.x + 5 - 1
		if xDiff > 2 and yDiff > 2 then
			return true, xDiff, yDiff, self.tileType
		end
	else
		return false, xDiff, yDiff, self.tileType
	end
	return false, xDiff, yDiff, self.tileType
end

class("SpikeD").extends(Tile)

function SpikeD:init(x, y)
	SpikeD.super.init(self, x, y)
	self.tileType = 7
	self.solid = false
end

function SpikeD:draw()
	local im = gfx.image.new("assets/07.png")
	im:draw(self.x, self.y)
end

function SpikeD:isColliding(tileLocation, playerX, playerY)
	if tileLocation == "S" then
		yDiff = self.y + 10 - playerY
		if yDiff > 2 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "A" then
		yDiff = self.y + 15 - playerY
		xDiff = self.x + 15 - playerX
		if xDiff > 0 and yDiff > 6 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "B" then
		yDiff = self.y + 15 - playerY
		if yDiff >= 6 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "C" then
		yDiff = self.y + 15 - playerY
		xDiff = playerX - self.x + 5
		if xDiff > 0 and yDiff > 6 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "D" then
		xDiff = self.x + 15 - playerX + 0.15
		yDiff = self.y + 10 - playerY
		if xDiff >= 1 and yDiff > 2 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "E" then
		xDiff = playerX - self.x + 5
		yDiff = self.y + 10 - playerY
		if xDiff > 1 and yDiff > 2 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "F" then
		yDiff = playerY - self.y + 5
		xDiff = self.x + 15 - playerX - 0.9
		if xDiff > 0 and yDiff > 0 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "G" then
		yDiff = playerY - self.y + 5
		if yDiff > 0 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "H" then
		yDiff = playerY - self.y + 5
		xDiff = playerX - self.x + 5 - 1
		if xDiff > 0 and yDiff > 0 then
			return true, xDiff, yDiff, self.tileType
		end
	else
		return false, xDiff, yDiff, self.tileType
	end
	return false, xDiff, yDiff, self.tileType
end

class("SpikeL").extends(Tile)

function SpikeL:init(x, y)
	SpikeL.super.init(self, x, y)
	self.tileType = 8
	self.solid = false
end

function SpikeL:draw()
	local im = gfx.image.new("assets/08.png")
	im:draw(self.x, self.y)
end

function SpikeL:isColliding(tileLocation, playerX, playerY)
	if tileLocation == "S" then
		xDiff = self.x + 10 - playerX
		if xDiff < 7 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "A" then
		yDiff = self.y + 15 - playerY
		xDiff = self.x + 15 - playerX + 0.15
		if xDiff >= 0 and yDiff > 0.5 then
			--print("hit spike A")
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "B" then
		yDiff = self.y + 15 - playerY
		xDiff = self.x + 10 - playerX
		--print("B", xDiff, yDiff)
		if yDiff >= 0.5 and xDiff <= 7.2 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "C" then
		yDiff = self.y + 15 - playerY
		xDiff = playerX - self.x + 5
		--print("C", xDiff, yDiff)
		if xDiff > 7 and yDiff > 0.5 then
			print("hit spike C")
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "D" then
		xDiff = self.x + 15 - playerX + 0.15
		if xDiff >= 0 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "E" then
		xDiff = playerX - self.x + 5
		if xDiff > 7 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "F" then
		yDiff = playerY - self.y + 5
		xDiff = self.x + 15 - playerX - 0.9
		if xDiff > 2 and yDiff > 2 then
			print("hit spike F")
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "G" then
		yDiff = playerY - self.y + 5
		xDiff = self.x + 10 - playerX
		if yDiff > 2 and xDiff <= 8 then
			return true, xDiff, yDiff, self.tileType
		end
	elseif tileLocation == "H" then
		yDiff = playerY - self.y + 5
		xDiff = playerX - self.x + 5 - 1
		if xDiff > 7 and yDiff > 0 then
			print("hit spike H")
			return true, xDiff, yDiff, self.tileType
		end
	else
		return false, xDiff, yDiff, self.tileType
	end
	return false, xDiff, yDiff, self.tileType
end

class("DashThrough").extends(Tile)

function DashThrough:init(x,y)
	DashThrough.super.init(self, x,y)
	self.tileType = 2
	self.solid = false
end

function DashThrough:draw()
	local im = gfx.image.new("images/dashThrough.png")
	im:draw(self.x, self.y)
end

class("WalkThrough").extends(Tile)

function WalkThrough:init(x,y)
	DashThrough.super.init(self, x,y)
	self.tileType = 3
	self.solid = false
end

function WalkThrough:draw()
	local im = gfx.image.new("images/walkThrough.png")
	im:draw(self.x, self.y)
end

-- simple tile ideas (stuff that shouldnt need custom collision code):
-- trampolines (give bigger jump/much bigger bounce, bounce you a bit for just landing on them)

-- ones below will not have corner collisions (maybe)
-- tile that kills you for dashing into it
-- tile that kills you for not dashing through it
-- one ways (should be easy the way i want to implement them?)

-- NO MORE SPIKES AND JUNK THAT TAKE UP HALF A TILE (THAT WAS AWFUL)
