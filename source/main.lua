import("CoreLibs/graphics")
import("CoreLibs/object")
import("CoreLibs/sprites")
import("CoreLibs/ui")
import("CoreLibs/nineSlice")
import("CoreLibs/timer")
import("player")
import("tiles")
import("entities")
local pd = playdate
local gfx = pd.graphics
local vect = pd.geometry.vector2D.new
pd.display.setRefreshRate(50)
local screenHeight = 240
local screenWidth = 400
local tileSize = 10
local firstLoad = true
STATE = "menu"
local test = "levels/00-test"
local easy = "levels/01-easy"
local medium = "levels/02-medium"
local hard = "levels/03-hard"
local custom = "levels/04-custom"
local levelListTestf = pd.file.listFiles(test)
local levelListEasyf = pd.file.listFiles(easy)
local levelListMediumf = pd.file.listFiles(medium)
local levelListHardf = pd.file.listFiles(hard)
local levelListCustomf = pd.file.listFiles(custom)
local getLevelNames = function(levelList, path)
	local names = {}
	for x = 1, #levelList do
		local levelPath = path .. "/" .. levelList[x]
		local levelInfo = pd.file.open(levelPath, pd.file.kFileRead)
		names[x] = levelInfo:readline()
		levelInfo:close()
	end
	return names
