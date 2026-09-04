love.window.setMode(800,480)
local justpress = true
local gfx = love.graphics

function love.load()
    local emptyGrid = {}
    for i = 0,41,1 do
        emptyGrid[i] = {}
        for j = 0,26,1 do
            emptyGrid[i][j] = 0
        end
    end
    blockGrid = emptyGrid
    entities = {}
    entityMode = false
    love.mouse.setVisible(false)
    currentBrush = 1
    saveName = love.filesystem.read("pwd.txt")
    print (saveName)
    timer = 0
end

function getInfo(message)
    local info = {}
    while not love.keyboard.isDown("return")do
    print(message)
    love.event.wait()
    end
    for line in love.filesystem.lines("info.txt") do 
        table.insert(info, line)
    end
    return info
end

function love.update()
    mouseLocationX, mouseLocationY = love.mouse.getPosition()
    --print(currentBrush)
    if not entityMode then
        local gridX = math.floor(mouseLocationX/20)+2
        local gridY = math.floor(mouseLocationY/20)+2
        if love.mouse.isDown(1) then
            if currentBrush < 0 then
                removeDupes()
            end
            blockGrid[gridX][gridY] = currentBrush
        elseif love.mouse.isDown(2) then
            blockGrid[gridX][gridY] = 0
        end
    else
        if love.keyboard.isDown("space") then
            gameX = math.floor(mouseLocationX/2) --exact PD coords
            gameY = math.floor(mouseLocationY/2)
        else
            gameX = math.ceil((mouseLocationX/2)-((mouseLocationX/2)%5)) --snap to finer grid
            gameY = math.ceil((mouseLocationY/2)-((mouseLocationY/2)%5)) 
        end
        if love.keyboard.isDown("right") then
            gameX = gameX + 5
        end
        if love.mouse.isDown(1) then
            if justpress then
            placeEntity(currentBrush)
            end
            justpress = false
        elseif love.mouse.isDown(2) then
            if love.keyboard.isDown("lshift") then
                editEntity(gameX, gameY)
            else
                if justpress then
                removeEntity(gameX, gameY)
                end
                justpress = false
            end
        else
            justpress = true
        end
    end
    timer = timer + .1
end

function removeEntity(x,y)
    key = getEntity(x,y)
    table.remove(entities, key)
end

function editEntity(x,y)
    local key = getEntity(x,y)
    if key == nil then
        print("nothing here")
        return
    end
    if entities[key].id == 1 then
        stuff = getInfo("edit mine info offset +x,+y, state (-1 or -2)")
        entities[key].x = entities[key].x + tonumber(stuff[1])
        entities[key].y = entities[key].y + tonumber(stuff[2])
        entities[key].state = tonumber(stuff[3])
    elseif entities[key].id == 2 then
        stuff = getInfo("edit chaser info offset +x,+y,+delay")
        entities[key].x = entities[key].x + tonumber(stuff[1])
        entities[key].y = entities[key].y + tonumber(stuff[2])
        entities[key].delay = entities[key].delay + tonumber(stuff[3])
    elseif entities[key].id == 3 then
        stuff = getInfo("edit door info offset +x, +y, +doorx, +doory, +height")
        entities[key].x = entities[key].x + tonumber(stuff[1])
        entities[key].y = entities[key].y + tonumber(stuff[2])
        entities[key].dx = entities[key].dx + tonumber(stuff[3])
        entities[key].dy = entities[key].dy + tonumber(stuff[4])
        entities[key].len = entities[key].len + tonumber(stuff[5])
    elseif entities[key].id == 4 then
        stuff = getInfo("edit wind info offset +x, +y, +w, +h, =vx, =vy, zeros change nothing")
        entities[key].x = entities[key].x + tonumber(stuff[1])
        entities[key].y = entities[key].y + tonumber(stuff[2])
        entities[key].w = entities[key].w + tonumber(stuff[3])
        entities[key].h = entities[key].h + tonumber(stuff[4])
        entities[key].vx = tonumber(stuff[5])
        entities[key].vy = tonumber(stuff[6])
    elseif entities[key].id == 5 then
        -- no entity 5 yet
    end
end

