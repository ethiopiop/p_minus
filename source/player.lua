import("CoreLibs/graphics")
import("CoreLibs/object")
import("CoreLibs/sprites")
local pd = playdate
local gfx = pd.graphics
local vect = pd.geometry.vector2D.new
class("Player").extends(gfx.sprite)

function Player:init(x, y, env)
	Player.super.init(self)
	self.environment = env
	self.spawnPosX = x
	self.spawnPosY = y
	self.position = vect(x, y)
	self.velocity = vect(0, 0)
	self.storedVelocity = vect(0, 0)
	self.size = 10
	self.dashCheck = 1
	self.deathCount = 0
	self.firstLoad = true
	self.grounded = false
	self.dead = false
	self.dashCount = 1
	self.dashing = 0
	self.dashType = 0
	self.dashJumpBufferTimer = 0
	self.dashBufferTimer = 0
	self.bufferTimer = 0
	self.cyoteTimer = 0
	self.jumpTimer = 0
	self.retryTimer = 0
	self.stompLockout = 0
	self.walled = 0
	self.objectNear = false
	self.dir = true
	self.terminalVelocity = 1.2
	self.terminalVelocityY = 2
	self.wallClingSpeed = 0.75
	self.wallFrict = 0.5
	self.jumpY = 1.85
	self.wallJumpX = 1.5
	self.runAcc = 0.07
	self.grav = 0.12
	self.normalGrav = 0.12
	self.jumpGrav = 0.06
	self.friction = 0.1
	self.drag = 2 * self.friction / 3
	self.dashSpeed = vect(3.5, 0)
	self.dashCooldown = 9
	self.maxJump = 10
	self.dashTotal = 1
	self.dashJumpBuffer = 4
	self.dashLockout = 2
	self.minWallJump = 0
	self.wallJumpY = 2
	self.wallJumpYReset = self.wallJumpY
	self.wallJumpXReset = self.wallJumpX
	self.walljumpCounter = 0
	self.walljumpSubtractor = 1
	self.maxJumps = 2
	self:setImage(self:draw())
	self:moveTo(self.position:unpack())
	self.dx = self.position.dx
	self.dy = self.position.dy
end

function Player:getPos()
	return math.floor(self.position.dx), math.floor(self.position.dy), 5
end

function Player:setDir(dir)
	self.dir = dir
end

function Player:getWalled()
	return self.walled
end

function Player:getGrounded()
	return self.grounded
end

function Player:getVelocity()
	return self.velocity
end

function Player:setVelocity(dv)
	self.velocity = dv
end

function Player:kill()
	self.dead = true
	STATE = "dead"
end

function Player:update()
	if not self.dead then
		self:checkCollisions()
		self:checkInputs()
		self.position = self.position + self.velocity
		--print(self.velocity.dx)
		self:moveTo(self.position:unpack())
		if self.dashCheck ~= self.dashCount then
			self:setImage(self:draw())
		end
		self.dashCheck = self.dashCount
	else
		self:deathHandler()
	end
end

function Player:draw()
	local im = gfx.image.new(self.size, self.size)
	gfx.pushContext(im)
	gfx.setColor(gfx.kColorBlack)
	gfx.fillRect(0, 0, self.size, self.size)
	if self.dashCount > 0 then
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(self.size / 4 - 1, self.size / 4 - 1, self.size / 2 + 1, self.size / 2 + 1)
	end
	gfx.popContext()
	
	return im
end

function Player:deathHandler()
	if self.dead == false then
		self.dead = true
		STATE = "dead"
	elseif not self.firstLoad then
		if pd.buttonJustPressed("a") then
			self:respawn()
			STATE = "level"
		elseif pd.buttonJustPressed("b") then
			STATE = "levelEXIT"
		end
	elseif pd.getButtonState() == 0 then
		self.firstLoad = false
	end
end

function Player:respawn()
	self.position = vect(self.spawnPosX, self.spawnPosY)
	self.velocity = vect(0, 0)
	self.firstLoad = true
	self.storedVelocity = vect(0, 0)
	self.grounded = false
	self.dashing = 0
	self.dashType = 0
	self.dashJumpBufferTimer = 0
	self.dashBufferTimer = 0
	self.bufferTimer = 0
	self.cyoteTimer = 0
	self.jumpTimer = 0
	self.retryTimer = 0
	self.stompLockout = 0
	self.walled = 0
	self.objectNear = false
	self.dir = true
	self.dashCount = 1
	self.dead = false
