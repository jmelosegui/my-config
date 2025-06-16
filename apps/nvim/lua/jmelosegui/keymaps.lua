vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move highlighted line up", silent = true })
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move highlighted line down", silent = true })

vim.keymap.set("n", "J", "mzJ`z", { desc = "Join line below to the current one", silent = true })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll Down, keeping the cursor in the middle of the buffer" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll Up, keeping the cursor in the middle of the buffer" })

-- Split navigation and management
vim.keymap.set("n", "<leader>bb", ":bprev<CR>", { desc = "Goto Previous Buffer", silent = true })
vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Goto Next Buffer", silent = true })

-- Move between splits
vim.keymap.set({ "n" }, "<C-h>", ":wincmd h<CR>", { desc = "Goto Left Buffer", silent = true })
vim.keymap.set({ "n" }, "<C-l>", ":wincmd l<CR>", { desc = "Goto Right Buffer", silent = true })
vim.keymap.set({ "n" }, "<C-j>", ":wincmd j<CR>", { desc = "Goto Below Buffer", silent = true })
vim.keymap.set({ "n" }, "<C-k>", ":wincmd k<CR>", { desc = "Goto Above Buffer", silent = true })

vim.keymap.set({ "n", "t" }, "<S-Left>", ":vertical res +1^M<CR>", { silent = true })
vim.keymap.set({ "n", "t" }, "<S-Right>", ":vertical res -1^M<CR>", { silent = true })
vim.keymap.set({ "n", "t" }, "<C-Up>", ":resize -1<CR>", { silent = true })
vim.keymap.set({ "n", "t" }, "<C-Down>", ":resize +1<CR>", { silent = true })
vim.keymap.set({ "n" }, "<S-l>", "10zl", { desc = "Scroll To The Right", silent = true })
vim.keymap.set({ "n" }, "<S-h>", "10zh", { desc = "Scroll To The Left", silent = true })

-- Play macros
vim.keymap.set("n", "Q", "@qj")
vim.keymap.set("x", "Q", ":norm @q<CR>")

-- Remove lines with only empty spaces
vim.keymap.set("n", "<leader>ev", ":%s/^\\s*$//gn | %s/^\\s*$//g", { desc = "Remove trailing whitespaces" })

-- Format current buffer
vim.keymap.set(
  'n',                   -- mode: normal
  '<leader>f',           -- key combo
  function()             -- what to run
    vim.lsp.buf.format({ async = true })
  end,
  { noremap = true, silent = true, desc = "LSP: format buffer" }
)
