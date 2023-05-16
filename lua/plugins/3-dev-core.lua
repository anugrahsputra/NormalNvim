-- Dev core
-- Things that are just there.


--    Sections:
--       ## TREE SITTER
--       -> nvim-treesitter                [syntax highlight]
--       -> nvim-ts-autotag                [treesitter understand html tags]
--       -> nvim-ts-context-commentstring  [treesitter comments]
--       -> nvim-colorizer                 [hex colors]

--       ## LSP
--       -> SchemaStore.nvim               [lsp schema manager]
--       -> mason.nvim                     [lsp package manager]
--       -> nvim-lspconfig                 [lsp config]
--       -> null-ls                        [code formatting]
--       -> luasnip                        [snippet-engine]

--       ## AUTO COMPLETON
--       -> nvim-cmp                       [auto completion engine]
--       -> cmp-nvim-buffer                [auto completion buffer]
--       -> cmp-nvim-path                  [auto completion path]
--       -> cmp-nvim-lsp                   [auto completion lsp]
--       -> cmp-luasnip                    [auto completion snippets]




return {
  {
    --  PURE CORE -------------------------------------------------------------
    --  [syntax highlight] + [treesitter understand html tags] + [comments]
    --  https://github.com/nvim-treesitter/nvim-treesitter
    --  https://github.com/windwp/nvim-ts-autotag
    --  https://github.com/JoosepAlviste/nvim-ts-context-commentstring

    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "windwp/nvim-ts-autotag",
      "JoosepAlviste/nvim-ts-context-commentstring"
    },
    event = "User BaseFile",
    cmd = {
      "TSBufDisable",
      "TSBufEnable",
      "TSBufToggle",
      "TSDisable",
      "TSEnable",
      "TSToggle",
      "TSInstall",
      "TSInstallInfo",
      "TSInstallSync",
      "TSModuleInfo",
      "TSUninstall",
      "TSUpdate",
      "TSUpdateSync",
    },
    build = ":TSUpdate",
    opts = {
      highlight = {
        enable = true,
        disable = function(_, bufnr) return vim.api.nvim_buf_line_count(bufnr) > 10000 end,
      },
      incremental_selection = { enable = true },
      indent = { enable = true },
      autotag = { enable = true },
      context_commentstring = { enable = true, enable_autocmd = false },
    },
    config = function(_, opts) require("nvim-treesitter.configs").setup(opts) end,
  },



  --  [hex colors]
  --  https://github.com/NvChad/nvim-colorizer.lua
  {
    "NvChad/nvim-colorizer.lua",
    event = "User BaseFile",
    cmd = { "ColorizerToggle", "ColorizerAttachToBuffer", "ColorizerDetachFromBuffer", "ColorizerReloadAllBuffers" },
    opts = { user_default_options = { names = false } },
  },





  --  LSP -------------------------------------------------------------------
  --  Schema Store [lsp schema manager]
  --  https://github.com/b0o/SchemaStore.nvim
  {
    "b0o/SchemaStore.nvim",
    {
      "folke/neodev.nvim",
      opts = {
        override = function(root_dir, library)
          for _, base_config in ipairs(base.supported_configs) do
            if root_dir:match(base_config) then
              library.plugins = true
              break
            end
          end
          vim.b.neodev_enabled = library.enabled
        end,
      },
    },




    --  Syntax highlight [lsp package manager]
    --  https://github.com/williamboman/mason.nvim
    {
      "williamboman/mason.nvim",
      cmd = {
        "Mason",
        "MasonInstall",
        "MasonUninstall",
        "MasonUninstallAll",
        "MasonLog",
        "MasonUpdate",    -- AstroNvim extension here as well
        "MasonUpdateAll", -- AstroNvim specific
      },
      opts = {
        ui = {
          icons = {
            package_installed = "✓",
            package_uninstalled = "✗",
            package_pending = "⟳",
          },
        },
      },
      build = ":MasonUpdate",
      config = function(_, opts)
        require("mason").setup(opts)

        -- TODO: AstroNvim v4: change these auto command names to not conflict with core Mason commands
        local cmd = vim.api.nvim_create_user_command
        cmd("MasonUpdate", function(options) require("base.utils.mason").update(options.fargs) end, {
          nargs = "*",
          desc = "Update Mason Package",
          complete = "custom,v:lua.mason_completion.available_package_completion",
        })
        cmd(
          "MasonUpdateAll",
          function() require("base.utils.mason").update_all() end,
          { desc = "Update Mason Packages" }
        )

        for _, plugin in ipairs { "mason-lspconfig", "mason-null-ls", "mason-nvim-dap" } do
          pcall(require, plugin)
        end
      end,
    },




    --  Syntax highlight [lsp config]
    --  https://github.com/nvim-lspconfig
    {
      "neovim/nvim-lspconfig",
      dependencies = {
        {
          "williamboman/mason-lspconfig.nvim",
          cmd = { "LspInstall", "LspUninstall" },
          opts = function(_, opts)
            if not opts.handlers then opts.handlers = {} end
            opts.handlers[1] = function(server) require("base.utils.lsp").setup(server) end
          end,
          config = function(_, opts)
            require("mason-lspconfig").setup(opts)
            require("base.utils").event "MasonLspSetup"
          end
        },
      },
      event = "User BaseFile",
      config = function(_, _)
        local lsp = require "base.utils.lsp"
        local get_icon = require("base.utils").get_icon
        local signs = {
          { name = "DiagnosticSignError",    text = get_icon "DiagnosticError",        texthl = "DiagnosticSignError" },
          { name = "DiagnosticSignWarn",     text = get_icon "DiagnosticWarn",         texthl = "DiagnosticSignWarn" },
          { name = "DiagnosticSignHint",     text = get_icon "DiagnosticHint",         texthl = "DiagnosticSignHint" },
          { name = "DiagnosticSignInfo",     text = get_icon "DiagnosticInfo",         texthl = "DiagnosticSignInfo" },
          { name = "DapStopped",             text = get_icon "DapStopped",             texthl = "DiagnosticWarn" },
          { name = "DapBreakpoint",          text = get_icon "DapBreakpoint",          texthl = "DiagnosticInfo" },
          { name = "DapBreakpointRejected",  text = get_icon "DapBreakpointRejected",  texthl = "DiagnosticError" },
          { name = "DapBreakpointCondition", text = get_icon "DapBreakpointCondition", texthl = "DiagnosticInfo" },
          { name = "DapLogPoint",            text = get_icon "DapLogPoint",            texthl = "DiagnosticInfo" },
        }

        for _, sign in ipairs(signs) do
          vim.fn.sign_define(sign.name, sign)
        end
        lsp.setup_diagnostics(signs)

        if vim.g.lsp_handlers_enabled then
          vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover,
            { border = "rounded", silent = true })
          vim.lsp.handlers["textDocument/signatureHelp"] =
              vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded", silent = true })
        end
        local setup_servers = function()
          vim.api.nvim_exec_autocmds("FileType", {})
          require("base.utils").event "LspSetup"
        end
        if require("base.utils").is_available "mason-lspconfig.nvim" then
          vim.api.nvim_create_autocmd("User", { pattern = "BaseMasonLspSetup", once = true, callback = setup_servers })
        else
          setup_servers()
        end
      end,
    },




    --  null ls [code formatting]
    --  https://github.com/jose-elias-alvarez/null-ls.nvim
    {
      "jose-elias-alvarez/null-ls.nvim",
      dependencies = {
        {
          "jay-babu/mason-null-ls.nvim",
          cmd = { "NullLsInstall", "NullLsUninstall" },
          opts = { handlers = {} },
        },
      },
      event = "User File",
      opts = function()
        local nls = require("null-ls")
        return {
          sources = {
            nls.builtins.formatting.beautysh.with({
              command = 'beautysh',
              args = {
                "--indent-size=2",
                "$FILENAME"
              },
            }),
          },
          on_attach = require("base.utils.lsp").on_attach
        }
      end
    },




    --  AUTO COMPLETION --------------------------------------------------------
    --  Auto completion engine [autocompletion engine]
    --  https://github.com/hrsh7th/nvim-cmp
    {
      "hrsh7th/nvim-cmp",
      commit = "a9c701fa7e12e9257b3162000e5288a75d280c28", -- https://github.com/hrsh7th/nvim-cmp/issues/1382
      dependencies = {
        "saadparwaiz1/cmp_luasnip",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-nvim-lsp",
      },
      event = "InsertEnter",
      opts = function()
        local cmp = require "cmp"
        local snip_status_ok, luasnip = pcall(require, "luasnip")
        local lspkind_status_ok, lspkind = pcall(require, "lspkind")
        if not snip_status_ok then return end
        local border_opts = {
          border = "single",
          winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
        }

        local function has_words_before()
          local line, col = unpack(vim.api.nvim_win_get_cursor(0))
          return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match "%s" == nil
        end

        return {
          enabled = function()
            if vim.api.nvim_get_option_value("buftype", { buf = 0 }) == "prompt" then return false end
            return vim.g.cmp_enabled
          end,
          preselect = cmp.PreselectMode.None,
          formatting = {
            fields = { "kind", "abbr", "menu" },
            format = lspkind_status_ok and lspkind.cmp_format(base.lspkind) or nil,
          },
          snippet = {
            expand = function(args) luasnip.lsp_expand(args.body) end,
          },
          duplicates = {
            nvim_lsp = 1,
            luasnip = 1,
            cmp_tabnine = 1,
            buffer = 1,
            path = 1,
          },
          confirm_opts = {
            behavior = cmp.ConfirmBehavior.Replace,
            select = false,
          },
          window = {
            completion = cmp.config.window.bordered(border_opts),
            documentation = cmp.config.window.bordered(border_opts),
          },
          mapping = {
            ["<Up>"] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Select },
            ["<Down>"] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Select },
            ["<C-p>"] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert },
            ["<C-n>"] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert },
            ["<C-k>"] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert },
            ["<C-j>"] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert },
            ["<C-u>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
            ["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
            ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
            ["<C-y>"] = cmp.config.disable,
            ["<C-e>"] = cmp.mapping { i = cmp.mapping.abort(), c = cmp.mapping.close() },
            ["<CR>"] = cmp.mapping.confirm { select = false },
            ["<Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              elseif has_words_before() then
                cmp.complete()
              else
                fallback()
              end
            end, { "i", "s" }),
            ["<S-Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { "i", "s" }),
          },
          sources = cmp.config.sources {
            { name = "nvim_lsp", priority = 1000 },
            { name = "luasnip",  priority = 750 },
            { name = "buffer",   priority = 500 },
            { name = "path",     priority = 250 },
          },
        }
      end,
    },
  } -- end of collection
}   -- end of return