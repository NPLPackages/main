local mlp = commonlib.inherit(nil, commonlib.gettable("mlp"))

local function block (lx) return mlp.block (lx) end
local expr_list = function (lx) return mlp.expr_list(lx) end

--module ("mlp", package.seeall)

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
         	mlp.lexer:add(s)
         	mlp.stat:add{s, "(", expr_list, ")", "{", block, "}", builder=nil, transformers={transformer_maker(s)}}
      	elseif type(s)=='table' then
      	end
   	else
      	error("def construction error")
   	end
end

mlp.lexer:add "def"
mlp.stat:add{name="define statement", "def", "(", expr_list, ")", "{", block, "}", builder=def_builder}

function emit()
	-- fake function
end
