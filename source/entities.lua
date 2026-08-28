import("CoreLibs/graphics")
import("CoreLibs/object")
import("CoreLibs/sprites")
local pd = playdate
local gfx = pd.graphics
local vect = pd.geometry.vector2D.new
class("Entity").extends()

function Entity:init(x, y, state)
	self.id = 1
	self.x = x --these will be on finer grid (but still saved as plain coordinates if it becomes important later)
	self.y = y
	self.size = 4
	if state == -1 then
		self.state = false 
	else self.state = true end
	self.initialState = self.state
	self.state2 = false
end

function Entity:getEntityType()
	return self.id
end

function Entity:draw()
	--print('drawing')
	if self.state then 
		gfx.fillCircleAtPoint(self.x, self.y, self.size)
	else
		gfx.drawCircleAtPoint(self.x, self.y, self.size)
	end
end

function Entity:update(player)

	if self:collision(player) then --collide
		if self.state then
			player:kill()
			
		elseif not self.state then
			self.state2 = true
		end
	else -- not colliding
		if self.state2 then -- turn on mine if you have touched it
			self.state = true
			self.state2 = false
		end
	end
end

function Entity:collision(player)
	local centerX, centerY, radius = player:getPos()
	--print (centerX, centerY, self.x, self.y)
	local dx = centerX - self.x 
	local dy = centerY - self.y 
	local dist = math.sqrt(dx*dx +  dy*dy)
	if dist < radius + self.size then return true else return false end
end

function Entity:reset()
	self.state = self.initialState
	self.state2 = false
end

class("Follower").extends(Entity)

function Follower:init(x,y, delay)
	self.x = x
	self.y = y
	self.startPosx = x
	self.startPosy = y
	self.pos = {}
	self.size = 3
	self.id = 2
	self.wait = delay
	self.waiter = 0
	self.active = false
	self.waiting = true
end

function Follower:update(player)
	if self:collision(player) then
		if self.active == false then self.active = true 
		elseif self.waiting then --do nothing
		elseif not self.waiting then
			player:kill()
		end
	end
	if self.active then
		if self.waiter < self.wait then
			table.insert(self.pos, vect(player:getPos()))
			self.waiter = self.waiter + 1
		else
			self.waiting = false
			self.x, self.y = self.pos[1].dx, self.pos[1].dy
			table.remove(self.pos, 1)
			table.insert(self.pos, vect(player:getPos()))
		end
	end
end

function Follower:draw()
	gfx.setLineWidth(2)
	gfx.drawRect(self.x-5, self.y-5, 10,10)
	gfx.setLineWidth(1)
	gfx.fillCircleAtPoint(self.x, self.y, self.size)
end

function Follower:reset()
	self.x = self.startPosx
	self.y = self.startPosy
	self.waiter = 0
	self.active = false
	self.waiting = true
	self.pos = {}
end

class("Door").extends(Entity)

function Door:init(x, y, doorx, doory, hor, length) --6 info!!
	self.id = 3
	self.x = x
	self.y = y
	self.size = 5
	self.doorX = doorx
	self.doorY = doory
	if hor == -1 then self.horizantal = true else self.horizantal = false end
	if self.horizantal then 
		self.doorWidth = length
		self.doorHeight = 4
	else
		self.doorWidth = 4
		self.doorHeight = length
	end
	self.closed = true
end

function Door:hitDoor(px, py, ps)
	local left, right, top, bottom = px - ps, px+ps, py - ps, py+ps
	local dl, dr, dt, db = self.doorX, self.doorX+self.doorWidth, self.doorY, self.doorY+self.doorHeight
	if ((right > dl and left < dr) and (bottom > dt and top < db)) then
		print("yes door")
		return true
	else
		print("no door")
		return false
	end
end

function Door:update(player)
	local pX, pY, pS = player:getPos()
	if self.closed then
		if self:collision(player) then --if you hit the button
			self.closed = false
		end
		if self:hitDoor(pX, pY, pS) then
				player:kill()
		end
	end
end

function Door:draw()
	local x = self.x
	local y = self.y
	if self.closed then
		gfx.setLineWidth(2)
		gfx.drawRect(self.doorX, self.doorY, self.doorWidth, self.doorHeight)
		gfx.setLineWidth(1)
		gfx.drawLine(x - 3, y -3, x + 3, y +3)
		gfx.drawLine(x+ 3, y - 3, x-3,y +3)
	else
		gfx.drawLine(x - 3, y -3, x-3, y +3)
		gfx.drawLine(x+ 3, y - 3,x + 3, y +3 )
	end
end

function Door:reset() 
	self.closed = true
end



-- entities will have circle/ line hitboxes to keep things simpler
-- i want mines (will be basic entity class) DONEZO (put it in the level editor)
-- i want missiles I GOT CHASERS INSTEAD LFGGGG
-- i want doors/ buttons DONEZO
-- i want dust bunnies
-- windbox? (how do i draw that??)
-- (in that order, if i get burnt out by dust bunnies then its fine)