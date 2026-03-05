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

    -- Aggressive keymap overrides for Neo-tree
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'neo-tree',
      callback = function()
        -- Force space to be the leader key (unmap Neo-tree default)
        vim.keymap.set('n', '<space>', '<space>', { remap = true, buffer = true })

        -- Custom 'u' to go up a directory
        vim.keymap.set('n', 'u', function()
          local state = require('neo-tree.sources.manager').get_state 'filesystem'
          local path = state.path
          local parent = vim.fn.fnamemodify(path, ':h')
          vim.cmd('cd ' .. vim.fn.fnameescape(parent))
          require('neo-tree.sources.manager').navigate(state, parent)
          vim.notify('Changed root to: ' .. parent)
        end, { buffer = true, desc = 'Go up to parent directory' })
      end,
    })
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
    },
    window = {
      mappings = {
        ['\\'] = 'close_window',
        ['J'] = 'next_sibling',
        ['K'] = 'prev_sibling',
        ['j'] = 'none',
        ['k'] = 'none',
        ['Y'] = 'copy_path',
        ['.'] = function(state)
          local node = state.tree:get_node()
          if node.type == 'directory' then
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
        ['h'] = function(state)
          local node = state.tree:get_node()
          if node and node.level > 0 then
            require('neo-tree.ui.renderer').focus_node(state, node:get_parent_id())
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
      },
    },
  },
}