end

function Player:checkInputs()
	if self.dashing < self.dashLockout and self.grounded then
		self.dashCount = self.dashTotal
	end
	if self.dashing > 0 then
		self.dashing = self.dashing - 1
		if self.dashing ~= 0 or self.velocity.dx == 0 then
		elseif self.dir then
			self.velocity.dx = self.terminalVelocity - 0.2
		else
			self.velocity.dx = -(self.terminalVelocity - 0.2)
		end
	end
	if self.dashJumpBufferTimer >= 0 and self.stompLockout >= 0 then
		if pd.buttonIsPressed("left") then
			self:move(-1)
			if self.walled == 2 then
				self.walled = 0
			end
		elseif pd.buttonIsPressed("right") then
			self:move(1)
			if self.walled == 1 then
				self.walled = 0
			end
		elseif math.abs(self.velocity.dx) > 0 then
			if self.grounded then
				self.velocity.dx = self.velocity.dx - self.velocity.dx / math.abs(self.velocity.dx) * self.friction
				if math.abs(self.velocity.dx) <= self.friction then
					self.velocity.dx = 0
				end
			else
				self.velocity.dx = self.velocity.dx - self.velocity.dx / math.abs(self.velocity.dx) * self.drag
				--if math.abs(self.velocity.dx) <= self.drag then
					--self.velocity.dx = 0
				--end
			end
		end
	end
	if pd.buttonIsPressed("left") and self.walled == 1 or pd.buttonIsPressed("right") and self.walled == 2 then
		self:wallFriction()
	end
	if pd.buttonJustPressed("b") then
		self.dashBufferTimer = -4
	end
	if self.dashCount > 0 and self.dashBufferTimer < 0 then
		self.dashCount = self.dashCount - 1
		self.dashBufferTimer = 0
		self.dashJumpBufferTimer = -self.dashCooldown - self.dashJumpBuffer
		self.dashing = self.dashCooldown
		self.storedVelocity = self.velocity
		if pd.buttonIsPressed("left") then
			self.dir = false
			self.dashType = -1
			self:dash(-1)
		elseif pd.buttonIsPressed("right") then
			self.dir = true
			self.dashType = 1
			self:dash(1)
		else
			if not self.grounded then
				self.dashType = 0
			else
				self.dashType = 2
			end
			self:dash(0)
		end
	end
	if pd.buttonJustPressed("a") and not self.grounded and self.walled == 0 then
		self.bufferTimer = 0
	end
	if (pd.buttonJustPressed("a") and self.grounded) or (self.bufferTimer < 3 and self.grounded) or (pd.buttonJustPressed("a") and self.cyoteTimer < 6) then
		self.walled = 0
		if self.dashJumpBufferTimer > 0 then
			self:jumpStart()
			--print("jump", self.bufferTimer, self.cyoteTimer)
		elseif math.abs(self.dashType) == 1 then
			self:dashJump()
		else
			self:stompJump()
		end
		self.bufferTimer = 20
		self.dashJumpBufferTimer = 20
		self.cyoteTimer = 20
		self.jumpTimer = 0
	end
	if not (not pd.buttonJustPressed("a") or self.walled == 0 or self.grounded) or self.bufferTimer < 4 and self.walled ~= 0 and not self.grounded then
		if self.dashJumpBufferTimer > 0 then
			self:wallJumpStart(self.walled)
		else
			self:dashBounce()
		end
		self.bufferTimer = 20
	end
	if pd.buttonIsPressed("a") and self.jumpTimer < self.maxJump then
		self.grav = self.jumpGrav
		self.jumpTimer = self.jumpTimer + 1
	else
		self.grav = self.normalGrav
	end
	if pd.buttonJustReleased("a") and self.velocity.dy <= 0 then
		self.velocity.dy = self.velocity.dy / 2.75
		self.bufferTimer = 20
	end
	if pd.buttonJustReleased("b") then
		self.dashBufferTimer = 20
	end
	if pd.buttonJustPressed("up") then
		if self.retryTimer > 15 then
			self.retryTimer = 0
		else
			self:deathHandler()
		end
	end
	self.bufferTimer = self.bufferTimer + 1
	self.dashJumpBufferTimer = self.dashJumpBufferTimer + 1
	self.dashBufferTimer = self.dashBufferTimer + 1
	self.stompLockout = self.stompLockout + 1
	self.retryTimer = self.retryTimer + 1
	if self.grounded then
		self.cyoteTimer = 0
	else
		self.cyoteTimer = self.cyoteTimer + 1
	end
