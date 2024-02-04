local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("jmelosegui.plugins", {
    -- Check for plugins update but do not notify
    checker = {
        enable = true,
        notify = false
    },
    -- Do not notify for updates in the plugins configuration
    change_detection = {
        notify = true
    }
})
