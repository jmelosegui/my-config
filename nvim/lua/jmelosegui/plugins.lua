return {
  	{ 'mbbill/undotree',                    lazy = false },
	{ 'github/copilot.vim',                 lazy = false },
    { 'nvim-tree/nvim-tree.lua',            dependencies =  { 'nvim-tree/nvim-web-devicons'},    lazy =true },
    { 'nvim-lualine/lualine.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' }, lazy = true },

    --themes
	{ "navarasu/onedark.nvim",            lazy = false },
    { "EdenEast/nightfox.nvim",           priority = 1000,    lazy = false }
}