end

function Player:dash(dir)
	if dir == 0 then
		if self.dashType == 0 then
			self.velocity = vect(0, self.dashSpeed.dx)
		else
			self.velocity = vect(0, 0)
		end
	elseif math.abs(self.velocity.dx) <= self.dashSpeed.dx then
		self.velocity = self.dashSpeed * dir
	else
		self.velocity.dy = 0
		self.velocity.dx = self.velocity.dx * 1.2
	end
end

function Player:dashBounce()
	self.velocity.dx = -self.dashSpeed.dx * self.dashType * 0.8
	self.velocity.dy = self.velocity.dy - self.wallJumpYReset
	self.grounded = false
	self.dashing = 0
	self.dir = not self.dir
end

function Player:dashJump()
	
	self.velocity.dx = self.dashSpeed.dx * self.dashType * 0.8
	self.velocity.dy = self.velocity.dy - self.jumpY * 0.66
	self.grounded = false
	self.dashing = 0

end

function Player:stompJump()
	self.velocity.dy = -2.66
	self.grounded = false
	self.dashing = 0
	self.stompLockout = -8
	if self.dashType == 2 then
		self.velocity.dy = -2.33
		self.velocity = self.velocity + self.storedVelocity
	end
end

function Player:move(dir)
	if math.abs(self.velocity.dx) < self.terminalVelocity and dir * self.velocity.dx >= 0 then
		self.velocity.dx = self.velocity.dx + dir * self.runAcc
		if dir > 0 then
			self.dir = true
		else
			self.dir = false
		end
	elseif dir * self.velocity.dx < 0 then
		self.velocity.dx = self.velocity.dx + dir * self.runAcc + dir * self.friction
	else
		self.velocity.dx = self.velocity.dx + dir * self.runAcc - dir * self.friction
	end
end

function Player:jumpStart()
	self.velocity.dy = self.velocity.dy - self.jumpY
	if self.dir and self.velocity.dx == false then
		self.velocity.dx = self.velocity.dx + 0.3
	elseif self.velocity.dx == false then
		self.velocity.dx = self.velocity.dx - 0.3
	end
	self.grounded = false
end

function Player:wallJumpStart(dir)
	local X = math.floor(self.position.dx / 10 + 1)
	local Y = math.floor(self.position.dy / 10 + 1)
	if self.walljumpCounter == 0 then
		self.wallJumpY = self.wallJumpYReset
		self.wallJumpX = self.wallJumpXReset
		self.walljumpCounter = self.walljumpCounter + 1
	elseif self.walljumpCounter < self.maxJumps then
		self.walljumpCounter = self.walljumpCounter + 1
	else
		self.wallJumpY = 0
		self.wallJumpX = 2.5
	end
	if (self.environment[X + 1][Y]:getTileType() == 1 and self.environment[X - 1][Y]:getTileType() == 1 or self.environment[X + 1][Y + 1]:getTileType() == 1 and self.environment[X - 1][Y + 1]:getTileType() == 1 or self.environment[X + 1][Y - 1]:getTileType() == 1 and self.environment[X - 1][Y - 1]:getTileType() == 1) and self.environment[X][Y - 1]:getTileType() == 0 and self.environment[X][Y + 1]:getTileType() == 0 then
		if self.velocity.dy > self.minWallJump then
			self.velocity.dy = self.minWallJump
		end
		self.velocity.dy = self.velocity.dy - self.wallJumpY
		self.walled = 0
		self.stompLockout = 0
		self.dir = not self.dir
	else
		if dir == 1 then
			self.velocity.dx = self.velocity.dx + self.wallJumpX
		else
			self.velocity.dx = self.velocity.dx - self.wallJumpX
		end
		if self.velocity.dy > self.minWallJump then
			self.velocity.dy = self.minWallJump
		end
		self.velocity.dy = self.velocity.dy - self.wallJumpY
		self.walled = 0
		self.stompLockout = 0
		self.dir = not self.dir
	end
