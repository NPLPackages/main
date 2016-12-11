

local _G           = _G
local assert       = _G.assert
local error        = _G.error
local io           = _G.io
local ipairs       = _G.ipairs
local os           = _G.os
local package      = _G.package
local require      = _G.require
local string       = _G.string
local table        = _G.table

-- note: includes gg/mlp Lua parsing Libraries taken from Metalua.
require "mlc"
require "lexer"
require "gg"
require "mlp_lexer"
require "mlp_misc"
require "mlp_table"
require "mlp_meta"
require "mlp_expr"
require "mlp_stat"
require "mlp_ext"
require "mlp_npl"
require "ast_to_string"
require "metalua.runtime"

local mlp = assert(_G.mlp)
local function src_to_ast(src)
  local  lx  = mlp.lexer:newstream (src)
  local  ast = mlp.chunk (lx)
  return ast
end

local src_filename = ...

if not src_filename then
  io.stderr:write("usage: lua2c filename.lua\n")
  os.exit(1)
end

local src_file = assert(io.open (src_filename, 'r'))
local src = src_file:read '*a'; src_file:close()
src = src:gsub('^#[^\r\n]*', '') -- remove any shebang

local ast = src_to_ast(src)

------modified for NPL----------

--table.print(ast, 80, "nohash")

compiled_src=ast_to_string(ast)
print(compiled_src)

---------------------------------
