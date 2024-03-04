return {
    "mfussenegger/nvim-dap",
    config = function()
        local dap = require("dap")

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
                    return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "\\Whkm\\bin\\Debug\\net8.0-windows\\Whkm.exe", "file")
                end,
            }
        }
    end
}

