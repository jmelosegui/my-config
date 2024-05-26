vim.opt.guicursor = ""

vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true
vim.opt.wrap = false

vim.opt.swapfile = false

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50
vim.opt.colorcolumn = "120"

vim.opt.confirm = true    -- Confirm to save changes before exiting modified buffer
vim.opt.cursorline = true -- Enable highlighting of the current line

vim.g.mapleader = " "

vim.opt.clipboard:append { 'unnamed', 'unnamedplus' }

-- Enable list mode to display whitespace characters
vim.opt.list = true

-- Define how whitespace characters are displayed
vim.opt.listchars:append({ tab = "▸\\ ", trail = "·", extends = "»", precedes = "«", nbsp = "•" })

vim.cmd("highlight SpecialKey ctermfg=red guifg=red")