function getEntity(x,y)
    for key, thing in pairs(entities) do
        if thing.x == x and thing.y == y then
            print("thing found! id: " .. thing.id)
            return key
        end
    end
end

function placeEntity(thing)
    if thing == 1 then
        table.insert(entities, {id = 1, x = gameX, y = gameY, state = -2})
    elseif thing == 2 then
        table.insert(entities, {id = 1, x = gameX, y = gameY, state = -1})
    elseif thing == 3 then
        local d = getInfo("enter delay into info.txt, reccomended between 50-200:")
        table.insert(entities, {id = 2, x = gameX, y = gameY, delay = tonumber(d[1])})
    elseif thing == 4 then
        local vxy = getInfo("enter door door height (remember 10 = one tile) enter door location (x,y)")
        table.insert(entities, {id = 3, x = gameX, y = gameY, dx = tonumber(vxy[2]), dy = tonumber(vxy[3]), hor = -2, len = tonumber(vxy[1])})
    elseif thing == 5 then
        local vxy = getInfo("enter door door width (remember 10 = one tile) enter door location (x,y)")
        table.insert(entities, {id = 3, x = gameX, y = gameY, dx = tonumber(vxy[2]), dy = tonumber(vxy[3]), hor = -1, len = tonumber(vxy[1])})
    elseif thing == 6 then
        local whv = getInfo("enter wind width, height, and vx, vy (keep v at 1 and below)")
        table.insert(entities, {id = 4, x = gameX, y = gameY, w = tonumber(whv[1]), h = tonumber(whv[2]), vx = tonumber(whv[3]), vy = tonumber(whv[4])})
    end
end

function love.keypressed(key, scancode, isrepeat)
    if not entityMode then
        if key == "p" then
            currentBrush = -1 -- place a player
        elseif key == "h" then
            -- show a list of all keys in the future
        elseif key == "b" then
            currentBrush = 1 -- place a block
        elseif key == "g" then
            currentBrush = -2 --place the goal (negative numbers should only be able to be placed once)
        elseif key == "s" then
            save()
            print("saved to " .. saveName .. ".txt")
        elseif key == "l" then
            if timer < 20 then 
                clearLevel()
                loadLevel(saveName .. ".txt")
            end
            timer = 0 
        elseif key == "r" then
            rotate()
        elseif key == "v" then
            currentBrush = 5 -- place spikes "vvv"
        elseif key == "c" then
            print(timer)
            if timer < 20 then 
                clearLevel()
            end
            timer = 0 
        elseif key == "e" then
            entityMode = true
            currentBrush = 1
        end
    else
        if key == "m" then --mines
            if currentBrush == 1 then
                currentBrush = 2
            elseif currentBrush == 2 then 
                currentBrush = 1
            else
                currentBrush = 1
            end
        elseif key == "h" then
            -- show a list of all keys in the future
        elseif key == "w" then -- wind 
            currentBrush = 6
        elseif key == "d" then --door
            if currentBrush == 4 then
                currentBrush = 5
            elseif currentBrush == 5 then 
                currentBrush = 4
            else
                currentBrush = 4
            end
        elseif key == "p" then --evil player
            currentBrush = 3
        elseif key == "b" then --dust bunny
        elseif key == "s" then
            save()
            print("saved to " .. saveName .. ".txt")
        elseif key == "l" then
            if timer < 20 then 
                clearLevel()
                loadLevel(saveName .. ".txt")
            end
            timer = 0 
        elseif key == "c" then
            print(timer)
            if timer < 20 then 
                clearLevel()
            end
            timer = 0 
        elseif key == "e" then
            entityMode = false
            currentBrush = 1
        end
    end
end

function save() -- write to level location
    local saveable = false
    saveData = saveName .. "\r\n"
    for i = 1,41,1 do
        for j = 1,25,1 do
            if blockGrid[i][j] == -1 then
                saveData = saveData .. tostring(i-1) .. "\r\n" .. tostring(j-1) .."\r\n"
                saveable = true
            end
        end
    end
    for i = 1,41,1 do
        for j = 1,25,1 do
            if blockGrid[i][j] == -2 then
                saveData = saveData .. tostring(i-1) .. "\r\n" .. tostring(j-1) .."\r\n"
                saveable = true
            end
        end
    end
    if saveable then
    saveObject(1);
    saveObject(2)
    saveObject(3)
    saveObject(5);
    saveObject(6);
    saveObject(7);
    saveObject(8);
    saveEntities();
    local worked, message = love.filesystem.write(saveName .. ".txt", saveData)
    print(worked, message)
    else
        print("NO START OR END OF LEVEL -- DID NOT SAVE")
    end
