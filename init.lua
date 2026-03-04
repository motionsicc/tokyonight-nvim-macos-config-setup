-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
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

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local ok, ts = pcall(require, "nvim-treesitter.configs")
      if ok then
        ts.setup({
          ensure_installed = { "c", "cpp", "python" },
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
        ensure_installed = { "clangd", "pyright" },
        handlers = {
          function(server_name)
            local opts = {}
            if server_name == "clangd" then
              opts = {
                cmd = {
                  "clangd",
                  "--query-driver=*", -- This tells clangd to search all system paths for your compiler
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
      -- This shortcut lets you see the actual error message
      vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = "Show line error" })
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

-- ===== Smart Build/Run Setup =====
local last_built_exe = ""

-- Smart Build (Ctrl+B)
vim.keymap.set("n", "<C-b>", function()
  vim.cmd("w") -- save file
  local ft = vim.bo.filetype
  local file = vim.fn.expand("%:p"):gsub("\\", "/")
  last_built_exe = vim.fn.expand("%:p:r"):gsub("\\", "/") .. ".exe"

  if ft == "cpp" then
    vim.cmd("botright split | resize 12")
    -- Compiling C++ with g++
    vim.cmd(string.format("terminal g++ -std=c++23 -Wall -Wextra \"%s\" -o \"%s\"", file, last_built_exe))
  elseif ft == "c" then
    vim.cmd("botright split | resize 12")
    -- Compiling pure C with gcc to avoid C++ warnings
    vim.cmd(string.format("terminal gcc -std=c17 -Wall -Wextra \"%s\" -o \"%s\"", file, last_built_exe))
  elseif ft == "python" then
    print("Python is interpreted; no build needed! Use Ctrl+R to run.")
  else
    print("Build not configured for filetype: " .. ft)
  end
end, { noremap = true, silent = true })

-- Smart Run (Ctrl+R)
vim.keymap.set("n", "<C-r>", function()
  local ft = vim.bo.filetype
  local file = vim.fn.expand("%:p"):gsub("\\", "/")

  if ft == "cpp" or ft == "c" then
    if last_built_exe == "" then last_built_exe = vim.fn.expand("%:p:r"):gsub("\\", "/") .. ".exe" end
    if vim.fn.filereadable(last_built_exe) == 1 then
      vim.cmd("botright split | resize 12")
      vim.cmd("terminal \"" .. last_built_exe .. "\"")
    else
      print("Error: No executable found. Build first with Ctrl+B.")
    end
  elseif ft == "python" then
    vim.cmd("botright split | resize 12")
    vim.cmd("terminal python \"" .. file .. "\"")
  else
    print("Run not configured for filetype: " .. ft)
  end
end, { noremap = true, silent = true })

-- Open Mason with <leader>m
vim.keymap.set("n", "<leader>m", ":Mason<CR>", { noremap = true, silent = true })

-- Force close terminal with Ctrl-X (No Esc needed)
vim.keymap.set('t', '<C-x>', [[<C-\><C-n>:q<CR>]], { noremap = true, silent = true })

vim.opt.number = true         -- Enables the line numbers
vim.opt.relativenumber = false -- Ensures numbers aren't "reversed" (relative)
