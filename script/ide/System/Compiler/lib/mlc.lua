module("mlc", package.seeall)

require "lcode"
require "ldump"
require "lopcodes"
require "compile"
require "metalua.runtime"
--print "Loading mlc module for compiler bootstrapping"

metabugs = false

function function_of_ast (ast)
   local  proto = bytecode.metalua_compile (ast) 
   local  dump  = bytecode.dump_string (proto)
   local  func  = string.undump(dump)
   return func
end
   
function ast_of_luastring (src)
   local  lx  = mlp.lexer:newstream (src)
   local  ast = mlp.chunk (lx)
   return ast
end
   
function function_of_luastring (src)
   local  ast  = ast_of_luastring (src)
   local  func = function_of_ast(ast)
   return func
end

function function_of_luafile (name)
   local f   = io.open(name, 'r')
   local src = f:read '*a'
   f:close()
   return function_of_luastring (src, "@"..name)
end
