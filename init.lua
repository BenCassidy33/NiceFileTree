local async = require("plenary.async")
local icons = require("nvim-web-devicons")

Plugin = {
	options = {
		showHidden = true,
		showIcons = true,
	},
}

---@class TimeSpec
---@field sec number
---@field nsec number

---@class FileStat
---@field atime TimeSpec
---@field birthtime TimeSpec
---@field blksize number
---@field blocks number
---@field ctime TimeSpec
---@field dev number
---@field flags number
---@field gen number
---@field gid number
---@field ino number
---@field mode number
---@field mtime TimeSpec
---@field nlink number
---@field rdev number
---@field size number
---@field type string
---@field uid number

---@class FileInfo
---@field filepath string
---@field filename string
---@field extension string
---@field stat FileStat
---
---@class State
---@field workingDirecory string
---@field isSideBarOpen boolean
---@field openDirectories string[]
---@field files FileInfo[]
---@field directories FileInfo[]

---@class State
local state = {
	workingDirecory = vim.fn.getcwd(),
	isSideBarOpen = false,
	files = {},
	directories = {},
	openDirectories = {},
	bufno = nil,
	winno = nil,
}

---@param filename string
---@return FileInfo
local getFileInfo = function(filename)
	local filepath = state.workingDirecory .. "/" .. filename
	local file_info = {
		filepath = filepath,
		filename = filename,
		stat = nil,
		extension = nil,
	}

	local _, fd = async.uv.fs_open(filepath, "r", 438)
	local _, stat = async.uv.fs_fstat(fd)
	file_info.stat = stat

	file_info.extension = filename:match("%.([^%.]+)$")

	async.uv.fs_close(fd)
	return file_info
end

local getDirInfo = function()
	local files = vim.fn.readdir(state.workingDirecory)
	for _, filename in ipairs(files) do
		local file_info = getFileInfo(filename)

		if file_info.stat.type == "directory" then
			state.directories[#state.directories + 1] = file_info
		elseif file_info.stat.type == "file" then
			state.files[#state.files + 1] = file_info
		else
			print("Unsupported file type: ", file_info.filepath)
		end
	end
end

--- TODO
---@param added table
---@param deleted table
local handleFSChanges = function (added, deleted)
end 

local handleBufUpdate = function()
	local lines = vim.api.nvim_buf_get_lines(state.bufno, 0, -1, false)
	vim.api.nvim_set_option_value("modified", false, { buf = state.bufno })

	local deleted = {}
	local added = {}

	local current_names = {}

	for _, line in ipairs(lines) do
		local name = line:gsub("^%s+", ""):gsub("/$", "")
		current_names[name] = true
	end

	for _, file in ipairs(state.files) do
		if not current_names[file.filename] then
			deleted[#deleted + 1] = file.filename
		end
	end

	for _, dir in ipairs(state.directories) do
        print(dir.filename, current_names[dir.filename])
		if not current_names[dir.filename] then
			deleted[#deleted + 1] = dir.filename
		end
	end

	local existing_names = {}

	for _, file in ipairs(state.files) do
		existing_names[file.filename] = true
	end

	for _, dir in ipairs(state.directories) do
		existing_names[dir.filename] = true
	end

	for _, line in ipairs(lines) do
		local name = line:gsub("^%s+", ""):gsub("/$", "")
		if name ~= "" and not existing_names[name] then
			added[#added + 1] = name
		end
	end

    handleFSChanges(added, deleted)
end

local updateBuffer = function()
	local text = {}
	local linenum = 0

	for _, file in ipairs(state.directories) do
		text[#text + 1] = " " .. file.filename .. "/"
		linenum = linenum + 1
	end

	for _, file in ipairs(state.files) do
		text[#text + 1] = file.filename
		linenum = linenum + 1
	end

	vim.schedule(function()
		vim.api.nvim_buf_set_lines(state.bufno, 0, -1, false, text)
		state.lastbuf = text

		local ns_id = vim.api.nvim_create_namespace("iconcol")

		if Plugin.options.showIcons then
			linenum = 0

			for _, dir in ipairs(state.directories) do
				local icon = icons.get_icon(dir.filename, dir.extension, { default = true })
				vim.api.nvim_buf_set_extmark(state.bufno, ns_id, linenum, 0, {
					virt_text = { { icon .. " ", "Normal" } },
					virt_text_pos = "inline",
				})

				linenum = linenum + 1
			end

			for _, file in ipairs(state.files) do
				local icon = icons.get_icon(file.filename, file.extension, { default = true })

				vim.api.nvim_buf_set_extmark(state.bufno, ns_id, linenum, 0, {
					virt_text = { { icon .. " ", "Normal" } },
					virt_text_pos = "inline",
				})

				linenum = linenum + 1
			end
		end

		vim.api.nvim_set_option_value("modified", false, { buf = state.bufno })
	end)
end

local closeSidebar = function()
	if not state.bufno and not state.winno then
		return
	end

	local ns_id = vim.api.nvim_create_namespace("iconcol")
	vim.api.nvim_buf_clear_namespace(state.bufno, ns_id, 0, -1)

	if vim.api.nvim_win_is_valid(state.winno) then
		vim.api.nvim_win_close(state.winno, true)
	end

	if vim.api.nvim_buf_is_valid(state.bufno) then
		vim.api.nvim_buf_delete(state.bufno, { force = true })
	end

	state.winno = nil
	state.bufno = nil
	state.isSideBarOpen = false
	state.files = {}
	state.directories = {}
end

local createSidebar = function()
	state.isSideBarOpen = true

	vim.cmd("vsplit")

	state.winno = vim.api.nvim_get_current_win()
	state.bufno = vim.api.nvim_create_buf(true, true)

	vim.api.nvim_win_set_buf(state.winno, state.bufno)

	vim.api.nvim_buf_set_name(state.bufno, "slicktree://sidebar")

	vim.api.nvim_set_option_value("buftype", "acwrite", { buf = state.bufno })
	vim.api.nvim_set_option_value("modifiable", true, { buf = state.bufno })

	print(state.bufno)
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = state.bufno,
		callback = function()
			handleBufUpdate()
		end,
	})
end

local sidebar = function(toggle_type)
	print(toggle_type, state.isSideBarOpen)

	if state.isSideBarOpen then
		if toggle_type == "toggle" or toggle_type == "close" then
			closeSidebar()
			return
		end

		if toggle_type == "focus" or toggle_type == "open" then
			vim.api.nvim_set_current_win(state.winno)
		end
	elseif not state.isSideBarOpen then
		async.run(function()
			getDirInfo()
		end, function()
			updateBuffer()
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
