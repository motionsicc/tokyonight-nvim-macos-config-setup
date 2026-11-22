-- Bootstrap lazy.nvim
vim.opt.title = true
vim.opt.titlestring = " nvim"
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Disable default virtual text
vim.diagnostic.config({ virtual_text = false })

require("lazy").setup({
  -- Theme
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function()
      vim.g.tokyonight_style = "storm"
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- EMMET (Trigger: Option + e followed by ,)
  {
    "mattn/emmet-vim",
    ft = { "html", "css", "javascript" },
    config = function()
      vim.g.user_emmet_leader_key = '<M-e>'
    end,
  },

  -- THE SMEAR CURSOR PLUGIN
  {
    "sphamba/smear-cursor.nvim",
    opts = {
      cursor_color = "#7aa2f7",
      stiffness = 0.6,
      trailing_stiffness = 0.3,
    },
  },

  -- AUTO-CLOSE HTML TAGS
  {
    "windwp/nvim-ts-autotag",
    config = function()
      require('nvim-ts-autotag').setup()
    end,
  },

  -- AUTO-CLOSE BRACKETS/PARENS (C++, C, Rust, Python)
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },

  -- THE NEW DIAGNOSTIC PLUGIN
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    config = function()
      require('tiny-inline-diagnostic').setup()
    end
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local ok, ts = pcall(require, "nvim-treesitter.configs")
      if ok then
        ts.setup({
          ensure_installed = { "c", "cpp", "python", "rust", "html", "css", "javascript" },
          highlight = { enable = true },
        })
      end
    end,
  },

  -- LSP & COMPLETION ENGINE
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      require("mason").setup()
      
      local cmp = require("cmp")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local kind_icons = {
        Text = "", Method = "󰆧", Function = "󰊕", Constructor = "", Field = "󰇵",
        Variable = "󰂡", Class = "󰠱", Interface = "", Module = "", Property = "󰜢",
        Unit = "", Value = "󰎟", Enum = "", Keyword = "󰌋", Snippet = "",
        Color = "󰏘", File = "󰈙", Reference = "", Folder = "󰉋", EnumMember = "",
        Constant = "󰏿", Struct = "", Event = "", Operator = "󰆕", TypeParameter = "󰅲",
      }

      cmp.setup({
        snippet = {
          expand = function(args) require("luasnip").lsp_expand(args.body) end,
        },
        formatting = {
          format = function(entry, vim_item)
            vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind)
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              luasnip = "[Snippet]",
              buffer = "[Buffer]",
              path = "[Path]",
            })[entry.source.name]
            return vim_item
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<M-b>"] = cmp.mapping.scroll_docs(-4),
          ["<M-f>"] = cmp.mapping.scroll_docs(4),
          ["<M-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item() else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item() else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
        }, {
          { name = "buffer" },
        }),
      })

      require("mason-lspconfig").setup({
        ensure_installed = { "clangd", "pyright", "rust_analyzer", "html", "cssls", "ts_ls" },
        handlers = {
          function(server_name)
            local opts = { capabilities = capabilities }
            if server_name == "clangd" then
              opts.cmd = {
                "clangd",
                "--background-index",
                "--clang-tidy",
                "--header-insertion=never",
                "--query-driver=*",
                -- MacOS Raylib Header Support
                "-I/opt/homebrew/include",
              }
            end
            require("lspconfig")[server_name].setup(opts)
          end,
        },
      })

      -- LSP Keybinds
      vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = "Show line error" })
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = "LSP Code Actions" })
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = "Show documentation" })
      vim.keymap.set('n', '<leader>m', ':Mason<CR>', { noremap = true, silent = true })
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({ options = { theme = "tokyonight" } })
    end,
  },

  -- File Tree
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        sort_by = "name",
        view = { width = 30, side = "left" },
      })
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
    end,
  },

  -- Dashboard
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    config = function()
      require('dashboard').setup {
        theme = 'doom',
        config = {
          header = {
            "",
            " ███╗   ███╗ ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗ ██████╗ ⚡️ ",
            " ████╗ ████║██╔═══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝██║██╔════╝██╔════╝    ",
            " ██╔████╔██║██║   ██║   ██║   ██║██║   ██║██╔██╗ ██║███████╗██║██║      ██║        ",
            " ██║╚██╔╝██║██║   ██║   ██║   ██║██║   ██║██║╚██╗██║╚════██║██║██║      ██║        ",
            " ██║ ╚═╝ ██║╚██████╔╝   ██║   ██║╚██████╔╝██║ ╚████║███████║██║╚██████╗╚██████╗ ⚡️ ",
            " ╚═╝     ╚═╝ ╚═════╝    ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝ ╚═════╝ ╚═════╝    ",
            "",
          },
          center = {
            { action = 'NvimTreeToggle', desc = ' File Explorer', icon = '󰙅 ', key = 'e' },
            { action = 'e $MYVIMRC',    desc = ' Open Config',   icon = ' ', key = 'c' },
            { action = 'qa',             desc = ' Quit',          icon = '󰈆 ', key = 'q' },
          },
        }
      }
    end,
  },
})

