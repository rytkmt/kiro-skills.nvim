-- telescope 拡張: kiro_skills
-- スキル一覧を description 付きで絞り込み、選択でカーソル位置に /name を挿入する。

local has_telescope, pickers = pcall(require, "telescope.pickers")
if not has_telescope then
  return require("telescope").register_extension({ exports = {} })
end

local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local core = require("kiro_skills")

-- 選択したスキル名をカーソル位置に挿入する。
local function insert_skill(name)
  local text = "/" .. name
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local before = line:sub(1, col)
  local after = line:sub(col + 1)
  vim.api.nvim_set_current_line(before .. text .. after)
  vim.api.nvim_win_set_cursor(0, { row, col + #text })
end

local function skills_picker(opts)
  opts = opts or {}
  local skills = core.collect()

  pickers
    .new(opts, {
      prompt_title = "Kiro Skills",
      finder = finders.new_table({
        results = skills,
        entry_maker = function(entry)
          local display = string.format("%-24s [%s]  %s", entry.name, entry.source, entry.description)
          return {
            value = entry,
            display = display,
            ordinal = entry.name .. " " .. entry.description,
            path = entry.path,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      previewer = previewers.new_buffer_previewer({
        title = "SKILL.md",
        define_preview = function(self, entry)
          local path = entry.value.path
          if path and vim.fn.filereadable(path) == 1 then
            local lines = vim.fn.readfile(path)
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
            vim.bo[self.state.bufnr].filetype = "markdown"
          end
        end,
      }),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            insert_skill(selection.value.name)
          end
        end)
        return true
      end,
    })
    :find()
end

return require("telescope").register_extension({
  exports = {
    kiro_skills = skills_picker,
  },
})
