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
NPL.load("(gl)script/ide/System/Compiler/nplp_def.lua");

local gg = commonlib.gettable("System.Compiler.lib.gg")
local nplp = commonlib.inherit(commonlib.gettable("System.Compiler.lib.mlp"), commonlib.gettable("System.Compiler.nplp"))
local nplp_def = commonlib.gettable("System.Compiler.nplp_def")
local nplgen = commonlib.gettable("System.Compiler.nplgen")

----------------------------------------------------------------------
--Delete original -{}, +{} structure parser in Metalua
----------------------------------------------------------------------
nplp.expr.primary:del("+{") -- TODO: FIXME, why deleting "+{" for nplp.expr leads to error
nplp.expr.suffix:del("+{")
nplp.expr.primary:del("-{")
nplp.stat:del("-{")
--nplp.lexer:del "-{"	TODO: delete "-{" keyword

----------------------------------------------------------------------
--Override Splice Parser
----------------------------------------------------------------------
function nplp.splice (ast)
   local s = nplgen.ast_to_str (ast)
   local f = loadstring (s)
   local result=f()
   return result
end

function nplp.splice_content (lx)
	local parser_name = "expr"
	if lx:is_keyword (lx:peek(2), ":") then
		local a = lx:next()
		lx:next() -- skip ":"
		assert (a.tag=="Id", "Invalid splice parser name")
		parser_name = a[1]
	end
	local ast = nplp[parser_name](lx)
	if nplp.in_a_quote then
		printf("SPLICE_IN_QUOTE:\n%s", _G.table.tostring(ast, "nohash", 60))
		return { tag="Splice", ast }
	else
		-- try to compare two ast, translate them into string first
		-- TODO: need a more robust comparision between two asts
		ast_str = _G.table.tostring(ast, "nohash", 60)
		--print(ast_str)  
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
--Override some parsers using splice parser
----------------------------------------------------------------------
function nplp.opt_id (lx)
   local a = lx:peek();
   if lx:is_keyword (a, "-{") then
      local v = gg.sequence{ "-{", nplp.splice_content, "}" } (lx) [1]
      if v.tag ~= "Id" and v.tag ~= "Splice" then
         gg.parse_error(lx,"Bad id splice")
      end
      return v
   elseif a.tag == "Id" then return lx:next()
   else return false end
end

function nplp.string (lx)
   local a = lx:peek()
   if lx:is_keyword (a, "-{") then
      local v = gg.sequence{ "-{", nplp.splice_content, "}" } (lx) [1]
      if v.tag ~= "" and v.tag ~= "Splice" then
         gg.parse_error(lx,"Bad string splice")
      end
      return v
   elseif a.tag == "String" then return lx:next()
   else error "String expected" end
end


--------------------------------------------------------------------------------
-- NPL def statements
--------------------------------------------------------------------------------
local function transformer_maker(name)
	local template_ast = {}
	if _G.metaDefined[name] then
		template_ast = _G.metaDefined[name]
   	else
    	error("not defined symbol")
   	end

   	local function traverse_and_replace(tast, args, blk, cfg)  -- traverse template ast and replace 
   		local res_ast={}
   		if(type(tast)=='table') then
   			if tast.tag and tast.tag=='EmitAll' then 
   				res_ast = blk
				cfg.emited = true
   			elseif tast.tag and tast.tag=='Param' then
				if args[tast[1]] then
					res_ast=args[tast[1]]
				else
					res_ast={tag='Nil'}
				end
			else 
   				res_ast.tag=tast.tag
				if not cfg.emited then
					res_ast.lineinfo = {first = cfg.before}
				else
					res_ast.lineinfo = {first = cfg.after}
				end
   				for i=1, #tast do
   					res_ast[i], cfg = traverse_and_replace(tast[i], args, blk, cfg)
   				end
   			end
   		else
   			res_ast=tast
   		end
   		return res_ast, cfg
   	end

   	local function transformer(ast)
	    local cfg = {
			before = ast.lineinfo.first, 
			after = ast.lineinfo.last,
			emited = false
		}
		table.print(ast.lineinfo.last, 60, "nohash")
   		args, blk = ast[1], ast[2]
		return traverse_and_replace(template_ast, args, blk, cfg)
   	end

   	return transformer
end

local function label_params(ast, symTbl)
	--if ast.lineinfo then
		--table.print(ast.lineinfo.first, 60, "nohash")
		--table.print(ast.lineinfo.last, 60, "nohash")
	--end
	local res_ast = {}
	if type(ast) == 'table' then
		if ast.tag == 'Id' and nplp.in_a_quote and symTbl[ast[1]] then
			res_ast.tag = 'Param'-- symTle[ast[1]] reflects ith param
			res_ast[1] = symTbl[ast[1]]
		elseif ast.tag == 'Quote' then
			local prev_quote = nplp.in_a_quote
			if prev_quote then
				error "not support quote in a quote"
			end
			nplp.in_a_quote = true
			for i=1, #ast do
				res_ast[i] = label_params(ast[i], symTbl)
				if ast[i].lineinfo then
					res_ast[i].lineinfo = ast[i].lineinfo
				end
			end
			nplp.in_a_quote = prev_quote
		else
			res_ast.tag = ast.tag
			for i=1, #ast do
				res_ast[i] = label_params(ast[i], symTbl)
				if ast[i].lineinfo then
					res_ast[i].lineinfo = ast[i].lineinfo
				end
			end
		end
	else
		res_ast = ast
	end
	return res_ast
end

function nplp.register (name, tempAst)
	if not _G.metaDefined then _G.metaDefined = {} end
	_G.metaDefined[name] = tempAst
	nplp.lexer:add(name)
    nplp.stat:add{name, "(", nplp.func_args_content, ")", "{", nplp.block, "}", builder=nil, transformers={transformer_maker(name)}}
end

local function def_builder(x)
   	local elems, blk = x[1], x[2]
   	if #elems > 0 then
      	name=elems[1][1]
		symTbl = {}
		for i=2, #elems do					-- read from second params to store as parameters for func in symbol table
			if elems[i].tag == "Id" then 
				symTbl[elems[i][1]] = i-1
			else 
				error ("def params only allow identifiers")
			end
		end
		nplp.in_a_quote = false
		labeld_blk = label_params(blk, symTbl)
      	if type(name)=='string' then
         	nplp.register(name, labeld_blk)
      	elseif type(s)=='table' then
      	end
   	else
      	error("def construction error")
   	end
end

nplp.lexer:add "def"
nplp.stat:add{name="define statement", "def", "(", nplp.expr_list, ")", "{", nplp_def.block, "}", builder=def_builder}

function nplp.src_to_ast(src)
  local  lx  = nplp.lexer:newstream (src)
  local  ast = nplp.chunk (lx)
  return ast
end

---------------------------------
