function ColorMyPencils(color)
	color = color or "nightfox"
	vim.cmd.colorscheme(color)

    vim.api.nvim_set_hl(0, 'Normal', {bg = 'NONE'})
    vim.api.nvim_set_hl(0, 'NormalFloat', {bg = 'NONE'})
    vim.api.nvim_set_hl(0, 'NormalNC', {bg = 'NONE'})
    vim.api.nvim_set_hl(0, 'NormalSB', {bg = 'NONE'})
--    vim.api.nvim_set_hl(0, 'NormalSBFloat', {bg = 'NONE'})
    
end

vim.g.edge_style = 'neon'

require('onedark').setup {
	style = 'deep'
}

ColorMyPencils('nightfox')

