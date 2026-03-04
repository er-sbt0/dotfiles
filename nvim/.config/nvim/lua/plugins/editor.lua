return {
	{
		"swaits/zellij-nav.nvim",
		lazy = false,
		event = "VeryLazy",
		config = function()
			require("zellij-nav").setup({})
			local keys = {
				{
					"<C-h>",
					"<cmd>ZellijNavigateLeftTab<cr>",
					{ silent = true, desc = "Zellij-nav navigate left or tab" },
				},
				{ "<C-j>", "<cmd>ZellijNavigateDown<cr>", { silent = true, desc = "Zellij-nav navigate down" } },
				{ "<C-k>", "<cmd>ZellijNavigateUp<cr>", { silent = true, desc = "Zellij-nav navigate up" } },
				{
					"<C-l>",
					"<cmd>ZellijNavigateRightTab<cr>",
					{ silent = true, desc = "Zellij-nav navigate right or tab" },
				},
			}
			for _, entry in ipairs(keys) do
				vim.keymap.set("n", entry[1], entry[2], entry[3])
			end
		end,
	},
	{
		"folke/sidekick.nvim",
		opts = {
			-- add any options here
			cli = {
				mux = {
					backend = "zellij",
					enabled = true,
				},
			},
		},
		keys = {
			{
				"<tab>",
				function()
					-- if there is a next edit, jump to it, otherwise apply it if any
					if not require("sidekick").nes_jump_or_apply() then
						return "<Tab>" -- fallback to normal tab
					end
				end,
				expr = true,
				desc = "Goto/Apply Next Edit Suggestion",
			},
			{
				"<c-.>",
				function()
					require("sidekick.cli").toggle()
				end,
				desc = "Sidekick Toggle",
				mode = { "n", "t", "i", "x" },
			},
			{
				"<lt>aa",
				function()
					require("sidekick.cli").toggle()
				end,
				desc = "Sidekick Toggle CLI",
			},
			{
				"<lt>as",
				function()
					require("sidekick.cli").select()
				end,
				-- Or to select only installed tools:
				-- require("sidekick.cli").select({ filter = { installed = true } })
				desc = "Select CLI",
			},
			{
				"<lt>ad",
				function()
					require("sidekick.cli").close()
				end,
				desc = "Detach a CLI Session",
			},
			{
				"<lt>at",
				function()
					require("sidekick.cli").send({ msg = "{this}" })
				end,
				mode = { "x", "n" },
				desc = "Send This",
			},
			{
				"<lt>af",
				function()
					require("sidekick.cli").send({ msg = "{file}" })
				end,
				desc = "Send File",
			},
			{
				"<lt>av",
				function()
					require("sidekick.cli").send({ msg = "{selection}" })
				end,
				mode = { "x" },
				desc = "Send Visual Selection",
			},
			{
				"<lt>ap",
				function()
					require("sidekick.cli").prompt()
				end,
				mode = { "n", "x" },
				desc = "Sidekick Select Prompt",
			},
			-- Example of a keybinding to open Claude directly
			{
				"<lt>ac",
				function()
					require("sidekick.cli").toggle({ name = "claude", focus = true })
				end,
				desc = "Sidekick Toggle Claude",
			},
		},
	},
	{
		"stevearc/conform.nvim",
		lazy = true,
		keys = {
			{
				"<lt>r",
				function()
					require("conform").format({ bufnr = vim.api.nvim_get_current_buf() })
				end,
				desc = "Conform format",
			},
			{
				"<lt>R",
				function()
					function GetGitFilePath()
						local bufname = vim.fn.bufname("%")
						local filepath = vim.fn.fnamemodify(bufname, ":p")
						local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
						if vim.v.shell_error ~= 0 then
							return nil
						end
						local relative_path = filepath:sub(#git_root + 2)
						return relative_path
					end

					local gitpath = GetGitFilePath()
					if gitpath ~= nil then
						os.execute(
							"git diff -U0 --no-color --relative HEAD -- " .. gitpath .. " | clang-format-diff -p1 -i"
						)
						vim.api.nvim_command("e")
					end
				end,
				desc = "Conform format git diff",
			},
		},
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
					rust = { "rustfmt" },
					c = { "clang-format" },
					cpp = { "clang-format" },
					python = { "ruff" },
					json = { "jq" },
					javascript = { "deno_fmt" },
					typescript = { "deno_fmt" },
					javascriptreact = { "deno_fmt" },
					typescriptreact = { "deno_fmt" },
					markdown = { "deno_fmt" },
				},
				formatters = {
					["clang-format"] = {
						prepend_args = { "-style", "file" },
					},
					["deno_fmt"] = {
						command = "deno",
						args = { "fmt", "-" }, -- format from stdin
						stdin = true,
					},
					["ruff"] = {
						command = "ruff",
						args = { "format", "-" },
						stdin = true,
					},
					["jq"] = {
						command = "jq",
						args = { "." },
						stdin = true,
					},
				},
				log_level = vim.log.levels.ERROR,
				notify_on_error = true,
			})
		end,
	},
	{
		"Tyler-Barham/floating-help.nvim",
		event = "VeryLazy",
		config = function()
			require("floating-help").setup({
				-- Defaults
				width = 0.5, -- Whole numbers are columns/rows
				height = 0.9, -- Decimals are a percentage of the editor
				position = "E", -- NW,N,NW,W,C,E,SW,S,SE (C==center)
				border = "rounded", -- rounded,double,single
				onload = function(_)
					vim.cmd("normal! zz")
				end,
			})

			local function cmd_abbrev(abbrev, expansion)
				local cmd = "cabbr "
					.. abbrev
					.. ' <c-r>=(getcmdpos() == 1 && getcmdtype() == ":" ? "'
					.. expansion
					.. '" : "'
					.. abbrev
					.. '")<CR>'
				vim.cmd(cmd)
			end
			-- Redirect `:h` to `:FloatingHelp`
			cmd_abbrev("h", "FloatingHelp")
			cmd_abbrev("help", "FloatingHelp")
			cmd_abbrev("helpc", "FloatingHelpClose")
			cmd_abbrev("helpclose", "FloatingHelpClose")
		end,
	},
	{
		"nvim-tree/nvim-tree.lua",
		version = "*",
		event = "VeryLazy",
		keys = {
			{
				"`",
				function()
					require("lazy").load({ plugins = { "nvim-tree.lua" } }) -- ensure loaded
					require("nvim-tree.api").tree.toggle({ focus = false })
					vim.cmd("wincmd = ")
				end,
				desc = "NvimTree Toggle",
			},
		},
		cmd = { "NvimTreeToggle", "NvimTreeFindFile" },
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("nvim-tree").setup({
				tab = {
					sync = {
						open = true,
						close = true,
						ignore = {},
					},
				},
				view = {
					number = false,
					relativenumber = false,
					side = "left",
					preserve_window_proportions = true,
				},
				renderer = {
					indent_width = 2,
					root_folder_label = false,
					indent_markers = {
						enable = true,
						inline_arrows = true,
						icons = {
							corner = "└",
							edge = "│",
							item = "│",
							bottom = "─",
							none = " ",
						},
					},
				},
				hijack_cursor = false,
				update_focused_file = {
					enable = false,
					-- update_root = false,
				},
				actions = {
					open_file = {
						window_picker = {
							enable = false,
						},
					},
				},
				on_attach = function(bufnr)
					local api = require("nvim-tree.api")

					local function opts(desc)
						return {
							desc = "nvim-tree: " .. desc,
							buffer = bufnr,
							noremap = true,
							silent = true,
							nowait = true,
						}
					end

					-- default mappings
					api.config.mappings.default_on_attach(bufnr)
					-- custom mappings
					vim.keymap.set("n", "<c-y>", api.tree.change_root_to_parent, opts("NvimTree Up"))
				end,
			})
		end,
	},
	{
		"nvim-lua/plenary.nvim",
		lazy = false,
	},
	{
		"akinsho/bufferline.nvim",
		dependencies = "nvim-tree/nvim-web-devicons", -- Fixed: 'requires' should be 'dependencies'
		event = "UIEnter",
		config = function()
			require("bufferline").setup({
				options = {
					mode = "tabs",
					separator_style = "slant",
					show_buffer_icons = false,
					show_buffer_close_icons = false,
					show_close_icon = false,
					tab_size = 20, -- Set the fixed width of tabs
					diagnostics = true,
					always_show_bufferline = true,
					show_tab_indicators = false,
					buffer_close_icon = "", -- Icon to close buffer
					modified_icon = "", -- Icon for modified buffers
					close_icon = "", -- Close all buffers icon
					left_trunc_marker = "", -- Icon for truncated buffers on the left
					right_trunc_marker = "", -- Icon for truncated buffers on the right
					offsets = {
						{
							filetype = "NvimTree",
							text = "File Explorer",
							text_align = "left",
							separator = true,
						},
					},
				},
				highlights = {
					fill = {
						fg = "none", -- Foreground color
						bg = "none", -- Background color
					},
					background = {
						bg = "#4a4a4a",
					},
					separator = {
						bg = "#4a4a4a",
					},
					separator_selected = {
						bg = "#4a4a4a",
						fg = "#4a4a4a",
					},
					buffer_selected = {
						bg = "#4a4a4a",
						fg = "#ffffff",
					},
				},
			})
			-- vim.o.showtabline = 2
		end,
	},
	{
		"mg979/vim-visual-multi",
		event = "VeryLazy",
		init = function()
			vim.g.VM_maps = {
				["Visual ALL"] = "<C-n>",
				["Find Under"] = "<C-n>",
				["Skip Region"] = "<down>",
			}
		end,
	},
	{
		"folke/edgy.nvim",
		event = "VeryLazy",
		init = function()
			vim.opt.laststatus = 3
			vim.opt.splitkeep = "screen"
		end,
		opts = {
			animate = {
				enabled = false,
			},
			bottom = {
				{
					title = "Diagnostics",
					ft = "trouble",
					filter = function(_, win)
						return vim.w[win].trouble and vim.w[win].trouble.mode == "diagnostics"
					end,
					open = function()
						vim.cmd("Trouble diagnostics")
					end,
					size = { height = 12 },
					pinned = false,
					collapsed = false, -- show window as closed/collapsed on start
				},
			},
			right = {
				{
					title = "Symbols",
					ft = "trouble",
					filter = function(_, win)
						return vim.w[win].trouble and vim.w[win].trouble.mode == "lsp_document_symbols"
					end,
					open = function()
						vim.cmd("Trouble lsp_document_symbols")
					end,
					size = { width = 55, height = 1.0 },
					pinned = false,
					collapsed = false, -- show window as closed/collapsed on start
				},
				{
					title = "Sidekick",
					ft = "sidekick_terminal",
					-- filter = function(_, win)
					-- 	return vim.w[win].trouble and vim.w[win].trouble.mode == "lsp_document_symbols"
					-- end,
					open = function()
						vim.cmd("Sidekick cli toggle opencode")
					end,
					size = { width = 85, height = 1.0 },
					pinned = false,
					collapsed = false, -- show window as closed/collapsed on start
				},
			},
			left = {
				-- NvimTree - constant sidebar that won't be interfered with
				{
					title = "NvimTree",
					ft = "NvimTree",
					pinned = true,
					collapsed = false,
					open = function()
						require("nvim-tree.api").tree.open()
					end,
					size = { width = 35 },
				},
				-- -- Neo-tree filesystem always takes half the screen height
				-- {
				-- 	title = "Neo-Tree",
				-- 	ft = "neo-tree",
				-- 	filter = function(buf)
				-- 		return vim.b[buf].neo_tree_source == "filesystem"
				-- 	end,
				-- 	pinned = true,
				-- 	size = { height = 0.5 },
				-- 	open = "Neotree position=left",
				-- },
				-- {
				-- 	title = "Neo-Tree Git",
				-- 	ft = "neo-tree",
				-- 	filter = function(buf)
				-- 		return vim.b[buf].neo_tree_source == "git_status"
				-- 	end,
				-- 	pinned = true,
				-- 	collapsed = false, -- show window as closed/collapsed on start
				-- 	open = "Neotree position=left git_status",
				-- },
				-- {
				-- 	title = "Neo-Tree Buffers",
				-- 	ft = "neo-tree",
				-- 	filter = function(buf)
				-- 		return vim.b[buf].neo_tree_source == "buffers"
				-- 	end,
				-- 	pinned = true,
				-- 	collapsed = false, -- show window as closed/collapsed on start
				-- 	open = "Neotree position=left buffers",
				-- },
			},
			options = {
				left = { size = 35 },
				right = { size = 50 },
				bottom = { size = 8 },
				top = { size = 8 },
			},
			-- Prevent external events from interfering with layout
			fix_win_height = true,
			wo = {
				winhl = "",
				winfixwidth = true,
				winfixheight = true,
			},
		},
		fix_win_height = true,
	},
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			win = {
				enabled = true,
				border = "rounded",
			},
			bigfile = {
				enabled = false,
				size = 256 * 1024, -- 256KB
			},
			dashboard = {
				enabled = false,
			},
			notifier = {
				enabled = true,
				timeout = 3000,
			},
			quickfile = {
				enabled = true,
			},
			statuscolumn = {
				enabled = false,
			},
			words = {
				enabled = true,
			},
			terminal = {
				enabled = true,
			},
			zen = {
				enabled = true,
				enter = true,
				toggles = {
					dim = false,
				},
				fixbuf = true,
				minimal = true,
				width = 120,
				height = 0,
				backdrop = { transparent = true, blend = 40 },
				keys = { q = false },
				zindex = 40,
				wo = {
					winhighlight = "NormalFloat:Normal",
				},
				zoom_indicator = {
					text = "▍ zoom  󰊓  ",
					minimal = true,
					enter = true,
					focusable = true,
					height = 1,
					row = 0,
					col = -1,
					backdrop = true,
				},
			},
			styles = {
				notification = {
					wo = { wrap = true }, -- Wrap notifications
				},
			},
			picker = {
				enabled = true,
				win = {
					preview = {
						wo = {
							statuscolumn = "   ",
							signcolumn = "yes",
							number = false,
							relativenumber = false,
						},
					},
				},
			},
		},
		keys = {
			{
				"<lt>/",
				function()
					Snacks.picker.grep({ cwd = vim.g.snacks_dir or vim.fn.getcwd() })
				end,
				desc = "Snacks Picker Grep",
			},
			{
				"<lt>w",
				function()
					Snacks.picker.lsp_workspace_symbols()
				end,
				desc = "Snacks Picker LSP Workspace Symbols", -- Fixed description
			},
			{
				"<lt>n",
				function()
					Snacks.picker.notifications()
				end,
				desc = "Snacks Picker Notification History",
			},
			{
				"<lt>f",
				function()
					Snacks.picker.files()
				end,
				desc = "Snacks Picker Files",
			},
			{
				"<lt>e",
				function()
					Snacks.explorer()
				end,
				desc = "Snacks Picker File Explorer",
			},
			{
				"<lt>gl",
				function()
					Snacks.picker.git_log()
				end,
				desc = "Snacks Picker Git Log",
			},
			{
				"<lt>gL",
				function()
					Snacks.picker.git_log_line()
				end,
				desc = "Snacks Picker Git Log Line",
			},
			{
				"<lt>gf",
				function()
					Snacks.picker.git_log_file()
				end,
				desc = "Snacks Picker Git Log File",
			},
			{
				"<lt>k",
				function()
					Snacks.picker.keymaps()
				end,
				desc = "Snacks Picker Keymaps",
			},
			{
				"<lt>.",
				function()
					Snacks.scratch()
				end,
				desc = "Snacks Toggle Scratch Buffer",
			},
			{
				"<lt>S",
				function()
					Snacks.scratch.select()
				end,
				desc = "Snacks Select Scratch Buffer",
			},
			{
				"<lt>hs",
				function()
					Snacks.notifier.show_history()
				end,
				desc = "Snacks Notification History",
			},
			{
				"<lt>bd",
				function()
					Snacks.bufdelete()
				end,
				desc = "Snacks Delete Buffer",
			},
			{
				"<lt>cR",
				function()
					Snacks.rename.rename_file()
				end,
				desc = "Snacks Rename File",
			},
			{
				"<lt>gB",
				function()
					Snacks.gitbrowse()
				end,
				desc = "Snacks Git Browse",
			},
			{
				"<lt>gb",
				function()
					Snacks.git.blame_line()
				end,
				desc = "Snacks Git Blame Line",
			},
			{
				"<lt>gf",
				function()
					Snacks.lazygit.log_file()
				end,
				desc = "Snacks Lazygit Current File History",
			},
			{
				"<lt>gl",
				function()
					Snacks.lazygit.log()
				end,
				desc = "Snacks Lazygit Log (cwd)",
			},
			{
				"<lt>go",
				function()
					Snacks.lazygit.open()
				end,
				desc = "Snacks Lazygit (cwd)",
			},
			{
				"<c-\\>",
				function()
					Snacks.terminal()
				end,
				desc = "Snacks Toggle Terminal",
			},
			{
				";;",
				function()
					Snacks.words.jump(vim.v.count1, true)
				end,
				desc = "Snacks Next Reference",
				mode = { "n", "t" },
			},
			{
				";[",
				function()
					Snacks.words.jump(-vim.v.count1, true)
				end,
				desc = "Snacks Prev Reference",
				mode = { "n", "t" },
			},
		},
		init = function()
			vim.api.nvim_create_autocmd("User", {
				pattern = "VeryLazy",
				callback = function()
					-- Setup some globals for debugging (lazy-loaded)
					_G.dd = function(...)
						Snacks.debug.inspect(...)
					end
					_G.bt = function()
						Snacks.debug.backtrace()
					end
					vim.print = _G.dd -- Override print to use snacks for `:=` command

					-- Create some toggle mappings
					Snacks.toggle.option("spell", { name = "Spelling" }):map("<lt>us")
					Snacks.toggle.option("wrap", { name = "Wrap" }):map("<lt>uw")
					Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<lt>uL")
					Snacks.toggle.diagnostics({ name = "Diagnostics" }):map("<lt>ud")
					Snacks.toggle.line_number({ name = "Line Numbers" }):map("<lt>ul")
					Snacks.toggle
						.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
						:map("<lt>uc")
					Snacks.toggle.treesitter({ name = "Treesitter" }):map("<lt>uT")
					Snacks.toggle
						.option("background", { off = "light", on = "dark", name = "Dark Background" })
						:map("<lt>ub")
					Snacks.toggle.inlay_hints({ name = "Inlay Hints" }):map("<lt>uh")
					Snacks.toggle.zen():map("<lt>z")

					-- Use local variable instead of global
					local snacks_dir = vim.fn.getcwd()
					vim.keymap.set("n", "<lt>dp", function()
						snacks_dir = vim.fn.input({
							prompt = "Enter directory path: ",
							default = snacks_dir,
							completion = "file",
						})
					end, { noremap = true, silent = true, desc = "Set picker directory" })

					-- Store in vim.g instead of _G for better namespace
					vim.g.snacks_dir = snacks_dir
				end,
			})
		end,
	},
	{
		"okuuva/auto-save.nvim",
		version = "^1.0.0", -- see https://devhints.io/semver, alternatively use '*' to use the latest tagged release
		event = { "InsertLeave", "TextChanged" }, -- optional for lazy loading on trigger events
		opts = {
			enabled = true, -- start auto-save when the plugin is loaded (i.e. when your package manager loads it)
			trigger_events = { -- See :h events
				immediate_save = { "BufLeave", "FocusLost", "QuitPre", "VimSuspend" }, -- vim events that trigger an immediate save
				defer_save = { "InsertLeave", "TextChanged" }, -- vim events that trigger a deferred save (saves after `debounce_delay`)
				cancel_deferred_save = { "InsertEnter" }, -- vim events that cancel a pending deferred save
			},
			-- function that takes the buffer handle and determines whether to save the current buffer or not
			-- return true: if buffer is ok to be saved
			-- return false: if it's not ok to be saved
			-- if set to `nil` then no specific condition is applied
			condition = nil,
			write_all_buffers = false, -- write all buffers when the current one meets `condition`
			noautocmd = false, -- do not execute autocmds when saving
			lockmarks = false, -- lock marks when saving, see `:h lockmarks` for more details
			debounce_delay = 1000, -- delay after which a pending save is executed
			-- log debug messages to 'auto-save.log' file in neovim cache directory, set to `true` to enable
			debug = false,
		},
	},
	{
		"nvim-tree/nvim-web-devicons",
		lazy = true,
		module = false, -- Don't auto-load on require
		config = function()
			require("nvim-web-devicons").setup({
				-- your personnal icons can go here (to override)
				-- you can specify color or cterm_color instead of specifying both of them
				-- DevIcon will be appended to `name`
				view = {
					signcolumn = "no", -- from nvim-tree docs
					number = false,
					relativenumber = false,
				},
				override = {
					zsh = {
						icon = "",
						color = "#428850",
						cterm_color = "65",
						name = "Zsh",
					},
				},
				number = false,
				-- globally enable different highlight colors per icon (default to true)
				-- if set to false all icons will have the default icon's color
				color_icons = true,
				-- globally enable default icons (default to false)
				-- will get overriden by `get_icons` option
				default = true,
				-- globally enable "strict" selection of icons - icon will be looked up in
				-- different tables, first by filename, and if not found by extension; this
				-- prevents cases when file doesn't have any extension but still gets some icon
				-- because its name happened to match some extension (default to false)
				strict = true,
				-- same as `override` but specifically for overrides by filename
				-- takes effect when `strict` is true
				override_by_filename = {
					[".gitignore"] = {
						icon = "",
						color = "#f1502f",
						name = "Gitignore",
					},
				},
				-- same as `override` but specifically for overrides by extension
				-- takes effect when `strict` is true
				override_by_extension = {
					["log"] = {
						icon = "",
						color = "#81e043",
						name = "Log",
					},
				},
			})
		end,
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
		config = function()
			require("noice").setup({
				log = nil,
				log_max_size = 0,
				markdown = {
					hover = {
						["|(%S-)|"] = vim.cmd.help, -- vim help links
						["%[.-%]%((%S-)%)"] = require("noice.util").open, -- markdown links
					},
					highlights = {
						["|%S-|"] = "@text.reference",
						["@%S+"] = "@parameter",
						["^%s*(Parameters:)"] = "@text.title",
						["^%s*(Return:)"] = "@text.title",
						["^%s*(See also:)"] = "@text.title",
						["{%S-}"] = "@parameter",
					},
				},
				health = {
					checker = true, -- Disable if you don't want health checks to run
				},
				notify = {
					-- Noice can be used as `vim.notify` so you can route any notification like other messages
					-- Notification messages have their level and other properties set.
					-- event is always "notify" and kind can be any log level as a string
					-- The default routes will forward notifications to nvim-notify
					-- Benefit of using Noice for this is the routing and consistent history view
					enabled = true,
					view = "notify",
				},
				-- default options for require('noice').redirect
				-- see the section on Command Redirection
				redirect = {
					view = "popup",
					filter = { event = "msg_show" },
				},
				-- You can add any custom commands below that will be available with `:Noice command`
				commands = {
					history = {
						filter_opts = { count = 1 },
						-- options for the message history that you get with `:Noice`
						view = "split",
						opts = { enter = true, format = "details" },
						filter = {
							any = {
								{ event = "notify" },
								{ error = true },
								{ warning = true },
								{ event = "msg_show", kind = { "" } },
								{ event = "lsp", kind = "message" },
							},
						},
					},
					-- :Noice last
					last = {
						view = "popup",
						opts = { enter = true, format = "details" },
						filter = {
							any = {
								{ event = "notify" },
								{ error = true },
								{ warning = true },
								{ event = "msg_show", kind = { "" } },
								{ event = "lsp", kind = "message" },
							},
						},
						filter_opts = { count = 1 },
					},
					-- :Noice errors
					errors = {
						-- options for the message history that you get with `:Noice`
						view = "popup",
						opts = { enter = true, format = "details" },
						filter = { error = true },
						filter_opts = { reverse = true },
					},
					all = {
						-- options for the message history that you get with `:Noice`
						view = "split",
						opts = { enter = true, format = "details" },
						filter = {},
						filter_opts = { count = 1 },
					},
				},
				throttle = 1000 / 30, -- how frequently does Noice need to check for ui updates? This has no effect when in blocking mode.
				views = {
					scrollbar = { enabled = false },
				}, ---@see section on views
				status = {}, --- @see section on statusline components
				format = {}, --- @see section on formatting
				debug = false,
				cmdline = {
					enabled = true, -- enables the Noice cmdline UI
					view = "cmdline_popup", -- view for rendering the cmdline. Change to `cmdline` to get a classic cmdline at the bottom
					opts = {}, -- global options for the cmdline. See section on views
					format = {
						cmdline = { pattern = "^:", icon = "", lang = "vim" },
						search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
						search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
						filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
						lua = {
							pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" },
							icon = "",
							lang = "lua",
						},
						help = { pattern = "^:%s*he?l?p?%s+", icon = "" },
						input = { view = "cmdline_input", icon = "󰥻 " }, -- Used by input()
						-- lua = false, -- to disable a format, set to `false`
					},
				},
				lsp = {
					progress = {
						enabled = false,
					},
					override = {
						-- override the default lsp markdown formatter with Noice
						["vim.lsp.util.convert_input_to_markdown_lines"] = false,
						-- override the lsp markdown formatter with Noice
						["vim.lsp.util.stylize_markdown"] = false,
						-- override cmp documentation with Noice (needs the other options to work)
						["cmp.entry.get_documentation"] = false,
					},
					hover = {
						enabled = true,
						silent = false, -- set to true to not show a message if hover is not available
						view = nil, -- when nil, use defaults from documentation
						opts = {}, -- merged with defaults from documentation
					},
					signature = {
						enabled = true,
						auto_open = {
							enabled = true,
							trigger = true, -- Automatically show signature help when typing a trigger character from the LSP
							luasnip = true, -- Will open signature help when jumping to Luasnip insert nodes
							throttle = 50, -- Debounce lsp signature help request by 50ms
						},
						view = nil, -- when nil, use defaults from documentation
						opts = {}, -- merged with defaults from documentation
					},
					message = {
						-- Messages shown by lsp servers
						enabled = true,
						view = "notify",
						opts = {},
					},
					-- defaults for hover and signature help
					documentation = {
						view = "hover",
						opts = {
							lang = "markdown",
							replace = true,
							render = "plain",
							format = { "{message}" },
							win_options = { concealcursor = "n", conceallevel = 3 },
						},
					},
				},
				-- you can enable a preset for easier configuration
				presets = {
					bottom_search = false, -- use a classic bottom cmdline for search
					command_palette = true, -- position the cmdline and popupmenu together
					long_message_to_split = true, -- long messages will be sent to a split
					inc_rename = true, -- enables an input dialog for inc-rename.nvim
					lsp_doc_border = true, -- add a border to hover docs and signature help
				},
				messages = {
					-- notify
					-- split
					-- vsplit
					-- popup
					-- mini
					-- cmdline
					-- cmdline_popup
					-- cmdline_output
					-- messages
					-- confirm
					-- hover
					-- popupmenu
					enabled = true, -- enables the Noice messages UI
					view = "notify", -- default view for messages
					view_error = "notify", -- view for errors
					view_warn = "notify", -- view for warnings
					view_history = "messages", -- view for :messages
					view_search = "virtualtext", -- view for search count messages. Set to `false` to disable
				},
				routes = {
					{
						filter = {
							event = "msg_show",
							cmdline = ":w",
						},
						opts = { skip = true },
					},
					{
						filter = {
							event = "msg_show",
							find = "AutoSave",
						},
						opts = { skip = true },
					},
					{
						filter = {
							event = "msg_show",
							find = "Hunk",
						},
						opts = { skip = true },
					},
				},
				popupmenu = {
					enabled = true, -- enables the Noice popupmenu UI
					backend = "nui", -- backend to use to show regular cmdline completions
					kind_icons = {}, -- set to `false` to disable icons
				},
			})
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		event = "UIEnter",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({
				options = {
					icons_enabled = true,
					theme = "auto",
					component_separators = { left = "", right = "" },
					section_separators = { left = "", right = "" },
					disabled_filetypes = {
						statusline = {},
						winbar = {},
					},
					ignore_focus = {},
					always_divide_middle = true,
					globalstatus = false,
					refresh = {
						statusline = 1000,
						tabline = 1000,
						winbar = 1000,
					},
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = {
						"branch",
						"diff",
						{
							"diagnostics",
							sources = { "nvim_diagnostic" },
							symbols = { error = " ", warn = " ", info = " ", hint = " " },
						},
					},
					lualine_c = {
						{
							"filename",
							path = 2,
						},
						{
							"_G.clipboard_icon",
						},
						{
							function() return _G.lsp_progress_status and _G.lsp_progress_status() or "" end,
							cond = function() return _G.lsp_progress_status ~= nil and _G.lsp_progress_status() ~= "" end,
							color = { fg = "#a4beea" },
						},
					},
					lualine_e = {},
					lualine_x = { "encoding", "fileformat", "filetype" },
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
				inactive_sections = {
					lualine_a = {},
				},
				tabline = {},
				winbar = {},
				inactive_winbar = {},
				extensions = {},
			})
		end,
	},
	-- {
	-- 	"nvim-telescope/telescope.nvim",
	-- 	tag = "0.1.4",
	-- 	lazy = true,
	-- 	cmd = { "Telescope" },
	-- 	keys = {
	-- 		{
	-- 			"<lt>f",
	-- 			function()
	-- 				require("telescope.builtin").find_files({
	-- 					cwd = vim.g.snacks_dir or vim.fn.getcwd(),
	-- 					path_display = { "absolute" },
	-- 				})
	-- 			end,
	-- 			desc = "Telescope find files",
	-- 		},
	-- 	},
	-- 	dependencies = {
	-- 		"nvim-lua/plenary.nvim",
	-- 		"nvim-tree/nvim-web-devicons",
	-- 		{
	-- 			"nvim-telescope/telescope-fzf-native.nvim",
	-- 			build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release",
	-- 		},
	-- 		"debugloop/telescope-undo.nvim",
	-- 		"nvim-telescope/telescope-dap.nvim",
	-- 	},
	-- 	config = function()
	-- 		local focus_preview = function(prompt_bufnr)
	-- 			local action_state = require("telescope.actions.state")
	-- 			local picker = action_state.get_current_picker(prompt_bufnr)
	-- 			local prompt_win = picker.prompt_win
	-- 			local previewer = picker.previewer
	-- 			local winid = previewer.state.winid
	-- 			local bufnr = previewer.state.bufnr
	-- 			vim.keymap.set("n", "<Tab>", function()
	-- 				vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", prompt_win))
	-- 			end, { buffer = bufnr })
	-- 			vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", winid))
	-- 			-- api.nvim_set_current_win(winid)
	-- 		end
	-- 		require("telescope").setup({
	-- 			defaults = {
	-- 				layout_config = {
	-- 					prompt_position = "top",
	-- 					horizontal = {
	-- 						preview_cutoff = 120,
	-- 						preview_width = 0.5, -- Ratio of the preview width
	-- 						results_width = 0.5, -- Ratio of the results width
	-- 					},
	-- 					width = 0.75, -- Overall width ratio of the Telescope window
	-- 					height = 0.85, -- Overall height ratio of the Telescope window
	-- 				},
	-- 				file_ignore_patterns = {
	-- 					"node_modules",
	-- 					"^./.git/",
	-- 					"target",
	-- 					"CMpub",
	-- 					"linux80",
	-- 					"linux90",
	-- 					"%.swp$",
	-- 					"%.bak$",
	-- 					"%.tmp$",
	-- 					"%.temp$",
	-- 					"*~$",
	-- 				},
	-- 				file_previewer = require("telescope.previewers").vim_buffer_cat.new,
	-- 				grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
	-- 				qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
	-- 				mappings = {
	-- 					n = {
	-- 						["<C-p>"] = require("telescope.actions.layout").toggle_preview,
	-- 						["<Tab>"] = focus_preview,
	-- 						["<C-]>"] = require("telescope.actions").select_vertical,
	-- 					},
	-- 					i = {
	-- 						["<esc>"] = require("telescope.actions").close,
	-- 						["<C-]>"] = require("telescope.actions").select_vertical,
	-- 						["<C-u>"] = false,
	-- 						["<S-Tab>"] = false,
	-- 						["<Tab>"] = focus_preview,
	-- 						["<C-p>"] = require("telescope.actions.layout").toggle_preview,
	-- 					},
	-- 				},
	-- 			},
	-- 			pickers = {
	-- 				lsp_references = {
	-- 					-- theme = "dropdown",
	-- 				},
	-- 			},
	-- 			extensions = {
	-- 				fzf = {
	-- 					fuzzy = true, -- false will only do exact matching
	-- 					override_generic_sorter = true, -- override the generic sorter
	-- 					override_file_sorter = true, -- override the file sorter
	-- 					case_mode = "smart_case", -- or "ignore_case" or "respect_case"
	-- 				},
	-- 			},
	-- 		})
	--
	-- 		-- Load extensions after setup
	-- 		require("telescope").load_extension("fzf")
	-- 	end,
	-- },
	{
		"mikavilpas/yazi.nvim",
		lazy = true,
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("yazi").setup({
				open_for_directories = false,
			})
		end,
		keys = {
			{
				"\\",
				function()
					require("yazi").yazi()
				end,
				desc = "Open the file manager",
			},
		},
		opts = {
			-- enable this if you want to open yazi instead of netrw.
			-- Note that if you enable this, you need to call yazi.setup() to
			-- initialize the plugin. lazy.nvim does this for you in certain cases.
			open_for_directories = false,
			floating_window_scaling_factor = 0.85,
			-- the transparency of the yazi floating window (0-100). See :h winblend
			yazi_floating_window_winblend = 0,

			log_level = vim.log.levels.OFF,
			yazi_floating_window_border = "none",
		},
	},
}
