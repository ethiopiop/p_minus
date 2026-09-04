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
	self.wait = math.ceil(delay/3)
	self.waiter = 0
	self.active = false
	self.waiting = true
	self.im = gfx.image.new("images/chaser.png")
	self.timer = math.random(3)
end

function Follower:update(player)
	if self:collision(player) then
		if self.active == false then self.active = true 
		elseif self.waiting then --do nothing
		elseif not self.waiting then
			player:kill()
		end
	end
	if self.timer%3 == 0 then
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
	self.timer = self.timer +1
end

function Follower:draw()
	self.im:draw(self.x-6, self.y-6)
	--[[
	gfx.setLineWidth(2)
	gfx.drawRect(self.x-5, self.y-5, 10,10)
	gfx.setLineWidth(1)
	gfx.fillCircleAtPoint(self.x, self.y, self.size)
	]]
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
	self.im = gfx.image.new("images/target.png")
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
		--print("yes door")
		return true
	else
		--print("no door")
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
		self.im:draw(self.x-5,self.y-5)
	else
		gfx.fillCircleAtPoint(self.x,self.y,2)
	end
end

function Door:reset() 
	self.closed = true
end

class("Wind").extends(Entity)

function Wind:init(x,y,w,h, vx, vy)
	self.id = 4
	self.x = x
	self.y = y
	self.w = w
	self.h = h
	self.imvx = vx*1.5
	self.imvy = vy*2
	self.vx = vx/3
	self.vy = vy/3
	self.pat = gfx.image.new("images/wind.png")
	self.imX = 0
	self.imY = 0
end

function Wind:collision(p)
	local px, py, ps = p:getPos()
	local left, right, top, bottom = px - ps, px+ps, py - ps, py+ps
	local dl, dr, dt, db = self.x, self.x+self.w, self.y, self.y+self.h
	if ((right > dl and left < dr) and (bottom > dt and top < db)) then
		return true
	else
		return false
	end
end

function Wind:update(player)
	local onFloor = player:getGrounded()
		if self:collision(player) then
			local pv = player:getVelocity()
			if player:getWalled() == 0 then
				pv.dx = pv.dx + self.vx end
			if not onFloor then 
				pv.dy = pv.dy + self.vy end
			if self.vx ~= 0 then
				if pv.dx > 0 then player:setDir(true) else player:setDir(false) end 
			end
			player:setVelocity(pv)
		end
	self.imX = (self.imX + self.imvx)%8
	self.imY = (self.imY + self.imvy)%8
	
end

function Wind:draw()
	gfx.setPattern(self.pat, 8-self.imX, 8-self.imY)
	gfx.fillRect(self.x, self.y, self.w, self.h)
	gfx.setColor(gfx.kColorBlack)
end

function Wind:reset()
	self.imX = 0
	self.imY = 0
end



-- entities will have circle/ line hitboxes to keep things simpler
-- i want mines (will be basic entity class) DONEZO (put it in the level editor)
-- i want missiles I GOT CHASERS INSTEAD LFGGGG
-- i want doors/ buttons DONEZO
-- i want dust bunnies (moved to lower priority, but i would want spinners and track movers)
-- windbox? DONEZO
-- (in that order, if i get burnt out by dust bunnies then its fine)