--[[ 

=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================
========                                    .-----.          ========
========         .----------------------.   | === |          ========
========         |.-""""""""""""""""""-.|   |-----|          ========
========         ||                    ||   | === |          ========
========         ||   KICKSTART.NVIM   ||   |-----|          ========
========         ||                    ||   | === |          ========
========         ||                    ||   |-----|          ========
========         ||:Tutor              ||   |:::::|		========
========         |'-..................-'|   |____o|          ========
========         `"")----------------(""`   ___________	     ========
========        /::::::::::|  |::::::::::\  \ no mouse \     ========
========       /:::========|  |==hjkl==:::\  \ required \    ========
========      '"""""""""""'  '"""""""""""'  '"""""""'   ========
========                                                     ========
=====================================================================
=====================================================================

What is Kickstart?

  Kickstart.nvim is *not* a distribution.

  Kickstart.nvim is a starting point for your own configuration.
    The goal is that you can read every line of code, top-to-bottom, understand
    what your configuration is doing, and modify it to suit your needs.

    Once you've done that, you can start exploring, configuring and tinkering to
    make Neovim your own! That might mean leaving Kickstart just the way it is for a while
    or immediately breaking it into modular pieces. It's up to you!

    If you don't know anything about Lua, I recommend taking some time to read through
    a guide. One possible example which will only take 10-15 minutes:
      - https://learnxinyminutes.com/docs/lua/

    After understanding a bit more about Lua, you can use `:help lua-guide` as a
    reference for how Neovim integrates Lua.
    - :help lua-guide
    - (or HTML version): https://neovim.io/doc/user/lua-guide.html

Kickstart Guide:

  TODO: The very first thing you should do is to run the command `:Tutor` in Neovim.

    If you don't know what this means, type the following:
      - <escape key>
      - :
      - Tutor
      - <enter key>

    (If you already know the Neovim basics, you can skip this step.)

  Once you've completed that, you can continue working through **AND READING** the rest
  of the kickstart init.lua.

  Next, run AND READ `:help`.
    This will open up a help window with some basic information
    about reading, navigating and searching the builtin help documentation.

    This should be the first place you go to look when you're stuck or confused
    with something. It's one of my favorite Neovim features.

    MOST IMPORTANTLY, we provide a keymap "<space>sh" to [s]earch the [h]elp documentation,
    which is very useful when you're not exactly sure of what you're looking for.

  I have left several `:help X` comments throughout the init.lua
    These are hints about where to find more information about the relevant settings,
    plugins or Neovim features used in Kickstart.

   NOTE: Look for lines like this

    Throughout the file. These are for you, the reader, to help you understand what is happening.
    Feel free to delete them once you know what you're doing, but they should serve as a guide
    for when you are first encountering a few different constructs in your Neovim config.

If you experience any errors while trying to install kickstart, run `:checkhealth` for more info.

I hope you enjoy your Neovim journey,
- TJ

P.S. You can delete this when you're done too. It's your config now! :)
--]]

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Nunjucks / 11ty support
vim.filetype.add {
  extension = {
    njk = 'htmldjango',
    usv = 'usv',
  },
}

-- Robust XLSX Editing via CLI Tools
local xlsx_tmp_dir = nil
local original_xlsx_path = nil

vim.api.nvim_create_user_command('XlsxExtract', function()
  original_xlsx_path = vim.fn.expand('%:p')
  if original_xlsx_path == '' or vim.fn.fnamemodify(original_xlsx_path, ':e') ~= 'xlsx' then
    print('Not an XLSX file.')
    return
  end

  xlsx_tmp_dir = vim.fn.tempname()
  vim.fn.mkdir(xlsx_tmp_dir, 'p')
  
  -- Unzip to tmp
  vim.fn.system(string.format('unzip "%s" -d "%s"', original_xlsx_path, xlsx_tmp_dir))
  
  -- Open Neo-tree in the tmp directory
  vim.cmd(string.format('Neotree %s', xlsx_tmp_dir))
  print('Extracted to: ' .. xlsx_tmp_dir .. ' | Use :XlsxPack to save changes.')
end, {})

vim.api.nvim_create_user_command('XlsxPack', function()
  if not xlsx_tmp_dir or not original_xlsx_path then
    print('No active XLSX session found.')
    return
  end

  -- Zip it back up
  -- -j is not used because we need to preserve the directory structure
  local cmd = string.format('cd "%s" && zip -r "%s" .', xlsx_tmp_dir, original_xlsx_path)
  vim.fn.system(cmd)
  print('Saved changes back to: ' .. original_xlsx_path)
end, {})

-- Format XML using python3 (useful for XLSX internal XML)
vim.api.nvim_create_user_command('FormatXML', function()
  vim.cmd('silent %!python3 -c "import xml.dom.minidom, sys; print(xml.dom.minidom.parseString(sys.stdin.read().encode(\'utf-8\')).toprettyxml())"')
  vim.bo.filetype = 'xml'
  vim.bo.buftype = ''
  vim.bo.readonly = false
end, {})

