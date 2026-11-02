# kiro-skills.nvim

Kiro CLI の `/editor` で開くプロンプト（`prompt.md`）に、登録済みスキル名を
補完・検索で挿入する Neovim プラグイン。

## 機能

- **nvim-cmp source** (`kiro_skills`): `prompt.md` バッファで `/` を打つとスキル名が補完候補に出る。確定するとスキル名が挿入される（例: `/list-skills`）。
- **telescope 拡張** (`:Telescope kiro_skills`): スキル一覧を description 付きで絞り込み、選択してカーソル位置に挿入する。

## 収集対象のスキル

| 系統 | パス |
|------|------|
| グローバル自作 | `~/.kiro/skills/*/SKILL.md` |
| ワークスペース自作 | `<cwdから上方向探索>/.kiro/skills/*/SKILL.md` |
| vendor | `~/.kiro/vendor_skills/**/SKILL.md` |

- `_shared` ディレクトリは除外する。
- 各 `SKILL.md` のフロントマター（`---` で囲まれた `name:` / `description:`）から抽出する。
- 組み込み（built-in）スキルはファイル実体が無いため対象外。

### ワークスペーススキルの探索基準

`/editor` が開く実ファイルは `/tmp/kiro-editor-*/prompt.md` で、バッファパスからは
プロジェクトを辿れない。そのため nvim の **プロセス cwd**（`vim.uv.cwd()`）を起点に
`.kiro/skills` を上方向探索する。`/editor` 起動時の cwd は Kiro の作業ディレクトリを
引き継ぐ前提。

## セットアップ (lazy.nvim / ローカル参照)

```lua
{
  dir = "~/git/kiro-skills.nvim",
  name = "kiro-skills.nvim",
  dependencies = { "hrsh7th/nvim-cmp", "nvim-telescope/telescope.nvim" },
  config = function()
    require("kiro_skills").setup()
  end,
}
```

cmp source は `prompt.md` バッファで自動有効化する（`setup()` 内で FileType/BufEnter フックを張る）。

## 手動利用

```vim
:Telescope kiro_skills
```

```lua
require("kiro_skills").collect()  -- { {name=, description=, path=, source=}, ... }
```
