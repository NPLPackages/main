NPL.load("(gl)script/ide/System/Compiler/lib/lcode.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/ldump.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/lopcodes.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/compile.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/metalua/table2.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/metalua/base.lua");
NPL.load("(gl)script/ide/System/Compiler/lib/metalua/string2.lua");
--module("mlc", package.seeall)
local mlc = commonlib.inherit(nil, commonlib.gettable("mlc"))
local mlp = commonlib.gettable("mlp")
local bytecode = commonlib.gettable("bytecode")
--print "Loading mlc module for compiler bootstrapping"

mlc.metabugs = false

function mlc:function_of_ast (ast)
   local  proto = bytecode.metalua_compile (ast) 
   local  dump  = bytecode.dump_string (proto)
   local  func  = string.undump(dump)
   return func
end
   
function mlc:ast_of_luastring (src)
   local  lx  = mlp.lexer:newstream (src)
   local  ast = mlp.chunk (lx)
   return ast
end
   
function mlc:function_of_luastring (src)
   local  ast  = ast_of_luastring (src)
   local  func = function_of_ast(ast)
   return func
end

function mlc:function_of_luafile (name)
   local f   = io.open(name, 'r')
   local src = f:read '*a'
   f:close()
   return function_of_luastring (src, "@"..name)
end
