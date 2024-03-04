return {
    "github/copilot.vim",
    config = function ()

        print("Configuring Copilot")

        vim.g.copilot_filetype = { xml = false }

        vim.g.copilot_assume_mapped = true       

        --vim.g.copilot_no_tab_map = true
        --vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("<CR>")', { silent = true, expr = true })

    end,
}

