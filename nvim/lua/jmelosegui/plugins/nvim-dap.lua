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

        --local codelldb = require('mason-registry').get_package('codelldb'):get_install_path() .. '/codelldb'
        dap.adapters.codelldb = {
            type = 'server',
            port = '${port}',
            executable = {
                --command = "C:\\Users\\jmelo\\AppData\\Local\\nvim-data\\mason\\packages\\codelldb\\extension\\adapter\\codelldb.exe",
                command = "C:\\Users\\jmelo\\AppData\\Local\\nvim-data\\mason\\bin\\codelldb.cmd",
                args = { '--port', '${port}' },
            },
        }
        dap.configurations.rust = {
            {
                type = "codelldb",
                name = "Debug",
                request = "launch",
                program = function()
                    return vim.fn.input("Path to executable: ", "T:/rust/guessing_game/target/debug/guessing_game.exe", "file")
                --    return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/collections.exe", "file")
                end,
                cwd = "T:\\rust\\guessing_game\\"
                --cwd = "${workspaceFolder}"
            }
        }
    end
}

