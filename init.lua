local async = require("plenary.async")

Plugin = {
    options = {
        showHidden = true
    }
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
---@field stat FileStat

---@class State
---@field workingDirecory string
---@field isSideBarOpen boolean
---@field files FileInfo[]
---@field directories FileInfo[]

---@class State
local state = {
	workingDirecory = vim.fn.getcwd(),

	isSideBarOpen = false,

	files = {},
	directories = {},

	bufno = nil,
	winno = nil,
}

---@return FileInfo
local getFileInfo = function(filename)
	local filepath = state.workingDirecory .. "/" .. filename
	local file_info = {
		filepath = filepath,
		filename = filename,
		stat = nil,
	}

	print("Reading " .. file_info.filepath)

	local _, fd = async.uv.fs_open(filepath, "r", 438)
	local _, stat = async.uv.fs_fstat(fd)
	file_info.stat = stat

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

local createSidebar = function()
	vim.cmd("vsplit")
	state.winno = vim.api.nvim_get_current_win()
	state.bufno = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_win_set_buf(state.winno, state.bufno)
    state.isSideBarOpen = true
end

local writeBuffer = function()
	local text = {}
	for _, file in ipairs(state.directories) do
		text[#text + 1] = file.filename .. "/"
	end

	for _, file in ipairs(state.files) do
		text[#text + 1] = file.filename
	end

    vim.schedule(function ()
	    vim.api.nvim_buf_set_lines(state.bufno, 0, -1, false, text)
    end)
end

local sidebar = function(toggle_type)
    if (toggle_type == "toggle" or toggle_type == "close") and state.isSideBarOpen == true then
        vim.api.nvim_win_close(state.winno, true)

        state.winno = nil
        state.bufno = nil
        state.isSideBarOpen = false
        state.files = {}
        state.directories = {}
    elseif (toggle_type == "open" or toggle_type == "toggle" or toggle_type == "focus") and state.isSideBarOpen == false then
        async.run(function()
            getDirInfo()
        end, function()
            writeBuffer()
        end)

        createSidebar()
    else
        vim.api.nvim_set_current_win(state.winno)
    end
end

Plugin.OpenSidebar = function ()
    sidebar("open")
end

Plugin.CloseSidebar = function ()
    sidebar("close")
end

Plugin.ToggleSidebar = function ()
    sidebar("toggle")
end

Plugin.FocusSidebar = function ()
    sidebar("focus")
end

vim.keymap.set("n", "<leader>S", function ()
    Plugin.ToggleSidebar()
end)
