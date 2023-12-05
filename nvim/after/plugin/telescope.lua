local builtin = require('telescope.builtin')
local telescope = require('telescope')


telescope.setup {
    defaults = {
        mappings = {
            i = {
                ['<C-j>'] = builtin.move_selection_next,
                ['<C-k>'] = builtin.move_selection_previous,
            },
            n = {
                ['<C-j>'] = builtin.move_selection_next,
                ['<C-k>'] = builtin.move_selection_previous,
            },
        },
    },
}


-- Telescope keymaps
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find Files' })
--vim.keymap.set('n', ['<C-j>'], builtin.move_selection_next, { desc = 'Move Selection Down' })
--vim.keymap.set('n', '<C-k>', builtin.move_selection_previous, { desc = 'Move Selection Up' })
vim.keymap.set("n", ";", "<cmd>lua require('telescope.builtin').resume(require('telescope.themes').get_ivy({}))<cr>", opts)
