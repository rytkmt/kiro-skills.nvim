-- kiro_skills.cmp: nvim-cmp カスタムソース
-- prompt.md バッファで `/` を打つとスキル名を補完候補に出す。

local core = require("kiro_skills")

local source = {}

function source.new()
  return setmetatable({}, { __index = source })
end

-- このバッファで有効か(= /editor の prompt.md か)
local function is_prompt_buffer()
  local name = vim.api.nvim_buf_get_name(0)
  return name:match("prompt%.md$") ~= nil
end

function source:is_available()
  return is_prompt_buffer()
end

function source:get_debug_name()
  return "kiro_skills"
end

-- `/` をトリガー文字にする
function source:get_trigger_characters()
  return { "/" }
end

-- `/` に続く英数・ハイフン・アンダースコアをキーワードとして認識させる
function source:get_keyword_pattern()
  return [[/\%(\k\|-\)*]]
end

function source:complete(params, callback)
  local skills = core.collect()
  local items = {}
  for _, s in ipairs(skills) do
    -- `/` はトリガーとして入力済み。insertText は `/name`(置換)にする。
    table.insert(items, {
      label = "/" .. s.name,
      insertText = "/" .. s.name,
      filterText = "/" .. s.name,
      kind = require("cmp").lsp.CompletionItemKind.Text,
      labelDetails = { description = "skills" },
      documentation = {
        kind = "markdown",
        value = string.format("**%s**\n\n%s", s.name, s.description),
      },
    })
  end
  callback({ items = items, isIncomplete = false })
end

local M = {}

-- cmp に source を登録し、prompt.md バッファで有効化するフックを張る。
function M.register(cmp)
  cmp.register_source("kiro_skills", source.new())

  local group = vim.api.nvim_create_augroup("KiroSkillsCmp", { clear = true })
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile", "BufEnter" }, {
    group = group,
    pattern = { "prompt.md", "*/prompt.md" },
    callback = function(args)
      -- このバッファにだけ kiro_skills source を足す。
      cmp.setup.buffer({
        sources = cmp.config.sources({
          { name = "kiro_skills", priority = 100 },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
      -- markdown 既定の `/` 非トリガーを上書きするため、バッファ単位で設定済み。
      vim.b[args.buf].kiro_skills_enabled = true
    end,
  })
end

return M