-- ===== CLIPBOARD & MACOS SHORTCUTS =====
vim.opt.clipboard = "unnamedplus"
vim.keymap.set("v", "<M-c>", '"+y', { noremap = true, silent = true })
vim.keymap.set("v", "<M-x>", '"+d', { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "<M-v>", '"+p', { noremap = true, silent = true })
vim.keymap.set("i", "<M-v>", '<C-r>+', { noremap = true, silent = true })
vim.keymap.set({ "n", "i" }, "<M-z>", "<Cmd>undo<CR>", { noremap = true, silent = true })
vim.keymap.set({ "n", "i" }, "<M-Z>", "<Cmd>redo<CR>", { noremap = true, silent = true })
vim.keymap.set({ "n", "i" }, "<M-a>", "<Esc>ggVG", { noremap = true, silent = true })
vim.keymap.set({ "n", "i", "v" }, "<M-f>", "<Esc>/", { noremap = true, silent = true })
vim.keymap.set("n", "<Esc>", ":noh<CR><Esc>", { noremap = true, silent = true })

-- ===== SPLIT SCREEN TERMINAL LOGIC =====
local last_built_exe = ""
local function open_right_terminal(cmd)
    vim.cmd("rightbelow vsplit")
    vim.cmd("vertical resize 65")
    if cmd then
        vim.cmd("terminal " .. cmd)
    else
        vim.cmd("terminal")
    end
    vim.cmd("startinsert") 
end

-- ===== WEB DEVELOPMENT SHORTCUTS (GOOGLE CHROME) =====
-- Option + L: Start Live Server using Google Chrome
vim.keymap.set("n", "<M-l>", function()
    vim.cmd("w") -- Auto-save
    local path = vim.fn.expand("%:p:h")
    open_right_terminal("cd \"" .. path .. "\" && live-server --browser=\"google chrome\"")
end, { noremap = true, silent = true, desc = "Live Server (Google Chrome)" })

-- Option + Shift + L: Quick Static Preview in Google Chrome
vim.keymap.set("n", "<M-L>", function()
    vim.cmd("w") -- Auto-save
    vim.cmd("silent !open -a \"Google Chrome\" %")
end, { noremap = true, silent = true, desc = "Google Chrome Preview" })

-- ===== BUILD & RUN LOGIC (C++, Python, Rust) =====
-- Build Shortcut (Option + B)
vim.keymap.set("n", "<M-b>", function()
    vim.cmd("w") -- Auto-save
    local ft = vim.bo.filetype
    local file = vim.fn.expand("%:p")
    last_built_exe = vim.fn.expand("%:p:r")

    -- Raylib MacOS Specific flags
    -- Link Homebrew paths and required Apple Frameworks
    local brew_inc = "-I/opt/homebrew/include"
    local brew_lib = "-L/opt/homebrew/lib"
    local mac_flags = "-lraylib -framework IOKit -framework Cocoa -framework OpenGL -framework CoreVideo"

    if ft == "cpp" then
        open_right_terminal(string.format("g++ -std=c++23 -Wall -Wextra %s %s \"%s\" -o \"%s\" %s", brew_inc, brew_lib, file, last_built_exe, mac_flags))
    elseif ft == "c" then
        open_right_terminal(string.format("gcc -std=c17 -Wall -Wextra %s %s \"%s\" -o \"%s\" %s", brew_inc, brew_lib, file, last_built_exe, mac_flags))
    elseif ft == "rust" then
        open_right_terminal(string.format("rustc \"%s\" -o \"%s\"", file, last_built_exe))
    end
end, { noremap = true, silent = true })

-- Run Shortcut (Option + R)
vim.keymap.set("n", "<M-r>", function()
    vim.cmd("w") -- Auto-save
    local ft = vim.bo.filetype
    local file = vim.fn.expand("%:p")
    if ft == "cpp" or ft == "c" or ft == "rust" then
        if last_built_exe == "" then last_built_exe = vim.fn.expand("%:p:r") end
        if vim.fn.filereadable(last_built_exe) == 1 then
            open_right_terminal('"' .. last_built_exe .. '"')
        else
            print("Error: Build first with Option+B.")
        end
    elseif ft == "python" then
        open_right_terminal("python3 \"" .. file .. "\"")
    end
end, { noremap = true, silent = true })

-- ===== TERMINAL MANAGEMENT =====
-- Option + T: Instantly kill terminal buffer and close split even during running loops
vim.keymap.set('t', '<M-t>', [[<C-\><C-n>:termclose!<CR>]], { noremap = true, silent = true })
vim.keymap.set('n', '<M-t>', ':bd!<CR>', { noremap = true, silent = true })
vim.keymap.set("n", "<leader>t", function() open_right_terminal() end, { noremap = true, silent = true })

-- Global Options
vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- VSCODE-STYLE AUTOSAVE
vim.opt.autowrite = true
vim.opt.autowriteall = true
