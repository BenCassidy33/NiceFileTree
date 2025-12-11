M = {}
M.Options = {
	showHidden = true,
	showIcons = true,
    maxDepth = 5,

	popup_window = {
		min_window_width = 40,
		min_window_height = 20,
		borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
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

---@class Directory
---@field isOpen boolean
---@field children (FileInfo | Directory)[] | nil
---@field stat FileStat
---@field name string

---@class State
---@field workingDirecory string
---@field isSideBarOpen boolean
---@field openDirectories string[]
---@field files Directory | nil

---@class State
M.state = {
	workingDirecory = vim.fn.getcwd(),
	isSideBarOpen = false,
	files = nil,
	directories = {},
	openDirectories = {},

	bufno = nil,
	winno = nil,
	lastbuf = nil,
}

return M
