vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.have_nerd_font = true

-- [[ Setting options ]]
vim.o.number = true
vim.o.mouse = "a"
vim.o.showmode = false
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = "yes"
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.o.inccommand = "split"
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true

-- [[ Basic Keymaps ]]
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- [[ Install `lazy.nvim` plugin manager ]]
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
require("lazy").setup({
	{ "NMAC427/guess-indent.nvim", opts = {} },
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
		},
	},

	{ -- Useful plugin to show you pending keybinds.
		"folke/which-key.nvim",
		event = "VimEnter",
		opts = {
			delay = 0,
			icons = { mappings = vim.g.have_nerd_font },
			spec = {
				{ "<leader>s", group = "[S]earch", mode = { "n", "v" } },
				{ "<leader>t", group = "[T]oggle" },
			},
		},
	},

	{ -- Fuzzy Finder (files, lsp, etc)
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			{ "nvim-telescope/telescope-ui-select.nvim" },
		},
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = { require("telescope.themes").get_dropdown() },
				},
			})
			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")

			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
			vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
		end,
	},

	-- LSP Plugins
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			-- FIXED: Corrected repository name here
			{ "williamboman/mason.nvim", config = true },
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			"saghen/blink.cmp",
		},
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			-- ENABLED C++ SUPPORT HERE
			local servers = {
				clangd = {}, -- C++
				lua_ls = {
					settings = {
						Lua = {
							completion = { callSnippet = "Replace" },
							diagnostics = { disable = { "missing-fields" } },
						},
					},
				},
			}

			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, {
				"stylua",
			})

			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			require("mason-lspconfig").setup({
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
						require("lspconfig")[server_name].setup(server)
					end,
				},
			})
		end,
	},

	{ -- Autoformat
		"stevearc/conform.nvim",
		opts = {
			notify_on_error = false,
			format_on_save = { timeout_ms = 500, lsp_fallback = true },
			formatters_by_ft = { lua = { "stylua" } },
		},
	},

	{ -- Autocompletion
		"saghen/blink.cmp",
		version = "v0.*",
		opts = {
			-- We add 'accept' and 'select_and_accept' to ensure Enter works
			keymap = {
				preset = "default",
				["<CR>"] = { "accept", "fallback" }, -- This makes Enter expand snippets
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
		},
	},

	{ -- Theme
		"folke/tokyonight.nvim",
		priority = 1000,
		init = function()
			vim.cmd.colorscheme("tokyonight-night")
		end,
	},

	{ -- Treesitter
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		opts = {
			ensure_installed = { "bash", "c", "cpp", "html", "lua", "markdown", "vim", "vimdoc" },
			auto_install = true,
			highlight = { enable = true },
			indent = { enable = true },
		},
		config = function(_, opts)
			local ok, configs = pcall(require, "nvim-treesitter.configs")
			if not ok then
				return
			end
			configs.setup(opts)
		end,
	},
	{ -- Autopairs (Fixed)
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup({})
		end,
	},
})
-- Compile and Run C++ with 3-window layout (Press F5)
vim.keymap.set("n", "<F5>", function()
	vim.cmd("write")
	local file = vim.fn.expand("%:p")
	local out = vim.fn.expand("%:p:r")
	local input_file = vim.fn.expand("%:p:h") .. "/input.txt"

	-- 1. Create input.txt if missing
	if vim.fn.filereadable(input_file) == 0 then
		vim.fn.writefile({}, input_file)
	end

	-- 2. Open input.txt in a vertical split on the right if not already open
	local input_win = vim.fn.bufwinnr("input.txt")
	if input_win == -1 then
		vim.cmd("vsplit " .. input_file)
		vim.cmd("vertical resize 40") -- Make the input window smaller
		vim.cmd("wincmd h") -- Jump back to the code window
	end

	-- 3. Cleanup old terminals
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.bo[buf].buftype == "terminal" then
			vim.api.nvim_buf_delete(buf, { force = true })
		end
	end

	-- 4. Run the code in a small bottom window
	local cmd = string.format("botright 10split | term g++ -std=c++17 %s -o %s && %s < %s", file, out, out, input_file)
	vim.cmd(cmd)
end, { desc = "Ultimate CP Layout" })
