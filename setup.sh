#!/usr/bin/env bash
set -euo pipefail

echo "Installing base tools..."

sudo apt-get update
sudo apt-get install -y \
  git curl unzip build-essential \
  tmux ripgrep fd-find \
  python3 python3-pip \
  ca-certificates

echo "Installing Node.js 22..."

# Remove Ubuntu's old Node packages, including conflicting headers.
sudo apt-get remove -y \
  nodejs npm libnode-dev nodejs-doc || true

# Recover cleanly if a previous package operation was interrupted.
sudo dpkg --configure -a
sudo apt-get --fix-broken install -y
sudo apt-get clean

curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

echo "Node version:"
node --version
npm --version

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
# Install latest fzf
rm -rf ~/.fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all

# Ensure it wins over apt's version
grep -qxF 'export PATH="$HOME/.fzf/bin:$PATH"' ~/.bashrc || \
      echo 'export PATH="$HOME/.fzf/bin:$PATH"' >> ~/.bashrc

export PATH="$HOME/.fzf/bin:$PATH"
hash -r
# Remove old Ubuntu package if present
sudo apt-get remove -y fzf || true

echo "Creating config dirs..."
mkdir -p ~/.config/nvim ~/.local/share/nvim

echo "Installing lazy.nvim..."
git clone --filter=blob:none https://github.com/folke/lazy.nvim.git \
  ~/.local/share/nvim/lazy/lazy.nvim 2>/dev/null || true

echo "Writing tmux config..."
cat > ~/.tmux.conf <<'EOF'
# Automatically renumber windows when one is closed
set-option -g renumber-windows on

# Set status bar right
set -g status-right '%Y-%m-%d %H:%M #{tmux_mode_indicator}'

### COLOR

# default statusbar colors
set -g mode-style bg=blue,fg=white,bold

set -g status-style bg=black,fg=white,default

# default window title colors
set -g window-status-style fg=brightblue,bg=default

# active window title colors
set -g window-status-current-style fg=yellow,bright

# pane border
set -g pane-border-style fg=black
set -g pane-active-border-style fg=green

# message text
set -g message-style bg=black,fg=brightred

# pane number display
set-option -g display-panes-active-colour blue #blue
set-option -g display-panes-colour brightred #orange

# clock
set-window-option -g clock-mode-colour green #green


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
      update_focused_file = {
        enable = true,
        update_root = true,
      },
      sync_root_with_cwd = true,

      on_attach = function(bufnr)
        local api = require("nvim-tree.api")

        api.config.mappings.default_on_attach(bufnr)

        local opts = { buffer = bufnr, noremap = true, silent = true }

        -- Keep NERDTree muscle memory
        vim.keymap.set("n", "v", api.node.open.horizontal, opts)
        vim.keymap.set("n", "s", api.node.open.vertical, opts)
        vim.keymap.set("n", "t", api.node.open.tab, opts)
      end,
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
  {
    "neovim/nvim-lspconfig",
  },

  {
    "williamboman/mason.nvim",
    opts = {},
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = { "pyright" },
    },
    config = function(_, opts)
      require("mason-lspconfig").setup(opts)
      vim.lsp.enable("pyright")
    end,
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

grep -qxF 'export PATH="/usr/local/bin:$PATH"' ~/.bashrc || \
  echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc

export PATH="/usr/local/bin:$PATH"
hash -r

echo
echo "Done."
echo
echo "Start with:"
echo "  tmux new -s dev"
echo "  nvim"