end

function saveEntities()
    local entity = 1
    saveData = saveData .. tostring(0) .. "\r\n"
    while entity < 6 do
        saveData = saveData .. tostring(entity) .. "\r\n"
        for _, thing in pairs(entities) do
            if entity == thing.id then
                print("saving entity", entity)
                saveEntity(thing)
            end
        end
        saveData = saveData .. tostring(0) .. "\r\n"
                            .. tostring(0) .. "\r\n"
                            .. tostring(0) .. "\r\n"
        print("done with entity", entity)
        entity = entity+1
    end
end

function saveEntity(thing)
    if thing.id == 1 then --mine
        saveData = saveData .. tostring(thing.x) .. "\r\n"
                            .. tostring(thing.y) .. "\r\n"
                            .. tostring(thing.state) .. "\r\n"
    elseif thing.id == 2 then --chaser
        saveData = saveData .. tostring(thing.x) .. "\r\n"
                            .. tostring(thing.y) .. "\r\n"
                            .. tostring(thing.delay) .. "\r\n"
    elseif thing.id == 3 then --door
        saveData = saveData .. tostring(thing.x) .. "\r\n"
                            .. tostring(thing.y) .. "\r\n"
                            .. tostring(thing.dx) .. "\r\n"
                            .. tostring(thing.dy) .. "\r\n"
                            .. tostring(thing.hor) .. "\r\n"
                            .. tostring(thing.len) .. "\r\n"
    elseif thing.id == 4 then --wind
        saveData = saveData .. tostring(thing.x) .. "\r\n"
                            .. tostring(thing.y) .. "\r\n"
                            .. tostring(thing.w) .. "\r\n"
                            .. tostring(thing.h) .. "\r\n"
                            .. tostring(thing.vx) .. "\r\n"
                            .. tostring(thing.vy) .. "\r\n"
    end
    
end

function love.draw()
    local mouseX = math.floor(mouseLocationX/20)*20
    local mouseY = math.floor(mouseLocationY/20)*20
    love.graphics.setBackgroundColor(.8,.8,.8)
    drawCursor(mouseX, mouseY, currentBrush)
    love.graphics.setColor(0,0,0)
    drawLevel()
    drawEntities()
end

function drawEntities()
    for _, thing in pairs(entities) do
        if thing.id == 1 then
            drawMine(thing.x, thing.y, thing.state)
        elseif thing.id == 2 then
            drawChaser(thing.x, thing.y)
        elseif thing.id == 3 then
            drawDoor(thing.x, thing.y, thing.dx, thing.dy, thing.hor, thing.len)
        elseif thing.id == 4 then
            drawWind(thing.x, thing.y, thing.w, thing.h, thing.vx, thing.vy)
        end
    end
end

function drawCursor(mouseX, mouseY, currentBrush)
    if not entityMode then
        if love.mouse.isDown(2) then
            love.graphics.setColor(1,1,1)
        end
        if currentBrush == 1 or currentBrush == 4 then
            love.graphics.rectangle("fill", mouseX, mouseY, 20, 20)
        elseif currentBrush == 2 then
            drawDashThrough(mouseX,mouseY)
        elseif currentBrush ==3 then 
            drawWalkThrough(mouseX, mouseY)
        elseif currentBrush == -1 then
            love.graphics.rectangle("fill", mouseX, mouseY, 20, 20)
            love.graphics.setColor(.8,.8,.8)
            love.graphics.rectangle("fill", mouseX+5, mouseY+5, 10, 10)
        elseif currentBrush == -2 then 
            drawGoal(mouseX, mouseY)
        elseif currentBrush > 4 and currentBrush <=8 then
            drawSpike(currentBrush, mouseX,mouseY)
        end
    else
        if currentBrush == 1 then --mine (on)
            drawMine(gameX, gameY, -2)
        elseif currentBrush == 2 then --mine (off)
            drawMine(gameX, gameY, -1)
        elseif currentBrush == 3 then -- chaser
            drawChaser(gameX, gameY)
        elseif currentBrush == 4 then -- door vertical
            drawDoor(gameX, gameY,gameX, gameY, -2, 30)
        elseif currentBrush == 5 then
            drawDoor(gameX, gameY, gameX, gameY, -1, 30)
        elseif currentBrush == 6 then -- wind
            drawWind(gameX, gameY, 50, 50, 0,0)
        end
    end
    
