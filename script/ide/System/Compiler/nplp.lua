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
