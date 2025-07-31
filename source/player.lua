import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/sprites"

local pd <const> = playdate
local gfx <const> = pd.graphics
local vect <const> = pd.geometry.vector2D.new


class('Player').extends(gfx.sprite)
function Player:init(x,y,env)
    Player.super.init(self)

    -- data
    self.environment = env
    self.position = vect(x,y)
    self.velocity = vect(0,0)
    self.storedVelocity = vect(0,0)
    self.size = 10 -- placeholder, will make an actual sprite someday
    self.dashCheck = 1

    -- player state infomation, on ground or wall, facing left or right etc
        -- will add buffer windows/cyote time/ dash time(?)/velocity storage here in the future
    self.grounded = false
    self.dashing = 0 
    self.dashType = 0 -- 1 for horizantal dashes and 0 for stomp
    self.dashJumpBufferTimer = 0
    self.dashBufferTimer = 0
    self.bufferTimer = 0
    self.jumpTimer = 0
    self.stompLockout = 0
    self.walled = 0   -- 0 is not on wall, 1 is on left wall, 2 is right wall
    self.objectNear = false
    self.dir = true -- true is right, false is left

    -- constants
                                        --LEGACY VALUES:
    self.terminalVelocity = 1.5         -- 2.5
    self.terminalVelocityY = 2
    self.wallClingSpeed = .75           -- 1.25
    self.wallFrict = 0.5                -- 0.5
    self.jumpY = 1.85                   -- 3  
    self.jumpX = 1.5                    -- 1.5 
    self.runAcc = .07                   -- .07
    self.grav = .12                     -- .14
    self.normalGrav = .12               -- .14
    self.jumpGrav = .06                 -- .08
    self.friction = .1                  -- .1
    self.drag = 2*self.friction/3         -- self.friction/2
    self.dashSpeed = vect(3.5,0)
    self.dashCooldown = 9
    self.maxJump = 10
    self.dashCount = 1
    self.dashTotal = 1
    self.dashJumpBuffer = 4
    self.dashLockout = 3 --the amount of frames you get to get an extended
    self.minWallJump = 0
    self.wallJumpY = 2
    self.wallJumpYReset = self.wallJumpY
    self.walljumpCounter = 0
    self.walljumpSubtractor = 1
    self.maxJumps = 2

    --idk what this does it seems important
    self:setImage(self:draw())
	--self:setCollideRect( 0, 0, self:getSize()) -- why did i do collisions manually when this is here ICANT 
                                                -- (i mean i like my custom stuff and whatnot but still)
	self:moveTo(self.position:unpack())

    self.dx = self.position.dx
    self.dy = self.position.dy

end

function Player:update() -- UPDATE FUNCTION
    
    self:checkCollisions()
    self:checkInputs()
    self.position += self.velocity
    self:moveTo(self.position:unpack())
    --print(self.position.dx, self.position.dy)
    if self.dashCheck ~= self.dashCount then
        self:setImage(self:draw())
        --print("redraw", self.dashCount)
    end
    self.dashCheck = self.dashCount
end

function Player:draw()
    local im = gfx.image.new(self.size , self.size) --sprites draw images so this makes image of a square
	gfx.pushContext(im)
    gfx.setColor(gfx.kColorBlack)
	gfx.fillRect(0, 0, self.size,self.size)
    if self.dashCount > 0 then
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect((self.size/4)-1, (self.size/4)-1, (self.size/2)+1, (self.size/2)+1)
    end
	gfx.popContext()
	return im	
end

-- COLLISIONS BELOW --

function Player:checkCollisions() 
    if (self.grounded == false and self.velocity.dy < 8 and self.dashing <= 0)then -- ""nothing"" collision, if youre in the air you are falling
        self.velocity.dy += self.grav
    end
    if self.grounded == true then
        self.walljumpCounter = 0
    end
    local gridX = math.floor(((self.position.dx)/10)+1) -- location in the grid is offset by 1 for buffer zone outside of drawn screen
    local gridY = math.floor(((self.position.dy)/10)+1)
    --print(self.walled, self.position.dx, self.position.dy)
    self:checkCloseCollisions(gridX, gridY, self.position.dx, self.position.dy)

    self:checkCloseCollisions(gridX, gridY, self.position.dx+self.velocity.dx, self.position.dy+self.velocity.dy)
    print(self.grounded,self.walled)
    
  
    
 