end

function drawLevel()
    for i = 1,41,1 do
        for j = 1,25,1 do
            if blockGrid[i][j] == 1 then
                love.graphics.rectangle("fill", (i-2)*20, (j-2)*20, 20, 20)
            elseif blockGrid[i][j] == -1 then
                love.graphics.rectangle("fill", (i-2)*20, (j-2)*20, 20, 20)
                love.graphics.setColor(.8,.8,.8)
                love.graphics.rectangle("fill", (i-2)*20+5, (j-2)*20+5, 10, 10)
                love.graphics.setColor(0,0,0)
            elseif blockGrid[i][j] == -2 then
                drawGoal((i-2)*20, (j-2)*20)
            elseif blockGrid[i][j] == 2 then
                drawDashThrough((i-2)*20, (j-2)*20)
            elseif blockGrid[i][j] == 3 then
                drawWalkThrough((i-2)*20, (j-2)*20)
            elseif blockGrid[i][j] <=8 and blockGrid[i][j] >= 5 then
                drawSpike(blockGrid[i][j], (i-2)*20, (j-2)*20)
            end  
        end
    end
end


function drawMine(x,y,state)
    local mode = "fill"
    if state == -1 then mode = "line" end
    love.graphics.circle(mode, x*2,y*2,8)
end

function drawChaser(x, y)
    love.graphics.circle("fill", x*2, y*2, 6)
    love.graphics.rectangle("line", x*2-10, y*2-10, 20,20)
end

function drawDoor(x,y,dx,dy,hor,length)
    local horizantal = true
    local doorWidth, doorHeight
    if hor == -1 then horizantal = true else horizantal = false end
    if horizantal then 
		doorWidth = length *2
		doorHeight = 4*2
	else
		doorWidth = 4*2
		doorHeight = length*2
	end
    love.graphics.setColor(0,.8,0.2)
    love.graphics.circle("fill", x*2,y*2, 10)
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("line", dx*2,dy*2, doorWidth,doorHeight)

end

function drawWind(x,y,w,h,vx,vy)
    love.graphics.setColor(0,0,0,0.2)
    love.graphics.rectangle("fill", x*2,y*2,w*2,h*2)
    love.graphics.setColor(0,0,0)
    local cx, cy = x*2+w,y*2+h
    love.graphics.line(cx,cy,cx+vx*100, cy+vy*100)
    love.graphics.circle("fill", cx+vx*100, cy+vy*100,5)
    love.graphics.circle("line", x*2, y*2, 5)
end

function drawGoal(x,y)
    love.graphics.setColor(1,.5,.5) --temp
    love.graphics.rectangle("fill", x,y,20,20)
    love.graphics.setColor(0,0,0)
end


function removeDupes()
    for i = 1,40,1 do
        for j = 1,25,1 do
            if blockGrid[i][j] == currentBrush then
                blockGrid[i][j] = 0
            end
        end
    end
end

function saveObject(x)
    saveData = saveData .. tostring(x) .. "\r\n"
    for i = 1,41,1 do
        for j = 1,25,1 do
            if blockGrid[i][j] == x then
                saveData = saveData .. tostring(i-1) .. "\r\n" .. tostring(j-1) .."\r\n"
            end
        end
    end
    saveData = saveData .. tostring(0) .. "\r\n" .. tostring(0) .."\r\n"
end

