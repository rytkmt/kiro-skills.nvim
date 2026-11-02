-- kiro_skills: スキル収集コア
-- 自作(global/workspace) + vendor の SKILL.md を走査し、
-- フロントマターから name/description を抽出する。

local M = {}

local uv = vim.uv or vim.loop

M.config = {
  global_dir = vim.fn.expand("~/.kiro/skills"),
  vendor_dir = vim.fn.expand("~/.kiro/vendor_skills"),
  workspace_subpath = ".kiro/skills",
}

-- SKILL.md のフロントマター(--- で囲まれた name:/description:)を抽出する。
-- 戻り値: name, description（取れなければ nil）
local function parse_frontmatter(path)
  local fd = io.open(path, "r")
  if not fd then
    return nil, nil
  end
  local name, desc
  local in_fm = false
  local fm_started = false
  for line in fd:lines() do
    if line:match("^%-%-%-%s*$") then
      if not fm_started then
        fm_started = true
        in_fm = true
      else
        -- フロントマター終端
        break
      end
    elseif in_fm then
      local n = line:match("^name:%s*(.+)$")
      if n then
        name = n:gsub('^%s*"', ""):gsub('"%s*$', ""):gsub("^%s+", ""):gsub("%s+$", "")
      end
      local d = line:match("^description:%s*(.+)$")
      if d then
        desc = d:gsub('^%s*"', ""):gsub('"%s*$', ""):gsub("^%s+", ""):gsub("%s+$", "")
      end
    elseif not fm_started then
      -- 先頭が --- で始まらない(フロントマター無し)なら打ち切る
      if line:match("%S") then
        break
      end
    end
  end
  fd:close()
  return name, desc
end

-- ディレクトリ直下の各サブディレクトリの SKILL.md を集める(glob: <dir>/*/SKILL.md)。
-- _shared は除外。
local function collect_dir_flat(dir, source, acc, seen)
  if vim.fn.isdirectory(dir) == 0 then
    return
  end
  local entries = vim.fn.glob(dir .. "/*/SKILL.md", true, true)
  for _, path in ipairs(entries) do
    local skilldir = vim.fn.fnamemodify(path, ":h:t")
    if skilldir ~= "_shared" and not seen[path] then
      local name, desc = parse_frontmatter(path)
      if name then
        seen[path] = true
        table.insert(acc, { name = name, description = desc or "", path = path, source = source })
      end
    end
  end
end

-- vendor は階層が深い(apresmoi-skills/skills/<name>/SKILL.md)ので再帰 glob。
local function collect_dir_recursive(dir, source, acc, seen)
  if vim.fn.isdirectory(dir) == 0 then
    return
  end
  local entries = vim.fn.glob(dir .. "/**/SKILL.md", true, true)
  for _, path in ipairs(entries) do
    local skilldir = vim.fn.fnamemodify(path, ":h:t")
    if skilldir ~= "_shared" and not seen[path] then
      local name, desc = parse_frontmatter(path)
      if name then
        seen[path] = true
        table.insert(acc, { name = name, description = desc or "", path = path, source = source })
      end
    end
  end
end

-- プロセス cwd から上方向に .kiro/skills を探索する。
-- /editor は /tmp/kiro-editor-*/prompt.md を開くためバッファパスは使えない。
-- 戻り値: 見つかった .kiro/skills の絶対パス、無ければ nil
function M.find_workspace_skills_dir()
  local cwd = uv.cwd()
  if not cwd then
    return nil
  end
  local found = vim.fs.find(".kiro", {
    path = cwd,
    upward = true,
    type = "directory",
    limit = 1,
  })
  if found and found[1] then
    local skills = found[1] .. "/skills"
    if vim.fn.isdirectory(skills) == 1 then
      -- 上方向探索がホームの ~/.kiro にヒットした場合は global と同一なので
      -- workspace 扱いしない(cwd 配下に .kiro/skills を持つプロジェクトのみ対象)。
      local norm = vim.fn.fnamemodify(skills, ":p"):gsub("/$", "")
      local global_norm = vim.fn.fnamemodify(M.config.global_dir, ":p"):gsub("/$", "")
      if norm == global_norm then
        return nil
      end
      return skills
    end
  end
  return nil
end

-- 全スキルを収集して返す。
-- 戻り値: { {name=, description=, path=, source="workspace"|"global"|"vendor"}, ... }
-- 重複(同一 path)は除外。name 衝突時は workspace を優先(先に入れる)。
function M.collect()
  local acc = {}
  local seen = {}

  -- workspace を先に(優先度高)
  local ws = M.find_workspace_skills_dir()
  if ws then
    collect_dir_flat(ws, "workspace", acc, seen)
  end
  collect_dir_flat(M.config.global_dir, "global", acc, seen)
  collect_dir_recursive(M.config.vendor_dir, "vendor", acc, seen)

  -- name 昇順で安定ソート(source優先は seen 挿入順で既に担保)
  table.sort(acc, function(a, b)
    if a.name == b.name then
      return a.source < b.source
    end
    return a.name < b.name
  end)
  return acc
end

-- cmp/telescope の有効化フックを張る。
function M.setup(opts)
  if opts then
    M.config = vim.tbl_extend("force", M.config, opts)
  end

  -- cmp source 登録(cmp があれば)
  local ok_cmp, cmp = pcall(require, "cmp")
  if ok_cmp then
    require("kiro_skills.cmp").register(cmp)
  end
end

return M
