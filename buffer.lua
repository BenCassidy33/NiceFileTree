local icons = require("nvim-web-devicons")

local Plugin = require("plugin")

local M = {}

M.UpdateBuffer = function()
	local text = {}
	local linenum = 0

	for _, file in ipairs(Plugin.state.directories) do
		text[#text + 1] = " " .. file.filename .. "/"
		linenum = linenum + 1
	end

	for _, file in ipairs(Plugin.state.files) do
		text[#text + 1] = file.filename
		linenum = linenum + 1
	end

	vim.schedule(function()
		vim.api.nvim_buf_set_lines(Plugin.state.bufno, 0, -1, false, text)
		Plugin.state.lastbuf = text

		local ns_id = vim.api.nvim_create_namespace("iconcol")

		if Plugin.Options.showIcons then
			linenum = 0

			for _, dir in ipairs(Plugin.state.directories) do
				local icon = icons.get_icon(dir.filename, dir.extension, { default = true })
				vim.api.nvim_buf_set_extmark(Plugin.state.bufno, ns_id, linenum, 0, {
					virt_text = { { icon .. " ", "Normal" } },
					virt_text_pos = "inline",
				})

				linenum = linenum + 1
			end

			for _, file in ipairs(Plugin.state.files) do
				local icon = icons.get_icon(file.filename, file.extension, { default = true })

				vim.api.nvim_buf_set_extmark(Plugin.state.bufno, ns_id, linenum, 0, {
					virt_text = { { icon .. " ", "Normal" } },
					virt_text_pos = "inline",
				})

				linenum = linenum + 1
			end
		end

		vim.api.nvim_set_option_value("modified", false, { buf = Plugin.state.bufno })
	end)
end

return M
