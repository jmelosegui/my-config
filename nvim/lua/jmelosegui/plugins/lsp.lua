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
                "gopls",
                "html",
                "jsonls",
                "lua_ls",
                "omnisharp",
                "powershell_es",
                "tsserver",
                "yamlls",
            },
            handlers = {

                function(server_name)
                    local lspconfig = require("lspconfig")

                    local cmp_nvim_lsp = require("cmp_nvim_lsp")

                    local opts = { noremap = true, silent = true }
                    local on_attach = function(client, bufnr)
                        opts.buffer = bufnr

                        opts.desc = "Show LSP references"
                        vim.keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) --show definitions, references

                        opts.desc = "Go to declaration"
                        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

                        opts.desc = "Show LSP definition"
                        vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) --show lsp definitions

                        opts.desc = "Show LSP implementations"
                        vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) --show lsp definitions

                        opts.desc = "Smart Renames"
                        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

                        opts.desc = "Go to previous diagnostic"
                        vim.keymap.set("n", "[d", vim.diagnostic.goto_next, opts)

                        opts.desc = "Go to next diagnostic"
                        vim.keymap.set("n", "]d", vim.diagnostic.goto_prev, opts)
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
    end,
}

