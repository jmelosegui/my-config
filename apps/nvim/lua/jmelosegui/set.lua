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

-- New splits open below / to the right (so :split | term lands in the lower split)
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Use PowerShell (pwsh) instead of cmd.exe for :! commands and :terminal.
-- Falls back to Windows PowerShell if pwsh (PowerShell 7+) is not installed.
-- The shell* options below are the Neovim-recommended settings that make
-- :make/:! redirection and UTF-8 output behave correctly under PowerShell.
if vim.fn.has("win32") == 1 then
    local powershell_options = {
        shell = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell",
        shellcmdflag =
        "-NoLogo -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;",
        shellredir = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode",
        shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode",
        shellquote = "",
        shellxquote = "",
    }
    for option, value in pairs(powershell_options) do
        vim.opt[option] = value
    end
end
