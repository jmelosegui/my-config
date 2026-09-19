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
                    -- <C-h> and <C-l> are reserved for window navigation
                    -- (see keymaps.lua); oil merges this table over its defaults,
                    -- so they have to be disabled explicitly with `false`.
                    ["<C-h>"] = false,
                    ["<C-l>"] = false,
                    ["<C-x>"] = { "actions.select", opts = { horizontal = true }, desc =
                    "Open the selection in a horizontal split" },
                    ["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open the selection in a new tab" },
                    ["<C-p>"] = "actions.preview",
                    ["<C-c>"] = "actions.close",
                    ["<F5>"] = "actions.refresh",
                    ["-"] = "actions.parent",
                    ["_"] = "actions.open_cwd",
                    ["`"] = "actions.cd",
                    ["~"] = { "actions.cd", opts = { scope = "tab" }, desc =
                    "Change windows directory (:tcd) to the current oil directory" },
                    ["gs"] = "actions.change_sort",
                    ["gx"] = "actions.open_external",
                    ["g."] = "actions.toggle_hidden",
                    ["g\\"] = "actions.toggle_trash",
                    ["gy"] = {
                        callback = function()
                            local oil = require("oil")
                            local entry = oil.get_cursor_entry()
                            local dir = oil.get_current_dir()
                            if not entry or not dir then
                                return
                            end
                            -- Windows-native separators so the path can be pasted
                            -- straight into Explorer or PowerShell.
                            local path = (dir .. entry.name):gsub("/", "\\")
                            vim.fn.setreg("+", path)
                            vim.notify("Copied: " .. path)
                        end,
                        desc = "Copy the full path of the entry under the cursor",
                    },
                },
                view_options = {
                    show_hidden = false, -- Change to true if you want to see dotfiles by default
                },
            })

            -- Recommended: Set a global keymap to open oil in the current file's directory
            vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

            -- Reflect the current working directory in the terminal (Windows Terminal
            -- tab) title. Neovim emits an OSC title escape sequence when `title` is on
            -- and `titlestring` changes. Only `actions.cd` (the ` mapping above) changes
            -- cwd, so DirChanged fires precisely when you press ` inside oil; plain oil
            -- browsing leaves the title untouched.
            vim.o.title = true

            local function set_tab_title()
                local cwd = vim.fn.getcwd()
                -- The tail of a drive root like "T:\" is empty, and an empty
                -- titlestring leaves the old title in place, so fall back to the
                -- full cwd in that case.
                local name = vim.fn.fnamemodify(cwd, ":t")
                if name == "" then
                    name = cwd
                end
                vim.o.titlestring = name
            end

            vim.api.nvim_create_autocmd("DirChanged", {
                group = vim.api.nvim_create_augroup("OilTabTitle", { clear = true }),
                callback = set_tab_title,
            })

            set_tab_title() -- initialize for the launch directory
        end
    },
    {
        "refractalize/oil-git-status.nvim",
        dependencies = { "stevearc/oil.nvim" },
        config = true,
    },
}
