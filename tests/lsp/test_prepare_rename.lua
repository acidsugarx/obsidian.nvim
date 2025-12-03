local eq = MiniTest.expect.equality
local h = dofile "tests/helpers.lua"

local T, child = h.child_vault()

local target = "target.md"
local ref = "ref.md"

local target_content = [[---
id: target
aliases: []
tags: []
---
hello
world]]

local target_expected = [[---
id: new_target
aliases: []
tags: []
---
hello
world]]

local ref_wiki = [==[

a link: [[target]] some text after
]==]

local ref_markdown = [==[

[target](target.md)
]==]

local ms = vim.lsp.protocol.Methods

local function request_prepare_rename()
  local responses = child.lsp.buf_request_sync(
    0,
    ms.textDocument_prepareRename,
    child.lua_get "vim.lsp.util.make_position_params(0, 'utf-8')"
  )

  local response = responses[1]
  local result = response.result
  return result
end

T["prepare rename current note"] = function()
  local root = child.Obsidian.dir
  local files = h.mock_vault_contents(root, {
    [target] = target_content,
  })

  child.cmd("edit " .. files[target])

  local result = request_prepare_rename()

  eq(result.placeholder, "target")
end

T["prepare rename wiki link under cursor"] = function()
  local root = child.Obsidian.dir

  local files = h.mock_vault_contents(root, {
    [ref] = ref_wiki,
  })

  child.cmd("edit " .. files[ref])
  child.api.nvim_win_set_cursor(0, { 2, 9 })

  local result = request_prepare_rename()
  eq(result.placeholder, "target")
end

T["rename markdown link under cursor"] = function()
  local root = child.Obsidian.dir

  local files = h.mock_vault_contents(root, {
    [ref] = ref_markdown,
  })

  child.cmd("edit " .. files[ref])
  child.api.nvim_win_set_cursor(0, { 2, 9 })

  local result = request_prepare_rename()
  eq(result.placeholder, "target")
end

T["rename links with suffixes: header and block"] = function()
  local root = child.Obsidian.dir

  local files = h.mock_vault_contents(root, {
    [ref] = [==[

[[target#header]]
[[target#^block]]
]==],
  })

  child.cmd("edit " .. files[ref])
  child.api.nvim_win_set_cursor(0, { 2, 9 })
  eq(request_prepare_rename().placeholder, "target")

  child.api.nvim_win_set_cursor(0, { 3, 9 })
  eq(request_prepare_rename().placeholder, "target")
end

return T
