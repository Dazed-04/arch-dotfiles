return {
  {
    "selimacerbas/live-server.nvim",
    lazy = true,
    opts = {
      default_port = 8000,
      live_reload = { enabled = true, inject_script = true, debounce = 120, css_inject = true },
      directory_listing = { enabled = true, show_hidden = true },
    },
    config = function(_, opts)
      require("live_server").setup(opts)
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, {
        require("live_server").statusline,
      })
    end,
  },
}
