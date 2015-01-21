console = require "libs.console"
local class = require "libs.hump-class"
local cpml = { vec2 = require "libs.cpml-vec2" }

-- local s1 = new_space()
-- s1:set_type(some_editor_class())
-- result:
--[[
	=====================
	|                  \|
	|                   |
	|                   |
	|         1         |
	|                   |
	|                   |
	|\                  |
	=====================
--]]
-- local s2 = s1:split("x", 0.5) -- split at 50% on X
-- result:
--[[
	=====================
	|        \|        \|
	|         |         |
	|         |         |
	|    1    |    2    |
	|         |         |
	|         |         |
	|\        |\        |
	=====================
--]]
-- local s3 = s2:split("y", 0.3) -- split at 30% on Y
-- result:
--[[
	=====================
	|        \|        \|
	|         |    2    |
	|         |\        |
	|    1    |=========|
	|         |        \|
	|         |    3    |
	|\        |\        |
	=====================

notes:
- the corners ("/""+"\") can be used to split and merge
	- split by dragging into the current view
	- join by dragging into an adjacent view
- resizing can be done by dragging edges
- (right?) click on borders to bring up a split/join menu
--]]

-- The final frontier
local space = class {}
function space:init(window, size, position, parent)
	table.insert(window, self)

	self.position = position or cpml.vec2(0, 0)
	self.size     = size
	self.id       = #window
	self.window   = window
	self.parent   = parent or window

	math.randomseed(self.id)
	local r, g, b = math.random(255), math.random(255), math.random(255)
	-- self.bg = { r, g, b }
	self.bg = { 50, 50, 50 }

	self:print_info()
end

function space:split(axis, amount)
	assert(
		axis == "x" or axis == "y",
		"You can only split a space by the 'x' or 'y' axis"
	)
	assert(
		amount > 0 and amount < 1,
		"Space splits must be between 0 and 1."
	)

	console.d(
		"Splitting space %d %0.1f%% across %s",
		self.id, amount * 100, axis
	)

	local s1, s2 = self:calc_split(axis, amount)
	self.size = s1.size
	self.position = s1.position
	self:print_info()

	return space(self.window, s2.size, s2.position, self)
end

function space:calc_split(axis, amount)
	local space1 = { size=self.size:clone(), position=self.position:clone() }
	local space2 = { size=self.size:clone(), position=self.position:clone() }

	local size = space2.size
	size[axis] = size[axis] - math.ceil(size[axis] * amount)

	local position = space2.position
	position[axis] = position[axis] + math.ceil(self.size[axis] * amount)

	space1.size[axis] = self.size[axis] - size[axis]

	return space1, space2
end

function space:print_info()
	console.d("id:\t\t%d", self.id)
	console.d("size:\t%s", self.size)
	console.d("pos:\t%s", self.position)
end

-- set up space for regular drawing
function space:predraw()
	local w, h = self.size.x, self.size.y

	love.graphics.push()
	love.graphics.translate(self.position.x, self.position.y)
	love.graphics.setScissor(
		self.position.x, self.position.y,
		w, h
	)

	-- bg fill
	love.graphics.setColor(self.bg[1], self.bg[2], self.bg[3])
	love.graphics.rectangle("fill", 0, 0, w, h)
end

-- for space controls and overlays
function space:postdraw()
	local w, h = self.size.x, self.size.y
	local corner_fill = { 255, 255, 255, 35 }
	local corner_border = { 0, 0, 0, 60 }

	-- tl border
	love.graphics.setLineWidth(0.5)
	love.graphics.setColor(255, 255, 255, 40)
	love.graphics.line(0, h, 0, 0, w, 0)
	-- br (huehuehue) border
	love.graphics.setColor(0, 0, 0, 100)
	love.graphics.line(0, h, w, h, w, 0)

	-- corners
	local tr = {
		w - 25, 0,
		w, 0,
		w, 25
	}
	local bl = {
		0, h - 25,
		0, h,
		25, h
	}

	love.graphics.setColor(corner_border)
	love.graphics.setLineWidth(1.0)
	love.graphics.line(w - 25, 0, w, 25)
	love.graphics.line(0, h - 25, 25, h)

	love.graphics.setColor(corner_fill)
	love.graphics.polygon("fill", tr)
	love.graphics.polygon("fill", bl)

	love.graphics.setStencil(function()
		local tr_s = {
			w - 10, 5,
			w - 5, 5,
			w - 5, 10
		}
		local bl_s = {
			5, h - 10,
			5, h - 5,
			10, h - 5
		}

		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.polygon("fill", tr_s)
		love.graphics.polygon("fill", bl_s)
	end)

	love.graphics.setColor(corner_border)
	love.graphics.polygon("fill", tr)
	love.graphics.polygon("fill", bl)
	love.graphics.setStencil()
	love.graphics.setScissor()
	love.graphics.pop()
end

function space:draw()
	local w, h = self.size.x, self.size.y

	local offset = love.graphics.getFont():getHeight() / 2

	love.graphics.setColor(0, 0, 0, 80)
	love.graphics.print(self.id, w/2, h/2+1 - offset)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.print(self.id, w/2, h/2 - offset)
end

local window = class {}

function window:init()
	self.splits = {}
end

function window:draw()
	for _, space in ipairs(self) do
		space:predraw()
		space:draw()
		space:postdraw()
	end
end

local spaces

function love.load()
	console.load(love.graphics.newFont("assets/fonts/Inconsolata.otf"), true)

	local w, h = love.graphics.getDimensions()

	spaces = window(w, h)
	local s1 = space(spaces, cpml.vec2(w, h))
	local s2 = s1:split("y", 0.85)
	local s3 = s1:split("x", 0.25)
	s3:split("x", 0.75)

	-- hopefully, you won't see this!
	love.graphics.setBackgroundColor(255, 0, 255, 255)
end

function love.mousepressed(x, y, b)
	if console.mousepressed(x, y, b) then
		return
	end
end

function love.keypressed(k, r)
	if console.keypressed(k) then
		return
	end

	if k == "escape" then
		love.event.quit()
	end
end

function love.textinput(t)
	console.textinput(t)
end

function love.resize(w, h)
	-- spaces:resize(w, h)
end

function love.update(dt)
	console.update(dt)
end

function love.draw()
	spaces:draw()
	console.draw()
end
