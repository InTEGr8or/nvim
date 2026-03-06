-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
    { '<leader>e', '<cmd>Neotree toggle<CR>', desc = 'Toggle Neo-tree' },
    { '<leader>E', '<cmd>Neotree reveal<CR>', desc = 'Reveal File in Neo-tree' },
  },
  init = function()
    -- Global command for copying relative path
    vim.api.nvim_create_user_command('CopyRelPath', function()
      local state = require('neo-tree.sources.manager').get_state 'filesystem'
      local node = state.tree:get_node()
      if node then
        local path = node:get_id()
        local relpath = vim.fn.fnamemodify(path, ':.')
        vim.fn.setreg('+', relpath)
        vim.notify('Copied relative path: ' .. relpath)
      else
        vim.notify('No node selected in Neo-tree', vim.log.levels.WARN)
      end
    end, { desc = 'Copy relative path of current Neo-tree node' })

    -- Simple history stack for Neo-tree roots
    _G.neotree_history = {}
  end,
  opts = {
    commands = {
      copy_path = function(state)
        local node = state.tree:get_node()
        local path = node:get_id()
        local relpath = vim.fn.fnamemodify(path, ':.')
        vim.fn.setreg('+', relpath)
        vim.notify('Copied relative path: ' .. relpath)
      end,
      parent_or_back = function(state)
        local current_path = state.path
        if #_G.neotree_history > 0 then
          local last_path = table.remove(_G.neotree_history)
          vim.cmd('cd ' .. vim.fn.fnameescape(last_path))
          require('neo-tree.sources.manager').navigate(state, last_path)
          vim.notify('Back to: ' .. last_path)
        else
          local parent = vim.fn.fnamemodify(current_path, ':h')
          vim.cmd('cd ' .. vim.fn.fnameescape(parent))
          require('neo-tree.sources.manager').navigate(state, parent)
          vim.notify('Up to parent: ' .. parent)
        end
      end,
    },
    window = {
      mappings = {
        ['\\'] = 'close_window',
        ['<space>'] = 'none', -- Definitive fix: Disable space in Neo-tree to allow leader key
        ['u'] = 'parent_or_back',
        ['l'] = 'open', -- Expand folder or open file
        ['h'] = 'close_node', -- Collapse folder
        ['gz'] = function()
          require('telescope').extensions.zoxide.list()
        end,
        ['J'] = 'next_sibling',
        ['K'] = 'prev_sibling',
        ['j'] = 'none',
        ['k'] = 'none',
        ['Y'] = 'copy_path',
        ['.'] = function(state)
          local node = state.tree:get_node()
          if node.type == 'directory' then
            table.insert(_G.neotree_history, state.path) -- Push current root to history
            vim.cmd('cd ' .. vim.fn.fnameescape(node.path))
            require('neo-tree.sources.manager').navigate(state, node.path)
            vim.notify('Changed root to: ' .. node.path)
          else
            vim.notify('Cannot change root to a file', vim.log.levels.WARN)
          end
        end,
        ['C'] = function(state)
          local node = state.tree:get_node()
          if node.type == 'directory' then
            vim.cmd('cd ' .. vim.fn.fnameescape(node.path))
            require('neo-tree.sources.manager').navigate(state, node.path)
            vim.notify('Changed root to: ' .. node.path)
          else
            vim.notify('Cannot change root to a file', vim.log.levels.WARN)
          end
        end,
        ['<leader>gv'] = function(state)
          local root = state.path
          local git_root = vim.fn.systemlist('git -C ' .. vim.fn.shellescape(root) .. ' rev-parse --show-toplevel')[1]
          if git_root then
            require('diffview').open({}, { git_root = git_root })
          else
            vim.notify('Not a git repository: ' .. root, vim.log.levels.WARN)
          end
        end,
        ['<leader>gh'] = function(state)
          local root = state.path
          local git_root = vim.fn.systemlist('git -C ' .. vim.fn.shellescape(root) .. ' rev-parse --show-toplevel')[1]
          if git_root then
            require('diffview').file_history({}, { git_root = git_root })
          else
            vim.notify('Not a git repository: ' .. root, vim.log.levels.WARN)
          end
        end,
        ['<leader>gf'] = function(state)
          local node = state.tree:get_node()
          if node then
            local root = state.path
            local git_root = vim.fn.systemlist('git -C ' .. vim.fn.shellescape(root) .. ' rev-parse --show-toplevel')[1]
            if git_root then
              require('diffview').file_history({ node.path }, { git_root = git_root })
            else
              vim.notify('Not a git repository: ' .. root, vim.log.levels.WARN)
            end
          end
        end,
      },
    },
    filesystem = {
      follow_current_file = {
        enabled = true,
      },
      filtered_items = {
        visible = true,
        hide_git_ignored = true,
        never_show = {
          '.git',
          'node_modules',
          '.ds_store',
        },
      },
      -- Limit large directories for performance
      filter = function(name, path)
        local state = require('neo-tree.sources.manager').get_state 'filesystem'
        local root = state.path
        if root:find 'indexes' or root:find 'queues' then
          -- We use a simple counter attached to the state to limit items
          state.limit_count = (state.limit_count or 0) + 1
          if state.limit_count > 30 then
            return false
          end
        end
        return true
      end,
      find_command = 'fd', -- Use fd for searching (respects .gitignore by default)
      find_args = {
        fd = {
          '--exclude',
          '.git',
          '--exclude',
          'node_modules',
          '--exclude',
          '.mypy_cache',
          '--exclude',
          '.venv',
          '--exclude',
          '__pycache__',
        },
      },
      find_by_full_path_words = true, -- Better path-based fuzzy searching
      window = {
        mappings = {
          ['f'] = 'fuzzy_finder',
          ['/'] = 'fuzzy_finder',
        },
      },
      event_handlers = {
        {
          event = 'neo_tree_directory_opened',
          handler = function(args)
            local state = require('neo-tree.sources.manager').get_state 'filesystem'
            state.limit_count = 0 -- Reset counter on every directory open
            local path = args.path
            if path:find 'indexes' or path:find 'queues' then
              vim.notify('Large directory: Limiting view to first 30 items for performance.', vim.log.levels.WARN)
            end
          end,
        },
      },
    },
  },
}