end

function Player:wallFriction()
	if self.velocity.dy > self.wallClingSpeed then
		self.velocity.dy = self.velocity.dy - self.wallFrict
	end
end

function Player:handleCollision(abc, X, Y, xDiff, yDiff, tile)
	if tile == 1 then
		if abc == "A" then
			self:handleCollisionA(X, Y, xDiff, yDiff)
		elseif abc == "B" then
			self:handleCollisionB(X, Y, xDiff, yDiff)
		elseif abc == "C" then
			self:handleCollisionC(X, Y, xDiff, yDiff)
		elseif abc == "D" then
			self:handleCollisionD(X, Y, xDiff, yDiff)
		elseif abc == "E" then
			self:handleCollisionE(X, Y, xDiff, yDiff)
		elseif abc == "F" then
			self:handleCollisionF(X, Y, xDiff, yDiff)
		elseif abc == "G" then
			self:handleCollisionG(X, Y, xDiff, yDiff)
		elseif abc == "H" then
			self:handleCollisionH(X, Y, xDiff, yDiff)
		end
	elseif tile == 999 then
		--print("end level here")
		STATE = "levelFINISH"
	elseif tile > 4 and tile <= 8 then
		self:deathHandler()
		--print("killed by: ", abc)
	elseif tile == 2 then
		if self.dashing == 0 and abc == "S" then
			self:deathHandler()
			print("killed by not dashing through!")
		end
	elseif tile == 3 and abc == "S" then
		if self.dashing > 0 then 
			self:deathHandler()
			print("killed by dashing through!")
		end
	end
end

function Player:checkCollisions()
	if self.grounded == false and self.velocity.dy < 8 and self.dashing <= 0 then
		self.velocity.dy = self.velocity.dy + self.grav
	end
	if self.grounded == true then
		self.walljumpCounter = 0
	end
	local gridX = math.floor(self.position.dx / 10 + 1)
	local gridY = math.floor(self.position.dy / 10 + 1)
	--print(gridX, gridY)
	if gridX >= 41 or gridX <=0 then self:kill() print("killed by OOB X")end -- kill you before OOB error
	if gridY >= 25 or gridY <=0 then self:kill() print("killed by OOB Y")end
	self:checkCloseCollisions(gridX, gridY, self.position.dx, self.position.dy)
end

