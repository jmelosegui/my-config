return {
    "mfussenegger/nvim-dap",
    config = function()
        local dap = require("dap")
        local mason_registry = require("mason-registry")

        dap.adapters.coreclr = {
            type = "executable",
            command = "U:\\netcoredbg-win64\\netcoredbg.exe",
            args = { "--interpreter=vscode" }
        }

        dap.configurations.cs = {
            {
                type = "coreclr",
                name = "lauch - netcoredbg",
                request = "launch",
                program = function()
                    return vim.fn.input("Path to dll: ",
                        vim.fn.getcwd() .. "\\Whkm\\bin\\Debug\\net8.0-windows\\Whkm.exe", "file")
                end,
            }
        }

        -- Resolve codelldb from Mason's bin dir under the active Neovim data dir,
        -- so it works regardless of the Windows username. Install it once with
        -- :MasonInstall codelldb
        dap.adapters.codelldb = {
            type = 'server',
            port = '${port}',
            executable = {
                command = vim.fn.stdpath("data") .. "/mason/bin/codelldb.cmd",
                args = { '--port', '${port}' },
            },
        }
        dap.configurations.rust = {
            {
                type = "codelldb",
                name = "Debug",
                request = "launch",
                program = function()
                    -- Default to an executable next to the current file, e.g. a
                    -- `rustc primes.rs` build produces primes.exe alongside primes.rs.
                    local guess = vim.fn.expand("%:p"):gsub("%.rs$", ".exe")
                    return vim.fn.input("Path to executable: ", guess, "file")
                end,
                cwd = function()
                    return vim.fn.expand("%:p:h")
                end,
                -- Prompt for command-line arguments on each launch; split on
                -- spaces so "10 20 foo" becomes { "10", "20", "foo" }. Leave the
                -- prompt empty to run with no args.
                args = function()
                    return vim.split(vim.fn.input("Args: "), " ", { trimempty = true })
                end,
            }
        }
    end
}

