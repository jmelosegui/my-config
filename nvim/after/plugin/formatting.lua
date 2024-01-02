local conform = require("conform")

conform.setup({
	formatters_by_ft = {
		javascript = { "prettier" },
		json = { "prettier" },
		lua = { "stylua" },
	},
})

vim.keymap.set({ "n", "v" }, "<C-f>", function()
	conform.format({
		lsp_fallback = true,
		async = false,
		timeout_ms = 500,
	})
end)
