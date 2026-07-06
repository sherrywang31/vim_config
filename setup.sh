#!/usr/bin/env bash
set -euo pipefail

echo "Installing base tools..."

sudo apt-get update
sudo apt-get install -y \
  git curl unzip build-essential \
  tmux ripgrep fd-find \
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

echo "Installing latest fzf..."
if [ -d ~/.fzf ]; then
    git -C ~/.fzf pull
else
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
fi
~/.fzf/install --all
grep -qxF 'export PATH="$HOME/.fzf/bin:$PATH"' ~/.bashrc || \
      echo 'export PATH="$HOME/.fzf/bin:$PATH"' >> ~/.bashrc

export PATH="$HOME/.fzf/bin:$PATH"
hash -r

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
bind m set -g mouse \; display-message "Mouse: #{?mouse,on,off}"

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
tmux source-file ~/.tmux.conf 2>/dev/null || true

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

  -- git status
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = "onedark",
        globalstatus = true,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "filename" },
        lualine_c = { "branch", "diff" },
        lualine_x = { "diagnostics" },
        lualine_y = { "filetype" },
        lualine_z = { "location" },
      },
    },
  },
  -- filetree
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      view = {
        width = 30,
        preserve_window_proportions = true,
      },
      renderer = {
        group_empty = true,
      },
      update_focused_file = {
        enable = true,
        update_root = true,
      },
      sync_root_with_cwd = true,
      filters = {
        dotfiles = false,
      },
    },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<CR>" },
      { "<leader>n", "<cmd>NvimTreeFindFile<CR>" },
    },
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
      -- Find
      { "<leader>ff", "<cmd>FzfLua files<CR>", desc = "Find files" },
      { "<leader>fc", "<cmd>FzfLua live_grep<CR>", desc = "Find code" },
      { "<leader>fb", "<cmd>FzfLua buffers<CR>", desc = "Find buffers" },
      { "<leader>fs", "<cmd>FzfLua lsp_document_symbols<CR>", desc = "Find symbols" },

      -- Git
      { "<leader>gb", "<cmd>FzfLua git_branches<CR>", desc = "Git branches" },
      { "<leader>gc", "<cmd>FzfLua git_commits<CR>", desc = "Git commits" },
      { "<leader>gf", "<cmd>FzfLua git_status<CR>", desc = "Git changed files" },
    },
  },

  -- git
  { "tpope/vim-fugitive" },
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>do", "<cmd>DiffviewOpen<CR>", desc = "Open diff review" },
      { "<leader>dc", "<cmd>DiffviewClose<CR>", desc = "Close diff review" },
      { "<leader>dh", "<cmd>DiffviewFileHistory %<CR>", desc = "File history" },
    },
  },
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

})

vim.cmd.colorscheme("onedark")
-- filetree default open
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function(data)
    local ok, api = pcall(require, "nvim-tree.api")
    if not ok then
      return
    end

    -- Always open the tree
    api.tree.open()

    -- If a directory was passed, cd into it
    if vim.fn.argc() == 1 and vim.fn.isdirectory(data.file) == 1 then
      vim.cmd.cd(data.file)
      api.tree.change_root(vim.fn.getcwd())
    end

    -- If a file was passed, reveal it in the tree
    if vim.fn.argc() > 0 and vim.fn.filereadable(data.file) == 1 then
      api.tree.find_file({
        open = false,
        focus = false,
      })
    end
  end,
})

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