function loadLevel(level)
    local leveldata = {}
    local blocktype = 0
    local bookmark = 0
    entities = {}
    if love.filesystem.exists(level) then
    for line in love.filesystem.lines(level) do 
        table.insert(leveldata, line)
    end
    end
    local i = 2
    while i < #leveldata do
        print (i, blocktype , leveldata[i], leveldata[i+1])
        if leveldata[i] == nil then return end
        if i < 5 then -- catch first two entries
            blocktype = blocktype - 1
            blockGrid[tonumber(leveldata[i])+1][tonumber(leveldata[i+1])+1] = blocktype
        elseif i == 6 then -- no more irregularities past this point. should be able to loop clean
            blocktype = tonumber(leveldata[i])
            i = i -1
        elseif i > 6 and tonumber(leveldata[i]) ~= 0  then
            blockGrid[tonumber(leveldata[i])+1][tonumber(leveldata[i+1])+1] = blocktype
        else --leveldata is zero
            if i + 2 >= #leveldata then
                return --exits function
            elseif tonumber(leveldata[i+2]) == 0 then
                bookmark = i+2
                i = #leveldata
                print("starting entities")
            else
                print(tonumber(leveldata[i+1]),tonumber(leveldata[i+2]))
                blocktype = tonumber(leveldata[i+2])
                i = i + 1
            end
        end
        i= i+2
    end

    local entityspot = bookmark+1
    i = bookmark + 2
    while i < #leveldata do --should be skipped automatically if top loop actually reaches the end
        blocktype = tonumber(leveldata[entityspot])

        local info1 = tonumber(leveldata[i])
        local info2 = tonumber(leveldata[i+1])
        local info3 = tonumber(leveldata[i+2])

        if info1 == 0 and info2 == 0 and info3 == 0 then
            print("done with entity", blocktype)
            entityspot = i+3
            print("starting entity", tonumber(entityspot))
            i = i+4
        elseif blocktype == 1 then --mines - 3 numbers
            table.insert(entities, {id = 1, x = info1, y = info2, state = info3})
            i = i+3
        elseif blocktype == 2 then --chaser
            table.insert(entities, {id = 2, x = info1, y = info2, delay = info3})
            i = i+3
        elseif blocktype == 3 then -- door
            local info4 = tonumber(leveldata[i+3])
            local info5 = tonumber(leveldata[i+4])
            local info6 = tonumber(leveldata[i+5])
            table.insert(entities, {id = 3, x = info1, y = info2, dx = info3, dy = info4, hor = info5, len = info6})
            i = i+6
        elseif blocktype == 4 then --windbox
            local info4 = tonumber(leveldata[i+3])
            local info5 = tonumber(leveldata[i+4])
            local info6 = tonumber(leveldata[i+5])
            table.insert(entities, {id = 4, x = info1, y = info2, w = info3, h = info4, vx = info5, vy = info6})
            i = i+6
        end

    end
end

function rotate()
    if currentBrush % 4 == 0 then
        currentBrush = currentBrush - 3
    else
        currentBrush = currentBrush + 1
    end
end

function clearLevel()
        local emptyGrid = {}
    for i = 0,41,1 do
        emptyGrid[i] = {}
        for j = 0,26,1 do
            emptyGrid[i][j] = 0
        end
    end
    blockGrid = emptyGrid
    entities = {}
end

function drawSpike(rotation, x, y)
    if rotation == 5 then --U
        love.graphics.polygon("line", x,y+20, x+5,y+14, x+10,y+20, x+15,y+14, x+20,y+20)
    elseif rotation == 6 then --R
        love.graphics.polygon("line", x,y, x+6,y+5, x,y+10, x+6,y+15, x,y+20)
    elseif rotation == 7 then --D
        love.graphics.polygon("line", x,y, x+5,y+6, x+10,y, x+15,y+6, x+20,y)
    elseif rotation == 8 then --L
        love.graphics.polygon("line", x+20,y, x+14,y+5, x+20,y+10, x+14,y+15, x+20,y+20)
    end
end

function drawDashThrough(x,y)
    gfx.setColor(.5,.5,.5)
    gfx.rectangle("fill", x,y,20,20)
    gfx.setColor(0,0,0)
end

function drawWalkThrough(x,y)
    gfx.rectangle("line",x,y,20,20)
end

--stuff needed:



-- tile types:
-- -1 == player
-- -2 == goal
-- 0 == nothing
-- 1-4 == block (rotations dont do anything)
-- 5-8 == spike orientations U,R,D,L