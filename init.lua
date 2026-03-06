-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com", -- Fixed your URL here too
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

-- Disable default virtual text so the new plugin can shine
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

  -- THE NEW DIAGNOSTIC PLUGIN (Now in the right place!)
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
          ensure_installed = { "c", "cpp", "python", "rust" },
          highlight = { enable = true },
        })
      end
    end,
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "clangd", "pyright", "rust_analyzer" },
        handlers = {
          function(server_name)
            local opts = {}
            if server_name == "clangd" then
              opts = {
                cmd = {
                  "clangd",
                  "--query-driver=*", 
                  "--background-index",
                  "--clang-tidy",
                  "--header-insertion=never",
                },
              }
            end
            require("lspconfig")[server_name].setup(opts)
          end,
        },
      })
      -- Keymaps for help/errors
      vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = "Show line error" })
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = "LSP Code Actions / Fix-it" })
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = { theme = "tokyonight" },
      })
    end,
  },

  -- File Tree
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        sort_by = "name",
        renderer = {
          icons = { show = { file = true, folder = true, git = true } },
        },
        view = {
          width = 30,
          side = "left",
        },
      })
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
    end,
  },
})

-- ===== Smart Build/Run Setup (MACOS OPTION KEY VERSION) =====
local last_built_exe = ""

-- Smart Build (Option+B)
vim.keymap.set("n", "<M-b>", function()
  vim.cmd("w") 
  local ft = vim.bo.filetype
  local file = vim.fn.expand("%:p")
  last_built_exe = vim.fn.expand("%:p:r")

  if ft == "cpp" then
    vim.cmd("botright split | resize 12")
    vim.cmd(string.format("terminal g++ -std=c++23 -Wall -Wextra \"%s\" -o \"%s\"", file, last_built_exe))
  elseif ft == "c" then
    vim.cmd("botright split | resize 12")
    vim.cmd(string.format("terminal gcc -std=c17 -Wall -Wextra \"%s\" -o \"%s\"", file, last_built_exe))
  elseif ft == "rust" then
    vim.cmd("botright split | resize 12")
    vim.cmd(string.format("terminal rustc \"%s\" -o \"%s\"", file, last_built_exe))
  elseif ft == "python" then
    print("Python is interpreted; no build needed! Use Option+R to run.")
  else
    print("Build not configured for filetype: " .. ft)
  end
end, { noremap = true, silent = true })

-- Smart Run (Option+R)
vim.keymap.set("n", "<M-r>", function()
  local ft = vim.bo.filetype
  local file = vim.fn.expand("%:p")

  if ft == "cpp" or ft == "c" or ft == "rust" then
    if last_built_exe == "" then last_built_exe = vim.fn.expand("%:p:r") end
    if vim.fn.filereadable(last_built_exe) == 1 then
      vim.cmd("botright split | resize 12")
      vim.cmd("terminal ./" .. vim.fn.fnamemodify(last_built_exe, ":t"))
    else
      print("Error: No executable found. Build first with Option+B.")
    end
  elseif ft == "python" then
    vim.cmd("botright split | resize 12")
    vim.cmd("terminal python3 \"" .. file .. "\"")
  else
    print("Run not configured for filetype: " .. ft)
  end
end, { noremap = true, silent = true })

-- Open Mason with <leader>m
vim.keymap.set("n", "<leader>m", ":Mason<CR>", { noremap = true, silent = true })

-- Force close terminal with Option-X
vim.keymap.set('t', '<M-x>', [[<C-\><C-n>:q<CR>]], { noremap = true, silent = true })

-- Global Options
vim.opt.number = true         
vim.opt.relativenumber = false 
vim.opt.tabstop = 4      
vim.opt.softtabstop = 4  
vim.opt.shiftwidth = 4   
vim.opt.expandtab = true 
