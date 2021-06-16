local config = require 'aerial.config'

local M = {}

M.rpad = function(str, length, padchar)
  if string.len(str) < length then
    return str .. string.rep(padchar or ' ', length - string.len(str))
  end
  return str
end

M.lpad = function(str, length, padchar)
  if string.len(str) < length then
    return string.rep(padchar or ' ', length - string.len(str)) .. str
  end
  return str
end

M.get_width = function(bufnr)
  local status, width = pcall(vim.api.nvim_buf_get_var, bufnr or 0, 'aerial_width')
  if status then
    return width
  end
  return config.get_min_width()
end

M.set_width = function(bufnr, width)
  if M.get_width(bufnr) == width then
    return
  end
  vim.api.nvim_buf_set_var(bufnr, 'aerial_width', width)
  -- TODO change to win_execute when available
  -- Current implementation won't update the width in other tabs
  local start_winid = vim.fn.win_getid()
  local winid = vim.fn.bufwinid(bufnr)
  if start_winid ~= winid then
    vim.fn.win_gotoid(winid)
    -- autocommand will do the resize
    vim.fn.win_gotoid(start_winid)
  else
    vim.cmd('vertical resize ' .. width)
  end
end

M.is_aerial_buffer = function(bufnr)
  local ft = vim.api.nvim_buf_get_option(bufnr or 0, 'filetype')
  return ft == 'aerial'
end

M.get_aerial_buffer = function(bufnr)
  return M.get_buffer_from_var(bufnr or 0, 'aerial_buffer')
end

M.get_source_buffer = function(bufnr)
  return M.get_buffer_from_var(bufnr or 0, 'source_buffer')
end

M.get_buffer_from_var = function(bufnr, varname)
  local status, result_bufnr = pcall(vim.api.nvim_buf_get_var, bufnr, varname)
  if not status or result_bufnr == nil then
    return -1
  end
  return vim.fn.bufnr(result_bufnr)
end

M.flash_highlight = function(bufnr, lnum, hl_group, durationMs)
  hl_group = hl_group or config.get_highlight_group()
  durationMs = durationMs or 300
  local ns = vim.api.nvim_buf_add_highlight(bufnr, 0, hl_group, lnum - 1, 0, -1)
  local remove_highlight = function()
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  end
  vim.defer_fn(remove_highlight, durationMs)
end

M.detect_split_direction = function()
  local bufnr = vim.api.nvim_get_current_buf()
  -- If we are the first window default to left side
  if vim.fn.winbufnr(1) == bufnr then
    return '<'
  end

  -- If we are the last window default to right side
  local lastwin = vim.fn.winnr('$')
  if vim.fn.winbufnr(lastwin) == bufnr then
    return '>'
  end

  return '<'
end

return M