end

function Player:checkCloseCollisions(X, Y, x, y)  --TODO: rework with functions to make more modular/readable at some point (just some copy pasting hopefully)
    
    -- if moving right, do right side collisions (eject player to the left side of blocks etc)
    -- if moving left, do left side
    -- always do up and down checks
    -- this means explicitly checking uhh FIVE tiles per frame with a block in range?
    -- thats a LOT better than checking everything all the time but, uh, we will see if it still needs to be improved later
    -- im down to rewrite the logic, but getting the interactions down first is important
    --[[ (0 for player)
        A B C
        D 0 E
        F G H
    ]]
      --print(self.walled, self.position.dx)
    if(self.dir) then --can assume positive x velocity, need to cover 'C' 'E' and 'H' 
        if(self.environment[X+1][Y] ~= 0)then
            local collide, xDiff, yDiff, tile = self.environment[X+1][Y]:isColliding('E', x, y) 
            if(collide)then
                self:handleCollisionE(X, Y, xDiff, yDiff, tile)
            end
        elseif(self.environment[X+1][Y+1] ~= 0)then
            local collide, xDiff, yDiff, tile = self.environment[X+1][Y+1]:isColliding('H', x, y) 
            if (collide)then
                self:handleCollisionH(X, Y, xDiff, yDiff, tile)
            end
        elseif(self.environment[X+1][Y-1] ~= 0)then
            local collide, xDiff, yDiff, tile = self.environment[X+1][Y-1]:isColliding('C', x, y) 
            if (collide)then
                self:handleCollisionC(X, Y, xDiff, yDiff, tile)
            end
        else
            print("zeroed")
            self.walled = 0
        end
    else              --can assume negative x velocity, need to cover 'A' 'D' and 'F' 
        if(self.environment[X-1][Y] ~= 0)then
            local collide, xDiff, yDiff, tile = self.environment[X-1][Y]:isColliding('D', x, y) 
            if (collide)then
                self:handleCollisionD(X, Y, xDiff, yDiff, tile)
            end      
        elseif(self.environment[X-1][Y+1] ~= 0)then
            local collide, xDiff, yDiff, tile = self.environment[X-1][Y+1]:isColliding('F', x, y) 
            if (collide)then
                self:handleCollisionF(X, Y, xDiff, yDiff, tile)
            end
        elseif(self.environment[X-1][Y-1] ~= 0)then
            local collide, xDiff, yDiff, tile = self.environment[X-1][Y-1]:isColliding('A', x, y)
            if (collide)then
                self:handleCollisionA(X, Y, xDiff, yDiff, tile)
            end
        else
            print("zeroed")
            self.walled = 0
        end
    end
-- vertical collisions : always check for floor, since you might not be moving but still have to collide with the floor
    if (self.velocity.dy < 0)then
        if(self.environment[X][Y-1] ~=0) then -- covering just 'B'
            local collide, xDiff, yDiff, tile = self.environment[X][Y-1]:isColliding('B', x, y) 
            if (collide)then
                self:handleCollisionB(X, Y, xDiff, yDiff, tile)
            end
        elseif (self.environment[X-1][Y-1] ~= 0) then -- covering 'A' 
            local collide, xDiff, yDiff, tile = self.environment[X-1][Y-1]:isColliding('A', x, y)
            if (collide)then
                self:handleCollisionA(X, Y, xDiff, yDiff, tile)
               
            end
        elseif (self.environment[X+1][Y-1] ~= 0) then -- covering 'C'
            local collide, xDiff, yDiff, tile = self.environment[X+1][Y-1]:isColliding('C', x, y) 
            if (collide)then
                self:handleCollisionC(X, Y, xDiff, yDiff, tile)
            end
        end
    end

    if(self.velocity.dy >= 0) then
        if(self.environment[X][Y+1] ~= 0) then -- covering just 'G'       
            local collide, xDiff, yDiff, tile = self.environment[X][Y+1]:isColliding('G', x, y) 
            if (collide)then
                self:handleCollisionG(X, Y, xDiff, yDiff, tile)
                
            end
        elseif((self.environment[X-1][Y+1] ~= 0) ) then --covering just 'F'
            local collide, xDiff, yDiff, tile = self.environment[X-1][Y+1]:isColliding('F', x, y) 
            if (collide)then
                self:handleCollisionF(X, Y, xDiff, yDiff, tile)
                
            end
        elseif((self.environment[X+1][Y+1] ~= 0)) then --covering just 'H'
            local collide, xDiff, yDiff, tile = self.environment[X+1][Y+1]:isColliding('H', x, y) 
            if (collide)then
                self:handleCollisionH(X, Y, xDiff, yDiff, tile)
               
            end
        else
            self.grounded = false
        end  
    end
