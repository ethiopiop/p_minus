import("CoreLibs/graphics")
import("CoreLibs/object")
import("CoreLibs/sprites")
local pd = playdate
local gfx = pd.graphics
local vect = pd.geometry.vector2D.new
class("Entity").extends()

function entity:init(x, y)
	self.id = 1
	self.x = x --these will be on finer grid (but still saved as plain coordinates if it becomes important later)
	self.y = y
	self.size = 1
	
end

-- entities will have circle/ point hitboxes to keep things simpler
-- i want mines
-- i want missiles
-- i want doors/ buttons
-- i want dust bunnies
-- (in that order, if i get burnt out by dust bunnies then its fine)