function Player:checkCloseCollisions(X, Y, x, y)
	if self.dir then
		local wallHit = false
		if self.environment[X - 1][Y]:getTileType() ~= 0 and self.environment[X - 1][Y]:isSolid() == false then --check behind for spikes
			local collide, xDiff, yDiff, tile = self.environment[X - 1][Y]:isColliding("D", x, y)
			if collide then
				self:handleCollision("D", X, Y, xDiff, yDiff, tile)
			end
		end
		if self.environment[X + 1][Y]:getTileType() ~= 0 then
			local collide, xDiff, yDiff, tile = self.environment[X + 1][Y]:isColliding("E", x, y)
			if collide then
				self:handleCollision("E", X, Y, xDiff, yDiff, tile)
			end
			wallHit = true
		else
			if self.environment[X + 1][Y + 1]:getTileType() ~= 0 then
				local collide, xDiff, yDiff, tile = self.environment[X + 1][Y + 1]:isColliding("H", x, y)
				if collide then
					self:handleCollision("H", X, Y, xDiff, yDiff, tile)
				elseif self.walled ~= 0 and self.dashing == 0 then
					self.walled = 0
				end
			end
			if self.environment[X + 1][Y - 1]:getTileType() ~= 0 then
				local collide, xDiff, yDiff, tile = self.environment[X + 1][Y - 1]:isColliding("C", x, y)
				if collide then
					self:handleCollision("C", X, Y, xDiff, yDiff, tile)
				elseif self.walled ~= 0 and self.dashing == 0 then
					self.walled = 0
				end
			end
		end
		if wallHit == false and self.walled ~= 0 then
			self.walled = 0
		end
	else
		local wallHit = false
		if self.environment[X + 1][Y]:getTileType() ~= 0 and self.environment[X - 1][Y]:isSolid() == false then --check behind for spikes
			local collide, xDiff, yDiff, tile = self.environment[X + 1][Y]:isColliding("E", x, y)
			if collide then
				self:handleCollision("E", X, Y, xDiff, yDiff, tile)
			end
		end
		if self.environment[X - 1][Y]:getTileType() ~= 0 then
			local collide, xDiff, yDiff, tile = self.environment[X - 1][Y]:isColliding("D", x, y)
			if collide then
				self:handleCollision("D", X, Y, xDiff, yDiff, tile)
			end
			wallHit = true
		else
			if self.environment[X - 1][Y + 1]:getTileType() ~= 0 then
				local collide, xDiff, yDiff, tile = self.environment[X - 1][Y + 1]:isColliding("F", x, y)
				if collide then
					self:handleCollision("F", X, Y, xDiff, yDiff, tile)
					wallHit = true
				elseif self.walled ~= 0 and self.dashing == 0 then
					self.walled = 0
				end
			end
			if self.environment[X - 1][Y - 1]:getTileType() ~= 0 then
				local collide, xDiff, yDiff, tile = self.environment[X - 1][Y - 1]:isColliding("A", x, y)
				if collide then
					self:handleCollision("A", X, Y, xDiff, yDiff, tile)
					wallHit = true
				elseif self.walled ~= 0 and self.dashing == 0 then
					self.walled = 0
				end
			end
		end
		if wallHit == false and self.walled ~= 0 then
			self.walled = 0
		end
	end
	if self.velocity.dy < 0 then
		if self.environment[X][Y - 1]:getTileType() ~= 0 then
			local collide, xDiff, yDiff, tile = self.environment[X][Y - 1]:isColliding("B", x, y)
			if collide then
				self:handleCollision("B", X, Y, xDiff, yDiff, tile)
			end
		else
			if self.environment[X - 1][Y - 1]:getTileType() ~= 0 then
				local collide, xDiff, yDiff, tile = self.environment[X - 1][Y - 1]:isColliding("A", x, y)
				if collide then
					--print("collide A")
					self:handleCollision("A", X, Y, xDiff, yDiff, tile)
				end
			end
			if self.environment[X + 1][Y - 1]:getTileType() ~= 0 then
				local collide, xDiff, yDiff, tile = self.environment[X + 1][Y - 1]:isColliding("C", x, y)
				if collide then
					self:handleCollision("C", X, Y, xDiff, yDiff, tile)
				end
			end
		end
	end
	if self.velocity.dy >= 0 then
		local hitGround = false
		if self.environment[X][Y + 1]:isSolid() then
			local collide, xDiff, yDiff, tile = self.environment[X][Y + 1]:isColliding("G", x, y)
			if collide then
				--print("colliding G!!!!!!")
				self:handleCollision("G", X, Y, xDiff, yDiff, tile)
				hitGround = true
				--print("grounded G")
			end
		else
			if self.environment[X - 1][Y + 1]:isSolid() then
				local collide, xDiff, yDiff, tile = self.environment[X - 1][Y + 1]:isColliding("F", x, y)
				if collide then
					self:handleCollision("F", X, Y, xDiff, yDiff, tile)
					hitGround = true
					--print("grounded F")
				end
			end
			if self.environment[X + 1][Y + 1]:isSolid() then
				local collide, xDiff, yDiff, tile = self.environment[X + 1][Y + 1]:isColliding("H", x, y)
				if collide then
					self:handleCollision("H", X, Y, xDiff, yDiff, tile)
					hitGround = true
					--print("grounded H")
				end
			end
			if not hitGround then
				self.grounded = false
			end
		end
		if not self.environment[X][Y + 1]:isSolid() then
			local collide, xDiff, yDiff, tile = self.environment[X][Y + 1]:isColliding("G", x, y)
			if collide then
				--print("hit spike G!!!!!!")
				--print("spike on G")
				self:handleCollision("G", X, Y, xDiff, yDiff, tile)
			end
		end
		if hitGround == true then
			self.grounded = true
		end
	end
	if self.environment[X][Y]:getTileType() ~= 0 then
		local collide, xDiff, yDiff, tile = self.environment[X][Y]:isColliding("S", x, y)
		if collide then
			self:handleCollision("S", X, Y, xDiff, yDiff, tile)
		end
	end
