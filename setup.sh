#!/usr/bin/env bash
set -euo pipefail

echo "Installing base tools..."

sudo apt-get update
sudo apt-get install -y \
  git curl unzip build-essential \
  tmux ripgrep fd-find fzf \
  nodejs npm python3 python3-pip \
  ca-certificates

echo "Installing latest stable Neovim..."

curl -L -o /tmp/nvim-linux-x86_64.tar.gz \
  https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz

sudo rm -rf /opt/nvim
sudo mkdir -p /opt/nvim
sudo tar -C /opt/nvim --strip-components=1 \
  -xzf /tmp/nvim-linux-x86_64.tar.gz

sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim

echo "Neovim version:"
nvim --version | head -n 1

echo "Creating config dirs..."
mkdir -p ~/.config/nvim ~/.local/share/nvim

echo "Installing lazy.nvim..."
git clone --filter=blob:none https://github.com/folke/lazy.nvim.git \
  ~/.local/share/nvim/lazy/lazy.nvim 2>/dev/null || true

echo "Writing tmux config..."
cat > ~/.tmux.conf <<'EOF'
set -g mouse on
set -g history-limit 50000
setw -g mode-keys vi

unbind C-b
set -g prefix C-a
bind C-a send-prefix

bind | split-window -h
bind - split-window -v

bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

bind r source-file ~/.tmux.conf \; display-message "tmux reloaded"

set -g base-index 1
setw -g pane-base-index 1
EOF

echo "Writing Neovim config..."
cat > ~/.config/nvim/init.lua <<'EOF'
vim.g.mapleader = " "

-- core vim feel
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.updatetime = 50
vim.opt.termguicolors = true
vim.opt.foldlevel = 99

vim.keymap.set("n", "<Esc>", "<cmd>noh<CR><Esc>")

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "navarasu/onedark.nvim", priority = 1000 },

  { "nvim-lualine/lualine.nvim", opts = { options = { theme = "onedark" } } },

  -- better syntax/highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  -- directory editing, better than file tree for Vim users
  {
    "stevearc/oil.nvim",
    opts = {},
    keys = {
      { "-", "<cmd>Oil<CR>", desc = "Open directory" },
      { "<leader>e", "<cmd>Oil<CR>", desc = "Open directory" },
    },
  },

  -- fuzzy files/search
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>ff", "<cmd>FzfLua files<CR>", desc = "Find files" },
      { "<leader>f", "<cmd>FzfLua live_grep<CR>", desc = "Search repo" },
      { "<leader>fb", "<cmd>FzfLua buffers<CR>", desc = "Buffers" },
      { "<leader>fs", "<cmd>FzfLua lsp_document_symbols<CR>", desc = "Symbols" },
    },
  },

  -- git
  { "tpope/vim-fugitive" },
  { "lewis6991/gitsigns.nvim", opts = {} },

  -- LSP
  { "neovim/nvim-lspconfig" },

  {
    "williamboman/mason.nvim",
      opts = {},
},

{
  "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
      opts = {
          ensure_installed = { "pyright" },
              automatic_enable = true,
                },
},

  -- completion
  {
    "saghen/blink.cmp",
    version = "1.*",
    opts = {
      keymap = { preset = "default" },
      completion = { documentation = { auto_show = true } },
    },
  },

  -- diagnostics UI
  {
    "folke/trouble.nvim",
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix" },
    },
  },

  -- formatting
  {
    "stevearc/conform.nvim",
    opts = {
      format_on_save = false,
    },
    keys = {
      {
        "<leader>fm",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        desc = "Format file",
      },
    },
  },
})

vim.cmd.colorscheme("onedark")

-- windows
vim.keymap.set("n", "<leader>h", "<cmd>wincmd h<CR>")
vim.keymap.set("n", "<leader>j", "<cmd>wincmd j<CR>")
vim.keymap.set("n", "<leader>k", "<cmd>wincmd k<CR>")
vim.keymap.set("n", "<leader>l", "<cmd>wincmd l<CR>")

-- LSP
vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition)
vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references)
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)

-- diagnostics
vim.keymap.set("n", "<leader>n", vim.diagnostic.goto_next)
vim.keymap.set("n", "<leader>p", vim.diagnostic.goto_prev)

-- folding
vim.keymap.set("n", "<leader>z", "za")
EOF

echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
export PATH="/usr/local/bin:$PATH"
hash -r

echo
echo "Done."
echo
echo "Start with:"
echo "  tmux new -s dev"
echo "  nvim"
