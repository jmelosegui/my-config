return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local builtin = require("telescope.builtin")
		local telescope = require("telescope")

		telescope.setup({
			defaults = {
				mappings = {
					i = {
						["<C-k>"] = builtin.move_selection_previous,
						["<C-j>"] = builtin.move_selection_next,
						--["<C-q>"] = builtin.send_selected_to_qflist + builtin.open_qflist,
					},
				},
			},
		})

		--telescope.load_extension("fzf")

		-- Telescope keymaps
		vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
		vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent Files" })
		vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live Grep" })
		vim.keymap.set("n", "<leader>fc", builtin.grep_string, { desc = "Grep String" })
	end,
}
