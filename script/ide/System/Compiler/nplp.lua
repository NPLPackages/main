

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
NPL.load("(gl)script/ide/System/Compiler/lib/metalua/base.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/metalua/string2.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/metalua/table2.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/lexer.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/gg.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/mlp_lexer.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/mlp_misc.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/mlp_table.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/mlp_meta.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/mlp_expr.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/mlp_stat.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/mlp_ext.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/mlp_npl.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/ast_to_string.lua");


local mlp = commonlib.gettable("mlp")
local nplp = commonlib.inherit(nil, commonlib.gettable("nplp"))

local function src_to_ast(src)
  local  lx  = mlp.lexer:newstream (src)
  local  ast = mlp.chunk (lx)
  return ast
end

--local src_filename = ...
--
--if not src_filename then
  --io.stderr:write("usage: lua2c filename.lua\n")
  --os.exit(1)
--end

function nplp.compile(src_filename)
	local src_file = assert(io.open (src_filename, 'r'))
	local src = src_file:read '*a'; src_file:close()
	src = src:gsub('^#[^\r\n]*', '') -- remove any shebang

	local ast = src_to_ast(src)

	--table.print(ast, 80, "nohash")

	compiled_src=ast_to_string(ast)

	local dst_file = assert(io.open ('result.lua', 'w'))
	dst_file:write(compiled_src)
	dst_file:close()
	print(compiled_src)
end

---------------------------------
