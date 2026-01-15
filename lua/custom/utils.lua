-- nvim/lua/custom/utils.lua
local M = {}

function M.get_git_relative_path()
  local file_path = vim.fn.expand('%:p')
  local git_toplevel_output = vim.fn.systemlist('git rev-parse --show-toplevel')

  if #git_toplevel_output > 0 and git_toplevel_output[1] ~= '' then
    local git_toplevel = vim.fn.fnamemodify(git_toplevel_output[1], ':p')
    -- Remove potential trailing slashes from git_toplevel for consistent path construction
    git_toplevel = git_toplevel:gsub('/$', '')

    -- Calculate the path relative to the Git toplevel
    -- This will correctly handle cases where the file_path is within the git_toplevel
    local relative_path = string.gsub(file_path, '^' .. git_toplevel .. '/', '')
    return relative_path
  else
    -- Not in a Git repository, or command failed, return path relative to current working directory
    -- or absolute path as a fallback.
    -- For this case, let's return path relative to cwd if possible, otherwise full path
    local cwd = vim.fn.getcwd()
    if file_path:find('^' .. cwd, 1, true) then
      return string.gsub(file_path, '^' .. cwd .. '/', '')
    else
      return file_path -- Fallback to absolute path if not relative to cwd either
    end
  end
end

return M
