----------------------------------------------------------------------
-- NPL Parser
-- Extended from Metalua Parser
-- Add a 'def' macro structure
-- Author:Zhiyuan
-- Date: 2016-12-13
----------------------------------------------------------------------

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

local nplp = commonlib.inherit(commonlib.gettable("System.Compiler.lib.mlp"), commonlib.gettable("System.Compiler.nplp"))
----------------------------------------------------------------------
--Override
----------------------------------------------------------------------
function nplp.splice_content (lx)
	print("I'm in nplp splice_content")
	local parser_name = "expr"
	if lx:is_keyword (lx:peek(2), ":") then
		local a = lx:next()
		lx:next() -- skip ":"
		assert (a.tag=="Id", "Invalid splice parser name")
		parser_name = a[1]
	end
	local ast = nplp[parser_name](lx)
	if nplp.in_a_quote then
		--printf("SPLICE_IN_QUOTE:\n%s", _G.table.tostring(ast, "nohash", 60))
		return { tag="Splice", ast }
	else
		-- try to compare two ast, translate them into string first
		-- TODO: need a more robust comparision between two asts
		ast_str = _G.table.tostring(ast, "nohash", 60)
		print(ast_str)  
		if parser_name == "expr" then 
			if ast_str == "`Call{ `Index{ `Id \"nplp\", `String \"emit\" } }" then
				ast = {tag="Table", {tag="Pair", {tag="String", "tag"}, {tag="String", "Current"}}}  -- special node in ast
			end
			ast = { { tag="Return", ast } }
		elseif parser_name == "stat"  then ast = { ast }
		elseif parser_name ~= "block" then
			error ("splice content must be an expr, stat or block") end
			--printf("EXEC THIS SPLICE:\n%s", _G.table.tostring(ast, "nohash", 60))
		return nplp.splice (ast)
	end
end

----------------------------------------------------------------------
--Replace splice structure -{} with new nplp parser
----------------------------------------------------------------------
nplp.stat:del("-{")
nplp.stat:add({ "-{", nplp.splice_content, "}", builder = nplp.fget (1) })

--------------------------------------------------------------------------------
-- NPL def statements
--------------------------------------------------------------------------------
local function transformer_maker(s)
	local template_ast = {}
	if _G.def[s] then
		template_ast = _G.def[s]
   	else
    	error("not defined symbol")
   	end

   	local function traverse_and_replace(tast, ast)  -- traverse template ast and replace 
   		local res_ast={}
   		if(type(tast)=='table') then
   			if tast.tag and tast.tag=='Current' then 
   				res_ast=ast
   			else 
   				res_ast.tag=tast.tag
   				for i=1, #tast do
   					res_ast[i] = traverse_and_replace(tast[i], ast)
   				end
   			end
   		else
   			res_ast=tast
   		end
   		return res_ast
   	end

   	local function transformer(ast)
   		el, b = ast[1], ast[2]
   		func_call={tag="Call", {tag="Id", s}, unpack(el)}
   		nast={func_call, traverse_and_replace(template_ast, ast[2])}
   		return nast
   	end

   	return transformer
end

local function def_builder(x)
   	local el, b = x[1], x[2]
   	if not _G.def then _G.def = {} end
   	if #el > 0 then
      	s=el[1][1]
      	if type(s)=='string' then
         	--print(s)
         	_G.def[s] = b
         	nplp.lexer:add(s)
         	nplp.stat:add{s, "(", nplp.expr_list, ")", "{", nplp.block, "}", builder=nil, transformers={transformer_maker(s)}}
      	elseif type(s)=='table' then
      	end
   	else
      	error("def construction error")
   	end
end

nplp.lexer:add "def"
nplp.stat:add{name="define statement", "def", "(", nplp.expr_list, ")", "{", nplp.block, "}", builder=def_builder}

function nplp.emit()
	-- fake function
end

function nplp.src_to_ast(src)
  local  lx  = nplp.lexer:newstream (src)
  local  ast = nplp.chunk (lx)
  return ast
end

---------------------------------
