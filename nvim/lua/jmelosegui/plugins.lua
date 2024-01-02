return {
	{ "mbbill/undotree", lazy = false },
	--	{'github/copilot.vim',             lazy = false },
	{ "nvim-tree/nvim-tree.lua", lazy = true, dependencies = { "nvim-tree/nvim-web-devicons" } },
	{ "nvim-lualine/lualine.nvim", lazy = true, dependencies = { "nvim-tree/nvim-web-devicons" } },
	{ "nvim-telescope/telescope.nvim", lazy = false, dependencies = { "nvim-lua/plenary.nvim" } },

	--themes
	{ "navarasu/onedark.nvim", lazy = false },
	{ "EdenEast/nightfox.nvim", lazy = false, priority = 1000 },

	--lsp support
	{ "VonHeikemen/lsp-zero.nvim", lazy = true, branch = "v3.x" },
	{ "williamboman/mason.nvim", lazy = false, config = true },
	{ "williamboman/mason-lspconfig.nvim" },
	{ "neovim/nvim-lspconfig" },
	--autocompletion
	{ "hrsh7th/cmp-nvim-lsp" },
	{ "hrsh7th/nvim-cmp" },
	--snippets
	{ "L3MON4D3/LuaSnip" },
	-- formatter
	{ "stevearc/conform.nvim", lazy = true, config = { "BufReadPre", "BufNewFile" } },
}
