NPL.load("(gl)script/ide/System/Compiler/nplp.lua");
NPL.load("(gl)script/ide/System/Compiler/nplgen.lua");

local nplp = commonlib.gettable("System.Compiler.nplp")
local nplgen = commonlib.gettable("System.Compiler.nplgen")
local nplc = commonlib.inherit(nil, commonlib.gettable("System.Compiler.nplc"))

function nplc.compile(src_filename)
	local src_file = assert(io.open (src_filename, 'r'))
	local src = src_file:read '*a'; src_file:close()
	src = src:gsub('^#[^\r\n]*', '') -- remove any shebang

	local ast = nplp.src_to_ast(src)

	--table.print(ast, 80, "nohash")

	compiled_src= nplgen.ast_to_str(ast)

	local dst_file = assert(io.open ('result.lua', 'w'))
	dst_file:write(compiled_src)
	dst_file:close()
	print(compiled_src)
end