end

-- MOVEMENT BELOW --

function Player:checkInputs()
    --print(self.jumpTimer)
    --print(self.dashing)
    --movement
    --print(self.dir)
    --print(self.dashCount, self.velocity.dx)

   
    
    if (self.dashing > 0) then --dash inventory management
        self.dashing -= 1
        if self.dashing < self.dashLockout and self.grounded then
            self.dashCount = self.dashTotal
        end
        if self.dashing == 0 then
            if self.velocity.dx == 0 then
                --do nothing
            elseif self.dir then
                self.velocity.dx = self.terminalVelocity - .2
            else
                self.velocity.dx = -(self.terminalVelocity - .2)
            end
            --print(self.velocity)
        end
    end

    --print(self.dashJumpBufferTimer)
    if self.dashJumpBufferTimer >= 0 and self.stompLockout >= 0 then --lock out movement while dashing
        if pd.buttonIsPressed("left") then
            self:move(-1)
        elseif pd.buttonIsPressed("right") then
            self:move(1)
        elseif (math.abs(self.velocity.dx) > 0)then   --theres still friction if you arent pushing any buttons
            if self.grounded then 
                self.velocity.dx = self.velocity.dx - (self.velocity.dx/math.abs(self.velocity.dx))*self.friction
                if(math.abs(self.velocity.dx) <= self.friction)then
                    self.velocity.dx = 0;
                end
            else
                self.velocity.dx = self.velocity.dx - (self.velocity.dx/math.abs(self.velocity.dx))*self.drag
                if(math.abs(self.velocity.dx) <= self.drag)then
                    self.velocity.dx = 0;
                end
            end
            
        end
    end    
    -- wall friction
    if(pd.buttonIsPressed("left") and self.walled == 1) or (pd.buttonIsPressed("right") and self.walled == 2) then
        self:wallFriction()
    end

 
    -- DASH CODE
    if (pd.buttonJustPressed("b"))then
        self.dashBufferTimer = -4
    end
    --print (self.dashBufferTimer)
    if self.dashCount > 0 then --only dash when you have a dash
    if (self.dashBufferTimer < 0) then
        self.dashCount -= 1
        self.dashBufferTimer = 0
        self.dashJumpBufferTimer = -self.dashCooldown - self.dashJumpBuffer --4 extra frames after dash ends to hit jumps
        --pd.wait(80) -- 60 milliseconds should be 3 frames, game will only check what direction you are holding after the freeze
        self.dashing = self.dashCooldown
        self.storedVelocity = self.velocity
        
        if(pd.buttonIsPressed("left"))then
            self.dir = false
            self.dashType = -1
            self:dash(-1)
        elseif(pd.buttonIsPressed("right"))then
            self.dir = true
            --print("dash dir")
            self.dashType = 1
            self:dash(1)
        else
            if( not self.grounded)then
                self.dashType = 0
            else
                self.dashType = 2 --special effect when stomping on the floor
            end
                self:dash(0)
        end
    end
    end

    -- JUMP CODE (height changed by constant in init)    
    if (pd.buttonJustPressed("a") and not self.grounded and self.walled == 0) then --starts the buffer for your jumps
        self.bufferTimer = 0                                                        --same buffer for dashjumps, the dash buffer timer just determines which jump happens
    end

    --print(self.walled, self.grounded)
    if ((pd.buttonJustPressed("a") and self.grounded) or (self.bufferTimer < 3 and self.grounded)) then --all the jumping
            print("floorjump")
            self.walled = 0;
            if self.dashJumpBufferTimer > 0 then self:jumpStart() 
            elseif math.abs(self.dashType) == 1 then self:dashJump() 
            else self:stompJump()  end
            self.bufferTimer = 20
            self.dashJumpBufferTimer = 20
            self.jumpTimer = 0
    end    -- walljumps
    if (pd.buttonJustPressed("a") and self.walled ~= 0 and not self.grounded) or (self.bufferTimer < 4 and self.walled ~= 0 and not self.grounded) then --jumpstart 
        print("walljump")
        if self.dashJumpBufferTimer > 0 then self:wallJumpStart(self.walled)
        else self:dashBounce()  end
        self.bufferTimer = 20
    end
    

    --jump physics that should always happen regardless of jump type
    if pd.buttonIsPressed("a") and self.jumpTimer < self.maxJump then --jumphold
        self.grav = self.jumpGrav
        self.jumpTimer += 1
    else
        self.grav = self.normalGrav
    end
    if (pd.buttonJustReleased("a") and self.velocity.dy <= 0)then --jumpfall
        self.velocity.dy = self.velocity.dy/2.75
        self.bufferTimer = 20
    end
    if pd.buttonJustReleased("b") then
        self.dashBufferTimer = 20
    end

    self.bufferTimer += 1 -- lots of timers =_=
    self.dashJumpBufferTimer += 1
    self.dashBufferTimer += 1
    self.stompLockout += 1
   --print(self.bufferTimer)


