function love.conf(t)
	t.window.width = 854
	t.window.height = 480
	t.window.resizable = true
	t.window.minwidth = 320
	t.window.minheight = 240
	-- t.window.srgb = true
	t.modules.audio = false
	t.modules.physics = false

	io.stdout:setvbuf("no")
end