-- USV Visuals: Make non-printable delimiters look nice
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'usv',
  callback = function()
    -- Define a custom highlight group for delimiters and map it to Conceal locally
    vim.cmd 'highlight UsvDelimiter guifg=Teal guibg=#00004d'
    vim.opt_local.winhighlight = 'Conceal:UsvDelimiter'

    -- Show U+001F (US) as ␟ and U+001E (RS) as ␞
    vim.opt_local.list = true
    vim.opt_local.listchars:append 'conceal: '
    -- Use \%x format for Vim regex to match hex characters correctly
    -- We use 'Conceal' group here, which winhighlight maps to 'UsvDelimiter'
    vim.fn.matchadd('Conceal', [[\%x1f]], 10, -1, { conceal = '␟' }) -- US
    vim.fn.matchadd('Conceal', [[\%x1e]], 10, -1, { conceal = '␞' }) -- RS
    vim.opt_local.conceallevel = 2
    vim.opt_local.concealcursor = 'nv' -- Keep concealed in Normal and Visual modes

    -- Navigation: ( and ) for unit separators
    vim.keymap.set('n', ')', '/\\%x1f<CR>', { buffer = true, silent = true, desc = 'Next Unit' })
    vim.keymap.set('n', '(', '?\\%x1f<CR>', { buffer = true, silent = true, desc = 'Prev Unit' })

    -- Treat Record Separator as a newline for editing
    local function RS_to_newline()
      local view = vim.fn.winsaveview()
      -- Replace RS with RS + newline if not already followed by one
      vim.cmd([[silent! %s/\%x1e\n\?/\%x1e\r/g]])
      vim.fn.winrestview(view)
      vim.bo.modified = false
    end

    RS_to_newline()

    vim.api.nvim_create_autocmd('BufWritePre', {
      buffer = 0,
      callback = function()
        -- Strip the newlines we added before saving
        vim.cmd([[silent! %s/\%x1e\n/\%x1e/g]])
      end,
    })

    vim.api.nvim_create_autocmd('BufWritePost', {
      buffer = 0,
      callback = RS_to_newline,
    })

    -- Keymaps to insert delimiters easily in Insert mode
    vim.keymap.set('i', '<M-u>', '\x1f', { buffer = true, desc = 'Insert Unit Separator' })
    vim.keymap.set('i', '<M-r>', '\x1e', { buffer = true, desc = 'Insert Record Separator' })

    -- Function to show the field name based on headers
    local function show_field_name()
      local headers = vim.b.usv_headers
      if not headers then
        vim.api.nvim_echo({ { 'No headers found', 'WarningMsg' } }, false, {})
        return
      end

      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      local prefix = line:sub(1, col)
      local _, count = prefix:gsub('\x1f', '')
      local index = count + 1

      if headers[index] then
        vim.api.nvim_echo({ { 'Field [' .. index .. ']: ', 'Label' }, { headers[index], 'Special' } }, false, {})
      else
        vim.api.nvim_echo({ { 'Field [' .. index .. ']', 'Label' } }, false, {})
      end
    end

    vim.keymap.set('n', 'gh', show_field_name, { buffer = true, desc = 'Show USV field name' })

    -- Header detection logic
    local function set_usv_headers()
      -- Fallback to _header.usv in the same directory
      local fallback_file = vim.fn.expand('%:p:h') .. '/_header.usv'
      local header_line = nil

      if vim.fn.filereadable(fallback_file) == 1 then
        local f = io.open(fallback_file, 'r')
        if f then
          header_line = f:read('*l')
          f:close()
        end
      end

      -- Primary: If no _header.usv, use the first line of the buffer
      if not header_line then
        header_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
      end

      if header_line then
        local t = {}
        -- USV is delimited by \x1f
        for s in string.gmatch(header_line .. '\x1f', '(.-)\x1f') do
          table.insert(t, s)
        end
        vim.b.usv_headers = t
        -- Also set rainbow_csv_header for the plugin, converting back to comma for its internal use
        vim.b.rainbow_csv_header = table.concat(t, ',')
      end
    end

    set_usv_headers()

    -- Force rainbow_csv to try and highlight if it didn't start
    -- This handles files without headers
    vim.defer_fn(function()
      if vim.fn.exists(':RainbowDelim') > 0 then
        -- We manually set the delimiter to US (0x1F)
        vim.cmd('RainbowDelimQuoted \x1f')
      end
    end, 100)
  end,
})

-- Rapid Index Viewer: Merges all .usv files in current dir into one buffer
vim.api.nvim_create_user_command('MergeIndices', function()
  -- Try to find files with .usv extension
  local files = vim.fn.glob('*.usv', false, true)
  if #files == 0 then
    print('No .usv files found in current directory.')
    return
  end

  local lines = {}
  for _, file in ipairs(files) do
    local f = io.open(file, 'rb') -- Open in binary mode to handle Unicode safely
    if f then
      local content = f:read('*all')
      -- Remove trailing newlines/separators to keep it compact
      content = content:gsub('[\n\r]+$', '')
      table.insert(lines, content)
      f:close()
    end
  end

  -- Create a new scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Set filetype FIRST so the autocmd can fire
  vim.api.nvim_buf_set_option(buf, 'filetype', 'usv')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_name(buf, 'MERGED_INDICES')

  -- Open the buffer in a new split
  vim.cmd('split')
  vim.api.nvim_set_current_buf(buf)
end, {})

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.opt.clipboard = 'unnamedplus'

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
--
--  Notice listchars is set using `vim.opt` instead of `vim.o`.
--  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
--   See `:help lua-options`
--   and `:help lua-options-guide`
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.o.inccommand = 'split'

-- Show which line your cursor is on
vim.o.cursorline = true

-- Make line numbers default
vim.o.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.o.relativenumber = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- Set default indent to 4 spaces
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Alt+s as Escape
vim.keymap.set({ 'i', 'v' }, '<M-s>', '<Esc>', { desc = 'Alt+s as Escape' })

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.keymap.set('n', '<leader>yR', function()
  local utils = require('custom.utils')
  vim.fn.setreg('+', utils.get_git_relative_path())
end, { desc = 'Copy Git root relative file path to clipboard' })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end

vim.opt.rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
require('lazy').setup(require 'plugins', {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

vim.keymap.set('n', '<leader>yf', ":lua vim.fn.setreg('+', vim.fn.expand('%:p'))<CR>", { desc = 'Copy current file path to clipboard' })

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
