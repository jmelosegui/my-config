return {
    {
        'stevearc/oil.nvim',
        --@module 'oil'
        --@type oil.SetupOpts
        opts = {},
        -- Optional dependencies
        dependencies = { { "nvim-tree/nvim-web-devicons", opts = {} } },
        config = function()
            require("oil").setup({
                -- Optional: Configure your preferences here
                default_file_explorer = true, -- Set oil as the default file explorer
                columns = {
                    "icon",
                    -- "permissions",
                    -- "size",
                    -- "mtime",
                },
                win_options = {
                    -- Required by oil-git-status: reserve two sign columns so it can
                    -- render the index status and working-tree status side by side.
                    signcolumn = "yes:2",
                },
                keymaps = {
                    ["g?"] = "actions.show_help",
                    ["<CR>"] = "actions.select",
                    ["<C-s>"] = { "actions.select", opts = { vertical = true }, desc =
                    "Open the selection in a vertical split" },
                    ["<C-h>"] = { "actions.select", opts = { horizontal = true }, desc =
                    "Open the selection in a horizontal split" },
                    ["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open the selection in a new tab" },
                    ["<C-p>"] = "actions.preview",
                    ["<C-c>"] = "actions.close",
                    ["<C-l>"] = "actions.refresh",
                    ["-"] = "actions.parent",
                    ["_"] = "actions.open_cwd",
                    ["`"] = "actions.cd",
                    ["~"] = { "actions.cd", opts = { scope = "tab" }, desc =
                    "Change windows directory (:tcd) to the current oil directory" },
                    ["gs"] = "actions.change_sort",
                    ["gx"] = "actions.open_external",
                    ["g."] = "actions.toggle_hidden",
                    ["g\\"] = "actions.toggle_trash",
                },
                view_options = {
                    show_hidden = false, -- Change to true if you want to see dotfiles by default
                },
            })

            -- Recommended: Set a global keymap to open oil in the current file's directory
            vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
        end
    },
    {
        "refractalize/oil-git-status.nvim",
        dependencies = { "stevearc/oil.nvim" },
        config = true,
    },
}
