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
        ['<leader>gv'] = function() vim.cmd('DiffviewOpen') end,
        ['<leader>gh'] = function() vim.cmd('DiffviewFileHistory') end,
        ['<leader>gf'] = function(state)
          local node = state.tree:get_node()
          if node then
            vim.cmd('DiffviewFileHistory ' .. vim.fn.fnameescape(node.path))
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
