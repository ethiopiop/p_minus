love.window.setMode(800,480)

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
    love.mouse.setVisible(false)
    currentBrush = 1
    saveName = love.filesystem.read("pwd.txt")
    print (saveName)
    timer = 0
end

function love.update()
    mouseLocationX, mouseLocationY = love.mouse.getPosition()
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
    timer = timer + .1
end

function love.keypressed(key, scancode, isrepeat)
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
    elseif key == "backspace" then
        print(timer)
        if timer < 20 then 
            clearLevel()
        end
        timer = 0 
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

function drawCursor(mouseX, mouseY)
    if love.mouse.isDown(2) then
        love.graphics.setColor(1,1,1)
    end
    if currentBrush >0 and currentBrush <= 4 then
    love.graphics.rectangle("fill", mouseX, mouseY, 20, 20)
    elseif currentBrush == -1 then
        love.graphics.rectangle("fill", mouseX, mouseY, 20, 20)
        love.graphics.setColor(.8,.8,.8)
        love.graphics.rectangle("fill", mouseX+5, mouseY+5, 10, 10)
    elseif currentBrush == -2 then 
        drawGoal(mouseX, mouseY)
    elseif currentBrush > 4 and currentBrush <=8 then
        drawSpike(currentBrush, mouseX,mouseY)
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

--stuff needed:
--LEVEL READER
--LEVEL SAVER
--LEVEL CLEAR
--erase is already in there i think
--goal placement
--all the spikes
--rotate function


-- tile types:
-- -1 == player
-- -2 == goal
-- 0 == nothing
-- 1-4 == block (rotations dont do anything)
-- 5-8 == spike orientations U,R,D,L