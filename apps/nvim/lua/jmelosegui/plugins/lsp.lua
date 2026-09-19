return {
    "neovim/nvim-lspconfig",

    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
        { "antosha417/nvim-lsp-file-operations", config = true },
    },

    event = { "BufReadPre", "BufNewFile" },

    config = function()
        require("mason").setup({
            ui = {
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗",
                },
            },
        })

        require("mason-lspconfig").setup({

            ensure_installed = {
                "bashls",
                "cssls",
                "dockerls",
                "docker_compose_language_service",
                "eslint",
                "helm_ls",
                "html",
                "jsonls",
                "lua_ls",
                "omnisharp",
                "powershell_es",
                "terraformls",
                "rust_analyzer",
            },
            handlers = {

                function(server_name)
                    local lspconfig = require("lspconfig")

                    local cmp_nvim_lsp = require("cmp_nvim_lsp")

                    local opts = { noremap = true, silent = true }

                    local on_attach = function(client, bufnr)
                    end

                    local settings = {
                        capabilities = cmp_nvim_lsp.default_capabilities(),
                        on_attach = on_attach,
                    }

                    if server_name == "lua_ls" then
                        settings.settings = {
                            Lua = {
                                diagnostic = {
                                    globals = { "vim" }
                                },
                                workspace = {
                                    library = {
                                        [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                                        [vim.fn.stdpath("config") .. "/lua"] = true
                                    }
                                }
                            }
                        }
                    end

                    lspconfig[server_name].setup(settings)
                end,
            },
        })

        -- Global LSP keybindings
        vim.keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", { noremap = true, silent = true, desc = "Show LSP references" })
        vim.keymap.set("n", "gD", "<cmd>Telescope lsp_declarations<CR>", { noremap = true, silent = true, desc = "Go to declaration" })
        vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", { noremap = true, silent = true, desc = "Show LSP definition" })
        vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", { noremap = true, silent = true, desc = "Show LSP implementations" })
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { noremap = true, silent = true, desc = "Smart Renames" })
        vim.keymap.set("n", "[d", vim.diagnostic.goto_next, { noremap = true, silent = true, desc = "Go to next diagnostic" })
        vim.keymap.set("n", "]d", vim.diagnostic.goto_prev, { noremap = true, silent = true, desc = "Go to previous diagnostic" })
        vim.keymap.set("n", "K", vim.lsp.buf.hover, { noremap = true, silent = true, desc = "Hover documentation" })
    end,
}

