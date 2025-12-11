local scan = require("plenary.scandir")

local async = require("plenary.async")
local popup = require("plenary.popup")

local Plugin = require("plugin")

local M = {}

M.cacheFS = function() end

M.MakeFSChanges = function(added, deleted) end

M.HandleFSChanges = function(added, deleted)
	local warning = { "Added:" }

	for _, v in ipairs(added) do
		warning[#warning + 1] = ("    " .. v)
	end

	warning[#warning + 1] = "Deleted:"

	for _, v in ipairs(deleted) do
		warning[#warning + 1] = ("    " .. v)
	end

	warning[#warning + 1] = "Okay? [y/N]"

	local popup_winno = popup.create(warning, {
		minwidth = Plugin.Options.popup_window.min_window_width,
		minheight = Plugin.Options.popup_window.min_window_height,
		borderchars = Plugin.Options.popup_window.borderchars,
		line = math.floor(((vim.o.lines - Plugin.Options.popup_window.min_window_height) / 2) - 1),
		col = math.floor((vim.o.columns - Plugin.Options.popup_window.min_window_width) / 2),
	})

	vim.schedule(function()
		local popup_bufno = vim.api.nvim_win_get_buf(popup_winno)

		vim.api.nvim_set_current_win(popup_winno)
		vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = popup_bufno })
		vim.api.nvim_set_option_value("modifiable", false, { buf = popup_bufno })

		vim.keymap.set("n", "y", function()
			vim.api.nvim_win_close(popup_winno, true)
			M.MakeFSChanges(added, deleted)
		end, { silent = false, buffer = popup_bufno })

		vim.keymap.set("n", "n", function()
			vim.api.nvim_win_close(popup_winno, true)
		end, { silent = false, buffer = popup_bufno })
	end)
end

---@param filename string
---@return FileInfo | Directory
M.GetFileInfo = function(path, filename, depth)
	local filepath = path .. "/" .. filename

	local _, fd = async.uv.fs_open(filepath, "r", 438)
	local _, stat = async.uv.fs_fstat(fd)

	if stat.type == "directory" then
		local children = M.GetDirFiles(filepath)

		---@class Directory
		local directory = {
			name = filename,
			stat = stat,
			children = children,
			isOpen = false,
		}
	else
		---@class File
		local file = {
			name = filename,
			path = filepath,
			extension = filename:match("%.([^%.]+)$"),
			stat = stat,
			bufno = nil,
		}
	end

	async.uv.fs_close(fd)
	return file_info
end

M.GetDirFiles = function(dirpath)
    local files = scan.scan_dir(dirpath, {
        hidden = Plugin.Options.showHidden,
        add_dirs = true,
        respect_gitignore = Plugin.Options.gitIgnore,
        depth = Plugin.maxDepth,
        on_insert = function (entry)
            print("ENTRY: ", vim.inspect(entry))
        end,

    })

    print(vim.inspect(files))

	-- if depth >= Plugin.Options.maxDepth then
	-- 	return nil
	-- end
	--
	-- local files = vim.fn.readdir(dirpath)
	--
	-- for _, filename in ipairs(files) do
	-- 	local info = M.GetFileInfo(dirpath, filename, 0)
	-- 	print(vim.inspect(info))
	-- end

	-- for _, filename in ipairs(files) do
	-- 	local file_info = M.GetFileInfo(filename)
	--
	-- 	if file_info.stat.type == "directory" then
	-- 		Plugin.state.directories[#Plugin.state.directories + 1] = file_info
	-- 	elseif file_info.stat.type == "file" then
	-- 		Plugin.state.files[#Plugin.state.files + 1] = file_info
	-- 	else
	-- 		print("Unsupported file type: ", file_info.filepath)
	-- 	end
	-- end
end

return M