end

function Player:handleCollisionA(X, Y, xDiff, yDiff)
	if xDiff <= yDiff and self.environment[X][Y - 1]:isSolid() == false and self.dir == false then
		self.velocity.dx = 0
		self.position.dx = (X - 1) * 10 + self.size / 2 + 0.15
		self.walled = 1
	elseif xDiff <= 3 and self.environment[X][Y - 1]:getTileType() == 0 then
		self.position.dx = (X - 1) * 10 + self.size / 2 + 0.15
		self.walled = 1
		--print("Corner Correct A", xDiff, yDiff)
	else
		self.velocity.dy = self.velocity.dy - self.velocity.dy
		self.position.dy = Y * 10 - self.size / 2 + 0.15
		--print("Ycollide A", xDiff, yDiff)
	end
end

function Player:handleCollisionB(X, Y, xDiff, yDiff)
	self.velocity.dy = self.velocity.dy - self.velocity.dy
	self.position.dy = Y * 10 - self.size / 2
end

function Player:handleCollisionC(X, Y, xDiff, yDiff)
	if xDiff <= yDiff and self.environment[X][Y - 1]:isSolid() == false and self.dir == true then
		self.velocity.dx = 0
		self.position.dx = X * 10 - self.size / 2
		--print("Xcollide C", xDiff, yDiff)
		self.walled = 2
	elseif xDiff <= 3 and self.environment[X][Y - 1]:getTileType() == 0 then
		self.position.dx = X * 10 - self.size / 2
		self.walled = 2
		--print("Corner Correct C")
	else
		self.velocity.dy = self.velocity.dy - self.velocity.dy
		self.position.dy = Y * 10 - self.size / 2
		--print("Ycollide C")
	end
end

function Player:handleCollisionD(X, Y, xDiff, yDiff)
	self.velocity.dx = 0
	self.position.dx = (X - 1) * 10 + self.size / 2 + 0.15
	self.walled = 1
end

function Player:handleCollisionE(X, Y, xDiff, yDiff)
	self.velocity.dx = 0
	self.position.dx = X * 10 - self.size / 2
	self.walled = 2
end

function Player:handleCollisionF(X, Y, xDiff, yDiff)
	if yDiff <= xDiff and self.environment[X - 1][Y]:isSolid() == false then
		self.velocity.dy = self.velocity.dy - self.velocity.dy
		self.position.dy = Y * 10 - self.size / 2
		self.grounded = true
		--print("Ycollide F", self.grounded, self.walled, self.dir)
	elseif self.environment[X - 1][Y]:getTileType() == 0 and yDiff <= 3 then
		--print(self.position.dy, "cornercorrect F")
		self.position.dy = Y * 10 - self.size / 2
		if self.velocity.dy < 0 then
			self.velocity.dx = self.velocity.dx + 0.1
		end
		self.velocity.dy = 0
		self.walled = 1
	elseif self.environment[X][Y + 1]:getTileType() == 0 then
		self.velocity.dx = 0
		self.position.dx = (X - 1) * 10 + self.size / 2 + 0.15
		--print("Xcollide F")
		self.walled = 1
	end
end

function Player:handleCollisionG(X, Y, xDiff, yDiff)
	self.velocity.dy = self.velocity.dy - self.velocity.dy
	self.position.dy = Y * 10 - self.size / 2
	self.grounded = true
end

function Player:handleCollisionH(X, Y, xDiff, yDiff)
	if xDiff >= yDiff - 1 and self.environment[X + 1][Y]:isSolid() == false then
		self.velocity.dy = self.velocity.dy - self.velocity.dy
		self.position.dy = Y * 10 - self.size / 2
		self.grounded = true
	elseif self.environment[X + 1][Y]:getTileType() == 0 and yDiff <= 3 then
		self.position.dy = Y * 10 - self.size / 2
		if self.velocity.dy < 0 then
			self.velocity.dx = self.velocity.dx + 0.1
		end
		self.velocity.dy = 0
		self.walled = 1
	elseif self.environment[X][Y + 1]:getTileType() == 0 then
		self.velocity.dx = 0
		self.position.dx = X * 10 - self.size / 2
		self.walled = 2
	end
end