end

function Player:dash(dir) -- left = -1, right = 1, neutral(down) = 0
    self.velocity = self.dashSpeed*dir
    self.walljumpCounter = 0
    if dir == 0 then
        if self.dashType == 0 then
            self.velocity = vect(0, self.dashSpeed.dx) 
        else
            self.velocity = vect(0,0)
        end
    end
end

function Player:dashBounce() -- symmetrical function, just inverts your speed
    --print("BOUNCE", self.dir)
    self.velocity.dx = -self.dashSpeed.dx * self.dashType * .8 
    self.velocity.dy -= self.wallJumpYReset
    self.grounded = false
    self.dashing = 0
    self.dir = not self.dir
    --print(self.dir)
end

function Player:dashJump() --to super or to hyper, that is the question (REMEMBER FOR LEVEL DESIGN -- THIS IS ADVANCED TECH)
    --print("hyper")
    self.velocity.dx = self.dashSpeed.dx * self.dashType * .8
    self.velocity.dy -= self.jumpY * .66
    self.grounded = false
    self.dashing = 0
end

function Player:stompJump() --conserves horizantal momentum only if you started the dash very close to (or on?) the floor
    --print("stomp")
    self.velocity.dy = -2.66
    self.grounded = false
    self.dashing = 0
    self.stompLockout = -8
    if self.dashType == 2 then
        self.velocity.dy = -2.33
        self.velocity = self.velocity + self.storedVelocity
        --print("special!")
    end
end

function Player:move(dir) --symmetrical movement function
    if(math.abs(self.velocity.dx) < self.terminalVelocity and dir*self.velocity.dx>=0)then -- move player right
        self.velocity.dx += dir*self.runAcc;
        if(dir>0) then
            self.dir = true
            --print("move dir")
        else
            self.dir = false
        end
    elseif(dir*self.velocity.dx<0)then
        self.velocity.dx = self.velocity.dx + dir*self.runAcc + dir*self.friction
    else
        self.velocity.dx = self.velocity.dx + dir*self.runAcc - dir*self.friction
    end
end

function Player:jumpStart()
    self.velocity.dy -= self.jumpY
    if(self.dir and self.velocity.dx == not 0)then --add a smidge of speed when jumping
        self.velocity.dx += .3;
    elseif(self.velocity.dx == not 0)then
        self.velocity.dx -= .3;
    end
    self.grounded = false

end

function Player:wallJumpStart(dir)
    
    if self.walljumpCounter == 0 then
        self.wallJumpY = self.wallJumpYReset
        self.walljumpCounter += 1
    elseif self.walljumpCounter < self.maxJumps then
        self.walljumpCounter += 1
    else
        self.wallJumpY = 0
    end

   -- print(self.wallJumpY)

    if dir == 1 then
        self.velocity.dx += self.jumpX
    else
        self.velocity.dx -= self.jumpX
    end
    if (self.velocity.dy > self.minWallJump) then
        --print("zeroed", self.velocity.dy, self.minWallJump)
        self.velocity.dy = self.minWallJump
    end
    self.velocity.dy -= self.wallJumpY
    --print("jumped", self.velocity.dy)
    self.walled = 0
    self.stompLockout = 0
    self.dir = not self.dir 
   
