local async = require("plenary.async")
local icons = require("nvim-web-devicons")
local popup = require("plenary.popup")

local Fs = require("fs")
local Plugin = require("plugin")
local Buffer = require("buffer")

local handleBufUpdate = function()
	local lines = vim.api.nvim_buf_get_lines(Plugin.state.bufno, 0, -1, false)
	vim.api.nvim_set_option_value("modified", false, { buf = Plugin.state.bufno })

	local deleted = {}
	local added = {}

	local current_names = {}

	for _, line in ipairs(lines) do
		local name = line:gsub("^%s+", ""):gsub("/$", "")
		current_names[name] = true
	end

	for _, file in ipairs(Plugin.state.files) do
		if not current_names[file.filename] then
			deleted[#deleted + 1] = file.filename
		end
	end

	for _, dir in ipairs(Plugin.state.directories) do
		if not current_names[dir.filename] then
			deleted[#deleted + 1] = dir.filename
		end
	end

	local existing_names = {}

	for _, file in ipairs(Plugin.state.files) do
		existing_names[file.filename] = true
	end

	for _, dir in ipairs(Plugin.state.directories) do
		existing_names[dir.filename] = true
	end

	for _, line in ipairs(lines) do
		local name = line:gsub("^%s+", ""):gsub("/$", "")
		if name ~= "" and not existing_names[name] then
			added[#added + 1] = name
		end
	end

	Fs.HandleFSChanges(added, deleted)
end

local closeSidebar = function()
	if not Plugin.state.bufno and not Plugin.state.winno then
		return
	end

	local ns_id = vim.api.nvim_create_namespace("iconcol")
	vim.api.nvim_buf_clear_namespace(Plugin.state.bufno, ns_id, 0, -1)

	if vim.api.nvim_win_is_valid(Plugin.state.winno) then
		vim.api.nvim_win_close(Plugin.state.winno, true)
	end

	if vim.api.nvim_buf_is_valid(Plugin.state.bufno) then
		vim.api.nvim_buf_delete(Plugin.state.bufno, { force = true })
	end

	Plugin.state.winno = nil
	Plugin.state.bufno = nil
	Plugin.state.isSideBarOpen = false
	Plugin.state.files = {}
	Plugin.state.directories = {}
end

local createSidebar = function()
	Plugin.state.isSideBarOpen = true

	vim.cmd("vsplit")

	Plugin.state.winno = vim.api.nvim_get_current_win()
	Plugin.state.bufno = vim.api.nvim_create_buf(true, true)

	vim.api.nvim_win_set_buf(Plugin.state.winno, Plugin.state.bufno)
	vim.api.nvim_buf_set_name(Plugin.state.bufno, "slicktree://sidebar")

	vim.api.nvim_set_option_value("buftype", "acwrite", { buf = Plugin.state.bufno })
	vim.api.nvim_set_option_value("modifiable", true, { buf = Plugin.state.bufno })

	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = Plugin.state.bufno,
		callback = function()
			handleBufUpdate()
		end,
	})

	-- TODO: display folders recursively
	vim.keymap.set("n", "<CR>", function()
		local filename = vim.api.nvim_get_current_line()
	end, { silent = true })
end

local sidebar = function(toggle_type)
	if Plugin.state.isSideBarOpen then
		if toggle_type == "toggle" or toggle_type == "close" then
			closeSidebar()
			return
		end

		if toggle_type == "focus" or toggle_type == "open" then
			vim.api.nvim_set_current_win(Plugin.state.winno)
		end
	elseif not Plugin.state.isSideBarOpen then
		async.run(function()
			Fs.GetDirFiles(Plugin.state.workingDirecory)
		end, function()
			Buffer.UpdateBuffer()
		end)

		createSidebar()
	end
end

Plugin.OpenSidebar = function()
	sidebar("open")
end

Plugin.CloseSidebar = function()
	sidebar("close")
end

Plugin.ToggleSidebar = function()
	sidebar("toggle")
end

Plugin.FocusSidebar = function()
	sidebar("focus")
end

vim.keymap.set("n", "<leader>S", function()
	Plugin.ToggleSidebar()
end)