end
local levelListTest = getLevelNames(levelListTestf, test)
local levelListEasy = getLevelNames(levelListEasyf, easy)
local levelListMedium = getLevelNames(levelListMediumf, medium)
local levelListHard = getLevelNames(levelListHardf, hard)
local levelListCustom = getLevelNames(levelListCustomf, custom)
local selectedGrid = 0
local listFont = gfx.font.new("assets/blocky")
listFont:setTracking(1)
local listviewHeight = 150
local lastDrawnListviewHeight = 0
local sublistviewHeight = 19
local lastDrawnSublistviewHeight = 0
local selection
local im = gfx.image.new("assets/05.png")
local logo = gfx.image.new("assets/logo-01.png")
local menuOptions = {
	"TUTORIAL",
	"EASY",
	"MEDIUM",
	"HARD",
	"CUSTOM"
}
local listview = playdate.ui.gridview.new(0, 10)
local sublistview = playdate.ui.gridview.new(0, 10)
listview.backgroundImage = playdate.graphics.nineSlice.new("assets/shadowbox", 4, 4, 45, 45)
listview:setNumberOfRows(#menuOptions)
listview:setCellPadding(0, 0, 13, 13)
listview:setContentInset(24, 24, 1, 5)
listview.scrollCellsToCenter = false
sublistview.backgroundImage = listview.backgroundImage
sublistview:setCellPadding(0, 0, 13, 13)
sublistview:setContentInset(24, 24, 1, 5)
local menuFirstLoad = function()
	if selectedGrid == 0 then
		print("drawing LIST")
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(18, 80, 160, 220)
		listview:drawInRect(18, 80, 160, listviewHeight)
		lastDrawnListviewHeight = listviewHeight
		gfx.setColor(gfx.kColorBlack)
		logo:draw(18, 20)
	end
	if selectedGrid == 1 then
		print("drawing SUBLIST")
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(18, 80, 160, 220)
		sublistview:drawInRect(18, 80, 160, sublistviewHeight)
		logo:draw(18, 20)
		lastDrawnSublistviewHeight = sublistviewHeight
	end
	if pd.getButtonState() == 0 then
		firstLoad = false
	end
end

function listview:drawCell(section, row, column, selected, x, y, width, height)
	if selected then
		gfx.setColor(gfx.kColorBlack)
		gfx.fillRoundRect(x, y, width, 20, 4)
	else
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
	end
	gfx.setFont(listFont)
	gfx.drawTextInRect(menuOptions[row], x + 6, y + 6, width, height + 2, nil, "...", kTextAlignment.left)
end

function sublistview:drawCell(section, row, column, selected, x, y, width, height)
	if selected then
		gfx.setColor(gfx.kColorBlack)
		gfx.fillRoundRect(x, y, width, 20, 4)
	else
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
	end
	gfx.setFont(listFont)
	if selection == 1 then
		gfx.drawTextInRect(levelListTest[row], x + 6, y + 6, width, height + 2, nil, "...", kTextAlignment.left)
	elseif selection == 2 then
		gfx.drawTextInRect(levelListEasy[row], x + 6, y + 6, width, height + 2, nil, "...", kTextAlignment.left)
	elseif selection == 3 then
		gfx.drawTextInRect(levelListMedium[row], x + 6, y + 6, width, height + 2, nil, "...", kTextAlignment.left)
	elseif selection == 4 then
		gfx.drawTextInRect(levelListHard[row], x + 6, y + 6, width, height + 2, nil, "...", kTextAlignment.left)
	elseif selection == 5 then
		gfx.drawTextInRect(levelListCustom[row], x + 6, y + 6, width, height + 2, nil, "...", kTextAlignment.left)
	end
end

local listviewTimer
local animateListviewOpen = function()
	listviewTimer = playdate.timer.new(300, listviewHeight, 150, playdate.easingFunctions.outCubic)
	
	function listviewTimer.updateCallback(timer)
		listviewHeight = timer.value
	end
	
	function listviewTimer.timerEndedCallback(timer)
		listviewHeight = timer.value
		listviewTimer = nil
	end
end
local animateListviewClosed = function()
	listviewTimer = playdate.timer.new(300, listviewHeight, 19, playdate.easingFunctions.outCubic)
	
	function listviewTimer.updateCallback(timer)
		listviewHeight = timer.value
	end
	
	function listviewTimer.timerEndedCallback(timer)
		listviewHeight = timer.value
		listviewTimer = nil
		selectedGrid = 1
		animateSublistviewOpen()
	end
end

function animateSublistviewOpen()
	listviewTimer = playdate.timer.new(300, sublistviewHeight, 150, playdate.easingFunctions.outCubic)
	
	function listviewTimer.updateCallback(timer)
		sublistviewHeight = timer.value
	end
	
	function listviewTimer.timerEndedCallback(timer)
		sublistviewHeight = timer.value
		listviewTimer = nil
	end
end

local animateSublistviewClosed = function()
	listviewTimer = playdate.timer.new(300, sublistviewHeight, 19, playdate.easingFunctions.outCubic)
	
	function listviewTimer.updateCallback(timer)
		sublistviewHeight = timer.value
	end
	
	function listviewTimer.timerEndedCallback(timer)
		sublistviewHeight = timer.value
		listviewTimer = nil
		selectedGrid = 0
		animateListviewOpen()
	end
end
local enterSelection = function()
	selection = listview:getSelectedRow()
	if selection == 1 then
		sublistview:setNumberOfRows(#levelListTest)
	elseif selection == 2 then
		sublistview:setNumberOfRows(#levelListEasy)
	elseif selection == 3 then
		sublistview:setNumberOfRows(#levelListMedium)
	elseif selection == 4 then
		sublistview:setNumberOfRows(#levelListHard)
	elseif selection == 5 then
		sublistview:setNumberOfRows(#levelListCustom)
	end
	animateListviewClosed()
end
local exitSelection = function()
	animateSublistviewClosed()
	sublistview:setSelectedRow(1)
end

function playdate.AButtonUp()
	if STATE == "menu" and not firstLoad then
		if selectedGrid == 0 then
			enterSelection()
		else
			STATE = "level"
			local lvlSelected = sublistview:getSelectedRow()
			local lvlPath
			if selection == 1 then
				lvlPath = test .. "/" .. levelListTestf[lvlSelected]
			elseif selection == 2 then
				lvlPath = easy .. "/" .. levelListEasyf[lvlSelected]
			elseif selection == 3 then
				lvlPath = medium .. "/" .. levelListMediumf[lvlSelected]
			elseif selection == 4 then
				lvlPath = hard .. "/" .. levelListHardf[lvlSelected]
			elseif selection == 5 then
				lvlPath = custom .. "/" .. levelListCustomf[lvlSelected]
			end
			if lvlPath ~= nil then
				levelSTART(lvlPath)
			else
				print("no level selected!")
			end
		end
	end
end

function playdate.BButtonUp()
	if STATE == "menu" and not firstLoad and selectedGrid == 1 then
		exitSelection()
	else
	end
end

function playdate.upButtonDown()
	if STATE == "menu" and not firstLoad then
		if selectedGrid == 0 then
			listview:selectPreviousRow(true)
		else
			sublistview:selectPreviousRow(false)
		end
	end
end

function playdate.downButtonDown()
	if STATE == "menu" and not firstLoad then
		if selectedGrid == 0 then
			listview:selectNextRow(true)
		else
			sublistview:selectNextRow(false)
		end
	end
end

local menuMode = function()
	playdate.timer.updateTimers()
	if firstLoad then
		menuFirstLoad()
	end
	if selectedGrid == 0 and (lastDrawnListviewHeight ~= listviewHeight or listview.needsDisplay == true) then
		print("drawing LIST")
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(18, 80, 160, 220)
		listview:drawInRect(18, 80, 160, listviewHeight)
		lastDrawnListviewHeight = listviewHeight
		gfx.setColor(gfx.kColorBlack)
		logo:draw(18, 20)
	end
	if selectedGrid == 1 and (lastDrawnSublistviewHeight ~= sublistviewHeight or sublistview.needsDisplay == true) then
		print("drawing SUBLIST")
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(18, 80, 160, 220)
		sublistview:drawInRect(18, 80, 160, sublistviewHeight)
		logo:draw(18, 20)
		lastDrawnSublistviewHeight = sublistviewHeight
	end
end
local gridDraw = function(grid)
	gfx.setColor(gfx.kColorBlack)
	local backgroundImage = gfx.image.new(400, 240)
	gfx.pushContext(backgroundImage)
	for x = 1, 40 do
		for y = 1, 24 do
			if grid[x][y] ~= 0 then
				grid[x][y]:draw()
			end
		end
	end
	gfx.popContext()
	return backgroundImage
end
local levelRead = function(levelPath)
	local grid = table.create(42, 0)
	local entities = {}
	--local itemType = 0
	for i = 0, 41 do
		grid[i] = table.create(26, 0)
	end
	for x = 0, 41 do
		for y = 0, 25 do
			if x == 0 or y == 0 or x == 41 or y == 25 then
				grid[x][y] = Tile(x, y)
			else
				grid[x][y] = Empty(x, y)
			end
		end
	end
	local levelInfo = pd.file.open(levelPath, pd.file.kFileRead)
	local infoX = levelInfo:readline()
	infoX = levelInfo:readline()
	local infoY = levelInfo:readline()
	local pX, pY = infoX * 10 - 5, infoY * 10 - 6
	infoX = tonumber(levelInfo:readline())
	infoY = tonumber(levelInfo:readline())
	print(infoX, infoY)
	grid[infoX][infoY] = Goal(infoX, infoY)
	while infoX ~= nil do
		local itemType = tonumber(levelInfo:readline())
		print("item: ", itemType)
		if itemType == 0 then
			break
		end
		while infoX ~= 0 and infoY ~= 0 do
			infoX = tonumber(levelInfo:readline())
			infoY = tonumber(levelInfo:readline())
			if infoX == nil or infoY == nil then
				break
			end
			if itemType == 1 then
				grid[infoX][infoY] = Tile(infoX, infoY)
			elseif itemType == 2 then
				grid[infoX][infoY] = DashThrough(infoX, infoY)
			elseif itemType == 3 then
				grid[infoX][infoY] = WalkThrough(infoX, infoY)
			elseif itemType == 4 then
			elseif itemType == 5 then
				grid[infoX][infoY] = SpikeU(infoX, infoY)
			elseif itemType == 6 then
				grid[infoX][infoY] = SpikeR(infoX, infoY)
			elseif itemType == 7 then
				grid[infoX][infoY] = SpikeD(infoX, infoY)
			elseif itemType == 8 then
				grid[infoX][infoY] = SpikeL(infoX, infoY)
			end
		end
		infoX = 1
		infoY = 1
		print("done with: ", itemType)
	end
	local info1, info2, info3 = 1, 1, 1
	while info1 ~= nil do
		local itemType = tonumber(levelInfo:readline())
		if itemType == nil then break end
		print("entity ", itemType)
		while true do
			info1 = tonumber(levelInfo:readline())
			info2 = tonumber(levelInfo:readline())
			info3 = tonumber(levelInfo:readline())
			if (info1 == 0 and info2 == 0 and info3 == 0) or info1 == nil then
				print("corrupt level")
				break
			end
			if itemType == 1 then
				local entity = Entity(info1, info2, info3)
				table.insert(entities, entity)
			elseif itemType == 2 then
				local entity = Follower(info1, info2, info3)
				table.insert(entities, entity)
			elseif itemType == 3 then
				local info4 = tonumber(levelInfo:readline())
				local info5 = tonumber(levelInfo:readline())
				local info6 = tonumber(levelInfo:readline())
				local entity = Door(info1, info2, info3, info4, info5, info6)
				table.insert(entities, entity)
				print("added entity", itemType, info1, info2, info3, info4, info5, info6)
			elseif itemType == 4 then
				local info4 = tonumber(levelInfo:readline())
				local info5 = tonumber(levelInfo:readline())
				local info6 = tonumber(levelInfo:readline())
				local entity = Wind(info1, info2, info3, info4, info5, info6)
				table.insert(entities, entity)
				print("added entity", itemType, info1, info2, info3, info4, info5, info6)
			end
			print("added entity", itemType, info1, info2, info3)
		end
		print("done with entity", itemType, info1, info2, info3)
		info1, info2, info3 = 1, 1, 1
	end

	
	return pX, pY, grid, entities
end
local levelLoad = function(levelPath)
	local playerPosX, playerPosY, levelGrid, entities = levelRead(levelPath)
	local player = Player(playerPosX, playerPosY, levelGrid, entities)
	local backgroundImage = gridDraw(levelGrid)
	firstLoad = true
	return player, backgroundImage, entities
end
local levelExit = function()
end
local levelNext = function()
end

function levelSTART(lvlPath)
	player, levelTerrain, entities = levelLoad(lvlPath)
	player:add()
end

function pd.update()
	if STATE == "menu" then
		menuMode()
	elseif STATE == "level" then
		gfx.sprite.update()
		pd.drawFPS(0, 0)
		levelTerrain:draw(0, 0)
		for _, thing in pairs(entities) do
			thing:update(player)
			thing:draw()
		end
		--print(player.position.dx, player.position.dy)
	elseif STATE == "levelFINISH" then
		if firstLoad then
			player:remove()
			gfx.clear(gfx.kColorWhite)
			gfx.drawText("LEVEL CLEAR!!!", 150, 100)
			gfx.drawText("PRESS BUTTON TO GO BACK TO MENU", 90, 120)
			if pd.getButtonState() == 0 then
				firstLoad = false
			end
		elseif pd.getButtonState() ~= 0 then
			gfx.clear(gfx.kColorWhite)
			STATE = "menu"
			firstLoad = true
		end
	elseif STATE == "levelEXIT" then
		player:remove()
		gfx.clear(gfx.kColorWhite)
		STATE = "menu"
		firstLoad = true
	elseif STATE == "dead" then
		gfx.sprite.update()
		pd.drawFPS(0, 0)
		for _, thing in pairs(entities) do
			thing:draw()
			thing:reset()
		end
		levelTerrain:draw(0, 0)
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(120, 85, 160, 80)
		gfx.setColor(gfx.kColorBlack)
		gfx.fillRect(125, 90, 150, 70)
		gfx.drawText("YOU DIED!!!", 135, 100)
		gfx.drawText("PRESS A TO RETRY", 135, 120)
		gfx.drawText("PRESS B TO EXIT", 135, 140)
	end
	pd.timer:updateTimers()
end

function Player:getX()
	return math.floor(player.position.dx / 10 + 1)
end

function Player:getY()
	return math.floor(player.position.dy / 10 + 1)
end

function Player:getDir()
	return player.dir
end
