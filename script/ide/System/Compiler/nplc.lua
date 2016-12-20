----------------------------------------------------------------------
-- NPL Compiler
-- the goal of NPL Compiler is to extend NPL Syntax
-- compiling procedure: source -> ast -> source
-- Author:Zhiyuan
-- Date: 2016-12-13
----------------------------------------------------------------------

NPL.load("(gl)script/ide/System/Compiler/nplp_def.lua");
NPL.load("(gl)script/ide/System/Compiler/nplp.lua");
NPL.load("(gl)script/ide/System/Compiler/nplgen.lua");

local nplp = commonlib.gettable("System.Compiler.nplp")
local nplgen = commonlib.gettable("System.Compiler.nplgen")
local nplc = commonlib.inherit(nil, commonlib.gettable("System.Compiler.nplc"))

function nplc.compile(src_filename, dst_filename)
	local src_file = assert(io.open (src_filename, 'r'))
	local src = src_file:read '*a'; src_file:close()
	--src = src:gsub('^#[^\r\n]*', '') 
	local ast = nplp.src_to_ast(src)

	--table.print(ast, 80, "nohash")
	local compiled_src= nplgen.ast_to_str(ast)
	--print(compiled_src)
	local dst_file = assert(io.open (dst_filename, 'w'))  -- debug only
	dst_file:write(compiled_src)
	dst_file:close()
end

function nplc.loadstring(string, filename)
	local ast = nplp.src_to_ast(string)
	local compiled_src= nplgen.ast_to_str(ast)
	return loadstring(compiled_src, filename)
end

NPL.loadstring = nplc.loadstring