end

function Player:wallFriction()
    if self.velocity.dy > self.wallClingSpeed then
        self.velocity.dy -= self.wallFrict
    end
end


function Player:handleCollisionA(X,Y,xDiff, yDiff, tile)
    if(xDiff <= yDiff)then -- hitting from the side
            self.velocity.dx = 0
            self.position.dx = ((X-1)*10)+self.size/2+.1
            --print("Xcollide A")
            self.walled = 1
    else -- yDiff < xDiff AKA hitting corner from below
        if(xDiff <= 3)then
            self.position.dx = ((X-1)*10)+self.size/2+.1
            --print("Corner Correct A")
        else
            self.velocity.dy = self.velocity.dy - self.velocity.dy
            self.position.dy = ((Y)*10)-self.size/2+.1
            --print("Ycollide A")
        end
    end
end

function Player:handleCollisionB(X,Y,xDiff, yDiff, tile)
    self.velocity.dy = self.velocity.dy - self.velocity.dy
    self.position.dy = (((Y)*10)-self.size/2)
    --print("Ycollide B")
end

function Player:handleCollisionC(X,Y,xDiff, yDiff, tile)
    if(xDiff <= yDiff)then -- hitting from the side
        self.velocity.dx = 0
        self.position.dx = ((X)*10)-self.size/2
        --print("Xcollide C")
        self.walled = 2
    else -- yDiff < xDiff AKA hitting corner from below
        if(xDiff <= 3)then
            self.position.dx = ((X)*10)-self.size/2  -- cornercorrect
            --print("Corner Correct C")
        else
            self.velocity.dy = self.velocity.dy - self.velocity.dy
            self.position.dy = ((Y)*10)-self.size/2
            --print("Ycollide C")
        end
    end
end

function Player:handleCollisionD(X,Y,xDiff, yDiff, tile)
    self.velocity.dx = 0
    self.position.dx = ((X-1)*10)+(self.size/2)+.1
    --print("Xcollide D")
    self.walled = 1 
end

function Player:handleCollisionE(X,Y,xDiff, yDiff, tile)
    self.velocity.dx = 0
    self.position.dx = ((X)*10)-self.size/2
    --print("Xcollide E")
    self.walled = 2
end

function Player:handleCollisionF(X,Y,xDiff, yDiff, tile)
    if(xDiff <= yDiff)then
        if(yDiff <= 2)then
            self.position.dy =  ((Y)*10)-self.size/2 + 1 
            self.velocity.dx -= 0.1
            --print("cornercorrect F")
        else
            self.position.dx = ((X-1)*10)+self.size/2 +.1
            --print("Xcollide F")
            self.walled = 1
        end
    else -- yDiff <= xDiff AKA hitting corner from above
        self.velocity.dy = self.velocity.dy - self.velocity.dy
        self.position.dy = ((Y)*10)-self.size/2
        self.grounded = true
        self.dashCount = self.dashTotal
        --print("Ycollide F")
    end
end

function Player:handleCollisionG(X,Y, xDiff, yDiff, tile)

    self.velocity.dy = self.velocity.dy - self.velocity.dy
    self.position.dy = ((Y)*10)-self.size/2
    self.grounded = true
    self.dashCount = self.dashTotal
    --print("Ycollide G")
end

function Player:handleCollisionH(X, Y, xDiff, yDiff, tile)
    if(xDiff <= yDiff)then
        if(yDiff <= 2)then
        self.position.dy =  ((Y)*10)-self.size/2 + 1
        self.velocity.dx += 0.1 --extra bit of speed to not get stuc
        --print("cornercorrect H")
        else
        self.position.dx = ((X)*10)-self.size/2 
        --print("Xcollide H")
        self.walled = 2
    end
    else -- yDiff <= xDiff AKA hitting corner from above
        self.velocity.dy = self.velocity.dy - self.velocity.dy
        self.position.dy = ((Y)*10)-self.size/2
        self.grounded = true
        self.dashCount = self.dashTotal
        --print("Ycollide H")
    end
end


--------------- end player code -------------------