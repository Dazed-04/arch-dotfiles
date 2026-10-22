return {
  "andythigpen/nvim-coverage",
  dependencies = "nvim-lua/plenary.nvim",
  config = function()
    require("coverage").setup({
      auto_reload = true,
      sign_group = "coverage",
      signs = {
        covered = { hl = "NonText", text = " " },
        uncovered = { hl = "NonText", text = " " },
        partial = { hl = "NonText", text = " " },
      },
      lang = {
        go = {
          coverage_file = "coverage.out",
        },
      },
      highlights = {
        covered = { fg = "#a9b665", bg = "#32361a" },
        uncovered = { fg = "#ea6962", bg = "#3d2726" },
        partial = { fg = "#d8a657", bg = "#3d3218" },
      },
    })

    local ns = vim.api.nvim_create_namespace("coverage_line_hl")
    local hl_visible = false

    local function clear_line_highlights()
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
          vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
        end
      end
    end

    local function apply_line_highlights()
      local cov_file = vim.fn.getcwd() .. "/coverage.out"
      local f = io.open(cov_file, "r")
      if not f then
        return
      end

      clear_line_highlights()

      for line in f:lines() do
        if line:sub(1, 4) ~= "mode" then
          local filepath, sl, el, cnt = line:match("^(.-)%:(%d+)%.%d+,(%d+)%.%d+ %d+ (%d+)$")

          if filepath and sl and el and cnt then
            local filename = filepath:match("[^/]+$")
            local bufnr = vim.fn.bufnr(filename)

            if bufnr ~= -1 then
              local hl = tonumber(cnt) > 0 and "CoverageCovered" or "CoverageUncovered"
              for lnum = tonumber(sl), tonumber(el) do
                vim.api.nvim__buf_debug_extmark(bufnr, ns, lnum - 1, 0, {
                  end_row = lnum - 1,
                  end_col = 0,
                  hl_group = hl,
                  hl_eol = true,
                })
              end
            end
          end
        end
      end
      f:close()
    end

    vim.keymap.set("n", "<leader>tc", function()
      os.execute("go test -coverprofile=coverage.out ./...")
      require("coverage").load(true)
      vim.defer_fn(function()
        apply_line_highlights()
        hl_visible = true
      end, 1500)
    end, { desc = "Run coverage" })

    vim.keymap.set("n", "<leader>tt", function()
      if hl_visible then
        require("coverage").hide()
        clear_line_highlights()
        hl_visible = false
      else
        require("coverage").show()
        vim.defer_fn(apply_line_highlights, 300)
        hl_visible = true
      end
    end, { desc = "Toggle coverage" })

    local function set_coverage_hl()
      vim.api.nvim_set_hl(0, "CoverageCovered", { fg = "#a9b665", bg = "#32361a" })
      vim.api.nvim_set_hl(0, "CoverageUncovered", { fg = "#ea6962", bg = "#3d2726" })
      vim.api.nvim_set_hl(0, "CoveragePartial", { fg = "#d8a657", bg = "#3d3218" })
    end

    set_coverage_hl()
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = set_coverage_hl,
    })
  end,
}
