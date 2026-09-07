return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = {
        enabled = true,
        exclude = { "vue" },
      },
      servers = {
        hyprls = {},
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                autoSearchPaths = true,
                diagnosticMode = "openFilesOnly",
                useLibraryCodeForTypes = true,
                inlay_hints = {
                  variableTypes = true,
                  callArgumentNames = true,
                  functionReturnTypes = true,
                  genericTypes = true,
                },
              },
            },
          },
        },
        clangd = {
          keys = {
            { "<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header (C++)" },
          },
          capabilities = {
            offsetEncoding = { "utf-16" },
          },
          settings = {
            clangd = {
              InlayHints = {
                Designators = true,
                Enabled = true,
                ParameterNames = true,
                DeducedTypes = true,
              },
            },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              hint = {
                enable = true,
                paramName = "All",
                setType = true,
                paramType = true,
                arrayIndex = "Disable",
              },
            },
          },
        },
        terraformls = {
          root_markers = { ".terraform", ".git", "main.tf", "versions.tf" },
          init_options = {
            experimentalFeatures = {
              prefillRequiredFiles = true,
              validateOnSave = true,
            },
          },
        },
      },
    },
  },
}
