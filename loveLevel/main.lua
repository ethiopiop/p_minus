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
    love.mouse.setVisible(false)
    currentBrush = 1
    saveName = love.filesystem.read("pwd.txt")
    print (saveName)
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
    end
end

function save() -- write to level location
    local saveData = saveName .. "\r\n"
    for i = 1,41,1 do
        for j = 1,25,1 do
            if blockGrid[i][j] == -1 then
                saveData = saveData .. tostring(i-1) .. "\r\n" .. tostring(j-1) .."\r\n"
            end
        end
    end
    saveData = saveData .. tostring(1) .. "\r\n"
    for i = 1,41,1 do
        for j = 1,25,1 do
            if blockGrid[i][j] == 1 then
                saveData = saveData .. tostring(i-1) .. "\r\n" .. tostring(j-1) .."\r\n"
            end
        end
    end
    local worked, message = love.filesystem.write(saveName .. ".txt", saveData)
    print(worked, message)
end

function love.draw()
    local mouseX = math.floor(mouseLocationX/20)*20
    local mouseY = math.floor(mouseLocationY/20)*20
    love.graphics.setBackgroundColor(.8,.8,.8)
    drawCursor(mouseX, mouseY)
    love.graphics.setColor(0,0,0)
    drawLevel()
end

function drawCursor(mouseX, mouseY)
    if love.mouse.isDown(2) then
        love.graphics.setColor(1,1,1)
    end
    love.graphics.rectangle("fill", mouseX, mouseY, 20, 20)
    if currentBrush == -1 then
        love.graphics.setColor(.8,.8,.8)
        love.graphics.rectangle("fill", mouseX+5, mouseY+5, 10, 10)
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
            end
        end
    end
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