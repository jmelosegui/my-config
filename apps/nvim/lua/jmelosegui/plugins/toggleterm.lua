return {
    "akinsho/toggleterm.nvim",
    version = "*",
    -- Lazy-load: the plugin only wakes up on the command or the keymap below.
    cmd = { "ToggleTerm", "TermExec" },
    keys = {
        { "<leader>t", "<cmd>ToggleTerm<cr>", desc = "Toggle floating terminal" },
    },
    opts = {
        -- A popup window rather than a split; `size` is ignored for floats.
        direction = "float",
        -- Land in insert mode so you can type straight away, like the old
        -- bottom-split mapping did with its trailing `i`.
        start_in_insert = true,
        -- pwsh, as configured in set.lua.
        shell = vim.o.shell,
        float_opts = {
            border = "rounded",
            -- Roughly 85% of the editor, so the popup reads as an overlay
            -- instead of a full-screen buffer.
            width = function()
                return math.floor(vim.o.columns * 0.85)
            end,
            height = function()
                return math.floor(vim.o.lines * 0.85)
            end,
            winblend = 3,
        },
        -- Hide keys, set per terminal buffer. Both modes are covered on purpose:
        -- in normal-in-terminal mode (where <C-\><C-\> leaves you) a plain
        -- <C-t> would otherwise pop the tag stack instead.
        on_open = function(term)
            local function hide(mode, lhs)
                vim.keymap.set(mode, lhs, "<cmd>ToggleTerm<cr>", {
                    buffer = term.bufnr,
                    desc = "Hide the floating terminal",
                    silent = true,
                })
            end
            hide("t", "<C-t>")
            hide("n", "<C-t>")
            -- Fallback that no terminal emulator can intercept: <C-\><C-\>
            -- to leave terminal mode, then q.
            hide("n", "q")
        end,
    },
}
